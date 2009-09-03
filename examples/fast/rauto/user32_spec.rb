require_relative '../../../lib/rauto/user32'

include RAuto

describe User32 do
  before do
    @hdc = User32.GetDC(0)
  end
  
  after do
    User32.ReleaseDC(0,@hdc) #clean up
  end
  
  it "should return a valid handle for a device context" do
    @hdc.should_not == 0
  end
  it "should return 1 when a device context is successfuly released" do
    User32.ReleaseDC(0,@hdc).should == 1
  end
  it "should return 0 when a device context is not released" do
    User32.ReleaseDC(0,0).should == 0
  end
  
  it "should return system metrics" do
    User32.GetSystemMetrics(67).should == 0
  end
end

describe RAuto, "SendInput" do
  it "should be able to move the mouse" do
		input = [User32::INPUT_MOUSE, # specify the input type
			50, # dx; the relative move distance for x axis
			50, # dx; the relative move distance for y axis
			0,  # mouseData(not used)
			User32::MOUSEEVENTF_MOVE, # dwFlags; perform a move
			0,  # time (not used)
			0,  # dwExtraInfo (not used)
		].pack("L! #DWORD,
					l! #LONG,
				l! #LONG,
				L! #DWORD,
				L! #DWORD,
				L! #DWORD,
				L! #ULONG_PTR")
		
		User32.SendInput(1,input,28).should_not == 0
  end
end

describe RAuto, "GetCursorPos" do
	it "should return the current mouse position" do
		point = [0, #x pos
						 0, #y pos
		].pack("l! #LONG,
						l! #LONG")
		User32.GetCursorPos(point).should_not == 0
	end
end
