require "spec_helper"
require "tempfile"
require "ffi-libarchive-binary"

RSpec.describe do
  let(:archive) { File.expand_path("examples/archive.pkg", __dir__) }

  it "unarchives pkg with no error" do
    Dir.mktmpdir do |target|
      unarchive(archive, target)

      expect(Pathname.new(File.join(target, "Payload"))).to exist
    end
  end

  def unarchive(archive, target)
    Dir.chdir(target) do
      flags = ::Archive::EXTRACT_PERM
      reader = ::Archive::Reader.open_filename(archive)

      reader.each_entry do |entry|
        reader.extract(entry, flags.to_i)
      end

      reader.close
    end
  end
end
