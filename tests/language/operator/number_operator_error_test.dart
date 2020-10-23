// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the new context type rules for number operators,
import "../static_type_helper.dart";

// as modified by Null Safety
void main() {
  testTypes<int, double, num, Object>(1, 1.0, 1, 1);
}

void
    testTypes<I extends int, D extends double, N extends num, O extends Object>(
        I ti, D td, N tn, O to) {
  int i = 1;
  double d = 1.0;
  num n = cast(1);
  O oi = cast(1);
  if (oi is! int) throw "promote oi to O&int";
  checkIntersectionType<O, int>(oi, oi, oi);
  O od = cast(1.0);
  if (od is! double) throw "promote od to O&double";
  checkIntersectionType<O, double>(od, od, od);
  O on = cast(1);
  if (on is! num) throw "promote on to I&num";
  checkIntersectionType<O, num>(on, on, on);
  dynamic dyn = cast(1);
  late var never = throw "unreachable";

  /* indent */ i + "string";
  //               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'num'.

  i += d;
  //^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  i += n;
  //^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  i += never;
  //^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  i += dyn; // type of `i + dyn` is `num`, not assignable to `int`.
  //^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ti += i; // Type of expression is `int`, not `I`.
  // ^
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'I'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ti += d; // Type of expression is `num`, not `I`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'I'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ti += n; // Type of expression is `num`, not `I`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'I'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ti += never; // Type of expression is `num`, not `I`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'I'.
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ti += dyn; // type of `i + dyn` is `num`, not assignable to `int`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'I'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  td += i; // Type of expression is `double`, not `D`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'D'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  td += d; // Type of expression is `double`, not `D`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'D'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  td += n; // Type of expression is `double`, not `D`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'D'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  td += dyn; // Type of expression is `double`, not `D`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'D'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  td += never; // Type of expression is `double`, not `D`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'D'.
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += i; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += d; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'N'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += n; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += dyn; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += never; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  O oi1 = to; // New variable to avoid demoting `oi`.
  if (oi1 is int) {
    // Promote oi1 to O&int
    oi1 + d; // Valid
    oi1 += d;
    //  ^
    // [cfe] A value of type 'double' can't be assigned to a variable of type 'O'.
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }

  O oi2 = to;
  if (oi2 is int) {
    // Promote oi2 to O&int.
    oi2 + n; // Valid
    oi2 += n;
    //  ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'O'.
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }

  O oi3 = to;
  if (oi3 is int) {
    // Promote oi3 to O&int.
    oi3 + dyn; // Valid
    oi3 += dyn;
    //  ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'O'.
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }

  O oi4 = to;
  if (oi4 is int) {
    // Promote oi4 to O&int.
    oi4 + never; // Valid.
    oi4 += never;
    //  ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'O'.
    //     ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }

  context<D>(i + td); // Type of expression is `double`, not `D`.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //           ^
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'D'.

  context<D>(n + td); // Type of expression is `double`, not `D`.
  //         ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //           ^
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'D'.

  context<D>(1.0 + td); // Type of expression is `double`, not `D`.
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //             ^
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'D'.

  tn += n; // Type of expression is `num`, not `N`.
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  tn += dyn;
  // ^
  // [cfe] A value of type 'num' can't be assigned to a variable of type 'N'.
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  O on1 = to;
  if (on1 is num) {
    // Promote on1 to O&num.
    on1 += n; // Type of expression is `num`, not `N` or `O`.
    //  ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'O'.
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }

  O on2 = to;
  if (on2 is num) {
    // Promote on2 to O&num.
    on2 += dyn; // Type of expression is `num`, not `N` or `O`.
    //  ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'O'.
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  }
}

// The value as the context type, without risking any assignment promotion.
T cast<T>(Object value) => value as T;
