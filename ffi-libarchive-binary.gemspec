# frozen_string_literal: true

$: << File.expand_path("lib", __dir__)
require "ffi-libarchive-binary/version"

Gem::Specification.new do |spec|
  spec.name          = "ffi-libarchive-binary"
  spec.version       = LibarchiveBinary::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Binaries for ffi-libarchive"
  spec.description   = "Contains pre-compiled and install-time-compiled binaries for ffi-libarchive"
  spec.homepage      = "https://github.com/fontist/ffi-libarchive-binary"
  spec.license       = "BSD-3-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fontist/ffi-libarchive-binary"
  spec.metadata["changelog_uri"] = "https://github.com/fontist/ffi-libarchive-binary"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features|bin|.github)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi-libarchive", "~> 1.0"
end
