// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {}

void f1(NotGeneric x) {
  x[0] + 1;
  x[0] = 1;
  useNonNullable(x[0] = 1);
  x[0] += 1;
  useNonNullable(x[0] += 1);
  x[0]++;
  useNonNullable(x[0]++);
  ++x[0];
  useNonNullable(++x[0]);
}

void f2(NotGeneric? x) {
  x?[0] + 1;
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] Operator '+' cannot be called on 'int?' because it is potentially null.
  x?[0] = 1;
  useNonNullable(x?[0] = 1);
  //             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
  x?[0] += 1;
  useNonNullable(x?[0] += 1);
  //             ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
  x?[0]++;
  useNonNullable(x?[0]++);
  //             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
  ++x?[0];
  useNonNullable(++x?[0]);
  //             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //               ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

void f3<T extends num>(Generic<T>? x) {
  x?[0] + 1;
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] Operator '+' cannot be called on 'T?' because it is potentially null.
}

void f4<T extends num>(Generic<T?> x) {
  x[0] + 1;
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] Operator '+' cannot be called on 'T?' because it is potentially null.
}

class NotGeneric {
  int operator [](int index) => throw 'unreachable';
  void operator []=(int index, int value) => throw 'unreachable';
}

class Generic<T> {
  T operator [](int index) => throw 'unreachable';
  void operator []=(int index, T value) => throw 'unreachable';
}

void useNonNullable(int a) {}
