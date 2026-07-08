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
Formats one time relative to another the way Finder-adjacent tools do:
symmetric "X ago" / "X from now" phrasing, no "about" prefix on the hour
bucket -- a deliberate departure from RelativeDateTimeFormatter's actual
asymmetric output ("X ago" / "in X"), not an attempt to reproduce it
verbatim.

### `Humane::TimeFormatter#initialize`
collapse_minute renders any duration under 60 seconds as "less than a
minute ago"/"less than a minute from now" instead of counting seconds.
Defaults to true -- Rails' distance_of_time_in_words, Go's
justincampbell/timeago, and zouk's own RelativeDateTimeFormatter wrapper
all do this in practice; Swift's formatter has no such bucket natively,
so there's no "pure" behavior being overridden here.

### `Humane::TimeFormatter#string`
Swift's localizedString(for:relativeTo:) uses "for:" as its first
argument label; Ruby's "for" is a reserved word, and while
`def string(for:, ...)` parses, reading the bound value back out inside
the method needs `binding.local_variable_get(:for)` since a bare `for`
triggers the keyword parser -- not worth it for a label match. "at:"
reads just as naturally: "the string for the time AT this moment,
RELATIVE TO that one".

    string(at: t, relative_to: t)             == "less than a minute ago"
    string(at: t - 180, relative_to: t)       == "3 minutes ago"
    string(at: t + 180, relative_to: t)       == "3 minutes from now"
    string(at: t - 15 * 3600, relative_to: t) == "15 hours ago"
    string(at: t - 30 * 3600, relative_to: t) == "1 day ago"
