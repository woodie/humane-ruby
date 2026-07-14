# frozen_string_literal: true

require "spec_helper"

# time_ago is a thin one-argument convenience over distance_in_time, supplying
# Time.now as relative_to -- see distance_in_time_spec.rb for the exhaustive
# wording/bucket coverage this doesn't need to repeat.
RSpec.describe "Humane.time_ago" do
  context "just now" do
    it "displays less than a minute ago" do
      expect(Humane.time_ago(Time.now)).to eq("less than a minute ago")
    end
  end

  context "3 minutes ago" do
    it "forwards to distance_in_time with Time.now as relative_to" do
      expect(Humane.time_ago(Time.now - 180)).to eq("3 minutes ago")
    end
  end

  context "when at is nil" do
    it "returns when_nil without formatting" do
      expect(Humane.time_ago(nil, when_nil: "an unknown time")).to eq("an unknown time")
    end
  end
end
