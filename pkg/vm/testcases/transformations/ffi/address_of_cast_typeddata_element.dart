// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import 'dart:ffi';
import 'dart:typed_data';

void main() {
  final typedData = Int8List(20);
  // These cast should accepted
  myNative(
    typedData.address.cast(),
  );

  myNative(typedData[0].address.cast());
}

@Native<
    Int8 Function(
      Pointer<Void>,
    )>(isLeaf: true)
external int myNative(
  Pointer<Void> pointer,
);
