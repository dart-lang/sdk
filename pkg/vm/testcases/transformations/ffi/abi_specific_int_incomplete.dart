// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

@AbiSpecificIntegerMapping({
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint32(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint32(),
})
class Incomplete extends AbiSpecificInteger {
  const Incomplete();
}

void main() {
  testSizeOf();
  testStoreLoad();
  testStoreLoadIndexed();
  testStruct();
  testInlineArray();
}

void testSizeOf() {
  final size = sizeOf<Incomplete>();
  print(size);
}

void testStoreLoad() {
  final p = noAlloc<Incomplete>();
  p.value = 10;
  print(p.value);
  noAlloc.free(p);
}

void testStoreLoadIndexed() {
  final p = noAlloc<Incomplete>(2);
  p[0] = 10;
  p[1] = 3;
  print(p[0]);
  print(p[1]);
  noAlloc.free(p);
}

class IncompleteStruct extends Struct {
  @Incomplete()
  external int a0;

  @Incomplete()
  external int a1;
}

void testStruct() {
  final p = noAlloc<IncompleteStruct>();
  p.ref.a0 = 1;
  print(p.ref.a0);
  p.ref.a0 = 2;
  print(p.ref.a0);
  noAlloc.free(p);
}

class IncompleteArrayStruct extends Struct {
  @Array(100)
  external Array<Incomplete> a0;
}

void testInlineArray() {
  final p = noAlloc<IncompleteArrayStruct>();
  final array = p.ref.a0;
  for (int i = 0; i < 100; i++) {
    array[i] = i;
  }
  for (int i = 0; i < 100; i++) {
    print(array[i]);
  }
  noAlloc.free(p);
}

const noAlloc = _DummyAllocator();

class _DummyAllocator implements Allocator {
  const _DummyAllocator();

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    return Pointer.fromAddress(0);
  }

  @override
  void free(Pointer pointer) {}
}
