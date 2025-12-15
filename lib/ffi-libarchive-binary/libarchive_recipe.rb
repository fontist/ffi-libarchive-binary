# frozen_string_literal: true

require "pathname"
require "open3"

require_relative "configuration"
require_relative "base_recipe"
require_relative "zlib_recipe"
require_relative "libexpat_recipe"
require_relative "openssl_recipe"
require_relative "xz_recipe"

module LibarchiveBinary
  class LibarchiveRecipe < MiniPortileCMake
    ROOT = Pathname.new(File.expand_path("../..", __dir__))
    NAME = "libarchive"
    def initialize
      libarchive = LibarchiveBinary.library_for(NAME)
      super(NAME, libarchive["version"])
      @printed = {}

      @files << {
        url: libarchive["url"],
        sha256: libarchive["sha256"],
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
        "-DENABLE_EXPAT::BOOL=ON",    "-DENABLE_TAR:BOOL=OFF",        "-DENABLE_CPIO::BOOL=OFF",
        "-DENABLE_CAT:BOOL=OFF",      "-DENABLE_ACL:BOOL=OFF",        "-DENABLE_TEST:BOOL=OFF",
        "-DENABLE_UNZIP:BOOL=OFF",    "-DOPENSSL_USE_STATIC_LIBS=ON", "-DENABLE_XAR:BOOL=ON",

        # Provide root directories - let CMake find libraries in lib or lib64
        "-DOPENSSL_ROOT_DIR:PATH=#{@openssl_recipe.path}",

        # Add include paths to C flags so CMake's header detection can find them
        "-DCMAKE_C_FLAGS=-I#{@expat_recipe.path}/include -I#{@openssl_recipe.path}/include -I#{@xz_recipe.path}/include -I#{@zlib_recipe.path}/include",

        # Provide search paths for CMake to find libraries
        "-DCMAKE_INCLUDE_PATH:STRING=#{include_path}",
        "-DCMAKE_LIBRARY_PATH:STRING=#{library_path}"
      ]
    end

    def configure_defaults
      df = generator_flags + default_flags

      ar = ARCHS[host]
      df += ["-DCMAKE_OSX_ARCHITECTURES=#{ar}"] if ar

      df
    end

    def include_path
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path, @xz_recipe.path]
      paths.map { |k| "#{k}/include" }.join(";")
    end

    def library_path
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path, @xz_recipe.path]
      paths.map { |k| "#{k}/lib;#{k}/lib64" }.join(";")
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

      # Set explicit LZMA environment variables for libarchive configure
      ENV['LIBLZMA_CFLAGS'] = "-I#{@xz_recipe.path}/include"
      ENV['LIBLZMA_LIBS'] = "-L#{@xz_recipe.path}/lib -llzma"

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

    def libraries
      configuration_file = File.join(File.dirname(__FILE__), "..", "..", "ext", "configuration.yml")
      @libraries ||= ::YAML.load_file(configuration_file)["libraries"] || {}
    rescue Psych::SyntaxError => e
      puts "Warning: The configuration file '#{configuration_file}' contains invalid YAML syntax."
      puts e.message
      exit 1
    rescue StandardError => e
      puts "An unexpected error occurred while loading the configuration file '#{configuration_file}'."
      puts e.message
      exit 1
    end

    def library_for(libname)
      libraries[libname][MiniPortile::windows? ? "windows" : "all"]
    rescue StandardError => e
      puts "Failed to load library configuration for '#{libname}'."
      puts e.message
      exit 1
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
