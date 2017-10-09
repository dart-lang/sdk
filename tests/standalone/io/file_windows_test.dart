// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

void testDeleteLongPathPrefix() {
  var dir = Directory.systemTemp.createTempSync('dart_file_win');
  var dirPath = "\\\\?\\${dir.path}";
  var subPath = dirPath;
  for (int i = 0; i < 16; i++) {
    subPath += "\\a-long-path-segment";
    dir = new Directory(subPath)..createSync();
  }
  Expect.isTrue(dir.path.length > 256);
  var prefixDir = new Directory(dirPath);
  Expect.isTrue(prefixDir.existsSync());
  prefixDir.deleteSync(recursive: true);
  Expect.isFalse(dir.existsSync());
  Expect.isFalse(prefixDir.existsSync());
}

void main() {
  if (!Platform.isWindows) return;
  testDeleteLongPathPrefix();
}
