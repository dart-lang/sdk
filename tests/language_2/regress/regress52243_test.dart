// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

/// Regression test for the issue discovered by
/// https://github.com/dart-lang/sdk/issues/52243.
///
/// In DDC the types [num], [int], [double], [String], and [bool] used in bounds
/// caused an "optimization" in type tests that was incorrect when passing a
/// subtype as the type argument.

bool isWithNumBound<T extends num>(x) => x is T;
T asWithNumBound<T extends num>(x) => x as T;
bool isWithIntBound<T extends int>(x) => x is T;
T asWithIntBound<T extends int>(x) => x as T;
bool isWithDoubleBound<T extends double>(x) => x is T;
T asWithDoubleBound<T extends double>(x) => x as T;
bool isWithStringBound<T extends String>(x) => x is T;
T asWithStringBound<T extends String>(x) => x as T;
bool isWithBoolBound<T extends bool>(x) => x is T;
T asWithBoolBound<T extends bool>(x) => x as T;

main() {
  Expect.isTrue(isWithNumBound<num>(1));
  Expect.isTrue(isWithNumBound<int>(1));
  // NOTE: Web backends can't determine that 1 is not a double so that test is
  // excluded here.
  Expect.isFalse(isWithNumBound<Null>(1));
  Expect.isTrue(isWithNumBound<num>(1.2));
  Expect.isFalse(isWithNumBound<int>(1.2));
  Expect.isTrue(isWithNumBound<double>(1.2));
  Expect.isFalse(isWithNumBound<Null>(1.2));
  Expect.isFalse(isWithNumBound<num>(null));
  Expect.isFalse(isWithNumBound<int>(null));
  Expect.isFalse(isWithNumBound<double>(null));
  Expect.isTrue(isWithNumBound<Null>(null));

  Expect.equals(1, asWithNumBound<num>(1));
  Expect.equals(1, asWithNumBound<int>(1));
  // NOTE: Web backends can't determine that 1 is not a double so that test is
  // excluded here.
  Expect.throws<TypeError>(() => asWithNumBound<Null>(1));
  Expect.equals(1.2, asWithNumBound<num>(1.2));
  Expect.throws<TypeError>(() => asWithNumBound<int>(1.2));
  Expect.equals(1.2, asWithNumBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithNumBound<Null>(1.2));
  Expect.equals(null, asWithNumBound<num>(null));
  Expect.equals(null, asWithNumBound<int>(null));
  Expect.equals(null, asWithNumBound<double>(null));
  Expect.equals(null, asWithNumBound<Null>(null));

  Expect.isTrue(isWithIntBound<int>(1));
  Expect.isFalse(isWithIntBound<Null>(1));
  Expect.isFalse(isWithIntBound<int>(1.2));
  Expect.isFalse(isWithIntBound<Null>(1.2));
  Expect.isFalse(isWithIntBound<int>(null));
  Expect.isTrue(isWithIntBound<Null>(null));

  Expect.equals(1, asWithIntBound<int>(1));
  Expect.throws<TypeError>(() => asWithIntBound<Null>(1));
  Expect.throws<TypeError>(() => asWithIntBound<int>(1.2));
  Expect.throws<TypeError>(() => asWithIntBound<Null>(1.2));
  Expect.equals(null, asWithIntBound<int>(null));
  Expect.equals(null, asWithIntBound<Null>(null));

  // NOTE: Web backends can't determine that 1 is not a double so that test is
  // excluded here.
  Expect.isFalse(isWithDoubleBound<Null>(1));
  Expect.isTrue(isWithDoubleBound<double>(1.2));
  Expect.isFalse(isWithDoubleBound<Null>(1.2));
  Expect.isFalse(isWithDoubleBound<double>(null));
  Expect.isTrue(isWithDoubleBound<Null>(null));

  // NOTE: Web backends can't determine that 1 is not a double so that test is
  // excluded here.
  Expect.throws<TypeError>(() => asWithDoubleBound<Null>(1));
  Expect.equals(1.2, asWithDoubleBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithDoubleBound<Null>(1.2));
  Expect.equals(null, asWithDoubleBound<double>(null));
  Expect.equals(null, asWithDoubleBound<Null>(null));

  Expect.isTrue(isWithStringBound<String>('hello'));
  Expect.isFalse(isWithStringBound<Null>('hello'));
  Expect.isFalse(isWithStringBound<String>(null));
  Expect.isTrue(isWithStringBound<Null>(null));

  Expect.equals('hello', asWithStringBound<String>('hello'));
  Expect.throws<TypeError>(() => asWithStringBound<Null>('hello'));
  Expect.equals(null, asWithStringBound<String>(null));
  Expect.equals(null, asWithStringBound<Null>(null));

  Expect.isTrue(isWithBoolBound<bool>(true));
  Expect.isFalse(isWithBoolBound<Null>(true));
  Expect.isFalse(isWithBoolBound<bool>(null));
  Expect.isTrue(isWithBoolBound<Null>(null));

  Expect.equals(true, asWithBoolBound<bool>(true));
  Expect.throws<TypeError>(() => asWithBoolBound<Null>(true));
  Expect.equals(null, asWithBoolBound<bool>(null));
  Expect.equals(null, asWithBoolBound<Null>(null));
}
