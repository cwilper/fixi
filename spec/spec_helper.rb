require 'rubygems'
require 'simplecov'
SimpleCov.start
require 'rspec'
require 'fixi'

require 'tempfile'

module FixiTestHelperMethods
  # Start capturing stdout
  def capture_stdout
      @orig_stdout = $stdout
      @stdout_file = Tempfile.new("stdout")
      $stdout = @stdout_file
  end

  # Finish capturing stdout, setting @stdout to have each line of output
  def release_stdout
      $stdout = @orig_stdout
      @stdout_file.rewind
      @stdout = []
      @stdout_file.each do |line|
        @stdout << line
      end
      @stdout_file.unlink
  end
end
