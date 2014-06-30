// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_MATH_H_
#define PLATFORM_MATH_H_

// We must take these math functions from the C++ header file as long as we
// are using the STL. Otherwise the Android build will break due to confusion
// between C++ and C headers when math.h is also included.
#include <cmath>

#define isinf(val) std::isinf(val)
#define isnan(val) std::isnan(val)
#define signbit(val) std::signbit(val)
#define isfinite(val) std::isfinite(val)

#endif  // PLATFORM_MATH_H_
