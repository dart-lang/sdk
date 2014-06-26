// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_FLOW_GRAPH_OPTIMIZER_H_
#define VM_FLOW_GRAPH_OPTIMIZER_H_

#include "vm/intermediate_language.h"
#include "vm/flow_graph.h"

namespace dart {

class CSEInstructionMap;
template <typename T> class GrowableArray;
class ParsedFunction;

class FlowGraphOptimizer : public FlowGraphVisitor {
 public:
  explicit FlowGraphOptimizer(FlowGraph* flow_graph)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph) { }
  virtual ~FlowGraphOptimizer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  // Use ICData to optimize, replace or eliminate instructions.
  void ApplyICData();

  // Use propagated class ids to optimize, replace or eliminate instructions.
  void ApplyClassIds();

  // Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
  // shift can be a truncating Smi shift-left and result is always Smi.
  // Merge instructions (only per basic-block).
  void TryOptimizePatterns();

  // Returns true if any instructions were canonicalized away.
  bool Canonicalize();

  void EliminateDeadPhis();

  void SelectRepresentations();

  void InferIntRanges();

  void AnalyzeTryCatch();

  bool TryInlineRecognizedMethod(intptr_t receiver_cid,
                                 const Function& target,
                                 Instruction* call,
                                 Definition* receiver,
                                 intptr_t token_pos,
                                 const ICData& ic_data,
                                 TargetEntryInstr** entry,
                                 Definition** last);

  // Remove environments from the instructions which do not deoptimize.
  void EliminateEnvironments();

  virtual void VisitStaticCall(StaticCallInstr* instr);
  virtual void VisitInstanceCall(InstanceCallInstr* instr);
  virtual void VisitStoreInstanceField(StoreInstanceFieldInstr* instr);

  void InsertBefore(Instruction* next,
                    Instruction* instr,
                    Environment* env,
                    FlowGraph::UseKind use_kind) {
    flow_graph_->InsertBefore(next, instr, env, use_kind);
  }

 private:
  // Attempt to build ICData for call using propagated class-ids.
  bool TryCreateICData(InstanceCallInstr* call);
  const ICData& TrySpecializeICData(const ICData& ic_data, intptr_t cid);

  void SpecializePolymorphicInstanceCall(PolymorphicInstanceCallInstr* call);

  bool TryReplaceWithStoreIndexed(InstanceCallInstr* call);
  bool InlineSetIndexed(MethodRecognizer::Kind kind,
                        const Function& target,
                        Instruction* call,
                        Definition* receiver,
                        intptr_t token_pos,
                        const ICData* ic_data,
                        const ICData& value_check,
                        TargetEntryInstr** entry,
                        Definition** last);
  bool TryReplaceWithLoadIndexed(InstanceCallInstr* call);
  bool InlineGetIndexed(MethodRecognizer::Kind kind,
                        Instruction* call,
                        Definition* receiver,
                        const ICData& ic_data,
                        TargetEntryInstr** entry,
                        Definition** last);
  intptr_t PrepareInlineIndexedOp(Instruction* call,
                                  intptr_t array_cid,
                                  Definition** array,
                                  Definition* index,
                                  Instruction** cursor);


  bool TryReplaceWithBinaryOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithUnaryOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryReplaceWithEqualityOp(InstanceCallInstr* call, Token::Kind op_kind);
  bool TryReplaceWithRelationalOp(InstanceCallInstr* call, Token::Kind op_kind);

  bool TryInlineInstanceGetter(InstanceCallInstr* call);
  bool TryInlineInstanceSetter(InstanceCallInstr* call,
                               const ICData& unary_ic_data);

  bool TryInlineInstanceMethod(InstanceCallInstr* call);
  bool TryInlineFloat32x4Constructor(StaticCallInstr* call,
                                     MethodRecognizer::Kind recognized_kind);
  bool TryInlineFloat64x2Constructor(StaticCallInstr* call,
                                     MethodRecognizer::Kind recognized_kind);
  bool TryInlineInt32x4Constructor(StaticCallInstr* call,
                                    MethodRecognizer::Kind recognized_kind);
  bool TryInlineFloat32x4Method(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);
  bool TryInlineFloat64x2Method(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);
  bool TryInlineInt32x4Method(InstanceCallInstr* call,
                               MethodRecognizer::Kind recognized_kind);
  void ReplaceWithInstanceOf(InstanceCallInstr* instr);
  void ReplaceWithTypeCast(InstanceCallInstr* instr);

  bool TryReplaceInstanceCallWithInline(InstanceCallInstr* call);

  LoadFieldInstr* BuildLoadStringLength(Definition* str);

  Definition* PrepareInlineStringIndexOp(Instruction* call,
                                         intptr_t cid,
                                         Definition* str,
                                         Definition* index,
                                         Instruction* cursor);

  bool InlineStringCodeUnitAt(Instruction* call,
                              intptr_t cid,
                              TargetEntryInstr** entry,
                              Definition** last);

  bool InlineStringBaseCharAt(Instruction* call,
                              intptr_t cid,
                              TargetEntryInstr** entry,
                              Definition** last);

  bool InlineByteArrayViewLoad(Instruction* call,
                               Definition* receiver,
                               intptr_t array_cid,
                               intptr_t view_cid,
                               const ICData& ic_data,
                               TargetEntryInstr** entry,
                               Definition** last);

  bool InlineByteArrayViewStore(const Function& target,
                                Instruction* call,
                                Definition* receiver,
                                intptr_t array_cid,
                                intptr_t view_cid,
                                const ICData& ic_data,
                                TargetEntryInstr** entry,
                                Definition** last);

  intptr_t PrepareInlineByteArrayViewOp(Instruction* call,
                                        intptr_t array_cid,
                                        intptr_t view_cid,
                                        Definition** array,
                                        Definition* index,
                                        Instruction** cursor);

  bool BuildByteArrayViewLoad(InstanceCallInstr* call,
                              intptr_t view_cid);
  bool BuildByteArrayViewStore(InstanceCallInstr* call,
                               intptr_t view_cid);

  // Insert a check of 'to_check' determined by 'unary_checks'.  If the
  // check fails it will deoptimize to 'deopt_id' using the deoptimization
  // environment 'deopt_environment'.  The check is inserted immediately
  // before 'insert_before'.
  void AddCheckClass(Definition* to_check,
                     const ICData& unary_checks,
                     intptr_t deopt_id,
                     Environment* deopt_environment,
                     Instruction* insert_before);
  Instruction* GetCheckClass(Definition* to_check,
                             const ICData& unary_checks,
                             intptr_t deopt_id,
                             intptr_t token_pos);

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

  void ConvertUse(Value* use, Representation from);
  void ConvertEnvironmentUse(Value* use, Representation from);

  void InsertConversion(Representation from,
                        Representation to,
                        Value* use,
                        bool is_environment_use);

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call) const;
  bool MethodExtractorNeedsClassCheck(InstanceCallInstr* call) const;

  bool InlineFloat32x4Getter(InstanceCallInstr* call,
                             MethodRecognizer::Kind getter);
  bool InlineFloat64x2Getter(InstanceCallInstr* call,
                             MethodRecognizer::Kind getter);
  bool InlineInt32x4Getter(InstanceCallInstr* call,
                            MethodRecognizer::Kind getter);
  bool InlineFloat32x4BinaryOp(InstanceCallInstr* call,
                               Token::Kind op_kind);
  bool InlineInt32x4BinaryOp(InstanceCallInstr* call,
                              Token::Kind op_kind);
  bool InlineFloat64x2BinaryOp(InstanceCallInstr* call,
                               Token::Kind op_kind);
  void InlineImplicitInstanceGetter(InstanceCallInstr* call);

  RawBool* InstanceOfAsBool(const ICData& ic_data,
                            const AbstractType& type,
                            ZoneGrowableArray<intptr_t>* results) const;

  void ReplaceWithMathCFunction(InstanceCallInstr* call,
                                MethodRecognizer::Kind recognized_kind);

  void OptimizeLeftShiftBitAndSmiOp(Definition* bit_and_instr,
                                    Definition* left_instr,
                                    Definition* right_instr);
  void TryMergeTruncDivMod(GrowableArray<BinarySmiOpInstr*>* merge_candidates);
  void TryMergeMathUnary(GrowableArray<MathUnaryInstr*>* merge_candidates);

  void AppendLoadIndexedForMerged(Definition* instr, intptr_t ix, intptr_t cid);
  void AppendExtractNthOutputForMerged(Definition* instr, intptr_t ix,
                                       Representation rep, intptr_t cid);
  bool TryStringLengthOneEquality(InstanceCallInstr* call, Token::Kind op_kind);

  Isolate* isolate() const { return flow_graph_->isolate(); }

  FlowGraph* flow_graph_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};


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
      CSEInstructionMap* map);
};


class DeadStoreElimination : public AllStatic {
 public:
  static void Optimize(FlowGraph* graph);
};


class DeadCodeElimination : public AllStatic {
 public:
  static void EliminateDeadPhis(FlowGraph* graph);
};


// Sparse conditional constant propagation and unreachable code elimination.
// Assumes that use lists are computed and preserves them.
class ConstantPropagator : public FlowGraphVisitor {
 public:
  ConstantPropagator(FlowGraph* graph,
                     const GrowableArray<BlockEntryInstr*>& ignored);

  static void Optimize(FlowGraph* graph);

  // (1) Visit branches to optimize away unreachable blocks discovered  by range
  // analysis.
  // (2) Eliminate branches that have the same true- and false-target: For
  // example, this occurs after expressions like
  //
  // if (a == null || b == null) {
  //   ...
  // }
  //
  // where b is known to be null.
  static void OptimizeBranches(FlowGraph* graph);

  // Used to initialize the abstract value of definitions.
  static RawObject* Unknown() { return Object::unknown_constant().raw(); }

 private:
  void Analyze();
  void VisitBranches();
  void Transform();
  void EliminateRedundantBranches();

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

  void HandleBinaryOp(Definition* instr,
                      Token::Kind op_kind,
                      const Value& left,
                      const Value& right);

  virtual void VisitBlocks() { UNREACHABLE(); }

#define DECLARE_VISIT(type) virtual void Visit##type(type##Instr* instr);
  FOR_EACH_INSTRUCTION(DECLARE_VISIT)
#undef DECLARE_VISIT

  Isolate* isolate() const { return graph_->isolate(); }

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

  // Replace a target entry instruction with a join entry instruction.  Does
  // not update the original target's predecessors to point to the new block
  // and does not replace the target in already computed block order lists.
  static JoinEntryInstr* ToJoinEntry(Isolate* isolate,
                                     TargetEntryInstr* target);

 private:
  // Match an instance of the pattern to rewrite.  See the implementation
  // for the patterns that are handled by this pass.
  static bool Match(JoinEntryInstr* block);

  // Duplicate a branch while replacing its comparison's left and right
  // inputs.
  static BranchInstr* CloneBranch(Isolate* isolate,
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


class AllocationSinking : public ZoneAllocated {
 public:
  explicit AllocationSinking(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        materializations_(5) { }

  void Optimize();

  void DetachMaterializations();

 private:
  void InsertMaterializations(AllocateObjectInstr* alloc);

  void CreateMaterializationAt(
      Instruction* exit,
      AllocateObjectInstr* alloc,
      const Class& cls,
      const ZoneGrowableArray<const Object*>& fields);

  Isolate* isolate() const { return flow_graph_->isolate(); }

  FlowGraph* flow_graph_;

  GrowableArray<MaterializeObjectInstr*> materializations_;
};


// Optimize spill stores inside try-blocks by identifying values that always
// contain a single known constant at catch block entry.
class TryCatchAnalyzer : public AllStatic {
 public:
  static void Optimize(FlowGraph* flow_graph);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
