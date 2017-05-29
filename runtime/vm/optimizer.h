// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OPTIMIZER_H_
#define RUNTIME_VM_OPTIMIZER_H_

#include "vm/globals.h"

#include "vm/growable_array.h"

namespace dart {

class Optimizer {
 public:
  // Tries to add cid tests to 'results' so that no deoptimization is
  // necessary for common number-related type tests.  Unconditionally adds an
  // entry for the Smi type to the start of the array.
  // TODO(srdjan): Do also for other than numeric types.
  static bool SpecializeTestCidsForNumericTypes(
      ZoneGrowableArray<intptr_t>* results,
      const AbstractType& type);
};

}  // namespace dart

#endif  // RUNTIME_VM_OPTIMIZER_H_
