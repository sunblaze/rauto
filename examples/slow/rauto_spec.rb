require_relative "../../lib/rauto"

describe RAuto, "image_search" do
	it "should not have a memory leak" do
		1000.times do
			RAuto.image_search(File.join(File.dirname(__FILE__),"x-home.png"))
		end
	end
end
