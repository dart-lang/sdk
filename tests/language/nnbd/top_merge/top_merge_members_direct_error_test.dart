// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Tests several aspects of the TOP_MERGE algorithm for merging members

class A<T> {
  T member() {
    throw "Unreachable";
  }
}

class B<T> {
  T member() {
    throw "Unreachable";
  }
}

void takesObject(Object x) {}

class D0 extends A<dynamic> implements B<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D1 extends A<Object?> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D2 extends A<void> implements B<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D3 extends A<Object?> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D4 extends A<void> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D5 extends A<dynamic> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class D6 extends A<void> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that member does not return Object?
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class D7 extends A<dynamic> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns dynamic
  }
}

// Test the same examples with top level normalization

class ND0 extends A<FutureOr<dynamic>> implements B<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND1 extends A<FutureOr<Object?>> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND2 extends A<FutureOr<void>> implements B<Object?> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND3 extends A<FutureOr<Object?>> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND4 extends A<FutureOr<void>> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND5 extends A<FutureOr<dynamic>> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class ND6 extends A<FutureOr<void>> implements B<void> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member does not return dynamic
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that member does not return Object?
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that member does not return Object
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class ND7 extends A<FutureOr<dynamic>> implements B<dynamic> {
  void test() {
    var self = this;
    var x = self.member();
    x.foo; // Check that member returns dynamic
  }
}

// Test the same examples with deep normalization

class DND0 extends A<FutureOr<dynamic> Function()>
    implements B<Object? Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND1 extends A<FutureOr<Object?> Function()>
    implements B<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND2 extends A<FutureOr<void> Function()>
    implements B<Object? Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND3 extends A<FutureOr<Object?> Function()>
    implements B<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND4 extends A<FutureOr<void> Function()>
    implements B<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND5 extends A<FutureOr<dynamic> Function()>
    implements B<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class DND6 extends A<FutureOr<void> Function()> implements B<void Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that member does not return Object? Function()
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class DND7 extends A<FutureOr<dynamic> Function()>
    implements B<dynamic Function()> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns dynamic Function()
  }
}

// Test the same examples with deep normalization + typedefs

typedef Wrap<T> = FutureOr<T>? Function();

class WND0 extends A<Wrap<FutureOr<dynamic>>> implements B<Wrap<Object?>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND1 extends A<Wrap<FutureOr<Object?>>> implements B<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND2 extends A<Wrap<FutureOr<void>>> implements B<Wrap<Object?>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND3 extends A<Wrap<FutureOr<Object?>>> implements B<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND4 extends A<Wrap<FutureOr<void>>> implements B<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND5 extends A<Wrap<FutureOr<dynamic>>> implements B<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The getter 'foo' isn't defined for the type 'Object?'.
    x.toString; // Check that member does not return void Function()
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'Object?' can't be assigned to the parameter type 'Object'.
  }
}

class WND6 extends A<Wrap<FutureOr<void>>> implements B<Wrap<void>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member does not return dynamic Function()
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] The getter 'foo' isn't defined for the type 'void'.
    x.toString; // Check that member does not return Object? Function()
    // [error column 5]
    // [cfe] This expression has type 'void' and can't be used.
    //^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    takesObject(x); // Check that member does not return Object Function()
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    // [cfe] This expression has type 'void' and can't be used.
  }
}

class WND7 extends A<Wrap<FutureOr<dynamic>>> implements B<Wrap<dynamic>> {
  void test() {
    var self = this;
    var x = self.member()();
    x.foo; // Check that member returns dynamic Function()
  }
}
