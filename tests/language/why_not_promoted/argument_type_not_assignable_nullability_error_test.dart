// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ArgumentTypeNotAssignableNullability` error, for which we wish to
// report "why not promoted" context information.

class C1 {
  int? bad;
  //   ^^^
  // [context 1] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f(int i) {}
}

required_unnamed(C1 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer 1] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C2 {
  int? bad;
  //   ^^^
  // [context 2] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f([int i = 0]) {}
}

optional_unnamed(C2 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer 2] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C3 {
  int? bad;
  //   ^^^
  // [context 3] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f({required int i}) {}
}

required_named(C3 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //     ^^^^^
  // [analyzer 3] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C4 {
  int? bad;
  //   ^^^
  // [context 4] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f({int i = 0}) {}
}

optional_named(C4 c) {
  if (c.bad == null) return;
  c.f(i: c.bad);
  //     ^^^^^
  // [analyzer 4] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C5 {
  List<int>? bad;
  //         ^^^
  // [context 5] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f<T>(List<T> x) {}
}

type_inferred(C5 c) {
  if (c.bad == null) return;
  c.f(c.bad);
  //  ^^^^^
  // [analyzer 5] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //    ^
  // [cfe] The argument type 'List<int>?' can't be assigned to the parameter type 'List<int>'.
}

class C6 {
  int? bad;
  //   ^^^
  // [context 6] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  C6(int i);
}

C6? constructor_with_implicit_new(C6 c) {
  if (c.bad == null) return null;
  return C6(c.bad);
  //        ^^^^^
  // [analyzer 6] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //          ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C7 {
  int? bad;
  //   ^^^
  // [context 7] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  C7(int i);
}

C7? constructor_with_explicit_new(C7 c) {
  if (c.bad == null) return null;
  return new C7(c.bad);
  //            ^^^^^
  // [analyzer 7] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //              ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C8 {
  int? bad;
  //   ^^^
  // [context 8] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

userDefinableBinaryOpRhs(C8 c) {
  if (c.bad == null) return;
  1 + c.bad;
  //  ^^^^^
  // [analyzer 8] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
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
  //    ^^^
  // [context 9] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 10] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f(bool b) {}
}

andOperand(C11 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad && b);
  //  ^^^^^
  // [analyzer 9] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  c.f(b && c.bad);
  //       ^^^^^
  // [analyzer 10] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C12 {
  bool? bad;
  //    ^^^
  // [context 11] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 12] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f(bool b) {}
}

orOperand(C12 c, bool b) {
  if (c.bad == null) return;
  c.f(c.bad || b);
  //  ^^^^^
  // [analyzer 11] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  c.f(b || c.bad);
  //       ^^^^^
  // [analyzer 12] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C13 {
  bool? bad;
  //    ^^^
  // [context 13] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

assertStatementCondition(C13 c) {
  if (c.bad == null) return;
  assert(c.bad);
  //     ^^^^^
  // [analyzer 13] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C14 {
  bool? bad;
  //    ^^^
  // [context 14] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  C14.assertInitializerCondition(C14 c) : bad = c.bad!, assert(c.bad);
  //                                                           ^^^^^
  // [analyzer 14] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                                                             ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C15 {
  bool? bad;
  //    ^^^
  // [context 15] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f(bool b) {}
}

notOperand(C15 c) {
  if (c.bad == null) return;
  c.f(!c.bad);
  //   ^^^^^
  // [analyzer 15] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C16 {
  bool? bad;
  //    ^^^
  // [context 16] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 17] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 18] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 19] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

forLoopCondition(C16 c) {
  if (c.bad == null) return;
  for (; c.bad;) {}
  //     ^^^^^
  // [analyzer 16] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  [for (; c.bad;) null];
  //      ^^^^^
  // [analyzer 17] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //        ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({for (; c.bad;) null});
  //       ^^^^^
  // [analyzer 18] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({for (; c.bad;) null: null});
  //       ^^^^^
  // [analyzer 19] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //         ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C17 {
  bool? bad;
  //    ^^^
  // [context 20] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  f(int i) {}
}

conditionalExpressionCondition(C17 c) {
  if (c.bad == null) return;
  c.f(c.bad ? 1 : 2);
  //  ^^^^^
  // [analyzer 20] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C18 {
  bool? bad;
  //    ^^^
  // [context 21] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

doLoopCondition(C18 c) {
  if (c.bad == null) return;
  do {} while (c.bad);
  //           ^^^^^
  // [analyzer 21] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //             ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C19 {
  bool? bad;
  //    ^^^
  // [context 22] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 23] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 24] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 25] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

ifCondition(C19 c) {
  if (c.bad == null) return;
  if (c.bad) {}
  //  ^^^^^
  // [analyzer 22] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //    ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  [if (c.bad) null];
  //   ^^^^^
  // [analyzer 23] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //     ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({if (c.bad) null});
  //    ^^^^^
  // [analyzer 24] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
  ({if (c.bad) null: null});
  //    ^^^^^
  // [analyzer 25] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //      ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C20 {
  bool? bad;
  //    ^^^
  // [context 26] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

whileCondition(C20 c) {
  if (c.bad == null) return;
  while (c.bad) {}
  //     ^^^^^
  // [analyzer 26] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //       ^
  // [cfe] A value of type 'bool?' can't be assigned to a variable of type 'bool'.
}

class C21 {
  int? bad;
  //   ^^^
  // [context 27] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

assignmentRhs(C21 c, int i) {
  if (c.bad == null) return;
  i = c.bad;
  //  ^^^^^
  // [analyzer 27] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C22 {
  int? bad;
  //   ^^^
  // [context 28] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

variableInitializer(C22 c) {
  if (c.bad == null) return;
  int i = c.bad;
  //      ^^^^^
  // [analyzer 28] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //        ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C23 {
  int? bad;
  //   ^^^
  // [context 29] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  final int x;
  final int y;
  C23.constructorInitializer(C23 c) : x = c.bad!, y = c.bad;
  //                                                  ^^^^^
  // [analyzer 29] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
  //                                                    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C24 {
  int? bad;
  //   ^^^
  // [context 30] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 31] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 32] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 33] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

forVariableInitializer(C24 c) {
  if (c.bad == null) return;
  for (int i = c.bad; false;) {}
  //           ^^^^^
  // [analyzer 30] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //             ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  [for (int i = c.bad; false;) null];
  //            ^^^^^
  // [analyzer 31] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (int i = c.bad; false;) null});
  //             ^^^^^
  // [analyzer 32] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (int i = c.bad; false;) null: null});
  //             ^^^^^
  // [analyzer 33] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C25 {
  int? bad;
  //   ^^^
  // [context 34] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 35] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 36] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 37] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

forAssignmentInitializer(C25 c, int i) {
  if (c.bad == null) return;
  for (i = c.bad; false;) {}
  //       ^^^^^
  // [analyzer 34] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  [for (i = c.bad; false;) null];
  //        ^^^^^
  // [analyzer 35] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (i = c.bad; false;) null});
  //         ^^^^^
  // [analyzer 36] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  ({for (i = c.bad; false;) null: null});
  //         ^^^^^
  // [analyzer 37] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C26 {
  int? bad;
  //   ^^^
  // [context 38] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

compoundAssignmentRhs(C26 c) {
  num n = 0;
  if (c.bad == null) return;
  n += c.bad;
  //   ^^^^^
  // [analyzer 38] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //     ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'num'.
}

class C27 {
  int? bad;
  //   ^^^
  // [context 39] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexGet(C27 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad];
  //     ^^^^^
  // [analyzer 39] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C28 {
  int? bad;
  //   ^^^
  // [context 40] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSet(C28 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad] = 0;
  //     ^^^^^
  // [analyzer 40] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C29 {
  int? bad;
  //   ^^^
  // [context 41] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSetCompound(C29 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad] += 1;
  //     ^^^^^
  // [analyzer 41] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C30 {
  int? bad;
  //   ^^^
  // [context 42] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSetIfNull(C30 c, List<int?> values) {
  if (c.bad == null) return;
  values[c.bad] ??= 1;
  //     ^^^^^
  // [analyzer 42] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C31 {
  int? bad;
  //   ^^^
  // [context 43] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 44] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSetPreIncDec(C31 c, List<int> values) {
  if (c.bad == null) return;
  ++values[c.bad];
  //       ^^^^^
  // [analyzer 43] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  --values[c.bad];
  //       ^^^^^
  // [analyzer 44] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C32 {
  int? bad;
  //   ^^^
  // [context 45] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 46] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSetPostIncDec(C32 c, List<int> values) {
  if (c.bad == null) return;
  values[c.bad]++;
  //     ^^^^^
  // [analyzer 45] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
  values[c.bad]--;
  //     ^^^^^
  // [analyzer 46] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

extension E33 on int {
  void f() {}
}

class C33 {
  int? bad;
  //   ^^^
  // [context 47] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

explicitExtensionInvocation(C33 c) {
  if (c.bad == null) return;
  E33(c.bad).f();
  //  ^^^^^
  // [analyzer 47] COMPILE_TIME_ERROR.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE
  //    ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}

class C34 {
  int? bad;
  //   ^^^
  // [context 48] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  C34(int value);
}

class D34 extends C34 {
  int other;
  D34(C34 c) : other = c.bad!, super(c.bad);
  //                                 ^^^^^
  // [analyzer 48] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                   ^
  // [cfe] The argument type 'int?' can't be assigned to the parameter type 'int'.
}

class C35 {
  int? bad;
  //   ^^^
  // [context 49] 'bad' refers to a public property so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
}

indexSetRhs(C35 c, List<int> x) {
  if (c.bad == null) return;
  x[0] = c.bad;
  //     ^^^^^
  // [analyzer 49] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //       ^
  // [cfe] A value of type 'int?' can't be assigned to a variable of type 'int'.
}
