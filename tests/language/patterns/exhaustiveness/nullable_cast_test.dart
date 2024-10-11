// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

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
  Expect.equals(0, exhaustiveNonNullableTypeVariable<Object>(42));
  Expect.equals(0, exhaustiveNonNullableTypeVariable<int>(42));
  Expect.throws(() => exhaustiveNonNullableTypeVariable(null));

  Expect.equals(0, exhaustiveNonNullableType(42));
  if (!unsoundNullSafety) {
    Expect.throws(() => exhaustiveNonNullableType(null));
  } else {
    Expect.equals(0, exhaustiveNonNullableType(null));
  }

  Expect.equals(0, exhaustiveNonNullableSuperType(42));
  Expect.throws(() => exhaustiveNonNullableSuperType(null));

  Expect.equals(0, exhaustiveNonNullableFutureOr1(42));
  Expect.equals(0, exhaustiveNonNullableFutureOr1(Future<int>.value(42)));
  if (!unsoundNullSafety) {
    Expect.throws(() => exhaustiveNonNullableFutureOr1(null));
  } else {
    Expect.equals(0, exhaustiveNonNullableFutureOr1(null));
  }

  Expect.equals(0, exhaustiveNonNullableFutureOr2(42));
  Expect.equals(0, exhaustiveNonNullableFutureOr2(Future<int>.value(42)));
  if (!unsoundNullSafety) {
    Expect.throws(
        () => exhaustiveNonNullableFutureOr2(Future<int?>.value(null)));
    Expect.throws(() => exhaustiveNonNullableFutureOr2(null));
  } else {
    Expect.equals(0, exhaustiveNonNullableFutureOr2(Future<int?>.value(null)));
    Expect.equals(0, exhaustiveNonNullableFutureOr2(null));
  }

  Expect.equals(0, exhaustiveNonNullableFutureOrTypeVariable1<Object>(42));
  Expect.equals(0,
      exhaustiveNonNullableFutureOrTypeVariable1<int>(Future<int>.value(42)));
  if (!unsoundNullSafety) {
    Expect.throws(
        () => exhaustiveNonNullableFutureOrTypeVariable1<Object>(null));
  } else {
    Expect.equals(0, exhaustiveNonNullableFutureOrTypeVariable1<Object>(null));
  }

  Expect.equals(0, exhaustiveNonNullableFutureOrTypeVariable2<int>(42));
  Expect.equals(
      0,
      exhaustiveNonNullableFutureOrTypeVariable2<Object>(
          Future<int>.value(42)));
  if (!unsoundNullSafety) {
    Expect.throws(() => exhaustiveNonNullableFutureOrTypeVariable2<int>(
        Future<int?>.value(null)));
    Expect.throws(
        () => exhaustiveNonNullableFutureOrTypeVariable2<Object>(null));
  } else {
    Expect.equals(
        0,
        exhaustiveNonNullableFutureOrTypeVariable2<int>(
            Future<int?>.value(null)));
    Expect.equals(0, exhaustiveNonNullableFutureOrTypeVariable2<Object>(null));
  }
}
