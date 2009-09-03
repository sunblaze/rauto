require_relative 'rauto/user32'
require_relative 'rauto/gdi32'
require_relative 'rauto/image'

require 'logger'

module RAuto
  NULL = 0
  COLOUR_BYTE_COUNT = 4
	
	class CPtr < DL::CPtr
		RUBY_FREE = DL::CFunc.new(DL::RUBY_FREE)
		def self.malloc(size,free = RUBY_FREE)
			super(size,free)
		end
	end
  
  def self.log(level = Logger::DEBUG)
    unless @log
      @log = Logger.new("rauto.log")
      started_logger = true
    end
    @log.level = level
    @log.datetime_format = "%Y-%m-%d %I:%M:%S%P"
    log.info "RAuto Logger Started" if started_logger
    @log
  end
  
  IMAGE_SEARCH_OPTIONS = {:within_shades => false}
  
  def self.image_search(image_path,*args)
    options = extract_options(args)
    options ||= IMAGE_SEARCH_OPTIONS
		capture(options) do |cap|
			cap.image_search(image_path,options)
		end
  end
  
  def self.screen_dimensions
    {width: User32.GetSystemMetrics(78),height: User32.GetSystemMetrics(79)}
  end
  
  # not used, I kept it in the file as reference
  def self.slow_find(screen_data,screen_width,screen_height,file_data, file_width, file_height,within_shades = nil)
    matching_pixels = 0
    (screen_height-file_height).times do |s_y|
      (screen_width-file_width).times do |s_x|
        #log.info "#{screen_data[((s_x+(matching_pixels % screen_width)) + (s_y+(matching_pixels / screen_width)) * screen_width) * 4,3]} #{file_data[matching_pixels * 4,3]}"
        # skip 4th data element since it's the alpha or reserved pixel
        while screen_data[((s_x+(matching_pixels % file_width)) + (s_y+(matching_pixels / file_height)) * screen_width) * 4,3] == file_data[matching_pixels * 4,3]
          matching_pixels += 1
          if matching_pixels == file_width * file_height
            return {x: s_x,y: s_y}
          end
        end
        matching_pixels = 0
      end
    end
    nil
  end
  
  def self.find(screen_data,screen_width,screen_height,file_data, file_width, file_height,within_shades = nil)
    start = Time.now
    file_regex = []
    file_height.times do|y|
      file_regex << Regexp.new(file_data[y*file_width*4,file_width*4].gsub(/(.)(.)(.)(.)/m){
				if within_shades or ($4 != "\x00" and $4 != "\xFF")
					if within_shades
						diff = within_shades
					else
						diff = 255 - $4.ord
					end
					"[#{Regexp.escape([$1.ord-diff,0].max.chr)}-#{Regexp.escape([$1.ord+diff,255].min.chr)}][#{Regexp.escape([$2.ord-diff,0].max.chr)}-#{Regexp.escape([$2.ord+diff,255].min.chr)}][#{Regexp.escape([$3.ord-diff,0].max.chr)}-#{Regexp.escape([$3.ord+diff,255].min.chr)}]."
				elsif $4 == "\x00"
					"...."
				else
					"#{Regexp.escape($1+$2+$3)}."
				end
			}, Regexp::MULTILINE)
    end
    log.info "find.regex:#{Time.now - start}"
    
		log.debug "file_regex:"+file_regex.inspect
	
    start = Time.now
    offset = 0
    while byte_pos = screen_data.index(file_regex[0],offset)
			x_position = (byte_pos/4) % screen_width
			log.debug "found first line at:#{x_position}"
			if x_position <= screen_width - file_width #check for file cliping with the edge of the screen
				if file_height == 1
					return {x: (byte_pos/4)%screen_width,y: (byte_pos/4)/screen_width}
				end
			
				#matched the first line of pixels from the image, now match the rest
				matching_line = 1
				while pos = screen_data.index(file_regex[matching_line],byte_pos+(screen_width*4)*matching_line) and
							pos == byte_pos+(screen_width*4)*matching_line
					matching_line += 1
					if matching_line == file_height
						log.info "find.while:#{Time.now - start}"
						return {x: (byte_pos/4)%screen_width,y: (byte_pos/4)/screen_width}
					end
				end
				if pos
					offset = pos - (screen_width*4)*matching_line
				else
					return nil
				end
			else
				offset = byte_pos + (screen_width-x_position) * 4
			end
    end
    log.info "find.while:#{Time.now - start}"
    nil
  end
  
  def self.fast_find(screen_data,screen_width,screen_height,file_data, file_width, file_height,within_shades = nil)
    start = Time.now
    location = nil
    if file_width <= screen_width and file_height <= screen_height
      
      file_regex = ""
			log.debug "screen_width,file_width:" + [screen_width,file_width].join(",")
      file_height.times do|y|
				file_regex << ".{#{(screen_width-file_width)*COLOUR_BYTE_COUNT}}" if file_regex.length > 0
				row_regex = file_data[y*file_width*COLOUR_BYTE_COUNT,file_width*COLOUR_BYTE_COUNT]
				row_regex.gsub!(/(...)(.)/m) do
					if $2 == "\x00"
						"...."
					elsif $2 == "\xFF"
						"#{Regexp.escape($1)}."
					else
						"...."
					end
				end
        file_regex << row_regex
      end

	  # The MULTILINE flag has to be used for the . in my regexp to be able to match all characters (including newline characters)
	  # Took me a while to figure this out...
      file_regex = Regexp.new(file_regex, Regexp::MULTILINE)
			log.debug "file_regex:#{file_regex.inspect}"
      log.info "find.regex:#{Time.now - start}"
      
      start = Time.now
      if byte_pos = screen_data.index(file_regex)
				log.debug "found!"
        location = {x: (byte_pos/COLOUR_BYTE_COUNT)%screen_width,y: (byte_pos/COLOUR_BYTE_COUNT)/screen_width}
      end
      log.info "find.index:#{Time.now - start}"
    end
    location
  end
	
	def self.mouse_position
		point_struct = "l! #LONG,
										l! #LONG"
		point = [0, #x pos
						 0, #y pos
		].pack(point_struct)
		if User32.GetCursorPos(point) != 0
			pos = point.unpack(point_struct)
			{x: pos[0], y: pos[1]}
		else
			nil
		end
	end
	
	MOUSE_INPUT_STRUCT = "L! #DWORD,
					l! #LONG,
				l! #LONG,
				L! #DWORD,
				L! #DWORD,
				L! #DWORD,
				L! #ULONG_PTR"
	
	def self.simple_click_mouse
		input = [User32::INPUT_MOUSE, # specify the input type
			0, # dx; the relative move distance for x axis
			0, # dx; the relative move distance for y axis
			0,  # mouseData(not used)
			User32::MOUSEEVENTF_LEFTDOWN | User32::MOUSEEVENTF_LEFTUP, # dwFlags; perform a move
			0,  # time (not used)
			0,  # dwExtraInfo (not used)
		].pack(MOUSE_INPUT_STRUCT)
		
		if User32.SendInput(1,input,28) != 0
			mouse_position
		else
			nil
		end
	end

	def self.coordToAbs(coord,width_or_height)
		(((65536 * coord) / width_or_height) + 1)
	end
	
	# Absolute position mouse move
	def self.simple_move_mouse(x,y)
		absX = coordToAbs(x,screen_dimensions[:width])
		absY = coordToAbs(y,screen_dimensions[:height])
	
		input = [User32::INPUT_MOUSE, # specify the input type
			absX, # dx; the relative move distance for x axis
			absY, # dx; the relative move distance for y axis
			0,  # mouseData(not used)
			User32::MOUSEEVENTF_MOVE | User32::MOUSEEVENTF_ABSOLUTE, # dwFlags; perform a move
			0,  # time (not used)
			0,  # dwExtraInfo (not used)
		].pack(MOUSE_INPUT_STRUCT)
		
		if User32.SendInput(1,input,28) != 0
			mouse_position
		else
			nil
		end
	end
	
	def self.extract_options(args)
		Hash.try_convert(args.last)
	end
	
	MOVE_MOUSE_DEFAULTS = {relative: false}
	
	def self.move_mouse(*args)
		options = extract_options(args)
		options ||= MOVE_MOUSE_DEFAULTS
		options = options.merge({x: args[0],y: args[1]}) if args.length > 1
		
		if options[:relative]
			pos = mouse_position
			x,y = options[:x] + pos[:x],options[:y] + pos[:y]
			simple_move_mouse(x,y)
		else
			simple_move_mouse(options[:x],options[:y])
		end
	end
	
	def self.click_mouse(*args)
		if args.length > 0
			move_mouse(*args)
		end
		simple_click_mouse
	end
	
	class Capture
		def initialize(screen_data,screen_width,screen_height)
			@screen_data,@screen_width,@screen_height = screen_data,screen_width,screen_height
		end
		
		def image_search(image_path,*args)
			options = RAuto::extract_options(args)
			options ||= IMAGE_SEARCH_OPTIONS
			position = nil
			
			file_data, file_width, file_height = Image.pixel_data(image_path)
			if file_data
				position = RAuto::find(@screen_data,@screen_width,@screen_height,file_data, file_width, file_height,options[:within_shades])
			end
			position
		end
	end
	
	def self.capture(*args)
		options = extract_options(args)
		options ||= IMAGE_SEARCH_OPTIONS
		rect_options = options[:rect] || {x: 0, y: 0, width: 100_000_000, height: 100_000_000}
    
		hdc = User32.GetDC(0)
		sdc = GDI32.CreateCompatibleDC(hdc)
		
		screen_width,screen_height = RAuto::screen_dimensions[:width],RAuto::screen_dimensions[:height]
    
		rect_options[:x] = [[screen_width,rect_options[:x]].min,0].max
		rect_options[:y] = [[screen_height,rect_options[:y]].min,0].max
		rect_options[:width] = [[screen_width-rect_options[:x],rect_options[:width]].min,0].max
		rect_options[:height] = [[screen_height-rect_options[:y],rect_options[:height]].min,0].max
    
		ddb = GDI32.CreateCompatibleBitmap(hdc,rect_options[:width],rect_options[:height])
		
		GDI32.SelectObject(sdc,ddb)
		GDI32.BitBlt(sdc, 0, 0, rect_options[:width], rect_options[:height], hdc, rect_options[:x], rect_options[:y], GDI32::SRCCOPY)
		
		bitmapinfo_ptr = CPtr.malloc(GDI32::BITMAPINFO.size)
		bitmapinfo = GDI32::BITMAPINFO.new(bitmapinfo_ptr)
		bitmapinfo.to_ptr['bmiHeader.biSize'] = GDI32::BITMAPINFOHEADER.size;
		bitmapinfo.to_ptr['bmiHeader.biBitCount'] = 0;
		
		GDI32.GetDIBits(sdc,ddb,0,0,NULL,bitmapinfo,GDI32::DIB_RGB_COLORS)
		
		pixel_count = rect_options[:width] * rect_options[:height]
		pixel_buffer = CPtr.malloc(pixel_count * GDI32.sizeof("DWORD"))
		
		bitmapinfo.to_ptr['bmiHeader.biHeight'] *= -1
		GDI32.GetDIBits(sdc,ddb,0,rect_options[:height],pixel_buffer,bitmapinfo,GDI32::DIB_RGB_COLORS)
		
		screen_data = pixel_buffer.to_s(pixel_count * GDI32.sizeof("DWORD"))
		
		results = yield(Capture.new(screen_data,rect_options[:width],rect_options[:height]))
		
		#clean up
		GDI32.DeleteObject(ddb)
		GDI32.DeleteDC(sdc)
		User32.ReleaseDC(0,hdc)
		results
	end
end