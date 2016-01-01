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
  FlowGraphOptimizer(
      FlowGraph* flow_graph,
      bool use_speculative_inlining,
      GrowableArray<intptr_t>* inlining_black_list)
      : FlowGraphVisitor(flow_graph->reverse_postorder()),
        flow_graph_(flow_graph),
        use_speculative_inlining_(use_speculative_inlining),
        inlining_black_list_(inlining_black_list) {
    ASSERT(!use_speculative_inlining || (inlining_black_list != NULL));
  }
  virtual ~FlowGraphOptimizer() {}

  FlowGraph* flow_graph() const { return flow_graph_; }

  // Add ICData to InstanceCalls, so that optimizations can be run on them.
  // TODO(srdjan): StaticCals as well?
  void PopulateWithICData();

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

  void WidenSmiToInt32();

  void InferIntRanges();

  void SelectIntegerInstructions();

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
  virtual void VisitAllocateContext(AllocateContextInstr* instr);
  virtual void VisitLoadCodeUnits(LoadCodeUnitsInstr* instr);

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

  bool TryReplaceWithIndexedOp(InstanceCallInstr* call);
  bool InlineSetIndexed(MethodRecognizer::Kind kind,
                        const Function& target,
                        Instruction* call,
                        Definition* receiver,
                        intptr_t token_pos,
                        const ICData& value_check,
                        TargetEntryInstr** entry,
                        Definition** last);
  bool InlineGetIndexed(MethodRecognizer::Kind kind,
                        Instruction* call,
                        Definition* receiver,
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

  bool TryInlineInstanceGetter(InstanceCallInstr* call,
                               bool allow_check = true);
  bool TryInlineInstanceSetter(InstanceCallInstr* call,
                               const ICData& unary_ic_data,
                               bool allow_check = true);

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
  bool TypeCheckAsClassEquality(const AbstractType& type);
  void ReplaceWithTypeCast(InstanceCallInstr* instr);

  bool TryReplaceInstanceCallWithInline(InstanceCallInstr* call);

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

  bool InlineDoubleOp(Token::Kind op_kind,
                      Instruction* call,
                      TargetEntryInstr** entry,
                      Definition** last);

  bool InlineByteArrayBaseLoad(Instruction* call,
                               Definition* receiver,
                               intptr_t array_cid,
                               intptr_t view_cid,
                               const ICData& ic_data,
                               TargetEntryInstr** entry,
                               Definition** last);

  bool InlineByteArrayBaseStore(const Function& target,
                                Instruction* call,
                                Definition* receiver,
                                intptr_t array_cid,
                                intptr_t view_cid,
                                const ICData& ic_data,
                                TargetEntryInstr** entry,
                                Definition** last);

  intptr_t PrepareInlineByteArrayBaseOp(Instruction* call,
                                        intptr_t array_cid,
                                        intptr_t view_cid,
                                        Definition** array,
                                        Definition* index,
                                        Instruction** cursor);

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

  bool InstanceCallNeedsClassCheck(InstanceCallInstr* call,
                                   RawFunction::Kind kind) const;

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
  bool InlineImplicitInstanceGetter(InstanceCallInstr* call, bool allow_check);

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

  void InstanceCallNoopt(InstanceCallInstr* instr);

  RawField* GetField(intptr_t class_id, const String& field_name);

  Thread* thread() const { return flow_graph_->thread(); }
  Isolate* isolate() const { return flow_graph_->isolate(); }
  Zone* zone() const { return flow_graph_->zone(); }

  const Function& function() const { return flow_graph_->function(); }

  bool IsBlackListedForInlining(intptr_t deopt_id);

  FlowGraph* flow_graph_;

  const bool use_speculative_inlining_;

  GrowableArray<intptr_t>* inlining_black_list_;

  DISALLOW_COPY_AND_ASSIGN(FlowGraphOptimizer);
};


// Loop invariant code motion.
class LICM : public ValueObject {
 public:
  explicit LICM(FlowGraph* flow_graph);

  void Optimize();

  void OptimisticallySpecializeSmiPhis();

 private:
  FlowGraph* flow_graph() const { return flow_graph_; }

  void Hoist(ForwardInstructionIterator* it,
             BlockEntryInstr* pre_header,
             Instruction* current);

  void TrySpecializeSmiPhi(PhiInstr* phi,
                           BlockEntryInstr* header,
                           BlockEntryInstr* pre_header);

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


// Rewrite branches to eliminate materialization of boolean values after
// inlining, and to expose other optimizations (e.g., constant folding of
// branches, unreachable code elimination).
class BranchSimplifier : public AllStatic {
 public:
  static void Simplify(FlowGraph* flow_graph);

  // Replace a target entry instruction with a join entry instruction.  Does
  // not update the original target's predecessors to point to the new block
  // and does not replace the target in already computed block order lists.
  static JoinEntryInstr* ToJoinEntry(Zone* zone,
                                     TargetEntryInstr* target);

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


class AllocationSinking : public ZoneAllocated {
 public:
  explicit AllocationSinking(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        candidates_(5),
        materializations_(5) { }

  const GrowableArray<Definition*>& candidates() const {
    return candidates_;
  }

  // Find the materialization insterted for the given allocation
  // at the given exit.
  MaterializeObjectInstr* MaterializationFor(Definition* alloc,
                                             Instruction* exit);

  void Optimize();

  void DetachMaterializations();

 private:
  // Helper class to collect deoptimization exits that might need to
  // rematerialize an object: that is either instructions that reference
  // this object explicitly in their deoptimization environment or
  // reference some other allocation sinking candidate that points to
  // this object.
  class ExitsCollector : public ValueObject {
   public:
    ExitsCollector() : exits_(10), worklist_(3) { }

    const GrowableArray<Instruction*>& exits() const { return exits_; }

    void CollectTransitively(Definition* alloc);

   private:
    // Collect immediate uses of this object in the environments.
    // If this object is stored into other allocation sinking candidates
    // put them onto worklist so that CollectTransitively will process them.
    void Collect(Definition* alloc);

    GrowableArray<Instruction*> exits_;
    GrowableArray<Definition*> worklist_;
  };

  void CollectCandidates();

  void NormalizeMaterializations();

  void RemoveUnusedMaterializations();

  void DiscoverFailedCandidates();

  void InsertMaterializations(Definition* alloc);

  void CreateMaterializationAt(
      Instruction* exit,
      Definition* alloc,
      const ZoneGrowableArray<const Object*>& fields);

  void EliminateAllocation(Definition* alloc);

  Isolate* isolate() const { return flow_graph_->isolate(); }
  Zone* zone() const { return flow_graph_->zone(); }

  FlowGraph* flow_graph_;

  GrowableArray<Definition*> candidates_;
  GrowableArray<MaterializeObjectInstr*> materializations_;

  ExitsCollector exits_collector_;
};


// Optimize spill stores inside try-blocks by identifying values that always
// contain a single known constant at catch block entry.
class TryCatchAnalyzer : public AllStatic {
 public:
  static void Optimize(FlowGraph* flow_graph);
};

}  // namespace dart

#endif  // VM_FLOW_GRAPH_OPTIMIZER_H_
