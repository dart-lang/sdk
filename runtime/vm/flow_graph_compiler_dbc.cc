// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/flow_graph_compiler.h"

#include "vm/ast_printer.h"
#include "vm/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/deopt_instructions.h"
#include "vm/il_printer.h"
#include "vm/instructions.h"
#include "vm/locations.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/verified_memory.h"

namespace dart {

DEFINE_FLAG(bool, trap_on_deoptimization, false, "Trap on deoptimization.");
DEFINE_FLAG(bool, unbox_mints, true, "Optimize 64-bit integer arithmetic.");
DEFINE_FLAG(bool, unbox_doubles, true, "Optimize double arithmetic.");
DECLARE_FLAG(bool, enable_simd_inline);
DECLARE_FLAG(bool, use_megamorphic_stub);
DECLARE_FLAG(charp, optimization_filter);

void MegamorphicSlowPath::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->jump_label()->IsLinked());
  }
}


bool FlowGraphCompiler::SupportsUnboxedDoubles() {
  return false;
}


bool FlowGraphCompiler::SupportsUnboxedMints() {
  return false;
}


bool FlowGraphCompiler::SupportsUnboxedSimd128() {
  return false;
}


bool FlowGraphCompiler::SupportsSinCos() {
  return false;
}


bool FlowGraphCompiler::SupportsHardwareDivision() {
  return true;
}


bool FlowGraphCompiler::CanConvertUnboxedMintToDouble() {
  return false;
}


void FlowGraphCompiler::EnterIntrinsicMode() {
  ASSERT(!intrinsic_mode());
  intrinsic_mode_ = true;
}


void FlowGraphCompiler::ExitIntrinsicMode() {
  ASSERT(intrinsic_mode());
  intrinsic_mode_ = false;
}


RawTypedData* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                 DeoptInfoBuilder* builder,
                                                 const Array& deopt_table) {
  UNIMPLEMENTED();
  return TypedData::null();
}


void CompilerDeoptInfoWithStub::GenerateCode(FlowGraphCompiler* compiler,
                                             intptr_t stub_ix) {
  UNIMPLEMENTED();
}


#define __ assembler()->


void FlowGraphCompiler::GenerateAssertAssignable(TokenPosition token_pos,
                                                 intptr_t deopt_id,
                                                 const AbstractType& dst_type,
                                                 const String& dst_name,
                                                 LocationSummary* locs) {
  ASSERT(!is_optimizing());
  SubtypeTestCache& test_cache = SubtypeTestCache::Handle();
  if (!dst_type.IsVoidType() && dst_type.IsInstantiated()) {
    test_cache = SubtypeTestCache::New();
  }

  __ PushConstant(dst_type);
  __ PushConstant(dst_name);
  __ AssertAssignable(__ AddConstant(test_cache));
  AddCurrentDescriptor(RawPcDescriptors::kOther, deopt_id, token_pos);
}


void FlowGraphCompiler::EmitInstructionEpilogue(Instruction* instr) {
  if (!is_optimizing()) {
    Definition* defn = instr->AsDefinition();
    if ((defn != NULL) &&
        (defn->tag() != Instruction::kPushArgument) &&
        (defn->tag() != Instruction::kStoreIndexed) &&
        (defn->tag() != Instruction::kStoreStaticField) &&
        (defn->tag() != Instruction::kStoreLocal) &&
        (defn->tag() != Instruction::kStoreInstanceField) &&
        (defn->tag() != Instruction::kDropTemps) &&
        (defn->tag() != Instruction::kPushTemp) &&
        !defn->HasTemp()) {
      __ Drop1();
    }
  }
}


void FlowGraphCompiler::GenerateInlinedGetter(intptr_t offset) {
  __ Move(0, -(1 + kParamEndSlotFromFp));
  __ LoadField(0, 0, offset / kWordSize);
  __ Return(0);
}


void FlowGraphCompiler::GenerateInlinedSetter(intptr_t offset) {
  __ Move(0, -(2 + kParamEndSlotFromFp));
  __ Move(1, -(1 + kParamEndSlotFromFp));
  __ StoreField(0, offset / kWordSize, 1);
  __ LoadConstant(0, Object::Handle());
  __ Return(0);
}


void FlowGraphCompiler::EmitFrameEntry() {
  const Function& function = parsed_function().function();
  const intptr_t num_fixed_params = function.num_fixed_parameters();
  const int num_opt_pos_params = function.NumOptionalPositionalParameters();
  const int num_opt_named_params = function.NumOptionalNamedParameters();
  const int num_params =
      num_fixed_params + num_opt_pos_params + num_opt_named_params;
  const bool has_optional_params = (num_opt_pos_params != 0) ||
      (num_opt_named_params != 0);
  const int num_locals = parsed_function().num_stack_locals();
  const intptr_t context_index =
      -parsed_function().current_context_var()->index() - 1;

  if (has_optional_params) {
    __ EntryOpt(num_fixed_params, num_opt_pos_params, num_opt_named_params);
  } else {
    __ Entry(num_fixed_params, num_locals, context_index);
  }

  if (num_opt_named_params != 0) {
    LocalScope* scope = parsed_function().node_sequence()->scope();

    // Start by alphabetically sorting the names of the optional parameters.
    LocalVariable** opt_param =
        zone()->Alloc<LocalVariable*>(num_opt_named_params);
    int* opt_param_position = zone()->Alloc<int>(num_opt_named_params);
    for (int pos = num_fixed_params; pos < num_params; pos++) {
      LocalVariable* parameter = scope->VariableAt(pos);
      const String& opt_param_name = parameter->name();
      int i = pos - num_fixed_params;
      while (--i >= 0) {
        LocalVariable* param_i = opt_param[i];
        const intptr_t result = opt_param_name.CompareTo(param_i->name());
        ASSERT(result != 0);
        if (result > 0) break;
        opt_param[i + 1] = opt_param[i];
        opt_param_position[i + 1] = opt_param_position[i];
      }
      opt_param[i + 1] = parameter;
      opt_param_position[i + 1] = pos;
    }

    for (intptr_t i = 0; i < num_opt_named_params; i++) {
      const int param_pos = opt_param_position[i];
      const Instance& value = parsed_function().DefaultParameterValueAt(
          param_pos - num_fixed_params);
      __ LoadConstant(param_pos, opt_param[i]->name());
      __ LoadConstant(param_pos, value);
    }
  } else if (num_opt_pos_params != 0) {
    for (intptr_t i = 0; i < num_opt_pos_params; i++) {
      const Object& value = parsed_function().DefaultParameterValueAt(i);
      __ LoadConstant(num_fixed_params + i, value);
    }
  }


  ASSERT(num_locals > 0);  // There is always at least context_var.
  if (has_optional_params) {
    ASSERT(!is_optimizing());
    __ Frame(num_locals);  // Reserve space for locals.
  }

  if (function.IsClosureFunction()) {
    Register reg = context_index;
    Register closure_reg = reg;
    LocalScope* scope = parsed_function().node_sequence()->scope();
    LocalVariable* local = scope->VariableAt(0);
    if (local->index() > 0) {
      __ Move(reg, -local->index());
    } else {
      closure_reg = -local->index() - 1;
    }
    __ LoadField(reg, closure_reg, Closure::context_offset() / kWordSize);
  } else if (has_optional_params) {
    __ LoadConstant(context_index,
        Object::Handle(isolate()->object_store()->empty_context()));
  }
}


void FlowGraphCompiler::CompileGraph() {
  InitCompiler();

  if (TryIntrinsify()) {
    // Skip regular code generation.
    return;
  }

  EmitFrameEntry();
  VisitBlocks();
}


#undef __
#define __ compiler_->assembler()->


void ParallelMoveResolver::EmitMove(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::EmitSwap(int index) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::MoveMemoryToMemory(const Address& dst,
                                              const Address& src) {
  UNREACHABLE();
}


void ParallelMoveResolver::StoreObject(const Address& dst, const Object& obj) {
  UNREACHABLE();
}


// Do not call or implement this function. Instead, use the form below that
// uses an offset from the frame pointer instead of an Address.
void ParallelMoveResolver::Exchange(Register reg, const Address& mem) {
  UNREACHABLE();
}


// Do not call or implement this function. Instead, use the form below that
// uses offsets from the frame pointer instead of Addresses.
void ParallelMoveResolver::Exchange(const Address& mem1, const Address& mem2) {
  UNREACHABLE();
}


void ParallelMoveResolver::Exchange(Register reg,
                                    Register base_reg,
                                    intptr_t stack_offset) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::Exchange(Register base_reg1,
                                    intptr_t stack_offset1,
                                    Register base_reg2,
                                    intptr_t stack_offset2) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreScratch(Register reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::SpillFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


void ParallelMoveResolver::RestoreFpuScratch(FpuRegister reg) {
  UNIMPLEMENTED();
}


#undef __

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
