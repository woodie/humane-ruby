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
  (Go)'s `WhenNil`. Defaults to `""`, not `nil` -- see "Brought `when_nil` to
  parity" below for why that changed.

## Brought `when_nil` to parity: defaults to `""`, not `nil`

A cross-language test comparison (all four `humane` repos, same session)
found `distance_in_time`'s "nil `at`, no fallback set" case actually
returned different things per language: Go/Swift/Kotlin all default their
`WhenNil`/`whenNil` to `""` explicitly; this gem alone defaulted `when_nil:`
to `nil`, inherited from matching ActionView's own helper conventions
rather than from anything Ruby-specific. Once the goal was named directly
-- `humane`'s own cross-language consistency matters more than any one
language's ecosystem convention -- keeping Ruby's `nil` stopped making
sense. Changed `lib/humane/time.rb`'s default to `when_nil: ""`, updated
`distance_in_time_spec.rb`'s "returns nil"/`be_nil` case to "returns an
empty string"/`eq("")`, and updated the README/`docs/COMMENTS.md`
explanations that documented the old default.

Real risk checked before changing, not just assumed safe: `nil` and `""`
differ in Ruby truthiness (`if result`/`result || fallback` behave
differently), so this is a genuine behavior change for any caller that
branches on the return value. `scandalous` (the one real Ruby consumer)
checked clean -- `web.rb`'s `time_ago(time)` always passes a real
timestamp from a listed file, never `nil`, so it never exercises this
path today.

`TimeAgo`/`timeAgo` accepting a nilable `at` at all stays split across the
family on purpose, not brought to parity here -- Go's `TimeAgo(at
time.Time, ...)` and Kotlin's `timeAgo(at: Instant, ...)` both take a
non-nullable `at`, while this gem's `time_ago`/Swift's `timeAgo` accept
`nil`. That's a difference in how much nil-checking each language's type
system requires at the call site, not in what happens once nil is
actually handled -- fine to leave differing, unlike the return value
above.

## Testing

RSpec. `bundle`/`rspec` aren't installed in the Cowork sandbox (only the `bundler`
gem library, no executable) even though Ruby itself is (`3.0.2p107`) -- smoke-test
new code with `ruby -Ilib` here, confirm for real via `bundle exec rspec`/`make
check` on the user's own Mac.

## Current status

`v0.9.4`, published to RubyGems as `humane`. Adopted by `scandalous`.

## Open items

- **[Issue #1](https://github.com/woodie/humane-ruby/issues/1)** ("Provide
  ActionView compatibility mode") remains open -- `distance_in_time` implements
  ActionView's bucket table only through the "1 day" row by design; the 2..29-day
  and month/year buckets past that are a deliberate scope boundary, not a gap, until
  a real downstream need shows up.
- **`human_size` rounding verification** is tracked on `humane-swift` (the
  real-hardware reference implementation), not here.
