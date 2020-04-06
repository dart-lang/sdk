// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_periodictimer;

import 'dart:async';
import 'package:expect/minitest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  int counter = 0;
  new Timer.periodic(const Duration(milliseconds: 10), (timer) {
    if (counter == 3) {
      counter = 1024;
      timer.cancel();
      // Wait some more time to be sure callback won't be invoked any
      // more.
      new Timer(const Duration(milliseconds: 30), () {
        replyTo.send('DONE');
      });
      return;
    }
    assert(counter < 3);
    counter++;
  });
}
