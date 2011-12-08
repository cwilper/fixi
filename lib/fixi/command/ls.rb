require 'time'
require 'trollop'

class Fixi::Command::Ls
  def self.synopsis
    "List contents of the index"
  end

  def self.details
    "This command is scoped to the current directory or the given path,
      if specified.".pack
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "ls"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
      opt :json, "Like --verbose, but outputs the result as a json array."
      opt :md5, "Restrict list to files with the given md5 checksum",
        :type => :string, :short => :none
      opt :sha1, "Restrict list to files with the given sha1 checksum",
        :type => :string, :short => :none
      opt :sha256, "Restrict list to files with the given sha256 checksum",
        :type => :string, :short => :none
      opt :sha384, "Restrict list to files with the given sha384 checksum",
        :type => :string, :short => :none
      opt :sha512, "Restrict list to files with the given sha512 checksum",
        :type => :string, :short => :none
      opt :verbose, "Include all information known about each file. By default,
        only paths will be listed.".pack
    end
    index = Fixi::Index.new(args[0])
    if opts[:json]
      print "["
    end
    i = 0
    index.each(args[0], opts) do |hash|
      path = hash['relpath']
      path = index.rootpath + '/' + path if opts[:absolute]
      if opts[:verbose]
        print "size=#{hash['size']},mtime=#{Time.at(hash['mtime']).utc.iso8601}"
        print ",md5=#{hash['md5']}" if hash['md5']
        print ",sha1=#{hash['sha1']}" if hash['sha1']
        print ",sha256=#{hash['sha256']}" if hash['sha256']
        print ",sha384=#{hash['sha384']}" if hash['sha384']
        print ",sha512=#{hash['sha512']}" if hash['sha512']
        puts " #{path}"
      elsif opts[:json]
        print "," if i > 0
        puts "\n  { path: \"#{path}\","
        puts "    size: \"#{hash['size']}\","
        print "    mtime: \"#{Time.at(hash['mtime']).utc.iso8601}\""
        print ",\n    md5: \"#{hash['md5']}\"" if hash['md5']
        print ",\n    sha1: \"#{hash['sha1']}\"" if hash['md5']
        print ",\n    sha256: \"#{hash['sha256']}\"" if hash['sha256']
        print ",\n    sha384: \"#{hash['sha384']}\"" if hash['sha384']
        print ",\n    sha512: \"#{hash['sha512']}\"" if hash['sha512']
        print " }"
      else
        puts path
      end
      i += 1
    end
    if opts[:json]
      print "\n" if i > 0
      puts "]"
    end
  end
end
