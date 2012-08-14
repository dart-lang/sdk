// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_XXX.

#include "vm/flow_graph_compiler.h"

#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/deopt_instructions.h"
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
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(bool, trace_functions);
DECLARE_FLAG(int, optimization_counter_threshold);

RawDeoptInfo* DeoptimizationStub::CreateDeoptInfo(FlowGraphCompiler* compiler) {
  if (deoptimization_env_ == NULL) return DeoptInfo::null();
  const Function& function = compiler->parsed_function().function();
  // For functions with optional arguments, all incoming are copied to local
  // area below FP, deoptimization environment does not track them.
  const intptr_t num_args = (function.num_optional_parameters() > 0) ?
      0 : function.num_fixed_parameters();
  const intptr_t fixed_parameter_count =
      deoptimization_env_->fixed_parameter_count();
  DeoptInfoBuilder builder(compiler->object_table(), num_args);

  intptr_t slot_ix = 0;
  builder.AddReturnAddress(function, deopt_id_, slot_ix++);

  // All locals between TOS and PC-marker.
  const GrowableArray<Value*>& values = deoptimization_env_->values();

  // Assign locations to values pushed above spill slots with PushArgument.
  intptr_t height = compiler->StackSize();
  for (intptr_t i = 0; i < values.length(); i++) {
    if (deoptimization_env_->LocationAt(i).IsInvalid() &&
        !values[i]->IsConstant()) {
      ASSERT(values[i]->AsUse()->definition()->IsPushArgument());
      *deoptimization_env_->LocationSlotAt(i) = Location::StackSlot(height++);
    }
  }

  for (intptr_t i = values.length() - 1; i >= fixed_parameter_count; i--) {
    builder.AddCopy(deoptimization_env_->LocationAt(i), *values[i], slot_ix++);
  }

  // PC marker, caller-fp, caller-pc.
  builder.AddPcMarker(function, slot_ix++);
  builder.AddCallerFp(slot_ix++);
  builder.AddCallerPc(slot_ix++);
  // Incoming arguments.
  for (intptr_t i = fixed_parameter_count - 1; i >= 0; i--) {
    builder.AddCopy(deoptimization_env_->LocationAt(i), *values[i], slot_ix++);
  }

  const DeoptInfo& deopt_info = DeoptInfo::Handle(builder.CreateDeoptInfo());
  return deopt_info.raw();
}


FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>& block_order,
    bool is_optimizing,
    bool is_ssa,
    bool is_leaf)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      block_order_(block_order),
      current_block_(NULL),
      exception_handlers_list_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_table_builder_(is_ssa ? new StackmapTableBuilder() : NULL),
      block_info_(block_order.length()),
      deopt_stubs_(),
      object_table_(GrowableObjectArray::Handle(GrowableObjectArray::New())),
      is_optimizing_(is_optimizing),
      is_ssa_(is_ssa),
      is_dart_leaf_(is_leaf),
      bool_true_(Bool::ZoneHandle(Bool::True())),
      bool_false_(Bool::ZoneHandle(Bool::False())),
      double_class_(Class::ZoneHandle(
          Isolate::Current()->object_store()->double_class())),
      frame_register_allocator_(this, is_optimizing, is_ssa),
      parallel_move_resolver_(this) {
  ASSERT(assembler != NULL);
  ASSERT(is_optimizing_ || !is_ssa_);
}


FlowGraphCompiler::~FlowGraphCompiler() {
  // BlockInfos are zone-allocated, so their destructors are not called.
  // Verify the labels explicitly here.
  for (int i = 0; i < block_info_.length(); ++i) {
    ASSERT(!block_info_[i]->label.IsLinked());
    ASSERT(!block_info_[i]->label.HasNear());
  }
}


bool FlowGraphCompiler::IsLeaf() const {
  return is_dart_leaf_ &&
         !parsed_function_.function().IsClosureFunction() &&
         (parsed_function().copied_parameter_count() == 0);
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
    ASSERT(frame_register_allocator()->IsSpilled());
    assembler()->Comment("B%d", i);
    // Compile the block entry.
    BlockEntryInstr* entry = block_order()[i];
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
      }
    }
  }
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
  if (is_ssa_) {
    return block_order_[0]->AsGraphEntry()->spill_slot_count();
  } else {
    return parsed_function_.stack_local_count() +
        parsed_function_.copied_parameter_count();
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


void FlowGraphCompiler::SaveLiveRegisters(LocationSummary* locs) {
  // TODO(vegorov): consider saving only caller save (volatile) registers.
  for (intptr_t reg_idx = 0; reg_idx < kNumberOfCpuRegisters; ++reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->Contains(reg)) {
      assembler()->PushRegister(reg);
    }
  }
}


void FlowGraphCompiler::RestoreLiveRegisters(LocationSummary* locs) {
  for (intptr_t reg_idx = kNumberOfCpuRegisters - 1; reg_idx >= 0; --reg_idx) {
    Register reg = static_cast<Register>(reg_idx);
    if (locs->live_registers()->Contains(reg)) {
      assembler()->PopRegister(reg);
    }
  }
}


void FlowGraphCompiler::AddSlowPathCode(SlowPathCode* code) {
  slow_path_code_.Add(code);
}


void FlowGraphCompiler::GenerateDeferredCode() {
  for (intptr_t i = 0; i < slow_path_code_.length(); i++) {
    slow_path_code_[i]->EmitNativeCode(this);
  }
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    deopt_stubs_[i]->GenerateCode(this, i);
  }
}


void FlowGraphCompiler::AddExceptionHandler(intptr_t try_index,
                                            intptr_t pc_offset) {
  exception_handlers_list_->AddHandler(try_index, pc_offset);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t deopt_id,
                                             intptr_t token_pos,
                                             intptr_t try_index) {
  ASSERT((kind != PcDescriptors::kDeopt) ||
         frame_register_allocator()->IsSpilled());
  pc_descriptors_list()->AddDescriptor(kind,
                                       assembler()->CodeSize(),
                                       deopt_id,
                                       token_pos,
                                       try_index);
}


Label* FlowGraphCompiler::AddDeoptStub(intptr_t deopt_id,
                                       intptr_t try_index,
                                       DeoptReasonId reason,
                                       Register reg1,
                                       Register reg2,
                                       Register reg3) {
  DeoptimizationStub* stub =
      new DeoptimizationStub(deopt_id, try_index, reason);
  if (pending_deoptimization_env_ == NULL) {
    ASSERT(!is_ssa_);
    frame_register_allocator()->SpillInDeoptStub(stub);
    if (reg1 != kNoRegister) stub->Push(reg1);
    if (reg2 != kNoRegister) stub->Push(reg2);
    if (reg3 != kNoRegister) stub->Push(reg3);
  } else {
    ASSERT(pending_deoptimization_env_ != NULL);
    stub->set_deoptimization_env(pending_deoptimization_env_);
  }
  deopt_stubs_.Add(stub);
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
  descriptors.Verify(parsed_function_.function().is_optimizable());
  code.set_pc_descriptors(descriptors);
}


void FlowGraphCompiler::FinalizeDeoptInfo(const Code& code) {
  const Array& array =
      Array::Handle(Array::New(deopt_stubs_.length(), Heap::kOld));
  DeoptInfo& info = DeoptInfo::Handle();
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    info = deopt_stubs_[i]->CreateDeoptInfo(this);
    array.SetAt(i, info);
  }
  code.set_deopt_info_array(array);
  const Array& object_array = Array::Handle(Array::MakeArray(object_table_));
  code.set_object_table(object_array);
}


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  if (stackmap_table_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_table_builder_->FinalizeStackmaps(code)));
    ASSERT(is_ssa() && is_optimizing());
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
    intptr_t try_index,
    const String& function_name,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t checked_argument_count,
    BitmapBuilder* stack_bitmap) {
  ASSERT(!IsLeaf());
  ASSERT(frame_register_allocator()->IsSpilled());
  ICData& ic_data =
      ICData::ZoneHandle(ICData::New(parsed_function().function(),
                                     function_name,
                                     deopt_id,
                                     checked_argument_count));
  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count, argument_names);
  uword label_address = 0;
  switch (checked_argument_count) {
    case 1:
      label_address = StubCode::OneArgCheckInlineCacheEntryPoint();
      break;
    case 2:
      label_address = StubCode::TwoArgsCheckInlineCacheEntryPoint();
      break;
    default:
      UNIMPLEMENTED();
  }
  ExternalLabel target_label("InlineCache", label_address);

  const intptr_t descr_offset = EmitInstanceCall(&target_label,
                                                 ic_data,
                                                 arguments_descriptor,
                                                 argument_count);
  if (is_ssa() && (stack_bitmap != NULL)) {
    stackmap_table_builder_->AddEntry(descr_offset, stack_bitmap);
  }
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kIcCall,
                                       descr_offset,
                                       deopt_id,
                                       token_pos,
                                       try_index);
}


void FlowGraphCompiler::GenerateStaticCall(intptr_t deopt_id,
                                           intptr_t token_pos,
                                           intptr_t try_index,
                                           const Function& function,
                                           intptr_t argument_count,
                                           const Array& argument_names,
                                           BitmapBuilder* stack_bitmap) {
  ASSERT(frame_register_allocator()->IsSpilled());

  const Array& arguments_descriptor =
      DartEntry::ArgumentsDescriptor(argument_count, argument_names);
  const intptr_t descr_offset = EmitStaticCall(function,
                                               arguments_descriptor,
                                               argument_count);
  if (is_ssa() && (stack_bitmap != NULL)) {
    stackmap_table_builder_->AddEntry(descr_offset, stack_bitmap);
  }
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kFuncCall,
                                       descr_offset,
                                       deopt_id,
                                       token_pos,
                                       try_index);
}


void FlowGraphCompiler::GenerateNumberTypeCheck(Register kClassIdReg,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  GrowableArray<intptr_t> args;
  if (type.IsNumberInterface()) {
    args.Add(kDoubleCid);
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsIntInterface()) {
    args.Add(kMintCid);
    args.Add(kBigintCid);
  } else if (type.IsDoubleInterface()) {
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
  args.Add(kFourByteStringCid);
  args.Add(kExternalOneByteStringCid);
  args.Add(kExternalTwoByteStringCid);
  args.Add(kExternalFourByteStringCid);
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


void FlowGraphCompiler::EmitLoadIndexedGeneric(LoadIndexedComp* comp) {
  const String& function_name =
      String::ZoneHandle(Symbols::New(Token::Str(Token::kINDEX)));

  AddCurrentDescriptor(PcDescriptors::kDeopt,
                       comp->deopt_id(),
                       comp->token_pos(),
                       comp->try_index());

  const intptr_t kNumArguments = 2;
  const intptr_t kNumArgsChecked = 1;  // Type-feedback.
  GenerateInstanceCall(comp->deopt_id(),
                       comp->token_pos(),
                       comp->try_index(),
                       function_name,
                       kNumArguments,
                       Array::ZoneHandle(),  // No optional arguments.
                       kNumArgsChecked,
                       comp->locs()->stack_bitmap());
}


void FlowGraphCompiler::EmitTestAndCall(const ICData& ic_data,
                                        Register class_id_reg,
                                        intptr_t arg_count,
                                        const Array& arg_names,
                                        Label* deopt,
                                        Label* done,
                                        intptr_t deopt_id,
                                        intptr_t token_index,
                                        intptr_t try_index,
                                        BitmapBuilder* stack_bitmap) {
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
                       try_index,
                       target,
                       arg_count,
                       arg_names,
                       stack_bitmap);
    if (!is_last_check) {
      assembler()->jmp(&match_found);
    }
    assembler()->Bind(&next_test);
  }
  assembler()->Bind(&match_found);
  if (done != NULL) {
    assembler()->jmp(done);
  }
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


Register FrameRegisterAllocator::AllocateFreeRegister(bool* blocked_registers) {
  for (intptr_t regno = 0; regno < kNumberOfCpuRegisters; regno++) {
    if (!blocked_registers[regno] && (registers_[regno] == NULL)) {
      blocked_registers[regno] = true;
      return static_cast<Register>(regno);
    }
  }
  return SpillFirst();
}


Register FrameRegisterAllocator::SpillFirst() {
  ASSERT(!stack_.is_empty());
  Register reg = stack_[0];
  stack_.RemoveFirst();
  compiler()->assembler()->PushRegister(reg);
  registers_[reg] = NULL;
  return reg;
}


void FrameRegisterAllocator::SpillRegister(Register reg) {
  while (registers_[reg] != NULL) SpillFirst();
}


void FrameRegisterAllocator::AllocateRegisters(Instruction* instr) {
  if (is_ssa_) return;

  LocationSummary* locs = instr->locs();

  bool blocked_registers[kNumberOfCpuRegisters];
  bool blocked_temp_registers[kNumberOfCpuRegisters];

  bool spill = false;

  // Mark all available registers free.
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    blocked_registers[i] = false;
    blocked_temp_registers[i] = false;
  }

  // Mark all fixed input, temp and output registers as used.
  for (intptr_t i = 0; i < locs->input_count(); i++) {
    Location loc = locs->in(i);
    if (loc.IsRegister()) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
      if (registers_[loc.reg()] != NULL) {
        intptr_t stack_index = stack_.length() - (locs->input_count() - i);
        if ((stack_index < 0) || (stack_[stack_index] != loc.reg())) {
          spill = true;
        }
      }
    }
  }

  if (spill) Spill();

  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.IsRegister()) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
      blocked_temp_registers[loc.reg()] = true;
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
  for (intptr_t i = locs->input_count() - 1; i >= 0; i--) {
    Location loc = locs->in(i);
    Register reg = kNoRegister;
    if (loc.IsRegister()) {
      reg = loc.reg();
    } else if (loc.IsUnallocated()) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      if (!stack_.is_empty() && !blocked_temp_registers[stack_.Last()]) {
        reg = stack_.Last();
        blocked_registers[reg] = true;
      } else {
        reg = AllocateFreeRegister(blocked_registers);
      }
      locs->set_in(i, Location::RegisterLocation(reg));
    }

    // Inputs are consumed from the simulated frame. In case of a call argument
    // we leave it until the call instruction.
    if (!instr->IsPushArgument()) Pop(reg, instr->InputAt(i));
  }

  // If this instruction is call spill everything that was not consumed by
  // input locations.
  if (locs->contains_call() || instr->IsBranch() || instr->IsGoto()) {
    Spill();
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
    SpillRegister(loc.reg());
  }

  Location result_location = locs->out();
  if (result_location.IsUnallocated()) {
    switch (result_location.policy()) {
      case Location::kAny:
      case Location::kPrefersRegister:
      case Location::kRequiresRegister:
        result_location = Location::RegisterLocation(
            AllocateFreeRegister(blocked_registers));
        break;
      case Location::kSameAsFirstInput:
        result_location = locs->in(0);
        break;
    }
    locs->set_out(result_location);
  }

  if (result_location.IsRegister()) {
    SpillRegister(result_location.reg());
  }
}


void FrameRegisterAllocator::Pop(Register dst, Value* val) {
  if (is_ssa_) return;

  if (!stack_.is_empty()) {
    ASSERT(keep_values_in_registers_);
    Register src = stack_.Last();
    ASSERT(val->AsUse()->definition() == registers_[src]);
    stack_.RemoveLast();
    registers_[src] = NULL;
    compiler()->assembler()->MoveRegister(dst, src);
  } else {
    compiler()->assembler()->PopRegister(dst);
  }
}


void FrameRegisterAllocator::Push(Register reg, BindInstr* val) {
  if (is_ssa_) return;

  ASSERT(registers_[reg] == NULL);
  if (keep_values_in_registers_) {
    registers_[reg] = val;
    stack_.Add(reg);
  } else {
    compiler()->assembler()->PushRegister(reg);
  }
}


void FrameRegisterAllocator::Spill() {
  if (is_ssa_) return;

  for (int i = 0; i < stack_.length(); i++) {
    Register r = stack_[i];
    registers_[r] = NULL;
    compiler()->assembler()->PushRegister(r);
  }
  stack_.Clear();
}


void FrameRegisterAllocator::SpillInDeoptStub(DeoptimizationStub* stub) {
  if (is_ssa_) return;

  for (int i = 0; i < stack_.length(); i++) {
    stub->Push(stack_[i]);
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


}  // namespace dart
