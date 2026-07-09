// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';
import 'dart:typed_data';

void main() {
  // This needs to create a view on the underlying typed data.
  // Or, create a `_Compound` with an offset.
  final typedData = Int8List(20);
  SomeClass.myNative(
    typedData[3].address,
    typedData[8].address,
  );
}

final class SomeClass {
  @Native<
      Int8 Function(
        Pointer<Int8>,
        Pointer<Int8>,
      )>(isLeaf: true)
  external static int myNative(
    Pointer<Int8> pointer,
    Pointer<Int8> pointer2,
  );
}
