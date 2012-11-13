// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  Directory scriptDir = new File(new Options().script).directorySync();
  var f = new File("${scriptDir.path}/æøå/æøå.dat");
  Expect.isTrue(f.existsSync());
  f.createSync();
  Expect.isTrue(f.directorySync().path.endsWith('æøå'));;
  Expect.equals(6, f.lengthSync());
  f.lastModifiedSync();
  Expect.isTrue(f.fullPathSync().endsWith('æøå.dat'));
  Expect.equals('æøå', f.readAsTextSync());
}
