// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:io';

void testReadAsString() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_read_encoded');

  var file = new File('${tmp.path}/file');
  file.createSync();

  file.writeAsBytesSync([0xb0]);

  Expect.throws(file.readAsStringSync, (e) => e is FileSystemException);

  asyncStart();
  file.readAsString().then((_) {
    Expect.fail("expected exception");
  }).catchError((e) {
    tmp.deleteSync(recursive: true);
    asyncEnd();
  }, test: (e) => e is FileSystemException);
}

void testReadAsLines() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_read_encoded');

  var file = new File('${tmp.path}/file');
  file.createSync();

  file.writeAsBytesSync([0xb0]);

  Expect.throws(file.readAsLinesSync, (e) => e is FileSystemException);

  asyncStart();
  file.readAsLines().then((_) {
    Expect.fail("expected exception");
  }).catchError((e) {
    tmp.deleteSync(recursive: true);
    asyncEnd();
  }, test: (e) => e is FileSystemException);
}

void main() {
  testReadAsString();
  testReadAsLines();
}
