require "mini_portile2"

module LibarchiveBinary
  class OpensslRecipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("openssl", "1.1.1n")

      @files << {
        url: "https://www.openssl.org/source/openssl-1.1.1n.tar.gz",
        sha256: "40dceb51a4f6a5275bde0e6bf20ef4b91bfc32ed57c0552e2e8e15463372b17a"
      }

      @target = ROOT.join(@target).to_s
    end

    def configure_defaults
      [
        "--host=#{@host}",
        "--disable-shared",
        "--enable-static",
      ]
    end

    def configure
      cmd = ["env", "CFLAGS=-fPIC", "LDFLAGS=-fPIC", "./configure"] + computed_options
      execute("configure", cmd)
    end

    def checkpoint
      File.join(@target, "#{self.name}-#{self.version}-#{self.host}.installed")
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
