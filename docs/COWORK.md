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
- **`include_seconds:`** (default `false`; renamed from `collapse_minute:` in
  `v0.3.0`, an exact polarity inversion -- see `docs/releases/v0.3.0.md`): when
  `false`, renders anything under 60 seconds as `"less than a minute ago"`/`"in
  less than a minute"`. Doesn't exist in `RelativeDateTimeFormatter` at all --
  zouk's own `ScanEntry.timeAgo` bolts a manual clamp on top of the formatter for
  exactly this reason. Ruby's keyword-arg defaults don't have Go's zero-value
  problem here -- `Humane::TimeFormatter.new` with no arguments already gets the
  recommended default, no constructor-function workaround needed the way Go's
  `TimeFormatter` requires `NewTimeFormatter()`. Future-side wording follows the
  same asymmetric `"in X"` pattern as the counted buckets.
- **`approximate:`** (default `false`; added in `v0.4.0`, ported from
  `humane-swift`'s identically-named option -- see `docs/releases/v0.4.0.md`):
  when `true`, prefixes `"about"`/`"in about"` on buckets of an hour or larger,
  matching ActionView's `distance_of_time_in_words` past its own "about"
  threshold. For contexts that can't live-refresh a rendered time (a web
  response, a cached page), a precise-looking "15 hours ago" overstates its own
  accuracy; `scandalous`'s listing is the motivating case. Simpler to implement
  here than in Swift: `#string` builds the bare quantity phrase before wrapping
  it in `"X ago"`/`"in X"`, so prefixing `"about "` first composes correctly for
  both directions with no string-surgery needed.

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

`v0.3.0`: `Humane::TimeFormatter.new`'s `collapse_minute:` (default `true`) renamed
to `include_seconds:` (default `false`) -- an exact polarity inversion, so default
behavior is unchanged; only explicit `collapse_minute: false` callers need to change
to `include_seconds: true`. Named after ActionView's own `include_seconds` (same
default), and deliberately moves off "collapse" language now that `humane-swift`'s
`approximate` option (ActionView-inspired "about"/"in about" prefixing) exists and
would otherwise compete for that word -- see `humane-swift/docs/COWORK.md` for the
full cross-repo naming discussion this came out of. `bundle` isn't installed in the
Cowork sandbox (no Ruby version mismatch this time -- the gemspec's own floor is
`>= 3.0`, which the sandbox's `3.0.2` satisfies), so a real `bundle exec rspec` run
couldn't happen here; instead, ran the renamed formatter directly via `ruby -Ilib`
against every case the updated spec covers (both `include_seconds: false` and
`true`, past and future) and all matched. Confirmed for real afterward via
`bundle exec rspec` on woodie's Mac -- 22/22 passing. Tagged, pushed, and
**published to RubyGems.org as `humane` `0.3.0`.**

`scandalous` picked up both `v0.2.0` (already had been, just undocumented -- its
spec already asserted the asymmetric wording) and `v0.3.0` (no behavior change,
since it never passed `collapse_minute:`/`include_seconds:` explicitly) in the same
session. Its `Gemfile` pin went `"~> 0.1"` -> `"~> 0.2"` (undocumented, found
already in place) -> `"~> 0.3"`. `lambada` (the Go sibling's consumer) went through
the equivalent motions on its own pin -- see `humane`'s own `docs/COWORK.md`.

`v0.4.0`: `Humane::TimeFormatter` gains `approximate:` (default `false`), ported
from `humane-swift`'s identically-named option -- see "Design decisions" above and
`docs/releases/v0.4.0.md`. Additive, not breaking. Confirmed via `ruby -Ilib`
smoke test (bundler unavailable in this sandbox), then for real via `bundle exec
rspec` on woodie's Mac. Tagged, pushed, and **published to RubyGems.org as
`humane` `0.4.0`** (confirmed via `gem list -r humane`). `scandalous`'s
`time_ago` picked up `approximate: true` in the same window, confirmed live
(`"about 14 hours ago"`), released as `scandalous` `2.5.0`.

Also this session: README's Swift code sample (raw `ByteCountFormatter`/
`RelativeDateTimeFormatter` calls) now links to `humane-swift` directly, since
that's a real, published sibling library now rather than just "the Foundation
this gem is modeled on."

`v0.5.0`: `#string` reworked to match the ActionView
`distance_of_time_in_words` bucket table quoted in issue #1 exactly, through the
"1 day" row (week/month/year buckets stay out of scope -- narrower than a "full
featured" port, matching what the scan-server/retriever projects actually need).
Two behavior changes, both additive to the API surface (no new keyword args):
`include_seconds: false`'s collapse cutoff moved from 60s to 30s (matching the
table's first row), and `approximate` narrowed from "about" on any bucket >= 1
hour to exactly the hour-scale buckets (1 hour, 2..24 hours) -- ActionView's own
table has no "about 1 day". Bucketing now goes through `distance_in_minutes`
(seconds/60, rounded once) rather than re-dividing raw seconds per unit, which is
what produces the table's specific 44:30/89:30/23:59:30 cutoffs and fixes a
latent rounding-carries-across-a-boundary bug (`59:59:59` used to read "60
minutes ago" instead of "1 hour ago"). New boundary-pair specs lock in all six
cutoffs from the table for both directions. Confirmed for real via `bundle exec
rspec` on woodie's Mac -- 35/35 passing. `humane` and `humane-swift` picked up
the identical table change in the same session -- see their own `docs/COWORK.md`.
Issue #1 can now be closed with a pointer to this table match, not just to
`approximate` existing in the abstract. Tagged and released:
https://github.com/woodie/humane-ruby/releases/tag/v0.5.0.

`v0.6.0`: `#string` on both `TimeFormatter` and `SizeFormatter` now also
accepts positional arguments (`string(when, base)`, `string(225_935)`)
alongside the existing keyword forms -- matches `humane` (Go), which is
positional-only since Go has no argument labels at all. Implemented as
optional positional parameters merged with the keyword parameters via
`||=`, with explicit `ArgumentError`s standing in for Ruby's built-in
missing-keyword check. `humane-swift` picked up the equivalent
`string(_:_:)`/`string(_:)` overloads in the same session. `at` is also now
documented as the one `TimeFormatter` parameter name every language in the
family can actually share (Ruby was always forced into it -- `for` is a
reserved word); `humane-swift` added `string(at:relativeTo:)` as an alias
alongside its primary `for:` spelling. See `docs/COMMENTS.md` and
`docs/releases/v0.6.0.md`.

This session also made explicit, in the README, the principle that's been
guiding these decisions: Foundation is the baseline every default matches
exactly, in all three languages; ActionView's vocabulary is a layer on top
of that baseline, opt-in, never a replacement for it.

`bundle`/`rspec` still aren't installed in this sandbox, but Ruby itself is
(`3.0.2p107`) -- confirmed for real via `ruby -Ilib` in the sandbox first
(positional and keyword calls return identical output on both formatters, a
mixed positional/keyword call works, missing either argument raises the
expected `ArgumentError`, the full existing bucket/fixture tables still
match with positional args), then for real via `bundle exec rspec` on
woodie's Mac -- 40/40 passing. Tagged, pushed, and **published to
RubyGems.org as `humane` `0.6.0`**.

## `v0.9.0`: a full API rethink, informed by three real consumers

Through `v0.6.0` this gem was built as a Ruby port of `ByteCountFormatter`/
`RelativeDateTimeFormatter` -- configurable formatter classes mirroring
Foundation's own API shape. With three real consumers now shipped
(`lambada`, `scandalous`, `zouk`) and this gem the sole user of its own API
(woodie), the goal shifted: feel as simple to drop into a Ruby HTML
template as ActionView's own helpers, while staying consistent with
`humane` (Go) and `humane-swift`. Breaking changes throughout -- see
`humane`'s own `docs/COWORK.md` `v0.9.0` entry for the full cross-repo
rationale, summarized here:

- **`SizeFormatter.new.string(...)`/`TimeFormatter.new.string(...)` ->
  `SizeFormatter.human_size(...)`/`TimeFormatter.time_ago(...)`**, class
  methods, no instantiation -- once configuration lived at the call site
  instead of the constructor, `.new` held no state and was ceremony left
  over from mirroring Foundation. `humane` (Go) and `humane-swift` picked
  up the equivalent change in the same session, each using its own
  idiomatic casing (`HumanSize`/`TimeAgo` in Go, `humanSize`/`timeAgo` in
  Swift) rather than one literal spelling shared across all three.
- **`human_size`'s rounding corrected toward 3 significant figures** --
  see `docs/COMMENTS.md` for the derivation. Fixes `5,240,000,000` ->
  `"5.24 GB"` (previously `"5.2 GB"`), and bakes in `humane-swift`'s
  other real-hardware findings (`"Zero KB"` for zero, spelled-out
  `"bytes"` below 1000).
- **`time_ago`'s `approximate:` default flips `false` -> `true`** --
  matches ActionView's own always-on-past-the-hour behavior, and matches
  what `scandalous`'s `web.rb` already passed explicitly. `include_seconds:`
  stays `false`, unchanged.
- **`time_ago` accepts `at: nil`** plus a new `when_nil:` keyword, returned
  as-is when `at` is `nil` -- lets a caller collapse a guard-then-fallback
  dance into one call. Motivated by `zouk`'s Swift `ScanEntry.timeAgo`,
  which has exactly this shape today (see `humane`'s own
  `docs/COMMENTS.md` for the full history).

Written by inspection -- `bundle`/`rspec` still aren't installed in this
sandbox (see "Sandbox limitation" above), though `ruby -Ilib` smoke-testing
is available and was used to confirm the new class methods before
committing. Confirmed for real via `bundle exec rspec` on woodie's Mac --
36/36 passing -- plus a green CI run on GitHub Actions (covering the
`standardrb` dev dependency added this session). Tagged, pushed, and
released: https://github.com/woodie/humane-ruby/releases/tag/v0.9.0,
and published to RubyGems as `humane` `0.9.0`.

All three real consumers have since adopted it: `lambada` `2.7.0`
(deployed to the Pi, confirmed live), `scandalous` `2.7.0`, and `zouk`
`v1.11.0` (Swift, adopted `humane-swift`'s equivalent `v0.9.0`) -- see each
repo's own `docs/COWORK.md`.

## `v0.9.3` (working, not yet finalized): flattened, `distance_in_time`/`time_ago` split

Still converging on this one -- tagged as `0.9.3`, not `1.0.0`, on purpose.

**`Humane::TimeFormatter`/`Humane::SizeFormatter` are gone.** Their class
methods move directly onto the `Humane` module: `Humane.human_size`,
`Humane.distance_in_time`, `Humane.time_ago`. Once `.new` was already gone
(`v0.9.0`), the class layer held no state either -- same reasoning `humane`
(Go) went through dropping its formatter structs, just one level later here
since Ruby's class methods didn't need the `.new` step Go's did. `humane`
(Go) already calls its functions directly off the `humane` package;
`humane-swift` picked up the equivalent flatten in the same session (one
`Humane` enum instead of two) -- see each repo's own `docs/COWORK.md`.

No `include`-able mixin added despite this being the natural place to graft
one on (Ruby, unlike Go/Swift, could support `include Humane` for bare
`time_ago`/`human_size` in a consumer's own scope, ActionView-style).
Checked against the actual precedent this was modeled on: `scandalous`'s
`web.rb` used to `include ActionView::Helpers::DateHelper`/`NumberHelper`,
but dropped both once `humane-ruby` existed, replacing them with its own
Sinatra `helpers do` block wrapping `Humane.human_size`/`.time_ago` -- the
bare-name-in-a-view ergonomics already live at the consumer layer, not
inside this gem. Go and Swift don't have an equivalent mixin mechanism at
all, so adding one here would be a Ruby-only branch in the API shape for a
need no real consumer actually has. Left out.

**`.time_ago` (the old two-argument class method) is renamed
`.distance_in_time`.** A new one-argument `.time_ago(at, **opts)` takes its
place, supplying `Time.now` as `relative_to` internally. Same naming split
as ActionView's own `distance_of_time_in_words`/`time_ago_in_words` --
deliberately borrowed rather than invented. The short names (`time_ago`,
`human_size`) stay reserved for the "format a string for a view" contract;
anything returning something richer than a string in the future gets a
longer, explicit name instead of competing for the short one. `humane` (Go)
and `humane-swift` picked up the identical split in the same session
(`DistanceInTime`/`TimeAgo`, `distanceInTime`/`timeAgo`).

Not invented from scratch -- `lambada`'s template FuncMap and `zouk`'s
`ScanEntry.timeAgo` computed property had already hand-built this same
two-tier shape independently; see `humane`'s own `docs/COWORK.md` `v0.9.3`
entry for the full cross-repo evidence, summarized once there rather than
three times.

Written by inspection; `bundle exec rspec` still isn't runnable in this
sandbox (no `bundle` executable, only the `bundler` gem library -- see
"Sandbox limitation" above), but `ruby -Ilib` smoke-testing confirmed
`Humane.human_size`/`.distance_in_time`/`.time_ago` load and behave as
expected before committing. Confirmed for real on woodie's Mac: `make
check` (`bundle exec standardrb` + `bundle exec rspec spec`) -- 39/39
examples, 0 failures. Tagged, pushed, and released:
https://github.com/woodie/humane-ruby/releases/tag/v0.9.3, and published to
RubyGems as `humane` `0.9.3` (confirmed via `gem push`:
"Successfully registered gem: humane (0.9.3)"). `lambada`/`zouk`/
`scandalous` adoption is a deliberately separate follow-up.

## Next up

1. `human_size`'s 3-significant-figure rounding rule reproduces every known
   fixture (including both cases previously cross-checked against real
   hardware) but is still an inference from a small fixture set -- worth a
   real `ByteCountFormatter` comparison across a wider range of magnitudes
   before treating it as confirmed the way the two original fixtures were.
2. `Humane::SizeFormatter` has no alternate unit/style options, and
   `Humane::TimeFormatter` has no `:named` style (`"yesterday"`,
   calendar-boundary-aware) -- both left out deliberately, not gaps to
   fill without a real need.
3. `humane-ruby` issue #1 quotes ActionView's full `distance_of_time_in_words`
   table; ported only through the "1 day" row. The 2..29-day and month/year
   buckets past that are out of scope by design (see README "Scope") -- not
   a gap to fill without a real downstream need.

All three real consumers (`lambada`, `scandalous`, `zouk`) have already
adopted `v0.9.0` -- see "All three real consumers have since adopted it"
above. Nothing left open on that front.
