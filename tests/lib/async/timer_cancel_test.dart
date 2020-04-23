// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_cancel_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

final ms = const Duration(milliseconds: 1);

main() {
  asyncStart();
  return testSimpleTimer()
      .then((_) => cancelTimerWithSame())
      .then((_) => asyncEnd());
}

Future testSimpleTimer() {
  var cancelTimer = new Timer(ms * 1000, unreachable);
  cancelTimer.cancel();

  var handler = new Completer();
  var repeatHandler = new Completer();
  new Timer(ms * 1000, () {
    cancelTimer.cancel();
    handler.complete();
  });

  cancelTimer = new Timer(ms * 2000, unreachable);
  var repeatTimer = 0;
  new Timer.periodic(ms * 1500, (Timer timer) {
    repeatTimer++;
    timer.cancel();
    Expect.equals(repeatTimer, 1);
    repeatHandler.complete();
  });

  return handler.future.then((_) => repeatHandler.future);
}

Future cancelTimerWithSame() {
  var completer = new Completer();
  var t2;
  var t1 = new Timer(ms * 0, () {
    t2.cancel();
    completer.complete();
  });
  t2 = new Timer(ms * 0, unreachable);
  return completer.future;
}

void unreachable() {
  Expect.fail("should not be reached");
}
