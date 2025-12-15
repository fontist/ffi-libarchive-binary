# frozen_string_literal: true

require "rbconfig"
require "rake/clean"
require "rubygems/package_task"
require_relative "lib/ffi-libarchive-binary/libarchive_recipe"

require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]
task spec: :compile

desc "Build install-compilation gem"
task "gem:native:any" do
  sh "rake platform:any gem"
end

desc "Define the gem task to build on any platform (compile on install)"
task "platform:any" do
  spec = Gem::Specification::load("ffi-libarchive-binary.gemspec").dup
  task = Gem::PackageTask.new(spec)
  task.define
end

platforms = [
  ["x64-mingw32", "x86_64-w64-mingw32"],
  ["x64-mingw-ucrt", "x86_64-w64-mingw32"],
  ["arm64-mingw-ucrt", "aarch64-w64-mingw32"],
  ["x86_64-linux", "x86_64-linux-gnu"],
  ["aarch64-linux", "aarch64-linux-gnu"],
  ["x86_64-darwin", "x86_64-apple-darwin"],
  ["arm64-darwin", "arm64-apple-darwin"],
]

platforms.each do |platform, host|
  desc "Build pre-compiled gem for the #{platform} platform"
  task "gem:native:#{platform}" do
    sh "rake compile[#{host}] platform:#{platform} gem"
  end

  desc "Define the gem task to build on the #{platform} platform (binary gem)"
  task "platform:#{platform}" do
    spec = Gem::Specification::load("ffi-libarchive-binary.gemspec").dup
    spec.platform = Gem::Platform.new(platform)
    spec.files += Dir.glob("lib/ffi-libarchive-binary/*.{dll,so,dylib}")
    spec.extensions = []
    spec.dependencies.reject! { |d| d.name == "mini_portile2" }

    task = Gem::PackageTask.new(spec)
    task.define
  end
end

desc "Compile binary for the target host"
task :compile, [:host] do |_t, args|
  recipe = LibarchiveBinary::LibarchiveRecipe.new
  if args[:host]
    recipe.host = args[:host]
  else
    recipe.host = "x86_64-apple-darwin" if /x86_64-apple-darwin*/.match?(recipe.host)
    recipe.host = "arm64-apple-darwin" if /arm64-apple-darwin*/.match?(recipe.host)
  end
  recipe.cook_if_not
end

CLOBBER.include("pkg")
CLEAN.include("ports",
              "tmp",
              "lib/ffi-libarchive-binary/libarchive-13.dll",
              "lib/ffi-libarchive-binary/libarchive.dylib",
              "lib/ffi-libarchive-binary/libarchive.so")
