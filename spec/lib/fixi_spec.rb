require 'spec_helper'
require 'tempfile'

describe Fixi do
  describe "::command" do
    it 'should return nil for bogus name' do
      Fixi::command("bogus").should == nil
    end

    it 'should return instance for real name' do
      Fixi::command("init").should_not == nil
    end
  end

  describe "::digests" do
    it 'should raise error for bogus name' do
      lambda { Fixi::digests("bogus") }.should raise_error
    end

    it 'should return instance for real name' do
      Fixi::digests("md5").should_not == nil
    end
  end

  describe "::hexdigests" do
    before(:all) do
      @file = Tempfile.new('foo')
      @file.write('foo')
      @file.close
    end

    it 'should compute correct single checksum' do
      hexdigests = Fixi::hexdigests(Fixi::digests("md5"), @file.path)
      hexdigests.should == ["acbd18db4cc2f85cedef654fccc4a4d8"]
    end

    it 'should compute correct multi checksum' do
      hexdigests = Fixi::hexdigests(Fixi::digests("md5,sha1"), @file.path)
      hexdigests.should == ["acbd18db4cc2f85cedef654fccc4a4d8",
          "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33"]
    end

    after(:all) do
      @file.unlink
    end
  end
end
