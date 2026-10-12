# humane-ruby

[![Ruby](https://img.shields.io/badge/Ruby-3.1-red.svg)](https://www.ruby-lang.org/)
[![CI](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-ruby.svg)](https://github.com/woodie/humane-ruby/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-ruby.svg)](LICENSE)

File sizes that read exactly the way macOS Finder shows them (`"4.1 MB"`,
`"226 KB"`), and relative dates in Rails ActionView's wording (`"about 3 hours
ago"`, `"in 3 minutes"`), for Ruby -- the same wording Rails apps already use,
without pulling in all of Rails.

```ruby
require "humane"

Humane.human_size(225_935) # "226 KB"

mtime = Time.now - 180
Humane.time_ago(mtime) # "3 minutes ago" -- relative to the real clock

now = Time.now
Humane.distance_in_time(mtime, now) # "3 minutes ago" -- explicit relative_to, for tests
```

## Install

```
gem install humane
```

or in a `Gemfile`:

```ruby
gem "humane"
```

## File sizes

`Humane.human_size` matches Foundation's `ByteCountFormatter` (file style), which is what
macOS Finder shows, and is checked against real Finder output:

- 1000-based units with capitalized labels: `KB`, `MB`, `GB`, `TB`, and up.
- A fixed number of decimal places per unit -- none for KB, one for MB, two
  for GB and above -- with trailing zeros dropped (`"2 MB"`, not `"2.0 MB"`).
- Rounds half up, and moves up a unit when rounding reaches 1000:
  999,999 bytes is `"1 MB"`, not `"1000 KB"`.
- Zero bytes is `"Zero KB"`, and anything under 1000 bytes is spelled out
  (`"1 byte"`, `"7 bytes"`).

```ruby
Humane.human_size(2_579)         # "3 KB"
Humane.human_size(4_132_383)     # "4.1 MB"
Humane.human_size(999_999)       # "1 MB"
Humane.human_size(5_240_000_000) # "5.24 GB"
```

## `distance_in_time` and `time_ago`

Two entry points, same naming split as ActionView's own
`distance_of_time_in_words`/`time_ago_in_words`:

- **`distance_in_time(at, relative_to, **opts)`** -- the explicit,
  fully-tested core. Takes both times, so it's what specs should call.
- **`time_ago(at, **opts)`** -- a one-argument convenience for the common
  "drop into a view" case. Supplies `Time.now` as `relative_to` internally;
  everything else is identical to `distance_in_time`.

The wording follows ActionView's `distance_of_time_in_words`, with one
difference: direction is picked for you. A past time reads `"3 minutes ago"`
and a future one `"in 3 minutes"`, where ActionView leaves that to the caller.

Both share the same keyword options and recommended defaults, already
matching ActionView's own `distance_of_time_in_words` defaults -- pass none
at all and you get them for free:

```ruby
Humane.distance_in_time(at, relative_to) # approximate: true, include_seconds: false
Humane.time_ago(at)                      # same defaults, relative_to is Time.now
```

- **`approximate`** (default `true`): prefixes `"about"`/`"in about"` on the
  hour-scale buckets (1 hour, and 2..24 hours), matching ActionView's
  `distance_of_time_in_words` wording for those buckets exactly (down to its
  44:30/89:30 rounding cutoffs), through the "1 day" bucket.
- **`include_seconds`** (default `false`): under 30 seconds, collapses to
  `"less than a minute ago"`/`"in less than a minute"` instead of an exact
  second count. Matches ActionView's `include_seconds` default.
- **`when_nil`** (default `""`): if `at` is `nil`, both methods return this
  value without formatting -- for a scan, download, or other record that
  doesn't have a timestamp yet.

```ruby
Humane.distance_in_time(t, now, approximate: false) # "15 hours ago", not "about 15 hours ago"
Humane.time_ago(nil, when_nil: "an unknown time") # "an unknown time"
```

## Scope

Finder's byte-count style, and a numeric (non-calendar-aware) relative time
style through the "1 day" bucket -- that's the whole surface area today.
Alternate size units/styles and a `:named` style (`"yesterday"`,
calendar-boundary-aware) aren't implemented -- contributions welcome.

## Development

```
bundle exec standardrb
bundle exec rspec -fd spec
```
