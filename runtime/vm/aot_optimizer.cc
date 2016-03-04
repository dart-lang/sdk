// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/aot_optimizer.h"

#include "vm/bit_vector.h"
#include "vm/branch_optimizer.h"
#include "vm/cha.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/flow_graph_builder.h"
#include "vm/flow_graph_compiler.h"
#include "vm/flow_graph_inliner.h"
#include "vm/flow_graph_range_analysis.h"
#include "vm/hash_map.h"
#include "vm/il_printer.h"
#include "vm/intermediate_language.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/precompiler.h"
#include "vm/resolver.h"
#include "vm/scopes.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

// Quick access to the current isolate and zone.
#define I (isolate())
#define Z (zone())

static bool ShouldInlineSimd() {
  return FlowGraphCompiler::SupportsUnboxedSimd128();
}


static bool CanUnboxDouble() {
  return FlowGraphCompiler::SupportsUnboxedDoubles();
}


static bool CanConvertUnboxedMintToDouble() {
  return FlowGraphCompiler::CanConvertUnboxedMintToDouble();
}


// Optimize instance calls using ICData.
void AotOptimizer::ApplyICData() {
  VisitBlocks();
}


void AotOptimizer::PopulateWithICData() {
  ASSERT(current_iterator_ == NULL);
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
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
void AotOptimizer::ApplyClassIds() {
  ASSERT(current_iterator_ == NULL);
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    ForwardInstructionIterator it(block_it.Current());
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
      }
    }
    current_iterator_ = NULL;
  }
}


// TODO(srdjan): Test/support other number types as well.
static bool IsNumberCid(intptr_t cid) {
  return (cid == kSmiCid) || (cid == kDoubleCid);
}


static void GetUniqueDynamicTarget(Isolate* isolate,
                                   const String& fname,
                                   Object* function) {
  UniqueFunctionsSet functions_set(
      isolate->object_store()->unique_dynamic_targets());
  ASSERT(fname.IsSymbol());
  *function = functions_set.GetOrNull(fname);
  ASSERT(functions_set.Release().raw() ==
      isolate->object_store()->unique_dynamic_targets());
}


bool AotOptimizer::TryCreateICData(InstanceCallInstr* call) {
  ASSERT(call->HasICData());
  if (call->ic_data()->NumberOfUsedChecks() > 0) {
    // This occurs when an instance call has too many checks, will be converted
    // to megamorphic call.
    return false;
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

  if (isolate()->object_store()->unique_dynamic_targets() != Array::null()) {
    // Check if the target is unique.
    Function& target_function = Function::Handle(Z);
    GetUniqueDynamicTarget(isolate(), call->function_name(), &target_function);
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


const ICData& AotOptimizer::TrySpecializeICData(const ICData& ic_data,
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


void AotOptimizer::SpecializePolymorphicInstanceCall(
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


void AotOptimizer::OptimizeLeftShiftBitAndSmiOp(
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


void AotOptimizer::AppendExtractNthOutputForMerged(Definition* instr,
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
void AotOptimizer::TryMergeTruncDivMod(
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
void AotOptimizer::TryMergeMathUnary(
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
void AotOptimizer::TryOptimizePatterns() {
  if (!FLAG_truncating_left_shift) return;
  ASSERT(current_iterator_ == NULL);
  GrowableArray<BinarySmiOpInstr*> div_mod_merge;
  GrowableArray<MathUnaryInstr*> sin_cos_merge;
  for (BlockIterator block_it = flow_graph_->reverse_postorder_iterator();
       !block_it.Done();
       block_it.Advance()) {
    // Merging only per basic-block.
    div_mod_merge.Clear();
    sin_cos_merge.Clear();
    ForwardInstructionIterator it(block_it.Current());
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


void AotOptimizer::ReplaceCall(Definition* call,
                               Definition* replacement) {
  // Remove the original push arguments.
  for (intptr_t i = 0; i < call->ArgumentCount(); ++i) {
    PushArgumentInstr* push = call->PushArgumentAt(i);
    push->ReplaceUsesWith(push->value()->definition());
    push->RemoveFromGraph();
  }
  call->ReplaceWith(replacement, current_iterator());
}


void AotOptimizer::AddCheckSmi(Definition* to_check,
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


Instruction* AotOptimizer::GetCheckClass(Definition* to_check,
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


void AotOptimizer::AddCheckClass(Definition* to_check,
                                 const ICData& unary_checks,
                                 intptr_t deopt_id,
                                 Environment* deopt_environment,
                                 Instruction* insert_before) {
  // Type propagation has not run yet, we cannot eliminate the check.
  Instruction* check = GetCheckClass(
      to_check, unary_checks, deopt_id, insert_before->token_pos());
  InsertBefore(insert_before, check, deopt_environment, FlowGraph::kEffect);
}


void AotOptimizer::AddReceiverCheck(InstanceCallInstr* call) {
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


bool AotOptimizer::TryReplaceWithIndexedOp(InstanceCallInstr* call) {
  // Check for monomorphic IC data.
  if (!call->HasICData()) return false;
  const ICData& ic_data =
      ICData::Handle(Z, call->ic_data()->AsUnaryClassChecks());
  if (ic_data.NumberOfChecks() != 1) {
    return false;
  }
  return TryReplaceInstanceCallWithInline(call);
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
bool AotOptimizer::TryStringLengthOneEquality(InstanceCallInstr* call,
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

bool AotOptimizer::TryReplaceWithEqualityOp(InstanceCallInstr* call,
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


bool AotOptimizer::TryReplaceWithRelationalOp(InstanceCallInstr* call,
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


bool AotOptimizer::TryReplaceWithBinaryOp(InstanceCallInstr* call,
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


bool AotOptimizer::TryReplaceWithUnaryOp(InstanceCallInstr* call,
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
RawField* AotOptimizer::GetField(intptr_t class_id,
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
bool AotOptimizer::InstanceCallNeedsClassCheck(
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


bool AotOptimizer::InlineImplicitInstanceGetter(InstanceCallInstr* call) {
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
    return false;
  }
  LoadFieldInstr* load = new(Z) LoadFieldInstr(
      new(Z) Value(call->ArgumentAt(0)),
      &field,
      AbstractType::ZoneHandle(Z, field.type()),
      call->token_pos());
  load->set_is_immutable(field.is_final());

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


bool AotOptimizer::InlineFloat32x4Getter(InstanceCallInstr* call,
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


bool AotOptimizer::InlineFloat64x2Getter(InstanceCallInstr* call,
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


bool AotOptimizer::InlineInt32x4Getter(InstanceCallInstr* call,
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


bool AotOptimizer::InlineFloat32x4BinaryOp(InstanceCallInstr* call,
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


bool AotOptimizer::InlineInt32x4BinaryOp(InstanceCallInstr* call,
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


bool AotOptimizer::InlineFloat64x2BinaryOp(InstanceCallInstr* call,
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
bool AotOptimizer::TryInlineInstanceGetter(InstanceCallInstr* call) {
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
  return InlineImplicitInstanceGetter(call);
}


bool AotOptimizer::TryReplaceInstanceCallWithInline(
    InstanceCallInstr* call) {
  Function& target = Function::Handle(Z);
  GrowableArray<intptr_t> class_ids;
  call->ic_data()->GetCheckAt(0, &class_ids, &target);
  const intptr_t receiver_cid = class_ids[0];

  TargetEntryInstr* entry;
  Definition* last;
  if (!FlowGraphInliner::TryInlineRecognizedMethod(flow_graph_,
                                                   receiver_cid,
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


void AotOptimizer::ReplaceWithMathCFunction(
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
bool AotOptimizer::TryInlineInstanceMethod(InstanceCallInstr* call) {
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


bool AotOptimizer::TryInlineFloat32x4Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  ASSERT(FLAG_precompiled_mode);
  return false;
}


bool AotOptimizer::TryInlineFloat64x2Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  ASSERT(FLAG_precompiled_mode);
  return false;
}


bool AotOptimizer::TryInlineInt32x4Constructor(
    StaticCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  ASSERT(FLAG_precompiled_mode);
  return false;
}


bool AotOptimizer::TryInlineFloat32x4Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  return false;
}


bool AotOptimizer::TryInlineFloat64x2Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  return false;
}


bool AotOptimizer::TryInlineInt32x4Method(
    InstanceCallInstr* call,
    MethodRecognizer::Kind recognized_kind) {
  // Cannot handle unboxed instructions.
  return false;
}


// If type tests specified by 'ic_data' do not depend on type arguments,
// return mapping cid->result in 'results' (i : cid; i + 1: result).
// If all tests yield the same result, return it otherwise return Bool::null.
// If no mapping is possible, 'results' is empty.
// An instance-of test returning all same results can be converted to a class
// check.
RawBool* AotOptimizer::InstanceOfAsBool(
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
bool AotOptimizer::TypeCheckAsClassEquality(const AbstractType& type) {
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
void AotOptimizer::ReplaceWithInstanceOf(InstanceCallInstr* call) {
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
void AotOptimizer::ReplaceWithTypeCast(InstanceCallInstr* call) {
  ASSERT(Token::IsTypeCastOperator(call->token_kind()));
  Definition* left = call->ArgumentAt(0);
  Definition* type_args = call->ArgumentAt(1);
  const AbstractType& type =
      AbstractType::Cast(call->ArgumentAt(2)->AsConstant()->value());
  ASSERT(!type.IsMalformedOrMalbounded());
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, call->ic_data()->AsUnaryClassChecks());
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


bool AotOptimizer::IsBlackListedForInlining(intptr_t call_deopt_id) {
  for (intptr_t i = 0; i < inlining_black_list_->length(); ++i) {
    if ((*inlining_black_list_)[i] == call_deopt_id) return true;
  }
  return false;
}


// Tries to optimize instance call by replacing it with a faster instruction
// (e.g, binary op, field load, ..).
void AotOptimizer::VisitInstanceCall(InstanceCallInstr* instr) {
  ASSERT(FLAG_precompiled_mode);
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
      TryInlineInstanceGetter(instr)) {
    return;
  }
  const ICData& unary_checks =
      ICData::ZoneHandle(Z, instr->ic_data()->AsUnaryClassChecks());
  if ((unary_checks.NumberOfChecks() > 0) &&
      (op_kind == Token::kSET) &&
      TryInlineInstanceSetter(instr, unary_checks)) {
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
  switch (instr->token_kind()) {
    case Token::kBIT_OR:
    case Token::kBIT_XOR:
    case Token::kBIT_AND:
    case Token::kADD:
    case Token::kSUB: {
      if (HasOnlyTwoOf(*instr->ic_data(), kSmiCid)) {
        Definition* left = instr->ArgumentAt(0);
        Definition* right = instr->ArgumentAt(1);
        CheckedSmiOpInstr* smi_op =
            new(Z) CheckedSmiOpInstr(instr->token_kind(),
                                     new(Z) Value(left),
                                     new(Z) Value(right),
                                     instr);

        ReplaceCall(instr, smi_op);
        return;
      }
    }
    default:
      break;
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
  }
}


void AotOptimizer::VisitStaticCall(StaticCallInstr* call) {
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
    ASSERT(FLAG_precompiled_mode);
    // TODO(srdjan): Adapt MathUnaryInstr to allow tagged inputs as well.
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
      ASSERT(FLAG_precompiled_mode);
      // No UnboxDouble instructions allowed.
      return;
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


void AotOptimizer::VisitLoadCodeUnits(LoadCodeUnitsInstr* instr) {
  // TODO(zerny): Use kUnboxedUint32 once it is fully supported/optimized.
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_ARM)
  if (!instr->can_pack_into_smi())
    instr->set_representation(kUnboxedMint);
#endif
}


bool AotOptimizer::TryInlineInstanceSetter(InstanceCallInstr* instr,
                                           const ICData& unary_ic_data) {
  ASSERT((unary_ic_data.NumberOfChecks() > 0) &&
      (unary_ic_data.NumArgsTested() == 1));
  if (I->type_checks()) {
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
    return false;
  }

  // Field guard was detached.
  StoreInstanceFieldInstr* store = new(Z) StoreInstanceFieldInstr(
      field,
      new(Z) Value(instr->ArgumentAt(0)),
      new(Z) Value(instr->ArgumentAt(1)),
      kEmitStoreBarrier,
      instr->token_pos());

  // No unboxed stores in precompiled code.
  ASSERT(!store->IsUnboxedStore());

  // Discard the environment from the original instruction because the store
  // can't deoptimize.
  instr->RemoveEnvironment();
  ReplaceCall(instr, store);
  return true;
}


}  // namespace dart
