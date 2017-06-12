// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.intercepted_superclass_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

check(ClassMirror cm) {
  Expect.isTrue(cm is ClassMirror);
  Expect.isNotNull(cm);
}

main() {
  check(reflect('').type.superclass);
  check(reflect(1).type.superclass);
  check(reflect(1.5).type.superclass);
  check(reflect(true).type.superclass);
  check(reflect(false).type.superclass);
  check(reflect([]).type.superclass);

  check(reflectClass(String).superclass);
  check(reflectClass(int).superclass);
  check(reflectClass(double).superclass);
  check(reflectClass(num).superclass);
  check(reflectClass(bool).superclass);
  check(reflectClass(List).superclass);
}
