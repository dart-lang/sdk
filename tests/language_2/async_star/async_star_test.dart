// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() async {
  asyncStart();
  // Normal operations.
  {
    Stream<int> f() async* {
      yield 1;
      yield 2;
      yield 3;
    }

    Expect.listEquals([1, 2, 3], await f().toList(), "basic1");
  }

  {
    Stream<int> f() async* {
      yield 1;
      yield 2;
      yield 3;
    }

    var log = [];
    var completer = Completer();
    f().listen(log.add,
        onError: (e) {
          // Shouldn't be reached.
          completer.complete(new Future.sync(() {
            Expect.fail("$e");
          }));
        },
        onDone: () => completer.complete(null));
    await completer.future;
    Expect.listEquals([1, 2, 3], log, "basic2");
  }

  {
    var log = [];
    Stream<int> f() async* {
      log.add("-1");
      yield 1;
      log.add("-2");
      yield 2;
    }

    await f().forEach((e) {
      log.add("+$e");
    });
    Expect.listEquals(["-1", "+1", "-2", "+2"], log, "basic3");
  }

  {
    var log = [];
    Stream<int> f() async* {
      log.add("-1");
      yield 1;
      log.add("-2");
      yield 2;
    }

    await for (var e in f()) {
      log.add("+$e");
    }
    Expect.listEquals(["-1", "+1", "-2", "+2"], log, "basic4");
  }

  // async
  {
    Stream<int> f() async* {
      yield 1;
      await Future(() {});
      yield 2;
      await Future(() {});
      yield 3;
    }

    Expect.listEquals([1, 2, 3], await f().toList(), "async");
  }

  // Yield*
  {
    Stream<int> f(n) async* {
      yield n;
      if (n == 0) return;
      yield* f(n - 1);
      yield n;
    }

    Expect.listEquals([3, 2, 1, 0, 1, 2, 3], await f(3).toList(), "yield*");
  }

  // Errors
  {
    var log = [];
    Stream<int> f() async* {
      yield 1;
      throw "error";
    }

    await f().handleError((e) {
      log.add(e);
    }).forEach(log.add);
    Expect.listEquals([1, "error"], log, "error");
  }

  {
    var log = [];
    Stream<int> f() async* {
      yield 1;
      yield* Future<int>.error("error").asStream(); // Emits error as error.
      yield 3;
    }

    await f().handleError((e) {
      log.add(e);
    }).forEach(log.add);
    Expect.listEquals([1, "error", 3], log, "error2");
  }

  // Pause is checked after delivering event.
  {
    var log = [];
    Stream<int> f() async* {
      log.add("-1");
      yield 1;
      log.add("-2");
      yield 2;
    }

    var completer = Completer();
    var s;
    s = f().listen((e) {
      log.add("+$e");
      s.pause(Future(() {}));
      log.add("++$e");
    }, onError: (e) {
      completer.complete(new Future.sync(() {
        Expect.fail("$e");
      }));
    }, onDone: () => completer.complete(null));
    await completer.future;
    Expect.listEquals(["-1", "+1", "++1", "-2", "+2", "++2"], log, "pause");
  }

  // Await for-loop pauses between events.
  {
    var log = [];
    Stream<int> f() async* {
      log.add("-1");
      yield 1;
      log.add("-2");
      yield 2;
    }

    await for (var e in f()) {
      log.add("+$e");
      await Future(() {}); // One timer tick.
      log.add("++$e");
    }
    Expect.listEquals(["-1", "+1", "++1", "-2", "+2", "++2"], log, "looppause");
  }

  // Await for-loop break works immediately.
  {
    var log = [];
    Stream<int> f() async* {
      try {
        log.add("-1");
        yield 1;
        log.add("-2");
        yield 2;
        log.add("-3");
        yield 3;
      } finally {
        log.add("x");
      }
    }

    await for (var e in f()) {
      log.add("+$e");
      await Future(() {}); // One timer tick, pauses function at yield.
      log.add("++$e");
      if (e == 2) break;
    }
    Expect.listEquals(
        ["-1", "+1", "++1", "-2", "+2", "++2", "x"], log, "loop-pause-break");
  }
  asyncEnd();
}
