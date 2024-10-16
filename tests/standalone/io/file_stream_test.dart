// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void testPauseResumeCancelStream() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_file_stream').then((d) {
    var file = new File("${d.path}/file");
    new File(Platform.executable)
        .openRead()
        .cast<List<int>>()
        .pipe(file.openWrite())
        .then((_) {
      var subscription;
      subscription = file.openRead().listen((data) {
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
  });
}

void testStreamIsEmpty() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_file_stream').then((d) {
    var file = new File("${d.path}/file");
    new File(Platform.executable)
        .openRead()
        .cast<List<int>>()
        .pipe(file.openWrite())
        .then((_) {
      // isEmpty will cancel the stream after first data event.
      file.openRead().isEmpty.then((empty) {
        Expect.isFalse(empty);
        d.deleteSync(recursive: true);
        asyncEnd();
      });
    });
  });
}

Future<void> testStreamAppendedToAfterOpen() async {
  asyncStart();

  final pipe = Pipe.createSync();
  pipe.write.add("Hello World".codeUnits);
  int i = 0;
  await pipe.read.listen((event) {
    Expect.listEquals("Hello World".codeUnits, event);
    if (i < 10) {
      pipe.write.add("Hello World".codeUnits);
      ++i;
    } else {
      pipe.write.close();
    }
  }).asFuture();

  asyncEnd();
}

void main() async {
  testPauseResumeCancelStream();
  testStreamIsEmpty();
  await testStreamAppendedToAfterOpen();
}
