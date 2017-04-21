// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';

main() {
  Directory tempDir =
      Directory.systemTemp.createTempSync('dart_directory_non_ascii_sync');
  var nonAsciiDir = new Directory("${tempDir.path}/æøå");
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  Expect.isFalse(nonAsciiDir.existsSync());
  nonAsciiDir.createSync();
  Expect.isTrue(nonAsciiDir.existsSync());
  var temp = new Directory("${tempDir.path}/æøå").createTempSync('tempdir');
  Expect.isTrue(
      temp.path.contains(precomposed) || temp.path.contains(decomposed));
  temp.deleteSync();
  temp = tempDir.createTempSync('æøå');
  Expect.isTrue(
      temp.path.contains(precomposed) || temp.path.contains(decomposed));
  temp.deleteSync();
  tempDir.deleteSync(recursive: true);
  Expect.isFalse(nonAsciiDir.existsSync());
  Expect.isFalse(temp.existsSync());
}
