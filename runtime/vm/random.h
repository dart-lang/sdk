// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RANDOM_H_
#define RUNTIME_VM_RANDOM_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class Random {
 public:
  Random();
  // Seed must be non-zero.
  explicit Random(uint64_t seed);
  ~Random();

  uint32_t NextUInt32();
  uint64_t NextUInt64() {
    return (static_cast<uint64_t>(NextUInt32()) << 32) |
           static_cast<uint64_t>(NextUInt32());
  }

 private:
  void NextState();
  void Initialize(uint64_t seed);

  uint64_t _state;

  DISALLOW_COPY_AND_ASSIGN(Random);
};

}  // namespace dart

#endif  // RUNTIME_VM_RANDOM_H_
