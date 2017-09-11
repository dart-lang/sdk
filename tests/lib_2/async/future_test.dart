// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_test;

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

const Duration MS = const Duration(milliseconds: 1);

void testValue() {
  final future = new Future<String>.value("42");
  asyncStart();
  future.then((x) {
    Expect.equals("42", x);
    asyncEnd();
  });
}

void testSync() {
  compare(func) {
    // Compare the results of the following two futures.
    Future f1 = new Future.sync(func);
    Future f2 = new Future.value().then((_) => func());
    f2.catchError((_) {}); // I'll get the error later.
    f1.then((v1) {
      f2.then((v2) {
        Expect.equals(v1, v2);
      });
    }, onError: (e1) {
      f2.then((_) {
        Expect.fail("Expected error");
      }, onError: (e2) {
        Expect.equals(e1, e2);
      });
    });
  }

  Future val = new Future.value(42);
  Future err1 = new Future.error("Error")..catchError((_) {});
  try {
    throw new List(0);
  } catch (e, st) {
    Future err2 = new Future.error(e, st)..catchError((_) {});
  }
  compare(() => 42);
  compare(() => val);
  compare(() {
    throw "Flif";
  });
  compare(() => err1);
  bool hasExecuted = false;
  compare(() {
    hasExecuted = true;
    return 499;
  });
  Expect.isTrue(hasExecuted);
}

void testNeverComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  future.then((v) => Expect.fail("Value not expected"));
  future.catchError((e) => Expect.fail("Value not expected"));
}

void testComplete() {
  final completer = new Completer<int>();
  final future = completer.future;
  Expect.isFalse(completer.isCompleted);

  completer.complete(3);
  Expect.isTrue(completer.isCompleted);

  future.then((v) => Expect.equals(3, v));
}

// Tests for [then]

void testCompleteWithSuccessHandlerBeforeComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int after;

  asyncStart();
  future.then((int v) {
    after = v;
  }).then((_) {
    Expect.equals(3, after);
    asyncEnd();
  });

  completer.complete(3);
  Expect.isNull(after);
}

void testCompleteWithSuccessHandlerAfterComplete() {
  final completer = new Completer<int>();
  final future = completer.future;

  int after;
  completer.complete(3);
  Expect.isNull(after);

  asyncStart();
  future.then((int v) {
    after = v;
  }).then((_) {
    Expect.equals(3, after);
    asyncEnd();
  });
}

void testCompleteManySuccessHandlers() {
  final completer = new Completer<int>();
  final future = completer.future;
  int before;
  int after1;
  int after2;

  var futures = <Future<int>>[];
  futures.add(future.then((int v) {
    before = v;
  }));
  completer.complete(3);
  futures.add(future.then((int v) {
    after1 = v;
  }));
  futures.add(future.then((int v) {
    after2 = v;
  }));

  asyncStart();
  Future.wait(futures).then((_) {
    Expect.equals(3, before);
    Expect.equals(3, after1);
    Expect.equals(3, after2);
    asyncEnd();
  });
}

// Tests for [catchError]

void testException() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  asyncStart();
  future.then((v) {
    throw "Value not expected";
  }).catchError((error) {
    Expect.equals(error, ex);
    asyncEnd();
  }, test: (e) => e == ex);
  completer.completeError(ex);
}

void testExceptionHandler() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  var ex2;
  var done = future.catchError((error) {
    ex2 = error;
  });

  Expect.isFalse(completer.isCompleted);
  completer.completeError(ex);
  Expect.isTrue(completer.isCompleted);

  asyncStart();
  done.then((_) {
    Expect.equals(ex, ex2);
    asyncEnd();
  });
}

void testExceptionHandlerReturnsTrue() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  future.catchError((e) {});
  future.catchError((e) {
    reached = true;
  }, test: (e) => false).catchError((e) {});
  Expect.isFalse(completer.isCompleted);
  completer.completeError(ex);
  Expect.isTrue(completer.isCompleted);
  Expect.isFalse(reached);
}

void testExceptionHandlerReturnsTrue2() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;
  var done = future.catchError((e) {}, test: (e) => false).catchError((e) {
    reached = true;
  });
  completer.completeError(ex);

  asyncStart();
  done.then((_) {
    Expect.isTrue(reached);
    asyncEnd();
  });
}

void testExceptionHandlerReturnsFalse() {
  final completer = new Completer<int>();
  final future = completer.future;
  final ex = new Exception();

  bool reached = false;

  future.catchError((e) {});

  future.catchError((e) {
    reached = true;
  }, test: (e) => false).catchError((e) {});

  completer.completeError(ex);

  Expect.isFalse(reached);
}

void testFutureAsStreamCompleteAfter() {
  var completer = new Completer();
  bool gotValue = false;
  asyncStart();
  completer.future.asStream().listen((data) {
    Expect.isFalse(gotValue);
    gotValue = true;
    Expect.equals("value", data);
  }, onDone: () {
    Expect.isTrue(gotValue);
    asyncEnd();
  });
  completer.complete("value");
}

void testFutureAsStreamCompleteBefore() {
  var completer = new Completer();
  bool gotValue = false;
  asyncStart();
  completer.complete("value");
  completer.future.asStream().listen((data) {
    Expect.isFalse(gotValue);
    gotValue = true;
    Expect.equals("value", data);
  }, onDone: () {
    Expect.isTrue(gotValue);
    asyncEnd();
  });
}

void testFutureAsStreamCompleteImmediate() {
  bool gotValue = false;
  asyncStart();
  new Future.value("value").asStream().listen((data) {
    Expect.isFalse(gotValue);
    gotValue = true;
    Expect.equals("value", data);
  }, onDone: () {
    Expect.isTrue(gotValue);
    asyncEnd();
  });
}

void testFutureAsStreamCompleteErrorAfter() {
  var completer = new Completer();
  bool gotError = false;
  asyncStart();
  completer.future.asStream().listen((data) {
    Expect.fail("Unexpected data");
  }, onError: (error) {
    Expect.isFalse(gotError);
    gotError = true;
    Expect.equals("error", error);
  }, onDone: () {
    Expect.isTrue(gotError);
    asyncEnd();
  });
  completer.completeError("error");
}

void testFutureAsStreamWrapper() {
  var completer = new Completer();
  bool gotValue = false;
  asyncStart();
  completer.complete("value");
  completer.future
      .catchError((_) {
        throw "not possible";
      }) // Returns a future wrapper.
      .asStream()
      .listen((data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      }, onDone: () {
        Expect.isTrue(gotValue);
        asyncEnd();
      });
}

void testFutureWhenCompleteValue() {
  asyncStart();
  int counter = 2;
  countDown() {
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(countDown);
  later.then((v) {
    Expect.equals(42, v);
    countDown();
  });
  completer.complete(42);
}

void testFutureWhenCompleteError() {
  asyncStart();
  int counter = 2;
  countDown() {
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(countDown);
  later.catchError((error) {
    Expect.equals("error", error);
    countDown();
  });
  completer.completeError("error");
}

void testFutureWhenCompleteValueNewError() {
  asyncStart();
  int counter = 2;
  countDown() {
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(() {
    countDown();
    throw "new error";
  });
  later.catchError((error) {
    Expect.equals("new error", error);
    countDown();
  });
  completer.complete(42);
}

void testFutureWhenCompleteErrorNewError() {
  asyncStart();
  int counter = 2;
  countDown() {
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(() {
    countDown();
    throw "new error";
  });
  later.catchError((error) {
    Expect.equals("new error", error);
    countDown();
  });
  completer.completeError("error");
}

void testFutureWhenCompletePreValue() {
  asyncStart();
  int counter = 2;
  countDown() {
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  Future future = completer.future;
  completer.complete(42);
  Timer.run(() {
    Future later = future.whenComplete(countDown);
    later.then((v) {
      Expect.equals(42, v);
      countDown();
    });
  });
}

void testFutureWhenValueFutureValue() {
  asyncStart();
  int counter = 3;
  countDown(int expect) {
    Expect.equals(expect, counter);
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  completer.future.whenComplete(() {
    countDown(3);
    var completer2 = new Completer();
    new Timer(MS * 10, () {
      countDown(2);
      completer2.complete(37);
    });
    return completer2.future;
  }).then((v) {
    Expect.equals(42, v);
    countDown(1);
  });

  completer.complete(42);
}

void testFutureWhenValueFutureError() {
  asyncStart();
  int counter = 3;
  countDown(int expect) {
    Expect.equals(expect, counter);
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  completer.future.whenComplete(() {
    countDown(3);
    var completer2 = new Completer();
    new Timer(MS * 10, () {
      countDown(2);
      completer2.completeError("Fail");
    });
    return completer2.future;
  }).then((v) {
    Expect.fail("should fail async");
  }, onError: (error) {
    Expect.equals("Fail", error);
    countDown(1);
  });

  completer.complete(42);
}

void testFutureWhenErrorFutureValue() {
  asyncStart();
  int counter = 3;
  countDown(int expect) {
    Expect.equals(expect, counter);
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  completer.future.whenComplete(() {
    countDown(3);
    var completer2 = new Completer();
    new Timer(MS * 10, () {
      countDown(2);
      completer2.complete(37);
    });
    return completer2.future;
  }).then((v) {
    Expect.fail("should fail async");
  }, onError: (error) {
    Expect.equals("Error", error);
    countDown(1);
  });

  completer.completeError("Error");
}

void testFutureWhenErrorFutureError() {
  asyncStart();
  int counter = 3;
  countDown(int expect) {
    Expect.equals(expect, counter);
    if (--counter == 0) asyncEnd();
  }

  var completer = new Completer();
  completer.future.whenComplete(() {
    countDown(3);
    var completer2 = new Completer();
    new Timer(MS * 10, () {
      countDown(2);
      completer2.completeError("Fail");
    });
    return completer2.future;
  }).then((v) {
    Expect.fail("should fail async");
  }, onError: (error) {
    Expect.equals("Fail", error);
    countDown(1);
  });

  completer.completeError("Error");
}

void testFutureThenThrowsAsync() {
  final completer = new Completer<int>();
  final future = completer.future;
  int error = 42;

  asyncStart();
  future.then((v) {
    throw error;
  }).catchError((e) {
    Expect.identical(error, e);
    asyncEnd();
  });
  completer.complete(0);
}

void testFutureCatchThrowsAsync() {
  final completer = new Completer<int>();
  final future = completer.future;
  int error = 42;

  asyncStart();
  future.catchError((e) {
    throw error;
  }).catchError((e) {
    Expect.identical(error, e);
    asyncEnd();
  });
  completer.completeError(0);
}

void testFutureCatchRethrowsAsync() {
  final completer = new Completer<int>();
  final future = completer.future;
  var error;

  asyncStart();
  future.catchError((e) {
    error = e;
    throw e;
  }).catchError((e) {
    Expect.identical(error, e);
    asyncEnd();
  });
  completer.completeError(0);
}

void testFutureWhenThrowsAsync() {
  final completer = new Completer<int>();
  final future = completer.future;
  var error = 42;

  asyncStart();
  future.whenComplete(() {
    throw error;
  }).catchError((e) {
    Expect.identical(error, e);
    asyncEnd();
  });
  completer.complete(0);
}

void testCompleteWithError() {
  final completer = new Completer<int>();
  final future = completer.future;
  var error = 42;

  asyncStart();
  future.catchError((e) {
    Expect.identical(error, e);
    asyncEnd();
  });

  completer.completeError(error);
}

void testCompleteWithFutureSuccess() {
  asyncStart();
  final completer = new Completer<int>();
  final completer2 = new Completer<int>();
  completer.complete(completer2.future);
  completer.future.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
  completer2.complete(42);
}

void testCompleteWithFutureSuccess2() {
  asyncStart();
  final completer = new Completer<int>();
  final result = new Future<int>.value(42);
  completer.complete(result);
  completer.future.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
}

void testCompleteWithFutureError() {
  asyncStart();
  final completer = new Completer<int>();
  final completer2 = new Completer<int>();
  completer.complete(completer2.future);
  completer.future.then((v) {
    Expect.fail("Should not happen");
    asyncEnd();
  }, onError: (e) {
    Expect.equals("ERROR-tcwfe", e);
    asyncEnd();
  });
  completer2.completeError("ERROR-tcwfe");
}

void testCompleteWithFutureError2() {
  asyncStart();
  final completer = new Completer<int>();
  var result = new Future<int>.error("ERROR-tcwfe2");
  completer.complete(result);
  completer.future.then((v) {
    Expect.fail("Should not happen");
    asyncEnd();
  }, onError: (e) {
    Expect.equals("ERROR-tcwfe2", e);
    asyncEnd();
  });

}

void testCompleteErrorWithFuture() {
  asyncStart();
  final completer = new Completer<int>();
  completer.completeError(new Future.value(42));
  completer.future.then((_) {
    Expect.fail("Shouldn't happen");
  }, onError: (e, s) {
    Future f = e;
    f.then((v) {
      Expect.equals(42, v);
      asyncEnd();
    });
  });
}

void testCompleteWithCustomFutureSuccess() {
  asyncStart();
  final completer = new Completer<int>();
  final completer2 = new Completer<int>();
  completer.complete(new CustomFuture(completer2.future));
  completer.future.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
  completer2.complete(42);
}

void testCompleteWithCustomFutureError() {
  asyncStart();
  final completer = new Completer<int>();
  final completer2 = new Completer<int>();
  completer.complete(new CustomFuture(completer2.future));
  completer.future.then((v) {
    Expect.fail("Should not happen");
    asyncEnd();
  }, onError: (e) {
    Expect.equals("ERROR-tcwcfe", e);
    asyncEnd();
  });
  completer2.completeError("ERROR-tcwcfe");
}

void testCompleteErrorWithCustomFuture() {
  asyncStart();
  final completer = new Completer<int>();
  var future = new CustomFuture(new Future.value(42));
  completer.completeError(future);
  completer.future.then((_) {
    Expect.fail("Shouldn't happen");
  }, onError: (Future f) {
    f.then((v) {
      Expect.equals(42, v);
      asyncEnd();
    });
  });
}

void testCompleteErrorWithNull() {
  asyncStart();
  final completer = new Completer<int>();
  completer.future.catchError((e) {
    Expect.isTrue(e is NullThrownError);
    asyncEnd();
  });
  completer.completeError(null);
}

void testChainedFutureValue() {
  final completer = new Completer();
  final future = completer.future;
  asyncStart();

  future.then((v) => new Future.value(v * 2)).then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
  completer.complete(21);
}

void testChainedFutureValueDelay() {
  final completer = new Completer();
  final future = completer.future;
  asyncStart();

  future
      .then((v) =>
          new Future.delayed(const Duration(milliseconds: 10), () => v * 2))
      .then((v) {
    Expect.equals(42, v);
    asyncEnd();
  });
  completer.complete(21);
}

void testChainedFutureValue2Delay() {
  asyncStart();

  new Future.delayed(const Duration(milliseconds: 10)).then((v) {
    Expect.isNull(v);
    asyncEnd();
  });
}

void testChainedFutureError() {
  final completer = new Completer();
  final future = completer.future;
  asyncStart();

  future.then((v) => new Future.error("Fehler")).then((v) {
    Expect.fail("unreachable!");
  }, onError: (error) {
    Expect.equals("Fehler", error);
    asyncEnd();
  });
  completer.complete(21);
}

void testSyncFuture_i13368() {
  asyncStart();

  final future = new Future<int>.sync(() {
    return new Future<int>.value(42);
  });

  future.then((int val) {
    Expect.equals(val, 42);
    asyncEnd();
  });
}

void testWaitCleanUp() {
  asyncStart();
  // Creates three futures with different completion times, and where some fail.
  // The `mask` specifies which futures fail (values 1-7),
  // and `permute` defines the order of completion. values 0-5.
  void doTest(int mask, int permute) {
    asyncStart();
    String stringId = "waitCleanup-$mask-$permute";
    List<Future> futures = new List(3);
    List cleanup = new List(3);
    int permuteTmp = permute;
    for (int i = 0; i < 3; i++) {
      bool throws = (mask & (1 << i)) != 0;
      var future = new Future.delayed(new Duration(milliseconds: 100 * (i + 1)),
          () => (throws ? throw "Error $i($mask-$permute)" : i));
      int mod = 3 - i;
      int position = permuteTmp % mod;
      permuteTmp = permuteTmp ~/ mod;
      while (futures[position] != null) position++;
      futures[position] = future;
      cleanup[i] = throws;
    }
    void cleanUp(index) {
      Expect.isFalse(cleanup[index]);
      cleanup[index] = true;
    }

    Future.wait(futures, cleanUp: cleanUp).then((_) {
      Expect.fail("No error: $stringId");
    }, onError: (e, s) {
      Expect.listEquals([true, true, true], cleanup);
      asyncEnd();
    });
  }

  for (int i = 1; i < 8; i++) {
    for (int j = 0; j < 6; j++) {
      doTest(i, j);
    }
  }
  asyncEnd();
}

void testWaitCleanUpEager() {
  asyncStart();
  // Creates three futures with different completion times, and where some fail.
  // The `mask` specifies which futures fail (values 1-7),
  // and `permute` defines the order of completion. values 0-5.
  void doTest(int mask, int permute) {
    asyncStart();
    asyncStart();
    bool done = false;
    String stringId = "waitCleanup-$mask-$permute";
    List<Future> futures = new List<Future>(3);
    List cleanup = new List(3);
    int permuteTmp = permute;
    for (int i = 0; i < 3; i++) {
      bool throws = (mask & (1 << i)) != 0;
      var future = new Future.delayed(new Duration(milliseconds: 100 * (i + 1)),
          () => (throws ? throw "Error $i($mask-$permute)" : i));
      int mod = 3 - i;
      int position = permuteTmp % mod;
      permuteTmp = permuteTmp ~/ mod;
      while (futures[position] != null) position++;
      futures[position] = future;
      cleanup[i] = throws;
    }
    void checkDone() {
      if (done) return;
      if (cleanup.every((v) => v)) {
        done = true;
        asyncEnd();
      }
    }

    void cleanUp(index) {
      Expect.isFalse(cleanup[index]);
      cleanup[index] = true;
      // Cleanup might happen before and after the wait().then() callback.
      checkDone();
    }

    Future.wait(futures, eagerError: true, cleanUp: cleanUp).then((_) {
      Expect.fail("No error: $stringId");
    }, onError: (e, s) {
      asyncEnd();
      checkDone();
    });
  }

  for (int i = 1; i < 8; i++) {
    for (int j = 0; j < 6; j++) {
      doTest(i, j);
    }
  }
  asyncEnd();
}

void testWaitCleanUpError() {
  var cms = const Duration(milliseconds: 100);
  var cleanups = new List.filled(3, false);
  var uncaughts = new List.filled(3, false);
  asyncStart();
  asyncStart();
  asyncStart();
  runZoned(() {
    Future.wait([
      new Future.delayed(cms, () => 0),
      new Future.delayed(cms * 2, () => throw 1),
      new Future.delayed(cms * 3, () => 2)
    ], cleanUp: (index) {
      Expect.isTrue(index == 0 || index == 2, "$index");
      Expect.isFalse(cleanups[index]);
      cleanups[index] = true;
      throw index;
    }).catchError((e) {
      Expect.equals(e, 1);
      asyncEnd();
    });
  }, onError: (int index, s) {
    Expect.isTrue(index == 0 || index == 2, "$index");
    Expect.isFalse(uncaughts[index]);
    uncaughts[index] = true;
    asyncEnd();
  });
}

void testWaitSyncError() {
  var cms = const Duration(milliseconds: 100);
  var cleanups = new List.filled(3, false);
  asyncStart();
  asyncStart();
  runZoned(() {
    Future.wait(
        new Iterable.generate(5, (i) {
          if (i != 3) return new Future.delayed(cms * (i + 1), () => i);
          throw "throwing synchronously in iterable";
        }), cleanUp: (index) {
      Expect.isFalse(cleanups[index]);
      cleanups[index] = true;
      if (cleanups.every((x) => x)) asyncEnd();
    });
  }, onError: (e, s) {
    asyncEnd();
  });
}

void testWaitSyncError2() {
  asyncStart();
  Future.wait([null]).catchError((e, st) {
    // Makes sure that the `catchError` is invoked.
    // Regression test: an earlier version of `Future.wait` would propagate
    // the error too soon for the code to install an error handler.
    // `testWaitSyncError` didn't show this problem, because the `runZoned`
    // was already installed.
    asyncEnd();
  });
}

// Future.wait transforms synchronous errors into asynchronous ones.
// This function tests that zones can intercept them.
void testWaitSyncError3() {
  var caughtError;
  var count = 0;

  AsyncError errorCallback(Zone self, ZoneDelegate parent, Zone zone,
      Object error, StackTrace stackTrace) {
    Expect.equals(0, count);
    count++;
    caughtError = error;
    return parent.errorCallback(zone, error, stackTrace);
  }

  asyncStart();
  runZoned(() {
    Future.wait([null]).catchError((e, st) {
      Expect.identical(e, caughtError);
      Expect.equals(1, count);
      asyncEnd();
    });
  }, zoneSpecification: new ZoneSpecification(errorCallback: errorCallback));
}

void testBadFuture() {
  var bad = new BadFuture();
  // Completing with bad future (then call throws) puts error in result.
  asyncStart();
  Completer completer = new Completer();
  completer.complete(bad);
  completer.future.then((_) {
    Expect.fail("unreachable");
  }, onError: (e, s) {
    Expect.isTrue(completer.isCompleted);
    asyncEnd();
  });

  asyncStart();
  var f = new Future.value().then((_) => bad);
  f.then((_) {
    Expect.fail("unreachable");
  }, onError: (e, s) {
    asyncEnd();
  });
}

void testTypes() {
  // Test that future is a Future<int> and not something less precise.
  testType(name, future, [depth = 2]) {
    var desc = "$name${".whenComplete"*(2-depth)}";
    Expect.isTrue(future is Future<int>, "$desc is Future<int>");
    Expect.isFalse(future is Future<String>, "$desc is! Future<String>");
    var stream = future.asStream();
    Expect.isTrue(stream is Stream<int>, "$desc.asStream() is Stream<int>");
    Expect.isFalse(
        stream is Stream<String>, "$desc.asStream() is! Stream<String>");
    if (depth > 0) {
      testType(name, future.whenComplete(() {}), depth - 1);
    }
  }

  for (var value in [42, null]) {
    testType("Future($value)", new Future<int>(() => value));
    testType("Future.delayed($value)",
        new Future<int>.delayed(Duration.ZERO, () => value));
    testType(
        "Future.microtask($value)", new Future<int>.microtask(() => value));
    testType( //# 01: ok
        "Future.sync($value)", new Future<int>.sync(() => value)); //# 01: continued
    testType( //# 01: continued
        "Future.sync(future($value))", //# 01: continued
        new Future<int>.sync(//# 01: continued
            () => new Future<int>.value(value))); //# 01: continued
    testType("Future.value($value)", new Future<int>.value(value));
  }
  testType("Completer.future", new Completer<int>().future);
  testType("Future.error", new Future<int>.error("ERR")..catchError((_) {}));
}

void testAnyValue() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var result = Future.any(cs.map((x) => x.future));

  result.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  }, onError: (e, s) {
    Expect.fail("Unexpected error: $e");
  });

  cs[1].complete(42);
  cs[2].complete(10);
  cs[0].complete(20);
}

void testAnyError() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var result = Future.any(cs.map((x) => x.future));

  result.then((v) {
    Expect.fail("Unexpected value: $v");
  }, onError: (e, s) {
    Expect.equals(42, e);
    asyncEnd();
  });

  cs[1].completeError(42);
  cs[2].complete(10);
  cs[0].complete(20);
}

void testAnyIgnoreIncomplete() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var result = Future.any(cs.map((x) => x.future));

  result.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  }, onError: (e, s) {
    Expect.fail("Unexpected error: $e");
  });

  cs[1].complete(42);
  // The other two futures never complete.
}

void testAnyIgnoreError() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var result = Future.any(cs.map((x) => x.future));

  result.then((v) {
    Expect.equals(42, v);
    asyncEnd();
  }, onError: (e, s) {
    Expect.fail("Unexpected error: $e");
  });

  cs[1].complete(42);
  // The errors are ignored, not uncaught.
  cs[2].completeError("BAD");
  cs[0].completeError("BAD");
}

void testFutureResult() {
  asyncStart();
  () async {
    var f = new UglyFuture(5);
    // Sanity check that our future is as mis-behaved as we think.
    f.then((v) {
      Expect.isTrue(v is Future);
    });

    var v = await f;
    // The static type of await is Flatten(static-type-of-expression), so it
    // suggests that it flattens. In practice it currently doesn't.
    // The specification doesn't say anything special, so v should be the
    // completion value of the UglyFuture future which is a future.
    Expect.isTrue(v is Future);

    // This used to hit an assert in checked mode.
    // The CL adding this test changed the behavior to actually flatten the
    // the future returned by the then-callback.
    var w = new Future.value(42).then((_) => f);
    Expect.equals(42, await w);
    asyncEnd();
  }();
}

main() {
  asyncStart();

  testValue();
  testSync();
  testNeverComplete();

  testComplete();
  testCompleteWithSuccessHandlerBeforeComplete();
  testCompleteWithSuccessHandlerAfterComplete();
  testCompleteManySuccessHandlers();
  testCompleteWithError();

  testCompleteWithFutureSuccess();
  testCompleteWithFutureSuccess2();
  testCompleteWithFutureError();
  testCompleteWithFutureError2();
  testCompleteErrorWithFuture();
  testCompleteWithCustomFutureSuccess();
  testCompleteWithCustomFutureError();
  testCompleteErrorWithCustomFuture();
  testCompleteErrorWithNull();

  testException();
  testExceptionHandler();
  testExceptionHandlerReturnsTrue();
  testExceptionHandlerReturnsTrue2();
  testExceptionHandlerReturnsFalse();

  testFutureAsStreamCompleteAfter();
  testFutureAsStreamCompleteBefore();
  testFutureAsStreamCompleteImmediate();
  testFutureAsStreamCompleteErrorAfter();
  testFutureAsStreamWrapper();

  testFutureWhenCompleteValue();
  testFutureWhenCompleteError();
  testFutureWhenCompleteValueNewError();
  testFutureWhenCompleteErrorNewError();

  testFutureWhenValueFutureValue();
  testFutureWhenErrorFutureValue();
  testFutureWhenValueFutureError();
  testFutureWhenErrorFutureError();

  testFutureThenThrowsAsync();
  testFutureCatchThrowsAsync();
  testFutureWhenThrowsAsync();
  testFutureCatchRethrowsAsync();

  testChainedFutureValue();
  testChainedFutureValueDelay();
  testChainedFutureError();

  testSyncFuture_i13368();

  testWaitCleanUp();
  testWaitCleanUpError();
  testWaitSyncError();
  testWaitSyncError2();
  testWaitSyncError3();

  testBadFuture();

  testTypes();

  testAnyValue();
  testAnyError();
  testAnyIgnoreIncomplete();
  testAnyIgnoreError();

  testFutureResult();

  asyncEnd();
}

/// A well-behaved Future that isn't recognizable as a _Future.
class CustomFuture<T> implements Future<T> {
  Future<T> _realFuture;
  CustomFuture(this._realFuture);
  Future<S> then<S>(action(T result), {Function onError}) =>
      _realFuture.then(action, onError: onError);
  Future<T> catchError(Function onError, {bool test(e)}) =>
      _realFuture.catchError(onError, test: test);
  Future<T> whenComplete(action()) => _realFuture.whenComplete(action);
  Future<T> timeout(Duration timeLimit, {void onTimeout()}) =>
      _realFuture.timeout(timeLimit, onTimeout: onTimeout);
  Stream<T> asStream() => _realFuture.asStream();
  String toString() => "CustomFuture@${_realFuture.hashCode}";
  int get hashCode => _realFuture.hashCode;
}

/// A bad future that throws on every method.
class BadFuture<T> implements Future<T> {
  Future<S> then<S>(action(T result), {Function onError}) {
    throw "then GOTCHA!";
  }

  Future<T> catchError(Function onError, {bool test(Object e)}) {
    throw "catch GOTCHA!";
  }

  Future<T> whenComplete(action()) {
    throw "finally GOTCHA!";
  }

  Stream<T> asStream() {
    throw "asStream GOTCHA!";
  }

  Future<T> timeout(Duration duration, {onTimeout()}) {
    throw "timeout GOTCHA!";
  }
}

// An evil future that completes with another future.
class UglyFuture implements Future<dynamic> {
  final _result;
  UglyFuture(int badness)
      : _result = (badness == 0) ? 42 : new UglyFuture(badness - 1);
  Future<S> then<S>(action(value), {Function onError}) {
    var c = new Completer();
    c.complete(new Future.microtask(() => action(_result)));
    return c.future;
  }

  Future catchError(onError, {test}) => this; // Never an error.
  Future whenComplete(action()) {
    return new Future.microtask(action).then((_) => this);
  }

  Stream asStream() {
    return (new StreamController()
          ..add(_result)
          ..close())
        .stream;
  }

  Future timeout(Duration duration, {onTimeout()}) {
    return this;
  }
}
