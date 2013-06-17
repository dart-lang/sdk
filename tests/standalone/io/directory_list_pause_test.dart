// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";


void testPauseList() {
  var keepAlive = new ReceivePort();
  new Directory("").createTemp().then((d) {
    // Linux reads 2K at a time, so be sure to be >>.
    int total = 4 * 1024 + 1;
    for (int i = 0; i < total; i++) {
      new File("${d.path}/$i").createSync();
    }
    bool first = true;
    var subscription;
    int count = 0;
    subscription = d.list().listen((file) {
      if (first) {
        first = false;
        subscription.pause();
        Timer.run(() {
          for (int i = 0; i < total; i++) {
            new File("${d.path}/$i").deleteSync();
          }
          subscription.resume();
        });
      }
      count++;
    }, onDone: () {
      Expect.notEquals(total, count);
      keepAlive.close();
      d.delete().then((ignore) => keepAlive.close());
    });
  });
}

void main() {
  testPauseList();
}
