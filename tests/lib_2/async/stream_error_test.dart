// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() async {
  var stack = StackTrace.fromString("some stack trace");
  var error = MyError();

  asyncStart();

  {
    // There is an error before any element.
    var stream = Stream<int>.error(error, stack);
    try {
      await stream.first;
      Expect.fail("didn't throw");
    } on MyError catch (e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
    }
  }

  {
    // There is an error before any element.
    var stream = Stream<int>.error(error, stack);
    try {
      await for (var _ in stream) {}
      Expect.fail("didn't throw");
    } on MyError catch (e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
    }
  }

  {
    // There is no second element or error.
    var stream = Stream<int>.error(error, stack);
    int errorCount = 0;
    var noErrorStream = stream.handleError((e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
      errorCount++;
    }, test: (o) => o is MyError);
    Expect.isTrue(await noErrorStream.isEmpty);
    Expect.equals(1, errorCount);
  }

  {
    // Works with subscriptions and pause-resume.
    var stream = Stream<int>.error(error, stack);
    int errorCount = 0;
    var onDone = Completer();
    var sub = stream.listen((v) {
      Expect.fail("Value event");
    }, onError: (e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
      errorCount++;
    }, onDone: () {
      Expect.equals(1, errorCount);
      onDone.complete();
    });
    sub.pause();
    await Future.delayed(Duration(milliseconds: 10));
    Expect.equals(0, errorCount);
    Expect.isFalse(onDone.isCompleted);
    sub.resume();
    await onDone.future;
  }

  // A null error argument is a synchronous error.
  Expect.throwsTypeError(() {
    Stream.error(null);
  });

  asyncEnd();
}

class MyError {}
