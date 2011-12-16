require 'trollop'
require 'find'
require 'fixi/index'

class Fixi::Command::Rm
  def self.synopsis
    "Delete old files from the index"
  end

  def self.arghelp
    "[<dir>|<file>]"
  end

  def self.details
    "If no argument is given, the current directory ('.') is assumed."
  end

  def execute args
    opts = Trollop::options args do
      banner Fixi::Command.banner "rm"
      opt :absolute, "Show absolute paths. By default, paths are reported
        relative to the index root.".pack
      opt :dry_run, "Don't do anything; just report what would be done"
    end
    path = File.expand_path(args[0] || ".")
    index = Fixi::Index.new(path)

    index.each(args[0]) do |hash|
      relpath = hash['relpath']
      abspath = index.rootpath + '/' + relpath
      if index.file_in_scope(relpath)
        unless File.exists?(abspath)
          puts "D #{opts[:absolute] ? abspath : relpath}"
          index.delete relpath unless opts[:dry_run]
        end
      else
        puts "X #{opts[:absolute] ? abspath : relpath}"
        index.delete relpath unless opts[:dry_run]
      end
    end

  end
end
