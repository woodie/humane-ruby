# humane-ruby

[![Ruby](https://img.shields.io/badge/Ruby-3.1-red.svg)](https://www.ruby-lang.org/)
[![CI](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-ruby.svg)](https://github.com/woodie/humane-ruby/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-ruby.svg)](LICENSE)

Human-readable file sizes (1000-based math, capitalized labels, the way Mac
Finder displays them) and relative times (`"3 minutes ago"`, `"in 3 hours"`)
for Ruby and Go HTML templates -- as simple to drop in as ActionView's own
helpers, with output that's consistent with
[`humane`](https://github.com/woodie/humane) (Go) and
[`humane-swift`](https://github.com/woodie/humane-swift).

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

## `distance_in_time` and `time_ago`

Two entry points, same naming split as ActionView's own
`distance_of_time_in_words`/`time_ago_in_words`:

- **`distance_in_time(at, relative_to, **opts)`** -- the explicit,
  fully-tested core. Takes both times, so it's what specs should call.
- **`time_ago(at, **opts)`** -- a one-argument convenience for the common
  "drop into a view" case. Supplies `Time.now` as `relative_to` internally;
  everything else is identical to `distance_in_time`.

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
- **`when_nil`** (default `nil`): if `at` is `nil`, both methods return this
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
