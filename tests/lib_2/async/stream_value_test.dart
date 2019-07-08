// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() async {
  asyncStart();

  {
    // There is a first element.
    var stream = Stream<int>.value(42);
    var first = await stream.first;
    Expect.equals(42, first);
    // Is single-subscription.
    Expect.throws(() => stream.first);
  }

  {
    // There is no second element.
    var stream = Stream<int>.value(42);
    try {
      await stream.skip(1).first;
      Expect.fail("didn't throw");
    } on Error {
      // Success.
    }
  }

  {
    // There is still no second element.
    var stream = Stream<int>.value(42);
    try {
      await stream.elementAt(1);
      Expect.fail("didn't throw");
    } on Error {
      // Success.
    }
  }

  {
    // Works with await for.
    var stream = Stream<int>.value(42);
    var value = null;
    await for (value in stream) {}
    Expect.equals(42, value);
  }

  {
    // Works with subscriptions and pause-resume.
    var stream = Stream<int>.value(42);
    var value;
    var onDone = Completer();
    var sub = stream.listen((v) {
      value = v;
    }, onDone: () {
      Expect.equals(42, value);
      onDone.complete();
    });
    sub.pause();
    await Future.delayed(Duration(milliseconds: 10));
    Expect.isNull(value);
    Expect.isFalse(onDone.isCompleted);
    sub.resume();
    await onDone.future;
  }

  asyncEnd();
}
