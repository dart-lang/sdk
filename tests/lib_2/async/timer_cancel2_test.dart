// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_cancel2_test;

import 'dart:async';
import 'package:expect/expect.dart';

main() {
  // Test that a timeout handler can cancel itself.
  var cancelTimer;
  var completer = new Completer();
  int calls = 0;
  void cancelHandler(Timer timer) {
    Expect.equals(1, ++calls);
    cancelTimer.cancel();
    completer.complete();
  }

  cancelTimer =
      new Timer.periodic(const Duration(milliseconds: 1), cancelHandler);
  return completer.future;
}
