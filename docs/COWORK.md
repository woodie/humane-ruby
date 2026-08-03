# Picking up humane-ruby in a new Cowork session

Cross-project conventions (git locks, sandbox toolchain gaps, pushing, comments, code
style) are in `~/workspace/woodie/docs/COWORK.md`.

## What this is

The Ruby sibling to `humane` (Go) and `humane-swift`: same file-size/relative-date
formatting matching macOS Finder/`ByteCountFormatter`/`RelativeDateTimeFormatter`,
plus an opt-in layer of ActionView-style vocabulary on top. Module-level methods, no
instantiation: `Humane.human_size`, `Humane.distance_in_time`, `Humane.time_ago`
(one-argument convenience over `distance_in_time`, supplying `Time.now`).

## Design decisions worth knowing

- **`at`, not `for`** -- Ruby's `for` is a reserved word, so `at` is the one
  parameter name every language in the family can actually share (Swift keeps `for:`
  as its primary spelling since it matches `RelativeDateTimeFormatter`, but also
  offers `at:`).
- **No `include`-able mixin**, despite Ruby supporting one (`include Humane` for bare
  `time_ago`/`human_size` calls in a consumer's own scope). Checked against the real
  precedent: `scandalous`'s `web.rb` used to `include ActionView::Helpers::
  DateHelper`/`NumberHelper`, but replaced both with its own Sinatra `helpers do`
  block wrapping `Humane.human_size`/`.time_ago` once this gem existed -- the
  bare-name-in-a-view ergonomics belong at the consumer layer, not in this gem.
- **`when_nil:` collapses a guard-then-fallback into one call**, matching `humane`
  (Go)'s `WhenNil`.

## Testing

RSpec. `bundle`/`rspec` aren't installed in the Cowork sandbox (only the `bundler`
gem library, no executable) even though Ruby itself is (`3.0.2p107`) -- smoke-test
new code with `ruby -Ilib` here, confirm for real via `bundle exec rspec`/`make
check` on the user's own Mac.

## Current status

`v0.9.3`, published to RubyGems as `humane`. Adopted by `scandalous`.

## Open items

- **[Issue #1](https://github.com/woodie/humane-ruby/issues/1)** ("Provide
  ActionView compatibility mode") remains open -- `distance_in_time` implements
  ActionView's bucket table only through the "1 day" row by design; the 2..29-day
  and month/year buckets past that are a deliberate scope boundary, not a gap, until
  a real downstream need shows up.
- **`human_size` rounding verification** is tracked on `humane-swift` (the
  real-hardware reference implementation), not here.
