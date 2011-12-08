module Fixi::Command
  def self.banner(name)
    "fixi-#{name}: #{const_get(name.capitalize).synopsis}\n\n" +
      "usage: fixi #{name} [<options>] [path]\n\n" +
      "#{const_get(name.capitalize).details}\n\n" +
      "Options:"
  end
end

Dir.glob(File.dirname(__FILE__) + '/command/*') {|file| require file}
