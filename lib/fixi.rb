require "digest"
require "fixi/version"
require "fixi/patch/string_pack"
require "fixi/command"

module Fixi
  # Get an instance of the command with the given name
  def self.command(name)
    return nil unless Command.const_defined? name.capitalize
    Command.const_get(name.capitalize).new
  end

  # Validate the given comma-separated list of checksum algorithms
  # and return and array of matching Digest implementations
  def self.digests(checksums)
    digests = []
    checksums.split(",").each do |checksum|
      begin
        digests << Digest(checksum.upcase).new
      rescue LoadError
        raise "No such algorithm: #{checksum}"
      end
    end
    digests
  end

  # Read the file once while computing any number of digests
  def self.hexdigests(digests, file)
    File.open(file, "rb") {|f|
      buf = ""
      while f.read(16384, buf)
        digests.each {|digest| digest.update buf}
      end
    }
    hds = []
    digests.each {|digest|
      hd = digest.hexdigest
      hds << hd
    }
    hds
  end

  def self.set_metadata(path, stat)
    File.utime(stat.atime, stat.mtime, path)
    begin
      File.chown(stat.uid, stat.gid, path)
    rescue Errno::EPERM
      File.chmod(stat.mode & 01777, path)
    else
      File.chmod(stat.mode, path)
    end
  end

end
