// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks on usage of expressions of type void.

void use(dynamic x) {}
void useAsVoid(void x) {}

Object? testVoidParam(void x) {
  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  x; // param_stmt: ok

  true ? x : x; // param_conditional: ok

  for (x; false; x) {} // param_for: ok

  useAsVoid(x); // param_argument_void: ok

  use(x); // param_argument
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  use(x as Object?); // param_as: ok

  void y = x; // param_void_init: ok

  dynamic z = x; // param_dynamic_init
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x is Object?; // param_is
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  throw x; // param_throw
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.

  <void>[x]; // param_literal_void_list_init: ok

  <Object?>[x]; // param_literal_list_init
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: x}; // param_literal_map_value_init: ok

  var m2 = <void, int>{x: 4}; // param_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: x}; // param_literal_map_value_init2
  //                             ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{x: 4}; // param_literal_map_key_init2
  //                          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ?? 499; // param_null_equals1
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  null ?? x; // param_null_equals2: ok

  return x; // param_return
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while (x) {} // param_while
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (x); // param_do_while
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in x) {} // param_for_in
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (x in [1, 2]) {} // param_for_in2: ok

  x += 1; // param_plus_eq
//^
// [cfe] This expression has type 'void' and can't be used.
  //^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  x.toString(); // param_toString
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x?.toString(); // param_null_dot
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x..toString(); // param_cascade
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  if (x) {} // param_conditional_stmt
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  !x; // param_boolean_negation
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x && true; // param_boolean_and_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true && x; // param_boolean_and_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x || true; // param_boolean_or_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true || x; // param_boolean_or_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x == 3; // param_equals_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  3 == x; // param_equals_right
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, x); // param_identical
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 + x; // param_addition
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 * x; // param_multiplication
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  -x; // param_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x(3); // param_use_as_function
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.
// ^
// [cfe] The method 'call' isn't defined for the class 'void'.

  "hello$x"; // param_use_in_string_interpolation
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ??= 3; // param_use_in_conditional_assignment_left
//^
// [cfe] This expression has type 'void' and can't be used.
  //^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT

  Object? xx;
  xx ??= x; // param_use_in_conditional_assignment_right
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[x]; // param_use_in_list_subscript
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[x]; // param_use_in_map_lookup
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

testVoidAsync(void x) async {
  await x; // async_use_in_await
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

testVoidAsyncStar(void x) async* {
  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  yield x; // async_use_in_yield
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  yield* x; // async_use_in_yield_star
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
  // [cfe] This expression has type 'void' and can't be used.

  await for (var i in x) {} // async_use_in_await_for
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

testVoidSyncStar(void x) sync* {
  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  yield x; // sync_use_in_yield
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  yield* x; // sync_use_in_yield_star
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
  // [cfe] This expression has type 'void' and can't be used.
}

const void c = null;

dynamic testVoidDefaultParameter(
    [int y = c]) {} // void_default_parameter_global
//           ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

dynamic testVoidDefaultParameterClosure() {
  ([int y = c]) => 3; // void_default_parameter_closure
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidParamDynamic(void x) {
  return x; // param_return_dynamic: ok
}

Object? testVoidCall(void f()) {
  var _ = () {
    f = () {}; // Prevent promotion of `f`.
  };

  f(); // call_stmt: ok

  true ? f() : f(); // call_conditional: ok

  for (f(); false; f()) {} // call_for: ok

  useAsVoid(f()); // call_argument_void: ok

  use(f()); // call_argument
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  use(f() as Object?); // call_as: ok

  void y = f(); // call_void_init: ok

  dynamic z = f(); // call_dynamic_init
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //           ^
  // [cfe] This expression has type 'void' and can't be used.

  f() is Object?; // call_is
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  throw f(); // call_throw
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //     ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[f()]; // call_literal_void_list_init: ok

  <Object?>[f()]; // call_literal_list_init
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //         ^
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: f()}; // call_literal_map_value_init: ok

  var m2 = <void, int>{f(): 4}; // call_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: f()}; // call_literal_map_value_init2
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                              ^
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{f(): 4}; // call_literal_map_key_init2
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                           ^
  // [cfe] This expression has type 'void' and can't be used.

  f() ?? 499; // call_null_equals1
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  null ?? f(); // call_null_equals2: ok

  return f(); // call_return
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //      ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while (f()) {} // call_while
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (f()); // call_do_while
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in f()) {} // call_for_in
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  f().toString(); // call_toString
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  f()?.toString(); // call_null_dot
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  f()..toString(); // call_cascade
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  if (f()) {} // call_conditional_stmt
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  !f(); // call_boolean_negation
// ^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  f() && true; // call_boolean_and_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  true && f(); // call_boolean_and_right
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  f() || true; // call_boolean_or_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  true || f(); // call_boolean_or_right
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  f() == 3; // call_equals_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  3 == f(); // call_equals_right
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, f()); // call_identical
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  3 + f(); // call_addition
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  3 * f(); // call_multiplication
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  -f(); // call_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  f()(3); // call_use_as_function
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.
  // ^
  // [cfe] The method 'call' isn't defined for the class 'void'.

  "hello${f()}"; // call_use_in_string_interpolation
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  // Skip this one, it is a syntax error.
  // f() ??= 3; // call_use_in_conditional_assignment_left

  Object? xx;
  xx ??= f(); // call_use_in_conditional_assignment_right
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[f()]; // call_use_in_list_subscript
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //  ^
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[f()]; // call_use_in_map_lookup
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //  ^
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidCallDynamic(void f()) {
  return f(); // call_return_dynamic: ok
}

Object? testVoidLocal() {
  void x;

  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  x = 42; // local_assign: ok

  x; // local_stmt: ok

  true ? x : x; // local_conditional: ok

  for (x; false; x) {} // local_for: ok

  useAsVoid(x); // local_argument_void: ok

  use(x); // local_argument
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  use(x as Object?); // local_as: ok

  void y = x; // local_void_init: ok

  dynamic z = x; // local_dynamic_init
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x is Object?; // local_is
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  throw x; // local_throw
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.

  <void>[x]; // local_literal_void_list_init: ok

  <Object?>[x]; // local_literal_list_init
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: x}; // local_literal_map_value_init: ok

  var m2 = <void, int>{x: 4}; // local_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: x}; // local_literal_map_value_init2
  //                             ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{x: 4}; // local_literal_map_key_init2
  //                          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ?? 499; // local_null_equals1
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  null ?? x; // local_null_equals2: ok

  return x; // local_return
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while (x) {} // local_while
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (x); // local_do_while
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in x) {} // local_for_in
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (x in [1, 2]) {} // local_for_in2: ok

  x += 1; // local_plus_eq
//^
// [cfe] This expression has type 'void' and can't be used.
  //^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  x.toString(); // local_toString
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x?.toString(); // local_null_dot
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x..toString(); // local_cascade
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  if (x) {} // local_conditional_stmt
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  !x; // local_boolean_negation
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x && true; // local_boolean_and_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true && x; // local_boolean_and_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x || true; // local_boolean_or_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true || x; // local_boolean_or_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x == 3; // local_equals_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  3 == x; // local_equals_right
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, x); // local_identical
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 + x; // local_addition
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 * x; // local_multiplication
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  -x; // local_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x(3); // local_use_as_function
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.
// ^
// [cfe] The method 'call' isn't defined for the class 'void'.

  "hello$x"; // local_use_in_string_interpolation
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ??= 3; // local_use_in_conditional_assignment_left
  //^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//^
// [cfe] This expression has type 'void' and can't be used.

  Object? xx;
  xx ??= x; // local_use_in_conditional_assignment_right
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[x]; // local_use_in_list_subscript
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[x]; // local_use_in_map_lookup
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidLocalDynamic() {
  void x;
  return x; // local_return_dynamic: ok
}

Object? testVoidFinalLocal() {
  late final void x;

  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  // Skip, shouldn't be definitely assigned below.
  // x = 42; // final_local_assign

  x; // final_local_stmt: ok

  true ? x : x; // final_local_conditional: ok

  for (x; false; x) {} // final_local_for: ok

  useAsVoid(x); // final_local_argument_void: ok

  use(x); // final_local_argument
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  use(x as Object?); // final_local_as: ok

  void y = x; // final_local_void_init: ok

  dynamic z = x; // final_local_dynamic_init
  //          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x is Object?; // final_local_is
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  throw x; // final_local_throw
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [cfe] This expression has type 'void' and can't be used.
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.

  <void>[x]; // final_local_literal_void_list_init: ok

  <Object?>[x]; // final_local_literal_list_init
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: x}; // final_local_literal_map_value_init: ok

  var m2 = <void, int>{x: 4}; // final_local_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: x}; // final_local_literal_map_value_init2
  //                             ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{x: 4}; // final_local_literal_map_key_init2
  //                          ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ?? 499; // final_local_null_equals1
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  null ?? x; // final_local_null_equals2: ok

  return x; // final_local_return
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while (x) {} // final_local_while
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (x); // final_local_do_while
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in x) {} // final_local_for_in
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  // Skip, cannot assign a final anyway.
  // for (x in [1, 2]) {} // final_local_for_in2

  // Skip, cannot assign a final anyway.
  // x += 1; // final_local_plus_eq

  x.toString(); // final_local_toString
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x?.toString(); // final_local_null_dot
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x..toString(); // final_local_cascade
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  if (x) {} // final_local_conditional_stmt
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  !x; // final_local_boolean_negation
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x && true; // final_local_boolean_and_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true && x; // final_local_boolean_and_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x || true; // final_local_boolean_or_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true || x; // final_local_boolean_or_right
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x == 3; // final_local_equals_left
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  3 == x; // final_local_equals_right
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, x); // final_local_identical
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 + x; // final_local_addition
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 * x; // final_local_multiplication
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  -x; // final_local_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  x(3); // final_local_use_as_function
//^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.
// ^
// [cfe] The method 'call' isn't defined for the class 'void'.

  "hello$x"; // final_local_use_in_string_interpolation
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  x ??= 3; // final_local_use_in_conditional_assignment_left
//^
// [cfe] This expression has type 'void' and can't be used.
//  ^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT

  Object? xx;
  xx ??= x; // final_local_use_in_conditional_assignment_right
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[x]; // final_local_use_in_list_subscript
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[x]; // final_local_use_in_map_lookup
  // ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidFinalLocalDynamic() {
  final void x = null;
  return x; // final_local_return_dynamic: ok
}

void global;

Object? testVoidGlobal() {
  global; // global_stmt: ok

  true ? global : global; // global_conditional: ok

  for (global; false; global) {} // global_for: ok

  useAsVoid(global); // global_argument_void: ok

  use(global); // global_argument
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  use(global as Object?); // global_as: ok

  void y = global; // global_void_init: ok

  dynamic z = global; // global_dynamic_init
  //          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  global is Object?; // global_is
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  throw global; // global_throw
  //    ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[global]; // global_literal_void_list_init: ok

  <Object?>[global]; // global_literal_list_init
  //        ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: global}; // global_literal_map_value_init: ok

  var m2 = <void, int>{global: 4}; // global_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: global}; // global_literal_map_value_init2
  //                             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{global: 4}; // global_literal_map_key_init2
  //                          ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  global ?? 499; // global_null_equals1
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  null ?? global; // global_null_equals2: ok

  return global; // global_return
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while (global) {} // global_while
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (global); // global_do_while
  //           ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in global) {} // global_for_in
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  for (global in [1, 2]) {} // global_for_in2: ok

  global += 1; // global_plus_eq
//^
// [cfe] This expression has type 'void' and can't be used.
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  global.toString(); // global_toString
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  global?.toString(); // global_null_dot
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  global..toString(); // global_cascade
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  if (global) {} // global_conditional_stmt
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  !global; // global_boolean_negation
// ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  global && true; // global_boolean_and_left
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true && global; // global_boolean_and_right
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  global || true; // global_boolean_or_left
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  true || global; // global_boolean_or_right
  //      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  global == 3; // global_equals_left
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  3 == global; // global_equals_right
  //   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, global); // global_identical
  //           ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 + global; // global_addition
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  3 * global; // global_multiplication
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  -global; // global_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.

  global(3); // global_use_as_function
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// [cfe] This expression has type 'void' and can't be used.
  //    ^
  // [cfe] The method 'call' isn't defined for the class 'void'.

  "hello$global"; // global_use_in_string_interpolation
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  global ??= 3; // global_use_in_conditional_assignment_left
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//^
// [cfe] This expression has type 'void' and can't be used.

  Object? xx;
  xx ??= global; // global_use_in_conditional_assignment_right
  //     ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[global]; // global_use_in_list_subscript
  // ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[global]; // global_use_in_map_lookup
  // ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidGlobalDynamic() {
  return global; // global_return_dynamic: ok
}

Object? testVoidConditional() {
  void x;

  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  (true ? x : x); // conditional_parens: ok

  true ? x : x; // conditional_stmt: ok

  true
      ? true
          ? x
          : x
      : true
          ? x
          : x; // conditional_conditional: ok

  for (true ? x : x; false; true ? x : x) {} // conditional_for: ok

  useAsVoid(true ? x : x); // conditional_argument_void: ok

  use(true ? x : x); // conditional_argument
  //  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  void y = true ? x : x; // conditional_void_init: ok

  dynamic z = true ? x : x; // conditional_dynamic_init
  //          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //               ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : x) is Object?; // conditional_is
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  throw true ? x : x; // conditional_throw
  //    ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //         ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[true ? x : x]; // conditional_literal_void_list_init: ok

  <Object?>[true ? x : x]; // conditional_literal_list_init
  //        ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: true ? x : x}; // conditional_literal_map_value_init

  // conditional_literal_map_value_init2
  var m3 = <dynamic, dynamic>{4: true ? x : x};
  //                             ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                                  ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : x) ?? null; // conditional_null_equals1
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? (true ? x : x); // conditional_null_equals2: ok

  return true ? x : x; // conditional_return
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //          ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (true ? x : x) {} // conditional_while
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (true ? x : x); // conditional_do_while
  //           ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in true ? x : x) {} // conditional_for_in
  //            ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                 ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : x).toString(); // conditional_toString
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? x : x)?.toString(); // conditional_null_dot
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? x : x)..toString(); // conditional_cascade
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x); // conditional2_parens: ok

  true ? 499 : x; // conditional2_stmt: ok

  true
      ? true
          ? 499
          : x
      : true
          ? 499
          : x; // conditional2_conditional: ok

  for (true ? 499 : x; false; true ? 499 : x) {} // conditional2_for: ok

  useAsVoid(true ? 499 : x); // conditional2_argument_void: ok

  use(true ? 499 : x); // conditional2_argument
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  void y2 = true ? 499 : x; // conditional2_void_init: ok

  dynamic z2 = true ? 499 : x; // conditional2_dynamic_init
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x) is Object?; // conditional2_is
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  throw true ? 499 : x; // conditional2_throw
  //    ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //         ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[true ? 499 : x]; // conditional2_literal_void_list_init: ok

  <Object?>[true ? 499 : x]; // conditional2_literal_list_init
  //        ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  var m12 = <int, void>{
    4: true ? 499 : x
  }; // conditional2_literal_map_value_init: ok

  // conditional2_literal_map_value_init2
  var m32 = <dynamic, dynamic>{4: true ? 499 : x};
  //                              ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                                   ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x) ?? null; // conditional2_null_equals1
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? (true ? 499 : x); // conditional2_null_equals2: ok

  return true ? 499 : x; // conditional2_return
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //          ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (true ? 499 : x) {} // conditional2_while
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (true ? 499 : x); // conditional2_do_while
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in true ? 499 : x) {} // conditional2_for_in
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                 ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x).toString(); // conditional2_toString
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x)?.toString(); // conditional2_null_dot
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? 499 : x)..toString(); // conditional2_cascade
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499); // conditional3_parens: ok

  true ? x : 499; // conditional3_stmt: ok

  true
      ? true
          ? x
          : 499
      : true
          ? x
          : 499; // conditional3_conditional: ok

  for (true ? x : 499; false; true ? x : 499) {} // conditional3_for: ok

  useAsVoid(true ? x : 499); // conditional3_argument_void: ok

  use(true ? x : 499); // conditional3_argument
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  void y3 = true ? x : 499; // conditional3_void_init: ok

  dynamic z3 = true ? x : 499; // conditional3_dynamic_init
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499) is Object?; // conditional3_is
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  throw true ? x : 499; // conditional3_throw
  //    ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //         ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[true ? x : 499]; // conditional3_literal_void_list_init: ok

  <Object?>[true ? x : 499]; // conditional3_literal_list_init
  //        ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  var m13 = <int, void>{
    4: true ? x : 499
  }; // conditional3_literal_map_value_init: ok

  // conditional3_literal_map_value_init2
  var m33 = <dynamic, dynamic>{4: true ? x : 499};
  //                              ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                                   ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499) ?? null; // conditional3_null_equals1
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? (true ? x : 499); // conditional3_null_equals2: ok

  return true ? x : 499; // conditional3_return
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //          ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (true ? x : 499) {} // conditional3_while
  //     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (true ? x : 499); // conditional3_do_while
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in true ? x : 499) {} // conditional3_for_in
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                 ^
  // [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499).toString(); // conditional3_toString
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499)?.toString(); // conditional3_null_dot
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.

  (true ? x : 499)..toString(); // conditional3_cascade
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//      ^
// [cfe] This expression has type 'void' and can't be used.
}

dynamic testVoidConditionalDynamic() {
  void x;

  return true ? x : x; // conditional_return_dynamic: ok

  return true ? 499 : x; // conditional2_return_dynamic: ok

  return true ? x : 499; // conditional3_return_dynamic: ok
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
    for (x in <void>[]) {} // instance2_for_in_void: ok

    for (x in [1, 2]) {} // instance2_for_in2: ok
  }
}

class C implements A<void> {
  void get x => null;
  set x(void y) {}

  void foo() {}

  void forInTest() {
    for (x in <void>[]) {} // instance3_for_in_void: ok

    for (x in [1, 2]) {} // instance3_for_in2: ok
  }
}

Object? testInstanceField() {
  A<void> a = new A<void>(null);

  a.x = 499; // field_assign: ok

  a.x; // instance_stmt: ok

  true ? a.x : a.x; // instance_conditional: ok

  for (a.x; false; a.x) {} // instance_for: ok

  useAsVoid(a.x); // instance_argument_void: ok

  use(a.x); // instance_argument
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  use(a.x as Object?); // instance_as: ok

  void y = a.x; // instance_void_init: ok

  dynamic z = a.x; // instance_dynamic_init
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  a.x is Object?; // instance_is
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  throw a.x; // instance_throw
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[a.x]; // instance_literal_void_list_init: ok

  <Object?>[a.x]; // instance_literal_list_init
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: a.x}; // instance_literal_map_value_init: ok

  var m2 = <void, int>{a.x: 4}; // instance_literal_map_key_init: ok

  // instance_literal_map_value_init2
  var m3 = <dynamic, dynamic>{4: a.x};
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                               ^
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{a.x: 4}; // instance_literal_map_key_init2
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                            ^
  // [cfe] This expression has type 'void' and can't be used.

  a.x ?? 499; // instance_null_equals1
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? a.x; // instance_null_equals2: ok

  return a.x; // instance_return
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //       ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (a.x) {} // instance_while
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (a.x); // instance_do_while
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in a.x) {} // instance_for_in
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //              ^
  // [cfe] This expression has type 'void' and can't be used.

  a.x += 1; // instance_plus_eq
  //^
  // [cfe] This expression has type 'void' and can't be used.
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  a.x.toString(); // instance_toString
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  a.x?.toString(); // instance_null_dot
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  a.x..toString(); // instance_cascade
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  B b = new B();

  b.x = 42; // field_assign2: ok

  b.x; // instance2_stmt: ok

  true ? b.x : b.x; // instance2_conditional: ok

  for (b.x; false; b.x) {} // instance2_for: ok

  useAsVoid(b.x); // instance2_argument_void: ok

  use(b.x); // instance2_argument
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  use(b.x as Object?); // instance2_as: ok

  void y2 = b.x; // instance2_void_init: ok

  dynamic z2 = b.x; // instance2_dynamic_init
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  b.x is Object?; // instance2_is
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  throw b.x; // instance2_throw
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[b.x]; // instance2_literal_void_list_init: ok

  <Object?>[b.x]; // instance2_literal_list_init
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  var m12 = <int, void>{4: b.x}; // instance2_literal_map_value_init: ok

  var m22 = <void, int>{b.x: 4}; // instance2_literal_map_key_init: ok

  var m32 = <dynamic, dynamic>{4: b.x}; // instance2_literal_map_value_init2
  //                              ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                                ^
  // [cfe] This expression has type 'void' and can't be used.

  var m42 = <dynamic, dynamic>{b.x: 4}; // instance2_literal_map_key_init2
  //                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                             ^
  // [cfe] This expression has type 'void' and can't be used.

  b.x ?? 499; // instance2_null_equals1
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? b.x; // instance2_null_equals2: ok

  return b.x; // instance2_return
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //       ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (b.x) {} // instance2_while
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (b.x); // instance2_do_while
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in b.x) {} // instance2_for_in
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //              ^
  // [cfe] This expression has type 'void' and can't be used.

  b.forInTest();

  b.x += 1; // instance2_plus_eq
  //^
  // [cfe] This expression has type 'void' and can't be used.
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  b.x.toString(); // instance2_toString
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  b.x?.toString(); // instance2_null_dot
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  b.x..toString(); // instance2_cascade
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  C c = new C();

  c.x = 32; // setter_assign: ok

  c.x; // instance3_stmt: ok

  true ? c.x : c.x; // instance3_conditional: ok

  for (c.x; false; c.x) {} // instance3_for: ok

  useAsVoid(c.x); // instance3_argument_void: ok

  use(c.x); // instance3_argument
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  use(c.x as Object?); // instance3_as: ok

  void y3 = c.x; // instance3_void_init: ok

  dynamic z3 = c.x; // instance3_dynamic_init
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  c.x is Object?; // instance3_is
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  throw c.x; // instance3_throw
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.
  // [cfe] This expression has type 'void' and can't be used.

  <void>[c.x]; // instance3_literal_void_list_init: ok

  <Object?>[c.x]; // instance3_literal_list_init
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //          ^
  // [cfe] This expression has type 'void' and can't be used.

  var m13 = <int, void>{4: c.x}; // instance3_literal_map_value_init: ok

  var m23 = <void, int>{c.x: 4}; // instance3_literal_map_key_init: ok

  var m33 = <dynamic, dynamic>{4: c.x}; // instance3_literal_map_value_init2
  //                              ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                                ^
  // [cfe] This expression has type 'void' and can't be used.

  var m43 = <dynamic, dynamic>{c.x: 4}; // instance3_literal_map_key_init2
  //                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                             ^
  // [cfe] This expression has type 'void' and can't be used.

  c.x ?? 499; // instance3_null_equals1
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  null ?? c.x; // instance3_null_equals2: ok

  return c.x; // instance3_return
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //       ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  while (c.x) {} // instance3_while
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while (c.x); // instance3_do_while
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in c.x) {} // instance3_for_in
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //              ^
  // [cfe] This expression has type 'void' and can't be used.

  c.forInTest();

  c.x += 1; // instance3_plus_eq
  //^
  // [cfe] This expression has type 'void' and can't be used.
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] The operator '+' isn't defined for the class 'void'.

  c.x.toString(); // instance3_toString
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  c.x?.toString(); // instance3_null_dot
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  c.x..toString(); // instance3_cascade
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testInstanceFieldDynamic() {
  A<void> a = new A<void>(null);
  return a.x; // instance_return_dynamic: ok

  B b = new B();
  return b.x; // instance2_return_dynamic: ok

  C c = new C();
  return c.x; // instance3_return_dynamic: ok
}

Object? testParenthesized() {
  void x;

  var _ = () {
    x = 15; // Prevent promotion of `x`.
  };

  (x); // paren_stmt: ok

  true ? (x) : (x); // paren_conditional: ok

  for ((x); false; (x)) {} // paren_for: ok

  useAsVoid((x)); // paren_argument_void: ok

  use((x)); // paren_argument
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  use((x) as Object?); // paren_as: ok

  void y = (x); // paren_void_init: ok

  dynamic z = (x); // paren_dynamic_init
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //           ^
  // [cfe] This expression has type 'void' and can't be used.

  (x) is Object?; // paren_is
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  throw (x); // paren_throw
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.THROW_OF_INVALID_TYPE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //     ^
  // [cfe] This expression has type 'void' and can't be used.
  // [cfe] Can't throw a value of 'void' since it is neither dynamic nor non-nullable.

  <void>[(x)]; // paren_literal_void_list_init: ok

  <Object?>[(x)]; // paren_literal_list_init
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //         ^
  // [cfe] This expression has type 'void' and can't be used.

  var m1 = <int, void>{4: (x)}; // paren_literal_map_value_init: ok

  var m2 = <void, int>{(x): 4}; // paren_literal_map_key_init: ok

  var m3 = <dynamic, dynamic>{4: (x)}; // paren_literal_map_value_init2
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                              ^
  // [cfe] This expression has type 'void' and can't be used.

  var m4 = <dynamic, dynamic>{(x): 4}; // paren_literal_map_key_init2
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                           ^
  // [cfe] This expression has type 'void' and can't be used.

  (x) ?? 499; // paren_null_equals1
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  null ?? (x); // paren_null_equals2: ok

  return (x); // paren_return
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //      ^
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Object?'.

  // Not reported, OK: [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // Not reported, OK: [cfe] This expression has type 'void' and can't be used.

  while ((x)) {} // paren_while
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] This expression has type 'void' and can't be used.

  do {} while ((x)); // paren_do_while
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  for (var v in (x)) {} // paren_for_in
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //             ^
  // [cfe] This expression has type 'void' and can't be used.

  (x).toString(); // paren_toString
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  (x)?.toString(); // paren_null_dot
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  (x)..toString(); // paren_cascade
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  if ((x)) {} // paren_conditional_stmt
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  !(x); // paren_boolean_negation
// ^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //^
  // [cfe] This expression has type 'void' and can't be used.

  (x) && true; // paren_boolean_and_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  true && (x); // paren_boolean_and_right
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  (x) || true; // paren_boolean_or_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  true || (x); // paren_boolean_or_right
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  (x) == 3; // paren_equals_left
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.

  3 == (x); // paren_equals_right
  //   ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  identical(3, (x)); // paren_identical
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  3 + (x); // paren_addition
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  3 * (x); // paren_multiplication
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //   ^
  // [cfe] This expression has type 'void' and can't be used.

  -(x); // paren_negation
//^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The operator 'unary-' isn't defined for the class 'void'.
// ^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
//  ^
// [cfe] This expression has type 'void' and can't be used.

  (x)(3); // paren_use_as_function
//^^^
// [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
// ^
// [cfe] This expression has type 'void' and can't be used.
  // ^
  // [cfe] The method 'call' isn't defined for the class 'void'.

  "hello${(x)}"; // paren_use_in_string_interpolation
  //      ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //       ^
  // [cfe] This expression has type 'void' and can't be used.

  // Skip this one, it is a syntax error.
  // (x) ??= 3; // paren_use_in_conditional_assignment_left

  Object? xx;
  xx ??= (x); // paren_use_in_conditional_assignment_right
  //     ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //      ^
  // [cfe] This expression has type 'void' and can't be used.

  var ll = <int>[3];
  ll[(x)]; // paren_use_in_list_subscript
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //  ^
  // [cfe] This expression has type 'void' and can't be used.

  var mm = <void, void>{};
  mm[(x)]; // paren_use_in_map_lookup
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //  ^
  // [cfe] This expression has type 'void' and can't be used.
}

dynamic testParenthesizedDynamic() {
  void x;
  return (x); // paren_return_dynamic: ok
}

var condition = false;

void testReturnToVoid(void x, void f()) {
  void y;
  final void z = null;
  A<void> a = new A<void>(null);
  B b = new B();
  C c = new C();

  if (condition) return x; // param_return_to_void: ok

  if (condition) return f(); // call_return_to_void: ok

  if (condition) return y; // local_return_to_void: ok

  if (condition) return z; // final_local_return_to_void: ok

  if (condition) return global; // global_return_to_void: ok

  if (condition) return true ? x : x; // conditional_return_to_void: ok

  if (condition) return true ? 499 : x; // conditional2_return_to_void: ok

  if (condition) return true ? x : 499; // conditional3_return_to_void: ok

  if (condition) return a.x; // instance_return_to_void: ok

  if (condition) return b.x; // instance2_return_to_void: ok

  if (condition) return c.x; // instance3_return_to_void: ok

  return (x); // paren_return_to_void: ok
}

main() {
  // Will not run, so we just ensure that each function is referred, such
  // that an optimizing compilation/analysis will not ignore them entirely.
  print(testVoidParam);
  print(testVoidCall);
  print(testVoidLocal);
  print(testVoidFinalLocal);
  print(testVoidConditional);
  print(testInstanceField);
  print(testParenthesized);
  print(testReturnToVoid);
}
