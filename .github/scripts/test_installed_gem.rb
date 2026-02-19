#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify the installed ffi-libarchive-binary gem works correctly.
# This script runs AFTER installing the gem via `gem install`,
# NOT from the source directory.
#
# Usage:
#   SPEC_EXAMPLES_PATH=/path/to/spec/examples ruby test_installed_gem.rb

require "tempfile"
require "fileutils"

def windows?
  RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
end

# Path to spec/examples directory
# Can be overridden via SPEC_EXAMPLES_PATH environment variable
SPEC_EXAMPLES = ENV.fetch("SPEC_EXAMPLES_PATH") do
  # Default: relative to this script (works when script is in .github/scripts/)
  File.expand_path("../../spec/examples", __dir__)
end

# Test 1: Verify the gem can be loaded
puts "Test 1: Loading ffi-libarchive-binary..."
begin
  require "ffi-libarchive-binary"
  puts "  PASS: ffi-libarchive-binary loaded successfully"
rescue LoadError => e
  puts "  FAIL: Could not load ffi-libarchive-binary: #{e.message}"
  exit 1
end

# Test 2: Verify libarchive library is accessible
puts "Test 2: Checking library path..."
lib_path = LibarchiveBinary.lib_path
if File.exist?(lib_path)
  puts "  PASS: Library found at #{lib_path}"
else
  puts "  FAIL: Library not found at #{lib_path}"
  puts "  Contents of lib directory:"
  lib_dir = File.dirname(lib_path)
  Dir.glob("#{lib_dir}/*").each { |f| puts "    - #{f}" } if Dir.exist?(lib_dir)
  exit 1
end

# Test 3: Verify Archive module is functional
puts "Test 3: Testing Archive module..."
begin
  puts "  Archive::EXTRACT_PERM = #{Archive::EXTRACT_PERM}"
  puts "  PASS: Archive module is functional"
rescue => e
  puts "  FAIL: Archive module error: #{e.message}"
  exit 1
end

# Test 4: Test archive extraction (7z self-extracting)
puts "Test 4: Testing archive extraction..."
test_archive = File.join(SPEC_EXAMPLES, "fonts_7z.exe")
if File.exist?(test_archive)
  Dir.mktmpdir do |target|
    begin
      Dir.chdir(target) do
        flags = Archive::EXTRACT_PERM
        reader = Archive::Reader.open_filename(test_archive)

        reader.each_entry do |entry|
          reader.extract(entry, flags.to_i)
        end

        reader.close
      end

      extracted_file = File.join(target, "Fonts", "Marlett.ttf")
      if File.exist?(extracted_file)
        puts "  PASS: Archive extracted successfully, found #{extracted_file}"
      else
        puts "  FAIL: Extraction did not create expected file #{extracted_file}"
        puts "  Files created:"
        Dir.glob("#{target}/**/*").each { |f| puts "    - #{f}" }
        exit 1
      end
    rescue => e
      puts "  FAIL: Archive extraction error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
else
  puts "  SKIP: Test archive not found at #{test_archive}"
end

# Test 5: Test XAR/pkg extraction (non-Windows only)
unless windows?
  puts "Test 5: Testing XAR/pkg extraction..."
  pkg_archive = File.join(SPEC_EXAMPLES, "archive.pkg")
  if File.exist?(pkg_archive)
    Dir.mktmpdir do |target|
      begin
        Dir.chdir(target) do
          flags = Archive::EXTRACT_PERM
          Archive.read_open_filename(pkg_archive) do |ar|
            ar.each_entry do |entry|
              ar.extract(entry, flags.to_i)
            end
          end
        end

        payload = File.join(target, "Payload")
        if File.exist?(payload)
          puts "  PASS: PKG extracted successfully, found #{payload}"
        else
          puts "  FAIL: PKG extraction did not create expected Payload file"
          exit 1
        end
      rescue => e
        puts "  FAIL: PKG extraction error: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        exit 1
      end
    end
  else
    puts "  SKIP: PKG archive not found at #{pkg_archive}"
  end
end

puts ""
puts "All tests passed!"
exit 0
