// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';

main() {
  Directory tempDir =
      Directory.systemTemp.createTempSync('dart_file_non_ascii_sync');
  Directory nonAsciiDir = new Directory('${tempDir.path}/æøå');
  nonAsciiDir.createSync();
  Expect.isTrue(nonAsciiDir.existsSync());
  File nonAsciiFile = new File('${nonAsciiDir.path}/æøå.txt');
  nonAsciiFile.writeAsStringSync('æøå');
  Expect.isTrue(nonAsciiFile.existsSync());
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  // The contents of the file is precomposed utf8.
  Expect.equals(precomposed, nonAsciiFile.readAsStringSync());
  nonAsciiFile.createSync();
  var path = nonAsciiFile.parent.path;
  Expect.isTrue(path.endsWith(precomposed) || path.endsWith(decomposed));
  Expect.equals(6, nonAsciiFile.lengthSync());
  nonAsciiFile.lastModifiedSync();
  path = nonAsciiFile.resolveSymbolicLinksSync();
  Expect.isTrue(path.endsWith('${precomposed}.txt') ||
      path.endsWith('${decomposed}.txt'));
  tempDir.deleteSync(recursive: true);
}
