require 'trollop'
require 'fixi/index'
require 'fileutils'

class Fixi::Command::Unbag
  def self.synopsis
    "Import files from a BagIt bag"
  end

  def self.arghelp
    "<input-dir> <output-dir>"
  end

  def self.details
    "Where:\n  input-dir is the base directory of the bag.\n" +
      "  output-dir is the directory in which to import it."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "unbag"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
    end

    # validate args and bag dir
    raise "Must specify input directory." unless args[0]
    raise "Must specify output directory." unless args[1]
    raise "Output directory already exists." if File.exists?(args[1])

    input_dir = File.expand_path(args[0])
    output_dir = File.expand_path(args[1])

    index = Fixi::Index.new(File.dirname(output_dir))
    Dir.mkdir(output_dir)

    data_dir = input_dir + "/data"
    raise "No data dir found in input dir." unless File.directory?(data_dir)

    # build hash of manifest algorithm => file path
    manifests = {}
    indexed_algs = index.algorithms.split(",")
    Dir.entries(input_dir).each do |child|
      if child =~ /^manifest-.*\.txt/
        alg = child[9..(child.length - 5)]
        if (indexed_algs.include?(alg))
          manifests[alg] = input_dir + "/" + child
        end
      end
    end

    # copy all data to dest dir, subject to includes and excludes
    Find.find(data_dir) do |abspath|
      unless abspath == data_dir
        relpath = abspath.slice(data_dir.length + 1..-1)
        destpath = output_dir + "/" + relpath
        if index.matches_any?(relpath, index.includes)
          if index.matches_any?(relpath, index.excludes)
            Find.prune
          elsif not File.directory?(abspath)
            begin
              FileUtils.cp(abspath, destpath, :preserve => true)
            rescue
              FileUtils.mkdir_p(File.dirname(destpath))
              FileUtils.cp(abspath, destpath, :preserve => true)
            end
          end
        else
          Find.prune unless File.directory?(abspath)
        end
      end
    end

    # revisit all dirs under output_dir, copying orig dir metadata
    Find.find(output_dir) do |dir|
      if File.directory?(dir) && dir != output_dir
        orig_dir = data_dir + dir[output_dir.length..-1]
        Fixi::set_metadata(dir, File.stat(orig_dir))
      end
    end

    # add paths, sizes, and mtimes to db
    index.find(output_dir) do |abspath|
      relpath = index.relpath(abspath)
      index.add(relpath, false)
    end

    # add manifest entries to db
    manifests.each do |alg, manifest|
      IO.foreach(manifest) do |line|
        i = line.index(" ")
        if i 
          digest = line[0..i-1].downcase
          bagpath = line[i+6..-1].rstrip
          relpath = index.relpath(output_dir + "/" + bagpath)
          index.set_digest(relpath, alg, digest)
        end
      end
    end

    # for all new files, compute any required hashes and print A path/etc
    algs = index.algorithms.split(",")
    index.each(output_dir) do |hash|
      relpath = hash['relpath']
      abspath = index.rootpath + '/' + relpath
      puts "A #{opts[:absolute] ? abspath : relpath}"

      missing_digests = []
      algs.each do |alg|
        missing_digests << alg unless hash[alg]
      end
      if missing_digests.size > 0
        digests = Fixi::digests(missing_digests.join(","))
        hexdigests = Fixi::hexdigests(digests, abspath)
        i = 0
        missing_digests.each do |alg|
          index.set_digest(relpath, alg, hexdigests[i])
          i += 1
        end
      end
    end

  end
end
