require 'trollop'
require 'fixi/index'

class Fixi::Command::Info
  def self.synopsis
    "Display a summary of the index"
  end

  def self.arghelp
    "[<dir>]"
  end

  def self.details
    "If no argument is given, the current directory ('.') is assumed."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command::banner "info"
    end
    Fixi::Index.new(args[0]).describe
  end
end
