// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_XXX.

#include "vm/flow_graph_compiler.h"

#include "vm/debugger.h"
#include "vm/il_printer.h"
#include "vm/intrinsifier.h"
#include "vm/locations.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/stub_code.h"

namespace dart {

DECLARE_FLAG(bool, code_comments);
DECLARE_FLAG(bool, enable_type_checks);
DECLARE_FLAG(bool, intrinsify);
DECLARE_FLAG(bool, report_usage_count);
DECLARE_FLAG(bool, trace_functions);
DECLARE_FLAG(int, optimization_counter_threshold);


FlowGraphCompiler::FlowGraphCompiler(
    Assembler* assembler,
    const ParsedFunction& parsed_function,
    const GrowableArray<BlockEntryInstr*>& block_order,
    bool is_optimizing)
    : assembler_(assembler),
      parsed_function_(parsed_function),
      block_order_(block_order),
      current_block_(NULL),
      exception_handlers_list_(NULL),
      pc_descriptors_list_(NULL),
      stackmap_builder_(NULL),
      block_info_(block_order.length()),
      deopt_stubs_(),
      is_optimizing_(is_optimizing),
      bool_true_(Bool::ZoneHandle(Bool::True())),
      bool_false_(Bool::ZoneHandle(Bool::False())),
      double_class_(Class::ZoneHandle(
          Isolate::Current()->object_store()->double_class())),
      frame_register_allocator_(this, is_optimizing) {
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


void FlowGraphCompiler::InitCompiler() {
  pc_descriptors_list_ = new DescriptorList();
  exception_handlers_list_ = new ExceptionHandlerList();
  block_info_.Clear();
  for (int i = 0; i < block_order_.length(); ++i) {
    block_info_.Add(new BlockInfo());
  }
}


void FlowGraphCompiler::VisitBlocks() {
  for (intptr_t i = 0; i < block_order().length(); ++i) {
    ASSERT(frame_register_allocator()->IsSpilled());
    assembler()->Comment("B%d", i);
    // Compile the block entry.
    set_current_block(block_order()[i]);
    current_block()->PrepareEntry(this);
    Instruction* instr = current_block()->StraightLineSuccessor();
    // Compile all successors until an exit, branch, or a block entry.
    while ((instr != NULL) && !instr->IsBlockEntry()) {
      if (FLAG_code_comments) EmitComment(instr);
      ASSERT(instr->locs() != NULL);
      EmitInstructionPrologue(instr);
      instr->EmitNativeCode(this);
      instr = instr->StraightLineSuccessor();
    }
    BlockEntryInstr* successor =
        (instr == NULL) ? NULL : instr->AsBlockEntry();
    if (successor != NULL) {
      frame_register_allocator()->Spill();
      // Block ended with a "goto".  We can fall through if it is the
      // next block in the list.  Otherwise, we need a jump.
      if ((i == block_order().length() - 1) ||
          (block_order()[i + 1] != successor)) {
        assembler()->jmp(GetBlockLabel(successor));
      }
    }
  }
}


void FlowGraphCompiler::Bailout(const char* reason) {
  const char* kFormat = "FlowGraphCompiler Bailout: %s %s.";
  const char* function_name = parsed_function().function().ToCString();
  intptr_t len = OS::SNPrint(NULL, 0, kFormat, function_name, reason) + 1;
  char* chars = reinterpret_cast<char*>(
      Isolate::Current()->current_zone()->Allocate(len));
  OS::SNPrint(chars, len, kFormat, function_name, reason);
  const Error& error = Error::Handle(
      LanguageError::New(String::Handle(String::New(chars))));
  Isolate::Current()->long_jump_base()->Jump(1, error);
}


intptr_t FlowGraphCompiler::StackSize() const {
  return parsed_function_.stack_local_count() +
      parsed_function_.copied_parameter_count();
}


Label* FlowGraphCompiler::GetBlockLabel(
    BlockEntryInstr* block_entry) const {
  intptr_t block_index = block_entry->postorder_number();
  return &block_info_[block_index]->label;
}


bool FlowGraphCompiler::IsNextBlock(TargetEntryInstr* block_entry) const {
  intptr_t current_index = reverse_index(current_block()->postorder_number());
  return block_order_[current_index + 1] == block_entry;
}


void FlowGraphCompiler::GenerateDeferredCode() {
  for (intptr_t i = 0; i < deopt_stubs_.length(); i++) {
    deopt_stubs_[i]->GenerateCode(this);
  }
}


void FlowGraphCompiler::AddExceptionHandler(intptr_t try_index,
                                            intptr_t pc_offset) {
  exception_handlers_list_->AddHandler(try_index, pc_offset);
}


// Uses current pc position and try-index.
void FlowGraphCompiler::AddCurrentDescriptor(PcDescriptors::Kind kind,
                                             intptr_t cid,
                                             intptr_t token_index,
                                             intptr_t try_index) {
  ASSERT((kind != PcDescriptors::kDeopt) ||
         frame_register_allocator()->IsSpilled());
  pc_descriptors_list()->AddDescriptor(kind,
                                       assembler()->CodeSize(),
                                       cid,
                                       token_index,
                                       try_index);
}


Label* FlowGraphCompiler::AddDeoptStub(intptr_t deopt_id,
                                       intptr_t deopt_token_index,
                                       intptr_t try_index,
                                       DeoptReasonId reason,
                                       Register reg1,
                                       Register reg2,
                                       Register reg3) {
  DeoptimizationStub* stub =
      new DeoptimizationStub(deopt_id, deopt_token_index, try_index, reason);
  frame_register_allocator()->SpillInDeoptStub(stub);
  if (reg1 != kNoRegister) stub->Push(reg1);
  if (reg2 != kNoRegister) stub->Push(reg2);
  if (reg3 != kNoRegister) stub->Push(reg3);
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


void FlowGraphCompiler::FinalizeStackmaps(const Code& code) {
  if (stackmap_builder_ == NULL) {
    // The unoptimizing compiler has no stack maps.
    code.set_stackmaps(Array::Handle());
  } else {
    // Finalize the stack map array and add it to the code object.
    code.set_stackmaps(
        Array::Handle(stackmap_builder_->FinalizeStackmaps(code)));
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


static bool CanOptimize() {
  return !FLAG_report_usage_count &&
         (FLAG_optimization_counter_threshold >= 0) &&
         !Isolate::Current()->debugger()->IsActive();
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
    intptr_t cid,
    intptr_t token_index,
    intptr_t try_index,
    const String& function_name,
    intptr_t argument_count,
    const Array& argument_names,
    intptr_t checked_argument_count) {
  ASSERT(frame_register_allocator()->IsSpilled());
  ICData& ic_data =
      ICData::ZoneHandle(ICData::New(parsed_function().function(),
                                     function_name,
                                     cid,
                                     checked_argument_count));
  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
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
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kIcCall,
                                       descr_offset,
                                       cid,
                                       token_index,
                                       try_index);
}


void FlowGraphCompiler::GenerateStaticCall(intptr_t cid,
                                           intptr_t token_index,
                                           intptr_t try_index,
                                           const Function& function,
                                           intptr_t argument_count,
                                           const Array& argument_names) {
  ASSERT(frame_register_allocator()->IsSpilled());

  const Array& arguments_descriptor =
      CodeGenerator::ArgumentsDescriptor(argument_count, argument_names);
  const intptr_t descr_offset = EmitStaticCall(function,
                                               arguments_descriptor,
                                               argument_count);
  pc_descriptors_list()->AddDescriptor(PcDescriptors::kFuncCall,
                                       descr_offset,
                                       cid,
                                       token_index,
                                       try_index);
}


void FlowGraphCompiler::GenerateNumberTypeCheck(Register kClassIdReg,
                                                const AbstractType& type,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  GrowableArray<intptr_t> args;
  if (type.IsNumberInterface()) {
    args.Add(kDouble);
    args.Add(kMint);
    args.Add(kBigint);
  } else if (type.IsIntInterface()) {
    args.Add(kMint);
    args.Add(kBigint);
  } else if (type.IsDoubleInterface()) {
    args.Add(kDouble);
  }
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateStringTypeCheck(Register kClassIdReg,
                                                Label* is_instance_lbl,
                                                Label* is_not_instance_lbl) {
  GrowableArray<intptr_t> args;
  args.Add(kOneByteString);
  args.Add(kTwoByteString);
  args.Add(kFourByteString);
  args.Add(kExternalOneByteString);
  args.Add(kExternalTwoByteString);
  args.Add(kExternalFourByteString);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, is_not_instance_lbl);
}


void FlowGraphCompiler::GenerateListTypeCheck(Register kClassIdReg,
                                              Label* is_instance_lbl) {
  Label unknown;
  GrowableArray<intptr_t> args;
  args.Add(kArray);
  args.Add(kGrowableObjectArray);
  args.Add(kImmutableArray);
  CheckClassIds(kClassIdReg, args, is_instance_lbl, &unknown);
  assembler()->Bind(&unknown);
}


void FlowGraphCompiler::EmitComment(Instruction* instr) {
  char buffer[80];
  BufferFormatter f(buffer, sizeof(buffer));
  instr->PrintTo(&f);
  assembler()->Comment("@%d: %s", instr->cid(), buffer);
}


void FlowGraphCompiler::EmitLoadIndexedGeneric(LoadIndexedComp* comp) {
  const String& function_name =
      String::ZoneHandle(String::NewSymbol(Token::Str(Token::kINDEX)));

  AddCurrentDescriptor(PcDescriptors::kDeopt,
                       comp->cid(),
                       comp->token_index(),
                       comp->try_index());

  const intptr_t kNumArguments = 2;
  const intptr_t kNumArgsChecked = 1;  // Type-feedback.
  GenerateInstanceCall(comp->cid(),
                       comp->token_index(),
                       comp->try_index(),
                       function_name,
                       kNumArguments,
                       Array::ZoneHandle(),  // No optional arguments.
                       kNumArgsChecked);
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
  ASSERT(stack_.length() > 0);
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
    if (loc.kind() == Location::kRegister) {
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
    if (loc.kind() == Location::kRegister) {
      ASSERT(!blocked_registers[loc.reg()]);
      blocked_registers[loc.reg()] = true;
      blocked_temp_registers[loc.reg()] = true;
    }
  }

  if (locs->out().kind() == Location::kRegister) {
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
    if (loc.kind() == Location::kRegister) {
      reg = loc.reg();
    } else if (loc.kind() == Location::kUnallocated) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      if ((stack_.length() > 0) && !blocked_temp_registers[stack_.Last()]) {
        reg = stack_.Last();
        blocked_registers[reg] = true;
      } else {
        reg = AllocateFreeRegister(blocked_registers);
      }
      locs->set_in(i, Location::RegisterLocation(reg));
    }

    Pop(reg, instr->InputAt(i));
  }

  // If this instruction is call spill everything that was not consumed by
  // input locations.
  if (locs->is_call() || locs->is_branch()) {
    Spill();
  }

  // Allocate all unallocated temp locations.
  for (intptr_t i = 0; i < locs->temp_count(); i++) {
    Location loc = locs->temp(i);
    if (loc.kind() == Location::kUnallocated) {
      ASSERT(loc.policy() == Location::kRequiresRegister);
      loc = Location::RegisterLocation(
        AllocateFreeRegister(blocked_registers));
      locs->set_temp(i, loc);
    }
    SpillRegister(loc.reg());
  }

  Location result_location = locs->out();
  if (result_location.kind() == Location::kUnallocated) {
    switch (result_location.policy()) {
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

  if (result_location.kind() == Location::kRegister) {
    SpillRegister(result_location.reg());
  }
}


void FrameRegisterAllocator::Pop(Register dst, Value* val) {
  if (stack_.length() > 0) {
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
  ASSERT(registers_[reg] == NULL);
  if (keep_values_in_registers_) {
    registers_[reg] = val;
    stack_.Add(reg);
  } else {
    compiler()->assembler()->PushRegister(reg);
  }
}


void FrameRegisterAllocator::Spill() {
  for (int i = 0; i < stack_.length(); i++) {
    Register r = stack_[i];
    registers_[r] = NULL;
    compiler()->assembler()->PushRegister(r);
  }
  stack_.Clear();
}


void FrameRegisterAllocator::SpillInDeoptStub(DeoptimizationStub* stub) {
  for (int i = 0; i < stack_.length(); i++) {
    stub->Push(stack_[i]);
  }
}


}  // namespace dart
