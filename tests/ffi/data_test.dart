// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.

library FfiTest;

import 'dart:ffi' as ffi;

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
  testFreeZeroOut();
}

void testPointerBasic() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate();
  p.store(42);
  Expect.equals(42, p.load<int>());
  p.free();
}

void testPointerFromPointer() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate();
  p.store(1337);
  int ptr = p.address;
  ffi.Pointer<ffi.Int64> p2 = ffi.fromAddress(ptr);
  Expect.equals(1337, p2.load<int>());
  p.free();
}

void testPointerPointerArithmetic() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate(count: 2);
  ffi.Pointer<ffi.Int64> p2 = p.elementAt(1);
  p2.store(100);
  ffi.Pointer<ffi.Int64> p3 = p.offsetBy(8);
  Expect.equals(100, p3.load<int>());
  p.free();
}

void testPointerPointerArithmeticSizes() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate(count: 2);
  ffi.Pointer<ffi.Int64> p2 = p.elementAt(1);
  int addr = p.address;
  Expect.equals(addr + 8, p2.address);
  p.free();

  ffi.Pointer<ffi.Int32> p3 = ffi.allocate(count: 2);
  ffi.Pointer<ffi.Int32> p4 = p3.elementAt(1);
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
  ffi.Pointer<ffi.Int8> p;
  try {
    p = ffi.allocate<ffi.Int8>(count: 0);
  } on Exception {
    returnedNullPointer = true;
  }
  if (!returnedNullPointer) {
    p.free();
  }
}

void testPointerCast() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate();
  ffi.Pointer<ffi.Int32> p2 = p.cast(); // gets the correct type args back
  p.free();
}

void testCastGeneric() {
  ffi.Pointer<T> generic<T extends ffi.NativeType>(ffi.Pointer<ffi.Int16> p) {
    return p.cast();
  }

  ffi.Pointer<ffi.Int16> p = ffi.allocate();
  ffi.Pointer<ffi.Int64> p2 = generic(p);
  p.free();
}

void testCastGeneric2() {
  ffi.Pointer<ffi.Int64> generic<T extends ffi.NativeType>(ffi.Pointer<T> p) {
    return p.cast();
  }

  ffi.Pointer<ffi.Int16> p = ffi.allocate();
  ffi.Pointer<ffi.Int64> p2 = generic(p);
  p.free();
}

void testCastNativeType() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate();
  p.cast<ffi.Pointer>();
  p.free();
}

void testCondensedNumbersInt8() {
  ffi.Pointer<ffi.Int8> p = ffi.allocate(count: 8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p.elementAt(i).store(i * 3);
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(i * 3, p.elementAt(i).load<int>());
  }
  p.free();
}

void testCondensedNumbersFloat() {
  ffi.Pointer<ffi.Float> p = ffi.allocate(count: 8);
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    p.elementAt(i).store(1.511366173271439e-13);
  }
  for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
    Expect.equals(1.511366173271439e-13, p.elementAt(i).load<double>());
  }
  p.free();
}

void testRangeInt8() {
  ffi.Pointer<ffi.Int8> p = ffi.allocate();
  p.store(127);
  Expect.equals(127, p.load<int>());
  p.store(-128);
  Expect.equals(-128, p.load<int>());

  Expect.equals(0x0000000000000080, 128);
  Expect.equals(0xFFFFFFFFFFFFFF80, -128);
  p.store(128);
  Expect.equals(-128, p.load<int>()); // truncated and sign extended

  Expect.equals(0xFFFFFFFFFFFFFF7F, -129);
  Expect.equals(0x000000000000007F, 127);
  p.store(-129);
  Expect.equals(127, p.load<int>()); // truncated
  p.free();
}

void testRangeUint8() {
  ffi.Pointer<ffi.Uint8> p = ffi.allocate();
  p.store(255);
  Expect.equals(255, p.load<int>());
  p.store(0);
  Expect.equals(0, p.load<int>());

  Expect.equals(0x0000000000000000, 0);
  Expect.equals(0x0000000000000100, 256);
  p.store(256);
  Expect.equals(0, p.load<int>()); // truncated

  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  Expect.equals(0x00000000000000FF, 255);
  p.store(-1);
  Expect.equals(255, p.load<int>()); // truncated
  p.free();
}

void testRangeInt16() {
  ffi.Pointer<ffi.Int16> p = ffi.allocate();
  p.store(0x7FFF);
  Expect.equals(0x7FFF, p.load<int>());
  p.store(-0x8000);
  Expect.equals(-0x8000, p.load<int>());
  p.store(0x8000);
  Expect.equals(
      0xFFFFFFFFFFFF8000, p.load<int>()); // truncated and sign extended
  p.store(-0x8001);
  Expect.equals(0x7FFF, p.load<int>()); // truncated
  p.free();
}

void testRangeUint16() {
  ffi.Pointer<ffi.Uint16> p = ffi.allocate();
  p.store(0xFFFF);
  Expect.equals(0xFFFF, p.load<int>());
  p.store(0);
  Expect.equals(0, p.load<int>());
  p.store(0x10000);
  Expect.equals(0, p.load<int>()); // truncated
  p.store(-1);
  Expect.equals(0xFFFF, p.load<int>()); // truncated
  p.free();
}

void testRangeInt32() {
  ffi.Pointer<ffi.Int32> p = ffi.allocate();
  p.store(0x7FFFFFFF);
  Expect.equals(0x7FFFFFFF, p.load<int>());
  p.store(-0x80000000);
  Expect.equals(-0x80000000, p.load<int>());
  p.store(0x80000000);
  Expect.equals(
      0xFFFFFFFF80000000, p.load<int>()); // truncated and sign extended
  p.store(-0x80000001);
  Expect.equals(0x7FFFFFFF, p.load<int>()); // truncated
  p.free();
}

void testRangeUint32() {
  ffi.Pointer<ffi.Uint32> p = ffi.allocate();
  p.store(0xFFFFFFFF);
  Expect.equals(0xFFFFFFFF, p.load<int>());
  p.store(0);
  Expect.equals(0, p.load<int>());
  p.store(0x100000000);
  Expect.equals(0, p.load<int>()); // truncated
  p.store(-1);
  Expect.equals(0xFFFFFFFF, p.load<int>()); // truncated
  p.free();
}

void testRangeInt64() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate();
  p.store(0x7FFFFFFFFFFFFFFF); // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.load<int>());
  p.store(-0x8000000000000000); // -2 ^ 63
  Expect.equals(-0x8000000000000000, p.load<int>());
  p.free();
}

void testRangeUint64() {
  ffi.Pointer<ffi.Uint64> p = ffi.allocate();
  p.store(0x7FFFFFFFFFFFFFFF); // 2 ^ 63 - 1
  Expect.equals(0x7FFFFFFFFFFFFFFF, p.load<int>());
  p.store(-0x8000000000000000); // -2 ^ 63 interpreted as 2 ^ 63
  Expect.equals(-0x8000000000000000, p.load<int>());

  // Dart allows interpreting bits both signed and unsigned
  Expect.equals(0xFFFFFFFFFFFFFFFF, -1);
  p.store(-1); // -1 interpreted as 2 ^ 64 - 1
  Expect.equals(-1, p.load<int>());
  Expect.equals(0xFFFFFFFFFFFFFFFF, p.load<int>());
  p.free();
}

void testRangeIntPtr() {
  ffi.Pointer<ffi.IntPtr> p = ffi.allocate();
  int pAddr = p.address;
  p.store(pAddr); // its own address should fit
  p.store(0x7FFFFFFF); // and 32 bit addresses should fit
  Expect.equals(0x7FFFFFFF, p.load<int>());
  p.store(-0x80000000);
  Expect.equals(-0x80000000, p.load<int>());
  p.free();
}

void testFloat() {
  ffi.Pointer<ffi.Float> p = ffi.allocate();
  p.store(1.511366173271439e-13);
  Expect.equals(1.511366173271439e-13, p.load<double>());
  p.store(1.4260258159703532e-105); // float does not have enough precision
  Expect.notEquals(1.4260258159703532e-105, p.load<double>());
  p.free();
}

void testDouble() {
  ffi.Pointer<ffi.Double> p = ffi.allocate();
  p.store(1.4260258159703532e-105);
  Expect.equals(1.4260258159703532e-105, p.load<double>());
  p.free();
}

void testVoid() {
  ffi.Pointer<ffi.IntPtr> p1 = ffi.allocate();
  ffi.Pointer<ffi.Void> p2 = p1.cast(); // make this dart pointer opaque
  p2.address; // we can print the address
  p2.free();
}

void testPointerPointer() {
  ffi.Pointer<ffi.Int16> p = ffi.allocate();
  p.store(17);
  ffi.Pointer<ffi.Pointer<ffi.Int16>> p2 = ffi.allocate();
  p2.store(p);
  Expect.equals(17, p2.load<ffi.Pointer<ffi.Int16>>().load<int>());
  p2.free();
  p.free();
}

void testPointerPointerNull() {
  ffi.Pointer<ffi.Pointer<ffi.Int8>> pointerToPointer = ffi.allocate();
  ffi.Pointer<ffi.Int8> value = null;
  pointerToPointer.store(value);
  value = pointerToPointer.load();
  Expect.isNull(value);
  value = ffi.allocate();
  pointerToPointer.store(value);
  value = pointerToPointer.load();
  Expect.isNotNull(value);
  value.free();
  value = null;
  pointerToPointer.store(value);
  value = pointerToPointer.load();
  Expect.isNull(value);
  pointerToPointer.free();
}

void testPointerStoreNull() {
  int i = null;
  ffi.Pointer<ffi.Int8> p = ffi.allocate();
  Expect.throws(() => p.store(i));
  p.free();
  double d = null;
  ffi.Pointer<ffi.Float> p2 = ffi.allocate();
  Expect.throws(() => p2.store(d));
  p2.free();
}

void testSizeOf() {
  Expect.equals(1, ffi.sizeOf<ffi.Int8>());
  Expect.equals(2, ffi.sizeOf<ffi.Int16>());
  Expect.equals(4, ffi.sizeOf<ffi.Int32>());
  Expect.equals(8, ffi.sizeOf<ffi.Int64>());
  Expect.equals(1, ffi.sizeOf<ffi.Uint8>());
  Expect.equals(2, ffi.sizeOf<ffi.Uint16>());
  Expect.equals(4, ffi.sizeOf<ffi.Uint32>());
  Expect.equals(8, ffi.sizeOf<ffi.Uint64>());
  Expect.equals(
      true, 4 == ffi.sizeOf<ffi.IntPtr>() || 8 == ffi.sizeOf<ffi.IntPtr>());
  Expect.equals(4, ffi.sizeOf<ffi.Float>());
  Expect.equals(8, ffi.sizeOf<ffi.Double>());
}

// note: stack overflows at around 15k calls
void testPointerChain(int length) {
  void createChain(ffi.Pointer<ffi.IntPtr> head, int length, int value) {
    if (length == 0) {
      head.store(value);
      return;
    }
    ffi.Pointer<ffi.IntPtr> next = ffi.allocate();
    head.store(next.address);
    createChain(next, length - 1, value);
  }

  int getChainValue(ffi.Pointer<ffi.IntPtr> head, int length) {
    if (length == 0) {
      return head.load();
    }
    ffi.Pointer<ffi.IntPtr> next = ffi.fromAddress(head.load());
    return getChainValue(next, length - 1);
  }

  void freeChain(ffi.Pointer<ffi.IntPtr> head, int length) {
    ffi.Pointer<ffi.IntPtr> next = ffi.fromAddress(head.load());
    head.free();
    if (length == 0) {
      return;
    }
    freeChain(next, length - 1);
  }

  ffi.Pointer<ffi.IntPtr> head = ffi.allocate();
  createChain(head, length, 512);
  int tailValue = getChainValue(head, length);
  Expect.equals(512, tailValue);
  freeChain(head, length);
}

void testTypeTest() {
  ffi.Pointer<ffi.Int8> p = ffi.allocate();
  Expect.isTrue(p is ffi.Pointer);
  p.free();
}

void testToString() {
  ffi.Pointer<ffi.Int16> p = ffi.allocate();
  Expect.stringEquals(
      "Pointer<Int16>: address=0x", p.toString().substring(0, 26));
  p.free();
  ffi.Pointer<ffi.Int64> p2 = ffi.fromAddress(0x123abc);
  Expect.stringEquals("Pointer<Int64>: address=0x123abc", p2.toString());
}

void testEquality() {
  ffi.Pointer<ffi.Int8> p = ffi.fromAddress(12345678);
  ffi.Pointer<ffi.Int8> p2 = ffi.fromAddress(12345678);
  Expect.equals(p, p2);
  Expect.equals(p.hashCode, p2.hashCode);
  ffi.Pointer<ffi.Int16> p3 = p.cast();
  Expect.equals(p, p3);
  Expect.equals(p.hashCode, p3.hashCode);
  Expect.notEquals(p, null);
  Expect.notEquals(null, p);
  ffi.Pointer<ffi.Int8> p4 = p.offsetBy(1337);
  Expect.notEquals(p, p4);
}

typedef Int8UnOp = ffi.Int8 Function(ffi.Int8);

void testAllocateGeneric() {
  ffi.Pointer<T> generic<T extends ffi.NativeType>() {
    ffi.Pointer<T> pointer;
    pointer = ffi.allocate();
    return pointer;
  }

  ffi.Pointer p = generic<ffi.Int64>();
  p.free();
}

void testAllocateVoid() {
  Expect.throws(() {
    ffi.Pointer<ffi.Void> p = ffi.allocate();
  });
}

void testAllocateNativeFunction() {
  Expect.throws(() {
    ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.allocate();
  });
}

void testAllocateNativeType() {
  Expect.throws(() {
    ffi.allocate();
  });
}

void testSizeOfGeneric() {
  int generic<T extends ffi.Pointer>() {
    int size;
    size = ffi.sizeOf<T>();
    return size;
  }

  int size = generic<ffi.Pointer<ffi.Int64>>();
  Expect.isTrue(size == 8 || size == 4);
}

void testSizeOfVoid() {
  Expect.throws(() {
    ffi.sizeOf<ffi.Void>();
  });
}

void testSizeOfNativeFunction() {
  Expect.throws(() {
    ffi.sizeOf<ffi.NativeFunction<Int8UnOp>>();
  });
}

void testSizeOfNativeType() {
  Expect.throws(() {
    ffi.sizeOf();
  });
}

void testFreeZeroOut() {
  // at least one of these pointers should have address != 0 on all platforms
  ffi.Pointer<ffi.Int8> p1 = ffi.allocate();
  ffi.Pointer<ffi.Int8> p2 = ffi.allocate();
  Expect.notEquals(0, p1.address & p2.address);
  p1.free();
  p2.free();
  Expect.equals(0, p1.address);
  Expect.equals(0, p2.address);
}
