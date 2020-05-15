// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'dart:_runtime' show typeRep, legacyTypeRep;
import 'dart:async' show FutureOr;

import 'runtime_utils.dart'
    show
        checkSubtype,
        checkProperSubtype,
        checkMutualSubtype,
        checkSubtypeFailure;
import 'runtime_utils_nnbd.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // Top type symmetry.
  // Object? <:> dynamic
  checkMutualSubtype(typeRep<Object?>(), typeRep<dynamic>());
  // Object? <:> void
  checkMutualSubtype(typeRep<Object?>(), typeRep<void>());
  // void <:> dynamic
  checkMutualSubtype(typeRep<void>(), typeRep<dynamic>());

  // Bottom is subtype of top.
  // Never <: dynamic
  checkProperSubtype(typeRep<Never>(), typeRep<dynamic>());
  // Never <: void
  checkProperSubtype(typeRep<Never>(), typeRep<void>());
  // Never <: Object?
  checkProperSubtype(typeRep<Never>(), typeRep<Object?>());

  // Object is between top and bottom.
  // Object <: Object?
  checkSubtype(typeRep<Object>(), typeRep<Object?>());
  // Never <: Object
  checkProperSubtype(typeRep<Never>(), typeRep<Object>());

  // Null is between top and bottom.
  // Null <: Object?
  checkProperSubtype(typeRep<Null>(), typeRep<Object?>());
  // Never <: Null
  checkProperSubtype(typeRep<Never>(), typeRep<Null>());

  // Class is between Object and bottom.
  // A <: Object
  checkProperSubtype(typeRep<A>(), typeRep<dynamic>());
  // Never <: A
  checkProperSubtype(typeRep<Never>(), typeRep<A>());

  // Nullable types are a union of T and Null.
  // A <: A?
  checkProperSubtype(typeRep<A>(), typeRep<A?>());
  // Null <: A?
  checkProperSubtype(typeRep<Null>(), typeRep<A?>());
  // A? <: Object?
  checkProperSubtype(typeRep<A?>(), typeRep<Object?>());

  // Legacy types will eventually be migrated to T or T? but until then are
  // symmetric with both.
  // Object* <:> Object
  checkMutualSubtype(legacyTypeRep<Object>(), typeRep<Object>());
  // Object* <:> Object?
  checkMutualSubtype(legacyTypeRep<Object>(), typeRep<Object?>());

  // Bottom Types
  // Null <: Object*
  checkSubtype(typeRep<Null>(), legacyTypeRep<Object>());
  // Never <: Object*
  checkSubtype(typeRep<Never>(), legacyTypeRep<Object>());
  // A* <:> A
  checkMutualSubtype(legacyTypeRep<A>(), typeRep<A>());
  // A* <:> A?
  checkMutualSubtype(legacyTypeRep<A>(), typeRep<A?>());
  // A* <: Object
  checkProperSubtype(legacyTypeRep<A>(), typeRep<Object>());
  // A* <: Object?
  checkProperSubtype(legacyTypeRep<A>(), typeRep<Object?>());
  // Null <: A*
  checkProperSubtype(typeRep<Null>(), legacyTypeRep<A>());
  // Never <: A*
  checkProperSubtype(typeRep<Never>(), legacyTypeRep<A>());

  // Futures.
  // Null <: FutureOr<Object?>
  checkProperSubtype(typeRep<Null>(), typeRep<FutureOr<Object?>>());
  // Object <: FutureOr<Object?>
  checkProperSubtype(typeRep<Object>(), typeRep<FutureOr<Object?>>());
  // Object? <:> FutureOr<Object?>
  checkMutualSubtype(typeRep<Object?>(), typeRep<FutureOr<Object?>>());
  // Object <:> FutureOr<Object>
  checkMutualSubtype(typeRep<Object>(), typeRep<FutureOr<Object>>());
  // Object <: FutureOr<dynamic>
  checkProperSubtype(typeRep<Object>(), typeRep<FutureOr<dynamic>>());
  // Object <: FutureOr<void>
  checkProperSubtype(typeRep<Object>(), typeRep<FutureOr<void>>());
  // Future<Object> <: FutureOr<Object?>
  checkProperSubtype(typeRep<Future<Object>>(), typeRep<FutureOr<Object?>>());
  // Future<Object?> <: FutureOr<Object?>
  checkProperSubtype(typeRep<Future<Object?>>(), typeRep<FutureOr<Object?>>());
  // FutureOr<Never> <: Future<Never>
  checkSubtype(typeRep<FutureOr<Never>>(), typeRep<Future<Never>>());
  // Future<B> <: FutureOr<A>
  checkProperSubtype(typeRep<Future<B>>(), typeRep<FutureOr<A>>());
  // B <: <: FutureOr<A>
  checkProperSubtype(typeRep<B>(), typeRep<FutureOr<A>>());
  // Future<B> <: Future<A>
  checkProperSubtype(typeRep<Future<B>>(), typeRep<Future<A>>());

  // Interface subtypes.
  // A <: A
  checkSubtype(typeRep<A>(), typeRep<A>());
  // B <: A
  checkProperSubtype(typeRep<B>(), typeRep<A>());
  // C <: B
  checkProperSubtype(typeRep<C>(), typeRep<B>());
  // C <: A
  checkProperSubtype(typeRep<C>(), typeRep<A>());

  // Functions.
  // A -> B <: Function
  checkProperSubtype(typeRep<B Function(A)>(), typeRep<Function>());

  // A -> B <: A -> B
  checkSubtype(typeRep<B Function(A)>(), typeRep<B Function(A)>());

  // A -> B <: B -> B
  checkProperSubtype(typeRep<B Function(A)>(), typeRep<B Function(B)>());

  // A -> B <: A -> A
  checkProperSubtype(typeRep<B Function(A)>(), typeRep<A Function(A)>());

  // Generic Function Subtypes.
  // Bound is a built in type.
  // <T extends int> void -> void <: <T extends int> void -> void
  checkSubtype(
      genericFunction(typeRep<int>()), genericFunction(typeRep<int>()));

  // <T extends String> A -> T <: <T extends String> B -> T
  checkProperSubtype(functionGenericReturn(typeRep<String>(), typeRep<A>()),
      functionGenericReturn(typeRep<String>(), typeRep<B>()));

  // <T extends double> T -> B <: <T extends double> T -> A
  checkProperSubtype(functionGenericArg(typeRep<double>(), typeRep<B>()),
      functionGenericArg(typeRep<double>(), typeRep<A>()));

  // Bound is a function type.
  // <T extends A -> B> void -> void <: <T extends A -> B> void -> void
  checkSubtype(genericFunction(typeRep<A Function(B)>()),
      genericFunction(typeRep<A Function(B)>()));

  // <T extends A -> B> A -> T <: <T extends A -> B> B -> T
  checkProperSubtype(
      functionGenericReturn(typeRep<A Function(B)>(), typeRep<A>()),
      functionGenericReturn(typeRep<A Function(B)>(), typeRep<B>()));

  // <T extends A -> B> T -> B <: <T extends A -> B> T -> A
  checkProperSubtype(functionGenericArg(typeRep<A Function(B)>(), typeRep<B>()),
      functionGenericArg(typeRep<A Function(B)>(), typeRep<A>()));

  // Bound is a user defined class.
  // <T extends B> void -> void <: <T extends B> void -> void
  checkSubtype(genericFunction(typeRep<B>()), genericFunction(typeRep<B>()));

  // <T extends B> A -> T <: <T extends B> B -> T
  checkProperSubtype(functionGenericReturn(typeRep<B>(), typeRep<A>()),
      functionGenericReturn(typeRep<B>(), typeRep<B>()));

  // <T extends B> T -> B <: <T extends B> T -> A
  checkProperSubtype(functionGenericArg(typeRep<B>(), typeRep<B>()),
      functionGenericArg(typeRep<B>(), typeRep<A>()));

  // Bound is a Future.
  // <T extends Future<B>> void -> void <: <T extends Future<B>> void -> void
  checkSubtype(genericFunction(typeRep<Future<B>>()),
      genericFunction(typeRep<Future<B>>()));

  // <T extends Future<B>> A -> T <: <T extends Future<B>> B -> T
  checkProperSubtype(functionGenericReturn(typeRep<Future<B>>(), typeRep<A>()),
      functionGenericReturn(typeRep<Future<B>>(), typeRep<B>()));

  // <T extends Future<B>> T -> B <: <T extends Future<B>> T -> A
  checkProperSubtype(functionGenericArg(typeRep<Future<B>>(), typeRep<B>()),
      functionGenericArg(typeRep<Future<B>>(), typeRep<A>()));

  // Bound is a FutureOr.
  // <T extends FutureOr<B>> void -> void <:
  //    <T extends FutureOr<B>> void -> void
  checkSubtype(genericFunction(typeRep<FutureOr<B>>()),
      genericFunction(typeRep<FutureOr<B>>()));

  // <T extends FutureOr<B>> A -> T <: <T extends FutureOr<B>> B -> T
  checkProperSubtype(
      functionGenericReturn(typeRep<FutureOr<B>>(), typeRep<A>()),
      functionGenericReturn(typeRep<FutureOr<B>>(), typeRep<B>()));

  // <T extends FutureOr<B>> T -> B <: <T extends FutureOr<B>> T -> A
  checkProperSubtype(functionGenericArg(typeRep<FutureOr<B>>(), typeRep<B>()),
      functionGenericArg(typeRep<FutureOr<B>>(), typeRep<A>()));

  // Generics.
  // D <:> D<B>
  checkMutualSubtype(typeRep<D>(), typeRep<D<B>>());
  // D<C> <: D<B>
  checkProperSubtype(typeRep<D<C>>(), typeRep<D<B>>());

  // F <: E
  checkProperSubtype(typeRep<F>(), typeRep<E>());
  // F <: E<A, A>
  checkProperSubtype(typeRep<F>(), typeRep<E<A, A>>());
  // E<B, B> <: E
  checkProperSubtype(typeRep<E<B, B>>(), typeRep<E>());
  // E<B, B> <: E<A, A>
  checkProperSubtype(typeRep<E<B, B>>(), typeRep<E<A, A>>());

  // Nullable interface subtypes.
  // B <: A?
  checkProperSubtype(typeRep<B>(), typeRep<A?>());
  // C <: A?
  checkProperSubtype(typeRep<C>(), typeRep<A?>());
  // B? <: A?
  checkProperSubtype(typeRep<B?>(), typeRep<A?>());
  // C? <: A?
  checkProperSubtype(typeRep<C?>(), typeRep<A?>());

  // Mixed mode.
  // B* <: A
  checkProperSubtype(legacyTypeRep<B>(), typeRep<A>());
  // B* <: A?
  checkProperSubtype(legacyTypeRep<B>(), typeRep<A?>());
  // A* <\: B
  checkSubtypeFailure(legacyTypeRep<A>(), typeRep<B>());
  // B? <: A*
  checkProperSubtype(typeRep<B?>(), legacyTypeRep<A>());
  // B <: A*
  checkProperSubtype(typeRep<B>(), legacyTypeRep<A>());
  // A <: B*
  checkSubtypeFailure(typeRep<A>(), legacyTypeRep<B>());
  // A? <: B*
  checkSubtypeFailure(typeRep<A?>(), legacyTypeRep<B>());

  // Allowed in weak mode.
  // dynamic <\: Object
  checkSubtypeFailure(typeRep<dynamic>(), typeRep<Object>());
  // void <\: Object
  checkSubtypeFailure(typeRep<void>(), typeRep<Object>());
  // Object? <\: Object
  checkSubtypeFailure(typeRep<Object?>(), typeRep<Object>());
  // A? <\: Object
  checkSubtypeFailure(typeRep<A?>(), typeRep<Object>());
  // A? <\: A
  checkSubtypeFailure(typeRep<A?>(), typeRep<A>());
  // Null <\: Never
  checkSubtypeFailure(typeRep<Null>(), typeRep<Never>());
  // Null <\: Object
  checkSubtypeFailure(typeRep<Null>(), typeRep<Object>());
  // Null <\: A
  checkSubtypeFailure(typeRep<Null>(), typeRep<A>());
  // Null <\: FutureOr<A>
  checkSubtypeFailure(typeRep<Null>(), typeRep<FutureOr<A>>());
  // Null <\: Future<A>
  checkSubtypeFailure(typeRep<Null>(), typeRep<Future<A>>());
  // FutureOr<Null> <\: Future<Null>
  checkSubtypeFailure(typeRep<FutureOr<Null>>(), typeRep<Future<Null>>());
  // Null <\: Future<A?>
  checkSubtypeFailure(typeRep<Null>(), typeRep<Future<A?>>());
  // FutureOr<Object?> <\: Object
  checkSubtypeFailure(typeRep<FutureOr<Object?>>(), typeRep<Object>());
  // FutureOr<dynamic> <\: Object
  checkSubtypeFailure(typeRep<FutureOr<dynamic>>(), typeRep<Object>());
  // FutureOr<void> <\: Object
  checkSubtypeFailure(typeRep<FutureOr<void>>(), typeRep<Object>());
}
