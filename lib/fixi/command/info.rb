require 'trollop'
require 'fixi/index'

class Fixi::Command::Info
  def self.synopsis
    "Display a summary of the index"
  end

  def self.details
    "This command is scoped to the current directory or the given path,
      if specified.".pack
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command::banner "info"
    end
    Fixi::Index.new(args[0]).describe
  end
end
