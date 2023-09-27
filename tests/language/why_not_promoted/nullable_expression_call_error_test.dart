// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableExpressionCallError`, for which we wish to report "why not
// promoted" context information.

class C1 {
  C2? bad;
  //  ^^^
  // [context 1] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 7] 'bad' refers to a public field so it couldn't be promoted.
}

class C2 {
  void call() {}
}

instance_method_invocation(C1 c) {
  if (c.bad == null) return;
  c.bad();
//^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//     ^
// [cfe 7] Can't use an expression of type 'C2?' as a function because it's potentially null.
}

class C3 {
  C4? ok;
  C5? bad;
  //  ^^^
  // [context 2] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 8] 'bad' refers to a public field so it couldn't be promoted.
}

class C4 {}

class C5 {}

extension on C4? {
  void call() {}
}

extension on C5 {
  void call() {}
}

extension_invocation_method(C3 c) {
  if (c.ok == null) return;
  c.ok();
  if (c.bad == null) return;
  c.bad();
//^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//     ^
// [cfe 8] Can't use an expression of type 'C5?' as a function because it's potentially null.
}

class C6 {
  C7? bad;
  //  ^^^
  // [context 3] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 9] 'bad' refers to a public field so it couldn't be promoted.
}

class C7 {
  void Function() get call => () {};
}

instance_getter_invocation(C6 c) {
  if (c.bad == null) return;
  c.bad();
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
// [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//     ^
// [cfe 9] Can't use an expression of type 'C7?' as a function because it's potentially null.
}

class C8 {
  C10? bad;
  //   ^^^
  // [context 4] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 10] 'bad' refers to a public field so it couldn't be promoted.
}

class C10 {}

extension on C10 {
  void Function() get call => () {};
}

extension_invocation_getter(C8 c) {
  if (c.bad == null) return;
  c.bad();
//^^^^^
// [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//     ^
// [cfe 10] Can't use an expression of type 'C10?' as a function because it's potentially null.
}

class C11 {
  void Function()? bad;
  //               ^^^
  // [context 5] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 11] 'bad' refers to a public field so it couldn't be promoted.
}

function_invocation(C11 c) {
  if (c.bad == null) return;
  c.bad();
//^^^^^
// [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//     ^
// [cfe 11] Can't use an expression of type 'void Function()?' as a function because it's potentially null.
}

class C12 {
  C13? bad;
  //   ^^^
  // [context 6] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 12] 'bad' refers to a public field so it couldn't be promoted.
}

class C13 {
  void Function() foo;
  C13(this.foo);
}

instance_field_invocation(C12 c) {
  if (c.bad == null) return;
  // Note: the CFE error message is misleading here.  See
  // https://github.com/dart-lang/sdk/issues/45552
  c.bad.foo();
//      ^^^
// [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 12] Can't use an expression of type 'C13?' as a function because it's potentially null.
}
