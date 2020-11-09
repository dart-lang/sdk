// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  Never never = throw "Unreachable";
  bool boolean = true;
  dynamic any = 3;
  Null nil = null;
  Object object = Object();
  Object? objectOrNull = null;

  {
    // Check that values of type `Never` are usable as booleans.
    if (never) {}
    [if (never) 3];
    never ? 3 : 4;
    while (never) {}
    do {} while (never);
    never || true;
    never && true;
    true || never;
    true && never;
    for (int i = 0; never; i++) {}
    [for (int i = 0; never; i++) 3];
  }
  {
    // Check that values of type `boolean` are usable as booleans.
    if (boolean) {}
    [if (boolean) 3];
    boolean ? 3 : 4;
    while (boolean) {}
    do {} while (boolean);
    boolean || true;
    boolean && true;
    true || boolean;
    true && boolean;
    for (int i = 0; boolean; i++) {}
    [for (int i = 0; boolean; i++) 3];
  }
  {
    // Check that values of type `dynamic` are usable as booleans.
    if (any) {}
    [if (any) 3];
    any ? 3 : 4;
    while (any) {}
    do {} while (any);
    any || true;
    any && true;
    true || any;
    true && any;
    for (int i = 0; any; i++) {}
    [for (int i = 0; any; i++) 3];
  }
  {
    // Check that values of type `Null` are not usable as booleans.
    if (nil) {}
    //  ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    [if (nil) 3];
    //   ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    nil ? 3 : 4;
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
// [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    while (nil) {}
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    do {} while (nil);
    //           ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    nil || true;
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    nil && true;
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    true || nil;
    //      ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    true && nil;
    //      ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    for (int i = 0; nil; i++) {}
    //              ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
    [for (int i = 0; nil; i++) 3];
    //               ^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Null' can't be assigned to a variable of type 'bool' because 'bool' is not nullable.
  }
  {
    // Check that values of type `Object` are not usable as booleans.
    if (object) {}
    //  ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    [if (object) 3];
    //   ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    object ? 3 : 4;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
// [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    while (object) {}
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    do {} while (object);
    //           ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    object || true;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    object && true;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    true || object;
    //      ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    true && object;
    //      ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    for (int i = 0; object; i++) {}
    //              ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
    [for (int i = 0; object; i++) 3];
    //               ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
  }
  {
    // Check that values of type `Object?` are not usable as booleans.
    if (objectOrNull) {}
    //  ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    [if (objectOrNull) 3];
    //   ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    objectOrNull ? 3 : 4;
//  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
// [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    while (objectOrNull) {}
    //     ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    do {} while (objectOrNull);
    //           ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    objectOrNull || true;
//  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    objectOrNull && true;
//  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
// [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    true || objectOrNull;
    //      ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    true && objectOrNull;
    //      ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_OPERAND
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    for (int i = 0; objectOrNull; i++) {}
    //              ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
    [for (int i = 0; objectOrNull; i++) 3];
    //               ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'Object?' can't be assigned to a variable of type 'bool'.
  }
}
