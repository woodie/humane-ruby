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

        it "rounds up to 1 minute ago (past the 30-second cutoff)" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 minute ago")
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

        it "rounds up to in 1 minute (past the 30-second cutoff)" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in 1 minute")
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

    context "with approximate: true" do
      subject(:formatter) { described_class.new(approximate: true) }

      context "59 minutes ago" do
        let(:when_time) { base - (59 * 60) }

        it "prefixes about (59 minutes falls in the 45..89-minute 'about 1 hour' bucket)" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("about 1 hour ago")
        end
      end

      context "exactly 1 hour ago" do
        let(:when_time) { base - 3600 }

        it "prefixes about, the threshold is inclusive" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("about 1 hour ago")
        end
      end

      context "15 hours ago" do
        let(:when_time) { base - (15 * 3600) }

        it "prefixes about" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("about 15 hours ago")
        end
      end

      context "30 hours ago" do
        let(:when_time) { base - (30 * 3600) }

        it "does not prefix about on the day bucket (ActionView's table has no 'about 1 day')" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("1 day ago")
        end
      end

      context "3 minutes from now" do
        let(:when_time) { base + 180 }

        it "stays exact below the hour" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in 3 minutes")
        end
      end

      context "3 hours from now" do
        let(:when_time) { base + (3 * 3600) }

        it "prefixes in about" do
          expect(formatter.string(at: when_time, relative_to: base)).to eq("in about 3 hours")
        end
      end
    end

    # Boundary regression coverage for the ActionView `distance_of_time_in_words` bucket
    # table this approximate-distance behavior ports, truncated at the "1 day" row since
    # month/year buckets are out of scope. Each pair straddles a cutoff second from that
    # table to lock in exactly where the wording flips.
    context "at the approximate-distance bucket table boundaries" do
      context "without approximate" do
        subject(:formatter) { described_class.new }

        it "29s stays less than a minute, 30s rounds up to 1 minute" do
          expect(formatter.string(at: base - 29, relative_to: base)).to eq("less than a minute ago")
          expect(formatter.string(at: base - 30, relative_to: base)).to eq("1 minute ago")
        end

        it "89s stays 1 minute, 90s rounds up to 2 minutes" do
          expect(formatter.string(at: base - 89, relative_to: base)).to eq("1 minute ago")
          expect(formatter.string(at: base - 90, relative_to: base)).to eq("2 minutes ago")
        end

        it "44:29 stays 44 minutes, 44:30 rounds up to 1 hour" do
          expect(formatter.string(at: base - (44 * 60 + 29), relative_to: base)).to eq("44 minutes ago")
          expect(formatter.string(at: base - (44 * 60 + 30), relative_to: base)).to eq("1 hour ago")
        end

        it "89:29 stays 1 hour, 89:30 rounds up to 2 hours" do
          expect(formatter.string(at: base - (89 * 60 + 29), relative_to: base)).to eq("1 hour ago")
          expect(formatter.string(at: base - (89 * 60 + 30), relative_to: base)).to eq("2 hours ago")
        end

        it "23:59:29 stays 24 hours, 23:59:30 rounds up to 1 day" do
          expect(formatter.string(at: base - (23 * 3600 + 59 * 60 + 29), relative_to: base)).to eq("24 hours ago")
          expect(formatter.string(at: base - (23 * 3600 + 59 * 60 + 30), relative_to: base)).to eq("1 day ago")
        end
      end

      context "with approximate: true" do
        subject(:formatter) { described_class.new(approximate: true) }

        it "44:29 has no about, 44:30 gains about (entering the hour bucket)" do
          expect(formatter.string(at: base - (44 * 60 + 29), relative_to: base)).to eq("44 minutes ago")
          expect(formatter.string(at: base - (44 * 60 + 30), relative_to: base)).to eq("about 1 hour ago")
        end

        it "23:59:29 keeps about, 23:59:30 drops about (entering the day bucket)" do
          expect(formatter.string(at: base - (23 * 3600 + 59 * 60 + 29), relative_to: base)).to eq("about 24 hours ago")
          expect(formatter.string(at: base - (23 * 3600 + 59 * 60 + 30), relative_to: base)).to eq("1 day ago")
        end
      end
    end
  end
end
