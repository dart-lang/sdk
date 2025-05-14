// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

void main() {
  final struct = Struct.create<TestStruct>();

  print(struct.structArray.elements);
  print(struct.unionArray.elements);
  print(struct.arrayArray.elements);
  print(struct.abiSpecificIntegerArray.elements);
}

final class TestStruct extends Struct {
  @Array(5)
  external Array<MyStruct> structArray;

  @Array(5)
  external Array<MyUnion> unionArray;

  @Array(5, 5)
  external Array<Array<Int8>> arrayArray;

  @Array(5)
  external Array<WChar> abiSpecificIntegerArray;
}

final class MyStruct extends Struct {
  @Int8()
  external int structValue;
}

final class MyUnion extends Union {
  @Int32()
  external int unionAlt1;

  @Float()
  external double unionAlt2;
}
