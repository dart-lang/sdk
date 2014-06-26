// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/cha.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/hash_map.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, array_bounds_check_elimination, true,
    "Eliminate redundant bounds checks.");
DEFINE_FLAG(int, getter_setter_ratio, 13,
    "Ratio of getter/setter usage used for double field unboxing heuristics");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");
DEFINE_FLAG(bool, dead_store_elimination, true, "Eliminate dead stores");
DEFINE_FLAG(int, max_polymorphic_checks, 4,
    "Maximum number of polymorphic check, otherwise it is megamorphic.");
DEFINE_FLAG(int, max_equality_polymorphic_checks, 32,
    "Maximum number of polymorphic checks in equality operator,"
    " otherwise use megamorphic dispatch.");
DEFINE_FLAG(bool, remove_redundant_phis, true, "Remove redundant phis.");
DEFINE_FLAG(bool, trace_constant_propagation, false,
    "Print constant propagation and useless code elimination.");
DEFINE_FLAG(bool, trace_load_optimization, false,
    "Print live sets for load optimization pass.");
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DEFINE_FLAG(bool, trace_range_analysis, false, "Trace range analysis progress");
DEFINE_FLAG(bool, truncating_left_shift, true,
    "Optimize left shift to truncate if possible");
DEFINE_FLAG(bool, use_cha, true, "Use class hierarchy analysis.");
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, source_lines);
DECLARE_FLAG(bool, trace_type_check_elimination);
DECLARE_FLAG(bool, warn_on_javascript_compatibility);

// Quick access to the locally defined isolate() method.
#define I (isolate())

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}


static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}


// Optimize instance calls using ICData.
void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


// Optimize instance calls using cid.  This is called after optimizer
// converted instance calls to instructions. Any remaining
// instance calls are either megamorphic calls, cannot be optimized or
// have no runtime type feedback collected.
// Attempts to convert an instance call (IC call) using propagated class-ids,
// e.g., receiver class id, guarded-cid, or by guessing cid-s.
void FlowGraphOptimizer::ApplyClassIds() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (call->HasICData()) {
          if (TryCreateICData(call)) {
            VisitInstanceCall(call);
          }
        }
      } else if (instr->IsPolymorphicInstanceCall()) {
        SpecializePolymorphicInstanceCall(instr->AsPolymorphicInstanceCall());
      } else if (instr->IsStrictCompare()) {
        VisitStrictCompare(instr->AsStrictCompare());
      } else if (instr->IsBranch()) {
        ComparisonInstr* compare = instr->AsBranch()->comparison();
        if (compare->IsStrictCompare()) {
          VisitStrictCompare(compare->AsStrictCompare());
        }
      }
    }
    current_iterator_ = NULL;
  }
}


// TODO(srdjan): Test/support other number types as well.
static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}


// Attempt to build ICData for call using propagated class-ids.
bool FlowGraphOptimizer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  if (call->ic_data()->NumberOfChecks() > 0) {
    // This occurs when an instance call has too many checks, will be converted
    // to megamorphic call.
    return false;
  }
  if (FLAG_warn_on_javascript_compatibility) {
    // Do not make the instance call megamorphic if the callee needs to decode
    // the calling code sequence to lookup the ic data and verify if a warning
    // has already been issued or not.
    // TryCreateICData is only invoked if the ic_data target has not been called
    // yet, so no warning can possibly have been issued.
    ASSERT(!call->ic_data()->IssuedJSWarning());
    if (call->ic_data()->MayCheckForJSWarning()) {
      return false;
    }
  }
  GrowableArray<intptr_t> class_ids(call->ic_data()->NumArgsTested());
  ASSERT(call->ic_data()->NumArgsTested() <= call->ArgumentCount());
  for (intptr_t i = 0; i < call->ic_data()->NumArgsTested(); i++) {
    const intptr_t cid = call->PushArgumentAt(i)->value()->Type()->ToCid();
    class_ids.Add(cid);
  }

  const Token::Kind op_kind = call->token_kind();
  if (Token::IsRelationalOperator(op_kind) ||
      Token::IsEqualityOperator(op_kind) ||
      Token::IsBinaryOperator(op_kind)) {
    // Guess cid: if one of the inputs is a number assume that the other
    // is a number of same type.
    const intptr_t cid_0 = class_ids[0];
    const intptr_t cid_1 = class_ids[1];
    if ((cid_0 == kDynamicCid) && (IsNumberCid(cid_1))) {
      class_ids[0] = cid_1;
    } else if (IsNumberCid(cid_0) && (cid_1 == kDynamicCid)) {
      class_ids[1] = cid_0;
    }
  }

  for (intptr_t i = 0; i < class_ids.length(); i++) {
    if (class_ids[i] == kDynamicCid) {
      // Not all cid-s known.
      return false;
    }
  }

  const Array& args_desc_array = Array::Handle(I,
      ArgumentsDescriptor::New(call->ArgumentCount(), call->argument_names()));
  ArgumentsDescriptor args_desc(args_desc_array);
  const Class& receiver_class = Class::Handle(I,
      isolate()->class_table()->At(class_ids[0]));
  const Function& function = Function::Handle(I,
      Resolver::ResolveDynamicForReceiverClass(
          receiver_class,
          call->function_name(),
          args_desc));
  if (function.IsNull()) {
    return false;
  }
  // Create new ICData, do not modify the one attached to the instruction
  // since it is attached to the assembly instruction itself.
  // TODO(srdjan): Prevent modification of ICData object that is
  // referenced in assembly code.
  ICData& ic_data = ICData::ZoneHandle(I, ICData::New(
      flow_graph_->parsed_function().function(),
      call->function_name(),
      args_desc_array,
      call->deopt_id(),
      class_ids.length()));
  if (class_ids.length() > 1) {
    ic_data.AddCheck(class_ids, function);
  } else {
    ASSERT(class_ids.length() == 1);
    ic_data.AddReceiverCheck(class_ids[0], function);
  }
  call->set_ic_data(&ic_data);
  return true;
}


const ICData& FlowGraphOptimizer::TrySpecializeICData(const ICData& ic_data,
                                                      intptr_t cid) {
  ASSERT(ic_data.NumArgsTested() == 1);

  if ((ic_data.NumberOfChecks() == 1) &&
      (ic_data.GetReceiverClassIdAt(0) == cid)) {
    return ic_data;  // Nothing to do
  }

  const Function& function =
      Function::Handle(I, ic_data.GetTargetForReceiverClassId(cid));
  // TODO(fschneider): Try looking up the function on the class if it is
  // not found in the ICData.
  if (!function.IsNull()) {
    const ICData& new_ic_data = ICData::ZoneHandle(I, ICData::New(
        Function::Handle(I, ic_data.owner()),
        String::Handle(I, ic_data.target_name()),
        Object::empty_array(),  // Dummy argument descriptor.
        ic_data.deopt_id(),
        ic_data.NumArgsTested()));
    new_ic_data.SetDeoptReasons(ic_data.DeoptReasons());
    new_ic_data.AddReceiverCheck(cid, function);
    return new_ic_data;
  }

  return ic_data;
}


void FlowGraphOptimizer::SpecializePolymorphicInstanceCall(
    PolymorphicInstanceCallInstr* call) {
  if (!call->with_checks()) {
    return;  // Already specialized.
  }

  const intptr_t receiver_cid =
      call->PushArgumentAt(0)->value()->Type()->ToCid();
  if (receiver_cid == kDynamicCid) {
    return;  // No information about receiver was infered.
  }

  const ICData& ic_data = TrySpecializeICData(call->ic_data(), receiver_cid);
  if (ic_data.raw() == call->ic_data().raw()) {
    // No specialization.
    return;
  }

  const bool with_checks = false;
  PolymorphicInstanceCallInstr* specialized =
      new(I) PolymorphicInstanceCallInstr(call->instance_call(),
                                          ic_data,
                                          with_checks);
  call->ReplaceWith(specialized, current_iterator());
}


static BinarySmiOpInstr* AsSmiShiftLeftInstruction(Definition* d) {
  BinarySmiOpInstr* instr = d->AsBinarySmiOp();
  if ((instr != NULL) && (instr->op_kind() == Token::kSHL)) {
    return instr;
  }
  return NULL;
}


static bool IsPositiveOrZeroSmiConst(Definition* d) {
  ConstantInstr* const_instr = d->AsConstant();
  if ((const_instr != NULL) && (const_instr->value().IsSmi())) {
    return Smi::Cast(const_instr->value()).Value() >= 0;
  }
  return false;
}


void FlowGraphOptimizer::OptimizeLeftShiftBitAndSmiOp(
    Definition* bit_and_instr,
    Definition* left_instr,
    Definition* right_instr) {
  ASSERT(bit_and_instr != NULL);
  ASSERT((left_instr != NULL) && (right_instr != NULL));

  // Check for pattern, smi_shift_left must be single-use.
  bool is_positive_or_zero = IsPositiveOrZeroSmiConst(left_instr);
  if (!is_positive_or_zero) {
    is_positive_or_zero = IsPositiveOrZeroSmiConst(right_instr);
  }
  if (!is_positive_or_zero) return;

  BinarySmiOpInstr* smi_shift_left = NULL;
  if (bit_and_instr->InputAt(0)->IsSingleUse()) {
    smi_shift_left = AsSmiShiftLeftInstruction(left_instr);
  }
  if ((smi_shift_left == NULL) && (bit_and_instr->InputAt(1)->IsSingleUse())) {
    smi_shift_left = AsSmiShiftLeftInstruction(right_instr);
  }
  if (smi_shift_left == NULL) return;

  // Pattern recognized.
  smi_shift_left->set_is_truncating(true);
  ASSERT(bit_and_instr->IsBinarySmiOp() || bit_and_instr->IsBinaryMintOp());
  if (bit_and_instr->IsBinaryMintOp()) {
    // Replace Mint op with Smi op.
    BinarySmiOpInstr* smi_op = new(I) BinarySmiOpInstr(
        Token::kBIT_AND,
        new(I) Value(left_instr),
        new(I) Value(right_instr),
        Isolate::kNoDeoptId,  // BIT_AND cannot deoptimize.
        Scanner::kNoSourcePos);
    bit_and_instr->ReplaceWith(smi_op, current_iterator());
  }
}



// Used by TryMergeDivMod.
// Inserts a load-indexed instruction between a TRUNCDIV or MOD instruction,
// and the using instruction. This is an intermediate step before merging.
void FlowGraphOptimizer::AppendLoadIndexedForMerged(Definition* instr,
                                                    intptr_t ix,
                                                    intptr_t cid) {
  const intptr_t index_scale = Instance::ElementSizeFor(cid);
  ConstantInstr* index_instr =
      flow_graph()->GetConstant(Smi::Handle(I, Smi::New(ix)));
  LoadIndexedInstr* load =
      new(I) LoadIndexedInstr(new(I) Value(instr),
                                      new(I) Value(index_instr),
                                      index_scale,
                                      cid,
                                      Isolate::kNoDeoptId,
                                      instr->token_pos());
  instr->ReplaceUsesWith(load);
  flow_graph()->InsertAfter(instr, load, NULL, FlowGraph::kValue);
}


void FlowGraphOptimizer::AppendExtractNthOutputForMerged(Definition* instr,
                                                         intptr_t index,
                                                         Representation rep,
                                                         intptr_t cid) {
  ExtractNthOutputInstr* extract =
      new(I) ExtractNthOutputInstr(new(I) Value(instr), index, rep, cid);
  instr->ReplaceUsesWith(extract);
  flow_graph()->InsertAfter(instr, extract, NULL, FlowGraph::kValue);
}


// Dart:
//  var x = d % 10;
//  var y = d ~/ 10;
//  var z = x + y;
//
// IL:
//  v4 <- %(v2, v3)
//  v5 <- ~/(v2, v3)
//  v6 <- +(v4, v5)
//
// IL optimized:
//  v4 <- DIVMOD(v2, v3);
//  v5 <- LoadIndexed(v4, 0); // ~/ result
//  v6 <- LoadIndexed(v4, 1); // % result
//  v7 <- +(v5, v6)
// Because of the environment it is important that merged instruction replaces
// first original instruction encountered.
void FlowGraphOptimizer::TryMergeTruncDivMod(
    GrowableArray<BinarySmiOpInstr*>* merge_candidates) {
  if (merge_candidates->length() < 2) {
    // Need at least a TRUNCDIV and a MOD.
    return;
  }
  for (intptr_t i = 0; i < merge_candidates->length(); i++) {
    BinarySmiOpInstr* curr_instr = (*merge_candidates)[i];
    if (curr_instr == NULL) {
      // Instruction was merged already.
      continue;
    }
    ASSERT((curr_instr->op_kind() == Token::kTRUNCDIV) ||
           (curr_instr->op_kind() == Token::kMOD));
    // Check if there is kMOD/kTRUNDIV binop with same inputs.
    const intptr_t other_kind = (curr_instr->op_kind() == Token::kTRUNCDIV) ?
        Token::kMOD : Token::kTRUNCDIV;
    Definition* left_def = curr_instr->left()->definition();
    Definition* right_def = curr_instr->right()->definition();
    for (intptr_t k = i + 1; k < merge_candidates->length(); k++) {
      BinarySmiOpInstr* other_binop = (*merge_candidates)[k];
      // 'other_binop' can be NULL if it was already merged.
      if ((other_binop != NULL) &&
          (other_binop->op_kind() == other_kind) &&
          (other_binop->left()->definition() == left_def) &&
          (other_binop->right()->definition() == right_def)) {
        (*merge_candidates)[k] = NULL;  // Clear it.
        ASSERT(curr_instr->HasUses());
        AppendExtractNthOutputForMerged(
            curr_instr,
            MergedMathInstr::OutputIndexOf(curr_instr->op_kind()),
            kTagged, kSmiCid);
        ASSERT(other_binop->HasUses());
        AppendExtractNthOutputForMerged(
            other_binop,
            MergedMathInstr::OutputIndexOf(other_binop->op_kind()),
            kTagged, kSmiCid);

        ZoneGrowableArray<Value*>* args = new(I) ZoneGrowableArray<Value*>(2);
        args->Add(new(I) Value(curr_instr->left()->definition()));
        args->Add(new(I) Value(curr_instr->right()->definition()));

        // Replace with TruncDivMod.
        MergedMathInstr* div_mod = new(I) MergedMathInstr(
            args,
            curr_instr->deopt_id(),
            MergedMathInstr::kTruncDivMod);
        curr_instr->ReplaceWith(div_mod, current_iterator());
        other_binop->ReplaceUsesWith(div_mod);
        other_binop->RemoveFromGraph();
        // Only one merge possible. Because canonicalization happens later,
        // more candidates are possible.
        // TODO(srdjan): Allow merging of trunc-div/mod into truncDivMod.
        break;
      }
    }
  }
}


// Tries to merge MathUnary operations, in this case sinus and cosinus.
void FlowGraphOptimizer::TryMergeMathUnary(
    GrowableArray<MathUnaryInstr*>* merge_candidates) {
  if (!FlowGraphCompiler::SupportsSinCos() || !CanUnboxDouble()) {
    return;
  }
  if (merge_candidates->length() < 2) {
    // Need at least a SIN and a COS.
    return;
  }
  for (intptr_t i = 0; i < merge_candidates->length(); i++) {
    MathUnaryInstr* curr_instr = (*merge_candidates)[i];
    if (curr_instr == NULL) {
      // Instruction was merged already.
      continue;
    }
    const intptr_t kind = curr_instr->kind();
    ASSERT((kind == MathUnaryInstr::kSin) ||
           (kind == MathUnaryInstr::kCos));
    // Check if there is sin/cos binop with same inputs.
    const intptr_t other_kind = (kind == MethodRecognizer::kMathSin) ?
        MethodRecognizer::kMathCos : MethodRecognizer::kMathSin;
    Definition* def = curr_instr->value()->definition();
    for (intptr_t k = i + 1; k < merge_candidates->length(); k++) {
      MathUnaryInstr* other_op = (*merge_candidates)[k];
      // 'other_op' can be NULL if it was already merged.
      if ((other_op != NULL) && (other_op->kind() == other_kind) &&
          (other_op->value()->definition() == def)) {
        (*merge_candidates)[k] = NULL;  // Clear it.
        ASSERT(curr_instr->HasUses());
        AppendExtractNthOutputForMerged(curr_instr,
                                        MergedMathInstr::OutputIndexOf(kind),
                                        kUnboxedDouble, kDoubleCid);
        ASSERT(other_op->HasUses());
        AppendExtractNthOutputForMerged(
            other_op,
            MergedMathInstr::OutputIndexOf(other_kind),
            kUnboxedDouble, kDoubleCid);
        ZoneGrowableArray<Value*>* args = new(I) ZoneGrowableArray<Value*>(1);
        args->Add(new(I) Value(curr_instr->value()->definition()));
        // Replace with SinCos.
        MergedMathInstr* sin_cos =
            new(I) MergedMathInstr(args,
                                   curr_instr->DeoptimizationTarget(),
                                   MergedMathInstr::kSinCos);
        curr_instr->ReplaceWith(sin_cos, current_iterator());
        other_op->ReplaceUsesWith(sin_cos);
        other_op->RemoveFromGraph();
        // Only one merge possible. Because canonicalization happens later,
        // more candidates are possible.
        // TODO(srdjan): Allow merging of sin/cos into sincos.
        break;
      }
    }
  }
}


// Optimize (a << b) & c pattern: if c is a positive Smi or zero, then the
// shift can be a truncating Smi shift-left and result is always Smi.
// Merging occurs only per basic-block.
void FlowGraphOptimizer::TryOptimizePatterns() {
  if (!FLAG_truncating_left_shift) return;
  ASSERT(current_iterator_ == NULL);
  GrowableArray<BinarySmiOpInstr*> div_mod_merge;
  GrowableArray<MathUnaryInstr*> sin_cos_merge;
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    // Merging only per basic-block.
    div_mod_merge.Clear();
    sin_cos_merge.Clear();
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    current_iterator_ = &it;
    for (; !it.Done(); it.Advance()) {
      if (it.Current()->IsBinarySmiOp()) {
        BinarySmiOpInstr* binop = it.Current()->AsBinarySmiOp();
        if (binop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(binop,
                                       binop->left()->definition(),
                                       binop->right()->definition());
        } else if ((binop->op_kind() == Token::kTRUNCDIV) ||
                   (binop->op_kind() == Token::kMOD)) {
          if (binop->HasUses()) {
            div_mod_merge.Add(binop);
          }
        }
      } else if (it.Current()->IsBinaryMintOp()) {
        BinaryMintOpInstr* mintop = it.Current()->AsBinaryMintOp();
        if (mintop->op_kind() == Token::kBIT_AND) {
          OptimizeLeftShiftBitAndSmiOp(mintop,
                                       mintop->left()->definition(),
                                       mintop->right()->definition());
        }
      } else if (it.Current()->IsMathUnary()) {
        MathUnaryInstr* math_unary = it.Current()->AsMathUnary();
        if ((math_unary->kind() == MathUnaryInstr::kSin) ||
            (math_unary->kind() == MathUnaryInstr::kCos)) {
          if (math_unary->HasUses()) {
            sin_cos_merge.Add(math_unary);
          }
        }
      }
    }
    TryMergeTruncDivMod(&div_mod_merge);
    TryMergeMathUnary(&sin_cos_merge);
    current_iterator_ = NULL;
  }
}


static void EnsureSSATempIndex(FlowGraph* graph,
                               Definition* defn,
                               Definition* replacement) {
  if ((replacement->ssa_temp_index() == -1) &&
      (defn->ssa_temp_index() != -1)) {
    replacement->set_ssa_temp_index(graph->alloc_ssa_temp_index());
  }
}


static void ReplaceCurrentInstruction(ForwardInstructionIterator* iterator,
                                      Instruction* current,
                                      Instruction* replacement,
                                      FlowGraph* graph) {
  Definition* current_defn = current->AsDefinition();
  if ((replacement != NULL) && (current_defn != NULL)) {
    Definition* replacement_defn = replacement->AsDefinition();
    ASSERT(replacement_defn != NULL);
    current_defn->ReplaceUsesWith(replacement_defn);
    EnsureSSATempIndex(graph, current_defn, replacement_defn);

    if (FLAG_trace_optimization) {
      OS::Print("Replacing v%" Pd " with v%" Pd "\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    if (current_defn == NULL) {
      OS::Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      OS::Print("Removing v%" Pd ".\n", current_defn->ssa_temp_index());
    }
  }
  iterator->RemoveCurrentFromGraph();
}


bool FlowGraphOptimizer::Canonicalize() {
  bool changed = false;
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      Instruction* replacement = current->Canonicalize(flow_graph());
      if (replacement != current) {
        // For non-definitions Canonicalize should return either NULL or
        // this.
        ASSERT((replacement == NULL) || current->IsDefinition());
        ReplaceCurrentInstruction(&it, current, replacement, flow_graph_);
        changed = true;
      }
    }
  }
  return changed;
}


void FlowGraphOptimizer::InsertConversion(Representation from,
                                          Representation to,
                                          Value* use,
                                          bool is_environment_use) {
  Instruction* insert_before;
  Instruction* deopt_target;
  PhiInstr* phi = use->instruction()->AsPhi();
  if (phi != NULL) {
    ASSERT(phi->is_alive());
    // For phis conversions have to be inserted in the predecessor.
    insert_before =
        phi->block()->PredecessorAt(use->use_index())->last_instruction();
    deopt_target = NULL;
  } else {
    deopt_target = insert_before = use->instruction();
  }

  Definition* converted = NULL;
  if ((from == kTagged) && (to == kUnboxedMint)) {
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kUnboxedMint));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(I) UnboxIntegerInstr(use->CopyWithType(), deopt_id);

  } else if ((from == kUnboxedMint) && (to == kTagged)) {
    converted = new(I) BoxIntegerInstr(use->CopyWithType());

  } else if (from == kUnboxedMint && to == kUnboxedDouble) {
    ASSERT(CanUnboxDouble());
    // Convert by boxing/unboxing.
    // TODO(fschneider): Implement direct unboxed mint-to-double conversion.
    BoxIntegerInstr* boxed =
        new(I) BoxIntegerInstr(use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, FlowGraph::kValue);

    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(I) UnboxDoubleInstr(new(I) Value(boxed), deopt_id);

  } else if ((from == kUnboxedDouble) && (to == kTagged)) {
    ASSERT(CanUnboxDouble());
    converted = new(I) BoxDoubleInstr(use->CopyWithType());

  } else if ((from == kTagged) && (to == kUnboxedDouble)) {
    ASSERT(CanUnboxDouble());
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kDoubleCid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ConstantInstr* constant = use->definition()->AsConstant();
    if ((constant != NULL) && constant->value().IsSmi()) {
      const double dbl_val = Smi::Cast(constant->value()).AsDoubleValue();
      const Double& dbl_obj =
          Double::ZoneHandle(I, Double::NewCanonical(dbl_val));
      ConstantInstr* double_const = flow_graph()->GetConstant(dbl_obj);
      converted = new(I) UnboxDoubleInstr(new(I) Value(double_const), deopt_id);
    } else {
      converted = new(I) UnboxDoubleInstr(use->CopyWithType(), deopt_id);
    }
  } else if ((from == kTagged) && (to == kUnboxedFloat32x4)) {
    ASSERT((deopt_target != NULL) ||
           (use->Type()->ToCid() == kFloat32x4Cid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(I) UnboxFloat32x4Instr(
        use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedFloat32x4) && (to == kTagged)) {
    converted = new(I) BoxFloat32x4Instr(use->CopyWithType());
  } else if ((from == kTagged) && (to == kUnboxedInt32x4)) {
    ASSERT((deopt_target != NULL) || (use->Type()->ToCid() == kInt32x4Cid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(I) UnboxInt32x4Instr(use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedInt32x4) && (to == kTagged)) {
    converted = new(I) BoxInt32x4Instr(use->CopyWithType());
  } else if ((from == kTagged) && (to == kUnboxedFloat64x2)) {
    ASSERT((deopt_target != NULL) || (use->Type()->ToCid() == kFloat64x2Cid));
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(I) UnboxFloat64x2Instr(use->CopyWithType(), deopt_id);
  } else if ((from == kUnboxedFloat64x2) && (to == kTagged)) {
    converted = new(I) BoxFloat64x2Instr(use->CopyWithType());
  } else {
    // We have failed to find a suitable conversion instruction.
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT(from != kTagged);
    ASSERT(to != kTagged);
    Definition* boxed = NULL;
    if (from == kUnboxedDouble) {
      boxed = new(I) BoxDoubleInstr(use->CopyWithType());
    } else if (from == kUnboxedInt32x4) {
      boxed = new(I) BoxInt32x4Instr(use->CopyWithType());
    } else if (from == kUnboxedFloat32x4) {
      boxed = new(I) BoxFloat32x4Instr(use->CopyWithType());
    } else if (from == kUnboxedMint) {
      boxed = new(I) BoxIntegerInstr(use->CopyWithType());
    } else if (from == kUnboxedFloat64x2) {
      boxed = new(I) BoxFloat64x2Instr(use->CopyWithType());
    } else {
      UNIMPLEMENTED();
    }
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, FlowGraph::kValue);
    Value* to_value = new(I) Value(boxed);
    if (to == kUnboxedDouble) {
      converted = new(I) UnboxDoubleInstr(to_value, deopt_id);
    } else if (to == kUnboxedInt32x4) {
      converted = new(I) UnboxInt32x4Instr(to_value, deopt_id);
    } else if (to == kUnboxedFloat32x4) {
      converted = new(I) UnboxFloat32x4Instr(to_value, deopt_id);
    } else if (to == kUnboxedMint) {
      converted = new(I) UnboxIntegerInstr(to_value, deopt_id);
    } else if (to == kUnboxedFloat64x2) {
      converted = new(I) UnboxFloat64x2Instr(to_value, deopt_id);
    } else {
      UNIMPLEMENTED();
    }
  }
  ASSERT(converted != NULL);
  InsertBefore(insert_before, converted, use->instruction()->env(),
               FlowGraph::kValue);
  if (is_environment_use) {
    use->BindToEnvironment(converted);
  } else {
    use->BindTo(converted);
  }
}


void FlowGraphOptimizer::ConvertUse(Value* use, Representation from_rep) {
  const Representation to_rep =
      use->instruction()->RequiredInputRepresentation(use->use_index());
  if (from_rep == to_rep || to_rep == kNoRepresentation) {
    return;
  }
  InsertConversion(from_rep, to_rep, use, /*is_environment_use=*/ false);
}


void FlowGraphOptimizer::ConvertEnvironmentUse(Value* use,
                                               Representation from_rep) {
  const Representation to_rep = kTagged;
  if (from_rep == to_rep || to_rep == kNoRepresentation) {
    return;
  }
  InsertConversion(from_rep, to_rep, use, /*is_environment_use=*/ true);
}


void FlowGraphOptimizer::InsertConversionsFor(Definition* def) {
  const Representation from_rep = def->representation();

  for (Value::Iterator it(def->input_use_list());
       !it.Done();
       it.Advance()) {
    ConvertUse(it.Current(), from_rep);
  }

  for (Value::Iterator it(def->env_use_list());
       !it.Done();
       it.Advance()) {
    Value* use = it.Current();
    if (use->instruction()->MayThrow() &&
        use->instruction()->GetBlock()->InsideTryBlock()) {
      // Environment uses at calls inside try-blocks must be converted to
      // tagged representation.
      ConvertEnvironmentUse(it.Current(), from_rep);
    }
  }
}


// Returns true if phi's representation was changed.
static bool UnboxPhi(PhiInstr* phi) {
  Representation current = phi->representation();
  Representation unboxed = current;

  switch (phi->Type()->ToCid()) {
    case kDoubleCid:
      if (CanUnboxDouble()) {
        unboxed = kUnboxedDouble;
      }
      break;
    case kFloat32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat32x4;
      }
      break;
    case kInt32x4Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedInt32x4;
      }
      break;
  }

  if (unboxed != current) {
    phi->set_representation(unboxed);
    return true;
  }

  return false;
}


void FlowGraphOptimizer::SelectRepresentations() {
  // Conservatively unbox all phis that were proven to be of Double,
  // Float32x4, or Int32x4 type.
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    JoinEntryInstr* join_entry = block_order_[i]->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        UnboxPhi(phi);
      }
    }
  }

  // Process all instructions and insert conversions where needed.
  GraphEntryInstr* graph_entry = block_order_[0]->AsGraphEntry();

  // Visit incoming parameters and constants.
  for (intptr_t i = 0; i < graph_entry->initial_definitions()->length(); i++) {
    InsertConversionsFor((*graph_entry->initial_definitions())[i]);
  }

  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    JoinEntryInstr* join_entry = entry->AsJoinEntry();
    if (join_entry != NULL) {
      for (PhiIterator it(join_entry); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        ASSERT(phi != NULL);
        ASSERT(phi->is_alive());
        InsertConversionsFor(phi);
      }
    }
    CatchBlockEntryInstr* catch_entry = entry->AsCatchBlockEntry();
    if (catch_entry != NULL) {
      for (intptr_t i = 0;
           i < catch_entry->initial_definitions()->length();
           i++) {
        InsertConversionsFor((*catch_entry->initial_definitions())[i]);
      }
    }
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Definition* def = it.Current()->AsDefinition();
      if (def != NULL) {
        InsertConversionsFor(def);
      }
    }
  }
}


static bool ICDataHasReceiverArgumentClassIds(const ICData& ic_data,
                                              intptr_t receiver_class_id,
                                              intptr_t argument_class_id) {
  ASSERT(receiver_class_id != kIllegalCid);
  ASSERT(argument_class_id != kIllegalCid);
  if (ic_data.NumArgsTested() != 2) return false;

  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
    ASSERT(class_ids.length() == 2);
    if ((class_ids[0] == receiver_class_id) &&
        (class_ids[1] == argument_class_id)) {
      return true;
    }
  }
  return false;
}


static bool ClassIdIsOneOf(intptr_t class_id,
                           const GrowableArray<intptr_t>& class_ids) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    if (class_ids[i] == class_id) {
      return true;
    }
  }
  return false;
}


// Returns true if ICData tests two arguments and all ICData cids are in the
// required sets 'receiver_class_ids' or 'argument_class_ids', respectively.
static bool ICDataHasOnlyReceiverArgumentClassIds(
    const ICData& ic_data,
    const GrowableArray<intptr_t>& receiver_class_ids,
    const GrowableArray<intptr_t>& argument_class_ids) {
  if (ic_data.NumArgsTested() != 2) return false;
  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    GrowableArray<intptr_t> class_ids;
    ic_data.GetCheckAt(i, &class_ids, &target);
    ASSERT(class_ids.length() == 2);
    if (!ClassIdIsOneOf(class_ids[0], receiver_class_ids) ||
        !ClassIdIsOneOf(class_ids[1], argument_class_ids)) {
      return false;
    }
  }
  return true;
}


static bool HasOnlyOneSmi(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1)
      && ic_data.HasReceiverClassId(kSmiCid);
}


static bool HasOnlySmiOrMint(const ICData& ic_data) {
  if (ic_data.NumberOfChecks() == 1) {
    return ic_data.HasReceiverClassId(kSmiCid)
        || ic_data.HasReceiverClassId(kMintCid);
  }
  return (ic_data.NumberOfChecks() == 2)
      && ic_data.HasReceiverClassId(kSmiCid)
      && ic_data.HasReceiverClassId(kMintCid);
}


static bool HasOnlyTwoOf(const ICData& ic_data, intptr_t cid) {
  return (ic_data.NumberOfChecks() == 1) &&
      ICDataHasReceiverArgumentClassIds(ic_data, cid, cid);
}

// Returns false if the ICData contains anything other than the 4 combinations
// of Mint and Smi for the receiver and argument classes.
static bool HasTwoMintOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kMintCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}


// Returns false if the ICData contains anything other than the 4 combinations
// of Double and Smi for the receiver and argument classes.
static bool HasTwoDoubleOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kDoubleCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}


static bool HasOnlyOneDouble(const ICData& ic_data) {
  return (ic_data.NumberOfChecks() == 1)
      && ic_data.HasReceiverClassId(kDoubleCid);
}


static bool ShouldSpecializeForDouble(const ICData& ic_data) {
  // Don't specialize for double if we can't unbox them.
  if (!CanUnboxDouble()) {
    return false;
  }

  // Unboxed double operation can't handle case of two smis.
  if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
    return false;
  }

  // Check that it have seen only smis and doubles.
  GrowableArray<intptr_t> class_ids(2);
  class_ids.Add(kSmiCid);
  class_ids.Add(kDoubleCid);
  return ICDataHasOnlyReceiverArgumentClassIds(ic_data, class_ids, class_ids);
}


void FlowGraphOptimizer::ReplaceCall(Definition* call,
                                     Definition* replacement) {
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  call->ReplaceWith(replacement, current_iterator());
}


void FlowGraphOptimizer::AddCheckSmi(Definition* to_check,
                                     intptr_t deopt_id,
                                     Environment* deopt_environment,
                                     Instruction* insert_before) {
  if (to_check->Type()->ToCid() != kSmiCid) {
    InsertBefore(insert_before,
                 new(I) CheckSmiInstr(new(I) Value(to_check),
                                      deopt_id,
                                      insert_before->token_pos()),
                 deopt_environment,
                 FlowGraph::kEffect);
  }
}


Instruction* FlowGraphOptimizer::GetCheckClass(Definition* to_check,
                                               const ICData& unary_checks,
                                               intptr_t deopt_id,
                                               intptr_t token_pos) {
  if ((unary_checks.NumberOfChecks() == 1) &&
      (unary_checks.GetReceiverClassIdAt(0) == kSmiCid)) {
    return new(I) CheckSmiInstr(new(I) Value(to_check),
                                deopt_id,
                                token_pos);
  }
  return new(I) CheckClassInstr(
      new(I) Value(to_check), deopt_id, unary_checks, token_pos);
}


void FlowGraphOptimizer::AddCheckClass(Definition* to_check,
                                       const ICData& unary_checks,
                                       intptr_t deopt_id,
                                       Environment* deopt_environment,
                                       Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = GetCheckClass(
      to_check, unary_checks, deopt_id, insert_before->token_pos());
  InsertBefore(insert_before, check, deopt_environment, FlowGraph::kEffect);
}


void FlowGraphOptimizer::AddReceiverCheck(InstanceCallInstr* call) {
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecks()),
                call->deopt_id(),
                call->env(),
                call);
}


static bool ArgIsAlways(intptr_t cid,
                        const ICData& ic_data,
                        intptr_t arg_number) {
  ASSERT(ic_data.NumArgsTested() > arg_number);
  const intptr_t num_checks = ic_data.NumberOfChecks();
  if (num_checks == 0) return false;
  for (intptr_t i = 0; i < num_checks; i++) {
    if (ic_data.GetClassIdAt(i, arg_number) != cid) return false;
  }
  return true;
}


static bool CanUnboxInt32() {
  // Int32/Uint32 can be unboxed if it fits into a smi or the platform
  // supports unboxed mints.
  return (kSmiBits >= 32) || FlowGraphCompiler::SupportsUnboxedMints();
}


static intptr_t MethodKindToCid(MethodRecognizer::Kind kind) {
  switch (kind) {
    case MethodRecognizer::kImmutableArrayGetIndexed:
      return kImmutableArrayCid;

    case MethodRecognizer::kObjectArrayGetIndexed:
    case MethodRecognizer::kObjectArraySetIndexed:
      return kArrayCid;

    case MethodRecognizer::kGrowableArrayGetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
      return kGrowableObjectArrayCid;

    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat32ArraySetIndexed:
      return kTypedDataFloat32ArrayCid;

    case MethodRecognizer::kFloat64ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed:
      return kTypedDataFloat64ArrayCid;

    case MethodRecognizer::kInt8ArrayGetIndexed:
    case MethodRecognizer::kInt8ArraySetIndexed:
      return kTypedDataInt8ArrayCid;

    case MethodRecognizer::kUint8ArrayGetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
      return kTypedDataUint8ArrayCid;

    case MethodRecognizer::kUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
      return kTypedDataUint8ClampedArrayCid;

    case MethodRecognizer::kExternalUint8ArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
      return kExternalTypedDataUint8ArrayCid;

    case MethodRecognizer::kExternalUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
      return kExternalTypedDataUint8ClampedArrayCid;

    case MethodRecognizer::kInt16ArrayGetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
      return kTypedDataInt16ArrayCid;

    case MethodRecognizer::kUint16ArrayGetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed:
      return kTypedDataUint16ArrayCid;

    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kInt32ArraySetIndexed:
      return kTypedDataInt32ArrayCid;

    case MethodRecognizer::kUint32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed:
      return kTypedDataUint32ArrayCid;

    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat32x4ArraySetIndexed:
      return kTypedDataFloat32x4ArrayCid;

    case MethodRecognizer::kInt32x4ArrayGetIndexed:
    case MethodRecognizer::kInt32x4ArraySetIndexed:
      return kTypedDataInt32x4ArrayCid;

    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArraySetIndexed:
      return kTypedDataFloat64x2ArrayCid;

    default:
      break;
  }
  return kIllegalCid;
}


bool FlowGraphOptimizer::TryReplaceWithStoreIndexed(InstanceCallInstr* call) {
  // Check for monomorphic IC data.
  if (!call->HasICData()) return false;
  const ICData& ic_data =
      ICData::Handle(I, call->ic_data()->AsUnaryClassChecks());
  if (ic_data.NumberOfChecks() != 1) return false;
  ASSERT(ic_data.HasOneTarget());

  const Function& target = Function::Handle(I, ic_data.GetTargetAt(0));
  TargetEntryInstr* entry;
  Definition* last;
  if (!TryInlineRecognizedMethod(ic_data.GetReceiverClassIdAt(0),
                                 target,
                                 call,
                                 call->ArgumentAt(0),
                                 call->token_pos(),
                                 *call->ic_data(),
                                 &entry, &last)) {
    return false;
  }
  // Insert receiver class check.
  AddReceiverCheck(call);
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  // Replace all uses of this definition with the result.
  call->ReplaceUsesWith(last);
  // Finally insert the sequence other definition in place of this one in the
  // graph.
  call->previous()->LinkTo(entry->next());
  entry->UnuseAllInputs();  // Entry block is not in the graph.
  last->LinkTo(call);
  // Remove through the iterator.
  ASSERT(current_iterator()->Current() == call);
  current_iterator()->RemoveCurrentFromGraph();
  call->set_previous(NULL);
  call->set_next(NULL);
  return true;
}


bool FlowGraphOptimizer::InlineSetIndexed(
    MethodRecognizer::Kind kind,
    const Function& target,
    Instruction* call,
    Definition* receiver,
    intptr_t token_pos,
    const ICData* ic_data,
    const ICData& value_check,
    TargetEntryInstr** entry,
    Definition** last) {
  intptr_t array_cid = MethodKindToCid(kind);
  ASSERT(array_cid != kIllegalCid);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);

  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);
  Instruction* cursor = *entry;
  if (FLAG_enable_type_checks) {
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const AbstractType& value_type =
        AbstractType::ZoneHandle(I, target.ParameterTypeAt(2));
    Definition* instantiator = NULL;
    Definition* type_args = NULL;
    switch (array_cid) {
      case kArrayCid:
      case kGrowableObjectArrayCid: {
        const Class& instantiator_class =  Class::Handle(I, target.Owner());
        intptr_t type_arguments_field_offset =
            instantiator_class.type_arguments_field_offset();
        LoadFieldInstr* load_type_args =
            new(I) LoadFieldInstr(new(I) Value(array),
                                  type_arguments_field_offset,
                                  Type::ZoneHandle(I),  // No type.
                                  call->token_pos());
        cursor = flow_graph()->AppendTo(cursor,
                                        load_type_args,
                                        NULL,
                                        FlowGraph::kValue);

        instantiator = array;
        type_args = load_type_args;
        break;
      }
      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
        ASSERT(value_type.IsIntType());
        // Fall through.
      case kTypedDataFloat32ArrayCid:
      case kTypedDataFloat64ArrayCid: {
        type_args = instantiator = flow_graph_->constant_null();
        ASSERT((array_cid != kTypedDataFloat32ArrayCid &&
                array_cid != kTypedDataFloat64ArrayCid) ||
               value_type.IsDoubleType());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat32x4ArrayCid: {
        type_args = instantiator = flow_graph_->constant_null();
        ASSERT((array_cid != kTypedDataFloat32x4ArrayCid) ||
               value_type.IsFloat32x4Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat64x2ArrayCid: {
        type_args = instantiator = flow_graph_->constant_null();
        ASSERT((array_cid != kTypedDataFloat64x2ArrayCid) ||
               value_type.IsFloat64x2Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      default:
        // TODO(fschneider): Add support for other array types.
        UNREACHABLE();
    }
    AssertAssignableInstr* assert_value =
        new(I) AssertAssignableInstr(token_pos,
                                     new(I) Value(stored_value),
                                     new(I) Value(instantiator),
                                     new(I) Value(type_args),
                                     value_type,
                                     Symbols::Value());
    // Newly inserted instructions that can deoptimize or throw an exception
    // must have a deoptimization id that is valid for lookup in the unoptimized
    // code.
    assert_value->deopt_id_ = call->deopt_id();
    cursor = flow_graph()->AppendTo(cursor,
                                    assert_value,
                                    call->env(),
                                    FlowGraph::kValue);
  }

  array_cid = PrepareInlineIndexedOp(call,
                                     array_cid,
                                     &array,
                                     index,
                                     &cursor);

  // Check if store barrier is needed. Byte arrays don't need a store barrier.
  StoreBarrierType needs_store_barrier =
      (RawObject::IsTypedDataClassId(array_cid) ||
       RawObject::IsTypedDataViewClassId(array_cid) ||
       RawObject::IsExternalTypedDataClassId(array_cid)) ? kNoStoreBarrier
                                                         : kEmitStoreBarrier;
  if (!value_check.IsNull()) {
    // No store barrier needed because checked value is a smi, an unboxed mint,
    // an unboxed double, an unboxed Float32x4, or unboxed Int32x4.
    needs_store_barrier = kNoStoreBarrier;
    Instruction* check = GetCheckClass(
        stored_value, value_check, call->deopt_id(), call->token_pos());
    cursor = flow_graph()->AppendTo(cursor,
                                    check,
                                    call->env(),
                                    FlowGraph::kEffect);
  }

  if (array_cid == kTypedDataFloat32ArrayCid) {
    stored_value =
        new(I) DoubleToFloatInstr(
            new(I) Value(stored_value), call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    NULL,
                                    FlowGraph::kValue);
  }

  const intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new(I) StoreIndexedInstr(new(I) Value(array),
                                   new(I) Value(index),
                                   new(I) Value(stored_value),
                                   needs_store_barrier,
                                   index_scale,
                                   array_cid,
                                   call->deopt_id(),
                                   call->token_pos());
  flow_graph()->AppendTo(cursor,
                         *last,
                         call->env(),
                         FlowGraph::kEffect);
  return true;
}


bool FlowGraphOptimizer::TryInlineRecognizedMethod(intptr_t receiver_cid,
                                                   const Function& target,
                                                   Instruction* call,
                                                   Definition* receiver,
                                                   intptr_t token_pos,
                                                   const ICData& ic_data,
                                                   TargetEntryInstr** entry,
                                                   Definition** last) {
  ICData& value_check = ICData::ZoneHandle(I);
  MethodRecognizer::Kind kind = MethodRecognizer::RecognizeKind(target);
  switch (kind) {
    // Recognized [] operators.
    case MethodRecognizer::kImmutableArrayGetIndexed:
    case MethodRecognizer::kObjectArrayGetIndexed:
    case MethodRecognizer::kGrowableArrayGetIndexed:
    case MethodRecognizer::kInt8ArrayGetIndexed:
    case MethodRecognizer::kUint8ArrayGetIndexed:
    case MethodRecognizer::kUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ArrayGetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArrayGetIndexed:
    case MethodRecognizer::kInt16ArrayGetIndexed:
    case MethodRecognizer::kUint16ArrayGetIndexed:
      return InlineGetIndexed(kind, call, receiver, ic_data, entry, last);
    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArrayGetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineGetIndexed(kind, call, receiver, ic_data, entry, last);
    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineGetIndexed(kind, call, receiver, ic_data, entry, last);
    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArrayGetIndexed:
      if (!CanUnboxInt32()) return false;
      return InlineGetIndexed(kind, call, receiver, ic_data, entry, last);

    // Recognized []= operators.
    case MethodRecognizer::kObjectArraySetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
      if (ArgIsAlways(kSmiCid, ic_data, 2)) {
        value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      }
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kInt8ArraySetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed:
      if (!ArgIsAlways(kSmiCid, ic_data, 2)) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kInt32ArraySetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed:
      if (!CanUnboxInt32()) {
        return false;
      }
      // Check that value is always smi or mint, if the platform has unboxed
      // mints (ia32 with at least SSE 4.1).
      value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      if (FlowGraphCompiler::SupportsUnboxedMints()) {
        if (!HasOnlySmiOrMint(value_check)) {
          return false;
        }
      } else if (!HasOnlyOneSmi(value_check)) {
        return false;
      }
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kFloat32ArraySetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      // Check that value is always double.
      if (!ArgIsAlways(kDoubleCid, ic_data, 2)) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kFloat32x4ArraySetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      // Check that value is always a Float32x4.
      if (!ArgIsAlways(kFloat32x4Cid, ic_data, 2)) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kFloat64x2ArraySetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      // Check that value is always a Float32x4.
      if (!ArgIsAlways(kFloat64x2Cid, ic_data, 2)) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForArgNr(2);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              &ic_data, value_check, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt8:
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataInt8ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint8:
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataUint8ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt16:
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataInt16ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint16:
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataUint16ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataInt32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataUint32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat64ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat32x4ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayViewLoad(call, receiver, receiver_cid,
                                     kTypedDataInt32x4ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt8:
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt8ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint8:
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint8ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt16:
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt16ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint16:
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint16ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat64ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat32x4ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayViewStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt32x4ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kStringBaseCodeUnitAt:
      return InlineStringCodeUnitAt(call, receiver_cid, entry, last);
    case MethodRecognizer::kStringBaseCharAt:
      return InlineStringBaseCharAt(call, receiver_cid, entry, last);
    default:
      return false;
  }
}


intptr_t FlowGraphOptimizer::PrepareInlineIndexedOp(Instruction* call,
                                                    intptr_t array_cid,
                                                    Definition** array,
                                                    Definition* index,
                                                    Instruction** cursor) {
  // Insert index smi check.
  *cursor = flow_graph()->AppendTo(
      *cursor,
      new(I) CheckSmiInstr(new(I) Value(index),
                           call->deopt_id(),
                           call->token_pos()),
      call->env(),
      FlowGraph::kEffect);

  // Insert array length load and bounds check.
  LoadFieldInstr* length =
      new(I) LoadFieldInstr(
          new(I) Value(*array),
          CheckArrayBoundInstr::LengthOffsetFor(array_cid),
          Type::ZoneHandle(I, Type::SmiType()),
          call->token_pos());
  length->set_is_immutable(
      CheckArrayBoundInstr::IsFixedLengthArrayType(array_cid));
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(
      LoadFieldInstr::RecognizedKindFromArrayCid(array_cid));
  *cursor = flow_graph()->AppendTo(*cursor,
                                   length,
                                   NULL,
                                   FlowGraph::kValue);

  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(I) CheckArrayBoundInstr(
                                       new(I) Value(length),
                                       new(I) Value(index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  if (array_cid == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements =
        new(I) LoadFieldInstr(
            new(I) Value(*array),
            GrowableObjectArray::data_offset(),
            Type::ZoneHandle(I, Type::DynamicType()),
            call->token_pos());
    elements->set_result_cid(kArrayCid);
    *cursor = flow_graph()->AppendTo(*cursor,
                                     elements,
                                     NULL,
                                     FlowGraph::kValue);
    // Load from the data from backing store which is a fixed-length array.
    *array = elements;
    array_cid = kArrayCid;
  } else if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements =
        new(I) LoadUntaggedInstr(new(I) Value(*array),
                                 ExternalTypedData::data_offset());
    *cursor = flow_graph()->AppendTo(*cursor,
                                     elements,
                                     NULL,
                                     FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}

bool FlowGraphOptimizer::InlineGetIndexed(MethodRecognizer::Kind kind,
                                          Instruction* call,
                                          Definition* receiver,
                                          const ICData& ic_data,
                                          TargetEntryInstr** entry,
                                          Definition** last) {
  intptr_t array_cid = MethodKindToCid(kind);
  ASSERT(array_cid != kIllegalCid);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineIndexedOp(call,
                                     array_cid,
                                     &array,
                                     index,
                                     &cursor);

  intptr_t deopt_id = Isolate::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Set deopt_id if we can optimistically assume that the result is Smi.
    // Assume mixed Mint/Smi if this instruction caused deoptimization once.
    deopt_id = ic_data.HasDeoptReasons() ?
        Isolate::kNoDeoptId : call->deopt_id();
  }

  // Array load and return.
  intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new(I) LoadIndexedInstr(new(I) Value(array),
                                  new(I) Value(index),
                                  index_scale,
                                  array_cid,
                                  deopt_id,
                                  call->token_pos());
  cursor = flow_graph()->AppendTo(
      cursor,
      *last,
      deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (array_cid == kTypedDataFloat32ArrayCid) {
    *last = new(I) FloatToDoubleInstr(new(I) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
                           FlowGraph::kValue);
  }
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithLoadIndexed(InstanceCallInstr* call) {
  // Check for monomorphic IC data.
  if (!call->HasICData()) return false;
  const ICData& ic_data =
      ICData::Handle(I, call->ic_data()->AsUnaryClassChecks());
  if (ic_data.NumberOfChecks() != 1) return false;
  ASSERT(ic_data.HasOneTarget());

  const Function& target = Function::Handle(I, ic_data.GetTargetAt(0));
  TargetEntryInstr* entry;
  Definition* last;
  if (!TryInlineRecognizedMethod(ic_data.GetReceiverClassIdAt(0),
                                 target,
                                 call,
                                 call->ArgumentAt(0),
                                 call->token_pos(),
                                 *call->ic_data(),
                                 &entry, &last)) {
    return false;
  }

  // Insert receiver class check.
  AddReceiverCheck(call);
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  // Replace all uses of this definition with the result.
  call->ReplaceUsesWith(last);
  // Finally insert the sequence other definition in place of this one in the
  // graph.
  call->previous()->LinkTo(entry->next());
  entry->UnuseAllInputs();  // Entry block is not in the graph.
  last->LinkTo(call);
  // Remove through the iterator.
  ASSERT(current_iterator()->Current() == call);
  current_iterator()->RemoveCurrentFromGraph();
  call->set_previous(NULL);
  call->set_next(NULL);
  return true;
}


// Return true if d is a string of length one (a constant or result from
// from string-from-char-code instruction.
static bool IsLengthOneString(Definition* d) {
  if (d->IsConstant()) {
    const Object& obj = d->AsConstant()->value();
    if (obj.IsString()) {
      return String::Cast(obj).Length() == 1;
    } else {
      return false;
    }
  } else {
    return d->IsStringFromCharCode();
  }
}


// Returns true if the string comparison was converted into char-code
// comparison. Conversion is only possible for strings of length one.
// E.g., detect str[x] == "x"; and use an integer comparison of char-codes.
// TODO(srdjan): Expand for two-byte and external strings.
bool FlowGraphOptimizer::TryStringLengthOneEquality(InstanceCallInstr* call,
                                                    Token::Kind op_kind) {
  ASSERT(HasOnlyTwoOf(*call->ic_data(), kOneByteStringCid));
  // Check that left and right are length one strings (either string constants
  // or results of string-from-char-code.
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  Value* left_val = NULL;
  Definition* to_remove_left = NULL;
  if (IsLengthOneString(right)) {
    // Swap, since we know that both arguments are strings
    Definition* temp = left;
    left = right;
    right = temp;
  }
  if (IsLengthOneString(left)) {
    // Optimize if left is a string with length one (either constant or
    // result of string-from-char-code.
    if (left->IsConstant()) {
      ConstantInstr* left_const = left->AsConstant();
      const String& str = String::Cast(left_const->value());
      ASSERT(str.Length() == 1);
      ConstantInstr* char_code_left = flow_graph()->GetConstant(
          Smi::ZoneHandle(I, Smi::New(str.CharAt(0))));
      left_val = new(I) Value(char_code_left);
    } else if (left->IsStringFromCharCode()) {
      // Use input of string-from-charcode as left value.
      StringFromCharCodeInstr* instr = left->AsStringFromCharCode();
      left_val = new(I) Value(instr->char_code()->definition());
      to_remove_left = instr;
    } else {
      // IsLengthOneString(left) should have been false.
      UNREACHABLE();
    }

    Definition* to_remove_right = NULL;
    Value* right_val = NULL;
    if (right->IsStringFromCharCode()) {
      // Skip string-from-char-code, and use its input as right value.
      StringFromCharCodeInstr* right_instr = right->AsStringFromCharCode();
      right_val = new(I) Value(right_instr->char_code()->definition());
      to_remove_right = right_instr;
    } else {
      const ICData& unary_checks_1 =
          ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecksForArgNr(1));
      AddCheckClass(right,
                    unary_checks_1,
                    call->deopt_id(),
                    call->env(),
                    call);
      // String-to-char-code instructions returns -1 (illegal charcode) if
      // string is not of length one.
      StringToCharCodeInstr* char_code_right =
          new(I) StringToCharCodeInstr(new(I) Value(right), kOneByteStringCid);
      InsertBefore(call, char_code_right, call->env(), FlowGraph::kValue);
      right_val = new(I) Value(char_code_right);
    }

    // Comparing char-codes instead of strings.
    EqualityCompareInstr* comp =
        new(I) EqualityCompareInstr(call->token_pos(),
                                    op_kind,
                                    left_val,
                                    right_val,
                                    kSmiCid,
                                    call->deopt_id());
    ReplaceCall(call, comp);

    // Remove dead instructions.
    if ((to_remove_left != NULL) &&
        (to_remove_left->input_use_list() == NULL)) {
      to_remove_left->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_left->RemoveFromGraph();
    }
    if ((to_remove_right != NULL) &&
        (to_remove_right->input_use_list() == NULL)) {
      to_remove_right->ReplaceUsesWith(flow_graph()->constant_null());
      to_remove_right->RemoveFromGraph();
    }
    return true;
  }
  return false;
}


static bool SmiFitsInDouble() { return kSmiBits < 53; }

bool FlowGraphOptimizer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
                                                  Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
  if (HasOnlyTwoOf(ic_data, kOneByteStringCid)) {
    if (TryStringLengthOneEquality(call, op_kind)) {
      return true;
    } else {
      return false;
    }
  } else if (HasOnlyTwoOf(ic_data, kSmiCid)) {
    InsertBefore(call,
                 new(I) CheckSmiInstr(new(I) Value(left),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    InsertBefore(call,
                 new(I) CheckSmiInstr(new(I) Value(right),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    cid = kSmiCid;
  } else if (HasTwoMintOrSmi(ic_data) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    cid = kMintCid;
  } else if (HasTwoDoubleOrSmi(ic_data) && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
      if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(call,
                     new(I) CheckEitherNonSmiInstr(
                         new(I) Value(left),
                         new(I) Value(right),
                         call->deopt_id()),
                     call->env(),
                     FlowGraph::kEffect);
        cid = kDoubleCid;
      }
    }
  } else {
    // Check if ICDData contains checks with Smi/Null combinations. In that case
    // we can still emit the optimized Smi equality operation but need to add
    // checks for null or Smi.
    GrowableArray<intptr_t> smi_or_null(2);
    smi_or_null.Add(kSmiCid);
    smi_or_null.Add(kNullCid);
    if (ICDataHasOnlyReceiverArgumentClassIds(ic_data,
                                              smi_or_null,
                                              smi_or_null)) {
      const ICData& unary_checks_0 =
          ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecks());
      AddCheckClass(left,
                    unary_checks_0,
                    call->deopt_id(),
                    call->env(),
                    call);

      const ICData& unary_checks_1 =
          ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecksForArgNr(1));
      AddCheckClass(right,
                    unary_checks_1,
                    call->deopt_id(),
                    call->env(),
                    call);
      cid = kSmiCid;
    } else {
      // Shortcut for equality with null.
      ConstantInstr* right_const = right->AsConstant();
      ConstantInstr* left_const = left->AsConstant();
      if ((right_const != NULL && right_const->value().IsNull()) ||
          (left_const != NULL && left_const->value().IsNull())) {
        StrictCompareInstr* comp =
            new(I) StrictCompareInstr(call->token_pos(),
                                      Token::kEQ_STRICT,
                                      new(I) Value(left),
                                      new(I) Value(right),
                                      false);  // No number check.
        ReplaceCall(call, comp);
        return true;
      }
      return false;
    }
  }
  ASSERT(cid != kIllegalCid);
  EqualityCompareInstr* comp = new(I) EqualityCompareInstr(call->token_pos(),
                                                           op_kind,
                                                           new(I) Value(left),
                                                           new(I) Value(right),
                                                           cid,
                                                           call->deopt_id());
  ReplaceCall(call, comp);
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithRelationalOp(InstanceCallInstr* call,
                                                    Token::Kind op_kind) {
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.NumArgsTested() == 2);

  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  intptr_t cid = kIllegalCid;
  if (HasOnlyTwoOf(ic_data, kSmiCid)) {
    InsertBefore(call,
                 new(I) CheckSmiInstr(new(I) Value(left),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    InsertBefore(call,
                 new(I) CheckSmiInstr(new(I) Value(right),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    cid = kSmiCid;
  } else if (HasTwoMintOrSmi(ic_data) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    cid = kMintCid;
  } else if (HasTwoDoubleOrSmi(ic_data) && CanUnboxDouble()) {
    // Use double comparison.
    if (SmiFitsInDouble()) {
      cid = kDoubleCid;
    } else {
      if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
        // We cannot use double comparison on two smis. Need polymorphic
        // call.
        return false;
      } else {
        InsertBefore(call,
                     new(I) CheckEitherNonSmiInstr(
                         new(I) Value(left),
                         new(I) Value(right),
                         call->deopt_id()),
                     call->env(),
                     FlowGraph::kEffect);
        cid = kDoubleCid;
      }
    }
  } else {
    return false;
  }
  ASSERT(cid != kIllegalCid);
  RelationalOpInstr* comp = new(I) RelationalOpInstr(call->token_pos(),
                                                     op_kind,
                                                     new(I) Value(left),
                                                     new(I) Value(right),
                                                     cid,
                                                     call->deopt_id());
  ReplaceCall(call, comp);
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
                                                Token::Kind op_kind) {
  intptr_t operands_type = kIllegalCid;
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  switch (op_kind) {
    case Token::kADD:
    case Token::kSUB:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        operands_type = ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)
            ? kMintCid
            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 FlowGraphCompiler::SupportsUnboxedMints()) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryMintOp)) return false;
        operands_type = kMintCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoOf(ic_data, kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kInt32x4Cid)) {
        operands_type = kInt32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kMUL:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        // Don't generate smi code if the IC data is marked because of an
        // overflow.
        // TODO(fschneider): Add unboxed mint multiplication.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)) return false;
        operands_type = kSmiCid;
      } else if (ShouldSpecializeForDouble(ic_data)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoOf(ic_data, kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (ShouldSpecializeForDouble(ic_data) ||
          HasOnlyTwoOf(ic_data, kSmiCid)) {
        operands_type = kDoubleCid;
      } else if (HasOnlyTwoOf(ic_data, kFloat32x4Cid)) {
        operands_type = kFloat32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kBIT_AND:
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        operands_type = kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data)) {
        operands_type = kMintCid;
      } else if (HasOnlyTwoOf(ic_data, kInt32x4Cid)) {
        operands_type = kInt32x4Cid;
      } else {
        return false;
      }
      break;
    case Token::kSHR:
    case Token::kSHL:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        // Left shift may overflow from smi into mint or big ints.
        // Don't generate smi code if the IC data is marked because
        // of an overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptShiftMintOp)) {
          return false;
        }
        operands_type = ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)
            ? kMintCid
            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 HasOnlyOneSmi(ICData::Handle(I,
                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptShiftMintOp)) {
          return false;
        }
        // Check for smi/mint << smi or smi/mint >> smi.
        operands_type = kMintCid;
      } else {
        return false;
      }
      break;
    case Token::kMOD:
    case Token::kTRUNCDIV:
      if (HasOnlyTwoOf(ic_data, kSmiCid)) {
        if (ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)) {
          return false;
        }
        operands_type = kSmiCid;
      } else {
        return false;
      }
      break;
    default:
      UNREACHABLE();
  }

  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  if (operands_type == kDoubleCid) {
    if (!CanUnboxDouble()) {
      return false;
    }
    // Check that either left or right are not a smi.  Result of a
    // binary operation with two smis is a smi not a double, except '/' which
    // returns a double for two smis.
    if (op_kind != Token::kDIV) {
      InsertBefore(call,
                   new(I) CheckEitherNonSmiInstr(
                       new(I) Value(left),
                       new(I) Value(right),
                       call->deopt_id()),
                   call->env(),
                   FlowGraph::kEffect);
    }

    BinaryDoubleOpInstr* double_bin_op =
        new(I) BinaryDoubleOpInstr(op_kind,
                                   new(I) Value(left),
                                   new(I) Value(right),
                                   call->deopt_id(), call->token_pos());
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    if (!FlowGraphCompiler::SupportsUnboxedMints()) return false;
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      ShiftMintOpInstr* shift_op =
          new(I) ShiftMintOpInstr(
              op_kind, new(I) Value(left), new(I) Value(right),
              call->deopt_id());
      ReplaceCall(call, shift_op);
    } else {
      BinaryMintOpInstr* bin_op =
          new(I) BinaryMintOpInstr(
              op_kind, new(I) Value(left), new(I) Value(right),
              call->deopt_id());
      ReplaceCall(call, bin_op);
    }
  } else if (operands_type == kFloat32x4Cid) {
    return InlineFloat32x4BinaryOp(call, op_kind);
  } else if (operands_type == kInt32x4Cid) {
    return InlineInt32x4BinaryOp(call, op_kind);
  } else if (operands_type == kFloat64x2Cid) {
    return InlineFloat64x2BinaryOp(call, op_kind);
  } else if (op_kind == Token::kMOD) {
    ASSERT(operands_type == kSmiCid);
    if (right->IsConstant()) {
      const Object& obj = right->AsConstant()->value();
      if (obj.IsSmi() && Utils::IsPowerOfTwo(Smi::Cast(obj).Value())) {
        // Insert smi check and attach a copy of the original environment
        // because the smi operation can still deoptimize.
        InsertBefore(call,
                     new(I) CheckSmiInstr(new(I) Value(left),
                                          call->deopt_id(),
                                          call->token_pos()),
                     call->env(),
                     FlowGraph::kEffect);
        ConstantInstr* constant =
            flow_graph()->GetConstant(Smi::Handle(I,
                Smi::New(Smi::Cast(obj).Value() - 1)));
        BinarySmiOpInstr* bin_op =
            new(I) BinarySmiOpInstr(Token::kBIT_AND,
                                    new(I) Value(left),
                                    new(I) Value(constant),
                                    call->deopt_id(),
                                    call->token_pos());
        ReplaceCall(call, bin_op);
        return true;
      }
    }
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    BinarySmiOpInstr* bin_op =
        new(I) BinarySmiOpInstr(op_kind,
                                        new(I) Value(left),
                                        new(I) Value(right),
                                        call->deopt_id(), call->token_pos());
    ReplaceCall(call, bin_op);
  } else {
    ASSERT(operands_type == kSmiCid);
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    if (left->IsConstant() &&
        ((op_kind == Token::kADD) || (op_kind == Token::kMUL))) {
      // Constant should be on the right side.
      Definition* temp = left;
      left = right;
      right = temp;
    }
    BinarySmiOpInstr* bin_op =
        new(I) BinarySmiOpInstr(
            op_kind, new(I) Value(left), new(I) Value(right),
            call->deopt_id(), call->token_pos());
    ReplaceCall(call, bin_op);
  }
  return true;
}


bool FlowGraphOptimizer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
                                               Token::Kind op_kind) {
  ASSERT(call->ArgumentCount() == 1);
  Definition* input = call->ArgumentAt(0);
  Definition* unary_op = NULL;
  if (HasOnlyOneSmi(*call->ic_data())) {
    InsertBefore(call,
                 new(I) CheckSmiInstr(new(I) Value(input),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    unary_op = new(I) UnarySmiOpInstr(
        op_kind, new(I) Value(input), call->deopt_id());
  } else if ((op_kind == Token::kBIT_NOT) &&
             HasOnlySmiOrMint(*call->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    unary_op = new(I) UnaryMintOpInstr(
        op_kind, new(I) Value(input), call->deopt_id());
  } else if (HasOnlyOneDouble(*call->ic_data()) &&
             (op_kind == Token::kNEGATE) &&
             CanUnboxDouble()) {
    AddReceiverCheck(call);
    unary_op = new(I) UnaryDoubleOpInstr(
        Token::kNEGATE, new(I) Value(input), call->deopt_id());
  } else {
    return false;
  }
  ASSERT(unary_op != NULL);
  ReplaceCall(call, unary_op);
  return true;
}


// Using field class
static RawField* GetField(intptr_t class_id, const String& field_name) {
  Isolate* isolate = Isolate::Current();
  Class& cls = Class::Handle(isolate, isolate->class_table()->At(class_id));
  Field& field = Field::Handle(isolate);
  while (!cls.IsNull()) {
    field = cls.LookupInstanceField(field_name);
    if (!field.IsNull()) {
      return field.raw();
    }
    cls = cls.SuperClass();
  }
  return Field::null();
}


// Use CHA to determine if the call needs a class check: if the callee's
// receiver is the same as the caller's receiver and there are no overriden
// callee functions, then no class check is needed.
bool FlowGraphOptimizer::InstanceCallNeedsClassCheck(
    InstanceCallInstr* call) const {
  if (!FLAG_use_cha) return true;
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->parsed_function().function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    return CHA::HasOverride(Class::Handle(I, function.Owner()),
                            call->function_name());
  }
  return true;
}


bool FlowGraphOptimizer::MethodExtractorNeedsClassCheck(
    InstanceCallInstr* call) const {
  if (!FLAG_use_cha) return true;
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->parsed_function().function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    const String& field_name =
      String::Handle(I, Field::NameFromGetter(call->function_name()));
    return CHA::HasOverride(Class::Handle(I, function.Owner()), field_name);
  }
  return true;
}


void FlowGraphOptimizer::InlineImplicitInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.HasOneTarget());
  Function& target = Function::Handle(I);
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  ASSERT(class_ids.length() == 1);
  // Inline implicit instance getter.
  const String& field_name =
      String::Handle(I, Field::NameFromGetter(call->function_name()));
  const Field& field =
      Field::ZoneHandle(I, GetField(class_ids[0], field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(call)) {
    AddReceiverCheck(call);
  }
  LoadFieldInstr* load = new(I) LoadFieldInstr(
      new(I) Value(call->ArgumentAt(0)),
      &field,
      AbstractType::ZoneHandle(I, field.type()),
      call->token_pos());
  load->set_is_immutable(field.is_final());
  if (field.guarded_cid() != kIllegalCid) {
    if (!field.is_nullable() || (field.guarded_cid() == kNullCid)) {
      load->set_result_cid(field.guarded_cid());
    }
    FlowGraph::AddToGuardedFields(flow_graph_->guarded_fields(), &field);
  }

  // Discard the environment from the original instruction because the load
  // can't deoptimize.
  call->RemoveEnvironment();
  ReplaceCall(call, load);

  if (load->result_cid() != kDynamicCid) {
    // Reset value types if guarded_cid was used.
    for (Value::Iterator it(load->input_use_list());
         !it.Done();
         it.Advance()) {
      it.Current()->SetReachingType(NULL);
    }
  }
}


LoadFieldInstr* FlowGraphOptimizer::BuildLoadStringLength(Definition* str) {
  // Treat length loads as mutable (i.e. affected by side effects) to avoid
  // hoisting them since we can't hoist the preceding class-check. This
  // is because of externalization of strings that affects their class-id.
  LoadFieldInstr* load = new(I) LoadFieldInstr(
      new(I) Value(str),
      String::length_offset(),
      Type::ZoneHandle(I, Type::SmiType()),
      str->token_pos());
  load->set_result_cid(kSmiCid);
  load->set_recognized_kind(MethodRecognizer::kStringBaseLength);
  return load;
}


bool FlowGraphOptimizer::InlineFloat32x4Getter(InstanceCallInstr* call,
                                               MethodRecognizer::Kind getter) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  intptr_t mask = 0;
  if ((getter == MethodRecognizer::kFloat32x4Shuffle) ||
      (getter == MethodRecognizer::kFloat32x4ShuffleMix)) {
    // Extract shuffle mask.
    Definition* mask_definition = NULL;
    if (getter == MethodRecognizer::kFloat32x4Shuffle) {
      ASSERT(call->ArgumentCount() == 2);
      mask_definition = call->ArgumentAt(1);
    } else {
      ASSERT(getter == MethodRecognizer::kFloat32x4ShuffleMix);
      ASSERT(call->ArgumentCount() == 3);
      mask_definition = call->ArgumentAt(2);
    }
    if (!mask_definition->IsConstant()) {
      return false;
    }
    ASSERT(mask_definition->IsConstant());
    ConstantInstr* constant_instruction = mask_definition->AsConstant();
    const Object& constant_mask = constant_instruction->value();
    if (!constant_mask.IsSmi()) {
      return false;
    }
    ASSERT(constant_mask.IsSmi());
    mask = Smi::Cast(constant_mask).Value();
    if ((mask < 0) || (mask > 255)) {
      // Not a valid mask.
      return false;
    }
  }
  if (getter == MethodRecognizer::kFloat32x4GetSignMask) {
    Simd32x4GetSignMaskInstr* instr = new(I) Simd32x4GetSignMaskInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kFloat32x4ShuffleMix) {
    Simd32x4ShuffleMixInstr* instr = new(I) Simd32x4ShuffleMixInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        new(I) Value(call->ArgumentAt(1)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else {
    ASSERT((getter == MethodRecognizer::kFloat32x4Shuffle)  ||
           (getter == MethodRecognizer::kFloat32x4ShuffleX) ||
           (getter == MethodRecognizer::kFloat32x4ShuffleY) ||
           (getter == MethodRecognizer::kFloat32x4ShuffleZ) ||
           (getter == MethodRecognizer::kFloat32x4ShuffleW));
    Simd32x4ShuffleInstr* instr = new(I) Simd32x4ShuffleInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  }
  UNREACHABLE();
  return false;
}


bool FlowGraphOptimizer::InlineFloat64x2Getter(InstanceCallInstr* call,
                                               MethodRecognizer::Kind getter) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  if ((getter == MethodRecognizer::kFloat64x2GetX) ||
      (getter == MethodRecognizer::kFloat64x2GetY)) {
    Simd64x2ShuffleInstr* instr = new(I) Simd64x2ShuffleInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        0,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  }
  UNREACHABLE();
  return false;
}


bool FlowGraphOptimizer::InlineInt32x4Getter(InstanceCallInstr* call,
                                              MethodRecognizer::Kind getter) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  intptr_t mask = 0;
  if ((getter == MethodRecognizer::kInt32x4Shuffle) ||
      (getter == MethodRecognizer::kInt32x4ShuffleMix)) {
    // Extract shuffle mask.
    Definition* mask_definition = NULL;
    if (getter == MethodRecognizer::kInt32x4Shuffle) {
      ASSERT(call->ArgumentCount() == 2);
      mask_definition = call->ArgumentAt(1);
    } else {
      ASSERT(getter == MethodRecognizer::kInt32x4ShuffleMix);
      ASSERT(call->ArgumentCount() == 3);
      mask_definition = call->ArgumentAt(2);
    }
    if (!mask_definition->IsConstant()) {
      return false;
    }
    ASSERT(mask_definition->IsConstant());
    ConstantInstr* constant_instruction = mask_definition->AsConstant();
    const Object& constant_mask = constant_instruction->value();
    if (!constant_mask.IsSmi()) {
      return false;
    }
    ASSERT(constant_mask.IsSmi());
    mask = Smi::Cast(constant_mask).Value();
    if ((mask < 0) || (mask > 255)) {
      // Not a valid mask.
      return false;
    }
  }
  if (getter == MethodRecognizer::kInt32x4GetSignMask) {
    Simd32x4GetSignMaskInstr* instr = new(I) Simd32x4GetSignMaskInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kInt32x4ShuffleMix) {
    Simd32x4ShuffleMixInstr* instr = new(I) Simd32x4ShuffleMixInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        new(I) Value(call->ArgumentAt(1)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kInt32x4Shuffle) {
    Simd32x4ShuffleInstr* instr = new(I) Simd32x4ShuffleInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else {
    Int32x4GetFlagInstr* instr = new(I) Int32x4GetFlagInstr(
        getter,
        new(I) Value(call->ArgumentAt(0)),
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  }
}


bool FlowGraphOptimizer::InlineFloat32x4BinaryOp(InstanceCallInstr* call,
                                                 Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left.
  AddCheckClass(left,
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  // Type check right.
  AddCheckClass(right,
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                call->deopt_id(),
                call->env(),
                call);
  // Replace call.
  BinaryFloat32x4OpInstr* float32x4_bin_op =
      new(I) BinaryFloat32x4OpInstr(
          op_kind, new(I) Value(left), new(I) Value(right),
          call->deopt_id());
  ReplaceCall(call, float32x4_bin_op);

  return true;
}


bool FlowGraphOptimizer::InlineInt32x4BinaryOp(InstanceCallInstr* call,
                                                Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left.
  AddCheckClass(left,
                ICData::ZoneHandle(
                    I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  // Type check right.
  AddCheckClass(right,
                ICData::ZoneHandle(I,
                    call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                call->deopt_id(),
                call->env(),
                call);
  // Replace call.
  BinaryInt32x4OpInstr* int32x4_bin_op =
      new(I) BinaryInt32x4OpInstr(
          op_kind, new(I) Value(left), new(I) Value(right),
          call->deopt_id());
  ReplaceCall(call, int32x4_bin_op);
  return true;
}


bool FlowGraphOptimizer::InlineFloat64x2BinaryOp(InstanceCallInstr* call,
                                                 Token::Kind op_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->ArgumentCount() == 2);
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);
  // Type check left.
  AddCheckClass(left,
                ICData::ZoneHandle(
                    call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  // Type check right.
  AddCheckClass(right,
                ICData::ZoneHandle(
                    call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                call->deopt_id(),
                call->env(),
                call);
  // Replace call.
  BinaryFloat64x2OpInstr* float64x2_bin_op =
      new(I) BinaryFloat64x2OpInstr(
          op_kind, new(I) Value(left), new(I) Value(right),
          call->deopt_id());
  ReplaceCall(call, float64x2_bin_op);
  return true;
}


// Only unique implicit instance getters can be currently handled.
bool FlowGraphOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }

  if (!ic_data.HasOneTarget()) {
    // Polymorphic sites are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }

  const Function& target = Function::Handle(I, ic_data.GetTargetAt(0));
  if (target.kind() != RawFunction::kImplicitGetter) {
    // Non-implicit getters are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }
  InlineImplicitInstanceGetter(call);
  return true;
}


bool FlowGraphOptimizer::TryReplaceInstanceCallWithInline(
    InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  Function& target = Function::Handle(I);
  GrowableArray<intptr_t> class_ids;
  call->ic_data()->GetCheckAt(0, &class_ids, &target);
  const intptr_t receiver_cid = class_ids[0];

  TargetEntryInstr* entry;
  Definition* last;
  if (!TryInlineRecognizedMethod(receiver_cid,
                                 target,
                                 call,
                                 call->ArgumentAt(0),
                                 call->token_pos(),
                                 *call->ic_data(),
                                 &entry, &last)) {
    return false;
  }

  // Insert receiver class check.
  AddReceiverCheck(call);
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  // Replace all uses of this definition with the result.
  call->ReplaceUsesWith(last);
  // Finally insert the sequence other definition in place of this one in the
  // graph.
  call->previous()->LinkTo(entry->next());
  entry->UnuseAllInputs();  // Entry block is not in the graph.
  last->LinkTo(call);
  // Remove through the iterator.
  ASSERT(current_iterator()->Current() == call);
  current_iterator()->RemoveCurrentFromGraph();
  call->set_previous(NULL);
  call->set_next(NULL);
  return true;
}


// Returns the LoadIndexedInstr.
Definition* FlowGraphOptimizer::PrepareInlineStringIndexOp(
    Instruction* call,
    intptr_t cid,
    Definition* str,
    Definition* index,
    Instruction* cursor) {

  cursor = flow_graph()->AppendTo(cursor,
                                  new(I) CheckSmiInstr(
                                      new(I) Value(index),
                                      call->deopt_id(),
                                      call->token_pos()),
                                  call->env(),
                                  FlowGraph::kEffect);

  // Load the length of the string.
  LoadFieldInstr* length = BuildLoadStringLength(str);
  cursor = flow_graph()->AppendTo(cursor, length, NULL, FlowGraph::kValue);
  // Bounds check.
  cursor = flow_graph()->AppendTo(cursor,
                                   new(I) CheckArrayBoundInstr(
                                       new(I) Value(length),
                                       new(I) Value(index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  LoadIndexedInstr* load_indexed = new(I) LoadIndexedInstr(
      new(I) Value(str),
      new(I) Value(index),
      Instance::ElementSizeFor(cid),
      cid,
      Isolate::kNoDeoptId,
      call->token_pos());

  cursor = flow_graph()->AppendTo(cursor,
                                  load_indexed,
                                  NULL,
                                  FlowGraph::kValue);
  ASSERT(cursor == load_indexed);
  return load_indexed;
}


bool FlowGraphOptimizer::InlineStringCodeUnitAt(
    Instruction* call,
    intptr_t cid,
    TargetEntryInstr** entry,
    Definition** last) {
  // TODO(johnmccutchan): Handle external strings in PrepareInlineStringIndexOp.
  if (RawObject::IsExternalStringClassId(cid)) {
    return false;
  }

  Definition* str = call->ArgumentAt(0);
  Definition* index = call->ArgumentAt(1);

  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);

  *last = PrepareInlineStringIndexOp(call, cid, str, index, *entry);

  return true;
}


bool FlowGraphOptimizer::InlineStringBaseCharAt(
    Instruction* call,
    intptr_t cid,
    TargetEntryInstr** entry,
    Definition** last) {
  // TODO(johnmccutchan): Handle external strings in PrepareInlineStringIndexOp.
  if (RawObject::IsExternalStringClassId(cid) || cid != kOneByteStringCid) {
    return false;
  }
  Definition* str = call->ArgumentAt(0);
  Definition* index = call->ArgumentAt(1);

  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);

  *last = PrepareInlineStringIndexOp(call, cid, str, index, *entry);

  StringFromCharCodeInstr* char_at = new(I) StringFromCharCodeInstr(
      new(I) Value(*last), cid);

  flow_graph()->AppendTo(*last, char_at, NULL, FlowGraph::kValue);
  *last = char_at;

  return true;
}


void FlowGraphOptimizer::ReplaceWithMathCFunction(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  AddReceiverCheck(call);
  ZoneGrowableArray<Value*>* args =
      new(I) ZoneGrowableArray<Value*>(call->ArgumentCount());
  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    args->Add(new(I) Value(call->ArgumentAt(i)));
  }
  InvokeMathCFunctionInstr* invoke =
      new(I) InvokeMathCFunctionInstr(args,
                                      call->deopt_id(),
                                      recognized_kind,
                                      call->token_pos());
  ReplaceCall(call, invoke);
}


static bool IsSupportedByteArrayViewCid(intptr_t cid) {
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid:
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid:
    case kTypedDataFloat32x4ArrayCid:
    case kTypedDataInt32x4ArrayCid:
      return true;
    default:
      return false;
  }
}


// Inline only simple, frequently called core library methods.
bool FlowGraphOptimizer::TryInlineInstanceMethod(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if ((ic_data.NumberOfChecks() == 0) || !ic_data.HasOneTarget()) {
    // No type feedback collected or multiple targets found.
    return false;
  }

  Function& target = Function::Handle(I);
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(target);

  if ((recognized_kind == MethodRecognizer::kGrowableArraySetData) &&
      (ic_data.NumberOfChecks() == 1) &&
      (class_ids[0] == kGrowableObjectArrayCid)) {
    // This is an internal method, no need to check argument types.
    Definition* array = call->ArgumentAt(0);
    Definition* value = call->ArgumentAt(1);
    StoreInstanceFieldInstr* store = new(I) StoreInstanceFieldInstr(
        GrowableObjectArray::data_offset(),
        new(I) Value(array),
        new(I) Value(value),
        kEmitStoreBarrier,
        call->token_pos());
    ReplaceCall(call, store);
    return true;
  }

  if ((recognized_kind == MethodRecognizer::kGrowableArraySetLength) &&
      (ic_data.NumberOfChecks() == 1) &&
      (class_ids[0] == kGrowableObjectArrayCid)) {
    // This is an internal method, no need to check argument types nor
    // range.
    Definition* array = call->ArgumentAt(0);
    Definition* value = call->ArgumentAt(1);
    StoreInstanceFieldInstr* store = new(I) StoreInstanceFieldInstr(
        GrowableObjectArray::length_offset(),
        new(I) Value(array),
        new(I) Value(value),
        kEmitStoreBarrier,
        call->token_pos());
    ReplaceCall(call, store);
    return true;
  }

  if (((recognized_kind == MethodRecognizer::kStringBaseCodeUnitAt) ||
       (recognized_kind == MethodRecognizer::kStringBaseCharAt)) &&
      (ic_data.NumberOfChecks() == 1) &&
      ((class_ids[0] == kOneByteStringCid) ||
       (class_ids[0] == kTwoByteStringCid))) {
    return TryReplaceInstanceCallWithInline(call);
  }

  if ((class_ids[0] == kOneByteStringCid) && (ic_data.NumberOfChecks() == 1)) {
    if (recognized_kind == MethodRecognizer::kOneByteStringSetAt) {
      // This is an internal method, no need to check argument types nor
      // range.
      Definition* str = call->ArgumentAt(0);
      Definition* index = call->ArgumentAt(1);
      Definition* value = call->ArgumentAt(2);
      StoreIndexedInstr* store_op = new(I) StoreIndexedInstr(
          new(I) Value(str),
          new(I) Value(index),
          new(I) Value(value),
          kNoStoreBarrier,
          1,  // Index scale
          kOneByteStringCid,
          call->deopt_id(),
          call->token_pos());
      ReplaceCall(call, store_op);
      return true;
    }
    return false;
  }

  if (CanUnboxDouble() &&
      (recognized_kind == MethodRecognizer::kIntegerToDouble) &&
      (ic_data.NumberOfChecks() == 1) &&
      (class_ids[0] == kSmiCid)) {
    AddReceiverCheck(call);
    ReplaceCall(call,
                new(I) SmiToDoubleInstr(
                    new(I) Value(call->ArgumentAt(0)),
                    call->token_pos()));
    return true;
  }

  if (class_ids[0] == kDoubleCid) {
    if (!CanUnboxDouble()) {
      return false;
    }
    switch (recognized_kind) {
      case MethodRecognizer::kDoubleToInteger: {
        AddReceiverCheck(call);
        ASSERT(call->HasICData());
        const ICData& ic_data = *call->ic_data();
        Definition* input = call->ArgumentAt(0);
        Definition* d2i_instr = NULL;
        if (ic_data.HasDeoptReason(ICData::kDeoptDoubleToSmi)) {
          // Do not repeatedly deoptimize because result didn't fit into Smi.
          d2i_instr =  new(I) DoubleToIntegerInstr(
              new(I) Value(input), call);
        } else {
          // Optimistically assume result fits into Smi.
          d2i_instr = new(I) DoubleToSmiInstr(
              new(I) Value(input), call->deopt_id());
        }
        ReplaceCall(call, d2i_instr);
        return true;
      }
      case MethodRecognizer::kDoubleMod:
      case MethodRecognizer::kDoubleRound:
        ReplaceWithMathCFunction(call, recognized_kind);
        return true;
      case MethodRecognizer::kDoubleTruncate:
      case MethodRecognizer::kDoubleFloor:
      case MethodRecognizer::kDoubleCeil:
        if (!TargetCPUFeatures::double_truncate_round_supported()) {
          ReplaceWithMathCFunction(call, recognized_kind);
        } else {
          AddReceiverCheck(call);
          DoubleToDoubleInstr* d2d_instr =
              new(I) DoubleToDoubleInstr(new(I) Value(call->ArgumentAt(0)),
                                         recognized_kind, call->deopt_id());
          ReplaceCall(call, d2d_instr);
        }
        return true;
      default:
        // Unsupported method.
        return false;
    }
  }

  if (IsSupportedByteArrayViewCid(class_ids[0]) &&
      (ic_data.NumberOfChecks() == 1)) {
    // For elements that may not fit into a smi on all platforms, check if
    // elements fit into a smi or the platform supports unboxed mints.
    if ((recognized_kind == MethodRecognizer::kByteArrayBaseGetInt32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseGetUint32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetInt32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetUint32)) {
      if (!CanUnboxInt32()) {
        return false;
      }
    }

    if ((recognized_kind == MethodRecognizer::kByteArrayBaseGetFloat32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseGetFloat64) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetFloat32) ||
        (recognized_kind == MethodRecognizer::kByteArrayBaseSetFloat64)) {
      if (!CanUnboxDouble()) {
        return false;
      }
    }

    switch (recognized_kind) {
      // ByteArray getters.
      case MethodRecognizer::kByteArrayBaseGetInt8:
        return BuildByteArrayViewLoad(call, kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint8:
        return BuildByteArrayViewLoad(call, kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt16:
        return BuildByteArrayViewLoad(call, kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint16:
        return BuildByteArrayViewLoad(call, kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt32:
        return BuildByteArrayViewLoad(call, kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint32:
        return BuildByteArrayViewLoad(call, kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32:
        return BuildByteArrayViewLoad(call, kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat64:
        return BuildByteArrayViewLoad(call, kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32x4:
        return BuildByteArrayViewLoad(call, kTypedDataFloat32x4ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt32x4:
        return BuildByteArrayViewLoad(call, kTypedDataInt32x4ArrayCid);

      // ByteArray setters.
      case MethodRecognizer::kByteArrayBaseSetInt8:
        return BuildByteArrayViewStore(call, kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint8:
        return BuildByteArrayViewStore(call, kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt16:
        return BuildByteArrayViewStore(call, kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint16:
        return BuildByteArrayViewStore(call, kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt32:
        return BuildByteArrayViewStore(call, kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint32:
        return BuildByteArrayViewStore(call, kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32:
        return BuildByteArrayViewStore(call, kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat64:
        return BuildByteArrayViewStore(call, kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32x4:
        return BuildByteArrayViewStore(call, kTypedDataFloat32x4ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt32x4:
        return BuildByteArrayViewStore(call, kTypedDataInt32x4ArrayCid);
      default:
        // Unsupported method.
        return false;
    }
  }

  if ((class_ids[0] == kFloat32x4Cid) && (ic_data.NumberOfChecks() == 1)) {
    return TryInlineFloat32x4Method(call, recognized_kind);
  }

  if ((class_ids[0] == kInt32x4Cid) && (ic_data.NumberOfChecks() == 1)) {
    return TryInlineInt32x4Method(call, recognized_kind);
  }

  if ((class_ids[0] == kFloat64x2Cid) && (ic_data.NumberOfChecks() == 1)) {
    return TryInlineFloat64x2Method(call, recognized_kind);
  }

  if (recognized_kind == MethodRecognizer::kIntegerLeftShiftWithMask32) {
    ASSERT(call->ArgumentCount() == 3);
    ASSERT(ic_data.NumArgsTested() == 2);
    Definition* value = call->ArgumentAt(0);
    Definition* count = call->ArgumentAt(1);
    Definition* int32_mask = call->ArgumentAt(2);
    if (HasOnlyTwoOf(ic_data, kSmiCid)) {
      if (ic_data.HasDeoptReason(ICData::kDeoptShiftMintOp)) {
        return false;
      }
      // We cannot overflow. The input value must be a Smi
      AddCheckSmi(value, call->deopt_id(), call->env(), call);
      AddCheckSmi(count, call->deopt_id(), call->env(), call);
      ASSERT(int32_mask->IsConstant());
      const Integer& mask_literal = Integer::Cast(
          int32_mask->AsConstant()->value());
      const int64_t mask_value = mask_literal.AsInt64Value();
      ASSERT(mask_value >= 0);
      if (mask_value > Smi::kMaxValue) {
        // The result will not be Smi.
        return false;
      }
      BinarySmiOpInstr* left_shift =
          new(I) BinarySmiOpInstr(Token::kSHL,
                                  new(I) Value(value),
                                  new(I) Value(count),
                                  call->deopt_id(), call->token_pos());
      left_shift->set_is_truncating(true);
      if ((kBitsPerWord == 32) && (mask_value == 0xffffffffLL)) {
        // No BIT_AND operation needed.
        ReplaceCall(call, left_shift);
      } else {
        InsertBefore(call, left_shift, call->env(), FlowGraph::kValue);
        BinarySmiOpInstr* bit_and =
            new(I) BinarySmiOpInstr(Token::kBIT_AND,
                                    new(I) Value(left_shift),
                                    new(I) Value(int32_mask),
                                    call->deopt_id(),
                                    call->token_pos());
        ReplaceCall(call, bit_and);
      }
      return true;
    }

    if (HasTwoMintOrSmi(ic_data) &&
        HasOnlyOneSmi(ICData::Handle(I,
                                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
      if (!FlowGraphCompiler::SupportsUnboxedMints() ||
          ic_data.HasDeoptReason(ICData::kDeoptShiftMintOp)) {
        return false;
      }
      ShiftMintOpInstr* left_shift =
          new(I) ShiftMintOpInstr(Token::kSHL,
                                  new(I) Value(value),
                                  new(I) Value(count),
                                  call->deopt_id());
      InsertBefore(call, left_shift, call->env(), FlowGraph::kValue);
      BinaryMintOpInstr* bit_and =
          new(I) BinaryMintOpInstr(Token::kBIT_AND,
                                   new(I) Value(left_shift),
                                   new(I) Value(int32_mask),
                                   call->deopt_id());
      ReplaceCall(call, bit_and);
      return true;
    }
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineFloat32x4Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kFloat32x4Zero) {
    Float32x4ZeroInstr* zero =
        new(I) Float32x4ZeroInstr(call->deopt_id());
    ReplaceCall(call, zero);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4Splat) {
    Float32x4SplatInstr* splat =
        new(I) Float32x4SplatInstr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, splat);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4Constructor) {
    Float32x4ConstructorInstr* con =
        new(I) Float32x4ConstructorInstr(
            new(I) Value(call->ArgumentAt(1)),
            new(I) Value(call->ArgumentAt(2)),
            new(I) Value(call->ArgumentAt(3)),
            new(I) Value(call->ArgumentAt(4)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4FromInt32x4Bits) {
    Int32x4ToFloat32x4Instr* cast =
        new(I) Int32x4ToFloat32x4Instr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4FromFloat64x2) {
    Float64x2ToFloat32x4Instr* cast =
        new(I) Float64x2ToFloat32x4Instr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineFloat64x2Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kFloat64x2Zero) {
    Float64x2ZeroInstr* zero =
        new(I) Float64x2ZeroInstr(call->deopt_id());
    ReplaceCall(call, zero);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2Splat) {
    Float64x2SplatInstr* splat =
        new(I) Float64x2SplatInstr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, splat);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2Constructor) {
    Float64x2ConstructorInstr* con =
        new(I) Float64x2ConstructorInstr(
            new(I) Value(call->ArgumentAt(1)),
            new(I) Value(call->ArgumentAt(2)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2FromFloat32x4) {
    Float32x4ToFloat64x2Instr* cast =
        new(I) Float32x4ToFloat64x2Instr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineInt32x4Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kInt32x4BoolConstructor) {
    Int32x4BoolConstructorInstr* con =
        new(I) Int32x4BoolConstructorInstr(
            new(I) Value(call->ArgumentAt(1)),
            new(I) Value(call->ArgumentAt(2)),
            new(I) Value(call->ArgumentAt(3)),
            new(I) Value(call->ArgumentAt(4)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kInt32x4FromFloat32x4Bits) {
    Float32x4ToInt32x4Instr* cast =
        new(I) Float32x4ToInt32x4Instr(
            new(I) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineFloat32x4Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->HasICData());
  switch (recognized_kind) {
    case MethodRecognizer::kFloat32x4ShuffleX:
    case MethodRecognizer::kFloat32x4ShuffleY:
    case MethodRecognizer::kFloat32x4ShuffleZ:
    case MethodRecognizer::kFloat32x4ShuffleW:
    case MethodRecognizer::kFloat32x4GetSignMask:
      ASSERT(call->ic_data()->HasReceiverClassId(kFloat32x4Cid));
      ASSERT(call->ic_data()->HasOneTarget());
      return InlineFloat32x4Getter(call, recognized_kind);

    case MethodRecognizer::kFloat32x4Equal:
    case MethodRecognizer::kFloat32x4GreaterThan:
    case MethodRecognizer::kFloat32x4GreaterThanOrEqual:
    case MethodRecognizer::kFloat32x4LessThan:
    case MethodRecognizer::kFloat32x4LessThanOrEqual:
    case MethodRecognizer::kFloat32x4NotEqual: {
      Definition* left = call->ArgumentAt(0);
      Definition* right = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      // Replace call.
      Float32x4ComparisonInstr* cmp =
          new(I) Float32x4ComparisonInstr(recognized_kind,
                                          new(I) Value(left),
                                          new(I) Value(right),
                                          call->deopt_id());
      ReplaceCall(call, cmp);
      return true;
    }
    case MethodRecognizer::kFloat32x4Min:
    case MethodRecognizer::kFloat32x4Max: {
      Definition* left = call->ArgumentAt(0);
      Definition* right = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4MinMaxInstr* minmax =
          new(I) Float32x4MinMaxInstr(
              recognized_kind,
              new(I) Value(left),
              new(I) Value(right),
              call->deopt_id());
      ReplaceCall(call, minmax);
      return true;
    }
    case MethodRecognizer::kFloat32x4Scale: {
      Definition* left = call->ArgumentAt(0);
      Definition* right = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      // Left and right values are swapped when handed to the instruction,
      // this is done so that the double value is loaded into the output
      // register and can be destroyed.
      Float32x4ScaleInstr* scale =
          new(I) Float32x4ScaleInstr(recognized_kind,
                                     new(I) Value(right),
                                     new(I) Value(left),
                                     call->deopt_id());
      ReplaceCall(call, scale);
      return true;
    }
    case MethodRecognizer::kFloat32x4Sqrt:
    case MethodRecognizer::kFloat32x4ReciprocalSqrt:
    case MethodRecognizer::kFloat32x4Reciprocal: {
      Definition* left = call->ArgumentAt(0);
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4SqrtInstr* sqrt =
          new(I) Float32x4SqrtInstr(recognized_kind,
                                    new(I) Value(left),
                                    call->deopt_id());
      ReplaceCall(call, sqrt);
      return true;
    }
    case MethodRecognizer::kFloat32x4WithX:
    case MethodRecognizer::kFloat32x4WithY:
    case MethodRecognizer::kFloat32x4WithZ:
    case MethodRecognizer::kFloat32x4WithW: {
      Definition* left = call->ArgumentAt(0);
      Definition* right = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4WithInstr* with = new(I) Float32x4WithInstr(recognized_kind,
                                                           new(I) Value(left),
                                                           new(I) Value(right),
                                                           call->deopt_id());
      ReplaceCall(call, with);
      return true;
    }
    case MethodRecognizer::kFloat32x4Absolute:
    case MethodRecognizer::kFloat32x4Negate: {
      Definition* left = call->ArgumentAt(0);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4ZeroArgInstr* zeroArg =
          new(I) Float32x4ZeroArgInstr(
              recognized_kind, new(I) Value(left), call->deopt_id());
      ReplaceCall(call, zeroArg);
      return true;
    }
    case MethodRecognizer::kFloat32x4Clamp: {
      Definition* left = call->ArgumentAt(0);
      Definition* lower = call->ArgumentAt(1);
      Definition* upper = call->ArgumentAt(2);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4ClampInstr* clamp = new(I) Float32x4ClampInstr(
          new(I) Value(left),
          new(I) Value(lower),
          new(I) Value(upper),
          call->deopt_id());
      ReplaceCall(call, clamp);
      return true;
    }
    case MethodRecognizer::kFloat32x4ShuffleMix:
    case MethodRecognizer::kFloat32x4Shuffle: {
      return InlineFloat32x4Getter(call, recognized_kind);
    }
    default:
      return false;
  }
}


bool FlowGraphOptimizer::TryInlineFloat64x2Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->HasICData());
  switch (recognized_kind) {
    case MethodRecognizer::kFloat64x2GetX:
    case MethodRecognizer::kFloat64x2GetY:
      ASSERT(call->ic_data()->HasReceiverClassId(kFloat64x2Cid));
      ASSERT(call->ic_data()->HasOneTarget());
      return InlineFloat64x2Getter(call, recognized_kind);
    case MethodRecognizer::kFloat64x2Negate:
    case MethodRecognizer::kFloat64x2Abs:
    case MethodRecognizer::kFloat64x2Sqrt:
    case MethodRecognizer::kFloat64x2GetSignMask: {
      Definition* left = call->ArgumentAt(0);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float64x2ZeroArgInstr* zeroArg =
          new(I) Float64x2ZeroArgInstr(
              recognized_kind, new(I) Value(left), call->deopt_id());
      ReplaceCall(call, zeroArg);
      return true;
    }
    case MethodRecognizer::kFloat64x2Scale:
    case MethodRecognizer::kFloat64x2WithX:
    case MethodRecognizer::kFloat64x2WithY:
    case MethodRecognizer::kFloat64x2Min:
    case MethodRecognizer::kFloat64x2Max: {
      Definition* left = call->ArgumentAt(0);
      Definition* right = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float64x2OneArgInstr* zeroArg =
          new(I) Float64x2OneArgInstr(recognized_kind,
                                      new(I) Value(left),
                                      new(I) Value(right),
                                      call->deopt_id());
      ReplaceCall(call, zeroArg);
      return true;
    }
    default:
      return false;
  }
}


bool FlowGraphOptimizer::TryInlineInt32x4Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  ASSERT(call->HasICData());
  switch (recognized_kind) {
    case MethodRecognizer::kInt32x4ShuffleMix:
    case MethodRecognizer::kInt32x4Shuffle:
    case MethodRecognizer::kInt32x4GetFlagX:
    case MethodRecognizer::kInt32x4GetFlagY:
    case MethodRecognizer::kInt32x4GetFlagZ:
    case MethodRecognizer::kInt32x4GetFlagW:
    case MethodRecognizer::kInt32x4GetSignMask:
      ASSERT(call->ic_data()->HasReceiverClassId(kInt32x4Cid));
      ASSERT(call->ic_data()->HasOneTarget());
      return InlineInt32x4Getter(call, recognized_kind);

    case MethodRecognizer::kInt32x4Select: {
      Definition* mask = call->ArgumentAt(0);
      Definition* trueValue = call->ArgumentAt(1);
      Definition* falseValue = call->ArgumentAt(2);
      // Type check left.
      AddCheckClass(mask,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Int32x4SelectInstr* select = new(I) Int32x4SelectInstr(
          new(I) Value(mask),
          new(I) Value(trueValue),
          new(I) Value(falseValue),
          call->deopt_id());
      ReplaceCall(call, select);
      return true;
    }
    case MethodRecognizer::kInt32x4WithFlagX:
    case MethodRecognizer::kInt32x4WithFlagY:
    case MethodRecognizer::kInt32x4WithFlagZ:
    case MethodRecognizer::kInt32x4WithFlagW: {
      Definition* left = call->ArgumentAt(0);
      Definition* flag = call->ArgumentAt(1);
      // Type check left.
      AddCheckClass(left,
                    ICData::ZoneHandle(
                        I, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Int32x4SetFlagInstr* setFlag = new(I) Int32x4SetFlagInstr(
          recognized_kind,
          new(I) Value(left),
          new(I) Value(flag),
          call->deopt_id());
      ReplaceCall(call, setFlag);
      return true;
    }
    default:
      return false;
  }
}


bool FlowGraphOptimizer::InlineByteArrayViewLoad(Instruction* call,
                                                 Definition* receiver,
                                                 intptr_t array_cid,
                                                 intptr_t view_cid,
                                                 const ICData& ic_data,
                                                 TargetEntryInstr** entry,
                                                 Definition** last) {
  ASSERT(array_cid != kIllegalCid);
  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineByteArrayViewOp(call,
                                           array_cid,
                                           view_cid,
                                           &array,
                                           index,
                                           &cursor);

  intptr_t deopt_id = Isolate::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Set deopt_id if we can optimistically assume that the result is Smi.
    // Assume mixed Mint/Smi if this instruction caused deoptimization once.
    deopt_id = ic_data.HasDeoptReasons() ?
        Isolate::kNoDeoptId : call->deopt_id();
  }

  *last = new(I) LoadIndexedInstr(new(I) Value(array),
                                  new(I) Value(index),
                                  1,
                                  view_cid,
                                  deopt_id,
                                  call->token_pos());
  cursor = flow_graph()->AppendTo(
      cursor,
      *last,
      deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (view_cid == kTypedDataFloat32ArrayCid) {
    *last = new(I) FloatToDoubleInstr(new(I) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
                           FlowGraph::kValue);
  }
  return true;
}


bool FlowGraphOptimizer::InlineByteArrayViewStore(const Function& target,
                                                  Instruction* call,
                                                  Definition* receiver,
                                                  intptr_t array_cid,
                                                  intptr_t view_cid,
                                                  const ICData& ic_data,
                                                  TargetEntryInstr** entry,
                                                  Definition** last) {
  ASSERT(array_cid != kIllegalCid);
  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new(I) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(I, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineByteArrayViewOp(call,
                                           array_cid,
                                           view_cid,
                                           &array,
                                           index,
                                           &cursor);

  // Extract the instance call so we can use the function_name in the stored
  // value check ICData.
  InstanceCallInstr* i_call = NULL;
  if (call->IsPolymorphicInstanceCall()) {
    i_call = call->AsPolymorphicInstanceCall()->instance_call();
  } else {
    ASSERT(call->IsInstanceCall());
    i_call = call->AsInstanceCall();
  }
  ASSERT(i_call != NULL);
  ICData& value_check = ICData::ZoneHandle(I);
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      // Check that value is always smi.
      value_check = ICData::New(flow_graph_->parsed_function().function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kSmiCid, target);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // We don't have ICData for the value stored, so we optimistically assume
      // smis first. If we ever deoptimized here, we require to unbox the value
      // before storing to handle the mint case, too.
      if (!i_call->ic_data()->HasDeoptReasons()) {
        value_check = ICData::New(flow_graph_->parsed_function().function(),
                                  i_call->function_name(),
                                  Object::empty_array(),  // Dummy args. descr.
                                  Isolate::kNoDeoptId,
                                  1);
        value_check.AddReceiverCheck(kSmiCid, target);
      }
      break;
    case kTypedDataFloat32ArrayCid:
    case kTypedDataFloat64ArrayCid: {
      // Check that value is always double.
      value_check = ICData::New(flow_graph_->parsed_function().function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kDoubleCid, target);
      break;
    }
    case kTypedDataInt32x4ArrayCid: {
      // Check that value is always Int32x4.
      value_check = ICData::New(flow_graph_->parsed_function().function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kInt32x4Cid, target);
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always Float32x4.
      value_check = ICData::New(flow_graph_->parsed_function().function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kFloat32x4Cid, target);
      break;
    }
    default:
      // Array cids are already checked in the caller.
      UNREACHABLE();
  }

  Definition* stored_value = call->ArgumentAt(2);
  if (!value_check.IsNull()) {
    AddCheckClass(stored_value, value_check, call->deopt_id(), call->env(),
                  call);
  }

  if (view_cid == kTypedDataFloat32ArrayCid) {
    stored_value = new(I) DoubleToFloatInstr(
        new(I) Value(stored_value), call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    NULL,
                                    FlowGraph::kValue);
  }

  StoreBarrierType needs_store_barrier = kNoStoreBarrier;
  *last = new(I) StoreIndexedInstr(new(I) Value(array),
                                   new(I) Value(index),
                                   new(I) Value(stored_value),
                                   needs_store_barrier,
                                   1,  // Index scale
                                   view_cid,
                                   call->deopt_id(),
                                   call->token_pos());

  flow_graph()->AppendTo(cursor,
                         *last,
                         call->deopt_id() != Isolate::kNoDeoptId ?
                            call->env() : NULL,
                         FlowGraph::kEffect);
  return true;
}



intptr_t FlowGraphOptimizer::PrepareInlineByteArrayViewOp(
    Instruction* call,
    intptr_t array_cid,
    intptr_t view_cid,
    Definition** array,
    Definition* byte_index,
    Instruction** cursor) {
  // Insert byte_index smi check.
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(I) CheckSmiInstr(
                                       new(I) Value(byte_index),
                                       call->deopt_id(),
                                       call->token_pos()),
                                   call->env(),
                                   FlowGraph::kEffect);

  LoadFieldInstr* length =
      new(I) LoadFieldInstr(
          new(I) Value(*array),
          CheckArrayBoundInstr::LengthOffsetFor(array_cid),
          Type::ZoneHandle(I, Type::SmiType()),
          call->token_pos());
  length->set_is_immutable(true);
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(
      LoadFieldInstr::RecognizedKindFromArrayCid(array_cid));
  *cursor = flow_graph()->AppendTo(*cursor,
                                   length,
                                   NULL,
                                   FlowGraph::kValue);

  intptr_t element_size = Instance::ElementSizeFor(array_cid);
  ConstantInstr* bytes_per_element =
      flow_graph()->GetConstant(Smi::Handle(I, Smi::New(element_size)));
  BinarySmiOpInstr* len_in_bytes =
      new(I) BinarySmiOpInstr(Token::kMUL,
                              new(I) Value(length),
                              new(I) Value(bytes_per_element),
                              call->deopt_id(), call->token_pos());
  *cursor = flow_graph()->AppendTo(*cursor, len_in_bytes, call->env(),
                                   FlowGraph::kValue);

  ConstantInstr* length_adjustment =
      flow_graph()->GetConstant(Smi::Handle(I, Smi::New(
          Instance::ElementSizeFor(view_cid) - 1)));
  // adjusted_length = len_in_bytes - (element_size - 1).
  BinarySmiOpInstr* adjusted_length =
      new(I) BinarySmiOpInstr(Token::kSUB,
                              new(I) Value(len_in_bytes),
                              new(I) Value(length_adjustment),
                              call->deopt_id(), call->token_pos());
  *cursor = flow_graph()->AppendTo(*cursor, adjusted_length, call->env(),
                                   FlowGraph::kValue);

  // Check adjusted_length > 0.
  ConstantInstr* zero =
      flow_graph()->GetConstant(Smi::Handle(I, Smi::New(0)));
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(I) CheckArrayBoundInstr(
                                       new(I) Value(adjusted_length),
                                       new(I) Value(zero),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);
  // Check 0 <= byte_index < adjusted_length.
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(I) CheckArrayBoundInstr(
                                       new(I) Value(adjusted_length),
                                       new(I) Value(byte_index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements =
        new(I) LoadUntaggedInstr(new(I) Value(*array),
                                 ExternalTypedData::data_offset());
    *cursor = flow_graph()->AppendTo(*cursor,
                                     elements,
                                     NULL,
                                     FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}


bool FlowGraphOptimizer::BuildByteArrayViewLoad(InstanceCallInstr* call,
                                                intptr_t view_cid) {
  const bool simd_view = (view_cid == kTypedDataFloat32x4ArrayCid) ||
                         (view_cid == kTypedDataInt32x4ArrayCid);
  const bool float_view = (view_cid == kTypedDataFloat32ArrayCid) ||
                          (view_cid == kTypedDataFloat64ArrayCid);
  if (float_view && !CanUnboxDouble()) {
    return false;
  }
  if (simd_view && !ShouldInlineSimd()) {
    return false;
  }
  return TryReplaceInstanceCallWithInline(call);
}


bool FlowGraphOptimizer::BuildByteArrayViewStore(InstanceCallInstr* call,
                                                 intptr_t view_cid) {
  const bool simd_view = (view_cid == kTypedDataFloat32x4ArrayCid) ||
                         (view_cid == kTypedDataInt32x4ArrayCid);
  const bool float_view = (view_cid == kTypedDataFloat32ArrayCid) ||
                          (view_cid == kTypedDataFloat64ArrayCid);
  if (float_view && !CanUnboxDouble()) {
    return false;
  }
  if (simd_view && !ShouldInlineSimd()) {
    return false;
  }
  return TryReplaceInstanceCallWithInline(call);
}


// If type tests specified by 'ic_data' do not depend on type arguments,
// return mapping cid->result in 'results' (i : cid; i + 1: result).
// If all tests yield the same result, return it otherwise return Bool::null.
// If no mapping is possible, 'results' is empty.
// An instance-of test returning all same results can be converted to a class
// check.
RawBool* FlowGraphOptimizer::InstanceOfAsBool(
    const ICData& ic_data,
    const AbstractType& type,
    ZoneGrowableArray<intptr_t>* results) const {
  ASSERT(results->is_empty());
  ASSERT(ic_data.NumArgsTested() == 1);  // Unary checks only.
  if (!type.IsInstantiated() || type.IsMalformedOrMalbounded()) {
    return Bool::null();
  }
  const Class& type_class = Class::Handle(I, type.type_class());
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const intptr_t num_type_params = type_class.NumTypeParameters();
    const intptr_t from_index = num_type_args - num_type_params;
    const TypeArguments& type_arguments =
        TypeArguments::Handle(I, type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
        type_arguments.IsRaw(from_index, num_type_params);
    if (!is_raw_type) {
      // Unknown result.
      return Bool::null();
    }
  }

  const ClassTable& class_table = *isolate()->class_table();
  Bool& prev = Bool::Handle(I);
  Class& cls = Class::Handle(I);

  bool results_differ = false;
  for (int i = 0; i < ic_data.NumberOfChecks(); i++) {
    cls = class_table.At(ic_data.GetReceiverClassIdAt(i));
    if (cls.NumTypeArguments() > 0) {
      return Bool::null();
    }
    const bool is_subtype = cls.IsSubtypeOf(
        TypeArguments::Handle(I),
        type_class,
        TypeArguments::Handle(I),
        NULL);
    results->Add(cls.id());
    results->Add(is_subtype);
    if (prev.IsNull()) {
      prev = Bool::Get(is_subtype).raw();
    } else {
      if (is_subtype != prev.value()) {
        results_differ = true;
      }
    }
  }
  return results_differ ?  Bool::null() : prev.raw();
}


// Returns true if checking against this type is a direct class id comparison.
static bool TypeCheckAsClassEquality(const AbstractType& type) {
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  // Requires CHA.
  if (!FLAG_use_cha) return false;
  if (!type.IsInstantiated()) return false;
  const Class& type_class = Class::Handle(type.type_class());
  // Signature classes have different type checking rules.
  if (type_class.IsSignatureClass()) return false;
  // Could be an interface check?
  if (type_class.is_implemented()) return false;
  const intptr_t type_cid = type_class.id();
  if (CHA::HasSubclasses(type_cid)) return false;
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const intptr_t num_type_params = type_class.NumTypeParameters();
    const intptr_t from_index = num_type_args - num_type_params;
    const TypeArguments& type_arguments =
        TypeArguments::Handle(type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
        type_arguments.IsRaw(from_index, num_type_params);
    return is_raw_type;
  }
  return true;
}


static bool CidTestResultsContains(const ZoneGrowableArray<intptr_t>& results,
                                   intptr_t test_cid) {
  for (intptr_t i = 0; i < results.length(); i += 2) {
    if (results[i] == test_cid) return true;
  }
  return false;
}


static void TryAddTest(ZoneGrowableArray<intptr_t>* results,
                       intptr_t test_cid,
                       bool result) {
  if (!CidTestResultsContains(*results, test_cid)) {
    results->Add(test_cid);
    results->Add(result);
  }
}


// Tries to add cid tests to 'results' so that no deoptimization is
// necessary.
// TODO(srdjan): Do also for other than 'int' type.
static bool TryExpandTestCidsResult(ZoneGrowableArray<intptr_t>* results,
                                    const AbstractType& type) {
  ASSERT(results->length() >= 2);  // At least on eentry.
  const ClassTable& class_table = *Isolate::Current()->class_table();
  if ((*results)[0] != kSmiCid) {
    const Class& cls = Class::Handle(class_table.At(kSmiCid));
    const Class& type_class = Class::Handle(type.type_class());
    const bool smi_is_subtype = cls.IsSubtypeOf(TypeArguments::Handle(),
                                                type_class,
                                                TypeArguments::Handle(),
                                                NULL);
    results->Add((*results)[results->length() - 2]);
    results->Add((*results)[results->length() - 2]);
    for (intptr_t i = results->length() - 3; i > 1; --i) {
      (*results)[i] = (*results)[i - 2];
    }
    (*results)[0] = kSmiCid;
    (*results)[1] = smi_is_subtype;
  }

  ASSERT(type.IsInstantiated() && !type.IsMalformedOrMalbounded());
  ASSERT(results->length() >= 2);
  if (type.IsIntType()) {
    ASSERT((*results)[0] == kSmiCid);
    TryAddTest(results, kMintCid, true);
    TryAddTest(results, kBigintCid, true);
    // Cannot deoptimize since all tests returning true have been added.
    return false;
  }

  return true;  // May deoptimize since we have not identified all 'true' tests.
}


// TODO(srdjan): Use ICData to check if always true or false.
void FlowGraphOptimizer::ReplaceWithInstanceOf(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeTestOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator = call->ArgumentAt(1);
  Definition* type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  const bool negate = Bool::Cast(
      call->ArgumentAt(4)->OriginalDefinition()->AsConstant()->value()).value();
  const ICData& unary_checks =
      ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecks());
  if (FLAG_warn_on_javascript_compatibility &&
      !unary_checks.IssuedJSWarning() &&
      (type.IsIntType() || type.IsDoubleType() || !type.IsInstantiated())) {
    // No warning was reported yet for this type check, either because it has
    // not been executed yet, or because no problematic combinations of instance
    // type and test type have been encountered so far. A warning may still be
    // reported, so do not replace the instance call.
    return;
  }
  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    ZoneGrowableArray<intptr_t>* results =
        new(I) ZoneGrowableArray<intptr_t>(unary_checks.NumberOfChecks() * 2);
    Bool& as_bool =
        Bool::ZoneHandle(I, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.IsNull()) {
      if (results->length() == unary_checks.NumberOfChecks() * 2) {
        const bool can_deopt = TryExpandTestCidsResult(results, type);
        TestCidsInstr* test_cids = new(I) TestCidsInstr(
            call->token_pos(),
            negate ? Token::kISNOT : Token::kIS,
            new(I) Value(left),
            *results,
            can_deopt ? call->deopt_id() : Isolate::kNoDeoptId);
        // Remove type.
        ReplaceCall(call, test_cids);
        return;
      }
    } else {
      // TODO(srdjan): Use TestCidsInstr also for this case.
      // One result only.
      AddReceiverCheck(call);
      if (negate) {
        as_bool = Bool::Get(!as_bool.value()).raw();
      }
      ConstantInstr* bool_const = flow_graph()->GetConstant(as_bool);
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->PushArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
      call->ReplaceUsesWith(bool_const);
      ASSERT(current_iterator()->Current() == call);
      current_iterator()->RemoveCurrentFromGraph();
      return;
    }
  }

  if (TypeCheckAsClassEquality(type)) {
    LoadClassIdInstr* left_cid = new(I) LoadClassIdInstr(new(I) Value(left));
    InsertBefore(call,
                 left_cid,
                 NULL,
                 FlowGraph::kValue);
    const intptr_t type_cid = Class::Handle(I, type.type_class()).id();
    ConstantInstr* cid =
        flow_graph()->GetConstant(Smi::Handle(I, Smi::New(type_cid)));

    StrictCompareInstr* check_cid =
        new(I) StrictCompareInstr(
            call->token_pos(),
            negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
            new(I) Value(left_cid),
            new(I) Value(cid),
            false);  // No number check.
    ReplaceCall(call, check_cid);
    return;
  }

  InstanceOfInstr* instance_of =
      new(I) InstanceOfInstr(call->token_pos(),
                             new(I) Value(left),
                             new(I) Value(instantiator),
                             new(I) Value(type_args),
                             type,
                             negate,
                             call->deopt_id());
  ReplaceCall(call, instance_of);
}


// TODO(srdjan): Apply optimizations as in ReplaceWithInstanceOf (TestCids).
void FlowGraphOptimizer::ReplaceWithTypeCast(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeCastOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* instantiator = call->ArgumentAt(1);
  Definition* type_args = call->ArgumentAt(2);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value());
  ASSERT(!type.IsMalformedOrMalbounded());
  const ICData& unary_checks =
      ICData::ZoneHandle(I, call->ic_data()->AsUnaryClassChecks());
  if (FLAG_warn_on_javascript_compatibility &&
      !unary_checks.IssuedJSWarning() &&
      (type.IsIntType() || type.IsDoubleType() || !type.IsInstantiated())) {
    // No warning was reported yet for this type check, either because it has
    // not been executed yet, or because no problematic combinations of instance
    // type and test type have been encountered so far. A warning may still be
    // reported, so do not replace the instance call.
    return;
  }
  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    ZoneGrowableArray<intptr_t>* results =
        new(I) ZoneGrowableArray<intptr_t>(unary_checks.NumberOfChecks() * 2);
    const Bool& as_bool = Bool::ZoneHandle(I,
        InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.raw() == Bool::True().raw()) {
      AddReceiverCheck(call);
      // Remove the original push arguments.
      for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
        PushArgumentInstr* push = call->PushArgumentAt(i);
        push->ReplaceUsesWith(push->value()->definition());
        push->RemoveFromGraph();
      }
      // Remove call, replace it with 'left'.
      call->ReplaceUsesWith(left);
      ASSERT(current_iterator()->Current() == call);
      current_iterator()->RemoveCurrentFromGraph();
      return;
    }
  }
  const String& dst_name = String::ZoneHandle(I,
      Symbols::New(Exceptions::kCastErrorDstName));
  AssertAssignableInstr* assert_as =
      new(I) AssertAssignableInstr(call->token_pos(),
                                   new(I) Value(left),
                                   new(I) Value(instantiator),
                                   new(I) Value(type_args),
                                   type,
                                   dst_name);
  // Newly inserted instructions that can deoptimize or throw an exception
  // must have a deoptimization id that is valid for lookup in the unoptimized
  // code.
  assert_as->deopt_id_ = call->deopt_id();
  ReplaceCall(call, assert_as);
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (!instr->HasICData() || (instr->ic_data()->NumberOfChecks() == 0)) {
    return;
  }

  const Token::Kind op_kind = instr->token_kind();
  // Type test is special as it always gets converted into inlined code.
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }

  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }

  const ICData& unary_checks =
      ICData::ZoneHandle(I, instr->ic_data()->AsUnaryClassChecks());

  intptr_t max_checks = (op_kind == Token::kEQ)
      ? FLAG_max_equality_polymorphic_checks
      : FLAG_max_polymorphic_checks;
  if ((unary_checks.NumberOfChecks() > max_checks) &&
      InstanceCallNeedsClassCheck(instr)) {
    // Too many checks, it will be megamorphic which needs unary checks.
    instr->set_ic_data(&unary_checks);
    return;
  }

  if ((op_kind == Token::kASSIGN_INDEX) && TryReplaceWithStoreIndexed(instr)) {
    return;
  }
  if ((op_kind == Token::kINDEX) && TryReplaceWithLoadIndexed(instr)) {
    return;
  }

  if (op_kind == Token::kEQ && TryReplaceWithEqualityOp(instr, op_kind)) {
    return;
  }

  if (Token::IsRelationalOperator(op_kind) &&
      TryReplaceWithRelationalOp(instr, op_kind)) {
    return;
  }

  if (Token::IsBinaryOperator(op_kind) &&
      TryReplaceWithBinaryOp(instr, op_kind)) {
    return;
  }
  if (Token::IsPrefixOperator(op_kind) &&
      TryReplaceWithUnaryOp(instr, op_kind)) {
    return;
  }
  if ((op_kind == Token::kGET) && TryInlineInstanceGetter(instr)) {
    return;
  }
  if ((op_kind == Token::kSET) &&
      TryInlineInstanceSetter(instr, unary_checks)) {
    return;
  }
  if (TryInlineInstanceMethod(instr)) {
    return;
  }

  bool has_one_target = unary_checks.HasOneTarget();

  if (has_one_target) {
    // Check if the single target is a polymorphic target, if it is,
    // we don't have one target.
    const Function& target =
        Function::Handle(I, unary_checks.GetTargetAt(0));
    const bool polymorphic_target = MethodRecognizer::PolymorphicTarget(target);
    has_one_target = !polymorphic_target;
  }

  if (has_one_target) {
    const bool is_method_extraction =
        Function::Handle(I, unary_checks.GetTargetAt(0)).IsMethodExtractor();

    if ((is_method_extraction && !MethodExtractorNeedsClassCheck(instr)) ||
        (!is_method_extraction && !InstanceCallNeedsClassCheck(instr))) {
      const bool call_with_checks = false;
      PolymorphicInstanceCallInstr* call =
          new(I) PolymorphicInstanceCallInstr(instr, unary_checks,
                                              call_with_checks);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    bool call_with_checks;
    if (has_one_target) {
      // Type propagation has not run yet, we cannot eliminate the check.
      AddReceiverCheck(instr);
      // Call can still deoptimize, do not detach environment from instr.
      call_with_checks = false;
    } else {
      call_with_checks = true;
    }
    PolymorphicInstanceCallInstr* call =
        new(I) PolymorphicInstanceCallInstr(instr, unary_checks,
                                            call_with_checks);
    instr->ReplaceWith(call, current_iterator());
  }
}


void FlowGraphOptimizer::VisitStaticCall(StaticCallInstr* call) {
  if (!CanUnboxDouble()) {
    return;
  }
  MethodRecognizer::Kind recognized_kind =
      MethodRecognizer::RecognizeKind(call->function());
  MathUnaryInstr::MathUnaryKind unary_kind;
  switch (recognized_kind) {
    case MethodRecognizer::kMathSqrt:
      unary_kind = MathUnaryInstr::kSqrt;
      break;
    case MethodRecognizer::kMathSin:
      unary_kind = MathUnaryInstr::kSin;
      break;
    case MethodRecognizer::kMathCos:
      unary_kind = MathUnaryInstr::kCos;
      break;
    default:
      unary_kind = MathUnaryInstr::kIllegal;
      break;
  }
  if (unary_kind != MathUnaryInstr::kIllegal) {
    MathUnaryInstr* math_unary =
        new(I) MathUnaryInstr(unary_kind,
                              new(I) Value(call->ArgumentAt(0)),
                              call->deopt_id());
    ReplaceCall(call, math_unary);
  } else if ((recognized_kind == MethodRecognizer::kFloat32x4Zero) ||
             (recognized_kind == MethodRecognizer::kFloat32x4Splat) ||
             (recognized_kind == MethodRecognizer::kFloat32x4Constructor) ||
             (recognized_kind == MethodRecognizer::kFloat32x4FromFloat64x2)) {
    TryInlineFloat32x4Constructor(call, recognized_kind);
  } else if ((recognized_kind == MethodRecognizer::kFloat64x2Constructor) ||
             (recognized_kind == MethodRecognizer::kFloat64x2Zero) ||
             (recognized_kind == MethodRecognizer::kFloat64x2Splat) ||
             (recognized_kind == MethodRecognizer::kFloat64x2FromFloat32x4)) {
    TryInlineFloat64x2Constructor(call, recognized_kind);
  } else if (recognized_kind == MethodRecognizer::kInt32x4BoolConstructor) {
    TryInlineInt32x4Constructor(call, recognized_kind);
  } else if (recognized_kind == MethodRecognizer::kObjectConstructor) {
    // Remove the original push arguments.
    for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
      PushArgumentInstr* push = call->PushArgumentAt(i);
      push->ReplaceUsesWith(push->value()->definition());
      push->RemoveFromGraph();
    }
    // Manually replace call with global null constant. ReplaceCall can't
    // be used for definitions that are already in the graph.
    call->ReplaceUsesWith(flow_graph_->constant_null());
    ASSERT(current_iterator()->Current() == call);
    current_iterator()->RemoveCurrentFromGraph();;
  } else if ((recognized_kind == MethodRecognizer::kMathMin) ||
             (recognized_kind == MethodRecognizer::kMathMax)) {
    // We can handle only monomorphic min/max call sites with both arguments
    // being either doubles or smis.
    if (call->HasICData() && (call->ic_data()->NumberOfChecks() == 1)) {
      const ICData& ic_data = *call->ic_data();
      intptr_t result_cid = kIllegalCid;
      if (ICDataHasReceiverArgumentClassIds(ic_data, kDoubleCid, kDoubleCid)) {
        result_cid = kDoubleCid;
      } else if (ICDataHasReceiverArgumentClassIds(ic_data, kSmiCid, kSmiCid)) {
        result_cid = kSmiCid;
      }
      if (result_cid != kIllegalCid) {
        MathMinMaxInstr* min_max = new(I) MathMinMaxInstr(
            recognized_kind,
            new(I) Value(call->ArgumentAt(0)),
            new(I) Value(call->ArgumentAt(1)),
            call->deopt_id(),
            result_cid);
        const ICData& unary_checks =
            ICData::ZoneHandle(I, ic_data.AsUnaryClassChecks());
        AddCheckClass(min_max->left()->definition(),
                      unary_checks,
                      call->deopt_id(),
                      call->env(),
                      call);
        AddCheckClass(min_max->right()->definition(),
                      unary_checks,
                      call->deopt_id(),
                      call->env(),
                      call);
        ReplaceCall(call, min_max);
      }
    }
  } else if (recognized_kind == MethodRecognizer::kMathDoublePow) {
    // We know that first argument is double, the second is num.
    // InvokeMathCFunctionInstr requires unboxed doubles. UnboxDouble
    // instructions contain type checks and conversions to double.
    ZoneGrowableArray<Value*>* args =
        new(I) ZoneGrowableArray<Value*>(call->ArgumentCount());
    for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
      args->Add(new(I) Value(call->ArgumentAt(i)));
    }
    InvokeMathCFunctionInstr* invoke =
        new(I) InvokeMathCFunctionInstr(args,
                                        call->deopt_id(),
                                        recognized_kind,
                                        call->token_pos());
    ReplaceCall(call, invoke);
  } else if (recognized_kind == MethodRecognizer::kObjectArrayConstructor) {
    Value* type = new(I) Value(call->ArgumentAt(0));
    Value* num_elements = new(I) Value(call->ArgumentAt(1));
    CreateArrayInstr* create_array =
        new(I) CreateArrayInstr(call->token_pos(), type, num_elements);
    ReplaceCall(call, create_array);
  } else if (call->function().IsFactory()) {
    const Class& function_class =
        Class::Handle(I, call->function().Owner());
    if ((function_class.library() == Library::CoreLibrary()) ||
        (function_class.library() == Library::TypedDataLibrary())) {
      intptr_t cid = FactoryRecognizer::ResultCid(call->function());
      switch (cid) {
        case kArrayCid: {
          Value* type = new(I) Value(call->ArgumentAt(0));
          Value* num_elements = new(I) Value(call->ArgumentAt(1));
          if (num_elements->BindsToConstant() &&
              num_elements->BoundConstant().IsSmi()) {
            intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
            if (length >= 0 && length <= Array::kMaxElements) {
              CreateArrayInstr* create_array =
                  new(I) CreateArrayInstr(
                      call->token_pos(), type, num_elements);
              ReplaceCall(call, create_array);
            }
          }
        }
        default:
          break;
      }
    }
  }
}


void FlowGraphOptimizer::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {
  if (instr->IsUnboxedStore()) {
    ASSERT(instr->is_initialization_);
    // Determine if this field should be unboxed based on the usage of getter
    // and setter functions: The heuristic requires that the setter has a
    // usage count of at least 1/kGetterSetterRatio of the getter usage count.
    // This is to avoid unboxing fields where the setter is never or rarely
    // executed.
    const Field& field = Field::ZoneHandle(I, instr->field().raw());
    const String& field_name = String::Handle(I, field.name());
    class Class& owner = Class::Handle(I, field.owner());
    const Function& getter =
        Function::Handle(I, owner.LookupGetterFunction(field_name));
    const Function& setter =
        Function::Handle(I, owner.LookupSetterFunction(field_name));
    bool result = !getter.IsNull()
               && !setter.IsNull()
               && (setter.usage_counter() > 0)
               && (FLAG_getter_setter_ratio * setter.usage_counter() >
                   getter.usage_counter());
    if (!result) {
      if (FLAG_trace_optimization) {
        OS::Print("Disabling unboxing of %s\n", field.ToCString());
      }
      field.set_is_unboxing_candidate(false);
      field.DeoptimizeDependentCode();
    } else {
      FlowGraph::AddToGuardedFields(flow_graph_->guarded_fields(), &field);
    }
  }
}


bool FlowGraphOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr,
                                                 const ICData& unary_ic_data) {
  ASSERT((unary_ic_data.NumberOfChecks() > 0) &&
      (unary_ic_data.NumArgsTested() == 1));
  if (FLAG_enable_type_checks) {
    // Checked mode setters are inlined like normal methods by conventional
    // inlining.
    return false;
  }

  ASSERT(instr->HasICData());
  if (unary_ic_data.NumberOfChecks() == 0) {
    // No type feedback collected.
    return false;
  }
  if (!unary_ic_data.HasOneTarget()) {
    // Polymorphic sites are inlined like normal method calls by conventional
    // inlining.
    return false;
  }
  Function& target = Function::Handle(I);
  intptr_t class_id;
  unary_ic_data.GetOneClassCheckAt(0, &class_id, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Non-implicit setter are inlined like normal method calls.
    return false;
  }
  // Inline implicit instance setter.
  const String& field_name =
      String::Handle(I, Field::NameFromSetter(instr->function_name()));
  const Field& field =
      Field::ZoneHandle(I, GetField(class_id, field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(instr)) {
    AddReceiverCheck(instr);
  }
  StoreBarrierType needs_store_barrier = kEmitStoreBarrier;
  if (ArgIsAlways(kSmiCid, *instr->ic_data(), 1)) {
    InsertBefore(instr,
                 new(I) CheckSmiInstr(
                     new(I) Value(instr->ArgumentAt(1)),
                     instr->deopt_id(),
                     instr->token_pos()),
                 instr->env(),
                 FlowGraph::kEffect);
    needs_store_barrier = kNoStoreBarrier;
  }

  if (field.guarded_cid() != kDynamicCid) {
    InsertBefore(instr,
                 new(I) GuardFieldClassInstr(
                     new(I) Value(instr->ArgumentAt(1)),
                      field,
                      instr->deopt_id()),
                 instr->env(),
                 FlowGraph::kEffect);
  }

  if (field.needs_length_check()) {
    InsertBefore(instr,
                 new(I) GuardFieldLengthInstr(
                     new(I) Value(instr->ArgumentAt(1)),
                      field,
                      instr->deopt_id()),
                 instr->env(),
                 FlowGraph::kEffect);
  }

  // Field guard was detached.
  StoreInstanceFieldInstr* store = new(I) StoreInstanceFieldInstr(
      field,
      new(I) Value(instr->ArgumentAt(0)),
      new(I) Value(instr->ArgumentAt(1)),
      needs_store_barrier,
      instr->token_pos());

  if (store->IsUnboxedStore()) {
    FlowGraph::AddToGuardedFields(flow_graph_->guarded_fields(), &field);
  }

  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCall(instr, store);
  return true;
}


// Range analysis for smi values.
class RangeAnalysis : public ValueObject {
 public:
  explicit RangeAnalysis(FlowGraph* flow_graph)
      : flow_graph_(flow_graph),
        marked_defns_(NULL) { }

  // Infer ranges for all values and remove overflow checks from binary smi
  // operations when proven redundant.
  void Analyze();

 private:
  // Collect all values that were proven to be smi in smi_values_ array and all
  // CheckSmi instructions in smi_check_ array.
  void CollectValues();

  // Iterate over smi values and constrain them at branch successors.
  // Additionally constraint values after CheckSmi instructions.
  void InsertConstraints();

  // Iterate over uses of the given definition and discover branches that
  // constrain it. Insert appropriate Constraint instructions at true
  // and false successor and rename all dominated uses to refer to a
  // Constraint instead of this definition.
  void InsertConstraintsFor(Definition* defn);

  // Create a constraint for defn, insert it after given instruction and
  // rename all uses that are dominated by it.
  ConstraintInstr* InsertConstraintFor(Definition* defn,
                                       Range* constraint,
                                       Instruction* after);

  void ConstrainValueAfterBranch(Definition* defn, Value* use);
  void ConstrainValueAfterCheckArrayBound(Definition* defn,
                                          CheckArrayBoundInstr* check,
                                          intptr_t use_index);

  // Replace uses of the definition def that are dominated by instruction dom
  // with uses of other definition.
  void RenameDominatedUses(Definition* def,
                           Instruction* dom,
                           Definition* other);


  // Walk the dominator tree and infer ranges for smi values.
  void InferRanges();
  void InferRangesRecursive(BlockEntryInstr* block);

  enum Direction {
    kUnknown,
    kPositive,
    kNegative,
    kBoth
  };

  Range* InferInductionVariableRange(JoinEntryInstr* loop_header,
                                     PhiInstr* var);

  void ResetWorklist();
  void MarkDefinition(Definition* defn);

  static Direction ToDirection(Value* val);

  static Direction Invert(Direction direction) {
    return (direction == kPositive) ? kNegative : kPositive;
  }

  static void UpdateDirection(Direction* direction,
                              Direction new_direction) {
    if (*direction != new_direction) {
      if (*direction != kUnknown) new_direction = kBoth;
      *direction = new_direction;
    }
  }

  // Remove artificial Constraint instructions and replace them with actual
  // unconstrained definitions.
  void RemoveConstraints();

  Range* ConstraintRange(Token::Kind op, Definition* boundary);

  Isolate* isolate() const { return flow_graph_->isolate(); }

  FlowGraph* flow_graph_;

  // Value that are known to be smi or mint.
  GrowableArray<Definition*> values_;
  // All CheckSmi instructions.
  GrowableArray<CheckSmiInstr*> smi_checks_;

  // All Constraints inserted during InsertConstraints phase. They are treated
  // as smi values.
  GrowableArray<ConstraintInstr*> constraints_;

  // Bitvector for a quick filtering of known smi or mint values.
  BitVector* definitions_;

  // Worklist for induction variables analysis.
  GrowableArray<Definition*> worklist_;
  BitVector* marked_defns_;

  DISALLOW_COPY_AND_ASSIGN(RangeAnalysis);
};


void RangeAnalysis::Analyze() {
  CollectValues();
  InsertConstraints();
  InferRanges();
  RemoveConstraints();
}


void RangeAnalysis::CollectValues() {
  const GrowableArray<Definition*>& initial =
      *flow_graph_->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* current = initial[i];
    if (current->Type()->ToCid() == kSmiCid) {
      values_.Add(current);
    } else if (current->IsMintDefinition()) {
      values_.Add(current);
    }
  }

  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();


    if (block->IsGraphEntry() || block->IsCatchBlockEntry()) {
      const GrowableArray<Definition*>& initial = block->IsGraphEntry()
          ? *block->AsGraphEntry()->initial_definitions()
          : *block->AsCatchBlockEntry()->initial_definitions();
      for (intptr_t i = 0; i < initial.length(); ++i) {
        Definition* current = initial[i];
        if (current->Type()->ToCid() == kSmiCid) {
          values_.Add(current);
        } else if (current->IsMintDefinition()) {
          values_.Add(current);
        }
      }
    }

    JoinEntryInstr* join = block->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator phi_it(join); !phi_it.Done(); phi_it.Advance()) {
        PhiInstr* current = phi_it.Current();
        if (current->Type()->ToCid() == kSmiCid) {
          values_.Add(current);
        }
      }
    }

    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* current = instr_it.Current();
      Definition* defn = current->AsDefinition();
      if (defn != NULL) {
        if ((defn->Type()->ToCid() == kSmiCid) &&
            (defn->ssa_temp_index() != -1)) {
          values_.Add(defn);
        } else if ((defn->IsMintDefinition()) &&
                   (defn->ssa_temp_index() != -1)) {
          values_.Add(defn);
        }
      } else if (current->IsCheckSmi()) {
        smi_checks_.Add(current->AsCheckSmi());
      }
    }
  }
}


// Returns true if use is dominated by the given instruction.
// Note: uses that occur at instruction itself are not dominated by it.
static bool IsDominatedUse(Instruction* dom, Value* use) {
  BlockEntryInstr* dom_block = dom->GetBlock();

  Instruction* instr = use->instruction();

  PhiInstr* phi = instr->AsPhi();
  if (phi != NULL) {
    return dom_block->Dominates(phi->block()->PredecessorAt(use->use_index()));
  }

  BlockEntryInstr* use_block = instr->GetBlock();
  if (use_block == dom_block) {
    // Fast path for the case of block entry.
    if (dom_block == dom) return true;

    for (Instruction* curr = dom->next(); curr != NULL; curr = curr->next()) {
      if (curr == instr) return true;
    }

    return false;
  }

  return dom_block->Dominates(use_block);
}


void RangeAnalysis::RenameDominatedUses(Definition* def,
                                        Instruction* dom,
                                        Definition* other) {
  for (Value::Iterator it(def->input_use_list());
       !it.Done();
       it.Advance()) {
    Value* use = it.Current();

    // Skip dead phis.
    PhiInstr* phi = use->instruction()->AsPhi();
    ASSERT((phi == NULL) || phi->is_alive());
    if (IsDominatedUse(dom, use)) {
      use->BindTo(other);
    }
  }
}


// For a comparison operation return an operation for the equivalent flipped
// comparison: a (op) b === b (op') a.
static Token::Kind FlipComparison(Token::Kind op) {
  switch (op) {
    case Token::kEQ: return Token::kEQ;
    case Token::kNE: return Token::kNE;
    case Token::kLT: return Token::kGT;
    case Token::kGT: return Token::kLT;
    case Token::kLTE: return Token::kGTE;
    case Token::kGTE: return Token::kLTE;
    default:
      UNREACHABLE();
      return Token::kILLEGAL;
  }
}


// Given a boundary (right operand) and a comparison operation return
// a symbolic range constraint for the left operand of the comparison assuming
// that it evaluated to true.
// For example for the comparison a < b symbol a is constrained with range
// [Smi::kMinValue, b - 1].
Range* RangeAnalysis::ConstraintRange(Token::Kind op, Definition* boundary) {
  switch (op) {
    case Token::kEQ:
      return new(I) Range(RangeBoundary::FromDefinition(boundary),
                          RangeBoundary::FromDefinition(boundary));
    case Token::kNE:
      return Range::Unknown();
    case Token::kLT:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(boundary, -1));
    case Token::kGT:
      return new(I) Range(RangeBoundary::FromDefinition(boundary, 1),
                          RangeBoundary::MaxSmi());
    case Token::kLTE:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(boundary));
    case Token::kGTE:
      return new(I) Range(RangeBoundary::FromDefinition(boundary),
                          RangeBoundary::MaxSmi());
    default:
      UNREACHABLE();
      return Range::Unknown();
  }
}


ConstraintInstr* RangeAnalysis::InsertConstraintFor(Definition* defn,
                                                    Range* constraint_range,
                                                    Instruction* after) {
  // No need to constrain constants.
  if (defn->IsConstant()) return NULL;

  ConstraintInstr* constraint = new(I) ConstraintInstr(
      new(I) Value(defn), constraint_range);
  flow_graph_->InsertAfter(after, constraint, NULL, FlowGraph::kValue);
  RenameDominatedUses(defn, constraint, constraint);
  constraints_.Add(constraint);
  return constraint;
}


void RangeAnalysis::ConstrainValueAfterBranch(Definition* defn, Value* use) {
  BranchInstr* branch = use->instruction()->AsBranch();
  RelationalOpInstr* rel_op = branch->comparison()->AsRelationalOp();
  if ((rel_op != NULL) && (rel_op->operation_cid() == kSmiCid)) {
    // Found comparison of two smis. Constrain defn at true and false
    // successors using the other operand as a boundary.
    Definition* boundary;
    Token::Kind op_kind;
    if (use->use_index() == 0) {  // Left operand.
      boundary = rel_op->InputAt(1)->definition();
      op_kind = rel_op->kind();
    } else {
      ASSERT(use->use_index() == 1);  // Right operand.
      boundary = rel_op->InputAt(0)->definition();
      // InsertConstraintFor assumes that defn is left operand of a
      // comparison if it is right operand flip the comparison.
      op_kind = FlipComparison(rel_op->kind());
    }

    // Constrain definition at the true successor.
    ConstraintInstr* true_constraint =
        InsertConstraintFor(defn,
                            ConstraintRange(op_kind, boundary),
                            branch->true_successor());
    // Mark true_constraint an artificial use of boundary. This ensures
    // that constraint's range is recalculated if boundary's range changes.
    if (true_constraint != NULL) {
      true_constraint->AddDependency(boundary);
      true_constraint->set_target(branch->true_successor());
    }

    // Constrain definition with a negated condition at the false successor.
    ConstraintInstr* false_constraint =
        InsertConstraintFor(
            defn,
            ConstraintRange(Token::NegateComparison(op_kind), boundary),
            branch->false_successor());
    // Mark false_constraint an artificial use of boundary. This ensures
    // that constraint's range is recalculated if boundary's range changes.
    if (false_constraint != NULL) {
      false_constraint->AddDependency(boundary);
      false_constraint->set_target(branch->false_successor());
    }
  }
}


void RangeAnalysis::InsertConstraintsFor(Definition* defn) {
  for (Value* use = defn->input_use_list();
       use != NULL;
       use = use->next_use()) {
    if (use->instruction()->IsBranch()) {
      ConstrainValueAfterBranch(defn, use);
    } else if (use->instruction()->IsCheckArrayBound()) {
      ConstrainValueAfterCheckArrayBound(
          defn,
          use->instruction()->AsCheckArrayBound(),
          use->use_index());
    }
  }
}


void RangeAnalysis::ConstrainValueAfterCheckArrayBound(
    Definition* defn, CheckArrayBoundInstr* check, intptr_t use_index) {
  Range* constraint_range = NULL;
  if (use_index == CheckArrayBoundInstr::kIndexPos) {
    Definition* length = check->length()->definition();
    constraint_range = new(I) Range(
        RangeBoundary::FromConstant(0),
        RangeBoundary::FromDefinition(length, -1));
  } else {
    ASSERT(use_index == CheckArrayBoundInstr::kLengthPos);
    Definition* index = check->index()->definition();
    constraint_range = new(I) Range(
        RangeBoundary::FromDefinition(index, 1),
        RangeBoundary::MaxSmi());
  }
  InsertConstraintFor(defn, constraint_range, check);
}


void RangeAnalysis::InsertConstraints() {
  for (intptr_t i = 0; i < smi_checks_.length(); i++) {
    CheckSmiInstr* check = smi_checks_[i];
    ConstraintInstr* constraint =
        InsertConstraintFor(check->value()->definition(),
                            Range::UnknownSmi(),
                            check);
    if (constraint == NULL) {
      // No constraint was needed.
      continue;
    }
    // Mark the constraint's value's reaching type as smi.
    CompileType* smi_compile_type =
        ZoneCompileType::Wrap(CompileType::FromCid(kSmiCid));
    constraint->value()->SetReachingType(smi_compile_type);
  }

  for (intptr_t i = 0; i < values_.length(); i++) {
    InsertConstraintsFor(values_[i]);
  }

  for (intptr_t i = 0; i < constraints_.length(); i++) {
    InsertConstraintsFor(constraints_[i]);
  }
}


void RangeAnalysis::ResetWorklist() {
  if (marked_defns_ == NULL) {
    marked_defns_ = new(I) BitVector(flow_graph_->current_ssa_temp_index());
  } else {
    marked_defns_->Clear();
  }
  worklist_.Clear();
}


void RangeAnalysis::MarkDefinition(Definition* defn) {
  // Unwrap constrained value.
  while (defn->IsConstraint()) {
    defn = defn->AsConstraint()->value()->definition();
  }

  if (!marked_defns_->Contains(defn->ssa_temp_index())) {
    worklist_.Add(defn);
    marked_defns_->Add(defn->ssa_temp_index());
  }
}


RangeAnalysis::Direction RangeAnalysis::ToDirection(Value* val) {
  if (val->BindsToConstant()) {
    return (Smi::Cast(val->BoundConstant()).Value() >= 0) ? kPositive
                                                          : kNegative;
  } else if (val->definition()->range() != NULL) {
    Range* range = val->definition()->range();
    if (Range::ConstantMin(range).ConstantValue() >= 0) {
      return kPositive;
    } else if (Range::ConstantMax(range).ConstantValue() <= 0) {
      return kNegative;
    }
  }
  return kUnknown;
}


Range* RangeAnalysis::InferInductionVariableRange(JoinEntryInstr* loop_header,
                                                  PhiInstr* var) {
  BitVector* loop_info = loop_header->loop_info();

  Definition* initial_value = NULL;
  Direction direction = kUnknown;

  ResetWorklist();
  MarkDefinition(var);
  while (!worklist_.is_empty()) {
    Definition* defn = worklist_.RemoveLast();

    if (defn->IsPhi()) {
      PhiInstr* phi = defn->AsPhi();
      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        Definition* defn = phi->InputAt(i)->definition();

        if (!loop_info->Contains(defn->GetBlock()->preorder_number())) {
          // The value is coming from outside of the loop.
          if (initial_value == NULL) {
            initial_value = defn;
            continue;
          } else if (initial_value == defn) {
            continue;
          } else {
            return NULL;
          }
        }

        MarkDefinition(defn);
      }
    } else if (defn->IsBinarySmiOp()) {
      BinarySmiOpInstr* binary_op = defn->AsBinarySmiOp();

      switch (binary_op->op_kind()) {
        case Token::kADD: {
          const Direction growth_right =
              ToDirection(binary_op->right());
          if (growth_right != kUnknown) {
            UpdateDirection(&direction, growth_right);
            MarkDefinition(binary_op->left()->definition());
            break;
          }

          const Direction growth_left =
              ToDirection(binary_op->left());
          if (growth_left != kUnknown) {
            UpdateDirection(&direction, growth_left);
            MarkDefinition(binary_op->right()->definition());
            break;
          }

          return NULL;
        }

        case Token::kSUB: {
          const Direction growth_right =
              ToDirection(binary_op->right());
          if (growth_right != kUnknown) {
            UpdateDirection(&direction, Invert(growth_right));
            MarkDefinition(binary_op->left()->definition());
            break;
          }
          return NULL;
        }

        default:
          return NULL;
      }
    } else {
      return NULL;
    }
  }


  // We transitively discovered all dependencies of the given phi
  // and confirmed that it depends on a single value coming from outside of
  // the loop and some linear combinations of itself.
  // Compute the range based on initial value and the direction of the growth.
  switch (direction) {
    case kPositive:
      return new(I) Range(RangeBoundary::FromDefinition(initial_value),
                          RangeBoundary::MaxSmi());

    case kNegative:
      return new(I) Range(RangeBoundary::MinSmi(),
                          RangeBoundary::FromDefinition(initial_value));

    case kUnknown:
    case kBoth:
      return Range::UnknownSmi();
  }

  UNREACHABLE();
  return NULL;
}


void RangeAnalysis::InferRangesRecursive(BlockEntryInstr* block) {
  JoinEntryInstr* join = block->AsJoinEntry();
  if (join != NULL) {
    const bool is_loop_header = (join->loop_info() != NULL);
    for (PhiIterator it(join); !it.Done(); it.Advance()) {
      PhiInstr* phi = it.Current();
      if (definitions_->Contains(phi->ssa_temp_index())) {
        if (is_loop_header) {
          // Try recognizing simple induction variables.
          Range* range = InferInductionVariableRange(join, phi);
          if (range != NULL) {
            phi->range_ = range;
            continue;
          }
        }

        phi->InferRange();
      }
    }
  }

  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();

    Definition* defn = current->AsDefinition();
    if ((defn != NULL) &&
        (defn->ssa_temp_index() != -1) &&
        definitions_->Contains(defn->ssa_temp_index())) {
      defn->InferRange();
    } else if (FLAG_array_bounds_check_elimination &&
               current->IsCheckArrayBound()) {
      CheckArrayBoundInstr* check = current->AsCheckArrayBound();
      RangeBoundary array_length =
          RangeBoundary::FromDefinition(check->length()->definition());
      if (check->IsRedundant(array_length)) {
        it.RemoveCurrentFromGraph();
      }
    }
  }

  for (intptr_t i = 0; i < block->dominated_blocks().length(); ++i) {
    InferRangesRecursive(block->dominated_blocks()[i]);
  }
}


void RangeAnalysis::InferRanges() {
  if (FLAG_trace_range_analysis) {
    OS::Print("---- before range analysis -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
  // Initialize bitvector for quick filtering of int values.
  definitions_ =
      new(I) BitVector(flow_graph_->current_ssa_temp_index());
  for (intptr_t i = 0; i < values_.length(); i++) {
    definitions_->Add(values_[i]->ssa_temp_index());
  }
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    definitions_->Add(constraints_[i]->ssa_temp_index());
  }

  // Infer initial values of ranges.
  const GrowableArray<Definition*>& initial =
      *flow_graph_->graph_entry()->initial_definitions();
  for (intptr_t i = 0; i < initial.length(); ++i) {
    Definition* definition = initial[i];
    if (definitions_->Contains(definition->ssa_temp_index())) {
      definition->InferRange();
    }
  }
  InferRangesRecursive(flow_graph_->graph_entry());

  if (FLAG_trace_range_analysis) {
    OS::Print("---- after range analysis -------\n");
    FlowGraphPrinter printer(*flow_graph_);
    printer.PrintBlocks();
  }
}


void RangeAnalysis::RemoveConstraints() {
  for (intptr_t i = 0; i < constraints_.length(); i++) {
    Definition* def = constraints_[i]->value()->definition();
    // Some constraints might be constraining constraints. Unwind the chain of
    // constraints until we reach the actual definition.
    while (def->IsConstraint()) {
      def = def->AsConstraint()->value()->definition();
    }
    constraints_[i]->ReplaceUsesWith(def);
    constraints_[i]->RemoveFromGraph();
  }
}


void FlowGraphOptimizer::InferIntRanges() {
  RangeAnalysis range_analysis(flow_graph_);
  range_analysis.Analyze();
}


void TryCatchAnalyzer::Optimize(FlowGraph* flow_graph) {
  // For every catch-block: Iterate over all call instructions inside the
  // corresponding try-block and figure out for each environment value if it
  // is the same constant at all calls. If yes, replace the initial definition
  // at the catch-entry with this constant.
  const GrowableArray<CatchBlockEntryInstr*>& catch_entries =
      flow_graph->graph_entry()->catch_entries();
  intptr_t base = kFirstLocalSlotFromFp + flow_graph->num_non_copied_params();
  for (intptr_t catch_idx = 0;
       catch_idx < catch_entries.length();
       ++catch_idx) {
    CatchBlockEntryInstr* catch_entry = catch_entries[catch_idx];

    // Initialize cdefs with the original initial definitions (ParameterInstr).
    // The following representation is used:
    // ParameterInstr => unknown
    // ConstantInstr => known constant
    // NULL => non-constant
    GrowableArray<Definition*>* idefs = catch_entry->initial_definitions();
    GrowableArray<Definition*> cdefs(idefs->length());
    cdefs.AddArray(*idefs);

    // exception_var and stacktrace_var are never constant.
    intptr_t ex_idx = base - catch_entry->exception_var().index();
    intptr_t st_idx = base - catch_entry->stacktrace_var().index();
    cdefs[ex_idx] = cdefs[st_idx] = NULL;

    for (BlockIterator block_it = flow_graph->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      if (block->try_index() == catch_entry->catch_try_index()) {
        for (ForwardInstructionIterator instr_it(block);
             !instr_it.Done();
             instr_it.Advance()) {
          Instruction* current = instr_it.Current();
          if (current->MayThrow()) {
            Environment* env = current->env();
            ASSERT(env != NULL);
            for (intptr_t env_idx = 0; env_idx < cdefs.length(); ++env_idx) {
              if (cdefs[env_idx] != NULL &&
                  env->ValueAt(env_idx)->BindsToConstant()) {
                cdefs[env_idx] = env->ValueAt(env_idx)->definition();
              }
              if (cdefs[env_idx] != env->ValueAt(env_idx)->definition()) {
                cdefs[env_idx] = NULL;
              }
            }
          }
        }
      }
    }
    for (intptr_t j = 0; j < idefs->length(); ++j) {
      if (cdefs[j] != NULL && cdefs[j]->IsConstant()) {
        // TODO(fschneider): Use constants from the constant pool.
        Definition* old = (*idefs)[j];
        ConstantInstr* orig = cdefs[j]->AsConstant();
        ConstantInstr* copy =
            new(flow_graph->isolate()) ConstantInstr(orig->value());
        copy->set_ssa_temp_index(flow_graph->alloc_ssa_temp_index());
        old->ReplaceUsesWith(copy);
        (*idefs)[j] = copy;
      }
    }
  }
}


static BlockEntryInstr* FindPreHeader(BlockEntryInstr* header) {
  for (intptr_t j = 0; j < header->PredecessorCount(); ++j) {
    BlockEntryInstr* candidate = header->PredecessorAt(j);
    if (header->dominator() == candidate) {
      return candidate;
    }
  }
  return NULL;
}


LICM::LICM(FlowGraph* flow_graph) : flow_graph_(flow_graph) {
  ASSERT(flow_graph->is_licm_allowed());
}


void LICM::Hoist(ForwardInstructionIterator* it,
                 BlockEntryInstr* pre_header,
                 Instruction* current) {
  if (current->IsCheckClass()) {
    current->AsCheckClass()->set_licm_hoisted(true);
  }
  // TODO(fschneider): Avoid repeated deoptimization when
  // speculatively hoisting checks.
  if (FLAG_trace_optimization) {
    OS::Print("Hoisting instruction %s:%" Pd " from B%" Pd " to B%" Pd "\n",
              current->DebugName(),
              current->GetDeoptId(),
              current->GetBlock()->block_id(),
              pre_header->block_id());
  }
  // Move the instruction out of the loop.
  current->RemoveEnvironment();
  it->RemoveCurrentFromGraph();
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  // Using kind kEffect will not assign a fresh ssa temporary index.
  flow_graph()->InsertBefore(last, current, last->env(), FlowGraph::kEffect);
  current->deopt_id_ = last->GetDeoptId();
}


void LICM::TryHoistCheckSmiThroughPhi(ForwardInstructionIterator* it,
                                      BlockEntryInstr* header,
                                      BlockEntryInstr* pre_header,
                                      CheckSmiInstr* current) {
  PhiInstr* phi = current->value()->definition()->AsPhi();
  if (!header->loop_info()->Contains(phi->block()->preorder_number())) {
    return;
  }

  if (phi->Type()->ToCid() == kSmiCid) {
    it->RemoveCurrentFromGraph();
    return;
  }

  // Check if there is only a single kDynamicCid input to the phi that
  // comes from the pre-header.
  const intptr_t kNotFound = -1;
  intptr_t non_smi_input = kNotFound;
  for (intptr_t i = 0; i < phi->InputCount(); ++i) {
    Value* input = phi->InputAt(i);
    if (input->Type()->ToCid() != kSmiCid) {
      if ((non_smi_input != kNotFound) ||
          (input->Type()->ToCid() != kDynamicCid)) {
        // There are multiple kDynamicCid inputs or there is an input that is
        // known to be non-smi.
        return;
      } else {
        non_smi_input = i;
      }
    }
  }

  if ((non_smi_input == kNotFound) ||
      (phi->block()->PredecessorAt(non_smi_input) != pre_header)) {
    return;
  }

  // Host CheckSmi instruction and make this phi smi one.
  Hoist(it, pre_header, current);

  // Replace value we are checking with phi's input.
  current->value()->BindTo(phi->InputAt(non_smi_input)->definition());

  phi->UpdateType(CompileType::FromCid(kSmiCid));
}


// Load instructions handled by load elimination.
static bool IsLoadEliminationCandidate(Instruction* instr) {
  return instr->IsLoadField()
      || instr->IsLoadIndexed()
      || instr->IsLoadStaticField()
      || instr->IsCurrentContext();
}


static bool IsLoopInvariantLoad(ZoneGrowableArray<BitVector*>* sets,
                                intptr_t loop_header_index,
                                Instruction* instr) {
  return IsLoadEliminationCandidate(instr) &&
      (sets != NULL) &&
      instr->HasPlaceId() &&
      ((*sets)[loop_header_index] != NULL) &&
      (*sets)[loop_header_index]->Contains(instr->place_id());
}


void LICM::Optimize() {
  if (!flow_graph()->parsed_function().function().
          allows_hoisting_check_class()) {
    // Do not hoist any.
    return;
  }

  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      flow_graph()->loop_headers();

  ZoneGrowableArray<BitVector*>* loop_invariant_loads =
      flow_graph()->loop_invariant_loads();

  BlockEffects* block_effects = flow_graph()->block_effects();

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    BlockEntryInstr* header = loop_headers[i];
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = FindPreHeader(header);
    if (pre_header == NULL) continue;

    for (BitVector::Iterator loop_it(header->loop_info());
         !loop_it.Done();
         loop_it.Advance()) {
      BlockEntryInstr* block = flow_graph()->preorder()[loop_it.Current()];
      for (ForwardInstructionIterator it(block);
           !it.Done();
           it.Advance()) {
        Instruction* current = it.Current();
        if ((current->AllowsCSE() &&
             block_effects->CanBeMovedTo(current, pre_header)) ||
            IsLoopInvariantLoad(loop_invariant_loads, i, current)) {
          bool inputs_loop_invariant = true;
          for (int i = 0; i < current->InputCount(); ++i) {
            Definition* input_def = current->InputAt(i)->definition();
            if (!input_def->GetBlock()->Dominates(pre_header)) {
              inputs_loop_invariant = false;
              break;
            }
          }
          if (inputs_loop_invariant &&
              !current->IsAssertAssignable() &&
              !current->IsAssertBoolean()) {
            // TODO(fschneider): Enable hoisting of Assert-instructions
            // if it safe to do.
            Hoist(&it, pre_header, current);
          } else if (current->IsCheckSmi() &&
                     current->InputAt(0)->definition()->IsPhi()) {
            TryHoistCheckSmiThroughPhi(
                &it, header, pre_header, current->AsCheckSmi());
          }
        }
      }
    }
  }
}


// Alias represents a family of locations. It is used to capture aliasing
// between stores and loads. Store can alias another load or store if and only
// if they have the same alias.
class Alias : public ValueObject {
 public:
  Alias(const Alias& other) : ValueObject(), alias_(other.alias_) { }

  // All indexed load/stores alias each other.
  // TODO(vegorov): incorporate type of array into alias to disambiguate
  // different typed data and normal arrays.
  static Alias UnknownIndex(intptr_t id) {
    return Alias(kUnknownIndexAlias, id);
  }

  static Alias ConstantIndex(intptr_t id) {
    ASSERT(id != 0);
    return Alias(kConstantIndex, id);
  }

  // Field load/stores alias each other only when they access the same field.
  // AliasedSet assigns ids to a combination of instance and field during
  // the optimization phase.
  static Alias Field(intptr_t id) {
    ASSERT(id != 0);
    return Alias(kFieldAlias, id);
  }

  // VMField load/stores alias each other when field offset matches.
  // TODO(vegorov) storing a context variable does not alias loading array
  // length.
  static Alias VMField(intptr_t id) {
    ASSERT(id != 0);
    return Alias(kVMFieldAlias, id);
  }

  // Current context load/stores alias each other.
  static Alias CurrentContext() {
    return Alias(kCurrentContextAlias, 0);
  }

  // Operation does not alias anything.
  static Alias None() {
    return Alias(kNoneAlias);
  }

  bool IsNone() const {
    return alias_ == kNoneAlias;
  }

  // Convert this alias to a positive array index.
  intptr_t ToIndex() const {
    ASSERT(!IsNone());
    return alias_;
  }

 private:
  enum {
    // Number of bits required to encode Kind value.
    // The payload occupies the rest of the bits, but leaves the MSB (sign bit)
    // empty so that the resulting encoded value is always a positive integer.
    kBitsForKind = 3,
    kBitsForPayload = kWordSize * kBitsPerByte - kBitsForKind - 1,
  };

  enum Kind {
    kNoneAlias = -1,
    kCurrentContextAlias = 0,
    kUnknownIndexAlias = 1,
    kFieldAlias = 2,
    kVMFieldAlias = 3,
    kConstantIndex = 4,
    kNumKinds = kConstantIndex + 1
  };
  COMPILE_ASSERT(kNumKinds < ((1 << kBitsForKind) - 1));

  explicit Alias(intptr_t alias) : alias_(alias) { }

  Alias(Kind kind, uword payload)
      : alias_(KindField::encode(kind) | PayloadField::encode(payload)) { }

  uword payload() const {
    return PayloadField::decode(alias_);
  }

  Kind kind() const {
    return IsNone() ? kNoneAlias : KindField::decode(alias_);
  }

  typedef BitField<Kind, 0, kBitsForKind> KindField;
  typedef BitField<uword, kBitsForKind, kBitsForPayload> PayloadField;

  const intptr_t alias_;
};


// Place describes an abstract location (e.g. field) that IR can load
// from or store to.
class Place : public ValueObject {
 public:
  enum Kind {
    kNone,

    // Field location. For instance fields is represented as a pair of a Field
    // object and an instance (SSA definition) that is being accessed.
    // For static fields instance is NULL.
    kField,

    // VMField location. Represented as a pair of an instance (SSA definition)
    // being accessed and offset to the field.
    kVMField,

    // Indexed location.
    kIndexed,

    // Current context.
    kContext
  };

  Place(const Place& other)
      : ValueObject(),
        kind_(other.kind_),
        representation_(other.representation_),
        instance_(other.instance_),
        raw_selector_(other.raw_selector_),
        id_(other.id_) {
  }

  // Construct a place from instruction if instruction accesses any place.
  // Otherwise constructs kNone place.
  Place(Instruction* instr, bool* is_load, bool* is_store)
      : kind_(kNone),
        representation_(kNoRepresentation),
        instance_(NULL),
        raw_selector_(0),
        id_(0) {
    switch (instr->tag()) {
      case Instruction::kLoadField: {
        LoadFieldInstr* load_field = instr->AsLoadField();
        representation_ = load_field->representation();
        instance_ = load_field->instance()->definition()->OriginalDefinition();
        if (load_field->field() != NULL) {
          kind_ = kField;
          field_ = load_field->field();
        } else {
          kind_ = kVMField;
          offset_in_bytes_ = load_field->offset_in_bytes();
        }
        *is_load = true;
        break;
      }

      case Instruction::kStoreInstanceField: {
        StoreInstanceFieldInstr* store =
            instr->AsStoreInstanceField();
        representation_ = store->RequiredInputRepresentation(
            StoreInstanceFieldInstr::kValuePos);
        instance_ = store->instance()->definition()->OriginalDefinition();
        if (!store->field().IsNull()) {
          kind_ = kField;
          field_ = &store->field();
        } else {
          kind_ = kVMField;
          offset_in_bytes_ = store->offset_in_bytes();
        }
        *is_store = true;
        break;
      }

      case Instruction::kLoadStaticField:
        kind_ = kField;
        representation_ = instr->AsLoadStaticField()->representation();
        field_ = &instr->AsLoadStaticField()->StaticField();
        *is_load = true;
        break;

      case Instruction::kStoreStaticField:
        kind_ = kField;
        representation_ = instr->AsStoreStaticField()->
            RequiredInputRepresentation(StoreStaticFieldInstr::kValuePos);
        field_ = &instr->AsStoreStaticField()->field();
        *is_store = true;
        break;

      case Instruction::kLoadIndexed: {
        LoadIndexedInstr* load_indexed = instr->AsLoadIndexed();
        kind_ = kIndexed;
        representation_ = load_indexed->representation();
        instance_ = load_indexed->array()->definition()->OriginalDefinition();
        index_ = load_indexed->index()->definition();
        *is_load = true;
        break;
      }

      case Instruction::kStoreIndexed: {
        StoreIndexedInstr* store_indexed = instr->AsStoreIndexed();
        kind_ = kIndexed;
        representation_ = store_indexed->
            RequiredInputRepresentation(StoreIndexedInstr::kValuePos);
        instance_ = store_indexed->array()->definition()->OriginalDefinition();
        index_ = store_indexed->index()->definition();
        *is_store = true;
        break;
      }

      case Instruction::kCurrentContext:
        kind_ = kContext;
        ASSERT(instr->AsCurrentContext()->representation() == kTagged);
        representation_ = kTagged;
        *is_load = true;
        break;

      case Instruction::kStoreContext:
        kind_ = kContext;
        ASSERT(instr->AsStoreContext()->RequiredInputRepresentation(
            StoreContextInstr::kValuePos) == kTagged);
        representation_ = kTagged;
        *is_store = true;
        break;

      default:
        break;
    }
  }

  intptr_t id() const { return id_; }
  void set_id(intptr_t id) { id_ = id; }

  Kind kind() const { return kind_; }

  Representation representation() const { return representation_; }

  Definition* instance() const {
    ASSERT((kind_ == kField) || (kind_ == kVMField) || (kind_ == kIndexed));
    return instance_;
  }

  void set_instance(Definition* def) {
    ASSERT((kind_ == kField) || (kind_ == kVMField) || (kind_ == kIndexed));
    instance_ = def->OriginalDefinition();
  }

  const Field& field() const {
    ASSERT(kind_ == kField);
    return *field_;
  }

  intptr_t offset_in_bytes() const {
    ASSERT(kind_ == kVMField);
    return offset_in_bytes_;
  }

  Definition* index() const {
    ASSERT(kind_ == kIndexed);
    return index_;
  }

  const char* ToCString() const {
    switch (kind_) {
      case kNone:
        return "<none>";

      case kField: {
        const char* field_name = String::Handle(field().name()).ToCString();
        if (instance() == NULL) {
          return field_name;
        }
        return Isolate::Current()->current_zone()->PrintToString(
            "<v%" Pd ".%s>", instance()->ssa_temp_index(), field_name);
      }

      case kVMField: {
        return Isolate::Current()->current_zone()->PrintToString(
            "<v%" Pd "@%" Pd ">",
            instance()->ssa_temp_index(), offset_in_bytes());
      }

      case kIndexed: {
        return Isolate::Current()->current_zone()->PrintToString(
            "<v%" Pd "[v%" Pd "]>",
            instance()->ssa_temp_index(),
            index()->ssa_temp_index());
      }

      case kContext:
        return "<context>";
    }
    UNREACHABLE();
    return "<?>";
  }

  bool IsFinalField() const {
    return (kind() == kField) && field().is_final();
  }

  intptr_t Hashcode() const {
    return (kind_ * 63 + reinterpret_cast<intptr_t>(instance_)) * 31 +
        representation_ * 15 + FieldHashcode();
  }

  bool Equals(Place* other) const {
    return (kind_ == other->kind_) &&
        (representation_ == other->representation_) &&
        (instance_ == other->instance_) &&
        SameField(other);
  }

  // Create a zone allocated copy of this place.
  static Place* Wrap(Isolate* isolate, const Place& place);

 private:
  bool SameField(Place* other) const {
    return (kind_ == kField) ? (field().raw() == other->field().raw())
                             : (offset_in_bytes_ == other->offset_in_bytes_);
  }

  intptr_t FieldHashcode() const {
    return (kind_ == kField) ? reinterpret_cast<intptr_t>(field().raw())
                             : offset_in_bytes_;
  }

  Kind kind_;
  Representation representation_;
  Definition* instance_;
  union {
    intptr_t raw_selector_;
    const Field* field_;
    intptr_t offset_in_bytes_;
    Definition* index_;
  };

  intptr_t id_;
};


class ZonePlace : public ZoneAllocated {
 public:
  explicit ZonePlace(const Place& place) : place_(place) { }

  Place* place() { return &place_; }

 private:
  Place place_;
};


Place* Place::Wrap(Isolate* isolate, const Place& place) {
  return (new(isolate) ZonePlace(place))->place();
}


// Correspondence between places connected through outgoing phi moves on the
// edge that targets join.
class PhiPlaceMoves : public ZoneAllocated {
 public:
  // Record a move from the place with id |from| to the place with id |to| at
  // the given block.
  void CreateOutgoingMove(Isolate* isolate,
                          BlockEntryInstr* block, intptr_t from, intptr_t to) {
    const intptr_t block_num = block->preorder_number();
    while (moves_.length() <= block_num) {
      moves_.Add(NULL);
    }

    if (moves_[block_num] == NULL) {
      moves_[block_num] = new(isolate) ZoneGrowableArray<Move>(5);
    }

    moves_[block_num]->Add(Move(from, to));
  }

  class Move {
   public:
    Move(intptr_t from, intptr_t to) : from_(from), to_(to) { }

    intptr_t from() const { return from_; }
    intptr_t to() const { return to_; }

   private:
    intptr_t from_;
    intptr_t to_;
  };

  typedef const ZoneGrowableArray<Move>* MovesList;

  MovesList GetOutgoingMoves(BlockEntryInstr* block) const {
    const intptr_t block_num = block->preorder_number();
    return (block_num < moves_.length()) ?
        moves_[block_num] : NULL;
  }

 private:
  GrowableArray<ZoneGrowableArray<Move>* > moves_;
};


// A map from aliases to a set of places sharing the alias. Additionally
// carries a set of places that can be aliased by side-effects, essentially
// those that are affected by calls.
class AliasedSet : public ZoneAllocated {
 public:
  AliasedSet(Isolate* isolate,
             ZoneGrowableArray<Place*>* places,
             PhiPlaceMoves* phi_moves)
      : isolate_(isolate),
        places_(*places),
        phi_moves_(phi_moves),
        sets_(),
        aliased_by_effects_(new(isolate) BitVector(places->length())),
        max_field_id_(0),
        field_ids_(),
        max_index_id_(0),
        index_ids_(),
        max_unknown_index_id_(0),
        unknown_index_ids_(),
        max_vm_field_id_(0),
        vm_field_ids_() { }

  Alias ComputeAlias(Place* place) {
    switch (place->kind()) {
      case Place::kIndexed:
        if (place->index()->IsConstant()) {
          const Object& index = place->index()->AsConstant()->value();
          if (index.IsSmi()) {
            return Alias::ConstantIndex(
                GetInstanceIndexId(place->instance(),
                                   Smi::Cast(index).Value()));
          }
        }
        return Alias::UnknownIndex(GetUnknownIndexId(place->instance()));
      case Place::kField:
        return Alias::Field(
            GetInstanceFieldId(place->instance(), place->field()));
      case Place::kVMField:
        return Alias::VMField(
            GetInstanceVMFieldId(place->instance(), place->offset_in_bytes()));
      case Place::kContext:
        return Alias::CurrentContext();
      case Place::kNone:
        UNREACHABLE();
    }

    UNREACHABLE();
    return Alias::None();
  }

  Alias ComputeAliasForStore(Instruction* instr) {
    StoreIndexedInstr* store_indexed = instr->AsStoreIndexed();
    if (store_indexed != NULL) {
      Definition* instance = store_indexed->array()->definition();
      if (store_indexed->index()->definition()->IsConstant()) {
        const Object& index =
            store_indexed->index()->definition()->AsConstant()->value();
        if (index.IsSmi()) {
          return Alias::ConstantIndex(
              GetInstanceIndexId(instance, Smi::Cast(index).Value()));
        }
      }
      return Alias::UnknownIndex(GetUnknownIndexId(instance));
    }

    StoreInstanceFieldInstr* store_instance_field =
        instr->AsStoreInstanceField();
    if (store_instance_field != NULL) {
      Definition* instance = store_instance_field->instance()->definition();
      if (!store_instance_field->field().IsNull()) {
        return Alias::Field(
            GetInstanceFieldId(instance, store_instance_field->field()));
      }
      return Alias::VMField(
          GetInstanceVMFieldId(instance,
                               store_instance_field->offset_in_bytes()));
    }

    if (instr->IsStoreContext()) {
      return Alias::CurrentContext();
    }

    StoreStaticFieldInstr* store_static_field = instr->AsStoreStaticField();
    if (store_static_field != NULL) {
      return Alias::Field(GetStaticFieldId(store_static_field->field()));
    }

    return Alias::None();
  }

  BitVector* Get(const Alias alias) {
    const intptr_t idx = alias.ToIndex();
    BitVector* ret = (idx < sets_.length()) ? sets_[idx] : NULL;
    return ret;
  }

  void AddRepresentative(Place* place) {
    if (!place->IsFinalField()) {
      AddIdForAlias(ComputeAlias(place), place->id());
      if (!IsIndependentFromEffects(place)) {
        aliased_by_effects_->Add(place->id());
      }
    }
  }

  void EnsureAliasingForUnknownIndices() {
    // Ids start at 1 because the hash-map uses 0 for element not found.
    for (intptr_t unknown_index_id = 1;
         unknown_index_id <= max_unknown_index_id_;
         unknown_index_id++) {
      BitVector* unknown_index = Get(Alias::UnknownIndex(unknown_index_id));
      if (unknown_index == NULL) {
        return;
      }

      // Constant indexes alias all non-constant indexes.
      // Non-constant indexes alias all constant indexes.
      // First update alias set for const-indices, then
      // update set for all indices. Ids start at 1.
      for (intptr_t id = 1; id <= max_index_id_; id++) {
        BitVector* const_indexes = Get(Alias::ConstantIndex(id));
        if (const_indexes != NULL) {
          const_indexes->AddAll(unknown_index);
        }
      }

      for (intptr_t id = 1; id <= max_index_id_; id++) {
        BitVector* const_indexes = Get(Alias::ConstantIndex(id));
        if (const_indexes != NULL) {
          unknown_index->AddAll(const_indexes);
        }
      }
    }
  }

  void AddIdForAlias(const Alias alias, intptr_t place_id) {
    const intptr_t idx = alias.ToIndex();
    while (sets_.length() <= idx) {
      sets_.Add(NULL);
    }

    if (sets_[idx] == NULL) {
      sets_[idx] = new(isolate_) BitVector(max_place_id());
    }

    sets_[idx]->Add(place_id);
  }

  intptr_t max_place_id() const { return places().length(); }
  bool IsEmpty() const { return max_place_id() == 0; }

  BitVector* aliased_by_effects() const { return aliased_by_effects_; }

  const ZoneGrowableArray<Place*>& places() const {
    return places_;
  }

  void PrintSet(BitVector* set) {
    bool comma = false;
    for (BitVector::Iterator it(set);
         !it.Done();
         it.Advance()) {
      if (comma) {
        OS::Print(", ");
      }
      OS::Print("%s", places_[it.Current()]->ToCString());
      comma = true;
    }
  }

  const PhiPlaceMoves* phi_moves() const { return phi_moves_; }

  // Returns true if the result of an allocation instruction can be aliased by
  // some other SSA variable and false otherwise. Currently simply checks if
  // this value is stored in a field, escapes to another function or
  // participates in a phi.
  static bool CanBeAliased(Definition* alloc) {
    ASSERT(alloc->IsAllocateObject() ||
           alloc->IsCreateArray() ||
           (alloc->IsStaticCall() &&
            alloc->AsStaticCall()->IsRecognizedFactory()));
    if (alloc->Identity() == kIdentityUnknown) {
      bool escapes = false;
      for (Value* use = alloc->input_use_list();
           use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        if (instr->IsPushArgument() ||
            (instr->IsStoreInstanceField()
             && (use->use_index() != StoreInstanceFieldInstr::kInstancePos)) ||
            (instr->IsStoreIndexed()
             && (use->use_index() == StoreIndexedInstr::kValuePos)) ||
            instr->IsStoreStaticField() ||
            instr->IsPhi() ||
            instr->IsAssertAssignable() ||
            instr->IsRedefinition()) {
          escapes = true;
          break;
        }
      }

      alloc->SetIdentity(escapes ? kIdentityAliased : kIdentityNotAliased);
    }

    return alloc->Identity() != kIdentityNotAliased;
  }

 private:
  // Get id assigned to the given field. Assign a new id if the field is seen
  // for the first time.
  intptr_t GetFieldId(intptr_t instance_id, const Field& field) {
    intptr_t id = field_ids_.Lookup(FieldIdPair::Key(instance_id, &field));
    if (id == 0) {
      id = ++max_field_id_;
      field_ids_.Insert(FieldIdPair(FieldIdPair::Key(instance_id, &field), id));
    }
    return id;
  }

  intptr_t GetIndexId(intptr_t instance_id, intptr_t index) {
    intptr_t id = index_ids_.Lookup(
        ConstantIndexIdPair::Key(instance_id, index));
    if (id == 0) {
      // Zero is used to indicate element not found. The first id is one.
      id = ++max_index_id_;
      index_ids_.Insert(ConstantIndexIdPair(
          ConstantIndexIdPair::Key(instance_id, index), id));
    }
    return id;
  }

  enum {
    kAnyInstance = -1
  };

  // Get or create an identifier for an instance field belonging to the
  // given instance.
  // The space of identifiers assigned to instance fields is split into
  // parts based on the instance that contains the field.
  // If compiler can prove that instance has a single SSA name in the compiled
  // function then we use that SSA name to distinguish fields of this object
  // from the same fields in other objects.
  // If multiple SSA names can point to the same object then we use
  // kAnyInstance instead of a concrete SSA name.
  intptr_t GetInstanceFieldId(Definition* defn, const Field& field) {
    ASSERT(field.is_static() == (defn == NULL));

    intptr_t instance_id = kAnyInstance;

    if (defn != NULL) {
      AllocateObjectInstr* alloc = defn->AsAllocateObject();
      if ((alloc != NULL) && !CanBeAliased(alloc)) {
        instance_id = alloc->ssa_temp_index();
        ASSERT(instance_id != kAnyInstance);
      }
    }

    return GetFieldId(instance_id, field);
  }

  intptr_t GetInstanceVMFieldId(Definition* defn, intptr_t offset) {
    intptr_t instance_id = kAnyInstance;

    ASSERT(defn != NULL);
    if ((defn->IsAllocateObject() ||
         defn->IsCreateArray() ||
         (defn->IsStaticCall() &&
          defn->AsStaticCall()->IsRecognizedFactory())) &&
        !CanBeAliased(defn)) {
      instance_id = defn->ssa_temp_index();
      ASSERT(instance_id != kAnyInstance);
    }

    intptr_t id = vm_field_ids_.Lookup(VMFieldIdPair::Key(instance_id, offset));
    if (id == 0) {
      id = ++max_vm_field_id_;
      vm_field_ids_.Insert(
          VMFieldIdPair(VMFieldIdPair::Key(instance_id, offset), id));
    }
    return id;
  }

  intptr_t GetInstanceIndexId(Definition* defn, intptr_t index) {
    intptr_t instance_id = kAnyInstance;

    ASSERT(defn != NULL);
    if ((defn->IsCreateArray() ||
         (defn->IsStaticCall() &&
          defn->AsStaticCall()->IsRecognizedFactory())) &&
        !CanBeAliased(defn)) {
      instance_id = defn->ssa_temp_index();
      ASSERT(instance_id != kAnyInstance);
    }

    return GetIndexId(instance_id, index);
  }

  intptr_t GetUnknownIndexId(Definition* defn) {
    intptr_t instance_id = kAnyInstance;

    ASSERT(defn != NULL);
    if ((defn->IsCreateArray() ||
         (defn->IsStaticCall() &&
          defn->AsStaticCall()->IsRecognizedFactory())) &&
        !CanBeAliased(defn)) {
      instance_id = defn->ssa_temp_index();
      ASSERT(instance_id != kAnyInstance);
    }

    intptr_t id = unknown_index_ids_.Lookup(
        UnknownIndexIdPair::Key(instance_id));
    if (id == 0) {
      // Zero is used to indicate element not found. The first id is one.
      id = ++max_unknown_index_id_;
      unknown_index_ids_.Insert(
          UnknownIndexIdPair(UnknownIndexIdPair::Key(instance_id), id));
    }
    return id;
  }

  // Get or create an identifier for a static field.
  intptr_t GetStaticFieldId(const Field& field) {
    ASSERT(field.is_static());
    return GetFieldId(kAnyInstance, field);
  }

  // Returns true if the given load is unaffected by external side-effects.
  // This essentially means that no stores to the same location can
  // occur in other functions.
  bool IsIndependentFromEffects(Place* place) {
    if (place->IsFinalField()) {
      // Note that we can't use LoadField's is_immutable attribute here because
      // some VM-fields (those that have no corresponding Field object and
      // accessed through offset alone) can share offset but have different
      // immutability properties.
      // One example is the length property of growable and fixed size list. If
      // loads of these two properties occur in the same function for the same
      // receiver then they will get the same expression number. However
      // immutability of the length of fixed size list does not mean that
      // growable list also has immutable property. Thus we will make a
      // conservative assumption for the VM-properties.
      // TODO(vegorov): disambiguate immutable and non-immutable VM-fields with
      // the same offset e.g. through recognized kind.
      return true;
    }

    if (((place->kind() == Place::kField) ||
         (place->kind() == Place::kVMField)) &&
        (place->instance() != NULL)) {
      AllocateObjectInstr* alloc = place->instance()->AsAllocateObject();
      return (alloc != NULL) && !CanBeAliased(alloc);
    }

    return false;
  }

  class FieldIdPair {
   public:
    struct Key {
      Key(intptr_t instance_id, const Field* field)
          : instance_id_(instance_id), field_(field) { }

      intptr_t instance_id_;
      const Field* field_;
    };

    typedef intptr_t Value;
    typedef FieldIdPair Pair;

    FieldIdPair(Key key, Value value) : key_(key), value_(value) { }

    static Key KeyOf(Pair kv) {
      return kv.key_;
    }

    static Value ValueOf(Pair kv) {
      return kv.value_;
    }

    static intptr_t Hashcode(Key key) {
      return String::Handle(key.field_->name()).Hash();
    }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return (KeyOf(kv).field_->raw() == key.field_->raw()) &&
          (KeyOf(kv).instance_id_ == key.instance_id_);
    }

   private:
    Key key_;
    Value value_;
  };

  class ConstantIndexIdPair {
   public:
    struct Key {
      Key(intptr_t instance_id, intptr_t index)
          : instance_id_(instance_id), index_(index) { }

      intptr_t instance_id_;
      intptr_t index_;
    };
    typedef intptr_t Value;
    typedef ConstantIndexIdPair Pair;

    ConstantIndexIdPair(Key key, Value value) : key_(key), value_(value) { }

    static Key KeyOf(ConstantIndexIdPair kv) {
      return kv.key_;
    }

    static Value ValueOf(ConstantIndexIdPair kv) {
      return kv.value_;
    }

    static intptr_t Hashcode(Key key) {
      return (key.instance_id_ + 1) * 1024 + key.index_;
    }

    static inline bool IsKeyEqual(ConstantIndexIdPair kv, Key key) {
      return (KeyOf(kv).index_ == key.index_)
          && (KeyOf(kv).instance_id_ == key.instance_id_);
    }

   private:
    Key key_;
    Value value_;
  };

  class UnknownIndexIdPair {
   public:
    typedef intptr_t Key;
    typedef intptr_t Value;
    typedef UnknownIndexIdPair Pair;

    UnknownIndexIdPair(Key key, Value value) : key_(key), value_(value) { }

    static Key KeyOf(UnknownIndexIdPair kv) {
      return kv.key_;
    }

    static Value ValueOf(UnknownIndexIdPair kv) {
      return kv.value_;
    }

    static intptr_t Hashcode(Key key) {
      return key + 1;
    }

    static inline bool IsKeyEqual(UnknownIndexIdPair kv, Key key) {
      return KeyOf(kv) == key;
    }

   private:
    Key key_;
    Value value_;
  };

  class VMFieldIdPair {
   public:
    struct Key {
      Key(intptr_t instance_id, intptr_t offset)
          : instance_id_(instance_id), offset_(offset) { }

      intptr_t instance_id_;
      intptr_t offset_;
    };

    typedef intptr_t Value;
    typedef VMFieldIdPair Pair;

    VMFieldIdPair(Key key, Value value) : key_(key), value_(value) { }

    static Key KeyOf(Pair kv) {
      return kv.key_;
    }

    static Value ValueOf(Pair kv) {
      return kv.value_;
    }

    static intptr_t Hashcode(Key key) {
      return (key.instance_id_ + 1) * 1024 + key.offset_;
    }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return (KeyOf(kv).offset_ == key.offset_) &&
          (KeyOf(kv).instance_id_ == key.instance_id_);
    }

   private:
    Key key_;
    Value value_;
  };

  Isolate* isolate_;

  const ZoneGrowableArray<Place*>& places_;

  const PhiPlaceMoves* phi_moves_;

  // Maps alias index to a set of ssa indexes corresponding to loads with the
  // given alias.
  GrowableArray<BitVector*> sets_;

  BitVector* aliased_by_effects_;

  // Table mapping static field to their id used during optimization pass.
  intptr_t max_field_id_;
  DirectChainedHashMap<FieldIdPair> field_ids_;

  intptr_t max_index_id_;
  DirectChainedHashMap<ConstantIndexIdPair> index_ids_;

  intptr_t max_unknown_index_id_;
  DirectChainedHashMap<UnknownIndexIdPair> unknown_index_ids_;

  intptr_t max_vm_field_id_;
  DirectChainedHashMap<VMFieldIdPair> vm_field_ids_;
};


static Definition* GetStoredValue(Instruction* instr) {
  if (instr->IsStoreIndexed()) {
    return instr->AsStoreIndexed()->value()->definition();
  }

  StoreInstanceFieldInstr* store_instance_field = instr->AsStoreInstanceField();
  if (store_instance_field != NULL) {
    return store_instance_field->value()->definition();
  }

  StoreStaticFieldInstr* store_static_field = instr->AsStoreStaticField();
  if (store_static_field != NULL) {
    return store_static_field->value()->definition();
  }

  if (instr->IsStoreContext()) {
    return instr->InputAt(0)->definition();
  }

  UNREACHABLE();  // Should only be called for supported store instructions.
  return NULL;
}


static bool IsPhiDependentPlace(Place* place) {
  return ((place->kind() == Place::kField) ||
          (place->kind() == Place::kVMField)) &&
        (place->instance() != NULL) &&
        place->instance()->IsPhi();
}


// For each place that depends on a phi ensure that equivalent places
// corresponding to phi input are numbered and record outgoing phi moves
// for each block which establish correspondence between phi dependent place
// and phi input's place that is flowing in.
static PhiPlaceMoves* ComputePhiMoves(
    DirectChainedHashMap<PointerKeyValueTrait<Place> >* map,
    ZoneGrowableArray<Place*>* places) {
  Isolate* isolate = Isolate::Current();
  PhiPlaceMoves* phi_moves = new(isolate) PhiPlaceMoves();

  for (intptr_t i = 0; i < places->length(); i++) {
    Place* place = (*places)[i];

    if (IsPhiDependentPlace(place)) {
      PhiInstr* phi = place->instance()->AsPhi();
      BlockEntryInstr* block = phi->GetBlock();

      if (FLAG_trace_optimization) {
        OS::Print("phi dependent place %s\n", place->ToCString());
      }

      Place input_place(*place);
      for (intptr_t j = 0; j < phi->InputCount(); j++) {
        input_place.set_instance(phi->InputAt(j)->definition());

        Place* result = map->Lookup(&input_place);
        if (result == NULL) {
          input_place.set_id(places->length());
          result = Place::Wrap(isolate, input_place);
          map->Insert(result);
          places->Add(result);
          if (FLAG_trace_optimization) {
            OS::Print("  adding place %s as %" Pd "\n",
                      result->ToCString(),
                      result->id());
          }
        }
        phi_moves->CreateOutgoingMove(isolate,
                                      block->PredecessorAt(j),
                                      result->id(),
                                      place->id());
      }
    }
  }

  return phi_moves;
}


enum CSEMode {
  kOptimizeLoads,
  kOptimizeStores
};


static AliasedSet* NumberPlaces(
    FlowGraph* graph,
    DirectChainedHashMap<PointerKeyValueTrait<Place> >* map,
    CSEMode mode) {
  // Loads representing different expression ids will be collected and
  // used to build per offset kill sets.
  Isolate* isolate = graph->isolate();
  ZoneGrowableArray<Place*>* places =
      new(isolate) ZoneGrowableArray<Place*>(10);

  bool has_loads = false;
  bool has_stores = false;
  for (BlockIterator it = graph->reverse_postorder_iterator();
       !it.Done();
       it.Advance()) {
    BlockEntryInstr* block = it.Current();
    for (ForwardInstructionIterator instr_it(block);
         !instr_it.Done();
         instr_it.Advance()) {
      Instruction* instr = instr_it.Current();
      Place place(instr, &has_loads, &has_stores);
      if (place.kind() == Place::kNone) {
        continue;
      }

      Place* result = map->Lookup(&place);
      if (result == NULL) {
        place.set_id(places->length());
        result = Place::Wrap(isolate, place);
        map->Insert(result);
        places->Add(result);

        if (FLAG_trace_optimization) {
          OS::Print("numbering %s as %" Pd "\n",
                    result->ToCString(),
                    result->id());
        }
      }

      instr->set_place_id(result->id());
    }
  }

  if ((mode == kOptimizeLoads) && !has_loads) {
    return NULL;
  }
  if ((mode == kOptimizeStores) && !has_stores) {
    return NULL;
  }

  PhiPlaceMoves* phi_moves = ComputePhiMoves(map, places);

  // Build aliasing sets mapping aliases to loads.
  AliasedSet* aliased_set = new(isolate) AliasedSet(isolate, places, phi_moves);
  for (intptr_t i = 0; i < places->length(); i++) {
    Place* place = (*places)[i];
    aliased_set->AddRepresentative(place);
  }

  aliased_set->EnsureAliasingForUnknownIndices();

  return aliased_set;
}


class LoadOptimizer : public ValueObject {
 public:
  LoadOptimizer(FlowGraph* graph,
                AliasedSet* aliased_set,
                DirectChainedHashMap<PointerKeyValueTrait<Place> >* map)
      : graph_(graph),
        map_(map),
        aliased_set_(aliased_set),
        in_(graph_->preorder().length()),
        out_(graph_->preorder().length()),
        gen_(graph_->preorder().length()),
        kill_(graph_->preorder().length()),
        exposed_values_(graph_->preorder().length()),
        out_values_(graph_->preorder().length()),
        phis_(5),
        worklist_(5),
        in_worklist_(NULL),
        forwarded_(false) {
    const intptr_t num_blocks = graph_->preorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      out_.Add(NULL);
      gen_.Add(new(I) BitVector(aliased_set_->max_place_id()));
      kill_.Add(new(I) BitVector(aliased_set_->max_place_id()));
      in_.Add(new(I) BitVector(aliased_set_->max_place_id()));

      exposed_values_.Add(NULL);
      out_values_.Add(NULL);
    }
  }

  Isolate* isolate() const { return graph_->isolate(); }

  static bool OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);
    if (FLAG_trace_load_optimization) {
      FlowGraphPrinter::PrintGraph("Before LoadOptimizer", graph);
    }

    DirectChainedHashMap<PointerKeyValueTrait<Place> > map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeLoads);
    if ((aliased_set != NULL) && !aliased_set->IsEmpty()) {
      // If any loads were forwarded return true from Optimize to run load
      // forwarding again. This will allow to forward chains of loads.
      // This is especially important for context variables as they are built
      // as loads from loaded context.
      // TODO(vegorov): renumber newly discovered congruences during the
      // forwarding to forward chains without running whole pass twice.
      LoadOptimizer load_optimizer(graph, aliased_set, &map);
      return load_optimizer.Optimize();
    }
    return false;
  }

 private:
  bool Optimize() {
    ComputeInitialSets();
    ComputeOutSets();
    ComputeOutValues();
    if (graph_->is_licm_allowed()) {
      MarkLoopInvariantLoads();
    }
    ForwardLoads();
    EmitPhis();

    if (FLAG_trace_load_optimization) {
      FlowGraphPrinter::PrintGraph("After LoadOptimizer", graph_);
    }

    return forwarded_;
  }

  // Compute sets of loads generated and killed by each block.
  // Additionally compute upwards exposed and generated loads for each block.
  // Exposed loads are those that can be replaced if a corresponding
  // reaching load will be found.
  // Loads that are locally redundant will be replaced as we go through
  // instructions.
  void ComputeInitialSets() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t preorder_number = block->preorder_number();

      BitVector* kill = kill_[preorder_number];
      BitVector* gen = gen_[preorder_number];

      ZoneGrowableArray<Definition*>* exposed_values = NULL;
      ZoneGrowableArray<Definition*>* out_values = NULL;

      for (ForwardInstructionIterator instr_it(block);
           !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        const Alias alias = aliased_set_->ComputeAliasForStore(instr);
        if (!alias.IsNone()) {
          // Interfering stores kill only loads from the same offset.
          BitVector* killed = aliased_set_->Get(alias);

          if (killed != NULL) {
            kill->AddAll(killed);
            // There is no need to clear out_values when clearing GEN set
            // because only those values that are in the GEN set
            // will ever be used.
            gen->RemoveAll(killed);
          }

          // Only forward stores to normal arrays, float64, and simd arrays
          // to loads because other array stores (intXX/uintXX/float32)
          // may implicitly convert the value stored.
          StoreIndexedInstr* array_store = instr->AsStoreIndexed();
          if ((array_store == NULL) ||
              (array_store->class_id() == kArrayCid) ||
              (array_store->class_id() == kTypedDataFloat64ArrayCid) ||
              (array_store->class_id() == kTypedDataFloat32ArrayCid) ||
              (array_store->class_id() == kTypedDataFloat32x4ArrayCid)) {
            bool is_load = false, is_store = false;
            Place store_place(instr, &is_load, &is_store);
            ASSERT(!is_load && is_store);
            Place* place = map_->Lookup(&store_place);
            if (place != NULL) {
              // Store has a corresponding numbered place that might have a
              // load. Try forwarding stored value to it.
              gen->Add(place->id());
              if (out_values == NULL) out_values = CreateBlockOutValues();
              (*out_values)[place->id()] = GetStoredValue(instr);
            }
          }

          ASSERT(!instr->IsDefinition() ||
                 !IsLoadEliminationCandidate(instr->AsDefinition()));
          continue;
        }

        // If instruction has effects then kill all loads affected.
        if (!instr->Effects().IsNone()) {
          kill->AddAll(aliased_set_->aliased_by_effects());
          // There is no need to clear out_values when removing values from GEN
          // set because only those values that are in the GEN set
          // will ever be used.
          gen->RemoveAll(aliased_set_->aliased_by_effects());
          continue;
        }

        Definition* defn = instr->AsDefinition();
        if (defn == NULL) {
          continue;
        }

        // For object allocation forward initial values of the fields to
        // subsequent loads. For simplicity we ignore escaping objects.
        //
        // The reason to ignore escaping objects is that final fields are
        // initialized in constructor that potentially can be not inlined into
        // the function that we are currently optimizing. However at the same
        // time we assume that values of the final fields can be forwarded
        // across side-effects. If we add 'null' as known values for these
        // fields here we will incorrectly propagate this null across
        // constructor invocation.
        // TODO(vegorov): record null-values at least for not final fields of
        // escaping object.
        AllocateObjectInstr* alloc = instr->AsAllocateObject();
        if ((alloc != NULL) && !AliasedSet::CanBeAliased(alloc)) {
          for (Value* use = alloc->input_use_list();
               use != NULL;
               use = use->next_use()) {
            // Look for all immediate loads from this object.
            if (use->use_index() != 0) {
              continue;
            }

            LoadFieldInstr* load = use->instruction()->AsLoadField();
            if (load != NULL) {
              // Found a load. Initialize current value of the field to null for
              // normal fields, or with type arguments.
              gen->Add(load->place_id());
              if (out_values == NULL) out_values = CreateBlockOutValues();

              if (alloc->ArgumentCount() > 0) {
                ASSERT(alloc->ArgumentCount() == 1);
                intptr_t type_args_offset =
                    alloc->cls().type_arguments_field_offset();
                if (load->offset_in_bytes() == type_args_offset) {
                  (*out_values)[load->place_id()] =
                      alloc->PushArgumentAt(0)->value()->definition();
                  continue;
                }
              }
              (*out_values)[load->place_id()] = graph_->constant_null();
            }
          }
          continue;
        }

        if (!IsLoadEliminationCandidate(defn)) {
          continue;
        }

        const intptr_t place_id = defn->place_id();
        if (gen->Contains(place_id)) {
          // This is a locally redundant load.
          ASSERT((out_values != NULL) && ((*out_values)[place_id] != NULL));

          Definition* replacement = (*out_values)[place_id];
          EnsureSSATempIndex(graph_, defn, replacement);
          if (FLAG_trace_optimization) {
            OS::Print("Replacing load v%" Pd " with v%" Pd "\n",
                      defn->ssa_temp_index(),
                      replacement->ssa_temp_index());
          }

          defn->ReplaceUsesWith(replacement);
          instr_it.RemoveCurrentFromGraph();
          forwarded_ = true;
          continue;
        } else if (!kill->Contains(place_id)) {
          // This is an exposed load: it is the first representative of a
          // given expression id and it is not killed on the path from
          // the block entry.
          if (exposed_values == NULL) {
            static const intptr_t kMaxExposedValuesInitialSize = 5;
            exposed_values = new(I) ZoneGrowableArray<Definition*>(
                Utils::Minimum(kMaxExposedValuesInitialSize,
                               aliased_set_->max_place_id()));
          }

          exposed_values->Add(defn);
        }

        gen->Add(place_id);

        if (out_values == NULL) out_values = CreateBlockOutValues();
        (*out_values)[place_id] = defn;
      }

      exposed_values_[preorder_number] = exposed_values;
      out_values_[preorder_number] = out_values;
    }
  }

  static void PerformPhiMoves(PhiPlaceMoves::MovesList phi_moves,
                              BitVector* out,
                              BitVector* forwarded_loads) {
    forwarded_loads->Clear();

    for (intptr_t i = 0; i < phi_moves->length(); i++) {
      const intptr_t from = (*phi_moves)[i].from();
      const intptr_t to = (*phi_moves)[i].to();
      if (from == to) continue;

      if (out->Contains(from)) {
        forwarded_loads->Add(to);
      }
    }

    for (intptr_t i = 0; i < phi_moves->length(); i++) {
      const intptr_t from = (*phi_moves)[i].from();
      const intptr_t to = (*phi_moves)[i].to();
      if (from == to) continue;

      out->Remove(to);
    }

    out->AddAll(forwarded_loads);
  }

  // Compute OUT sets by propagating them iteratively until fix point
  // is reached.
  void ComputeOutSets() {
    BitVector* temp = new(I) BitVector(aliased_set_->max_place_id());
    BitVector* forwarded_loads = new(I) BitVector(aliased_set_->max_place_id());
    BitVector* temp_out = new(I) BitVector(aliased_set_->max_place_id());

    bool changed = true;
    while (changed) {
      changed = false;

      for (BlockIterator block_it = graph_->reverse_postorder_iterator();
           !block_it.Done();
           block_it.Advance()) {
        BlockEntryInstr* block = block_it.Current();

        const intptr_t preorder_number = block->preorder_number();

        BitVector* block_in = in_[preorder_number];
        BitVector* block_out = out_[preorder_number];
        BitVector* block_kill = kill_[preorder_number];
        BitVector* block_gen = gen_[preorder_number];

        // Compute block_in as the intersection of all out(p) where p
        // is a predecessor of the current block.
        if (block->IsGraphEntry()) {
          temp->Clear();
        } else {
          temp->SetAll();
          ASSERT(block->PredecessorCount() > 0);
          for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
            BlockEntryInstr* pred = block->PredecessorAt(i);
            BitVector* pred_out = out_[pred->preorder_number()];
            if (pred_out == NULL) continue;
            PhiPlaceMoves::MovesList phi_moves =
                aliased_set_->phi_moves()->GetOutgoingMoves(pred);
            if (phi_moves != NULL) {
              // If there are phi moves, perform intersection with
              // a copy of pred_out where the phi moves are applied.
              temp_out->CopyFrom(pred_out);
              PerformPhiMoves(phi_moves, temp_out, forwarded_loads);
              pred_out = temp_out;
            }
            temp->Intersect(pred_out);
          }
        }

        if (!temp->Equals(*block_in) || (block_out == NULL)) {
          // If IN set has changed propagate the change to OUT set.
          block_in->CopyFrom(temp);

          temp->RemoveAll(block_kill);
          temp->AddAll(block_gen);

          if ((block_out == NULL) || !block_out->Equals(*temp)) {
            if (block_out == NULL) {
              block_out = out_[preorder_number] =
                  new(I) BitVector(aliased_set_->max_place_id());
            }
            block_out->CopyFrom(temp);
            changed = true;
          }
        }
      }
    }
  }

  // Compute out_values mappings by propagating them in reverse postorder once
  // through the graph. Generate phis on back edges where eager merge is
  // impossible.
  // No replacement is done at this point and thus any out_value[place_id] is
  // changed at most once: from NULL to an actual value.
  // When merging incoming loads we might need to create a phi.
  // These phis are not inserted at the graph immediately because some of them
  // might become redundant after load forwarding is done.
  void ComputeOutValues() {
    GrowableArray<PhiInstr*> pending_phis(5);
    ZoneGrowableArray<Definition*>* temp_forwarded_values = NULL;

    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();

      const bool can_merge_eagerly = CanMergeEagerly(block);

      const intptr_t preorder_number = block->preorder_number();

      ZoneGrowableArray<Definition*>* block_out_values =
          out_values_[preorder_number];


      // If OUT set has changed then we have new values available out of
      // the block. Compute these values creating phi where necessary.
      for (BitVector::Iterator it(out_[preorder_number]);
           !it.Done();
           it.Advance()) {
        const intptr_t place_id = it.Current();

        if (block_out_values == NULL) {
          out_values_[preorder_number] = block_out_values =
              CreateBlockOutValues();
        }

        if ((*block_out_values)[place_id] == NULL) {
          ASSERT(block->PredecessorCount() > 0);
          Definition* in_value = can_merge_eagerly ?
              MergeIncomingValues(block, place_id) : NULL;
          if ((in_value == NULL) &&
              (in_[preorder_number]->Contains(place_id))) {
            PhiInstr* phi = new(I) PhiInstr(block->AsJoinEntry(),
                                            block->PredecessorCount());
            phi->set_place_id(place_id);
            pending_phis.Add(phi);
            in_value = phi;
          }
          (*block_out_values)[place_id] = in_value;
        }
      }

      // If the block has outgoing phi moves perform them. Use temporary list
      // of values to ensure that cyclic moves are performed correctly.
      PhiPlaceMoves::MovesList phi_moves =
          aliased_set_->phi_moves()->GetOutgoingMoves(block);
      if ((phi_moves != NULL) && (block_out_values != NULL)) {
        if (temp_forwarded_values == NULL) {
          temp_forwarded_values = CreateBlockOutValues();
        }

        for (intptr_t i = 0; i < phi_moves->length(); i++) {
          const intptr_t from = (*phi_moves)[i].from();
          const intptr_t to = (*phi_moves)[i].to();
          if (from == to) continue;

          (*temp_forwarded_values)[to] = (*block_out_values)[from];
        }

        for (intptr_t i = 0; i < phi_moves->length(); i++) {
          const intptr_t from = (*phi_moves)[i].from();
          const intptr_t to = (*phi_moves)[i].to();
          if (from == to) continue;

          (*block_out_values)[to] = (*temp_forwarded_values)[to];
        }
      }

      if (FLAG_trace_load_optimization) {
        OS::Print("B%" Pd "\n", block->block_id());
        OS::Print("  IN: ");
        aliased_set_->PrintSet(in_[preorder_number]);
        OS::Print("\n");

        OS::Print("  KILL: ");
        aliased_set_->PrintSet(kill_[preorder_number]);
        OS::Print("\n");

        OS::Print("  OUT: ");
        aliased_set_->PrintSet(out_[preorder_number]);
        OS::Print("\n");
      }
    }

    // All blocks were visited. Fill pending phis with inputs
    // that flow on back edges.
    for (intptr_t i = 0; i < pending_phis.length(); i++) {
      FillPhiInputs(pending_phis[i]);
    }
  }

  bool CanMergeEagerly(BlockEntryInstr* block) {
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      if (pred->postorder_number() < block->postorder_number()) {
        return false;
      }
    }
    return true;
  }

  void MarkLoopInvariantLoads() {
    const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
        graph_->loop_headers();

    ZoneGrowableArray<BitVector*>* invariant_loads =
        new(I) ZoneGrowableArray<BitVector*>(loop_headers.length());

    for (intptr_t i = 0; i < loop_headers.length(); i++) {
      BlockEntryInstr* header = loop_headers[i];
      BlockEntryInstr* pre_header = FindPreHeader(header);
      if (pre_header == NULL) {
        invariant_loads->Add(NULL);
        continue;
      }

      BitVector* loop_gen = new(I) BitVector(aliased_set_->max_place_id());
      for (BitVector::Iterator loop_it(header->loop_info());
           !loop_it.Done();
           loop_it.Advance()) {
        const intptr_t preorder_number = loop_it.Current();
        loop_gen->AddAll(gen_[preorder_number]);
      }

      for (BitVector::Iterator loop_it(header->loop_info());
           !loop_it.Done();
           loop_it.Advance()) {
        const intptr_t preorder_number = loop_it.Current();
        loop_gen->RemoveAll(kill_[preorder_number]);
      }

      if (FLAG_trace_optimization) {
        for (BitVector::Iterator it(loop_gen); !it.Done(); it.Advance()) {
          OS::Print("place %s is loop invariant for B%" Pd "\n",
                    aliased_set_->places()[it.Current()]->ToCString(),
                    header->block_id());
        }
      }

      invariant_loads->Add(loop_gen);
    }

    graph_->set_loop_invariant_loads(invariant_loads);
  }

  // Compute incoming value for the given expression id.
  // Will create a phi if different values are incoming from multiple
  // predecessors.
  Definition* MergeIncomingValues(BlockEntryInstr* block, intptr_t place_id) {
    // First check if the same value is coming in from all predecessors.
    static Definition* const kDifferentValuesMarker =
        reinterpret_cast<Definition*>(-1);
    Definition* incoming = NULL;
    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      if ((pred_out_values == NULL) || ((*pred_out_values)[place_id] == NULL)) {
        return NULL;
      } else if (incoming == NULL) {
        incoming = (*pred_out_values)[place_id];
      } else if (incoming != (*pred_out_values)[place_id]) {
        incoming = kDifferentValuesMarker;
      }
    }

    if (incoming != kDifferentValuesMarker) {
      ASSERT(incoming != NULL);
      return incoming;
    }

    // Incoming values are different. Phi is required to merge.
    PhiInstr* phi = new(I) PhiInstr(
        block->AsJoinEntry(), block->PredecessorCount());
    phi->set_place_id(place_id);
    FillPhiInputs(phi);
    return phi;
  }

  void FillPhiInputs(PhiInstr* phi) {
    BlockEntryInstr* block = phi->GetBlock();
    const intptr_t place_id = phi->place_id();

    for (intptr_t i = 0; i < block->PredecessorCount(); i++) {
      BlockEntryInstr* pred = block->PredecessorAt(i);
      ZoneGrowableArray<Definition*>* pred_out_values =
          out_values_[pred->preorder_number()];
      ASSERT((*pred_out_values)[place_id] != NULL);

      // Sets of outgoing values are not linked into use lists so
      // they might contain values that were replaced and removed
      // from the graph by this iteration.
      // To prevent using them we additionally mark definitions themselves
      // as replaced and store a pointer to the replacement.
      Definition* replacement = (*pred_out_values)[place_id]->Replacement();
      Value* input = new(I) Value(replacement);
      phi->SetInputAt(i, input);
      replacement->AddInputUse(input);
    }

    phi->set_ssa_temp_index(graph_->alloc_ssa_temp_index());
    phis_.Add(phi);  // Postpone phi insertion until after load forwarding.

    if (FLAG_trace_load_optimization) {
      OS::Print("created pending phi %s for %s at B%" Pd "\n",
                phi->ToCString(),
                aliased_set_->places()[place_id]->ToCString(),
                block->block_id());
    }
  }

  // Iterate over basic blocks and replace exposed loads with incoming
  // values.
  void ForwardLoads() {
    for (BlockIterator block_it = graph_->reverse_postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();

      ZoneGrowableArray<Definition*>* loads =
          exposed_values_[block->preorder_number()];
      if (loads == NULL) continue;  // No exposed loads.

      BitVector* in = in_[block->preorder_number()];

      for (intptr_t i = 0; i < loads->length(); i++) {
        Definition* load = (*loads)[i];
        if (!in->Contains(load->place_id())) continue;  // No incoming value.

        Definition* replacement = MergeIncomingValues(block, load->place_id());
        ASSERT(replacement != NULL);

        // Sets of outgoing values are not linked into use lists so
        // they might contain values that were replace and removed
        // from the graph by this iteration.
        // To prevent using them we additionally mark definitions themselves
        // as replaced and store a pointer to the replacement.
        replacement = replacement->Replacement();

        if (load != replacement) {
          EnsureSSATempIndex(graph_, load, replacement);

          if (FLAG_trace_optimization) {
            OS::Print("Replacing load v%" Pd " with v%" Pd "\n",
                      load->ssa_temp_index(),
                      replacement->ssa_temp_index());
          }

          load->ReplaceUsesWith(replacement);
          load->RemoveFromGraph();
          load->SetReplacement(replacement);
          forwarded_ = true;
        }
      }
    }
  }

  // Check if the given phi take the same value on all code paths.
  // Eliminate it as redundant if this is the case.
  // When analyzing phi operands assumes that only generated during
  // this load phase can be redundant. They can be distinguished because
  // they are not marked alive.
  // TODO(vegorov): move this into a separate phase over all phis.
  bool EliminateRedundantPhi(PhiInstr* phi) {
    Definition* value = NULL;  // Possible value of this phi.

    worklist_.Clear();
    if (in_worklist_ == NULL) {
      in_worklist_ = new(I) BitVector(graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    worklist_.Add(phi);
    in_worklist_->Add(phi->ssa_temp_index());

    for (intptr_t i = 0; i < worklist_.length(); i++) {
      PhiInstr* phi = worklist_[i];

      for (intptr_t i = 0; i < phi->InputCount(); i++) {
        Definition* input = phi->InputAt(i)->definition();
        if (input == phi) continue;

        PhiInstr* phi_input = input->AsPhi();
        if ((phi_input != NULL) && !phi_input->is_alive()) {
          if (!in_worklist_->Contains(phi_input->ssa_temp_index())) {
            worklist_.Add(phi_input);
            in_worklist_->Add(phi_input->ssa_temp_index());
          }
          continue;
        }

        if (value == NULL) {
          value = input;
        } else if (value != input) {
          return false;  // This phi is not redundant.
        }
      }
    }

    // All phis in the worklist are redundant and have the same computed
    // value on all code paths.
    ASSERT(value != NULL);
    for (intptr_t i = 0; i < worklist_.length(); i++) {
      worklist_[i]->ReplaceUsesWith(value);
    }

    return true;
  }

  bool AddPhiPairToWorklist(PhiInstr* a, PhiInstr* b) {
    // Can't compare two phis from different blocks.
    if (a->block() != b->block()) {
      return false;
    }

    // If a is already in the worklist check if it is being compared to b.
    // Give up if it is not.
    if (in_worklist_->Contains(a->ssa_temp_index())) {
      for (intptr_t i = 0; i < worklist_.length(); i += 2) {
        if (a == worklist_[i]) {
          return (b == worklist_[i + 1]);
        }
      }
      UNREACHABLE();
    }

    worklist_.Add(a);
    worklist_.Add(b);
    in_worklist_->Add(a->ssa_temp_index());
    return true;
  }

  // Replace the given phi with another if they are equal.
  // Returns true if succeeds.
  bool ReplacePhiWith(PhiInstr* phi, PhiInstr* replacement) {
    ASSERT(phi->InputCount() == replacement->InputCount());
    ASSERT(phi->block() == replacement->block());

    worklist_.Clear();
    if (in_worklist_ == NULL) {
      in_worklist_ = new(I) BitVector(graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    // During the comparison worklist contains pairs of phis to be compared.
    AddPhiPairToWorklist(phi, replacement);

    // Process the worklist. It might grow during each comparison step.
    for (intptr_t i = 0; i < worklist_.length(); i += 2) {
      PhiInstr* a = worklist_[i];
      PhiInstr* b = worklist_[i + 1];

      // Compare phi inputs.
      for (intptr_t j = 0; j < a->InputCount(); j++) {
        Definition* inputA = a->InputAt(j)->definition();
        Definition* inputB = b->InputAt(j)->definition();

        if (inputA != inputB) {
          // If inputs are unequal by they are phis then add them to
          // the worklist for recursive comparison.
          if (inputA->IsPhi() && inputB->IsPhi() &&
              AddPhiPairToWorklist(inputA->AsPhi(), inputB->AsPhi())) {
            continue;
          }
          return false;  // Not equal.
        }
      }
    }

    // At this point worklist contains pairs of equal phis. Replace the first
    // phi in the pair with the second.
    for (intptr_t i = 0; i < worklist_.length(); i += 2) {
      PhiInstr* a = worklist_[i];
      PhiInstr* b = worklist_[i + 1];
      a->ReplaceUsesWith(b);
      if (a->is_alive()) {
        a->mark_dead();
        a->block()->RemovePhi(a);
        a->UnuseAllInputs();
      }
    }
    return true;
  }

  // Insert the given phi into the graph. Attempt to find an equal one in the
  // target block first.
  // Returns true if the phi was inserted and false if it was replaced.
  bool EmitPhi(PhiInstr* phi) {
    for (PhiIterator it(phi->block()); !it.Done(); it.Advance()) {
      if (ReplacePhiWith(phi, it.Current())) {
        return false;
      }
    }

    phi->mark_alive();
    phi->block()->InsertPhi(phi);
    return true;
  }

  // Phis have not yet been inserted into the graph but they have uses of
  // their inputs.  Insert the non-redundant ones and clear the input uses
  // of the redundant ones.
  void EmitPhis() {
    // First eliminate all redundant phis.
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if (!phi->HasUses() || EliminateRedundantPhi(phi)) {
        phi->UnuseAllInputs();
        phis_[i] = NULL;
      }
    }

    // Now emit phis or replace them with equal phis already present in the
    // graph.
    for (intptr_t i = 0; i < phis_.length(); i++) {
      PhiInstr* phi = phis_[i];
      if ((phi != NULL) && (!phi->HasUses() || !EmitPhi(phi))) {
        phi->UnuseAllInputs();
      }
    }
  }

  ZoneGrowableArray<Definition*>* CreateBlockOutValues() {
    ZoneGrowableArray<Definition*>* out =
        new(I) ZoneGrowableArray<Definition*>(aliased_set_->max_place_id());
    for (intptr_t i = 0; i < aliased_set_->max_place_id(); i++) {
      out->Add(NULL);
    }
    return out;
  }

  FlowGraph* graph_;
  DirectChainedHashMap<PointerKeyValueTrait<Place> >* map_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  AliasedSet* aliased_set_;

  // Per block sets of expression ids for loads that are: incoming (available
  // on the entry), outgoing (available on the exit), generated and killed.
  GrowableArray<BitVector*> in_;
  GrowableArray<BitVector*> out_;
  GrowableArray<BitVector*> gen_;
  GrowableArray<BitVector*> kill_;

  // Per block list of upwards exposed loads.
  GrowableArray<ZoneGrowableArray<Definition*>*> exposed_values_;

  // Per block mappings between expression ids and outgoing definitions that
  // represent those ids.
  GrowableArray<ZoneGrowableArray<Definition*>*> out_values_;

  // List of phis generated during ComputeOutValues and ForwardLoads.
  // Some of these phis might be redundant and thus a separate pass is
  // needed to emit only non-redundant ones.
  GrowableArray<PhiInstr*> phis_;

  // Auxiliary worklist used by redundant phi elimination.
  GrowableArray<PhiInstr*> worklist_;
  BitVector* in_worklist_;

  // True if any load was eliminated.
  bool forwarded_;

  DISALLOW_COPY_AND_ASSIGN(LoadOptimizer);
};


class StoreOptimizer : public LivenessAnalysis {
 public:
  StoreOptimizer(FlowGraph* graph,
                 AliasedSet* aliased_set,
                 DirectChainedHashMap<PointerKeyValueTrait<Place> >* map)
      : LivenessAnalysis(aliased_set->max_place_id(), graph->postorder()),
        graph_(graph),
        map_(map),
        aliased_set_(aliased_set),
        exposed_stores_(graph_->postorder().length()) {
    const intptr_t num_blocks = graph_->postorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      exposed_stores_.Add(NULL);
    }
  }

  static void OptimizeGraph(FlowGraph* graph) {
    ASSERT(FLAG_load_cse);
    if (FLAG_trace_load_optimization) {
      FlowGraphPrinter::PrintGraph("Before StoreOptimizer", graph);
    }

    DirectChainedHashMap<PointerKeyValueTrait<Place> > map;
    AliasedSet* aliased_set = NumberPlaces(graph, &map, kOptimizeStores);
    if ((aliased_set != NULL) && !aliased_set->IsEmpty()) {
      StoreOptimizer store_optimizer(graph, aliased_set, &map);
      store_optimizer.Optimize();
    }
  }

 private:
  void Optimize() {
    Analyze();
    if (FLAG_trace_load_optimization) {
      Dump();
    }
    EliminateDeadStores();
    if (FLAG_trace_load_optimization) {
      FlowGraphPrinter::PrintGraph("After StoreOptimizer", graph_);
    }
  }

  bool CanEliminateStore(Instruction* instr) {
    switch (instr->tag()) {
      case Instruction::kStoreInstanceField:
        if (instr->AsStoreInstanceField()->is_initialization()) {
          // Can't eliminate stores that initialized unboxed fields.
          return false;
        }
      case Instruction::kStoreContext:
      case Instruction::kStoreIndexed:
      case Instruction::kStoreStaticField:
        return true;
      default:
        UNREACHABLE();
        return false;
    }
  }

  virtual void ComputeInitialSets() {
    Isolate* isolate = graph_->isolate();
    BitVector* all_places = new(isolate) BitVector(
        aliased_set_->max_place_id());
    all_places->SetAll();
    for (BlockIterator block_it = graph_->postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t postorder_number = block->postorder_number();

      BitVector* kill = kill_[postorder_number];
      BitVector* live_in = live_in_[postorder_number];
      BitVector* live_out = live_out_[postorder_number];

      ZoneGrowableArray<Instruction*>* exposed_stores = NULL;

      // Iterate backwards starting at the last instruction.
      for (BackwardInstructionIterator instr_it(block);
           !instr_it.Done();
           instr_it.Advance()) {
        Instruction* instr = instr_it.Current();

        bool is_load = false;
        bool is_store = false;
        Place place(instr, &is_load, &is_store);
        if (place.IsFinalField()) {
          // Loads/stores of final fields do not participate.
          continue;
        }

        // Handle stores.
        if (is_store) {
          if (kill->Contains(instr->place_id())) {
            if (!live_in->Contains(instr->place_id()) &&
                CanEliminateStore(instr)) {
              if (FLAG_trace_optimization) {
                OS::Print(
                    "Removing dead store to place %" Pd " in block B%" Pd "\n",
                    instr->place_id(), block->block_id());
              }
              instr_it.RemoveCurrentFromGraph();
            }
          } else if (!live_in->Contains(instr->place_id())) {
            // Mark this store as down-ward exposed: They are the only
            // candidates for the global store elimination.
            if (exposed_stores == NULL) {
              const intptr_t kMaxExposedStoresInitialSize = 5;
              exposed_stores = new(isolate) ZoneGrowableArray<Instruction*>(
                  Utils::Minimum(kMaxExposedStoresInitialSize,
                                 aliased_set_->max_place_id()));
            }
            exposed_stores->Add(instr);
          }
          // Interfering stores kill only loads from the same place.
          kill->Add(instr->place_id());
          live_in->Remove(instr->place_id());
          continue;
        }

        // Handle side effects, deoptimization and function return.
        if (!instr->Effects().IsNone() ||
            instr->CanDeoptimize() ||
            instr->IsThrow() ||
            instr->IsReThrow() ||
            instr->IsReturn()) {
          // Instructions that return from the function, instructions with side
          // effects and instructions that can deoptimize are considered as
          // loads from all places.
          live_in->CopyFrom(all_places);
          if (instr->IsThrow() || instr->IsReThrow() || instr->IsReturn()) {
            // Initialize live-out for exit blocks since it won't be computed
            // otherwise during the fixed point iteration.
            live_out->CopyFrom(all_places);
          }
          continue;
        }

        // Handle loads.
        Definition* defn = instr->AsDefinition();
        if ((defn != NULL) && IsLoadEliminationCandidate(defn)) {
          const Alias alias = aliased_set_->ComputeAlias(&place);
          live_in->AddAll(aliased_set_->Get(alias));
          continue;
        }
      }
      exposed_stores_[postorder_number] = exposed_stores;
    }
    if (FLAG_trace_load_optimization) {
      Dump();
      OS::Print("---\n");
    }
  }

  void EliminateDeadStores() {
    // Iteration order does not matter here.
    for (BlockIterator block_it = graph_->postorder_iterator();
         !block_it.Done();
         block_it.Advance()) {
      BlockEntryInstr* block = block_it.Current();
      const intptr_t postorder_number = block->postorder_number();

      BitVector* live_out = live_out_[postorder_number];

      ZoneGrowableArray<Instruction*>* exposed_stores =
        exposed_stores_[postorder_number];
      if (exposed_stores == NULL) continue;  // No exposed stores.

      // Iterate over candidate stores.
      for (intptr_t i = 0; i < exposed_stores->length(); ++i) {
        Instruction* instr = (*exposed_stores)[i];
        bool is_load = false;
        bool is_store = false;
        Place place(instr, &is_load, &is_store);
        ASSERT(!is_load && is_store);
        if (place.IsFinalField()) {
          // Final field do not participate in dead store elimination.
          continue;
        }
        // Eliminate a downward exposed store if the corresponding place is not
        // in live-out.
        if (!live_out->Contains(instr->place_id()) &&
            CanEliminateStore(instr)) {
          if (FLAG_trace_optimization) {
            OS::Print("Removing dead store to place %" Pd " block B%" Pd "\n",
                      instr->place_id(), block->block_id());
          }
          instr->RemoveFromGraph(/* ignored */ false);
        }
      }
    }
  }

  FlowGraph* graph_;
  DirectChainedHashMap<PointerKeyValueTrait<Place> >* map_;

  // Mapping between field offsets in words and expression ids of loads from
  // that offset.
  AliasedSet* aliased_set_;

  // Per block list of downward exposed stores.
  GrowableArray<ZoneGrowableArray<Instruction*>*> exposed_stores_;

  DISALLOW_COPY_AND_ASSIGN(StoreOptimizer);
};


void DeadStoreElimination::Optimize(FlowGraph* graph) {
  if (FLAG_dead_store_elimination) {
    StoreOptimizer::OptimizeGraph(graph);
  }
}


void DeadCodeElimination::EliminateDeadPhis(FlowGraph* flow_graph) {
  GrowableArray<PhiInstr*> live_phis;
  for (BlockIterator b = flow_graph->postorder_iterator();
       !b.Done();
       b.Advance()) {
    JoinEntryInstr* join = b.Current()->AsJoinEntry();
    if (join != NULL) {
      for (PhiIterator it(join); !it.Done(); it.Advance()) {
        PhiInstr* phi = it.Current();
        // Phis that have uses and phis inside try blocks are
        // marked as live.
        if (phi->HasUses() || join->InsideTryBlock()) {
          live_phis.Add(phi);
          phi->mark_alive();
        } else {
          phi->mark_dead();
        }
      }
    }
  }

  while (!live_phis.is_empty()) {
    PhiInstr* phi = live_phis.RemoveLast();
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Value* val = phi->InputAt(i);
      PhiInstr* used_phi = val->definition()->AsPhi();
      if ((used_phi != NULL) && !used_phi->is_alive()) {
        used_phi->mark_alive();
        live_phis.Add(used_phi);
      }
    }
  }

  for (BlockIterator it(flow_graph->postorder_iterator());
       !it.Done();
       it.Advance()) {
    JoinEntryInstr* join = it.Current()->AsJoinEntry();
    if (join != NULL) {
      if (join->phis_ == NULL) continue;

      // Eliminate dead phis and compact the phis_ array of the block.
      intptr_t to_index = 0;
      for (intptr_t i = 0; i < join->phis_->length(); ++i) {
        PhiInstr* phi = (*join->phis_)[i];
        if (phi != NULL) {
          if (!phi->is_alive()) {
            phi->ReplaceUsesWith(flow_graph->constant_null());
            phi->UnuseAllInputs();
            (*join->phis_)[i] = NULL;
            if (FLAG_trace_optimization) {
              OS::Print("Removing dead phi v%" Pd "\n", phi->ssa_temp_index());
            }
          } else if (phi->IsRedundant()) {
            phi->ReplaceUsesWith(phi->InputAt(0)->definition());
            phi->UnuseAllInputs();
            (*join->phis_)[i] = NULL;
            if (FLAG_trace_optimization) {
              OS::Print("Removing redundant phi v%" Pd "\n",
                         phi->ssa_temp_index());
            }
          } else {
            (*join->phis_)[to_index++] = phi;
          }
        }
      }
      if (to_index == 0) {
        join->phis_ = NULL;
      } else {
        join->phis_->TruncateTo(to_index);
      }
    }
  }
}


class CSEInstructionMap : public ValueObject {
 public:
  // Right now CSE and LICM track a single effect: possible externalization of
  // strings.
  // Other effects like modifications of fields are tracked in a separate load
  // forwarding pass via Alias structure.
  COMPILE_ASSERT(EffectSet::kLastEffect == 1);

  CSEInstructionMap() : independent_(), dependent_() { }
  explicit CSEInstructionMap(const CSEInstructionMap& other)
      : ValueObject(),
        independent_(other.independent_),
        dependent_(other.dependent_) {
  }

  void RemoveAffected(EffectSet effects) {
    if (!effects.IsNone()) {
      dependent_.Clear();
    }
  }

  Instruction* Lookup(Instruction* other) const {
    return GetMapFor(other)->Lookup(other);
  }

  void Insert(Instruction* instr) {
    return GetMapFor(instr)->Insert(instr);
  }

 private:
  typedef DirectChainedHashMap<PointerKeyValueTrait<Instruction> >  Map;

  Map* GetMapFor(Instruction* instr) {
    return instr->Dependencies().IsNone() ? &independent_ : &dependent_;
  }

  const Map* GetMapFor(Instruction* instr) const {
    return instr->Dependencies().IsNone() ? &independent_ : &dependent_;
  }

  // All computations that are not affected by any side-effect.
  // Majority of computations are not affected by anything and will be in
  // this map.
  Map independent_;

  // All computations that are affected by side effect.
  Map dependent_;
};


bool DominatorBasedCSE::Optimize(FlowGraph* graph) {
  bool changed = false;
  if (FLAG_load_cse) {
    changed = LoadOptimizer::OptimizeGraph(graph) || changed;
  }

  CSEInstructionMap map;
  changed = OptimizeRecursive(graph, graph->graph_entry(), &map) || changed;

  return changed;
}


bool DominatorBasedCSE::OptimizeRecursive(
    FlowGraph* graph,
    BlockEntryInstr* block,
    CSEInstructionMap* map) {
  bool changed = false;
  for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
    Instruction* current = it.Current();
    if (current->AllowsCSE()) {
      Instruction* replacement = map->Lookup(current);
      if ((replacement != NULL) &&
          graph->block_effects()->IsAvailableAt(replacement, block)) {
        // Replace current with lookup result.
        ReplaceCurrentInstruction(&it, current, replacement, graph);
        changed = true;
        continue;
      }

      // For simplicity we assume that instruction either does not depend on
      // anything or does not affect anything. If this is not the case then
      // we should first remove affected instructions from the map and
      // then add instruction to the map so that it does not kill itself.
      ASSERT(current->Effects().IsNone() || current->Dependencies().IsNone());
      map->Insert(current);
    }

    map->RemoveAffected(current->Effects());
  }

  // Process children in the dominator tree recursively.
  intptr_t num_children = block->dominated_blocks().length();
  for (intptr_t i = 0; i < num_children; ++i) {
    BlockEntryInstr* child = block->dominated_blocks()[i];
    if (i  < num_children - 1) {
      // Copy map.
      CSEInstructionMap child_map(*map);
      changed = OptimizeRecursive(graph, child, &child_map) || changed;
    } else {
      // Reuse map for the last child.
      changed = OptimizeRecursive(graph, child, map) || changed;
    }
  }
  return changed;
}


ConstantPropagator::ConstantPropagator(
    FlowGraph* graph,
    const GrowableArray<BlockEntryInstr*>& ignored)
    : FlowGraphVisitor(ignored),
      graph_(graph),
      unknown_(Object::unknown_constant()),
      non_constant_(Object::non_constant()),
      reachable_(new(graph->isolate()) BitVector(graph->preorder().length())),
      definition_marks_(new(graph->isolate()) BitVector(
          graph->max_virtual_register_number())),
      block_worklist_(),
      definition_worklist_() {}


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
  cp.VisitBranches();
  cp.Transform();
  cp.EliminateRedundantBranches();
}


void ConstantPropagator::SetReachable(BlockEntryInstr* block) {
  if (!reachable_->Contains(block->preorder_number())) {
    reachable_->Add(block->preorder_number());
    block_worklist_.Add(block);
  }
}


void ConstantPropagator::SetValue(Definition* definition, const Object& value) {
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
      ASSERT(definition->HasSSATemp());
      if (!definition_marks_->Contains(definition->ssa_temp_index())) {
        definition_worklist_.Add(definition);
        definition_marks_->Add(definition->ssa_temp_index());
      }
    }
  }
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


void ConstantPropagator::VisitGoto(GotoInstr* instr) {
  SetReachable(instr->successor());

  // Phi value depends on the reachability of a predecessor. We have
  // to revisit phis every time a predecessor becomes reachable.
  for (PhiIterator it(instr->successor()); !it.Done(); it.Advance()) {
    it.Current()->Accept(this);
  }
}


void ConstantPropagator::VisitBranch(BranchInstr* instr) {
  instr->comparison()->Accept(this);

  // The successors may be reachable, but only if this instruction is.  (We
  // might be analyzing it because the constant value of one of its inputs
  // has changed.)
  if (reachable_->Contains(instr->GetBlock()->preorder_number())) {
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


// --------------------------------------------------------------------------
// Analysis of non-definition instructions.  They do not have values so they
// cannot have constant values.
void ConstantPropagator::VisitStoreContext(StoreContextInstr* instr) { }


void ConstantPropagator::VisitCheckStackOverflow(
    CheckStackOverflowInstr* instr) { }


void ConstantPropagator::VisitCheckClass(CheckClassInstr* instr) { }

void ConstantPropagator::VisitGuardFieldClass(GuardFieldClassInstr* instr) { }

void ConstantPropagator::VisitGuardFieldLength(GuardFieldLengthInstr* instr) { }

void ConstantPropagator::VisitCheckSmi(CheckSmiInstr* instr) { }


void ConstantPropagator::VisitCheckEitherNonSmi(
    CheckEitherNonSmiInstr* instr) { }


void ConstantPropagator::VisitCheckArrayBound(CheckArrayBoundInstr* instr) { }


// --------------------------------------------------------------------------
// Analysis of definitions.  Compute the constant value.  If it has changed
// and the definition has input uses, add the definition to the definition
// worklist so that the used can be processed.
void ConstantPropagator::VisitPhi(PhiInstr* instr) {
  // Compute the join over all the reachable predecessor values.
  JoinEntryInstr* block = instr->block();
  Object& value = Object::ZoneHandle(I, Unknown());
  for (intptr_t pred_idx = 0; pred_idx < instr->InputCount(); ++pred_idx) {
    if (reachable_->Contains(
            block->PredecessorAt(pred_idx)->preorder_number())) {
      Join(&value,
           instr->InputAt(pred_idx)->definition()->constant_value());
    }
  }
  SetValue(instr, value);
}


void ConstantPropagator::VisitRedefinition(RedefinitionInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
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


void ConstantPropagator::VisitCurrentContext(CurrentContextInstr* instr) {
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


void ConstantPropagator::VisitPushTemp(PushTempInstr* instr) {
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
    SetValue(instr,
             Smi::Handle(I, Smi::New(
                 result ? instr->if_true() : instr->if_false())));
  }
}


void ConstantPropagator::VisitStrictCompare(StrictCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();

  if (instr->left()->definition() == instr->right()->definition()) {
    // Fold x === x, and x !== x to true/false.
    SetValue(instr, Bool::Get(instr->kind() == Token::kEQ_STRICT));
    return;
  }

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
    case Token::kEQ: return (result == 0);
    case Token::kNE: return (result != 0);
    case Token::kLT: return (result < 0);
    case Token::kGT: return (result > 0);
    case Token::kLTE: return (result <= 0);
    case Token::kGTE: return (result >= 0);
    default:
      UNREACHABLE();
      return false;
  }
}


void ConstantPropagator::VisitTestSmi(TestSmiInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(
          instr->kind(),
          Integer::Handle(I, Integer::Cast(left).BitOp(Token::kBIT_AND,
                                                       Integer::Cast(right))),
          Smi::Handle(I, Smi::New(0)));
      SetValue(instr, result ? Bool::True() : Bool::False());
    } else {
      SetValue(instr, non_constant_);
    }
  }
}


void ConstantPropagator::VisitTestCids(TestCidsInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitEqualityCompare(EqualityCompareInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();

  if (instr->left()->definition() == instr->right()->definition()) {
    // Fold x == x, and x != x to true/false for numbers comparisons.
    if (RawObject::IsIntegerClassId(instr->operation_cid())) {
      return SetValue(instr, Bool::Get(instr->kind() == Token::kEQ));
    }
  }

  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const bool result = CompareIntegers(instr->kind(),
                                          Integer::Cast(left),
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
      const bool result = CompareIntegers(instr->kind(),
                                          Integer::Cast(left),
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


void ConstantPropagator::VisitStringFromCharCode(
    StringFromCharCodeInstr* instr) {
  const Object& o = instr->char_code()->definition()->constant_value();
  if (o.IsNull() || IsNonConstant(o)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(o)) {
    const intptr_t ch_code = Smi::Cast(o).Value();
    ASSERT(ch_code >= 0);
    if (ch_code < Symbols::kMaxOneCharCodeSymbol) {
      RawString** table = Symbols::PredefinedAddress();
      SetValue(instr, String::ZoneHandle(I, table[ch_code]));
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
    const intptr_t result = (str.Length() == 1) ? str.CharAt(0) : -1;
    SetValue(instr, Smi::ZoneHandle(I, Smi::New(result)));
  }
}




void ConstantPropagator::VisitStringInterpolate(StringInterpolateInstr* instr) {
  SetValue(instr, non_constant_);
  return;
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
          SetValue(instr, Smi::Handle(I, Smi::New(str.CharAt(index))));
          return;
        }
      } else if (array_obj.IsArray()) {
        const Array& a = Array::Cast(array_obj);
        if ((a.Length() > index) && a.IsImmutable()) {
          Instance& result = Instance::Handle(I);
          result ^= a.At(index);
          SetValue(instr, result);
          return;
        }
      }
    }
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitStoreIndexed(StoreIndexedInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitStoreInstanceField(
    StoreInstanceFieldInstr* instr) {
  SetValue(instr, instr->value()->definition()->constant_value());
}


void ConstantPropagator::VisitLoadStaticField(LoadStaticFieldInstr* instr) {
  const Field& field = instr->StaticField();
  ASSERT(field.is_static());
  if (field.is_final()) {
    Instance& obj = Instance::Handle(I, field.value());
    ASSERT(obj.raw() != Object::sentinel().raw());
    ASSERT(obj.raw() != Object::transition_sentinel().raw());
    if (obj.IsSmi() || obj.IsOld()) {
      SetValue(instr, obj);
      return;
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
  const Definition* def = instr->value()->definition();
  const Object& value = def->constant_value();
  if (IsNonConstant(value)) {
    const AbstractType& checked_type = instr->type();
    intptr_t value_cid = instr->value()->Type()->ToCid();
    Representation rep = def->representation();
    if ((checked_type.IsFloat32x4Type() && (rep == kUnboxedFloat32x4)) ||
        (checked_type.IsInt32x4Type() && (rep == kUnboxedInt32x4)) ||
        (checked_type.IsDoubleType() && (rep == kUnboxedDouble) &&
         CanUnboxDouble()) ||
        (checked_type.IsIntType() && (rep == kUnboxedMint))) {
      // Ensure that compile time type matches representation.
      ASSERT(((rep == kUnboxedFloat32x4) && (value_cid == kFloat32x4Cid)) ||
             ((rep == kUnboxedInt32x4) && (value_cid == kInt32x4Cid)) ||
             ((rep == kUnboxedDouble) && (value_cid == kDoubleCid)) ||
             ((rep == kUnboxedMint) && (value_cid == kMintCid)));
      // The representation guarantees the type check to be true.
      SetValue(instr, instr->negate_result() ? Bool::False() : Bool::True());
    } else {
      SetValue(instr, non_constant_);
    }
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle instanceof on constants.
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
    SetValue(instr, Smi::ZoneHandle(I, Smi::New(cid)));
    return;
  }
  const Object& object = instr->object()->definition()->constant_value();
  if (IsConstant(object)) {
    SetValue(instr, Smi::ZoneHandle(I, Smi::New(object.GetClassId())));
    return;
  }
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitLoadField(LoadFieldInstr* instr) {
  if ((instr->recognized_kind() == MethodRecognizer::kObjectArrayLength) &&
      (instr->instance()->definition()->IsCreateArray())) {
    Value* num_elements =
        instr->instance()->definition()->AsCreateArray()->num_elements();
    if (num_elements->BindsToConstant() &&
        num_elements->BoundConstant().IsSmi()) {
      intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
      const Object& result = Smi::ZoneHandle(I, Smi::New(length));
      SetValue(instr, result);
      return;
    }
  }

  if (instr->IsImmutableLengthLoad()) {
    ConstantInstr* constant = instr->instance()->definition()->AsConstant();
    if (constant != NULL) {
      if (constant->value().IsString()) {
        SetValue(instr, Smi::ZoneHandle(I,
            Smi::New(String::Cast(constant->value()).Length())));
        return;
      }
      if (constant->value().IsArray()) {
        SetValue(instr, Smi::ZoneHandle(I,
            Smi::New(Array::Cast(constant->value()).Length())));
        return;
      }
    }
  }
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitInstantiateType(InstantiateTypeInstr* instr) {
  const Object& object =
      instr->instantiator()->definition()->constant_value();
  if (IsNonConstant(object)) {
    SetValue(instr, non_constant_);
    return;
  }
  if (IsConstant(object)) {
    if (instr->type().IsTypeParameter()) {
      if (object.IsNull()) {
        SetValue(instr, Type::ZoneHandle(I, Type::DynamicType()));
        return;
      }
      // We could try to instantiate the type parameter and return it if no
      // malformed error is reported.
    }
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitInstantiateTypeArguments(
    InstantiateTypeArgumentsInstr* instr) {
  const Object& object =
      instr->instantiator()->definition()->constant_value();
  if (IsNonConstant(object)) {
    SetValue(instr, non_constant_);
    return;
  }
  if (IsConstant(object)) {
    const intptr_t len = instr->type_arguments().Length();
    if (instr->type_arguments().IsRawInstantiatedRaw(len) &&
        object.IsNull()) {
      SetValue(instr, object);
      return;
    }
    if (instr->type_arguments().IsUninstantiatedIdentity() ||
        instr->type_arguments().CanShareInstantiatorTypeArguments(
            instr->instantiator_class())) {
      SetValue(instr, object);
      return;
    }
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitAllocateContext(AllocateContextInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitCloneContext(CloneContextInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::HandleBinaryOp(Definition* instr,
                                        Token::Kind op_kind,
                                        const Value& left_val,
                                        const Value& right_val) {
  const Object& left = left_val.definition()->constant_value();
  const Object& right = right_val.definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    // TODO(srdjan): Add arithemtic simplifications, e.g, add with 0.
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    if (left.IsInteger() && right.IsInteger()) {
      const Integer& left_int = Integer::Cast(left);
      const Integer& right_int = Integer::Cast(right);
      switch (op_kind) {
        case Token::kTRUNCDIV:
        case Token::kMOD:
          // Check right value for zero.
          if (right_int.AsInt64Value() == 0) {
            SetValue(instr, non_constant_);
            break;
          }
          // Fall through.
        case Token::kADD:
        case Token::kSUB:
        case Token::kMUL: {
          Instance& result = Integer::ZoneHandle(I,
              left_int.ArithmeticOp(op_kind, right_int));
          result = result.CheckAndCanonicalize(NULL);
          ASSERT(!result.IsNull());
          SetValue(instr, result);
          break;
        }
        case Token::kSHL:
        case Token::kSHR:
          if (left.IsSmi() && right.IsSmi()) {
            Instance& result = Integer::ZoneHandle(I,
                Smi::Cast(left_int).ShiftOp(op_kind, Smi::Cast(right_int)));
            result = result.CheckAndCanonicalize(NULL);
            ASSERT(!result.IsNull());
            SetValue(instr, result);
          } else {
            SetValue(instr, non_constant_);
          }
          break;
        case Token::kBIT_AND:
        case Token::kBIT_OR:
        case Token::kBIT_XOR: {
          Instance& result = Integer::ZoneHandle(I,
              left_int.BitOp(op_kind, right_int));
          result = result.CheckAndCanonicalize(NULL);
          ASSERT(!result.IsNull());
          SetValue(instr, result);
          break;
        }
        case Token::kDIV:
          SetValue(instr, non_constant_);
          break;
        default:
          UNREACHABLE();
      }
    } else {
      // TODO(kmillikin): support other types.
      SetValue(instr, non_constant_);
    }
  }
}


void ConstantPropagator::VisitBinarySmiOp(BinarySmiOpInstr* instr) {
  HandleBinaryOp(instr, instr->op_kind(), *instr->left(), *instr->right());
}


void ConstantPropagator::VisitBoxInteger(BoxIntegerInstr* instr) {
  // TODO(kmillikin): Handle box operation.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitUnboxInteger(UnboxIntegerInstr* instr) {
  // TODO(kmillikin): Handle unbox operation.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitBinaryMintOp(BinaryMintOpInstr* instr) {
  HandleBinaryOp(instr, instr->op_kind(), *instr->left(), *instr->right());
}


void ConstantPropagator::VisitShiftMintOp(ShiftMintOpInstr* instr) {
  HandleBinaryOp(instr, instr->op_kind(), *instr->left(), *instr->right());
}


void ConstantPropagator::VisitUnaryMintOp(UnaryMintOpInstr* instr) {
  // TODO(kmillikin): Handle unary operations.
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitUnarySmiOp(UnarySmiOpInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle unary operations.
    SetValue(instr, non_constant_);
  }
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
    SetValue(instr, Double::Handle(I,
        Double::New(Integer::Cast(value).AsDoubleValue(), Heap::kOld)));
  } else if (IsNonConstant(value)) {
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


void ConstantPropagator::VisitMergedMath(MergedMathInstr* instr) {
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


void ConstantPropagator::VisitBinaryDoubleOp(
    BinaryDoubleOpInstr* instr) {
  const Object& left = instr->left()->definition()->constant_value();
  const Object& right = instr->right()->definition()->constant_value();
  if (IsNonConstant(left) || IsNonConstant(right)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(left) && IsConstant(right)) {
    // TODO(kmillikin): Handle binary operation.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBinaryFloat32x4Op(
    BinaryFloat32x4OpInstr* instr) {
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


void ConstantPropagator::VisitFloat64x2Zero(
    Float64x2ZeroInstr* instr) {
  SetValue(instr, non_constant_);
}


void ConstantPropagator::VisitFloat64x2Splat(
    Float64x2SplatInstr* instr) {
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


void ConstantPropagator::VisitUnboxDouble(UnboxDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxDouble(BoxDoubleInstr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitUnboxFloat32x4(UnboxFloat32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxFloat32x4(BoxFloat32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitUnboxFloat64x2(UnboxFloat64x2Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxFloat64x2(BoxFloat64x2Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitUnboxInt32x4(UnboxInt32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::VisitBoxInt32x4(BoxInt32x4Instr* instr) {
  const Object& value = instr->value()->definition()->constant_value();
  if (IsNonConstant(value)) {
    SetValue(instr, non_constant_);
  } else if (IsConstant(value)) {
    // TODO(kmillikin): Handle conversion.
    SetValue(instr, non_constant_);
  }
}


void ConstantPropagator::Analyze() {
  GraphEntryInstr* entry = graph_->graph_entry();
  reachable_->Add(entry->preorder_number());
  block_worklist_.Add(entry);

  while (true) {
    if (block_worklist_.is_empty()) {
      if (definition_worklist_.is_empty()) break;
      Definition* definition = definition_worklist_.RemoveLast();
      definition_marks_->Remove(definition->ssa_temp_index());
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


void ConstantPropagator::VisitBranches() {
  GraphEntryInstr* entry = graph_->graph_entry();
  reachable_->Add(entry->preorder_number());
  block_worklist_.Add(entry);

  while (!block_worklist_.is_empty()) {
    BlockEntryInstr* block = block_worklist_.RemoveLast();
    if (block->IsGraphEntry()) {
      // TODO(fschneider): Improve this approximation. Catch entries are only
      // reachable if a call in the corresponding try-block is reachable.
      for (intptr_t i = 0; i < block->SuccessorCount(); ++i) {
        SetReachable(block->SuccessorAt(i));
      }
      continue;
    }
    Instruction* last = block->last_instruction();
    if (last->IsGoto()) {
      SetReachable(last->AsGoto()->successor());
    } else if (last->IsBranch()) {
      BranchInstr* branch = last->AsBranch();
      // The current block must be reachable.
      ASSERT(reachable_->Contains(branch->GetBlock()->preorder_number()));
      if (branch->constant_target() != NULL) {
        // Found constant target computed by range analysis.
        if (branch->constant_target() == branch->true_successor()) {
          SetReachable(branch->true_successor());
        } else {
          ASSERT(branch->constant_target() == branch->false_successor());
          SetReachable(branch->false_successor());
        }
      } else {
        // No new information: Assume both targets are reachable.
        SetReachable(branch->true_successor());
        SetReachable(branch->false_successor());
      }
    }
  }
}


static bool IsEmptyBlock(BlockEntryInstr* block) {
  return block->next()->IsGoto() &&
      (!block->IsJoinEntry() || (block->AsJoinEntry()->phis() == NULL));
}


// Traverses a chain of empty blocks and returns the first reachable non-empty
// block that is not dominated by the start block. The empty blocks are added
// to the supplied bit vector.
static BlockEntryInstr* FindFirstNonEmptySuccessor(
    TargetEntryInstr* block,
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
  BitVector* empty_blocks = new(I) BitVector(graph_->preorder().length());
  for (BlockIterator b = graph_->postorder_iterator();
       !b.Done();
       b.Advance()) {
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
          GotoInstr* jump = new(I) GotoInstr(if_true->AsJoinEntry());
          jump->InheritDeoptTarget(I, branch);

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

          if (FLAG_trace_constant_propagation) {
            OS::Print("Eliminated branch in B%" Pd " common target B%" Pd "\n",
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
  if (FLAG_trace_constant_propagation) {
    OS::Print("\n==== Before constant propagation ====\n");
    FlowGraphPrinter printer(*graph_);
    printer.PrintBlocks();
  }

  // We will recompute dominators, block ordering, block ids, block last
  // instructions, previous pointers, predecessors, etc. after eliminating
  // unreachable code.  We do not maintain those properties during the
  // transformation.
  for (BlockIterator b = graph_->reverse_postorder_iterator();
       !b.Done();
       b.Advance()) {
    BlockEntryInstr* block = b.Current();
    if (!reachable_->Contains(block->preorder_number())) {
      if (FLAG_trace_constant_propagation) {
        OS::Print("Unreachable B%" Pd "\n", block->block_id());
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
      if ((defn != NULL) &&
          IsConstant(defn->constant_value()) &&
          (defn->constant_value().IsSmi() || defn->constant_value().IsOld()) &&
          !defn->IsConstant() &&
          !defn->IsPushArgument() &&
          !defn->IsStoreIndexed() &&
          !defn->IsStoreInstanceField() &&
          !defn->IsStoreStaticField()) {
        if (FLAG_trace_constant_propagation) {
          OS::Print("Constant v%" Pd " = %s\n",
                    defn->ssa_temp_index(),
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
        join = new(I) JoinEntryInstr(if_false->block_id(),
                                     if_false->try_index());
        join->InheritDeoptTarget(I, if_false);
        if_false->UnuseAllInputs();
        next = if_false->next();
      } else if (!reachable_->Contains(if_false->preorder_number())) {
        ASSERT(if_true->parallel_move() == NULL);
        ASSERT(if_true->loop_info() == NULL);
        join = new(I) JoinEntryInstr(if_true->block_id(),
                                     if_true->try_index());
        join->InheritDeoptTarget(I, if_true);
        if_true->UnuseAllInputs();
        next = if_true->next();
      }

      if (join != NULL) {
        // Replace the branch with a jump to the reachable successor.
        // Drop the comparison, which does not have side effects as long
        // as it is a strict compare (the only one we can determine is
        // constant with the current analysis).
        GotoInstr* jump = new(I) GotoInstr(join);
        jump->InheritDeoptTarget(I, branch);

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
  GrowableArray<BitVector*> dominance_frontier;
  graph_->ComputeDominators(&dominance_frontier);

  if (FLAG_trace_constant_propagation) {
    OS::Print("\n==== After constant propagation ====\n");
    FlowGraphPrinter printer(*graph_);
    printer.PrintBlocks();
  }
}


// Returns true if the given phi has a single input use and
// is used in the environments either at the corresponding block entry or
// at the same instruction where input use is.
static bool PhiHasSingleUse(PhiInstr* phi, Value* use) {
  if ((use->next_use() != NULL) || (phi->input_use_list() != use)) {
    return false;
  }

  BlockEntryInstr* block = phi->block();
  for (Value* env_use = phi->env_use_list();
       env_use != NULL;
       env_use = env_use->next_use()) {
    if ((env_use->instruction() != block) &&
        (env_use->instruction() != use->instruction())) {
      return false;
    }
  }

  return true;
}


bool BranchSimplifier::Match(JoinEntryInstr* block) {
  // Match the pattern of a branch on a comparison whose left operand is a
  // phi from the same block, and whose right operand is a constant.
  //
  //   Branch(Comparison(kind, Phi, Constant))
  //
  // These are the branches produced by inlining in a test context.  Also,
  // the phi has no other uses so they can simply be eliminated.  The block
  // has no other phis and no instructions intervening between the phi and
  // branch so the block can simply be eliminated.
  BranchInstr* branch = block->last_instruction()->AsBranch();
  ASSERT(branch != NULL);
  ComparisonInstr* comparison = branch->comparison();
  Value* left = comparison->left();
  PhiInstr* phi = left->definition()->AsPhi();
  Value* right = comparison->right();
  ConstantInstr* constant =
      (right == NULL) ? NULL : right->definition()->AsConstant();
  return (phi != NULL) &&
      (constant != NULL) &&
      (phi->GetBlock() == block) &&
      PhiHasSingleUse(phi, left) &&
      (block->next() == branch) &&
      (block->phis()->length() == 1);
}


JoinEntryInstr* BranchSimplifier::ToJoinEntry(Isolate* isolate,
                                              TargetEntryInstr* target) {
  // Convert a target block into a join block.  Branches will be duplicated
  // so the former true and false targets become joins of the control flows
  // from all the duplicated branches.
  JoinEntryInstr* join =
      new(isolate) JoinEntryInstr(target->block_id(), target->try_index());
  join->InheritDeoptTarget(isolate, target);
  join->LinkTo(target->next());
  join->set_last_instruction(target->last_instruction());
  target->UnuseAllInputs();
  return join;
}


BranchInstr* BranchSimplifier::CloneBranch(Isolate* isolate,
                                           BranchInstr* branch,
                                           Value* new_left,
                                           Value* new_right) {
  ComparisonInstr* comparison = branch->comparison();
  ComparisonInstr* new_comparison =
      comparison->CopyWithNewOperands(new_left, new_right);
  BranchInstr* new_branch = new(isolate) BranchInstr(new_comparison);
  new_branch->set_is_checked(branch->is_checked());
  return new_branch;
}


void BranchSimplifier::Simplify(FlowGraph* flow_graph) {
  // Optimize some branches that test the value of a phi.  When it is safe
  // to do so, push the branch to each of the predecessor blocks.  This is
  // an optimization when (a) it can avoid materializing a boolean object at
  // the phi only to test its value, and (b) it can expose opportunities for
  // constant propagation and unreachable code elimination.  This
  // optimization is intended to run after inlining which creates
  // opportunities for optimization (a) and before constant folding which
  // can perform optimization (b).

  // Begin with a worklist of join blocks ending in branches.  They are
  // candidates for the pattern below.
  Isolate* isolate = flow_graph->isolate();
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  GrowableArray<BlockEntryInstr*> worklist(postorder.length());
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    if (block->IsJoinEntry() && block->last_instruction()->IsBranch()) {
      worklist.Add(block);
    }
  }

  // Rewrite until no more instance of the pattern exists.
  bool changed = false;
  while (!worklist.is_empty()) {
    // All blocks in the worklist are join blocks (ending with a branch).
    JoinEntryInstr* block = worklist.RemoveLast()->AsJoinEntry();
    ASSERT(block != NULL);

    if (Match(block)) {
      changed = true;

      // The branch will be copied and pushed to all the join's
      // predecessors.  Convert the true and false target blocks into join
      // blocks to join the control flows from all of the true
      // (respectively, false) targets of the copied branches.
      //
      // The converted join block will have no phis, so it cannot be another
      // instance of the pattern.  There is thus no need to add it to the
      // worklist.
      BranchInstr* branch = block->last_instruction()->AsBranch();
      ASSERT(branch != NULL);
      JoinEntryInstr* join_true =
          ToJoinEntry(isolate, branch->true_successor());
      JoinEntryInstr* join_false =
          ToJoinEntry(isolate, branch->false_successor());

      ComparisonInstr* comparison = branch->comparison();
      PhiInstr* phi = comparison->left()->definition()->AsPhi();
      ConstantInstr* constant = comparison->right()->definition()->AsConstant();
      ASSERT(constant != NULL);
      // Copy the constant and branch and push it to all the predecessors.
      for (intptr_t i = 0, count = block->PredecessorCount(); i < count; ++i) {
        GotoInstr* old_goto =
            block->PredecessorAt(i)->last_instruction()->AsGoto();
        ASSERT(old_goto != NULL);

        // Replace the goto in each predecessor with a rewritten branch,
        // rewritten to use the corresponding phi input instead of the phi.
        Value* new_left = phi->InputAt(i)->Copy(isolate);
        Value* new_right = new(isolate) Value(constant);
        BranchInstr* new_branch =
            CloneBranch(isolate, branch, new_left, new_right);
        if (branch->env() == NULL) {
          new_branch->InheritDeoptTarget(isolate, old_goto);
        } else {
          // Take the environment from the branch if it has one.
          new_branch->InheritDeoptTarget(isolate, branch);
          // InheritDeoptTarget gave the new branch's comparison the same
          // deopt id that it gave the new branch.  The id should be the
          // deopt id of the original comparison.
          new_branch->comparison()->SetDeoptId(comparison->GetDeoptId());
          // The phi can be used in the branch's environment.  Rename such
          // uses.
          for (Environment::DeepIterator it(new_branch->env());
               !it.Done();
               it.Advance()) {
            Value* use = it.CurrentValue();
            if (use->definition() == phi) {
              Definition* replacement = phi->InputAt(i)->definition();
              use->RemoveFromUseList();
              use->set_definition(replacement);
              replacement->AddEnvUse(use);
            }
          }
        }

        new_branch->InsertBefore(old_goto);
        new_branch->set_next(NULL);  // Detaching the goto from the graph.
        old_goto->UnuseAllInputs();

        // Update the predecessor block.  We may have created another
        // instance of the pattern so add it to the worklist if necessary.
        BlockEntryInstr* branch_block = new_branch->GetBlock();
        branch_block->set_last_instruction(new_branch);
        if (branch_block->IsJoinEntry()) worklist.Add(branch_block);

        // Connect the branch to the true and false joins, via empty target
        // blocks.
        TargetEntryInstr* true_target =
            new(isolate) TargetEntryInstr(flow_graph->max_block_id() + 1,
                                          block->try_index());
        true_target->InheritDeoptTarget(isolate, join_true);
        TargetEntryInstr* false_target =
            new(isolate) TargetEntryInstr(flow_graph->max_block_id() + 2,
                                          block->try_index());
        false_target->InheritDeoptTarget(isolate, join_false);
        flow_graph->set_max_block_id(flow_graph->max_block_id() + 2);
        *new_branch->true_successor_address() = true_target;
        *new_branch->false_successor_address() = false_target;
        GotoInstr* goto_true = new(isolate) GotoInstr(join_true);
        goto_true->InheritDeoptTarget(isolate, join_true);
        true_target->LinkTo(goto_true);
        true_target->set_last_instruction(goto_true);
        GotoInstr* goto_false = new(isolate) GotoInstr(join_false);
        goto_false->InheritDeoptTarget(isolate, join_false);
        false_target->LinkTo(goto_false);
        false_target->set_last_instruction(goto_false);
      }
      // When all predecessors have been rewritten, the original block is
      // unreachable from the graph.
      phi->UnuseAllInputs();
      branch->UnuseAllInputs();
      block->UnuseAllInputs();
      ASSERT(!phi->HasUses());
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}


static bool IsTrivialBlock(BlockEntryInstr* block, Definition* defn) {
  return (block->IsTargetEntry() && (block->PredecessorCount() == 1)) &&
    ((block->next() == block->last_instruction()) ||
     ((block->next() == defn) && (defn->next() == block->last_instruction())));
}


static void EliminateTrivialBlock(BlockEntryInstr* block,
                                  Definition* instr,
                                  IfThenElseInstr* before) {
  block->UnuseAllInputs();
  block->last_instruction()->UnuseAllInputs();

  if ((block->next() == instr) &&
      (instr->next() == block->last_instruction())) {
    before->previous()->LinkTo(instr);
    instr->LinkTo(before);
  }
}


void IfConverter::Simplify(FlowGraph* flow_graph) {
  Isolate* isolate = flow_graph->isolate();
  bool changed = false;

  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph->postorder();
  for (BlockIterator it(postorder); !it.Done(); it.Advance()) {
    BlockEntryInstr* block = it.Current();
    JoinEntryInstr* join = block->AsJoinEntry();

    // Detect diamond control flow pattern which materializes a value depending
    // on the result of the comparison:
    //
    // B_pred:
    //   ...
    //   Branch if COMP goto (B_pred1, B_pred2)
    // B_pred1: -- trivial block that contains at most one definition
    //   v1 = Constant(...)
    //   goto B_block
    // B_pred2: -- trivial block that contains at most one definition
    //   v2 = Constant(...)
    //   goto B_block
    // B_block:
    //   v3 = phi(v1, v2) -- single phi
    //
    // and replace it with
    //
    // Ba:
    //   v3 = IfThenElse(COMP ? v1 : v2)
    //
    if ((join != NULL) &&
        (join->phis() != NULL) &&
        (join->phis()->length() == 1) &&
        (block->PredecessorCount() == 2)) {
      BlockEntryInstr* pred1 = block->PredecessorAt(0);
      BlockEntryInstr* pred2 = block->PredecessorAt(1);

      PhiInstr* phi = (*join->phis())[0];
      Value* v1 = phi->InputAt(0);
      Value* v2 = phi->InputAt(1);

      if (IsTrivialBlock(pred1, v1->definition()) &&
          IsTrivialBlock(pred2, v2->definition()) &&
          (pred1->PredecessorAt(0) == pred2->PredecessorAt(0))) {
        BlockEntryInstr* pred = pred1->PredecessorAt(0);
        BranchInstr* branch = pred->last_instruction()->AsBranch();
        ComparisonInstr* comparison = branch->comparison();

        // Check if the platform supports efficient branchless IfThenElseInstr
        // for the given combination of comparison and values flowing from
        // false and true paths.
        if (IfThenElseInstr::Supports(comparison, v1, v2)) {
          Value* if_true = (pred1 == branch->true_successor()) ? v1 : v2;
          Value* if_false = (pred2 == branch->true_successor()) ? v1 : v2;

          ComparisonInstr* new_comparison =
              comparison->CopyWithNewOperands(
                  comparison->left()->Copy(isolate),
                  comparison->right()->Copy(isolate));
          IfThenElseInstr* if_then_else = new(isolate) IfThenElseInstr(
              new_comparison,
              if_true->Copy(isolate),
              if_false->Copy(isolate));
          flow_graph->InsertBefore(branch,
                                   if_then_else,
                                   NULL,
                                   FlowGraph::kValue);

          phi->ReplaceUsesWith(if_then_else);

          // Connect IfThenElseInstr to the first instruction in the merge block
          // effectively eliminating diamond control flow.
          // Current block as well as pred1 and pred2 blocks are no longer in
          // the graph at this point.
          if_then_else->LinkTo(join->next());
          pred->set_last_instruction(join->last_instruction());

          // Resulting block must inherit block id from the eliminated current
          // block to guarantee that ordering of phi operands in its successor
          // stays consistent.
          pred->set_block_id(block->block_id());

          // If v1 and v2 were defined inside eliminated blocks pred1/pred2
          // move them out to the place before inserted IfThenElse instruction.
          EliminateTrivialBlock(pred1, v1->definition(), if_then_else);
          EliminateTrivialBlock(pred2, v2->definition(), if_then_else);

          // Update use lists to reflect changes in the graph.
          phi->UnuseAllInputs();
          branch->UnuseAllInputs();
          block->UnuseAllInputs();

          // The graph has changed. Recompute dominators and block orders after
          // this pass is finished.
          changed = true;
        }
      }
    }
  }

  if (changed) {
    // We may have changed the block order and the dominator tree.
    flow_graph->DiscoverBlocks();
    GrowableArray<BitVector*> dominance_frontier;
    flow_graph->ComputeDominators(&dominance_frontier);
  }
}


void FlowGraphOptimizer::EliminateEnvironments() {
  // After this pass we can no longer perform LICM and hoist instructions
  // that can deoptimize.

  flow_graph_->disallow_licm();
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* block = block_order_[i];
    block->RemoveEnvironment();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      Instruction* current = it.Current();
      if (!current->CanDeoptimize()) {
        // TODO(srdjan): --source-lines needs deopt environments to get at
        // the code for this instruction, however, leaving the environment
        // changes code.
        current->RemoveEnvironment();
      }
    }
  }
}


// Right now we are attempting to sink allocation only into
// deoptimization exit. So candidate should only be used in StoreInstanceField
// instructions that write into fields of the allocated object.
// We do not support materialization of the object that has type arguments.
static bool IsAllocationSinkingCandidate(AllocateObjectInstr* alloc) {
  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = use->next_use()) {
    if (!(use->instruction()->IsStoreInstanceField() &&
          (use->use_index() == 0))) {
      return false;
    }
  }

  return true;
}


// Remove the given allocation from the graph. It is not observable.
// If deoptimization occurs the object will be materialized.
static void EliminateAllocation(AllocateObjectInstr* alloc) {
  ASSERT(IsAllocationSinkingCandidate(alloc));

  if (FLAG_trace_optimization) {
    OS::Print("removing allocation from the graph: v%" Pd "\n",
              alloc->ssa_temp_index());
  }

  // As an allocation sinking candidate it is only used in stores to its own
  // fields. Remove these stores.
  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = alloc->input_use_list()) {
    use->instruction()->RemoveFromGraph();
  }

  // There should be no environment uses. The pass replaced them with
  // MaterializeObject instructions.
  ASSERT(alloc->env_use_list() == NULL);
  ASSERT(alloc->input_use_list() == NULL);
  alloc->RemoveFromGraph();
  if (alloc->ArgumentCount() > 0) {
    ASSERT(alloc->ArgumentCount() == 1);
    for (intptr_t i = 0; i < alloc->ArgumentCount(); ++i) {
      alloc->PushArgumentAt(i)->RemoveFromGraph();
    }
  }
}


void AllocationSinking::Optimize() {
  GrowableArray<AllocateObjectInstr*> candidates(5);

  // Collect sinking candidates.
  const GrowableArray<BlockEntryInstr*>& postorder = flow_graph_->postorder();
  for (BlockIterator block_it(postorder);
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      AllocateObjectInstr* alloc = it.Current()->AsAllocateObject();
      if ((alloc != NULL) && IsAllocationSinkingCandidate(alloc)) {
        if (FLAG_trace_optimization) {
          OS::Print("discovered allocation sinking candidate: v%" Pd "\n",
                    alloc->ssa_temp_index());
        }

        // All sinking candidate are known to be not aliased.
        alloc->SetIdentity(kIdentityNotAliased);

        candidates.Add(alloc);
      }
    }
  }

  // Insert MaterializeObject instructions that will describe the state of the
  // object at all deoptimization points. Each inserted materialization looks
  // like this (where v_0 is allocation that we are going to eliminate):
  //   v_1     <- LoadField(v_0, field_1)
  //           ...
  //   v_N     <- LoadField(v_0, field_N)
  //   v_{N+1} <- MaterializeObject(field_1 = v_1, ..., field_N = v_{N})
  for (intptr_t i = 0; i < candidates.length(); i++) {
    InsertMaterializations(candidates[i]);
  }

  // Run load forwarding to eliminate LoadField instructions inserted above.
  // All loads will be successfully eliminated because:
  //   a) they use fields (not offsets) and thus provide precise aliasing
  //      information
  //   b) candidate does not escape and thus its fields is not affected by
  //      external effects from calls.
  LoadOptimizer::OptimizeGraph(flow_graph_);

  if (FLAG_trace_optimization) {
    FlowGraphPrinter::PrintGraph("Sinking", flow_graph_);
  }

  // At this point we have computed the state of object at each deoptimization
  // point and we can eliminate it. Loads inserted above were forwarded so there
  // are no uses of the allocation just as in the begging of the pass.
  for (intptr_t i = 0; i < candidates.length(); i++) {
    EliminateAllocation(candidates[i]);
  }

  // Process materializations and unbox their arguments: materializations
  // are part of the environment and can materialize boxes for double/mint/simd
  // values when needed.
  // TODO(vegorov): handle all box types here.
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    for (intptr_t j = 0; j < mat->InputCount(); j++) {
      Definition* defn = mat->InputAt(j)->definition();
      if (defn->IsBoxDouble() ||
          defn->IsBoxFloat32x4() ||
          defn->IsBoxInt32x4()) {
        mat->InputAt(j)->BindTo(defn->InputAt(0)->definition());
      }
    }
  }
}


// Remove materializations from the graph. Register allocator will treat them
// as part of the environment not as a real instruction.
void AllocationSinking::DetachMaterializations() {
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    ASSERT(materializations_[i]->input_use_list() == NULL);
    materializations_[i]->previous()->LinkTo(materializations_[i]->next());
  }
}


// Add a field/offset to the list of fields if it is not yet present there.
static void AddSlot(ZoneGrowableArray<const Object*>* slots,
                    const Object& slot) {
  for (intptr_t i = 0; i < slots->length(); i++) {
    if ((*slots)[i]->raw() == slot.raw()) {
      return;
    }
  }
  slots->Add(&slot);
}


// Add given instruction to the list of the instructions if it is not yet
// present there.
static void AddInstruction(GrowableArray<Instruction*>* exits,
                           Instruction* exit) {
  ASSERT(!exit->IsGraphEntry());
  for (intptr_t i = 0; i < exits->length(); i++) {
    if ((*exits)[i] == exit) {
      return;
    }
  }
  exits->Add(exit);
}


// Insert MaterializeObject instruction for the given allocation before
// the given instruction that can deoptimize.
void AllocationSinking::CreateMaterializationAt(
    Instruction* exit,
    AllocateObjectInstr* alloc,
    const Class& cls,
    const ZoneGrowableArray<const Object*>& slots) {
  ZoneGrowableArray<Value*>* values =
      new(I) ZoneGrowableArray<Value*>(slots.length());

  // Insert load instruction for every field.
  for (intptr_t i = 0; i < slots.length(); i++) {
    LoadFieldInstr* load = slots[i]->IsField()
        ? new(I) LoadFieldInstr(
            new(I) Value(alloc),
            &Field::Cast(*slots[i]),
            AbstractType::ZoneHandle(I),
            alloc->token_pos())
        : new(I) LoadFieldInstr(
            new(I) Value(alloc),
            Smi::Cast(*slots[i]).Value(),
            AbstractType::ZoneHandle(I),
            alloc->token_pos());
    flow_graph_->InsertBefore(
        exit, load, NULL, FlowGraph::kValue);
    values->Add(new(I) Value(load));
  }

  MaterializeObjectInstr* mat =
      new(I) MaterializeObjectInstr(cls, slots, values);
  flow_graph_->InsertBefore(exit, mat, NULL, FlowGraph::kValue);

  // Replace all mentions of this allocation with a newly inserted
  // MaterializeObject instruction.
  // We must preserve the identity: all mentions are replaced by the same
  // materialization.
  for (Environment::DeepIterator env_it(exit->env());
       !env_it.Done();
       env_it.Advance()) {
    Value* use = env_it.CurrentValue();
    if (use->definition() == alloc) {
      use->RemoveFromUseList();
      use->set_definition(mat);
      mat->AddEnvUse(use);
    }
  }

  // Record inserted materialization.
  materializations_.Add(mat);
}


void AllocationSinking::InsertMaterializations(AllocateObjectInstr* alloc) {
  // Collect all fields that are written for this instance.
  ZoneGrowableArray<const Object*>* slots =
      new(I) ZoneGrowableArray<const Object*>(5);

  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = use->next_use()) {
    StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
    if (!store->field().IsNull()) {
      AddSlot(slots, store->field());
    } else {
      AddSlot(slots, Smi::ZoneHandle(I, Smi::New(store->offset_in_bytes())));
    }
  }

  if (alloc->ArgumentCount() > 0) {
    ASSERT(alloc->ArgumentCount() == 1);
    intptr_t type_args_offset = alloc->cls().type_arguments_field_offset();
    AddSlot(slots, Smi::ZoneHandle(I, Smi::New(type_args_offset)));
  }

  // Collect all instructions that mention this object in the environment.
  GrowableArray<Instruction*> exits(10);
  for (Value* use = alloc->env_use_list();
       use != NULL;
       use = use->next_use()) {
    AddInstruction(&exits, use->instruction());
  }

  // Insert materializations at environment uses.
  for (intptr_t i = 0; i < exits.length(); i++) {
    CreateMaterializationAt(exits[i], alloc, alloc->cls(), *slots);
  }
}


}  // namespace dart
