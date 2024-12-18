require "spec_helper"
require "tempfile"
require "ffi-libarchive-binary"

RSpec.describe do
  let(:pkg) { File.expand_path("examples/archive.pkg", __dir__) }
  let(:exe_7z) { File.expand_path("examples/fonts_7z.exe", __dir__) }

  it "unarchives pkg with no error" do
    Dir.mktmpdir do |target|
      unarchive(pkg, target)

      expect(Pathname.new(File.join(target, "Payload"))).to exist
    end
  end

  it "unarchives 7z self-extracing archive with no error" do
    Dir.mktmpdir do |target|
      unarchive(exe_7z, target)
      expect(Pathname.new(File.join(target, "Fonts", "Marlett.ttf"))).to exist
    end
  end

  def unarchive(archive, target)
    Dir.chdir(target) do
      flags = ::Archive::EXTRACT_PERM
      puts "===> #{archive}"
      reader = ::Archive::Reader.open_filename(archive)

      reader.each_entry do |entry|
        reader.extract(entry, flags.to_i)
      end

      reader.close
    end
  end
end
