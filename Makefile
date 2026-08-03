.PHONY: lint test check

# lint and test are always verbose. check is terse (dots on pass, full
# detail on any failure/error) -- matching Go's/Swift's own lint/test/check
# split in this family.

lint:
	bundle exec standardrb

# Verbose on purpose -- rutidy's `fs` (RSpec/Mocha-style) rendering of the
# same tree, the Ruby equivalent of Go's `ginkgo-fd -r` / Swift's
# `swift test | xctidy`.
test:
	bundle exec rutidy -fs spec

# Terser than `test` on purpose: rspec's default progress formatter prints a
# dot per passing example and suppresses per-example chatter, but always
# prints full detail for any failure.
check: lint
	bundle exec rspec spec
