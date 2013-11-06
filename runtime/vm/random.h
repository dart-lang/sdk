// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_RANDOM_H_
#define VM_RANDOM_H_

#include "vm/globals.h"
#include "vm/allocation.h"

namespace dart {

class Random : public ValueObject {
 public:
  Random();
  ~Random();

  uint32_t NextUInt32();

 private:
  void NextState();

  uint64_t _state;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Random);
};

}  // namespace dart

#endif  // VM_RANDOM_H_
