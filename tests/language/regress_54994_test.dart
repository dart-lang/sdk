// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();

  X<double>();
  X<int>().test1();
  X<int>().test2();
}

final bool kTrue = int.parse('1') == 1;

void test1() {
  final B0<int> a = kTrue ? B2<String>() : B1<bool, bool>();
  Expect.isFalse(a is B2<int>);
  Expect.isTrue(a is B2<String>);
}

void test2() {
  final B1<num, num> a = kTrue
      ? (B1<int, double>() as B1<num, num>)
      : (B2<double>() as B1<num, num>);
  Expect.isFalse(a is B2<int>);
  Expect.isFalse(a is B2<double>);
  Expect.isFalse(a is B2<num>); // Should be optimized to cid-range check.
}

void test3() {
  final B1<int, num> a =
      kTrue ? (B1<int, double>() as B1<int, num>) : (B2<int>() as B1<int, num>);
  Expect.isFalse(a is B2<int>);
  Expect.isFalse(a is B2<double>);
  Expect.isFalse(a is B2<num>);
}

void test4() {
  final B1<num, num> a = kTrue ? B2<int>() : B1<num, num>();
  Expect.isTrue(a is B2<num>); // Should be optimized to cid-range check.
  Expect.isTrue(a is B2<int>);
  Expect.isFalse(a is B2<double>);
}

void test5() {
  final B1<int, num> a = kTrue ? B2<int>() : B1<int, num>();
  Expect.isTrue(a is B2<num>);
  Expect.isTrue(a is B2<int>);
  Expect.isFalse(a is B2<double>);
}

void test6() {
  final B1<int, int> a = kTrue ? B2<int>() : B1<int, int>();
  Expect.isTrue(a is B2<num>); // Should be optimized to cid-range check.
  Expect.isTrue(a is B2<int>); // Should be optimized to cid-range check.
  Expect.isFalse(a is B2<double>);
}

void test7() {
  final B1<List<int>, List<int>> a =
      kTrue ? B2<List<int>>() : B1<List<int>, List<int>>();
  Expect.isTrue(a is B2<List<num>>); // Should be optimized to cid-range check.
  Expect.isTrue(a is B2<List<int>>); // Should be optimized to cid-range check.
  Expect.isFalse(a is B2<List<double>>);
}

class X<T extends num> {
  void test1() {
    final B1<T, T> a = kTrue ? B2<T>() : B1<T, T>();
    Expect.isTrue(a is B2<T>); // Should be optimized to cid-range check.
    Expect.isTrue(a is B2<int>);
    Expect.isFalse(a is B2<double>);
  }

  void test2() {
    final B1<List<T>, List<T>> a =
        kTrue ? B2<List<T>>() : B1<List<T>, List<T>>();
    Expect.isTrue(a is B2<List<T>>); // Should be optimized to cid-range check.
    Expect.isTrue(
        a is B2<List<num>>); // Should be optimized to cid-range check.
    Expect.isTrue(a is B2<List<int>>);
    Expect.isFalse(a is B2<List<double>>);
  }
}

class B0<T> {}

class B1<T, H> extends B0<int> {}

class B2<T> extends B1<T, T> {}
