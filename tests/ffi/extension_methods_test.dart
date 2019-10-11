// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

main(List<String> arguments) {
  for (int i = 0; i < 100; i++) {
    testStoreLoad();
    testNullReceivers();
    testNullIndices();
    testNullArguments();
    testReifiedGeneric();
  }
}

testStoreLoad() {
  final p = allocate<Int8>(count: 2);
  p.value = 10;
  Expect.equals(10, p.value);
  p[1] = 20;
  Expect.equals(20, p[1]);
  if (sizeOf<IntPtr>() == 4) {
    // Test round tripping.
    Expect.equals(20, p.elementAt(0x100000001).value);
    Expect.equals(20, p[0x100000001]);
  }

  // Test negative index.
  final pUseNegative = p.elementAt(1);
  Expect.equals(10, pUseNegative[-1]);

  final p1 = allocate<Double>(count: 2);
  p1.value = 10.0;
  Expect.approxEquals(10.0, p1.value);
  p1[1] = 20.0;
  Expect.approxEquals(20.0, p1[1]);
  free(p1);

  final p2 = allocate<Pointer<Int8>>(count: 2);
  p2.value = p;
  Expect.equals(p, p2.value);
  p2[1] = p;
  Expect.equals(p, p2[1]);
  free(p2);
  free(p);

  final p3 = allocate<Foo>();
  Foo foo = p3.ref;
  foo.a = 1;
  Expect.equals(1, foo.a);
  free(p3);
}

/// With extension methods, the receiver position can be null.
testNullReceivers() {
  Pointer<Int8> p = allocate();

  Pointer<Int8> p4 = null;
  Expect.throws(() => Expect.equals(10, p4.value));
  Expect.throws(() => p4.value = 10);

  Pointer<Pointer<Int8>> p5 = null;
  Expect.throws(() => Expect.equals(10, p5.value));
  Expect.throws(() => p5.value = p);

  Pointer<Foo> p6 = null;
  Expect.throws(() => Expect.equals(10, p6.ref));

  free(p);
}

testNullIndices() {
  Pointer<Int8> p = allocate();

  Expect.throws(() => Expect.equals(10, p[null]));
  Expect.throws(() => p[null] = 10);

  Pointer<Pointer<Int8>> p5 = p.cast();
  Expect.throws(() => Expect.equals(10, p5[null]));
  Expect.throws(() => p5[null] = p);

  Pointer<Foo> p6 = p.cast();
  Expect.throws(() => Expect.equals(10, p6[null]));

  free(p);
}

testNullArguments() {
  Pointer<Int8> p = allocate();
  Expect.throws(() => p.value = null);
  free(p);
}

testReifiedGeneric() {
  final p = allocate<Pointer<Int8>>();
  Pointer<Pointer<NativeType>> p2 = p;
  Expect.isTrue(p2.value is Pointer<Int8>);
  free(p);
}

class Foo extends Struct<Foo> {
  @Int8()
  int a;
}
