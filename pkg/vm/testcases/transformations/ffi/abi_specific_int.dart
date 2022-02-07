// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint32(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint32(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint32(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint32(),
  Abi.iosX64: Uint32(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint32(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint32(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint32(),
  Abi.macosArm64: Uint32(),
  Abi.macosX64: Uint32(),
  Abi.windowsArm64: Uint16(),
  Abi.windowsIA32: Uint16(),
  Abi.windowsX64: Uint16(),
})
class WChar extends AbiSpecificInteger {
  const WChar();
}

void main() {
  testSizeOf();
  testStoreLoad();
  testStoreLoadIndexed();
  testStruct();
  testInlineArray();
}

void testSizeOf() {
  final size = sizeOf<WChar>();
  print(size);
}

void testStoreLoad() {
  final p = noAlloc<WChar>();
  p.value = 10;
  print(p.value);
  noAlloc.free(p);
}

void testStoreLoadIndexed() {
  final p = noAlloc<WChar>(2);
  p[0] = 10;
  p[1] = 3;
  print(p[0]);
  print(p[1]);
  noAlloc.free(p);
}

class WCharStruct extends Struct {
  @WChar()
  external int a0;

  @WChar()
  external int a1;
}

void testStruct() {
  final p = noAlloc<WCharStruct>();
  p.ref.a0 = 1;
  print(p.ref.a0);
  p.ref.a0 = 2;
  print(p.ref.a0);
  noAlloc.free(p);
}

class WCharArrayStruct extends Struct {
  @Array(100)
  external Array<WChar> a0;
}

void testInlineArray() {
  final p = noAlloc<WCharArrayStruct>();
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
