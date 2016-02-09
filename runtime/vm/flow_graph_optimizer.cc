// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flow_graph_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/branch_optimizer.h"
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
#include "vm/precompiler.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(int, getter_setter_ratio, 13,
    "Ratio of getter/setter usage used for double field unboxing heuristics");
DEFINE_FLAG(bool, guess_icdata_cid, true,
    "Artificially create type feedback for arithmetic etc. operations"
    " by guessing the other unknown argument cid");
DEFINE_FLAG(int, max_polymorphic_checks, 4,
    "Maximum number of polymorphic check, otherwise it is megamorphic.");
DEFINE_FLAG(int, max_equality_polymorphic_checks, 32,
    "Maximum number of polymorphic checks in equality operator,"
    " otherwise use megamorphic dispatch.");
DEFINE_FLAG(bool, merge_sin_cos, false, "Merge sin/cos into sincos");
DEFINE_FLAG(bool, trace_optimization, false, "Print optimization details.");
DEFINE_FLAG(bool, truncating_left_shift, true,
    "Optimize left shift to truncate if possible");
DEFINE_FLAG(bool, use_cha_deopt, true,
    "Use class hierarchy analysis even if it can cause deoptimization.");
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_IA32)
DEFINE_FLAG(bool, trace_smi_widening, false, "Trace Smi->Int32 widening pass.");
#endif

DECLARE_FLAG(bool, precompilation);
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
    if (call->ic_data()->MayCheckForJSWarning()) {
      return false;
    }
  }
  GrowableArray<intptr_t> class_ids(call->ic_data()->NumArgsTested());
  ASSERT(call->ic_data()->NumArgsTested() <= call->ArgumentCount());
  for (intptr_t i = 0; i < call->ic_data()->NumArgsTested(); i++) {
    class_ids.Add(call->PushArgumentAt(i)->value()->Type()->ToCid());
  }

  const Token::Kind op_kind = call->token_kind();
  if (Token::IsRelationalOperator(op_kind) ||
      Token::IsEqualityOperator(op_kind) ||
      Token::IsBinaryOperator(op_kind)) {
    // Guess cid: if one of the inputs is a number assume that the other
    // is a number of same type.
    if (FLAG_guess_icdata_cid) {
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
    const Class& receiver_class = Class::Handle(Z,
        isolate()->class_table()->At(class_ids[0]));
    if (!receiver_class.is_finalized()) {
      // Do not eagerly finalize classes. ResolveDynamicForReceiverClass can
      // cause class finalization, since callee's receiver class may not be
      // finalized yet.
      return false;
    }
    const Array& args_desc_array = Array::Handle(Z,
        ArgumentsDescriptor::New(call->ArgumentCount(),
                                 call->argument_names()));
    ArgumentsDescriptor args_desc(args_desc_array);
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

#ifdef DART_PRECOMPILER
  if (FLAG_precompilation &&
      (isolate()->object_store()->unique_dynamic_targets() != Array::null())) {
    // Check if the target is unique.
    Function& target_function = Function::Handle(Z);
    Precompiler::GetUniqueDynamicTarget(
        isolate(), call->function_name(), &target_function);
    // Calls with named arguments must be resolved/checked at runtime.
    String& error_message = String::Handle(Z);
    if (!target_function.IsNull() &&
        !target_function.HasOptionalNamedParameters() &&
        target_function.AreValidArgumentCounts(call->ArgumentCount(), 0,
                                               &error_message)) {
      const intptr_t cid = Class::Handle(Z, target_function.Owner()).id();
      const ICData& ic_data = ICData::ZoneHandle(Z,
          ICData::NewFrom(*call->ic_data(), 1));
      ic_data.AddReceiverCheck(cid, target_function);
      call->set_ic_data(&ic_data);
      return true;
    }
  }
#endif

  // Check if getter or setter in function's class and class is currently leaf.
  if (FLAG_guess_icdata_cid &&
      ((call->token_kind() == Token::kGET) ||
          (call->token_kind() == Token::kSET))) {
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
      if (!function.IsNull()) {
        const ICData& ic_data = ICData::ZoneHandle(Z,
            ICData::NewFrom(*call->ic_data(), class_ids.length()));
        ic_data.AddReceiverCheck(owner_class.id(), function);
        call->set_ic_data(&ic_data);
        return true;
      }
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
        Function::Handle(Z, ic_data.Owner()),
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
        Thread::kNoDeoptId);  // BIT_AND cannot deoptimize.
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
                                      Thread::kNoDeoptId,
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
        flow_graph_->ReplaceCurrentInstruction(&it, current, replacement);
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
      deopt_target->DeoptimizationTarget() : Thread::kNoDeoptId;
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
        deopt_target->DeoptimizationTarget() : Thread::kNoDeoptId;
    ASSERT(CanUnboxDouble());
    converted = new MintToDoubleInstr(use->CopyWithType(), deopt_id);
  } else if ((from == kTagged) && Boxing::Supports(to)) {
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Thread::kNoDeoptId;
    converted = UnboxInstr::Create(to, use->CopyWithType(), deopt_id);
  } else if ((to == kTagged) && Boxing::Supports(from)) {
    converted = BoxInstr::Create(from, use->CopyWithType());
  } else {
    // We have failed to find a suitable conversion instruction.
    // Insert two "dummy" conversion instructions with the correct
    // "from" and "to" representation. The inserted instructions will
    // trigger a deoptimization if executed. See #12417 for a discussion.
    const intptr_t deopt_id = (deopt_target != NULL) ?
        deopt_target->DeoptimizationTarget() : Thread::kNoDeoptId;
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
      RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt64)) {
    // On 32-bit platforms conservatively unbox phis that:
    //   - are proven to be of type Int;
    //   - fit into 64bits range;
    //   - have either constants or Box() operations as inputs;
    //   - have at least one Box() operation as an input;
    //   - are used in at least 1 Unbox() operation.
    bool should_unbox = false;
    for (intptr_t i = 0; i < phi->InputCount(); i++) {
      Definition* input = phi->InputAt(i)->definition();
      if (input->IsBox() &&
          RangeUtils::Fits(input->range(),
                           RangeBoundary::kRangeBoundaryInt64)) {
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
      unboxed =
          RangeUtils::Fits(phi->range(), RangeBoundary::kRangeBoundaryInt32)
          ? kUnboxedInt32 : kUnboxedMint;
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
  const intptr_t len = ic_data.NumberOfChecks();
  GrowableArray<intptr_t> class_ids;
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      ic_data.GetClassIdsAt(i, &class_ids);
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
  const intptr_t len = ic_data.NumberOfChecks();
  for (intptr_t i = 0; i < len; i++) {
    if (ic_data.IsUsedAt(i)) {
      GrowableArray<intptr_t> class_ids;
      ic_data.GetClassIdsAt(i, &class_ids);
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
                                               TokenPosition token_pos) {
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
    TokenPosition token_pos,
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
        type_args = flow_graph_->constant_null();
        ASSERT((array_cid != kTypedDataFloat32ArrayCid &&
                array_cid != kTypedDataFloat64ArrayCid) ||
               value_type.IsDoubleType());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat32x4ArrayCid: {
        type_args = flow_graph_->constant_null();
        ASSERT((array_cid != kTypedDataFloat32x4ArrayCid) ||
               value_type.IsFloat32x4Type());
        ASSERT(value_type.IsInstantiated());
        break;
      }
      case kTypedDataFloat64x2ArrayCid: {
        type_args = flow_graph_->constant_null();
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
                                                   TokenPosition token_pos,
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
            Object::dynamic_type(),
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

  intptr_t deopt_id = Thread::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Thread::kNoDeoptId : call->deopt_id();
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
      deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (array_cid == kTypedDataFloat32ArrayCid) {
    *last = new(Z) FloatToDoubleInstr(new(Z) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
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
RawField* FlowGraphOptimizer::GetField(intptr_t class_id,
                                       const String& field_name) {
  Class& cls = Class::Handle(Z, isolate()->class_table()->At(class_id));
  Field& field = Field::Handle(Z);
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
  if (!FLAG_use_cha_deopt && !isolate()->all_classes_finalized()) {
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
        THR_Print("  **(CHA) Instance call needs no check, "
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
  GrowableArray<intptr_t> class_ids;
  ic_data.GetClassIdsAt(0, &class_ids);
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
      Thread::kNoDeoptId,
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
    return TryReplaceInstanceCallWithInline(call);
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
  if (FLAG_precompilation) {
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
  if (FLAG_precompilation) {
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
  if (FLAG_precompilation) {
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

  intptr_t deopt_id = Thread::kNoDeoptId;
  if ((array_cid == kTypedDataInt32ArrayCid) ||
      (array_cid == kTypedDataUint32ArrayCid)) {
    // Deoptimization may be needed if result does not always fit in a Smi.
    deopt_id = (kSmiBits >= 32) ? Thread::kNoDeoptId : call->deopt_id();
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
      deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
      FlowGraph::kValue);

  if (view_cid == kTypedDataFloat32ArrayCid) {
    *last = new(Z) FloatToDoubleInstr(new(Z) Value(*last), deopt_id);
    flow_graph()->AppendTo(cursor,
                           *last,
                           deopt_id != Thread::kNoDeoptId ? call->env() : NULL,
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
                                Thread::kNoDeoptId,
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
                                  Thread::kNoDeoptId,
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
                                Thread::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kDoubleCid, target);
      break;
    }
    case kTypedDataInt32x4ArrayCid: {
      // Check that value is always Int32x4.
      value_check = ICData::New(flow_graph_->function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Thread::kNoDeoptId,
                                1);
      value_check.AddReceiverCheck(kInt32x4Cid, target);
      break;
    }
    case kTypedDataFloat32x4ArrayCid: {
      // Check that value is always Float32x4.
      value_check = ICData::New(flow_graph_->function(),
                                i_call->function_name(),
                                Object::empty_array(),  // Dummy args. descr.
                                Thread::kNoDeoptId,
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
                         call->deopt_id() != Thread::kNoDeoptId ?
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
  if (type.IsFunctionType() || type.IsDartFunctionType() ||
      !type.IsInstantiated() || type.IsMalformedOrMalbounded()) {
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
        NULL,
        Heap::kOld);
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
  // Function types have different type checking rules.
  if (type.IsFunctionType()) return false;
  const Class& type_class = Class::Handle(type.type_class());
  // Could be an interface check?
  if (CHA::IsImplemented(type_class)) return false;
  // Check if there are subclasses.
  if (CHA::HasSubclasses(type_class)) {
    return false;
  }

  // Private classes cannot be subclassed by later loaded libs.
  if (!type_class.IsPrivate()) {
    if (FLAG_use_cha_deopt || isolate()->all_classes_finalized()) {
      if (FLAG_trace_cha) {
        THR_Print("  **(CHA) Typecheck as class equality since no "
            "subclasses: %s\n",
            type_class.ToCString());
      }
      if (FLAG_use_cha_deopt) {
        thread()->cha()->AddToLeafClasses(type_class);
      }
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
                                                NULL,
                                                Heap::kOld);
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
  Definition* type_args = NULL;
  AbstractType& type = AbstractType::ZoneHandle(Z);
  bool negate = false;
  if (call->ArgumentCount() == 2) {
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
    type_args = call->ArgumentAt(1);
    type = AbstractType::Cast(call->ArgumentAt(2)->AsConstant()->value()).raw();
    negate = Bool::Cast(call->ArgumentAt(3)->OriginalDefinition()
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
            can_deopt ? call->deopt_id() : Thread::kNoDeoptId);
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
  Definition* type_args = call->ArgumentAt(1);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(2)->AsConstant()->value());
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
                                   new(Z) Value(type_args),
                                   type,
                                   dst_name,
                                   call->deopt_id());
  ReplaceCall(call, assert_as);
}


bool FlowGraphOptimizer::IsBlackListedForInlining(intptr_t call_deopt_id) {
  for (intptr_t i = 0; i < inlining_black_list_->length(); ++i) {
    if ((*inlining_black_list_)[i] == call_deopt_id) return true;
  }
  return false;
}

// Special optimizations when running in --noopt mode.
void FlowGraphOptimizer::InstanceCallNoopt(InstanceCallInstr* instr) {
  // TODO(srdjan): Investigate other attempts, as they are not allowed to
  // deoptimize.

  // Type test is special as it always gets converted into inlined code.
  const Token::Kind op_kind = instr->token_kind();
  if (Token::IsTypeTestOperator(op_kind)) {
    ReplaceWithInstanceOf(instr);
    return;
  }
  if (Token::IsTypeCastOperator(op_kind)) {
    ReplaceWithTypeCast(instr);
    return;
  }

  if ((op_kind == Token::kGET) &&
      TryInlineInstanceGetter(instr, false /* no checks allowed */)) {
    return;
  }
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());
  if ((unary_checks.NumberOfChecks() > 0) &&
      (op_kind == Token::kSET) &&
      TryInlineInstanceSetter(instr, unary_checks, false /* no checks */)) {
    return;
  }

  if (use_speculative_inlining_ &&
      !IsBlackListedForInlining(instr->deopt_id()) &&
      (unary_checks.NumberOfChecks() > 0)) {
    if ((op_kind == Token::kINDEX) && TryReplaceWithIndexedOp(instr)) {
      return;
    }
    if ((op_kind == Token::kASSIGN_INDEX) && TryReplaceWithIndexedOp(instr)) {
      return;
    }
    if ((op_kind == Token::kEQ) && TryReplaceWithEqualityOp(instr, op_kind)) {
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
  }

  bool has_one_target =
      (unary_checks.NumberOfChecks() > 0) && unary_checks.HasOneTarget();
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
      PolymorphicInstanceCallInstr* call =
          new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
                                              /* with_checks = */ false);
      instr->ReplaceWith(call, current_iterator());
      return;
    }
  }

  // More than one targets. Generate generic polymorphic call without
  // deoptimization.
  if (instr->ic_data()->NumberOfUsedChecks() > 0) {
    ASSERT(!FLAG_polymorphic_with_deopt);
    // OK to use checks with PolymorphicInstanceCallInstr since no
    // deoptimization is allowed.
    PolymorphicInstanceCallInstr* call =
        new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
                                            /* with_checks = */ true);
    instr->ReplaceWith(call, current_iterator());
    return;
  }

  // No IC data checks. Try resolve target using the propagated type.
  // If the propagated type has a method with the target name and there are
  // no overrides with that name according to CHA, call the method directly.
  const intptr_t receiver_cid =
      instr->PushArgumentAt(0)->value()->Type()->ToCid();
  if (receiver_cid == kDynamicCid) return;
  const Class& receiver_class = Class::Handle(Z,
      isolate()->class_table()->At(receiver_cid));

  const Array& args_desc_array = Array::Handle(Z,
      ArgumentsDescriptor::New(instr->ArgumentCount(),
                               instr->argument_names()));
  ArgumentsDescriptor args_desc(args_desc_array);
  const Function& function = Function::Handle(Z,
      Resolver::ResolveDynamicForReceiverClass(
          receiver_class,
          instr->function_name(),
          args_desc));
  if (function.IsNull()) {
    return;
  }
  if (!thread()->cha()->HasOverride(receiver_class, instr->function_name())) {
    if (FLAG_trace_cha) {
      THR_Print("  **(CHA) Instance call needs no check, "
          "no overrides of '%s' '%s'\n",
          instr->function_name().ToCString(), receiver_class.ToCString());
    }
    thread()->cha()->AddToLeafClasses(receiver_class);

    // Create fake IC data with the resolved target.
    const ICData& ic_data = ICData::Handle(
        ICData::New(flow_graph_->function(),
                    instr->function_name(),
                    args_desc_array,
                    Thread::kNoDeoptId,
                    /* args_tested = */ 1));
    ic_data.AddReceiverCheck(receiver_class.id(), function);
    PolymorphicInstanceCallInstr* call =
        new(Z) PolymorphicInstanceCallInstr(instr, ic_data,
                                            /* with_checks = */ false);
    instr->ReplaceWith(call, current_iterator());
    return;
  }
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void FlowGraphOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  if (FLAG_precompilation) {
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
      PolymorphicInstanceCallInstr* call =
          new(Z) PolymorphicInstanceCallInstr(instr, unary_checks,
                                              /* call_with_checks = */ false);
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
    if (FLAG_precompilation) {
      // TODO(srdjan): Adapt MathUnaryInstr to allow tagged inputs as well.
      return;
    }
    MathUnaryInstr* math_unary =
        new(Z) MathUnaryInstr(unary_kind,
                              new(Z) Value(call->ArgumentAt(0)),
                              call->deopt_id());
    ReplaceCall(call, math_unary);
    return;
  }
  switch (recognized_kind) {
    case MethodRecognizer::kFloat32x4Zero:
    case MethodRecognizer::kFloat32x4Splat:
    case MethodRecognizer::kFloat32x4Constructor:
    case MethodRecognizer::kFloat32x4FromFloat64x2:
      TryInlineFloat32x4Constructor(call, recognized_kind);
      break;
    case MethodRecognizer::kFloat64x2Constructor:
    case MethodRecognizer::kFloat64x2Zero:
    case MethodRecognizer::kFloat64x2Splat:
    case MethodRecognizer::kFloat64x2FromFloat32x4:
      TryInlineFloat64x2Constructor(call, recognized_kind);
      break;
    case MethodRecognizer::kInt32x4BoolConstructor:
    case MethodRecognizer::kInt32x4Constructor:
      TryInlineInt32x4Constructor(call, recognized_kind);
      break;
    case MethodRecognizer::kObjectConstructor: {
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
      current_iterator()->RemoveCurrentFromGraph();
      break;
    }
    case MethodRecognizer::kMathMin:
    case MethodRecognizer::kMathMax: {
      // We can handle only monomorphic min/max call sites with both arguments
      // being either doubles or smis.
      if (call->HasICData() && (call->ic_data()->NumberOfChecks() == 1)) {
        const ICData& ic_data = *call->ic_data();
        intptr_t result_cid = kIllegalCid;
        if (ICDataHasReceiverArgumentClassIds(ic_data,
                                              kDoubleCid, kDoubleCid)) {
          result_cid = kDoubleCid;
        } else if (ICDataHasReceiverArgumentClassIds(ic_data,
                                                     kSmiCid, kSmiCid)) {
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
      break;
    }
    case MethodRecognizer::kMathDoublePow:
    case MethodRecognizer::kMathTan:
    case MethodRecognizer::kMathAsin:
    case MethodRecognizer::kMathAcos:
    case MethodRecognizer::kMathAtan:
    case MethodRecognizer::kMathAtan2: {
      if (FLAG_precompilation) {
        // No UnboxDouble instructons allowed.
        return;
      }
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
      break;
    }
    case MethodRecognizer::kDoubleFromInteger: {
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
      break;
    }
    default: {
      if (call->function().IsFactory()) {
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
                intptr_t length =
                    Smi::Cast(num_elements->BoundConstant()).Value();
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
        THR_Print("Disabling unboxing of %s\n", field.ToCString());
        if (!setter.IsNull()) {
          OS::Print("  setter usage count: %" Pd "\n", setter.usage_counter());
        }
        if (!getter.IsNull()) {
          OS::Print("  getter usage count: %" Pd "\n", getter.usage_counter());
        }
      }
      field.set_is_unboxing_candidate(false);
      if (Compiler::IsBackgroundCompilation()) {
        // Delay deoptimization of dependent code to the code installation time.
        // The invalidation of the background compilation result occurs only
        // when the deoptimization is triggered at code installation.
        flow_graph()->deoptimize_dependent_code().Add(&field);
      } else {
        field.DeoptimizeDependentCode();
      }
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
                                                 const ICData& unary_ic_data,
                                                 bool allow_checks) {
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
    if (!allow_checks) {
      return false;
    }
    AddReceiverCheck(instr);
  }
  if (field.guarded_cid() != kDynamicCid) {
    if (!allow_checks) {
      return false;
    }
    InsertBefore(instr,
                 new(Z) GuardFieldClassInstr(
                     new(Z) Value(instr->ArgumentAt(1)),
                      field,
                      instr->deopt_id()),
                 instr->env(),
                 FlowGraph::kEffect);
  }

  if (field.needs_length_check()) {
    if (!allow_checks) {
      return false;
    }
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
          smi_op->HasSSATemp() &&
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
      THR_Print("analysing candidate: %s\n", op->ToCString());
    }
    worklist.Clear();
    worklist.Add(op);

    // Collect dependency graph. Note: more items are added to worklist
    // inside this loop.
    intptr_t gain = 0;
    for (intptr_t j = 0; j < worklist.definitions().length(); j++) {
      Definition* defn = worklist.definitions()[j];

      if (FLAG_trace_smi_widening) {
        THR_Print("> %s\n", defn->ToCString());
      }

      if (defn->IsBinarySmiOp() &&
          BenefitsFromWidening(defn->AsBinarySmiOp())) {
        gain++;
        if (FLAG_trace_smi_widening) {
          THR_Print("^ [%" Pd "] (o) %s\n", gain, defn->ToCString());
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
            THR_Print("^ [%" Pd "] (i) %s\n", gain, input->ToCString());
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
            THR_Print("v [%" Pd "] (i) %s\n", gain, input->ToCString());
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
              THR_Print("v [%" Pd "] (u) %s\n",
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
            THR_Print("^ [%" Pd "] (u) %s\n",
                      gain,
                      use->instruction()->ToCString());
          }
        } else if (defn_loop == loops[instr->GetBlock()->preorder_number()]) {
          gain--;
          if (FLAG_trace_smi_widening) {
            THR_Print("v [%" Pd "] (u) %s\n",
                      gain,
                      use->instruction()->ToCString());
          }
        }
      }
    }

    processed->AddAll(worklist.contains_vector());

    if (FLAG_trace_smi_widening) {
      THR_Print("~ %s gain %" Pd "\n", op->ToCString(), gain);
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


}  // namespace dart
