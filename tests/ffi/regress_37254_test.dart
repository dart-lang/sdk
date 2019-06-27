// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This program tests interaction with generic Pointers.
//
// Notation used in following tables:
// * static_type//dynamic_type
// * P = Pointer
// * I = Int8
// * NT = NativeType
//
// Note #1: When NNBD is landed, implicit downcasts will be static errors.
//
// Note #2: When we switch to extension methods we will _only_ use the static
//          type of the container.
//
// ===== a.store(b) ======
// Does a.store(b), where a and b have specific static and dynamic types: run
// fine, fail at compile time, or fail at runtime?
// =======================
//                  b     P<I>//P<I>   P<NT>//P<I>           P<NT>//P<NT>
// a
// P<P<I>>//P<P<I>>     1 ok         2 implicit downcast   3 implicit downcast
//                                     of argument: ok       of argument: fail
//                                                           at runtime
//
// P<P<NT>>//P<P<I>>    4 ok         5 ok                  6 fail at runtime
//
// P<P<NT>>//P<P<NT>>   7 ok         8 ok                  9 ok
//
// ====== final c = a.load() ======
// What is the (inferred) static type and runtime type of `a.load()`. Note that
// we assume extension method here: on Pointer<PointerT>> { Pointer<T> load(); }
// ================================
// a                    a.load()
//                      inferred static type*//runtime type
// P<P<I>>//P<P<I>>     P<I>//P<I>
//
// P<P<NT>>//P<P<I>>    P<NT>//P<I>
//
// P<P<NT>>//P<P<NT>>   P<NT>//P<NT>
//
// * The inferred static type when we get extension methods.
//
// ====== b = a.load() ======
// What happens when we try to assign the result of a.load() to variable b with
// a specific static type: runs fine, fails at compile time, or fails at runtime.
// ==========================
//                  b     P<I>                        P<NT>
// a
// P<P<I>>//P<P<I>>     1 ok                        2 ok
//
// P<P<NT>>//P<P<I>>    3 implicit downcast         4 ok
//                        of returnvalue: ok
//
// P<P<NT>>//P<P<NT>>   5 implicit downcast         6 ok
//                        of returnvalue: fail
//                        at runtime
//
// These are the normal Dart assignment rules.

import 'dart:ffi';

import "package:expect/expect.dart";

// ===== a.store(b) ======
// The tests follow table cells left to right, top to bottom.
void store1() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<Int8> b = allocate<Int8>();

  a.store(b);

  a.free();
  b.free();
}

void store2() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<NativeType> b =
      allocate<Int8>(); // Reified Pointer<Int8> at runtime.

  // Successful implicit downcast of argument at runtime.
  // Should succeed now, should statically be rejected when NNBD lands.
  a.store(b);

  a.free();
  b.free();
}

void store3() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  // Failing implicit downcast of argument at runtime.
  // Should fail now at runtime, should statically be rejected when NNBD lands.
  Expect.throws(() {
    a.store(b);
  });

  a.free();
  b.free();
}

void store4() {
  final Pointer<Pointer<NativeType>> a = allocate<
      Pointer<Int8>>(); // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<Int8> b = allocate<Int8>();

  a.store(b);

  a.free();
  b.free();
}

void store5() {
  final Pointer<Pointer<NativeType>> a = allocate<
      Pointer<Int8>>(); // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<NativeType> b =
      allocate<Int8>(); // Reified as Pointer<Int8> at runtime.

  a.store(b);

  a.free();
  b.free();
}

void store6() {
  final Pointer<Pointer<NativeType>> a = allocate<
      Pointer<Int8>>(); // Reified as Pointer<Pointer<Int8>> at runtime.
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  // Fails on type check of argument.
  Expect.throws(() {
    a.store(b);
  });

  a.free();
  b.free();
}

void store7() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();
  final Pointer<Int8> b = allocate<Int8>();

  a.store(b);

  a.free();
  b.free();
}

void store8() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();
  final Pointer<NativeType> b =
      allocate<Int8>(); // Reified as Pointer<Int8> at runtime.

  a.store(b);

  a.free();
  b.free();
}

void store9() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();
  final Pointer<NativeType> b = allocate<Int8>().cast<Pointer<NativeType>>();

  a.store(b);

  a.free();
  b.free();
}

// ====== b = a.load() ======
// The tests follow table cells left to right, top to bottom.
void load1() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();

  Pointer<Int8> b = a.load();
  Expect.type<Pointer<Int8>>(b);

  a.free();
}

void load2() {
  final Pointer<Pointer<Int8>> a = allocate<Pointer<Int8>>();

  Pointer<NativeType> b = a.load<Pointer<Int8>>();
  Expect.type<Pointer<Int8>>(b);

  a.free();
}

void load3() {
  final Pointer<Pointer<NativeType>> a = allocate<
      Pointer<Int8>>(); // Reified as Pointer<Pointer<Int8>> at runtime.

  Pointer<Int8> b = a.load<Pointer<NativeType>>();
  Expect.type<Pointer<Int8>>(b);

  a.free();
}

void load4() {
  final Pointer<Pointer<NativeType>> a = allocate<
      Pointer<Int8>>(); // Reified as Pointer<Pointer<Int8>> at runtime.

  // Return value runtime type is Pointer<Int8>.
  Pointer<NativeType> b = a.load();
  Expect.type<Pointer<Int8>>(b);

  a.free();
}

void load5() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();

  // Failing implicit downcast of return value at runtime.
  // Should fail now at runtime, should statically be rejected when NNBD lands.
  Expect.throws(() {
    Pointer<Int8> b = a.load<Pointer<NativeType>>();
  });

  a.free();
}

void load6() {
  final Pointer<Pointer<NativeType>> a = allocate<Pointer<NativeType>>();

  Pointer<NativeType> b = a.load();
  Expect.type<Pointer<NativeType>>(b);

  a.free();
}

void main() {
  store1();
  store2();
  store3();
  store4();
  store5();
  store6();
  store7();
  store8();
  store9();
  load1();
  load2();
  load3();
  load4();
  load5();
  load6();
}
