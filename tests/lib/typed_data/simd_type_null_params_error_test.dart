// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

// Many other tests will check that static nullability checks are applied to
// actual arguments of regular function invocations. This test is still not
// redundant, because it involves a built-in type and methods subject to
// patching, and patching could introduce bugs in this area.

import 'dart:typed_data';

main() {
  // Float32x4
  final float32x4 = Float32x4(0.0, 0.0, 0.0, 0.0);

  float32x4 + null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4 - null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4 * null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4 / null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.lessThan(null);
  //                 ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.lessThanOrEqual(null);
  //                        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.greaterThan(null);
  //                    ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.greaterThanOrEqual(null);
  //                           ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.equal(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.notEqual(null);
  //                 ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.scale(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.clamp(null, float32x4);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.clamp(float32x4, null);
  //                         ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.shuffle(null);
  //                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.shuffleMix(float32x4, null);
  //                              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.shuffleMix(null, 0);
  //                   ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.withX(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.withY(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.withZ(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.withW(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.min(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float32x4.max(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float32x4(null, 0.0, 0.0, 0.0);
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float32x4(0.0, null, 0.0, 0.0);
  //             ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float32x4(0.0, 0.0, null, 0.0);
  //                  ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float32x4(0.0, 0.0, 0.0, null);
  //                       ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Float32x4.splat
  Float32x4.splat(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Float64x2
  final float64x2 = Float64x2(0.0, 0.0);
  float64x2 + null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2 - null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2 * null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2 / null;
  //          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.scale(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.clamp(null, float64x2);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.clamp(float64x2, null);
  //                         ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.withX(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.withY(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float64x2(null, 0.0);
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Float64x2(0.0, null);
  //             ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.min(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  float64x2.max(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Float64x2.splat
  Float64x2.splat(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Int32x4
  final int32x4 = Int32x4(0, 0, 0, 0);
  int32x4 + null;
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4 - null;
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4 ^ null;
  //           ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4 & null;
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4 | null;
  //        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.shuffle(null);
  //              ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.shuffleMix(int32x4, null);
  //                          ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.shuffleMix(null, 0);
  //                 ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withX(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withY(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withZ(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withW(null);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withFlagX(null);
  //                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withFlagY(null);
  //                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withFlagZ(null);
  //                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.withFlagW(null);
  //                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4(null, 0, 0, 0);
  //      ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4(0, null, 0, 0);
  //         ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4(0, 0, null, 0);
  //            ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4(0, 0, 0, null);
  //               ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.select(null, float32x4);
  //             ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int32x4.select(float32x4, null);
  //                        ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  // Int32x4.bool
  Int32x4.bool(null, false, false, false);
  //           ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4.bool(false, null, false, false);
  //                  ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4.bool(false, false, null, false);
  //                         ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Int32x4.bool(false, false, false, null);
  //                                ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}
