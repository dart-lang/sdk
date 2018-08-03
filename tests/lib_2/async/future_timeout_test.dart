// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_timeout_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  Future timeoutNoComplete() async {
    asyncStart();
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutCompleteAfterTimeout() async {
    asyncStart();
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    Timer timer = new Timer(const Duration(seconds: 1), () {
      asyncStart();
      completer.complete(-1);
    });
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutCompleteBeforeTimeout() async {
    asyncStart();
    Completer completer = new Completer();
    Timer timer = new Timer(const Duration(milliseconds: 5), () {
      asyncStart();
      completer.complete(42);
    });
    Future timedOut = completer.future
        .timeout(const Duration(seconds: 1), onTimeout: () => -1);
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutCompleteBeforeCreate() async {
    asyncStart();
    Completer completer = new Completer.sync();
    completer.complete(42);
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => -1);
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutThrows() async {
    asyncStart();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      throw "EXN1";
    });
    timedOut.catchError((e, s) {
      Expect.isTrue(e == "EXN1");
    });
  }

  Future timeoutThrowAfterTimeout() async {
    asyncStart();
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => 42);
    Timer timer = new Timer(const Duration(seconds: 1), () {
      asyncStart();
      completer.completeError("EXN2");
    });
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutThrowBeforeTimeout() async {
    asyncStart();
    Completer completer = new Completer();
    Timer timer = new Timer(const Duration(milliseconds: 5), () {
      asyncStart();
      completer.completeError("EXN3");
    });
    Future timedOut = completer.future
        .timeout(const Duration(seconds: 1), onTimeout: () => -1);
    timedOut.catchError((e, s) {
      Expect.isTrue(e == "EXN3");
    });
  }

  Future timeoutThrowBeforeCreate() async {
    asyncStart();
    // Prevent uncaught error when we create the error.
    Completer completer = new Completer.sync()..future.catchError((e) {});
    completer.completeError("EXN4");
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => -1);
    timedOut.catchError((e, s) {
      Expect.isTrue(e == "EXN4");
    });
  }

  Future timeoutReturnFutureValue() async {
    asyncStart();
    Future result = new Future.value(42);
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => result);
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutReturnFutureError() async {
    asyncStart();
    Future result = new Future.error("EXN5")..catchError((e) {});
    Completer completer = new Completer();
    Future timedOut = completer.future
        .timeout(const Duration(milliseconds: 5), onTimeout: () => result);
    timedOut.catchError((e, s) {
      Expect.isTrue(e == "EXN5");
    });
  }

  Future timeoutReturnFutureValueLater() async {
    asyncStart();
    Completer result = new Completer();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      result.complete(42);
      return result.future;
    });
    timedOut.then((v) {
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutFutureReturnErrorLater() async {
    asyncStart();
    Completer result = new Completer();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5),
        onTimeout: () {
      result.completeError("EXN6");
      return result.future;
    });
    timedOut.catchError((e, s) {
      Expect.isTrue(e == "EXN6");
    });
  }

  Future timeoutZone() async {
    asyncStart();
    var initialZone = Zone.current;
    Zone forked;
    int registerCallDelta = 0;
    bool callbackCalled = false;
    Function callback = () {
      Expect.isFalse(callbackCalled);
      callbackCalled = true;
      Expect.isTrue(Zone.current == forked);
      return 42;
    };
    forked = Zone.current.fork(specification: new ZoneSpecification(
        registerCallback:
            <R>(Zone self, ZoneDelegate parent, Zone origin, R f()) {
      R Function() result;
      if (!identical(f, callback)) {
        result = f;
      } else {
        registerCallDelta++; // Increment calls to register.
        Expect.isTrue(origin == forked);
        Expect.isTrue(self == forked);
        result = () {
          registerCallDelta--;
          return f();
        };
      }
      return f;
    }));
    Completer completer = new Completer();
    Future timedOut;
    forked.run(() {
      timedOut = completer.future
          .timeout(const Duration(milliseconds: 5), onTimeout: callback);
    });
    timedOut.then((v) {
      Expect.isTrue(callbackCalled);
      Expect.isTrue(registerCallDelta == 0);
      Expect.isTrue(Zone.current == initialZone);
      Expect.isTrue(v == 42);
      asyncEnd();
    });
  }

  Future timeoutNoFunction() async {
    asyncStart();
    Completer completer = new Completer();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5));
    timedOut.catchError((e, s) {
      Expect.isTrue(e is TimeoutException);
      Expect.isTrue(e.duration == const Duration(milliseconds: 5));
      Expect.isNull(s);
    });
  }

  Future timeoutType() async {
    asyncStart();
    Completer completer = new Completer<int>();
    Future timedOut = completer.future.timeout(const Duration(milliseconds: 5));
    Expect.isTrue(timedOut is Future<int>);
    Expect.isTrue(timedOut is! Future<String>);
    timedOut.catchError((_) {});
    completer.complete(499);
  }
}
