// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks on usage of expressions of type void.

void use(dynamic x) { }

void testVoidParam(void x) {
  x;  //# param_stmt: ok
  true ? x : x;  //# param_conditional: compile-time error
  for (x; false; x) {}   //# param_for: ok
  use(x);   //# param_argument: compile-time error
  use(x as Object);  //# param_as: ok
  void y = x;   //# param_void_init: compile-time error
  dynamic z = x;  //# param_dynamic_init: compile-time error
  x is Object;   //# param_is: compile-time error
  throw x;   //# param_throw: compile-time error
  [x];   //# param_literal_list_init: compile-time error
  var m1 = {4: x};   //# param_literal_map_value_init: compile-time error
  var m2 = {x : 4};   //# param_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: x};  //# param_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = {x : 4};  //# param_literal_map_key_init2: compile-time error
  x ?? 499;  //# param_null_equals2: compile-time error
  null ?? x;  //# param_null_equals2: compile-time error
  return x;   //# param_return: compile-time error
  while (x) {};  //# param_while: compile-time error
  do {} while (x);  //# param_do_while: compile-time error
  for (var v in x) {}   //# param_for_in: compile-time error
  for (x in [1, 2]) {}  //# param_for_in2: ok
  x += 1;  //# param_plus_eq: compile-time error
  x.toString();  //# param_toString: compile-time error
  x?.toString();  //# param_null_dot: compile-time error
  x..toString();  //# param_cascade: compile-time error
}

void testVoidCall(void f()) {
  f();  //# call_stmt: ok
  true ? f() : f();  //# call_conditional: compile-time error
  for (f(); false; f()) {}   //# call_for: ok
  use(f());   //# call_argument: compile-time error
  use(f() as Object);  //# call_as: ok
  void y = f();   //# call_void_init: compile-time error
  dynamic z = f();  //# call_dynamic_init: compile-time error
  f() is Object;   //# call_is: compile-time error
  throw f();   //# call_throw: compile-time error
  [f()];   //# call_literal_list_init: compile-time error
  var m1 = {4: f() };   //# call_literal_map_value_init: compile-time error
  var m2 = { f(): 4};   //# call_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: f() };  //# call_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = { f(): 4};  //# call_literal_map_key_init2: compile-time error
  f() ?? 499;  //# call_null_equals2: compile-time error
  null ?? f();  //# call_null_equals2: compile-time error
  return f();   //# call_return: compile-time error
  while (f()) {};  //# call_while: compile-time error
  do {} while (f());  //# call_do_while: compile-time error
  for (var v in f()) {}   //# call_for_in: compile-time error
  f().toString();  //# call_toString: compile-time error
  f()?.toString();  //# call_null_dot: compile-time error
  f()..toString();  //# call_cascade: compile-time error
}

void testVoidLocal() {
  void x;
  x = 42;   //# local_assign: ok
  x;  //# local_stmt: ok
  true ? x : x;  //# local_conditional: compile-time error
  for (x; false; x) {}   //# local_for: ok
  use(x);   //# local_argument: compile-time error
  use(x as Object);  //# local_as: ok
  void y = x;   //# local_void_init: compile-time error
  dynamic z = x;  //# local_dynamic_init: compile-time error
  x is Object;   //# local_is: compile-time error
  throw x;   //# local_throw: compile-time error
  [x];   //# local_literal_list_init: compile-time error
  var m1 = {4: x};   //# local_literal_map_value_init: compile-time error
  var m2 = {x : 4};   //# local_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: x};  //# local_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = {x : 4};  //# local_literal_map_key_init2: compile-time error
  x ?? 499;  //# local_null_equals2: compile-time error
  null ?? x;  //# local_null_equals2: compile-time error
  return x;   //# local_return: compile-time error
  while (x) {};  //# local_while: compile-time error
  do {} while (x);  //# local_do_while: compile-time error
  for (var v in x) {}   //# local_for_in: compile-time error
  for (x in [1, 2]) {}  //# local_for_in2: ok
  x += 1;  //# local_plus_eq: compile-time error
  x.toString();  //# local_toString: compile-time error
  x?.toString();  //# local_null_dot: compile-time error
  x..toString();  //# local_cascade: compile-time error
}

void testVoidFinalLocal() {
  final void x = null;
  x = 42;   //# final_local_assign: compile-time error
  x;  //# final_local_stmt: ok
  true ? x : x;  //# final_local_conditional: compile-time error
  for (x; false; x) {}   //# final_local_for: ok
  use(x);   //# final_local_argument: compile-time error
  use(x as Object);  //# final_local_as: ok
  void y = x;   //# final_local_void_init: compile-time error
  dynamic z = x;  //# final_local_dynamic_init: compile-time error
  x is Object;   //# final_local_is: compile-time error
  throw x;   //# final_local_throw: compile-time error
  [x];   //# final_local_literal_list_init: compile-time error
  var m1 = {4: x};   //# final_local_literal_map_value_init: compile-time error
  var m2 = {x : 4};   //# final_local_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: x};  //# final_local_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = {x : 4};  //# final_local_literal_map_key_init2: compile-time error
  x ?? 499;  //# final_local_null_equals2: compile-time error
  null ?? x;  //# final_local_null_equals2: compile-time error
  return x;   //# final_local_return: compile-time error
  while (x) {};  //# final_local_while: compile-time error
  do {} while (x);  //# final_local_do_while: compile-time error
  for (var v in x) {}   //# final_local_for_in: compile-time error
  for (x in [1, 2]) {}  //# final_local_for_in2: compile-time error
  x += 1;  //# final_local_plus_eq: compile-time error
  x.toString();  //# final_local_toString: compile-time error
  x?.toString();  //# final_local_null_dot: compile-time error
  x..toString();  //# final_local_cascade: compile-time error
}

void global;
void testVoidGlobal() {
  global;  //# global_stmt: ok
  true ? global : global;  //# global_conditional: compile-time error
  for (global; false; global) {}   //# global_for: ok
  use(global);   //# global_argument: compile-time error
  use(global as Object);  //# global_as: ok
  void y = global;   //# global_void_init: compile-time error
  dynamic z = global;  //# global_dynamic_init: compile-time error
  global is Object;   //# global_is: compile-time error
  throw global;   //# global_throw: compile-time error
  [global];   //# global_literal_list_init: compile-time error
  var m1 = {4: global };   //# global_literal_map_value_init: compile-time error
  var m2 = { global: 4};   //# global_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: global };  //# global_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = { global: 4};  //# global_literal_map_key_init2: compile-time error
  null ?? global;  //# global_null_equals2: compile-time error
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
}

void testVoidConditional() {
  void x;
  (true ? x : x);   //# conditional_parens: compile-time error
  true ? x : x;  //# conditional_stmt: compile-time error
  true ? true ? x : x : true ? x : x;  //# conditional_conditional: compile-time error
  for (true ? x : x; false; true ? x : x) {}   //# conditional_for: compile-time error
  use(true ? x : x);   //# conditional_argument: compile-time error
  void y = true ? x : x;   //# conditional_void_init: compile-time error
  dynamic z = true ? x : x;  //# conditional_dynamic_init: compile-time error
  throw true ? x : x;   //# conditional_throw: compile-time error
  [true ? x : x];   //# conditional_literal_list_init: compile-time error
  var m1 = {4: true ? x : x};   //# conditional_literal_map_value_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: true ? x : x};  //# conditional_literal_map_value_init2: compile-time error
  null ?? true ? x : x;  //# conditional_null_equals2: compile-time error
  return true ? x : x;   //# conditional_return: compile-time error
  while (true ? x : x) {};  //# conditional_while: compile-time error
  do {} while (true ? x : x);  //# conditional_do_while: compile-time error
  for (var v in true ? x : x) {}   //# conditional_for_in: compile-time error

  (true ? 499 : x);   //# conditional2_parens: compile-time error
  true ? 499 : x;  //# conditional2_stmt: compile-time error
  true ? true ? 499 : x : true ? 499 : x;  //# conditional2_conditional: compile-time error
  for (true ? 499 : x; false; true ? 499 : x) {}   //# conditional2_for: compile-time error
  use(true ? 499 : x);   //# conditional2_argument: compile-time error
  void y2 = true ? 499 : x;   //# conditional2_void_init: compile-time error
  dynamic z2 = true ? 499 : x;  //# conditional2_dynamic_init: compile-time error
  throw true ? 499 : x;   //# conditional2_throw: compile-time error
  [true ? 499 : x];   //# conditional2_literal_list_init: compile-time error
  var m12 = {4: true ? 499 : x};   //# conditional2_literal_map_value_init: compile-time error
  Map<dynamic, dynamic> m32 = {4: true ? 499 : x};  //# conditional2_literal_map_value_init2: compile-time error
  null ?? true ? 499 : x;  //# conditional2_null_equals2: compile-time error
  return true ? 499 : x;   //# conditional2_return: compile-time error
  while (true ? 499 : x) {};  //# conditional2while: compile-time error
  do {} while (true ? 499 : x);  //# conditional2do_while: compile-time error
  for (var v in true ? 499 : x) {}   //# conditional2for_in: compile-time error

  (true ? x : 499);   //# conditional3_parens: compile-time error
  true ? x : 499;  //# conditional3_stmt: compile-time error
  true ? true ? x : 499 : true ? x : 499;  //# conditional3_conditional: compile-time error
  for (true ? x : 499; false; true ? x : 499) {}   //# conditional3_for: compile-time error
  use(true ? x : 499);   //# conditional3_argument: compile-time error
  void y3 = true ? x : 499;   //# conditional3_void_init: compile-time error
  dynamic z3 = true ? x : 499;  //# conditional3_dynamic_init: compile-time error
  throw true ? x : 499;   //# conditional3_throw: compile-time error
  [true ? x : 499];   //# conditional3_literal_list_init: compile-time error
  var m13 = {4: true ? x : 499 };   //# conditional3_literal_map_value_init: compile-time error
  Map<dynamic, dynamic> m33 = {4: true ? x : 499 };  //# conditional3_literal_map_value_init2: compile-time error
  null ?? true ? x : 499;  //# conditional3_null_equals2: compile-time error
  return true ? x : 499;   //# conditional3_return: compile-time error
  while (true ? x : 499) {};  //# conditional_while: compile-time error
  do {} while (true ? x : 499);  //# conditional_do_while: compile-time error
  for (var v in true ? x : 499) {}   //# conditional_for_in: compile-time error
}


class A<T> {
  T x;

  void foo() {}
}

class B implements A<void> {
  void x;

  int foo() => 499;

  void forInTest() {
    for (x in <void>[]) {}  //# instance2_for_in2: compile-time error
    for (x in [1, 2]) {}  //# instance2_for_in3: ok
  }
}

class C implements A<void> {
  void get x => null;
  set x(void y) {}

  void forInTest() {
    for (x in <void>[]) {}  //# instance3_for_in2: compile-time error
    for (x in [1, 2]) {}  //# instance3_for_in3: ok
  }
}


void testInstanceField() {
  A<void> a = new A<void>();
  a.x = 499;  //# field_assign: ok
  a.x;  //# instance_stmt: ok
  true ? a.x : a.x;  //# instance_conditional: compile-time error
  for (a.x; false; a.x) {}   //# instance_for: ok
  use(a.x);   //# instance_argument: compile-time error
  use(a.x as Object);  //# instance_as: ok
  void y = a.x;   //# instance_void_init: compile-time error
  dynamic z = a.x;  //# instance_dynamic_init: compile-time error
  a.x is Object;   //# instance_is: compile-time error
  throw a.x;   //# instance_throw: compile-time error
  [a.x];   //# instance_literal_list_init: compile-time error
  var m1 = {4: a.x};   //# instance_literal_map_value_init: compile-time error
  var m2 = { a.x : 4};   //# instance_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: a.x};  //# instance_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = { a.x : 4};  //# instance_literal_map_key_init2: compile-time error
  null ?? a.x;  //# instance_null_equals2: compile-time error
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
  true ? b.x : b.x;  //# instance2_conditional: compile-time error
  for (b.x; false; b.x) {}   //# instance2_for: ok
  use(b.x);   //# instance2_argument: compile-time error
  use(b.x as Object);  //# instance2_as: ok
  void y2 = b.x;   //# instance2_void_init: compile-time error
  dynamic z2 = b.x;  //# instance2_dynamic_init: compile-time error
  b.x is Object;   //# instance2_is: compile-time error
  throw b.x;   //# instance2_throw: compile-time error
  [b.x];   //# instance2_literal_list_init: compile-time error
  var m12 = {4: b.x};   //# instance2_literal_map_value_init: compile-time error
  var m22 = { b.x : 4};   //# instance2_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m32 = {4: b.x};  //# instance2_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m42 = { b.x : 4};  //# instance2_literal_map_key_init2: compile-time error
  null ?? b.x;  //# instance2_null_equals2: compile-time error
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
  true ? c.x : c.x;  //# instance3_conditional: compile-time error
  for (c.x; false; c.x) {}   //# instance3_for: ok
  use(c.x);   //# instance3_argument: compile-time error
  use(c.x as Object);  //# instance3_as: ok
  void y3 = c.x;   //# instance3_void_init: compile-time error
  dynamic z3 = c.x;  //# instance3_dynamic_init: compile-time error
  c.x is Object;   //# instance3_is: compile-time error
  throw c.x;   //# instance3_throw: compile-time error
  [c.x];   //# instance3_literal_list_init: compile-time error
  var m13 = {4: c.x};   //# instance3_literal_map_value_init: compile-time error
  var m23 = { c.x : 4};   //# instance3_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m33 = {4: c.x};  //# instance3_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m43 = { c.x : 4};  //# instance3_literal_map_key_init2: compile-time error
  null ?? c.x;  //# instance3_null_equals2: compile-time error
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

void testParenthesized() {
  void x;
  (x);  //# paren_stmt: ok
  true ? (x) : (x);  //# paren_conditional: compile-time error
  for ((x); false; (x)) {}   //# paren_for: ok
  use((x));   //# paren_argument: compile-time error
  use((x) as Object);  //# paren_as: ok
  void y = (x);   //# paren_void_init: compile-time error
  dynamic z = (x);  //# paren_dynamic_init: compile-time error
  (x) is Object;   //# paren_is: compile-time error
  throw (x);   //# paren_throw: compile-time error
  [(x)];   //# paren_literal_list_init: compile-time error
  var m1 = {4: (x) };   //# paren_literal_map_value_init: compile-time error
  var m2 = { (x): 4};   //# paren_literal_map_key_init: compile-time error
  Map<dynamic, dynamic> m3 = {4: (x) };  //# paren_literal_map_value_init2: compile-time error
  Map<dynamic, dynamic> m4 = { (x): 4};  //# paren_literal_map_key_init2: compile-time error
  (x) ?? 499;  //# paren_null_equals2: compile-time error
  null ?? (x);  //# paren_null_equals2: compile-time error
  return (x);   //# paren_return: compile-time error
  while ((x)) {};  //# paren_while: compile-time error
  do {} while ((x));  //# paren_do_while: compile-time error
  for (var v in (x)) {}   //# paren_for_in: compile-time error
  (x).toString();  //# paren_toString: compile-time error
  (x)?.toString();  //# paren_null_dot: compile-time error
  (x)..toString();  //# paren_cascade: compile-time error
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
  } catch (e) {
    // Silently eat all dynamic errors.
    // This test is only testing static warnings.
  }
}