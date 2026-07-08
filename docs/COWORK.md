# Picking up humane-ruby in a new Cowork session

Context for whoever opens this repo cold, with none of the prior conversation history.
Cross-project conventions (git locks, sandbox toolchain gaps, pushing, comments, code
style) are in `~/workspace/woodie/docs/COWORK.md`.

## What this is

A small Ruby gem for formatting file sizes and relative dates the way macOS Finder
does, modeled on Swift's `ByteCountFormatter` and `RelativeDateTimeFormatter`:
configurable formatter *classes* with a `string(from:)`-flavored method, rather than
a bare helper method (the shape Rails' own `number_to_human_size`/
`time_ago_in_words` use). [`humane`](https://github.com/woodie/humane) is the Go
sibling -- same algorithm, same wording, separate repo since Go module versioning
and RubyGems versioning don't share a tag namespace cleanly.

## Why this exists

Extracted out of `lambada` and `scandalous` after a multi-step saga fixing their
file-size formatting (see lambada's `docs/COWORK.md`, the "humanSize/timeAgo went
through N shapes" history, steps 6-8, for the full blow-by-blow -- `scandalous`
doesn't have its own `docs/COWORK.md` yet, this is the fuller writeup for the Ruby
side):

1. lambada showed `"80 kB"` (go-humanize, SI/1000-based, lowercase), scandalous
   showed `"78.1 KB"` (Rails' `number_to_human_size`, 1024-based, capitalized).
   Fixed lambada to match scandalous's label -- wrong move, see next.
2. Real-world testing (comparing a live file's size across lambada-web,
   scandalous-web, zouk, and actual Finder) revealed scandalous's `"78.1 KB"` was
   *also* wrong: Rails' `number_to_human_size` is 1024-based despite the `KB`
   label, and Finder is 1000-based under that same label. Only zouk (Swift's
   `ByteCountFormatter(.file)`) was right the whole time, for free, via the OS.
   Rails dropped the `:prefix` option that used to allow 1000-based output back
   in Rails 5 ([rails/rails#40054](https://github.com/rails/rails/issues/40054));
   getting it back would mean monkey-patching a private (`:nodoc:`) class.
3. No published Go or Ruby library ships 1000-based math under capitalized
   `KB`/`MB` labels -- the SI-correct ones use lowercase `kB`; the ones that
   capitalize it pair it with 1024-based math. Both lambada and scandalous ended
   up hand-rolling the same fix independently (`human_size` in `web.rb`).
4. Since the same fix had to be written twice, `humane`/`humane-ruby` exist to
   write it once, as a real gem instead of a helper buried in `web.rb`. Picked up
   `TimeFormatter` while at it, replacing scandalous's
   `ActionView::Helpers::DateHelper#time_ago_in_words` (which has a known,
   never-fixed future-date bug -- `distance_of_time_in_words(...).abs` collapses
   a future mtime into `"X ago"` instead of `"X from now"`) and lambada's
   `justincampbell/timeago` (which adds an `"about"` prefix Swift's formatter
   doesn't).

## Naming

`cocoa`, `aqua`, `finder`, and `cupertino` were all checked and are already taken
on RubyGems.org (unrelated old gems). `humane` was open -- double meaning:
human-readable formatting, and a nod to Apple's Human Interface Guidelines, which
is the actual design lineage here. This repo is `humane-ruby` rather than
`humane-gem`: "-ruby" names the language (matching the
`google-cloud-go`/`google-cloud-ruby` convention), "-gem" would've just said
"this is a gem," true of every RubyGem and not distinguishing information.

## Design decisions

Same algorithm and wording as `humane` (Go) -- see that repo's `docs/COWORK.md`
for the full reasoning, summarized here:

- **`Humane::SizeFormatter`**: zero-config, `#string(from_byte_count:)`. No
  `allowed_units`/`count_style` -- there's exactly one style (Finder's) anything
  here needs yet. 2-significant-digit rounding (one decimal when the integer
  part is a single digit, none once it hits two), 1000-based math, capitalized
  `KB`/`MB`/... labels.
- **`Humane::TimeFormatter`**: `#string(for:relative_to:)`, symmetric
  `"X ago"` / `"X from now"` wording -- a deliberate departure from
  `RelativeDateTimeFormatter`'s actual asymmetric output (`"X ago"` / `"in X"`).
  No `"about"` prefix on the hour bucket. `date_time_style`/`:named`
  (`"yesterday"`, calendar-boundary-aware) isn't implemented.
- **`collapse_minute:`** (default `true`): renders anything under 60 seconds as
  `"less than a minute ago"`/`"...from now"`. Doesn't exist in
  `RelativeDateTimeFormatter` at all -- zouk's own `ScanEntry.timeAgo` bolts a
  manual `< 30`-second clamp on top of the formatter for exactly this reason.
  Ruby's keyword-arg defaults don't have Go's zero-value problem here --
  `Humane::TimeFormatter.new` with no arguments already gets `collapse_minute:
  true`, no constructor-function workaround needed the way Go's `TimeFormatter`
  requires `NewTimeFormatter()`.

## Sandbox limitation

Ruby itself **is** present in the Cowork sandbox (`ruby 3.0.2p107`, confirmed via
`ruby -v`) -- unlike `lambada`'s complete absence of a Go toolchain, this is a
narrower gap. `gem install` fails, though: the outbound network proxy returns
`403 Forbidden` for `rubygems.org`, so RSpec (or anything else) can't be
installed here. Code can be written and read back, but specs can't actually be
run in this sandbox -- same end result as lambada/scandalous's situation
(specs run on woodie's Mac), different root cause (network policy, not a
missing interpreter).

## Current state

Not yet started as of this file's creation -- `humane` (Go) was built first.
This file exists so a fresh session picks up the Ruby side with the same context
the Go side already has, without re-deriving the naming/design history above.

## Next up

- Build `Humane::SizeFormatter` and `Humane::TimeFormatter`, mirroring
  `humane`'s `size.go`/`time.go` exactly (same test fixtures translated to
  RSpec).
- gemspec, `Gemfile`, `lib/humane.rb` entry point, RSpec specs mirroring
  `humane`'s `size_test.go`/`time_test.go`.
- Confirm specs pass on woodie's Mac (sandbox can't run them -- see Sandbox
  limitation).
- Integrate into `scandalous`'s `web.rb` (replace `human_size` and
  `ActionView::Helpers::DateHelper#time_ago_in_words`), updating
  `web_spec.rb`'s fixtures for the wording changes (e.g., `"about 15 hours
  ago"` -> `"15 hours ago"`, and the long-standing future-date bug finally
  getting fixed).
- Publish: `gem push` to RubyGems once ready.
