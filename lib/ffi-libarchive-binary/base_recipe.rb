require "mini_portile2"

module LibarchiveBinary
  class BaseRecipe < MiniPortile
    def initialize(name, version)
      super
      @printed = {}
    end

    def apple_arch_flag(host)
      if host.eql? "arm64-apple-darwin"
        "-arch arm64"
      else
        ""
      end
    end

    def cflags(host)
      "CFLAGS=-fPIC #{apple_arch_flag(host)}"
    end

    def ldflags(host)
      "LDFLAGS=-fPIC #{apple_arch_flag(host)}"
    end

    def message(text)
      return super unless text.start_with?("\rDownloading")

      match = text.match(/(\rDownloading .*)\((\s*)(\d+)%\)/)
      pattern = match ? match[1] : text
      return if @printed[pattern] && match[3].to_i != 100

      @printed[pattern] = true
      super
    end
  end
end
