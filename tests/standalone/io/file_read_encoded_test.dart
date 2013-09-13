// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:io';

void testReadAsString() {
  var tmp = new Directory('').createTempSync();

  var file = new File('${tmp.path}/file');
  file.createSync();

  file.writeAsBytesSync([0xb0]);

  Expect.throws(file.readAsStringSync, (e) => e is FileException);

  asyncStart();
  file.readAsString().then((_) {
    Expect.fail("expected exception");
  }).catchError((e) {
    tmp.deleteSync(recursive: true);
    asyncEnd();
  }, test: (e) => e is FileException);
}

void testReadAsLines() {
  var tmp = new Directory('').createTempSync();

  var file = new File('${tmp.path}/file');
  file.createSync();

  file.writeAsBytesSync([0xb0]);

  Expect.throws(file.readAsLinesSync, (e) => e is FileException);

  asyncStart();
  file.readAsLines().then((_) {
    Expect.fail("expected exception");
  }).catchError((e) {
    tmp.deleteSync(recursive: true);
    asyncEnd();
  }, test: (e) => e is FileException);
}

void main() {
  testReadAsString();
  testReadAsLines();
}
