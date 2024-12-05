// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/56314.

import "package:expect/expect.dart";
import "package:expect/variations.dart";

class B1 {
  String foo1([int a = 100, int b = 200]) => '$a, $b';
}

class D1 extends B1 {
  String foo1([int? a, int? b]) => '${a ?? 100}, ${b ?? 200}';
}

class B2 {
  String foo2({int a = 100, int b = 200}) => '$a, $b';
}

class D2 extends B2 {
  String foo2({int? a, int? b}) => '${a ?? 100}, ${b ?? 200}';
}

class B3 {
  String foo3({int a = 100, int b = 200}) => '$a, $b';
}

class D3 extends B3 {
  String foo3({num a = 1.5, num b = 2.5}) => '$a, $b, '
      '${a is int ? "int" : "double"}, '
      '${b is int ? "int" : "double"}';
}

// B4/D4: Variation that targets a 'widened' type for the subclass method
// parameter in the global type inference abstract value domain of dart2js.

class B4 {
  // With JS numbers, bitwise operations convert their result to an 'unsigned'
  // 32-bit value. `a | 1` is never negative, regardless of the input `a`.
  // dart2js optimizes away the conversion if it sees the inputs are such that
  // the conversion is unnecessary. This happens when both operands are inferred
  // to have small non-negative values. The operands `1` and `a` are small
  // non-negative integers, `a` having a small non-negative default, and when
  // provided at the call site, is also a small non-negative value.
  int foo4([int a = 0]) => a | 1;
}

class D4 extends B4 {
  // The default value is negative, so the conversion is neccessary. The
  // conversion will be optimized away if the negative default value is ignored
  // in the global type analysis.
  int foo4([int a = -16]) => a | 1;
}

@pragma('dart2js:never-inline')
void check1(B1 b) {
  Expect.equals('100, 200', b.foo1());
  Expect.equals('666, 200', b.foo1(666));
  Expect.equals('666, 777', b.foo1(666, 777));
}

@pragma('dart2js:never-inline')
void check2(B2 b) {
  Expect.equals('100, 200', b.foo2());
  Expect.equals('666, 200', b.foo2(a: 666));
  Expect.equals('666, 777', b.foo2(a: 666, b: 777));
}

@pragma('dart2js:never-inline')
void check3(B3 b, bool first) {
  Expect.equals(
    first ? '100, 200' : '1.5, 2.5, double, double',
    b.foo3(),
  );
  Expect.equals(
    first ? '666, 200' : '666, 2.5, int, double',
    b.foo3(a: 666),
  );
  Expect.equals(
    first ? '666, 777' : '666, 777, int, int',
    b.foo3(a: 666, b: 777),
  );
}

@pragma('dart2js:never-inline')
void check4(B4 b, bool isB) {
  Expect.equals(
      isB
          ? 1
          : jsNumbers
              ? 0xfffffff1 // Should be 'unsigned' when using JS numbers.
              : -15,
      b.foo4());
  Expect.equals(3, b.foo4(2));
}

main() {
  check1(B1());
  check1(D1());
  check2(B2());
  check2(D2());
  check3(B3(), true);
  check3(D3(), false);
  check4(B4(), true);
  check4(D4(), false);
}
