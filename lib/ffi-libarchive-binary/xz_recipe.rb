# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  class XZRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    # As of 19.10.2022
    #   versions > 5.2.4 get crazy on MinGW
    #   versions <= 5.2.5 do not support arm64-apple-darwin target
    #   version 5.2.7 could not be linked statically to libarchive

    def initialize
      if MiniPortile::windows?
        super("xz", "5.2.4")
        windows_files
      else
        super("xz", "5.2.6")
        not_windows_files
      end

      @target = ROOT.join(@target).to_s
    end

    def windows_files
      @files << {
        url: "https://tukaani.org/xz/xz-5.2.4.tar.gz",
        sha256: "b512f3b726d3b37b6dc4c8570e137b9311e7552e8ccbab4d39d47ce5f4177145",
      }
    end

    def not_windows_files
      @files << {
        url: "https://tukaani.org/xz/xz-5.2.6.tar.gz",
        sha256: "a2105abee17bcd2ebd15ced31b4f5eda6e17efd6b10f921a01cda4a44c91b3a0",
      }
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
