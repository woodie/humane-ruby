# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Humane.distance_in_time" do
  let(:base) { Time.new(2026, 7, 8, 12, 0, 0, "+00:00") }

  context "with no keyword arguments (the recommended defaults: approximate true, include_seconds false -- matching ActionView's own defaults)" do
    context "just now" do
      it "displays less than a minute ago" do
        expect(Humane.distance_in_time(base, base)).to eq("less than a minute ago")
      end
    end

    context "45 seconds ago" do
      it "rounds up to 1 minute ago (past the 30-second cutoff)" do
        expect(Humane.distance_in_time(base - 45, base)).to eq("1 minute ago")
      end
    end

    context "1 minute ago" do
      it "displays 1 minute ago, singular" do
        expect(Humane.distance_in_time(base - 60, base)).to eq("1 minute ago")
      end
    end

    context "3 minutes ago" do
      it "displays 3 minutes ago" do
        expect(Humane.distance_in_time(base - 180, base)).to eq("3 minutes ago")
      end
    end

    context "1 hour ago" do
      it "displays about 1 hour ago" do
        expect(Humane.distance_in_time(base - 3600, base)).to eq("about 1 hour ago")
      end
    end

    context "15 hours ago" do
      it "displays about 15 hours ago" do
        expect(Humane.distance_in_time(base - (15 * 3600), base)).to eq("about 15 hours ago")
      end
    end

    context "30 hours ago" do
      it "rolls up to 1 day ago, with no about (ActionView's table has none on the day bucket)" do
        expect(Humane.distance_in_time(base - (30 * 3600), base)).to eq("1 day ago")
      end
    end

    context "3 days ago" do
      it "displays 3 days ago" do
        expect(Humane.distance_in_time(base - (3 * 86_400), base)).to eq("3 days ago")
      end
    end

    context "45 seconds from now" do
      it "rounds up to in 1 minute (past the 30-second cutoff)" do
        expect(Humane.distance_in_time(base + 45, base)).to eq("in 1 minute")
      end
    end

    context "3 minutes from now" do
      it "displays in 3 minutes" do
        expect(Humane.distance_in_time(base + 180, base)).to eq("in 3 minutes")
      end
    end

    context "3 hours from now" do
      it "displays in about 3 hours" do
        expect(Humane.distance_in_time(base + (3 * 3600), base)).to eq("in about 3 hours")
      end
    end
  end

  context "with include_seconds: true" do
    context "just now" do
      it "displays 0 seconds ago" do
        expect(Humane.distance_in_time(base, base, include_seconds: true)).to eq("0 seconds ago")
      end
    end

    context "1 second ago" do
      it "displays 1 second ago, singular" do
        expect(Humane.distance_in_time(base - 1, base, include_seconds: true)).to eq("1 second ago")
      end
    end

    context "45 seconds ago" do
      it "displays 45 seconds ago" do
        expect(Humane.distance_in_time(base - 45, base, include_seconds: true)).to eq("45 seconds ago")
      end
    end

    context "45 seconds from now" do
      it "displays in 45 seconds" do
        expect(Humane.distance_in_time(base + 45, base, include_seconds: true)).to eq("in 45 seconds")
      end
    end
  end

  context "with approximate: false" do
    context "1 hour ago" do
      it "displays the exact count, no about prefix" do
        expect(Humane.distance_in_time(base - 3600, base, approximate: false)).to eq("1 hour ago")
      end
    end

    context "15 hours ago" do
      it "displays 15 hours ago" do
        expect(Humane.distance_in_time(base - (15 * 3600), base, approximate: false)).to eq("15 hours ago")
      end
    end
  end

  context "when at is nil" do
    context "and when_nil is given" do
      it "returns when_nil without formatting" do
        expect(Humane.distance_in_time(nil, base, when_nil: "an unknown time")).to eq("an unknown time")
      end
    end

    context "and when_nil is left unset" do
      it "returns nil" do
        expect(Humane.distance_in_time(nil, base)).to be_nil
      end
    end
  end

  # Boundary regression coverage for the ActionView `distance_of_time_in_words` bucket
  # table this approximate-distance behavior ports, truncated at the "1 day" row since
  # month/year buckets are out of scope. Each pair straddles a cutoff second from that
  # table to lock in exactly where the wording flips.
  context "at the approximate-distance bucket table boundaries" do
    context "with approximate: false" do
      it "29s stays less than a minute, 30s rounds up to 1 minute" do
        expect(Humane.distance_in_time(base - 29, base, approximate: false)).to eq("less than a minute ago")
        expect(Humane.distance_in_time(base - 30, base, approximate: false)).to eq("1 minute ago")
      end

      it "89s stays 1 minute, 90s rounds up to 2 minutes" do
        expect(Humane.distance_in_time(base - 89, base, approximate: false)).to eq("1 minute ago")
        expect(Humane.distance_in_time(base - 90, base, approximate: false)).to eq("2 minutes ago")
      end

      it "44:29 stays 44 minutes, 44:30 rounds up to 1 hour" do
        expect(Humane.distance_in_time(base - (44 * 60 + 29), base, approximate: false)).to eq("44 minutes ago")
        expect(Humane.distance_in_time(base - (44 * 60 + 30), base, approximate: false)).to eq("1 hour ago")
      end

      it "89:29 stays 1 hour, 89:30 rounds up to 2 hours" do
        expect(Humane.distance_in_time(base - (89 * 60 + 29), base, approximate: false)).to eq("1 hour ago")
        expect(Humane.distance_in_time(base - (89 * 60 + 30), base, approximate: false)).to eq("2 hours ago")
      end

      it "23:59:29 stays 24 hours, 23:59:30 rounds up to 1 day" do
        expect(Humane.distance_in_time(base - (23 * 3600 + 59 * 60 + 29), base, approximate: false)).to eq("24 hours ago")
        expect(Humane.distance_in_time(base - (23 * 3600 + 59 * 60 + 30), base, approximate: false)).to eq("1 day ago")
      end
    end

    context "with no keyword arguments (approximate true by default)" do
      it "44:29 has no about, 44:30 gains about (entering the hour bucket)" do
        expect(Humane.distance_in_time(base - (44 * 60 + 29), base)).to eq("44 minutes ago")
        expect(Humane.distance_in_time(base - (44 * 60 + 30), base)).to eq("about 1 hour ago")
      end

      it "23:59:29 keeps about, 23:59:30 drops about (entering the day bucket)" do
        expect(Humane.distance_in_time(base - (23 * 3600 + 59 * 60 + 29), base)).to eq("about 24 hours ago")
        expect(Humane.distance_in_time(base - (23 * 3600 + 59 * 60 + 30), base)).to eq("1 day ago")
      end
    end
  end
end
