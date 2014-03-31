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
