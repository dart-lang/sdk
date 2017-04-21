// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_timeout_test;

import 'dart:async';
import 'package:unittest/unittest.dart';

main() {
  test("timeoutNoComplete", () {
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutCompleteAfterTimeout", () {
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    Timer timer = new Timer(const Duration(seconds: 1), () {
      completer.complete(-1);
    });
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutCompleteBeforeTimeout", () {
    Completer completer = new Completer();
    Timer timer = new Timer(const Duration(milliseconds: 5), () {
      completer.complete(42);
    });
    Future timedOut = completer.future
        .timeout(const Duration(seconds: 1), onTimeout: () => -1);
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutCompleteBeforeCreate", () {
    Completer completer = new Completer.sync();
    completer.complete(42);
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => -1);
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutThrows", () {
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      throw "EXN1";
    });
    timedOut.catchError(expectAsync((e, s) {
      expect(e, "EXN1");
    }));
  });

  test("timeoutThrowAfterTimeout", () {
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    Timer timer = new Timer(const Duration(seconds: 1), () {
      completer.completeError("EXN2");
    });
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutThrowBeforeTimeout", () {
    Completer completer = new Completer();
    Timer timer = new Timer(const Duration(milliseconds: 5), () {
      completer.completeError("EXN3");
    });
    Future timedOut = completer.future
        .timeout(const Duration(seconds: 1), onTimeout: () => -1);
    timedOut.catchError(expectAsync((e, s) {
      expect(e, "EXN3");
    }));
  });

  test("timeoutThrowBeforeCreate", () {
    // Prevent uncaught error when we create the error.
    Completer completer = new Completer.sync()..future.catchError((e) {});
    completer.completeError("EXN4");
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => -1);
    timedOut.catchError(expectAsync((e, s) {
      expect(e, "EXN4");
    }));
  });

  test("timeoutReturnFutureValue", () {
    Future result = new Future.value(42);
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => result);
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutReturnFutureError", () {
    Future result = new Future.error("EXN5")..catchError((e) {});
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => result);
    timedOut.catchError(expectAsync((e, s) {
      expect(e, "EXN5");
    }));
  });

  test("timeoutReturnFutureValueLater", () {
    Completer result = new Completer();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      result.complete(42);
      return result.future;
    });
    timedOut.then(expectAsync((v) {
      expect(v, 42);
    }));
  });

  test("timeoutReturnFutureErrorLater", () {
    Completer result = new Completer();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      result.completeError("EXN6");
      return result.future;
    });
    timedOut.catchError(expectAsync((e, s) {
      expect(e, "EXN6");
    }));
  });

  test("timeoutZone", () {
    var initialZone = Zone.current;
    Zone forked;
    int registerCallDelta = 0;
    bool callbackCalled = false;
    Function callback = () {
      expect(callbackCalled, false);
      callbackCalled = true;
      expect(Zone.current, forked);
      return 42;
    };
    forked = Zone.current.fork(specification: new ZoneSpecification(
        registerCallback: (Zone self, ZoneDelegate parent, Zone origin, f()) {
      if (!identical(f, callback)) return f;
      registerCallDelta++; // Increment calls to register.
      expect(origin, forked);
      expect(self, forked);
      return expectAsync(() {
        registerCallDelta--;
        return f();
      });
    }));
    Completer completer = new Completer();
    Future timedOut;
    forked.run(() {
      timedOut = completer.future
          .timeout(const Duration(milliseconds: 5), onTimeout: callback);
    });
    timedOut.then(expectAsync((v) {
      expect(callbackCalled, true);
      expect(registerCallDelta, 0);
      expect(Zone.current, initialZone);
      expect(v, 42);
    }));
  });

  test("timeoutNoFunction", () {
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5));
    timedOut.catchError(expectAsync((e, s) {
      expect(e, new isInstanceOf<TimeoutException>());
      expect(e.duration, const Duration(milliseconds: 5));
      expect(s, null);
    }));
  });

  test("timeoutType", () {
    Completer completer = new Completer<int>();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5));
    expect(timedOut, new isInstanceOf<Future<int>>());
    expect(timedOut, isNot(new isInstanceOf<Future<String>>()));
    timedOut.catchError((_) {});
    completer.complete(499);
  });
}
