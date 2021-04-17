# frozen_string_literal: true

require "ffi-libarchive-binary/version"
require "pathname"

module LibarchiveBinary
  class Error < StandardError; end

  LIBRARY_PATH = Pathname.new(File.join(__dir__, "ffi-libarchive-binary"))

  def self.lib_path
    LIBRARY_PATH.join(lib_filename).to_s
  end

  def self.lib_filename
    if FFI::Platform.windows?
      "libarchive-13.dll"
    elsif FFI::Platform.mac?
      "libarchive.dylib"
    else
      "libarchive.so"
    end
  end
end

module Archive
  module C
    def self.ffi_lib(*args)
      prefixed = args.map do |names|
        paths = names.is_a?(Array) ? names : [names]
        if paths.any? { |f| f.include?("libarchive") }
          [LibarchiveBinary.lib_path] + paths
        else
          names
        end
      end

      super(*prefixed)
    end
  end
end

require "ffi-libarchive"
