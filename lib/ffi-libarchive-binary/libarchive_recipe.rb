require "pathname"
require "open3"

require_relative "base_recipe"
require_relative "zlib_recipe"
require_relative "libexpat_recipe"
require_relative "openssl_recipe"
require_relative "xz_recipe"

module LibarchiveBinary
  FORMATS = {
    "arm64-apple-darwin" => "Mach-O 64-bit dynamically linked shared library arm64",
    "x86_64-apple-darwin" => "Mach-O 64-bit dynamically linked shared library x86_64",
    "aarch64-linux-gnu" => "ELF 64-bit LSB shared object, ARM aarch64",
    "x86_64-linux-gnu" => "ELF 64-bit LSB shared object, x86-64",
    "x86_64-w64-mingw32" => "PE32+ executable (DLL) (console) x86-64, for MS Windows",
  }.freeze

  class LibarchiveRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    attr_accessor :lib_filename

    def initialize
      super("libarchive", "3.6.1")

      @files << {
        url: "https://www.libarchive.org/downloads/libarchive-3.6.1.tar.gz",
        sha256: "c676146577d989189940f1959d9e3980d28513d74eedfbc6b7f15ea45fe54ee2",
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

    def configure_defaults
      [
        "--host=#{@host}",    "--disable-bsdtar", "--disable-bsdcat",
        "--disable-bsdcpio",  "--without-bz2lib", "--without-libb2",
        "--without-iconv",    "--without-lz4",    "--without-zstd",
        "--with-lzma",        "--without-cng",    "--without-xml2",
        "--with-expat",       "--with-openssl",   "--disable-acl"
      ]
    end

    def configure
      fl = apple_arch_flag(host)
      cmd = ["env", "CFLAGS=#{include_flags} #{fl}", "LDFLAGS=#{fl}",
             "./configure"] + computed_options
      execute("configure", cmd)

      if MiniPortile::windows?
        patch_makefile_windows
      else
        patch_makefile
      end
    end

    def include_flags
      paths = [@zlib_recipe.path, @expat_recipe.path, @openssl_recipe.path]
      paths.map { |k| "-I#{k}/include" }.join(" ")
    end

    def patch_makefile_windows
      llibz = File.join(@zlib_recipe.path, "lib")
      llibexpat = File.join(@expat_recipe.path, "lib")
      llibcrypto = File.join(@openssl_recipe.path, "lib")
      lliblzma = File.join(@xz_recipe.path, "lib")

      makefile = File.join(work_path, "Makefile")
      replace_in_file(" -lz ", " -L#{llibz} -Wl,-Bstatic,-lz ", makefile)
      replace_in_file(" -lexpat ", " -L#{llibexpat}  -Wl,-Bstatic,-lexpat ", makefile)
      replace_in_file(" -lcrypto ", " -L#{llibcrypto} -Wl,-Bstatic,-lcrypto ", makefile)
      replace_in_file(" -llzma ", " -L#{lliblzma} -Wl,-Bstatic,-llzma ", makefile)
    end

    def patch_makefile
      libz = File.join(@zlib_recipe.path, "lib", "libz.a")
      libexpat = File.join(@expat_recipe.path, "lib", "libexpat.a")
      libcrypto = File.join(@openssl_recipe.path, "lib", "libcrypto.a")
      liblzma = File.join(@xz_recipe.path, "lib", "liblzma.a")
      lliblzma = File.join(@xz_recipe.path, "lib")

      makefile = File.join(work_path, "Makefile")
      replace_in_file(" -lz ", " #{libz} ", makefile)
      replace_in_file(" -lexpat ", " #{libexpat} ", makefile)
      replace_in_file(" -lcrypto ", " #{libcrypto} ", makefile)
      replace_in_file(" -llzma ", " -L#{lliblzma} -l:liblzma.a ", makefile)  # #{liblzma}
    end

    def replace_in_file(search_str, replace_str, filename)
      puts "Replacing \"#{search_str}\" with \"#{replace_str}\" in #{filename}"

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

    def patch
      super

      FileUtils.cp(Dir.glob(ROOT.join("updates", "config.*").to_s),
                   File.join(work_path, "build", "autoconf"))
    end

    def install
      super

      libs = Dir.glob(File.join(port_path, "{lib,bin}", "*"))
        .grep(/\/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$/)
      FileUtils.cp_r(libs, lib_workpath, verbose: true)
      verify_lib
    end

    def lib_workpath
      @lib_workpath ||= ROOT.join("lib", "ffi-libarchive-binary")
    end

    def lib_fullpath
      @lib_fullpath ||= File.join(lib_workpath, lib_filename)
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
  end
end
