// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream timedStream(int n) {
  int i = 0;
  StreamController controller;
  tick() {
    if (i >= n) {
      controller.close();
      return;
    }
    controller.add(i);
    i++;
    new Future.delayed(new Duration(milliseconds: 0), tick);
  }

  controller = new StreamController(onListen: tick);
  return controller.stream;
}

void main() {
  asyncStart();
  StreamIterator iterator = new StreamIterator(timedStream(10));
  helper(more) {
    if (!more) {
      // Canceling the already closed iterator should not lead to a crash.
      iterator.cancel();
      asyncEnd();
    } else {
      iterator.moveNext().then(helper);
    }
  }

  iterator.moveNext().then(helper);
}
