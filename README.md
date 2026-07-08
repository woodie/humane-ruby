# humane-ruby

[![Gem Version](https://badge.fury.io/rb/humane.svg)](https://rubygems.org/gems/humane)
[![Ruby](https://img.shields.io/badge/Ruby-3.1-red.svg)](https://www.ruby-lang.org/)
[![CI](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/woodie/humane-ruby/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/woodie/humane-ruby.svg)](https://github.com/woodie/humane-ruby/releases/latest)
[![License](https://img.shields.io/github/license/woodie/humane-ruby.svg)](LICENSE)

Swift's file sizes and relative dates for Ruby

Finder-accurate file sizes and relative dates for Ruby, modeled on Swift's [`ByteCountFormatter`](https://developer.apple.com/documentation/foundation/bytecountformatter) and [`RelativeDateTimeFormatter`](https://developer.apple.com/documentation/foundation/relativedatetimeformatter) -- not literal ports (both are closed-source, and `TimeFormatter`'s wording is a deliberate departure), but the same idea: a small, configurable formatter object instead of a bare helper method.

## Install

```
gem install humane
```

or in a `Gemfile`:

```ruby
gem "humane"
```

## Usage

```ruby
require "humane"

size_formatter = Humane::SizeFormatter.new
size_formatter.string(from_byte_count: 225_935) # "226 KB" -- 1000-based math,
                                                # capitalized units, matching
                                                # Finder, not Rails'
                                                # number_to_human_size (1024-
                                                # based despite the same label)

time_formatter = Humane::TimeFormatter.new      # collapse_minute: true
time_formatter.string(at: scanned_at, relative_to: Time.now)
# "3 minutes ago" / "3 minutes from now" / "less than a minute ago"
```

`Humane::TimeFormatter.new` uses `at:`, not `for:` -- Ruby's `for` is a
reserved word, and while a `for:` keyword argument technically parses, reading
it back out inside the method needs `binding.local_variable_get(:for)`. Not
worth it just to match Swift's `localizedString(for:relativeTo:)` label
literally.

## Scope

Only what lambada and scandalous actually need today: Finder's `.file`
byte-count style, and a numeric (non-calendar-aware) relative time style.
`ByteCountFormatter`'s `allowed_units`/alternate `count_style`s and
`RelativeDateTimeFormatter`'s `:named` style (`"yesterday"`, calendar-
boundary-aware) aren't implemented -- contributions welcome.
