# Comments

Rationale, history, and design notes that used to live as multi-line
comments in the source. Organized by file, then by the class or method
each note is attached to. The source itself now carries at most one
short line at any given spot -- anything longer that would previously
have been a multi-line comment lives here instead.

## lib/humane/size_formatter.rb

### `Humane::SizeFormatter` (class)
Formats byte counts the way Finder does: 1000-based math, capitalized
unit labels, rounded to 2 significant digits. Not the SI-correct
lowercase "kB" (that's what number_to_human_size's siblings in other
languages get wrong the other way), and not 1024-based math under a
"KB" label (that's what Rails' number_to_human_size gets wrong).

### `Humane::SizeFormatter#string`
Returns from_byte_count as a Finder-style human-readable string.

    string(from_byte_count: 79_992)    == "80 KB"
    string(from_byte_count: 225_935)   == "226 KB"
    string(from_byte_count: 1_500_000) == "1.5 MB"

## lib/humane/time_formatter.rb

### `Humane::TimeFormatter` (class)
Formats one time relative to another the way RelativeDateTimeFormatter
does: asymmetric "X ago" / "in X" phrasing, no "about" prefix on the hour
bucket by default. An earlier version used symmetric "X ago" / "X from
now" wording, billed as a "deliberate departure" -- but that departure
wasn't earning its keep against this library's actual goal (match what
RelativeDateTimeFormatter, the API this is modeled on, actually outputs),
so it was reverted. `approximate: true` (v0.4.0, see below) opts into
the "about" prefix for contexts that can't earn back the precision --
still off by default, since matching Foundation's raw output is the
baseline this library is held to.

### `Humane::TimeFormatter#initialize`
include_seconds: false (the default) renders any duration under 30
seconds as "less than a minute ago"/"in less than a minute" instead of
counting seconds -- matching the first row of ActionView's
distance_of_time_in_words bucket table (see #string below), not an
arbitrary round number. The future phrasing follows the same asymmetric
"in X" pattern as the counted buckets below. Named and defaulted after
ActionView's own include_seconds (v0.3.0, renamed from
collapse_minute: true -- an exact polarity inversion, so the default
behavior is unchanged; see docs/releases/v0.3.0.md).

approximate: false (the default) prefixes "about"/"in about" onto the
hour-scale buckets (1 hour, and 2..24 hours) when true, matching
ActionView's distance_of_time_in_words wording for those exact buckets
-- for a static render (a web response, a cached page) that can't
live-refresh, exact-looking precision on a rounded value is misleading.
Deliberately narrower than the "any bucket >= 1 hour" rule this had in
v0.4.0: ActionView's own table has no "about" on the day bucket (or
week/month/year buckets beyond this library's scope), so neither does
this. Ported from humane-swift's identically-named option (v0.1.0);
this Ruby port is simpler than Swift's, since `text` is built bare here
(no "ago"/"in " wrapping yet) -- prefixing "about " before that wrapping
composes correctly for both directions with no string-surgery needed.

### `Humane::TimeFormatter#string`
Swift's localizedString(for:relativeTo:) uses "for:" as its first
argument label; Ruby's "for" is a reserved word, and while
`def string(for:, ...)` parses, reading the bound value back out inside
the method needs `binding.local_variable_get(:for)` since a bare `for`
triggers the keyword parser -- not worth it for a label match. "at:"
reads just as naturally: "the string for the time AT this moment,
RELATIVE TO that one".

Buckets are chosen from `distance_in_minutes` (seconds/60, rounded
once via Ruby's round-half-up `Float#round`), not by re-dividing raw
seconds independently per unit. The old per-unit approach let rounding
carry across a bucket boundary on its own -- 59:59:59 (< 3600s, so the
old code took the minutes branch) rounded to "60 minutes ago" instead
of "1 hour ago". Computing distance_in_minutes once and branching on
*that* is exactly how ActionView's own distance_of_time_in_words works,
and is what produces its specific, non-obvious cutoffs: the "about 1
hour" bucket starts at 44 minutes 30 seconds (not 60:00), and "about 2
hours" starts at 89:30, not 90:00 -- see humane-ruby issue #1
(https://github.com/woodie/humane-ruby/issues/1) for the full table
this ports, truncated here at the "1 day" row (week/month/year buckets
are out of scope -- see "Design decisions" in docs/COWORK.md).

    string(at: t, relative_to: t)                    == "less than a minute ago"
    string(at: t - 45, relative_to: t)                == "1 minute ago"
    string(at: t - 180, relative_to: t)               == "3 minutes ago"
    string(at: t + 180, relative_to: t)               == "in 3 minutes"
    string(at: t - (44 * 60 + 29), relative_to: t)    == "44 minutes ago"
    string(at: t - (44 * 60 + 30), relative_to: t)    == "1 hour ago"
    string(at: t - 15 * 3600, relative_to: t)         == "15 hours ago"
    string(at: t - 30 * 3600, relative_to: t)         == "1 day ago"

    approx = Humane::TimeFormatter.new(approximate: true)
    approx.string(at: t - (44 * 60 + 30), relative_to: t) == "about 1 hour ago"
    approx.string(at: t - 15 * 3600, relative_to: t)      == "about 15 hours ago"
    approx.string(at: t - 30 * 3600, relative_to: t)      == "1 day ago"  # no "about" -- ActionView's table has none on the day bucket
