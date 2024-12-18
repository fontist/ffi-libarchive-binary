# frozen_string_literal: true

require "pathname"
require "open3"

require_relative "base_recipe"
require_relative "zlib_recipe"
require_relative "libexpat_recipe"
require_relative "openssl_recipe"
require_relative "xz_recipe"

module LibarchiveBinary
  class LibarchiveRecipe < MiniPortileCMake
    ROOT = Pathname.new(File.expand_path("../..", __dir__))
    #
    # libarchive 3.7.x uses new GLIBC packaging ( links to libc only and not to pthread, dl, ...)
    # this does not link work on Ubuntu 20 with GLIBC 3.21
    #
    # Cannot build 3.7.x on Ubuntu 22 either because it creates a reference to GLIB 3.22 (min) that does
    # not resolve on Ubuntu 20
    #
    # So without patching we are stick to 3.6.2 until Ubuntu 20 shall be supported
    #
    def initialize
      super("libarchive", "3.6.2")
      @printed = {}

      @files << {
        url: "https://www.libarchive.org/downloads/libarchive-3.6.2.tar.gz",
        sha256: "ba6d02f15ba04aba9c23fd5f236bb234eab9d5209e95d1c4df85c44d5f19b9b3",
      }

      @target = ROOT.join(@target).to_s

      create_dependencies
    end

    def create_dependencies
      @zlib_recipe = ZLibRecipe.new
      @expat_recipe = LibexpatRecipe.new
      @openssl_recipe = OpensslRecipe.new
      @xz_recipe = XZRecipe.new
    end

    def generator_flags
      MiniPortile::mingw? ? ["-G", "MSYS Makefiles"] : []
    end

    def default_flags
      [
        "-DENABLE_OPENSSL:BOOL=ON",   "-DENABLE_LIBB2:BOOL=OFF",      "-DENABLE_LZ4:BOOL=OFF",
        "-DENABLE_LZO::BOOL=OFF",     "-DENABLE_LZMA:BOOL=ON",        "-DENABLE_ZSTD:BOOL=OFF",
        "-DENABLE_ZLIB::BOOL=ON",     "-DENABLE_BZip2:BOOL=OFF",      "-DENABLE_LIBXML2:BOOL=OFF",
        "-DENABLE_EXPAT::BOOL=ON",    "-DENABLE_TAR:BOOL=OFF",        "-DENABLE_ICONV::BOOL=OFF",
        "-DENABLE_CPIO::BOOL=OFF",    "-DENABLE_CAT:BOOL=OFF",        "-DENABLE_ACL:BOOL=OFF",
        "-DENABLE_TEST:BOOL=OFF",     "-DENABLE_UNZIP:BOOL=OFF",
        "-DCMAKE_INCLUDE_PATH=#{include_path}",
        "-DCMAKE_LIBRARY_PATH=#{library_path}"
      ]
    end

    def configure_defaults
      df = generator_flags + default_flags
      ar = ARCHS[host]
      if ar.nil?
        df
      else
        df + ["-DCMAKE_OSX_ARCHITECTURES=#{ar}"]
      end
    end

    def include_path
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path, @xz_recipe.path]
      paths.map { |k| "#{k}/include" }.join(";")
    end

    def library_path
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path, @xz_recipe.path]
      paths.map { |k| "#{k}/lib" }.join(";")
    end

    def activate
      @zlib_recipe.activate
      @expat_recipe.activate
      @openssl_recipe.activate
      @xz_recipe.activate

      super
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      @zlib_recipe.host = @host if @host
      @zlib_recipe.cook_if_not

      @expat_recipe.host = @host if @host
      @expat_recipe.cook_if_not

      @openssl_recipe.host = @host if @host
      @openssl_recipe.cook_if_not

      @xz_recipe.host = @host if @host
      @xz_recipe.cook_if_not

      super

      FileUtils.touch(checkpoint)
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def install
      super

      libs = Dir.glob(File.join(port_path, "{lib,bin}", "*"))
        .grep(/\/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$/)
      FileUtils.cp_r(libs, lib_workpath, verbose: true)
      if lib_fullpath.nil?
        message("Cannot guess libarchive library name, skipping format verification")
      else
        verify_lib
      end
    end

    def lib_workpath
      @lib_workpath ||= ROOT.join("lib", "ffi-libarchive-binary")
    end

    def lib_fullpath
      lib_filename = LIBNAMES[@host]
      @lib_fullpath ||= lib_filename.nil? ? nil : File.join(lib_workpath, lib_filename)
    end

    def verify_lib
      begin
        out, = Open3.capture2("file #{lib_fullpath}")
      rescue StandardError
        message("failed to call file, library verification skipped.\n")
        return
      end
      unless out.include?(target_format)
        raise "Invalid file format '#{out.strip}', '#{target_format}' expected"
      end

      message("#{lib_fullpath} format has been verified (#{target_format})\n")
    end

    def target_format
      @target_format ||= FORMATS[@host].nil? ? "skip" : FORMATS[@host]
    end

    def message(text)
      return super unless text.start_with?("\rDownloading")

      match = text.match(/(\rDownloading .*)\((\s*)(\d+)%\)/)
      pattern = match ? match[1] : text
      return if @printed[pattern] && match[3].to_i != 100

      @printed[pattern] = true
      super
    end
  end
end
