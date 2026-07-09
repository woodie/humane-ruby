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
- **`Humane::TimeFormatter`**: `#string(at:relative_to:)`, asymmetric
  `"X ago"` / `"in X"` wording, matching `RelativeDateTimeFormatter`'s actual
  output exactly. `v0.1.0` shipped symmetric `"X ago"` / `"X from now"`
  wording instead, documented as "a deliberate departure" -- reverted in
  `v0.2.0` once it became clear that departure contradicted this library's own
  premise (matching what Swift/Finder-adjacent APIs actually do, the same bar
  `SizeFormatter` was held to). No `"about"` prefix on the hour bucket.
  `date_time_style`/`:named` (`"yesterday"`, calendar-boundary-aware) isn't
  implemented. `at:`, not Swift's `for:` -- Ruby's `for` is a reserved word;
  see `docs/COMMENTS.md` for why that rules out matching the label literally.
- **`collapse_minute:`** (default `true`): renders anything under 60 seconds as
  `"less than a minute ago"`/`"in less than a minute"`. Doesn't exist in
  `RelativeDateTimeFormatter` at all -- zouk's own `ScanEntry.timeAgo` bolts a
  manual `< 30`-second clamp on top of the formatter for exactly this reason.
  Ruby's keyword-arg defaults don't have Go's zero-value problem here --
  `Humane::TimeFormatter.new` with no arguments already gets `collapse_minute:
  true`, no constructor-function workaround needed the way Go's `TimeFormatter`
  requires `NewTimeFormatter()`. Future-side wording follows the same
  asymmetric `"in X"` pattern as the counted buckets.

## Sandbox limitation

Ruby itself **is** present in the Cowork sandbox (`ruby 3.0.2p107`, confirmed via
`ruby -v`) -- unlike `lambada`'s complete absence of a Go toolchain, this is a
narrower gap. `gem install` from RubyGems.org fails (network policy, `403
Forbidden`), but a gem built locally (`gem build humane.gemspec` then `gem
install ./humane-0.1.0.gem --local --user-install`) installs and runs fine --
used this to sanity-check the built `.gem`'s contents before woodie published
it for real. `bundle install`/`bundle exec rspec` still can't run here though:
`scandalous`'s Gemfile pins `ruby "3.1.2"`, and the sandbox has `3.0.2` --
specs run on woodie's Mac, same end result as lambada/scandalous's situation,
different root cause than lambada's (missing Go toolchain vs. a Ruby version
mismatch).

## Current state

Done: `Humane::SizeFormatter`, `Humane::TimeFormatter`, RSpec specs, README,
`docs/COMMENTS.md` (long comments extracted per the convention in zouk's
`docs/COWORK.md`), a GitHub Actions `ci.yml` (Ruby matrix: `3.0`/`3.3`,
matching the gemspec's floor), and README badges. Tagged and pushed as
`v0.1.0`. **Published to RubyGems.org as `humane` 0.1.0** -- woodie's first
gem push since 2012, using a scoped API key (`push_rubygem`/`yank_rubygem`,
no `index_rubygems`). Integrated into `scandalous`'s `web.rb` (replacing
`human_size` and `ActionView::Helpers::DateHelper#time_ago_in_words`,
dropping the `actionview`/`activesupport` dependency entirely), first via a
`path:` Gemfile source, then `github:`, now pinned `"~> 0.1"` from RubyGems
directly. Released as `scandalous` `2.2.0` -- confirmed via `bundle exec
rspec`, 29/29 passing, including the long-standing future-date bug
(`"X ago"` instead of `"X from now"`) finally fixed.

`v0.2.0`: `Humane::TimeFormatter`'s future-side wording changed from symmetric
`"X from now"` to asymmetric `"in X"`, matching `RelativeDateTimeFormatter`
exactly -- see "Design decisions" above. Breaking change to the string
output; `scandalous` (and its spec suite) needs a follow-up pass once this is
tagged and published, since it's currently locked to the old `"X from now"`
wording.

## Next up

Nothing outstanding on the formatters themselves. If scope ever needs to
grow: `Humane::SizeFormatter` has no `allowed_units`/`count_style` (Finder's
style is the only one anything downstream needs today), and
`Humane::TimeFormatter` has no `:named` style (`"yesterday"`,
calendar-boundary-aware) -- both left out deliberately per "Design decisions"
above, not gaps to fill without a real need. Outstanding: propagate the
`v0.2.0` wording change into `scandalous`.
