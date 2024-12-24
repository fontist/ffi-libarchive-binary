# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class XZRecipe < BaseRecipe
    def initialize
      super("xz")
    end

    def configure_defaults
      [
        "--host=#{@host}",
        "--disable-doc",      "--disable-xz",       "--with-pic",
        "--disable-xzdec",    "--disable-lzmadec",  "--disable-lzmainfo",
        "--disable-scripts",  "--disable-shared",   "--enable-static"
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
