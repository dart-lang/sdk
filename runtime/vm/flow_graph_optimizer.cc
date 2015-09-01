// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/cha.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_range_analysis.h"
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

DEFINE_FLAG(int, getter_setter_ratio, 13,
    "Ratio of getter/setter usage used for double field unboxing heuristics");
DEFINE_FLAG(bool, guess_other_cid, true,
    "Artificially create type feedback for arithmetic etc. operations"
    " by guessing the other unknown argument cid");
DEFINE_FLAG(bool, load_cse, true, "Use redundant load elimination.");
DEFINE_FLAG(bool, dead_store_elimination, true, "Eliminate dead stores");
DEFINE_FLAG(int, max_polymorphic_checks, 4,
    "Maximum number of polymorphic check, otherwise it is megamorphic.");
DEFINE_FLAG(int, max_equality_polymorphic_checks, 32,
    "Maximum number of polymorphic checks in equality operator,"
    " otherwise use megamorphic dispatch.");
DEFINE_FLAG(bool, merge_sin_cos, false, "Merge sin/cos into sincos");
DEFINE_FLAG(bool, trace_load_optimization, false,
    "Print live sets for load optimization pass.");
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DEFINE_FLAG(bool, truncating_left_shift, true,
    "Optimize left shift to truncate if possible");
DEFINE_FLAG(bool, use_cha_deopt, true,
    "Use class hierarchy analysis even if it can cause deoptimization.");
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
DEFINE_FLAG(bool, trace_smi_widening, false, "Trace Smi->Int32 widening pass.");
#endif

DECLARE_FLAG(bool, polymorphic_with_deopt);
DECLARE_FLAG(bool, source_lines);
DECLARE_FLAG(bool, trace_cha);
DECLARE_FLAG(bool, trace_field_guards);
DECLARE_FLAG(bool, trace_type_check_elimination);
DECLARE_FLAG(bool, warn_on_javascript_compatibility);

// Quick access to the current isolate and zone.
#define I (isolate())
#define Z (zone())

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}


static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}


static bool ShouldInlineInt64ArrayOps() {
#if defined(TARGET_ARCH_X64)
  return true;
#endif
  return false;
}

static bool CanConvertUnboxedMintToDouble() {
#if defined(TARGET_ARCH_IA32)
  return true;
#else
  // ARM does not have a short instruction sequence for converting int64 to
  // double.
  // TODO(johnmccutchan): Investigate possibility on MIPS once
  // mints are implemented there.
  return false;
#endif
}


// Optimize instance calls using ICData.
void FlowGraphOptimizer::ApplyICData() {
  VisitBlocks();
}


void FlowGraphOptimizer::PopulateWithICData() {
  ASSERT(current_iterator_ == NULL);
  for (intptr_t i = 0; i < block_order_.length(); ++i) {
    BlockEntryInstr* entry = block_order_[i];
    ForwardInstructionIterator it(entry);
    for (; !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (instr->IsInstanceCall()) {
        InstanceCallInstr* call = instr->AsInstanceCall();
        if (!call->HasICData()) {
          const Array& arguments_descriptor =
              Array::Handle(zone(),
                  ArgumentsDescriptor::New(call->ArgumentCount(),
                                           call->argument_names()));
          const ICData& ic_data = ICData::ZoneHandle(zone(), ICData::New(
              function(), call->function_name(),
              arguments_descriptor, call->deopt_id(),
              call->checked_argument_count()));
          call->set_ic_data(&ic_data);
        }
      }
    }
    current_iterator_ = NULL;
  }
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


bool FlowGraphOptimizer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  if (call->ic_data()->NumberOfUsedChecks() > 0) {
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
    if (FLAG_guess_other_cid) {
      const intptr_t cid_0 = class_ids[0];
      const intptr_t cid_1 = class_ids[1];
      if ((cid_0 == kDynamicCid) && (IsNumberCid(cid_1))) {
        class_ids[0] = cid_1;
      } else if (IsNumberCid(cid_0) && (cid_1 == kDynamicCid)) {
        class_ids[1] = cid_0;
      }
    }
  }

  bool all_cids_known = true;
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    if (class_ids[i] == kDynamicCid) {
      // Not all cid-s known.
      all_cids_known = false;
      break;
    }
  }

  if (all_cids_known) {
    const Array& args_desc_array = Array::Handle(Z,
        ArgumentsDescriptor::New(call->ArgumentCount(),
                                 call->argument_names()));
    ArgumentsDescriptor args_desc(args_desc_array);
    const Class& receiver_class = Class::Handle(Z,
        isolate()->class_table()->At(class_ids[0]));
    const Function& function = Function::Handle(Z,
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
    const ICData& ic_data = ICData::ZoneHandle(Z,
        ICData::NewFrom(*call->ic_data(), class_ids.length()));
    if (class_ids.length() > 1) {
      ic_data.AddCheck(class_ids, function);
    } else {
      ASSERT(class_ids.length() == 1);
      ic_data.AddReceiverCheck(class_ids[0], function);
    }
    call->set_ic_data(&ic_data);
    return true;
  }

  // Check if getter or setter in function's class and class is currently leaf.
  if ((call->token_kind() == Token::kGET) ||
      (call->token_kind() == Token::kSET)) {
    const Class& owner_class = Class::Handle(Z, function().Owner());
    if (!owner_class.is_abstract() &&
        !CHA::HasSubclasses(owner_class) &&
        !CHA::IsImplemented(owner_class)) {
      const Array& args_desc_array = Array::Handle(Z,
          ArgumentsDescriptor::New(call->ArgumentCount(),
                                   call->argument_names()));
      ArgumentsDescriptor args_desc(args_desc_array);
      const Function& function = Function::Handle(Z,
          Resolver::ResolveDynamicForReceiverClass(owner_class,
                                                   call->function_name(),
                                                   args_desc));
      if (function.IsNull()) {
        return false;
      }
      const ICData& ic_data = ICData::ZoneHandle(Z,
          ICData::NewFrom(*call->ic_data(), class_ids.length()));
      ic_data.AddReceiverCheck(owner_class.id(), function);
      call->set_ic_data(&ic_data);
      return true;
    }
  }

  return false;
}


const ICData& FlowGraphOptimizer::TrySpecializeICData(const ICData& ic_data,
                                                      intptr_t cid) {
  ASSERT(ic_data.NumArgsTested() == 1);

  if ((ic_data.NumberOfUsedChecks() == 1) && ic_data.HasReceiverClassId(cid)) {
    return ic_data;  // Nothing to do
  }

  const Function& function =
      Function::Handle(Z, ic_data.GetTargetForReceiverClassId(cid));
  // TODO(fschneider): Try looking up the function on the class if it is
  // not found in the ICData.
  if (!function.IsNull()) {
    const ICData& new_ic_data = ICData::ZoneHandle(Z, ICData::New(
        Function::Handle(Z, ic_data.owner()),
        String::Handle(Z, ic_data.target_name()),
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
  if (!FLAG_polymorphic_with_deopt) {
    // Specialization adds receiver checks which can lead to deoptimization.
    return;
  }
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
      new(Z) PolymorphicInstanceCallInstr(call->instance_call(),
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
  smi_shift_left->mark_truncating();
  ASSERT(bit_and_instr->IsBinarySmiOp() || bit_and_instr->IsBinaryMintOp());
  if (bit_and_instr->IsBinaryMintOp()) {
    // Replace Mint op with Smi op.
    BinarySmiOpInstr* smi_op = new(Z) BinarySmiOpInstr(
        Token::kBIT_AND,
        new(Z) Value(left_instr),
        new(Z) Value(right_instr),
        Isolate::kNoDeoptId);  // BIT_AND cannot deoptimize.
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
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(ix)));
  LoadIndexedInstr* load =
      new(Z) LoadIndexedInstr(new(Z) Value(instr),
                                      new(Z) Value(index_instr),
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
      new(Z) ExtractNthOutputInstr(new(Z) Value(instr), index, rep, cid);
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

        ZoneGrowableArray<Value*>* args = new(Z) ZoneGrowableArray<Value*>(2);
        args->Add(new(Z) Value(curr_instr->left()->definition()));
        args->Add(new(Z) Value(curr_instr->right()->definition()));

        // Replace with TruncDivMod.
        MergedMathInstr* div_mod = new(Z) MergedMathInstr(
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
  if (!FlowGraphCompiler::SupportsSinCos() || !CanUnboxDouble() ||
      !FLAG_merge_sin_cos) {
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
    const intptr_t other_kind = (kind == MathUnaryInstr::kSin) ?
        MathUnaryInstr::kCos : MathUnaryInstr::kSin;
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
        ZoneGrowableArray<Value*>* args = new(Z) ZoneGrowableArray<Value*>(1);
        args->Add(new(Z) Value(curr_instr->value()->definition()));
        // Replace with SinCos.
        MergedMathInstr* sin_cos =
            new(Z) MergedMathInstr(args,
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
      ISL_Print("Replacing v%" Pd " with v%" Pd "\n",
                current_defn->ssa_temp_index(),
                replacement_defn->ssa_temp_index());
    }
  } else if (FLAG_trace_optimization) {
    if (current_defn == NULL) {
      ISL_Print("Removing %s\n", current->DebugName());
    } else {
      ASSERT(!current_defn->HasUses());
      ISL_Print("Removing v%" Pd ".\n", current_defn->ssa_temp_index());
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
      if (current->HasUnmatchedInputRepresentations()) {
        // Can't canonicalize this instruction until all conversions for its
        // inputs are inserted.
        continue;
      }

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


static bool IsUnboxedInteger(Representation rep) {
  return (rep == kUnboxedInt32) ||
         (rep == kUnboxedUint32) ||
         (rep == kUnboxedMint);
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
  if (IsUnboxedInteger(from) && IsUnboxedInteger(to)) {
    const intptr_t deopt_id = (to == kUnboxedInt32) && (deopt_target != NULL) ?
      deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = new(Z) UnboxedIntConverterInstr(from,
                                                to,
                                                use->CopyWithType(),
                                                deopt_id);
  } else if ((from == kUnboxedInt32) && (to == kUnboxedDouble)) {
    converted = new Int32ToDoubleInstr(use->CopyWithType());
  } else if ((from == kUnboxedMint) &&
             (to == kUnboxedDouble) &&
             CanConvertUnboxedMintToDouble()) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
      deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT(CanUnboxDouble());
    converted = new MintToDoubleInstr(use->CopyWithType(), deopt_id);
  } else if ((from == kTagged) && Boxing::Supports(to)) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
      deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    converted = UnboxInstr::Create(to, use->CopyWithType(), deopt_id);
  } else if ((to == kTagged) && Boxing::Supports(from)) {
    converted = BoxInstr::Create(from, use->CopyWithType());
  } else {
    // We have failed to find a suitable conversion instruction.
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    const intptr_t deopt_id = (deopt_target != NULL) ?
      deopt_target->DeoptimizationTarget() : Isolate::kNoDeoptId;
    ASSERT(Boxing::Supports(from));
    ASSERT(Boxing::Supports(to));
    Definition* boxed = BoxInstr::Create(from, use->CopyWithType());
    use->BindTo(boxed);
    InsertBefore(insert_before, boxed, NULL, FlowGraph::kValue);
    converted = UnboxInstr::Create(to, new(Z) Value(boxed), deopt_id);
  }
  ASSERT(converted != NULL);
  InsertBefore(insert_before, converted, use->instruction()->env(),
               FlowGraph::kValue);
  if (is_environment_use) {
    use->BindToEnvironment(converted);
  } else {
    use->BindTo(converted);
  }

  if ((to == kUnboxedInt32) && (phi != NULL)) {
    // Int32 phis are unboxed optimistically. Ensure that unboxing
    // has deoptimization target attached from the goto instruction.
    flow_graph_->CopyDeoptTarget(converted, insert_before);
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
  if (from_rep == to_rep) {
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

  if (flow_graph()->graph_entry()->SuccessorCount() > 1) {
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
}


static void UnboxPhi(PhiInstr* phi) {
  Representation unboxed = phi->representation();

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
    case kFloat64x2Cid:
      if (ShouldInlineSimd()) {
        unboxed = kUnboxedFloat64x2;
      }
      break;
  }

  if ((kSmiBits < 32) &&
      (unboxed == kTagged) &&
      phi->Type()->IsInt() &&
      RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt32)) {
    // On 32-bit platforms conservatively unbox phis that:
    //   - are proven to be of type Int;
    //   - fit into 32bits range;
    //   - have either constants or Box() operations as inputs;
    //   - have at least one Box() operation as an input;
    //   - are used in at least 1 Unbox() operation.
    bool should_unbox = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsBox() &&
          RangeUtils::Fits(input->range(),
                           RangeBoundary::kRangeBoundaryInt32)) {
        should_unbox = true;
      } else if (!input->IsConstant()) {
        should_unbox = false;
        break;
      }
    }

    if (should_unbox) {
      // We checked inputs. Check if phi is used in at least one unbox
      // operation.
      bool has_unboxed_use = false;
      for (Value* use = phi->input_use_list();
           use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        if (instr->IsUnbox()) {
          has_unboxed_use = true;
          break;
        } else if (IsUnboxedInteger(
            instr->RequiredInputRepresentation(use->use_index()))) {
          has_unboxed_use = true;
          break;
        }
      }

      if (!has_unboxed_use) {
        should_unbox = false;
      }
    }

    if (should_unbox) {
      unboxed = kUnboxedInt32;
    }
  }

  phi->set_representation(unboxed);
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


static bool ClassIdIsOneOf(intptr_t class_id,
                           const GrowableArray<intptr_t>& class_ids) {
  for (intptr_t i = 0; i < class_ids.length(); i++) {
    ASSERT(class_ids[i] != kIllegalCid);
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
  if (ic_data.NumArgsTested() != 2) {
    return false;
  }
  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      ic_data.GetCheckAt(i, &class_ids, &target);
      ASSERT(class_ids.length() == 2);
      if (!ClassIdIsOneOf(class_ids[0], receiver_class_ids) ||
          !ClassIdIsOneOf(class_ids[1], argument_class_ids)) {
        return false;
      }
    }
  }
  return true;
}


static bool ICDataHasReceiverArgumentClassIds(const ICData& ic_data,
                                              intptr_t receiver_class_id,
                                              intptr_t argument_class_id) {
  if (ic_data.NumArgsTested() != 2) {
    return false;
  }
  Function& target = Function::Handle();
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      GrowableArray<intptr_t> class_ids;
      ic_data.GetCheckAt(i, &class_ids, &target);
      ASSERT(class_ids.length() == 2);
      if ((class_ids[0] == receiver_class_id) &&
          (class_ids[1] == argument_class_id)) {
        return true;
      }
    }
  }
  return false;
}


static bool HasOnlyOneSmi(const ICData& ic_data) {
  return (ic_data.NumberOfUsedChecks() == 1)
      && ic_data.HasReceiverClassId(kSmiCid);
}


static bool HasOnlySmiOrMint(const ICData& ic_data) {
  if (ic_data.NumberOfUsedChecks() == 1) {
    return ic_data.HasReceiverClassId(kSmiCid)
        || ic_data.HasReceiverClassId(kMintCid);
  }
  return (ic_data.NumberOfUsedChecks() == 2)
      && ic_data.HasReceiverClassId(kSmiCid)
      && ic_data.HasReceiverClassId(kMintCid);
}


static bool HasOnlyTwoOf(const ICData& ic_data, intptr_t cid) {
  if (ic_data.NumberOfUsedChecks() != 1) {
    return false;
  }
  GrowableArray<intptr_t> first;
  GrowableArray<intptr_t> second;
  ic_data.GetUsedCidsForTwoArgs(&first, &second);
  return (first[0] == cid) && (second[0] == cid);
}

// Returns false if the ICData contains anything other than the 4 combinations
// of Mint and Smi for the receiver and argument classes.
static bool HasTwoMintOrSmi(const ICData& ic_data) {
  GrowableArray<intptr_t> first;
  GrowableArray<intptr_t> second;
  ic_data.GetUsedCidsForTwoArgs(&first, &second);
  for (intptr_t i = 0; i < first.length(); i++) {
    if ((first[i] != kSmiCid) && (first[i] != kMintCid)) {
      return false;
    }
    if ((second[i] != kSmiCid) && (second[i] != kMintCid)) {
      return false;
    }
  }
  return true;
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
  return (ic_data.NumberOfUsedChecks() == 1)
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
  return HasTwoDoubleOrSmi(ic_data);
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
                 new(Z) CheckSmiInstr(new(Z) Value(to_check),
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
  if ((unary_checks.NumberOfUsedChecks() == 1) &&
      unary_checks.HasReceiverClassId(kSmiCid)) {
    return new(Z) CheckSmiInstr(new(Z) Value(to_check),
                                deopt_id,
                                token_pos);
  }
  return new(Z) CheckClassInstr(
      new(Z) Value(to_check), deopt_id, unary_checks, token_pos);
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
                ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks()),
                call->deopt_id(),
                call->env(),
                call);
}


static bool ArgIsAlways(intptr_t cid,
                        const ICData& ic_data,
                        intptr_t arg_number) {
  ASSERT(ic_data.NumArgsTested() > arg_number);
  if (ic_data.NumberOfUsedChecks() == 0) {
    return false;
  }
  const intptr_t num_checks = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < num_checks; i++) {
    if (ic_data.IsUsedAt(i) && ic_data.GetClassIdAt(i, arg_number) != cid) {
      return false;
    }
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

    case MethodRecognizer::kInt64ArrayGetIndexed:
    case MethodRecognizer::kInt64ArraySetIndexed:
      return kTypedDataInt64ArrayCid;

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


bool FlowGraphOptimizer::TryReplaceWithIndexedOp(InstanceCallInstr* call) {
  // Check for monomorphic IC data.
  if (!call->HasICData()) return false;
  const ICData& ic_data =
      ICData::Handle(Z, call->ic_data()->AsUnaryClassChecks());
  if (ic_data.NumberOfChecks() != 1) {
    return false;
  }
  return TryReplaceInstanceCallWithInline(call);
}


bool FlowGraphOptimizer::InlineSetIndexed(
    MethodRecognizer::Kind kind,
    const Function& target,
    Instruction* call,
    Definition* receiver,
    intptr_t token_pos,
    const ICData& value_check,
    TargetEntryInstr** entry,
    Definition** last) {
  intptr_t array_cid = MethodKindToCid(kind);
  ASSERT(array_cid != kIllegalCid);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  Definition* stored_value = call->ArgumentAt(2);

  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;
  if (I->flags().type_checks()) {
    // Only type check for the value. A type check for the index is not
    // needed here because we insert a deoptimizing smi-check for the case
    // the index is not a smi.
    const AbstractType& value_type =
        AbstractType::ZoneHandle(Z, target.ParameterTypeAt(2));
    Definition* instantiator = NULL;
    Definition* type_args = NULL;
    switch (array_cid) {
      case kArrayCid:
      case kGrowableObjectArrayCid: {
        const Class& instantiator_class =  Class::Handle(Z, target.Owner());
        intptr_t type_arguments_field_offset =
            instantiator_class.type_arguments_field_offset();
        LoadFieldInstr* load_type_args =
            new(Z) LoadFieldInstr(new(Z) Value(array),
                                  type_arguments_field_offset,
                                  Type::ZoneHandle(Z),  // No type.
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
      case kTypedDataInt64ArrayCid:
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
        new(Z) AssertAssignableInstr(token_pos,
                                     new(Z) Value(stored_value),
                                     new(Z) Value(instantiator),
                                     new(Z) Value(type_args),
                                     value_type,
                                     Symbols::Value(),
                                     call->deopt_id());
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

  // No need to class check stores to Int32 and Uint32 arrays because
  // we insert unboxing instructions below which include a class check.
  if ((array_cid != kTypedDataUint32ArrayCid) &&
      (array_cid != kTypedDataInt32ArrayCid) &&
      !value_check.IsNull()) {
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
        new(Z) DoubleToFloatInstr(
            new(Z) Value(stored_value), call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    NULL,
                                    FlowGraph::kValue);
  } else if (array_cid == kTypedDataInt32ArrayCid) {
    stored_value = new(Z) UnboxInt32Instr(
        UnboxInt32Instr::kTruncate,
        new(Z) Value(stored_value),
        call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    call->env(),
                                    FlowGraph::kValue);
  } else if (array_cid == kTypedDataUint32ArrayCid) {
    stored_value = new(Z) UnboxUint32Instr(
        new(Z) Value(stored_value),
        call->deopt_id());
    ASSERT(stored_value->AsUnboxInteger()->is_truncating());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    call->env(),
                                    FlowGraph::kValue);
  }

  const intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new(Z) StoreIndexedInstr(new(Z) Value(array),
                                   new(Z) Value(index),
                                   new(Z) Value(stored_value),
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
  ICData& value_check = ICData::ZoneHandle(Z);
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
      return InlineGetIndexed(kind, call, receiver, entry, last);
    case MethodRecognizer::kFloat32ArrayGetIndexed:
    case MethodRecognizer::kFloat64ArrayGetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineGetIndexed(kind, call, receiver, entry, last);
    case MethodRecognizer::kFloat32x4ArrayGetIndexed:
    case MethodRecognizer::kFloat64x2ArrayGetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineGetIndexed(kind, call, receiver, entry, last);
    case MethodRecognizer::kInt32ArrayGetIndexed:
    case MethodRecognizer::kUint32ArrayGetIndexed:
      if (!CanUnboxInt32()) return false;
      return InlineGetIndexed(kind, call, receiver, entry, last);

    case MethodRecognizer::kInt64ArrayGetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineGetIndexed(kind, call, receiver, entry, last);
    // Recognized []= operators.
    case MethodRecognizer::kObjectArraySetIndexed:
    case MethodRecognizer::kGrowableArraySetIndexed:
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kInt8ArraySetIndexed:
    case MethodRecognizer::kUint8ArraySetIndexed:
    case MethodRecognizer::kUint8ClampedArraySetIndexed:
    case MethodRecognizer::kExternalUint8ArraySetIndexed:
    case MethodRecognizer::kExternalUint8ClampedArraySetIndexed:
    case MethodRecognizer::kInt16ArraySetIndexed:
    case MethodRecognizer::kUint16ArraySetIndexed:
      // Optimistically assume Smi.
      if (ic_data.HasDeoptReason(ICData::kDeoptCheckSmi)) {
        // Optimistic assumption failed at least once.
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForCid(kSmiCid, target);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kInt32ArraySetIndexed:
    case MethodRecognizer::kUint32ArraySetIndexed: {
      // Value check not needed for Int32 and Uint32 arrays because they
      // implicitly contain unboxing instructions which check for right type.
      ICData& value_check = ICData::Handle();
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    }
    case MethodRecognizer::kInt64ArraySetIndexed:
      if (!ShouldInlineInt64ArrayOps()) {
        return false;
      }
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kFloat32ArraySetIndexed:
    case MethodRecognizer::kFloat64ArraySetIndexed:
      if (!CanUnboxDouble()) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForCid(kDoubleCid, target);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kFloat32x4ArraySetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForCid(kFloat32x4Cid, target);

      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kFloat64x2ArraySetIndexed:
      if (!ShouldInlineSimd()) {
        return false;
      }
      value_check = ic_data.AsUnaryClassChecksForCid(kFloat64x2Cid, target);
      return InlineSetIndexed(kind, target, call, receiver, token_pos,
                              value_check, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt8:
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataInt8ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint8:
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataUint8ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt16:
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataInt16ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint16:
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataUint16ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataInt32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetUint32:
      if (!CanUnboxInt32()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataUint32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat32ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat64ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataFloat32x4ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseGetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseLoad(call, receiver, receiver_cid,
                                     kTypedDataInt32x4ArrayCid,
                                     ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt8:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt8ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint8:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint8ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt16:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt16ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint16:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint16ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetUint32:
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataUint32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat32ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat64:
      if (!CanUnboxDouble()) {
        return false;
      }
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat64ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetFloat32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataFloat32x4ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kByteArrayBaseSetInt32x4:
      if (!ShouldInlineSimd()) {
        return false;
      }
      return InlineByteArrayBaseStore(target, call, receiver, receiver_cid,
                                      kTypedDataInt32x4ArrayCid,
                                      ic_data, entry, last);
    case MethodRecognizer::kStringBaseCodeUnitAt:
      return InlineStringCodeUnitAt(call, receiver_cid, entry, last);
    case MethodRecognizer::kStringBaseCharAt:
      return InlineStringBaseCharAt(call, receiver_cid, entry, last);
    case MethodRecognizer::kDoubleAdd:
      return InlineDoubleOp(Token::kADD, call, entry, last);
    case MethodRecognizer::kDoubleSub:
      return InlineDoubleOp(Token::kSUB, call, entry, last);
    case MethodRecognizer::kDoubleMul:
      return InlineDoubleOp(Token::kMUL, call, entry, last);
    case MethodRecognizer::kDoubleDiv:
      return InlineDoubleOp(Token::kDIV, call, entry, last);
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
      new(Z) CheckSmiInstr(new(Z) Value(index),
                           call->deopt_id(),
                           call->token_pos()),
      call->env(),
      FlowGraph::kEffect);

  // Insert array length load and bounds check.
  LoadFieldInstr* length =
      new(Z) LoadFieldInstr(
          new(Z) Value(*array),
          CheckArrayBoundInstr::LengthOffsetFor(array_cid),
          Type::ZoneHandle(Z, Type::SmiType()),
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
                                   new(Z) CheckArrayBoundInstr(
                                       new(Z) Value(length),
                                       new(Z) Value(index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  if (array_cid == kGrowableObjectArrayCid) {
    // Insert data elements load.
    LoadFieldInstr* elements =
        new(Z) LoadFieldInstr(
            new(Z) Value(*array),
            GrowableObjectArray::data_offset(),
            Type::ZoneHandle(Z, Type::DynamicType()),
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
        new(Z) LoadUntaggedInstr(new(Z) Value(*array),
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
                                          TargetEntryInstr** entry,
                                          Definition** last) {
  intptr_t array_cid = MethodKindToCid(kind);
  ASSERT(array_cid != kIllegalCid);

  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineIndexedOp(call,
                                     array_cid,
                                     &array,
                                     index,
                                     &cursor);

  intptr_t deopt_id = Isolate::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Isolate::kNoDeoptId : call->deopt_id();
  }

  // Array load and return.
  intptr_t index_scale = Instance::ElementSizeFor(array_cid);
  *last = new(Z) LoadIndexedInstr(new(Z) Value(array),
                                  new(Z) Value(index),
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
    *last = new(Z) FloatToDoubleInstr(new(Z) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
                           FlowGraph::kValue);
  }
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
          Smi::ZoneHandle(Z, Smi::New(static_cast<intptr_t>(str.CharAt(0)))));
      left_val = new(Z) Value(char_code_left);
    } else if (left->IsStringFromCharCode()) {
      // Use input of string-from-charcode as left value.
      StringFromCharCodeInstr* instr = left->AsStringFromCharCode();
      left_val = new(Z) Value(instr->char_code()->definition());
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
      right_val = new(Z) Value(right_instr->char_code()->definition());
      to_remove_right = right_instr;
    } else {
      const ICData& unary_checks_1 =
          ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecksForArgNr(1));
      AddCheckClass(right,
                    unary_checks_1,
                    call->deopt_id(),
                    call->env(),
                    call);
      // String-to-char-code instructions returns -1 (illegal charcode) if
      // string is not of length one.
      StringToCharCodeInstr* char_code_right =
          new(Z) StringToCharCodeInstr(new(Z) Value(right), kOneByteStringCid);
      InsertBefore(call, char_code_right, call->env(), FlowGraph::kValue);
      right_val = new(Z) Value(char_code_right);
    }

    // Comparing char-codes instead of strings.
    EqualityCompareInstr* comp =
        new(Z) EqualityCompareInstr(call->token_pos(),
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
                 new(Z) CheckSmiInstr(new(Z) Value(left),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    InsertBefore(call,
                 new(Z) CheckSmiInstr(new(Z) Value(right),
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
                     new(Z) CheckEitherNonSmiInstr(
                         new(Z) Value(left),
                         new(Z) Value(right),
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
          ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
      AddCheckClass(left,
                    unary_checks_0,
                    call->deopt_id(),
                    call->env(),
                    call);

      const ICData& unary_checks_1 =
          ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecksForArgNr(1));
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
            new(Z) StrictCompareInstr(call->token_pos(),
                                      Token::kEQ_STRICT,
                                      new(Z) Value(left),
                                      new(Z) Value(right),
                                      false);  // No number check.
        ReplaceCall(call, comp);
        return true;
      }
      return false;
    }
  }
  ASSERT(cid != kIllegalCid);
  EqualityCompareInstr* comp = new(Z) EqualityCompareInstr(call->token_pos(),
                                                           op_kind,
                                                           new(Z) Value(left),
                                                           new(Z) Value(right),
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
                 new(Z) CheckSmiInstr(new(Z) Value(left),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    InsertBefore(call,
                 new(Z) CheckSmiInstr(new(Z) Value(right),
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
                     new(Z) CheckEitherNonSmiInstr(
                         new(Z) Value(left),
                         new(Z) Value(right),
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
  RelationalOpInstr* comp = new(Z) RelationalOpInstr(call->token_pos(),
                                                     op_kind,
                                                     new(Z) Value(left),
                                                     new(Z) Value(right),
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
    case Token::kMUL:
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
        ASSERT(op_kind != Token::kMUL);  // Int32x4 doesn't have a multiply op.
        operands_type = kInt32x4Cid;
      } else if (HasOnlyTwoOf(ic_data, kFloat64x2Cid)) {
        operands_type = kFloat64x2Cid;
      } else {
        return false;
      }
      break;
    case Token::kDIV:
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
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
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryMintOp)) {
          return false;
        }
        operands_type = ic_data.HasDeoptReason(ICData::kDeoptBinarySmiOp)
            ? kMintCid
            : kSmiCid;
      } else if (HasTwoMintOrSmi(ic_data) &&
                 HasOnlyOneSmi(ICData::Handle(Z,
                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
        // Don't generate mint code if the IC data is marked because of an
        // overflow.
        if (ic_data.HasDeoptReason(ICData::kDeoptBinaryMintOp)) {
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
      if (!FlowGraphCompiler::SupportsHardwareDivision()) return false;
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
                   new(Z) CheckEitherNonSmiInstr(
                       new(Z) Value(left),
                       new(Z) Value(right),
                       call->deopt_id()),
                   call->env(),
                   FlowGraph::kEffect);
    }

    BinaryDoubleOpInstr* double_bin_op =
        new(Z) BinaryDoubleOpInstr(op_kind,
                                   new(Z) Value(left),
                                   new(Z) Value(right),
                                   call->deopt_id(), call->token_pos());
    ReplaceCall(call, double_bin_op);
  } else if (operands_type == kMintCid) {
    if (!FlowGraphCompiler::SupportsUnboxedMints()) return false;
    if ((op_kind == Token::kSHR) || (op_kind == Token::kSHL)) {
      ShiftMintOpInstr* shift_op =
          new(Z) ShiftMintOpInstr(
              op_kind, new(Z) Value(left), new(Z) Value(right),
              call->deopt_id());
      ReplaceCall(call, shift_op);
    } else {
      BinaryMintOpInstr* bin_op =
          new(Z) BinaryMintOpInstr(
              op_kind, new(Z) Value(left), new(Z) Value(right),
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
                     new(Z) CheckSmiInstr(new(Z) Value(left),
                                          call->deopt_id(),
                                          call->token_pos()),
                     call->env(),
                     FlowGraph::kEffect);
        ConstantInstr* constant =
            flow_graph()->GetConstant(Smi::Handle(Z,
                Smi::New(Smi::Cast(obj).Value() - 1)));
        BinarySmiOpInstr* bin_op =
            new(Z) BinarySmiOpInstr(Token::kBIT_AND,
                                    new(Z) Value(left),
                                    new(Z) Value(constant),
                                    call->deopt_id());
        ReplaceCall(call, bin_op);
        return true;
      }
    }
    // Insert two smi checks and attach a copy of the original
    // environment because the smi operation can still deoptimize.
    AddCheckSmi(left, call->deopt_id(), call->env(), call);
    AddCheckSmi(right, call->deopt_id(), call->env(), call);
    BinarySmiOpInstr* bin_op =
        new(Z) BinarySmiOpInstr(op_kind,
                                new(Z) Value(left),
                                new(Z) Value(right),
                                call->deopt_id());
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
        new(Z) BinarySmiOpInstr(
            op_kind,
            new(Z) Value(left),
            new(Z) Value(right),
            call->deopt_id());
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
                 new(Z) CheckSmiInstr(new(Z) Value(input),
                                      call->deopt_id(),
                                      call->token_pos()),
                 call->env(),
                 FlowGraph::kEffect);
    unary_op = new(Z) UnarySmiOpInstr(
        op_kind, new(Z) Value(input), call->deopt_id());
  } else if ((op_kind == Token::kBIT_NOT) &&
             HasOnlySmiOrMint(*call->ic_data()) &&
             FlowGraphCompiler::SupportsUnboxedMints()) {
    unary_op = new(Z) UnaryMintOpInstr(
        op_kind, new(Z) Value(input), call->deopt_id());
  } else if (HasOnlyOneDouble(*call->ic_data()) &&
             (op_kind == Token::kNEGATE) &&
             CanUnboxDouble()) {
    AddReceiverCheck(call);
    unary_op = new(Z) UnaryDoubleOpInstr(
        Token::kNEGATE, new(Z) Value(input), call->deopt_id());
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
    InstanceCallInstr* call, RawFunction::Kind kind) const {
  if (!FLAG_use_cha_deopt) {
    // Even if class or function are private, lazy class finalization
    // may later add overriding methods.
    return true;
  }
  Definition* callee_receiver = call->ArgumentAt(0);
  ASSERT(callee_receiver != NULL);
  const Function& function = flow_graph_->function();
  if (function.IsDynamicFunction() &&
      callee_receiver->IsParameter() &&
      (callee_receiver->AsParameter()->index() == 0)) {
    const String& name = (kind == RawFunction::kMethodExtractor)
        ? String::Handle(Z, Field::NameFromGetter(call->function_name()))
        : call->function_name();
    const Class& cls = Class::Handle(Z, function.Owner());
    if (!thread()->cha()->HasOverride(cls, name)) {
      if (FLAG_trace_cha) {
        ISL_Print("  **(CHA) Instance call needs no check, "
            "no overrides of '%s' '%s'\n",
            name.ToCString(), cls.ToCString());
      }
      thread()->cha()->AddToLeafClasses(cls);
      return false;
    }
  }
  return true;
}


bool FlowGraphOptimizer::InlineImplicitInstanceGetter(InstanceCallInstr* call,
                                                      bool allow_check) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  ASSERT(ic_data.HasOneTarget());
  Function& target = Function::Handle(Z);
  GrowableArray<intptr_t> class_ids;
  ic_data.GetCheckAt(0, &class_ids, &target);
  ASSERT(class_ids.length() == 1);
  // Inline implicit instance getter.
  const String& field_name =
      String::Handle(Z, Field::NameFromGetter(call->function_name()));
  const Field& field =
      Field::ZoneHandle(Z, GetField(class_ids[0], field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(call, RawFunction::kImplicitGetter)) {
    if (!allow_check) {
      return false;
    }
    AddReceiverCheck(call);
  }
  LoadFieldInstr* load = new(Z) LoadFieldInstr(
      new(Z) Value(call->ArgumentAt(0)),
      &field,
      AbstractType::ZoneHandle(Z, field.type()),
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
  return true;
}


bool FlowGraphOptimizer::InlineFloat32x4Getter(InstanceCallInstr* call,
                                               MethodRecognizer::Kind getter) {
  if (!ShouldInlineSimd()) {
    return false;
  }
  AddCheckClass(call->ArgumentAt(0),
                ICData::ZoneHandle(
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
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
    Simd32x4GetSignMaskInstr* instr = new(Z) Simd32x4GetSignMaskInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kFloat32x4ShuffleMix) {
    Simd32x4ShuffleMixInstr* instr = new(Z) Simd32x4ShuffleMixInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
        new(Z) Value(call->ArgumentAt(1)),
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
    Simd32x4ShuffleInstr* instr = new(Z) Simd32x4ShuffleInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
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
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  if ((getter == MethodRecognizer::kFloat64x2GetX) ||
      (getter == MethodRecognizer::kFloat64x2GetY)) {
    Simd64x2ShuffleInstr* instr = new(Z) Simd64x2ShuffleInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
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
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
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
    Simd32x4GetSignMaskInstr* instr = new(Z) Simd32x4GetSignMaskInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kInt32x4ShuffleMix) {
    Simd32x4ShuffleMixInstr* instr = new(Z) Simd32x4ShuffleMixInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
        new(Z) Value(call->ArgumentAt(1)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else if (getter == MethodRecognizer::kInt32x4Shuffle) {
    Simd32x4ShuffleInstr* instr = new(Z) Simd32x4ShuffleInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
        mask,
        call->deopt_id());
    ReplaceCall(call, instr);
    return true;
  } else {
    Int32x4GetFlagInstr* instr = new(Z) Int32x4GetFlagInstr(
        getter,
        new(Z) Value(call->ArgumentAt(0)),
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
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  // Type check right.
  AddCheckClass(right,
                ICData::ZoneHandle(
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                call->deopt_id(),
                call->env(),
                call);
  // Replace call.
  BinaryFloat32x4OpInstr* float32x4_bin_op =
      new(Z) BinaryFloat32x4OpInstr(
          op_kind, new(Z) Value(left), new(Z) Value(right),
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
                    Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                call->deopt_id(),
                call->env(),
                call);
  // Type check right.
  AddCheckClass(right,
                ICData::ZoneHandle(Z,
                    call->ic_data()->AsUnaryClassChecksForArgNr(1)),
                call->deopt_id(),
                call->env(),
                call);
  // Replace call.
  BinaryInt32x4OpInstr* int32x4_bin_op =
      new(Z) BinaryInt32x4OpInstr(
          op_kind, new(Z) Value(left), new(Z) Value(right),
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
      new(Z) BinaryFloat64x2OpInstr(
          op_kind, new(Z) Value(left), new(Z) Value(right),
          call->deopt_id());
  ReplaceCall(call, float64x2_bin_op);
  return true;
}


// Only unique implicit instance getters can be currently handled.
// Returns false if 'allow_check' is false and a check is needed.
bool FlowGraphOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call,
                                                 bool allow_check) {
  ASSERT(call->HasICData());
  const ICData& ic_data = *call->ic_data();
  if (ic_data.NumberOfUsedChecks() == 0) {
    // No type feedback collected.
    return false;
  }

  if (!ic_data.HasOneTarget()) {
    // Polymorphic sites are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }

  const Function& target = Function::Handle(Z, ic_data.GetTargetAt(0));
  if (target.kind() != RawFunction::kImplicitGetter) {
    // Non-implicit getters are inlined like normal methods by conventional
    // inlining in FlowGraphInliner.
    return false;
  }
  return InlineImplicitInstanceGetter(call, allow_check);
}


bool FlowGraphOptimizer::TryReplaceInstanceCallWithInline(
    InstanceCallInstr* call) {
  Function& target = Function::Handle(Z);
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
                                  new(Z) CheckSmiInstr(
                                      new(Z) Value(index),
                                      call->deopt_id(),
                                      call->token_pos()),
                                  call->env(),
                                  FlowGraph::kEffect);

  // Load the length of the string.
  // Treat length loads as mutable (i.e. affected by side effects) to avoid
  // hoisting them since we can't hoist the preceding class-check. This
  // is because of externalization of strings that affects their class-id.
  LoadFieldInstr* length = new(Z) LoadFieldInstr(
      new(Z) Value(str),
      String::length_offset(),
      Type::ZoneHandle(Z, Type::SmiType()),
      str->token_pos());
  length->set_result_cid(kSmiCid);
  length->set_recognized_kind(MethodRecognizer::kStringBaseLength);

  cursor = flow_graph()->AppendTo(cursor, length, NULL, FlowGraph::kValue);
  // Bounds check.
  cursor = flow_graph()->AppendTo(cursor,
                                   new(Z) CheckArrayBoundInstr(
                                       new(Z) Value(length),
                                       new(Z) Value(index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  LoadIndexedInstr* load_indexed = new(Z) LoadIndexedInstr(
      new(Z) Value(str),
      new(Z) Value(index),
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

  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);

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

  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);

  *last = PrepareInlineStringIndexOp(call, cid, str, index, *entry);

  StringFromCharCodeInstr* char_at = new(Z) StringFromCharCodeInstr(
      new(Z) Value(*last), cid);

  flow_graph()->AppendTo(*last, char_at, NULL, FlowGraph::kValue);
  *last = char_at;

  return true;
}


bool FlowGraphOptimizer::InlineDoubleOp(
    Token::Kind op_kind,
    Instruction* call,
    TargetEntryInstr** entry,
    Definition** last) {
  Definition* left = call->ArgumentAt(0);
  Definition* right = call->ArgumentAt(1);

  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);
  // Arguments are checked. No need for class check.
  BinaryDoubleOpInstr* double_bin_op =
      new(Z) BinaryDoubleOpInstr(op_kind,
                                 new(Z) Value(left),
                                 new(Z) Value(right),
                                 call->deopt_id(), call->token_pos());
  flow_graph()->AppendTo(*entry, double_bin_op, call->env(), FlowGraph::kValue);
  *last = double_bin_op;

  return true;
}


void FlowGraphOptimizer::ReplaceWithMathCFunction(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  AddReceiverCheck(call);
  ZoneGrowableArray<Value*>* args =
      new(Z) ZoneGrowableArray<Value*>(call->ArgumentCount());
  for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
    args->Add(new(Z) Value(call->ArgumentAt(i)));
  }
  InvokeMathCFunctionInstr* invoke =
      new(Z) InvokeMathCFunctionInstr(args,
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
  if ((ic_data.NumberOfUsedChecks() == 0) || !ic_data.HasOneTarget()) {
    // No type feedback collected or multiple targets found.
    return false;
  }

  Function& target = Function::Handle(Z);
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
    StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
        GrowableObjectArray::data_offset(),
        new(Z) Value(array),
        new(Z) Value(value),
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
    StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
        GrowableObjectArray::length_offset(),
        new(Z) Value(array),
        new(Z) Value(value),
        kNoStoreBarrier,
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
      StoreIndexedInstr* store_op = new(Z) StoreIndexedInstr(
          new(Z) Value(str),
          new(Z) Value(index),
          new(Z) Value(value),
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
      (ic_data.NumberOfChecks() == 1)) {
    if (class_ids[0] == kSmiCid) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new(Z) SmiToDoubleInstr(
                      new(Z) Value(call->ArgumentAt(0)),
                      call->token_pos()));
      return true;
    } else if ((class_ids[0] == kMintCid) && CanConvertUnboxedMintToDouble()) {
      AddReceiverCheck(call);
      ReplaceCall(call,
                  new(Z) MintToDoubleInstr(new(Z) Value(call->ArgumentAt(0)),
                                           call->deopt_id()));
      return true;
    }
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
          d2i_instr =  new(Z) DoubleToIntegerInstr(
              new(Z) Value(input), call);
        } else {
          // Optimistically assume result fits into Smi.
          d2i_instr = new(Z) DoubleToSmiInstr(
              new(Z) Value(input), call->deopt_id());
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
              new(Z) DoubleToDoubleInstr(new(Z) Value(call->ArgumentAt(0)),
                                         recognized_kind, call->deopt_id());
          ReplaceCall(call, d2d_instr);
        }
        return true;
      case MethodRecognizer::kDoubleAdd:
      case MethodRecognizer::kDoubleSub:
      case MethodRecognizer::kDoubleMul:
      case MethodRecognizer::kDoubleDiv:
        return TryReplaceInstanceCallWithInline(call);
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
        return BuildByteArrayBaseLoad(call, kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint8:
        return BuildByteArrayBaseLoad(call, kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt16:
        return BuildByteArrayBaseLoad(call, kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint16:
        return BuildByteArrayBaseLoad(call, kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt32:
        return BuildByteArrayBaseLoad(call, kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetUint32:
        return BuildByteArrayBaseLoad(call, kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32:
        return BuildByteArrayBaseLoad(call, kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat64:
        return BuildByteArrayBaseLoad(call, kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetFloat32x4:
        return BuildByteArrayBaseLoad(call, kTypedDataFloat32x4ArrayCid);
      case MethodRecognizer::kByteArrayBaseGetInt32x4:
        return BuildByteArrayBaseLoad(call, kTypedDataInt32x4ArrayCid);

      // ByteArray setters.
      case MethodRecognizer::kByteArrayBaseSetInt8:
        return BuildByteArrayBaseStore(call, kTypedDataInt8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint8:
        return BuildByteArrayBaseStore(call, kTypedDataUint8ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt16:
        return BuildByteArrayBaseStore(call, kTypedDataInt16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint16:
        return BuildByteArrayBaseStore(call, kTypedDataUint16ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt32:
        return BuildByteArrayBaseStore(call, kTypedDataInt32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetUint32:
        return BuildByteArrayBaseStore(call, kTypedDataUint32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32:
        return BuildByteArrayBaseStore(call, kTypedDataFloat32ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat64:
        return BuildByteArrayBaseStore(call, kTypedDataFloat64ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetFloat32x4:
        return BuildByteArrayBaseStore(call, kTypedDataFloat32x4ArrayCid);
      case MethodRecognizer::kByteArrayBaseSetInt32x4:
        return BuildByteArrayBaseStore(call, kTypedDataInt32x4ArrayCid);
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
      if (ic_data.HasDeoptReason(ICData::kDeoptBinaryMintOp)) {
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
          new(Z) BinarySmiOpInstr(Token::kSHL,
                                  new(Z) Value(value),
                                  new(Z) Value(count),
                                  call->deopt_id());
      left_shift->mark_truncating();
      if ((kBitsPerWord == 32) && (mask_value == 0xffffffffLL)) {
        // No BIT_AND operation needed.
        ReplaceCall(call, left_shift);
      } else {
        InsertBefore(call, left_shift, call->env(), FlowGraph::kValue);
        BinarySmiOpInstr* bit_and =
            new(Z) BinarySmiOpInstr(Token::kBIT_AND,
                                    new(Z) Value(left_shift),
                                    new(Z) Value(int32_mask),
                                    call->deopt_id());
        ReplaceCall(call, bit_and);
      }
      return true;
    }

    if (HasTwoMintOrSmi(ic_data) &&
        HasOnlyOneSmi(ICData::Handle(Z,
                                     ic_data.AsUnaryClassChecksForArgNr(1)))) {
      if (!FlowGraphCompiler::SupportsUnboxedMints() ||
          ic_data.HasDeoptReason(ICData::kDeoptBinaryMintOp)) {
        return false;
      }
      ShiftMintOpInstr* left_shift =
          new(Z) ShiftMintOpInstr(Token::kSHL,
                                  new(Z) Value(value),
                                  new(Z) Value(count),
                                  call->deopt_id());
      InsertBefore(call, left_shift, call->env(), FlowGraph::kValue);
      BinaryMintOpInstr* bit_and =
          new(Z) BinaryMintOpInstr(Token::kBIT_AND,
                                   new(Z) Value(left_shift),
                                   new(Z) Value(int32_mask),
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
  if (Compiler::always_optimize()) {
    // Cannot handle unboxed instructions.
    return false;
  }
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kFloat32x4Zero) {
    Float32x4ZeroInstr* zero = new(Z) Float32x4ZeroInstr();
    ReplaceCall(call, zero);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4Splat) {
    Float32x4SplatInstr* splat =
        new(Z) Float32x4SplatInstr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, splat);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4Constructor) {
    Float32x4ConstructorInstr* con =
        new(Z) Float32x4ConstructorInstr(
            new(Z) Value(call->ArgumentAt(1)),
            new(Z) Value(call->ArgumentAt(2)),
            new(Z) Value(call->ArgumentAt(3)),
            new(Z) Value(call->ArgumentAt(4)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4FromInt32x4Bits) {
    Int32x4ToFloat32x4Instr* cast =
        new(Z) Int32x4ToFloat32x4Instr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat32x4FromFloat64x2) {
    Float64x2ToFloat32x4Instr* cast =
        new(Z) Float64x2ToFloat32x4Instr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineFloat64x2Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (Compiler::always_optimize()) {
    // Cannot handle unboxed instructions.
    return false;
  }
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kFloat64x2Zero) {
    Float64x2ZeroInstr* zero = new(Z) Float64x2ZeroInstr();
    ReplaceCall(call, zero);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2Splat) {
    Float64x2SplatInstr* splat =
        new(Z) Float64x2SplatInstr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, splat);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2Constructor) {
    Float64x2ConstructorInstr* con =
        new(Z) Float64x2ConstructorInstr(
            new(Z) Value(call->ArgumentAt(1)),
            new(Z) Value(call->ArgumentAt(2)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kFloat64x2FromFloat32x4) {
    Float32x4ToFloat64x2Instr* cast =
        new(Z) Float32x4ToFloat64x2Instr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  }
  return false;
}


bool FlowGraphOptimizer::TryInlineInt32x4Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  if (Compiler::always_optimize()) {
    // Cannot handle unboxed instructions.
    return false;
  }
  if (!ShouldInlineSimd()) {
    return false;
  }
  if (recognized_kind == MethodRecognizer::kInt32x4BoolConstructor) {
    Int32x4BoolConstructorInstr* con =
        new(Z) Int32x4BoolConstructorInstr(
            new(Z) Value(call->ArgumentAt(1)),
            new(Z) Value(call->ArgumentAt(2)),
            new(Z) Value(call->ArgumentAt(3)),
            new(Z) Value(call->ArgumentAt(4)),
            call->deopt_id());
    ReplaceCall(call, con);
    return true;
  } else if (recognized_kind == MethodRecognizer::kInt32x4FromFloat32x4Bits) {
    Float32x4ToInt32x4Instr* cast =
        new(Z) Float32x4ToInt32x4Instr(
            new(Z) Value(call->ArgumentAt(1)), call->deopt_id());
    ReplaceCall(call, cast);
    return true;
  } else if (recognized_kind == MethodRecognizer::kInt32x4Constructor) {
    Int32x4ConstructorInstr* con =
        new(Z) Int32x4ConstructorInstr(
            new(Z) Value(call->ArgumentAt(1)),
            new(Z) Value(call->ArgumentAt(2)),
            new(Z) Value(call->ArgumentAt(3)),
            new(Z) Value(call->ArgumentAt(4)),
            call->deopt_id());
    ReplaceCall(call, con);
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      // Replace call.
      Float32x4ComparisonInstr* cmp =
          new(Z) Float32x4ComparisonInstr(recognized_kind,
                                          new(Z) Value(left),
                                          new(Z) Value(right),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4MinMaxInstr* minmax =
          new(Z) Float32x4MinMaxInstr(
              recognized_kind,
              new(Z) Value(left),
              new(Z) Value(right),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      // Left and right values are swapped when handed to the instruction,
      // this is done so that the double value is loaded into the output
      // register and can be destroyed.
      Float32x4ScaleInstr* scale =
          new(Z) Float32x4ScaleInstr(recognized_kind,
                                     new(Z) Value(right),
                                     new(Z) Value(left),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4SqrtInstr* sqrt =
          new(Z) Float32x4SqrtInstr(recognized_kind,
                                    new(Z) Value(left),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4WithInstr* with = new(Z) Float32x4WithInstr(recognized_kind,
                                                           new(Z) Value(left),
                                                           new(Z) Value(right),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4ZeroArgInstr* zeroArg =
          new(Z) Float32x4ZeroArgInstr(
              recognized_kind, new(Z) Value(left), call->deopt_id());
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float32x4ClampInstr* clamp = new(Z) Float32x4ClampInstr(
          new(Z) Value(left),
          new(Z) Value(lower),
          new(Z) Value(upper),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float64x2ZeroArgInstr* zeroArg =
          new(Z) Float64x2ZeroArgInstr(
              recognized_kind, new(Z) Value(left), call->deopt_id());
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Float64x2OneArgInstr* zeroArg =
          new(Z) Float64x2OneArgInstr(recognized_kind,
                                      new(Z) Value(left),
                                      new(Z) Value(right),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Int32x4SelectInstr* select = new(Z) Int32x4SelectInstr(
          new(Z) Value(mask),
          new(Z) Value(trueValue),
          new(Z) Value(falseValue),
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
                        Z, call->ic_data()->AsUnaryClassChecksForArgNr(0)),
                    call->deopt_id(),
                    call->env(),
                    call);
      Int32x4SetFlagInstr* setFlag = new(Z) Int32x4SetFlagInstr(
          recognized_kind,
          new(Z) Value(left),
          new(Z) Value(flag),
          call->deopt_id());
      ReplaceCall(call, setFlag);
      return true;
    }
    default:
      return false;
  }
}


bool FlowGraphOptimizer::InlineByteArrayBaseLoad(Instruction* call,
                                                 Definition* receiver,
                                                 intptr_t array_cid,
                                                 intptr_t view_cid,
                                                 const ICData& ic_data,
                                                 TargetEntryInstr** entry,
                                                 Definition** last) {
  ASSERT(array_cid != kIllegalCid);
  Definition* array = receiver;
  Definition* index = call->ArgumentAt(1);
  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineByteArrayBaseOp(call,
                                           array_cid,
                                           view_cid,
                                           &array,
                                           index,
                                           &cursor);

  intptr_t deopt_id = Isolate::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Isolate::kNoDeoptId : call->deopt_id();
  }

  *last = new(Z) LoadIndexedInstr(new(Z) Value(array),
                                  new(Z) Value(index),
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
    *last = new(Z) FloatToDoubleInstr(new(Z) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Isolate::kNoDeoptId ? call->env() : NULL,
                           FlowGraph::kValue);
  }
  return true;
}


bool FlowGraphOptimizer::InlineByteArrayBaseStore(const Function& target,
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
  *entry = new(Z) TargetEntryInstr(flow_graph()->allocate_block_id(),
                                   call->GetBlock()->try_index());
  (*entry)->InheritDeoptTarget(Z, call);
  Instruction* cursor = *entry;

  array_cid = PrepareInlineByteArrayBaseOp(call,
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
  ICData& value_check = ICData::ZoneHandle(Z);
  switch (view_cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
    case kTypedDataInt16ArrayCid:
    case kTypedDataUint16ArrayCid: {
      // Check that value is always smi.
      value_check = ICData::New(flow_graph_->function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kSmiCid, target);
      break;
    }
    case kTypedDataInt32ArrayCid:
    case kTypedDataUint32ArrayCid:
      // On 64-bit platforms assume that stored value is always a smi.
      if (kSmiBits >= 32) {
        value_check = ICData::New(flow_graph_->function(),
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
      value_check = ICData::New(flow_graph_->function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kDoubleCid, target);
      break;
    }
    case kTypedDataInt32x4ArrayCid: {
      // Check that value is always Int32x4.
      value_check = ICData::New(flow_graph_->function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Isolate::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kInt32x4Cid, target);
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always Float32x4.
      value_check = ICData::New(flow_graph_->function(),
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
    stored_value = new(Z) DoubleToFloatInstr(
        new(Z) Value(stored_value), call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    NULL,
                                    FlowGraph::kValue);
  } else if (view_cid == kTypedDataInt32ArrayCid) {
    stored_value = new(Z) UnboxInt32Instr(
        UnboxInt32Instr::kTruncate,
        new(Z) Value(stored_value),
        call->deopt_id());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    call->env(),
                                    FlowGraph::kValue);
  } else if (view_cid == kTypedDataUint32ArrayCid) {
    stored_value = new(Z) UnboxUint32Instr(
        new(Z) Value(stored_value),
        call->deopt_id());
    ASSERT(stored_value->AsUnboxInteger()->is_truncating());
    cursor = flow_graph()->AppendTo(cursor,
                                    stored_value,
                                    call->env(),
                                    FlowGraph::kValue);
  }

  StoreBarrierType needs_store_barrier = kNoStoreBarrier;
  *last = new(Z) StoreIndexedInstr(new(Z) Value(array),
                                   new(Z) Value(index),
                                   new(Z) Value(stored_value),
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



intptr_t FlowGraphOptimizer::PrepareInlineByteArrayBaseOp(
    Instruction* call,
    intptr_t array_cid,
    intptr_t view_cid,
    Definition** array,
    Definition* byte_index,
    Instruction** cursor) {
  // Insert byte_index smi check.
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(Z) CheckSmiInstr(
                                       new(Z) Value(byte_index),
                                       call->deopt_id(),
                                       call->token_pos()),
                                   call->env(),
                                   FlowGraph::kEffect);

  LoadFieldInstr* length =
      new(Z) LoadFieldInstr(
          new(Z) Value(*array),
          CheckArrayBoundInstr::LengthOffsetFor(array_cid),
          Type::ZoneHandle(Z, Type::SmiType()),
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
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(element_size)));
  BinarySmiOpInstr* len_in_bytes =
      new(Z) BinarySmiOpInstr(Token::kMUL,
                              new(Z) Value(length),
                              new(Z) Value(bytes_per_element),
                              call->deopt_id());
  *cursor = flow_graph()->AppendTo(*cursor, len_in_bytes, call->env(),
                                   FlowGraph::kValue);

  // adjusted_length = len_in_bytes - (element_size - 1).
  Definition* adjusted_length = len_in_bytes;
  intptr_t adjustment = Instance::ElementSizeFor(view_cid) - 1;
  if (adjustment > 0) {
    ConstantInstr* length_adjustment =
        flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(adjustment)));
    adjusted_length =
        new(Z) BinarySmiOpInstr(Token::kSUB,
                                new(Z) Value(len_in_bytes),
                                new(Z) Value(length_adjustment),
                                call->deopt_id());
    *cursor = flow_graph()->AppendTo(*cursor, adjusted_length, call->env(),
                                     FlowGraph::kValue);
  }

  // Check adjusted_length > 0.
  ConstantInstr* zero =
      flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(0)));
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(Z) CheckArrayBoundInstr(
                                       new(Z) Value(adjusted_length),
                                       new(Z) Value(zero),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);
  // Check 0 <= byte_index < adjusted_length.
  *cursor = flow_graph()->AppendTo(*cursor,
                                   new(Z) CheckArrayBoundInstr(
                                       new(Z) Value(adjusted_length),
                                       new(Z) Value(byte_index),
                                       call->deopt_id()),
                                   call->env(),
                                   FlowGraph::kEffect);

  if (RawObject::IsExternalTypedDataClassId(array_cid)) {
    LoadUntaggedInstr* elements =
        new(Z) LoadUntaggedInstr(new(Z) Value(*array),
                                 ExternalTypedData::data_offset());
    *cursor = flow_graph()->AppendTo(*cursor,
                                     elements,
                                     NULL,
                                     FlowGraph::kValue);
    *array = elements;
  }
  return array_cid;
}


bool FlowGraphOptimizer::BuildByteArrayBaseLoad(InstanceCallInstr* call,
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


bool FlowGraphOptimizer::BuildByteArrayBaseStore(InstanceCallInstr* call,
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
  const Class& type_class = Class::Handle(Z, type.type_class());
  const intptr_t num_type_args = type_class.NumTypeArguments();
  if (num_type_args > 0) {
    // Only raw types can be directly compared, thus disregarding type
    // arguments.
    const intptr_t num_type_params = type_class.NumTypeParameters();
    const intptr_t from_index = num_type_args - num_type_params;
    const TypeArguments& type_arguments =
        TypeArguments::Handle(Z, type.arguments());
    const bool is_raw_type = type_arguments.IsNull() ||
        type_arguments.IsRaw(from_index, num_type_params);
    if (!is_raw_type) {
      // Unknown result.
      return Bool::null();
    }
  }

  const ClassTable& class_table = *isolate()->class_table();
  Bool& prev = Bool::Handle(Z);
  Class& cls = Class::Handle(Z);

  bool results_differ = false;
  for (int i = 0; i < ic_data.NumberOfChecks(); i++) {
    cls = class_table.At(ic_data.GetReceiverClassIdAt(i));
    if (cls.NumTypeArguments() > 0) {
      return Bool::null();
    }
    const bool is_subtype = cls.IsSubtypeOf(
        TypeArguments::Handle(Z),
        type_class,
        TypeArguments::Handle(Z),
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
bool FlowGraphOptimizer::TypeCheckAsClassEquality(const AbstractType& type) {
  ASSERT(type.IsFinalized() && !type.IsMalformedOrMalbounded());
  // Requires CHA.
  if (!type.IsInstantiated()) return false;
  const Class& type_class = Class::Handle(type.type_class());
  // Signature classes have different type checking rules.
  if (type_class.IsSignatureClass()) return false;
  // Could be an interface check?
  if (CHA::IsImplemented(type_class)) return false;
  // Check if there are subclasses.
  if (CHA::HasSubclasses(type_class)) {
    return false;
  }

  // Private classes cannot be subclassed by later loaded libs.
  if (!type_class.IsPrivate()) {
    if (FLAG_use_cha_deopt) {
      if (FLAG_trace_cha) {
        ISL_Print("  **(CHA) Typecheck as class equality since no "
            "subclasses: %s\n",
            type_class.ToCString());
      }
      thread()->cha()->AddToLeafClasses(type_class);
    } else {
      return false;
    }
  }
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
  Definition* instantiator = NULL;
  Definition* type_args = NULL;
  AbstractType& type = AbstractType::ZoneHandle(Z);
  bool negate = false;
  if (call->ArgumentCount() == 2) {
    instantiator = flow_graph()->constant_null();
    type_args = flow_graph()->constant_null();
    if (call->function_name().raw() ==
        Library::PrivateCoreLibName(Symbols::_instanceOfNum()).raw()) {
      type = Type::Number();
    } else if (call->function_name().raw() ==
        Library::PrivateCoreLibName(Symbols::_instanceOfInt()).raw()) {
      type = Type::IntType();
    } else if (call->function_name().raw() ==
        Library::PrivateCoreLibName(Symbols::_instanceOfSmi()).raw()) {
      type = Type::SmiType();
    } else if (call->function_name().raw() ==
        Library::PrivateCoreLibName(Symbols::_instanceOfDouble()).raw()) {
      type = Type::Double();
    } else if (call->function_name().raw() ==
        Library::PrivateCoreLibName(Symbols::_instanceOfString()).raw()) {
      type = Type::StringType();
    } else {
      UNIMPLEMENTED();
    }
    negate = Bool::Cast(call->ArgumentAt(1)->OriginalDefinition()
        ->AsConstant()->value()).value();
  } else {
    instantiator = call->ArgumentAt(1);
    type_args = call->ArgumentAt(2);
    type = AbstractType::Cast(call->ArgumentAt(3)->AsConstant()->value()).raw();
    negate = Bool::Cast(call->ArgumentAt(4)->OriginalDefinition()
        ->AsConstant()->value()).value();
  }
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  if (FLAG_warn_on_javascript_compatibility &&
      !unary_checks.IssuedJSWarning() &&
      (type.IsIntType() || type.IsDoubleType() || !type.IsInstantiated())) {
    // No warning was reported yet for this type check, either because it has
    // not been executed yet, or because no problematic combinations of instance
    // type and test type have been encountered so far. A warning may still be
    // reported, so do not replace the instance call.
    return;
  }
  if ((unary_checks.NumberOfChecks() > 0) &&
      (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks)) {
    ZoneGrowableArray<intptr_t>* results =
        new(Z) ZoneGrowableArray<intptr_t>(unary_checks.NumberOfChecks() * 2);
    Bool& as_bool =
        Bool::ZoneHandle(Z, InstanceOfAsBool(unary_checks, type, results));
    if (as_bool.IsNull()) {
      if (results->length() == unary_checks.NumberOfChecks() * 2) {
        const bool can_deopt = TryExpandTestCidsResult(results, type);
        TestCidsInstr* test_cids = new(Z) TestCidsInstr(
            call->token_pos(),
            negate ? Token::kISNOT : Token::kIS,
            new(Z) Value(left),
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
    LoadClassIdInstr* left_cid = new(Z) LoadClassIdInstr(new(Z) Value(left));
    InsertBefore(call,
                 left_cid,
                 NULL,
                 FlowGraph::kValue);
    const intptr_t type_cid = Class::Handle(Z, type.type_class()).id();
    ConstantInstr* cid =
        flow_graph()->GetConstant(Smi::Handle(Z, Smi::New(type_cid)));

    StrictCompareInstr* check_cid =
        new(Z) StrictCompareInstr(
            call->token_pos(),
            negate ? Token::kNE_STRICT : Token::kEQ_STRICT,
            new(Z) Value(left_cid),
            new(Z) Value(cid),
            false);  // No number check.
    ReplaceCall(call, check_cid);
    return;
  }

  InstanceOfInstr* instance_of =
      new(Z) InstanceOfInstr(call->token_pos(),
                             new(Z) Value(left),
                             new(Z) Value(instantiator),
                             new(Z) Value(type_args),
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
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
  if (FLAG_warn_on_javascript_compatibility &&
      !unary_checks.IssuedJSWarning() &&
      (type.IsIntType() || type.IsDoubleType() || !type.IsInstantiated())) {
    // No warning was reported yet for this type check, either because it has
    // not been executed yet, or because no problematic combinations of instance
    // type and test type have been encountered so far. A warning may still be
    // reported, so do not replace the instance call.
    return;
  }
  if ((unary_checks.NumberOfChecks() > 0) &&
      (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks)) {
    ZoneGrowableArray<intptr_t>* results =
        new(Z) ZoneGrowableArray<intptr_t>(unary_checks.NumberOfChecks() * 2);
    const Bool& as_bool = Bool::ZoneHandle(Z,
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
  const String& dst_name = String::ZoneHandle(Z,
      Symbols::New(Exceptions::kCastErrorDstName));
  AssertAssignableInstr* assert_as =
      new(Z) AssertAssignableInstr(call->token_pos(),
                                   new(Z) Value(left),
                                   new(Z) Value(instantiator),
                                   new(Z) Value(type_args),
                                   type,
                                   dst_name,
                                   call->deopt_id());
  ReplaceCall(call, assert_as);
}


// Special optimizations when running in --noopt mode.
void FlowGraphOptimizer::InstanceCallNoopt(InstanceCallInstr* instr) {
  // TODO(srdjan): Investigate other attempts, as they are not allowed to
  // deoptimize.
  const Token::Kind op_kind = instr->token_kind();
  if (instr->HasICData() && (instr->ic_data()->NumberOfUsedChecks() > 0)) {
    const ICData& unary_checks =
        ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());

    PolymorphicInstanceCallInstr* call =
        new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
                                            true /* call_with_checks*/);
    instr->ReplaceWith(call, current_iterator());
    return;
  }

  // Type test is special as it always gets converted into inlined code.
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }
  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (Compiler::always_optimize()) {
    InstanceCallNoopt(instr);
    return;
  }

  if (!instr->HasICData() || (instr->ic_data()->NumberOfUsedChecks() == 0)) {
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
      ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());

  const intptr_t max_checks = (op_kind == Token::kEQ)
      ? FLAG_max_equality_polymorphic_checks
      : FLAG_max_polymorphic_checks;
  if ((unary_checks.NumberOfChecks() > max_checks) &&
      InstanceCallNeedsClassCheck(instr, RawFunction::kRegularFunction)) {
    // Too many checks, it will be megamorphic which needs unary checks.
    instr->set_ic_data(&unary_checks);
    return;
  }

  if ((op_kind == Token::kASSIGN_INDEX) && TryReplaceWithIndexedOp(instr)) {
    return;
  }
  if ((op_kind == Token::kINDEX) && TryReplaceWithIndexedOp(instr)) {
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
  if (Token::IsUnaryOperator(op_kind) &&
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
        Function::Handle(Z, unary_checks.GetTargetAt(0));
    const bool polymorphic_target = MethodRecognizer::PolymorphicTarget(target);
    has_one_target = !polymorphic_target;
  }

  if (has_one_target) {
    RawFunction::Kind function_kind =
        Function::Handle(Z, unary_checks.GetTargetAt(0)).kind();
    if (!InstanceCallNeedsClassCheck(instr, function_kind)) {
      const bool call_with_checks = false;
      PolymorphicInstanceCallInstr* call =
          new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
                                              call_with_checks);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  if (unary_checks.NumberOfChecks() <= FLAG_max_polymorphic_checks) {
    bool call_with_checks;
    if (has_one_target && FLAG_polymorphic_with_deopt) {
      // Type propagation has not run yet, we cannot eliminate the check.
      AddReceiverCheck(instr);
      // Call can still deoptimize, do not detach environment from instr.
      call_with_checks = false;
    } else {
      call_with_checks = true;
    }
    PolymorphicInstanceCallInstr* call =
        new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
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
    if (Compiler::always_optimize()) {
      // TODO(srdjan): Adapt MathUnaryInstr to allow tagged inputs as well.
    } else {
      MathUnaryInstr* math_unary =
          new(Z) MathUnaryInstr(unary_kind,
                                new(Z) Value(call->ArgumentAt(0)),
                                call->deopt_id());
      ReplaceCall(call, math_unary);
    }
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
  } else if ((recognized_kind == MethodRecognizer::kInt32x4BoolConstructor) ||
             (recognized_kind == MethodRecognizer::kInt32x4Constructor)) {
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
        MathMinMaxInstr* min_max = new(Z) MathMinMaxInstr(
            recognized_kind,
            new(Z) Value(call->ArgumentAt(0)),
            new(Z) Value(call->ArgumentAt(1)),
            call->deopt_id(),
            result_cid);
        const ICData& unary_checks =
            ICData::ZoneHandle(Z, ic_data.AsUnaryClassChecks());
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
    if (Compiler::always_optimize()) {
      // No UnboxDouble instructons allowed.
      return;
    }
    // We know that first argument is double, the second is num.
    // InvokeMathCFunctionInstr requires unboxed doubles. UnboxDouble
    // instructions contain type checks and conversions to double.
    ZoneGrowableArray<Value*>* args =
        new(Z) ZoneGrowableArray<Value*>(call->ArgumentCount());
    for (intptr_t i = 0; i < call->ArgumentCount(); i++) {
      args->Add(new(Z) Value(call->ArgumentAt(i)));
    }
    InvokeMathCFunctionInstr* invoke =
        new(Z) InvokeMathCFunctionInstr(args,
                                        call->deopt_id(),
                                        recognized_kind,
                                        call->token_pos());
    ReplaceCall(call, invoke);
  } else if (recognized_kind == MethodRecognizer::kDoubleFromInteger) {
    if (call->HasICData() && (call->ic_data()->NumberOfChecks() == 1)) {
      const ICData& ic_data = *call->ic_data();
      if (CanUnboxDouble()) {
        if (ArgIsAlways(kSmiCid, ic_data, 1)) {
          Definition* arg = call->ArgumentAt(1);
          AddCheckSmi(arg, call->deopt_id(), call->env(), call);
          ReplaceCall(call,
                      new(Z) SmiToDoubleInstr(new(Z) Value(arg),
                                              call->token_pos()));
        } else if (ArgIsAlways(kMintCid, ic_data, 1) &&
                   CanConvertUnboxedMintToDouble()) {
          Definition* arg = call->ArgumentAt(1);
          ReplaceCall(call,
                      new(Z) MintToDoubleInstr(new(Z) Value(arg),
                                               call->deopt_id()));
        }
      }
    }
  } else if (call->function().IsFactory()) {
    const Class& function_class =
        Class::Handle(Z, call->function().Owner());
    if ((function_class.library() == Library::CoreLibrary()) ||
        (function_class.library() == Library::TypedDataLibrary())) {
      intptr_t cid = FactoryRecognizer::ResultCid(call->function());
      switch (cid) {
        case kArrayCid: {
          Value* type = new(Z) Value(call->ArgumentAt(0));
          Value* num_elements = new(Z) Value(call->ArgumentAt(1));
          if (num_elements->BindsToConstant() &&
              num_elements->BoundConstant().IsSmi()) {
            intptr_t length = Smi::Cast(num_elements->BoundConstant()).Value();
            if (length >= 0 && length <= Array::kMaxElements) {
              CreateArrayInstr* create_array =
                  new(Z) CreateArrayInstr(
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
    ASSERT(instr->is_potential_unboxed_initialization_);
    // Determine if this field should be unboxed based on the usage of getter
    // and setter functions: The heuristic requires that the setter has a
    // usage count of at least 1/kGetterSetterRatio of the getter usage count.
    // This is to avoid unboxing fields where the setter is never or rarely
    // executed.
    const Field& field = Field::ZoneHandle(Z, instr->field().raw());
    const String& field_name = String::Handle(Z, field.name());
    const Class& owner = Class::Handle(Z, field.owner());
    const Function& getter =
        Function::Handle(Z, owner.LookupGetterFunction(field_name));
    const Function& setter =
        Function::Handle(Z, owner.LookupSetterFunction(field_name));
    bool unboxed_field = false;
    if (!getter.IsNull() && !setter.IsNull()) {
      if (field.is_double_initialized()) {
        unboxed_field = true;
      } else if ((setter.usage_counter() > 0) &&
                 ((FLAG_getter_setter_ratio * setter.usage_counter()) >=
                   getter.usage_counter())) {
        unboxed_field = true;
      }
    }
    if (!unboxed_field) {
      if (FLAG_trace_optimization || FLAG_trace_field_guards) {
        ISL_Print("Disabling unboxing of %s\n", field.ToCString());
        if (!setter.IsNull()) {
          OS::Print("  setter usage count: %" Pd "\n", setter.usage_counter());
        }
        if (!getter.IsNull()) {
          OS::Print("  getter usage count: %" Pd "\n", getter.usage_counter());
        }
      }
      field.set_is_unboxing_candidate(false);
      field.DeoptimizeDependentCode();
    } else {
      FlowGraph::AddToGuardedFields(flow_graph_->guarded_fields(), &field);
    }
  }
}


void FlowGraphOptimizer::VisitAllocateContext(AllocateContextInstr* instr) {
  // Replace generic allocation with a sequence of inlined allocation and
  // explicit initalizing stores.
  AllocateUninitializedContextInstr* replacement =
      new AllocateUninitializedContextInstr(instr->token_pos(),
                                            instr->num_context_variables());
  instr->ReplaceWith(replacement, current_iterator());

  StoreInstanceFieldInstr* store =
      new(Z) StoreInstanceFieldInstr(Context::parent_offset(),
                                     new Value(replacement),
                                     new Value(flow_graph_->constant_null()),
                                     kNoStoreBarrier,
                                     instr->token_pos());
  // Storing into uninitialized memory; remember to prevent dead store
  // elimination and ensure proper GC barrier.
  store->set_is_object_reference_initialization(true);
  flow_graph_->InsertAfter(replacement, store, NULL, FlowGraph::kEffect);
  Definition* cursor = store;
  for (intptr_t i = 0; i < instr->num_context_variables(); ++i) {
    store =
        new(Z) StoreInstanceFieldInstr(Context::variable_offset(i),
                                       new Value(replacement),
                                       new Value(flow_graph_->constant_null()),
                                       kNoStoreBarrier,
                                       instr->token_pos());
    // Storing into uninitialized memory; remember to prevent dead store
    // elimination and ensure proper GC barrier.
    store->set_is_object_reference_initialization(true);
    flow_graph_->InsertAfter(cursor, store, NULL, FlowGraph::kEffect);
    cursor = store;
  }
}


void FlowGraphOptimizer::VisitLoadCodeUnits(LoadCodeUnitsInstr* instr) {
  // TODO(zerny): Use kUnboxedUint32 once it is fully supported/optimized.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
  if (!instr->can_pack_into_smi())
    instr->set_representation(kUnboxedMint);
#endif
}


bool FlowGraphOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr,
                                                 const ICData& unary_ic_data) {
  ASSERT((unary_ic_data.NumberOfChecks() > 0) &&
      (unary_ic_data.NumArgsTested() == 1));
  if (I->flags().type_checks()) {
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
  Function& target = Function::Handle(Z);
  intptr_t class_id;
  unary_ic_data.GetOneClassCheckAt(0, &class_id, &target);
  if (target.kind() != RawFunction::kImplicitSetter) {
    // Non-implicit setter are inlined like normal method calls.
    return false;
  }
  // Inline implicit instance setter.
  const String& field_name =
      String::Handle(Z, Field::NameFromSetter(instr->function_name()));
  const Field& field =
      Field::ZoneHandle(Z, GetField(class_id, field_name));
  ASSERT(!field.IsNull());

  if (InstanceCallNeedsClassCheck(instr, RawFunction::kImplicitSetter)) {
    AddReceiverCheck(instr);
  }
  if (field.guarded_cid() != kDynamicCid) {
    InsertBefore(instr,
                 new(Z) GuardFieldClassInstr(
                     new(Z) Value(instr->ArgumentAt(1)),
                      field,
                      instr->deopt_id()),
                 instr->env(),
                 FlowGraph::kEffect);
  }

  if (field.needs_length_check()) {
    InsertBefore(instr,
                 new(Z) GuardFieldLengthInstr(
                     new(Z) Value(instr->ArgumentAt(1)),
                      field,
                      instr->deopt_id()),
                 instr->env(),
                 FlowGraph::kEffect);
  }

  // Field guard was detached.
  StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
      field,
      new(Z) Value(instr->ArgumentAt(0)),
      new(Z) Value(instr->ArgumentAt(1)),
      kEmitStoreBarrier,
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


#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
// Smi widening pass is only meaningful on platforms where Smi
// is smaller than 32bit. For now only support it on ARM and ia32.
static bool CanBeWidened(BinarySmiOpInstr* smi_op) {
  return BinaryInt32OpInstr::IsSupported(smi_op->op_kind(),
                                         smi_op->left(),
                                         smi_op->right());
}


static bool BenefitsFromWidening(BinarySmiOpInstr* smi_op) {
  // TODO(vegorov): when shifts with non-constants shift count are supported
  // add them here as we save untagging for the count.
  switch (smi_op->op_kind()) {
    case Token::kMUL:
    case Token::kSHR:
      // For kMUL we save untagging of the argument for kSHR
      // we save tagging of the result.
      return true;

    default:
      return false;
  }
}


void FlowGraphOptimizer::WidenSmiToInt32() {
  GrowableArray<BinarySmiOpInstr*> candidates;

  // Step 1. Collect all instructions that potentially benefit from widening of
  // their operands (or their result) into int32 range.
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    for (ForwardInstructionIterator instr_it(block_it.Current());
         !instr_it.Done();
         instr_it.Advance()) {
      BinarySmiOpInstr* smi_op = instr_it.Current()->AsBinarySmiOp();
      if ((smi_op != NULL) &&
          BenefitsFromWidening(smi_op) &&
          CanBeWidened(smi_op)) {
        candidates.Add(smi_op);
      }
    }
  }

  if (candidates.is_empty()) {
    return;
  }

  // Step 2. For each block in the graph compute which loop it belongs to.
  // We will use this information later during computation of the widening's
  // gain: we are going to assume that only conversion occuring inside the
  // same loop should be counted against the gain, all other conversions
  // can be hoisted and thus cost nothing compared to the loop cost itself.
  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      flow_graph()->LoopHeaders();

  GrowableArray<intptr_t> loops(flow_graph_->preorder().length());
  for (intptr_t i = 0; i < flow_graph_->preorder().length(); i++) {
    loops.Add(-1);
  }

  for (intptr_t loop_id = 0; loop_id < loop_headers.length(); ++loop_id) {
    for (BitVector::Iterator loop_it(loop_headers[loop_id]->loop_info());
         !loop_it.Done();
         loop_it.Advance()) {
      loops[loop_it.Current()] = loop_id;
    }
  }

  // Step 3. For each candidate transitively collect all other BinarySmiOpInstr
  // and PhiInstr that depend on it and that it depends on and count amount of
  // untagging operations that we save in assumption that this whole graph of
  // values is using kUnboxedInt32 representation instead of kTagged.
  // Convert those graphs that have positive gain to kUnboxedInt32.

  // BitVector containing SSA indexes of all processed definitions. Used to skip
  // those candidates that belong to dependency graph of another candidate.
  BitVector* processed =
      new(Z) BitVector(Z, flow_graph_->current_ssa_temp_index());

  // Worklist used to collect dependency graph.
  DefinitionWorklist worklist(flow_graph_, candidates.length());
  for (intptr_t i = 0; i < candidates.length(); i++) {
    BinarySmiOpInstr* op = candidates[i];
    if (op->WasEliminated() || processed->Contains(op->ssa_temp_index())) {
      continue;
    }

    if (FLAG_trace_smi_widening) {
      ISL_Print("analysing candidate: %s\n", op->ToCString());
    }
    worklist.Clear();
    worklist.Add(op);

    // Collect dependency graph. Note: more items are added to worklist
    // inside this loop.
    intptr_t gain = 0;
    for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
      Definition* defn = worklist.definitions()[j];

      if (FLAG_trace_smi_widening) {
        ISL_Print("> %s\n", defn->ToCString());
      }

      if (defn->IsBinarySmiOp() &&
          BenefitsFromWidening(defn->AsBinarySmiOp())) {
        gain++;
        if (FLAG_trace_smi_widening) {
          ISL_Print("^ [%" Pd "] (o) %s\n", gain, defn->ToCString());
        }
      }

      const intptr_t defn_loop = loops[defn->GetBlock()->preorder_number()];

      // Process all inputs.
      for (intptr_t k = 0; k < defn->InputCount(); k++) {
        Definition* input = defn->InputAt(k)->definition();
        if (input->IsBinarySmiOp() &&
            CanBeWidened(input->AsBinarySmiOp())) {
          worklist.Add(input);
        } else if (input->IsPhi() && (input->Type()->ToCid() == kSmiCid)) {
          worklist.Add(input);
        } else if (input->IsBinaryMintOp()) {
          // Mint operation produces untagged result. We avoid tagging.
          gain++;
          if (FLAG_trace_smi_widening) {
            ISL_Print("^ [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        } else if (defn_loop == loops[input->GetBlock()->preorder_number()] &&
                   (input->Type()->ToCid() == kSmiCid)) {
          // Input comes from the same loop, is known to be smi and requires
          // untagging.
          // TODO(vegorov) this heuristic assumes that values that are not
          // known to be smi have to be checked and this check can be
          // coalesced with untagging. Start coalescing them.
          gain--;
          if (FLAG_trace_smi_widening) {
            ISL_Print("v [%" Pd "] (i) %s\n", gain, input->ToCString());
          }
        }
      }

      // Process all uses.
      for (Value* use = defn->input_use_list();
           use != NULL;
           use = use->next_use()) {
        Instruction* instr = use->instruction();
        Definition* use_defn = instr->AsDefinition();
        if (use_defn == NULL) {
          // We assume that tagging before returning or pushing argument costs
          // very little compared to the cost of the return/call itself.
          if (!instr->IsReturn() && !instr->IsPushArgument()) {
            gain--;
            if (FLAG_trace_smi_widening) {
              ISL_Print("v [%" Pd "] (u) %s\n",
                        gain,
                        use->instruction()->ToCString());
            }
          }
          continue;
        } else if (use_defn->IsBinarySmiOp() &&
                   CanBeWidened(use_defn->AsBinarySmiOp())) {
          worklist.Add(use_defn);
        } else if (use_defn->IsPhi() &&
                   use_defn->AsPhi()->Type()->ToCid() == kSmiCid) {
          worklist.Add(use_defn);
        } else if (use_defn->IsBinaryMintOp()) {
          // BinaryMintOp requires untagging of its inputs.
          // Converting kUnboxedInt32 to kUnboxedMint is essentially zero cost
          // sign extension operation.
          gain++;
          if (FLAG_trace_smi_widening) {
            ISL_Print("^ [%" Pd "] (u) %s\n",
                      gain,
                      use->instruction()->ToCString());
          }
        } else if (defn_loop == loops[instr->GetBlock()->preorder_number()]) {
          gain--;
          if (FLAG_trace_smi_widening) {
            ISL_Print("v [%" Pd "] (u) %s\n",
                      gain,
                      use->instruction()->ToCString());
          }
        }
      }
    }

    processed->AddAll(worklist.contains_vector());

    if (FLAG_trace_smi_widening) {
      ISL_Print("~ %s gain %" Pd "\n", op->ToCString(), gain);
    }

    if (gain > 0) {
      // We have positive gain from widening. Convert all BinarySmiOpInstr into
      // BinaryInt32OpInstr and set representation of all phis to kUnboxedInt32.
      for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
        Definition* defn = worklist.definitions()[j];
        ASSERT(defn->IsPhi() || defn->IsBinarySmiOp());

        if (defn->IsBinarySmiOp()) {
          BinarySmiOpInstr* smi_op = defn->AsBinarySmiOp();
          BinaryInt32OpInstr* int32_op = new(Z) BinaryInt32OpInstr(
            smi_op->op_kind(),
            smi_op->left()->CopyWithType(),
            smi_op->right()->CopyWithType(),
            smi_op->DeoptimizationTarget());

          smi_op->ReplaceWith(int32_op, NULL);
        } else if (defn->IsPhi()) {
          defn->AsPhi()->set_representation(kUnboxedInt32);
          ASSERT(defn->Type()->IsInt());
        }
      }
    }
  }
}
#else
void FlowGraphOptimizer::WidenSmiToInt32() {
  // TODO(vegorov) ideally on 64-bit platforms we would like to narrow smi
  // operations to 32-bit where it saves tagging and untagging and allows
  // to use shorted (and faster) instructions. But we currently don't
  // save enough range information in the ICData to drive this decision.
}
#endif

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
            Environment* env = current->env()->Outermost();
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
            new(flow_graph->zone()) ConstantInstr(orig->value());
        copy->set_ssa_temp_index(flow_graph->alloc_ssa_temp_index());
        old->ReplaceUsesWith(copy);
        (*idefs)[j] = copy;
      }
    }
  }
}


LICM::LICM(FlowGraph* flow_graph) : flow_graph_(flow_graph) {
  ASSERT(flow_graph->is_licm_allowed());
}


void LICM::Hoist(ForwardInstructionIterator* it,
                 BlockEntryInstr* pre_header,
                 Instruction* current) {
  if (current->IsCheckClass()) {
    current->AsCheckClass()->set_licm_hoisted(true);
  } else if (current->IsCheckSmi()) {
    current->AsCheckSmi()->set_licm_hoisted(true);
  } else if (current->IsCheckEitherNonSmi()) {
    current->AsCheckEitherNonSmi()->set_licm_hoisted(true);
  } else if (current->IsCheckArrayBound()) {
    current->AsCheckArrayBound()->set_licm_hoisted(true);
  }
  if (FLAG_trace_optimization) {
    ISL_Print("Hoisting instruction %s:%" Pd " from B%" Pd " to B%" Pd "\n",
              current->DebugName(),
              current->GetDeoptId(),
              current->GetBlock()->block_id(),
              pre_header->block_id());
  }
  // Move the instruction out of the loop.
  current->RemoveEnvironment();
  if (it != NULL) {
    it->RemoveCurrentFromGraph();
  } else {
    current->RemoveFromGraph();
  }
  GotoInstr* last = pre_header->last_instruction()->AsGoto();
  // Using kind kEffect will not assign a fresh ssa temporary index.
  flow_graph()->InsertBefore(last, current, last->env(), FlowGraph::kEffect);
  current->CopyDeoptIdFrom(*last);
}


void LICM::TrySpecializeSmiPhi(PhiInstr* phi,
                               BlockEntryInstr* header,
                               BlockEntryInstr* pre_header) {
  if (phi->Type()->ToCid() == kSmiCid) {
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

  CheckSmiInstr* check = NULL;
  for (Value* use = phi->input_use_list();
       (use != NULL) && (check == NULL);
       use = use->next_use()) {
    check = use->instruction()->AsCheckSmi();
  }

  if (check == NULL) {
    return;
  }

  // Host CheckSmi instruction and make this phi smi one.
  Hoist(NULL, pre_header, check);

  // Replace value we are checking with phi's input.
  check->value()->BindTo(phi->InputAt(non_smi_input)->definition());

  phi->UpdateType(CompileType::FromCid(kSmiCid));
}


// Load instructions handled by load elimination.
static bool IsLoadEliminationCandidate(Instruction* instr) {
  return instr->IsLoadField()
      || instr->IsLoadIndexed()
      || instr->IsLoadStaticField();
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


void LICM::OptimisticallySpecializeSmiPhis() {
  if (!flow_graph()->function().allows_hoisting_check_class()) {
    // Do not hoist any.
    return;
  }

  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      flow_graph()->LoopHeaders();

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    JoinEntryInstr* header = loop_headers[i]->AsJoinEntry();
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = header->ImmediateDominator();
    if (pre_header == NULL) continue;

    for (PhiIterator it(header); !it.Done(); it.Advance()) {
      TrySpecializeSmiPhi(it.Current(), header, pre_header);
    }
  }
}


void LICM::Optimize() {
  if (!flow_graph()->function().allows_hoisting_check_class()) {
    // Do not hoist any.
    return;
  }

  const ZoneGrowableArray<BlockEntryInstr*>& loop_headers =
      flow_graph()->LoopHeaders();

  ZoneGrowableArray<BitVector*>* loop_invariant_loads =
      flow_graph()->loop_invariant_loads();

  BlockEffects* block_effects = flow_graph()->block_effects();

  for (intptr_t i = 0; i < loop_headers.length(); ++i) {
    BlockEntryInstr* header = loop_headers[i];
    // Skip loop that don't have a pre-header block.
    BlockEntryInstr* pre_header = header->ImmediateDominator();
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
          }
        }
      }
    }
  }
}


// Place describes an abstract location (e.g. field) that IR can load
// from or store to.
//
// Places are also used to describe wild-card locations also known as aliases,
// that essentially represent sets of places that alias each other. Places A
// and B are said to alias each other if store into A can affect load from B.
//
// We distinguish the following aliases:
//
//   - for fields
//     - *.f, *.@offs - field inside some object;
//     - X.f, X.@offs - field inside an allocated object X;
//   - for indexed accesses
//     - *[*] - non-constant index inside some object;
//     - *[C] - constant index inside some object;
//     - X[*] - non-constant index inside an allocated object X;
//     - X[C] - constant index inside an allocated object X.
//
// Constant indexed places are divided into two subcategories:
//
//   - Access to homogeneous array-like objects: Array, ImmutableArray,
//     OneByteString, TwoByteString. These objects can only be accessed
//     on element by element basis with all elements having the same size.
//     This means X[C] aliases X[K] if and only if C === K.
//   - TypedData accesses. TypedData allow to read one of the primitive
//     data types at the given byte offset. When TypedData is accessed through
//     index operator on a typed array or a typed array view it is guaranteed
//     that the byte offset is always aligned by the element size. We write
//     these accesses as X[C|S], where C is constant byte offset and S is size
//     of the data type. Obviously X[C|S] and X[K|U] alias if and only if either
//     C = RoundDown(K, S) or K = RoundDown(C, U).
//     Note that not all accesses to typed data are aligned: e.g. ByteData
//     allows unanaligned access through it's get*/set* methods.
//     Check in Place::SetIndex ensures that we never create a place X[C|S]
//     such that C is not aligned by S.
//
// Separating allocations from other objects improves precision of the
// load forwarding pass because of the following two properties:
//
//   - if X can be proven to have no aliases itself (i.e. there is no other SSA
//     variable that points to X) then no place inside X can be aliased with any
//     wildcard dependent place (*.f, *.@offs, *[*], *[C]);
//   - given allocations X and Y no place inside X can be aliased with any place
//     inside Y even if any of them or both escape.
//
// It important to realize that single place can belong to multiple aliases.
// For example place X.f with aliased allocation X belongs both to X.f and *.f
// aliases. Likewise X[C] with non-aliased allocation X belongs to X[C] and X[*]
// aliases.
//
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

    // Indexed location with a non-constant index.
    kIndexed,

    // Indexed location with a constant index.
    kConstantIndexed,
  };

  // Size of the element accessed by constant index. Size is only important
  // for TypedData because those accesses can alias even when constant indexes
  // are not the same: X[0|4] aliases X[0|2] and X[2|2].
  enum ElementSize {
    // If indexed access is not a TypedData access then element size is not
    // important because there is only a single possible access size depending
    // on the receiver - X[C] aliases X[K] if and only if C == K.
    // This is the size set for Array, ImmutableArray, OneByteString and
    // TwoByteString accesses.
    kNoSize,

    // 1 byte (Int8List, Uint8List, Uint8ClampedList).
    kInt8,

    // 2 bytes (Int16List, Uint16List).
    kInt16,

    // 4 bytes (Int32List, Uint32List, Float32List).
    kInt32,

    // 8 bytes (Int64List, Uint64List, Float64List).
    kInt64,

    // 16 bytes (Int32x4List, Float32x4List, Float64x2List).
    kInt128,

    kLargestElementSize = kInt128,
  };

  Place(const Place& other)
      : ValueObject(),
        flags_(other.flags_),
        instance_(other.instance_),
        raw_selector_(other.raw_selector_),
        id_(other.id_) {
  }

  // Construct a place from instruction if instruction accesses any place.
  // Otherwise constructs kNone place.
  Place(Instruction* instr, bool* is_load, bool* is_store)
      : flags_(0),
        instance_(NULL),
        raw_selector_(0),
        id_(0) {
    switch (instr->tag()) {
      case Instruction::kLoadField: {
        LoadFieldInstr* load_field = instr->AsLoadField();
        set_representation(load_field->representation());
        instance_ = load_field->instance()->definition()->OriginalDefinition();
        if (load_field->field() != NULL) {
          set_kind(kField);
          field_ = load_field->field();
        } else {
          set_kind(kVMField);
          offset_in_bytes_ = load_field->offset_in_bytes();
        }
        *is_load = true;
        break;
      }

      case Instruction::kStoreInstanceField: {
        StoreInstanceFieldInstr* store =
            instr->AsStoreInstanceField();
        set_representation(store->RequiredInputRepresentation(
            StoreInstanceFieldInstr::kValuePos));
        instance_ = store->instance()->definition()->OriginalDefinition();
        if (!store->field().IsNull()) {
          set_kind(kField);
          field_ = &store->field();
        } else {
          set_kind(kVMField);
          offset_in_bytes_ = store->offset_in_bytes();
        }
        *is_store = true;
        break;
      }

      case Instruction::kLoadStaticField:
        set_kind(kField);
        set_representation(instr->AsLoadStaticField()->representation());
        field_ = &instr->AsLoadStaticField()->StaticField();
        *is_load = true;
        break;

      case Instruction::kStoreStaticField:
        set_kind(kField);
        set_representation(instr->AsStoreStaticField()->
            RequiredInputRepresentation(StoreStaticFieldInstr::kValuePos));
        field_ = &instr->AsStoreStaticField()->field();
        *is_store = true;
        break;

      case Instruction::kLoadIndexed: {
        LoadIndexedInstr* load_indexed = instr->AsLoadIndexed();
        set_representation(load_indexed->representation());
        instance_ = load_indexed->array()->definition()->OriginalDefinition();
        SetIndex(load_indexed->index()->definition(),
                 load_indexed->index_scale(),
                 load_indexed->class_id());
        *is_load = true;
        break;
      }

      case Instruction::kStoreIndexed: {
        StoreIndexedInstr* store_indexed = instr->AsStoreIndexed();
        set_representation(store_indexed->
            RequiredInputRepresentation(StoreIndexedInstr::kValuePos));
        instance_ = store_indexed->array()->definition()->OriginalDefinition();
        SetIndex(store_indexed->index()->definition(),
                 store_indexed->index_scale(),
                 store_indexed->class_id());
        *is_store = true;
        break;
      }

      default:
        break;
    }
  }

  // Create object representing *[*] alias.
  static Place* CreateAnyInstanceAnyIndexAlias(Zone* zone,
                                               intptr_t id) {
    return Wrap(zone, Place(
        EncodeFlags(kIndexed, kNoRepresentation, kNoSize),
        NULL,
        0), id);
  }

  // Return least generic alias for this place. Given that aliases are
  // essentially sets of places we define least generic alias as a smallest
  // alias that contains this place.
  //
  // We obtain such alias by a simple transformation:
  //
  //    - for places that depend on an instance X.f, X.@offs, X[i], X[C]
  //      we drop X if X is not an allocation because in this case X does not
  //      posess an identity obtaining aliases *.f, *.@offs, *[i] and *[C]
  //      respectively;
  //    - for non-constant indexed places X[i] we drop information about the
  //      index obtaining alias X[*].
  //    - we drop information about representation, but keep element size
  //      if any.
  //
  Place ToAlias() const {
    return Place(
        RepresentationBits::update(kNoRepresentation, flags_),
        (DependsOnInstance() && IsAllocation(instance())) ? instance() : NULL,
        (kind() == kIndexed) ? 0 : raw_selector_);
  }

  bool DependsOnInstance() const {
    switch (kind()) {
      case kField:
      case kVMField:
      case kIndexed:
      case kConstantIndexed:
        return true;

      case kNone:
        return false;
    }

    UNREACHABLE();
    return false;
  }

  // Given instance dependent alias X.f, X.@offs, X[C], X[*] return
  // wild-card dependent alias *.f, *.@offs, *[C] or *[*] respectively.
  Place CopyWithoutInstance() const {
    ASSERT(DependsOnInstance());
    return Place(flags_, NULL, raw_selector_);
  }

  // Given alias X[C] or *[C] return X[*] and *[*] respectively.
  Place CopyWithoutIndex() const {
    ASSERT(kind() == kConstantIndexed);
    return Place(EncodeFlags(kIndexed, kNoRepresentation, kNoSize),
                 instance_,
                 0);
  }

  // Given alias X[ByteOffs|S] and a larger element size S', return
  // alias X[RoundDown(ByteOffs, S')|S'] - this is the byte offset of a larger
  // typed array element that contains this typed array element.
  // In other words this method computes the only possible place with the given
  // size that can alias this place (due to alignment restrictions).
  // For example for X[9|kInt8] and target size kInt32 we would return
  // X[8|kInt32].
  Place ToLargerElement(ElementSize to) const {
    ASSERT(kind() == kConstantIndexed);
    ASSERT(element_size() != kNoSize);
    ASSERT(element_size() < to);
    return Place(ElementSizeBits::update(to, flags_),
                 instance_,
                 RoundByteOffset(to, index_constant_));
  }


  intptr_t id() const { return id_; }

  Kind kind() const { return KindBits::decode(flags_); }

  Representation representation() const {
    return RepresentationBits::decode(flags_);
  }

  Definition* instance() const {
    ASSERT(DependsOnInstance());
    return instance_;
  }

  void set_instance(Definition* def) {
    ASSERT(DependsOnInstance());
    instance_ = def->OriginalDefinition();
  }

  const Field& field() const {
    ASSERT(kind() == kField);
    return *field_;
  }

  intptr_t offset_in_bytes() const {
    ASSERT(kind() == kVMField);
    return offset_in_bytes_;
  }

  Definition* index() const {
    ASSERT(kind() == kIndexed);
    return index_;
  }

  ElementSize element_size() const {
    return ElementSizeBits::decode(flags_);
  }

  intptr_t index_constant() const {
    ASSERT(kind() == kConstantIndexed);
    return index_constant_;
  }

  static const char* DefinitionName(Definition* def) {
    if (def == NULL) {
      return "*";
    } else {
      return Thread::Current()->zone()->PrintToString(
            "v%" Pd, def->ssa_temp_index());
    }
  }

  const char* ToCString() const {
    switch (kind()) {
      case kNone:
        return "<none>";

      case kField: {
        const char* field_name = String::Handle(field().name()).ToCString();
        if (field().is_static()) {
          return Thread::Current()->zone()->PrintToString(
              "<%s>", field_name);
        } else {
          return Thread::Current()->zone()->PrintToString(
              "<%s.%s>", DefinitionName(instance()), field_name);
        }
      }

      case kVMField:
        return Thread::Current()->zone()->PrintToString(
            "<%s.@%" Pd ">",
            DefinitionName(instance()),
            offset_in_bytes());

      case kIndexed:
        return Thread::Current()->zone()->PrintToString(
            "<%s[%s]>",
            DefinitionName(instance()),
            DefinitionName(index()));

      case kConstantIndexed:
        if (element_size() == kNoSize) {
          return Thread::Current()->zone()->PrintToString(
              "<%s[%" Pd "]>",
              DefinitionName(instance()),
              index_constant());
        } else {
          return Thread::Current()->zone()->PrintToString(
              "<%s[%" Pd "|%" Pd "]>",
              DefinitionName(instance()),
              index_constant(),
              ElementSizeMultiplier(element_size()));
        }
    }
    UNREACHABLE();
    return "<?>";
  }

  bool IsFinalField() const {
    return (kind() == kField) && field().is_final();
  }

  intptr_t Hashcode() const {
    return (flags_ * 63 + reinterpret_cast<intptr_t>(instance_)) * 31 +
        FieldHashcode();
  }

  bool Equals(const Place* other) const {
    return (flags_ == other->flags_) &&
        (instance_ == other->instance_) &&
        SameField(other);
  }

  // Create a zone allocated copy of this place and assign given id to it.
  static Place* Wrap(Zone* zone, const Place& place, intptr_t id);

  static bool IsAllocation(Definition* defn) {
    return (defn != NULL) &&
        (defn->IsAllocateObject() ||
         defn->IsCreateArray() ||
         defn->IsAllocateUninitializedContext() ||
         (defn->IsStaticCall() &&
          defn->AsStaticCall()->IsRecognizedFactory()));
  }

 private:
  Place(uword flags, Definition* instance, intptr_t selector)
      : flags_(flags),
        instance_(instance),
        raw_selector_(selector),
        id_(0) {
  }

  bool SameField(const Place* other) const {
    return (kind() == kField) ? (field().raw() == other->field().raw())
                              : (offset_in_bytes_ == other->offset_in_bytes_);
  }

  intptr_t FieldHashcode() const {
    return (kind() == kField) ? reinterpret_cast<intptr_t>(field().raw())
                              : offset_in_bytes_;
  }

  void set_representation(Representation rep) {
    flags_ = RepresentationBits::update(rep, flags_);
  }

  void set_kind(Kind kind) {
    flags_ = KindBits::update(kind, flags_);
  }

  void set_element_size(ElementSize scale) {
    flags_ = ElementSizeBits::update(scale, flags_);
  }

  void SetIndex(Definition* index, intptr_t scale, intptr_t class_id) {
    ConstantInstr* index_constant = index->AsConstant();
    if ((index_constant != NULL) && index_constant->value().IsSmi()) {
      const intptr_t index_value = Smi::Cast(index_constant->value()).Value();
      const ElementSize size = ElementSizeFor(class_id);
      const bool is_typed_data = (size != kNoSize);

      // If we are writing into the typed data scale the index to
      // get byte offset. Otherwise ignore the scale.
      if (!is_typed_data) {
        scale = 1;
      }

      // Guard against potential multiplication overflow and negative indices.
      if ((0 <= index_value) && (index_value < (kMaxInt32 / scale))) {
        const intptr_t scaled_index = index_value * scale;

        // Guard against unaligned byte offsets.
        if (!is_typed_data ||
            Utils::IsAligned(scaled_index, ElementSizeMultiplier(size))) {
          set_kind(kConstantIndexed);
          set_element_size(size);
          index_constant_ = scaled_index;
          return;
        }
      }

      // Fallthrough: create generic _[*] place.
    }

    set_kind(kIndexed);
    index_ = index;
  }

  static uword EncodeFlags(Kind kind, Representation rep, ElementSize scale) {
    ASSERT((kind == kConstantIndexed) || (scale == kNoSize));
    return KindBits::encode(kind) |
        RepresentationBits::encode(rep) |
        ElementSizeBits::encode(scale);
  }

  static ElementSize ElementSizeFor(intptr_t class_id) {
    switch (class_id) {
      case kArrayCid:
      case kImmutableArrayCid:
      case kOneByteStringCid:
      case kTwoByteStringCid:
        // Object arrays and strings do not allow accessing them through
        // different types. No need to attach scale.
        return kNoSize;

      case kTypedDataInt8ArrayCid:
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        return kInt8;

      case kTypedDataInt16ArrayCid:
      case kTypedDataUint16ArrayCid:
        return kInt16;

      case kTypedDataInt32ArrayCid:
      case kTypedDataUint32ArrayCid:
      case kTypedDataFloat32ArrayCid:
        return kInt32;

      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
      case kTypedDataFloat64ArrayCid:
        return kInt64;

      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataFloat64x2ArrayCid:
        return kInt128;

      default:
        UNREACHABLE();
        return kNoSize;
    }
  }

  static intptr_t ElementSizeMultiplier(ElementSize size) {
    return 1 << (static_cast<intptr_t>(size) - static_cast<intptr_t>(kInt8));
  }

  static intptr_t RoundByteOffset(ElementSize size, intptr_t offset) {
    return offset & ~(ElementSizeMultiplier(size) - 1);
  }

  typedef BitField<Kind, 0, 3> KindBits;
  typedef BitField<Representation, KindBits::kNextBit, 11> RepresentationBits;
  typedef BitField<
      ElementSize, RepresentationBits::kNextBit, 3> ElementSizeBits;

  uword flags_;
  Definition* instance_;
  union {
    intptr_t raw_selector_;
    const Field* field_;
    intptr_t offset_in_bytes_;
    intptr_t index_constant_;
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


Place* Place::Wrap(Zone* zone, const Place& place, intptr_t id) {
  Place* wrapped = (new(zone) ZonePlace(place))->place();
  wrapped->id_ = id;
  return wrapped;
}


// Correspondence between places connected through outgoing phi moves on the
// edge that targets join.
class PhiPlaceMoves : public ZoneAllocated {
 public:
  // Record a move from the place with id |from| to the place with id |to| at
  // the given block.
  void CreateOutgoingMove(Zone* zone,
                          BlockEntryInstr* block, intptr_t from, intptr_t to) {
    const intptr_t block_num = block->preorder_number();
    while (moves_.length() <= block_num) {
      moves_.Add(NULL);
    }

    if (moves_[block_num] == NULL) {
      moves_[block_num] = new(zone) ZoneGrowableArray<Move>(5);
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
  AliasedSet(Zone* zone,
             DirectChainedHashMap<PointerKeyValueTrait<Place> >* places_map,
             ZoneGrowableArray<Place*>* places,
             PhiPlaceMoves* phi_moves)
      : zone_(zone),
        places_map_(places_map),
        places_(*places),
        phi_moves_(phi_moves),
        aliases_(5),
        aliases_map_(),
        typed_data_access_sizes_(),
        representatives_(),
        killed_(),
        aliased_by_effects_(new(zone) BitVector(zone, places->length())) {
    InsertAlias(Place::CreateAnyInstanceAnyIndexAlias(zone_,
        kAnyInstanceAnyIndexAlias));
    for (intptr_t i = 0; i < places_.length(); i++) {
      AddRepresentative(places_[i]);
    }
    ComputeKillSets();
  }

  intptr_t LookupAliasId(const Place& alias) {
    const Place* result = aliases_map_.Lookup(&alias);
    return (result != NULL) ? result->id() : static_cast<intptr_t>(kNoAlias);
  }

  BitVector* GetKilledSet(intptr_t alias) {
    return (alias < killed_.length()) ? killed_[alias] : NULL;
  }

  intptr_t max_place_id() const { return places().length(); }
  bool IsEmpty() const { return max_place_id() == 0; }

  BitVector* aliased_by_effects() const { return aliased_by_effects_; }

  const ZoneGrowableArray<Place*>& places() const {
    return places_;
  }

  Place* LookupCanonical(Place* place) const {
    return places_map_->Lookup(place);
  }

  void PrintSet(BitVector* set) {
    bool comma = false;
    for (BitVector::Iterator it(set);
         !it.Done();
         it.Advance()) {
      if (comma) {
        ISL_Print(", ");
      }
      ISL_Print("%s", places_[it.Current()]->ToCString());
      comma = true;
    }
  }

  const PhiPlaceMoves* phi_moves() const { return phi_moves_; }

  void RollbackAliasedIdentites() {
    for (intptr_t i = 0; i < identity_rollback_.length(); ++i) {
      identity_rollback_[i]->SetIdentity(AliasIdentity::Unknown());
    }
  }

  // Returns false if the result of an allocation instruction can't be aliased
  // by another SSA variable and true otherwise.
  bool CanBeAliased(Definition* alloc) {
    if (!Place::IsAllocation(alloc)) {
      return true;
    }

    if (alloc->Identity().IsUnknown()) {
      ComputeAliasing(alloc);
    }

    return !alloc->Identity().IsNotAliased();
  }

  enum {
    kNoAlias = 0
  };

 private:
  enum {
    // Artificial alias that is used to collect all representatives of the
    // *[C], X[C] aliases for arbitrary C.
    kAnyConstantIndexedAlias = 1,

    // Artificial alias that is used to collect all representatives of
    // *[C] alias for arbitrary C.
    kUnknownInstanceConstantIndexedAlias = 2,

    // Artificial alias that is used to collect all representatives of
    // X[*] alias for all X.
    kAnyAllocationIndexedAlias = 3,

    // *[*] alias.
    kAnyInstanceAnyIndexAlias = 4
  };

  // Compute least generic alias for the place and assign alias id to it.
  void AddRepresentative(Place* place) {
    if (!place->IsFinalField()) {
      const Place* alias = CanonicalizeAlias(place->ToAlias());
      EnsureSet(&representatives_, alias->id())->Add(place->id());

      // Update cumulative representative sets that are used during
      // killed sets computation.
      if (alias->kind() == Place::kConstantIndexed) {
        if (CanBeAliased(alias->instance())) {
          EnsureSet(&representatives_, kAnyConstantIndexedAlias)->
              Add(place->id());
        }

        if (alias->instance() == NULL) {
          EnsureSet(&representatives_, kUnknownInstanceConstantIndexedAlias)->
              Add(place->id());
        }

        // Collect all element sizes used to access TypedData arrays in
        // the function. This is used to skip sizes without representatives
        // when computing kill sets.
        if (alias->element_size() != Place::kNoSize) {
          typed_data_access_sizes_.Add(alias->element_size());
        }
      } else if ((alias->kind() == Place::kIndexed) &&
                 CanBeAliased(place->instance())) {
        EnsureSet(&representatives_, kAnyAllocationIndexedAlias)->
            Add(place->id());
      }

      if (!IsIndependentFromEffects(place)) {
        aliased_by_effects_->Add(place->id());
      }
    }
  }

  void ComputeKillSets() {
    for (intptr_t i = 0; i < aliases_.length(); ++i) {
      const Place* alias = aliases_[i];
      // Add all representatives to the kill set.
      AddAllRepresentatives(alias->id(), alias->id());
      ComputeKillSet(alias);
    }

    if (FLAG_trace_load_optimization) {
      ISL_Print("Aliases KILL sets:\n");
      for (intptr_t i = 0; i < aliases_.length(); ++i) {
        const Place* alias = aliases_[i];
        BitVector* kill = GetKilledSet(alias->id());

        ISL_Print("%s: ", alias->ToCString());
        if (kill != NULL) {
          PrintSet(kill);
        }
        ISL_Print("\n");
      }
    }
  }

  void InsertAlias(const Place* alias) {
    aliases_map_.Insert(alias);
    aliases_.Add(alias);
  }

  const Place* CanonicalizeAlias(const Place& alias) {
    const Place* canonical = aliases_map_.Lookup(&alias);
    if (canonical == NULL) {
      canonical = Place::Wrap(zone_,
                              alias,
                              kAnyInstanceAnyIndexAlias + aliases_.length());
      InsertAlias(canonical);
    }
    ASSERT(aliases_map_.Lookup(&alias) == canonical);
    return canonical;
  }

  BitVector* GetRepresentativesSet(intptr_t alias) {
    return (alias < representatives_.length()) ? representatives_[alias] : NULL;
  }

  BitVector* EnsureSet(GrowableArray<BitVector*>* sets,
                       intptr_t alias) {
    while (sets->length() <= alias) {
      sets->Add(NULL);
    }

    BitVector* set = (*sets)[alias];
    if (set == NULL) {
      (*sets)[alias] = set = new(zone_) BitVector(zone_, max_place_id());
    }
    return set;
  }

  void AddAllRepresentatives(const Place* to, intptr_t from) {
    AddAllRepresentatives(to->id(), from);
  }

  void AddAllRepresentatives(intptr_t to, intptr_t from) {
    BitVector* from_set = GetRepresentativesSet(from);
    if (from_set != NULL) {
      EnsureSet(&killed_, to)->AddAll(from_set);
    }
  }

  void CrossAlias(const Place* to, const Place& from) {
    const intptr_t from_id = LookupAliasId(from);
    if (from_id == kNoAlias) {
      return;
    }
    CrossAlias(to, from_id);
  }

  void CrossAlias(const Place* to, intptr_t from) {
    AddAllRepresentatives(to->id(), from);
    AddAllRepresentatives(from, to->id());
  }

  // When computing kill sets we let less generic alias insert its
  // representatives into more generic alias'es kill set. For example
  // when visiting alias X[*] instead of searching for all aliases X[C]
  // and inserting their representatives into kill set for X[*] we update
  // kill set for X[*] each time we visit new X[C] for some C.
  // There is an exception however: if both aliases are parametric like *[C]
  // and X[*] which cross alias when X is an aliased allocation then we use
  // artificial aliases that contain all possible representatives for the given
  // alias for any value of the parameter to compute resulting kill set.
  void ComputeKillSet(const Place* alias) {
    switch (alias->kind()) {
      case Place::kIndexed:  // Either *[*] or X[*] alias.
        if (alias->instance() == NULL) {
          // *[*] aliases with X[*], X[C], *[C].
          AddAllRepresentatives(alias, kAnyConstantIndexedAlias);
          AddAllRepresentatives(alias, kAnyAllocationIndexedAlias);
        } else if (CanBeAliased(alias->instance())) {
          // X[*] aliases with X[C].
          // If X can be aliased then X[*] also aliases with *[C], *[*].
          CrossAlias(alias, kAnyInstanceAnyIndexAlias);
          AddAllRepresentatives(alias, kUnknownInstanceConstantIndexedAlias);
        }
        break;

      case Place::kConstantIndexed:  // Either X[C] or *[C] alias.
        if (alias->element_size() != Place::kNoSize) {
          const bool has_aliased_instance =
              (alias->instance() != NULL) && CanBeAliased(alias->instance());

          // If this is a TypedData access then X[C|S] aliases larger elements
          // covering this one X[RoundDown(C, S')|S'] for all S' > S and
          // all smaller elements being covered by this one X[C'|S'] for
          // some S' < S and all C' such that C = RoundDown(C', S).
          // In the loop below it's enough to only propagate aliasing to
          // larger aliases because propagation is symmetric: smaller aliases
          // (if there are any) would update kill set for this alias when they
          // are visited.
          for (intptr_t i = static_cast<intptr_t>(alias->element_size()) + 1;
               i <= Place::kLargestElementSize;
               i++) {
            // Skip element sizes that a guaranteed to have no representatives.
            if (!typed_data_access_sizes_.Contains(alias->element_size())) {
              continue;
            }

            // X[C|S] aliases with X[RoundDown(C, S')|S'] and likewise
            // *[C|S] aliases with *[RoundDown(C, S')|S'].
            const Place larger_alias =
                alias->ToLargerElement(static_cast<Place::ElementSize>(i));
            CrossAlias(alias, larger_alias);
            if (has_aliased_instance) {
              // If X is an aliased instance then X[C|S] aliases
              // with *[RoundDown(C, S')|S'].
              CrossAlias(alias, larger_alias.CopyWithoutInstance());
            }
          }
        }

        if (alias->instance() == NULL) {
          // *[C] aliases with X[C], X[*], *[*].
          AddAllRepresentatives(alias, kAnyAllocationIndexedAlias);
          CrossAlias(alias, kAnyInstanceAnyIndexAlias);
        } else {
          // X[C] aliases with X[*].
          // If X can be aliased then X[C] also aliases with *[C], *[*].
          CrossAlias(alias, alias->CopyWithoutIndex());
          if (CanBeAliased(alias->instance())) {
            CrossAlias(alias, alias->CopyWithoutInstance());
            CrossAlias(alias, kAnyInstanceAnyIndexAlias);
          }
        }
        break;

      case Place::kField:
      case Place::kVMField:
        if (CanBeAliased(alias->instance())) {
          // X.f or X.@offs alias with *.f and *.@offs respectively.
          CrossAlias(alias, alias->CopyWithoutInstance());
        }
        break;

      case Place::kNone:
        UNREACHABLE();
    }
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

    return ((place->kind() == Place::kField) ||
         (place->kind() == Place::kVMField)) &&
        !CanBeAliased(place->instance());
  }

  // Returns true if there are direct loads from the given place.
  bool HasLoadsFromPlace(Definition* defn, const Place* place) {
    ASSERT((place->kind() == Place::kField) ||
           (place->kind() == Place::kVMField));

    for (Value* use = defn->input_use_list();
         use != NULL;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if ((instr->IsRedefinition() ||
           instr->IsAssertAssignable()) &&
          HasLoadsFromPlace(instr->AsDefinition(), place)) {
        return true;
      }
      bool is_load = false, is_store;
      Place load_place(instr, &is_load, &is_store);

      if (is_load && load_place.Equals(place)) {
        return true;
      }
    }

    return false;
  }

  // Check if any use of the definition can create an alias.
  // Can add more objects into aliasing_worklist_.
  bool AnyUseCreatesAlias(Definition* defn) {
    for (Value* use = defn->input_use_list();
         use != NULL;
         use = use->next_use()) {
      Instruction* instr = use->instruction();
      if (instr->IsPushArgument() ||
          (instr->IsStoreIndexed()
           && (use->use_index() == StoreIndexedInstr::kValuePos)) ||
          instr->IsStoreStaticField() ||
          instr->IsPhi()) {
        return true;
      } else if ((instr->IsAssertAssignable() || instr->IsRedefinition()) &&
                 AnyUseCreatesAlias(instr->AsDefinition())) {
        return true;
      } else if ((instr->IsStoreInstanceField()
           && (use->use_index() != StoreInstanceFieldInstr::kInstancePos))) {
        ASSERT(use->use_index() == StoreInstanceFieldInstr::kValuePos);
        // If we store this value into an object that is not aliased itself
        // and we never load again then the store does not create an alias.
        StoreInstanceFieldInstr* store = instr->AsStoreInstanceField();
        Definition* instance =
            store->instance()->definition()->OriginalDefinition();
        if (Place::IsAllocation(instance) &&
            !instance->Identity().IsAliased()) {
          bool is_load, is_store;
          Place store_place(instr, &is_load, &is_store);

          if (!HasLoadsFromPlace(instance, &store_place)) {
            // No loads found that match this store. If it is yet unknown if
            // the object is not aliased then optimistically assume this but
            // add it to the worklist to check its uses transitively.
            if (instance->Identity().IsUnknown()) {
              instance->SetIdentity(AliasIdentity::NotAliased());
              aliasing_worklist_.Add(instance);
            }
            continue;
          }
        }
        return true;
      }
    }
    return false;
  }

  // Mark any value stored into the given object as potentially aliased.
  void MarkStoredValuesEscaping(Definition* defn) {
    // Find all stores into this object.
    for (Value* use = defn->input_use_list();
         use != NULL;
         use = use->next_use()) {
      if (use->instruction()->IsRedefinition() ||
          use->instruction()->IsAssertAssignable()) {
        MarkStoredValuesEscaping(use->instruction()->AsDefinition());
        continue;
      }
      if ((use->use_index() == StoreInstanceFieldInstr::kInstancePos) &&
          use->instruction()->IsStoreInstanceField()) {
        StoreInstanceFieldInstr* store =
            use->instruction()->AsStoreInstanceField();
        Definition* value = store->value()->definition()->OriginalDefinition();
        if (value->Identity().IsNotAliased()) {
          value->SetIdentity(AliasIdentity::Aliased());
          identity_rollback_.Add(value);

          // Add to worklist to propagate the mark transitively.
          aliasing_worklist_.Add(value);
        }
      }
    }
  }

  // Determine if the given definition can't be aliased.
  void ComputeAliasing(Definition* alloc) {
    ASSERT(Place::IsAllocation(alloc));
    ASSERT(alloc->Identity().IsUnknown());
    ASSERT(aliasing_worklist_.is_empty());

    alloc->SetIdentity(AliasIdentity::NotAliased());
    aliasing_worklist_.Add(alloc);

    while (!aliasing_worklist_.is_empty()) {
      Definition* defn = aliasing_worklist_.RemoveLast();
      ASSERT(Place::IsAllocation(defn));
      // If the definition in the worklist was optimistically marked as
      // not-aliased check that optimistic assumption still holds: check if
      // any of its uses can create an alias.
      if (!defn->Identity().IsAliased() && AnyUseCreatesAlias(defn)) {
        defn->SetIdentity(AliasIdentity::Aliased());
        identity_rollback_.Add(defn);
      }

      // If the allocation site is marked as aliased conservatively mark
      // any values stored into the object aliased too.
      if (defn->Identity().IsAliased()) {
        MarkStoredValuesEscaping(defn);
      }
    }
  }

  Zone* zone_;

  DirectChainedHashMap<PointerKeyValueTrait<Place> >* places_map_;

  const ZoneGrowableArray<Place*>& places_;

  const PhiPlaceMoves* phi_moves_;

  // A list of all seen aliases and a map that allows looking up canonical
  // alias object.
  GrowableArray<const Place*> aliases_;
  DirectChainedHashMap<PointerKeyValueTrait<const Place> > aliases_map_;

  SmallSet<Place::ElementSize> typed_data_access_sizes_;

  // Maps alias id to set of ids of places representing the alias.
  // Place represents an alias if this alias is least generic alias for
  // the place.
  // (see ToAlias for the definition of least generic alias).
  GrowableArray<BitVector*> representatives_;

  // Maps alias id to set of ids of places aliased.
  GrowableArray<BitVector*> killed_;

  // Set of ids of places that can be affected by side-effects other than
  // explicit stores (i.e. through calls).
  BitVector* aliased_by_effects_;

  // Worklist used during alias analysis.
  GrowableArray<Definition*> aliasing_worklist_;

  // List of definitions that had their identity set to Aliased. At the end
  // of load optimization their identity will be rolled back to Unknown to
  // avoid treating them as Aliased at later stages without checking first
  // as optimizations can potentially eliminate instructions leading to
  // aliasing.
  GrowableArray<Definition*> identity_rollback_;
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
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  PhiPlaceMoves* phi_moves = new(zone) PhiPlaceMoves();

  for (intptr_t i = 0; i < places->length(); i++) {
    Place* place = (*places)[i];

    if (IsPhiDependentPlace(place)) {
      PhiInstr* phi = place->instance()->AsPhi();
      BlockEntryInstr* block = phi->GetBlock();

      if (FLAG_trace_optimization) {
        ISL_Print("phi dependent place %s\n", place->ToCString());
      }

      Place input_place(*place);
      for (intptr_t j = 0; j < phi->InputCount(); j++) {
        input_place.set_instance(phi->InputAt(j)->definition());

        Place* result = map->Lookup(&input_place);
        if (result == NULL) {
          result = Place::Wrap(zone, input_place, places->length());
          map->Insert(result);
          places->Add(result);
          if (FLAG_trace_optimization) {
            ISL_Print("  adding place %s as %" Pd "\n",
                      result->ToCString(),
                      result->id());
          }
        }
        phi_moves->CreateOutgoingMove(zone,
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
  Zone* zone = graph->zone();
  ZoneGrowableArray<Place*>* places =
      new(zone) ZoneGrowableArray<Place*>(10);

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
        result = Place::Wrap(zone, place, places->length());
        map->Insert(result);
        places->Add(result);

        if (FLAG_trace_optimization) {
          ISL_Print("numbering %s as %" Pd "\n",
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
  return new(zone) AliasedSet(zone, map, places, phi_moves);
}


class LoadOptimizer : public ValueObject {
 public:
  LoadOptimizer(FlowGraph* graph, AliasedSet* aliased_set)
      : graph_(graph),
        aliased_set_(aliased_set),
        in_(graph_->preorder().length()),
        out_(graph_->preorder().length()),
        gen_(graph_->preorder().length()),
        kill_(graph_->preorder().length()),
        exposed_values_(graph_->preorder().length()),
        out_values_(graph_->preorder().length()),
        phis_(5),
        worklist_(5),
        congruency_worklist_(6),
        in_worklist_(NULL),
        forwarded_(false) {
    const intptr_t num_blocks = graph_->preorder().length();
    for (intptr_t i = 0; i < num_blocks; i++) {
      out_.Add(NULL);
      gen_.Add(new(Z) BitVector(Z, aliased_set_->max_place_id()));
      kill_.Add(new(Z) BitVector(Z, aliased_set_->max_place_id()));
      in_.Add(new(Z) BitVector(Z, aliased_set_->max_place_id()));

      exposed_values_.Add(NULL);
      out_values_.Add(NULL);
    }
  }

  ~LoadOptimizer() {
    aliased_set_->RollbackAliasedIdentites();
  }

  Isolate* isolate() const { return graph_->isolate(); }
  Zone* zone() const { return graph_->zone(); }

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
      LoadOptimizer load_optimizer(graph, aliased_set);
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

        bool is_load = false, is_store = false;
        Place place(instr, &is_load, &is_store);

        BitVector* killed = NULL;
        if (is_store) {
          const intptr_t alias_id =
              aliased_set_->LookupAliasId(place.ToAlias());
          if (alias_id != AliasedSet::kNoAlias) {
            killed = aliased_set_->GetKilledSet(alias_id);
          } else if (!place.IsFinalField()) {
            // We encountered unknown alias: this means intrablock load
            // forwarding refined parameter of this store, for example
            //
            //     o   <- alloc()
            //     a.f <- o
            //     u   <- a.f
            //     u.x <- null ;; this store alias is *.x
            //
            // after intrablock load forwarding
            //
            //     o   <- alloc()
            //     a.f <- o
            //     o.x <- null ;; this store alias is o.x
            //
            // In this case we fallback to using place id recorded in the
            // instruction that still points to the old place with a more
            // generic alias.
            const intptr_t old_alias_id = aliased_set_->LookupAliasId(
                aliased_set_->places()[instr->place_id()]->ToAlias());
            killed = aliased_set_->GetKilledSet(old_alias_id);
          }

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
            Place* canonical_place = aliased_set_->LookupCanonical(&place);
            if (canonical_place != NULL) {
              // Store has a corresponding numbered place that might have a
              // load. Try forwarding stored value to it.
              gen->Add(canonical_place->id());
              if (out_values == NULL) out_values = CreateBlockOutValues();
              (*out_values)[canonical_place->id()] = GetStoredValue(instr);
            }
          }

          ASSERT(!instr->IsDefinition() ||
                 !IsLoadEliminationCandidate(instr->AsDefinition()));
          continue;
        } else if (is_load) {
          // Check if this load needs renumbering because of the intrablock
          // load forwarding.
          const Place* canonical = aliased_set_->LookupCanonical(&place);
          if ((canonical != NULL) &&
            (canonical->id() != instr->AsDefinition()->place_id())) {
            instr->AsDefinition()->set_place_id(canonical->id());
          }
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
        // subsequent loads. For skip final fields.  Final fields are
        // initialized in constructor that potentially can be not inlined into
        // the function that we are currently optimizing. However at the same
        // time we assume that values of the final fields can be forwarded
        // across side-effects. If we add 'null' as known values for these
        // fields here we will incorrectly propagate this null across
        // constructor invocation.
        AllocateObjectInstr* alloc = instr->AsAllocateObject();
        if ((alloc != NULL)) {
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

              // Forward for all fields for non-escaping objects and only
              // non-final fields and type arguments for escaping ones.
              if (aliased_set_->CanBeAliased(alloc) &&
                  (load->field() != NULL) &&
                  load->field()->is_final()) {
                continue;
              }

              Definition* forward_def = graph_->constant_null();
              if (alloc->ArgumentCount() > 0) {
                ASSERT(alloc->ArgumentCount() == 1);
                intptr_t type_args_offset =
                    alloc->cls().type_arguments_field_offset();
                if (load->offset_in_bytes() == type_args_offset) {
                  forward_def = alloc->PushArgumentAt(0)->value()->definition();
                }
              }
              gen->Add(load->place_id());
              if (out_values == NULL) out_values = CreateBlockOutValues();
              (*out_values)[load->place_id()] = forward_def;
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
            ISL_Print("Replacing load v%" Pd " with v%" Pd "\n",
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
            exposed_values = new(Z) ZoneGrowableArray<Definition*>(
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
    BitVector* temp = new(Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* forwarded_loads =
        new(Z) BitVector(Z, aliased_set_->max_place_id());
    BitVector* temp_out = new(Z) BitVector(Z, aliased_set_->max_place_id());

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
                  new(Z) BitVector(Z, aliased_set_->max_place_id());
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
            PhiInstr* phi = new(Z) PhiInstr(block->AsJoinEntry(),
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
        ISL_Print("B%" Pd "\n", block->block_id());
        ISL_Print("  IN: ");
        aliased_set_->PrintSet(in_[preorder_number]);
        ISL_Print("\n");

        ISL_Print("  KILL: ");
        aliased_set_->PrintSet(kill_[preorder_number]);
        ISL_Print("\n");

        ISL_Print("  OUT: ");
        aliased_set_->PrintSet(out_[preorder_number]);
        ISL_Print("\n");
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
        graph_->LoopHeaders();

    ZoneGrowableArray<BitVector*>* invariant_loads =
        new(Z) ZoneGrowableArray<BitVector*>(loop_headers.length());

    for (intptr_t i = 0; i < loop_headers.length(); i++) {
      BlockEntryInstr* header = loop_headers[i];
      BlockEntryInstr* pre_header = header->ImmediateDominator();
      if (pre_header == NULL) {
        invariant_loads->Add(NULL);
        continue;
      }

      BitVector* loop_gen = new(Z) BitVector(Z, aliased_set_->max_place_id());
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
          ISL_Print("place %s is loop invariant for B%" Pd "\n",
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
    PhiInstr* phi = new(Z) PhiInstr(
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
      Value* input = new(Z) Value(replacement);
      phi->SetInputAt(i, input);
      replacement->AddInputUse(input);
    }

    phi->set_ssa_temp_index(graph_->alloc_ssa_temp_index());
    phis_.Add(phi);  // Postpone phi insertion until after load forwarding.

    if (FLAG_trace_load_optimization) {
      ISL_Print("created pending phi %s for %s at B%" Pd "\n",
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
            ISL_Print("Replacing load v%" Pd " with v%" Pd "\n",
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
      in_worklist_ = new(Z) BitVector(Z, graph_->current_ssa_temp_index());
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

  // Returns true if definitions are congruent assuming their inputs
  // are congruent.
  bool CanBeCongruent(Definition* a, Definition* b) {
    return (a->tag() == b->tag()) &&
       ((a->IsPhi() && (a->GetBlock() == b->GetBlock())) ||
        (a->AllowsCSE() && a->Dependencies().IsNone() &&
         a->AttributesEqual(b)));
  }

  // Given two definitions check if they are congruent under assumption that
  // their inputs will be proven congruent. If they are - add them to the
  // worklist to check their inputs' congruency.
  // Returns true if pair was added to the worklist or is already in the
  // worklist and false if a and b are not congruent.
  bool AddPairToCongruencyWorklist(Definition* a, Definition* b) {
    if (!CanBeCongruent(a, b)) {
      return false;
    }

    // If a is already in the worklist check if it is being compared to b.
    // Give up if it is not.
    if (in_worklist_->Contains(a->ssa_temp_index())) {
      for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
        if (a == congruency_worklist_[i]) {
          return (b == congruency_worklist_[i + 1]);
        }
      }
      UNREACHABLE();
    } else if (in_worklist_->Contains(b->ssa_temp_index())) {
      return AddPairToCongruencyWorklist(b, a);
    }

    congruency_worklist_.Add(a);
    congruency_worklist_.Add(b);
    in_worklist_->Add(a->ssa_temp_index());
    return true;
  }

  bool AreInputsCongruent(Definition* a, Definition* b) {
    ASSERT(a->tag() == b->tag());
    ASSERT(a->InputCount() == b->InputCount());
    for (intptr_t j = 0; j < a->InputCount(); j++) {
      Definition* inputA = a->InputAt(j)->definition();
      Definition* inputB = b->InputAt(j)->definition();

      if (inputA != inputB) {
        if (!AddPairToCongruencyWorklist(inputA, inputB)) {
          return false;
        }
      }
    }
    return true;
  }

  // Returns true if instruction dom dominates instruction other.
  static bool Dominates(Instruction* dom, Instruction* other) {
    BlockEntryInstr* dom_block = dom->GetBlock();
    BlockEntryInstr* other_block = other->GetBlock();

    if (dom_block == other_block) {
      for (Instruction* current = dom->next();
           current != NULL;
           current = current->next()) {
        if (current == other) {
          return true;
        }
      }
      return false;
    }

    return dom_block->Dominates(other_block);
  }

  // Replace the given phi with another if they are congruent.
  // Returns true if succeeds.
  bool ReplacePhiWith(PhiInstr* phi, PhiInstr* replacement) {
    ASSERT(phi->InputCount() == replacement->InputCount());
    ASSERT(phi->block() == replacement->block());

    congruency_worklist_.Clear();
    if (in_worklist_ == NULL) {
      in_worklist_ = new(Z) BitVector(Z, graph_->current_ssa_temp_index());
    } else {
      in_worklist_->Clear();
    }

    // During the comparison worklist contains pairs of definitions to be
    // compared.
    if (!AddPairToCongruencyWorklist(phi, replacement)) {
      return false;
    }

    // Process the worklist. It might grow during each comparison step.
    for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
      if (!AreInputsCongruent(congruency_worklist_[i],
                              congruency_worklist_[i + 1])) {
        return false;
      }
    }

    // At this point worklist contains pairs of congruent definitions.
    // Replace the one member of the pair with another maintaining proper
    // domination relation between definitions and uses.
    for (intptr_t i = 0; i < congruency_worklist_.length(); i += 2) {
      Definition* a = congruency_worklist_[i];
      Definition* b = congruency_worklist_[i + 1];

      // If these definitions are not phis then we need to pick up one
      // that dominates another as the replacement: if a dominates b swap them.
      // Note: both a and b are used as a phi input at the same block B which
      // means a dominates B and b dominates B, which guarantees that either
      // a dominates b or b dominates a.
      if (!a->IsPhi()) {
        if (Dominates(a, b)) {
          Definition* t = a;
          a = b;
          b = t;
        }
        ASSERT(Dominates(b, a));
      }

      if (FLAG_trace_load_optimization) {
        ISL_Print("Replacing %s with congruent %s\n",
                  a->ToCString(),
                  b->ToCString());
      }

      a->ReplaceUsesWith(b);
      if (a->IsPhi()) {
        // We might be replacing a phi introduced by the load forwarding
        // that is not inserted in the graph yet.
        ASSERT(b->IsPhi());
        PhiInstr* phi_a = a->AsPhi();
        if (phi_a->is_alive()) {
          phi_a->mark_dead();
          phi_a->block()->RemovePhi(phi_a);
          phi_a->UnuseAllInputs();
        }
      } else {
        a->RemoveFromGraph();
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
        new(Z) ZoneGrowableArray<Definition*>(aliased_set_->max_place_id());
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
  GrowableArray<Definition*> congruency_worklist_;
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
      case Instruction::kStoreInstanceField: {
        StoreInstanceFieldInstr* store_instance = instr->AsStoreInstanceField();
        // Can't eliminate stores that initialize fields.
        return !(store_instance->is_potential_unboxed_initialization() ||
                 store_instance->is_object_reference_initialization());
      }
      case Instruction::kStoreIndexed:
      case Instruction::kStoreStaticField:
        return true;
      default:
        UNREACHABLE();
        return false;
    }
  }

  virtual void ComputeInitialSets() {
    Zone* zone = graph_->zone();
    BitVector* all_places = new(zone) BitVector(zone,
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
                ISL_Print(
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
              exposed_stores = new(zone) ZoneGrowableArray<Instruction*>(
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
          const intptr_t alias = aliased_set_->LookupAliasId(place.ToAlias());
          live_in->AddAll(aliased_set_->GetKilledSet(alias));
          continue;
        }
      }
      exposed_stores_[postorder_number] = exposed_stores;
    }
    if (FLAG_trace_load_optimization) {
      Dump();
      ISL_Print("---\n");
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
            ISL_Print("Removing dead store to place %" Pd " block B%" Pd "\n",
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


// Returns true iff this definition is used in a non-phi instruction.
static bool HasRealUse(Definition* def) {
  // Environment uses are real (non-phi) uses.
  if (def->env_use_list() != NULL) return true;

  for (Value::Iterator it(def->input_use_list());
       !it.Done();
       it.Advance()) {
    if (!it.Current()->instruction()->IsPhi()) return true;
  }
  return false;
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
        if (HasRealUse(phi) || join->InsideTryBlock()) {
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
              ISL_Print("Removing dead phi v%" Pd "\n", phi->ssa_temp_index());
            }
          } else if (phi->IsRedundant()) {
            phi->ReplaceUsesWith(phi->InputAt(0)->definition());
            phi->UnuseAllInputs();
            (*join->phis_)[i] = NULL;
            if (FLAG_trace_optimization) {
              ISL_Print("Removing redundant phi v%" Pd "\n",
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


JoinEntryInstr* BranchSimplifier::ToJoinEntry(Zone* zone,
                                              TargetEntryInstr* target) {
  // Convert a target block into a join block.  Branches will be duplicated
  // so the former true and false targets become joins of the control flows
  // from all the duplicated branches.
  JoinEntryInstr* join =
      new(zone) JoinEntryInstr(target->block_id(), target->try_index());
  join->InheritDeoptTarget(zone, target);
  join->LinkTo(target->next());
  join->set_last_instruction(target->last_instruction());
  target->UnuseAllInputs();
  return join;
}


BranchInstr* BranchSimplifier::CloneBranch(Zone* zone,
                                           BranchInstr* branch,
                                           Value* new_left,
                                           Value* new_right) {
  ComparisonInstr* comparison = branch->comparison();
  ComparisonInstr* new_comparison =
      comparison->CopyWithNewOperands(new_left, new_right);
  BranchInstr* new_branch = new(zone) BranchInstr(new_comparison);
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
  Zone* zone = flow_graph->zone();
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
          ToJoinEntry(zone, branch->true_successor());
      JoinEntryInstr* join_false =
          ToJoinEntry(zone, branch->false_successor());

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
        Value* new_left = phi->InputAt(i)->Copy(zone);
        Value* new_right = new(zone) Value(constant);
        BranchInstr* new_branch =
            CloneBranch(zone, branch, new_left, new_right);
        if (branch->env() == NULL) {
          new_branch->InheritDeoptTarget(zone, old_goto);
        } else {
          // Take the environment from the branch if it has one.
          new_branch->InheritDeoptTarget(zone, branch);
          // InheritDeoptTarget gave the new branch's comparison the same
          // deopt id that it gave the new branch.  The id should be the
          // deopt id of the original comparison.
          new_branch->comparison()->SetDeoptId(*comparison);
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
            new(zone) TargetEntryInstr(flow_graph->max_block_id() + 1,
                                          block->try_index());
        true_target->InheritDeoptTarget(zone, join_true);
        TargetEntryInstr* false_target =
            new(zone) TargetEntryInstr(flow_graph->max_block_id() + 2,
                                          block->try_index());
        false_target->InheritDeoptTarget(zone, join_false);
        flow_graph->set_max_block_id(flow_graph->max_block_id() + 2);
        *new_branch->true_successor_address() = true_target;
        *new_branch->false_successor_address() = false_target;
        GotoInstr* goto_true = new(zone) GotoInstr(join_true);
        goto_true->InheritDeoptTarget(zone, join_true);
        true_target->LinkTo(goto_true);
        true_target->set_last_instruction(goto_true);
        GotoInstr* goto_false = new(zone) GotoInstr(join_false);
        goto_false->InheritDeoptTarget(zone, join_false);
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
  Zone* zone = flow_graph->zone();
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
                  comparison->left()->Copy(zone),
                  comparison->right()->Copy(zone));
          IfThenElseInstr* if_then_else = new(zone) IfThenElseInstr(
              new_comparison,
              if_true->Copy(zone),
              if_false->Copy(zone));
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


enum SafeUseCheck { kOptimisticCheck, kStrictCheck };

// Check if the use is safe for allocation sinking. Allocation sinking
// candidates can only be used at store instructions:
//
//     - any store into the allocation candidate itself is unconditionally safe
//       as it just changes the rematerialization state of this candidate;
//     - store into another object is only safe if another object is allocation
//       candidate.
//
// We use a simple fix-point algorithm to discover the set of valid candidates
// (see CollectCandidates method), that's why this IsSafeUse can operate in two
// modes:
//
//     - optimistic, when every allocation is assumed to be an allocation
//       sinking candidate;
//     - strict, when only marked allocations are assumed to be allocation
//       sinking candidates.
//
// Fix-point algorithm in CollectCandiates first collects a set of allocations
// optimistically and then checks each collected candidate strictly and unmarks
// invalid candidates transitively until only strictly valid ones remain.
static bool IsSafeUse(Value* use, SafeUseCheck check_type) {
  if (use->instruction()->IsMaterializeObject()) {
    return true;
  }

  StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
  if (store != NULL) {
    if (use == store->value()) {
      Definition* instance = store->instance()->definition();
      return instance->IsAllocateObject() &&
          ((check_type == kOptimisticCheck) ||
           instance->Identity().IsAllocationSinkingCandidate());
    }
    return true;
  }

  return false;
}


// Right now we are attempting to sink allocation only into
// deoptimization exit. So candidate should only be used in StoreInstanceField
// instructions that write into fields of the allocated object.
// We do not support materialization of the object that has type arguments.
static bool IsAllocationSinkingCandidate(Definition* alloc,
                                         SafeUseCheck check_type) {
  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = use->next_use()) {
    if (!IsSafeUse(use, check_type)) {
      if (FLAG_trace_optimization) {
        ISL_Print("use of %s at %s is unsafe for allocation sinking\n",
                  alloc->ToCString(),
                  use->instruction()->ToCString());
      }
      return false;
    }
  }

  return true;
}


// If the given use is a store into an object then return an object we are
// storing into.
static Definition* StoreInto(Value* use) {
  StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
  if (store != NULL) {
    return store->instance()->definition();
  }

  return NULL;
}


// Remove the given allocation from the graph. It is not observable.
// If deoptimization occurs the object will be materialized.
void AllocationSinking::EliminateAllocation(Definition* alloc) {
  ASSERT(IsAllocationSinkingCandidate(alloc, kStrictCheck));

  if (FLAG_trace_optimization) {
    ISL_Print("removing allocation from the graph: v%" Pd "\n",
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
#ifdef DEBUG
  for (Value* use = alloc->env_use_list();
       use != NULL;
       use = use->next_use()) {
    ASSERT(use->instruction()->IsMaterializeObject());
  }
#endif
  ASSERT(alloc->input_use_list() == NULL);
  alloc->RemoveFromGraph();
  if (alloc->ArgumentCount() > 0) {
    ASSERT(alloc->ArgumentCount() == 1);
    for (intptr_t i = 0; i < alloc->ArgumentCount(); ++i) {
      alloc->PushArgumentAt(i)->RemoveFromGraph();
    }
  }
}


// Find allocation instructions that can be potentially eliminated and
// rematerialized at deoptimization exits if needed. See IsSafeUse
// for the description of algorithm used below.
void AllocationSinking::CollectCandidates() {
  // Optimistically collect all potential candidates.
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    BlockEntryInstr* block = block_it.Current();
    for (ForwardInstructionIterator it(block); !it.Done(); it.Advance()) {
      { AllocateObjectInstr* alloc = it.Current()->AsAllocateObject();
        if ((alloc != NULL) &&
            IsAllocationSinkingCandidate(alloc, kOptimisticCheck)) {
          alloc->SetIdentity(AliasIdentity::AllocationSinkingCandidate());
          candidates_.Add(alloc);
        }
      }
      { AllocateUninitializedContextInstr* alloc =
            it.Current()->AsAllocateUninitializedContext();
        if ((alloc != NULL) &&
            IsAllocationSinkingCandidate(alloc, kOptimisticCheck)) {
          alloc->SetIdentity(AliasIdentity::AllocationSinkingCandidate());
          candidates_.Add(alloc);
        }
      }
    }
  }

  // Transitively unmark all candidates that are not strictly valid.
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < candidates_.length(); i++) {
      Definition* alloc = candidates_[i];
      if (alloc->Identity().IsAllocationSinkingCandidate()) {
        if (!IsAllocationSinkingCandidate(alloc, kStrictCheck)) {
          alloc->SetIdentity(AliasIdentity::Unknown());
          changed = true;
        }
      }
    }
  } while (changed);

  // Shrink the list of candidates removing all unmarked ones.
  intptr_t j = 0;
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];
    if (alloc->Identity().IsAllocationSinkingCandidate()) {
      if (FLAG_trace_optimization) {
        ISL_Print("discovered allocation sinking candidate: v%" Pd "\n",
                  alloc->ssa_temp_index());
      }

      if (j != i) {
        candidates_[j] = alloc;
      }
      j++;
    }
  }
  candidates_.TruncateTo(j);
}


// If materialization references an allocation sinking candidate then replace
// this reference with a materialization which should have been computed for
// this side-exit. CollectAllExits should have collected this exit.
void AllocationSinking::NormalizeMaterializations() {
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];

    Value* next_use;
    for (Value* use = alloc->input_use_list();
         use != NULL;
         use = next_use) {
      next_use = use->next_use();
      if (use->instruction()->IsMaterializeObject()) {
        use->BindTo(MaterializationFor(alloc, use->instruction()));
      }
    }
  }
}


// We transitively insert materializations at each deoptimization exit that
// might see the given allocation (see ExitsCollector). Some of this
// materializations are not actually used and some fail to compute because
// they are inserted in the block that is not dominated by the allocation.
// Remove them unused materializations from the graph.
void AllocationSinking::RemoveUnusedMaterializations() {
  intptr_t j = 0;
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    if ((mat->input_use_list() == NULL) && (mat->env_use_list() == NULL)) {
      // Check if this materialization failed to compute and remove any
      // unforwarded loads. There were no loads from any allocation sinking
      // candidate in the beggining so it is safe to assume that any encountered
      // load was inserted by CreateMaterializationAt.
      for (intptr_t i = 0; i < mat->InputCount(); i++) {
        LoadFieldInstr* load = mat->InputAt(i)->definition()->AsLoadField();
        if ((load != NULL) &&
            (load->instance()->definition() == mat->allocation())) {
          load->ReplaceUsesWith(flow_graph_->constant_null());
          load->RemoveFromGraph();
        }
      }
      mat->RemoveFromGraph();
    } else {
      if (j != i) {
        materializations_[j] = mat;
      }
      j++;
    }
  }
  materializations_.TruncateTo(j);
}


// Some candidates might stop being eligible for allocation sinking after
// the load forwarding because they flow into phis that load forwarding
// inserts. Discover such allocations and remove them from the list
// of allocation sinking candidates undoing all changes that we did
// in preparation for sinking these allocations.
void AllocationSinking::DiscoverFailedCandidates() {
  // Transitively unmark all candidates that are not strictly valid.
  bool changed;
  do {
    changed = false;
    for (intptr_t i = 0; i < candidates_.length(); i++) {
      Definition* alloc = candidates_[i];
      if (alloc->Identity().IsAllocationSinkingCandidate()) {
        if (!IsAllocationSinkingCandidate(alloc, kStrictCheck)) {
          alloc->SetIdentity(AliasIdentity::Unknown());
          changed = true;
        }
      }
    }
  } while (changed);

  // Remove all failed candidates from the candidates list.
  intptr_t j = 0;
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    Definition* alloc = candidates_[i];
    if (!alloc->Identity().IsAllocationSinkingCandidate()) {
      if (FLAG_trace_optimization) {
        ISL_Print("allocation v%" Pd " can't be eliminated\n",
                  alloc->ssa_temp_index());
      }

#ifdef DEBUG
      for (Value* use = alloc->env_use_list();
           use != NULL;
           use = use->next_use()) {
        ASSERT(use->instruction()->IsMaterializeObject());
      }
#endif

      // All materializations will be removed from the graph. Remove inserted
      // loads first and detach materializations from allocation's environment
      // use list: we will reconstruct it when we start removing
      // materializations.
      alloc->set_env_use_list(NULL);
      for (Value* use = alloc->input_use_list();
           use != NULL;
           use = use->next_use()) {
        if (use->instruction()->IsLoadField()) {
          LoadFieldInstr* load = use->instruction()->AsLoadField();
          load->ReplaceUsesWith(flow_graph_->constant_null());
          load->RemoveFromGraph();
        } else {
          ASSERT(use->instruction()->IsMaterializeObject() ||
                 use->instruction()->IsPhi() ||
                 use->instruction()->IsStoreInstanceField());
        }
      }
    } else {
      if (j != i) {
        candidates_[j] = alloc;
      }
      j++;
    }
  }

  if (j != candidates_.length()) {  // Something was removed from candidates.
    intptr_t k = 0;
    for (intptr_t i = 0; i < materializations_.length(); i++) {
      MaterializeObjectInstr* mat = materializations_[i];
      if (!mat->allocation()->Identity().IsAllocationSinkingCandidate()) {
        // Restore environment uses of the allocation that were replaced
        // by this materialization and drop materialization.
        mat->ReplaceUsesWith(mat->allocation());
        mat->RemoveFromGraph();
      } else {
        if (k != i) {
          materializations_[k] = mat;
        }
        k++;
      }
    }
    materializations_.TruncateTo(k);
  }

  candidates_.TruncateTo(j);
}


void AllocationSinking::Optimize() {
  CollectCandidates();

  // Insert MaterializeObject instructions that will describe the state of the
  // object at all deoptimization points. Each inserted materialization looks
  // like this (where v_0 is allocation that we are going to eliminate):
  //   v_1     <- LoadField(v_0, field_1)
  //           ...
  //   v_N     <- LoadField(v_0, field_N)
  //   v_{N+1} <- MaterializeObject(field_1 = v_1, ..., field_N = v_{N})
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    InsertMaterializations(candidates_[i]);
  }

  // Run load forwarding to eliminate LoadField instructions inserted above.
  // All loads will be successfully eliminated because:
  //   a) they use fields (not offsets) and thus provide precise aliasing
  //      information
  //   b) candidate does not escape and thus its fields is not affected by
  //      external effects from calls.
  LoadOptimizer::OptimizeGraph(flow_graph_);

  NormalizeMaterializations();

  RemoveUnusedMaterializations();

  // If any candidates are no longer eligible for allocation sinking abort
  // the optimization for them and undo any changes we did in preparation.
  DiscoverFailedCandidates();

  // At this point we have computed the state of object at each deoptimization
  // point and we can eliminate it. Loads inserted above were forwarded so there
  // are no uses of the allocation just as in the begging of the pass.
  for (intptr_t i = 0; i < candidates_.length(); i++) {
    EliminateAllocation(candidates_[i]);
  }

  // Process materializations and unbox their arguments: materializations
  // are part of the environment and can materialize boxes for double/mint/simd
  // values when needed.
  // TODO(vegorov): handle all box types here.
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    MaterializeObjectInstr* mat = materializations_[i];
    for (intptr_t j = 0; j < mat->InputCount(); j++) {
      Definition* defn = mat->InputAt(j)->definition();
      if (defn->IsBox()) {
        mat->InputAt(j)->BindTo(defn->InputAt(0)->definition());
      }
    }
  }
}


// Remove materializations from the graph. Register allocator will treat them
// as part of the environment not as a real instruction.
void AllocationSinking::DetachMaterializations() {
  for (intptr_t i = 0; i < materializations_.length(); i++) {
    materializations_[i]->previous()->LinkTo(materializations_[i]->next());
  }
}


// Add a field/offset to the list of fields if it is not yet present there.
static bool AddSlot(ZoneGrowableArray<const Object*>* slots,
                    const Object& slot) {
  for (intptr_t i = 0; i < slots->length(); i++) {
    if ((*slots)[i]->raw() == slot.raw()) {
      return false;
    }
  }
  slots->Add(&slot);
  return true;
}


// Find deoptimization exit for the given materialization assuming that all
// materializations are emitted right before the instruction which is a
// deoptimization exit.
static Instruction* ExitForMaterialization(MaterializeObjectInstr* mat) {
  while (mat->next()->IsMaterializeObject()) {
    mat = mat->next()->AsMaterializeObject();
  }
  return mat->next();
}


// Given the deoptimization exit find first materialization that was inserted
// before it.
static Instruction* FirstMaterializationAt(Instruction* exit) {
  while (exit->previous()->IsMaterializeObject()) {
    exit = exit->previous();
  }
  return exit;
}


// Given the allocation and deoptimization exit try to find MaterializeObject
// instruction corresponding to this allocation at this exit.
MaterializeObjectInstr* AllocationSinking::MaterializationFor(
    Definition* alloc, Instruction* exit) {
  if (exit->IsMaterializeObject()) {
    exit = ExitForMaterialization(exit->AsMaterializeObject());
  }

  for (MaterializeObjectInstr* mat = exit->previous()->AsMaterializeObject();
       mat != NULL;
       mat = mat->previous()->AsMaterializeObject()) {
    if (mat->allocation() == alloc) {
      return mat;
    }
  }

  return NULL;
}


// Insert MaterializeObject instruction for the given allocation before
// the given instruction that can deoptimize.
void AllocationSinking::CreateMaterializationAt(
    Instruction* exit,
    Definition* alloc,
    const ZoneGrowableArray<const Object*>& slots) {
  ZoneGrowableArray<Value*>* values =
      new(Z) ZoneGrowableArray<Value*>(slots.length());

  // All loads should be inserted before the first materialization so that
  // IR follows the following pattern: loads, materializations, deoptimizing
  // instruction.
  Instruction* load_point = FirstMaterializationAt(exit);

  // Insert load instruction for every field.
  for (intptr_t i = 0; i < slots.length(); i++) {
    LoadFieldInstr* load = slots[i]->IsField()
        ? new(Z) LoadFieldInstr(
            new(Z) Value(alloc),
            &Field::Cast(*slots[i]),
            AbstractType::ZoneHandle(Z),
            alloc->token_pos())
        : new(Z) LoadFieldInstr(
            new(Z) Value(alloc),
            Smi::Cast(*slots[i]).Value(),
            AbstractType::ZoneHandle(Z),
            alloc->token_pos());
    flow_graph_->InsertBefore(
        load_point, load, NULL, FlowGraph::kValue);
    values->Add(new(Z) Value(load));
  }

  MaterializeObjectInstr* mat = NULL;
  if (alloc->IsAllocateObject()) {
    mat = new(Z) MaterializeObjectInstr(
        alloc->AsAllocateObject(), slots, values);
  } else {
    ASSERT(alloc->IsAllocateUninitializedContext());
    mat = new(Z) MaterializeObjectInstr(
        alloc->AsAllocateUninitializedContext(), slots, values);
  }

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

  // Mark MaterializeObject as an environment use of this allocation.
  // This will allow us to discover it when we are looking for deoptimization
  // exits for another allocation that potentially flows into this one.
  Value* val = new(Z) Value(alloc);
  val->set_instruction(mat);
  alloc->AddEnvUse(val);

  // Record inserted materialization.
  materializations_.Add(mat);
}


// Add given instruction to the list of the instructions if it is not yet
// present there.
template<typename T>
void AddInstruction(GrowableArray<T*>* list, T* value) {
  ASSERT(!value->IsGraphEntry());
  for (intptr_t i = 0; i < list->length(); i++) {
    if ((*list)[i] == value) {
      return;
    }
  }
  list->Add(value);
}


// Transitively collect all deoptimization exits that might need this allocation
// rematerialized. It is not enough to collect only environment uses of this
// allocation because it can flow into other objects that will be
// dematerialized and that are referenced by deopt environments that
// don't contain this allocation explicitly.
void AllocationSinking::ExitsCollector::Collect(Definition* alloc) {
  for (Value* use = alloc->env_use_list();
       use != NULL;
       use = use->next_use()) {
    if (use->instruction()->IsMaterializeObject()) {
      AddInstruction(&exits_, ExitForMaterialization(
          use->instruction()->AsMaterializeObject()));
    } else {
      AddInstruction(&exits_, use->instruction());
    }
  }

  // Check if this allocation is stored into any other allocation sinking
  // candidate and put it on worklist so that we conservatively collect all
  // exits for that candidate as well because they potentially might see
  // this object.
  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = use->next_use()) {
    Definition* obj = StoreInto(use);
    if ((obj != NULL) && (obj != alloc)) {
      AddInstruction(&worklist_, obj);
    }
  }
}


void AllocationSinking::ExitsCollector::CollectTransitively(Definition* alloc) {
  exits_.TruncateTo(0);
  worklist_.TruncateTo(0);

  worklist_.Add(alloc);

  // Note: worklist potentially will grow while we are iterating over it.
  // We are not removing allocations from the worklist not to waste space on
  // the side maintaining BitVector of already processed allocations: worklist
  // is expected to be very small thus linear search in it is just as effecient
  // as a bitvector.
  for (intptr_t i = 0; i < worklist_.length(); i++) {
    Collect(worklist_[i]);
  }
}


void AllocationSinking::InsertMaterializations(Definition* alloc) {
  // Collect all fields that are written for this instance.
  ZoneGrowableArray<const Object*>* slots =
      new(Z) ZoneGrowableArray<const Object*>(5);

  for (Value* use = alloc->input_use_list();
       use != NULL;
       use = use->next_use()) {
    StoreInstanceFieldInstr* store = use->instruction()->AsStoreInstanceField();
    if ((store != NULL) && (store->instance()->definition() == alloc)) {
      if (!store->field().IsNull()) {
        AddSlot(slots, store->field());
      } else {
        AddSlot(slots, Smi::ZoneHandle(Z, Smi::New(store->offset_in_bytes())));
      }
    }
  }

  if (alloc->ArgumentCount() > 0) {
    AllocateObjectInstr* alloc_object = alloc->AsAllocateObject();
    ASSERT(alloc_object->ArgumentCount() == 1);
    intptr_t type_args_offset =
        alloc_object->cls().type_arguments_field_offset();
    AddSlot(slots, Smi::ZoneHandle(Z, Smi::New(type_args_offset)));
  }

  // Collect all instructions that mention this object in the environment.
  exits_collector_.CollectTransitively(alloc);

  // Insert materializations at environment uses.
  for (intptr_t i = 0; i < exits_collector_.exits().length(); i++) {
    CreateMaterializationAt(
        exits_collector_.exits()[i], alloc, *slots);
  }
}


}  // namespace dart
