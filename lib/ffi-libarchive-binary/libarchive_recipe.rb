require "mini_portile2"
require "pathname"

require_relative "zlib_recipe"
require_relative "libexpat_recipe"

module LibarchiveBinary
  class LibarchiveRecipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libarchive", "3.5.1")

      @files << {
        url: "https://www.libarchive.org/downloads/libarchive-3.5.1.tar.gz",
        sha256: "9015d109ec00bb9ae1a384b172bf2fc1dff41e2c66e5a9eeddf933af9db37f5a"
      }

      @zlib_recipe = ZLibRecipe.new
      @expat_recipe = LibexpatRecipe.new

      @target = ROOT.join(@target).to_s
    end

    def configure_defaults
      [
        "--host=#{@host}",
        "--disable-bsdtar",
        "--disable-bsdcat",
        "--disable-bsdcpio",
        "--without-bz2lib",
        "--without-libb2",
        "--without-iconv",
        "--without-lz4",
        "--without-zstd",
        "--without-lzma",
        "--without-cng",
        "--without-xml2",
        "--with-expat",
        "--with-openssl",
        "--disable-acl",
      ]
    end

    def configure
      paths = [@zlib_recipe.path, @expat_recipe.path]
      cflags = paths.map { |k| "-I#{k}/include" }.join(" ")
      libs = [File.join(@zlib_recipe.path, "lib", "libz.a"),
              File.join(@expat_recipe.path, "lib", "libexpat.a")].join(" ")
      cmd = ["env", "CFLAGS=#{cflags}", "LIBS=#{libs}", "./configure"] + configure_defaults + [configure_prefix]

      execute("configure", cmd)

      # drop default libexpat and zlib
      replace_in_file("LIBS = -lexpat -lz ", "LIBS = ", File.join(work_path, "Makefile"))
    end

    def replace_in_file(searchString, replaceString, fileName)
      aFile = File.open(fileName, "r")
      aString = aFile.read
      aFile.close

      aString.gsub!(searchString, replaceString)

      File.open(fileName, "w") { |file| file << aString }
    end

    def activate
      @zlib_recipe.activate
      @expat_recipe.activate

      super
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      @zlib_recipe.cook_if_not
      @expat_recipe.cook_if_not

      super

      FileUtils.touch(checkpoint)
    end

    def checkpoint
      File.join(@target, "#{self.name}-#{self.version}-#{self.host}.installed")
    end

    def patch
      super

      FileUtils.cp(Dir.glob(ROOT.join("updates", "config.*").to_s),
                   File.join(work_path, "build", "autoconf"))
    end

    def install
      super

      libs = Dir.glob(File.join(port_path, "{lib,bin}", "*"))
        .grep(/\/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$/)
      FileUtils.cp_r(libs, ROOT.join("lib", "ffi-libarchive-binary"), verbose: true)
    end
  end
end
