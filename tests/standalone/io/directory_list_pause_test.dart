// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";


void testPauseList() {
  asyncStart();
  // TOTAL should be bigger the our directory listing buffer.
  const int TOTAL = 128;
  new Directory("").createTemp().then((d) {
    for (int i = 0; i < TOTAL; i++) {
      new Directory("${d.path}/$i").createSync();
      new File("${d.path}/$i/file").createSync();
    }
    bool first = true;
    var subscription;
    int count = 0;
    subscription = d.list(recursive: true).listen((file) {
      if (file is File) {
        if (first) {
          first = false;
          subscription.pause();
          Timer.run(() {
            for (int i = 0; i < TOTAL; i++) {
              new File("${d.path}/$i/file").deleteSync();
            }
            subscription.resume();
          });
        }
        count++;
      }
    }, onDone: () {
      Expect.notEquals(TOTAL, count);
      Expect.isTrue(count > 0);
      d.delete(recursive: true).then((ignore) => asyncEnd());
    });
  });
}

void main() {
  testPauseList();
}
