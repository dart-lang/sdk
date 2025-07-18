// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Tests several aspects of the TOP_MERGE algorithm for merging super-interfaces.

class A<T> {}

mixin M<T> implements A<T> {}

T deconstruct<T>(A<T> x) => throw "Unreachable";

void takesObject(Object x) {}

class D0 extends A<dynamic> with M<Object?> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D1 extends A<Object?> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D2 extends A<void> with M<Object?> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D3 extends A<Object?> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D4 extends A<void> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D5 extends A<dynamic> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D6 extends A<void> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that we do not implement A<Object?>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class D7 extends A<dynamic> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we implement A<dynamic>
  }
}

// Test the same examples with top level normalization

class ND0 extends A<FutureOr<dynamic>> with M<Object?> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND1 extends A<FutureOr<Object?>> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND2 extends A<FutureOr<void>> with M<Object?> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND3 extends A<FutureOr<Object?>> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND4 extends A<FutureOr<void>> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND5 extends A<FutureOr<dynamic>> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void>
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND6 extends A<FutureOr<void>> with M<void> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we do not implement A<dynamic>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that we do not implement A<Object?>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that we do not implement A<Object>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class ND7 extends A<FutureOr<dynamic>> with M<dynamic> {
  void test() {
    var x = deconstruct(this);
    x.foo; // Check that we implement A<dynamic>
  }
}

// Test the same examples with deep normalization

class DND0 extends A<FutureOr<dynamic> Function()> with M<Object? Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND1 extends A<FutureOr<Object?> Function()> with M<dynamic Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND2 extends A<FutureOr<void> Function()> with M<Object? Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND3 extends A<FutureOr<Object?> Function()> with M<void Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND4 extends A<FutureOr<void> Function()> with M<dynamic Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND5 extends A<FutureOr<dynamic> Function()> with M<void Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND6 extends A<FutureOr<void> Function()> with M<void Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that we do not implement A<Object? Function()>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class DND7 extends A<FutureOr<dynamic> Function()> with M<dynamic Function()> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we implement A<dynamic Function()>
  }
}

// Test the same examples with deep normalization + typedefs

typedef Wrap<T> = FutureOr<T>? Function();

class WND0 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<Object?>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND1 extends A<Wrap<FutureOr<Object?>>> with M<Wrap<dynamic>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND2 extends A<Wrap<FutureOr<void>>> with M<Wrap<Object?>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND3 extends A<Wrap<FutureOr<Object?>>> with M<Wrap<void>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND4 extends A<Wrap<FutureOr<void>>> with M<Wrap<dynamic>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND5 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<void>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that we do not implement A<void Function()>
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND6 extends A<Wrap<FutureOr<void>>> with M<Wrap<void>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we do not implement A<dynamic Function()>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that we do not implement A<Object? Function()>
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that we do not implement A<Object Function()>
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class WND7 extends A<Wrap<FutureOr<dynamic>>> with M<Wrap<dynamic>> {
  void test() {
    var x = deconstruct(this)();
    x.foo; // Check that we implement A<dynamic Function()>
  }
}
