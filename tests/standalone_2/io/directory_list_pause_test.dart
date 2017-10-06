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
  Directory.systemTemp.createTemp('dart_directory_list_pause').then((d) {
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

void testPauseResumeCancelList() {
  asyncStart();
  // TOTAL should be bigger the our directory listing buffer.
  const int TOTAL = 128;
  Directory.systemTemp.createTemp('dart_directory_list_pause').then((d) {
    for (int i = 0; i < TOTAL; i++) {
      new Directory("${d.path}/$i").createSync();
      new File("${d.path}/$i/file").createSync();
    }
    var subscription;
    subscription = d.list(recursive: true).listen((entity) {
      subscription.pause();
      subscription.resume();
      void close() {
        d.deleteSync(recursive: true);
        asyncEnd();
      }

      var future = subscription.cancel();
      if (future != null) {
        future.whenComplete(close);
      } else {
        close();
      }
    }, onDone: () {
      Expect.fail('the stream was canceled, onDone should not happen');
    });
  });
}

void testListIsEmpty() {
  asyncStart();
  // TOTAL should be bigger the our directory listing buffer.
  const int TOTAL = 128;
  Directory.systemTemp.createTemp('dart_directory_list_pause').then((d) {
    for (int i = 0; i < TOTAL; i++) {
      new Directory("${d.path}/$i").createSync();
      new File("${d.path}/$i/file").createSync();
    }
    // isEmpty will cancel the stream after first data event.
    d.list(recursive: true).isEmpty.then((empty) {
      Expect.isFalse(empty);
      d.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}

void main() {
  testPauseList();
  testPauseResumeCancelList();
  testListIsEmpty();
}
