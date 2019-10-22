// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'dart:_runtime' as dart;
import 'dart:async';

import 'runtime_utils.dart';
import 'runtime_utils_nnbd.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // dynamic <\: A
  checkSubtypeFailure(dynamic, A);
  // A <: dynamic
  checkProperSubtype(A, dynamic);
  // A <: void
  checkProperSubtype(A, dart.wrapType(dart.void_));
  // Null <\: A
  checkSubtypeFailure(Null, A);

  // FutureOr<Never> <: Future<Never>
  checkSubtype(generic1(FutureOr, dart.wrapType(dart.never_)),
      generic1(Future, dart.wrapType(dart.never_)));
  // Future<B> <: FutureOr<A>
  checkProperSubtype(generic1(Future, B), generic1(FutureOr, A));
  // B <: <: FutureOr<A>
  checkProperSubtype(B, generic1(FutureOr, A));
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
  checkSubtype(genericFunction(generic1(FutureOr, B)),
      genericFunction(generic1(FutureOr, B)));

  // <T extends FutureOr<B>> A -> T <: <T extends FutureOr<B>> B -> T
  checkProperSubtype(functionGenericReturn(generic1(FutureOr, B), A),
      functionGenericReturn(generic1(FutureOr, B), B));

  // <T extends FutureOr<B>> T -> B <: <T extends FutureOr<B>> T -> A
  checkProperSubtype(functionGenericArg(generic1(FutureOr, B), B),
      functionGenericArg(generic1(FutureOr, B), A));

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

  // A <: A?
  checkProperSubtype(A, nullable(A));
  // B <: A?
  checkProperSubtype(B, nullable(A));
  // C <: A?
  checkProperSubtype(C, nullable(A));
  // B? <: A?
  checkProperSubtype(nullable(B), nullable(A));
  // C? <: A?
  checkProperSubtype(nullable(C), nullable(A));

  // A <: Object
  checkProperSubtype(A, Object);
  // A* <: Object
  checkProperSubtype(legacy(A), Object);
  // dynamic <\: Object
  checkSubtypeFailure(dynamic, Object);
  // void <\: Object
  checkSubtypeFailure(dart.wrapType(dart.void_), Object);
  // Null <\: Object
  checkSubtypeFailure(Null, Object);
  // A? <\: Object
  checkSubtypeFailure(nullable(A), Object);

  // Null <: FutureOr<A?>
  checkProperSubtype(Null, generic1(FutureOr, nullable(A)));
  // Null <: Null
  checkSubtype(Null, Null);
  // Null <: A?
  checkProperSubtype(Null, nullable(A));
  // Null <: A*
  checkProperSubtype(Null, legacy(A));

  // B* <: A
  checkProperSubtype(legacy(B), A);
  // A* <\: B
  checkSubtypeFailure(legacy(A), B);

  // B? <: A*
  checkProperSubtype(nullable(B), legacy(A));
  // B <: A*
  checkProperSubtype(B, legacy(A));
  // A <: B*
  checkSubtypeFailure(A, legacy(B));
  // A? <: B*
  checkSubtypeFailure(nullable(A), legacy(B));
}
