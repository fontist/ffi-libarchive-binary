require_relative "base_recipe"

module LibarchiveBinary
  class XZRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("xz", "5.2.4")

      @files << {
        url: "https://tukaani.org/xz/xz-5.2.4.tar.gz",
        sha256: "b512f3b726d3b37b6dc4c8570e137b9311e7552e8ccbab4d39d47ce5f4177145",
      }

      @target = ROOT.join(@target).to_s
    end

    def configure_defaults
      h = @host.eql?("arm64-apple-darwin") ? "aarch64-apple" : @host
      [
        "--host=#{h}",        "--disable-doc",      "--disable-xz",
        "--disable-xzdec",    "--disable-lzmadec",  "--disable-lzmainfo",
        "--disable-scripts",  "--disable-shared",   "--enable-static",
        "--with-pic"
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
