// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

exhaustiveNonNullableTypeVariable<T extends Object>(int? o) => switch (o) {
      int() as T => 0,
    };

exhaustiveNonNullableType(int? o) => switch (o) {
      int() as int => 0,
    };

exhaustiveNonNullableSuperType(int? o) => switch (o) {
      int() as num => 0,
    };

exhaustiveNonNullableFutureOr1(FutureOr<int>? o) => switch (o) {
      FutureOr<int>() as FutureOr<int> => 0,
    };

exhaustiveNonNullableFutureOr2(FutureOr<int?> o) => switch (o) {
      FutureOr<int>() as FutureOr<int> => 0,
    };

exhaustiveNonNullableFutureOrTypeVariable1<T extends Object>(FutureOr<T>? o) =>
    switch (o) {
      FutureOr<T>() as FutureOr<T> => 0,
    };

exhaustiveNonNullableFutureOrTypeVariable2<T extends Object>(FutureOr<T?> o) =>
    switch (o) {
      FutureOr<T>() as FutureOr<T> => 0,
    };

main() {
  expect(0, exhaustiveNonNullableTypeVariable<Object>(42));
  expect(0, exhaustiveNonNullableTypeVariable<int>(42));
  throws(() => exhaustiveNonNullableTypeVariable(null));

  expect(0, exhaustiveNonNullableType(42));
  throwsOr(0, () => exhaustiveNonNullableType(null));

  expect(0, exhaustiveNonNullableSuperType(42));
  throws(() => exhaustiveNonNullableSuperType(null));

  expect(0, exhaustiveNonNullableFutureOr1(42));
  expect(0, exhaustiveNonNullableFutureOr1(Future<int>.value(42)));
  throwsOr(0, () => exhaustiveNonNullableFutureOr1(null));

  expect(0, exhaustiveNonNullableFutureOr2(42));
  expect(0, exhaustiveNonNullableFutureOr2(Future<int>.value(42)));
  throwsOr(0, () => exhaustiveNonNullableFutureOr2(Future<int?>.value(null)));
  throwsOr(0, () => exhaustiveNonNullableFutureOr2(null));

  expect(0, exhaustiveNonNullableFutureOrTypeVariable1<Object>(42));
  expect(0,
      exhaustiveNonNullableFutureOrTypeVariable1<int>(Future<int>.value(42)));
  throwsOr(0, () => exhaustiveNonNullableFutureOrTypeVariable1<Object>(null));

  expect(0, exhaustiveNonNullableFutureOrTypeVariable2<int>(42));
  expect(
      0,
      exhaustiveNonNullableFutureOrTypeVariable2<Object>(
          Future<int>.value(42)));
  throwsOr(
      0,
      () => exhaustiveNonNullableFutureOrTypeVariable2<int>(
          Future<int?>.value(null)));
  throwsOr(0, () => exhaustiveNonNullableFutureOrTypeVariable2<Object>(null));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}

final bool inWeakMode = const <Null>[] is List<Object>;

throwsOr(expectedIfWeak, dynamic Function() f) {
  if (inWeakMode) {
    expect(expectedIfWeak, f());
    return;
  } else {
    throws(f);
  }
}

throws(dynamic Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw "Didn't throw";
}
