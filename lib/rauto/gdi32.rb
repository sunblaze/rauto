require 'dl/import'
require 'dl/types'
require 'dl/cparser'

module RAuto
  module GDI32
    extend DL::Importer
    dlload "Gdi32"
    include DL::Win32Types #add aliases for some common Win32Types
    include DL::CParser
    
    #new types unique to gdi32
    typealias "HBITMAP", "HANDLE"
    typealias "HGDIOBJ", "HANDLE"
    typealias "LPVOID", "void*"
    typealias "LPBITMAPINFO", "void*"
    typealias "LONG", "long"
    
    #Constants
    # Ternary raster operations
    SRCCOPY = 0x00CC0020 # dest = source
    
    # DIB color table identifiers
    DIB_RGB_COLORS = 0 # color table in RGBs
    
    extern "HDC CreateCompatibleDC(HDC)"
    extern "BOOL DeleteDC(HDC)"
    extern "HBITMAP CreateCompatibleBitmap(HDC,int,int)"
    extern "BOOL DeleteObject(HGDIOBJ)"
    extern "HGDIOBJ SelectObject(HDC,HGDIOBJ)"
    extern "BOOL BitBlt(HDC,int,int,int,int,HDC,int,int,DWORD)"
    extern "int GetDIBits(HDC,HBITMAP,UINT,UINT,LPVOID,LPBITMAPINFO,UINT)"
    
    def self.nested_struct
      @nest_types, @nest_members = [],[]
      yield
      DL::CStructBuilder.create(DL::CStruct, @nest_types, @nest_members)
    end
    
    def self.inline_struct(signature,accessor,array_size = nil)
      types, members = parse_struct_signature(signature, @type_alias)
      (array_size or 1).times do|i|
        renamed_members = members.map do|member|
          if array_size
            "#{accessor}[#{i}].#{member}"
          else
            "#{accessor}.#{member}"
          end
        end
        @nest_types += types
        @nest_members += renamed_members
      end
    end
    
    #Structs
    bitmapinfoheader_sig = [
      "DWORD  biSize",
      "LONG   biWidth",
      "LONG   biHeight", 
      "WORD   biPlanes", 
      "WORD   biBitCount", 
      "DWORD  biCompression", 
      "DWORD  biSizeImage", 
      "LONG   biXPelsPerMeter", 
      "LONG   biYPelsPerMeter", 
      "DWORD  biClrUsed", 
      "DWORD  biClrImportant"
    ]
    BITMAPINFOHEADER = struct(bitmapinfoheader_sig)
    
    rgbquad_sig = [
      "BYTE rgbBlue",
      "BYTE rgbGreen",
      "BYTE rgbRed",
      "BYTE rgbReserved"
    ]
    RGBQUAD = struct(rgbquad_sig)
    
    BITMAPINFO = nested_struct do
      inline_struct(bitmapinfoheader_sig,"bmiHeader")
      inline_struct(rgbquad_sig,"bmiColors",260)
    end
  end
end
