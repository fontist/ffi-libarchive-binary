require "mini_portile2"

module LibarchiveBinary
  # based on 
  class LibexpatRecipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("libexpat", "2.4.1")

      @files << {
        url: "https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.gz",
        sha256: "a00ae8a6b96b63a3910ddc1100b1a7ef50dc26dceb65ced18ded31ab392f132b"
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
