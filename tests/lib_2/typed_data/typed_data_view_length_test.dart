// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/43204

import 'dart:typed_data';

import "package:expect/expect.dart";

void main() {
  // This test should not throw.
  // The created views should extend as far as possible in each case.
  var buffer = Uint8List(127).buffer;

  var f32l = buffer.asFloat32List();
  Expect.equals(31, f32l.length);
  Expect.equals(31 * Float32List.bytesPerElement, f32l.lengthInBytes);
  f32l = buffer.asFloat32List(8);
  Expect.equals(29, f32l.length);
  Expect.equals(29 * Float32List.bytesPerElement, f32l.lengthInBytes);

  var f64l = buffer.asFloat64List();
  Expect.equals(15, f64l.length);
  Expect.equals(15 * Float64List.bytesPerElement, f64l.lengthInBytes);
  f64l = buffer.asFloat64List(8);
  Expect.equals(14, f64l.length);
  Expect.equals(14 * Float64List.bytesPerElement, f64l.lengthInBytes);

  var i16l = buffer.asInt16List();
  Expect.equals(63, i16l.length);
  Expect.equals(63 * Int16List.bytesPerElement, i16l.lengthInBytes);
  i16l = buffer.asInt16List(8);
  Expect.equals(59, i16l.length);
  Expect.equals(59 * Int16List.bytesPerElement, i16l.lengthInBytes);

  var i32l = buffer.asInt32List();
  Expect.equals(31, i32l.length);
  Expect.equals(31 * Int32List.bytesPerElement, i32l.lengthInBytes);
  i32l = buffer.asInt32List(8);
  Expect.equals(29, i32l.length);
  Expect.equals(29 * Int32List.bytesPerElement, i32l.lengthInBytes);

  var u16l = buffer.asUint16List();
  Expect.equals(63, u16l.length);
  Expect.equals(63 * Uint16List.bytesPerElement, u16l.lengthInBytes);
  u16l = buffer.asUint16List(8);
  Expect.equals(59, u16l.length);
  Expect.equals(59 * Uint16List.bytesPerElement, u16l.lengthInBytes);

  var u32l = buffer.asUint32List();
  Expect.equals(31, u32l.length);
  Expect.equals(31 * Uint32List.bytesPerElement, u32l.lengthInBytes);
  u32l = buffer.asUint32List(8);
  Expect.equals(29, u32l.length);
  Expect.equals(29 * Uint32List.bytesPerElement, u32l.lengthInBytes);

  var f32x4l = buffer.asFloat32x4List();
  Expect.equals(7, f32x4l.length);
  Expect.equals(7 * Float32x4List.bytesPerElement, f32x4l.lengthInBytes);
  f32x4l = buffer.asFloat32x4List(16);
  Expect.equals(6, f32x4l.length);
  Expect.equals(6 * Float32x4List.bytesPerElement, f32x4l.lengthInBytes);

  var f64x2l = buffer.asFloat64x2List();
  Expect.equals(7, f64x2l.length);
  Expect.equals(7 * Float64x2List.bytesPerElement, f64x2l.lengthInBytes);
  f64x2l = buffer.asFloat64x2List(16);
  Expect.equals(6, f64x2l.length);
  Expect.equals(6 * Float64x2List.bytesPerElement, f64x2l.lengthInBytes);

  var i32x4l = buffer.asInt32x4List();
  Expect.equals(7, i32x4l.length);
  Expect.equals(7 * Int32x4List.bytesPerElement, i32x4l.lengthInBytes);
  i32x4l = buffer.asInt32x4List(16);
  Expect.equals(6, i32x4l.length);
  Expect.equals(6 * Int32x4List.bytesPerElement, i32x4l.lengthInBytes);
}
