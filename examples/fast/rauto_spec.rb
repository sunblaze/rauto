require_relative "../../lib/rauto"

require 'win32ole'

HOME_POSITION_X = 665
HOME_POSITION_Y = 117

def show_ie(top = 0,left = 0)
	ie = WIN32OLE.new('InternetExplorer.Application')
	ie.visible = true
	ie.navigate("http://google.com")
	ie.top = top
	ie.left = left
	ie.width = 1024
	ie.height = 768
	sleep 1
	ie.quit unless yield(ie) == :quit
end

describe RAuto, "mouse_position" do
	it "should give the global mouse position, no matter what window is selected" do
		
	end
end

describe RAuto, "move_mouse" do
	it "should be able to move the mouse using relative coordinates" do
		pos = RAuto.mouse_position
		if pos[:x] > 50
			RAuto.move_mouse(-50,0,relative: true)
			RAuto.mouse_position[:x].should == pos[:x] - 50
		else
			RAuto.move_mouse(50,0,relative: true)
			RAuto.mouse_position[:x].should == pos[:x] + 50
		end
	end
	it "should be able to move the mouse using absolute coordinates" do
		pos = RAuto.mouse_position
		if pos[:x] > 50
			RAuto.move_mouse(pos[:x]-50,0)
			RAuto.mouse_position[:x].should == pos[:x] - 50
		else
			RAuto.move_mouse(pos[:x]+50,0)
			RAuto.mouse_position[:x].should == pos[:x] + 50
		end
	end
end

describe RAuto, "click_mouse" do
	it "should be able to click the mouse button where the cursor is now" do
		show_ie do |ie|
			pos = RAuto.mouse_position
			RAuto.move_mouse(1005-pos[:x],10-pos[:y],relative: true) # move the mouse over the close button
			ev = WIN32OLE_EVENT.new(ie,'DWebBrowserEvents')
			ie_closed = false
			ev.on_event("Quit") {|*args|ie_closed = true}
			RAuto.click_mouse # click the close button
			10.times do
				sleep 0.1
				WIN32OLE_EVENT.message_loop
			end
			ie_closed.should == true
			:quit
		end
	end
	
	it "should be able to move the mouse to an absolute coordinate and click it" do
		show_ie do |ie|
			ev = WIN32OLE_EVENT.new(ie,'DWebBrowserEvents')
			ie_closed = false
			ev.on_event("Quit") {|*args|ie_closed = true}
			RAuto.click_mouse(1005,10) # click the close button
			10.times do
				sleep 0.1
				WIN32OLE_EVENT.message_loop
			end
			ie_closed.should == true
			:quit
		end
	end
end

describe RAuto, "image_search" do
  it "should be able to find the Home icon in IE" do
    show_ie do
      result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp.png"))
      
      result.should == {x: HOME_POSITION_X,y: HOME_POSITION_Y}
    end
  end
  
  it "should be able to find the Home icon in IE but moved a bit" do
    show_ie(10,10) do
      result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp.png"))

      result.should == {x: HOME_POSITION_X + 10,y: HOME_POSITION_Y + 10}
    end
  end
  
  it "should not be able to find the Xed Home icon" do
    result = RAuto.image_search(File.join(File.dirname(__FILE__),"x-home.png"))
    result.should == nil
  end
  
  it "should be able to find an image within multiple shades on the screen" do
		show_ie do
			result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp-darkened.png"),:within_shades => 15)

      result.should == {x: HOME_POSITION_X,y: HOME_POSITION_Y}
		end
	end
  it "should support on and off alpha channel (exact match vs. match any colour)" do
		show_ie do
			result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp-alpha.png"))

      result.should == {x: HOME_POSITION_X,y: HOME_POSITION_Y}
		end
	end
  it "should support within multiple shades using the alpha channel" do
		show_ie do
			result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp-darkened-alpha.png"))

      result.should == {x: HOME_POSITION_X,y: HOME_POSITION_Y}
		end
	end
  it "should allow searching only a specefic rectangle of the screen" do
    show_ie do
      result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp.png"),
                                  rect: {x:500,y:50,width:200,height:200})
      
      result.should == {x:HOME_POSITION_X-500,y: HOME_POSITION_Y-50}
    end
  end
  it "should allow searching only a specefic rectangle of the screen and not find it" do
    show_ie do
      result = RAuto.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp.png"),
                                  rect: {x:0,y:0,width:200,height:200})
      
      result.should == nil
    end
  end
end

describe RAuto, "screen_dimensions" do
  it "should be able to return the virtual screen dimensions" do
    dimensions = RAuto.screen_dimensions
    dimensions.should == {width: 1024,height: 768} #TODO my virtual screen size
  end
end

describe RAuto, "capture" do
	it "should allow multiple image_searches on one screen capture" do
		show_ie do
      result = RAuto.capture do |cap| 
				cap.image_search(File.join(File.dirname(__FILE__),"home-ie8-xp.png"))
			end
      
      result.should == {x: HOME_POSITION_X,y: HOME_POSITION_Y}
    end
	end
end

describe RAuto, "get_key_state" do
	it "should use GetKeyboardState to get the keys states"
end
