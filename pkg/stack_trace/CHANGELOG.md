## 0.9.3+1

* If an error is thrown in `Chain.capture`'s `onError` handler, that error is
  handled by the parent zone. This matches the behavior of `runZoned` in
  `dart:async`.

## 0.9.3

* Add a `Chain.foldFrames` method that parallels `Trace.foldFrames`.

* Record anonymous method frames in IE10 as "<fn>".
