// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testOpenOutputStreamSync() {
  Directory tempDirectory = new Directory('').createTempSync();

  asyncStart();
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
    tempDirectory.deleteSync();
    asyncEnd();
  });
}


main() {
  testOpenOutputStreamSync();
}
