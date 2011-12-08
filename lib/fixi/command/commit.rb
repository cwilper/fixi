require 'trollop'
require 'find'
require 'fixi/index'

class Fixi::Command::Commit
  def self.synopsis
    "Commit modified files to the index"
  end

  def self.details
    "This command is scoped to the current directory or the given path,
      if specified.".pack
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "commit"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
      opt :dry_run, "Don't do anything; just report what would be done"
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
      if index.file_in_scope(relpath) && File.exists?(abspath)
        size = File.size(abspath)
        mtime = File.mtime(abspath).to_i
        if size != hash['size']
          detail = opts[:verbose] ? "size=#{size} " : ""
          puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
          index.update(relpath) unless opts[:dry_run]
        elsif mtime != hash['mtime']
          detail = opts[:verbose] ? "mtime=#{Time.at(mtime).utc.iso8601} " : ""
          puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
          index.update(relpath) unless opts[:dry_run]
        elsif not opts[:shallow]
          hexdigests = Fixi::hexdigests(Fixi::digests(index.algorithms), abspath)
          i = 0
          need_update = false
          index.algorithms.split(',').each do |algorithm|
            if not(need_update) && (hexdigests[i] != hash[algorithm])
              need_update = true
              detail = opts[:verbose] ? "#{algorithm}=#{hexdigests[i]} " : ""
              puts "M #{detail}#{opts[:absolute] ? abspath : relpath}"
            end
            hash[algorithm] = hexdigests[i]
            i += 1
          end
          index.update(relpath, hash) if need_update && not(opts[:dry_run])
        end
      end
    end
  end
end
