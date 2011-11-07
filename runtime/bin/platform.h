// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PLATFORM_H_
#define BIN_PLATFORM_H_

#include "bin/builtin.h"

class Platform {
 public:
  static int NumberOfProcessors();
  static const char* OperatingSystem();

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Platform);
};

#endif  // BIN_PLATFORM_H_
