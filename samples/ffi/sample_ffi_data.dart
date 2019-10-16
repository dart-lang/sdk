// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';

main(List<String> arguments) {
  print('start main');

  {
    // basic operation: allocate, get, set, and free
    Pointer<Int64> p = allocate();
    p.value = 42;
    int pValue = p.value;
    print('${p.runtimeType} value: ${pValue}');
    free(p);
  }

  {
    // undefined behavior before set
    Pointer<Int64> p = allocate();
    int pValue = p.value;
    print('If not set, returns garbage: ${pValue}');
    free(p);
  }

  {
    // pointers can be created from an address
    Pointer<Int64> pHelper = allocate();
    pHelper.value = 1337;

    int address = pHelper.address;
    print('Address: ${address}');

    Pointer<Int64> p = Pointer.fromAddress(address);
    print('${p.runtimeType} value: ${p.value}');

    free(pHelper);
  }

  {
    // address is zeroed out after free
    Pointer<Int64> p = allocate();
    free(p);
    print('After free, address is zero: ${p.address}');
  }

  {
    // allocating too much throws an exception
    try {
      int maxMint = 9223372036854775807; // 2^63 - 1
      allocate<Int64>(count: maxMint);
    } on RangeError {
      print('Expected exception on allocating too much');
    }
    try {
      int maxInt1_8 = 1152921504606846975; // 2^60 -1
      allocate<Int64>(count: maxInt1_8);
    } on ArgumentError {
      print('Expected exception on allocating too much');
    }
  }

  {
    // pointers can be cast into another type
    // resulting in the corresponding bits read
    Pointer<Int64> p1 = allocate();
    p1.value = 9223372036854775807; // 2^63 - 1

    Pointer<Int32> p2 = p1.cast();
    print('${p2.runtimeType} value: ${p2.value}'); // -1

    Pointer<Int32> p3 = p2.elementAt(1);
    print('${p3.runtimeType} value: ${p3.value}'); // 2^31 - 1

    free(p1);
  }

  {
    // data can be tightly packed in memory
    Pointer<Int8> p = allocate(count: 8);
    for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
      p.elementAt(i).value = i * 3;
    }
    for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
      print('p.elementAt($i) value: ${p.elementAt(i).value}');
    }
    free(p);
  }

  {
    // exception on storing a value that does not fit
    Pointer<Int32> p11 = allocate();

    try {
      p11.value = 9223372036854775807;
    } on ArgumentError {
      print('Expected exception on calling set with a value that does not fit');
    }

    free(p11);
  }

  {
    // doubles
    Pointer<Double> p = allocate();
    p.value = 3.14159265359;
    print('${p.runtimeType} value: ${p.value}');
    p.value = 3.14;
    print('${p.runtimeType} value: ${p.value}');
    free(p);
  }

  {
    // floats
    Pointer<Float> p = allocate();
    p.value = 3.14159265359;
    print('${p.runtimeType} value: ${p.value}');
    p.value = 3.14;
    print('${p.runtimeType} value: ${p.value}');
    free(p);
  }

  {
    // IntPtr varies in size based on whether the platform is 32 or 64 bit
    // addresses of pointers fit in this size
    Pointer<IntPtr> p = allocate();
    int p14addr = p.address;
    p.value = p14addr;
    int pValue = p.value;
    print('${p.runtimeType} value: ${pValue}');
    free(p);
  }

  {
    // void pointers are unsized
    // the size of the element it is pointing to is undefined
    // this means they cannot be allocated, read, or written
    // this would would fail to compile:
    // allocate<Void>();

    Pointer<IntPtr> p1 = allocate();
    Pointer<Void> p2 = p1.cast();
    print('${p2.runtimeType} address: ${p2.address}');

    // this fails to compile, we cannot read something unsized
    // p2.load<int>();

    // this fails to compile, we cannot write something unsized
    // p2.store(1234);

    free(p1);
  }

  {
    // pointer to a pointer to something
    Pointer<Int16> pHelper = allocate();
    pHelper.value = 17;

    Pointer<Pointer<Int16>> p = allocate();

    // storing into a pointer pointer automatically unboxes
    p.value = pHelper;

    // reading from a pointer pointer automatically boxes
    Pointer<Int16> pHelper2 = p.value;
    print('${pHelper2.runtimeType} value: ${pHelper2.value}');

    int pValue = p.value.value;
    print('${p.runtimeType} value\'s value: ${pValue}');

    free(p);
    free(pHelper);
  }

  {
    // the pointer to pointer types must match up
    Pointer<Int8> pHelper = allocate();
    pHelper.value = 123;

    Pointer<Pointer<Int16>> p = allocate();

    // this fails to compile due to type mismatch
    // p.store(pHelper);

    free(pHelper);
    free(p);
  }

  {
    // null pointer in Dart points to address 0 in c++
    Pointer<Pointer<Int8>> pointerToPointer = allocate();
    Pointer<Int8> value = null;
    pointerToPointer.value = value;
    value = pointerToPointer.value;
    print("Loading a pointer to the 0 address is null: ${value}");
    free(pointerToPointer);
  }

  {
    // sizeof returns element size in bytes
    print('sizeOf<Double>(): ${sizeOf<Double>()}');
    print('sizeOf<Int16>(): ${sizeOf<Int16>()}');
    print('sizeOf<IntPtr>(): ${sizeOf<IntPtr>()}');
  }

  {
    // only concrete sub types of NativeType can be allocated
    // this would fail to compile:
    // allocate();
  }

  {
    // only concrete sub types of NativeType can be asked for size
    // this would fail to compile:
    // sizeOf();
  }

  {
    // with IntPtr pointers, one can manually setup aribtrary data
    // structres in C memory.

    void createChain(Pointer<IntPtr> head, int length, int value) {
      if (length == 0) {
        head.value = value;
        return;
      }
      Pointer<IntPtr> next = allocate<IntPtr>();
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
      free(head);
      if (length == 0) {
        return;
      }
      freeChain(next, length - 1);
    }

    int length = 10;
    Pointer<IntPtr> head = allocate();
    createChain(head, length, 512);
    int tailValue = getChainValue(head, length);
    print('tailValue: ${tailValue}');
    freeChain(head, length);
  }

  print("end main");
}
