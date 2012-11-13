// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  Directory scriptDir = new File(new Options().script).directorySync();
  var d = new Directory("${scriptDir.path}/æøå");
  Expect.isTrue(d.existsSync());
  d.createSync();
  var temp = new Directory('').createTempSync();
  var temp2 = new Directory("${temp.path}/æøå").createTempSync();
  Expect.isTrue(temp2.path.contains("æøå"));
  temp2.deleteSync();
  temp.deleteSync(recursive: true);
}
