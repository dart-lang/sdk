// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B {}

main() {
  var a = new A();
  var b = new B();
  var f = () => null;
  var funcType = f.runtimeType;
  var classA = A;
  var classB = B;

  Expect.isTrue(a.runtimeType is Type);
  Expect.equals(A, a.runtimeType);
  Expect.notEquals(B, a.runtimeType);
  Expect.notEquals(A, b.runtimeType);

  Expect.isTrue(f.runtimeType is Type);
  Expect.isFalse(f.runtimeType == a.runtimeType);

  Expect.isTrue(classA.runtimeType is Type);
  Expect.isTrue(classA.runtimeType == classB.runtimeType);
  Expect.isFalse(classA.runtimeType == a.runtimeType);
  Expect.isFalse(classA.runtimeType == f.runtimeType);

  Expect.isTrue(funcType.runtimeType == classA.runtimeType);

  Expect.isTrue(null.runtimeType is Type);
  Expect.equals(Null, null.runtimeType);

  Expect.equals([].runtimeType.toString(), 'List');
  Expect.equals((<int>[]).runtimeType.toString(), 'List<int>');
}
