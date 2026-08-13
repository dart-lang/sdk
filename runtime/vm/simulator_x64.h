// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SIMULATOR_X64_H_
#define RUNTIME_VM_SIMULATOR_X64_H_

#ifndef RUNTIME_VM_SIMULATOR_H_
#error Do not include simulator_x64.h directly; use simulator.h.
#endif

#include "vm/constants.h"
#include "vm/random.h"

namespace dart {

class Thread;

class Simulator {
 public:
  static constexpr uword kSimulatorStackUnderflowSize = 64;

  Simulator();
  ~Simulator();

  static Simulator* Current();

  int64_t Call(int64_t entry,
               int64_t parameter0,
               int64_t parameter1,
               int64_t parameter2,
               int64_t parameter3,
               bool fp_return = false,
               bool fp_args = false);

  // Runtime and native call support.
  enum CallKind {
    kRuntimeCall,
    kLeafRuntimeCall,
    kLeafFloatRuntimeCall,
    kNativeCallWrapper
  };
  static uword RedirectExternalReference(uword function,
                                         CallKind call_kind,
                                         int argument_count);

  static uword FunctionForRedirect(uword redirect);

  void JumpToFrame(uword pc, uword sp, uword fp, Thread* thread);

  uint64_t get_register(Register rs) const { return 0; }
  uint64_t get_pc() const { return 0; }
  uint64_t get_sp() const { return 0; }
  uint64_t get_fp() const { return 0; }
  uint64_t get_lr() const { return 0; }

  // High address.
  uword stack_base() const { return 0; }
  // Limit for StackOverflowError.
  uword overflow_stack_limit() const { return 0; }
  // Low address.
  uword stack_limit() const { return 0; }

  // Accessor to the instruction counter.
  uint64_t get_icount() const { return 0; }

  // Call on program start.
  static void Init();

 private:
  DISALLOW_COPY_AND_ASSIGN(Simulator);
};

}  // namespace dart

#endif  // RUNTIME_VM_SIMULATOR_X64_H_
