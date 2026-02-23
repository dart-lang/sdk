// Copyright 2011 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A simple interpreter for the Irregexp byte code.

#include "vm/regexp/regexp-interpreter.h"

#include <limits>

#include "vm/exceptions.h"
#include "vm/regexp/regexp-bytecodes-inl.h"
#include "vm/regexp/regexp-bytecodes.h"
#include "vm/regexp/regexp-macro-assembler.h"
#include "vm/regexp/regexp.h"
#include "vm/regexp/small-vector.h"

#ifdef V8_INTL_SUPPORT
#include "unicode/uchar.h"
#endif  // V8_INTL_SUPPORT

// Use token threaded dispatch iff the compiler supports computed gotos and the
// build argument v8_enable_regexp_interpreter_threaded_dispatch was set.
#if V8_HAS_COMPUTED_GOTO &&                                                    \
    defined(V8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH)
#define V8_USE_COMPUTED_GOTO 1
#endif  // V8_HAS_COMPUTED_GOTO

namespace dart {

namespace {

bool BackRefMatchesNoCase(Thread* thread,
                          int from,
                          int current,
                          int len,
                          base::Vector<const uint16_t> subject,
                          bool unicode) {
  Address offset_a =
      reinterpret_cast<Address>(const_cast<uint16_t*>(&subject.at(from)));
  Address offset_b =
      reinterpret_cast<Address>(const_cast<uint16_t*>(&subject.at(current)));
  size_t length = len * base::kUC16Size;

  bool result = unicode
                    ? RegExpMacroAssembler::CaseInsensitiveCompareUnicode(
                          offset_a, offset_b, length, thread->isolate())
                    : RegExpMacroAssembler::CaseInsensitiveCompareNonUnicode(
                          offset_a, offset_b, length, thread->isolate());
  return result == 1;
}

bool BackRefMatchesNoCase(Thread* thread,
                          int from,
                          int current,
                          int len,
                          base::Vector<const uint8_t> subject,
                          bool unicode) {
  // For Latin1 characters the unicode flag makes no difference.
  for (int i = 0; i < len; i++) {
    unsigned int old_char = subject[from++];
    unsigned int new_char = subject[current++];
    if (old_char == new_char) continue;
    // Convert both characters to lower case.
    old_char |= 0x20;
    new_char |= 0x20;
    if (old_char != new_char) return false;
    // Not letters in the ASCII range and Latin-1 range.
    if (!(old_char - 'a' <= 'z' - 'a') &&
        !(old_char - 224 <= 254 - 224 && old_char != 247)) {
      return false;
    }
  }
  return true;
}

#ifdef ENABLE_DISASSEMBLER
void MaybeTraceInterpreter(const uint8_t* code_base,
                           const uint8_t* pc,
                           int stack_depth,
                           int current_position,
                           uint32_t current_char,
                           int bytecode_length,
                           const char* bytecode_name) {
  if (v8_flags.trace_regexp_bytecodes) {
    // The behaviour of std::isprint is undefined if the value isn't
    // representable as unsigned char.
    const bool is_single_char =
        current_char <= std::numeric_limits<unsigned char>::max();
    const bool printable = is_single_char ? std::isprint(current_char) : false;
    const char* format =
        printable ? "pc = %02x, sp = %d, curpos = %d, curchar = %08x (%c), "
                  : "pc = %02x, sp = %d, curpos = %d, curchar = %08x .%c., ";
    PrintF(format, pc - code_base, stack_depth, current_position, current_char,
           printable ? current_char : '.');

    RegExpBytecodeDisassembleSingle(code_base, pc);
  }
}
#endif  // ENABLE_DISASSEMBLER

template <class Char>
constexpr int BitsPerChar() {
  return kBitsPerByte * sizeof(Char);
}

template <class Char>
uint32_t Load2Characters(const base::Vector<const Char>& string, int index) {
  return string[index] | (string[index + 1] << BitsPerChar<Char>());
}

uint32_t Load4Characters(const base::Vector<const uint8_t>& string, int index) {
  return string[index] | (string[index + 1] << 8) | (string[index + 2] << 16) |
         (string[index + 3] << 24);
}

uint32_t Load4Characters(const base::Vector<const uint16_t>&, int) {
  UNREACHABLE();
}

// A simple abstraction over the backtracking stack used by the interpreter.
//
// Despite the name 'backtracking' stack, it's actually used as a generic stack
// that stores both program counters (= offsets into the bytecode) and generic
// integer values.
class BacktrackStack {
 public:
  BacktrackStack() = default;
  BacktrackStack(const BacktrackStack&) = delete;
  BacktrackStack& operator=(const BacktrackStack&) = delete;

  V8_WARN_UNUSED_RESULT bool push(int v) {
    data_.emplace_back(v);
    return (static_cast<int>(data_.size()) <= kMaxSize);
  }
  int peek() const {
    SBXCHECK(!data_.empty());
    return data_.back();
  }
  int pop() {
    int v = peek();
    data_.pop_back();
    return v;
  }

  // The 'sp' is the index of the first empty element in the stack.
  int sp() const { return static_cast<int>(data_.size()); }
  void set_sp(uint32_t new_sp) {
    // Dart: V8 has mixed sign comparison.
    // DCHECK_LE(new_sp, sp());
    data_.resize(new_sp);
  }

 private:
  // Semi-arbitrary. Should be large enough for common cases to remain in the
  // static stack-allocated backing store, but small enough not to waste space.
  static constexpr int kStaticCapacity = 64;

  using ValueT = int;
  base::SmallVector<ValueT, kStaticCapacity> data_;

  static constexpr int kMaxSize = 64 * MB / sizeof(ValueT);
};

// Registers used during interpreter execution. These consist of output
// registers in indices [0, output_register_count[ which will contain matcher
// results as a {start,end} index tuple for each capture (where the whole match
// counts as implicit capture 0); and internal registers in indices
// [output_register_count, total_register_count[.
class InterpreterRegisters {
 public:
  using RegisterT = int;
  static constexpr int kNoMatchValue = -1;

  InterpreterRegisters(int total_register_count,
                       RegisterT* output_registers,
                       int output_register_count)
      : registers_(total_register_count),
        output_registers_(output_registers),
        total_register_count_(total_register_count),
        output_register_count_(output_register_count) {
    // TODO(jgruber): Use int32_t consistently for registers. Currently, CSA
    // uses int32_t while runtime uses int.
    static_assert(sizeof(int) == sizeof(int32_t));
    SBXCHECK_GE(output_register_count, 2);  // At least 2 for the match itself.
    SBXCHECK_GE(total_register_count, output_register_count);
    SBXCHECK_LE(total_register_count, RegExpMacroAssembler::kMaxRegisterCount);
    DCHECK_NOT_NULL(output_registers);

    // Initialize the output register region to -1 signifying 'no match'.
    std::memset(registers_.data(), kNoMatchValue,
                output_register_count * sizeof(RegisterT));
    USE(total_register_count_);
  }

  const RegisterT& operator[](size_t index) const {
    // Dart: V8 has mixed sign comparison
    // SBXCHECK_LT(index, total_register_count_);
    return registers_[index];
  }
  RegisterT& operator[](size_t index) {
    // Dart: V8 has mixed sign comparison
    // SBXCHECK_LT(index, total_register_count_);
    return registers_[index];
  }

  void CopyToOutputRegisters() {
    base::MemCopy(output_registers_, registers_.data(),
                  output_register_count_ * sizeof(RegisterT));
  }

 private:
  static constexpr int kStaticCapacity = 64;  // Arbitrary.
  base::SmallVector<RegisterT, kStaticCapacity> registers_;
  RegisterT* const output_registers_;
  const int total_register_count_;
  const int output_register_count_;
};

IrregexpInterpreter::Result ThrowStackOverflow(
    Thread* thread,
    RegExpStatics::CallOrigin call_origin) {
  CHECK(call_origin == RegExpStatics::CallOrigin::kFromRuntime);

  Exceptions::ThrowStackOverflow();
}

// Only throws if called from the runtime, otherwise just returns the EXCEPTION
// status code.
IrregexpInterpreter::Result MaybeThrowStackOverflow(
    Thread* thread,
    RegExpStatics::CallOrigin call_origin) {
  if (call_origin == RegExpStatics::CallOrigin::kFromRuntime) {
    return ThrowStackOverflow(thread, call_origin);
  } else {
    return IrregexpInterpreter::EXCEPTION;
  }
}

bool CheckBitInTable(const uint32_t current_char, const uint8_t* const table) {
  int mask = RegExpMacroAssembler::kTableMask;
  int b = table[(current_char & mask) >> kBitsPerByteLog2];
  int bit = (current_char & (kBitsPerByte - 1));
  return (b & (1 << bit)) != 0;
}

// Returns true iff 0 <= index < length.
bool IndexIsInBounds(int index, int length) {
  DCHECK_GE(length, 0);
  return static_cast<uintptr_t>(index) < static_cast<uintptr_t>(length);
}

// If computed gotos are supported by the compiler, we can get addresses to
// labels directly in C/C++. Every bytecode handler has its own label and we
// store the addresses in a dispatch table indexed by bytecode. To execute the
// next handler we simply jump (goto) directly to its address.
#if V8_USE_COMPUTED_GOTO
#define BC_LABEL(name) BC_k##name:
#define DECODE()                                                               \
  do {                                                                         \
    RegExpBytecode next_bc = RegExpBytecodes::FromPtr(next_pc);                \
    next_handler_addr =                                                        \
        dispatch_table[RegExpBytecodes::ToByte(next_bc) & kBytecodeMask];      \
  } while (false)
#define DISPATCH()                                                             \
  pc = next_pc;                                                                \
  goto* next_handler_addr
// Without computed goto support, we fall back to a simple switch-based
// dispatch (A large switch statement inside a loop with a case for every
// bytecode).
#else  // V8_USE_COMPUTED_GOTO
#define BC_LABEL(name) case RegExpBytecode::k##name:
#define DECODE() ((void)0)
#define DISPATCH()                                                             \
  pc = next_pc;                                                                \
  goto switch_dispatch_continuation
#endif  // V8_USE_COMPUTED_GOTO

// ADVANCE/SET_PC_FROM_OFFSET are separated from DISPATCH, because ideally some
// instructions can be executed between ADVANCE/SET_PC_FROM_OFFSET and DISPATCH.
// We want those two macros as far apart as possible, because the goto in
// DISPATCH is dependent on a memory load in ADVANCE/SET_PC_FROM_OFFSET. If we
// don't hit the cache and have to fetch the next handler address from physical
// memory, instructions between ADVANCE/SET_PC_FROM_OFFSET and DISPATCH can
// potentially be executed unconditionally, reducing memory stall.
#define ADVANCE()                                                              \
  next_pc = pc + RegExpBytecodes::Size(current_bc);                            \
  DECODE()

#define SET_PC_FROM_OFFSET(offset)                                             \
  next_pc = code_base + offset;                                                \
  DECODE()

// Current position mutations.
#define SET_CURRENT_POSITION(value)                                            \
  do {                                                                         \
    current = (value);                                                         \
    ASSERT(base::IsInRange(current, 0, subject.length()));                     \
  } while (false)
#define ADVANCE_CURRENT_POSITION(by) SET_CURRENT_POSITION(current + (by))

// These weird looking macros are required for clang-format and cpplint to not
// interfere/complain about our logic of opening/closing blocks in our macros.
#define OPEN_BLOCK {
#define CLOSE_BLOCK }
#define BYTECODES_START() OPEN_BLOCK
#define BYTECODES_END() CLOSE_BLOCK

#ifdef ENABLE_DISASSEMBLER
#define BYTECODE(Name, ...)                                                    \
  CLOSE_BLOCK                                                                  \
  BC_LABEL(Name) OPEN_BLOCK INIT(Name __VA_OPT__(, ) __VA_ARGS__);             \
  MaybeTraceInterpreter(code_base, pc, backtrack_stack.sp(), current,          \
                        current_char, RegExpBytecodes::Size(current_bc),       \
                        #Name);
#else
#define BYTECODE(Name, ...)                                                    \
  CLOSE_BLOCK                                                                  \
  BC_LABEL(Name) OPEN_BLOCK INIT(Name __VA_OPT__(, ) __VA_ARGS__);
#endif  // ENABLE_DISASSEMBLER

#define DEAD_BYTECODE(Name, ...)                                               \
  CLOSE_BLOCK                                                                  \
  BC_LABEL(Name) OPEN_BLOCK {                                                  \
    UNREACHABLE();                                                             \
  }

#define INIT(Name, ...)                                                        \
  constexpr RegExpBytecode current_bc = RegExpBytecode::k##Name;               \
  using Operands = RegExpBytecodeOperands<current_bc>;                         \
  __VA_OPT__(auto argument_tuple = std::apply(                                 \
                 [&](auto... ops) {                                            \
                   return std::make_tuple(                                     \
                       Operands::template Get<ops.value>(pc, no_gc)...);       \
                 },                                                            \
                 Operands::GetOperandsTuple());                                \
             auto [__VA_ARGS__] = argument_tuple;)                             \
  static_assert((IS_VA_EMPTY(__VA_ARGS__)) == (Operands::kCount == 0),         \
                "Number of arguments to VISIT doesn't match the bytecodes "    \
                "operands count")

namespace {

template <typename Char>
bool CheckSpecialClassRanges(uint32_t current_char,
                             StandardCharacterSet character_set) {
  constexpr bool is_one_byte = sizeof(Char) == 1;
  switch (character_set) {
    case StandardCharacterSet::kWhitespace:
      ASSERT(is_one_byte);
      if (current_char == ' ' || base::IsInRange(current_char, '\t', '\r') ||
          current_char == 0xA0) {
        return true;
      }
      return false;
    case StandardCharacterSet::kNotWhitespace:
      UNREACHABLE();
    case StandardCharacterSet::kWord: {
      if constexpr (!is_one_byte) {
        if (current_char > 'z') {
          return false;
        }
      }
      base::Vector<const uint8_t> word_character_map =
          RegExpMacroAssembler::word_character_map();
      DCHECK_EQ(0,
                word_character_map[0]);  // Character '\0' is not a word char.
      return word_character_map[current_char] != 0;
      return true;
    }
    case StandardCharacterSet::kNotWord: {
      if constexpr (!is_one_byte) {
        if (current_char > 'z') {
          return true;
        }
      }
      base::Vector<const uint8_t> word_character_map =
          RegExpMacroAssembler::word_character_map();
      DCHECK_EQ(0,
                word_character_map[0]);  // Character '\0' is not a word char.
      return word_character_map[current_char] == 0;
    }
    case StandardCharacterSet::kDigit:
      if (base::IsInRange(current_char, '0', '9')) {
        return true;
      }
      return false;
    case StandardCharacterSet::kNotDigit:
      if (base::IsInRange(current_char, '0', '9')) {
        return false;
      }
      return true;
    case StandardCharacterSet::kLineTerminator: {
      if (current_char == '\n' || current_char == '\r') {
        return true;
      }
      if constexpr (!is_one_byte) {
        if (current_char == 0x2028 || current_char == 0x2029) {
          return true;
        }
      }
      return false;
    }
    case StandardCharacterSet::kNotLineTerminator: {
      const bool is_one_byte_match =
          current_char != '\n' && current_char != '\r';
      if constexpr (is_one_byte) {
        if (is_one_byte_match) {
          return true;
        }
      } else {
        if (is_one_byte_match && current_char != 0x2028 &&
            current_char != 0x2029) {
          return true;
        }
      }
      return false;
    }
    case StandardCharacterSet::kEverything:
      return true;
  }
  UNREACHABLE();
  return false;
}

}  // namespace

template <typename Char, typename NByteString>
IrregexpInterpreter::Result RawMatch(Thread* thread,
                                     const TypedData& code_array,
                                     const String& subject_string,
                                     base::Vector<const Char> subject,
                                     int* output_registers,
                                     int output_register_count,
                                     int total_register_count,
                                     int current,
                                     uint32_t current_char,
                                     RegExpStatics::CallOrigin call_origin,
                                     const uint32_t backtrack_limit) {
  DisallowGarbageCollection no_gc;

#if V8_USE_COMPUTED_GOTO

  // Maximum number of bytecodes that will be used (next power of 2 of actually
  // defined bytecodes).
  // All slots between the last actually defined bytecode and maximum id will be
  // filled with kBreaks, indicating an invalid operation. This way using
  // kBytecodeMask guarantees no OOB access to the dispatch table.
  constexpr int kPaddedBytecodeCount =
      Utils::RoundUpToPowerOfTwo(RegExpBytecodes::kCount);
  constexpr int kBytecodeMask = kPaddedBytecodeCount - 1;
  static_assert(std::numeric_limits<uint8_t>::max() >= kBytecodeMask);

  // We have to make sure that no OOB access to the dispatch table is possible
  // and all values are valid label addresses. Otherwise jumps to arbitrary
  // addresses could potentially happen. This is ensured as follows: Every index
  // to the dispatch table gets masked using kBytecodeMask in DECODE(). This way
  // we can only get values between 0 (only the least significant byte of an
  // integer is used) and kPaddedBytecodeCount - 1 (kBytecodeMask is defined to
  // be exactly this value). All entries from RegExpBytecodes::kCount to
  // kRegExpPaddedBytecodeCount are automatically filled with kBreak (invalid
  // operation).

#define DECLARE_DISPATCH_TABLE_ENTRY(name, ...) &&BC_k##name,
  static const void* const unsafe_dispatch_table[RegExpBytecodes::kCount] = {
      REGEXP_BYTECODE_LIST(DECLARE_DISPATCH_TABLE_ENTRY)};
#undef DECLARE_DISPATCH_TABLE_ENTRY
#undef BYTECODE_FILLER_ITERATOR

  static const void* const filler_entry = &&BC_kBreak;
  static const std::array<const void*, kPaddedBytecodeCount> dispatch_table =
      [=]() {
        std::array<const void*, kPaddedBytecodeCount> table;

        size_t i = 0;
        // Copy all valid Bytecodes to the dispatch table.
        for (; i < RegExpBytecodes::kCount; ++i) {
          table[i] = unsafe_dispatch_table[i];
        }
        // Fill dispatch table from last defined bytecode up to the next power
        // of two with kBreak (invalid operation).
        for (; i < kPaddedBytecodeCount; ++i) {
          table[i] = filler_entry;
        }
        return table;
      }();

#endif  // V8_USE_COMPUTED_GOTO

  const uint8_t* pc;
  const uint8_t* code_base;
  {
    NoSafepointScope no_safepoint(thread);
    pc = code_base = reinterpret_cast<const uint8_t*>(code_array.DataAddr(0));
  }

  InterpreterRegisters registers(total_register_count, output_registers,
                                 output_register_count);
  BacktrackStack backtrack_stack;

  uint32_t backtrack_count = 0;

  while (true) {
    const uint8_t* next_pc = pc;
#if V8_USE_COMPUTED_GOTO
    const void* next_handler_addr;
    DECODE();
    DISPATCH();
#else
    switch (RegExpBytecodes::FromPtr(pc)) {
#endif  // V8_USE_COMPUTED_GOTO
    BYTECODES_START()
    BYTECODE(Break) {
      UNREACHABLE();
    }
    BYTECODE(PushCurrentPosition) {
      ADVANCE();
      if (!backtrack_stack.push(current)) {
        return MaybeThrowStackOverflow(thread, call_origin);
      }
      DISPATCH();
    }
    BYTECODE(PushBacktrack, label) {
      ADVANCE();
      if (!backtrack_stack.push(label)) {
        return MaybeThrowStackOverflow(thread, call_origin);
      }
      DISPATCH();
    }
    BYTECODE(PushRegister, register_index, stack_check) {
      ADVANCE();
      USE(stack_check);  // Unused in interpreter.
      if (!backtrack_stack.push(registers[register_index])) {
        return MaybeThrowStackOverflow(thread, call_origin);
      }
      DISPATCH();
    }
    BYTECODE(SetRegister, register_index, value) {
      ADVANCE();
      registers[register_index] = value;
      DISPATCH();
    }
    BYTECODE(ClearRegisters, from_register, to_register) {
      ADVANCE();
      SBXCHECK_LE(from_register, to_register);
      for (uint16_t i = from_register; i <= to_register; ++i) {
        registers[i] = InterpreterRegisters::kNoMatchValue;
      }
      DISPATCH();
    }
    BYTECODE(AdvanceRegister, register_index, by) {
      ADVANCE();
      registers[register_index] += by;
      DISPATCH();
    }
    BYTECODE(WriteCurrentPositionToRegister, register_index, cp_offset) {
      ADVANCE();
      registers[register_index] = current + cp_offset;
      DISPATCH();
    }
    BYTECODE(ReadCurrentPositionFromRegister, register_index) {
      ADVANCE();
      SET_CURRENT_POSITION(registers[register_index]);
      DISPATCH();
    }
    BYTECODE(WriteStackPointerToRegister, register_index) {
      ADVANCE();
      registers[register_index] = backtrack_stack.sp();
      DISPATCH();
    }
    BYTECODE(ReadStackPointerFromRegister, register_index) {
      ADVANCE();
      backtrack_stack.set_sp(registers[register_index]);
      DISPATCH();
    }
    BYTECODE(PopCurrentPosition) {
      ADVANCE();
      SET_CURRENT_POSITION(backtrack_stack.pop());
      DISPATCH();
    }
    BYTECODE(Backtrack, return_code) {
      static_assert(JSRegExp::kNoBacktrackLimit == 0);
      if (++backtrack_count == backtrack_limit) {
        return static_cast<IrregexpInterpreter::Result>(return_code);
      }

      if (UNLIKELY(thread->HasScheduledInterrupts())) {
        intptr_t pc_offset = pc - code_base;
        ErrorPtr error = thread->HandleInterrupts();
        if (error != Object::null()) {
          // Not throwing directly because we first need to run destructors for
          // types that aren't ThreadResources.
          thread->set_sticky_error(Error::Handle(error));
          return IrregexpInterpreter::EXCEPTION;
        }

        NoSafepointScope no_safepoint(thread);
        code_base = reinterpret_cast<const uint8_t*>(code_array.DataAddr(0));
        pc = code_base + pc_offset;
        subject = {NByteString::DataStart(subject_string),
                   static_cast<size_t>(subject_string.Length())};
      }

      SET_PC_FROM_OFFSET(backtrack_stack.pop());
      DISPATCH();
    }
    BYTECODE(PopRegister, register_index) {
      ADVANCE();
      registers[register_index] = backtrack_stack.pop();
      DISPATCH();
    }
    BYTECODE(Fail) {
      //isolate->counters()->regexp_backtracks()->AddSample(
      //    static_cast<int>(backtrack_count));
      return IrregexpInterpreter::FAILURE;
    }
    BYTECODE(Succeed) {
      //isolate->counters()->regexp_backtracks()->AddSample(
      //    static_cast<int>(backtrack_count));
      registers.CopyToOutputRegisters();
      return IrregexpInterpreter::SUCCESS;
    }
    BYTECODE(AdvanceCurrentPosition, by) {
      ADVANCE();
      ADVANCE_CURRENT_POSITION(by);
      DISPATCH();
    }
    BYTECODE(GoTo, label) {
      SET_PC_FROM_OFFSET(label);
      DISPATCH();
    }
    BYTECODE(AdvanceCpAndGoto, by, on_goto) {
      SET_PC_FROM_OFFSET(on_goto);
      ADVANCE_CURRENT_POSITION(by);
      DISPATCH();
    }
    BYTECODE(CheckFixedLengthLoop, on_tos_equals_current_position) {
      if (current == backtrack_stack.peek()) {
        SET_PC_FROM_OFFSET(on_tos_equals_current_position);
        backtrack_stack.pop();
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(LoadCurrentCharacter, cp_offset, on_failure) {
      int pos = current + cp_offset;
      if (pos >= subject.length() || pos < 0) {
        SET_PC_FROM_OFFSET(on_failure);
      } else {
        ADVANCE();
        current_char = subject[pos];
      }
      DISPATCH();
    }
    BYTECODE(LoadCurrentCharacterUnchecked, cp_offset) {
      ADVANCE();
      int pos = current + cp_offset;
      current_char = subject[pos];
      DISPATCH();
    }
    BYTECODE(Load2CurrentChars, cp_offset, on_failure) {
      int pos = current + cp_offset;
      if (pos + 2 > subject.length() || pos < 0) {
        SET_PC_FROM_OFFSET(on_failure);
      } else {
        ADVANCE();
        current_char = Load2Characters(subject, pos);
      }
      DISPATCH();
    }
    BYTECODE(Load2CurrentCharsUnchecked, cp_offset) {
      ADVANCE();
      int pos = current + cp_offset;
      current_char = Load2Characters(subject, pos);
      DISPATCH();
    }
    BYTECODE(Load4CurrentChars, cp_offset, on_failure) {
      DCHECK_EQ(1, sizeof(Char));
      int pos = current + cp_offset;
      if (pos + 4 > subject.length() || pos < 0) {
        SET_PC_FROM_OFFSET(on_failure);
      } else {
        ADVANCE();
        current_char = Load4Characters(subject, pos);
      }
      DISPATCH();
    }
    BYTECODE(Load4CurrentCharsUnchecked, cp_offset) {
      ADVANCE();
      DCHECK_EQ(1, sizeof(Char));
      int pos = current + cp_offset;
      current_char = Load4Characters(subject, pos);
      DISPATCH();
    }
    BYTECODE(Check4Chars, characters, on_equal) {
      if (characters == current_char) {
        SET_PC_FROM_OFFSET(on_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacter, character, on_equal) {
      if (character == current_char) {
        SET_PC_FROM_OFFSET(on_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNot4Chars, characters, on_not_equal) {
      if (characters != current_char) {
        SET_PC_FROM_OFFSET(on_not_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNotCharacter, character, on_not_equal) {
      if (character != current_char) {
        SET_PC_FROM_OFFSET(on_not_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(AndCheck4Chars, characters, mask, on_equal) {
      if (characters == (current_char & mask)) {
        SET_PC_FROM_OFFSET(on_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacterAfterAnd, character, mask, on_equal) {
      if (character == (current_char & mask)) {
        SET_PC_FROM_OFFSET(on_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(AndCheckNot4Chars, characters, mask, on_not_equal) {
      if (characters != (current_char & mask)) {
        SET_PC_FROM_OFFSET(on_not_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNotCharacterAfterAnd, character, mask, on_not_equal) {
      if (character != (current_char & mask)) {
        SET_PC_FROM_OFFSET(on_not_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNotCharacterAfterMinusAnd, character, minus, mask,
             on_not_equal) {
      if (character != ((current_char - minus) & mask)) {
        SET_PC_FROM_OFFSET(on_not_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacterInRange, from, to, on_in_range) {
      if (from <= current_char && current_char <= to) {
        SET_PC_FROM_OFFSET(on_in_range);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacterNotInRange, from, to, on_not_in_range) {
      if (from > current_char || current_char > to) {
        SET_PC_FROM_OFFSET(on_not_in_range);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckBitInTable, on_bit_set, table) {
      if (CheckBitInTable(current_char, table)) {
        SET_PC_FROM_OFFSET(on_bit_set);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacterLT, limit, on_less) {
      if (current_char < limit) {
        SET_PC_FROM_OFFSET(on_less);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckCharacterGT, limit, on_greater) {
      if (current_char > limit) {
        SET_PC_FROM_OFFSET(on_greater);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(IfRegisterLT, register_index, comparand, on_less_than) {
      if (registers[register_index] < comparand) {
        SET_PC_FROM_OFFSET(on_less_than);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(IfRegisterGE, register_index, comparand, on_greater_or_equal) {
      if (registers[register_index] >= comparand) {
        SET_PC_FROM_OFFSET(on_greater_or_equal);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(IfRegisterEqPos, register_index, on_eq) {
      if (registers[register_index] == current) {
        SET_PC_FROM_OFFSET(on_eq);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNotBackRef, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current + len > subject.length() ||
            !CompareCharsEqual(&subject[from], &subject[current], len)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckNotBackRefBackward, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current - len < 0 ||
            !CompareCharsEqual(&subject[from], &subject[current - len], len)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        SET_CURRENT_POSITION(current - len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckNotBackRefNoCaseUnicode, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current + len > subject.length() ||
            !BackRefMatchesNoCase(thread, from, current, len, subject, true)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckNotBackRefNoCase, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current + len > subject.length() ||
            !BackRefMatchesNoCase(thread, from, current, len, subject, false)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckNotBackRefNoCaseUnicodeBackward, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current - len < 0 ||
            !BackRefMatchesNoCase(thread, from, current - len, len, subject,
                                  true)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        SET_CURRENT_POSITION(current - len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckNotBackRefNoCaseBackward, start_reg, on_not_equal) {
      int from = registers[start_reg];
      int len = registers[start_reg + 1] - from;
      if (from >= 0 && len > 0) {
        if (current - len < 0 ||
            !BackRefMatchesNoCase(thread, from, current - len, len, subject,
                                  false)) {
          SET_PC_FROM_OFFSET(on_not_equal);
          DISPATCH();
        }
        SET_CURRENT_POSITION(current - len);
      }
      ADVANCE();
      DISPATCH();
    }
    BYTECODE(CheckAtStart, cp_offset, on_at_start) {
      if (current + cp_offset == 0) {
        SET_PC_FROM_OFFSET(on_at_start);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckNotAtStart, cp_offset, on_not_at_start) {
      if (current + cp_offset == 0) {
        ADVANCE();
      } else {
        SET_PC_FROM_OFFSET(on_not_at_start);
      }
      DISPATCH();
    }
    BYTECODE(SetCurrentPositionFromEnd, by) {
      ADVANCE();
      if (subject.length() - current > by) {
        SET_CURRENT_POSITION(subject.length() - by);
        current_char = subject[current - 1];
      }
      DISPATCH();
    }
    BYTECODE(CheckPosition, cp_offset, on_failure) {
      int pos = current + cp_offset;
      if (pos >= subject.length() || pos < 0) {
        SET_PC_FROM_OFFSET(on_failure);
      } else {
        ADVANCE();
      }
      DISPATCH();
    }
    BYTECODE(CheckSpecialClassRanges, character_set, on_no_match) {
      const bool match =
          CheckSpecialClassRanges<Char>(current_char, character_set);
      if (match) {
        ADVANCE();
      } else {
        SET_PC_FROM_OFFSET(on_no_match);
      }
      DISPATCH();
    }
    BYTECODE(SkipUntilChar, cp_offset, advance_by, character, on_match,
             on_no_match) {
      while (IndexIsInBounds(current + cp_offset, subject.length())) {
        current_char = subject[current + cp_offset];
        if (character == current_char) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilCharAnd, cp_offset, advance_by, character, mask,
             eats_at_least, on_match, on_no_match) {
      while (IndexIsInBounds(current + eats_at_least, subject.length())) {
        current_char = subject[current + cp_offset];
        if (character == (current_char & mask)) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilCharPosChecked, cp_offset, advance_by, character,
             eats_at_least, on_match, on_no_match) {
      while (IndexIsInBounds(current + eats_at_least, subject.length())) {
        current_char = subject[current + cp_offset];
        if (character == current_char) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilBitInTable, cp_offset, advance_by, table, on_match,
             on_no_match) {
      while (IndexIsInBounds(current + cp_offset, subject.length())) {
        current_char = subject[current + cp_offset];
        if (CheckBitInTable(current_char, table)) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilGtOrNotBitInTable, cp_offset, advance_by, character,
             table, on_match, on_no_match) {
      while (IndexIsInBounds(current + cp_offset, subject.length())) {
        current_char = subject[current + cp_offset];
        if (current_char > character) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        if (!CheckBitInTable(current_char, table)) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilCharOrChar, cp_offset, advance_by, char1, char2, on_match,
             on_no_match) {
      while (IndexIsInBounds(current + cp_offset, subject.length())) {
        current_char = subject[current + cp_offset];
        // The two if-statements below are split up intentionally, as combining
        // them seems to result in register allocation behaving quite
        // differently and slowing down the resulting code.
        if (char1 == current_char) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        if (char2 == current_char) {
          SET_PC_FROM_OFFSET(on_match);
          DISPATCH();
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_no_match);
      DISPATCH();
    }
    BYTECODE(SkipUntilOneOfMasked, cp_offset, advance_by, both_chars, both_mask,
             max_offset, chars1, mask1, chars2, mask2, on_match1, on_match2,
             on_failure) {
      DCHECK_GE(cp_offset, 0);
      DCHECK_GE(max_offset, cp_offset);
      // We should only get here in 1-byte mode.
      DCHECK_EQ(1, sizeof(Char));
      while (IndexIsInBounds(current + max_offset, subject.length())) {
        int pos = current + cp_offset;
        current_char = Load4Characters(subject, pos);
        if (both_chars == (current_char & both_mask)) {
          if (chars1 == (current_char & mask1)) {
            SET_PC_FROM_OFFSET(on_match1);
            DISPATCH();
          }
          if (chars2 == (current_char & mask2)) {
            SET_PC_FROM_OFFSET(on_match2);
            DISPATCH();
          }
        }
        ADVANCE_CURRENT_POSITION(advance_by);
      }
      SET_PC_FROM_OFFSET(on_failure);
      DISPATCH();
    }
    // MSVC: compiler limit: initializers nested too deeply
    // But only generated by optimizer that Dart disables.
    DEAD_BYTECODE(SkipUntilOneOfMasked3) {
      UNREACHABLE();
    }
    BYTECODES_END()
#if V8_USE_COMPUTED_GOTO
// Lint gets confused a lot if we just use !V8_USE_COMPUTED_GOTO or ifndef
// V8_USE_COMPUTED_GOTO here.
#else
      default:
        UNREACHABLE();
    }
  // Label we jump to in DISPATCH(). There must be no instructions between the
  // end of the switch, this label and the end of the loop.
  switch_dispatch_continuation: {}
#endif  // V8_USE_COMPUTED_GOTO
  }
}

#undef OPEN_BLOCK
#undef CLOSE_BLOCK
#undef BYTECODES_START
#undef BYTECODES_END
#undef BYTECODE
#undef ADVANCE_CURRENT_POSITION
#undef SET_CURRENT_POSITION
#undef DISPATCH
#undef DECODE
#undef SET_PC_FROM_OFFSET
#undef ADVANCE
#undef BC_LABEL
#undef V8_USE_COMPUTED_GOTO

}  // namespace

// static
int IrregexpInterpreter::Match(Thread* thread,
                               const RegExp& regexp_data,
                               const String& subject_string,
                               int* output_registers,
                               int output_register_count,
                               int start_position,
                               RegExpStatics::CallOrigin call_origin,
                               bool is_sticky) {
  // bool is_any_unicode = IsEitherUnicode((regexp_data.flags()));
  bool is_one_byte = subject_string.IsOneByteString();
  SBXCHECK(regexp_data.has_bytecode(is_one_byte, is_sticky));
  const TypedData& code_array =
      TypedData::Handle(regexp_data.bytecode(is_one_byte, is_sticky));
  int total_register_count = regexp_data.num_registers(is_one_byte);
  // MatchInternal only supports returning a single match per call. In global
  // mode, i.e. when output_registers has space for more than one match, we
  // need to keep running until all matches are filled in.
  int registers_per_match =
      JSRegExp::RegistersForCaptureCount(regexp_data.num_bracket_expressions());
  // DCHECK_LE(registers_per_match, output_register_count);
  // int number_of_matches_in_output_registers =
  // output_register_count / registers_per_match;

  int backtrack_limit = JSRegExp::kNoBacktrackLimit;

#ifdef ENABLE_DISASSEMBLER
  if (v8_flags.trace_regexp_bytecodes) {
    static constexpr uint32_t kTruncateSubjectAtLength = 64;
    const char* opt_truncated = "";
    uint32_t subject_length = subject_string->length();
    if (subject_length > kTruncateSubjectAtLength) {
      subject_length = kTruncateSubjectAtLength;
      opt_truncated = " (truncated)";
    }
    Tagged<String> pattern = Cast<String>(regexp_data->source());
    PrintF("\n\nStart bytecode interpreter. Pattern /%s/ Subject '%s'%s\n",
           pattern->ToCString().get(),
           subject_string->ToCString(0, subject_length).get(), opt_truncated);
  }
#endif

  int* current_output_registers = output_registers;
  return MatchInternal(thread, code_array, subject_string,
                       current_output_registers, registers_per_match,
                       total_register_count, start_position, call_origin,
                       backtrack_limit);
}

IrregexpInterpreter::Result IrregexpInterpreter::MatchInternal(
    Thread* thread,
    const TypedData& code_array,
    const String& subject_string,
    int* output_registers,
    int output_register_count,
    int total_register_count,
    int start_position,
    RegExpStatics::CallOrigin call_origin,
    uint32_t backtrack_limit) {
  // Note: Heap allocation *is* allowed in two situations if calling from
  // Runtime:
  // 1. When creating & throwing a stack overflow exception. The interpreter
  //    aborts afterwards, and thus possible-moved objects are never used.
  // 2. When handling interrupts. We manually relocate unhandlified references
  //    after interrupts have run.

  uint16_t previous_char = '\n';
  // Because interrupts can result in GC and string content relocation, the
  // checksum verification in FlatContent may fail even though this code is
  // safe. See (2) above.
  //subject_content.UnsafeDisableChecksumVerification();
  if (subject_string.IsOneByteString()) {
    base::Vector<const uint8_t> subject_vector;
    {
      NoSafepointScope no_safepoint(thread);
      subject_vector = {OneByteString::DataStart(subject_string),
                        (size_t)subject_string.Length()};
    }
    if (start_position != 0) previous_char = subject_vector[start_position - 1];
    return RawMatch<const uint8_t, OneByteString>(
        thread, code_array, subject_string, subject_vector, output_registers,
        output_register_count, total_register_count, start_position,
        previous_char, call_origin, backtrack_limit);
  } else {
    ASSERT(subject_string.IsTwoByteString());
    base::Vector<const uint16_t> subject_vector;
    {
      NoSafepointScope no_safepoint(thread);
      subject_vector = {TwoByteString::DataStart(subject_string),
                        (size_t)subject_string.Length()};
    }
    if (start_position != 0) previous_char = subject_vector[start_position - 1];
    return RawMatch<const uint16_t, TwoByteString>(
        thread, code_array, subject_string, subject_vector, output_registers,
        output_register_count, total_register_count, start_position,
        previous_char, call_origin, backtrack_limit);
  }
}

#ifndef COMPILING_IRREGEXP_FOR_EXTERNAL_EMBEDDER

// This method is called through an external reference from RegExpExecInternal
// builtin.
#ifdef V8_ENABLE_SANDBOX_HARDWARE_SUPPORT
// Hardware sandboxing is incompatible with ASAN, see crbug.com/432168626.
DISABLE_ASAN
#endif  // V8_ENABLE_SANDBOX_HARDWARE_SUPPORT
int IrregexpInterpreter::MatchForCallFromJs(
    Address subject,
    int32_t start_position,
    Address,
    Address,
    int* output_registers,
    int32_t output_register_count,
    RegExpStatics::CallOrigin call_origin,
    Isolate* isolate,
    Address regexp_data) {
  // TODO(422992937): investigate running the interpreter in sandboxed mode.
  ExitSandboxScope unsandboxed;

  DCHECK_NOT_NULL(isolate);
  DCHECK_NOT_NULL(output_registers);
  ASSERT(call_origin == RegExpStatics::CallOrigin::kFromJs);

  DisallowGarbageCollection no_gc;
  DisallowJavascriptExecution no_js(isolate);
  DisallowHandleAllocation no_handles;
  DisallowHandleDereference no_deref;

  Tagged<String> subject_string = Cast<String>(Tagged<Object>(subject));
  Tagged<IrRegExpData> regexp_data_obj =
      SbxCast<IrRegExpData>(Tagged<Object>(regexp_data));

  if (regexp_data_obj->MarkedForTierUp()) {
    // Returning RETRY will re-enter through runtime, where actual recompilation
    // for tier-up takes place.
    return IrregexpInterpreter::RETRY;
  }

  return Match(isolate, regexp_data_obj, subject_string, output_registers,
               output_register_count, start_position, call_origin);
}

#endif  // !COMPILING_IRREGEXP_FOR_EXTERNAL_EMBEDDER

int IrregexpInterpreter::MatchForCallFromRuntime(Thread* thread,
                                                 const RegExp& regexp_data,
                                                 const String& subject_string,
                                                 int* output_registers,
                                                 int output_register_count,
                                                 int start_position,
                                                 bool is_sticky) {
  return Match(thread, regexp_data, subject_string, output_registers,
               output_register_count, start_position,
               RegExpStatics::CallOrigin::kFromRuntime, is_sticky);
}

}  // namespace dart
