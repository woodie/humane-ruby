# humane-ruby

[![Ruby](https://img.shields.io/badge/Ruby-3.1-red.svg)](https://www.ruby-lang.org/)
[![CI](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-ruby.svg)](https://github.com/woodie/humane-ruby/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-ruby.svg)](LICENSE)

Getting human-readable file sizes with 1000-based math
(as the Mac Finder displays) and relative times worded the way Swift's
`RelativeDateTimeFormatter` does turned out to be a real challenge to get
both right and simple. The `humane` library exists so a Ruby application can share
consistent size and time formatting with a Swift application, instead of
reaching for a library whose output doesn't match Swift's or that's
complicated to drop in.

```ruby
require "humane"

Humane::SizeFormatter.new.string(from_byte_count: 225_935) # "226 KB"

time_formatter = Humane::TimeFormatter.new
time_formatter.string(at: Time.now - 180, relative_to: Time.now) # "3 minutes ago"
```

Both methods also accept positional arguments, matching `humane` (Go)'s
positional-only calling convention:

```ruby
Humane::SizeFormatter.new.string(225_935) # "226 KB"
time_formatter.string(Time.now - 180, Time.now) # "3 minutes ago"
```

Corresponding functions in Swift will have consistent output.

```swift
import Foundation

ByteCountFormatter.string(fromByteCount: Int64(225935), countStyle: .file) // "226 KB"

let formatter = RelativeDateTimeFormatter(); formatter.unitsStyle = .full
formatter.localizedString(for: time, relativeTo: now) // "3 minutes ago"
```

If you're writing Swift directly rather than calling Foundation by hand,
[`humane-swift`](https://github.com/woodie/humane-swift) wraps these same two
formatters with the identical API shape -- including the
`includeSeconds`/`approximate` options below.

## Install

```
gem install humane
```

or in a `Gemfile`:

```ruby
gem "humane"
```

## Beyond Foundation's defaults

Foundation is the baseline every default matches exactly, in all three
languages -- these two options on `Humane::TimeFormatter` are how you layer
ActionView's wording on top of it, not a replacement for it. Both off by
default, so `Humane::TimeFormatter.new` and calling `RelativeDateTimeFormatter`
directly always agree:

- `include_seconds` (default `false`): under 30 seconds, collapses to "less than a
  minute ago"/"in less than a minute" instead of an exact second count. Named after
  ActionView's `include_seconds`, which defaults the same way.
- `approximate` (default `false`): prefixes "about"/"in about" on the hour-scale
  buckets (1 hour, and 2..24 hours), the way ActionView's `distance_of_time_in_words`
  does for those same buckets -- for a render that can't refresh itself and shouldn't
  overstate its own precision. Matches ActionView's own table exactly (down to its
  44:30/89:30 rounding cutoffs), through the "1 day" bucket; week/month/year buckets
  are out of scope. See [issue #1](https://github.com/woodie/humane-ruby/issues/1).

```ruby
Humane::TimeFormatter.new(approximate: true).string(at: t - 15 * 3600, relative_to: t)
# => "about 15 hours ago"
```

## Scope

Finder's `.file` byte-count style, and a numeric (non-calendar-aware)
relative time style -- that's the whole surface area today.
`allowed_units`/alternate `count_style`s and a `:named` style
(`"yesterday"`, calendar-boundary-aware) aren't implemented -- contributions
welcome.
