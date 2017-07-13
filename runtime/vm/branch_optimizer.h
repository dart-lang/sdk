// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BRANCH_OPTIMIZER_H_
#define RUNTIME_VM_BRANCH_OPTIMIZER_H_

#include "vm/allocation.h"

namespace dart {

class FlowGraph;
class JoinEntryInstr;
class Zone;
class TargetEntryInstr;
class Value;
class BranchInstr;

// Rewrite branches to eliminate materialization of boolean values after
// inlining, and to expose other optimizations (e.g., constant folding of
// branches, unreachable code elimination).
class BranchSimplifier : public AllStatic {
 public:
  static void Simplify(FlowGraph* flow_graph);

  // Replace a target entry instruction with a join entry instruction.  Does
  // not update the original target's predecessors to point to the new block
  // and does not replace the target in already computed block order lists.
  static JoinEntryInstr* ToJoinEntry(Zone* zone, TargetEntryInstr* target);

 private:
  // Match an instance of the pattern to rewrite.  See the implementation
  // for the patterns that are handled by this pass.
  static bool Match(JoinEntryInstr* block);

  // Duplicate a branch while replacing its comparison's left and right
  // inputs.
  static BranchInstr* CloneBranch(Zone* zone,
                                  BranchInstr* branch,
                                  Value* new_left,
                                  Value* new_right);
};

// Rewrite diamond control flow patterns that materialize values to use more
// efficient branchless code patterns if such are supported on the current
// platform.
class IfConverter : public AllStatic {
 public:
  static void Simplify(FlowGraph* flow_graph);
};

}  // namespace dart

#endif  // RUNTIME_VM_BRANCH_OPTIMIZER_H_
