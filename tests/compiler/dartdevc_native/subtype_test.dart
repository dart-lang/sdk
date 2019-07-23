// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;
import 'dart:async';

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class C extends B {}

class D<T extends B> {}

class E<T, S> {}

class F extends E<B, B> {}

// Returns sWrapped<tWrapped> as a wrapped type.
Object generic1(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#)', sGeneric, t));
}

// Returns sWrapped<tWrapped, rWrapped> as a wrapped type.
Object generic2(Type sWrapped, Type tWrapped, Type rWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  var r = dart.unwrapType(rWrapped);
  var sGeneric = dart.getGenericClass(s);
  return dart.wrapType(JS('', '#(#, #)', sGeneric, t, r));
}

// Returns a function type of argWrapped -> returnWrapped as a wrapped type.
Object function1(Type returnWrapped, Type argWrapped) {
  var returnType = dart.unwrapType(returnWrapped);
  var argType = dart.unwrapType(argWrapped);
  var fun = dart.fnType(returnType, [argType]);
  return dart.wrapType(fun);
}

// Returns a function type with a bounded type argument that takes no argument
// and returns void as a wrapped type.
Object genericFunction(Type boundWrapped) => dart.wrapType(dart.gFnType(
    (T) => [dart.VoidType, []], (T) => [dart.unwrapType(boundWrapped)]));

// Returns a function type with a bounded generic return type of
// <T extends typeBoud> argWrapped -> T as a wrapped type.
Object functionGenericReturn(Type boundWrapped, Type argWrapped) =>
    dart.wrapType(dart.gFnType(
        (T) => [
              T,
              [dart.unwrapType(argWrapped)]
            ],
        (T) => [dart.unwrapType(boundWrapped)]));

// Returns a function with a bounded generic argument type of
// <T extends typeBoud> T -> returnWrapped as a wrapped type.
Object functionGenericArg(Type boundWrapped, Type returnWrapped) =>
    dart.wrapType(dart.gFnType(
        (T) => [
              dart.unwrapType(returnWrapped),
              [T]
            ],
        (T) => [dart.unwrapType(boundWrapped)]));

void checkSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
}

void checkProperSubtype(Type sWrapped, Type tWrapped) {
  var s = dart.unwrapType(sWrapped);
  var t = dart.unwrapType(tWrapped);
  Expect.isTrue(dart.isSubtypeOf(s, t), '$s should be subtype of $t.');
  Expect.isFalse(dart.isSubtypeOf(t, s), '$t should not be subtype of $s.');
}

void main() {
  // A <: dynamic
  checkProperSubtype(A, dynamic);
  // A <: Object
  checkProperSubtype(A, Object);
  // TODO(nshahan) Test void as top? A <: void

  // Null <: A
  checkProperSubtype(Null, A);

  // FutureOr<Null> <: Future<Null>
  checkSubtype(generic1(FutureOr, Null), generic1(Future, Null));
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

  // <T extends B> void fn() <: <T extends B> void fn()
  checkSubtype(genericFunction(B), genericFunction(B));

  // <T extends B> T fn(A) <: <T extends B> T fn(B)
  checkProperSubtype(functionGenericReturn(B, A), functionGenericReturn(B, B));

  // <T extends B> B fn(T) <: <T extends B> A fn(T)
  checkProperSubtype(functionGenericArg(B, B), functionGenericArg(B, A));

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
