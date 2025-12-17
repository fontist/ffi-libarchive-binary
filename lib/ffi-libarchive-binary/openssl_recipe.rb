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
    # Use mingw64 target for Windows ARM64 with clang and explicit CFLAGS
    # This prevents OpenSSL from adding -m64 flag which would create x86_64 objects
    "aarch64-w64-mingw32" => "mingw64",
  }.freeze

  ENV_CMD = ["env", "CFLAGS=-fPIC", "LDFLAGS=-fPIC"].freeze

  class OpensslRecipe < BaseRecipe
    def initialize
      super("openssl")
    end

    def configure
      os_compiler = OS_COMPILERS[@host]
      common_opts = ["--openssldir=#{ROOT}/ports/SSL", "--libdir=lib", "no-tests", "no-shared", "no-docs"] +
        computed_options.grep(/--prefix/)

      # For Windows ARM64, set CFLAGS=-fPIC first to prevent OpenSSL from adding -m64
      # The mingw64 target unconditionally adds -m64 which breaks ARM64 cross-compilation
      common_opts.unshift("CFLAGS=-fPIC") if @host == "aarch64-w64-mingw32"

      # Disable assembly for ARM64 as x86_64-specific instructions (AVX512, etc.) won't work
      common_opts << "no-asm" if @host == "aarch64-w64-mingw32"

      # Disable module loading for Windows ARM64 to avoid resource file compilation
      # The resource compiler (llvm-rc) can't find Windows SDK headers like winver.h
      common_opts << "no-module" if @host == "aarch64-w64-mingw32"

      # Disable command-line apps for Windows ARM64 to avoid resource file compilation
      # The apps/openssl.rc also requires Windows SDK headers which llvm-rc can't find
      common_opts << "no-apps" if @host == "aarch64-w64-mingw32"

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

      # For Windows ARM64, fix the Makefile to use pe-arm64 instead of pe-x86-64 for windres
      # OpenSSL's mingw64 target hardcodes --target=pe-x86-64 which creates x86_64 resource files
      if @host == "aarch64-w64-mingw32"
        makefile = File.join(work_path, "Makefile")
        content = File.read(makefile)
        content.gsub!("pe-x86-64", "pe-arm64")
        File.write(makefile, content)
        message("OpensslRecipe: fixed Makefile to use pe-arm64 for windres\n")
      end
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
