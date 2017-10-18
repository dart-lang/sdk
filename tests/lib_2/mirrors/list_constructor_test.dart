// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'dart:mirrors';

main() {
  var cls = reflectClass(List);
  Expect.throwsArgumentError(() => cls.newInstance(const Symbol(''), [null]));

  var list = cls.newInstance(const Symbol(''), [42]).reflectee;
  // Check that the list is fixed.
  Expect.equals(42, list.length);
  Expect.throwsUnsupportedError(() => list.add(2));
  list[0] = 1;
  Expect.equals(1, list[0]);

  testGrowableList(); //# 01: ok
}

testGrowableList() {
  var cls = reflectClass(List);
  var list = cls.newInstance(const Symbol(''), []).reflectee;
  // Check that the list is growable.
  Expect.equals(0, list.length);
  list.add(42);
  Expect.equals(1, list.length);
}
