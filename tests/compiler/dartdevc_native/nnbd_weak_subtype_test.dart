// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'dart:async';

import 'runtime_utils.dart' show futureOrOf, voidType;
import 'runtime_utils_nnbd.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // Top type symmetry.
  // Object? <: dynamic
  // dynamic <: Object?
  checkMutualSubtype(nullable(Object), dynamic);
  // Object? <: void
  // void <: Object?
  checkMutualSubtype(nullable(Object), voidType);
  // void <: dynamic
  // dynamic <: void
  checkMutualSubtype(voidType, dynamic);

  // Bottom is subtype of top.
  // Never <: dynamic
  checkProperSubtype(Never, dynamic);
  // Never <: void
  checkProperSubtype(Never, voidType);
  // Never <: Object?
  checkProperSubtype(Never, nullable(Object));

  // Object is between top and bottom.
  // Object <: Object?
  checkSubtype(Object, nullable(Object));
  // Never <: Object
  checkProperSubtype(Never, Object);

  // Null is between top and bottom.
  // Null <: Object?
  checkProperSubtype(Null, nullable(Object));
  // Never <: Null
  checkSubtype(Never, Null);

  // Class is between Object and bottom.
  // A <: Object
  checkProperSubtype(A, dynamic);
  // Never <: A
  checkProperSubtype(Never, A);

  // Nullable types are a union of T and Null.
  // A <: A?
  checkSubtype(A, nullable(A));
  // Null <: A?
  checkProperSubtype(Null, nullable(A));
  // A? <: Object?
  checkProperSubtype(nullable(A), nullable(Object));

  // Legacy types will eventually be migrated to T or T? but until then are
  // symmetric with both.
  // Object* <: Object
  // Object <: Object*
  checkMutualSubtype(legacy(Object), Object);
  // Object* <: Object?
  // Object? <: Object*
  checkMutualSubtype(legacy(Object), nullable(Object));

  // Bottom Types
  // Null <: Object*
  checkSubtype(Null, legacy(Object));
  // Never <: Object*
  checkSubtype(Never, legacy(Object));
  // A* <: A
  // A <: A*
  checkMutualSubtype(legacy(A), A);
  // A* <: A?
  // A? <: A*
  checkMutualSubtype(legacy(A), nullable(A));
  // A* <: Object
  checkProperSubtype(legacy(A), Object);
  // A* <: Object?
  checkProperSubtype(legacy(A), nullable(Object));
  // Null <: A*
  checkProperSubtype(Null, legacy(A));
  // Never <: A*
  checkProperSubtype(Never, legacy(A));

  // Futures.
  // Null <: FutureOr<Object?>
  checkProperSubtype(Null, futureOrOf(nullable(Object)));
  // Object <: FutureOr<Object?>
  checkSubtype(Object, futureOrOf(nullable(Object)));
  // Object? <: FutureOr<Object?>
  // FutureOr<Object?> <: Object?
  checkMutualSubtype(nullable(Object), futureOrOf(nullable(Object)));
  // Object <: FutureOr<Object>
  // FutureOr<Object> <: Object
  checkMutualSubtype(Object, futureOrOf(Object));
  // Object <: FutureOr<dynamic>
  // FutureOr<dynamic> <: Object
  checkMutualSubtype(Object, futureOrOf(dynamic));
  // Object <: FutureOr<void>
  // FutureOr<void> <: Object
  checkMutualSubtype(Object, futureOrOf(voidType));
  // Future<Object> <: FutureOr<Object?>
  checkProperSubtype(generic1(Future, Object), futureOrOf(nullable(Object)));
  // Future<Object?> <: FutureOr<Object?>
  checkProperSubtype(
      generic1(Future, nullable(Object)), futureOrOf(nullable(Object)));
  // FutureOr<Never> <: Future<Never>
  checkSubtype(futureOrOf(Never), generic1(Future, Never));
  // Future<B> <: FutureOr<A>
  checkProperSubtype(generic1(Future, B), futureOrOf(A));
  // B <: <: FutureOr<A>
  checkProperSubtype(B, futureOrOf(A));
  // Future<B> <: Future<A>
  checkProperSubtype(generic1(Future, B), generic1(Future, A));

  // Interface subtypes.
  // A <: A
  checkSubtype(A, A);
  // B <: A
  checkProperSubtype(B, A);
  // C <: B
  checkProperSubtype(C, B);
  // C <: A
  checkProperSubtype(C, A);

  // Functions.
  // A -> B <: Function
  checkProperSubtype(function1(B, A), Function);

  // A -> B <: A -> B
  checkSubtype(function1(B, A), function1(B, A));

  // A -> B <: B -> B
  checkProperSubtype(function1(B, A), function1(B, B));

  // A -> B <: A -> A
  checkProperSubtype(function1(B, A), function1(A, A));

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

  // Generics.
  // D <: D<B>
  // D<B> <: D
  checkMutualSubtype(D, generic1(D, B));
  // D<C> <: D<B>
  checkProperSubtype(generic1(D, C), generic1(D, B));

  // F <: E
  checkProperSubtype(F, E);
  // F <: E<A, A>
  checkProperSubtype(F, generic2(E, A, A));
  // E<B, B> <: E<A, A>
  checkProperSubtype(generic2(E, B, B), E);
  // E<B, B> <: E<A, A>
  checkProperSubtype(generic2(E, B, B), generic2(E, A, A));

  // Nullable interface subtypes.
  // B <: A?
  checkProperSubtype(B, nullable(A));
  // C <: A?
  checkProperSubtype(C, nullable(A));
  // B? <: A?
  checkProperSubtype(nullable(B), nullable(A));
  // C? <: A?
  checkProperSubtype(nullable(C), nullable(A));

  // Mixed mode.
  // B* <: A
  checkProperSubtype(legacy(B), A);
  // B* <: A?
  checkProperSubtype(legacy(B), nullable(A));
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

  // Allowed in weak mode.
  // dynamic <: Object
  checkSubtype(dynamic, Object);
  // void <: Object
  checkSubtype(voidType, Object);
  // Object? <: Object
  checkSubtype(nullable(Object), Object);
  // A? <: Object
  checkProperSubtype(nullable(A), Object);
  // A? <: A
  checkSubtype(nullable(A), A);
  // Null <: Never
  checkSubtype(Null, Never);
  // Null <: Object
  checkProperSubtype(Null, Object);
  // Null <: A
  checkProperSubtype(Null, A);
  // Null <: FutureOr<A>
  checkProperSubtype(Null, futureOrOf(A));
  // Null <: Future<A>
  checkProperSubtype(Null, generic1(Future, A));
  // FutureOr<Null> <: Future<Null>
  checkSubtype(futureOrOf(Null), generic1(Future, Null));
  // Null <: Future<A?>
  checkProperSubtype(Null, generic1(Future, nullable(A)));
  // FutureOr<Object?> <: Object
  checkSubtype(futureOrOf(nullable(Object)), Object);
  // FutureOr<dynamic> <: Object
  checkSubtype(futureOrOf(dynamic), Object);
  // FutureOr<void> <: Object
  checkSubtype(futureOrOf(voidType), Object);
}
