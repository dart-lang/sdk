// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

main(List<String> arguments) {
  for (int i = 0; i < 100; i++) {
    testStoreLoad();
    testReifiedGeneric();
    testCompoundLoadAndStore();
  }
}

testStoreLoad() {
  final p = calloc<Int8>(2);
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

  final p1 = calloc<Double>(2);
  p1.value = 10.0;
  Expect.approxEquals(10.0, p1.value);
  p1[1] = 20.0;
  Expect.approxEquals(20.0, p1[1]);
  calloc.free(p1);

  final p2 = calloc<Pointer<Int8>>(2);
  p2.value = p;
  Expect.equals(p, p2.value);
  p2[1] = p;
  Expect.equals(p, p2[1]);
  calloc.free(p2);
  calloc.free(p);

  final p3 = calloc<Foo>();
  Foo foo = p3.ref;
  foo.a = 1;
  Expect.equals(1, foo.a);
  calloc.free(p3);

  final p4 = calloc<Foo>(2);
  Foo src = p4[1];
  src.a = 2;
  p4.ref = src;
  Foo dst = p4.ref;
  Expect.equals(2, dst.a);
  calloc.free(p4);
}

testReifiedGeneric() {
  final p = calloc<Pointer<Int8>>();
  Pointer<Pointer<NativeType>> p2 = p;
  Expect.isTrue(p2.value is Pointer<Int8>);
  calloc.free(p);
}

testCompoundLoadAndStore() {
  final foos = calloc<Foo>(10);
  final reference = foos.ref..a = 10;

  for (var i = 1; i < 9; i++) {
    foos[i] = reference;
    Expect.isTrue(foos[i].a == 10);

    foos.elementAt(i).ref = reference;
    Expect.isTrue(foos.elementAt(i).ref.a == 10);
  }

  final bars = calloc<Bar>(10);
  bars[0].foo = reference;

  for (var i = 1; i < 9; i++) {
    bars[i] = bars[0];
    Expect.isTrue(bars.elementAt(i).ref.foo.a == 10);
  }

  calloc.free(foos);
  calloc.free(bars);
}

class Foo extends Struct {
  @Int8()
  external int a;
}

class Bar extends Union {
  external Foo foo;
  @Int32()
  external int baz;
}
