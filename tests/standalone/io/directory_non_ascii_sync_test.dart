// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  Directory scriptDir = new File(new Options().script).directorySync();
  var d = new Directory("${scriptDir.path}/æøå");
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  Expect.isTrue(d.existsSync());
  d.createSync();
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory("${temp.path}/æøå").createTempSync();
  Expect.isTrue(temp2.path.contains(precomposed) ||
                temp2.path.contains(decomposed));
  temp2.deleteSync();
  temp.deleteSync(recursive: true);
}
