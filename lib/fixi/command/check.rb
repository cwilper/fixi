require 'trollop'

class Fixi::Command::Check
  def self.synopsis
    "Verify the fixity of files in the index"
  end

  def self.details
    "This command is scoped to the current directory or the given path,
      if specified.".pack
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "check"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
      opt :shallow, "Do shallow comparisons when determining which files have
        changed. If specified, only file sizes and mtimes will be used. By 
        default, checksums will also be computed and compared if necessary.".pack
      opt :verbose, "For modified files, show which attribute changed.
        By default, only the path is shown.".pack
    end
    path = File.expand_path(args[0] || ".")
    index = Fixi::Index.new(path)
   
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
            hexdigests = Fixi::hexdigests(Fixi::digests(index.algorithms), abspath)
            i = 0
            index.algorithms.split(',').each do |algorithm|
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
