// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

// The `TypedData` interface has the following properties:
// * `buffer`
// * `offsetInBytes`
// * `lengthInBytes`
// * `elementSizeInBytes`
//
// The new `TypedDataList` has these and the `List` interface.
// Testing that all the typed data types have the members, and that if they
// are lists, their list length matches their typed-data view size.

void test(TypedData data, int bytesPerElement, int lengthInBytes) {
  var type = data.runtimeType.toString();
  Expect.equals(
      bytesPerElement, data.elementSizeInBytes, "$type.elementSizeInBytes");
  Expect.equals(lengthInBytes, data.lengthInBytes, "$type.lengthInBytes");
  // Always aligned.
  Expect.equals(0, data.offsetInBytes % bytesPerElement, "$type alignment");
  if (data is TypedDataList) {
    Expect.equals(
        lengthInBytes ~/ bytesPerElement, data.length, "$type.length");
  } else {
    // Only `ByteData` is not a `TypedDataList`.
    Expect.type<ByteData>(data);
  }
}

void main() {
  // Reusable buffer
  var typedList = Uint8List(128);
  var buffer = typedList.buffer;

  for (var bytes in [0, 16, 64]) {
    int size;

    size = 1; // No ByteData.bytesPerElement.
    test(ByteData(bytes), size, bytes);
    test(ByteData.view(buffer, 32, bytes), size, bytes);
    test(ByteData.sublistView(typedList, 32, 32 + bytes * size), size, bytes);

    size = Uint8List.bytesPerElement;
    Expect.equals(1, size);
    test(Uint8List(bytes), size, bytes);
    test(Uint8List.view(buffer, 32, bytes), size, bytes);
    test(Uint8List.sublistView(typedList, 32, 32 + bytes * size), size, bytes);

    size = Int8List.bytesPerElement;
    Expect.equals(1, size);
    test(Int8List(bytes), size, bytes);
    test(Int8List.view(buffer, 32, bytes), size, bytes);
    test(Int8List.sublistView(typedList, 32, 32 + bytes * size), size, bytes);

    size = Uint8ClampedList.bytesPerElement;
    Expect.equals(1, size);
    test(Uint8ClampedList(bytes), size, bytes);
    test(Uint8ClampedList.view(buffer, 32, bytes), size, bytes);
    test(Uint8ClampedList.sublistView(typedList, 32, 32 + bytes * size), size,
        bytes);

    size = Uint16List.bytesPerElement;
    Expect.equals(2, size);
    test(Uint16List(bytes ~/ 2), size, bytes);
    test(Uint16List.view(buffer, 32, bytes ~/ 2), size, bytes);
    test(Uint16List.sublistView(typedList, 32, 32 + bytes * size ~/ 2), size,
        bytes);

    size = Int16List.bytesPerElement;
    Expect.equals(2, size);
    test(Int16List(bytes ~/ 2), size, bytes);
    test(Int16List.view(buffer, 32, bytes ~/ 2), size, bytes);
    test(Int16List.sublistView(typedList, 32, 32 + bytes * size ~/ 2), size,
        bytes);

    size = Uint32List.bytesPerElement;
    Expect.equals(4, size);
    test(Uint32List(bytes ~/ 4), size, bytes);
    test(Uint32List.view(buffer, 32, bytes ~/ 4), size, bytes);
    test(Uint32List.sublistView(typedList, 32, 32 + bytes * size ~/ 4), size,
        bytes);

    size = Int32List.bytesPerElement;
    Expect.equals(4, size);
    test(Int32List(bytes ~/ 4), size, bytes);
    test(Int32List.view(buffer, 32, bytes ~/ 4), size, bytes);
    test(Int32List.sublistView(typedList, 32, 32 + bytes * size ~/ 4), size,
        bytes);

    if (!jsNumbers) {
      size = Uint64List.bytesPerElement;
      Expect.equals(8, size);
      test(Uint64List(bytes ~/ 8), size, bytes);
      test(Uint64List.view(buffer, 32, bytes ~/ 8), size, bytes);
      test(Uint64List.sublistView(typedList, 32, 32 + bytes * size ~/ 8), size,
          bytes);

      size = Int64List.bytesPerElement;
      Expect.equals(8, size);
      test(Int64List(bytes ~/ 8), size, bytes);
      test(Int64List.view(buffer, 32, bytes ~/ 8), size, bytes);
      test(Int64List.sublistView(typedList, 32, 32 + bytes * size ~/ 8), size,
          bytes);
    }

    size = Float32List.bytesPerElement;
    Expect.equals(4, size);
    test(Float32List(bytes ~/ 4), size, bytes);
    test(Float32List.view(buffer, 32, bytes ~/ 4), size, bytes);
    test(Float32List.sublistView(typedList, 32, 32 + bytes * size ~/ 4), size,
        bytes);

    size = Float64List.bytesPerElement;
    Expect.equals(8, size);
    test(Float64List(bytes ~/ 8), size, bytes);
    test(Float64List.view(buffer, 32, bytes ~/ 8), size, bytes);
    test(Float64List.sublistView(typedList, 32, 32 + bytes * size ~/ 8), size,
        bytes);

    size = Int32x4List.bytesPerElement;
    Expect.equals(16, size);
    test(Int32x4List(bytes ~/ 16), size, bytes);
    test(Int32x4List.view(buffer, 32, bytes ~/ 16), size, bytes);
    test(Int32x4List.sublistView(typedList, 32, 32 + bytes * size ~/ 16), size,
        bytes);

    size = Float32x4List.bytesPerElement;
    Expect.equals(16, size);
    test(Float32x4List(bytes ~/ 16), size, bytes);
    test(Float32x4List.view(buffer, 32, bytes ~/ 16), size, bytes);
    test(Float32x4List.sublistView(typedList, 32, 32 + bytes * size ~/ 16),
        size, bytes);

    size = Float64x2List.bytesPerElement;
    Expect.equals(16, size);
    test(Float64x2List(bytes ~/ 16), size, bytes);
    test(Float64x2List.view(buffer, 32, bytes ~/ 16), size, bytes);
    test(Float64x2List.sublistView(typedList, 32, 32 + bytes * size ~/ 16),
        size, bytes);
  }

  var oddSize = 64 + 7;
  var oddList = Uint8List(oddSize);
  var oddBuffer = oddList.buffer;
  // View truncates to multiple of `lengthInBytes`.
  int roundTo(int num, int mod) => num - (num % mod);
  Expect.equals(oddSize, ByteData.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Uint8List.bytesPerElement),
      Uint8List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Int8List.bytesPerElement),
      Int8List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Uint8ClampedList.bytesPerElement),
      Uint8ClampedList.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Uint16List.bytesPerElement),
      Uint16List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Int16List.bytesPerElement),
      Int16List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Uint32List.bytesPerElement),
      Uint32List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Int32List.bytesPerElement),
      Int32List.view(oddBuffer).lengthInBytes);
  if (!jsNumbers) {
    Expect.equals(roundTo(oddSize, Uint64List.bytesPerElement),
        Uint64List.view(oddBuffer).lengthInBytes);
    Expect.equals(roundTo(oddSize, Int64List.bytesPerElement),
        Int64List.view(oddBuffer).lengthInBytes);
  }
  Expect.equals(roundTo(oddSize, Float32List.bytesPerElement),
      Float32List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Float64List.bytesPerElement),
      Float64List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Int32x4List.bytesPerElement),
      Int32x4List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Float32x4List.bytesPerElement),
      Float32x4List.view(oddBuffer).lengthInBytes);
  Expect.equals(roundTo(oddSize, Float64x2List.bytesPerElement),
      Float64x2List.view(oddBuffer).lengthInBytes);
}
