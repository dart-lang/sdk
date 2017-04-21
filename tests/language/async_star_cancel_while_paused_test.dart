// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for issue 22853.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() {
  var list = [];
  var sync = new Sync();
  f() async* {
    list.add("*1");
    yield 1;
    await sync.wait();
    sync.release();
    list.add("*2");
    yield 2;
    list.add("*3");
  }

  ;
  var stream = f();
  var sub = stream.listen(list.add);

  asyncStart();
  return sync.wait().whenComplete(() {
    Expect.listEquals(list, ["*1", 1]);
    sub.pause();
    return sync.wait();
  }).whenComplete(() {
    Expect.listEquals(list, ["*1", 1, "*2"]);
    sub.cancel();
    new Future.delayed(new Duration(milliseconds: 200), () {
      // Should not have yielded 2 or added *3 while paused.
      Expect.listEquals(list, ["*1", 1, "*2"]);
      asyncEnd();
    });
  });
}

/**
 * Allows two asynchronous executions to synchronize.
 *
 * Calling [wait] and waiting for the returned future to complete will
 * wait for the other executions to call [wait] again. At that point,
 * the waiting execution is allowed to continue (the returned future completes),
 * and the more recent call to [wait] is now the waiting execution.
 */
class Sync {
  Completer _completer = null;
  // Release whoever is currently waiting and start waiting yourself.
  Future wait([v]) {
    if (_completer != null) _completer.complete(v);
    _completer = new Completer();
    return _completer.future;
  }

  // Release whoever is currently waiting.
  void release([v]) {
    if (_completer != null) {
      _completer.complete(v);
      _completer = null;
    }
  }
}
