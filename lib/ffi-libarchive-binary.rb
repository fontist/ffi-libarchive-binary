# frozen_string_literal: true

require "ffi-libarchive-binary/version"
require "pathname"

module LibarchiveBinary
  class Error < StandardError; end

  LIBRARY_PATH = Pathname.new(File.join(__dir__, "ffi-libarchive-binary"))
end

module Archive
  module C
    def self.ffi_lib(*args)
      prefixed = args.map do |names|
        filenames = names.is_a?(Array) ? names : [names]
        with_path = filenames.map(&:to_s).map do |filename|
          LibarchiveBinary::LIBRARY_PATH.join(FFI.map_library_name(filename)).to_s
        end

        with_path + filenames
      end

      super(*prefixed)
    end
  end
end

require "ffi-libarchive"
