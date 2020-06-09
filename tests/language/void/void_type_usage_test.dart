// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks on usage of expressions of type void.

void use(dynamic x) { }
void useAsVoid(void x) { }

Object? testVoidParam(void x) {
  x;  //# param_stmt: ok
  true ? x : x;  //# param_conditional: ok
  for (x; false; x) {}   //# param_for: ok
  useAsVoid(x); //# param_argument_void: ok
  use(x);   //# param_argument: compile-time error
  use(x as Object?);  //# param_as: ok
  void y = x;   //# param_void_init: ok
  dynamic z = x;  //# param_dynamic_init: compile-time error
  x is Object?;   //# param_is: compile-time error
  throw x;   //# param_throw: compile-time error
  <void>[x];   //# param_literal_void_list_init: ok
  <Object?>[x];   //# param_literal_list_init: compile-time error
  var m1 = <int, void>{4: x};   //# param_literal_map_value_init: ok
  var m2 = <void, int>{x : 4};   //# param_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: x};  //# param_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{x : 4};  //# param_literal_map_key_init2: compile-time error
  x ?? 499;  //# param_null_equals1: compile-time error
  null ?? x;  //# param_null_equals2: ok
  return x;   //# param_return: compile-time error
  while (x) {};  //# param_while: compile-time error
  do {} while (x);  //# param_do_while: compile-time error
  for (var v in x) {}   //# param_for_in: compile-time error
  for (x in [1, 2]) {}  //# param_for_in2: ok
  x += 1;  //# param_plus_eq: compile-time error
  x.toString();  //# param_toString: compile-time error
  x?.toString();  //# param_null_dot: compile-time error
  x..toString();  //# param_cascade: compile-time error
  if (x) {}; //# param_conditional_stmt: compile-time error
  !x; //# param_boolean_negation: compile-time error
  x && true; //# param_boolean_and_left: compile-time error
  true && x; //# param_boolean_and_right: compile-time error
  x || true; //# param_boolean_or_left: compile-time error
  true || x; //# param_boolean_or_right: compile-time error
  x == 3; //# param_equals_left: compile-time error
  3 == x; //# param_equals_right: compile-time error
  identical(3, x); //# param_identical: compile-time error
  3 + x; //# param_addition: compile-time error
  3 * x; //# param_multiplication: compile-time error
  -x; //# param_negation: compile-time error
  x(3); //# param_use_as_function: compile-time error
  "hello$x"; //# param_use_in_string_interpolation: compile-time error
  x ??= 3; //# param_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= x; //# param_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[x]; //# param_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[x]; //# param_use_in_map_lookup: compile-time error
}

testVoidAsync(void x) async {
  await x; //# async_use_in_await: compile-time error
}

testVoidAsyncStar(void x) async* {
  yield x; //# async_use_in_yield: compile-time error
  yield* x; //# async_use_in_yield_star: compile-time error
  await for (var i in x) {} //# async_use_in_await_for: compile-time error
}

testVoidSyncStar(void x) sync* {
  yield x; //# sync_use_in_yield: compile-time error
  yield* x; //# sync_use_in_yield_star: compile-time error
}

const void c = null;

dynamic testVoidDefaultParameter([int y = c]) {} //# void_default_parameter_global: compile-time error

dynamic testVoidDefaultParameterClosure() {
  ([int y = c]) => 3;//# void_default_parameter_closure: compile-time error
}

dynamic testVoidParamDynamic(void x) {
  return x;   //# param_return_dynamic: ok
}

Object? testVoidCall(void f()) {
  f();  //# call_stmt: ok
  true ? f() : f();  //# call_conditional: ok
  for (f(); false; f()) {}   //# call_for: ok
  useAsVoid(f()); //# call_argument_void: ok
  use(f());   //# call_argument: compile-time error
  use(f() as Object?);  //# call_as: ok
  void y = f();   //# call_void_init: ok
  dynamic z = f();  //# call_dynamic_init: compile-time error
  f() is Object?;   //# call_is: compile-time error
  throw f();   //# call_throw: compile-time error
  <void>[f()];   //# call_literal_void_list_init: ok
  <Object?>[f()];   //# call_literal_list_init: compile-time error
  var m1 = <int, void>{4: f() };   //# call_literal_map_value_init: ok
  var m2 = <void, int>{ f(): 4};   //# call_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: f() };  //# call_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{ f(): 4};  //# call_literal_map_key_init2: compile-time error
  f() ?? 499;  //# call_null_equals1: compile-time error
  null ?? f();  //# call_null_equals2: ok
  return f();   //# call_return: compile-time error
  while (f()) {};  //# call_while: compile-time error
  do {} while (f());  //# call_do_while: compile-time error
  for (var v in f()) {}   //# call_for_in: compile-time error
  f().toString();  //# call_toString: compile-time error
  f()?.toString();  //# call_null_dot: compile-time error
  f()..toString();  //# call_cascade: compile-time error
  if (f()) {}; //# call_conditional_stmt: compile-time error
  !f(); //# call_boolean_negation: compile-time error
  f() && true; //# call_boolean_and_left: compile-time error
  true && f(); //# call_boolean_and_right: compile-time error
  f() || true; //# call_boolean_or_left: compile-time error
  true || f(); //# call_boolean_or_right: compile-time error
  f() == 3; //# call_equals_left: compile-time error
  3 == f(); //# call_equals_right: compile-time error
  identical(3, f()); //# call_identical: compile-time error
  3 + f(); //# call_addition: compile-time error
  3 * f(); //# call_multiplication: compile-time error
  -f(); //# call_negation: compile-time error
  f()(3); //# call_use_as_function: compile-time error
  "hello${f()}"; //# call_use_in_string_interpolation: compile-time error
  f() ??= 3; //# call_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= f(); //# call_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[f()]; //# call_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[f()]; //# call_use_in_map_lookup: compile-time error
}

dynamic testVoidCallDynamic(void f()) {
  return f();   //# call_return: ok
}

Object? testVoidLocal() {
  void x;
  x = 42;   //# local_assign: ok
  x;  //# local_stmt: ok
  true ? x : x;  //# local_conditional: ok
  for (x; false; x) {}   //# local_for: ok
  useAsVoid(x); //# local_argument_void: ok
  use(x);   //# local_argument: compile-time error
  use(x as Object?);  //# local_as: ok
  void y = x;   //# local_void_init: ok
  dynamic z = x;  //# local_dynamic_init: compile-time error
  x is Object?;   //# local_is: compile-time error
  throw x;   //# local_throw: compile-time error
  <void>[x];   //# local_literal_void_list_init: ok
  <Object?>[x];   //# local_literal_list_init: compile-time error
  var m1 = <int, void>{4: x};   //# local_literal_map_value_init: ok
  var m2 = <void, int>{x : 4};   //# local_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: x};  //# local_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{x : 4};  //# local_literal_map_key_init2: compile-time error
  x ?? 499;  //# local_null_equals1: compile-time error
  null ?? x;  //# local_null_equals2: ok
  return x;   //# local_return: compile-time error
  while (x) {};  //# local_while: compile-time error
  do {} while (x);  //# local_do_while: compile-time error
  for (var v in x) {}   //# local_for_in: compile-time error
  for (x in [1, 2]) {}  //# local_for_in2: ok
  x += 1;  //# local_plus_eq: compile-time error
  x.toString();  //# local_toString: compile-time error
  x?.toString();  //# local_null_dot: compile-time error
  x..toString();  //# local_cascade: compile-time error
   if (x) {}; //# local_conditional_stmt: compile-time error
  !x; //# local_boolean_negation: compile-time error
  x && true; //# local_boolean_and_left: compile-time error
  true && x; //# local_boolean_and_right: compile-time error
  x || true; //# local_boolean_or_left: compile-time error
  true || x; //# local_boolean_or_right: compile-time error
  x == 3; //# local_equals_left: compile-time error
  3 == x; //# local_equals_right: compile-time error
  identical(3, x); //# local_identical: compile-time error
  3 + x; //# local_addition: compile-time error
  3 * x; //# local_multiplication: compile-time error
  -x; //# local_negation: compile-time error
  x(3); //# local_use_as_function: compile-time error
  "hello$x"; //# local_use_in_string_interpolation: compile-time error
  x ??= 3; //# local_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= x; //# local_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[x]; //# local_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[x]; //# local_use_in_map_lookup: compile-time error
}

dynamic testVoidLocalDynamic() {
  void x;
  return x;   //# local_return_dynamic: ok
}

Object? testVoidFinalLocal() {
  final void x = null;
  x = 42;   //# final_local_assign: compile-time error
  x;  //# final_local_stmt: ok
  true ? x : x;  //# final_local_conditional: ok
  for (x; false; x) {}   //# final_local_for: ok
  useAsVoid(x); //# final_local_argument_void: ok
  use(x);   //# final_local_argument: compile-time error
  use(x as Object?);  //# final_local_as: ok
  void y = x;   //# final_local_void_init: ok
  dynamic z = x;  //# final_local_dynamic_init: compile-time error
  x is Object?;   //# final_local_is: compile-time error
  throw x;   //# final_local_throw: compile-time error
  <void>[x];   //# final_local_literal_void_list_init: ok
  <Object?>[x];   //# final_local_literal_list_init: compile-time error
  var m1 = <int, void>{4: x};   //# final_local_literal_map_value_init: ok
  var m2 = <void, int>{x : 4};   //# final_local_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: x};  //# final_local_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{x : 4};  //# final_local_literal_map_key_init2: compile-time error
  x ?? 499;  //# final_local_null_equals1: compile-time error
  null ?? x;  //# final_local_null_equals2: ok
  return x;   //# final_local_return: compile-time error
  while (x) {};  //# final_local_while: compile-time error
  do {} while (x);  //# final_local_do_while: compile-time error
  for (var v in x) {}   //# final_local_for_in: compile-time error
  for (x in [1, 2]) {}  //# final_local_for_in2: compile-time error
  x += 1;  //# final_local_plus_eq: compile-time error
  x.toString();  //# final_local_toString: compile-time error
  x?.toString();  //# final_local_null_dot: compile-time error
  x..toString();  //# final_local_cascade: compile-time error
   if (x) {}; //# final_local_conditional_stmt: compile-time error
  !x; //# final_local_boolean_negation: compile-time error
  x && true; //# final_local_boolean_and_left: compile-time error
  true && x; //# final_local_boolean_and_right: compile-time error
  x || true; //# final_local_boolean_or_left: compile-time error
  true || x; //# final_local_boolean_or_right: compile-time error
  x == 3; //# final_local_equals_left: compile-time error
  3 == x; //# final_local_equals_right: compile-time error
  identical(3, x); //# final_local_identical: compile-time error
  3 + x; //# final_local_addition: compile-time error
  3 * x; //# final_local_multiplication: compile-time error
  -x; //# final_local_negation: compile-time error
  x(3); //# final_local_use_as_function: compile-time error
  "hello$x"; //# final_local_use_in_string_interpolation: compile-time error
  x ??= 3; //# final_local_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= x; //# final_local_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[x]; //# final_local_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[x]; //# final_local_use_in_map_lookup: compile-time error
}

dynamic testVoidFinalLocalDynamic() {
  final void x = null;
  return x;   //# final_local_return_dynamic: ok
}

void global;
Object? testVoidGlobal() {
  global;  //# global_stmt: ok
  true ? global : global;  //# global_conditional: ok
  for (global; false; global) {}   //# global_for: ok
  useAsVoid(global); //# global_argument_void: ok
  use(global);   //# global_argument: compile-time error
  use(global as Object?);  //# global_as: ok
  void y = global;   //# global_void_init: ok
  dynamic z = global;  //# global_dynamic_init: compile-time error
  global is Object?;   //# global_is: compile-time error
  throw global;   //# global_throw: compile-time error
  <void>[global];   //# global_literal_void_list_init: ok
  <Object?>[global];   //# global_literal_list_init: compile-time error
  var m1 = <int, void>{4: global };   //# global_literal_map_value_init: ok
  var m2 = <void, int>{ global: 4};   //# global_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: global };  //# global_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{ global: 4};  //# global_literal_map_key_init2: compile-time error
  null ?? global;  //# global_null_equals1: ok
  global ?? 499;  //# global_null_equals2: compile-time error
  return global;   //# global_return: compile-time error
  while (global) {};  //# global_while: compile-time error
  do {} while (global);  //# global_do_while: compile-time error
  for (var v in global) {}   //# global_for_in: compile-time error
  for (global in [1, 2]) {}  //# global_for_in2: ok
  global += 1;  //# global_plus_eq: compile-time error
  global.toString();  //# global_toString: compile-time error
  global?.toString();  //# global_null_dot: compile-time error
  global..toString();  //# global_cascade: compile-time error
  if (global) {}; //# global_conditional_stmt: compile-time error
  !global; //# global_boolean_negation: compile-time error
  global && true; //# global_boolean_and_left: compile-time error
  true && global; //# global_boolean_and_right: compile-time error
  global || true; //# global_boolean_or_left: compile-time error
  true || global; //# global_boolean_or_right: compile-time error
  global == 3; //# global_equals_left: compile-time error
  3 == global; //# global_equals_right: compile-time error
  identical(3, global); //# global_identical: compile-time error
  3 + global; //# global_addition: compile-time error
  3 * global; //# global_multiplication: compile-time error
  -global; //# global_negation: compile-time error
  global(3); //# global_use_as_function: compile-time error
  "hello$global"; //# global_use_in_string_interpolation: compile-time error
  global ??= 3; //# global_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= global; //# global_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[global]; //# global_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[global]; //# global_use_in_map_lookup: compile-time error
}

dynamic testVoidGlobalDynamic() {
  return global;   //# global_return_dynamic: ok
}

Object? testVoidConditional() {
  void x;
  (true ? x : x);   //# conditional_parens: ok
  true ? x : x;  //# conditional_stmt: ok
  true ? true ? x : x : true ? x : x;  //# conditional_conditional: ok
  for (true ? x : x; false; true ? x : x) {}   //# conditional_for: ok
  useAsVoid(true ? x : x); //# conditional_argument_void: ok
  use(true ? x : x);   //# conditional_argument: compile-time error
  void y = true ? x : x;   //# conditional_void_init: ok
  dynamic z = true ? x : x;  //# conditional_dynamic_init: compile-time error
  throw true ? x : x;   //# conditional_throw: compile-time error
  <void>[true ? x : x];   //# conditional_literal_void_list_init: ok
  <Object?>[true ? x : x];   //# conditional_literal_list_init: compile-time error
  var m1 = <int, void>{4: true ? x : x};   //# conditional_literal_map_value_init: ok
  var m3 = <dynamic, dynamic>{4: true ? x : x};  //# conditional_literal_map_value_init2: compile-time error
  (true ? x : x) ?? null;  //# conditional_null_equals1: compile-time error
  null ?? (true ? x : x);  //# conditional_null_equals2: ok
  return true ? x : x;   //# conditional_return: compile-time error
  while (true ? x : x) {};  //# conditional_while: compile-time error
  do {} while (true ? x : x);  //# conditional_do_while: compile-time error
  for (var v in true ? x : x) {}   //# conditional_for_in: compile-time error

  (true ? 499 : x);   //# conditional2_parens: ok
  true ? 499 : x;  //# conditional2_stmt: ok
  true ? true ? 499 : x : true ? 499 : x;  //# conditional2_conditional: ok
  for (true ? 499 : x; false; true ? 499 : x) {}   //# conditional2_for: ok
  useAsVoid(true ? 499 : x); //# conditional2_argument_void: ok
  use(true ? 499 : x);   //# conditional2_argument: compile-time error
  void y2 = true ? 499 : x;   //# conditional2_void_init: ok
  dynamic z2 = true ? 499 : x;  //# conditional2_dynamic_init: compile-time error
  throw true ? 499 : x;   //# conditional2_throw: compile-time error
  <void>[true ? 499 : x];   //# conditional2_literal_void_list_init: ok
  <Object?>[true ? 499 : x];   //# conditional2_literal_list_init: compile-time error
  var m12 = <int, void>{4: true ? 499 : x};   //# conditional2_literal_map_value_init: ok
  var m32 = <dynamic, dynamic>{4: true ? 499 : x};  //# conditional2_literal_map_value_init2: compile-time error
  (true ? 499 : x) ?? null;  //# conditional2_null_equals1: compile-time error
  null ?? (true ? 499 : x);  //# conditional2_null_equals2: ok
  return true ? 499 : x;   //# conditional2_return: compile-time error
  while (true ? 499 : x) {};  //# conditional2while: compile-time error
  do {} while (true ? 499 : x);  //# conditional2do_while: compile-time error
  for (var v in true ? 499 : x) {}   //# conditional2for_in: compile-time error

  (true ? x : 499);   //# conditional3_parens: ok
  true ? x : 499;  //# conditional3_stmt: ok
  true ? true ? x : 499 : true ? x : 499;  //# conditional3_conditional: ok
  for (true ? x : 499; false; true ? x : 499) {}   //# conditional3_for: ok
  useAsVoid(true ? x : 499); //# conditional3_argument_void: ok
  use(true ? x : 499);   //# conditional3_argument: compile-time error
  void y3 = true ? x : 499;   //# conditional3_void_init: ok
  dynamic z3 = true ? x : 499;  //# conditional3_dynamic_init: compile-time error
  throw true ? x : 499;   //# conditional3_throw: compile-time error
  <void>[true ? x : 499];   //# conditional3_literal_void_list_init: ok
  <Object?>[true ? x : 499];   //# conditional3_literal_list_init: compile-time error
  var m13 = <int, void>{4: true ? x : 499 };   //# conditional3_literal_map_value_init: ok
  var m33 = <dynamic, dynamic>{4: true ? x : 499 };  //# conditional3_literal_map_value_init2: compile-time error
  (true ? x : 499) ?? null;  //# conditional3_null_equals1: compile-time error
  null ?? (true ? x : 499);  //# conditional3_null_equals2: ok
  return true ? x : 499;   //# conditional3_return: compile-time error
  while (true ? x : 499) {};  //# conditional_while: compile-time error
  do {} while (true ? x : 499);  //# conditional_do_while: compile-time error
  for (var v in true ? x : 499) {}   //# conditional_for_in: compile-time error
}

dynamic testVoidConditionalDynamic() {
  void x;
  return true ? x : x;   //# conditional_return_dynamic: ok
  return true ? 499 : x;   //# conditional2_return_dynamic: ok
  return true ? x : 499;   //# conditional3_return_dynamic: ok
}

class A<T> {
  T x;
  A(this.x);
  void foo() {}
}

class B implements A<void> {
  void x;

  int foo() => 499;

  void forInTest() {
    for (x in <void>[]) {}  //# instance2_for_in2: ok
    for (x in [1, 2]) {}  //# instance2_for_in3: ok
  }
}

class C implements A<void> {
  void get x => null;
  set x(void y) {}

  void foo() {}

  void forInTest() {
    for (x in <void>[]) {}  //# instance3_for_in2: ok
    for (x in [1, 2]) {}  //# instance3_for_in3: ok
  }
}

Object? testInstanceField() {
  A<void> a = new A<void>(null);
  a.x = 499;  //# field_assign: ok
  a.x;  //# instance_stmt: ok
  true ? a.x : a.x;  //# instance_conditional: ok
  for (a.x; false; a.x) {}   //# instance_for: ok
  useAsVoid(a.x); //# instance_argument_void: ok
  use(a.x);   //# instance_argument: compile-time error
  use(a.x as Object?);  //# instance_as: ok
  void y = a.x;   //# instance_void_init: ok
  dynamic z = a.x;  //# instance_dynamic_init: compile-time error
  a.x is Object?;   //# instance_is: compile-time error
  throw a.x;   //# instance_throw: compile-time error
  <void>[a.x];   //# instance_literal_void_list_init: ok
  <Object?>[a.x];   //# instance_literal_list_init: compile-time error
  var m1 = <int, void>{4: a.x};   //# instance_literal_map_value_init: ok
  var m2 = <void, int>{ a.x : 4};   //# instance_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: a.x};  //# instance_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{ a.x : 4};  //# instance_literal_map_key_init2: compile-time error
  null ?? a.x;  //# instance_null_equals1: ok
  a.x ?? 499;  //# instance_null_equals2: compile-time error
  return a.x;   //# instance_return: compile-time error
  while (a.x) {};  //# instance_while: compile-time error
  do {} while (a.x);  //# instance_do_while: compile-time error
  for (var v in a.x) {}   //# instance_for_in: compile-time error
  a.x += 1;  //# instance_plus_eq: compile-time error
  a.x.toString();  //# instance_toString: compile-time error
  a.x?.toString();  //# instance_null_dot: compile-time error
  a.x..toString();  //# instance_cascade: compile-time error

  B b = new B();
  b.x = 42;   //# field_assign2: ok
  b.x;  //# instance2_stmt: ok
  true ? b.x : b.x;  //# instance2_conditional: ok
  for (b.x; false; b.x) {}   //# instance2_for: ok
  useAsVoid(b.x); //# instance2_argument_void: ok
  use(b.x);   //# instance2_argument: compile-time error
  use(b.x as Object?);  //# instance2_as: ok
  void y2 = b.x;   //# instance2_void_init: ok
  dynamic z2 = b.x;  //# instance2_dynamic_init: compile-time error
  b.x is Object?;   //# instance2_is: compile-time error
  throw b.x;   //# instance2_throw: compile-time error
  <void>[b.x];   //# instance2_literal_void_list_init: ok
  <Object?>[b.x];   //# instance2_literal_list_init: compile-time error
  var m12 = <int, void>{4: b.x};   //# instance2_literal_map_value_init: ok
  var m22 = <void, int>{ b.x : 4};   //# instance2_literal_map_key_init: ok
  var m32 = <dynamic, dynamic>{4: b.x};  //# instance2_literal_map_value_init2: compile-time error
  var m42 = <dynamic, dynamic>{ b.x : 4};  //# instance2_literal_map_key_init2: compile-time error
  null ?? b.x;  //# instance2_null_equals1: ok
  b.x ?? 499;  //# instance2_null_equals2: compile-time error
  return b.x;   //# instance2_return: compile-time error
  while (b.x) {};  //# instance2_while: compile-time error
  do {} while (b.x);  //# instance2_do_while: compile-time error
  for (var v in b.x) {}   //# instance2_for_in: compile-time error
  b.forInTest();
  b.x += 1;  //# instance2_plus_eq: compile-time error
  b.x.toString();  //# instance2_toString: compile-time error
  b.x?.toString();  //# instance2_null_dot: compile-time error
  b.x..toString();  //# instance2_cascade: compile-time error

  C c = new C();
  c.x = 32;   //# setter_assign: ok
  c.x;  //# instance3_stmt: ok
  true ? c.x : c.x;  //# instance3_conditional: ok
  for (c.x; false; c.x) {}   //# instance3_for: ok
  useAsVoid(c.x); //# instance3_argument_void: ok
  use(c.x);   //# instance3_argument: compile-time error
  use(c.x as Object?);  //# instance3_as: ok
  void y3 = c.x;   //# instance3_void_init: ok
  dynamic z3 = c.x;  //# instance3_dynamic_init: compile-time error
  c.x is Object?;   //# instance3_is: compile-time error
  throw c.x;   //# instance3_throw: compile-time error
  <void>[c.x];   //# instance3_literal_void_list_init: ok
  <Object?>[c.x];   //# instance3_literal_list_init: compile-time error
  var m13 = <int, void>{4: c.x};   //# instance3_literal_map_value_init: ok
  var m23 = <void, int>{ c.x : 4};   //# instance3_literal_map_key_init: ok
  var m33 = <dynamic, dynamic>{4: c.x};  //# instance3_literal_map_value_init2: compile-time error
  var m43 = <dynamic, dynamic>{ c.x : 4};  //# instance3_literal_map_key_init2: compile-time error
  null ?? c.x;  //# instance3_null_equals1: ok
  c.x ?? 499;  //# instance3_null_equals2: compile-time error
  return c.x;   //# instance3_return: compile-time error
  while (c.x) {};  //# instance3_while: compile-time error
  do {} while (c.x);  //# instance3_do_while: compile-time error
  for (var v in c.x) {}   //# instance3_for_in: compile-time error
  c.forInTest();
  c.x += 1;  //# instance3_plus_eq: compile-time error
  c.x.toString();  //# instance3_toString: compile-time error
  c.x?.toString();  //# instance3_null_dot: compile-time error
  c.x..toString();  //# instance3_cascade: compile-time error
}

dynamic testInstanceFieldDynamic() {
  A<void> a = new A<void>(null);
  return a.x;   //# instance_return_dynamic: ok

  B b = new B();
  return b.x;   //# instance2_return_dynamic: ok

  C c = new C();
  return c.x;   //# instance3_return_dynamic: ok
}

Object? testParenthesized() {
  void x;
  (x);  //# paren_stmt: ok
  true ? (x) : (x);  //# paren_conditional: ok
  for ((x); false; (x)) {}   //# paren_for: ok
  useAsVoid((x)); //# paren_argument_void: ok
  use((x));   //# paren_argument: compile-time error
  use((x) as Object?);  //# paren_as: ok
  void y = (x);   //# paren_void_init: ok
  dynamic z = (x);  //# paren_dynamic_init: compile-time error
  (x) is Object?;   //# paren_is: compile-time error
  throw (x);   //# paren_throw: compile-time error
  <void>[(x)];   //# paren_literal_void_list_init: ok
  <Object?>[(x)];   //# paren_literal_list_init: compile-time error
  var m1 = <int, void>{4: (x) };   //# paren_literal_map_value_init: ok
  var m2 = <void, int>{ (x): 4};   //# paren_literal_map_key_init: ok
  var m3 = <dynamic, dynamic>{4: (x) };  //# paren_literal_map_value_init2: compile-time error
  var m4 = <dynamic, dynamic>{ (x): 4};  //# paren_literal_map_key_init2: compile-time error
  (x) ?? 499;  //# paren_null_equals1: compile-time error
  null ?? (x);  //# paren_null_equals2: ok
  return (x);   //# paren_return: compile-time error
  while ((x)) {};  //# paren_while: compile-time error
  do {} while ((x));  //# paren_do_while: compile-time error
  for (var v in (x)) {}   //# paren_for_in: compile-time error
  (x).toString();  //# paren_toString: compile-time error
  (x)?.toString();  //# paren_null_dot: compile-time error
  (x)..toString();  //# paren_cascade: compile-time error
   if ((x)) {}; //# paren_conditional_stmt: compile-time error
  !(x); //# paren_boolean_negation: compile-time error
  (x) && true; //# paren_boolean_and_left: compile-time error
  true && (x); //# paren_boolean_and_right: compile-time error
  (x) || true; //# paren_boolean_or_left: compile-time error
  true || (x); //# paren_boolean_or_right: compile-time error
  (x) == 3; //# paren_equals_left: compile-time error
  3 == (x); //# paren_equals_right: compile-time error
  identical(3, (x)); //# paren_identical: compile-time error
  3 + (x); //# paren_addition: compile-time error
  3 * (x); //# paren_multiplication: compile-time error
  -(x); //# paren_negation: compile-time error
  (x)(3); //# paren_use_as_function: compile-time error
  "hello${(x)}"; //# paren_use_in_string_interpolation: compile-time error
  (x) ??= 3; //# paren_use_in_conditional_assignment_left: compile-time error
  Object? xx;  xx ??= (x); //# paren_use_in_conditional_assignment_right: compile-time error
  var ll = <int>[3]; ll[(x)]; //# paren_use_in_list_subscript: compile-time error
  var mm = <void, void>{}; mm[(x)]; //# paren_use_in_map_lookup: compile-time error
}

dynamic testParenthesizedDynamic() {
  void x;
  return (x);   //# paren_return_dynamic: ok
}

void testReturnToVoid(void x, void f()) {
  void y;
  final void z = null;
  A<void> a = new A<void>(null);
  B b = new B();
  C c = new C();
  return x;   //# param_return_to_void: ok
  return f();   //# call_return_to_void: ok
  return y;   //# local_return_to_void: ok
  return z;   //# final_local_return_to_void: ok
  return global;   //# global_return_to_void: ok
  return true ? x : x;   //# conditional_return_to_void: ok
  return true ? 499 : x;   //# conditional2_return_to_void: ok
  return true ? x : 499;   //# conditional3_return_to_void: ok
  return a.x;   //# instance_return_to_void: ok
  return b.x;   //# instance2_return_to_void: ok
  return c.x;   //# instance3_return_to_void: ok
  return (x);   //# paren_return_to_void: ok
}

main() {
  try {
    testVoidParam(499);
    testVoidCall(() {});
    testVoidLocal();
    testVoidFinalLocal();
    testVoidConditional();
    testInstanceField();
    testParenthesized();
    testReturnToVoid(499, () {});
  } catch (e) {
    // Silently eat all dynamic errors.
    // This test is only testing static analysis.
  }
}
