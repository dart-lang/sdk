// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';

void main() {
  // This should create a `_Compound` with the right offset.
  final myStruct = Struct.create<MyStruct>();
  myNative(
    myStruct.a.address,
    myStruct.b.address,
  );

  // Unions do not need to create a view with an offset.
  final myUnion = Union.create<MyUnion>();
  myNative(
    myUnion.a.address,
    myUnion.b.address,
  );

  // This should create a `_Compound` with the right offset.
  myNative(
    myStruct.array[3].address,
    myStruct.array[4].address,
  );

  // This should create a `_Compound` with the right offset.
  myNative(
    myStruct.array2[3].address,
    myStruct.array2[4].address,
  );
}

@Native<
    Void Function(
      Pointer<Int8>,
      Pointer<Int8>,
    )>(isLeaf: true)
external void myNative(
  Pointer<Int8> pointer,
  Pointer<Int8> pointer2,
);

final class MyStruct extends Struct {
  @Int8()
  external int a;

  @Int8()
  external int b;

  @Array(10)
  external Array<Int8> array;

  @Array(10)
  external Array<UnsignedLong> array2;
}

final class MyUnion extends Union {
  @Int8()
  external int a;

  @Int8()
  external int b;
}
