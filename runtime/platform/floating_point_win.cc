// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include <limits>  // NOLINT

// Taken from third_party/v8/src/platform-win32.cc
double fmod_ieee(double x, double y) {
  // x is dividend, y is divisor.
  // Work around MS fmod bugs. ISO Standard says:
  // If dividend is finite and divisor is an infinity or
  //    dividend is a zero and divisor is nonzero finite,
  // then dividend is returned.
  if (!(_finite(x) && (!_finite(y) && !isnan(y))) &&
      !(x == 0 && (y != 0 && _finite(y)))) {
    x = fmod(x, y);
  }
  return x;
}

// Bring MSVC atan2 behavior in line with ISO standard.
// MSVC atan2 returns NaN when x and y are either +infinity or -infinity.
// Per ISO standard:
//  - If y is +/-infinity and x is -infinity, +/-3*pi/4 is returned.
//  - If y is +/-infinity and x is +infinity, +/-pi/4 is returned.
double atan2_ieee(double x, double y) {
  int cls_x = _fpclass(x);
  int cls_y = _fpclass(y);
  if (((cls_x & (_FPCLASS_PINF | _FPCLASS_NINF)) != 0) &&
      ((cls_y & (_FPCLASS_PINF | _FPCLASS_NINF)) != 0)) {
    // atan2 values at infinities listed above are the same as values
    // at (+/-1, +/-1). index_x is 0, when x is +infinty, 1 when x is -infinty.
    // Same is with index_y.
    int index_x = (cls_x & _FPCLASS_PINF) != 0 ? 0 : 1;
    int index_y = (cls_y & _FPCLASS_PINF) != 0 ? 0 : 1;
    static double atans_at_infinities[2][2] =
      { { atan2(1.,  1.), atan2(1.,  -1.) },
        { atan2(-1., 1.), atan2(-1., -1.) } };
    return atans_at_infinities[index_x][index_y];
  } else {
    return atan2(x, y);
  }
}

#endif  // defined(TARGET_OS_WINDOWS)
