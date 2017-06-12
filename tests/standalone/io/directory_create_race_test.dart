// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test for a race condition that can occur when recursively creating
// a directory multiple times simultaneously.  This consistently reproduces
// issue https://code.google.com/p/dart/issues/detail?id=7679 in revisions
// without the fix for this issue.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testCreateRecursiveRace() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('dart_directory_create_race');
  var d = new Directory('${temp.path}/a/b/c/d/e');
  Future.wait([
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true),
    d.create(recursive: true)
  ]).then((_) {
    Expect.isTrue(new Directory('${temp.path}/a').existsSync());
    Expect.isTrue(new Directory('${temp.path}/a/b').existsSync());
    Expect.isTrue(new Directory('${temp.path}/a/b/c').existsSync());
    Expect.isTrue(new Directory('${temp.path}/a/b/c/d').existsSync());
    Expect.isTrue(new Directory('${temp.path}/a/b/c/d/e').existsSync());
    temp.delete(recursive: true).then((_) {
      asyncEnd();
    });
  });
}

void main() {
  testCreateRecursiveRace();
  testCreateRecursiveRace();
}
