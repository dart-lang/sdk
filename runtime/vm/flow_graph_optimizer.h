// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_OPTIMIZER_H_
#define VM_FLOW_GRAPH_OPTIMIZER_H_

#include "vm/intermediate_language.h"
#include "vm/flow_graph.h"

namespace dart {

template <typename T> class GrowableArray;
template <typename T> class DirectChainedHashMap;
template <typename T> class PointerKeyValueTrait;

class FlowGraphOptimizer : public FlowGraphVisitor {
 public:
  FlowGraphOptimizer(FlowGraph* flow_graph,
                     GrowableArray<Field*>* guarded_fields)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph),
        guarded_fields_(guarded_fields) { }
  virtual ~FlowGraphOptimizer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  // Use ICData to optimize, replace or eliminate instructions.
  void ApplyICData();

  // Use propagated class ids to optimize, replace or eliminate instructions.
  void ApplyClassIds();

  // Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
  // shift can be a truncating Smi shift-left and result is always Smi.
  void TryOptimizeLeftShiftWithBitAndPattern();

  void Canonicalize();

  void EliminateDeadPhis();

  void SelectRepresentations();

  void InferSmiRanges();

  virtual void VisitStaticCall(StaticCallInstr* instr);
  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitRelationalOp(RelationalOpInstr* instr);
  virtual void VisitEqualityCompare(EqualityCompareInstr* instr);
  virtual void VisitBranch(BranchInstr* instr);
  virtual void VisitStrictCompare(StrictCompareInstr* instr);

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    Definition::UseKind use_kind) {
    flow_graph_->InsertBefore(next, instr, env, use_kind);
  }

 private:
  // Attempt to build ICData for call using propagated class-ids.
  bool TryCreateICData(InstanceCallInstr* call);

  void SpecializePolymorphicInstanceCall(PolymorphicInstanceCallInstr* call);

  intptr_t PrepareIndexedOp(InstanceCallInstr* call,
                            intptr_t class_id,
                            Definition** array,
                            Definition** index);
  bool TryReplaceWithStoreIndexed(InstanceCallInstr* call);
  void BuildStoreIndexed(InstanceCallInstr* call,
                         const ICData& value_check,
                         intptr_t class_id);
  bool TryReplaceWithLoadIndexed(InstanceCallInstr* call);

  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call,
                               const ICData& unary_ic_data);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);
  void ReplaceWithInstanceOf(InstanceCallInstr* instr);
  void ReplaceWithTypeCast(InstanceCallInstr* instr);

  LoadIndexedInstr* BuildStringCodeUnitAt(InstanceCallInstr* call,
                                          intptr_t cid);

  bool BuildByteArrayViewLoad(InstanceCallInstr* call,
                              intptr_t receiver_cid,
                              intptr_t view_cid);
  bool BuildByteArrayViewStore(InstanceCallInstr* call,
                               intptr_t receiver_cid,
                               intptr_t view_cid);
  void PrepareByteArrayViewOp(InstanceCallInstr* call,
                              intptr_t receiver_cid,
                              intptr_t view_cid,
                              Definition** array);

  // Insert a check of 'to_check' determined by 'unary_checks'.  If the
  // check fails it will deoptimize to 'deopt_id' using the deoptimization
  // environment 'deopt_environment'.  The check is inserted immediately
  // before 'insert_before'.
  void AddCheckClass(Definition* to_check,
                     const ICData& unary_checks,
                     intptr_t deopt_id,
                     Environment* deopt_environment,
                     Instruction* insert_before);

  // Insert a Smi check if needed.
  void AddCheckSmi(Definition* to_check,
                   intptr_t deopt_id,
                   Environment* deopt_environment,
                   Instruction* insert_before);

  // Add a class check for a call's first argument immediately before the
  // call, using the call's IC data to determine the check, and the call's
  // deopt ID and deoptimization environment if the check fails.
  void AddReceiverCheck(InstanceCallInstr* call);

  void ReplaceCall(Definition* call, Definition* replacement);

  void InsertConversionsFor(Definition* def);

  void InsertConversion(Representation from,
                        Representation to,
                        Value* use,
                        Instruction* insert_before,
                        Instruction* deopt_target);

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call) const;
  bool MethodExtractorNeedsClassCheck(InstanceCallInstr* call) const;

  void InlineImplicitInstanceGetter(InstanceCallInstr* call);
  void InlineArrayLengthGetter(InstanceCallInstr* call,
                               intptr_t length_offset,
                               bool is_immutable,
                               MethodRecognizer::Kind kind);
  void InlineGrowableArrayCapacityGetter(InstanceCallInstr* call);
  void InlineStringLengthGetter(InstanceCallInstr* call);
  void InlineStringIsEmptyGetter(InstanceCallInstr* call);

  RawBool* InstanceOfAsBool(const ICData& ic_data,
                            const AbstractType& type) const;

  void ReplaceWithMathCFunction(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);

  void HandleRelationalOp(RelationalOpInstr* comp);

  // Visit an equality compare.  The current instruction can be the
  // comparison itself or a branch on the comparison.
  template <typename T>
  void HandleEqualityCompare(EqualityCompareInstr* comp,
                             T current_instruction);

  void OptimizeLeftShiftBitAndSmiOp(Definition* bit_and_instr,
                                    Definition* left_instr,
                                    Definition* right_instr);

  void AddToGuardedFields(Field* field);

  FlowGraph* flow_graph_;
  GrowableArray<Field*>* guarded_fields_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};


class ParsedFunction;


// Loop invariant code motion.
class LICM : public ValueObject {
 public:
  explicit LICM(FlowGraph* flow_graph);

  void Optimize();

 private:
  FlowGraph* flow_graph() const { return flow_graph_; }

  void Hoist(ForwardInstructionIterator* it,
             BlockEntryInstr* pre_header,
             Instruction* current);

  void TryHoistCheckSmiThroughPhi(ForwardInstructionIterator* it,
                                  BlockEntryInstr* header,
                                  BlockEntryInstr* pre_header,
                                  CheckSmiInstr* current);

  FlowGraph* const flow_graph_;
};


// A simple common subexpression elimination based
// on the dominator tree.
class DominatorBasedCSE : public AllStatic {
 public:
  // Return true, if the optimization changed the flow graph.
  // False, if nothing changed.
  static bool Optimize(FlowGraph* graph);

 private:
  static bool OptimizeRecursive(
      FlowGraph* graph,
      BlockEntryInstr* entry,
      DirectChainedHashMap<PointerKeyValueTrait<Instruction> >* map);
};


// Sparse conditional constant propagation and unreachable code elimination.
// Assumes that use lists are computed and preserves them.
class ConstantPropagator : public FlowGraphVisitor {
 public:
  ConstantPropagator(FlowGraph* graph,
                     const GrowableArray<BlockEntryInstr*>& ignored);

  static void Optimize(FlowGraph* graph);

  // Only visit branches to optimize away unreachable blocks discovered
  // by range analysis.
  static void OptimizeBranches(FlowGraph* graph);

  // Used to initialize the abstract value of definitions.
  static RawObject* Unknown() { return Object::transition_sentinel().raw(); }

 private:
  void Analyze();
  void VisitBranches();
  void Transform();

  void SetReachable(BlockEntryInstr* block);
  void SetValue(Definition* definition, const Object& value);

  // Assign the join (least upper bound) of a pair of abstract values to the
  // first one.
  void Join(Object* left, const Object& right);

  bool IsUnknown(const Object& value) {
    return value.raw() == unknown_.raw();
  }
  bool IsNonConstant(const Object& value) {
    return value.raw() == non_constant_.raw();
  }
  bool IsConstant(const Object& value) {
    return !IsNonConstant(value) && !IsUnknown(value);
  }

  virtual void VisitBlocks() { UNREACHABLE(); }

#define DECLARE_VISIT(type) virtual void Visit##type(type##Instr* instr);
  FOR_EACH_INSTRUCTION(DECLARE_VISIT)
#undef DECLARE_VISIT

  FlowGraph* graph_;

  // Sentinels for unknown constant and non-constant values.
  const Object& unknown_;
  const Object& non_constant_;

  // Analysis results. For each block, a reachability bit.  Indexed by
  // preorder number.
  BitVector* reachable_;

  // Definitions can move up the lattice twice, so we use a mark bit to
  // indicate that they are already on the worklist in order to avoid adding
  // them again.  Indexed by SSA temp index.
  BitVector* definition_marks_;

  // Worklists of blocks and definitions.
  GrowableArray<BlockEntryInstr*> block_worklist_;
  GrowableArray<Definition*> definition_worklist_;
};


// Rewrite branches to eliminate materialization of boolean values after
// inlining, and to expose other optimizations (e.g., constant folding of
// branches, unreachable code elimination).
class BranchSimplifier : public AllStatic {
 public:
  static void Simplify(FlowGraph* flow_graph);

 private:
  // Match an instance of the pattern to rewrite.  See the implementation
  // for the patterns that are handled by this pass.
  static bool Match(JoinEntryInstr* block);

  // Replace a target entry instruction with a join entry instruction.  Does
  // not update the original target's predecessors to point to the new block
  // and does not replace the target in already computed block order lists.
  static JoinEntryInstr* ToJoinEntry(TargetEntryInstr* target);

  // Duplicate a constant, assigning it a new SSA name.
  static ConstantInstr* CloneConstant(FlowGraph* flow_graph,
                                      ConstantInstr* constant);

  // Duplicate a branch while replacing its comparison's left and right
  // inputs.
  static BranchInstr* CloneBranch(BranchInstr* branch,
                                  Value* left,
                                  Value* right);
};


// Rewrite diamond control flow patterns that materialize values to use more
// efficient branchless code patterns if such are supported on the current
// platform.
class IfConverter : public AllStatic {
 public:
  static void Simplify(FlowGraph* flow_graph);
};


}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
