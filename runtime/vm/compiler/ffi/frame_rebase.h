// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_FRAME_REBASE_H_
#define RUNTIME_VM_COMPILER_FFI_FRAME_REBASE_H_

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/runtime_api.h"
#include "vm/thread.h"

namespace dart {

namespace compiler {

namespace ffi {

// Describes a change of stack frame where the stack or base register or stack
// offset may change. This class allows easily rebasing stack locations across
// frame manipulations.
//
// If the stack offset register matches 'old_base', it is changed to 'new_base'
// and 'stack_delta' (# of slots) is applied.
class FrameRebase : public ValueObject {
 public:
  FrameRebase(const Register old_base,
              const Register new_base,
              intptr_t stack_delta)
      : old_base_(old_base), new_base_(new_base), stack_delta_(stack_delta) {}

  Location Rebase(const Location loc) const;

 private:
  const Register old_base_;
  const Register new_base_;
  const intptr_t stack_delta_;
};

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_FRAME_REBASE_H_
