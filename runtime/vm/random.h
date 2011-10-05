// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RANDOM_H_
#define VM_RANDOM_H_

#include "vm/allocation.h"

namespace dart {

class Random : public AllStatic {
 public:
  static const int32_t kDefaultRandomSeed = 294967;

  // Generate a random number in the range [1, 2^31[ (will never return 0 or a
  // negative number). Not cryptographically safe.
  static int32_t RandomInt32();
};

}  // namespace dart

#endif  // VM_RANDOM_H_
