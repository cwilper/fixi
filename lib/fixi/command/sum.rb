require 'trollop'
require 'find'
require 'fixi/index'

class Fixi::Command::Sum
  def self.synopsis
    "Calculate checksum(s) of a file"
  end

  def self.arghelp
    "<file>"
  end

  def self.details
    "This command operates on files and does not require an index to exist."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "sum"
      opt :algorithms, "Checksum algorithm(s) to use. This is a comma-separated
        list, which may include  md5, sha1, sha256, sha384, and sha512. At least
        one must be specified.".pack, :short => 'l', :type => :string,
        :required => true
    end
    unless args[0]
      raise "Must specify a file."
      exit 1
    end
    path = args[0]
    unless File.exists?(path)
      raise "No such file: #{path}"
      exit 1
    end
    hexdigests = Fixi::hexdigests(Fixi::digests(opts[:algorithms]), path)
    hexdigests.each { |hexdigest| puts "#{hexdigest}" }
  end
end
