// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/constant_propagator.h"

#include "vm/bit_vector.h"
#include "vm/compiler/backend/evaluator.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/range_analysis.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/parser.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, remove_redundant_phis, true, "Remove redundant phis.");
DEFINE_FLAG(bool,
            trace_constant_propagation,
            false,
            "Print constant propagation and useless code elimination.");

// Quick access to the current zone and isolate.
#define I (isolate())
#define Z (graph_->zone())
#define T (graph_->thread())

ConstantPropagator::ConstantPropagator(
    FlowGraph* graph,
    const GrowableArray<BlockEntryInstr*>& ignored)
    : FlowGraphVisitor(ignored),
      graph_(graph),
      unknown_(Object::unknown_constant()),
      non_constant_(Object::non_constant()),
      constant_value_(Object::Handle(Z)),
      reachable_(new (Z) BitVector(Z, graph->preorder().length())),
      unwrapped_phis_(new (Z)
                          BitVector(Z, graph->max_virtual_register_number())),
      block_worklist_(),
      definition_worklist_(graph, 10) {}

void ConstantPropagator::Optimize(FlowGraph* graph) {
  GrowableArray<BlockEntryInstr*> ignored;
  ConstantPropagator cp(graph, ignored);
  cp.Analyze();
  cp.Transform();
}

void ConstantPropagator::OptimizeBranches(FlowGraph* graph) {
  GrowableArray<BlockEntryInstr*> ignored;
  ConstantPropagator cp(graph, ignored);
  cp.Analyze();
  cp.Transform();
  cp.EliminateRedundantBranches();
}

void ConstantPropagator::SetReachable(BlockEntryInstr* block) {
  if (!reachable_->Contains(block->preorder_number())) {
    reachable_->Add(block->preorder_number());
    block_worklist_.Add(block);
  }
}

bool ConstantPropagator::SetValue(Definition* definition, const Object& value) {
  // We would like to assert we only go up (toward non-constant) in the lattice.
  //
  // ASSERT(IsUnknown(definition->constant_value()) ||
  //        IsNonConstant(value) ||
  //        (definition->constant_value().raw() == value.raw()));
  //
  // But the final disjunct is not true (e.g., mint or double constants are
  // heap-allocated and so not necessarily pointer-equal on each iteration).
  if (definition->constant_value().raw() != value.raw()) {
    definition->constant_value() = value.raw();
    if (definition->input_use_list() != NULL) {
      definition_worklist_.Add(definition);
    }
    return true;
  }
  return false;
}

static bool IsIdenticalConstants(const Object& left, const Object& right) {
  // This should be kept in line with Identical_comparison (identical.cc)
  // (=> Instance::IsIdenticalTo in object.cc).

  if (left.raw() == right.raw()) return true;
  if (left.GetClassId() != right.GetClassId()) return false;
  if (left.IsInteger()) {
    return Integer::Cast(left).Equals(Integer::Cast(right));
  }
  if (left.IsDouble()) {
    return Double::Cast(left).BitwiseEqualsToDouble(
        Double::Cast(right).value());
  }
  return false;
}

// Compute the join of two values in the lattice, assign it to the first.
void ConstantPropagator::Join(Object* left, const Object& right) {
  // Join(non-constant, X) = non-constant
  // Join(X, unknown)      = X
  if (IsNonConstant(*left) || IsUnknown(right)) return;

  // Join(unknown, X)      = X
  // Join(X, non-constant) = non-constant
  if (IsUnknown(*left) || IsNonConstant(right)) {
    *left = right.raw();
    return;
  }

  // Join(X, X) = X
  if (IsIdenticalConstants(*left, right)) return;

  // Join(X, Y) = non-constant
  *left = non_constant_.raw();
}

// --------------------------------------------------------------------------
// Analysis of blocks.  Called at most once per block.  The block is already
// marked as reachable.  All instructions in the block are analyzed.
void ConstantPropagator::VisitGraphEntry(GraphEntryInstr* block) {
  for (auto def : *block->initial_definitions()) {
    def->Accept(this);
  }
  ASSERT(ForwardInstructionIterator(block).Done());

  // TODO(fschneider): Improve this approximation. The catch entry is only
  // reachable if a call in the try-block is reachable.
  for (intptr_t i = 0; i < block->SuccessorCount(); ++i) {
    SetReachable(block->SuccessorAt(i));
  }
}

void ConstantPropagator::VisitFunctionEntry(FunctionEntryInstr* block) {
  for (auto def : *block->initial_definitions()) {
    def->Accept(this);
  }
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitNativeEntry(NativeEntryInstr* block) {
  VisitFunctionEntry(block);
}

void ConstantPropagator::VisitOsrEntry(OsrEntryInstr* block) {
  for (auto def : *block->initial_definitions()) {
    def->Accept(this);
  }
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitCatchBlockEntry(CatchBlockEntryInstr* block) {
  for (auto def : *block->initial_definitions()) {
    def->Accept(this);
  }
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitJoinEntry(JoinEntryInstr* block) {
  // Phis are visited when visiting Goto at a predecessor. See VisitGoto.
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitTargetEntry(TargetEntryInstr* block) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitIndirectEntry(IndirectEntryInstr* block) {
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}

void ConstantPropagator::VisitParallelMove(ParallelMoveInstr* instr) {
  // Parallel moves have not yet been inserted in the graph.
  UNREACHABLE();
}

// --------------------------------------------------------------------------
// Analysis of control instructions.  Unconditional successors are
// reachable.  Conditional successors are reachable depending on the
// constant value of the condition.
void ConstantPropagator::VisitReturn(ReturnInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitNativeReturn(NativeReturnInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitThrow(ThrowInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitReThrow(ReThrowInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitStop(StopInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitGoto(GotoInstr* instr) {
  SetReachable(instr->successor());

  // Phi value depends on the reachability of a predecessor. We have
  // to revisit phis every time a predecessor becomes reachable.
  for (PhiIterator it(instr->successor()); !it.Done(); it.Advance()) {
    PhiInstr* phi = it.Current();
    phi->Accept(this);

    // If this phi was previously unwrapped as redundant and it is no longer
    // redundant (does not unwrap) then we need to revisit the uses.
    if (unwrapped_phis_->Contains(phi->ssa_temp_index()) &&
        (UnwrapPhi(phi) == phi)) {
      unwrapped_phis_->Remove(phi->ssa_temp_index());
      definition_worklist_.Add(phi);
    }
  }
}

void ConstantPropagator::VisitIndirectGoto(IndirectGotoInstr* instr) {
  for (intptr_t i = 0; i < instr->SuccessorCount(); i++) {
    SetReachable(instr->SuccessorAt(i));
  }
}

void ConstantPropagator::VisitBranch(BranchInstr* instr) {
  instr->comparison()->Accept(this);

  // The successors may be reachable, but only if this instruction is.  (We
  // might be analyzing it because the constant value of one of its inputs
  // has changed.)
  if (reachable_->Contains(instr->GetBlock()->preorder_number())) {
    if (instr->constant_target() != NULL) {
      ASSERT((instr->constant_target() == instr->true_successor()) ||
             (instr->constant_target() == instr->false_successor()));
      SetReachable(instr->constant_target());
    } else {
      const Object& value = instr->comparison()->constant_value();
      if (IsNonConstant(value)) {
        SetReachable(instr->true_successor());
        SetReachable(instr->false_successor());
      } else if (value.raw() == Bool::True().raw()) {
        SetReachable(instr->true_successor());
      } else if (!IsUnknown(value)) {  // Any other constant.
        SetReachable(instr->false_successor());
      }
    }
  }
}

// --------------------------------------------------------------------------
// Analysis of non-definition instructions.  They do not have values so they
// cannot have constant values.
void ConstantPropagator::VisitCheckStackOverflow(
    CheckStackOverflowInstr* instr) {}

void ConstantPropagator::VisitCheckClass(CheckClassInstr* instr) {}

void ConstantPropagator::VisitCheckCondition(CheckConditionInstr* instr) {}

void ConstantPropagator::VisitCheckClassId(CheckClassIdInstr* instr) {}

void ConstantPropagator::VisitGuardFieldClass(GuardFieldClassInstr* instr) {}

void ConstantPropagator::VisitGuardFieldLength(GuardFieldLengthInstr* instr) {}

void ConstantPropagator::VisitGuardFieldType(GuardFieldTypeInstr* instr) {}

void ConstantPropagator::VisitCheckSmi(CheckSmiInstr* instr) {}

void ConstantPropagator::VisitTailCall(TailCallInstr* instr) {}

void ConstantPropagator::VisitCheckEitherNonSmi(CheckEitherNonSmiInstr* instr) {
}

void ConstantPropagator::VisitStoreUntagged(StoreUntaggedInstr* instr) {}

void ConstantPropagator::VisitStoreIndexedUnsafe(
    StoreIndexedUnsafeInstr* instr) {}

void ConstantPropagator::VisitStoreIndexed(StoreIndexedInstr* instr) {}

void ConstantPropagator::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {}

void ConstantPropagator::VisitMemoryCopy(MemoryCopyInstr* instr) {}

void ConstantPropagator::VisitDeoptimize(DeoptimizeInstr* instr) {
  // TODO(vegorov) remove all code after DeoptimizeInstr as dead.
}

Definition* ConstantPropagator::UnwrapPhi(Definition* defn) {
  if (defn->IsPhi()) {
    JoinEntryInstr* block = defn->AsPhi()->block();

    Definition* input = NULL;
    for (intptr_t i = 0; i < defn->InputCount(); ++i) {
      if (reachable_->Contains(block->PredecessorAt(i)->preorder_number())) {
        if (input == NULL) {
          input = defn->InputAt(i)->definition();
        } else {
          return defn;
        }
      }
    }

    return input;
  }

  return defn;
}

void ConstantPropagator::MarkUnwrappedPhi(Definition* phi) {
  ASSERT(phi->IsPhi());
  unwrapped_phis_->Add(phi->ssa_temp_index());
}

ConstantPropagator::PhiInfo* ConstantPropagator::GetPhiInfo(PhiInstr* phi) {
  if (phi->HasPassSpecificId(CompilerPass::kConstantPropagation)) {
    const intptr_t id =
        phi->GetPassSpecificId(CompilerPass::kConstantPropagation);
    // Note: id might have been assigned by the previous round of constant
    // propagation, so we need to verify it before using it.
    if (id < phis_.length() && phis_[id].phi == phi) {
      return &phis_[id];
    }
  }

  phi->SetPassSpecificId(CompilerPass::kConstantPropagation, phis_.length());
  phis_.Add({phi, 0});
  return &phis_.Last();
}

// --------------------------------------------------------------------------
// Analysis of definitions.  Compute the constant value.  If it has changed
// and the definition has input uses, add the definition to the definition
// worklist so that the used can be processed.
void ConstantPropagator::VisitPhi(PhiInstr* instr) {
  // Detect convergence issues by checking if visit count for this phi
  // is too high. We should only visit this phi once for every predecessor
  // becoming reachable, once for every input changing its constant value and
  // once for an unwrapped redundant phi becoming non-redundant.
  // Inputs can only change their constant value at most three times: from
  // non-constant to unknown to specific constant to non-constant. The first
  // link (non-constant to ...) can happen when we run the second round of
  // constant propagation - some instructions can have non-constant assigned to
  // them at the end of the previous constant propagation.
  auto info = GetPhiInfo(instr);
  info->visit_count++;
  const intptr_t kMaxVisitsExpected = 5 * instr->InputCount();
  if (info->visit_count > kMaxVisitsExpected) {
    OS::PrintErr(
        "ConstantPropagation pass is failing to converge on graph for %s\n",
        graph_->parsed_function().function().ToCString());
    OS::PrintErr("Phi %s was visited %" Pd " times\n", instr->ToCString(),
                 info->visit_count);
    NOT_IN_PRODUCT(
        FlowGraphPrinter::PrintGraph("Constant Propagation", graph_));
    FATAL("Aborting due to non-covergence.");
  }

  // Compute the join over all the reachable predecessor values.
  JoinEntryInstr* block = instr->block();
  Object& value = Object::ZoneHandle(Z, Unknown());
  for (intptr_t pred_idx = 0; pred_idx < instr->InputCount(); ++pred_idx) {
    if (reachable_->Contains(
            block->PredecessorAt(pred_idx)->preorder_number())) {
      Join(&value, instr->InputAt(pred_idx)->definition()->constant_value());
    }
  }
  SetValue(instr, value);
}

void ConstantPropagator::VisitRedefinition(RedefinitionInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsConstant(value)) {
    SetValue(instr, value);
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitReachabilityFence(ReachabilityFenceInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitCheckArrayBound(CheckArrayBoundInstr* instr) {
  // Don't propagate constants through check, since it would eliminate
  // the data dependence between the bound check and the load/store.
  // Graph finalization will expose the constant eventually.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitGenericCheckBound(GenericCheckBoundInstr* instr) {
  // Don't propagate constants through check, since it would eliminate
  // the data dependence between the bound check and the load/store.
  // Graph finalization will expose the constant eventually.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitCheckNull(CheckNullInstr* instr) {
  // Don't propagate constants through check, since it would eliminate
  // the data dependence between the null check and its use.
  // Graph finalization will expose the constant eventually.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitParameter(ParameterInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitNativeParameter(NativeParameterInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitPushArgument(PushArgumentInstr* instr) {
  UNREACHABLE();
}

void ConstantPropagator::VisitAssertAssignable(AssertAssignableInstr* instr) {
  const auto& value = instr->value()->definition()->constant_value();
  const auto& dst_type = instr->dst_type()->definition()->constant_value();

  if (IsNonConstant(value) || IsNonConstant(dst_type)) {
    SetValue(instr, non_constant_);
    return;
  } else if (IsUnknown(value) || IsUnknown(dst_type)) {
    return;
  }
  ASSERT(IsConstant(value) && IsConstant(dst_type));
  if (dst_type.IsAbstractType()) {
    // We are ignoring the instantiator and instantiator_type_arguments, but
    // still monotonic and safe.
    if (instr->value()->Type()->IsAssignableTo(AbstractType::Cast(dst_type))) {
      SetValue(instr, value);
      return;
    }
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitAssertSubtype(AssertSubtypeInstr* instr) {}

void ConstantPropagator::VisitAssertBoolean(AssertBooleanInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsBool()) {
    SetValue(instr, value);
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitSpecialParameter(SpecialParameterInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitClosureCall(ClosureCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInstanceCall(InstanceCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitPolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitDispatchTableCall(DispatchTableCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitStaticCall(StaticCallInstr* instr) {
  const auto kind = instr->function().recognized_kind();
  switch (kind) {
    case MethodRecognizer::kOneByteString_equality:
    case MethodRecognizer::kTwoByteString_equality: {
      ASSERT(instr->FirstArgIndex() == 0);
      // Use pure identity as a fast equality test.
      if (instr->ArgumentAt(0)->OriginalDefinition() ==
          instr->ArgumentAt(1)->OriginalDefinition()) {
        SetValue(instr, Bool::True());
        return;
      }
      // Otherwise evaluate string compare with propagated constants.
      const Object& o1 = instr->ArgumentAt(0)->constant_value();
      const Object& o2 = instr->ArgumentAt(1)->constant_value();
      if (o1.IsString() && o2.IsString()) {
        SetValue(instr, Bool::Get(String::Cast(o1).Equals(String::Cast(o2))));
        return;
      }
      break;
    }
    case MethodRecognizer::kStringBaseLength:
    case MethodRecognizer::kStringBaseIsEmpty: {
      ASSERT(instr->FirstArgIndex() == 0);
      // Otherwise evaluate string length with propagated constants.
      const Object& o = instr->ArgumentAt(0)->constant_value();
      if (o.IsString()) {
        const auto& str = String::Cast(o);
        if (kind == MethodRecognizer::kStringBaseLength) {
          SetValue(instr, Integer::ZoneHandle(Z, Integer::New(str.Length())));
        } else {
          SetValue(instr, Bool::Get(str.Length() == 0));
        }
        return;
      }
      break;
    }
    default:
      break;
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadLocal(LoadLocalInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}

void ConstantPropagator::VisitDropTemps(DropTempsInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}

void ConstantPropagator::VisitMakeTemp(MakeTempInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}

void ConstantPropagator::VisitStoreLocal(StoreLocalInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}

void ConstantPropagator::VisitIfThenElse(IfThenElseInstr* instr) {
  instr->comparison()->Accept(this);
  const Object& value = instr->comparison()->constant_value();
  ASSERT(!value.IsNull());
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsBool()) {
    bool result = Bool::Cast(value).value();
    SetValue(instr, Smi::Handle(Z, Smi::New(result ? instr->if_true()
                                                   : instr->if_false())));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitStrictCompare(StrictCompareInstr* instr) {
  Definition* left_defn = instr->left()->definition();
  Definition* right_defn = instr->right()->definition();

  Definition* unwrapped_left_defn = UnwrapPhi(left_defn);
  Definition* unwrapped_right_defn = UnwrapPhi(right_defn);
  if (unwrapped_left_defn == unwrapped_right_defn) {
    // Fold x === x, and x !== x to true/false.
    if (SetValue(instr, Bool::Get(instr->kind() == Token::kEQ_STRICT))) {
      if (unwrapped_left_defn != left_defn) {
        MarkUnwrappedPhi(left_defn);
      }
      if (unwrapped_right_defn != right_defn) {
        MarkUnwrappedPhi(right_defn);
      }
    }
    return;
  }

  const Object& left = left_defn->constant_value();
  const Object& right = right_defn->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    // TODO(vegorov): incorporate nullability information into the lattice.
    if ((left.IsNull() && instr->right()->Type()->HasDecidableNullability()) ||
        (right.IsNull() && instr->left()->Type()->HasDecidableNullability())) {
      bool result = left.IsNull() ? instr->right()->Type()->IsNull()
                                  : instr->left()->Type()->IsNull();
      if (instr->kind() == Token::kNE_STRICT) {
        result = !result;
      }
      SetValue(instr, Bool::Get(result));
    } else {
      const intptr_t left_cid = instr->left()->Type()->ToCid();
      const intptr_t right_cid = instr->right()->Type()->ToCid();
      // If exact classes (cids) are known and they differ, the result
      // of strict compare can be computed.
      // The only exception is comparison with special sentinel value
      // (used for lazy initialization) which can be compared to a
      // value of any type. Sentinel value has kNeverCid.
      if ((left_cid != kDynamicCid) && (right_cid != kDynamicCid) &&
          (left_cid != kNeverCid) && (right_cid != kNeverCid) &&
          (left_cid != right_cid)) {
        const bool result = (instr->kind() != Token::kEQ_STRICT);
        SetValue(instr, Bool::Get(result));
      } else {
        SetValue(instr, non_constant_);
      }
    }
  } else if (IsConstant(left) && IsConstant(right)) {
    bool result = IsIdenticalConstants(left, right);
    if (instr->kind() == Token::kNE_STRICT) {
      result = !result;
    }
    SetValue(instr, Bool::Get(result));
  }
}

static bool CompareIntegers(Token::Kind kind,
                            const Integer& left,
                            const Integer& right) {
  const int result = left.CompareWith(right);
  switch (kind) {
    case Token::kEQ:
      return (result == 0);
    case Token::kNE:
      return (result != 0);
    case Token::kLT:
      return (result < 0);
    case Token::kGT:
      return (result > 0);
    case Token::kLTE:
      return (result <= 0);
    case Token::kGTE:
      return (result >= 0);
    default:
      UNREACHABLE();
      return false;
  }
}

// Comparison instruction that is equivalent to the (left & right) == 0
// comparison pattern.
void ConstantPropagator::VisitTestSmi(TestSmiInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
    return;
  } else if (IsUnknown(left) || IsUnknown(right)) {
    return;
  }
  ASSERT(IsConstant(left) && IsConstant(right));
  if (left.IsInteger() && right.IsInteger()) {
    const bool result = CompareIntegers(
        instr->kind(),
        Integer::Handle(Z, Integer::Cast(left).BitOp(Token::kBIT_AND,
                                                     Integer::Cast(right))),
        Object::smi_zero());
    SetValue(instr, result ? Bool::True() : Bool::False());
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitTestCids(TestCidsInstr* instr) {
  // TODO(sra): Constant fold test.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitEqualityCompare(EqualityCompareInstr* instr) {
  Definition* left_defn = instr->left()->definition();
  Definition* right_defn = instr->right()->definition();

  if (IsIntegerClassId(instr->operation_cid())) {
    // Fold x == x, and x != x to true/false for numbers comparisons.
    Definition* unwrapped_left_defn = UnwrapPhi(left_defn);
    Definition* unwrapped_right_defn = UnwrapPhi(right_defn);
    if (unwrapped_left_defn == unwrapped_right_defn) {
      // Fold x === x, and x !== x to true/false.
      if (SetValue(instr, Bool::Get(instr->kind() == Token::kEQ))) {
        if (unwrapped_left_defn != left_defn) {
          MarkUnwrappedPhi(left_defn);
        }
        if (unwrapped_right_defn != right_defn) {
          MarkUnwrappedPhi(right_defn);
        }
      }
      return;
    }
  }

  const Object& left = left_defn->constant_value();
  const Object& right = right_defn->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(instr->kind(), Integer::Cast(left),
                                          Integer::Cast(right));
      SetValue(instr, Bool::Get(result));
    } else if (left.IsString() && right.IsString()) {
      const bool result = String::Cast(left).Equals(String::Cast(right));
      SetValue(instr, Bool::Get((instr->kind() == Token::kEQ) == result));
    } else {
      SetValue(instr, non_constant_);
    }
  }
}

void ConstantPropagator::VisitRelationalOp(RelationalOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(instr->kind(), Integer::Cast(left),
                                          Integer::Cast(right));
      SetValue(instr, Bool::Get(result));
    } else if (left.IsDouble() && right.IsDouble()) {
      // TODO(srdjan): Implement.
      SetValue(instr, non_constant_);
    } else {
      SetValue(instr, non_constant_);
    }
  }
}

void ConstantPropagator::VisitNativeCall(NativeCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFfiCall(FfiCallInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitEnterHandleScope(EnterHandleScopeInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitExitHandleScope(ExitHandleScopeInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitAllocateHandle(AllocateHandleInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitRawStoreField(RawStoreFieldInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitDebugStepCheck(DebugStepCheckInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitOneByteStringFromCharCode(
    OneByteStringFromCharCodeInstr* instr) {
  const Object& o = instr->char_code()->definition()->constant_value();
  if (IsUnknown(o)) {
    return;
  }
  if (o.IsSmi()) {
    const intptr_t ch_code = Smi::Cast(o).Value();
    ASSERT(ch_code >= 0);
    if (ch_code < Symbols::kMaxOneCharCodeSymbol) {
      StringPtr* table = Symbols::PredefinedAddress();
      SetValue(instr, String::ZoneHandle(Z, table[ch_code]));
      return;
    }
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitStringToCharCode(StringToCharCodeInstr* instr) {
  const Object& o = instr->str()->definition()->constant_value();
  if (IsUnknown(o)) {
    return;
  }
  if (o.IsString()) {
    const String& str = String::Cast(o);
    const intptr_t result =
        (str.Length() == 1) ? static_cast<intptr_t>(str.CharAt(0)) : -1;
    SetValue(instr, Smi::ZoneHandle(Z, Smi::New(result)));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitStringInterpolate(StringInterpolateInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUtf8Scan(Utf8ScanInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadIndexed(LoadIndexedInstr* instr) {
  const Object& array_obj = instr->array()->definition()->constant_value();
  const Object& index_obj = instr->index()->definition()->constant_value();
  if (IsNonConstant(array_obj) || IsNonConstant(index_obj)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(array_obj) && IsConstant(index_obj)) {
    // Need index to be Smi and array to be either String or an immutable array.
    if (!index_obj.IsSmi()) {
      // Should not occur.
      SetValue(instr, non_constant_);
      return;
    }
    const intptr_t index = Smi::Cast(index_obj).Value();
    if (index >= 0) {
      if (array_obj.IsString()) {
        const String& str = String::Cast(array_obj);
        if (str.Length() > index) {
          SetValue(instr,
                   Smi::Handle(
                       Z, Smi::New(static_cast<intptr_t>(str.CharAt(index)))));
          return;
        }
      } else if (array_obj.IsArray()) {
        const Array& a = Array::Cast(array_obj);
        if ((a.Length() > index) && a.IsImmutable()) {
          Instance& result = Instance::Handle(Z);
          result ^= a.At(index);
          SetValue(instr, result);
          return;
        }
      }
    }
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitLoadCodeUnits(LoadCodeUnitsInstr* instr) {
  // TODO(zerny): Implement constant propagation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadIndexedUnsafe(LoadIndexedUnsafeInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadStaticField(LoadStaticFieldInstr* instr) {
  if (!FLAG_fields_may_be_reset) {
    const Field& field = instr->field();
    ASSERT(field.is_static());
    if (field.is_final() && instr->IsFieldInitialized()) {
      Instance& obj = Instance::Handle(Z, field.StaticValue());
      if (obj.IsSmi() || (obj.IsOld() && obj.IsCanonical())) {
        SetValue(instr, obj);
        return;
      }
    }
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitStoreStaticField(StoreStaticFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}

void ConstantPropagator::VisitBooleanNegate(BooleanNegateInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsBool()) {
    bool val = value.raw() != Bool::True().raw();
    SetValue(instr, Bool::Get(val));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitInstanceOf(InstanceOfInstr* instr) {
  Definition* def = instr->value()->definition();
  const Object& value = def->constant_value();
  const AbstractType& checked_type = instr->type();
  // If the checked type is a top type, the result is always true.
  if (checked_type.IsTopTypeForInstanceOf()) {
    SetValue(instr, Bool::True());
  } else if (IsNonConstant(value)) {
    intptr_t value_cid = instr->value()->definition()->Type()->ToCid();
    Representation rep = def->representation();
    if ((checked_type.IsFloat32x4Type() && (rep == kUnboxedFloat32x4)) ||
        (checked_type.IsInt32x4Type() && (rep == kUnboxedInt32x4)) ||
        (checked_type.IsDoubleType() && (rep == kUnboxedDouble) &&
         FlowGraphCompiler::SupportsUnboxedDoubles()) ||
        (checked_type.IsIntType() && (rep == kUnboxedInt64))) {
      // Ensure that compile time type matches representation.
      ASSERT(((rep == kUnboxedFloat32x4) && (value_cid == kFloat32x4Cid)) ||
             ((rep == kUnboxedInt32x4) && (value_cid == kInt32x4Cid)) ||
             ((rep == kUnboxedDouble) && (value_cid == kDoubleCid)) ||
             ((rep == kUnboxedInt64) && (value_cid == kMintCid)));
      // The representation guarantees the type check to be true.
      SetValue(instr, Bool::True());
    } else {
      SetValue(instr, non_constant_);
    }
  } else if (IsConstant(value)) {
    if (value.IsInstance() && (value.raw() != Object::sentinel().raw())) {
      const Instance& instance = Instance::Cast(value);
      if (instr->instantiator_type_arguments()->BindsToConstantNull() &&
          instr->function_type_arguments()->BindsToConstantNull()) {
        bool is_instance =
            instance.IsInstanceOf(checked_type, Object::null_type_arguments(),
                                  Object::null_type_arguments());
        SetValue(instr, Bool::Get(is_instance));
        return;
      }
    }
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitCreateArray(CreateArrayInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitAllocateTypedData(AllocateTypedDataInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitAllocateObject(AllocateObjectInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadUntagged(LoadUntaggedInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadClassId(LoadClassIdInstr* instr) {
  // This first part duplicates the work done in LoadClassIdInstr::Canonicalize,
  // which replaces uses of LoadClassIdInstr where the object has a concrete
  // type with a Constant. Canonicalize runs before the ConstantPropagation
  // pass, so if that was all, this wouldn't be needed.
  //
  // However, the ConstantPropagator also runs as part of OptimizeBranches, and
  // TypePropagation runs between it and the previous Canonicalize. Thus, the
  // type may have become concrete and we should take that into account. Not
  // doing so led to some benchmark regressions.
  intptr_t cid = instr->object()->Type()->ToCid();
  if (cid != kDynamicCid) {
    SetValue(instr, Smi::ZoneHandle(Z, Smi::New(cid)));
    return;
  }
  const Object& object = instr->object()->definition()->constant_value();
  if (IsConstant(object)) {
    cid = object.GetClassId();
    SetValue(instr, Smi::ZoneHandle(Z, Smi::New(cid)));
    return;
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadField(LoadFieldInstr* instr) {
  Value* instance = instr->instance();
  if ((instr->slot().kind() == Slot::Kind::kArray_length) &&
      instance->definition()->OriginalDefinition()->IsCreateArray()) {
    Value* num_elements = instance->definition()
                              ->OriginalDefinition()
                              ->AsCreateArray()
                              ->num_elements();
    if (num_elements->BindsToConstant() &&
        num_elements->BoundConstant().IsSmi()) {
      intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
      const Object& result = Smi::ZoneHandle(Z, Smi::New(length));
      SetValue(instr, result);
      return;
    }
  }

  const Object& constant = instance->definition()->constant_value();
  if (IsConstant(constant)) {
    if (instr->IsImmutableLengthLoad()) {
      if (constant.IsString()) {
        SetValue(instr,
                 Smi::ZoneHandle(Z, Smi::New(String::Cast(constant).Length())));
        return;
      }
      if (constant.IsArray()) {
        SetValue(instr,
                 Smi::ZoneHandle(Z, Smi::New(Array::Cast(constant).Length())));
        return;
      }
      if (constant.IsTypedData()) {
        SetValue(instr, Smi::ZoneHandle(
                            Z, Smi::New(TypedData::Cast(constant).Length())));
        return;
      }
    } else {
      Object& value = Object::Handle();
      if (instr->Evaluate(constant, &value)) {
        SetValue(instr, Object::ZoneHandle(Z, value.raw()));
        return;
      }
    }
  }

  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInstantiateType(InstantiateTypeInstr* instr) {
  TypeArguments& instantiator_type_args = TypeArguments::Handle(Z);
  TypeArguments& function_type_args = TypeArguments::Handle(Z);
  if (!instr->type().IsInstantiated(kCurrentClass)) {
    // Type refers to class type parameters.
    const Object& instantiator_type_args_obj =
        instr->instantiator_type_arguments()->definition()->constant_value();
    if (IsUnknown(instantiator_type_args_obj)) {
      return;
    }
    if (instantiator_type_args_obj.IsTypeArguments()) {
      instantiator_type_args ^= instantiator_type_args_obj.raw();
    } else {
      SetValue(instr, non_constant_);
      return;
    }
  }
  if (!instr->type().IsInstantiated(kFunctions)) {
    // Type refers to function type parameters.
    const Object& function_type_args_obj =
        instr->function_type_arguments()->definition()->constant_value();
    if (IsUnknown(function_type_args_obj)) {
      return;
    }
    if (function_type_args_obj.IsTypeArguments()) {
      function_type_args ^= function_type_args_obj.raw();
    } else {
      SetValue(instr, non_constant_);
      return;
    }
  }
  AbstractType& result = AbstractType::Handle(
      Z, instr->type().InstantiateFrom(
             instantiator_type_args, function_type_args, kAllFree, Heap::kOld));
  if (result.IsTypeRef()) {
    result = TypeRef::Cast(result).type();
  }
  ASSERT(result.IsInstantiated());
  result = result.Canonicalize(T, nullptr);
  SetValue(instr, result);
}

void ConstantPropagator::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsInstr* instr) {
  const auto& type_arguments_obj =
      instr->type_arguments()->definition()->constant_value();
  if (IsUnknown(type_arguments_obj)) {
    return;
  }
  if (type_arguments_obj.IsNull()) {
    SetValue(instr, type_arguments_obj);
    return;
  }
  if (!type_arguments_obj.IsTypeArguments()) {
    SetValue(instr, non_constant_);
    return;
  }
  const auto& type_arguments = TypeArguments::Cast(type_arguments_obj);
  if (type_arguments.IsInstantiated()) {
    ASSERT(type_arguments.IsCanonical());
    SetValue(instr, type_arguments);
    return;
  }
  auto& instantiator_type_args = TypeArguments::Handle(Z);
  if (!type_arguments.IsInstantiated(kCurrentClass)) {
    // Type arguments refer to class type parameters.
    const Object& instantiator_type_args_obj =
        instr->instantiator_type_arguments()->definition()->constant_value();
    if (IsUnknown(instantiator_type_args_obj)) {
      return;
    }
    if (!instantiator_type_args_obj.IsNull() &&
        !instantiator_type_args_obj.IsTypeArguments()) {
      SetValue(instr, non_constant_);
      return;
    }
    instantiator_type_args ^= instantiator_type_args_obj.raw();
    if (instr->CanShareInstantiatorTypeArguments()) {
      SetValue(instr, instantiator_type_args);
      return;
    }
  }
  auto& function_type_args = TypeArguments::Handle(Z);
  if (!type_arguments.IsInstantiated(kFunctions)) {
    // Type arguments refer to function type parameters.
    const Object& function_type_args_obj =
        instr->function_type_arguments()->definition()->constant_value();
    if (IsUnknown(function_type_args_obj)) {
      return;
    }
    if (!function_type_args_obj.IsNull() &&
        !function_type_args_obj.IsTypeArguments()) {
      SetValue(instr, non_constant_);
      return;
    }
    function_type_args ^= function_type_args_obj.raw();
    if (instr->CanShareFunctionTypeArguments()) {
      SetValue(instr, function_type_args);
      return;
    }
  }
  auto& result = TypeArguments::Handle(
      Z, type_arguments.InstantiateFrom(
             instantiator_type_args, function_type_args, kAllFree, Heap::kOld));
  ASSERT(result.IsInstantiated());
  result = result.Canonicalize(T, nullptr);
  SetValue(instr, result);
}

void ConstantPropagator::VisitAllocateContext(AllocateContextInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitAllocateUninitializedContext(
    AllocateUninitializedContextInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitCloneContext(CloneContextInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBinaryIntegerOp(BinaryIntegerOpInstr* binary_op) {
  const Object& left = binary_op->left()->definition()->constant_value();
  const Object& right = binary_op->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(binary_op, non_constant_);
    return;
  } else if (IsUnknown(left) || IsUnknown(right)) {
    return;
  }
  ASSERT(IsConstant(left) && IsConstant(right));
  if (left.IsInteger() && right.IsInteger()) {
    const Integer& result = Integer::Handle(
        Z, Evaluator::BinaryIntegerEvaluate(left, right, binary_op->op_kind(),
                                            binary_op->is_truncating(),
                                            binary_op->representation(), T));
    if (!result.IsNull()) {
      SetValue(binary_op, Integer::ZoneHandle(Z, result.raw()));
      return;
    }
  }
  SetValue(binary_op, non_constant_);
}

void ConstantPropagator::VisitCheckedSmiOp(CheckedSmiOpInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitCheckedSmiComparison(
    CheckedSmiComparisonInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBinarySmiOp(BinarySmiOpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitBinaryInt32Op(BinaryInt32OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitBinaryUint32Op(BinaryUint32OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitBinaryInt64Op(BinaryInt64OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitShiftInt64Op(ShiftInt64OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitSpeculativeShiftInt64Op(
    SpeculativeShiftInt64OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitShiftUint32Op(ShiftUint32OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitSpeculativeShiftUint32Op(
    SpeculativeShiftUint32OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitBoxInt64(BoxInt64Instr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnboxInt64(UnboxInt64Instr* instr) {
  // TODO(kmillikin): Handle unbox operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnaryIntegerOp(UnaryIntegerOpInstr* unary_op) {
  const Object& value = unary_op->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsInteger()) {
    const Integer& result = Integer::Handle(
        Z, Evaluator::UnaryIntegerEvaluate(value, unary_op->op_kind(),
                                           unary_op->representation(), T));
    if (!result.IsNull()) {
      SetValue(unary_op, Integer::ZoneHandle(Z, result.raw()));
      return;
    }
  }
  SetValue(unary_op, non_constant_);
}

void ConstantPropagator::VisitUnaryInt64Op(UnaryInt64OpInstr* instr) {
  VisitUnaryIntegerOp(instr);
}

void ConstantPropagator::VisitUnarySmiOp(UnarySmiOpInstr* instr) {
  VisitUnaryIntegerOp(instr);
}

void ConstantPropagator::VisitUnaryDoubleOp(UnaryDoubleOpInstr* instr) {
  // TODO(kmillikin): Handle unary operations.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitSmiToDouble(SmiToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitInt64ToDouble(Int64ToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitInt32ToDouble(Int32ToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  if (value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitDoubleToInteger(DoubleToIntegerInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitDoubleToSmi(DoubleToSmiInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitDoubleToDouble(DoubleToDoubleInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitDoubleToFloat(DoubleToFloatInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloatToDouble(FloatToDoubleInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInvokeMathCFunction(
    InvokeMathCFunctionInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitTruncDivMod(TruncDivModInstr* instr) {
  // TODO(srdjan): Handle merged instruction.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitExtractNthOutput(ExtractNthOutputInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitConstant(ConstantInstr* instr) {
  SetValue(instr, instr->value());
}

void ConstantPropagator::VisitUnboxedConstant(UnboxedConstantInstr* instr) {
  SetValue(instr, instr->value());
}

void ConstantPropagator::VisitConstraint(ConstraintInstr* instr) {
  // Should not be used outside of range analysis.
  UNREACHABLE();
}

void ConstantPropagator::VisitMaterializeObject(MaterializeObjectInstr* instr) {
  // Should not be used outside of allocation elimination pass.
  UNREACHABLE();
}

static bool IsIntegerOrDouble(const Object& value) {
  return value.IsInteger() || value.IsDouble();
}

static double ToDouble(const Object& value) {
  return value.IsInteger() ? Integer::Cast(value).AsDoubleValue()
                           : Double::Cast(value).value();
}

void ConstantPropagator::VisitBinaryDoubleOp(BinaryDoubleOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
    return;
  } else if (IsUnknown(left) || IsUnknown(right)) {
    return;
  }
  ASSERT(IsConstant(left) && IsConstant(right));
  const bool both_are_integers = left.IsInteger() && right.IsInteger();
  if (IsIntegerOrDouble(left) && IsIntegerOrDouble(right) &&
      !both_are_integers) {
    const double result_val = Evaluator::EvaluateDoubleOp(
        ToDouble(left), ToDouble(right), instr->op_kind());
    const Double& result = Double::ZoneHandle(Double::NewCanonical(result_val));
    SetValue(instr, result);
    return;
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitDoubleTestOp(DoubleTestOpInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsUnknown(value)) {
    return;
  }
  const bool is_negated = instr->kind() != Token::kEQ;
  if (value.IsInteger()) {
    SetValue(instr, is_negated ? Bool::True() : Bool::False());
  } else if (IsIntegerOrDouble(value)) {
    switch (instr->op_kind()) {
      case MethodRecognizer::kDouble_getIsNaN: {
        const bool is_nan = isnan(ToDouble(value));
        SetValue(instr, Bool::Get(is_negated ? !is_nan : is_nan));
        break;
      }
      case MethodRecognizer::kDouble_getIsInfinite: {
        const bool is_inf = isinf(ToDouble(value));
        SetValue(instr, Bool::Get(is_negated ? !is_inf : is_inf));
        break;
      }
      default:
        UNREACHABLE();
    }
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitSimdOp(SimdOpInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitMathUnary(MathUnaryInstr* instr) {
  // TODO(kmillikin): Handle Math's unary operations (sqrt, cos, sin).
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitMathMinMax(MathMinMaxInstr* instr) {
  // TODO(srdjan): Handle min and max.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitCaseInsensitiveCompare(
    CaseInsensitiveCompareInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnbox(UnboxInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBox(BoxInstr* instr) {
  // TODO(kmillikin): Handle conversion.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBoxUint8(BoxUint8Instr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBoxUint32(BoxUint32Instr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnboxUint32(UnboxUint32Instr* instr) {
  // TODO(kmillikin): Handle unbox operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBoxInt32(BoxInt32Instr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnboxInt32(UnboxInt32Instr* instr) {
  // TODO(kmillikin): Handle unbox operation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitIntConverter(IntConverterInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBitCast(BitCastInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnaryUint32Op(UnaryUint32OpInstr* instr) {
  // TODO(kmillikin): Handle unary operations.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::Analyze() {
  GraphEntryInstr* entry = graph_->graph_entry();
  reachable_->Add(entry->preorder_number());
  block_worklist_.Add(entry);

  while (true) {
    if (block_worklist_.is_empty()) {
      if (definition_worklist_.IsEmpty()) break;
      Definition* definition = definition_worklist_.RemoveLast();
      for (Value* use = definition->input_use_list(); use != nullptr;
           use = use->next_use()) {
        use->instruction()->Accept(this);
      }
    } else {
      BlockEntryInstr* block = block_worklist_.RemoveLast();
      block->Accept(this);
    }
  }
}

static bool HasPhis(BlockEntryInstr* block) {
  if (auto* join = block->AsJoinEntry()) {
    return (join->phis() != nullptr) && !join->phis()->is_empty();
  }
  return false;
}

static bool IsEmptyBlock(BlockEntryInstr* block) {
  return block->next()->IsGoto() && !HasPhis(block) &&
         !block->IsIndirectEntry();
}

// Traverses a chain of empty blocks and returns the first reachable non-empty
// block that is not dominated by the start block. The empty blocks are added
// to the supplied bit vector.
static BlockEntryInstr* FindFirstNonEmptySuccessor(TargetEntryInstr* block,
                                                   BitVector* empty_blocks) {
  BlockEntryInstr* current = block;
  while (IsEmptyBlock(current) && block->Dominates(current)) {
    ASSERT(!HasPhis(block));
    empty_blocks->Add(current->preorder_number());
    current = current->next()->AsGoto()->successor();
  }
  return current;
}

void ConstantPropagator::EliminateRedundantBranches() {
  // Canonicalize branches that have no side-effects and where true- and
  // false-targets are the same.
  bool changed = false;
  BitVector* empty_blocks = new (Z) BitVector(Z, graph_->preorder().length());
  for (BlockIterator b = graph_->postorder_iterator(); !b.Done(); b.Advance()) {
    BlockEntryInstr* block = b.Current();
    BranchInstr* branch = block->last_instruction()->AsBranch();
    empty_blocks->Clear();
    if ((branch != NULL) && !branch->HasUnknownSideEffects()) {
      ASSERT(branch->previous() != NULL);  // Not already eliminated.
      BlockEntryInstr* if_true =
          FindFirstNonEmptySuccessor(branch->true_successor(), empty_blocks);
      BlockEntryInstr* if_false =
          FindFirstNonEmptySuccessor(branch->false_successor(), empty_blocks);
      if (if_true == if_false) {
        // Replace the branch with a jump to the common successor.
        // Drop the comparison, which does not have side effects
        JoinEntryInstr* join = if_true->AsJoinEntry();
        if (!HasPhis(join)) {
          GotoInstr* jump = new (Z) GotoInstr(join, DeoptId::kNone);
          graph_->CopyDeoptTarget(jump, branch);

          Instruction* previous = branch->previous();
          branch->set_previous(NULL);
          previous->LinkTo(jump);

          // Remove uses from branch and all the empty blocks that
          // are now unreachable.
          branch->UnuseAllInputs();
          for (BitVector::Iterator it(empty_blocks); !it.Done(); it.Advance()) {
            BlockEntryInstr* empty_block = graph_->preorder()[it.Current()];
            empty_block->ClearAllInstructions();
          }

          changed = true;

          if (FLAG_trace_constant_propagation && graph_->should_print()) {
            THR_Print("Eliminated branch in B%" Pd " common target B%" Pd "\n",
                      block->block_id(), join->block_id());
          }
        }
      }
    }
  }

  if (changed) {
    graph_->DiscoverBlocks();
    graph_->MergeBlocks();
    // TODO(fschneider): Update dominator tree in place instead of recomputing.
    GrowableArray<BitVector*> dominance_frontier;
    graph_->ComputeDominators(&dominance_frontier);
  }
}

void ConstantPropagator::Transform() {
  // We will recompute dominators, block ordering, block ids, block last
  // instructions, previous pointers, predecessors, etc. after eliminating
  // unreachable code.  We do not maintain those properties during the
  // transformation.
  for (BlockIterator b = graph_->reverse_postorder_iterator(); !b.Done();
       b.Advance()) {
    BlockEntryInstr* block = b.Current();
    if (!reachable_->Contains(block->preorder_number())) {
      if (FLAG_trace_constant_propagation && graph_->should_print()) {
        THR_Print("Unreachable B%" Pd "\n", block->block_id());
      }
      // Remove all uses in unreachable blocks.
      block->ClearAllInstructions();
      continue;
    }

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      // Remove phi inputs corresponding to unreachable predecessor blocks.
      // Predecessors will be recomputed (in block id order) after removing
      // unreachable code so we merely have to keep the phi inputs in order.
      ZoneGrowableArray<PhiInstr*>* phis = join->phis();
      if ((phis != NULL) && !phis->is_empty()) {
        intptr_t pred_count = join->PredecessorCount();
        intptr_t live_count = 0;
        for (intptr_t pred_idx = 0; pred_idx < pred_count; ++pred_idx) {
          if (reachable_->Contains(
                  join->PredecessorAt(pred_idx)->preorder_number())) {
            if (live_count < pred_idx) {
              for (PhiIterator it(join); !it.Done(); it.Advance()) {
                PhiInstr* phi = it.Current();
                ASSERT(phi != NULL);
                phi->SetInputAt(live_count, phi->InputAt(pred_idx));
              }
            }
            ++live_count;
          } else {
            for (PhiIterator it(join); !it.Done(); it.Advance()) {
              PhiInstr* phi = it.Current();
              ASSERT(phi != NULL);
              phi->InputAt(pred_idx)->RemoveFromUseList();
            }
          }
        }
        if (live_count < pred_count) {
          intptr_t to_idx = 0;
          for (intptr_t from_idx = 0; from_idx < phis->length(); ++from_idx) {
            PhiInstr* phi = (*phis)[from_idx];
            ASSERT(phi != NULL);
            if (FLAG_remove_redundant_phis && (live_count == 1)) {
              Value* input = phi->InputAt(0);
              phi->ReplaceUsesWith(input->definition());
              input->RemoveFromUseList();
            } else {
              phi->inputs_.TruncateTo(live_count);
              (*phis)[to_idx++] = phi;
            }
          }
          if (to_idx == 0) {
            join->phis_ = NULL;
          } else {
            phis->TruncateTo(to_idx);
          }
        }
      }
    }

    if (join != nullptr) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        auto phi = it.Current();
        if (TransformDefinition(phi)) {
          it.RemoveCurrentFromGraph();
        }
      }
    }
    for (ForwardInstructionIterator i(block); !i.Done(); i.Advance()) {
      Definition* defn = i.Current()->AsDefinition();
      if (TransformDefinition(defn)) {
        i.RemoveCurrentFromGraph();
      }
    }

    // Replace branches where one target is unreachable with jumps.
    BranchInstr* branch = block->last_instruction()->AsBranch();
    if (branch != NULL) {
      TargetEntryInstr* if_true = branch->true_successor();
      TargetEntryInstr* if_false = branch->false_successor();
      JoinEntryInstr* join = NULL;
      Instruction* next = NULL;

      if (!reachable_->Contains(if_true->preorder_number())) {
        ASSERT(reachable_->Contains(if_false->preorder_number()));
        ASSERT(if_false->parallel_move() == NULL);
        join = new (Z) JoinEntryInstr(if_false->block_id(),
                                      if_false->try_index(), DeoptId::kNone);
        graph_->CopyDeoptTarget(join, if_false);
        if_false->UnuseAllInputs();
        next = if_false->next();
      } else if (!reachable_->Contains(if_false->preorder_number())) {
        ASSERT(if_true->parallel_move() == NULL);
        join = new (Z) JoinEntryInstr(if_true->block_id(), if_true->try_index(),
                                      DeoptId::kNone);
        graph_->CopyDeoptTarget(join, if_true);
        if_true->UnuseAllInputs();
        next = if_true->next();
      }

      if (join != NULL) {
        // Replace the branch with a jump to the reachable successor.
        // Drop the comparison, which does not have side effects as long
        // as it is a strict compare (the only one we can determine is
        // constant with the current analysis).
        GotoInstr* jump = new (Z) GotoInstr(join, DeoptId::kNone);
        graph_->CopyDeoptTarget(jump, branch);

        Instruction* previous = branch->previous();
        branch->set_previous(NULL);
        previous->LinkTo(jump);

        // Replace the false target entry with the new join entry. We will
        // recompute the dominators after this pass.
        join->LinkTo(next);
        branch->UnuseAllInputs();
      }
    }
  }

  graph_->DiscoverBlocks();
  graph_->MergeBlocks();
  GrowableArray<BitVector*> dominance_frontier;
  graph_->ComputeDominators(&dominance_frontier);
}

bool ConstantPropagator::TransformDefinition(Definition* defn) {
  // Replace constant-valued instructions without observable side
  // effects.  Do this for smis and old objects only to avoid having to
  // copy other objects into the heap's old generation.
  ASSERT((defn == nullptr) || !defn->IsPushArgument());
  if ((defn != nullptr) && IsConstant(defn->constant_value()) &&
      (defn->constant_value().IsSmi() || defn->constant_value().IsOld()) &&
      !defn->IsConstant() && !defn->IsStoreIndexed() &&
      !defn->IsStoreInstanceField() && !defn->IsStoreStaticField()) {
    if (FLAG_trace_constant_propagation && graph_->should_print()) {
      THR_Print("Constant v%" Pd " = %s\n", defn->ssa_temp_index(),
                defn->constant_value().ToCString());
    }
    constant_value_ = defn->constant_value().raw();
    if ((constant_value_.IsString() || constant_value_.IsMint() ||
         constant_value_.IsDouble()) &&
        !constant_value_.IsCanonical()) {
      constant_value_ = Instance::Cast(constant_value_).Canonicalize(T);
      ASSERT(!constant_value_.IsNull());
    }
    if (auto call = defn->AsStaticCall()) {
      ASSERT(!call->HasPushArguments());
    }
    Definition* replacement =
        graph_->TryCreateConstantReplacementFor(defn, constant_value_);
    if (replacement != defn) {
      defn->ReplaceUsesWith(replacement);
      return true;
    }
  }
  return false;
}

}  // namespace dart
