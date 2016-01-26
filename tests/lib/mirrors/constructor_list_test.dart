// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructor_lsit_test;

@MirrorsUsed(targets: const [List])
import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  ClassMirror cm;
  MethodMirror mm;

  cm = reflectClass(List);
  print(cm);

  var list1 = cm.newInstance(const Symbol(''), []).reflectee;
  var list2 = cm.newInstance(const Symbol(''), [10]).reflectee;

  Expect.equals(0, list1.length);
  Expect.equals(10, list2.length);
}
