// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'dart:_foreign_helper' show LEGACY_TYPE_REF, TYPE_REF;
import 'dart:async' show FutureOr;

import 'runtime_utils.dart'
    show
        checkSubtype,
        checkProperSubtype,
        checkMutualSubtype,
        checkSubtypeFailure;

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // Top type symmetry.
  // Object? <:> dynamic
  checkMutualSubtype(TYPE_REF<Object?>(), TYPE_REF<dynamic>());
  // Object? <:> void
  checkMutualSubtype(TYPE_REF<Object?>(), TYPE_REF<void>());
  // void <:> dynamic
  checkMutualSubtype(TYPE_REF<void>(), TYPE_REF<dynamic>());

  // Bottom is subtype of top.
  // Never <: dynamic
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<dynamic>());
  // Never <: void
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<void>());
  // Never <: Object?
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<Object?>());

  // Object is between top and bottom.
  // Object <: Object?
  checkSubtype(TYPE_REF<Object>(), TYPE_REF<Object?>());
  // Never <: Object
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<Object>());

  // Null is between top and bottom.
  // Null <: Object?
  checkProperSubtype(TYPE_REF<Null>(), TYPE_REF<Object?>());
  // Never <: Null
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<Null>());

  // Class is between Object and bottom.
  // A <: Object
  checkProperSubtype(TYPE_REF<A>(), TYPE_REF<dynamic>());
  // Never <: A
  checkProperSubtype(TYPE_REF<Never>(), TYPE_REF<A>());

  // Nullable types are a union of T and Null.
  // A <: A?
  checkProperSubtype(TYPE_REF<A>(), TYPE_REF<A?>());
  // Null <: A?
  checkProperSubtype(TYPE_REF<Null>(), TYPE_REF<A?>());
  // A? <: Object?
  checkProperSubtype(TYPE_REF<A?>(), TYPE_REF<Object?>());

  // Legacy types will eventually be migrated to T or T? but until then are
  // symmetric with both.
  // Object* <:> Object
  checkMutualSubtype(LEGACY_TYPE_REF<Object>(), TYPE_REF<Object>());
  // Object* <:> Object?
  checkMutualSubtype(LEGACY_TYPE_REF<Object>(), TYPE_REF<Object?>());

  // Bottom Types
  // Null <: Object*
  checkSubtype(TYPE_REF<Null>(), LEGACY_TYPE_REF<Object>());
  // Never <: Object*
  checkSubtype(TYPE_REF<Never>(), LEGACY_TYPE_REF<Object>());
  // A* <:> A
  checkMutualSubtype(LEGACY_TYPE_REF<A>(), TYPE_REF<A>());
  // A* <:> A?
  checkMutualSubtype(LEGACY_TYPE_REF<A>(), TYPE_REF<A?>());
  // A* <: Object
  checkProperSubtype(LEGACY_TYPE_REF<A>(), TYPE_REF<Object>());
  // A* <: Object?
  checkProperSubtype(LEGACY_TYPE_REF<A>(), TYPE_REF<Object?>());
  // Null <: A*
  checkProperSubtype(TYPE_REF<Null>(), LEGACY_TYPE_REF<A>());
  // Never <: A*
  checkProperSubtype(TYPE_REF<Never>(), LEGACY_TYPE_REF<A>());

  // Futures.
  // Null <: FutureOr<Object?>
  checkProperSubtype(TYPE_REF<Null>(), TYPE_REF<FutureOr<Object?>>());
  // Object <: FutureOr<Object?>
  checkProperSubtype(TYPE_REF<Object>(), TYPE_REF<FutureOr<Object?>>());
  // Object? <:> FutureOr<Object?>
  checkMutualSubtype(TYPE_REF<Object?>(), TYPE_REF<FutureOr<Object?>>());
  // Object <:> FutureOr<Object>
  checkMutualSubtype(TYPE_REF<Object>(), TYPE_REF<FutureOr<Object>>());
  // Object <: FutureOr<dynamic>
  checkProperSubtype(TYPE_REF<Object>(), TYPE_REF<FutureOr<dynamic>>());
  // Object <: FutureOr<void>
  checkProperSubtype(TYPE_REF<Object>(), TYPE_REF<FutureOr<void>>());
  // Future<Object> <: FutureOr<Object?>
  checkProperSubtype(TYPE_REF<Future<Object>>(), TYPE_REF<FutureOr<Object?>>());
  // Future<Object?> <: FutureOr<Object?>
  checkProperSubtype(
    TYPE_REF<Future<Object?>>(),
    TYPE_REF<FutureOr<Object?>>(),
  );
  // FutureOr<Never> <: Future<Never>
  checkSubtype(TYPE_REF<FutureOr<Never>>(), TYPE_REF<Future<Never>>());
  // Future<B> <: FutureOr<A>
  checkProperSubtype(TYPE_REF<Future<B>>(), TYPE_REF<FutureOr<A>>());
  // B <: <: FutureOr<A>
  checkProperSubtype(TYPE_REF<B>(), TYPE_REF<FutureOr<A>>());
  // Future<B> <: Future<A>
  checkProperSubtype(TYPE_REF<Future<B>>(), TYPE_REF<Future<A>>());

  // Interface subtypes.
  // A <: A
  checkSubtype(TYPE_REF<A>(), TYPE_REF<A>());
  // B <: A
  checkProperSubtype(TYPE_REF<B>(), TYPE_REF<A>());
  // C <: B
  checkProperSubtype(TYPE_REF<C>(), TYPE_REF<B>());
  // C <: A
  checkProperSubtype(TYPE_REF<C>(), TYPE_REF<A>());

  // Functions.
  // A -> B <: Function
  checkProperSubtype(TYPE_REF<B Function(A)>(), TYPE_REF<Function>());

  // A -> B <: A -> B
  checkSubtype(TYPE_REF<B Function(A)>(), TYPE_REF<B Function(A)>());

  // A -> B <: B -> B
  checkProperSubtype(TYPE_REF<B Function(A)>(), TYPE_REF<B Function(B)>());

  // A -> B <: A -> A
  checkProperSubtype(TYPE_REF<B Function(A)>(), TYPE_REF<A Function(A)>());

  // Generic Function Subtypes.
  // Bound is a built in type.
  // <T extends int> void -> void <: <T extends int> void -> void
  checkSubtype(
    TYPE_REF<void Function<T extends int>()>(),
    TYPE_REF<void Function<T extends int>()>(),
  );

  // <T extends String> A -> T <: <T extends String> B -> T
  checkProperSubtype(
    TYPE_REF<T Function<T extends String>(A)>(),
    TYPE_REF<T Function<T extends String>(B)>(),
  );

  // <T extends double> T -> B <: <T extends double> T -> A
  checkProperSubtype(
    TYPE_REF<B Function<T extends double>(T)>(),
    TYPE_REF<A Function<T extends double>(T)>(),
  );

  // Bound is a function type.
  // <T extends A -> B> void -> void <: <T extends A -> B> void -> void
  checkSubtype(
    TYPE_REF<void Function<T extends A Function(B)>()>(),
    TYPE_REF<void Function<T extends A Function(B)>()>(),
  );

  // <T extends A -> B> A -> T <: <T extends A -> B> B -> T
  checkProperSubtype(
    TYPE_REF<T Function<T extends A Function(B)>(A)>(),
    TYPE_REF<T Function<T extends A Function(B)>(B)>(),
  );

  // <T extends A -> B> T -> B <: <T extends A -> B> T -> A
  checkProperSubtype(
    TYPE_REF<B Function<T extends A Function(B)>(T)>(),
    TYPE_REF<A Function<T extends A Function(B)>(T)>(),
  );

  // Bound is a user defined class.
  // <T extends B> void -> void <: <T extends B> void -> void
  checkSubtype(
    TYPE_REF<void Function<T extends B>()>(),
    TYPE_REF<void Function<T extends B>()>(),
  );

  // <T extends B> A -> T <: <T extends B> B -> T
  checkProperSubtype(
    TYPE_REF<T Function<T extends B>(A)>(),
    TYPE_REF<T Function<T extends B>(B)>(),
  );

  // // <T extends B> T -> B <: <T extends B> T -> A
  checkProperSubtype(
    TYPE_REF<B Function<T extends B>(T)>(),
    TYPE_REF<A Function<T extends B>(T)>(),
  );

  // Bound is a Future.
  // <T extends Future<B>> void -> void <: <T extends Future<B>> void -> void
  checkSubtype(
    TYPE_REF<void Function<T extends Future<B>>()>(),
    TYPE_REF<void Function<T extends Future<B>>()>(),
  );

  // <T extends Future<B>> A -> T <: <T extends Future<B>> B -> T
  checkProperSubtype(
    TYPE_REF<T Function<T extends Future<B>>(A)>(),
    TYPE_REF<T Function<T extends Future<B>>(B)>(),
  );

  // <T extends Future<B>> T -> B <: <T extends Future<B>> T -> A
  checkProperSubtype(
    TYPE_REF<B Function<T extends Future<B>>(T)>(),
    TYPE_REF<A Function<T extends Future<B>>(T)>(),
  );

  // Bound is a FutureOr.
  // <T extends FutureOr<B>> void -> void <:
  //    <T extends FutureOr<B>> void -> void
  checkSubtype(
    TYPE_REF<void Function<T extends FutureOr<B>>()>(),
    TYPE_REF<void Function<T extends FutureOr<B>>()>(),
  );

  // <T extends FutureOr<B>> A -> T <: <T extends FutureOr<B>> B -> T
  checkProperSubtype(
    TYPE_REF<T Function<T extends FutureOr<B>>(A)>(),
    TYPE_REF<T Function<T extends FutureOr<B>>(B)>(),
  );

  // <T extends FutureOr<B>> T -> B <: <T extends FutureOr<B>> T -> A
  checkProperSubtype(
    TYPE_REF<B Function<T extends FutureOr<B>>(T)>(),
    TYPE_REF<A Function<T extends FutureOr<B>>(T)>(),
  );

  // Generics.
  // D <:> D<B>
  checkMutualSubtype(TYPE_REF<D>(), TYPE_REF<D<B>>());
  // D<C> <: D<B>
  checkProperSubtype(TYPE_REF<D<C>>(), TYPE_REF<D<B>>());

  // F <: E
  checkProperSubtype(TYPE_REF<F>(), TYPE_REF<E>());
  // F <: E<A, A>
  checkProperSubtype(TYPE_REF<F>(), TYPE_REF<E<A, A>>());
  // E<B, B> <: E
  checkProperSubtype(TYPE_REF<E<B, B>>(), TYPE_REF<E>());
  // E<B, B> <: E<A, A>
  checkProperSubtype(TYPE_REF<E<B, B>>(), TYPE_REF<E<A, A>>());

  // Nullable interface subtypes.
  // B <: A?
  checkProperSubtype(TYPE_REF<B>(), TYPE_REF<A?>());
  // C <: A?
  checkProperSubtype(TYPE_REF<C>(), TYPE_REF<A?>());
  // B? <: A?
  checkProperSubtype(TYPE_REF<B?>(), TYPE_REF<A?>());
  // C? <: A?
  checkProperSubtype(TYPE_REF<C?>(), TYPE_REF<A?>());

  // Mixed mode.
  // B* <: A
  checkProperSubtype(LEGACY_TYPE_REF<B>(), TYPE_REF<A>());
  // B* <: A?
  checkProperSubtype(LEGACY_TYPE_REF<B>(), TYPE_REF<A?>());
  // A* <\: B
  checkSubtypeFailure(LEGACY_TYPE_REF<A>(), TYPE_REF<B>());
  // B? <: A*
  checkProperSubtype(TYPE_REF<B?>(), LEGACY_TYPE_REF<A>());
  // B <: A*
  checkProperSubtype(TYPE_REF<B>(), LEGACY_TYPE_REF<A>());
  // A <: B*
  checkSubtypeFailure(TYPE_REF<A>(), LEGACY_TYPE_REF<B>());
  // A? <: B*
  checkSubtypeFailure(TYPE_REF<A?>(), LEGACY_TYPE_REF<B>());

  // Allowed in weak mode.
  // dynamic <\: Object
  checkSubtypeFailure(TYPE_REF<dynamic>(), TYPE_REF<Object>());
  // void <\: Object
  checkSubtypeFailure(TYPE_REF<void>(), TYPE_REF<Object>());
  // Object? <\: Object
  checkSubtypeFailure(TYPE_REF<Object?>(), TYPE_REF<Object>());
  // A? <\: Object
  checkSubtypeFailure(TYPE_REF<A?>(), TYPE_REF<Object>());
  // A? <\: A
  checkSubtypeFailure(TYPE_REF<A?>(), TYPE_REF<A>());
  // Null <\: Never
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<Never>());
  // Null <\: Object
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<Object>());
  // Null <\: A
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<A>());
  // Null <\: FutureOr<A>
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<FutureOr<A>>());
  // Null <\: Future<A>
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<Future<A>>());
  // FutureOr<Null> <\: Future<Null>
  checkSubtypeFailure(TYPE_REF<FutureOr<Null>>(), TYPE_REF<Future<Null>>());
  // Null <\: Future<A?>
  checkSubtypeFailure(TYPE_REF<Null>(), TYPE_REF<Future<A?>>());
  // FutureOr<Object?> <\: Object
  checkSubtypeFailure(TYPE_REF<FutureOr<Object?>>(), TYPE_REF<Object>());
  // FutureOr<dynamic> <\: Object
  checkSubtypeFailure(TYPE_REF<FutureOr<dynamic>>(), TYPE_REF<Object>());
  // FutureOr<void> <\: Object
  checkSubtypeFailure(TYPE_REF<FutureOr<void>>(), TYPE_REF<Object>());
}
