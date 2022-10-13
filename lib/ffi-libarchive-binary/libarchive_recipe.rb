require "mini_portile2"
require "pathname"

require_relative "zlib_recipe"
require_relative "libexpat_recipe"
require_relative "openssl_recipe"

module LibarchiveBinary
  class LibarchiveRecipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libarchive", "3.6.1")

      @files << {
        url: "https://www.libarchive.org/downloads/libarchive-3.6.1.tar.gz",          # rubocop:disable Layout/LineLength
        sha256: "c676146577d989189940f1959d9e3980d28513d74eedfbc6b7f15ea45fe54ee2",   # rubocop:disable Layout/LineLength
      }

      @zlib_recipe = ZLibRecipe.new
      @expat_recipe = LibexpatRecipe.new
      @openssl_recipe = OpensslRecipe.new

      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def configure_defaults
      [
        "--host=#{@host}",    "--disable-bsdtar", "--disable-bsdcat",
        "--disable-bsdcpio",  "--without-bz2lib", "--without-libb2",
        "--without-iconv",    "--without-lz4",    "--without-zstd",
        "--without-lzma",     "--without-cng",    "--without-xml2",
        "--with-expat",       "--with-openssl",   "--disable-acl"
      ]
    end

    def configure
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path]
      cflags = paths.map { |k| "-I#{k}/include" }.join(" ")
      cmd = ["env", "CFLAGS=#{cflags}", "./configure"] + computed_options

      execute("configure", cmd)

      # drop default libexpat and zlib
      libz = File.join(@zlib_recipe.path, "lib", "libz.a")
      libexpat = File.join(@expat_recipe.path, "lib", "libexpat.a")
      openssl = File.join(@openssl_recipe.path, "lib", "libcrypto.a")

      if LibarchiveBinary::windows?
        # https://stackoverflow.com/a/14112368/902217
        static_link_pref = "-Wl,-Bstatic,"
        libz.prepend(static_link_pref)
        libexpat.prepend(static_link_pref)
      end

      makefile = File.join(work_path, "Makefile")
      replace_in_file(" -lz ", " #{libz} ", makefile)
      replace_in_file(" -lexpat ", " #{libexpat} ", makefile)
      replace_in_file(" -lcrypto ", " #{openssl} ", makefile)
    end

    def replace_in_file(search_str, replace_str, filename)
      puts "Replace \"#{search_str}\" with \"#{replace_str}\" in #{filename}"

      fc = File.open(filename, "r")
      content = fc.read
      fc.close

      content.gsub!(search_str, replace_str)

      File.open(filename, "w") { |f| f << content }
    end

    def activate
      @zlib_recipe.activate
      @expat_recipe.activate
      @openssl_recipe.activate

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

      super

      FileUtils.touch(checkpoint)
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
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
      FileUtils.cp_r(libs, ROOT.join("lib", "ffi-libarchive-binary"),
                     verbose: true)
    end

    def message(text)
      return super unless text.start_with?("\rDownloading")

      match = text.match(/(\rDownloading .*)\(\s*\d+%\)/)
      pattern = match ? match[1] : text
      return if @printed[pattern]

      @printed[pattern] = true
      super
    end
  end
end
