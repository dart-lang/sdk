// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.superclass;

import 'dart:mirrors';
import 'package:expect/expect.dart';

checkSuperclassChain(ClassMirror cm) {
  ClassMirror last;
  do {
    last = cm;
    cm = cm.superclass;
  } while (cm != null);
  Expect.equals(reflectClass(Object), last);
}

main() {
  checkSuperclassChain(reflect(null).type);
  checkSuperclassChain(reflect([]).type);
  checkSuperclassChain(reflect(<int>[]).type);
  checkSuperclassChain(reflect(0).type);
  checkSuperclassChain(reflect(1.5).type);
  checkSuperclassChain(reflect("str").type);
  checkSuperclassChain(reflect(true).type);
  checkSuperclassChain(reflect(false).type);
}
