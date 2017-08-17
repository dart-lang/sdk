// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/constant_propagator.h"

#include "vm/bit_vector.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
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

ConstantPropagator::ConstantPropagator(
    FlowGraph* graph,
    const GrowableArray<BlockEntryInstr*>& ignored)
    : FlowGraphVisitor(ignored),
      graph_(graph),
      unknown_(Object::unknown_constant()),
      non_constant_(Object::non_constant()),
      reachable_(new (Z) BitVector(Z, graph->preorder().length())),
      marked_phis_(new (Z) BitVector(Z, graph->max_virtual_register_number())),
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
  // TODO(kmillikin): support equality for doubles, mints, etc.
  if (left->raw() == right.raw()) return;

  // Join(X, Y) = non-constant
  *left = non_constant_.raw();
}

// --------------------------------------------------------------------------
// Analysis of blocks.  Called at most once per block.  The block is already
// marked as reachable.  All instructions in the block are analyzed.
void ConstantPropagator::VisitGraphEntry(GraphEntryInstr* block) {
  const GrowableArray<Definition*>& defs = *block->initial_definitions();
  for (intptr_t i = 0; i < defs.length(); ++i) {
    defs[i]->Accept(this);
  }
  ASSERT(ForwardInstructionIterator(block).Done());

  // TODO(fschneider): Improve this approximation. The catch entry is only
  // reachable if a call in the try-block is reachable.
  for (intptr_t i = 0; i < block->SuccessorCount(); ++i) {
    SetReachable(block->SuccessorAt(i));
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

void ConstantPropagator::VisitCatchBlockEntry(CatchBlockEntryInstr* block) {
  const GrowableArray<Definition*>& defs = *block->initial_definitions();
  for (intptr_t i = 0; i < defs.length(); ++i) {
    defs[i]->Accept(this);
  }
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
    it.Current()->Accept(this);
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

void ConstantPropagator::VisitCheckClassId(CheckClassIdInstr* instr) {}

void ConstantPropagator::VisitGuardFieldClass(GuardFieldClassInstr* instr) {}

void ConstantPropagator::VisitGuardFieldLength(GuardFieldLengthInstr* instr) {}

void ConstantPropagator::VisitCheckSmi(CheckSmiInstr* instr) {}

void ConstantPropagator::VisitGenericCheckBound(GenericCheckBoundInstr* instr) {
}

void ConstantPropagator::VisitCheckEitherNonSmi(CheckEitherNonSmiInstr* instr) {
}

void ConstantPropagator::VisitCheckArrayBound(CheckArrayBoundInstr* instr) {}

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

void ConstantPropagator::MarkPhi(Definition* phi) {
  ASSERT(phi->IsPhi());
  marked_phis_->Add(phi->ssa_temp_index());
}

// --------------------------------------------------------------------------
// Analysis of definitions.  Compute the constant value.  If it has changed
// and the definition has input uses, add the definition to the definition
// worklist so that the used can be processed.
void ConstantPropagator::VisitPhi(PhiInstr* instr) {
  // Compute the join over all the reachable predecessor values.
  JoinEntryInstr* block = instr->block();
  Object& value = Object::ZoneHandle(Z, Unknown());
  for (intptr_t pred_idx = 0; pred_idx < instr->InputCount(); ++pred_idx) {
    if (reachable_->Contains(
            block->PredecessorAt(pred_idx)->preorder_number())) {
      Join(&value, instr->InputAt(pred_idx)->definition()->constant_value());
    }
  }
  if (!SetValue(instr, value) &&
      marked_phis_->Contains(instr->ssa_temp_index())) {
    marked_phis_->Remove(instr->ssa_temp_index());
    definition_worklist_.Add(instr);
  }
}

void ConstantPropagator::VisitRedefinition(RedefinitionInstr* instr) {
  // Ensure that we never remove redefinition of a constant unless we are also
  // are guaranteed to fold away code paths that correspond to non-matching
  // class ids. Otherwise LICM might potentially hoist incorrect code.
  const Object& value = instr->value()->definition()->constant_value();
  if (IsConstant(value) && !Field::IsExternalizableCid(value.GetClassId())) {
    SetValue(instr, value);
  } else {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitParameter(ParameterInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitPushArgument(PushArgumentInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}

void ConstantPropagator::VisitAssertAssignable(AssertAssignableInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // We are ignoring the instantiator and instantiator_type_arguments, but
    // still monotonic and safe.
    if (instr->value()->Type()->IsAssignableTo(instr->dst_type())) {
      SetValue(instr, value);
    } else {
      SetValue(instr, non_constant_);
    }
  }
}

void ConstantPropagator::VisitAssertBoolean(AssertBooleanInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    if (value.IsBool()) {
      SetValue(instr, value);
    } else {
      SetValue(instr, non_constant_);
    }
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

void ConstantPropagator::VisitStaticCall(StaticCallInstr* instr) {
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

void ConstantPropagator::VisitStoreLocal(StoreLocalInstr* instr) {
  // Instruction is eliminated when translating to SSA.
  UNREACHABLE();
}

void ConstantPropagator::VisitIfThenElse(IfThenElseInstr* instr) {
  instr->comparison()->Accept(this);
  const Object& value = instr->comparison()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    ASSERT(!value.IsNull());
    ASSERT(value.IsBool());
    bool result = Bool::Cast(value).value();
    SetValue(instr, Smi::Handle(Z, Smi::New(result ? instr->if_true()
                                                   : instr->if_false())));
  }
}

void ConstantPropagator::VisitStrictCompare(StrictCompareInstr* instr) {
  Definition* left_defn = instr->left()->definition();
  Definition* right_defn = instr->right()->definition();

  Definition* unwrapped_left_defn = UnwrapPhi(left_defn);
  Definition* unwrapped_right_defn = UnwrapPhi(right_defn);
  if (unwrapped_left_defn == unwrapped_right_defn) {
    // Fold x === x, and x !== x to true/false.
    SetValue(instr, Bool::Get(instr->kind() == Token::kEQ_STRICT));
    if (unwrapped_left_defn != left_defn) {
      MarkPhi(left_defn);
    }
    if (unwrapped_right_defn != right_defn) {
      MarkPhi(right_defn);
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
      if ((left_cid != kDynamicCid) && (right_cid != kDynamicCid) &&
          (left_cid != right_cid)) {
        const bool result = (instr->kind() != Token::kEQ_STRICT);
        SetValue(instr, Bool::Get(result));
      } else {
        SetValue(instr, non_constant_);
      }
    }
  } else if (IsConstant(left) && IsConstant(right)) {
    bool result = (left.raw() == right.raw());
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
  } else if (IsConstant(left) && IsConstant(right)) {
    // BitOp does not work on Bigints.
    if (left.IsInteger() && right.IsInteger() && !left.IsBigint() &&
        !right.IsBigint()) {
      const bool result = CompareIntegers(
          instr->kind(),
          Integer::Handle(Z, Integer::Cast(left).BitOp(Token::kBIT_AND,
                                                       Integer::Cast(right))),
          Smi::Handle(Z, Smi::New(0)));
      SetValue(instr, result ? Bool::True() : Bool::False());
    } else {
      SetValue(instr, non_constant_);
    }
  }
}

void ConstantPropagator::VisitTestCids(TestCidsInstr* instr) {
  // TODO(sra): Constant fold test.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitEqualityCompare(EqualityCompareInstr* instr) {
  Definition* left_defn = instr->left()->definition();
  Definition* right_defn = instr->right()->definition();

  if (RawObject::IsIntegerClassId(instr->operation_cid())) {
    // Fold x == x, and x != x to true/false for numbers comparisons.
    Definition* unwrapped_left_defn = UnwrapPhi(left_defn);
    Definition* unwrapped_right_defn = UnwrapPhi(right_defn);
    if (unwrapped_left_defn == unwrapped_right_defn) {
      // Fold x === x, and x !== x to true/false.
      SetValue(instr, Bool::Get(instr->kind() == Token::kEQ));
      if (unwrapped_left_defn != left_defn) {
        MarkPhi(left_defn);
      }
      if (unwrapped_right_defn != right_defn) {
        MarkPhi(right_defn);
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

void ConstantPropagator::VisitDebugStepCheck(DebugStepCheckInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitOneByteStringFromCharCode(
    OneByteStringFromCharCodeInstr* instr) {
  const Object& o = instr->char_code()->definition()->constant_value();
  if (o.IsNull() || IsNonConstant(o)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(o)) {
    const intptr_t ch_code = Smi::Cast(o).Value();
    ASSERT(ch_code >= 0);
    if (ch_code < Symbols::kMaxOneCharCodeSymbol) {
      RawString** table = Symbols::PredefinedAddress();
      SetValue(instr, String::ZoneHandle(Z, table[ch_code]));
    } else {
      SetValue(instr, non_constant_);
    }
  }
}

void ConstantPropagator::VisitStringToCharCode(StringToCharCodeInstr* instr) {
  const Object& o = instr->str()->definition()->constant_value();
  if (o.IsNull() || IsNonConstant(o)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(o)) {
    const String& str = String::Cast(o);
    const intptr_t result =
        (str.Length() == 1) ? static_cast<intptr_t>(str.CharAt(0)) : -1;
    SetValue(instr, Smi::ZoneHandle(Z, Smi::New(result)));
  }
}

void ConstantPropagator::VisitStringInterpolate(StringInterpolateInstr* instr) {
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

void ConstantPropagator::VisitStoreIndexed(StoreIndexedInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}

void ConstantPropagator::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}

void ConstantPropagator::VisitInitStaticField(InitStaticFieldInstr* instr) {
  // Nothing to do.
}

void ConstantPropagator::VisitLoadStaticField(LoadStaticFieldInstr* instr) {
  if (!FLAG_fields_may_be_reset) {
    const Field& field = instr->StaticField();
    ASSERT(field.is_static());
    Instance& obj = Instance::Handle(Z, field.StaticValue());
    if (field.is_final() && (obj.raw() != Object::sentinel().raw()) &&
        (obj.raw() != Object::transition_sentinel().raw())) {
      if (obj.IsSmi() || obj.IsOld()) {
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
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    bool val = value.raw() != Bool::True().raw();
    SetValue(instr, Bool::Get(val));
  }
}

void ConstantPropagator::VisitInstanceOf(InstanceOfInstr* instr) {
  Definition* def = instr->value()->definition();
  const Object& value = def->constant_value();
  if (IsNonConstant(value)) {
    const AbstractType& checked_type = instr->type();
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
    if (value.IsInstance()) {
      const Instance& instance = Instance::Cast(value);
      const AbstractType& checked_type = instr->type();
      if (instr->instantiator_type_arguments()->BindsToConstantNull() &&
          instr->function_type_arguments()->BindsToConstantNull()) {
        Error& bound_error = Error::Handle();
        bool is_instance =
            instance.IsInstanceOf(checked_type, Object::null_type_arguments(),
                                  Object::null_type_arguments(), &bound_error);
        // Can only have bound error with generics.
        ASSERT(bound_error.IsNull());
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

void ConstantPropagator::VisitAllocateObject(AllocateObjectInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadUntagged(LoadUntaggedInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadClassId(LoadClassIdInstr* instr) {
  intptr_t cid = instr->object()->Type()->ToCid();
  if (cid != kDynamicCid) {
    SetValue(instr, Smi::ZoneHandle(Z, Smi::New(cid)));
    return;
  }

  const Object& object = instr->object()->definition()->constant_value();
  if (IsConstant(object)) {
    cid = object.GetClassId();
    if (!Field::IsExternalizableCid(cid)) {
      SetValue(instr, Smi::ZoneHandle(Z, Smi::New(cid)));
      return;
    }
  }
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitLoadField(LoadFieldInstr* instr) {
  Value* instance = instr->instance();
  if ((instr->recognized_kind() == MethodRecognizer::kObjectArrayLength) &&
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
  const Object& object =
      instr->instantiator_type_arguments()->definition()->constant_value();
  if (IsNonConstant(object)) {
    SetValue(instr, non_constant_);
    return;
  }
  if (IsConstant(object)) {
    if (instr->type().IsTypeParameter() &&
        TypeParameter::Cast(instr->type()).IsClassTypeParameter()) {
      if (object.IsNull()) {
        SetValue(instr, Object::dynamic_type());
        return;
      }
      // We could try to instantiate the type parameter and return it if no
      // malformed error is reported.
    }
    SetValue(instr, non_constant_);
  }
  // TODO(regis): We can do the same as above for a function type parameter.
  // Better: If both instantiator type arguments and function type arguments are
  // constant, instantiate the type if no bound error is reported.
}

void ConstantPropagator::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsInstr* instr) {
  const Object& instantiator_type_args =
      instr->instantiator_type_arguments()->definition()->constant_value();
  const Object& function_type_args =
      instr->function_type_arguments()->definition()->constant_value();
  if (IsNonConstant(instantiator_type_args) ||
      IsNonConstant(function_type_args)) {
    SetValue(instr, non_constant_);
    return;
  }
  if (IsConstant(instantiator_type_args) && IsConstant(function_type_args)) {
    if (instantiator_type_args.IsNull() && function_type_args.IsNull()) {
      const intptr_t len = instr->type_arguments().Length();
      if (instr->type_arguments().IsRawWhenInstantiatedFromRaw(len)) {
        SetValue(instr, instantiator_type_args);
        return;
      }
    }
    if (instr->type_arguments().IsUninstantiatedIdentity() ||
        instr->type_arguments().CanShareInstantiatorTypeArguments(
            instr->instantiator_class())) {
      SetValue(instr, instantiator_type_args);
      return;
    }
    SetValue(instr, non_constant_);
  }
  // TODO(regis): If both instantiator type arguments and function type
  // arguments are constant, instantiate the type arguments if no bound error
  // is reported.
  // TODO(regis): If either instantiator type arguments or function type
  // arguments are constant null, check
  // type_arguments().IsRawWhenInstantiatedFromRaw() separately for each
  // genericity.
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
  if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const Integer& left_int = Integer::Cast(left);
      const Integer& right_int = Integer::Cast(right);
      const Integer& result =
          Integer::Handle(Z, binary_op->Evaluate(left_int, right_int));
      if (!result.IsNull()) {
        SetValue(binary_op, Integer::ZoneHandle(Z, result.raw()));
        return;
      }
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

void ConstantPropagator::VisitShiftUint32Op(ShiftUint32OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitBinaryInt64Op(BinaryInt64OpInstr* instr) {
  VisitBinaryIntegerOp(instr);
}

void ConstantPropagator::VisitShiftInt64Op(ShiftInt64OpInstr* instr) {
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
  if (IsConstant(value) && value.IsInteger()) {
    const Integer& value_int = Integer::Cast(value);
    const Integer& result = Integer::Handle(Z, unary_op->Evaluate(value_int));
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
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle unary operations.
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitSmiToDouble(SmiToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsConstant(value) && value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else if (!IsUnknown(value)) {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitMintToDouble(MintToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsConstant(value) && value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else if (!IsUnknown(value)) {
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitInt32ToDouble(Int32ToDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsConstant(value) && value.IsInteger()) {
    SetValue(instr,
             Double::Handle(Z, Double::New(Integer::Cast(value).AsDoubleValue(),
                                           Heap::kOld)));
  } else if (!IsUnknown(value)) {
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
  } else if (left.IsInteger() && right.IsInteger()) {
    SetValue(instr, non_constant_);
  } else if (IsIntegerOrDouble(left) && IsIntegerOrDouble(right)) {
    const double left_val = ToDouble(left);
    const double right_val = ToDouble(right);
    double result_val = 0.0;
    switch (instr->op_kind()) {
      case Token::kADD:
        result_val = left_val + right_val;
        break;
      case Token::kSUB:
        result_val = left_val - right_val;
        break;
      case Token::kMUL:
        result_val = left_val * right_val;
        break;
      case Token::kDIV:
        result_val = left_val / right_val;
        break;
      default:
        UNREACHABLE();
    }
    const Double& result = Double::ZoneHandle(Double::NewCanonical(result_val));
    SetValue(instr, result);
  }
}

void ConstantPropagator::VisitDoubleTestOp(DoubleTestOpInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
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

void ConstantPropagator::VisitBinaryFloat32x4Op(BinaryFloat32x4OpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle binary operation.
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitFloat32x4Constructor(
    Float32x4ConstructorInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitSimd32x4Shuffle(Simd32x4ShuffleInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitSimd32x4ShuffleMix(
    Simd32x4ShuffleMixInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitSimd32x4GetSignMask(
    Simd32x4GetSignMaskInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Zero(Float32x4ZeroInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Splat(Float32x4SplatInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Comparison(
    Float32x4ComparisonInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4MinMax(Float32x4MinMaxInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Scale(Float32x4ScaleInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Sqrt(Float32x4SqrtInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4ZeroArg(Float32x4ZeroArgInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4Clamp(Float32x4ClampInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4With(Float32x4WithInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4ToInt32x4(
    Float32x4ToInt32x4Instr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4Constructor(
    Int32x4ConstructorInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4BoolConstructor(
    Int32x4BoolConstructorInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4GetFlag(Int32x4GetFlagInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4SetFlag(Int32x4SetFlagInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4Select(Int32x4SelectInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitInt32x4ToFloat32x4(
    Int32x4ToFloat32x4Instr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBinaryInt32x4Op(BinaryInt32x4OpInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitSimd64x2Shuffle(Simd64x2ShuffleInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitBinaryFloat64x2Op(BinaryFloat64x2OpInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat32x4ToFloat64x2(
    Float32x4ToFloat64x2Instr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2ToFloat32x4(
    Float64x2ToFloat32x4Instr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2Zero(Float64x2ZeroInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2Splat(Float64x2SplatInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2Constructor(
    Float64x2ConstructorInstr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2ZeroArg(Float64x2ZeroArgInstr* instr) {
  // TODO(johnmccutchan): Implement constant propagation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitFloat64x2OneArg(Float64x2OneArgInstr* instr) {
  // TODO(johnmccutchan): Implement constant propagation.
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitMathUnary(MathUnaryInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle Math's unary operations (sqrt, cos, sin).
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitMathMinMax(MathMinMaxInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(srdjan): Handle min and max.
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitCaseInsensitiveCompareUC16(
    CaseInsensitiveCompareUC16Instr* instr) {
  SetValue(instr, non_constant_);
}

void ConstantPropagator::VisitUnbox(UnboxInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}

void ConstantPropagator::VisitBox(BoxInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
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

void ConstantPropagator::VisitUnboxedIntConverter(
    UnboxedIntConverterInstr* instr) {
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
      Value* use = definition->input_use_list();
      while (use != NULL) {
        use->instruction()->Accept(this);
        use = use->next_use();
      }
    } else {
      BlockEntryInstr* block = block_worklist_.RemoveLast();
      block->Accept(this);
    }
  }
}

static bool IsEmptyBlock(BlockEntryInstr* block) {
  return block->next()->IsGoto() &&
         (!block->IsJoinEntry() || (block->AsJoinEntry()->phis() == NULL)) &&
         !block->IsIndirectEntry();
}

// Traverses a chain of empty blocks and returns the first reachable non-empty
// block that is not dominated by the start block. The empty blocks are added
// to the supplied bit vector.
static BlockEntryInstr* FindFirstNonEmptySuccessor(TargetEntryInstr* block,
                                                   BitVector* empty_blocks) {
  BlockEntryInstr* current = block;
  while (IsEmptyBlock(current) && block->Dominates(current)) {
    ASSERT(!block->IsJoinEntry() || (block->AsJoinEntry()->phis() == NULL));
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
    if ((branch != NULL) && branch->Effects().IsNone()) {
      ASSERT(branch->previous() != NULL);  // Not already eliminated.
      BlockEntryInstr* if_true =
          FindFirstNonEmptySuccessor(branch->true_successor(), empty_blocks);
      BlockEntryInstr* if_false =
          FindFirstNonEmptySuccessor(branch->false_successor(), empty_blocks);
      if (if_true == if_false) {
        // Replace the branch with a jump to the common successor.
        // Drop the comparison, which does not have side effects
        JoinEntryInstr* join = if_true->AsJoinEntry();
        if (join->phis() == NULL) {
          GotoInstr* jump =
              new (Z) GotoInstr(if_true->AsJoinEntry(), Thread::kNoDeoptId);
          jump->InheritDeoptTarget(Z, branch);

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

          if (FLAG_trace_constant_propagation &&
              FlowGraphPrinter::ShouldPrint(graph_->function())) {
            THR_Print("Eliminated branch in B%" Pd " common target B%" Pd "\n",
                      block->block_id(), join->block_id());
          }
        }
      }
    }
  }

  if (changed) {
    graph_->DiscoverBlocks();
    // TODO(fschneider): Update dominator tree in place instead of recomputing.
    GrowableArray<BitVector*> dominance_frontier;
    graph_->ComputeDominators(&dominance_frontier);
  }
}

void ConstantPropagator::Transform() {
  if (FLAG_trace_constant_propagation &&
      FlowGraphPrinter::ShouldPrint(graph_->function())) {
    FlowGraphPrinter::PrintGraph("Before CP", graph_);
  }

  // We will recompute dominators, block ordering, block ids, block last
  // instructions, previous pointers, predecessors, etc. after eliminating
  // unreachable code.  We do not maintain those properties during the
  // transformation.
  for (BlockIterator b = graph_->reverse_postorder_iterator(); !b.Done();
       b.Advance()) {
    BlockEntryInstr* block = b.Current();
    if (!reachable_->Contains(block->preorder_number())) {
      if (FLAG_trace_constant_propagation &&
          FlowGraphPrinter::ShouldPrint(graph_->function())) {
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

    for (ForwardInstructionIterator i(block); !i.Done(); i.Advance()) {
      Definition* defn = i.Current()->AsDefinition();
      // Replace constant-valued instructions without observable side
      // effects.  Do this for smis only to avoid having to copy other
      // objects into the heap's old generation.
      if ((defn != NULL) && IsConstant(defn->constant_value()) &&
          (defn->constant_value().IsSmi() || defn->constant_value().IsOld()) &&
          !defn->IsConstant() && !defn->IsPushArgument() &&
          !defn->IsStoreIndexed() && !defn->IsStoreInstanceField() &&
          !defn->IsStoreStaticField()) {
        if (FLAG_trace_constant_propagation &&
            FlowGraphPrinter::ShouldPrint(graph_->function())) {
          THR_Print("Constant v%" Pd " = %s\n", defn->ssa_temp_index(),
                    defn->constant_value().ToCString());
        }
        ConstantInstr* constant = graph_->GetConstant(defn->constant_value());
        defn->ReplaceUsesWith(constant);
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
        ASSERT(if_false->loop_info() == NULL);
        join = new (Z) JoinEntryInstr(
            if_false->block_id(), if_false->try_index(), Thread::kNoDeoptId);
        join->InheritDeoptTarget(Z, if_false);
        if_false->UnuseAllInputs();
        next = if_false->next();
      } else if (!reachable_->Contains(if_false->preorder_number())) {
        ASSERT(if_true->parallel_move() == NULL);
        ASSERT(if_true->loop_info() == NULL);
        join = new (Z) JoinEntryInstr(if_true->block_id(), if_true->try_index(),
                                      Thread::kNoDeoptId);
        join->InheritDeoptTarget(Z, if_true);
        if_true->UnuseAllInputs();
        next = if_true->next();
      }

      if (join != NULL) {
        // Replace the branch with a jump to the reachable successor.
        // Drop the comparison, which does not have side effects as long
        // as it is a strict compare (the only one we can determine is
        // constant with the current analysis).
        GotoInstr* jump = new (Z) GotoInstr(join, Thread::kNoDeoptId);
        jump->InheritDeoptTarget(Z, branch);

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

  if (FLAG_trace_constant_propagation &&
      FlowGraphPrinter::ShouldPrint(graph_->function())) {
    FlowGraphPrinter::PrintGraph("After CP", graph_);
  }
}

}  // namespace dart
