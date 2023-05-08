// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/278841863.
//
// Verifies that generic type literal correctly compares to a runtime type.

import "package:expect/expect.dart";

class A<T> {}

class B<T> extends A {}

dynamic getTypeA<T>() => A<T>;
dynamic getTypeB<T>() => B<T>;

void main() {
  Expect.isTrue(A().runtimeType == getTypeA());
  Expect.isTrue(A<int>().runtimeType == getTypeA<int>());
  Expect.isFalse(A<int>().runtimeType == getTypeA());
  Expect.isFalse(A().runtimeType == getTypeA<int>());

  Expect.isTrue(B().runtimeType == getTypeB());
  Expect.isTrue(B<int>().runtimeType == getTypeB<int>());
  Expect.isFalse(B<int>().runtimeType == getTypeB());
  Expect.isFalse(B().runtimeType == getTypeB<int>());
}
