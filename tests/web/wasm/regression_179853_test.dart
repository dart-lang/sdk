// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  const size = 128;
  for (final buffer in createBuffers(128)) {
    Expect.equals(size, buffer.lengthInBytes);
    initData(buffer, size);
    forEachTypedData((viewConstructor, lengthFun, sublistFun, elementSize) {
      final sizeInElements = size ~/ elementSize;

      final view = viewConstructor(
        buffer,
        /*offsetInBytes=*/ elementSize,
        /*length=*/ sizeInElements - 2,
      );
      print(
        'view: ${view.runtimeType} offsetInBytes:${view.offsetInBytes} len=${lengthFun(view)}',
      );
      Expect.equals(elementSize, view.offsetInBytes);
      Expect.equals(sizeInElements - 2, lengthFun(view));
      Expect.equals((sizeInElements - 2) * elementSize, view.lengthInBytes);
      verifyData(view, elementSize, size - 2 * elementSize);

      // This creates a new list.
      final sublist = sublistFun(
        view,
        /*start=*/ 1,
        /*end=*/ sizeInElements - 3,
      );
      Expect.equals(0, sublist.offsetInBytes);
      Expect.equals(sizeInElements - 4, lengthFun(sublist));
      Expect.equals((sizeInElements - 4) * elementSize, sublist.lengthInBytes);

      verifyData(sublist, 2 * elementSize, size - 4 * elementSize);
    });
  }
}

void forEachTypedData(
  void Function(
    TypedData Function(ByteBuffer, [int, int?]),
    int Function(TypedData),
    TypedData Function(TypedData, int, int?),
    int,
  )
  fun,
) {
  fun(
    Uint8List.view,
    (td) => (td as Uint8List).length,
    (td, start, end) => (td as Uint8List).sublist(start, end),
    1,
  );
  fun(
    Int8List.view,
    (td) => (td as Int8List).length,
    (td, start, end) => (td as Int8List).sublist(start, end),
    1,
  );
  fun(
    Uint8ClampedList.view,
    (td) => (td as Uint8ClampedList).length,
    (td, start, end) => (td as Uint8ClampedList).sublist(start, end),
    1,
  );
  fun(
    Uint16List.view,
    (td) => (td as Uint16List).length,
    (td, start, end) => (td as Uint16List).sublist(start, end),
    2,
  );
  fun(
    Int16List.view,
    (td) => (td as Int16List).length,
    (td, start, end) => (td as Int16List).sublist(start, end),
    2,
  );
  fun(
    Uint32List.view,
    (td) => (td as Uint32List).length,
    (td, start, end) => (td as Uint32List).sublist(start, end),
    4,
  );
  fun(
    Int32List.view,
    (td) => (td as Int32List).length,
    (td, start, end) => (td as Int32List).sublist(start, end),
    4,
  );
  fun(
    Float32List.view,
    (td) => (td as Float32List).length,
    (td, start, end) => (td as Float32List).sublist(start, end),
    4,
  );
  fun(
    Float64List.view,
    (td) => (td as Float64List).length,
    (td, start, end) => (td as Float64List).sublist(start, end),
    8,
  );
}

List<ByteBuffer> createBuffers(int size) {
  return [
    // JS backed.
    JSArrayBuffer(size).toDart,
    JSUint8Array.withLength(size).toDart.buffer,
    JSInt8Array.withLength(size).toDart.buffer,
    JSUint8ClampedArray.withLength(size).toDart.buffer,
    JSUint16Array.withLength(size ~/ 2).toDart.buffer,
    JSInt16Array.withLength(size ~/ 2).toDart.buffer,
    JSUint32Array.withLength(size ~/ 4).toDart.buffer,
    JSInt32Array.withLength(size ~/ 4).toDart.buffer,
    JSFloat32Array.withLength(size ~/ 4).toDart.buffer,
    JSFloat64Array.withLength(size ~/ 8).toDart.buffer,

    // Dart backed.
    Uint8List(size).buffer,
    Int8List(size).buffer,
    Uint8ClampedList(size).buffer,
    Uint16List(size ~/ 2).buffer,
    Int16List(size ~/ 2).buffer,
    Uint32List(size ~/ 4).buffer,
    Int32List(size ~/ 4).buffer,
    Int64List(size ~/ 8).buffer,
    Float32List(size ~/ 4).buffer,
    Float64List(size ~/ 8).buffer,
    Float32x4List(size ~/ 16).buffer,
    Float64x2List(size ~/ 16).buffer,
  ];
}

void initData(ByteBuffer buffer, int length) {
  final td = buffer.asUint8List();
  for (int i = 0; i < length; i++) {
    td[i] = i;
  }
}

void verifyData(TypedData typedData, int offset, int length) {
  final td = typedData.buffer.asUint8List(typedData.offsetInBytes);
  print('verifyData($offset, $length) ');
  for (int i = 0; i < length; i++) {
    Expect.equals(offset + i, td[i]);
  }
}
