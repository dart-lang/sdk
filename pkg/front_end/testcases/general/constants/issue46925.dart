// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.14

class MyClass<T> {
  final a;
  const MyClass(int i, int j) : a = (i + j);
  const MyClass.constr() : a = 0;
}

test() {
  const v1 = MyClass<String>.new;
  const v2 = MyClass<int>.constr;
  const v3 = MyClass<int>.new;
  const v4 = MyClass<String>.constr;

  const c1 = v1(3, 14);
  const c2 = v1(3, 14);
  const c3 = v2();
  const c4 = v2();
  const c5 = v3(3, 14);
  const c6 = v4();
}

main() {}