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
    f2.catchError((_){});  // I'll get the error later.
    f1.then((v1) { f2.then((v2) { Expect.equals(v1, v2); }); },
            onError: (e1) {
              f2.then((_) { Expect.fail("Expected error"); },
                      onError: (e2) {
                         Expect.equals(e1, e2);
                      });
            });
  }
  Future val = new Future.value(42);
  Future err1 = new Future.error("Error")..catchError((_){});
  try {
    throw new List(0);
  } catch (e, st) {
    Future err2 = new Future.error(e, st)..catchError((_){});
  }
  compare(() => 42);
  compare(() => val);
  compare(() { throw "Flif"; });
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
  future.then((int v) { after = v; })
    .then((_) {
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
  future.then((int v) { after = v; })
    .then((_) {
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

  var futures = [];
  futures.add(future.then((int v) { before = v; }));
  completer.complete(3);
  futures.add(future.then((int v) { after1 = v; }));
  futures.add(future.then((int v) { after2 = v; }));

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
  future
      .then((v) { throw "Value not expected"; })
      .catchError((error) {
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
  var done = future.catchError((error) { ex2 = error; });

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
  future.catchError((e) { });
  future.catchError((e) { reached = true; }, test: (e) => false)
        .catchError((e) {});
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
  var done = future
      .catchError((e) { }, test: (e) => false)
      .catchError((e) { reached = true; });
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

  future.catchError((e) { });

  future.catchError((e) { reached = true; }, test: (e) => false)
        .catchError((e) { });

  completer.completeError(ex);

  Expect.isFalse(reached);
}

void testFutureAsStreamCompleteAfter() {
  var completer = new Completer();
  bool gotValue = false;
  asyncStart();
  completer.future.asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
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
  completer.future.asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
        Expect.isTrue(gotValue);
        asyncEnd();
      });
}

void testFutureAsStreamCompleteImmediate() {
  bool gotValue = false;
  asyncStart();
  new Future.value("value").asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
        Expect.isTrue(gotValue);
        asyncEnd();
      });
}

void testFutureAsStreamCompleteErrorAfter() {
  var completer = new Completer();
  bool gotError = false;
  asyncStart();
  completer.future.asStream().listen(
      (data) {
        Expect.fail("Unexpected data");
      },
      onError: (error) {
        Expect.isFalse(gotError);
        gotError = true;
        Expect.equals("error", error);
      },
      onDone: () {
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
      .catchError((_) { throw "not possible"; })  // Returns a future wrapper.
      .asStream().listen(
        (data) {
          Expect.isFalse(gotValue);
          gotValue = true;
          Expect.equals("value", data);
        },
        onDone: () {
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
  Future result = new Future.value(42);
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
  Future result = new Future.error("ERROR-tcwfe2");
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

  future.then((v) => new Future.value(v * 2))
        .then((v) {
          Expect.equals(42, v);
          asyncEnd();
        });
  completer.complete(21);
}

void testChainedFutureValueDelay() {
  final completer = new Completer();
  final future = completer.future;
  asyncStart();

  future.then((v) => new Future.delayed(const Duration(milliseconds: 10),
                                        () => v * 2))
        .then((v) {
          Expect.equals(42, v);
          asyncEnd();
        });
  completer.complete(21);
}

void testChainedFutureValue2Delay() {
  asyncStart();

  new Future.delayed(const Duration(milliseconds: 10))
    .then((v) {
      Expect.isNull(v);
      asyncEnd();
    });
}

void testChainedFutureError() {
  final completer = new Completer();
  final future = completer.future;
  asyncStart();

  future.then((v) => new Future.error("Fehler"))
        .then((v) { Expect.fail("unreachable!"); }, onError: (error) {
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

  asyncEnd();
}

/// A Future that isn't recognizable as a _Future.
class CustomFuture<T> implements Future<T> {
  Future _realFuture;
  CustomFuture(this._realFuture);
  Future then(action(result), {Function onError}) =>
      _realFuture.then(action, onError: onError);
  Future catchError(Function onError, {bool test(e)}) =>
      _realFuture.catchError(onError, test: test);
  Future whenComplete(action()) => _realFuture.whenComplete(action);
  Future timeout(Duration timeLimit, {void onTimeout()}) =>
      _realFuture.timeout(timeLimit, onTimeout: onTimeout);
  Stream asStream() => _realFuture.asStream();
  String toString() => "CustomFuture@${_realFuture.hashCode}";
  int get hashCode => _realFuture.hashCode;
}
