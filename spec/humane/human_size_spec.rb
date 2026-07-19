# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Humane.human_size" do
  subject { Humane.human_size(bytes) }

  context "with 0 bytes" do
    let(:bytes) { 0 }

    it "formats as Zero KB, matching ByteCountFormatter's own wording" do
      expect(subject).to eq("Zero KB")
    end
  end

  context "with 1 byte" do
    let(:bytes) { 1 }

    it "spells out the singular unit" do
      expect(subject).to eq("1 byte")
    end
  end

  context "with a small byte count" do
    let(:bytes) { 7 }

    it "spells out bytes rather than using a B label" do
      expect(subject).to eq("7 bytes")
    end
  end

  context "with 999 bytes" do
    let(:bytes) { 999 }

    it "stays in bytes, just under the 1 KB threshold" do
      expect(subject).to eq("999 bytes")
    end
  end

  context "with the shared 79992-byte fixture used by lambada/scandalous" do
    let(:bytes) { 79_992 }

    it "formats as 80 KB" do
      expect(subject).to eq("80 KB")
    end
  end

  context "with a real file's byte count" do
    let(:bytes) { 225_935 }

    it "matches Finder's reported size" do
      expect(subject).to eq("226 KB")
    end
  end

  context "with zouk's ByteCountFormatter(.file) fixture" do
    let(:bytes) { 500_000 }

    it "matches its output" do
      expect(subject).to eq("500 KB")
    end
  end

  context "with a single-digit megabyte value" do
    let(:bytes) { 1_500_000 }

    it "shows one decimal place, trailing zero trimmed" do
      expect(subject).to eq("1.5 MB")
    end
  end

  context "with a gigabyte-scale value" do
    let(:bytes) { 5_240_000_000 }

    it "keeps 2 decimal places at 3 significant figures (not truncated to 1)" do
      expect(subject).to eq("5.24 GB")
    end
  end

  context "with a value that lands on an exact unit" do
    let(:bytes) { 2_000_000 }

    it "trims both trailing decimal digits" do
      expect(subject).to eq("2 MB")
    end
  end
end
