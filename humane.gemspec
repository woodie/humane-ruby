# frozen_string_literal: true

require_relative "lib/humane/version"

Gem::Specification.new do |spec|
  spec.name        = "humane"
  spec.version     = Humane::VERSION
  spec.authors     = ["John Woodell"]
  spec.email       = ["woodie@netpress.com"]

  spec.summary     = "Swift's file sizes and relative dates for Ruby"
  spec.description = "Finder-accurate file sizes and relative dates for Ruby, " \
                      "modeled on Swift's ByteCountFormatter and RelativeDateTimeFormatter."
  spec.homepage    = "https://github.com/woodie/humane-ruby"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
