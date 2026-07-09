// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests are mainly for dart2wasm, where we have multiple `ByteData`
// classes with differently typed backing arrays.

import 'dart:typed_data';

import 'package:expect/expect.dart';

const bool isJS = identical(1, 1.0);

void main() {
  testBufferBytes(Int8List.fromList, [42]);
  testBufferBytes(Uint8List.fromList, [42]);
  testBufferBytes(Uint8ClampedList.fromList, [42]);
  testBufferBytes(Int16List.fromList, [42, 0]);
  testBufferBytes(Uint16List.fromList, [42, 0]);
  testBufferBytes(Int32List.fromList, [42, 0, 0, 0]);
  testBufferBytes(Uint32List.fromList, [42, 0, 0, 0]);
  if (!isJS) {
    testBufferBytes(Int64List.fromList, [42, 0, 0, 0, 0, 0, 0, 0]);
    testBufferBytes(Uint64List.fromList, [42, 0, 0, 0, 0, 0, 0, 0]);
  }
}

void testBufferBytes(
  TypedData Function(List<int>) makeList,
  List<int> expected,
) {
  final buffer = makeList([42]).buffer;
  final data = ByteData.view(buffer);
  final list = Uint8List.sublistView(data);
  Expect.listEquals(expected, list);
}
