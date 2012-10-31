// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_XXX.

#include "vm/flow_graph_compiler.h"

#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
#include "vm/flow_graph_allocator.h"
#include "vm/il_printer.h"
#include "vm/intrinsifier.h"
#include "vm/locations.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, print_scopes, false, "Print scopes of local variables.");
DEFINE_FLAG(bool, trace_functions, false, "Trace entry of each function.");
DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, propagate_ic_data);
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(bool, trace_functions);
DECLARE_FLAG(int, optimization_counter_threshold);

void CompilerDeoptInfo::BuildReturnAddress(DeoptInfoBuilder* builder,
                                           const Function& function,
                                           intptr_t slot_ix) {
  builder->AddReturnAddressAfter(function, deopt_id(), slot_ix);
}


void CompilerDeoptInfoWithStub::BuildReturnAddress(DeoptInfoBuilder* builder,
                                                   const Function& function,
                                                   intptr_t slot_ix) {
  builder->AddReturnAddressBefore(function, deopt_id(), slot_ix);
}


// Assign locations to incoming arguments, i.e., values pushed above spill slots
// with PushArgument.  Recursively allocates from outermost to innermost
// environment.
void CompilerDeoptInfo::AllocateIncomingParametersRecursive(
    Environment* env,
    intptr_t* stack_height) {
  if (env == NULL) return;
  AllocateIncomingParametersRecursive(env->outer(), stack_height);
  for (Environment::ShallowIterator it(env); !it.Done(); it.Advance()) {
    if (it.CurrentLocation().IsInvalid()) {
      ASSERT(it.CurrentValue()->definition()->IsPushArgument());
      it.SetCurrentLocation(Location::StackSlot((*stack_height)++));
    }
  }
}


RawDeoptInfo* CompilerDeoptInfo::CreateDeoptInfo(FlowGraphCompiler* compiler,
                                                 DeoptInfoBuilder* builder) {
  if (deoptimization_env_ == NULL) return DeoptInfo::null();

  intptr_t stack_height = compiler->StackSize();
  AllocateIncomingParametersRecursive(deoptimization_env_, &stack_height);

  intptr_t slot_ix = 0;
  Environment* current = deoptimization_env_;

  // For the innermost environment, call the virtual return builder.
  BuildReturnAddress(builder, current->function(), slot_ix++);

  // For the innermost environment, set outgoing arguments and the locals.
  for (intptr_t i = current->Length() - 1;
       i >= current->fixed_parameter_count();
       i--) {
    builder->AddCopy(current->LocationAt(i), *current->ValueAt(i), slot_ix++);
  }

  // PC marker and caller FP.
  builder->AddPcMarker(current->function(), slot_ix++);
  builder->AddCallerFp(slot_ix++);

  Environment* previous = current;
  current = current->outer();
  while (current != NULL) {
    // For any outer environment the deopt id is that of the call instruction
    // which is recorded in the outer environment.
    builder->AddReturnAddressAfter(current->function(),
                                   current->deopt_id(),
                                   slot_ix++);

    // The values of outgoing arguments can be changed from the inlined call so
    // we must read them from the previous environment.
    for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
      builder->AddCopy(previous->LocationAt(i), *previous->ValueAt(i),
                       slot_ix++);
    }

    // Set the locals, note that outgoing arguments are not in the environment.
    for (intptr_t i = current->Length() - 1;
         i >= current->fixed_parameter_count();
         i--) {
      builder->AddCopy(current->LocationAt(i), *current->ValueAt(i), slot_ix++);
    }

    // PC marker and caller FP.
    builder->AddPcMarker(current->function(), slot_ix++);
    builder->AddCallerFp(slot_ix++);

    // Iterate on the outer environment.
    previous = current;
    current = current->outer();
  }
  // The previous pointer is now the outermost environment.
  ASSERT(previous != NULL);

  // For the outermost environment, set caller PC.
  builder->AddCallerPc(slot_ix++);

  // For the outermost environment, set the incoming arguments.
  for (intptr_t i = previous->fixed_parameter_count() - 1; i >= 0; i--) {
    builder->AddCopy(previous->LocationAt(i), *previous->ValueAt(i), slot_ix++);
  }

  const DeoptInfo& deopt_info = DeoptInfo::Handle(builder->CreateDeoptInfo());
  return deopt_info.raw();
}


FlowGraphCompiler::FlowGraphCompiler(Assembler* assembler,
                                     const FlowGraph& flow_graph,
                                     bool is_optimizing)
    : assembler_(assembler),
      parsed_function_(flow_graph.parsed_function()),
      block_order_(flow_graph.reverse_postorder()),
      current_block_(NULL),
      exception_handlers_list_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_table_builder_(
          is_optimizing ? new StackmapTableBuilder() : NULL),
      block_info_(block_order_.length()),
      deopt_infos_(),
      is_optimizing_(is_optimizing),
      bool_true_(Bool::ZoneHandle(Bool::True())),
      bool_false_(Bool::ZoneHandle(Bool::False())),
      double_class_(Class::ZoneHandle(
          Isolate::Current()->object_store()->double_class())),
      parallel_move_resolver_(this) {
  ASSERT(assembler != NULL);
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}


bool FlowGraphCompiler::HasFinally() const {
  return parsed_function().function().has_finally();
}


void FlowGraphCompiler::InitCompiler() {
  pc_descriptors_list_ = new DescriptorList(64);
  exception_handlers_list_ = new ExceptionHandlerList();
  block_info_.Clear();
  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


bool FlowGraphCompiler::CanOptimize() {
  return !FLAG_report_usage_count &&
         (FLAG_optimization_counter_threshold >= 0) &&
         !Isolate::Current()->debugger()->IsActive();
}


void FlowGraphCompiler::VisitBlocks() {
  for (intptr_t i = 0; i < block_order().length(); ++i) {
    // Compile the block entry.
    BlockEntryInstr* entry = block_order()[i];
    assembler()->Comment("B%"Pd"", entry->block_id());
    set_current_block(entry);
    entry->PrepareEntry(this);
    // Compile all successors until an exit, branch, or a block entry.
    for (ForwardInstructionIterator it(entry); !it.Done(); it.Advance()) {
      Instruction* instr = it.Current();
      if (FLAG_code_comments) EmitComment(instr);
      if (instr->IsParallelMove()) {
        parallel_move_resolver_.EmitNativeCode(instr->AsParallelMove());
      } else {
        ASSERT(instr->locs() != NULL);
        EmitInstructionPrologue(instr);
        pending_deoptimization_env_ = instr->env();
        instr->EmitNativeCode(this);
        EmitInstructionEpilogue(instr);
      }
    }
  }
  set_current_block(NULL);
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function().function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


intptr_t FlowGraphCompiler::StackSize() const {
  if (is_optimizing_) {
    return block_order_[0]->AsGraphEntry()->spill_slot_count();
  } else {
    return parsed_function_.num_stack_locals() +
        parsed_function_.num_copied_params();
  }
}


Label* FlowGraphCompiler::GetBlockLabel(
    BlockEntryInstr* block_entry) const {
  intptr_t block_index = block_entry->postorder_number();
  return &block_info_[block_index]->label;
}


bool FlowGraphCompiler::IsNextBlock(BlockEntryInstr* block_entry) const {
  intptr_t current_index = reverse_index(current_block()->postorder_number());
  return (current_index < (block_order().length() - 1)) &&
      (block_order()[current_index + 1] == block_entry);
}


void FlowGraphCompiler::AddSlowPathCode(SlowPathCode* code) {
  slow_path_code_.Add(code);
}


void FlowGraphCompiler::GenerateDeferredCode() {
  for (intptr_t i = 0; i < slow_path_code_.length(); i++) {
    slow_path_code_[i]->EmitNativeCode(this);
  }
  for (intptr_t i = 0; i < deopt_infos_.length(); i++) {
    deopt_infos_[i]->GenerateCode(this, i);
  }
}


void FlowGraphCompiler::AddExceptionHandler(intptr_t try_index,
                                            intptr_t pc_offset) {
  exception_handlers_list_->AddHandler(try_index, pc_offset);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t deopt_id,
                                             intptr_t token_pos) {
  pc_descriptors_list()->AddDescriptor(kind,
                                       assembler()->CodeSize(),
                                       deopt_id,
                                       token_pos,
                                       CurrentTryIndex());
}


void FlowGraphCompiler::AddDeoptIndexAtCall(intptr_t deopt_id,
                                            intptr_t token_pos) {
  ASSERT(is_optimizing());
  CompilerDeoptInfo* info = new CompilerDeoptInfo(deopt_id, kDeoptAtCall);
  ASSERT(pending_deoptimization_env_ != NULL);
  info->set_deoptimization_env(pending_deoptimization_env_);
  info->set_pc_offset(assembler()->CodeSize());
  deopt_infos_.Add(info);
}


void FlowGraphCompiler::RecordSafepoint(LocationSummary* locs) {
  if (is_optimizing()) {
    BitmapBuilder* bitmap = locs->stack_bitmap();
    ASSERT(bitmap != NULL);
    ASSERT(bitmap->Length() <= StackSize());
    // Pad the bitmap out to describe all the spill slots.
    bitmap->SetLength(StackSize());

    // Mark the bits in the stack map in the same order we push registers in
    // slow path code (see FlowGraphCompiler::SaveLiveRegisters).
    //
    // Slow path code can have registers at the safepoint.
    if (!locs->always_calls()) {
      RegisterSet* regs = locs->live_registers();
      if (regs->xmm_regs_count() > 0) {
        // Denote XMM registers with 0 bits in the stackmap.  Based on the
        // assumption that there are normally few live XMM registers, this
        // encoding is simpler and roughly as compact as storing a separate
        // count of XMM registers.
        //
        // XMM registers have the highest register number at the highest
        // address (i.e., first in the stackmap).
        for (intptr_t i = kNumberOfXmmRegisters - 1; i >= 0; --i) {
          XmmRegister reg = static_cast<XmmRegister>(i);
          if (regs->ContainsXmmRegister(reg)) {
            for (intptr_t j = 0;
                 j < FlowGraphAllocator::kDoubleSpillSlotFactor;
                 ++j) {
              bitmap->Set(bitmap->Length(), false);
            }
          }
        }
      }
      // General purpose registers have the lowest register number at the
      // highest address (i.e., first in the stackmap).
      for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
        Register reg = static_cast<Register>(i);
        if (locs->live_registers()->ContainsRegister(reg)) {
          bitmap->Set(bitmap->Length(), true);
        }
      }
    }

    intptr_t register_bit_count = bitmap->Length() - StackSize();
    stackmap_table_builder_->AddEntry(assembler()->CodeSize(),
                                      bitmap,
                                      register_bit_count);
  }
}


Label* FlowGraphCompiler::AddDeoptStub(intptr_t deopt_id,
                                       DeoptReasonId reason) {
  CompilerDeoptInfoWithStub* stub =
      new CompilerDeoptInfoWithStub(deopt_id, reason);
  ASSERT(is_optimizing_);
  ASSERT(pending_deoptimization_env_ != NULL);
  stub->set_deoptimization_env(pending_deoptimization_env_);
  deopt_infos_.Add(stub);
  return stub->entry_label();
}


void FlowGraphCompiler::FinalizeExceptionHandlers(const Code& code) {
  ASSERT(exception_handlers_list_ != NULL);
  const ExceptionHandlers& handlers = ExceptionHandlers::Handle(
      exception_handlers_list_->FinalizeExceptionHandlers(code.EntryPoint()));
  code.set_exception_handlers(handlers);
}


void FlowGraphCompiler::FinalizePcDescriptors(const Code& code) {
  ASSERT(pc_descriptors_list_ != NULL);
  const PcDescriptors& descriptors = PcDescriptors::Handle(
      pc_descriptors_list_->FinalizePcDescriptors(code.EntryPoint()));
  if (!is_optimizing_) descriptors.Verify(parsed_function_.function());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeDeoptInfo(const Code& code) {
  // For functions with optional arguments, all incoming arguments are copied
  // to spill slots. The deoptimization environment does not track them.
  const Function& function = parsed_function().function();
  const intptr_t incoming_arg_count =
      function.HasOptionalParameters() ? 0 : function.num_fixed_parameters();
  DeoptInfoBuilder builder(incoming_arg_count);

  const Array& array =
      Array::Handle(Array::New(DeoptTable::SizeFor(deopt_infos_.length()),
                               Heap::kOld));
  Smi& offset = Smi::Handle();
  DeoptInfo& info = DeoptInfo::Handle();
  Smi& reason = Smi::Handle();
  for (intptr_t i = 0; i < deopt_infos_.length(); i++) {
    offset = Smi::New(deopt_infos_[i]->pc_offset());
    info = deopt_infos_[i]->CreateDeoptInfo(this, &builder);
    reason = Smi::New(deopt_infos_[i]->reason());
    DeoptTable::SetEntry(array, i, offset, info, reason);
  }
  code.set_deopt_info_array(array);
  const Array& object_array =
      Array::Handle(Array::MakeArray(builder.object_table()));
  code.set_object_table(object_array);
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  if (stackmap_table_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    ASSERT(is_optimizing());
    code.set_stackmaps(
        Array::Handle(stackmap_table_builder_->FinalizeStackmaps(code)));
  }
}


void FlowGraphCompiler::FinalizeVarDescriptors(const Code& code) {
  const LocalVarDescriptors& var_descs = LocalVarDescriptors::Handle(
          parsed_function_.node_sequence()->scope()->GetVarDescriptors(
              parsed_function_.function()));
  code.set_var_descriptors(var_descs);
}


void FlowGraphCompiler::FinalizeComments(const Code& code) {
  code.set_comments(assembler()->GetCodeComments());
}


// Returns 'true' if code generation for this function is complete, i.e.,
// no fall-through to regular code is needed.
bool FlowGraphCompiler::TryIntrinsify() {
  if (!CanOptimize()) return false;
  // Intrinsification skips arguments checks, therefore disable if in checked
  // mode.
  if (FLAG_intrinsify && !FLAG_trace_functions && !FLAG_enable_type_checks) {
    if ((parsed_function().function().kind() == RawFunction::kImplicitGetter)) {
      // An implicit getter must have a specific AST structure.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 1);
      ASSERT(sequence_node.NodeAt(0)->IsReturnNode());
      const ReturnNode& return_node = *sequence_node.NodeAt(0)->AsReturnNode();
      ASSERT(return_node.value()->IsLoadInstanceFieldNode());
      const LoadInstanceFieldNode& load_node =
          *return_node.value()->AsLoadInstanceFieldNode();
      GenerateInlinedGetter(load_node.field().Offset());
      return true;
    }
    if ((parsed_function().function().kind() == RawFunction::kImplicitSetter)) {
      // An implicit setter must have a specific AST structure.
      // Sequence node has one store node and one return NULL node.
      const SequenceNode& sequence_node = *parsed_function().node_sequence();
      ASSERT(sequence_node.length() == 2);
      ASSERT(sequence_node.NodeAt(0)->IsStoreInstanceFieldNode());
      ASSERT(sequence_node.NodeAt(1)->IsReturnNode());
      const StoreInstanceFieldNode& store_node =
          *sequence_node.NodeAt(0)->AsStoreInstanceFieldNode();
      GenerateInlinedSetter(store_node.field().Offset());
      return true;
    }
  }
  // Even if an intrinsified version of the function was successfully
  // generated, it may fall through to the non-intrinsified method body.
  if (!FLAG_trace_functions) {
    return Intrinsifier::Intrinsify(parsed_function().function(), assembler());
  }
  return false;
}


void FlowGraphCompiler::GenerateInstanceCall(
    intptr_t deopt_id,
    intptr_t token_pos,
    intptr_t argument_count,
    const Array& argument_names,
    LocationSummary* locs,
    const ICData& ic_data) {
  ASSERT(!ic_data.IsNull());
  ASSERT(FLAG_propagate_ic_data || (ic_data.NumberOfChecks() == 0));
  // Because optimized code should not waste time.
  ASSERT(!is_optimizing() || ic_data.num_args_tested() == 1);
  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count, argument_names);
  uword label_address = 0;
  switch (ic_data.num_args_tested()) {
    case 1:
      label_address = StubCode::OneArgCheckInlineCacheEntryPoint();
      break;
    case 2:
      label_address = StubCode::TwoArgsCheckInlineCacheEntryPoint();
      break;
    case 3:
      label_address = StubCode::ThreeArgsCheckInlineCacheEntryPoint();
      break;
    default:
      UNIMPLEMENTED();
  }
  ExternalLabel target_label("InlineCache", label_address);

  EmitInstanceCall(&target_label, ic_data, arguments_descriptor, argument_count,
                   deopt_id, token_pos, locs);
}


void FlowGraphCompiler::GenerateStaticCall(intptr_t deopt_id,
                                           intptr_t token_pos,
                                           const Function& function,
                                           intptr_t argument_count,
                                           const Array& argument_names,
                                           LocationSummary* locs) {
  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count, argument_names);
  EmitStaticCall(function, arguments_descriptor, argument_count,
                 deopt_id, token_pos, locs);
}


void FlowGraphCompiler::GenerateNumberTypeCheck(Register kClassIdReg,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  GrowableArray<intptr_t> args;
  if (type.IsNumberType()) {
    args.Add(kDoubleCid);
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsIntType()) {
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsDoubleType()) {
    args.Add(kDoubleCid);
  }
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateStringTypeCheck(Register kClassIdReg,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  GrowableArray<intptr_t> args;
  args.Add(kOneByteStringCid);
  args.Add(kTwoByteStringCid);
  args.Add(kExternalOneByteStringCid);
  args.Add(kExternalTwoByteStringCid);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateListTypeCheck(Register kClassIdReg,
                                              Label* is_instance_lbl) {
  Label unknown;
  GrowableArray<intptr_t> args;
  args.Add(kArrayCid);
  args.Add(kGrowableObjectArrayCid);
  args.Add(kImmutableArrayCid);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, &unknown);
  assembler()->Bind(&unknown);
}


void FlowGraphCompiler::EmitComment(Instruction* instr) {
  char buffer[256];
  BufferFormatter f(buffer, sizeof(buffer));
  instr->PrintTo(&f);
  assembler()->Comment("%s", buffer);
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t arg_count,
                                        const Array& arg_names,
                                        Label* deopt,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        LocationSummary* locs) {
  ASSERT(!ic_data.IsNull() && (ic_data.NumberOfChecks() > 0));
  Label match_found;
  for (intptr_t i = 0; i < ic_data.NumberOfChecks(); i++) {
    const bool is_last_check = (i == (ic_data.NumberOfChecks() - 1));
    Label next_test;
    assembler()->cmpl(class_id_reg, Immediate(ic_data.GetReceiverClassIdAt(i)));
    if (is_last_check) {
      assembler()->j(NOT_EQUAL, deopt);
    } else {
      assembler()->j(NOT_EQUAL, &next_test);
    }
    const Function& target = Function::ZoneHandle(ic_data.GetTargetAt(i));
    GenerateStaticCall(deopt_id,
                       token_index,
                       target,
                       arg_count,
                       arg_names,
                       locs);
    if (!is_last_check) {
      assembler()->jmp(&match_found);
    }
    assembler()->Bind(&next_test);
  }
  assembler()->Bind(&match_found);
}


void FlowGraphCompiler::EmitDoubleCompareBranch(Condition true_condition,
                                                XmmRegister left,
                                                XmmRegister right,
                                                BranchInstr* branch) {
  ASSERT(branch != NULL);
  assembler()->comisd(left, right);
  BlockEntryInstr* nan_result = (true_condition == NOT_EQUAL) ?
      branch->true_successor() : branch->false_successor();
  assembler()->j(PARITY_EVEN, GetBlockLabel(nan_result));
  branch->EmitBranchOnCondition(this, true_condition);
}



void FlowGraphCompiler::EmitDoubleCompareBool(Condition true_condition,
                                              XmmRegister left,
                                              XmmRegister right,
                                              Register result) {
  assembler()->comisd(left, right);
  Label is_false, is_true, done;
  assembler()->j(PARITY_EVEN, &is_false, Assembler::kNearJump);  // NaN false;
  assembler()->j(true_condition, &is_true, Assembler::kNearJump);
  assembler()->Bind(&is_false);
  assembler()->LoadObject(result, bool_false());
  assembler()->jmp(&done);
  assembler()->Bind(&is_true);
  assembler()->LoadObject(result, bool_true());
  assembler()->Bind(&done);
}


// Allocate a register that is not explicitly blocked.
static Register AllocateFreeRegister(bool* blocked_registers) {
  for (intptr_t regno = 0; regno < kNumberOfCpuRegisters; regno++) {
    if (!blocked_registers[regno]) {
      blocked_registers[regno] = true;
      return static_cast<Register>(regno);
    }
  }
  UNREACHABLE();
  return kNoRegister;
}


void FlowGraphCompiler::AllocateRegistersLocally(Instruction* instr) {
  ASSERT(!is_optimizing());

  LocationSummary* locs = instr->locs();

  bool blocked_registers[kNumberOfCpuRegisters];

  // Mark all available registers free.
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    blocked_registers[i] = false;
  }

  // Mark all fixed input, temp and output registers as used.
  for (intptr_t i = 0; i < locs->input_count(); i++) {
    Location loc = locs->in(i);
    if (loc.IsRegister()) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
    }
  }

  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsRegister()) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
    }
  }

  if (locs->out().IsRegister()) {
    // Fixed output registers are allowed to overlap with
    // temps and inputs.
    blocked_registers[locs->out().reg()] = true;
  }

  // Do not allocate known registers.
  blocked_registers[CTX] = true;
  blocked_registers[SPREG] = true;
  blocked_registers[FPREG] = true;
  if (TMP != kNoRegister) {
    blocked_registers[TMP] = true;
  }

  // Allocate all unallocated input locations.
  const bool should_pop = !instr->IsPushArgument();
  for (intptr_t i = locs->input_count() - 1; i >= 0; i--) {
    Location loc = locs->in(i);
    Register reg = kNoRegister;
    if (loc.IsRegister()) {
      reg = loc.reg();
    } else if (loc.IsUnallocated() || loc.IsConstant()) {
      ASSERT(loc.IsConstant() ||
             ((loc.policy() == Location::kRequiresRegister) ||
              (loc.policy() == Location::kWritableRegister)));
      reg = AllocateFreeRegister(blocked_registers);
      locs->set_in(i, Location::RegisterLocation(reg));
    }
    ASSERT(reg != kNoRegister);

    // Inputs are consumed from the simulated frame. In case of a call argument
    // we leave it until the call instruction.
    if (should_pop) {
      assembler()->PopRegister(reg);
    }
  }

  // Allocate all unallocated temp locations.
  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsUnallocated()) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      loc = Location::RegisterLocation(
        AllocateFreeRegister(blocked_registers));
      locs->set_temp(i, loc);
    }
  }

  Location result_location = locs->out();
  if (result_location.IsUnallocated()) {
    switch (result_location.policy()) {
      case Location::kAny:
      case Location::kPrefersRegister:
      case Location::kRequiresRegister:
      case Location::kWritableRegister:
        result_location = Location::RegisterLocation(
            AllocateFreeRegister(blocked_registers));
        break;
      case Location::kSameAsFirstInput:
        result_location = locs->in(0);
        break;
      case Location::kRequiresXmmRegister:
        UNREACHABLE();
        break;
    }
    locs->set_out(result_location);
  }
}


ParallelMoveResolver::ParallelMoveResolver(FlowGraphCompiler* compiler)
    : compiler_(compiler), moves_(32) {}


void ParallelMoveResolver::EmitNativeCode(ParallelMoveInstr* parallel_move) {
  ASSERT(moves_.is_empty());
  // Build up a worklist of moves.
  BuildInitialMoveList(parallel_move);

  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    // Skip constants to perform them last.  They don't block other moves
    // and skipping such moves with register destinations keeps those
    // registers free for the whole algorithm.
    if (!move.IsEliminated() && !move.src().IsConstant()) PerformMove(i);
  }

  // Perform the moves with constant sources.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& move = *moves_[i];
    if (!move.IsEliminated()) {
      ASSERT(move.src().IsConstant());
      EmitMove(i);
    }
  }

  moves_.Clear();
}


void ParallelMoveResolver::BuildInitialMoveList(
    ParallelMoveInstr* parallel_move) {
  // Perform a linear sweep of the moves to add them to the initial list of
  // moves to perform, ignoring any move that is redundant (the source is
  // the same as the destination, the destination is ignored and
  // unallocated, or the move was already eliminated).
  for (int i = 0; i < parallel_move->NumMoves(); i++) {
    MoveOperands* move = parallel_move->MoveOperandsAt(i);
    if (!move->IsRedundant()) moves_.Add(move);
  }
}


void ParallelMoveResolver::PerformMove(int index) {
  // Each call to this function performs a move and deletes it from the move
  // graph.  We first recursively perform any move blocking this one.  We
  // mark a move as "pending" on entry to PerformMove in order to detect
  // cycles in the move graph.  We use operand swaps to resolve cycles,
  // which means that a call to PerformMove could change any source operand
  // in the move graph.

  ASSERT(!moves_[index]->IsPending());
  ASSERT(!moves_[index]->IsRedundant());

  // Clear this move's destination to indicate a pending move.  The actual
  // destination is saved in a stack-allocated local.  Recursion may allow
  // multiple moves to be pending.
  ASSERT(!moves_[index]->src().IsInvalid());
  Location destination = moves_[index]->MarkPending();

  // Perform a depth-first traversal of the move graph to resolve
  // dependencies.  Any unperformed, unpending move with a source the same
  // as this one's destination blocks this one so recursively perform all
  // such moves.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(destination) && !other_move.IsPending()) {
      // Though PerformMove can change any source operand in the move graph,
      // this call cannot create a blocking move via a swap (this loop does
      // not miss any).  Assume there is a non-blocking move with source A
      // and this move is blocked on source B and there is a swap of A and
      // B.  Then A and B must be involved in the same cycle (or they would
      // not be swapped).  Since this move's destination is B and there is
      // only a single incoming edge to an operand, this move must also be
      // involved in the same cycle.  In that case, the blocking move will
      // be created but will be "pending" when we return from PerformMove.
      PerformMove(i);
    }
  }

  // We are about to resolve this move and don't need it marked as
  // pending, so restore its destination.
  moves_[index]->ClearPending(destination);

  // This move's source may have changed due to swaps to resolve cycles and
  // so it may now be the last move in the cycle.  If so remove it.
  if (moves_[index]->src().Equals(destination)) {
    moves_[index]->Eliminate();
    return;
  }

  // The move may be blocked on a (at most one) pending move, in which case
  // we have a cycle.  Search for such a blocking move and perform a swap to
  // resolve it.
  for (int i = 0; i < moves_.length(); ++i) {
    const MoveOperands& other_move = *moves_[i];
    if (other_move.Blocks(destination)) {
      ASSERT(other_move.IsPending());
      EmitSwap(index);
      return;
    }
  }

  // This move is not blocked.
  EmitMove(index);
}


Condition FlowGraphCompiler::FlipCondition(Condition condition) {
  switch (condition) {
    case EQUAL:         return EQUAL;
    case NOT_EQUAL:     return NOT_EQUAL;
    case LESS:          return GREATER;
    case LESS_EQUAL:    return GREATER_EQUAL;
    case GREATER:       return LESS;
    case GREATER_EQUAL: return LESS_EQUAL;
    case BELOW:         return ABOVE;
    case BELOW_EQUAL:   return ABOVE_EQUAL;
    case ABOVE:         return BELOW;
    case ABOVE_EQUAL:   return BELOW_EQUAL;
    default:
      UNIMPLEMENTED();
      return EQUAL;
  }
}


bool FlowGraphCompiler::EvaluateCondition(Condition condition,
                                          intptr_t left,
                                          intptr_t right) {
  const uintptr_t unsigned_left = static_cast<uintptr_t>(left);
  const uintptr_t unsigned_right = static_cast<uintptr_t>(right);
  switch (condition) {
    case EQUAL:         return left == right;
    case NOT_EQUAL:     return left != right;
    case LESS:          return left < right;
    case LESS_EQUAL:    return left <= right;
    case GREATER:       return left > right;
    case GREATER_EQUAL: return left >= right;
    case BELOW:         return unsigned_left < unsigned_right;
    case BELOW_EQUAL:   return unsigned_left <= unsigned_right;
    case ABOVE:         return unsigned_left > unsigned_right;
    case ABOVE_EQUAL:   return unsigned_left >= unsigned_right;
    default:
      UNIMPLEMENTED();
      return false;
  }
}


FieldAddress FlowGraphCompiler::ElementAddressForIntIndex(intptr_t cid,
                                                          Register array,
                                                          intptr_t offset) {
  switch (cid) {
    case kArrayCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid: {
      const intptr_t disp = offset * kWordSize + sizeof(RawArray);
      ASSERT(Utils::IsInt(31, disp));
      return FieldAddress(array, disp);
    }
    case kFloat32ArrayCid: {
      const intptr_t disp =
          offset * kFloatSize + Float32Array::data_offset();
      ASSERT(Utils::IsInt(31, disp));
      return FieldAddress(array, disp);
    }
    case kFloat64ArrayCid: {
      const intptr_t disp =
          offset * kDoubleSize + Float64Array::data_offset();
      ASSERT(Utils::IsInt(31, disp));
      return FieldAddress(array, disp);
    }
    default:
      UNIMPLEMENTED();
      return FieldAddress(SPREG, 0);
  }
}

}  // namespace dart
