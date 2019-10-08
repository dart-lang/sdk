// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:expect/expect.dart";

main(List<String> arguments) {
  for (int i = 0; i < 100; i++) {
    testStoreLoad();
    testNullReceivers();
    testNullArguments();
    testReifiedGeneric();
  }
}

testStoreLoad() {
  final p = Pointer<Int8>.allocate(count: 2);
  p.value = 10;
  Expect.equals(10, p.value);
  p[1] = 20;
  Expect.equals(20, p[1]);

  final p1 = Pointer<Double>.allocate(count: 2);
  p1.value = 10.0;
  Expect.approxEquals(10.0, p1.value);
  p1[1] = 20.0;
  Expect.approxEquals(20.0, p1[1]);
  p1.free();

  final p2 = Pointer<Pointer<Int8>>.allocate(count: 2);
  p2.value = p;
  Expect.equals(p, p2.value);
  p2[1] = p;
  Expect.equals(p, p2[1]);
  p2.free();
  p.free();

  final p3 = Pointer<Foo>.allocate();
  Foo foo = p3.ref;
  foo.a = 1;
  Expect.equals(1, foo.a);
  p3.free();
}

/// With extension methods, the receiver position can be null.
testNullReceivers() {
  Pointer<Int8> p = Pointer.allocate();

  Pointer<Int8> p4 = null;
  Expect.throws(() => Expect.equals(10, p4.value));
  Expect.throws(() => p4.value = 10);

  Pointer<Pointer<Int8>> p5 = null;
  Expect.throws(() => Expect.equals(10, p5.value));
  Expect.throws(() => p5.value = p);

  Pointer<Foo> p6 = null;
  Expect.throws(() => Expect.equals(10, p6.ref));

  p.free();
}

testNullArguments() {
  Pointer<Int8> p = Pointer.allocate();
  Expect.throws(() => p.value = null);
  p.free();
}

testReifiedGeneric() {
  final p = Pointer<Pointer<Int8>>.allocate();
  Pointer<Pointer<NativeType>> p2 = p;
  Expect.isTrue(p2.value is Pointer<Int8>);
  p.free();
}

class Foo extends Struct<Foo> {
  @Int8()
  int a;
}
