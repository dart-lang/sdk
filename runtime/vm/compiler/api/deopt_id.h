// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_API_DEOPT_ID_H_
#define RUNTIME_VM_COMPILER_API_DEOPT_ID_H_

#include "platform/allocation.h"

namespace dart {

// Deoptimization Id logic.
//
// Deoptimization ids are used to refer to deoptimization points, at which
// control can enter unoptimized code from the optimized version of the code.
//
// Note: any instruction that does a call has two deoptimization points,
// one before the call and one after the call - so that we could deoptimize
// to either before or after the call depending on whether the same call
// already occured in the optimized code (and potentially produced
// observable side-effects) or not.
//
// To simplify implementation we always allocate two deopt ids (one for before
// point and one for the after point).
class DeoptId : public AllStatic {
 public:
  static constexpr intptr_t kNone = -1;

  static inline intptr_t Next(intptr_t deopt_id) { return deopt_id + kStep; }

  static inline intptr_t ToDeoptAfter(intptr_t deopt_id) {
    ASSERT(IsDeoptBefore(deopt_id));
    return deopt_id + kAfterOffset;
  }

  static inline bool IsDeoptBefore(intptr_t deopt_id) {
    return (deopt_id % kStep) == kBeforeOffset;
  }

  static inline bool IsDeoptAfter(intptr_t deopt_id) {
    return (deopt_id % kStep) == kAfterOffset;
  }

 private:
  static constexpr intptr_t kStep = 2;
  static constexpr intptr_t kBeforeOffset = 0;
  static constexpr intptr_t kAfterOffset = 1;
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_API_DEOPT_ID_H_
