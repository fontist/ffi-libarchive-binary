# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  OS_COMPILERS = {
    "arm64-apple-darwin" => "darwin64-arm64-cc",
    "x86_64-apple-darwin" => "darwin64-x86_64-cc",
    "aarch64-linux-gnu" => nil,
    "x86_64-linux-gnu" => nil,
    "x86_64-w64-mingw32" => "mingw64",
  }.freeze

  ENV_CMD = ["env", "CFLAGS=-fPIC", "LDFLAGS=-fPIC"].freeze

  class OpensslRecipe < BaseRecipe
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("openssl", MiniPortile::windows? ? "1.1.1w" : "3.3.2")

      @files << source_archive
      @target = ROOT.join(@target).to_s
    end

    def configure
      os_compiler = OS_COMPILERS[@host]
      common_opts = ["--openssldir=#{ROOT}/ports/SSL", "no-tests", "no-shared"] +
        computed_options.grep(/--prefix/)
      cmd = if os_compiler.nil?
              message("OpensslRecipe: guessing with 'config' for '#{@host}'\n")
              ENV_CMD + ["./config"] + common_opts
            else
              ENV_CMD + ["./Configure"] + common_opts + [os_compiler]
            end
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

    def source_archive
      if MiniPortile::windows?
        { url: "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz",
          sha256: "cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8" }
      else
        { url: "https://github.com/openssl/openssl/releases/download/openssl-3.3.2/openssl-3.3.2.tar.gz",
          sha256: "2e8a40b01979afe8be0bbfb3de5dc1c6709fedb46d6c89c10da114ab5fc3d281" }
      end
    end
  end
end
