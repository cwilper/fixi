require 'spec_helper'

describe Fixi do
  describe "::command" do
    it 'should return nil for bogus name' do
      Fixi::command("bogus").should == nil
    end

    it 'should return instance for real name' do
      Fixi::command("init").should_not == nil
    end
  end
end
