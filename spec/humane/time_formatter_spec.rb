# frozen_string_literal: true

require "spec_helper"

RSpec.describe Humane::TimeFormatter do
  let(:base) { Time.new(2026, 7, 8, 12, 0, 0, "+00:00") }

  describe "#string" do
    context "with include_seconds: false (the default)" do
      subject(:formatter) { described_class.new }

      context "just now" do
        let(:when_time) { base }

        it "displays less than a minute ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("less than a minute ago")
        end
      end

      context "45 seconds ago" do
        let(:when_time) { base - 45 }

        it "displays less than a minute ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("less than a minute ago")
        end
      end

      context "1 minute ago" do
        let(:when_time) { base - 60 }

        it "displays 1 minute ago, singular" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 minute ago")
        end
      end

      context "3 minutes ago" do
        let(:when_time) { base - 180 }

        it "displays 3 minutes ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("3 minutes ago")
        end
      end

      context "1 hour ago" do
        let(:when_time) { base - 3600 }

        it "displays 1 hour ago, singular" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 hour ago")
        end
      end

      context "15 hours ago" do
        let(:when_time) { base - (15 * 3600) }

        it "displays 15 hours ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("15 hours ago")
        end
      end

      context "30 hours ago" do
        let(:when_time) { base - (30 * 3600) }

        it "rolls up to 1 day ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 day ago")
        end
      end

      context "3 days ago" do
        let(:when_time) { base - (3 * 86_400) }

        it "displays 3 days ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("3 days ago")
        end
      end

      context "45 seconds from now" do
        let(:when_time) { base + 45 }

        it "displays in less than a minute" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in less than a minute")
        end
      end

      context "3 minutes from now" do
        let(:when_time) { base + 180 }

        it "displays in 3 minutes" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in 3 minutes")
        end
      end
    end

    context "with include_seconds: true" do
      subject(:formatter) { described_class.new(include_seconds: true) }

      context "just now" do
        let(:when_time) { base }

        it "displays 0 seconds ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("0 seconds ago")
        end
      end

      context "1 second ago" do
        let(:when_time) { base - 1 }

        it "displays 1 second ago, singular" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 second ago")
        end
      end

      context "45 seconds ago" do
        let(:when_time) { base - 45 }

        it "displays 45 seconds ago" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("45 seconds ago")
        end
      end

      context "45 seconds from now" do
        let(:when_time) { base + 45 }

        it "displays in 45 seconds" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in 45 seconds")
        end
      end
    end
  end
end
