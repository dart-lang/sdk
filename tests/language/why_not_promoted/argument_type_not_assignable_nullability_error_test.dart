// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ArgumentTypeNotAssignableNullability` error, for which we wish to
// report "why not promoted" context information.

class C1 {
  int? bad;
  f(int i) {}
}

required_unnamed(C1 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C2 {
  int? bad;
  f([int i = 0]) {}
}

optional_unnamed(C2 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C3 {
  int? bad;
  f({required int i}) {}
}

required_named(C3 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C4 {
  int? bad;
  f({int i = 0}) {}
}

optional_named(C4 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C5 {
  List<int>? bad;
  f<T>(List<T> x) {}
}

type_inferred(C5 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'List<int>?' can't be assigned to the parameter type 'List<int>'.
}

class C6 {
  int? bad;
  C6(int i);
}

C6? constructor_with_implicit_new(C6 c) {
  if (c.bad == null) return null;
  return C6(c.bad);
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //          ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C7 {
  int? bad;
  C7(int i);
}

C7? constructor_with_explicit_new(C7 c) {
  if (c.bad == null) return null;
  return new C7(c.bad);
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //              ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C8 {
  int? bad;
}

userDefinableBinaryOpRhs(C8 c) {
  if (c.bad == null) return;
  1 + c.bad;
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'num'.
}

class C9 {
  int? bad;
  f(int i) {}
}

questionQuestionRhs(C9 c, int? i) {
  // Note: "why not supported" functionality is currently not supported for the
  // RHS of `??` because it requires more clever reasoning than we currently do:
  // we would have to understand that the reason `i ?? c.bad` has a type of
  // `int?` rather than `int` is because `c.bad` was not promoted.  We currently
  // only support detecting non-promotion when the expression that had the wrong
  // type *is* the expression that wasn't promoted.
  if (c.bad == null) return;
  c.f(i ?? c.bad);
  //  ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C10 {
  D10? bad;
  f(bool b) {}
}

class D10 {
  bool operator ==(covariant D10 other) => true;
}

equalRhs(C10 c, D10 d) {
  if (c.bad == null) return;
  // Note: we don't report an error here because `==` always accepts `null`.
  c.f(d == c.bad);
  c.f(d != c.bad);
}

class C11 {
  bool? bad;
  f(bool b) {}
}

andOperand(C11 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad && b);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  c.f(b && c.bad);
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C12 {
  bool? bad;
  f(bool b) {}
}

orOperand(C12 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad || b);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  c.f(b || c.bad);
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C13 {
  bool? bad;
}

assertStatementCondition(C13 c) {
  if (c.bad == null) return;
  assert(c.bad);
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C14 {
  bool? bad;
  C14.assertInitializerCondition(C14 c) : bad = c.bad!, assert(c.bad);
  //                                                           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                                                             ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C15 {
  bool? bad;
  f(bool b) {}
}

notOperand(C15 c) {
  if (c.bad == null) return;
  c.f(!c.bad);
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C16 {
  bool? bad;
}

forLoopCondition(C16 c) {
  if (c.bad == null) return;
  for (; c.bad;) {}
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  [for (; c.bad;) null];
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //        ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({for (; c.bad;) null});
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({for (; c.bad;) null: null});
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C17 {
  bool? bad;
  f(int i) {}
}

conditionalExpressionCondition(C17 c) {
  if (c.bad == null) return;
  c.f(c.bad ? 1 : 2);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C18 {
  bool? bad;
}

doLoopCondition(C18 c) {
  if (c.bad == null) return;
  do {} while (c.bad);
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //             ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C19 {
  bool? bad;
}

ifCondition(C19 c) {
  if (c.bad == null) return;
  if (c.bad) {}
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  [if (c.bad) null];
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({if (c.bad) null});
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({if (c.bad) null: null});
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C20 {
  bool? bad;
}

whileCondition(C20 c) {
  if (c.bad == null) return;
  while (c.bad) {}
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C21 {
  int? bad;
}

assignmentRhs(C21 c, int i) {
  if (c.bad == null) return;
  i = c.bad;
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C22 {
  int? bad;
}

variableInitializer(C22 c) {
  if (c.bad == null) return;
  int i = c.bad;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //        ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C23 {
  int? bad;
  final int x;
  final int y;
  C23.constructorInitializer(C23 c) : x = c.bad!, y = c.bad;
  //                                                  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
  //                                                    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C24 {
  int? bad;
}

forVariableInitializer(C24 c) {
  if (c.bad == null) return;
  for (int i = c.bad; false;) {}
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //             ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  [for (int i = c.bad; false;) null];
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (int i = c.bad; false;) null});
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (int i = c.bad; false;) null: null});
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C25 {
  int? bad;
}

forAssignmentInitializer(C25 c, int i) {
  if (c.bad == null) return;
  for (i = c.bad; false;) {}
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  [for (i = c.bad; false;) null];
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (i = c.bad; false;) null});
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (i = c.bad; false;) null: null});
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C26 {
  int? bad;
}

compoundAssignmentRhs(C26 c) {
  num n = 0;
  if (c.bad == null) return;
  n += c.bad;
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'num'.
}

class C27 {
  int? bad;
}

indexGet(C27 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad];
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C28 {
  int? bad;
}

indexSet(C28 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad] = 0;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C29 {
  int? bad;
}

indexSetCompound(C29 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad] += 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C30 {
  int? bad;
}

indexSetIfNull(C30 c, List<int?> values) {
  if (c.bad == null) return;
  values[c.bad] ??= 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C31 {
  int? bad;
}

indexSetPreIncDec(C31 c, List<int> values) {
  if (c.bad == null) return;
  ++values[c.bad];
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  --values[c.bad];
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C32 {
  int? bad;
}

indexSetPostIncDec(C32 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad]++;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  values[c.bad]--;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

extension E33 on int {
  void f() {}
}

class C33 {
  int? bad;
}

explicitExtensionInvocation(C33 c) {
  if (c.bad == null) return;
  E33(c.bad).f();
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE
  //    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C34 {
  int? bad;
  C34(int value);
}

class D34 extends C34 {
  int other;
  D34(C34 c) : other = c.bad!, super(c.bad);
  //                                 ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                   ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C35 {
  int? bad;
}

indexSetRhs(C35 c, List<int> x) {
  if (c.bad == null) return;
  x[0] = c.bad;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}
