# frozen_string_literal: true

require "mini_portile2"
require_relative "configuration"

module LibarchiveBinary
  FORMATS = {
    "arm64-apple-darwin" => "Mach-O 64-bit dynamically linked shared library arm64",
    "x86_64-apple-darwin" => "Mach-O 64-bit dynamically linked shared library x86_64",
    "aarch64-linux-gnu" => "ELF 64-bit LSB shared object, ARM aarch64",
    "x86_64-linux-gnu" => "ELF 64-bit LSB shared object, x86-64",
    "x86_64-w64-mingw32" => "PE32+ executable",
    "aarch64-w64-mingw32" => "PE32+ executable",
  }.freeze

  ARCHS = {
    "arm64-apple-darwin" => "arm64",
    "x86_64-apple-darwin" => "x86_64",
  }.freeze

  LIBNAMES = {
    "x86_64-w64-mingw32" => "libarchive.dll",
    "aarch64-w64-mingw32" => "libarchive.dll",
    "x86_64-linux-gnu" => "libarchive.so",
    "aarch64-linux-gnu" => "libarchive.so",
    "x86_64-apple-darwin" => "libarchive.dylib",
    "arm64-apple-darwin" => "libarchive.dylib",
  }.freeze

  ROOT = Pathname.new(File.expand_path("../..", __dir__))

  class BaseRecipe < MiniPortile
    def initialize(name)
      library = LibarchiveBinary.library_for(name)
      version = library["version"]
      super(name, version)
      @target = ROOT.join(@target).to_s
      @files << {
        url: library["url"],
        sha256: library["sha256"],
      }
      @printed = {}
    end

    def apple_arch_flag(host)
      fl = ARCHS[host]
      fl.nil? ? "" : " -arch #{fl}"
    end

    def cflags(host)
      "CFLAGS=-fPIC#{apple_arch_flag(host)}"
    end

    def ldflags(host)
      "LDFLAGS=-fPIC#{apple_arch_flag(host)}"
    end

    def cross_compiler_env(host)
      # For aarch64 cross-compilation, set the compiler
      return {} unless host&.start_with?("aarch64")

      if host == "aarch64-linux-gnu" || host == "aarch64-linux-musl"
        # Note: We use aarch64-linux-gnu-gcc for both glibc and musl targets because:
        # 1. We build static libraries (.a files) which are libc-agnostic
        # 2. The compiler generates aarch64 machine code (architecture-specific)
        # 3. glibc vs musl only matters for dynamic linking at runtime
        # 4. Our static libs link into libarchive.so which links to the target libc
        {
          "CC" => "aarch64-linux-gnu-gcc",
          "CXX" => "aarch64-linux-gnu-g++",
          "AR" => "aarch64-linux-gnu-ar",
          "RANLIB" => "aarch64-linux-gnu-ranlib",
          "STRIP" => "aarch64-linux-gnu-strip",
        }
      elsif host == "aarch64-w64-mingw32"
        # For Windows ARM64 cross-compilation, use regular clang with explicit target
        # Not clang-cl because configure scripts don't recognize it as a C99 compiler
        {
          "CC" => "clang -target aarch64-w64-mingw32",
          "CXX" => "clang++ -target aarch64-w64-mingw32",
          "AR" => "ar",
          "RANLIB" => "ranlib",
          "NM" => "nm",
          # Put all windres flags in RC to prevent OpenSSL from appending --target=pe-x86-64
          # OpenSSL's mingw64 target adds --target=pe-x86-64 which must be the LAST flag
          "RC" => "windres",
        }
      else
        {}
      end
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
