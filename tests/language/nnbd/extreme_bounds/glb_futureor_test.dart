// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

/*
 * Set up three synthetic types Left, Right, Bottom, such that
 * Left and Right are not subtype related, both are
 * supertypes of Bottom, and GLB(Left, Right) == Bottom
 */
typedef Left = void Function(double);
typedef Right = void Function(int);
typedef Bottom = void Function(num);

/*
 * Typedefs which given a type T produce a contra-variant
 * occurrence of FutureOr<T>, Future<T>, and T respectively.
 */
typedef TakesFutureOr<T> = void Function(FutureOr<T>);
typedef TakesFuture<T> = void Function(Future<T>);
typedef Takes<T> = void Function(T);

/*
* Given a type T, produce a type Exactly<T> such that
* Exactly<S> <: Exactly<T> iff S and T are mutual subtypes.
*/
typedef Exactly<T> = T Function(T);
/*
* Given an argument of type T, produce a result of type Exactly<T>.
*/
Exactly<T> exactly<T>(T t) => (T t) => t;

/*
* Given a call infer(a, b) where a has type void Function(S0) and b has type
* void Function(S1), set up an inference constraint system of the form:
* ? <: T <: S0
* ? <: T <: S1
* which merges to:
* ? <: T <: GLB(S0, S1)
*/
Exactly<void Function(T)> infer<T>(void Function(T) x, void Function(T) y) {
  return (void Function(T) t) => t;
}

void test(bool b) {
  // Variables of specific types for input into the GLB algorithm
  TakesFutureOr<Left> futureOrLeft = (_) {};
  TakesFutureOr<Right> futureOrRight = (_) {};
  TakesFuture<Left> futureLeft = (_) {};
  TakesFuture<Right> futureRight = (_) {};
  Takes<Left> left = (_) {};
  Takes<Right> right = (_) {};

  // Check variables of exact type.  Assigning the result of inference
  // to any of these checks that the result is exactly as expect.
  Exactly<TakesFutureOr<Bottom>> checkFutureOrBottom = (t) => t;
  Exactly<TakesFuture<Bottom>> checkFutureBottom = (t) => t;
  Exactly<Takes<Bottom>> checkBottom = (t) => t;

  // Note: assignments are done in separate steps below to avoid interactions
  // with downward inference.

  // GLB(FutureOr<A>, FutureOr<B>) = FutureOr<GLB(A, B)>
  {
    // Compute the upper bound of the function types, which computes
    // the GLB of the argument types.
    var glb = b ? futureOrLeft : futureOrRight;
    // Capture the inferred type of glb as an exact type.
    var exactlyGlb = exactly(glb);
    // Check that the inferred type is exactly as expected.
    checkFutureOrBottom = exactlyGlb;
    Expect.type<Exactly<TakesFutureOr<Bottom>>>(exactlyGlb);

    // Compute the upper bound of the function types via inference
    // constraint merge which computes the GLB of the argument types.
    var merge = infer(futureOrLeft, futureOrRight);
    checkFutureOrBottom = merge;
    Expect.type<Exactly<TakesFutureOr<Bottom>>>(merge);
  }

  // GLB(FutureOr<A>, Future<B>) = Future<GLB(A, B)>
  {
    // Compute the upper bound of the function types, which computes
    // the GLB of the argument types.
    var glb = b ? futureOrLeft : futureRight;
    // Capture the inferred type of glb as an exact type.
    var exactlyGlb = exactly(glb);
    // Check that the inferred type is exactly as expected.
    checkFutureBottom = exactlyGlb;
    Expect.type<Exactly<TakesFuture<Bottom>>>(exactlyGlb);

    // Compute the upper bound of the function types via inference
    // constraint merge which computes the GLB of the argument types.
    var merge = infer(futureOrLeft, futureRight);
    checkFutureBottom = merge;
    Expect.type<Exactly<TakesFuture<Bottom>>>(merge);
  }

  // GLB(Future<A>, FutureOr<B>) = Future<GLB(A, B)>
  {
    // Compute the upper bound of the function types, which computes
    // the GLB of the argument types.
    var glb = b ? futureLeft : futureOrRight;
    // Capture the inferred type of glb as an exact type.
    var exactlyGlb = exactly(glb);
    // Check that the inferred type is exactly as expected.
    checkFutureBottom = exactlyGlb;
    Expect.type<Exactly<TakesFuture<Bottom>>>(exactlyGlb);

    // Compute the upper bound of the function types via inference
    // constraint merge which computes the GLB of the argument types.
    var merge = infer(futureLeft, futureOrRight);
    checkFutureBottom = merge;
    Expect.type<Exactly<TakesFuture<Bottom>>>(merge);
  }

  // GLB(FutureOr<A>, B) = GLB(A, B)
  {
    // Compute the upper bound of the function types, which computes
    // the GLB of the argument types.
    var glb = b ? futureOrLeft : right;
    // Capture the inferred type of glb as an exact type.
    var exactlyGlb = exactly(glb);
    // Check that the inferred type is exactly as expected.
    checkBottom = exactlyGlb;
    Expect.type<Exactly<Takes<Bottom>>>(exactlyGlb);

    // Compute the upper bound of the function types via inference
    // constraint merge which computes the GLB of the argument types.
    var merge = infer(futureOrLeft, right);
    checkBottom = merge;
    Expect.type<Exactly<Takes<Bottom>>>(merge);
  }

  // GLB(A, FutureOr<B>) = GLB(A, B)
  {
    // Compute the upper bound of the function types, which computes
    // the GLB of the argument types.
    var glb = b ? left : futureOrRight;
    // Capture the inferred type of glb as an exact type.
    var exactlyGlb = exactly(glb);
    // Check that the inferred type is exactly as expected.
    checkBottom = exactlyGlb;
    Expect.type<Exactly<Takes<Bottom>>>(exactlyGlb);

    // Compute the upper bound of the function types via inference
    // constraint merge which computes the GLB of the argument types.
    var merge = infer(left, futureOrRight);
    checkBottom = merge;
    Expect.type<Exactly<Takes<Bottom>>>(merge);
  }
}

main() {
  test(true);
  test(false);
}
