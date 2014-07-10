// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'dart:_internal' show FixedLengthListMixin;
import 'dart:_foreign_helper' show JS;
import 'dart:math' as Math;
import 'dart:_internal';
import 'dart:_interceptors' show JSIndexable, JSUInt32, JSUInt31;
import 'dart:_js_helper'
    show Creates, JavaScriptIndexingBehavior, JSName, Null, Returns, patch;
import 'dart:_native_typed_data';

@patch class ByteData {
  @patch factory ByteData(int length) =>
      new NativeByteData(length);
}


@patch class Float32List {
  @patch factory Float32List(int length) =>
      new NativeFloat32List(length);

  @patch factory Float32List.fromList(List<double> elements) =>
      new NativeFloat32List.fromList(elements);
}


@patch class Float64List {
  @patch factory Float64List(int length) =>
      new NativeFloat64List(length);

  @patch factory Float64List.fromList(List<double> elements) =>
      new NativeFloat64List.fromList(elements);
}


@patch class Int16List {
  @patch factory Int16List(int length) =>
      new NativeInt16List(length);

  @patch factory Int16List.fromList(List<int> elements) =>
      new NativeInt16List.fromList(elements);
}

@patch class Int32List {
  @patch factory Int32List(int length) =>
      new NativeInt32List(length);

  @patch factory Int32List.fromList(List<int> elements) =>
      new NativeInt32List.fromList(elements);
}


@patch class Int8List {
  @patch factory Int8List(int length) =>
      new NativeInt8List(length);

  @patch factory Int8List.fromList(List<int> elements) =>
      new NativeInt8List.fromList(elements);
}


@patch class Uint32List {
  @patch factory Uint32List(int length) =>
      new NativeUint32List(length);

  @patch factory Uint32List.fromList(List<int> elements) =>
      new NativeUint32List.fromList(elements);
}


@patch class Uint16List {
  @patch factory Uint16List(int length) =>
      new NativeUint16List(length);

  @patch factory Uint16List.fromList(List<int> elements) =>
      new NativeUint16List.fromList(elements);
}


@patch class Uint8ClampedList {
  @patch factory Uint8ClampedList(int length) =>
      new NativeUint8ClampedList(length);

  @patch factory Uint8ClampedList.fromList(List<int> elements) =>
      new NativeUint8ClampedList.fromList(elements);
}


@patch class Uint8List {
  @patch factory Uint8List(int length) =>
      new NativeUint8List(length);

  @patch factory Uint8List.fromList(List<int> elements) =>
      new NativeUint8List.fromList(elements);
}


@patch class Int64List {
  @patch factory Int64List(int length) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  @patch factory Int64List.fromList(List<int> elements) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }
}


@patch class Uint64List {
  @patch factory Uint64List(int length) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  @patch factory Uint64List.fromList(List<int> elements) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }
}

@patch class Int32x4List {
  @patch factory Int32x4List(int length) =>
      new NativeInt32x4List(length);

  @patch factory Int32x4List.fromList(List<Int32x4> elements) =>
      new NativeInt32x4List.fromList(elements);
}

@patch class Float32x4List {
  @patch factory Float32x4List(int length) =>
      new NativeFloat32x4List(length);

  @patch factory Float32x4List.fromList(List<Float32x4> elements) =>
      new NativeFloat32x4List.fromList(elements);
}

@patch class Float64x2List {
  @patch factory Float64x2List(int length) =>
      new NativeFloat64x2List(length);

  @patch factory Float64x2List.fromList(List<Float64x2> elements) =>
      new NativeFloat64x2List.fromList(elements);
}

@patch class Float32x4 {
  @patch factory Float32x4(double x, double y, double z, double w) =>
      new NativeFloat32x4(x, y, z, w);
  @patch factory Float32x4.splat(double v) =>
      new NativeFloat32x4.splat(v);
  @patch factory Float32x4.zero() => new NativeFloat32x4.zero();
  @patch factory Float32x4.fromInt32x4Bits(Int32x4 x) =>
      new NativeFloat32x4.fromInt32x4Bits(x);
  @patch factory Float32x4.fromFloat64x2(Float64x2 v) =>
      new NativeFloat32x4.fromFloat64x2(v);
}

@patch class Int32x4 {
  @patch factory Int32x4(int x, int y, int z, int w)
      => new NativeInt32x4(x, y, z , w);
  @patch factory Int32x4.bool(bool x, bool y, bool z, bool w)
      => new NativeInt32x4.bool(x, y, z, w);
  @patch factory Int32x4.fromFloat32x4Bits(Float32x4 x)
      => new NativeInt32x4.fromFloat32x4Bits(x);
}

@patch class Float64x2 {
  @patch factory Float64x2(double x, double y) => new NativeFloat64x2(x, y);
  @patch factory Float64x2.splat(double v)
      => new NativeFloat64x2.splat(v);
  @patch factory Float64x2.zero()
      => new NativeFloat64x2.zero();
  @patch factory Float64x2.fromFloat32x4(Float32x4 v)
      => new NativeFloat64x2.fromFloat32x4(v);
}
