# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class LibexpatRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libexpat", "2.6.4")

      @files << {
        url: "https://github.com/libexpat/libexpat/releases/download/R_2_6_4/expat-2.6.4.tar.gz",
        sha256: "fd03b7172b3bd7427a3e7a812063f74754f24542429b634e0db6511b53fb2278",
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
