require_relative '../../../lib/rauto/user32'
require_relative '../../../lib/rauto/gdi32'
require_relative '../../../lib/rauto/kernel32'

include RAuto

describe GDI32 do
  before do
    @hdc = User32.GetDC(0)
    @sdc = GDI32.CreateCompatibleDC(@hdc)
    @ddb = GDI32.CreateCompatibleBitmap(@hdc,16,16)
  end
  
  after do
    #clean up
    GDI32.DeleteObject(@ddb)
    GDI32.DeleteDC(@sdc)
    User32.ReleaseDC(0,@hdc) 
  end
  
  it "should create a memory device context compatible with the specified device" do
    @sdc.should_not == 0
  end
  it "should not create a memory device context when no compatible device is specified" do
    GDI32.CreateCompatibleDC(1).should == 0 #1 is low enough in the address space that I can assume it's not valid
  end
  it "should release memory device context successfuly" do
    GDI32.DeleteDC(@sdc).should_not == 0
  end
  it "should not release memory device context successfuly when 0 is passed as the HDC" do
    GDI32.DeleteDC(0).should == 0
  end
  it "should create bitmap memory area" do
    @ddb.should_not == 0
  end
  it "should delete an gdi object" do
    GDI32.DeleteObject(@ddb).should_not == 0
  end
  it "should be able to associate an object to the device context" do
    GDI32.SelectObject(@sdc,@ddb).should_not == 0
  end
  it "should be able to bitblt the screen to the @sdc" do
    GDI32.BitBlt(@sdc, 0, 0, 16, 16, @hdc, 0, 0, GDI32::SRCCOPY).should_not == 0
  end
  
  it "should have a GetDIBits method that fills a structure with the bitmap info" do
    GDI32.SelectObject(@sdc,@ddb).should_not == 0
    GDI32.BitBlt(@sdc, 0, 0, 16, 16, @hdc, 0, 0, GDI32::SRCCOPY).should_not == 0
  
		bitmapinfo_ptr = CPtr.malloc(GDI32::BITMAPINFO.size)
    bitmapinfo = GDI32::BITMAPINFO.new(bitmapinfo_ptr)
    bitmapinfo.to_ptr['bmiHeader.biSize'] = GDI32::BITMAPINFOHEADER.size;
    bitmapinfo.to_ptr['bmiHeader.biBitCount'] = 0;
    
    GDI32.GetDIBits(@sdc,@ddb,0,0,NULL,bitmapinfo.to_ptr,GDI32::DIB_RGB_COLORS).should_not == 0
    
    pixel_count = bitmapinfo.to_ptr['bmiHeader.biWidth'] * bitmapinfo.to_ptr['bmiHeader.biHeight']
    pixel_buffer = CPtr.malloc(pixel_count * GDI32.sizeof("DWORD"))
    
    bitmapinfo.to_ptr['bmiHeader.biHeight'] *= -1
    GDI32.GetDIBits(@sdc,@ddb,0,16,pixel_buffer,bitmapinfo.to_ptr,GDI32::DIB_RGB_COLORS).should_not == 0
  end
end
