// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';

// `.address.cast()` from members of struct and union should accepted
void main() {
  final myStruct = Struct.create<MyStruct>();
  myNative(
    myStruct.a.address.cast<Void>(),
    myStruct.b.address.cast<Void>(),
  );

  final myUnion = Union.create<MyUnion>();
  myNative(
    myUnion.a.address.cast<Void>(),
    myUnion.b.address.cast<Void>(),
  );

  myNative(
    myStruct.array[3].address.cast<Void>(),
    myStruct.array[4].address.cast<Void>(),
  );

  myNative(
    myStruct.array2[3].address.cast<Void>(),
    myStruct.array2[4].address.cast<Void>(),
  );
}

@Native<
    Void Function(
      Pointer<Void>,
      Pointer<Void>,
    )>(isLeaf: true)
external void myNative(
  Pointer<Void> pointer,
  Pointer<Void> pointer2,
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
