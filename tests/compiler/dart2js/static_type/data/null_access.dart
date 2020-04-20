// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  test1();
  test2();
  test3();
}

class Class1 {
  const Class1();

  void method1() {}
}

test1() {
  // TODO(johnniwinther): Compute actual type of constants?
  const Class1 c = null;
  return c. /*invoke: [Class1]->void*/ method1();
}

class Class2<T> {
  const Class2();

  T method2() => null;
}

test2() {
  const Class2<int> c = null;
  // TODO(johnniwinther): Track the unreachable code properly.
  return c. /*invoke: [Class2<int>]->int*/ method2();
}

class Class3<T> {
  const Class3();

  Class3<T> method3() => null;
}

test3() {
  const Class3<int> c = null;
  // TODO(johnniwinther): Track the unreachable code properly.
  return c. /*invoke: [Class3<int>]->Class3<int>*/ method3();
}
