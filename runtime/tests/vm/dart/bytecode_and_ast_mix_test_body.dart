// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  void foo() {}
}

class B extends A {
  @override
  void foo() {}
}

main() {
  ClassMirror classB = reflectClass(B);
  MethodMirror foo = classB.declarations[#foo];
  final annotation = foo.metadata[0].reflectee;
  Expect.isTrue(annotation.toString().contains('_Override'));
  print('OK');
}
