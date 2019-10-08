// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.

library FfiTest;

import 'dart:ffi';

import "package:expect/expect.dart";

void main() {
  testPointerBasic();
  testPointerFromPointer();
  testPointerPointerArithmetic();
  testPointerPointerArithmeticSizes();
  testPointerAllocateZero();
  testPointerCast();
  testCastGeneric();
  testCastGeneric2();
  testCastNativeType();
  testCondensedNumbersInt8();
  testCondensedNumbersFloat();
  testRangeInt8();
  testRangeUint8();
  testRangeInt16();
  testRangeUint16();
  testRangeInt32();
  testRangeUint32();
  testRangeInt64();
  testRangeUint64();
  testRangeIntPtr();
  testFloat();
  testDouble();
  testVoid();
  testPointerPointer();
  testPointerPointerNull();
  testPointerStoreNull();
  testSizeOf();
  testPointerChain(100);
  testTypeTest();
  testToString();
  testEquality();
  testAllocateGeneric();
  testAllocateVoid();
  testAllocateNativeFunction();
  testAllocateNativeType();
  testSizeOfGeneric();
  testSizeOfVoid();
  testSizeOfNativeFunction();
  testSizeOfNativeType();
  testDynamicInvocation();
}

void testPointerBasic() {
  Pointer<Int64> p = Pointer.allocate();
  p.value = 42;
  Expect.equals(42, p.value);
  p.free();
}

void testPointerFromPointer() {
  Pointer<Int64> p = Pointer.allocate();
  p.value = 1337;
  int ptr = p.address;
  Pointer<Int64> p2 = Pointer.fromAddress(ptr);
  Expect.equals(1337, p2.value);
  p.free();
}

void testPointerPointerArithmetic() {
  Pointer<Int64> p = Pointer.allocate(count: 2);
  Pointer<Int64> p2 = p.elementAt(1);
  p2.value = 100;
  Pointer<Int64> p3 = p.offsetBy(8);
  Expect.equals(100, p3.value);
  p.free();
}

void testPointerPointerArithmeticSizes() {
  Pointer<Int64> p = Pointer.allocate(count: 2);
  Pointer<Int64> p2 = p.elementAt(1);
  int addr = p.address;
  Expect.equals(addr + 8, p2.address);
  p.free();

  Pointer<Int32> p3 = Pointer.allocate(count: 2);
  Pointer<Int32> p4 = p3.elementAt(1);
  addr = p3.address;
  Expect.equals(addr + 4, p4.address);
  p3.free();
}

void testPointerAllocateZero() {
  // > If size is 0, either a null pointer or a unique pointer that can be
  // > successfully passed to free() shall be returned.
  // http://pubs.opengroup.org/onlinepubs/009695399/functions/malloc.html
  //
  // Null pointer throws a Dart exception.
  bool returnedNullPointer = false;
  Pointer<Int8> p;
  try {
    p = Pointer<Int8>.allocate(count: 0);
  } on Exception {
    returnedNullPointer = true;
  }
  if (!returnedNullPointer) {
    p.free();
  }
}

void testPointerCast() {
  Pointer<Int64> p = Pointer.allocate();
  Pointer<Int32> p2 = p.cast(); // gets the correct type args back
  p.free();
}

void testCastGeneric() {
  Pointer<T> generic<T extends NativeType>(Pointer<Int16> p) {
    return p.cast();
  }

  Pointer<Int16> p = Pointer.allocate();
  Pointer<Int64> p2 = generic(p);
  p.free();
}

void testCastGeneric2() {
  Pointer<Int64> generic<T extends NativeType>(Pointer<T> p) {
    return p.cast();
  }

  Pointer<Int16> p = Pointer.allocate();
  Pointer<Int64> p2 = generic(p);
  p.free();
}

void testCastNativeType() {
  Pointer<Int64> p = Pointer.allocate();
  p.cast<Pointer>();
  p.free();
}

void testCondensedNumbersInt8() {
  Pointer<Int8> p = Pointer.allocate(count: 8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p[i] = i * 3;
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(i * 3, p[i]);
  }
  p.free();
}

void testCondensedNumbersFloat() {
  Pointer<Float> p = Pointer.allocate(count: 8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p[i] = 1.511366173271439e-13;
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(1.511366173271439e-13, p[i]);
  }
  p.free();
}

void testRangeInt8() {
  Pointer<Int8> p = Pointer.allocate();
  p.value = 127;
  Expect.equals(127, p.value);
  p.value = -128;
  Expect.equals(-128, p.value);

  Expect.equals(0x0000000000000080, 128);
  Expect.equals(0xFFFFFFFFFFFFFF80, -128);
  p.value = 128;
  Expect.equals(-128, p.value); // truncated and sign extended

  Expect.equals(0xFFFFFFFFFFFFFF7F, -129);
  Expect.equals(0x000000000000007F, 127);
  p.value = -129;
  Expect.equals(127, p.value); // truncated
  p.free();
}

void testRangeUint8() {
  Pointer<Uint8> p = Pointer.allocate();
  p.value = 255;
  Expect.equals(255, p.value);
  p.value = 0;
  Expect.equals(0, p.value);

  Expect.equals(0x0000000000000000, 0);
  Expect.equals(0x0000000000000100, 256);
  p.value = 256;
  Expect.equals(0, p.value); // truncated

  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  Expect.equals(0x00000000000000FF, 255);
  p.value = -1;
  Expect.equals(255, p.value); // truncated
  p.free();
}

void testRangeInt16() {
  Pointer<Int16> p = Pointer.allocate();
  p.value = 0x7FFF;
  Expect.equals(0x7FFF, p.value);
  p.value = -0x8000;
  Expect.equals(-0x8000, p.value);
  p.value = 0x8000;
  Expect.equals(0xFFFFFFFFFFFF8000, p.value); // truncated and sign extended
  p.value = -0x8001;
  Expect.equals(0x7FFF, p.value); // truncated
  p.free();
}

void testRangeUint16() {
  Pointer<Uint16> p = Pointer.allocate();
  p.value = 0xFFFF;
  Expect.equals(0xFFFF, p.value);
  p.value = 0;
  Expect.equals(0, p.value);
  p.value = 0x10000;
  Expect.equals(0, p.value); // truncated
  p.value = -1;
  Expect.equals(0xFFFF, p.value); // truncated
  p.free();
}

void testRangeInt32() {
  Pointer<Int32> p = Pointer.allocate();
  p.value = 0x7FFFFFFF;
  Expect.equals(0x7FFFFFFF, p.value);
  p.value = -0x80000000;
  Expect.equals(-0x80000000, p.value);
  p.value = 0x80000000;
  Expect.equals(0xFFFFFFFF80000000, p.value); // truncated and sign extended
  p.value = -0x80000001;
  Expect.equals(0x7FFFFFFF, p.value); // truncated
  p.free();
}

void testRangeUint32() {
  Pointer<Uint32> p = Pointer.allocate();
  p.value = 0xFFFFFFFF;
  Expect.equals(0xFFFFFFFF, p.value);
  p.value = 0;
  Expect.equals(0, p.value);
  p.value = 0x100000000;
  Expect.equals(0, p.value); // truncated
  p.value = -1;
  Expect.equals(0xFFFFFFFF, p.value); // truncated
  p.free();
}

void testRangeInt64() {
  Pointer<Int64> p = Pointer.allocate();
  p.value = 0x7FFFFFFFFFFFFFFF; // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.value);
  p.value = -0x8000000000000000; // -2 ^ 63
  Expect.equals(-0x8000000000000000, p.value);
  p.free();
}

void testRangeUint64() {
  Pointer<Uint64> p = Pointer.allocate();
  p.value = 0x7FFFFFFFFFFFFFFF; // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.value);
  p.value = -0x8000000000000000; // -2 ^ 63 interpreted as 2 ^ 63
  Expect.equals(-0x8000000000000000, p.value);

  // Dart allows interpreting bits both signed and unsigned
  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  p.value = -1; // -1 interpreted as 2 ^ 64 - 1
  Expect.equals(-1, p.value);
  Expect.equals(0xFFFFFFFFFFFFFFFF, p.value);
  p.free();
}

void testRangeIntPtr() {
  Pointer<IntPtr> p = Pointer.allocate();
  int pAddr = p.address;
  p.value = pAddr; // its own address should fit
  p.value = 0x7FFFFFFF; // and 32 bit addresses should fit
  Expect.equals(0x7FFFFFFF, p.value);
  p.value = -0x80000000;
  Expect.equals(-0x80000000, p.value);
  p.free();
}

void testFloat() {
  Pointer<Float> p = Pointer.allocate();
  p.value = 1.511366173271439e-13;
  Expect.equals(1.511366173271439e-13, p.value);
  p.value = 1.4260258159703532e-105; // float does not have enough precision
  Expect.notEquals(1.4260258159703532e-105, p.value);
  p.free();
}

void testDouble() {
  Pointer<Double> p = Pointer.allocate();
  p.value = 1.4260258159703532e-105;
  Expect.equals(1.4260258159703532e-105, p.value);
  p.free();
}

void testVoid() {
  Pointer<IntPtr> p1 = Pointer.allocate();
  Pointer<Void> p2 = p1.cast(); // make this dart pointer opaque
  p2.address; // we can print the address
  p2.free();
}

void testPointerPointer() {
  Pointer<Int16> p = Pointer.allocate();
  p.value = 17;
  Pointer<Pointer<Int16>> p2 = Pointer.allocate();
  p2.value = p;
  Expect.equals(17, p2.value.value);
  p2.free();
  p.free();
}

void testPointerPointerNull() {
  Pointer<Pointer<Int8>> pointerToPointer = Pointer.allocate();
  Pointer<Int8> value = nullptr.cast();
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.equals(value, nullptr);
  value = Pointer.allocate();
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.isNotNull(value);
  value.free();
  value = nullptr.cast();
  pointerToPointer.value = value;
  value = pointerToPointer.value;
  Expect.equals(value, nullptr);
  pointerToPointer.free();
}

void testPointerStoreNull() {
  int i = null;
  Pointer<Int8> p = Pointer.allocate();
  Expect.throws(() => p.value = i);
  p.free();
  double d = null;
  Pointer<Float> p2 = Pointer.allocate();
  Expect.throws(() => p2.value = d);
  p2.free();
  Pointer<Void> x = null;
  Pointer<Pointer<Void>> p3 = Pointer.allocate();
  Expect.throws(() => p3.value = x);
  p3.free();
}

void testSizeOf() {
  Expect.equals(1, sizeOf<Int8>());
  Expect.equals(2, sizeOf<Int16>());
  Expect.equals(4, sizeOf<Int32>());
  Expect.equals(8, sizeOf<Int64>());
  Expect.equals(1, sizeOf<Uint8>());
  Expect.equals(2, sizeOf<Uint16>());
  Expect.equals(4, sizeOf<Uint32>());
  Expect.equals(8, sizeOf<Uint64>());
  Expect.equals(true, 4 == sizeOf<IntPtr>() || 8 == sizeOf<IntPtr>());
  Expect.equals(4, sizeOf<Float>());
  Expect.equals(8, sizeOf<Double>());
}

// note: stack overflows at around 15k calls
void testPointerChain(int length) {
  void createChain(Pointer<IntPtr> head, int length, int value) {
    if (length == 0) {
      head.value = value;
      return;
    }
    Pointer<IntPtr> next = Pointer.allocate();
    head.value = next.address;
    createChain(next, length - 1, value);
  }

  int getChainValue(Pointer<IntPtr> head, int length) {
    if (length == 0) {
      return head.value;
    }
    Pointer<IntPtr> next = Pointer.fromAddress(head.value);
    return getChainValue(next, length - 1);
  }

  void freeChain(Pointer<IntPtr> head, int length) {
    Pointer<IntPtr> next = Pointer.fromAddress(head.value);
    head.free();
    if (length == 0) {
      return;
    }
    freeChain(next, length - 1);
  }

  Pointer<IntPtr> head = Pointer.allocate();
  createChain(head, length, 512);
  int tailValue = getChainValue(head, length);
  Expect.equals(512, tailValue);
  freeChain(head, length);
}

void testTypeTest() {
  Pointer<Int8> p = Pointer.allocate();
  Expect.isTrue(p is Pointer);
  p.free();
}

void testToString() {
  Pointer<Int16> p = Pointer.allocate();
  Expect.stringEquals(
      "Pointer<Int16>: address=0x", p.toString().substring(0, 26));
  p.free();
  Pointer<Int64> p2 = Pointer.fromAddress(0x123abc);
  Expect.stringEquals("Pointer<Int64>: address=0x123abc", p2.toString());
}

void testEquality() {
  Pointer<Int8> p = Pointer.fromAddress(12345678);
  Pointer<Int8> p2 = Pointer.fromAddress(12345678);
  Expect.equals(p, p2);
  Expect.equals(p.hashCode, p2.hashCode);
  Pointer<Int16> p3 = p.cast();
  Expect.equals(p, p3);
  Expect.equals(p.hashCode, p3.hashCode);
  Expect.notEquals(p, null);
  Expect.notEquals(null, p);
  Pointer<Int8> p4 = p.offsetBy(1337);
  Expect.notEquals(p, p4);
}

typedef Int8UnOp = Int8 Function(Int8);

void testAllocateGeneric() {
  Pointer<T> generic<T extends NativeType>() {
    Pointer<T> pointer;
    pointer = Pointer.allocate();
    return pointer;
  }

  Pointer p = generic<Int64>();
  p.free();
}

void testAllocateVoid() {
  Expect.throws(() {
    Pointer<Void> p = Pointer.allocate();
  });
}

void testAllocateNativeFunction() {
  Expect.throws(() {
    Pointer<NativeFunction<Int8UnOp>> p = Pointer.allocate();
  });
}

void testAllocateNativeType() {
  Expect.throws(() {
    Pointer.allocate();
  });
}

void testSizeOfGeneric() {
  int generic<T extends Pointer>() {
    int size;
    size = sizeOf<T>();
    return size;
  }

  int size = generic<Pointer<Int64>>();
  Expect.isTrue(size == 8 || size == 4);
}

void testSizeOfVoid() {
  Expect.throws(() {
    sizeOf<Void>();
  });
}

void testSizeOfNativeFunction() {
  Expect.throws(() {
    sizeOf<NativeFunction<Int8UnOp>>();
  });
}

void testSizeOfNativeType() {
  Expect.throws(() {
    sizeOf();
  });
}

void testDynamicInvocation() {
  dynamic p = Pointer<Int8>.allocate();
  Expect.throws(() {
    final int i = p.value;
  });
  Expect.throws(() => p.value = 1);
  p.elementAt(5); // Works, but is slow.
  final int addr = p.address;
  final Pointer<Int16> p2 = p.cast<Int16>();
  p.free();
}
