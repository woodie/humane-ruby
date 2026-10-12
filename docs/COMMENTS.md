# Comments

Rationale, history, and design notes that used to live as multi-line
comments in the source. Organized by file, then by the class or method
each note is attached to. The source itself now carries at most one
short line at any given spot -- anything longer that would previously
have been a multi-line comment lives here instead.

## lib/humane/size.rb (formerly lib/humane/size_formatter.rb, renamed in v0.9.3)

### `Humane.human_size` (formerly `Humane::SizeFormatter.human_size`)
Formats byte counts the way Finder does, as a module method
(`.human_size`) rather than an instantiated formatter. Through `v0.6.0`
this mirrored `ByteCountFormatter`'s own shape (`SizeFormatter.new.string`)
on purpose. `v0.9.0` dropped instantiation -- once there was no per-instance
configuration to hold, `.new` was ceremony left over from mirroring
Foundation rather than something this design still needs. `v0.9.3` dropped
the `SizeFormatter` class itself, moving `.human_size` directly onto the
`Humane` module -- see `docs/COWORK.md`'s `v0.9.0` and `v0.9.3` entries.
Formats bytes the way Finder does:

- `0` reads `"Zero KB"`, not `"0 B"` -- a hardcoded special case;
  `ByteCountFormatter` doesn't run its usual rounding logic for zero.
- Values under 1000 spell out `"byte"`/`"bytes"` (`"1 byte"`, `"7 bytes"`)
  rather than using a `"B"` label.
- Everything else is scaled to its unit, rounded half up to that unit's
  `DECIMAL_PLACES` (`KB` 0, `MB` 1, `GB` and above 2), then has trailing
  fractional zeros trimmed (`"2 MB"`, not `"2.0 MB"`).
- If rounding reaches 1000 of a unit, the value moves up to the next unit
  and is re-rounded there: `999_999` is `"1 MB"`, not `"1000 KB"`, and
  `999_960_000` is `"1 GB"`, not `"1000 MB"`.

This is `ByteCountFormatter`'s default ("adaptive") behavior, confirmed
against real Finder output in `humane` issue #3. Earlier versions rounded
everything to 3 significant figures instead. That rule matched every
fixture the suite had at the time, but was wrong for most sizes under
10 MB (`4_132_383` is `"4.1 MB"`, not `"4.13 MB"`) and above 100 MB
(`123_456_789` is `"123.5 MB"`, not `"123 MB"`).

    human_size(0)              == "Zero KB"
    human_size(1)              == "1 byte"
    human_size(2_579)          == "3 KB"
    human_size(225_935)        == "226 KB"
    human_size(999_999)        == "1 MB"
    human_size(4_132_383)      == "4.1 MB"
    human_size(123_456_789)    == "123.5 MB"
    human_size(5_240_000_000)  == "5.24 GB"
    human_size(12_345_678_901) == "12.35 GB"

### `Humane.round_for_unit`
Rounds the scaled value with `Float#round` (half away from zero), so
`1_500` bytes is `"2 KB"`, matching Finder.

### `Humane.trim_zeros`
Formats an already-rounded value to its unit's decimal places, then trims
trailing fractional zeros (and the decimal point itself, if nothing remains
after it).

## lib/humane/time.rb (formerly lib/humane/time_formatter.rb, renamed in v0.9.3)

### `Humane.distance_in_time` (formerly `Humane::TimeFormatter.time_ago`, renamed in v0.9.3)
Formats one time relative to another the way ActionView's
`distance_of_time_in_words` does for wording, but direction-aware like
`RelativeDateTimeFormatter` -- `"X ago"`/`"in X"`, chosen automatically
from the sign of `relative_to - at` rather than requiring the caller to
know which applies ahead of time (which is what ActionView itself
requires, and whose own `.abs` collapses future distances into a
past-tense string as a known, unfixed bug -- see this repo's original
`docs/COWORK.md` "Why this exists" section).

A module method, not an instantiated formatter -- `v0.6.0` and earlier
mirrored `RelativeDateTimeFormatter`'s shape
(`TimeFormatter.new(approximate: true).string(...)`) on purpose; `v0.9.0`
dropped that in favor of ActionView's own bare-helper-method shape
(`distance_of_time_in_words`), since the actual goal is dropping into a
Rails-style view as simply as ActionView does. `v0.9.3` dropped the
`TimeFormatter` class itself (moving `.time_ago` directly onto `Humane`)
and renamed the two-argument method itself to `.distance_in_time`, adding
a new one-argument `.time_ago` convenience wrapping it with `Time.now` --
see `docs/COWORK.md`'s `v0.9.3` entry for why (the ActionView
`distance_of_time_in_words`/`time_ago_in_words` naming pair this mirrors).
Configuration moves from constructor keyword arguments to call-site
keyword arguments -- Ruby's native kwargs make this a plain rename, not a
redesign of the mechanism (unlike Go, which needed a new `TimeOptions`
type; see `humane`'s own `docs/COMMENTS.md`).

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
Added in `v0.9.0` alongside `time_ago` (now `distance_in_time`, see above)
accepting a `nil` `at`. Motivated by `zouk`'s Swift
`ScanEntry.timeAgo(relativeTo:)`, which used to guard a possibly-unparsable
timestamp itself and hand the caller a value that still needed its own
fallback one layer up -- two guard points for one final string.
`distance_in_time`/`time_ago` now take `nil` directly and a caller-supplied
`when_nil:` fallback, collapsing both layers into one call. The fallback
value stays app-specific -- not a hardcoded "unknown time" baked into this
gem -- consistent with keeping ActionView-flavored vocabulary opt-in
rather than assumed, the same principle `approximate`/`include_seconds`
already follow. Default changed from `nil` to `""` in a later pass (see
`docs/COWORK.md`) to match `humane`/`humane-swift`/`humane-kotlin`, all
three of which already defaulted to an empty string -- `nil` here was
this gem alone quietly deviating from the rest of the family, not a
Ruby-specific requirement.

### `distance_in_time`'s bucketing (formerly `Humane::TimeFormatter.time_ago`)
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

    distance_in_time(t, t)                        == "less than a minute ago"
    distance_in_time(t - 45, t)                   == "1 minute ago"
    distance_in_time(t - 180, t)                  == "3 minutes ago"
    distance_in_time(t + 180, t)                  == "in 3 minutes"
    distance_in_time(t - 15 * 3600, t)            == "about 15 hours ago"
    distance_in_time(t - 30 * 3600, t)            == "1 day ago" # no "about" -- ActionView's table has none on the day bucket
    distance_in_time(nil, t, when_nil: "an unknown time") == "an unknown time"

### `Humane.time_ago` (new in v0.9.3)
A one-argument convenience over `distance_in_time`, supplying `Time.now` as
`relative_to` -- see `docs/COWORK.md`'s `v0.9.3` entry for why. Thin
passthrough, no bucketing logic of its own; `time_ago_spec.rb` covers it
with three cases rather than re-testing everything `distance_in_time`
already does.
