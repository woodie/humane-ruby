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

Two options on `Humane::TimeFormatter`, both off by default so it matches
`RelativeDateTimeFormatter` exactly out of the box:

- `include_seconds` (default `false`): below a minute, collapses to "less than a
  minute ago"/"in less than a minute" instead of an exact second count. Named after
  ActionView's `include_seconds`, which defaults the same way.
- `approximate` (default `false`): prefixes "about"/"in about" on buckets of an hour
  or larger, the way ActionView's `distance_of_time_in_words` does past that same
  boundary -- for a render that can't refresh itself and shouldn't overstate its own
  precision.

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
