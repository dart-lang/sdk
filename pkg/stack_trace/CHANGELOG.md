## 1.1.0

* Unify the parsing of Safari and Firefox stack traces. This fixes an error in
  Firefox trace parsing.

* Deprecate `Trace.parseSafari6_0`, `Trace.parseSafari6_1`,
  `Frame.parseSafari6_0`, and `Frame.parseSafari6_1`.

* Add `Frame.parseSafari`.

## 1.0.3

* Use `Zone.errorCallback` to attach stack chains to all errors without the need
  for `Chain.track`, which is now deprecated.

## 1.0.2

* Remove a workaround for [issue 17083][].

[issue 17083]: http://code.google.com/p/dart/issues/detail?id=17083

## 1.0.1

* Synchronous errors in the [Chain.capture] callback are now handled correctly.

## 1.0.0

* No API changes, just declared stable.

## 0.9.3+2

* Update the dependency on path.

* Improve the formatting of library URIs in stack traces.

## 0.9.3+1

* If an error is thrown in `Chain.capture`'s `onError` handler, that error is
  handled by the parent zone. This matches the behavior of `runZoned` in
  `dart:async`.

## 0.9.3

* Add a `Chain.foldFrames` method that parallels `Trace.foldFrames`.

* Record anonymous method frames in IE10 as "<fn>".
