// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ArgumentTypeNotAssignableNullability` error, for which we wish to
// report "why not promoted" context information.

class C1 {
  int? bad;
  //   ^
  // [context 1] 'bad' refers to a property so it couldn't be promoted.
  f(int i) {}
}

required_unnamed(C1 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe 1] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C2 {
  int? bad;
  //   ^
  // [context 2] 'bad' refers to a property so it couldn't be promoted.
  f([int i = 0]) {}
}

optional_unnamed(C2 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe 2] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C3 {
  int? bad;
  //   ^
  // [context 3] 'bad' refers to a property so it couldn't be promoted.
  f({required int i}) {}
}

required_named(C3 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe 3] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C4 {
  int? bad;
  //   ^
  // [context 4] 'bad' refers to a property so it couldn't be promoted.
  f({int i = 0}) {}
}

optional_named(C4 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe 4] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C5 {
  List<int>? bad;
  //         ^
  // [context 5] 'bad' refers to a property so it couldn't be promoted.
  f<T>(List<T> x) {}
}

type_inferred(C5 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe 5] The argument type 'List<int>?' can't be assigned to the parameter type 'List<int>' because 'List<int>?' is nullable and 'List<int>' isn't.
}

class C6 {
  int? bad;
  //   ^
  // [context 6] 'bad' refers to a property so it couldn't be promoted.
  C6(int i);
}

C6? constructor_with_implicit_new(C6 c) {
  if (c.bad == null) return null;
  return C6(c.bad);
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //          ^
  // [cfe 6] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C7 {
  int? bad;
  //   ^
  // [context 7] 'bad' refers to a property so it couldn't be promoted.
  C7(int i);
}

C7? constructor_with_explicit_new(C7 c) {
  if (c.bad == null) return null;
  return new C7(c.bad);
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //              ^
  // [cfe 7] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
}

class C8 {
  int? bad;
  //   ^
  // [context 8] 'bad' refers to a property so it couldn't be promoted.
}

userDefinableBinaryOpRhs(C8 c) {
  if (c.bad == null) return;
  1 + c.bad;
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe 8] A value of type 'int?' can't be assigned to a variable of type 'num' because 'int?' is nullable and 'num' isn't.
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
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int' because 'int?' is nullable and 'int' isn't.
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
  //    ^
  // [context 9] 'bad' refers to a property so it couldn't be promoted.
  // [context 10] 'bad' refers to a property so it couldn't be promoted.
  f(bool b) {}
}

andOperand(C11 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad && b);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe 9] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  c.f(b && c.bad);
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe 10] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C12 {
  bool? bad;
  //    ^
  // [context 11] 'bad' refers to a property so it couldn't be promoted.
  // [context 12] 'bad' refers to a property so it couldn't be promoted.
  f(bool b) {}
}

orOperand(C12 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad || b);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe 11] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  c.f(b || c.bad);
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe 12] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C13 {
  bool? bad;
  //    ^
  // [context 13] 'bad' refers to a property so it couldn't be promoted.
}

assertStatementCondition(C13 c) {
  if (c.bad == null) return;
  assert(c.bad);
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe 13] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C14 {
  bool? bad;
  //    ^
  // [context 14] 'bad' refers to a property so it couldn't be promoted.
  C14.assertInitializerCondition(C14 c)
      : bad = c.bad!,
        assert(c.bad);
        //     ^^^^^
        // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
        //       ^
        // [cfe 14] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C15 {
  bool? bad;
  //    ^
  // [context 15] 'bad' refers to a property so it couldn't be promoted.
  f(bool b) {}
}

notOperand(C15 c) {
  if (c.bad == null) return;
  c.f(!c.bad);
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe 15] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C16 {
  bool? bad;
  //    ^
  // [context 16] 'bad' refers to a property so it couldn't be promoted.
  // [context 17] 'bad' refers to a property so it couldn't be promoted.
  // [context 18] 'bad' refers to a property so it couldn't be promoted.
  // [context 19] 'bad' refers to a property so it couldn't be promoted.
}

forLoopCondition(C16 c) {
  if (c.bad == null) return;
  for (; c.bad;) {}
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe 16] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  [for (; c.bad;) null];
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //        ^
  // [cfe 17] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  ({for (; c.bad;) null});
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe 18] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  ({for (; c.bad;) null: null});
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe 19] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C17 {
  bool? bad;
  //    ^
  // [context 20] 'bad' refers to a property so it couldn't be promoted.
  f(int i) {}
}

conditionalExpressionCondition(C17 c) {
  if (c.bad == null) return;
  c.f(c.bad ? 1 : 2);
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe 20] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C18 {
  bool? bad;
  //    ^
  // [context 21] 'bad' refers to a property so it couldn't be promoted.
}

doLoopCondition(C18 c) {
  if (c.bad == null) return;
  do {} while (c.bad);
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //             ^
  // [cfe 21] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C19 {
  bool? bad;
  //    ^
  // [context 22] 'bad' refers to a property so it couldn't be promoted.
  // [context 23] 'bad' refers to a property so it couldn't be promoted.
  // [context 24] 'bad' refers to a property so it couldn't be promoted.
  // [context 25] 'bad' refers to a property so it couldn't be promoted.
}

ifCondition(C19 c) {
  if (c.bad == null) return;
  if (c.bad) {}
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe 22] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  [if (c.bad) null];
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe 23] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  ({if (c.bad) null});
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe 24] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
  ({if (c.bad) null: null});
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe 25] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C20 {
  bool? bad;
  //    ^
  // [context 26] 'bad' refers to a property so it couldn't be promoted.
}

whileCondition(C20 c) {
  if (c.bad == null) return;
  while (c.bad) {}
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe 26] A value of type 'bool?' can't be assigned to a variable of type 'bool' because 'bool?' is nullable and 'bool' isn't.
}

class C21 {
  int? bad;
  //   ^
  // [context 27] 'bad' refers to a property so it couldn't be promoted.
}

assignmentRhs(C21 c, int i) {
  if (c.bad == null) return;
  i = c.bad;
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //    ^
  // [cfe 27] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C22 {
  int? bad;
  //   ^
  // [context 28] 'bad' refers to a property so it couldn't be promoted.
}

variableInitializer(C22 c) {
  if (c.bad == null) return;
  int i = c.bad;
  //      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //        ^
  // [cfe 28] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C23 {
  int? bad;
  //   ^
  // [context 29] 'bad' refers to a property so it couldn't be promoted.
  final int x;
  final int y;
  C23.constructorInitializer(C23 c)
      : x = c.bad!,
        y = c.bad;
        //  ^^^^^
        // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
        //    ^
        // [cfe 29] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C24 {
  int? bad;
  //   ^
  // [context 30] 'bad' refers to a property so it couldn't be promoted.
  // [context 31] 'bad' refers to a property so it couldn't be promoted.
  // [context 32] 'bad' refers to a property so it couldn't be promoted.
  // [context 33] 'bad' refers to a property so it couldn't be promoted.
}

forVariableInitializer(C24 c) {
  if (c.bad == null) return;
  for (int i = c.bad; false;) {}
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //             ^
  // [cfe 30] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  [for (int i = c.bad; false;) null];
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe 31] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  ({for (int i = c.bad; false;) null});
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe 32] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  ({for (int i = c.bad; false;) null: null});
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe 33] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C25 {
  int? bad;
  //   ^
  // [context 34] 'bad' refers to a property so it couldn't be promoted.
  // [context 35] 'bad' refers to a property so it couldn't be promoted.
  // [context 36] 'bad' refers to a property so it couldn't be promoted.
  // [context 37] 'bad' refers to a property so it couldn't be promoted.
}

forAssignmentInitializer(C25 c, int i) {
  if (c.bad == null) return;
  for (i = c.bad; false;) {}
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //         ^
  // [cfe 34] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  [for (i = c.bad; false;) null];
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe 35] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  ({for (i = c.bad; false;) null});
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe 36] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  ({for (i = c.bad; false;) null: null});
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe 37] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C26 {
  int? bad;
  //   ^
  // [context 38] 'bad' refers to a property so it couldn't be promoted.
}

compoundAssignmentRhs(C26 c) {
  num n = 0;
  if (c.bad == null) return;
  n += c.bad;
  //   ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe 38] A value of type 'int?' can't be assigned to a variable of type 'num' because 'int?' is nullable and 'num' isn't.
}

class C27 {
  int? bad;
  //   ^
  // [context 39] 'bad' refers to a property so it couldn't be promoted.
}

indexGet(C27 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad];
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe 39] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C28 {
  int? bad;
  //   ^
  // [context 40] 'bad' refers to a property so it couldn't be promoted.
}

indexSet(C28 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad] = 0;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe 40] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C29 {
  int? bad;
}

indexSetCompound(C29 c, List<int> values) {
  // TODO(paulberry): get this to work with the CFE
  if (c.bad == null) return;
  values[c.bad] += 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C30 {
  int? bad;
}

indexSetIfNull(C30 c, List<int?> values) {
  // TODO(paulberry): get this to work with the CFE
  if (c.bad == null) return;
  values[c.bad] ??= 1;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C31 {
  int? bad;
}

indexSetPreIncDec(C31 c, List<int> values) {
  // TODO(paulberry): get this to work with the CFE
  if (c.bad == null) return;
  ++values[c.bad];
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  --values[c.bad];
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}

class C32 {
  int? bad;
}

indexSetPostIncDec(C32 c, List<int> values) {
  // TODO(paulberry): get this to work with the CFE
  if (c.bad == null) return;
  values[c.bad]++;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
  values[c.bad]--;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int' because 'int?' is nullable and 'int' isn't.
}
