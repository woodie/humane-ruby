# Comments

Rationale, history, and design notes that used to live as multi-line
comments in the source. Organized by file, then by the class or method
each note is attached to. The source itself now carries at most one
short line at any given spot -- anything longer that would previously
have been a multi-line comment lives here instead.

## lib/humane/size_formatter.rb

### `Humane::SizeFormatter` (class)
Formats byte counts the way Finder does, as a class method
(`.human_size`) rather than an instantiated formatter. Through `v0.6.0`
this mirrored `ByteCountFormatter`'s own shape (`SizeFormatter.new.string`)
on purpose. `v0.9.0` drops that -- once there was no per-instance
configuration to hold, `.new` was ceremony left over from mirroring
Foundation rather than something this design still needs. See
`docs/COWORK.md`'s `v0.9.0` entry.

### `Humane::SizeFormatter.human_size`
Bakes in three corrections found by comparing this gem's original
2-significant-digit port against real `ByteCountFormatter` output (via
`humane-swift`'s real-hardware testing -- see that repo's
`docs/COWORK.md`, "Current state"):

- `0` reads `"Zero KB"`, not `"0 B"` -- a hardcoded special case;
  `ByteCountFormatter` doesn't run its usual rounding logic for zero.
- Values under 1000 spell out `"byte"`/`"bytes"` (`"1 byte"`, `"7 bytes"`)
  rather than using a `"B"` label.
- Everything else rounds to 3 significant figures (not 2) via
  `format_significant`, then gets unit-labeled. The old rule (1 decimal
  below 10, none at or above) undercounted precision under 10:
  `5,240,000,000` bytes is `"5.24 GB"` on real hardware, not `"5.2 GB"`.

The 3-significant-figure rule was chosen over a narrower "just fix the GB
case" patch because it's the only single rule found that reproduces every
known fixture at once -- including the two cross-checked against real
hardware before this change (`225_935` -> `"226 KB"`, `500_000` ->
`"500 KB"`) and the existing `1_500_000` -> `"1.5 MB"` fixture, alongside
the new GB finding. Still an inference from a small fixture set, not
confirmed across every magnitude -- see `docs/COWORK.md`'s `v0.9.0` entry
for what still needs a real `ByteCountFormatter` comparison.

    human_size(0)          == "Zero KB"
    human_size(1)          == "1 byte"
    human_size(79_992)     == "80 KB"
    human_size(225_935)    == "226 KB"
    human_size(1_500_000)  == "1.5 MB"
    human_size(5_240_000_000) == "5.24 GB"

### `Humane::SizeFormatter.format_significant`
Rounds `value` to `sig_figs` significant figures, then trims trailing
fractional zeros (and the decimal point itself, if nothing remains after
it) -- keeps `"1.5 MB"` from becoming `"1.50 MB"` while still letting
`"5.24 GB"` keep both of its non-zero decimal digits. `magnitude` (digits
before the decimal point) uses `Math.log10(value).floor + 1` rather than
`.ceil` specifically to avoid a boundary bug at exact powers of 10.

## lib/humane/time_formatter.rb

### `Humane::TimeFormatter` (class)
Formats one time relative to another the way ActionView's
`distance_of_time_in_words` does for wording, but direction-aware like
`RelativeDateTimeFormatter` -- `"X ago"`/`"in X"`, chosen automatically
from the sign of `relative_to - at` rather than requiring the caller to
know which applies ahead of time (which is what ActionView itself
requires, and whose own `.abs` collapses future distances into a
past-tense string as a known, unfixed bug -- see this repo's original
`docs/COWORK.md` "Why this exists" section).

Now a class method (`.time_ago`), not an instantiated formatter --
`v0.6.0` and earlier mirrored `RelativeDateTimeFormatter`'s shape
(`TimeFormatter.new(approximate: true).string(...)`) on purpose; `v0.9.0`
drops that in favor of ActionView's own bare-helper-method shape
(`distance_of_time_in_words`), since the actual goal is dropping into a
Rails-style view as simply as ActionView does. Configuration moves from
constructor keyword arguments to call-site keyword arguments -- Ruby's
native kwargs make this a plain rename, not a redesign of the mechanism
(unlike Go, which needed a new `TimeOptions` type; see `humane`'s own
`docs/COMMENTS.md`).

### `approximate:` default flips `false` -> `true`
Matches ActionView's own `distance_of_time_in_words` (which has no toggle
for this at all -- always on past the hour boundary), and, checked
against real code, matches what every current consumer already passed
explicitly (`scandalous`'s `web.rb` sets `approximate: true`
unconditionally). Zero behavior change for the one real Ruby consumer;
removes required boilerplate at the call site instead. `include_seconds:`
stays `false` by default, unchanged. Ruby's keyword-argument defaults
don't have Go's zero-value struct problem here -- each keyword argument
gets its own literal default in the method signature, so there's no
single "zero value" that has to serve every field at once.

### `when_nil:`
Added in `v0.9.0` alongside `time_ago` accepting a `nil` `at`. Motivated
by `zouk`'s Swift `ScanEntry.timeAgo(relativeTo:)`, which used to guard a
possibly-unparsable timestamp itself and hand the caller a value that
still needed its own fallback one layer up -- two guard points for one
final string. `time_ago` now takes `nil` directly and a caller-supplied
`when_nil:` fallback, collapsing both layers into one call. The fallback
value stays app-specific (`nil` by default, not a hardcoded "unknown
time" baked into this gem) -- consistent with keeping ActionView-flavored
vocabulary opt-in rather than assumed, the same principle
`approximate`/`include_seconds` already follow.

### `Humane::TimeFormatter.time_ago`
Buckets are chosen from `distance_in_minutes` (seconds/60, rounded once
via Ruby's round-half-up `Float#round`), not by re-dividing raw seconds
independently per unit. The old per-unit approach let rounding carry
across a bucket boundary on its own -- 59:59:59 (< 3600s, so the old code
took the minutes branch) rounded to "60 minutes ago" instead of "1 hour
ago". Computing `distance_in_minutes` once and branching on *that* is
exactly how ActionView's own `distance_of_time_in_words` works, and is
what produces its specific, non-obvious cutoffs: the "about 1 hour"
bucket starts at 44 minutes 30 seconds (not 60:00), and "about 2 hours"
starts at 89:30, not 90:00 -- see humane-ruby issue #1
(https://github.com/woodie/humane-ruby/issues/1) for the full table this
ports, truncated here at the "1 day" row (week/month/year buckets are
out of scope -- see "Scope" in the README).

    time_ago(t, t)                        == "less than a minute ago"
    time_ago(t - 45, t)                   == "1 minute ago"
    time_ago(t - 180, t)                  == "3 minutes ago"
    time_ago(t + 180, t)                  == "in 3 minutes"
    time_ago(t - 15 * 3600, t)            == "about 15 hours ago"
    time_ago(t - 30 * 3600, t)            == "1 day ago" # no "about" -- ActionView's table has none on the day bucket
    time_ago(nil, t, when_nil: "an unknown time") == "an unknown time"
