# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Humane.distance_in_time" do
  subject { Humane.distance_in_time(at, base, **opts) }

  let(:base) { Time.new(2026, 7, 8, 12, 0, 0, "+00:00") }
  let(:opts) { {} }

  context "with no keyword arguments (the recommended defaults: approximate true, include_seconds false -- matching ActionView's own defaults)" do
    context "just now" do
      let(:at) { base }

      it "displays less than a minute ago" do
        expect(subject).to eq("less than a minute ago")
      end
    end

    context "45 seconds ago" do
      let(:at) { base - 45 }

      it "rounds up to 1 minute ago (past the 30-second cutoff)" do
        expect(subject).to eq("1 minute ago")
      end
    end

    context "1 minute ago" do
      let(:at) { base - 60 }

      it "displays 1 minute ago, singular" do
        expect(subject).to eq("1 minute ago")
      end
    end

    context "3 minutes ago" do
      let(:at) { base - 180 }

      it "displays 3 minutes ago" do
        expect(subject).to eq("3 minutes ago")
      end
    end

    context "1 hour ago" do
      let(:at) { base - 3600 }

      it "displays about 1 hour ago" do
        expect(subject).to eq("about 1 hour ago")
      end
    end

    context "15 hours ago" do
      let(:at) { base - (15 * 3600) }

      it "displays about 15 hours ago" do
        expect(subject).to eq("about 15 hours ago")
      end
    end

    context "30 hours ago" do
      let(:at) { base - (30 * 3600) }

      it "rolls up to 1 day ago, with no about (ActionView's table has none on the day bucket)" do
        expect(subject).to eq("1 day ago")
      end
    end

    context "3 days ago" do
      let(:at) { base - (3 * 86_400) }

      it "displays 3 days ago" do
        expect(subject).to eq("3 days ago")
      end
    end

    context "45 seconds from now" do
      let(:at) { base + 45 }

      it "rounds up to in 1 minute (past the 30-second cutoff)" do
        expect(subject).to eq("in 1 minute")
      end
    end

    context "3 minutes from now" do
      let(:at) { base + 180 }

      it "displays in 3 minutes" do
        expect(subject).to eq("in 3 minutes")
      end
    end

    context "3 hours from now" do
      let(:at) { base + (3 * 3600) }

      it "displays in about 3 hours" do
        expect(subject).to eq("in about 3 hours")
      end
    end
  end

  context "with include_seconds: true" do
    let(:opts) { { include_seconds: true } }

    context "just now" do
      let(:at) { base }

      it "displays 0 seconds ago" do
        expect(subject).to eq("0 seconds ago")
      end
    end

    context "1 second ago" do
      let(:at) { base - 1 }

      it "displays 1 second ago, singular" do
        expect(subject).to eq("1 second ago")
      end
    end

    context "45 seconds ago" do
      let(:at) { base - 45 }

      it "displays 45 seconds ago" do
        expect(subject).to eq("45 seconds ago")
      end
    end

    context "45 seconds from now" do
      let(:at) { base + 45 }

      it "displays in 45 seconds" do
        expect(subject).to eq("in 45 seconds")
      end
    end
  end

  context "with approximate: false" do
    let(:opts) { { approximate: false } }

    context "1 hour ago" do
      let(:at) { base - 3600 }

      it "displays the exact count, no about prefix" do
        expect(subject).to eq("1 hour ago")
      end
    end

    context "15 hours ago" do
      let(:at) { base - (15 * 3600) }

      it "displays 15 hours ago" do
        expect(subject).to eq("15 hours ago")
      end
    end
  end

  context "when at is nil" do
    let(:at) { nil }

    context "and when_nil is given" do
      let(:opts) { { when_nil: "an unknown time" } }

      it "returns when_nil without formatting" do
        expect(subject).to eq("an unknown time")
      end
    end

    context "and when_nil is left unset" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  # Boundary regression coverage for ActionView's distance_of_time_in_words bucket table (truncated at the "1 day" row); each context below sits on one cutoff second from that table.
  context "at the approximate-distance bucket table boundaries" do
    context "with approximate: false" do
      let(:opts) { { approximate: false } }

      context "29 seconds ago" do
        let(:at) { base - 29 }

        it "stays less than a minute" do
          expect(subject).to eq("less than a minute ago")
        end
      end

      context "30 seconds ago" do
        let(:at) { base - 30 }

        it "rounds up to 1 minute" do
          expect(subject).to eq("1 minute ago")
        end
      end

      context "89 seconds ago" do
        let(:at) { base - 89 }

        it "stays 1 minute" do
          expect(subject).to eq("1 minute ago")
        end
      end

      context "90 seconds ago" do
        let(:at) { base - 90 }

        it "rounds up to 2 minutes" do
          expect(subject).to eq("2 minutes ago")
        end
      end

      context "44 minutes 29 seconds ago" do
        let(:at) { base - (44 * 60 + 29) }

        it "stays 44 minutes" do
          expect(subject).to eq("44 minutes ago")
        end
      end

      context "44 minutes 30 seconds ago" do
        let(:at) { base - (44 * 60 + 30) }

        it "rounds up to 1 hour" do
          expect(subject).to eq("1 hour ago")
        end
      end

      context "89 minutes 29 seconds ago" do
        let(:at) { base - (89 * 60 + 29) }

        it "stays 1 hour" do
          expect(subject).to eq("1 hour ago")
        end
      end

      context "89 minutes 30 seconds ago" do
        let(:at) { base - (89 * 60 + 30) }

        it "rounds up to 2 hours" do
          expect(subject).to eq("2 hours ago")
        end
      end

      context "23 hours 59 minutes 29 seconds ago" do
        let(:at) { base - (23 * 3600 + 59 * 60 + 29) }

        it "stays 24 hours" do
          expect(subject).to eq("24 hours ago")
        end
      end

      context "23 hours 59 minutes 30 seconds ago" do
        let(:at) { base - (23 * 3600 + 59 * 60 + 30) }

        it "rounds up to 1 day" do
          expect(subject).to eq("1 day ago")
        end
      end
    end

    context "with no keyword arguments (approximate true by default)" do
      context "44 minutes 29 seconds ago" do
        let(:at) { base - (44 * 60 + 29) }

        it "has no about" do
          expect(subject).to eq("44 minutes ago")
        end
      end

      context "44 minutes 30 seconds ago" do
        let(:at) { base - (44 * 60 + 30) }

        it "gains about, entering the hour bucket" do
          expect(subject).to eq("about 1 hour ago")
        end
      end

      context "23 hours 59 minutes 29 seconds ago" do
        let(:at) { base - (23 * 3600 + 59 * 60 + 29) }

        it "keeps about" do
          expect(subject).to eq("about 24 hours ago")
        end
      end

      context "23 hours 59 minutes 30 seconds ago" do
        let(:at) { base - (23 * 3600 + 59 * 60 + 30) }

        it "drops about, entering the day bucket" do
          expect(subject).to eq("1 day ago")
        end
      end
    end
  end
end
