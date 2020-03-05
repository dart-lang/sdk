// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'runtime_utils.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // A <: dynamic
  checkProperSubtype(A, dynamic);
  // A <: Object
  checkProperSubtype(A, Object);
  // TODO(nshahan) Test void as top? A <: void

  // Null <: A
  checkProperSubtype(Null, A);

  // FutureOr<Null> <: Future<Null>
  checkSubtype(futureOrOf(Null), generic1(Future, Null));
  // Future<Null> <: FutureOr<Null>
  checkSubtype(generic1(Future, Null), futureOrOf(Null));
  // Future<B> <: FutureOr<A>
  checkProperSubtype(generic1(Future, B), futureOrOf(A));
  // B <: <: FutureOr<A>
  checkProperSubtype(B, futureOrOf(A));
  // Future<B> <: Future<A>
  checkProperSubtype(generic1(Future, B), generic1(Future, A));
  // B <: A
  checkProperSubtype(B, A);

  // A <: A
  checkSubtype(A, A);
  // C <: B
  checkProperSubtype(C, B);
  // C <: A
  checkProperSubtype(C, A);

  // A -> B <: Function
  checkProperSubtype(function1(B, A), Function);

  // A -> B <: A -> B
  checkSubtype(function1(B, A), function1(B, A));

  // A -> B <: B -> B
  checkProperSubtype(function1(B, A), function1(B, B));
  // TODO(nshahan) Subtype check with covariant keyword?

  // A -> B <: A -> A
  checkSubtype(function1(B, A), function1(A, A));

  // Generic Function Subtypes.
  // Bound is a built in type.
  // <T extends int> void -> void <: <T extends int> void -> void
  checkSubtype(genericFunction(int), genericFunction(int));

  // <T extends String> A -> T <: <T extends String> B -> T
  checkProperSubtype(
      functionGenericReturn(String, A), functionGenericReturn(String, B));

  // <T extends double> T -> B <: <T extends double> T -> A
  checkProperSubtype(
      functionGenericArg(double, B), functionGenericArg(double, A));

  // Bound is a function type.
  // <T extends A -> B> void -> void <: <T extends A -> B> void -> void
  checkSubtype(
      genericFunction(function1(B, A)), genericFunction(function1(B, A)));

  // <T extends A -> B> A -> T <: <T extends A -> B> B -> T
  checkProperSubtype(functionGenericReturn(function1(B, A), A),
      functionGenericReturn(function1(B, A), B));

  // <T extends A -> B> T -> B <: <T extends A -> B> T -> A
  checkProperSubtype(functionGenericArg(function1(B, A), B),
      functionGenericArg(function1(B, A), A));

  // Bound is a user defined class.
  // <T extends B> void -> void <: <T extends B> void -> void
  checkSubtype(genericFunction(B), genericFunction(B));

  // <T extends B> A -> T <: <T extends B> B -> T
  checkProperSubtype(functionGenericReturn(B, A), functionGenericReturn(B, B));

  // <T extends B> T -> B <: <T extends B> T -> A
  checkProperSubtype(functionGenericArg(B, B), functionGenericArg(B, A));

  // Bound is a Future.
  // <T extends Future<B>> void -> void <: <T extends Future<B>> void -> void
  checkSubtype(genericFunction(generic1(Future, B)),
      genericFunction(generic1(Future, B)));

  // <T extends Future<B>> A -> T <: <T extends Future<B>> B -> T
  checkProperSubtype(functionGenericReturn(generic1(Future, B), A),
      functionGenericReturn(generic1(Future, B), B));

  // <T extends Future<B>> T -> B <: <T extends Future<B>> T -> A
  checkProperSubtype(functionGenericArg(generic1(Future, B), B),
      functionGenericArg(generic1(Future, B), A));

  // Bound is a FutureOr.
  // <T extends FutureOr<B>> void -> void <:
  //    <T extends FutureOr<B>> void -> void
  checkSubtype(genericFunction(futureOrOf(B)), genericFunction(futureOrOf(B)));

  // <T extends FutureOr<B>> A -> T <: <T extends FutureOr<B>> B -> T
  checkProperSubtype(functionGenericReturn(futureOrOf(B), A),
      functionGenericReturn(futureOrOf(B), B));

  // <T extends FutureOr<B>> T -> B <: <T extends FutureOr<B>> T -> A
  checkProperSubtype(functionGenericArg(futureOrOf(B), B),
      functionGenericArg(futureOrOf(B), A));

  // D <: D<B>
  checkSubtype(D, generic1(D, B));
  // D<B> <: D
  checkSubtype(generic1(D, B), D);
  // D<C> <: D<B>
  checkProperSubtype(generic1(D, C), generic1(D, B));

  // F <: E
  checkProperSubtype(F, E);
  // F <: E<A, A>
  checkProperSubtype(F, generic2(E, A, A));
  // // E<B, B> <: E<A, A>
  checkProperSubtype(generic2(E, B, B), E);
  // // E<B, B> <: E<A, A>
  checkProperSubtype(generic2(E, B, B), generic2(E, A, A));
}
