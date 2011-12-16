module Fixi::Command
  def self.banner(name)
    n = name.capitalize
    "fixi-#{name}: #{const_get(n).synopsis}\n\n" +
      "usage: fixi #{name} [<options>] #{const_get(n).arghelp}\n\n" +
      "#{const_get(n).details}\n\n" +
      "Options:"
  end
end

Dir.glob(File.dirname(__FILE__) + '/command/*') {|file| require file}
