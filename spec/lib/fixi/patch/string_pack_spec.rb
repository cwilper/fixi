require 'spec_helper'

describe "String#pack" do
  it 'should drop leading whitespace' do
    "\n foo".pack.should == "foo"
  end

  it 'should drop trailing whitespace' do
    "\n foo".pack.should == "foo"
  end

  it 'should turn multi whitespace into one space' do
    "foo \n\n  bar".pack.should == "foo bar"
  end
end
