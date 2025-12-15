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
