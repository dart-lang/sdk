// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

void testOpenOutputStreamSync() {
  Directory tempDirectory = new Directory('').createTempSync();

  // Create a port for waiting on the final result of this test.
  ReceivePort done = new ReceivePort();
  done.receive((message, replyTo) {
    tempDirectory.deleteSync();
    done.close();
  });

  String fileName = "${tempDirectory.path}/test";
  File file = new File(fileName);
  file.createSync();
  IOSink x = file.openWrite();
  var data = [65, 66, 67];
  x.add(data);
  x.close();
  x.done.then((_) {
    Expect.listEquals(file.readAsBytesSync(), data);
    file.deleteSync();
    done.toSendPort().send("done");
  });
}


main() {
  testOpenOutputStreamSync();
}
