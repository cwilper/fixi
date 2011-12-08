require 'trollop'
require 'fixi/index'

class Fixi::Command::Init
  def self.synopsis
    "Create a new, empty index"
  end

  def self.details
    "This command is scoped to the current directory or the given path,
      if specified.".pack
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command::banner "init"
      opt :algorithms, "Checksum algorithm(s) to use for the index. This is
        a comma-separated list, which may include md5, sha1, sha256, sha384, and
        sha512.".pack, :default => "sha256", :short => 'l'
    end
    index = Fixi::Index.new(args[0], true, opts[:algorithms])
    puts "Initialized empty index at #{index.dotpath}"
  end
end
