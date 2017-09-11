// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  x() async {
    print("Starting!");
    try {
      await runAsync();
    } catch (e, st) {
      print("Got exception and stacktrace:");
      var stText = st.toString();
      print(e);
      print(stText);
      // Stacktrace should be something like
      // #0      runAsync.<runAsync_async_body> (this file)
      // #1      Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184)
      // #2      _microtaskLoop (dart:async/schedule_microtask.dart:41)
      // #3      _startMicrotaskLoop (dart:async/schedule_microtask.dart:50)
      // #4      _runPendingImmediateCallback (dart:isolate-patch/isolate_patch.dart:96)
      // #5      _RawReceivePortImpl._handleMessage (dart:isolate-patch/isolate_patch.dart:149)

      // if exception and stacktrace is rethrown correctly, NOT

      // #0      main.<anonymous closure>.async_op (this file)
      // #1      _asyncErrorWrapperHelper.<anonymous closure> (dart:async:134:33)
      // #2      _RootZone.runBinary (dart:async/zone.dart:1410:54)
      // #3      _FutureListener.handleError (dart:async/future_impl.dart:146:20)
      // #4      _Future._propagateToListeners.handleError (dart:async/future_impl.dart:649:47)
      // #5      _Future._propagateToListeners (dart:async/future_impl.dart:671:13)
      // #6      _Future._completeError (dart:async/future_impl.dart:485:5)
      // #7      _SyncCompleter._completeError (dart:async/future_impl.dart:56:12)
      // #8      _Completer.completeError (dart:async/future_impl.dart:27:5)
      // #9      runAsync.async_op (this file)
      // #10     Future.Future.microtask.<anonymous closure> (dart:async/future.dart:184:26)
      // #11     _microtaskLoop (dart:async/schedule_microtask.dart:41:5)
      // #12     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50:5)
      // #13     _runPendingImmediateCallback (dart:isolate:1054:5)
      // #14     _RawReceivePortImpl._handleMessage (dart:isolate:1104:5)

      Expect.isFalse(stText.contains("propagateToListeners"));
      Expect.isFalse(stText.contains("_completeError"));
    }
    print("Ending!");
  }

  asyncStart();
  x().then((_) => asyncEnd());
}

runAsync() async {
  throw 'oh no!';
}
