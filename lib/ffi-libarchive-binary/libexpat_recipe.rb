# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class LibexpatRecipe < BaseRecipe
    def initialize
      super("libexpat")

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
