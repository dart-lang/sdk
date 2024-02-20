// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We say that a type T is incompatible with await if at least one of
// the following criteria holds:
//
//   1. T is an extension type that does not implement Future.
//   2. T is S?, and S is incompatible with await.
//   3. T is X & B, and B is incompatible with await.
//   4. T is a type variable with bound S, and S is incompatible with await.
//
// This test targets the classification of await expressions according to
// the type of the operand being compatible or incompatible with await.
//
// Each case has a comment indicating the sequence of rules used. For example,
// the case where we use rule 4 above and then rule 2 is marked '// 4.2.'.

import 'dart:async';

// Incompatible.
extension type N(Future<int> _) {}

// Compatible.
extension type F(Future<int> _) implements Future<int>, N {}

class SF implements Future<int> {
  noSuchMethod(Invocation _) => throw "Just kidding, this is a static test.";
}

// Compatible (implements `Future<int>`).
extension type SFE(SF _) implements SF {}

// Compatible (ditto).
extension type SFE2(SFE _) implements SFE {}

void main() async {
  // 1 (use rule 1).
  await N(Future<int>.value(1));
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
//      ^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.
  await F(Future<int>.value(1));

  N n = N(Future<int>.value(1));
  F f = F(Future<int>.value(1));
  N? nq = n as dynamic;
  F? fq = f as dynamic;

  // 2.1 (use rule 2 which in turn uses rule 1).
  await nq;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
//      ^
// [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  await fq;

  FutureOr<N> fon = n;
  await fon;

  FutureOr<F> fof = f;
  await fof;

  FutureOr<N?> fonq = nq;
  await fonq;

  FutureOr<F?> fofq = fq;
  await fofq;

  var fut = Future<int>.value(1);
  foo<Object?, N, F, N?, F?, FutureOr<N>, FutureOr<F>, FutureOr<N>?,
      FutureOr<F>?>(
    fut,
    N(fut),
    F(fut),
    null,
    null,
    N(fut),
    F(fut),
    N(fut),
    F(fut),
  );

  var sfe2 = SFE2(SFE(SF()));
  await sfe2;
}

// Test type parameter types.
void foo<
    X,
    XN extends N,
    XF extends F,
    XNQ extends N?,
    XFQ extends F?,
    XFoN extends FutureOr<N>,
    XFoF extends FutureOr<F>,
    XFoNQ extends FutureOr<N>?,
    XFoFQ extends FutureOr<F>?>(
  X x,
  XN xn,
  XF xf,
  XNQ xnq,
  XFQ xfq,
  XFoN xfon,
  XFoF xfof,
  XFoNQ xfonq,
  XFoFQ xfofq,
) async {
  await x;

  // 4.1.
  await xn;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
//      ^^
// [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  await xf;
  await xfon;
  await xfof;
  await xfonq;
  await xfofq;

  // 4.2.
  await xnq;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
//      ^^^
// [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  await xfq;

  // 3.1.
  if (x is N) await x;
  //          ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (xnq is N) await xnq;
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                  ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (xfon is N) await xfon;
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                   ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (xfonq is N) await xfonq;
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                    ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is F) await x;
  if (xn is F) await xn;
  if (xf is F) await xf;
  if (xnq is F) await xnq;
  if (xfq is F) await xfq;
  if (xfon is F) await xfon;
  if (xfof is F) await xfof;
  if (xfonq is F) await xfonq;
  if (xfofq is F) await xfofq;

  if (xnq is Null) await xnq;
  if (xfq is Null) await xfq;
  if (xfonq is Null) await xfonq;
  if (xfofq is Null) await xfofq;

  if (x is N? && x is Null) await x;

  // 3.2.1.
  if (x is N?) await x;
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                 ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is F?) await x;

  // 3.2.4.
  if (x is XN?) await x;
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                  ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is XF?) await x;

  // 3.4.1.
  if (x is XN) await x;
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                 ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is XF) await x;

  // 3.4.2.
  if (x is XNQ) await x;
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                  ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is XFQ) await x;

  // 2.3.4.2.
  if (x is XNQ?) await x;
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AWAIT_OF_INCOMPATIBLE_TYPE
  //                   ^
  // [cfe] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.

  if (x is XFQ?) await x;
}
