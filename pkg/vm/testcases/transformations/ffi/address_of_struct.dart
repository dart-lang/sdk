// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';

void main() {
  // All of these pass a `_Compound`.
  final myStruct = Struct.create<MyStruct>();
  myNative(myStruct.address);

  final myUnion = Union.create<MyUnion>();
  myNative2(myUnion.address);

  myNative3(myStruct.a.address);
}

@Native<Void Function(Pointer<MyStruct>)>(isLeaf: true)
external void myNative(Pointer<MyStruct> pointer);

final class MyStruct extends Struct {
  @Array(10)
  external Array<Int8> a;
}

@Native<Void Function(Pointer<MyUnion>)>(isLeaf: true)
external void myNative2(Pointer<MyUnion> pointer);

final class MyUnion extends Union {
  @Int8()
  external int a;
}

@Native<Void Function(Pointer<Int8>)>(isLeaf: true)
external void myNative3(Pointer<Int8> pointer);
