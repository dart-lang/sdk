// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify
// VMOptions=--no-intrinsify

import 'dart:typed_data';

Float32x4 f32 = Float32x4.splat(-0.40150792030288873);
Float64x2 f64 = Float64x2.splat(-0.40150792030288873);

// Work around dart2js's broken `identical`.
bool bitwiseEqual(double x, double y) {
  var b = ByteData(16);
  b.setFloat64(0, x);
  b.setFloat64(8, y);
  return (b.getUint32(0) == b.getUint32(8)) &&
      (b.getUint32(4) == b.getUint32(12));
}

main() {
  f32 -= f32.sqrt();
  print(f32);
  if (!bitwiseEqual(f32.x, f32.y) ||
      !bitwiseEqual(f32.x, f32.z) ||
      !bitwiseEqual(f32.x, f32.w)) {
    throw "Float32x4 lane mismatch";
  }
  f64 -= f64.sqrt();
  print(f64);
  if (!bitwiseEqual(f64.x, f64.y)) {
    throw "Float64x2 lane mismatch";
  }
}
