require 'dl/import'
require 'dl/types'
require 'dl/cparser'

module RAuto
  module Image
    extend DL::Importer
    dlload "CORE_RL_wand_" #make sure the dll imagemagick is installed version >= 6.4.5
    
    typealias "MagickBooleanType", "long"
    typealias "StorageType", "long"
    
    extern "void MagickWandGenesis()"
    extern "void MagickWandTerminus()"
    extern "MagickWand *NewMagickWand()"
    extern "MagickWand *DestroyMagickWand(MagickWand *wand)"
    extern "MagickBooleanType MagickReadImage(MagickWand *wand,const char *filename)"
    extern "MagickBooleanType MagickExportImagePixels(MagickWand *wand,long,long,unsigned long,unsigned long,char *,StorageType,void *)"
    extern "unsigned long MagickGetImageWidth(MagickWand *wand)"
    extern "unsigned long MagickGetImageHeight(MagickWand *wand)"
		extern "unsigned long MagickGetImageAlphaChannel(MagickWand *wand)"
    
    #MagickBooleanType enum
    MagickFalse = 0
    MagickTrue = 1
    
    #StorageType enum
    CharPixel = 1
    
    def self.pixel_data(file_path)
      self.MagickWandGenesis
      
      magick_wand = self.NewMagickWand
      
      pixel_data = nil
      if self.MagickReadImage(magick_wand,*[file_path].pack("p").unpack("l!*")) != MagickFalse
        width = self.MagickGetImageWidth(magick_wand)
        height = self.MagickGetImageHeight(magick_wand)
        
				if self.MagickGetImageAlphaChannel(magick_wand) != MagickFalse
					RAuto.log.debug "Alpha on!"
				else
					RAuto.log.debug "Alpha off!"
				end
				
        color_map = "BGRA"
        data_size = width*height*color_map.size
        pixel_ptr = CPtr.malloc(data_size)
        
        if self.MagickExportImagePixels(magick_wand,0,0,width,height,*[color_map].pack("p").unpack("l!*"),CharPixel,*[pixel_ptr.to_i].pack("l!").unpack("l!*")) != MagickFalse
          pixel_data = pixel_ptr.to_s(data_size)
        end
      end
      
      self.DestroyMagickWand(magick_wand)
      
      self.MagickWandTerminus
      
      return pixel_data,width,height
    end
  end
end
  