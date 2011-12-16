require 'trollop'
require 'fixi/index'
require 'set'
require 'fileutils'

class Fixi::Command::Bag
  def self.synopsis
    "Export files as a new BagIt bag"
  end

  def self.arghelp
    "<input-dir> <output-dir>"
  end

  def self.details
    "Where:\n  input-dir is an indexed directory whose content should be exported.\n" +
      "  output-dir is the base directory of the bag to be created."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "bag"
      opt :algorithms, "Checksum algorithm(s) to use for the bag. This is
        a comma-separated list, which may include md5, sha1, sha256, sha384,
        sha512, and must be a subset of the indexed algorithms. If unspecified,
        manifests will be created for all indexed algorithms.".pack,
        :short => 'l', :type => :string
    end

    raise "Must specify input directory." unless args[0] 
    raise "Must specify output directory." unless args[1]
    raise "Output directory already exists." if File.exists?(args[1])

    input_dir = File.expand_path(args[0])
    output_dir = File.expand_path(args[1])

    index = Fixi::Index.new(input_dir)
    Dir.mkdir(output_dir)

    # if algorithms specified, must be a subset of those indexed
    opts[:algorithms] ||= index.algorithms
    set = Set.new(index.algorithms.split(","))
    subset = Set.new(opts[:algorithms].split(","))
    raise "Specified algorithm(s) must be a subset of #{index.algorithms}" unless subset.subset?(set)

    manifiles = {}
    
    begin
      # write bag declaration
      file = File.new(File.join(args[1], "bagit.txt"), "w")
      file.puts("BagIt-Version: 0.97")
      file.puts("Tag-File-Character-Encoding: UTF-8")
      file.close

      # open manifest files for writing
      opts[:algorithms].split(",").each do |alg|
        filename = File.join(args[1], "manifest-#{alg}.txt")
        manifiles[alg] = File.new(filename, "w")
      end

      # copy all files, preserving attributes
      index.each(input_dir) do |hash|
        relpath = hash['relpath']
        abspath = index.rootpath + '/' + relpath
        if index.file_in_scope(relpath) && File.exists?(abspath)
          bagrelpath = "data" + abspath[input_dir.length..-1]
          destpath = args[1] + "/" + bagrelpath
          manifiles.each do |alg, file|
            file.puts("#{hash[alg]} #{bagrelpath}")
          end
          begin
            FileUtils.cp(abspath, destpath, :preserve => true)
          rescue
            FileUtils.mkdir_p(File.dirname(destpath))
            FileUtils.cp(abspath, destpath, :preserve => true)
          end
        end
      end

      data_dir = output_dir + "/data"

      # revisit all dirs under data/, copying orig dir metadata
      Find.find(data_dir) do |dir|
        if File.directory?(dir) && dir != data_dir
          orig_dir = input_dir + dir[data_dir.length..-1]
          Fixi::set_metadata(dir, File.stat(orig_dir))
        end
      end
    ensure
      manifiles.each_value { |file| file.close }
    end
  end

end
