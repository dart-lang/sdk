// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

Future testOneScheduleMicrotask() {
  var completer = new Completer();
  Timer.run(() {
    scheduleMicrotask(completer.complete);
  });
  return completer.future;
}

Future testMultipleScheduleMicrotask() {
  var completer = new Completer();
  Timer.run(() {
    const TOTAL = 10;
    int done = 0;
    for (int i = 0; i < TOTAL; i++) {
      scheduleMicrotask(() {
        done++;
        if (done == TOTAL) completer.complete();
        ;
      });
    }
  });
  return completer.future;
}

Future testScheduleMicrotaskThenTimer() {
  var completer = new Completer();
  Timer.run(() {
    bool scheduleMicrotaskDone = false;
    scheduleMicrotask(() {
      Expect.isFalse(scheduleMicrotaskDone);
      scheduleMicrotaskDone = true;
    });
    Timer.run(() {
      Expect.isTrue(scheduleMicrotaskDone);
      completer.complete();
    });
  });
  return completer.future;
}

Future testTimerThenScheduleMicrotask() {
  var completer = new Completer();
  Timer.run(() {
    bool scheduleMicrotaskDone = false;
    Timer.run(() {
      Expect.isTrue(scheduleMicrotaskDone);
      completer.complete();
    });
    scheduleMicrotask(() {
      Expect.isFalse(scheduleMicrotaskDone);
      scheduleMicrotaskDone = true;
    });
  });
  return completer.future;
}

Future testTimerThenScheduleMicrotaskChain() {
  var completer = new Completer();
  Timer.run(() {
    const TOTAL = 10;
    int scheduleMicrotaskDone = 0;
    Timer.run(() {
      Expect.equals(TOTAL, scheduleMicrotaskDone);
      completer.complete();
    });
    Future scheduleMicrotaskCallback() {
      scheduleMicrotaskDone++;
      if (scheduleMicrotaskDone != TOTAL) {
        scheduleMicrotask(scheduleMicrotaskCallback);
      }
    }

    scheduleMicrotask(scheduleMicrotaskCallback);
  });
  return completer.future;
}

main() {
  asyncStart();
  testOneScheduleMicrotask()
      .then((_) => testMultipleScheduleMicrotask())
      .then((_) => testScheduleMicrotaskThenTimer())
      .then((_) => testTimerThenScheduleMicrotask())
      .then((_) => testTimerThenScheduleMicrotaskChain())
      .then((_) => asyncEnd());
}
