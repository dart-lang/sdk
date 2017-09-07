// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_
#define RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_

#include "runtime/vm/compiler/call_specializer.h"

namespace dart {

class Precompiler;

class AotCallSpecializer : public CallSpecializer {
 public:
  AotCallSpecializer(Precompiler* precompiler,
                     FlowGraph* flow_graph,
                     bool use_speculative_inlining,
                     GrowableArray<intptr_t>* inlining_black_list);

  virtual ~AotCallSpecializer() {}

  // TODO(dartbug.com/30633) these method has nothing to do with
  // specialization of calls. They are here for historical reasons.
  // Find a better place for them.
  void ReplaceArrayBoundChecks();

  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitPolymorphicInstanceCall(
      PolymorphicInstanceCallInstr* instr);

  virtual bool TryReplaceInstanceOfWithRangeCheck(InstanceCallInstr* call,
                                                  const AbstractType& type);
  virtual bool TryReplaceTypeCastWithRangeCheck(InstanceCallInstr* call,
                                                const AbstractType& type);

 private:
  // Attempt to build ICData for call using propagated class-ids.
  virtual bool TryCreateICData(InstanceCallInstr* call);

  bool TryCreateICDataForUniqueTarget(InstanceCallInstr* call);

  bool RecognizeRuntimeTypeGetter(InstanceCallInstr* call);
  bool TryReplaceWithHaveSameRuntimeType(InstanceCallInstr* call);

  bool TryInlineFieldAccess(InstanceCallInstr* call);

  virtual bool IsAllowedForInlining(intptr_t deopt_id) const;

  Precompiler* precompiler_;

  const bool use_speculative_inlining_;

  GrowableArray<intptr_t>* inlining_black_list_;

  bool has_unique_no_such_method_;

  DISALLOW_COPY_AND_ASSIGN(AotCallSpecializer);
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_AOT_AOT_CALL_SPECIALIZER_H_
