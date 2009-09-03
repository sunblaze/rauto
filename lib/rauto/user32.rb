require 'dl/import'
require 'dl/types'

module RAuto
  module User32
    extend DL::Importer
    dlload "user32"
    include DL::Win32Types #add aliases for some common Win32Types
    
	#Input Types
	INPUT_MOUSE = 0
	INPUT_KEYBOARD = 1
	#Mouse Flags
	MOUSEEVENTF_MOVE = 1
	MOUSEEVENTF_ABSOLUTE = 32768
	MOUSEEVENTF_LEFTDOWN = 2
	MOUSEEVENTF_LEFTUP = 4
	
	typealias "LPINPUT", "void*"
	typealias "LPPOINT", "void*"
	
    extern "HDC GetDC(HWND)"
    extern "int ReleaseDC(HWND, HDC)"
    extern "int GetSystemMetrics(int)"
		extern "UINT SendInput(UINT,LPINPUT,int)"
		extern "BOOL GetCursorPos(LPPOINT)"
  end
end
