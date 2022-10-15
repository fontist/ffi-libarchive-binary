# frozen_string_literal: true

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
  ["x64-mingw32", "x86_64-w64-mingw32", "libarchive-13.dll"],
  ["x64-mingw-ucrt", "x86_64-w64-mingw32", "libarchive-13.dll"],
  ["x86_64-linux", "x86_64-linux-gnu", "libarchive.so"],
  ["aarch64-linux", "aarch64-linux-gnu", "libarchive.so"],
  ["x86_64-darwin", "x86_64-apple-darwin", "libarchive.dylib"],
  ["arm64-darwin", "arm64-apple-darwin", "libarchive.dylib"],
]

platforms.each do |platform, host, lib|
  desc "Build pre-compiled gem for the #{platform} platform"
  task "gem:native:#{platform}" do
    sh "rake compile[#{host},#{lib}] platform:#{platform} gem"
  end

  desc "Define the gem task to build on the #{platform} platform (binary gem)"
  task "platform:#{platform}" do
    spec = Gem::Specification::load("ffi-libarchive-binary.gemspec").dup
    spec.platform = Gem::Platform.new(platform)
    spec.files += ["lib/ffi-libarchive-binary/#{lib}"]
    spec.extensions = []
    spec.dependencies.reject! { |d| d.name == "mini_portile2" }

    task = Gem::PackageTask.new(spec)
    task.define
  end
end

desc "Compile binary for the target host"
task :compile, [:host, :lib] do |_t, args|
  recipe = LibarchiveBinary::LibarchiveRecipe.new
  recipe.host = args[:host] if args[:host]
  recipe.lib_filename = args[:lib] if args[:lib]
  recipe.cook_if_not
end

desc "Recompile binary"
task :recompile do
  recipe = LibarchiveBinary::LibarchiveRecipe.new
  recipe.cook
end

CLOBBER.include("pkg")
CLEAN.include("ports",
              "tmp",
              "lib/ffi-libarchive-binary/libarchive-13.dll",
              "lib/ffi-libarchive-binary/libarchive.dylib",
              "lib/ffi-libarchive-binary/libarchive.so")
