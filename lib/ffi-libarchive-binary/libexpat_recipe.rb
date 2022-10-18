# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class LibexpatRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libexpat", "2.4.9")

      @files << {
        url: "https://github.com/libexpat/libexpat/releases/download/R_2_4_9/expat-2.4.9.tar.gz",
        sha256: "4415710268555b32c4e5ab06a583bea9fec8ff89333b218b70b43d4ca10e38fa",
      }

      @target = ROOT.join(@target).to_s
    end

    def configure_defaults
      [
        "--host=#{@host}",        "--disable-shared", "--enable-static",
        "--without-tests",        "--without-examples"
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
