# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class Libxml2Recipe < BaseRecipe
    def initialize
      super("libxml2")

      @target = ROOT.join(@target).to_s
    end

    def configure_defaults
      [
        "--host=#{@host}",
        "--disable-dependency-tracking",
        "--without-python",
        "--without-lzma",
        "--without-zlib",
        "--without-iconv",
        "--without-icu",
        "--without-debug",
        "--without-threads",
        "--without-modules",
        "--without-catalog",
        "--without-docbook",
        "--without-legacy",
        "--without-http",
        "--without-ftp",
        "--enable-static",
        "--disable-shared"
      ]
    end

    def configure
      cmd = ["env", cflags(host), ldflags(host),
             "./configure"] + computed_options
      execute("configure", cmd)
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      super

      FileUtils.touch(checkpoint)
    end
  end
end