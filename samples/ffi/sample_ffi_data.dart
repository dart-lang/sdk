// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';
import 'package:ffi/ffi.dart';

main() {
  print('start main');

  {
    // Basic operation: allocate, get, set, and free.
    Pointer<Int64> p = allocate();
    p.value = 42;
    int pValue = p.value;
    print('${p.runtimeType} value: ${pValue}');
    free(p);
  }

  {
    // Undefined behavior before set.
    Pointer<Int64> p = allocate();
    int pValue = p.value;
    print('If not set, returns garbage: ${pValue}');
    free(p);
  }

  {
    // Pointers can be created from an address.
    Pointer<Int64> pHelper = allocate();
    pHelper.value = 1337;

    int address = pHelper.address;
    print('Address: ${address}');

    Pointer<Int64> p = Pointer.fromAddress(address);
    print('${p.runtimeType} value: ${p.value}');

    free(pHelper);
  }

  {
    // Address is zeroed out after free.
    Pointer<Int64> p = allocate();
    free(p);
    print('After free, address is zero: ${p.address}');
  }

  {
    // Allocating too much throws an exception.
    try {
      int maxMint = 9223372036854775807; // 2^63 - 1
      allocate<Int64>(count: maxMint);
    } on Error {
      print('Expected exception on allocating too much');
    }
    try {
      int maxInt1_8 = 1152921504606846975; // 2^60 -1
      allocate<Int64>(count: maxInt1_8);
    } on Error {
      print('Expected exception on allocating too much');
    }
  }

  {
    // Pointers can be cast into another type,
    // resulting in the corresponding bits read.
    Pointer<Int64> p1 = allocate();
    p1.value = 9223372036854775807; // 2^63 - 1

    Pointer<Int32> p2 = p1.cast();
    print('${p2.runtimeType} value: ${p2.value}'); // -1

    Pointer<Int32> p3 = p2.elementAt(1);
    print('${p3.runtimeType} value: ${p3.value}'); // 2^31 - 1

    free(p1);
  }

  {
    // Data can be tightly packed in memory.
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
    // Values that don't fit are truncated.
    Pointer<Int32> p11 = allocate();

    p11.value = 9223372036854775807;

    print(p11);

    free(p11);
  }

  {
    // Doubles.
    Pointer<Double> p = allocate();
    p.value = 3.14159265359;
    print('${p.runtimeType} value: ${p.value}');
    p.value = 3.14;
    print('${p.runtimeType} value: ${p.value}');
    free(p);
  }

  {
    // Floats.
    Pointer<Float> p = allocate();
    p.value = 3.14159265359;
    print('${p.runtimeType} value: ${p.value}');
    p.value = 3.14;
    print('${p.runtimeType} value: ${p.value}');
    free(p);
  }

  {
    // IntPtr varies in size based on whether the platform is 32 or 64 bit.
    // Addresses of pointers fit in this size.
    Pointer<IntPtr> p = allocate();
    int p14addr = p.address;
    p.value = p14addr;
    int pValue = p.value;
    print('${p.runtimeType} value: ${pValue}');
    free(p);
  }

  {
    // Void pointers are unsized.
    // The size of the element it is pointing to is undefined,
    // they cannot be allocated, read, or written.

    Pointer<IntPtr> p1 = allocate();
    Pointer<Void> p2 = p1.cast();
    print('${p2.runtimeType} address: ${p2.address}');

    free(p1);
  }

  {
    // Pointer to a pointer to something.
    Pointer<Int16> pHelper = allocate();
    pHelper.value = 17;

    Pointer<Pointer<Int16>> p = allocate();

    // Storing into a pointer pointer automatically unboxes.
    p.value = pHelper;

    // Reading from a pointer pointer automatically boxes.
    Pointer<Int16> pHelper2 = p.value;
    print('${pHelper2.runtimeType} value: ${pHelper2.value}');

    int pValue = p.value.value;
    print('${p.runtimeType} value\'s value: ${pValue}');

    free(p);
    free(pHelper);
  }

  {
    // The pointer to pointer types must match up.
    Pointer<Int8> pHelper = allocate();
    pHelper.value = 123;

    Pointer<Pointer<Int16>> p = allocate();

    // Trying to store `pHelper` into `p.val` would result in a type mismatch.

    free(pHelper);
    free(p);
  }

  {
    // `nullptr` points to address 0 in c++.
    Pointer<Pointer<Int8>> pointerToPointer = allocate();
    Pointer<Int8> value = nullptr;
    pointerToPointer.value = value;
    value = pointerToPointer.value;
    print("Loading a pointer to the 0 address is null: ${value}");
    free(pointerToPointer);
  }

  {
    // The toplevel function sizeOf returns element size in bytes.
    print('sizeOf<Double>(): ${sizeOf<Double>()}');
    print('sizeOf<Int16>(): ${sizeOf<Int16>()}');
    print('sizeOf<IntPtr>(): ${sizeOf<IntPtr>()}');
  }

  {
    // With IntPtr pointers, one could manually setup aribtrary data
    // structres in C memory.
    //
    // However, it is advised to use Pointer<Pointer<...>> for that.

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
