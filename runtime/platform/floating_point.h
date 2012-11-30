// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_FLOATING_POINT_H_
#define PLATFORM_FLOATING_POINT_H_

inline double fmod_ieee(double x, double y) { return fmod(x, y); }
inline double atan2_ieee(double y, double x) { return atan2(y, x); }

#endif  // PLATFORM_FLOATING_POINT_H_
