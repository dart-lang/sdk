// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;

// These are naive patches for SIMD typed data which we can use until Wasm
// we implement intrinsics for Wasm SIMD.
// TODO(joshualitt): Implement SIMD intrinsics and delete this patch.

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) = _NaiveInt32x4List;

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =
      _NaiveInt32x4List.fromList;
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) = _NaiveFloat32x4List;

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =
      _NaiveFloat32x4List.fromList;
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) = _NaiveFloat64x2List;

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =
      _NaiveFloat64x2List.fromList;
}

@patch
abstract class UnmodifiableInt32x4ListView implements Int32x4List {
  @patch
  factory UnmodifiableInt32x4ListView(Int32x4List list) =>
      _NaiveUnmodifiableInt32x4List(list);
}

@patch
abstract class UnmodifiableFloat32x4ListView implements Float32x4List {
  @patch
  factory UnmodifiableFloat32x4ListView(Float32x4List list) =>
      _NaiveUnmodifiableFloat32x4List(list);
}

@patch
abstract class UnmodifiableFloat64x2ListView implements Float64x2List {
  @patch
  factory UnmodifiableFloat64x2ListView(Float64x2List list) =>
      _NaiveUnmodifiableFloat64x2List(list);
}

@patch
class Int32x4 {
  @patch
  factory Int32x4(int x, int y, int z, int w) = _NaiveInt32x4;

  @patch
  factory Int32x4.bool(bool x, bool y, bool z, bool w) = _NaiveInt32x4.bool;

  @patch
  factory Int32x4.fromFloat32x4Bits(Float32x4 x) =
      _NaiveInt32x4.fromFloat32x4Bits;
}

@patch
class Float32x4 {
  @patch
  factory Float32x4(double x, double y, double z, double w) = _NaiveFloat32x4;

  @patch
  factory Float32x4.splat(double v) = _NaiveFloat32x4.splat;

  @patch
  factory Float32x4.zero() = _NaiveFloat32x4.zero;

  @patch
  factory Float32x4.fromInt32x4Bits(Int32x4 x) =
      _NaiveFloat32x4.fromInt32x4Bits;

  @patch
  factory Float32x4.fromFloat64x2(Float64x2 v) = _NaiveFloat32x4.fromFloat64x2;
}

@patch
class Float64x2 {
  @patch
  factory Float64x2(double x, double y) = _NaiveFloat64x2;

  @patch
  factory Float64x2.splat(double v) = _NaiveFloat64x2.splat;

  @patch
  factory Float64x2.zero() = _NaiveFloat64x2.zero;

  @patch
  factory Float64x2.fromFloat32x4(Float32x4 v) = _NaiveFloat64x2.fromFloat32x4;
}
