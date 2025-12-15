# frozen_string_literal: true

require_relative "base_recipe"

module LibarchiveBinary
  OS_COMPILERS = {
    "arm64-apple-darwin" => "darwin64-arm64-cc",
    "x86_64-apple-darwin" => "darwin64-x86_64-cc",
    "aarch64-linux-gnu" => "linux-aarch64",
    "aarch64-linux-musl" => "linux-aarch64",
    "x86_64-linux-gnu" => nil,
    "x86_64-linux-musl" => nil,
    "x86_64-w64-mingw32" => "mingw64",
    # Future: Windows ARM64 support (commented out due to OpenSSL build system incompatibility)
    # "aarch64-w64-mingw32" => "VC-CLANG-WIN64-CLANGASM-ARM",
  }.freeze

  ENV_CMD = ["env", "CFLAGS=-fPIC", "LDFLAGS=-fPIC"].freeze

  class OpensslRecipe < BaseRecipe
    def initialize
      super("openssl")
    end

    def configure
      os_compiler = OS_COMPILERS[@host]
      common_opts = ["--openssldir=#{ROOT}/ports/SSL", "--libdir=lib", "no-tests", "no-shared"] +
        computed_options.grep(/--prefix/)

      # Set cross-compiler environment variables for aarch64
      env_vars = cross_compiler_env(@host)
      env_prefix = env_vars.empty? ? ENV_CMD : ENV_CMD + env_vars.map { |k, v| "#{k}=#{v}" }

      cmd = if os_compiler.nil?
              message("OpensslRecipe: guessing with 'config' for '#{@host}'\n")
              env_prefix + ["./config"] + common_opts
            else
              env_prefix + ["./Configure"] + common_opts + [os_compiler]
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
  end
end
