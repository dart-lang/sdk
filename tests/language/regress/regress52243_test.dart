// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/// Regression test for the issue discovered by
/// https://github.com/dart-lang/sdk/issues/52243.
///
/// In DDC the types [num], [int], [double], [String], and [bool] used in bounds
/// caused an "optimization" in type tests that was incorrect when passing a
/// subtype as the type argument.

bool isWithNumBound<T extends num>(x) => x is T;
T asWithNumBound<T extends num>(x) => x as T;
bool isWithNullableNumBound<T extends num?>(x) => x is T;
T asWithNullableNumBound<T extends num?>(x) => x as T;
bool isWithIntBound<T extends int>(x) => x is T;
T asWithIntBound<T extends int>(x) => x as T;
bool isWithNullableIntBound<T extends int?>(x) => x is T;
T asWithNullableIntBound<T extends int?>(x) => x as T;
bool isWithDoubleBound<T extends double>(x) => x is T;
T asWithDoubleBound<T extends double>(x) => x as T;
bool isWithNullableDoubleBound<T extends double?>(x) => x is T;
T asWithNullableDoubleBound<T extends double?>(x) => x as T;
bool isWithStringBound<T extends String>(x) => x is T;
T asWithStringBound<T extends String>(x) => x as T;
bool isWithNullableStringBound<T extends String?>(x) => x is T;
T asWithNullableStringBound<T extends String?>(x) => x as T;
bool isWithBoolBound<T extends bool>(x) => x is T;
T asWithBoolBound<T extends bool>(x) => x as T;
bool isWithNullableBoolBound<T extends bool?>(x) => x is T;
T asWithNullableBoolBound<T extends bool?>(x) => x as T;

expectTypeErrorWhenSoundOrValue<T>(T Function(T) computation, T value) {
  hasSoundNullSafety
      ? Expect.throws<TypeError>(() => computation(value))
      : Expect.equals(value, computation(value));
}

main() {
  // NOTE: JavaScript platforms can't determine that 1 is not a double so any
  // test combination that would exercise that pattern are excluded here.
  Expect.isTrue(isWithNumBound<num>(1));
  Expect.isTrue(isWithNumBound<int>(1));
  Expect.isFalse(isWithNumBound<Never>(1));
  Expect.isTrue(isWithNumBound<num>(1.2));
  Expect.isFalse(isWithNumBound<int>(1.2));
  Expect.isTrue(isWithNumBound<double>(1.2));
  Expect.isFalse(isWithNumBound<Never>(1.2));

  Expect.equals(1, asWithNumBound<num>(1));
  Expect.equals(1, asWithNumBound<int>(1));
  Expect.throws<TypeError>(() => asWithNumBound<Never>(1));
  Expect.equals(1.2, asWithNumBound<num>(1.2));
  Expect.throws<TypeError>(() => asWithNumBound<int>(1.2));
  Expect.equals(1.2, asWithNumBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithNumBound<Never>(1.2));

  Expect.isTrue(isWithNullableNumBound<num>(1));
  Expect.isTrue(isWithNullableNumBound<int>(1));
  Expect.isFalse(isWithNullableNumBound<Never>(1));
  Expect.isTrue(isWithNullableNumBound<num?>(1));
  Expect.isTrue(isWithNullableNumBound<int?>(1));
  Expect.isFalse(isWithNullableNumBound<Null>(1));
  Expect.isTrue(isWithNullableNumBound<num>(1.2));
  Expect.isFalse(isWithNullableNumBound<int>(1.2));
  Expect.isTrue(isWithNullableNumBound<double>(1.2));
  Expect.isFalse(isWithNullableNumBound<Never>(1.2));
  Expect.isTrue(isWithNullableNumBound<num?>(1.2));
  Expect.isFalse(isWithNullableNumBound<int?>(1.2));
  Expect.isTrue(isWithNullableNumBound<double?>(1.2));
  Expect.isFalse(isWithNullableNumBound<Null>(1.2));
  Expect.isFalse(isWithNullableNumBound<num>(null));
  Expect.isFalse(isWithNullableNumBound<int>(null));
  Expect.isFalse(isWithNullableNumBound<double>(null));
  Expect.isFalse(isWithNullableNumBound<Never>(null));
  Expect.isTrue(isWithNullableNumBound<num?>(null));
  Expect.isTrue(isWithNullableNumBound<int?>(null));
  Expect.isTrue(isWithNullableNumBound<double?>(null));
  Expect.isTrue(isWithNullableNumBound<Null>(null));

  Expect.equals(1, asWithNullableNumBound<num>(1));
  Expect.equals(1, asWithNullableNumBound<int>(1));
  Expect.throws<TypeError>(() => asWithNullableNumBound<Never>(1));
  Expect.equals(1, asWithNullableNumBound<num?>(1));
  Expect.equals(1, asWithNullableNumBound<int?>(1));
  Expect.throws<TypeError>(() => asWithNullableNumBound<Null>(1));
  Expect.equals(1.2, asWithNullableNumBound<num>(1.2));
  Expect.throws<TypeError>(() => asWithNullableNumBound<int>(1.2));
  Expect.equals(1.2, asWithNullableNumBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithNullableNumBound<Never>(1.2));
  Expect.equals(1.2, asWithNullableNumBound<num?>(1.2));
  Expect.throws<TypeError>(() => asWithNullableNumBound<int?>(1.2));
  Expect.equals(1.2, asWithNullableNumBound<double?>(1.2));
  Expect.throws<TypeError>(() => asWithNullableNumBound<Null>(1.2));
  expectTypeErrorWhenSoundOrValue(asWithNullableNumBound<num>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableNumBound<int>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableNumBound<double>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableNumBound<Never>, null);
  Expect.equals(null, asWithNullableNumBound<num?>(null));
  Expect.equals(null, asWithNullableNumBound<int?>(null));
  Expect.equals(null, asWithNullableNumBound<double?>(null));
  Expect.equals(null, asWithNullableNumBound<Null>(null));

  Expect.isTrue(isWithIntBound<int>(1));
  Expect.isFalse(isWithIntBound<Never>(1));
  Expect.isFalse(isWithIntBound<int>(1.2));
  Expect.isFalse(isWithIntBound<Never>(1.2));

  Expect.equals(1, asWithIntBound<int>(1));
  Expect.throws<TypeError>(() => asWithIntBound<Never>(1));
  Expect.throws<TypeError>(() => asWithIntBound<int>(1.2));
  Expect.throws<TypeError>(() => asWithIntBound<Never>(1.2));

  Expect.isTrue(isWithNullableIntBound<int>(1));
  Expect.isFalse(isWithNullableIntBound<Never>(1));
  Expect.isTrue(isWithNullableIntBound<int?>(1));
  Expect.isFalse(isWithNullableIntBound<Null>(1));
  Expect.isFalse(isWithNullableIntBound<int>(1.2));
  Expect.isFalse(isWithNullableIntBound<Never>(1.2));
  Expect.isFalse(isWithNullableIntBound<int?>(1.2));
  Expect.isFalse(isWithNullableIntBound<Null>(1.2));
  Expect.isFalse(isWithNullableIntBound<int>(null));
  Expect.isFalse(isWithNullableIntBound<Never>(null));
  Expect.isTrue(isWithNullableIntBound<int?>(null));
  Expect.isTrue(isWithNullableIntBound<Null>(null));

  Expect.equals(1, asWithNullableIntBound<int>(1));
  Expect.throws<TypeError>(() => asWithNullableIntBound<Never>(1));
  Expect.equals(1, asWithNullableIntBound<int?>(1));
  Expect.throws<TypeError>(() => asWithNullableIntBound<Null>(1));
  Expect.throws<TypeError>(() => asWithNullableIntBound<int>(1.2));
  Expect.throws<TypeError>(() => asWithNullableIntBound<Never>(1.2));
  Expect.throws<TypeError>(() => asWithNullableIntBound<int?>(1.2));
  Expect.throws<TypeError>(() => asWithNullableIntBound<Null>(1.2));
  expectTypeErrorWhenSoundOrValue(asWithNullableIntBound<int>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableIntBound<Never>, null);
  Expect.equals(null, asWithNullableIntBound<int?>(null));
  Expect.equals(null, asWithNullableIntBound<Null>(null));

  Expect.isFalse(isWithDoubleBound<Never>(1));
  Expect.isTrue(isWithDoubleBound<double>(1.2));
  Expect.isFalse(isWithDoubleBound<Never>(1.2));

  Expect.throws<TypeError>(() => asWithDoubleBound<Never>(1));
  Expect.equals(1.2, asWithDoubleBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithDoubleBound<Never>(1.2));

  Expect.isFalse(isWithNullableDoubleBound<Never>(1));
  Expect.isFalse(isWithNullableDoubleBound<Null>(1));
  Expect.isTrue(isWithNullableDoubleBound<double>(1.2));
  Expect.isFalse(isWithNullableDoubleBound<Never>(1.2));
  Expect.isTrue(isWithNullableDoubleBound<double?>(1.2));
  Expect.isFalse(isWithNullableDoubleBound<Null>(1.2));
  Expect.isFalse(isWithNullableDoubleBound<double>(null));
  Expect.isFalse(isWithNullableDoubleBound<Never>(null));
  Expect.isTrue(isWithNullableDoubleBound<double?>(null));
  Expect.isTrue(isWithNullableDoubleBound<Null>(null));

  Expect.throws<TypeError>(() => asWithNullableDoubleBound<Never>(1));
  Expect.throws<TypeError>(() => asWithNullableDoubleBound<Null>(1));
  Expect.equals(1.2, asWithNullableDoubleBound<double>(1.2));
  Expect.throws<TypeError>(() => asWithNullableDoubleBound<Never>(1.2));
  Expect.equals(1.2, asWithNullableDoubleBound<double?>(1.2));
  Expect.throws<TypeError>(() => asWithNullableDoubleBound<Null>(1.2));
  expectTypeErrorWhenSoundOrValue(asWithNullableDoubleBound<double>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableDoubleBound<Never>, null);
  Expect.equals(null, asWithNullableDoubleBound<double?>(null));
  Expect.equals(null, asWithNullableDoubleBound<Null>(null));

  Expect.isTrue(isWithStringBound<String>('hello'));
  Expect.isFalse(isWithStringBound<Never>('hello'));

  Expect.equals('hello', asWithStringBound<String>('hello'));
  Expect.throws<TypeError>(() => asWithStringBound<Never>('hello'));

  Expect.isTrue(isWithNullableStringBound<String>('hello'));
  Expect.isFalse(isWithNullableStringBound<Never>('hello'));
  Expect.isTrue(isWithNullableStringBound<String?>('hello'));
  Expect.isFalse(isWithNullableStringBound<Null>('hello'));
  Expect.isFalse(isWithNullableStringBound<String>(null));
  Expect.isFalse(isWithNullableStringBound<Never>(null));
  Expect.isTrue(isWithNullableStringBound<String?>(null));
  Expect.isTrue(isWithNullableStringBound<Null>(null));

  Expect.equals('hello', asWithNullableStringBound<String>('hello'));
  Expect.throws<TypeError>(() => asWithNullableStringBound<Never>('hello'));
  Expect.equals('hello', asWithNullableStringBound<String?>('hello'));
  Expect.throws<TypeError>(() => asWithNullableStringBound<Null>('hello'));
  expectTypeErrorWhenSoundOrValue(asWithNullableStringBound<String>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableStringBound<Never>, null);
  Expect.equals(null, asWithNullableStringBound<String?>(null));
  Expect.equals(null, asWithNullableStringBound<Null>(null));

  Expect.isTrue(isWithBoolBound<bool>(true));
  Expect.isFalse(isWithBoolBound<Never>(true));

  Expect.equals(true, asWithBoolBound<bool>(true));
  Expect.throws<TypeError>(() => asWithBoolBound<Never>(true));

  Expect.isTrue(isWithNullableBoolBound<bool>(true));
  Expect.isFalse(isWithNullableBoolBound<Never>(true));
  Expect.isTrue(isWithNullableBoolBound<bool?>(true));
  Expect.isFalse(isWithNullableBoolBound<Null>(true));
  Expect.isFalse(isWithNullableBoolBound<bool>(null));
  Expect.isFalse(isWithNullableBoolBound<Never>(null));
  Expect.isTrue(isWithNullableBoolBound<bool?>(null));
  Expect.isTrue(isWithNullableBoolBound<Null>(null));

  Expect.equals(true, asWithNullableBoolBound<bool>(true));
  Expect.throws<TypeError>(() => asWithNullableBoolBound<Never>(true));
  Expect.equals(true, asWithNullableBoolBound<bool?>(true));
  Expect.throws<TypeError>(() => asWithNullableBoolBound<Null>(true));
  expectTypeErrorWhenSoundOrValue(asWithNullableBoolBound<bool>, null);
  expectTypeErrorWhenSoundOrValue(asWithNullableBoolBound<Never>, null);
  Expect.equals(null, asWithNullableBoolBound<bool?>(null));
  Expect.equals(null, asWithNullableBoolBound<Null>(null));
}
