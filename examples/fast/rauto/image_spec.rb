require_relative '../../../lib/rauto/image'

include RAuto

describe Image do
  it "should load an image from a file path and return pixel data in an array" do
    data, width, height = Image.pixel_data(File.join(File.dirname(__FILE__),"..","home.png"))
    data.should_not == nil
    
    data.size.should == 3328
    
    width.should == 32
    height.should == 26
  end
end
