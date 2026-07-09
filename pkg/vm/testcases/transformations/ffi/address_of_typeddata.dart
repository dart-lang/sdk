// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';
import 'dart:typed_data';

void main() {
  // Invocation with no `.address`, should use the original native.
  final pointer = nullptr.cast<Int8>();
  myNative(
    pointer,
    pointer,
    1,
  );

  // Invocations with `.address` should invoke a copy, but the same copy.
  final typedData = Int8List(20);
  myNative(
    typedData.address,
    typedData.address,
    2,
  );
  myNative(
    Int8List.sublistView(typedData, 4).address,
    typedData.address,
    3,
  );

  // And invocations with different arguments being TypedDataBase should
  // have a different copy.
  myNative(
    pointer,
    typedData.address,
    4,
  );
}

@Native<
    Int8 Function(
      Pointer<Int8>,
      Pointer<Int8>,
      Int8,
    )>(isLeaf: true)
external int myNative(
  Pointer<Int8> pointer,
  Pointer<Int8> pointer2,
  int nonPointer,
);
