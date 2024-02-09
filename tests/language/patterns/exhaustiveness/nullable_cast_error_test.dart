// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Work-around for `<pattern>?` vs `<type>?` conflict which favors the former.
typedef Nullable<T> = T?;

nonExhaustiveNullableTypeVariable<T>(int? o) => switch (o) {
//                                              ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                      ^
// [cfe] The type 'int?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
      int() as T => 0,
    };

nonExhaustiveNonNullableType(int? o) => switch (o) {
//                                      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                              ^
// [cfe] The type 'int?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
      int() as Nullable<int> => 0,
    };

nonExhaustiveNonNullableFutureOr1(FutureOr<int>? o) => switch (o) {
//                                                     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                             ^
// [cfe] The type 'FutureOr<int>?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
      FutureOr<int>() as Nullable<FutureOr<int>> => 0,
    };

nonExhaustiveNonNullableFutureOr2(FutureOr<int?> o) => switch (o) {
//                                                     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                             ^
// [cfe] The type 'FutureOr<int?>' is not exhaustively matched by the switch cases since it doesn't match 'Future<int?>()'.
      FutureOr<int>() as FutureOr<int?> => 0,
    };

nonExhaustiveNonNullableFutureOrTypeVariable1<T extends Object>(
        FutureOr<T>? o) =>
    switch (o) {
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//          ^
// [cfe] The type 'FutureOr<T>?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
      FutureOr<T>() as Nullable<FutureOr<T>> => 0,
    };

nonExhaustiveNonNullableFutureOrTypeVariable2<T extends Object>(
        FutureOr<T?> o) =>
    switch (o) {
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//          ^
// [cfe] The type 'FutureOr<T?>' is not exhaustively matched by the switch cases since it doesn't match 'Future<T?>()'.
      FutureOr<T>() as FutureOr<T?> => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable1<T>(FutureOr<T>? o) => switch (o) {
      FutureOr<T>() as FutureOr<T> => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable2<T>(FutureOr<T?> o) => switch (o) {
      FutureOr<T>() as FutureOr<T> => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable3<T>(FutureOr<T>? o) => switch (o) {
//                                                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                                       ^
// [cfe] The type 'FutureOr<T>?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
      FutureOr<T>() as Nullable<FutureOr<T>> => 0,
    };

nonExhaustiveNullableFutureOrTypeVariable4<T>(FutureOr<T?> o) => switch (o) {
//                                                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                                       ^
// [cfe] The type 'FutureOr<T?>' is not exhaustively matched by the switch cases since it doesn't match 'Future<T?>()'.
      FutureOr<T>() as FutureOr<T?> => 0,
    };
