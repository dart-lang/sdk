// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/regexp_assembler_bytecode.h"

#include "vm/exceptions.h"
#include "vm/object_store.h"
#include "vm/regexp.h"
#include "vm/regexp_assembler.h"
#include "vm/regexp_assembler_bytecode_inl.h"
#include "vm/regexp_bytecodes.h"
#include "vm/regexp_interpreter.h"
#include "vm/regexp_parser.h"
#include "vm/timeline.h"

namespace dart {

BytecodeRegExpMacroAssembler::BytecodeRegExpMacroAssembler(
    ZoneGrowableArray<uint8_t>* buffer,
    Zone* zone)
    : RegExpMacroAssembler(zone),
      buffer_(buffer),
      pc_(0),
      advance_current_end_(kInvalidPC) {}

BytecodeRegExpMacroAssembler::~BytecodeRegExpMacroAssembler() {
  if (backtrack_.is_linked()) backtrack_.Unuse();
}

BytecodeRegExpMacroAssembler::IrregexpImplementation
BytecodeRegExpMacroAssembler::Implementation() {
  return kBytecodeImplementation;
}

void BytecodeRegExpMacroAssembler::BindBlock(BlockLabel* l) {
  advance_current_end_ = kInvalidPC;
  ASSERT(!l->is_bound());
  if (l->is_linked()) {
    intptr_t pos = l->pos();
    while (pos != 0) {
      intptr_t fixup = pos;
      pos = *reinterpret_cast<int32_t*>(buffer_->data() + fixup);
      *reinterpret_cast<uint32_t*>(buffer_->data() + fixup) = pc_;
    }
  }
  l->bind_to(pc_);
}

void BytecodeRegExpMacroAssembler::EmitOrLink(BlockLabel* l) {
  if (l == NULL) l = &backtrack_;
  if (l->is_bound()) {
    Emit32(l->pos());
  } else {
    int pos = 0;
    if (l->is_linked()) {
      pos = l->pos();
    }
    l->link_to(pc_);
    Emit32(pos);
  }
}

void BytecodeRegExpMacroAssembler::PopRegister(intptr_t register_index) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_POP_REGISTER, register_index);
}

void BytecodeRegExpMacroAssembler::PushRegister(intptr_t register_index) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_PUSH_REGISTER, register_index);
}

void BytecodeRegExpMacroAssembler::WriteCurrentPositionToRegister(
    intptr_t register_index,
    intptr_t cp_offset) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_SET_REGISTER_TO_CP, register_index);
  Emit32(cp_offset);  // Current position offset.
}

void BytecodeRegExpMacroAssembler::ClearRegisters(intptr_t reg_from,
                                                  intptr_t reg_to) {
  ASSERT(reg_from <= reg_to);
  for (int reg = reg_from; reg <= reg_to; reg++) {
    SetRegister(reg, -1);
  }
}

void BytecodeRegExpMacroAssembler::ReadCurrentPositionFromRegister(
    intptr_t register_index) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_SET_CP_TO_REGISTER, register_index);
}

void BytecodeRegExpMacroAssembler::WriteStackPointerToRegister(
    intptr_t register_index) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_SET_REGISTER_TO_SP, register_index);
}

void BytecodeRegExpMacroAssembler::ReadStackPointerFromRegister(
    intptr_t register_index) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_SET_SP_TO_REGISTER, register_index);
}

void BytecodeRegExpMacroAssembler::SetCurrentPositionFromEnd(intptr_t by) {
  ASSERT(Utils::IsUint(24, by));
  Emit(BC_SET_CURRENT_POSITION_FROM_END, by);
}

void BytecodeRegExpMacroAssembler::SetRegister(intptr_t register_index,
                                               intptr_t to) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_SET_REGISTER, register_index);
  Emit32(to);
}

void BytecodeRegExpMacroAssembler::AdvanceRegister(intptr_t register_index,
                                                   intptr_t by) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_ADVANCE_REGISTER, register_index);
  Emit32(by);
}

void BytecodeRegExpMacroAssembler::PopCurrentPosition() {
  Emit(BC_POP_CP, 0);
}

void BytecodeRegExpMacroAssembler::PushCurrentPosition() {
  Emit(BC_PUSH_CP, 0);
}

void BytecodeRegExpMacroAssembler::Backtrack() {
  Emit(BC_POP_BT, 0);
}

void BytecodeRegExpMacroAssembler::GoTo(BlockLabel* l) {
  if (advance_current_end_ == pc_) {
    // Combine advance current and goto.
    pc_ = advance_current_start_;
    Emit(BC_ADVANCE_CP_AND_GOTO, advance_current_offset_);
    EmitOrLink(l);
    advance_current_end_ = kInvalidPC;
  } else {
    // Regular goto.
    Emit(BC_GOTO, 0);
    EmitOrLink(l);
  }
}

void BytecodeRegExpMacroAssembler::PushBacktrack(BlockLabel* l) {
  Emit(BC_PUSH_BT, 0);
  EmitOrLink(l);
}

bool BytecodeRegExpMacroAssembler::Succeed() {
  Emit(BC_SUCCEED, 0);
  return false;  // Restart matching for global regexp not supported.
}

void BytecodeRegExpMacroAssembler::Fail() {
  Emit(BC_FAIL, 0);
}

void BytecodeRegExpMacroAssembler::AdvanceCurrentPosition(intptr_t by) {
  ASSERT(by >= kMinCPOffset);
  ASSERT(by <= kMaxCPOffset);
  advance_current_start_ = pc_;
  advance_current_offset_ = by;
  Emit(BC_ADVANCE_CP, by);
  advance_current_end_ = pc_;
}

void BytecodeRegExpMacroAssembler::CheckGreedyLoop(
    BlockLabel* on_tos_equals_current_position) {
  Emit(BC_CHECK_GREEDY, 0);
  EmitOrLink(on_tos_equals_current_position);
}

void BytecodeRegExpMacroAssembler::LoadCurrentCharacter(intptr_t cp_offset,
                                                        BlockLabel* on_failure,
                                                        bool check_bounds,
                                                        intptr_t characters) {
  ASSERT(cp_offset >= kMinCPOffset);
  ASSERT(cp_offset <= kMaxCPOffset);
  int bytecode;
  if (check_bounds) {
    if (characters == 4) {
      bytecode = BC_LOAD_4_CURRENT_CHARS;
    } else if (characters == 2) {
      bytecode = BC_LOAD_2_CURRENT_CHARS;
    } else {
      ASSERT(characters == 1);
      bytecode = BC_LOAD_CURRENT_CHAR;
    }
  } else {
    if (characters == 4) {
      bytecode = BC_LOAD_4_CURRENT_CHARS_UNCHECKED;
    } else if (characters == 2) {
      bytecode = BC_LOAD_2_CURRENT_CHARS_UNCHECKED;
    } else {
      ASSERT(characters == 1);
      bytecode = BC_LOAD_CURRENT_CHAR_UNCHECKED;
    }
  }
  Emit(bytecode, cp_offset);
  if (check_bounds) EmitOrLink(on_failure);
}

void BytecodeRegExpMacroAssembler::CheckCharacterLT(uint16_t limit,
                                                    BlockLabel* on_less) {
  Emit(BC_CHECK_LT, limit);
  EmitOrLink(on_less);
}

void BytecodeRegExpMacroAssembler::CheckCharacterGT(uint16_t limit,
                                                    BlockLabel* on_greater) {
  Emit(BC_CHECK_GT, limit);
  EmitOrLink(on_greater);
}

void BytecodeRegExpMacroAssembler::CheckCharacter(uint32_t c,
                                                  BlockLabel* on_equal) {
  if (c > MAX_FIRST_ARG) {
    Emit(BC_CHECK_4_CHARS, 0);
    Emit32(c);
  } else {
    Emit(BC_CHECK_CHAR, c);
  }
  EmitOrLink(on_equal);
}

void BytecodeRegExpMacroAssembler::CheckAtStart(BlockLabel* on_at_start) {
  Emit(BC_CHECK_AT_START, 0);
  EmitOrLink(on_at_start);
}

void BytecodeRegExpMacroAssembler::CheckNotAtStart(
    BlockLabel* on_not_at_start) {
  Emit(BC_CHECK_NOT_AT_START, 0);
  EmitOrLink(on_not_at_start);
}

void BytecodeRegExpMacroAssembler::CheckNotCharacter(uint32_t c,
                                                     BlockLabel* on_not_equal) {
  if (c > MAX_FIRST_ARG) {
    Emit(BC_CHECK_NOT_4_CHARS, 0);
    Emit32(c);
  } else {
    Emit(BC_CHECK_NOT_CHAR, c);
  }
  EmitOrLink(on_not_equal);
}

void BytecodeRegExpMacroAssembler::CheckCharacterAfterAnd(
    uint32_t c,
    uint32_t mask,
    BlockLabel* on_equal) {
  if (c > MAX_FIRST_ARG) {
    Emit(BC_AND_CHECK_4_CHARS, 0);
    Emit32(c);
  } else {
    Emit(BC_AND_CHECK_CHAR, c);
  }
  Emit32(mask);
  EmitOrLink(on_equal);
}

void BytecodeRegExpMacroAssembler::CheckNotCharacterAfterAnd(
    uint32_t c,
    uint32_t mask,
    BlockLabel* on_not_equal) {
  if (c > MAX_FIRST_ARG) {
    Emit(BC_AND_CHECK_NOT_4_CHARS, 0);
    Emit32(c);
  } else {
    Emit(BC_AND_CHECK_NOT_CHAR, c);
  }
  Emit32(mask);
  EmitOrLink(on_not_equal);
}

void BytecodeRegExpMacroAssembler::CheckNotCharacterAfterMinusAnd(
    uint16_t c,
    uint16_t minus,
    uint16_t mask,
    BlockLabel* on_not_equal) {
  Emit(BC_MINUS_AND_CHECK_NOT_CHAR, c);
  Emit16(minus);
  Emit16(mask);
  EmitOrLink(on_not_equal);
}

void BytecodeRegExpMacroAssembler::CheckCharacterInRange(
    uint16_t from,
    uint16_t to,
    BlockLabel* on_in_range) {
  Emit(BC_CHECK_CHAR_IN_RANGE, 0);
  Emit16(from);
  Emit16(to);
  EmitOrLink(on_in_range);
}

void BytecodeRegExpMacroAssembler::CheckCharacterNotInRange(
    uint16_t from,
    uint16_t to,
    BlockLabel* on_not_in_range) {
  Emit(BC_CHECK_CHAR_NOT_IN_RANGE, 0);
  Emit16(from);
  Emit16(to);
  EmitOrLink(on_not_in_range);
}

void BytecodeRegExpMacroAssembler::CheckBitInTable(const TypedData& table,
                                                   BlockLabel* on_bit_set) {
  Emit(BC_CHECK_BIT_IN_TABLE, 0);
  EmitOrLink(on_bit_set);
  for (int i = 0; i < kTableSize; i += kBitsPerByte) {
    int byte = 0;
    for (int j = 0; j < kBitsPerByte; j++) {
      if (table.GetUint8(i + j) != 0) byte |= 1 << j;
    }
    Emit8(byte);
  }
}

void BytecodeRegExpMacroAssembler::CheckNotBackReference(
    intptr_t start_reg,
    BlockLabel* on_not_equal) {
  ASSERT(start_reg >= 0);
  ASSERT(start_reg <= kMaxRegister);
  Emit(BC_CHECK_NOT_BACK_REF, start_reg);
  EmitOrLink(on_not_equal);
}

void BytecodeRegExpMacroAssembler::CheckNotBackReferenceIgnoreCase(
    intptr_t start_reg,
    BlockLabel* on_not_equal) {
  ASSERT(start_reg >= 0);
  ASSERT(start_reg <= kMaxRegister);
  Emit(BC_CHECK_NOT_BACK_REF_NO_CASE, start_reg);
  EmitOrLink(on_not_equal);
}

void BytecodeRegExpMacroAssembler::IfRegisterLT(intptr_t register_index,
                                                intptr_t comparand,
                                                BlockLabel* on_less_than) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_CHECK_REGISTER_LT, register_index);
  Emit32(comparand);
  EmitOrLink(on_less_than);
}

void BytecodeRegExpMacroAssembler::IfRegisterGE(
    intptr_t register_index,
    intptr_t comparand,
    BlockLabel* on_greater_or_equal) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_CHECK_REGISTER_GE, register_index);
  Emit32(comparand);
  EmitOrLink(on_greater_or_equal);
}

void BytecodeRegExpMacroAssembler::IfRegisterEqPos(intptr_t register_index,
                                                   BlockLabel* on_eq) {
  ASSERT(register_index >= 0);
  ASSERT(register_index <= kMaxRegister);
  Emit(BC_CHECK_REGISTER_EQ_POS, register_index);
  EmitOrLink(on_eq);
}

RawTypedData* BytecodeRegExpMacroAssembler::GetBytecode() {
  BindBlock(&backtrack_);
  Emit(BC_POP_BT, 0);

  intptr_t len = length();
  const TypedData& bytecode =
      TypedData::Handle(TypedData::New(kTypedDataUint8ArrayCid, len));

  NoSafepointScope no_safepoint;
  memmove(bytecode.DataAddr(0), buffer_->data(), len);

  return bytecode.raw();
}

intptr_t BytecodeRegExpMacroAssembler::length() {
  return pc_;
}

void BytecodeRegExpMacroAssembler::Expand() {
  // BOGUS
  buffer_->Add(0);
  buffer_->Add(0);
  buffer_->Add(0);
  buffer_->Add(0);
  intptr_t x = buffer_->length();
  for (intptr_t i = 0; i < x; i++)
    buffer_->Add(0);
}

static intptr_t Prepare(const RegExp& regexp,
                        const String& subject,
                        bool sticky,
                        Zone* zone) {
  bool is_one_byte =
      subject.IsOneByteString() || subject.IsExternalOneByteString();

  if (regexp.bytecode(is_one_byte, sticky) == TypedData::null()) {
    const String& pattern = String::Handle(zone, regexp.pattern());
#if !defined(PRODUCT)
    TimelineDurationScope tds(Thread::Current(), Timeline::GetCompilerStream(),
                              "CompileIrregexpBytecode");
    if (tds.enabled()) {
      tds.SetNumArguments(1);
      tds.CopyArgument(0, "pattern", pattern.ToCString());
    }
#endif  // !defined(PRODUCT)

    const bool multiline = regexp.is_multi_line();
    RegExpCompileData* compile_data = new (zone) RegExpCompileData();
    if (!RegExpParser::ParseRegExp(pattern, multiline, compile_data)) {
      // Parsing failures are handled in the RegExp factory constructor.
      UNREACHABLE();
    }

    regexp.set_num_bracket_expressions(compile_data->capture_count);
    if (compile_data->simple) {
      regexp.set_is_simple();
    } else {
      regexp.set_is_complex();
    }

    RegExpEngine::CompilationResult result = RegExpEngine::CompileBytecode(
        compile_data, regexp, is_one_byte, sticky, zone);
    ASSERT(result.bytecode != NULL);
    ASSERT((regexp.num_registers() == -1) ||
           (regexp.num_registers() == result.num_registers));
    regexp.set_num_registers(result.num_registers);
    regexp.set_bytecode(is_one_byte, sticky, *(result.bytecode));
  }

  ASSERT(regexp.num_registers() != -1);

  return regexp.num_registers() +
         (Smi::Value(regexp.num_bracket_expressions()) + 1) * 2;
}

static IrregexpInterpreter::IrregexpResult ExecRaw(const RegExp& regexp,
                                                   const String& subject,
                                                   intptr_t index,
                                                   bool sticky,
                                                   int32_t* output,
                                                   intptr_t output_size,
                                                   Zone* zone) {
  bool is_one_byte =
      subject.IsOneByteString() || subject.IsExternalOneByteString();

  ASSERT(regexp.num_bracket_expressions() != Smi::null());

  // We must have done EnsureCompiledIrregexp, so we can get the number of
  // registers.
  int number_of_capture_registers =
      (Smi::Value(regexp.num_bracket_expressions()) + 1) * 2;
  int32_t* raw_output = &output[number_of_capture_registers];

  // We do not touch the actual capture result registers until we know there
  // has been a match so that we can use those capture results to set the
  // last match info.
  for (int i = number_of_capture_registers - 1; i >= 0; i--) {
    raw_output[i] = -1;
  }

  const TypedData& bytecode =
      TypedData::Handle(zone, regexp.bytecode(is_one_byte, sticky));
  ASSERT(!bytecode.IsNull());
  IrregexpInterpreter::IrregexpResult result =
      IrregexpInterpreter::Match(bytecode, subject, raw_output, index, zone);

  if (result == IrregexpInterpreter::RE_SUCCESS) {
    // Copy capture results to the start of the registers array.
    memmove(output, raw_output, number_of_capture_registers * sizeof(int32_t));
  }
  if (result == IrregexpInterpreter::RE_EXCEPTION) {
    Thread* thread = Thread::Current();
    Isolate* isolate = thread->isolate();
    const Instance& exception =
        Instance::Handle(isolate->object_store()->stack_overflow());
    Exceptions::Throw(thread, exception);
    UNREACHABLE();
  }
  return result;
}

RawInstance* BytecodeRegExpMacroAssembler::Interpret(const RegExp& regexp,
                                                     const String& subject,
                                                     const Smi& start_index,
                                                     bool sticky,
                                                     Zone* zone) {
  intptr_t required_registers = Prepare(regexp, subject, sticky, zone);
  if (required_registers < 0) {
    // Compiling failed with an exception.
    UNREACHABLE();
  }

  // V8 uses a shared copy on the isolate when smaller than some threshold.
  int32_t* output_registers = zone->Alloc<int32_t>(required_registers);

  IrregexpInterpreter::IrregexpResult result =
      ExecRaw(regexp, subject, start_index.Value(), sticky, output_registers,
              required_registers, zone);

  if (result == IrregexpInterpreter::RE_SUCCESS) {
    intptr_t capture_count = Smi::Value(regexp.num_bracket_expressions());
    intptr_t capture_register_count = (capture_count + 1) * 2;
    ASSERT(required_registers >= capture_register_count);

    const TypedData& result = TypedData::Handle(
        TypedData::New(kTypedDataInt32ArrayCid, capture_register_count));
    {
#ifdef DEBUG
      // These indices will be used with substring operations that don't check
      // bounds, so sanity check them here.
      for (intptr_t i = 0; i < capture_register_count; i++) {
        int32_t val = output_registers[i];
        ASSERT(val == -1 || (val >= 0 && val <= subject.Length()));
      }
#endif

      NoSafepointScope no_safepoint;
      memmove(result.DataAddr(0), output_registers,
              capture_register_count * sizeof(int32_t));
    }

    return result.raw();
  }
  if (result == IrregexpInterpreter::RE_EXCEPTION) {
    UNREACHABLE();
  }
  ASSERT(result == IrregexpInterpreter::RE_FAILURE);
  return Instance::null();
}

}  // namespace dart
