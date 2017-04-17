// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for Issue 14304.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";
import "package:expect/expect.dart";

class A<T> {
  T m() {}
}

main() {
  ClassMirror a = reflectClass(A);
  TypeVariableMirror t = a.typeVariables[0];
  MethodMirror m = a.declarations[#m];

  Expect.equals(t, m.returnType);
}
