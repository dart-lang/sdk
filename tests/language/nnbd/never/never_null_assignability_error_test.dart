// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'never_null_assignability_lib1.dart';

// This test validates that in a null safe (opted in) library which calls out
// to another null safe (opted in) library, the static errors around `Never`

// and `Null` that are suppressed when calling out a null safe library from
// a **legacy** library are correctly reported.  This file is derived from
// never_null_assignability_weak_test.dart and validates that calls to a
// null safe library that are only permitted in that test because of legacy
// support become errors when it is opted in.

// Tests for direct calls to null safe functions.
void testNullSafeCalls() {
  // Test calling a null safe function expecting Null from a null safe library
  {
    takesNull(nil);
    takesNull(never);
    takesNull(3 as dynamic);
    (takesNull as dynamic)(3);
  }

  // Test calling a null safe function expecting Never from a null safe library
  {
    takesNever(nil);
    //         ^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Null' can't be assigned to the parameter type 'Never' because 'Never' is not nullable.
    takesNever(never);
    takesNever(3 as dynamic);
    (takesNever as dynamic)(3);
  }

  // Test calling a null safe function expecting int from a null safe library
  {
    takesInt(3);
    takesInt(nil);
    //       ^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Null' can't be assigned to the parameter type 'int' because 'int' is not nullable.
    takesInt(nil as dynamic);
    (takesInt as dynamic)(nil);
    (takesInt as dynamic)("hello");
  }

  // Test calling a null safe function expecting Object from a null safe library
  {
    takesObject(3);
    takesObject(nil);
    //          ^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Null' can't be assigned to the parameter type 'Object' because 'Object' is not nullable.
    takesObject(nil as dynamic);
    (takesObject as dynamic)(nil);
  }

  // Test calling a null safe function expecting Object? from a null safe library
  {
    takesAny(3);
    takesAny(nil);
    (takesAny as dynamic)(nil);
  }
}

void testNullSafeApply() {
  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with null cast to Null at the call
  // site.
  {
    applyTakesNull(takesNull, nil);
    applyTakesNull(takesNever, nil);
    //             ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Never)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Never' isn't.
    applyTakesNull(takesAny, nil);

    applyTakesNull(takesInt, nil);
    //             ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(int)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'int' isn't.
    applyTakesNull(takesObject, nil);
    //             ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Object)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Object' isn't.
  }

  // Test applying a null safe function of static type void Function(Null)
  // in a null safe library, when called with a non-null value cast to Null
  // at the call site.
  {
    applyTakesNull(takesNull, 3);
    applyTakesNull(takesNever, 3);
    //             ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Never)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Never' isn't.
    applyTakesNull(takesInt, 3);
    //             ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(int)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'int' isn't.
    applyTakesNull(takesObject, 3);
    //             ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Object)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Object' isn't.
    applyTakesNull(takesAny, 3);
  }

  // Test applying a null safe function of static type void Function(Never)
  // in a null safe library, when called with null cast to Never at the call
  // site.
  {
    applyTakesNever(takesNull, nil);
    applyTakesNever(takesNever, nil);
    applyTakesNever(takesAny, nil);
    applyTakesNever(takesInt, nil);
    applyTakesNever(takesObject, nil);
  }

  // Test applying a null safe function of static type void Function(Never)
  // in a null safe library, when called with a non-null value cast to Never
  // at the call site.
  {
    applyTakesNever(takesNull, 3);
    applyTakesNever(takesNever, 3);
    applyTakesNever(takesInt, 3);
    applyTakesNever(takesObject, 3);
    applyTakesNever(takesAny, 3);
  }
}

void testNullSafeApplyDynamically() {
  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // null.
  {
    applyTakesNullDynamically(takesNull, nil);
    applyTakesNullDynamically(takesNever, nil);
    //                        ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Never)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Never' isn't.
    applyTakesNullDynamically(takesAny, nil);
    applyTakesNullDynamically(takesInt, nil);
    //                        ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(int)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'int' isn't.
    applyTakesNullDynamically(takesObject, nil);
    //                        ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Object)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Object' isn't.
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Null) in a null safe library, when called with
  // a non-null value.
  {
    applyTakesNullDynamically(takesNull, 3);
    applyTakesNullDynamically(takesNever, 3);
    //                        ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Never)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Never' isn't.
    applyTakesNullDynamically(takesInt, 3);
    //                        ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(int)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'int' isn't.
    applyTakesNullDynamically(takesInt, "hello");
    //                        ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(int)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'int' isn't.
    applyTakesNullDynamically(takesObject, 3);
    //                        ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'void Function(Object)' can't be assigned to the parameter type 'void Function(Null)' because 'Null' is nullable and 'Object' isn't.
    applyTakesNullDynamically(takesAny, 3);
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Never) in a null safe library, when called with
  // null.
  {
    applyTakesNeverDynamically(takesNull, nil);
    applyTakesNeverDynamically(takesNever, nil);
    applyTakesNeverDynamically(takesAny, nil);
    applyTakesNeverDynamically(takesInt, nil);
    applyTakesNeverDynamically(takesObject, nil);
  }

  // Test dynamically applying a null safe function of static type
  // void Function(Never) in a null safe library, when called with
  // a non-null value.
  {
    applyTakesNeverDynamically(takesNull, 3);
    applyTakesNeverDynamically(takesNever, 3);
    applyTakesNeverDynamically(takesInt, 3);
    applyTakesNeverDynamically(takesInt, "hello");
    applyTakesNeverDynamically(takesObject, 3);
    applyTakesNeverDynamically(takesAny, 3);
  }
}

void main() {
  never = null;
  // ^
  // [analyzer] unspecified
  //      ^
  // [cfe] The value 'null' can't be assigned to a variable of type 'Never' because 'Never' is not nullable.
  never = nil;
  // ^
  // [analyzer] unspecified
  //      ^
  // [cfe] A value of type 'Null' can't be assigned to a variable of type 'Never' because 'Never' is not nullable.
  nil = never;
  testNullSafeCalls();
  testNullSafeApply();
  testNullSafeApplyDynamically();
}
