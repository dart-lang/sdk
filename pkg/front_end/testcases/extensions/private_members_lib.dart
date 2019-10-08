// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension _PrivateExtension on String {
  int publicMethod1() => 42;
  int _privateMethod1() => 87;
  static int publicStaticMethod1() => 24;
  static int _privateStaticMethod1() => 78;

  test1() {
    expect(42, publicMethod1());
    expect(87, _privateMethod1());
    expect(24, publicStaticMethod1());
    expect(78, _privateStaticMethod1());
  }
}

extension PublicExtension on String {
  int publicMethod2() => 123;
  int _privateMethod2() => 237;
  static int publicStaticMethod2() => 321;
  static int _privateStaticMethod2() => 732;

  test2() {
    expect(123, publicMethod2());
    expect(237, _privateMethod2());
    expect(321, publicStaticMethod2());
    expect(732, _privateStaticMethod2());
  }
}

extension on String {
  int publicMethod3() => 473;
  int _privateMethod3() => 586;
  static int publicStaticMethod3() => 374;
  static int _privateStaticMethod3() => 685;

  test3() {
    expect(473, publicMethod3());
    expect(586, _privateMethod3());
    expect(374, publicStaticMethod3());
    expect(685, _privateStaticMethod3());
  }
}

test() {
  expect(42, "".publicMethod1());
  expect(87, ""._privateMethod1());
  expect(123, "".publicMethod2());
  expect(237, ""._privateMethod2());
  expect(473, "".publicMethod3());
  expect(586, ""._privateMethod3());

  expect(42, _PrivateExtension("").publicMethod1());
  expect(87, _PrivateExtension("")._privateMethod1());
  expect(123, PublicExtension("").publicMethod2());
  expect(237, PublicExtension("")._privateMethod2());

  expect(24, _PrivateExtension.publicStaticMethod1());
  expect(78, _PrivateExtension._privateStaticMethod1());
  expect(321, PublicExtension.publicStaticMethod2());
  expect(732, PublicExtension._privateStaticMethod2());

  "".test1();
  "".test2();
  "".test3();
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
