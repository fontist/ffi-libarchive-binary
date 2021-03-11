# frozen_string_literal: true

require "ffi-libarchive-binary/version"
require "ffi"
require "pathname"

module LibarchiveBinary
  class Error < StandardError; end

  module LibraryPath
    LIBRARY_PATH = Pathname.new(File.join(__dir__, "ffi-libarchive-binary"))

    def ffi_lib(*names)
      prefixed = names.map do |name|
        paths = name.is_a?(Array) ? name : [name]
        paths.map { |x| LIBRARY_PATH.join(FFI::map_library_name(x)).to_s }
      end

      super(*(prefixed + names))
    end
  end

  ::FFI::Library.prepend(LibraryPath)
  require "ffi-libarchive"
end
