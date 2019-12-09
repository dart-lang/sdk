// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import "package:expect/expect.dart";

bool throwsArgumentError(void Function() f) {
  bool caught = false;
  try {
    f();
  } on ArgumentError catch (e) {
    caught = true;
  }
  return caught;
}

main() {
  // Float32x4
  Expect.equals(
      throwsArgumentError(() => Float32x4(null, 0.0, 0.0, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, null, 0.0, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, 0.0, null, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, 0.0, 0.0, null)), true);

  // Float32x4.splat
  Expect.equals(throwsArgumentError(() => Float32x4.splat(null)), true);

  // Float64x2
  Expect.equals(throwsArgumentError(() => Float64x2(null, 0.0)), true);
  Expect.equals(throwsArgumentError(() => Float64x2(0.0, null)), true);

  // Float64x2.splat
  Expect.equals(throwsArgumentError(() => Float64x2.splat(null)), true);

  // Int32x4
  Expect.equals(throwsArgumentError(() => Int32x4(null, 0, 0, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, null, 0, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, 0, null, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, 0, 0, null)), true);

  // Int32x4.bool
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(null, false, false, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, null, false, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, false, null, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, false, false, null)), true);
}
