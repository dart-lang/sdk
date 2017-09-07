// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_JIT_JIT_CALL_SPECIALIZER_H_
#define RUNTIME_VM_COMPILER_JIT_JIT_CALL_SPECIALIZER_H_

#include "vm/compiler/call_specializer.h"

namespace dart {

class JitCallSpecializer : public CallSpecializer {
 public:
  explicit JitCallSpecializer(FlowGraph* flow_graph);

  virtual ~JitCallSpecializer() {}

  virtual void VisitInstanceCall(InstanceCallInstr* instr);

  // TODO(dartbug.com/30633) these methods have nothing to do with
  // specialization of calls. They are here for historical reasons.
  // Find a better place for them.
  virtual void VisitAllocateContext(AllocateContextInstr* instr);
  virtual void VisitStoreInstanceField(StoreInstanceFieldInstr* instr);

 private:
  virtual bool IsAllowedForInlining(intptr_t deopt_id) const;

  DISALLOW_COPY_AND_ASSIGN(JitCallSpecializer);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_JIT_JIT_CALL_SPECIALIZER_H_
