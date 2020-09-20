// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  void f(int i);
  void g([int i]);
  void h({int i});
}

abstract class Mixin implements Base {}

class Derived extends Object with Mixin {
  // Type `(int) -> void` should be inherited from `Base`
  f(i) {}

  // Type `([int]) -> void` should be inherited from `Base`
  g([i = -1]) {}

  // Type `({h: int}) -> void` should be inherited from `Base`
  h({i = -1}) {}
}

main() {
  var d = new Derived();
  d.f('bad');
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  d.g('bad');
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  d.h(i: 'bad');
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  Object x = d.f(1);
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  Object y = d.g(1);
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  Object z = d.h(i: 1);
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}
