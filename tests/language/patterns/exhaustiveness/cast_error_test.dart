// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

nonExhaustiveDynamicAsStringOrDouble(o) => switch (o) {
//                                         ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                 ^
// [cfe] The type 'dynamic' is not exhaustively matched by the switch cases since it doesn't match 'Object()'.
      final String value => value,
      final double value as num => '$value',
    };

nonExhaustiveDynamicAsStringOrIntRestricted(o) => switch (o) {
//                                                ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                        ^
// [cfe] The type 'dynamic' is not exhaustively matched by the switch cases since it doesn't match 'Object()'.
      final String value => value,
      int(isEven: true) as int => '',
    };

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

nonExhaustiveDynamicAsMRestricted(dynamic m) => switch (m) {
//                                              ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                                                      ^
// [cfe] The type 'dynamic' is not exhaustively matched by the switch cases since it doesn't match 'Object()'.
      (A() || B() || C(hashCode: 5)) as M => 0,
    };

nonExhaustiveList(o) => switch (o) {
//                      ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                              ^
// [cfe] The type 'dynamic' is not exhaustively matched by the switch cases since it doesn't match 'Object()'.
      [] as List => 0,
    };

main() {}
