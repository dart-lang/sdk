// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/34982
import 'dart:mirrors';
import 'package:expect/expect.dart';

abstract class A {
  int c();
}

class B implements A {
  dynamic noSuchMethod(Invocation invocation) {}
}

void main() {
  MethodMirror method1 = reflectClass(B).declarations[#c] as MethodMirror;
  Expect.isTrue(method1.isSynthetic);

  MethodMirror method2 =
      reflectClass(B).declarations[#noSuchMethod] as MethodMirror;
  Expect.isFalse(method2.isSynthetic);

  MethodMirror method3 = reflectClass(A).declarations[#c] as MethodMirror;
  Expect.isFalse(method3.isSynthetic);
}
