// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_FLOATING_POINT_H_
#define RUNTIME_PLATFORM_FLOATING_POINT_H_

#include <math.h>

inline double fmod_ieee(double x, double y) {
  return fmod(x, y);
}
inline double atan2_ieee(double y, double x) {
  return atan2(y, x);
}

#endif  // RUNTIME_PLATFORM_FLOATING_POINT_H_
