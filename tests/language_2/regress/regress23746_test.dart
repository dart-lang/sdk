// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import "package:expect/expect.dart";

class A<T, U> {
  B<T> get b => B<T>();
}

class B<T> {}

@pragma('vm:never-inline')
bool test(Object a, Object b) {
  print(a.runtimeType);
  print(b.runtimeType);
  return a.runtimeType == b.runtimeType;
}

void main() {
  Expect.isTrue(test(B<int>(), A<int, String>().b));
}
