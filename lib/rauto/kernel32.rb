require 'dl/import'
require 'dl/types'

module RAuto
  module Kernel32
    extend DL::Importer
    dlload "Kernel32.dll"
    include DL::Win32Types #add aliases for some common Win32Types
    
    extern "DWORD GetLastError()"
  end
end
