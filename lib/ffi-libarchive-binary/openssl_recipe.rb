require "mini_portile2"

module LibarchiveBinary
  class OpensslRecipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("openssl", "1.1.1n")

      @files << {
        url: "https://www.openssl.org/source/openssl-1.1.1n.tar.gz",                  # rubocop:disable Layout/LineLength
        sha256: "40dceb51a4f6a5275bde0e6bf20ef4b91bfc32ed57c0552e2e8e15463372b17a",   # rubocop:disable Layout/LineLength
      }

      @target = ROOT.join(@target).to_s
    end

    def configure
      cmd = ["env", "CFLAGS=-fPIC", "LDFLAGS=-fPIC",
             "./config"] + computed_options.grep(/--prefix/)
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
