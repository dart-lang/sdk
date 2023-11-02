// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Struct1ByteInt code should not be shaken out if the only place instances
// of this class are created is FFI call return values.

import 'dart:ffi';

void main() {
  final result = returnStruct1ByteIntNative(-1);
  print("result = $result");
}

// ignore: sdk_version_since
@Native<Struct1ByteInt Function(Int8)>(symbol: 'ReturnStruct1ByteInt')
external Struct1ByteInt returnStruct1ByteIntNative(int a0);

final class Struct1ByteInt extends Struct {
  @Int8()
  external int a0;

  String toString() => "(${a0})";
}
