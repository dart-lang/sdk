// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/regexp_assembler_ir.h"

#include "platform/unicode.h"
#include "vm/bit_vector.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_entry.h"
#include "vm/longjump.h"
#include "vm/object_store.h"
#include "vm/regexp.h"
#include "vm/resolver.h"
#include "vm/runtime_entry.h"
#include "vm/stack_frame.h"

#define Z zone()

// Debugging output macros. TAG() is called at the head of each interesting
// function and prints its name during execution if irregexp tracing is enabled.
#define TAG()                                                                  \
  if (FLAG_trace_irregexp) {                                                   \
    TAG_();                                                                    \
  }
#define TAG_()                                                                 \
  Print(Bind(new (Z) ConstantInstr(String::ZoneHandle(                         \
      Z, String::Concat(String::Handle(String::New("TAG: ")),                  \
                        String::Handle(String::New(__FUNCTION__)),             \
                        Heap::kOld)))));

#define PRINT(arg)                                                             \
  if (FLAG_trace_irregexp) {                                                   \
    Print(arg);                                                                \
  }

namespace dart {

static const intptr_t kMinStackSize = 512;

/*
 * This assembler uses the following main local variables:
 * - stack_: A pointer to a growable list which we use as an all-purpose stack
 *           storing backtracking offsets, positions & stored register values.
 * - current_character_: Stores the currently loaded characters (possibly more
 *                       than one).
 * - current_position_: The current position within the string, stored as a
 *                      negative offset from the end of the string (i.e. the
 *                      position corresponding to str[0] is -str.length).
 *                      Note that current_position_ is *not* byte-based, unlike
 *                      original V8 code.
 *
 * Results are returned though an array of capture indices, stored at
 * matches_param_. A null array specifies a failure to match. The match indices
 * [start_inclusive, end_exclusive] for capture group i are stored at positions
 * matches_param_[i * 2] and matches_param_[i * 2 + 1], respectively. Match
 * indices of -1 denote non-matched groups. Note that we store these indices
 * as a negative offset from the end of the string in registers_array_
 * during processing, and convert them to standard indexes when copying them
 * to matches_param_ on successful match.
 */
IRRegExpMacroAssembler::IRRegExpMacroAssembler(
    intptr_t specialization_cid,
    intptr_t capture_count,
    const ParsedFunction* parsed_function,
    const ZoneGrowableArray<const ICData*>& ic_data_array,
    intptr_t osr_id,
    Zone* zone)
    : RegExpMacroAssembler(zone),
      thread_(Thread::Current()),
      specialization_cid_(specialization_cid),
      parsed_function_(parsed_function),
      ic_data_array_(ic_data_array),
      current_instruction_(NULL),
      stack_(NULL),
      stack_pointer_(NULL),
      current_character_(NULL),
      current_position_(NULL),
      string_param_(NULL),
      string_param_length_(NULL),
      start_index_param_(NULL),
      registers_count_(0),
      saved_registers_count_((capture_count + 1) * 2),
      stack_array_cell_(Array::ZoneHandle(zone, Array::New(1, Heap::kOld))),
      // The registers array is allocated at a fixed size after assembly.
      registers_array_(TypedData::ZoneHandle(zone, TypedData::null())),
      // B0 is taken by GraphEntry thus block ids must start at 1.
      block_id_(1) {
  switch (specialization_cid) {
    case kOneByteStringCid:
    case kExternalOneByteStringCid:
      mode_ = ASCII;
      break;
    case kTwoByteStringCid:
    case kExternalTwoByteStringCid:
      mode_ = UC16;
      break;
    default:
      UNREACHABLE();
  }

  InitializeLocals();

  // Allocate an initial stack backing of the minimum stack size. The stack
  // backing is indirectly referred to so we can reuse it on subsequent matches
  // even in the case where the backing has been enlarged and thus reallocated.
  stack_array_cell_.SetAt(
      0,
      TypedData::Handle(zone, TypedData::New(kTypedDataInt32ArrayCid,
                                             kMinStackSize / 4, Heap::kOld)));

  // Create and generate all preset blocks.
  entry_block_ = new (zone) GraphEntryInstr(*parsed_function_, osr_id);

  auto function_entry = new (zone) FunctionEntryInstr(
      entry_block_, block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());
  entry_block_->set_normal_entry(function_entry);

  start_block_ = new (zone)
      JoinEntryInstr(block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());
  success_block_ = new (zone)
      JoinEntryInstr(block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());
  backtrack_block_ = new (zone)
      JoinEntryInstr(block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());
  exit_block_ = new (zone)
      JoinEntryInstr(block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());

  GenerateEntryBlock();
  GenerateSuccessBlock();
  GenerateExitBlock();

  blocks_.Add(entry_block_);
  blocks_.Add(entry_block_->normal_entry());
  blocks_.Add(start_block_);
  blocks_.Add(success_block_);
  blocks_.Add(backtrack_block_);
  blocks_.Add(exit_block_);

  // Begin emission at the start_block_.
  set_current_instruction(start_block_);
}

IRRegExpMacroAssembler::~IRRegExpMacroAssembler() {}

void IRRegExpMacroAssembler::InitializeLocals() {
  // All generated functions are expected to have a current-context variable.
  // This variable is unused in irregexp functions.
  parsed_function_->current_context_var()->set_index(
      VariableIndex(GetNextLocalIndex()));

  // Create local variables and parameters.
  stack_ = Local(Symbols::stack());
  stack_pointer_ = Local(Symbols::stack_pointer());
  registers_ = Local(Symbols::position_registers());
  current_character_ = Local(Symbols::current_character());
  current_position_ = Local(Symbols::current_position());
  string_param_length_ = Local(Symbols::string_param_length());
  capture_length_ = Local(Symbols::capture_length());
  match_start_index_ = Local(Symbols::match_start_index());
  capture_start_index_ = Local(Symbols::capture_start_index());
  match_end_index_ = Local(Symbols::match_end_index());
  char_in_capture_ = Local(Symbols::char_in_capture());
  char_in_match_ = Local(Symbols::char_in_match());
  index_temp_ = Local(Symbols::index_temp());
  result_ = Local(Symbols::result());

  string_param_ = Parameter(Symbols::string_param(),
                            RegExpMacroAssembler::kParamStringIndex);
  start_index_param_ = Parameter(Symbols::start_index_param(),
                                 RegExpMacroAssembler::kParamStartOffsetIndex);
}

void IRRegExpMacroAssembler::GenerateEntryBlock() {
  set_current_instruction(entry_block_->normal_entry());
  TAG();

  // Store string.length.
  Value* string_push = PushLocal(string_param_);

  StoreLocal(string_param_length_,
             Bind(InstanceCall(InstanceCallDescriptor(String::ZoneHandle(
                                   Field::GetterSymbol(Symbols::Length()))),
                               string_push)));

  // Store (start_index - string.length) as the current position (since it's a
  // negative offset from the end of the string).
  Value* start_index_push = PushLocal(start_index_param_);
  Value* length_push = PushLocal(string_param_length_);

  StoreLocal(current_position_, Bind(Sub(start_index_push, length_push)));

  // Generate a local list variable to represent "registers" and
  // initialize capture registers (others remain garbage).
  StoreLocal(registers_, Bind(new (Z) ConstantInstr(registers_array_)));
  ClearRegisters(0, saved_registers_count_ - 1);

  // Generate a local list variable to represent the backtracking stack.
  Value* stack_cell_push = Bind(new (Z) ConstantInstr(stack_array_cell_));
  StoreLocal(stack_,
             Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                               stack_cell_push, Bind(Uint64Constant(0)))));
  StoreLocal(stack_pointer_, Bind(Int64Constant(-1)));

  // Jump to the start block.
  current_instruction_->Goto(start_block_);
}

void IRRegExpMacroAssembler::GenerateBacktrackBlock() {
  set_current_instruction(backtrack_block_);
  TAG();
  CheckPreemption(/*is_backtrack=*/true);

  const intptr_t entries_count = entry_block_->indirect_entries().length();

  TypedData& offsets = TypedData::ZoneHandle(
      Z, TypedData::New(kTypedDataInt32ArrayCid, entries_count, Heap::kOld));

  Value* block_offsets_push = Bind(new (Z) ConstantInstr(offsets));
  Value* block_id_push = Bind(PopStack());

  Value* offset_value =
      Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                        block_offsets_push, block_id_push));

  backtrack_goto_ = new (Z) IndirectGotoInstr(&offsets, offset_value);
  CloseBlockWith(backtrack_goto_);

  // Add an edge from the "indirect" goto to each of the targets.
  for (intptr_t j = 0; j < entries_count; j++) {
    backtrack_goto_->AddSuccessor(
        TargetWithJoinGoto(entry_block_->indirect_entries().At(j)));
  }
}

void IRRegExpMacroAssembler::GenerateSuccessBlock() {
  set_current_instruction(success_block_);
  TAG();

  Value* type = Bind(new (Z) ConstantInstr(TypeArguments::ZoneHandle(
      Z, Isolate::Current()->object_store()->type_argument_int())));
  Value* length = Bind(Uint64Constant(saved_registers_count_));
  Value* array = Bind(new (Z) CreateArrayInstr(TokenPosition::kNoSource, type,
                                               length, GetNextDeoptId()));
  StoreLocal(result_, array);

  // Store captured offsets in the `matches` parameter.
  for (intptr_t i = 0; i < saved_registers_count_; i++) {
    Value* matches_push = PushLocal(result_);
    Value* index_push = Bind(Uint64Constant(i));

    // Convert negative offsets from the end of the string to string indices.
    // TODO(zerny): use positive offsets from the get-go.
    Value* offset_push = LoadRegister(i);
    Value* len_push = PushLocal(string_param_length_);
    Value* value_push = Bind(Add(offset_push, len_push));

    Do(InstanceCall(InstanceCallDescriptor::FromToken(Token::kASSIGN_INDEX),
                    matches_push, index_push, value_push));
  }

  // Print the result if tracing.
  PRINT(PushLocal(result_));

  // Return true on success.
  AppendInstruction(new (Z) ReturnInstr(
      TokenPosition::kNoSource, Bind(LoadLocal(result_)), GetNextDeoptId()));
}

void IRRegExpMacroAssembler::GenerateExitBlock() {
  set_current_instruction(exit_block_);
  TAG();

  // Return false on failure.
  AppendInstruction(new (Z) ReturnInstr(
      TokenPosition::kNoSource, Bind(LoadLocal(result_)), GetNextDeoptId()));
}

void IRRegExpMacroAssembler::FinalizeRegistersArray() {
  ASSERT(registers_count_ >= saved_registers_count_);
  registers_array_ =
      TypedData::New(kTypedDataInt32ArrayCid, registers_count_, Heap::kOld);
}

bool IRRegExpMacroAssembler::CanReadUnaligned() {
  return !slow_safe();
}

ArrayPtr IRRegExpMacroAssembler::Execute(const RegExp& regexp,
                                         const String& input,
                                         const Smi& start_offset,
                                         bool sticky,
                                         Zone* zone) {
  const intptr_t cid = input.GetClassId();
  const Function& fun = Function::Handle(regexp.function(cid, sticky));
  ASSERT(!fun.IsNull());
  // Create the argument list.
  const Array& args =
      Array::Handle(Array::New(RegExpMacroAssembler::kParamCount));
  args.SetAt(RegExpMacroAssembler::kParamRegExpIndex, regexp);
  args.SetAt(RegExpMacroAssembler::kParamStringIndex, input);
  args.SetAt(RegExpMacroAssembler::kParamStartOffsetIndex, start_offset);

  // And finally call the generated code.

  const Object& retval =
      Object::Handle(zone, DartEntry::InvokeFunction(fun, args));
  if (retval.IsUnwindError()) {
    Exceptions::PropagateError(Error::Cast(retval));
  }
  if (retval.IsError()) {
    const Error& error = Error::Cast(retval);
    OS::PrintErr("%s\n", error.ToErrorCString());
    // Should never happen.
    UNREACHABLE();
  }

  if (retval.IsNull()) {
    return Array::null();
  }

  ASSERT(retval.IsArray());
  return Array::Cast(retval).raw();
}

LocalVariable* IRRegExpMacroAssembler::Parameter(const String& name,
                                                 intptr_t index) const {
  LocalVariable* local =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            name, Object::dynamic_type());

  intptr_t param_frame_index = kParamCount - index;
  local->set_index(VariableIndex(param_frame_index));

  return local;
}

LocalVariable* IRRegExpMacroAssembler::Local(const String& name) {
  LocalVariable* local =
      new (Z) LocalVariable(TokenPosition::kNoSource, TokenPosition::kNoSource,
                            name, Object::dynamic_type());
  local->set_index(VariableIndex(GetNextLocalIndex()));

  return local;
}

ConstantInstr* IRRegExpMacroAssembler::Int64Constant(int64_t value) const {
  return new (Z)
      ConstantInstr(Integer::ZoneHandle(Z, Integer::NewCanonical(value)));
}

ConstantInstr* IRRegExpMacroAssembler::Uint64Constant(uint64_t value) const {
  ASSERT(value < static_cast<uint64_t>(kMaxInt64));
  return Int64Constant(static_cast<int64_t>(value));
}

ConstantInstr* IRRegExpMacroAssembler::BoolConstant(bool value) const {
  return new (Z) ConstantInstr(value ? Bool::True() : Bool::False());
}

ConstantInstr* IRRegExpMacroAssembler::StringConstant(const char* value) const {
  return new (Z)
      ConstantInstr(String::ZoneHandle(Z, String::New(value, Heap::kOld)));
}

ConstantInstr* IRRegExpMacroAssembler::WordCharacterMapConstant() const {
  const Library& lib = Library::Handle(Z, Library::CoreLibrary());
  const Class& regexp_class =
      Class::Handle(Z, lib.LookupClassAllowPrivate(Symbols::_RegExp()));
  const Field& word_character_field = Field::ZoneHandle(
      Z,
      regexp_class.LookupStaticFieldAllowPrivate(Symbols::_wordCharacterMap()));
  ASSERT(!word_character_field.IsNull());

  DEBUG_ASSERT(Thread::Current()->TopErrorHandlerIsSetJump());
  if (word_character_field.IsUninitialized()) {
    ASSERT(!Compiler::IsBackgroundCompilation());
    const Error& error =
        Error::Handle(Z, word_character_field.InitializeStatic());
    if (!error.IsNull()) {
      Report::LongJump(error);
    }
  }
  ASSERT(!word_character_field.IsUninitialized());

  return new (Z) ConstantInstr(
      Instance::ZoneHandle(Z, word_character_field.StaticValue()));
}

ComparisonInstr* IRRegExpMacroAssembler::Comparison(ComparisonKind kind,
                                                    Value* lhs,
                                                    Value* rhs) {
  Token::Kind strict_comparison = Token::kEQ_STRICT;
  Token::Kind intermediate_operator = Token::kILLEGAL;
  switch (kind) {
    case kEQ:
      intermediate_operator = Token::kEQ;
      break;
    case kNE:
      intermediate_operator = Token::kEQ;
      strict_comparison = Token::kNE_STRICT;
      break;
    case kLT:
      intermediate_operator = Token::kLT;
      break;
    case kGT:
      intermediate_operator = Token::kGT;
      break;
    case kLTE:
      intermediate_operator = Token::kLTE;
      break;
    case kGTE:
      intermediate_operator = Token::kGTE;
      break;
    default:
      UNREACHABLE();
  }

  ASSERT(intermediate_operator != Token::kILLEGAL);

  Value* lhs_value = Bind(InstanceCall(
      InstanceCallDescriptor::FromToken(intermediate_operator), lhs, rhs));
  Value* rhs_value = Bind(BoolConstant(true));

  return new (Z)
      StrictCompareInstr(TokenPosition::kNoSource, strict_comparison, lhs_value,
                         rhs_value, true, GetNextDeoptId());
}

ComparisonInstr* IRRegExpMacroAssembler::Comparison(ComparisonKind kind,
                                                    Definition* lhs,
                                                    Definition* rhs) {
  Value* lhs_push = Bind(lhs);
  Value* rhs_push = Bind(rhs);
  return Comparison(kind, lhs_push, rhs_push);
}

StaticCallInstr* IRRegExpMacroAssembler::StaticCall(
    const Function& function,
    ICData::RebindRule rebind_rule) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 0);
  return StaticCall(function, arguments, rebind_rule);
}

StaticCallInstr* IRRegExpMacroAssembler::StaticCall(
    const Function& function,
    Value* arg1,
    ICData::RebindRule rebind_rule) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 1);
  arguments->Add(arg1);

  return StaticCall(function, arguments, rebind_rule);
}

StaticCallInstr* IRRegExpMacroAssembler::StaticCall(
    const Function& function,
    Value* arg1,
    Value* arg2,
    ICData::RebindRule rebind_rule) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 2);
  arguments->Add(arg1);
  arguments->Add(arg2);

  return StaticCall(function, arguments, rebind_rule);
}

StaticCallInstr* IRRegExpMacroAssembler::StaticCall(
    const Function& function,
    InputsArray* arguments,
    ICData::RebindRule rebind_rule) const {
  const intptr_t kTypeArgsLen = 0;
  return new (Z) StaticCallInstr(TokenPosition::kNoSource, function,
                                 kTypeArgsLen, Object::null_array(), arguments,
                                 ic_data_array_, GetNextDeoptId(), rebind_rule);
}

InstanceCallInstr* IRRegExpMacroAssembler::InstanceCall(
    const InstanceCallDescriptor& desc,
    Value* arg1) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 1);
  arguments->Add(arg1);

  return InstanceCall(desc, arguments);
}

InstanceCallInstr* IRRegExpMacroAssembler::InstanceCall(
    const InstanceCallDescriptor& desc,
    Value* arg1,
    Value* arg2) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 2);
  arguments->Add(arg1);
  arguments->Add(arg2);

  return InstanceCall(desc, arguments);
}

InstanceCallInstr* IRRegExpMacroAssembler::InstanceCall(
    const InstanceCallDescriptor& desc,
    Value* arg1,
    Value* arg2,
    Value* arg3) const {
  InputsArray* arguments = new (Z) InputsArray(Z, 3);
  arguments->Add(arg1);
  arguments->Add(arg2);
  arguments->Add(arg3);

  return InstanceCall(desc, arguments);
}

InstanceCallInstr* IRRegExpMacroAssembler::InstanceCall(
    const InstanceCallDescriptor& desc,
    InputsArray* arguments) const {
  const intptr_t kTypeArgsLen = 0;
  return new (Z) InstanceCallInstr(
      TokenPosition::kNoSource, desc.name, desc.token_kind, arguments,
      kTypeArgsLen, Object::null_array(), desc.checked_argument_count,
      ic_data_array_, GetNextDeoptId());
}

LoadLocalInstr* IRRegExpMacroAssembler::LoadLocal(LocalVariable* local) const {
  return new (Z) LoadLocalInstr(*local, TokenPosition::kNoSource);
}

void IRRegExpMacroAssembler::StoreLocal(LocalVariable* local, Value* value) {
  Do(new (Z) StoreLocalInstr(*local, value, TokenPosition::kNoSource));
}

void IRRegExpMacroAssembler::set_current_instruction(Instruction* instruction) {
  current_instruction_ = instruction;
}

Value* IRRegExpMacroAssembler::Bind(Definition* definition) {
  AppendInstruction(definition);
  definition->set_temp_index(temp_id_.Alloc());

  return new (Z) Value(definition);
}

void IRRegExpMacroAssembler::Do(Definition* definition) {
  AppendInstruction(definition);
}

Value* IRRegExpMacroAssembler::BindLoadLocal(const LocalVariable& local) {
  if (local.IsConst()) {
    return Bind(new (Z) ConstantInstr(*local.ConstValue()));
  }
  ASSERT(!local.is_captured());
  return Bind(new (Z) LoadLocalInstr(local, TokenPosition::kNoSource));
}

// In some cases, the V8 irregexp engine generates unreachable code by emitting
// a jmp not followed by a bind. We cannot do the same, since it is impossible
// to append to a block following a jmp. In such cases, assume that we are doing
// the correct thing, but output a warning when tracing.
#define HANDLE_DEAD_CODE_EMISSION()                                            \
  if (current_instruction_ == NULL) {                                          \
    if (FLAG_trace_irregexp) {                                                 \
      OS::PrintErr(                                                            \
          "WARNING: Attempting to append to a closed assembler. "              \
          "This could be either a bug or generation of dead code "             \
          "inherited from V8.\n");                                             \
    }                                                                          \
    BlockLabel dummy;                                                          \
    BindBlock(&dummy);                                                         \
  }

void IRRegExpMacroAssembler::AppendInstruction(Instruction* instruction) {
  HANDLE_DEAD_CODE_EMISSION();

  ASSERT(current_instruction_ != NULL);
  ASSERT(current_instruction_->next() == NULL);

  temp_id_.Dealloc(instruction->InputCount());

  current_instruction_->LinkTo(instruction);
  set_current_instruction(instruction);
}

void IRRegExpMacroAssembler::CloseBlockWith(Instruction* instruction) {
  HANDLE_DEAD_CODE_EMISSION();

  ASSERT(current_instruction_ != NULL);
  ASSERT(current_instruction_->next() == NULL);

  temp_id_.Dealloc(instruction->InputCount());

  current_instruction_->LinkTo(instruction);
  set_current_instruction(NULL);
}

void IRRegExpMacroAssembler::GoTo(BlockLabel* to) {
  if (to == NULL) {
    Backtrack();
  } else {
    to->SetLinked();
    GoTo(to->block());
  }
}

// Closes the current block with a goto, and unsets current_instruction_.
// BindBlock() must be called before emission can continue.
void IRRegExpMacroAssembler::GoTo(JoinEntryInstr* to) {
  HANDLE_DEAD_CODE_EMISSION();

  ASSERT(current_instruction_ != NULL);
  ASSERT(current_instruction_->next() == NULL);
  current_instruction_->Goto(to);
  set_current_instruction(NULL);
}

Value* IRRegExpMacroAssembler::PushLocal(LocalVariable* local) {
  return Bind(LoadLocal(local));
}

void IRRegExpMacroAssembler::Print(const char* str) {
  Print(Bind(new (Z) ConstantInstr(
      String::ZoneHandle(Z, String::New(str, Heap::kOld)))));
}

void IRRegExpMacroAssembler::Print(Value* argument) {
  const Library& lib = Library::Handle(Library::CoreLibrary());
  const Function& print_fn =
      Function::ZoneHandle(Z, lib.LookupFunctionAllowPrivate(Symbols::print()));
  Do(StaticCall(print_fn, argument, ICData::kStatic));
}

void IRRegExpMacroAssembler::PrintBlocks() {
  for (intptr_t i = 0; i < blocks_.length(); i++) {
    FlowGraphPrinter::PrintBlock(blocks_[i], false);
  }
}

intptr_t IRRegExpMacroAssembler::stack_limit_slack() {
  return 32;
}

void IRRegExpMacroAssembler::AdvanceCurrentPosition(intptr_t by) {
  TAG();
  if (by != 0) {
    Value* cur_pos_push = PushLocal(current_position_);
    Value* by_push = Bind(Int64Constant(by));

    Value* new_pos_value = Bind(Add(cur_pos_push, by_push));
    StoreLocal(current_position_, new_pos_value);
  }
}

void IRRegExpMacroAssembler::AdvanceRegister(intptr_t reg, intptr_t by) {
  TAG();
  ASSERT(reg >= 0);
  ASSERT(reg < registers_count_);

  if (by != 0) {
    Value* registers_push = PushLocal(registers_);
    Value* index_push = PushRegisterIndex(reg);
    Value* reg_push = LoadRegister(reg);
    Value* by_push = Bind(Int64Constant(by));
    Value* value_push = Bind(Add(reg_push, by_push));
    StoreRegister(registers_push, index_push, value_push);
  }
}

void IRRegExpMacroAssembler::Backtrack() {
  TAG();
  GoTo(backtrack_block_);
}

// A BindBlock is analogous to assigning a label to a basic block.
// If the BlockLabel does not yet contain a block, it is created.
// If there is a current instruction, append a goto to the bound block.
void IRRegExpMacroAssembler::BindBlock(BlockLabel* label) {
  ASSERT(!label->is_bound());
  ASSERT(label->block()->next() == NULL);

  label->BindTo(block_id_.Alloc());
  blocks_.Add(label->block());

  if (current_instruction_ != NULL) {
    GoTo(label);
  }
  set_current_instruction(label->block());

  // Print the id of the current block if tracing.
  PRINT(Bind(Uint64Constant(label->block()->block_id())));
}

intptr_t IRRegExpMacroAssembler::GetNextLocalIndex() {
  intptr_t id = local_id_.Alloc();
  return -id;
}

Value* IRRegExpMacroAssembler::LoadRegister(intptr_t index) {
  Value* registers_push = PushLocal(registers_);
  Value* index_push = PushRegisterIndex(index);
  return Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                           registers_push, index_push));
}

void IRRegExpMacroAssembler::StoreRegister(intptr_t index, intptr_t value) {
  Value* registers_push = PushLocal(registers_);
  Value* index_push = PushRegisterIndex(index);
  Value* value_push = Bind(Uint64Constant(value));
  StoreRegister(registers_push, index_push, value_push);
}

void IRRegExpMacroAssembler::StoreRegister(Value* registers,
                                           Value* index,
                                           Value* value) {
  TAG();
  Do(InstanceCall(InstanceCallDescriptor::FromToken(Token::kASSIGN_INDEX),
                  registers, index, value));
}

Value* IRRegExpMacroAssembler::PushRegisterIndex(intptr_t index) {
  if (registers_count_ <= index) {
    registers_count_ = index + 1;
  }
  return Bind(Uint64Constant(index));
}

void IRRegExpMacroAssembler::CheckCharacter(uint32_t c, BlockLabel* on_equal) {
  TAG();
  Definition* cur_char_def = LoadLocal(current_character_);
  Definition* char_def = Uint64Constant(c);

  BranchOrBacktrack(Comparison(kEQ, cur_char_def, char_def), on_equal);
}

void IRRegExpMacroAssembler::CheckCharacterGT(uint16_t limit,
                                              BlockLabel* on_greater) {
  TAG();
  BranchOrBacktrack(
      Comparison(kGT, LoadLocal(current_character_), Uint64Constant(limit)),
      on_greater);
}

void IRRegExpMacroAssembler::CheckAtStart(BlockLabel* on_at_start) {
  TAG();

  // Are we at the start of the input, i.e. is (offset == string_length * -1)?
  Definition* neg_len_def =
      InstanceCall(InstanceCallDescriptor::FromToken(Token::kNEGATE),
                   PushLocal(string_param_length_));
  Definition* offset_def = LoadLocal(current_position_);
  BranchOrBacktrack(Comparison(kEQ, neg_len_def, offset_def), on_at_start);
}

// cp_offset => offset from the current (character) pointer
// This offset may be negative due to traversing backwards during lookbehind.
void IRRegExpMacroAssembler::CheckNotAtStart(intptr_t cp_offset,
                                             BlockLabel* on_not_at_start) {
  TAG();

  // Are we at the start of the input, i.e. is (offset == string_length * -1)?
  auto neg_len_def =
      Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kNEGATE),
                        PushLocal(string_param_length_)));
  auto current_pos_def = PushLocal(current_position_);
  auto cp_offset_def = Bind(Int64Constant(cp_offset));
  auto offset_def = Bind(Add(current_pos_def, cp_offset_def));
  BranchOrBacktrack(Comparison(kNE, neg_len_def, offset_def), on_not_at_start);
}

void IRRegExpMacroAssembler::CheckCharacterLT(uint16_t limit,
                                              BlockLabel* on_less) {
  TAG();
  BranchOrBacktrack(
      Comparison(kLT, LoadLocal(current_character_), Uint64Constant(limit)),
      on_less);
}

void IRRegExpMacroAssembler::CheckGreedyLoop(BlockLabel* on_equal) {
  TAG();

  BlockLabel fallthrough;

  Definition* head = PeekStack();
  Definition* cur_pos_def = LoadLocal(current_position_);
  BranchOrBacktrack(Comparison(kNE, head, cur_pos_def), &fallthrough);

  // Pop, throwing away the value.
  Do(PopStack());

  BranchOrBacktrack(NULL, on_equal);

  BindBlock(&fallthrough);
}

void IRRegExpMacroAssembler::CheckNotBackReferenceIgnoreCase(
    intptr_t start_reg,
    bool read_backward,
    bool unicode,
    BlockLabel* on_no_match) {
  TAG();
  ASSERT(start_reg + 1 <= registers_count_);

  BlockLabel fallthrough;

  Value* end_push = LoadRegister(start_reg + 1);
  Value* start_push = LoadRegister(start_reg);
  StoreLocal(capture_length_, Bind(Sub(end_push, start_push)));

  // The length of a capture should not be negative. This can only happen
  // if the end of the capture is unrecorded, or at a point earlier than
  // the start of the capture.
  // BranchOrBacktrack(less, on_no_match);

  BranchOrBacktrack(
      Comparison(kLT, LoadLocal(capture_length_), Uint64Constant(0)),
      on_no_match);

  // If length is zero, either the capture is empty or it is completely
  // uncaptured. In either case succeed immediately.
  BranchOrBacktrack(
      Comparison(kEQ, LoadLocal(capture_length_), Uint64Constant(0)),
      &fallthrough);

  Value* pos_push = nullptr;
  Value* len_push = nullptr;

  if (!read_backward) {
    // Check that there are sufficient characters left in the input.
    pos_push = PushLocal(current_position_);
    len_push = PushLocal(capture_length_);
    BranchOrBacktrack(
        Comparison(kGT,
                   InstanceCall(InstanceCallDescriptor::FromToken(Token::kADD),
                                pos_push, len_push),
                   Uint64Constant(0)),
        on_no_match);
  }

  pos_push = PushLocal(current_position_);
  len_push = PushLocal(string_param_length_);
  StoreLocal(match_start_index_, Bind(Add(pos_push, len_push)));

  if (read_backward) {
    // First check that there are enough characters before this point in
    // the string that we can match the backreference.
    BranchOrBacktrack(Comparison(kLT, LoadLocal(match_start_index_),
                                 LoadLocal(capture_length_)),
                      on_no_match);

    // The string to check is before the current position, not at it.
    pos_push = PushLocal(match_start_index_);
    len_push = PushLocal(capture_length_);
    StoreLocal(match_start_index_, Bind(Sub(pos_push, len_push)));
  }

  pos_push = LoadRegister(start_reg);
  len_push = PushLocal(string_param_length_);
  StoreLocal(capture_start_index_, Bind(Add(pos_push, len_push)));

  pos_push = PushLocal(match_start_index_);
  len_push = PushLocal(capture_length_);
  StoreLocal(match_end_index_, Bind(Add(pos_push, len_push)));

  BlockLabel success;
  if (mode_ == ASCII) {
    BlockLabel loop_increment;
    BlockLabel loop;
    BindBlock(&loop);

    StoreLocal(char_in_capture_, CharacterAt(capture_start_index_));
    StoreLocal(char_in_match_, CharacterAt(match_start_index_));

    BranchOrBacktrack(
        Comparison(kEQ, LoadLocal(char_in_capture_), LoadLocal(char_in_match_)),
        &loop_increment);

    // Mismatch, try case-insensitive match (converting letters to lower-case).
    Value* match_char_push = PushLocal(char_in_match_);
    Value* mask_push = Bind(Uint64Constant(0x20));
    StoreLocal(
        char_in_match_,
        Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_OR),
                          match_char_push, mask_push)));

    BlockLabel convert_capture;
    BlockLabel on_not_in_range;
    BranchOrBacktrack(
        Comparison(kLT, LoadLocal(char_in_match_), Uint64Constant('a')),
        &on_not_in_range);
    BranchOrBacktrack(
        Comparison(kGT, LoadLocal(char_in_match_), Uint64Constant('z')),
        &on_not_in_range);
    GoTo(&convert_capture);
    BindBlock(&on_not_in_range);

    // Latin-1: Check for values in range [224,254] but not 247.
    BranchOrBacktrack(
        Comparison(kLT, LoadLocal(char_in_match_), Uint64Constant(224)),
        on_no_match);
    BranchOrBacktrack(
        Comparison(kGT, LoadLocal(char_in_match_), Uint64Constant(254)),
        on_no_match);

    BranchOrBacktrack(
        Comparison(kEQ, LoadLocal(char_in_match_), Uint64Constant(247)),
        on_no_match);

    // Also convert capture character.
    BindBlock(&convert_capture);

    Value* capture_char_push = PushLocal(char_in_capture_);
    mask_push = Bind(Uint64Constant(0x20));
    StoreLocal(
        char_in_capture_,
        Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_OR),
                          capture_char_push, mask_push)));

    BranchOrBacktrack(
        Comparison(kNE, LoadLocal(char_in_match_), LoadLocal(char_in_capture_)),
        on_no_match);

    BindBlock(&loop_increment);

    // Increment indexes into capture and match strings.
    Value* index_push = PushLocal(capture_start_index_);
    Value* inc_push = Bind(Uint64Constant(1));
    StoreLocal(capture_start_index_, Bind(Add(index_push, inc_push)));

    index_push = PushLocal(match_start_index_);
    inc_push = Bind(Uint64Constant(1));
    StoreLocal(match_start_index_, Bind(Add(index_push, inc_push)));

    // Compare to end of match, and loop if not done.
    BranchOrBacktrack(Comparison(kLT, LoadLocal(match_start_index_),
                                 LoadLocal(match_end_index_)),
                      &loop);
  } else {
    ASSERT(mode_ == UC16);

    Value* string_value = Bind(LoadLocal(string_param_));
    Value* lhs_index_value = Bind(LoadLocal(match_start_index_));
    Value* rhs_index_value = Bind(LoadLocal(capture_start_index_));
    Value* length_value = Bind(LoadLocal(capture_length_));

    Definition* is_match_def;

    if (unicode) {
      is_match_def = new (Z) CaseInsensitiveCompareInstr(
          string_value, lhs_index_value, rhs_index_value, length_value,
          kCaseInsensitiveCompareUTF16RuntimeEntry, specialization_cid_);
    } else {
      is_match_def = new (Z) CaseInsensitiveCompareInstr(
          string_value, lhs_index_value, rhs_index_value, length_value,
          kCaseInsensitiveCompareUCS2RuntimeEntry, specialization_cid_);
    }

    BranchOrBacktrack(Comparison(kNE, is_match_def, BoolConstant(true)),
                      on_no_match);
  }

  BindBlock(&success);

  if (read_backward) {
    // Move current character position to start of match.
    pos_push = PushLocal(current_position_);
    len_push = PushLocal(capture_length_);
    StoreLocal(current_position_, Bind(Sub(pos_push, len_push)));
  } else {
    // Move current character position to position after match.
    Value* match_end_push = PushLocal(match_end_index_);
    len_push = PushLocal(string_param_length_);
    StoreLocal(current_position_, Bind(Sub(match_end_push, len_push)));
  }

  BindBlock(&fallthrough);
}

void IRRegExpMacroAssembler::CheckNotBackReference(intptr_t start_reg,
                                                   bool read_backward,
                                                   BlockLabel* on_no_match) {
  TAG();
  ASSERT(start_reg + 1 <= registers_count_);

  BlockLabel fallthrough;
  BlockLabel success;

  // Find length of back-referenced capture.
  Value* end_push = LoadRegister(start_reg + 1);
  Value* start_push = LoadRegister(start_reg);
  StoreLocal(capture_length_, Bind(Sub(end_push, start_push)));

  // Fail on partial or illegal capture (start of capture after end of capture).
  BranchOrBacktrack(
      Comparison(kLT, LoadLocal(capture_length_), Uint64Constant(0)),
      on_no_match);

  // Succeed on empty capture (including no capture)
  BranchOrBacktrack(
      Comparison(kEQ, LoadLocal(capture_length_), Uint64Constant(0)),
      &fallthrough);

  Value* pos_push = nullptr;
  Value* len_push = nullptr;

  if (!read_backward) {
    // Check that there are sufficient characters left in the input.
    pos_push = PushLocal(current_position_);
    len_push = PushLocal(capture_length_);
    BranchOrBacktrack(
        Comparison(kGT,
                   InstanceCall(InstanceCallDescriptor::FromToken(Token::kADD),
                                pos_push, len_push),
                   Uint64Constant(0)),
        on_no_match);
  }

  // Compute pointers to match string and capture string.
  pos_push = PushLocal(current_position_);
  len_push = PushLocal(string_param_length_);
  StoreLocal(match_start_index_, Bind(Add(pos_push, len_push)));

  if (read_backward) {
    // First check that there are enough characters before this point in
    // the string that we can match the backreference.
    BranchOrBacktrack(Comparison(kLT, LoadLocal(match_start_index_),
                                 LoadLocal(capture_length_)),
                      on_no_match);

    // The string to check is before the current position, not at it.
    pos_push = PushLocal(match_start_index_);
    len_push = PushLocal(capture_length_);
    StoreLocal(match_start_index_, Bind(Sub(pos_push, len_push)));
  }

  pos_push = LoadRegister(start_reg);
  len_push = PushLocal(string_param_length_);
  StoreLocal(capture_start_index_, Bind(Add(pos_push, len_push)));

  pos_push = PushLocal(match_start_index_);
  len_push = PushLocal(capture_length_);
  StoreLocal(match_end_index_, Bind(Add(pos_push, len_push)));

  BlockLabel loop;
  BindBlock(&loop);

  StoreLocal(char_in_capture_, CharacterAt(capture_start_index_));
  StoreLocal(char_in_match_, CharacterAt(match_start_index_));

  BranchOrBacktrack(
      Comparison(kNE, LoadLocal(char_in_capture_), LoadLocal(char_in_match_)),
      on_no_match);

  // Increment indexes into capture and match strings.
  Value* index_push = PushLocal(capture_start_index_);
  Value* inc_push = Bind(Uint64Constant(1));
  StoreLocal(capture_start_index_, Bind(Add(index_push, inc_push)));

  index_push = PushLocal(match_start_index_);
  inc_push = Bind(Uint64Constant(1));
  StoreLocal(match_start_index_, Bind(Add(index_push, inc_push)));

  // Check if we have reached end of match area.
  BranchOrBacktrack(Comparison(kLT, LoadLocal(match_start_index_),
                               LoadLocal(match_end_index_)),
                    &loop);

  BindBlock(&success);

  if (read_backward) {
    // Move current character position to start of match.
    pos_push = PushLocal(current_position_);
    len_push = PushLocal(capture_length_);
    StoreLocal(current_position_, Bind(Sub(pos_push, len_push)));
  } else {
    // Move current character position to position after match.
    Value* match_end_push = PushLocal(match_end_index_);
    len_push = PushLocal(string_param_length_);
    StoreLocal(current_position_, Bind(Sub(match_end_push, len_push)));
  }

  BindBlock(&fallthrough);
}

void IRRegExpMacroAssembler::CheckNotCharacter(uint32_t c,
                                               BlockLabel* on_not_equal) {
  TAG();
  BranchOrBacktrack(
      Comparison(kNE, LoadLocal(current_character_), Uint64Constant(c)),
      on_not_equal);
}

void IRRegExpMacroAssembler::CheckCharacterAfterAnd(uint32_t c,
                                                    uint32_t mask,
                                                    BlockLabel* on_equal) {
  TAG();

  Definition* actual_def = LoadLocal(current_character_);

  Value* actual_push = Bind(actual_def);
  Value* mask_push = Bind(Uint64Constant(mask));
  actual_def = InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_AND),
                            actual_push, mask_push);
  Definition* expected_def = Uint64Constant(c);

  BranchOrBacktrack(Comparison(kEQ, actual_def, expected_def), on_equal);
}

void IRRegExpMacroAssembler::CheckNotCharacterAfterAnd(
    uint32_t c,
    uint32_t mask,
    BlockLabel* on_not_equal) {
  TAG();

  Definition* actual_def = LoadLocal(current_character_);

  Value* actual_push = Bind(actual_def);
  Value* mask_push = Bind(Uint64Constant(mask));
  actual_def = InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_AND),
                            actual_push, mask_push);
  Definition* expected_def = Uint64Constant(c);

  BranchOrBacktrack(Comparison(kNE, actual_def, expected_def), on_not_equal);
}

void IRRegExpMacroAssembler::CheckNotCharacterAfterMinusAnd(
    uint16_t c,
    uint16_t minus,
    uint16_t mask,
    BlockLabel* on_not_equal) {
  TAG();
  ASSERT(minus < Utf16::kMaxCodeUnit);  // NOLINT

  Definition* actual_def = LoadLocal(current_character_);

  Value* actual_push = Bind(actual_def);
  Value* minus_push = Bind(Uint64Constant(minus));

  actual_push = Bind(Sub(actual_push, minus_push));
  Value* mask_push = Bind(Uint64Constant(mask));
  actual_def = InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_AND),
                            actual_push, mask_push);
  Definition* expected_def = Uint64Constant(c);

  BranchOrBacktrack(Comparison(kNE, actual_def, expected_def), on_not_equal);
}

void IRRegExpMacroAssembler::CheckCharacterInRange(uint16_t from,
                                                   uint16_t to,
                                                   BlockLabel* on_in_range) {
  TAG();
  ASSERT(from <= to);

  // TODO(zerny): All range comparisons could be done cheaper with unsigned
  // compares. This pattern repeats in various places.

  BlockLabel on_not_in_range;
  BranchOrBacktrack(
      Comparison(kLT, LoadLocal(current_character_), Uint64Constant(from)),
      &on_not_in_range);
  BranchOrBacktrack(
      Comparison(kGT, LoadLocal(current_character_), Uint64Constant(to)),
      &on_not_in_range);
  BranchOrBacktrack(NULL, on_in_range);

  BindBlock(&on_not_in_range);
}

void IRRegExpMacroAssembler::CheckCharacterNotInRange(
    uint16_t from,
    uint16_t to,
    BlockLabel* on_not_in_range) {
  TAG();
  ASSERT(from <= to);

  BranchOrBacktrack(
      Comparison(kLT, LoadLocal(current_character_), Uint64Constant(from)),
      on_not_in_range);

  BranchOrBacktrack(
      Comparison(kGT, LoadLocal(current_character_), Uint64Constant(to)),
      on_not_in_range);
}

void IRRegExpMacroAssembler::CheckBitInTable(const TypedData& table,
                                             BlockLabel* on_bit_set) {
  TAG();

  Value* table_push = Bind(new (Z) ConstantInstr(table));
  Value* index_push = PushLocal(current_character_);

  if (mode_ != ASCII || kTableMask != Symbols::kMaxOneCharCodeSymbol) {
    Value* mask_push = Bind(Uint64Constant(kTableSize - 1));
    index_push =
        Bind(InstanceCall(InstanceCallDescriptor::FromToken(Token::kBIT_AND),
                          index_push, mask_push));
  }

  Definition* byte_def = InstanceCall(
      InstanceCallDescriptor::FromToken(Token::kINDEX), table_push, index_push);
  Definition* zero_def = Int64Constant(0);

  BranchOrBacktrack(Comparison(kNE, byte_def, zero_def), on_bit_set);
}

bool IRRegExpMacroAssembler::CheckSpecialCharacterClass(
    uint16_t type,
    BlockLabel* on_no_match) {
  TAG();

  // Range checks (c in min..max) are generally implemented by an unsigned
  // (c - min) <= (max - min) check
  switch (type) {
    case 's':
      // Match space-characters
      if (mode_ == ASCII) {
        // One byte space characters are '\t'..'\r', ' ' and \u00a0.
        BlockLabel success;
        // Space (' ').
        BranchOrBacktrack(
            Comparison(kEQ, LoadLocal(current_character_), Uint64Constant(' ')),
            &success);
        // Check range 0x09..0x0d.
        CheckCharacterInRange('\t', '\r', &success);
        // \u00a0 (NBSP).
        BranchOrBacktrack(Comparison(kNE, LoadLocal(current_character_),
                                     Uint64Constant(0x00a0)),
                          on_no_match);
        BindBlock(&success);
        return true;
      }
      return false;
    case 'S':
      // The emitted code for generic character classes is good enough.
      return false;
    case 'd':
      // Match ASCII digits ('0'..'9')
      CheckCharacterNotInRange('0', '9', on_no_match);
      return true;
    case 'D':
      // Match non ASCII-digits
      CheckCharacterInRange('0', '9', on_no_match);
      return true;
    case '.': {
      // Match non-newlines (not 0x0a('\n'), 0x0d('\r'), 0x2028 and 0x2029)
      BranchOrBacktrack(
          Comparison(kEQ, LoadLocal(current_character_), Uint64Constant('\n')),
          on_no_match);
      BranchOrBacktrack(
          Comparison(kEQ, LoadLocal(current_character_), Uint64Constant('\r')),
          on_no_match);
      if (mode_ == UC16) {
        BranchOrBacktrack(Comparison(kEQ, LoadLocal(current_character_),
                                     Uint64Constant(0x2028)),
                          on_no_match);
        BranchOrBacktrack(Comparison(kEQ, LoadLocal(current_character_),
                                     Uint64Constant(0x2029)),
                          on_no_match);
      }
      return true;
    }
    case 'w': {
      if (mode_ != ASCII) {
        // Table is 128 entries, so all ASCII characters can be tested.
        BranchOrBacktrack(
            Comparison(kGT, LoadLocal(current_character_), Uint64Constant('z')),
            on_no_match);
      }

      Value* table_push = Bind(WordCharacterMapConstant());
      Value* index_push = PushLocal(current_character_);

      Definition* byte_def =
          InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                       table_push, index_push);
      Definition* zero_def = Int64Constant(0);

      BranchOrBacktrack(Comparison(kEQ, byte_def, zero_def), on_no_match);

      return true;
    }
    case 'W': {
      BlockLabel done;
      if (mode_ != ASCII) {
        // Table is 128 entries, so all ASCII characters can be tested.
        BranchOrBacktrack(
            Comparison(kGT, LoadLocal(current_character_), Uint64Constant('z')),
            &done);
      }

      // TODO(zerny): Refactor to use CheckBitInTable if possible.

      Value* table_push = Bind(WordCharacterMapConstant());
      Value* index_push = PushLocal(current_character_);

      Definition* byte_def =
          InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                       table_push, index_push);
      Definition* zero_def = Int64Constant(0);

      BranchOrBacktrack(Comparison(kNE, byte_def, zero_def), on_no_match);

      if (mode_ != ASCII) {
        BindBlock(&done);
      }
      return true;
    }
    // Non-standard classes (with no syntactic shorthand) used internally.
    case '*':
      // Match any character.
      return true;
    case 'n': {
      // Match newlines (0x0a('\n'), 0x0d('\r'), 0x2028 or 0x2029).
      // The opposite of '.'.
      BlockLabel success;
      BranchOrBacktrack(
          Comparison(kEQ, LoadLocal(current_character_), Uint64Constant('\n')),
          &success);
      BranchOrBacktrack(
          Comparison(kEQ, LoadLocal(current_character_), Uint64Constant('\r')),
          &success);
      if (mode_ == UC16) {
        BranchOrBacktrack(Comparison(kEQ, LoadLocal(current_character_),
                                     Uint64Constant(0x2028)),
                          &success);
        BranchOrBacktrack(Comparison(kEQ, LoadLocal(current_character_),
                                     Uint64Constant(0x2029)),
                          &success);
      }
      BranchOrBacktrack(NULL, on_no_match);
      BindBlock(&success);
      return true;
    }
    // No custom implementation (yet): s(uint16_t), S(uint16_t).
    default:
      return false;
  }
}

void IRRegExpMacroAssembler::Fail() {
  TAG();
  ASSERT(FAILURE == 0);  // Return value for failure is zero.
  if (!global()) {
    UNREACHABLE();  // Dart regexps are always global.
  }
  GoTo(exit_block_);
}

void IRRegExpMacroAssembler::IfRegisterGE(intptr_t reg,
                                          intptr_t comparand,
                                          BlockLabel* if_ge) {
  TAG();
  Value* reg_push = LoadRegister(reg);
  Value* pos = Bind(Int64Constant(comparand));
  BranchOrBacktrack(Comparison(kGTE, reg_push, pos), if_ge);
}

void IRRegExpMacroAssembler::IfRegisterLT(intptr_t reg,
                                          intptr_t comparand,
                                          BlockLabel* if_lt) {
  TAG();
  Value* reg_push = LoadRegister(reg);
  Value* pos = Bind(Int64Constant(comparand));
  BranchOrBacktrack(Comparison(kLT, reg_push, pos), if_lt);
}

void IRRegExpMacroAssembler::IfRegisterEqPos(intptr_t reg, BlockLabel* if_eq) {
  TAG();
  Value* reg_push = LoadRegister(reg);
  Value* pos = Bind(LoadLocal(current_position_));
  BranchOrBacktrack(Comparison(kEQ, reg_push, pos), if_eq);
}

RegExpMacroAssembler::IrregexpImplementation
IRRegExpMacroAssembler::Implementation() {
  return kIRImplementation;
}

void IRRegExpMacroAssembler::LoadCurrentCharacter(intptr_t cp_offset,
                                                  BlockLabel* on_end_of_input,
                                                  bool check_bounds,
                                                  intptr_t characters) {
  TAG();
  ASSERT(cp_offset < (1 << 30));  // Be sane! (And ensure negation works)
  if (check_bounds) {
    if (cp_offset >= 0) {
      CheckPosition(cp_offset + characters - 1, on_end_of_input);
    } else {
      CheckPosition(cp_offset, on_end_of_input);
    }
  }
  LoadCurrentCharacterUnchecked(cp_offset, characters);
}

void IRRegExpMacroAssembler::PopCurrentPosition() {
  TAG();
  StoreLocal(current_position_, Bind(PopStack()));
}

void IRRegExpMacroAssembler::PopRegister(intptr_t reg) {
  TAG();
  ASSERT(reg < registers_count_);
  Value* registers_push = PushLocal(registers_);
  Value* index_push = PushRegisterIndex(reg);
  Value* pop_push = Bind(PopStack());
  StoreRegister(registers_push, index_push, pop_push);
}

void IRRegExpMacroAssembler::PushStack(Definition* definition) {
  Value* stack_push = PushLocal(stack_);
  Value* stack_pointer_push = PushLocal(stack_pointer_);
  StoreLocal(stack_pointer_,
             Bind(Add(stack_pointer_push, Bind(Uint64Constant(1)))));
  stack_pointer_push = PushLocal(stack_pointer_);
  // TODO(zerny): bind value and push could break stack discipline.
  Value* value_push = Bind(definition);
  Do(InstanceCall(InstanceCallDescriptor::FromToken(Token::kASSIGN_INDEX),
                  stack_push, stack_pointer_push, value_push));
}

Definition* IRRegExpMacroAssembler::PopStack() {
  Value* stack_push = PushLocal(stack_);
  Value* stack_pointer_push1 = PushLocal(stack_pointer_);
  Value* stack_pointer_push2 = PushLocal(stack_pointer_);
  StoreLocal(stack_pointer_,
             Bind(Sub(stack_pointer_push2, Bind(Uint64Constant(1)))));
  return InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                      stack_push, stack_pointer_push1);
}

Definition* IRRegExpMacroAssembler::PeekStack() {
  Value* stack_push = PushLocal(stack_);
  Value* stack_pointer_push = PushLocal(stack_pointer_);
  return InstanceCall(InstanceCallDescriptor::FromToken(Token::kINDEX),
                      stack_push, stack_pointer_push);
}

// Pushes the location corresponding to label to the backtracking stack.
void IRRegExpMacroAssembler::PushBacktrack(BlockLabel* label) {
  TAG();

  // Ensure that targets of indirect jumps are never accessed through a
  // normal control flow instructions by creating a new block for each backtrack
  // target.
  IndirectEntryInstr* indirect_target = IndirectWithJoinGoto(label->block());

  // Add a fake edge from the graph entry for data flow analysis.
  entry_block_->AddIndirectEntry(indirect_target);

  ConstantInstr* offset = Uint64Constant(indirect_target->indirect_id());
  PushStack(offset);
  CheckStackLimit();
}

void IRRegExpMacroAssembler::PushCurrentPosition() {
  TAG();
  PushStack(LoadLocal(current_position_));
}

void IRRegExpMacroAssembler::PushRegister(intptr_t reg) {
  TAG();
  // TODO(zerny): Refactor PushStack so it can be reused here.
  Value* stack_push = PushLocal(stack_);
  Value* stack_pointer_push = PushLocal(stack_pointer_);
  StoreLocal(stack_pointer_,
             Bind(Add(stack_pointer_push, Bind(Uint64Constant(1)))));
  stack_pointer_push = PushLocal(stack_pointer_);
  // TODO(zerny): bind value and push could break stack discipline.
  Value* value_push = LoadRegister(reg);
  Do(InstanceCall(InstanceCallDescriptor::FromToken(Token::kASSIGN_INDEX),
                  stack_push, stack_pointer_push, value_push));
  CheckStackLimit();
}

// Checks that (stack.capacity - stack_limit_slack) > stack_pointer.
// This ensures that up to stack_limit_slack stack pushes can be
// done without exhausting the stack space. If the check fails the
// stack will be grown.
void IRRegExpMacroAssembler::CheckStackLimit() {
  TAG();
  Value* stack_push = PushLocal(stack_);
  Value* length_push =
      Bind(InstanceCall(InstanceCallDescriptor(String::ZoneHandle(
                            Field::GetterSymbol(Symbols::Length()))),
                        stack_push));
  Value* capacity_push =
      Bind(Sub(length_push, Bind(Uint64Constant(stack_limit_slack()))));
  Value* stack_pointer_push = PushLocal(stack_pointer_);
  BranchInstr* branch = new (Z) BranchInstr(
      Comparison(kGT, capacity_push, stack_pointer_push), GetNextDeoptId());
  CloseBlockWith(branch);

  BlockLabel grow_stack;
  BlockLabel fallthrough;
  *branch->true_successor_address() = TargetWithJoinGoto(fallthrough.block());
  *branch->false_successor_address() = TargetWithJoinGoto(grow_stack.block());

  BindBlock(&grow_stack);
  GrowStack();

  BindBlock(&fallthrough);
}

void IRRegExpMacroAssembler::GrowStack() {
  TAG();
  const Library& lib = Library::Handle(Library::InternalLibrary());
  const Function& grow_function = Function::ZoneHandle(
      Z, lib.LookupFunctionAllowPrivate(Symbols::GrowRegExpStack()));
  StoreLocal(stack_, Bind(StaticCall(grow_function, PushLocal(stack_),
                                     ICData::kStatic)));

  // Note: :stack and stack_array_cell content might diverge because each
  // instance of :matcher code has its own stack_array_cell embedded into it
  // as a constant but :stack is a local variable and its value might be
  // comming from OSR or deoptimization. This means we should never use
  // stack_array_cell in the body of the :matcher to reload the :stack.
  Value* stack_cell_push = Bind(new (Z) ConstantInstr(stack_array_cell_));
  Value* index_push = Bind(Uint64Constant(0));
  Value* stack_push = PushLocal(stack_);
  Do(InstanceCall(InstanceCallDescriptor::FromToken(Token::kASSIGN_INDEX),
                  stack_cell_push, index_push, stack_push));
}

void IRRegExpMacroAssembler::ReadCurrentPositionFromRegister(intptr_t reg) {
  TAG();
  StoreLocal(current_position_, LoadRegister(reg));
}

// Resets the tip of the stack to the value stored in reg.
void IRRegExpMacroAssembler::ReadStackPointerFromRegister(intptr_t reg) {
  TAG();
  ASSERT(reg < registers_count_);
  StoreLocal(stack_pointer_, LoadRegister(reg));
}

void IRRegExpMacroAssembler::SetCurrentPositionFromEnd(intptr_t by) {
  TAG();

  BlockLabel after_position;

  Definition* cur_pos_def = LoadLocal(current_position_);
  Definition* by_value_def = Int64Constant(-by);

  BranchOrBacktrack(Comparison(kGTE, cur_pos_def, by_value_def),
                    &after_position);

  StoreLocal(current_position_, Bind(Int64Constant(-by)));

  // On RegExp code entry (where this operation is used), the character before
  // the current position is expected to be already loaded.
  // We have advanced the position, so it's safe to read backwards.
  LoadCurrentCharacterUnchecked(-1, 1);

  BindBlock(&after_position);
}

void IRRegExpMacroAssembler::SetRegister(intptr_t reg, intptr_t to) {
  TAG();
  // Reserved for positions!
  ASSERT(reg >= saved_registers_count_);
  StoreRegister(reg, to);
}

bool IRRegExpMacroAssembler::Succeed() {
  TAG();
  GoTo(success_block_);
  return global();
}

void IRRegExpMacroAssembler::WriteCurrentPositionToRegister(
    intptr_t reg,
    intptr_t cp_offset) {
  TAG();

  Value* registers_push = PushLocal(registers_);
  Value* index_push = PushRegisterIndex(reg);
  Value* pos_push = PushLocal(current_position_);
  Value* off_push = Bind(Int64Constant(cp_offset));
  Value* neg_off_push = Bind(Add(pos_push, off_push));
  // Push the negative offset; these are converted to positive string positions
  // within the success block.
  StoreRegister(registers_push, index_push, neg_off_push);
}

void IRRegExpMacroAssembler::ClearRegisters(intptr_t reg_from,
                                            intptr_t reg_to) {
  TAG();

  ASSERT(reg_from <= reg_to);

  // In order to clear registers to a final result value of -1, set them to
  // (-1 - string length), the offset of -1 from the end of the string.

  for (intptr_t reg = reg_from; reg <= reg_to; reg++) {
    Value* registers_push = PushLocal(registers_);
    Value* index_push = PushRegisterIndex(reg);
    Value* minus_one_push = Bind(Int64Constant(-1));
    Value* length_push = PushLocal(string_param_length_);
    Value* value_push = Bind(Sub(minus_one_push, length_push));
    StoreRegister(registers_push, index_push, value_push);
  }
}

void IRRegExpMacroAssembler::WriteStackPointerToRegister(intptr_t reg) {
  TAG();

  Value* registers_push = PushLocal(registers_);
  Value* index_push = PushRegisterIndex(reg);
  Value* tip_push = PushLocal(stack_pointer_);
  StoreRegister(registers_push, index_push, tip_push);
}

// Private methods:

void IRRegExpMacroAssembler::CheckPosition(intptr_t cp_offset,
                                           BlockLabel* on_outside_input) {
  TAG();
  if (cp_offset >= 0) {
    Definition* curpos_def = LoadLocal(current_position_);
    Definition* cp_off_def = Int64Constant(-cp_offset);
    // If (current_position_ < -cp_offset), we are in bounds.
    // Remember, current_position_ is a negative offset from the string end.

    BranchOrBacktrack(Comparison(kGTE, curpos_def, cp_off_def),
                      on_outside_input);
  } else {
    // We need to see if there's enough characters left in the string to go
    // back cp_offset characters, so get the normalized position and then
    // make sure that (normalized_position >= -cp_offset).
    Value* pos_push = PushLocal(current_position_);
    Value* len_push = PushLocal(string_param_length_);
    BranchOrBacktrack(
        Comparison(kLT, Add(pos_push, len_push), Uint64Constant(-cp_offset)),
        on_outside_input);
  }
}

void IRRegExpMacroAssembler::BranchOrBacktrack(ComparisonInstr* comparison,
                                               BlockLabel* true_successor) {
  if (comparison == NULL) {  // No condition
    if (true_successor == NULL) {
      Backtrack();
      return;
    }
    GoTo(true_successor);
    return;
  }

  // If no successor block has been passed in, backtrack.
  JoinEntryInstr* true_successor_block = backtrack_block_;
  if (true_successor != NULL) {
    true_successor->SetLinked();
    true_successor_block = true_successor->block();
  }
  ASSERT(true_successor_block != NULL);

  // If the condition is not true, fall through to a new block.
  BlockLabel fallthrough;

  BranchInstr* branch = new (Z) BranchInstr(comparison, GetNextDeoptId());
  *branch->true_successor_address() = TargetWithJoinGoto(true_successor_block);
  *branch->false_successor_address() = TargetWithJoinGoto(fallthrough.block());

  CloseBlockWith(branch);
  BindBlock(&fallthrough);
}

TargetEntryInstr* IRRegExpMacroAssembler::TargetWithJoinGoto(
    JoinEntryInstr* dst) {
  TargetEntryInstr* target = new (Z)
      TargetEntryInstr(block_id_.Alloc(), kInvalidTryIndex, GetNextDeoptId());
  blocks_.Add(target);

  target->AppendInstruction(new (Z) GotoInstr(dst, GetNextDeoptId()));

  return target;
}

IndirectEntryInstr* IRRegExpMacroAssembler::IndirectWithJoinGoto(
    JoinEntryInstr* dst) {
  IndirectEntryInstr* target =
      new (Z) IndirectEntryInstr(block_id_.Alloc(), indirect_id_.Alloc(),
                                 kInvalidTryIndex, GetNextDeoptId());
  blocks_.Add(target);

  target->AppendInstruction(new (Z) GotoInstr(dst, GetNextDeoptId()));

  return target;
}

void IRRegExpMacroAssembler::CheckPreemption(bool is_backtrack) {
  TAG();

  // We don't have the loop_depth available when compiling regexps, but
  // we set loop_depth to a non-zero value because this instruction does
  // not act as an OSR entry outside loops.
  AppendInstruction(new (Z) CheckStackOverflowInstr(
      TokenPosition::kNoSource,
      /*stack_depth=*/0,
      /*loop_depth=*/1, GetNextDeoptId(),
      is_backtrack ? CheckStackOverflowInstr::kOsrAndPreemption
                   : CheckStackOverflowInstr::kOsrOnly));
}

Definition* IRRegExpMacroAssembler::Add(Value* lhs, Value* rhs) {
  return InstanceCall(InstanceCallDescriptor::FromToken(Token::kADD), lhs, rhs);
}

Definition* IRRegExpMacroAssembler::Sub(Value* lhs, Value* rhs) {
  return InstanceCall(InstanceCallDescriptor::FromToken(Token::kSUB), lhs, rhs);
}

void IRRegExpMacroAssembler::LoadCurrentCharacterUnchecked(
    intptr_t cp_offset,
    intptr_t characters) {
  TAG();

  ASSERT(characters == 1 || CanReadUnaligned());
  if (mode_ == ASCII) {
    ASSERT(characters == 1 || characters == 2 || characters == 4);
  } else {
    ASSERT(mode_ == UC16);
    ASSERT(characters == 1 || characters == 2);
  }

  // Calculate the addressed string index as:
  //    cp_offset + current_position_ + string_param_length_
  // TODO(zerny): Avoid generating 'add' instance-calls here.
  Value* off_arg = Bind(Int64Constant(cp_offset));
  Value* pos_arg = BindLoadLocal(*current_position_);
  Value* off_pos_arg = Bind(Add(off_arg, pos_arg));
  Value* len_arg = BindLoadLocal(*string_param_length_);
  // Index is stored in a temporary local so that we can later load it safely.
  StoreLocal(index_temp_, Bind(Add(off_pos_arg, len_arg)));

  // Load and store the code units.
  Value* code_unit_value = LoadCodeUnitsAt(index_temp_, characters);
  StoreLocal(current_character_, code_unit_value);
  PRINT(PushLocal(current_character_));
}

Value* IRRegExpMacroAssembler::CharacterAt(LocalVariable* index) {
  return LoadCodeUnitsAt(index, 1);
}

Value* IRRegExpMacroAssembler::LoadCodeUnitsAt(LocalVariable* index,
                                               intptr_t characters) {
  // Bind the pattern as the load receiver.
  Value* pattern_val = BindLoadLocal(*string_param_);
  if (IsExternalStringClassId(specialization_cid_)) {
    // The data of an external string is stored through one indirection.
    intptr_t external_offset = 0;
    if (specialization_cid_ == kExternalOneByteStringCid) {
      external_offset = ExternalOneByteString::external_data_offset();
    } else if (specialization_cid_ == kExternalTwoByteStringCid) {
      external_offset = ExternalTwoByteString::external_data_offset();
    } else {
      UNREACHABLE();
    }
    // This pushes an untagged value on the stack which is immediately consumed
    // by LoadCodeUnitsAtInstr below.
    pattern_val = Bind(new (Z) LoadUntaggedInstr(pattern_val, external_offset));
  }

  // Here pattern_val might be untagged so this must not trigger a GC.
  Value* index_val = BindLoadLocal(*index);

  return Bind(new (Z) LoadCodeUnitsInstr(pattern_val, index_val, characters,
                                         specialization_cid_,
                                         TokenPosition::kNoSource));
}

#undef __

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
