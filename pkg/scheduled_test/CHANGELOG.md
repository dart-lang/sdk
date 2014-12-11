## 0.11.5

* Bump the version constraint for `unittest`.

## 0.11.4

* Bump the version constraint for `unittest`.

## 0.11.3

* Narrow the constraint on unittest to ensure that new features are reflected in
  scheduled_test's version.

## 0.11.2+3

* Ignore hidden files in `DirectoryDescriptor.fromFilesystem`.

## 0.11.2+2

* Moved shared test utilities to `metatest` package.

## 0.11.2+1

* Fix a case where a `ScheduledProcess` could fail to log its output.

## 0.11.2

* Add a `DirectoryDescriptor.fromFilesystem` constructor.

## 0.11.1

* Add a top-level `tearDown` function.

## 0.11.0+7

* A `nothing()` descriptor will fail if a broken symlink is present.

## 0.11.0+6

* Use `http_multi_server` to bind to both the IPv4 and IPv6 loopback addresses
  for scheduled_test.

## 0.11.0+5

* Widen the version constraint for `stack_trace`.

## 0.11.0+4

* Added `README.md` with content from `lib/scheduled_test.dart`.

* Made changes to `test/metatest.dart` related to outstanding issues.

## 0.11.0+3

* Support `v0.11.0` of `unittest`.

## 0.11.0+1

* Support `v0.5.0` of `shelf`.

## 0.11.0

* `ScheduledServer.handle` now takes a `shelf.Handler` rather than a custom
  handler class.

* The body of a `test()` or a `setUp()` call may now return a Future. This was
  already supported by the `unittest` package. The Future is passed to a
  `wrapFuture` call.

## 0.10.1+1

* Updated `http` version constraint from `">=0.9.0 <0.10.0"` to
  `">=0.9.0 <0.11.0"`

## 0.10.1

* Add a `StreamMatcher.hasMatch` method.

* The `consumeThrough` and `consumeWhile` matchers for `ScheduledStream` now
  take `StreamMatcher`s as well as normal `Matcher`s.

## 0.10.0

* Convert `ScheduledProcess` to expose `stdout` and `stderr` as
  `ScheduledStream`s.

* Add a `consumeWhile` matcher for `ScheduledStream`.
