// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  Directory scriptDir = new File(new Options().script).directorySync();
  var f = new File("${scriptDir.path}/æøå/æøå.dat");
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  Expect.isTrue(f.existsSync());
  f.createSync();
  var path = f.directorySync().path;
  Expect.isTrue(f.directorySync().path.endsWith(precomposed) ||
                f.directorySync().path.endsWith(decomposed));
  Expect.equals(6, f.lengthSync());
  f.lastModifiedSync();
  Expect.isTrue(f.fullPathSync().endsWith('${precomposed}.dat') ||
                f.fullPathSync().endsWith('${decomposed}.dat'));
  // The contents of the file is precomposed utf8.
  Expect.equals(precomposed, f.readAsTextSync());
}
