// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

import 'dart:_runtime' show typeRep;
import 'dart:async' show FutureOr;

import 'runtime_utils.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

void main() {
  // A <: dynamic
  checkProperSubtype(typeRep<A>(), typeRep<dynamic>());
  // A <: Object
  checkProperSubtype(typeRep<A>(), typeRep<Object>());
  // A <: Object
  checkProperSubtype(typeRep<A>(), typeRep<void>());

  // Null <: A
  checkProperSubtype(typeRep<Null>(), typeRep<A>());

  // FutureOr<Null> <: Future<Null>
  checkSubtype(typeRep<FutureOr<Null>>(), typeRep<Future<Null>>());
  // Future<Null> <: FutureOr<Null>
  checkSubtype(typeRep<Future<Null>>(), typeRep<FutureOr<Null>>());
  // Future<B> <: FutureOr<A>
  checkProperSubtype(typeRep<Future<B>>(), typeRep<FutureOr<A>>());
  // B <: <: FutureOr<A>
  checkProperSubtype(typeRep<B>(), typeRep<FutureOr<A>>());
  // Future<B> <: Future<A>
  checkProperSubtype(typeRep<Future<B>>(), typeRep<Future<A>>());
  // B <: A
  checkProperSubtype(typeRep<B>(), typeRep<A>());

  // A <: A
  checkSubtype(typeRep<A>(), typeRep<A>());
  // C <: B
  checkProperSubtype(typeRep<C>(), typeRep<B>());
  // C <: A
  checkProperSubtype(typeRep<C>(), typeRep<A>());

  // A -> B <: Function
  checkProperSubtype(typeRep<B Function(A)>(), typeRep<Function>());

  // A -> B <: A -> B
  checkSubtype(typeRep<B Function(A)>(), typeRep<B Function(A)>());

  // A -> B <: B -> B
  checkProperSubtype(typeRep<B Function(A)>(), typeRep<B Function(B)>());

  // A -> B <: A -> A
  checkSubtype(typeRep<B Function(A)>(), typeRep<A Function(A)>());

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
  checkSubtype(genericFunction(typeRep<B Function(A)>()),
      genericFunction(typeRep<B Function(A)>()));

  // <T extends A -> B> A -> T <: <T extends A -> B> B -> T
  checkProperSubtype(
      functionGenericReturn(typeRep<B Function(A)>(), typeRep<A>()),
      functionGenericReturn(typeRep<B Function(A)>(), typeRep<B>()));

  // <T extends A -> B> T -> B <: <T extends A -> B> T -> A
  checkProperSubtype(functionGenericArg(typeRep<B Function(A)>(), typeRep<B>()),
      functionGenericArg(typeRep<B Function(A)>(), typeRep<A>()));

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

  // D <: D<B>
  checkSubtype(typeRep<D>(), typeRep<D<B>>());
  // D<B> <: D
  checkSubtype(typeRep<D<B>>(), typeRep<D>());
  // D<C> <: D<B>
  checkSubtype(typeRep<D<C>>(), typeRep<D<B>>());

  // F <: E
  checkProperSubtype(typeRep<F>(), typeRep<E>());
  // F <: E<A, A>
  checkProperSubtype(typeRep<F>(), typeRep<E<A, A>>());
  // E<B, B> <: E
  checkProperSubtype(typeRep<E<B, B>>(), typeRep<E>());
  // // E<B, B> <: E<A, A>
  checkProperSubtype(typeRep<E<B, B>>(), typeRep<E<A, A>>());
}
