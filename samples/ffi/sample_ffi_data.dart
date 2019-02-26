// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

main(List<String> arguments) {
  print('start main');

  {
    // basic operation: allocate, get, set, and free
    ffi.Pointer<ffi.Int64> p = ffi.allocate();
    p.store(42);
    int pValue = p.load();
    print('${p.runtimeType} value: ${pValue}');
    p.free();
  }

  {
    // undefined behavior before set
    ffi.Pointer<ffi.Int64> p = ffi.allocate();
    int pValue = p.load();
    print('If not set, returns garbage: ${pValue}');
    p.free();
  }

  {
    // pointers can be created from an address
    ffi.Pointer<ffi.Int64> pHelper = ffi.allocate();
    pHelper.store(1337);

    int address = pHelper.address;
    print('Address: ${address}');

    ffi.Pointer<ffi.Int64> p = ffi.fromAddress(address);
    print('${p.runtimeType} value: ${p.load<int>()}');

    pHelper.free();
  }

  {
    // address is zeroed out after free
    ffi.Pointer<ffi.Int64> p = ffi.allocate();
    p.free();
    print('After free, address is zero: ${p.address}');
  }

  {
    // pointer arithmetic can be done with element offsets or bytes
    ffi.Pointer<ffi.Int64> p1 = ffi.allocate<ffi.Int64>(count: 2);
    print('p1 address: ${p1.address}');

    ffi.Pointer<ffi.Int64> p2 = p1.elementAt(1);
    print('p1.elementAt(1) address: ${p2.address}');
    p2.store(100);

    ffi.Pointer<ffi.Int64> p3 = p1.offsetBy(8);
    print('p1.offsetBy(8) address: ${p3.address}');
    print('p1.offsetBy(8) value: ${p3.load<int>()}');
    p1.free();
  }

  {
    // allocating too much throws an exception
    try {
      int maxMint = 9223372036854775807; // 2^63 - 1
      ffi.allocate<ffi.Int64>(count: maxMint);
    } on RangeError {
      print('Expected exception on allocating too much');
    }
    try {
      int maxInt1_8 = 1152921504606846975; // 2^60 -1
      ffi.allocate<ffi.Int64>(count: maxInt1_8);
    } on ArgumentError {
      print('Expected exception on allocating too much');
    }
  }

  {
    // pointers can be cast into another type
    // resulting in the corresponding bits read
    ffi.Pointer<ffi.Int64> p1 = ffi.allocate();
    p1.store(9223372036854775807); // 2^63 - 1

    ffi.Pointer<ffi.Int32> p2 = p1.cast();
    print('${p2.runtimeType} value: ${p2.load<int>()}'); // -1

    ffi.Pointer<ffi.Int32> p3 = p2.elementAt(1);
    print('${p3.runtimeType} value: ${p3.load<int>()}'); // 2^31 - 1

    p1.free();
  }

  {
    // data can be tightly packed in memory
    ffi.Pointer<ffi.Int8> p = ffi.allocate(count: 8);
    for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
      p.elementAt(i).store(i * 3);
    }
    for (var i in [0, 1, 2, 3, 4, 5, 6, 7]) {
      print('p.elementAt($i) value: ${p.elementAt(i).load<int>()}');
    }
    p.free();
  }

  {
    // exception on storing a value that does not fit
    ffi.Pointer<ffi.Int32> p11 = ffi.allocate();

    try {
      p11.store(9223372036854775807);
    } on ArgumentError {
      print('Expected exception on calling set with a value that does not fit');
    }

    p11.free();
  }

  {
    // doubles
    ffi.Pointer<ffi.Double> p = ffi.allocate();
    p.store(3.14159265359);
    print('${p.runtimeType} value: ${p.load<double>()}');
    p.store(3.14);
    print('${p.runtimeType} value: ${p.load<double>()}');
    p.free();
  }

  {
    // floats
    ffi.Pointer<ffi.Float> p = ffi.allocate();
    p.store(3.14159265359);
    print('${p.runtimeType} value: ${p.load<double>()}');
    p.store(3.14);
    print('${p.runtimeType} value: ${p.load<double>()}');
    p.free();
  }

  {
    // ffi.IntPtr varies in size based on whether the platform is 32 or 64 bit
    // addresses of pointers fit in this size
    ffi.Pointer<ffi.IntPtr> p = ffi.allocate();
    int p14addr = p.address;
    p.store(p14addr);
    int pValue = p.load();
    print('${p.runtimeType} value: ${pValue}');
    p.free();
  }

  {
    // void pointers are unsized
    // the size of the element it is pointing to is undefined
    // this means they cannot be ffi.allocated, read, or written
    // this would would fail to compile:
    // ffi.allocate<ffi.Void>();

    ffi.Pointer<ffi.IntPtr> p1 = ffi.allocate();
    ffi.Pointer<ffi.Void> p2 = p1.cast();
    print('${p2.runtimeType} address: ${p2.address}');

    // this fails to compile, we cannot read something unsized
    // p2.load<int>();

    // this fails to compile, we cannot write something unsized
    // p2.store(1234);

    p1.free();
  }

  {
    // pointer to a pointer to something
    ffi.Pointer<ffi.Int16> pHelper = ffi.allocate();
    pHelper.store(17);

    ffi.Pointer<ffi.Pointer<ffi.Int16>> p = ffi.allocate();

    // storing into a pointer pointer automatically unboxes
    p.store(pHelper);

    // reading from a pointer pointer automatically boxes
    ffi.Pointer<ffi.Int16> pHelper2 = p.load();
    print('${pHelper2.runtimeType} value: ${pHelper2.load<int>()}');

    int pValue = p.load<ffi.Pointer<ffi.Int16>>().load();
    print('${p.runtimeType} value\'s value: ${pValue}');

    p.free();
    pHelper.free();
  }

  {
    // the pointer to pointer types must match up
    ffi.Pointer<ffi.Int8> pHelper = ffi.allocate();
    pHelper.store(123);

    ffi.Pointer<ffi.Pointer<ffi.Int16>> p = ffi.allocate();

    // this fails to compile due to type mismatch
    // p.store(pHelper);

    pHelper.free();
    p.free();
  }

  {
    // null pointer in Dart points to address 0 in c++
    ffi.Pointer<ffi.Pointer<ffi.Int8>> pointerToPointer = ffi.allocate();
    ffi.Pointer<ffi.Int8> value = null;
    pointerToPointer.store(value);
    value = pointerToPointer.load();
    print("Loading a pointer to the 0 address is null: ${value}");
    pointerToPointer.free();
  }

  {
    // sizeof returns element size in bytes
    print('sizeOf<ffi.Double>(): ${ffi.sizeOf<ffi.Double>()}');
    print('sizeOf<ffi.Int16>(): ${ffi.sizeOf<ffi.Int16>()}');
    print('sizeOf<ffi.IntPtr>(): ${ffi.sizeOf<ffi.IntPtr>()}');
  }

  {
    // only concrete sub types of NativeType can be ffi.allocated
    // this would fail to compile:
    // ffi.allocate();
  }

  {
    // only concrete sub types of NativeType can be asked for size
    // this would fail to compile:
    // ffi.sizeOf();
  }

  {
    // with ffi.IntPtr pointers, one can manually setup aribtrary data
    // structres in C memory.

    void createChain(ffi.Pointer<ffi.IntPtr> head, int length, int value) {
      if (length == 0) {
        head.store(value);
        return;
      }
      ffi.Pointer<ffi.IntPtr> next = ffi.allocate<ffi.IntPtr>();
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

    int length = 10;
    ffi.Pointer<ffi.IntPtr> head = ffi.allocate();
    createChain(head, length, 512);
    int tailValue = getChainValue(head, length);
    print('tailValue: ${tailValue}');
    freeChain(head, length);
  }

  print("end main");
}
