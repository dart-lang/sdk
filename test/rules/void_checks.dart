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
  T m5(e) => null;
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

void simple_return_inside_block_function_body() {
  return; // OK
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

void assert_is_void_function_is_ok() {
  assert(() {
    return true; // OK
  }());
}

async_function() {
  void f(Function f) {}
  f(() //OK
      async {
    return 1; // OK
  });
}

inference() {
  f(void Function() f) {}
  f(() // LINT
      {
    return 1; // OK
  });
}

generics_with_function() {
  f<T>(T Function() f) => f();
  f(() // OK
      {
    return 1;
  });
  f<void>(() // LINT
      {
    return 1;
  });
}

/// function ref are similar to expression function body with void return type
function_ref_are_ok() {
  fA(void Function(dynamic) f) {}
  fB({void Function(dynamic) f}) {}

  void Function(String e) f1 = (e) {};
  fA(f1); // OK
  final f2 = (e) {};
  fA(f2); // OK
  final f3 = (e) => 1;
  fA(f3); // OK
  final a1 = new A();
  fA(a1.m5); // OK
  fB(f: a1.m5); // OK
  final a2 = new A<void>();
  fA(a2.m5); // OK
}

allow_functionWithReturnType_forFunctionWithout() {
  takeVoidFn(void Function() f) {}
  void Function() voidFn;

  int nonVoidFn() => 1;

  takeVoidFn(nonVoidFn); // OK
  voidFn = nonVoidFn; // OK
  void Function() returnsVoidFn() {
    return nonVoidFn; // OK
  }
}

allow_functionWithReturnType_forFunctionWithout_asComplexExpr() {
  takeVoidFn(void Function() f) {}
  void Function() voidFn;

  List<int Function()> listNonVoidFn;

  takeVoidFn(listNonVoidFn[0]); // OK
  voidFn = listNonVoidFn[0]; // OK
  void Function() returnsVoidFn() {
    return listNonVoidFn[0]; // OK
  }
}

allow_Null_for_void() {
  forget(void Function() f) {}

  forget(() {}); // OK

  void Function() f;
  f = () {}; // OK
}

allow_Future_void_for_void() {
  forget(void Function() f) {}

  forget(() async {}); // OK

  void Function() f;
  f = () async {}; // OK
}

allow_expression_function_body() {
  forget(void Function() f) {}
  int i;
  forget(() => i); // OK
  forget(() => i++); // OK

  void Function() f;
  f = () => i; // OK
  f = () => i++; // OK
}

missing_parameter_for_argument() {
  void foo() {}
  foo(0);
}
