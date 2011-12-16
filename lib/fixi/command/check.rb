require 'trollop'

class Fixi::Command::Check
  def self.synopsis
    "Verify the fixity of files in the index"
  end

  def self.arghelp
    "[<dir>|<file>]"
  end

  def self.details
    "If no argument is given, the current directory ('.') is assumed."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "check"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
      opt :algorithms, "Checksum algorithm(s) to use if shallow isn't specified.
        This is a comma-separated list, which may include md5, sha1, sha256, sha384,
        sha512, and must be a subset of the indexed algorithms. If unspecified,
        defaults to all indexed algorithms.".pack, :short => 'l', :type => :string
      opt :shallow, "Do shallow comparisons when determining which files have
        changed. If specified, only file sizes and mtimes will be used. By 
        default, checksums will also be computed and compared if necessary.".pack
      opt :verbose, "For modified files, show which attribute changed.
        By default, only the path is shown.".pack
    end
    path = File.expand_path(args[0] || ".")
    index = Fixi::Index.new(path)
   
    # if algorithms specified, must be a subset of those indexed
    opts[:algorithms] ||= index.algorithms
    set = Set.new(index.algorithms.split(","))
    subset = Set.new(opts[:algorithms].split(","))
    raise "Specified algorithm(s) must be a subset of #{index.algorithms}" unless subset.subset?(set)

    index.each(args[0]) do |hash|
      relpath = hash['relpath']
      abspath = index.rootpath + '/' + relpath
      if index.file_in_scope(relpath)
        if File.exists?(abspath)
          size = File.size(abspath)
          mtime = File.mtime(abspath).to_i
          if size != hash['size']
            detail = opts[:verbose] ? "size=#{size} " : ""
            puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
          elsif File.mtime(abspath).to_i != hash['mtime']
            detail = opts[:verbose] ? "mtime=#{Time.at(mtime).utc.iso8601} " : ""
            puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
          elsif not opts[:shallow]
            hexdigests = Fixi::hexdigests(Fixi::digests(opts[:algorithms]), abspath)
            i = 0
            opts[:algorithms].split(',').each do |algorithm|
              if hexdigests[i] != hash[algorithm]
                detail = opts[:verbose] ? "#{algorithm}=#{hexdigests[i]} " : ""
                puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
              end
              i += 1
            end
          end
        else
          puts "D #{opts[:absolute] ? abspath : relpath}"
        end
      else
        puts "X #{opts[:absolute] ? abspath : relpath}"
      end
    end

    index.find(path) do |abspath|
      relpath = index.relpath(abspath)
      unless index.contains?(relpath)
        puts "A #{opts[:absolute] ? abspath : relpath}"
      end
    end
  end
end
