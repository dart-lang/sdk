// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N void_checks`

import 'dart:async';

var x;
get g => null;
set s(v) {}
m() {}

class A<T> {
  T value;
  A();
  A.c(this.value);
  void m1(T arg) {}
  void m2(i, [T v]) {}
  void m3(i, {T v}) {}
  void m4(void arg) {}
}

void call_constructor_with_void_positional_parameter() {
  new A<void>.c(x); // LINT
}

void call_method_with_void_positional_parameter() {
  final a = new A<void>();
  a.m1(x); // LINT
}

void call_method_with_void_optional_positional_parameter() {
  final a = new A<void>();
  a.m2(
    null,
    x, // LINT
  );
}

void call_method_with_void_optional_named_parameter() {
  final a = new A<void>();
  a.m3(
    null,
    v: x, // LINT
  );
}

void use_setter_with_void_parameter() {
  final a = new A<void>();
  a.value = x; // LINT
}

void call_method_with_futureOr_void_parameter() {
  final a = new A<FutureOr<void>>();
  // it's OK to pass Future or FutureOr to m1
  a.m1(new Future.value()); // OK
  FutureOr<void> fo;
  a.m1(fo); // OK
  a.m1(x); // OK
  a.m1(null); // OK
  a.m1(1); // LINT
}

void use_setter_with_futureOr_void_parameter() {
  final a = new A<FutureOr<void>>();
  // it's OK to pass Future or FutureOr to set value
  a.value = new Future.value(); //OK
  FutureOr<void> fo;
  a.value = fo; // OK
  a.value = x; // OK
  a.value = null; // OK
  a.value = 1; // LINT
}

void return_inside_block_function_body() {
  return x; // LINT
}

void return_from_expression_function_body() => x; // OK

FutureOr<void> return_value_for_futureOr() {
  return 1; // LINT
}

FutureOr<void> return_future_for_futureOr() {
  return new Future.value(); // OK
}

FutureOr<void> return_futureOr_for_futureOr() {
  return x; // OK
}

// generics_with_function() {
//   f<T>(T Function() f) => f();
//   f(() // OK
//       {
//     return 1;
//   });
//   f<void>(() // LINT
//       {
//     return 1;
//   });
// }
