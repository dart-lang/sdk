// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

testFutureAsStreamCompleteAfter() {
  var completer = new Completer();
  bool gotValue = false;
  var port = new ReceivePort();
  completer.future.asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
        Expect.isTrue(gotValue);
        port.close();
      });
  completer.complete("value");
}

testFutureAsStreamCompleteBefore() {
  var completer = new Completer();
  bool gotValue = false;
  var port = new ReceivePort();
  completer.complete("value");
  completer.future.asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
        Expect.isTrue(gotValue);
        port.close();
      });
}

testFutureAsStreamCompleteImmediate() {
  bool gotValue = false;
  var port = new ReceivePort();
  new Future.immediate("value").asStream().listen(
      (data) {
        Expect.isFalse(gotValue);
        gotValue = true;
        Expect.equals("value", data);
      },
      onDone: () {
        Expect.isTrue(gotValue);
        port.close();
      });
}

testFutureAsStreamCompleteErrorAfter() {
  var completer = new Completer();
  bool gotError = false;
  var port = new ReceivePort();
  completer.future.asStream().listen(
      (data) {
        Expect.fail("Unexpected data");
      },
      onError: (error) {
        Expect.isFalse(gotError);
        gotError = true;
        Expect.equals("error", error.error);
      },
      onDone: () {
        Expect.isTrue(gotError);
        port.close();
      });
  completer.completeError("error");
}

testFutureAsStreamWrapper() {
  var completer = new Completer();
  bool gotValue = false;
  var port = new ReceivePort();
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
          port.close();
        });
}

testFutureWhenCompleteValue() {
  var port = new ReceivePort();
  int counter = 2;
  countDown() {
    if (--counter == 0) port.close();
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

testFutureWhenCompleteError() {
  var port = new ReceivePort();
  int counter = 2;
  countDown() {
    if (--counter == 0) port.close();
  }
  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(countDown);
  later.catchError((AsyncError e) {
    Expect.equals("error", e.error);
    countDown();
  });
  completer.completeError("error");
}

testFutureWhenCompleteValueNewError() {
  var port = new ReceivePort();
  int counter = 2;
  countDown() {
    if (--counter == 0) port.close();
  }
  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(() {
    countDown();
    throw "new error";
  });
  later.catchError((AsyncError e) {
    Expect.equals("new error", e.error);
    countDown();
  });
  completer.complete(42);
}

testFutureWhenCompleteErrorNewError() {
  var port = new ReceivePort();
  int counter = 2;
  countDown() {
    if (--counter == 0) port.close();
  }
  var completer = new Completer();
  Future future = completer.future;
  Future later = future.whenComplete(() {
    countDown();
    throw "new error";
  });
  later.catchError((AsyncError e) {
    Expect.equals("new error", e.error);
    countDown();
  });
  completer.completeError("error");
}

testFutureWhenCompletePreValue() {
  var port = new ReceivePort();
  int counter = 2;
  countDown() {
    if (--counter == 0) port.close();
  }
  var completer = new Completer();
  Future future = completer.future;
  completer.complete(42);
  new Timer(0, () {
    Future later = future.whenComplete(countDown);
    later.then((v) {
      Expect.equals(42, v);
      countDown();
    });
  });
}

main() {
  testFutureAsStreamCompleteAfter();
  testFutureAsStreamCompleteBefore();
  testFutureAsStreamCompleteImmediate();
  testFutureAsStreamCompleteErrorAfter();
  testFutureAsStreamWrapper();

  testFutureWhenCompleteValue();
  testFutureWhenCompleteError();
  testFutureWhenCompleteValueNewError();
  testFutureWhenCompleteErrorNewError();
}

