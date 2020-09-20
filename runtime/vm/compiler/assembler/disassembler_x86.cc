// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A combined disassembler for IA32 and X64.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_xxx.
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)

#include "vm/compiler/assembler/disassembler.h"

#include "platform/unaligned.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/constants_x86.h"
#include "vm/heap/heap.h"
#include "vm/instructions.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

enum OperandType {
  UNSET_OP_ORDER = 0,
  // Operand size decides between 16, 32 and 64 bit operands.
  REG_OPER_OP_ORDER = 1,  // Register destination, operand source.
  OPER_REG_OP_ORDER = 2,  // Operand destination, register source.
  // Fixed 8-bit operands.
  BYTE_SIZE_OPERAND_FLAG = 4,
  BYTE_REG_OPER_OP_ORDER = REG_OPER_OP_ORDER | BYTE_SIZE_OPERAND_FLAG,
  BYTE_OPER_REG_OP_ORDER = OPER_REG_OP_ORDER | BYTE_SIZE_OPERAND_FLAG
};

//------------------------------------------------------------------
// Tables
//------------------------------------------------------------------
struct ByteMnemonic {
  int b;  // -1 terminates, otherwise must be in range (0..255)
  OperandType op_order_;
  const char* mnem;
};

#define ALU_ENTRY(name, code)                                                  \
  {code * 8 + 0, BYTE_OPER_REG_OP_ORDER, #name},                               \
      {code * 8 + 1, OPER_REG_OP_ORDER, #name},                                \
      {code * 8 + 2, BYTE_REG_OPER_OP_ORDER, #name},                           \
      {code * 8 + 3, REG_OPER_OP_ORDER, #name},
static const ByteMnemonic two_operands_instr[] = {
    X86_ALU_CODES(ALU_ENTRY){0x63, REG_OPER_OP_ORDER, "movsxd"},
    {0x84, BYTE_REG_OPER_OP_ORDER, "test"},
    {0x85, REG_OPER_OP_ORDER, "test"},
    {0x86, BYTE_REG_OPER_OP_ORDER, "xchg"},
    {0x87, REG_OPER_OP_ORDER, "xchg"},
    {0x88, BYTE_OPER_REG_OP_ORDER, "mov"},
    {0x89, OPER_REG_OP_ORDER, "mov"},
    {0x8A, BYTE_REG_OPER_OP_ORDER, "mov"},
    {0x8B, REG_OPER_OP_ORDER, "mov"},
    {0x8D, REG_OPER_OP_ORDER, "lea"},
    {-1, UNSET_OP_ORDER, ""}};

#define ZERO_OPERAND_ENTRY(name, opcode) {opcode, UNSET_OP_ORDER, #name},
static const ByteMnemonic zero_operands_instr[] = {
    X86_ZERO_OPERAND_1_BYTE_INSTRUCTIONS(ZERO_OPERAND_ENTRY){-1, UNSET_OP_ORDER,
                                                             ""}};

static const ByteMnemonic call_jump_instr[] = {{0xE8, UNSET_OP_ORDER, "call"},
                                               {0xE9, UNSET_OP_ORDER, "jmp"},
                                               {-1, UNSET_OP_ORDER, ""}};

#define SHORT_IMMEDIATE_ENTRY(name, code) {code * 8 + 5, UNSET_OP_ORDER, #name},
static const ByteMnemonic short_immediate_instr[] = {
    X86_ALU_CODES(SHORT_IMMEDIATE_ENTRY){-1, UNSET_OP_ORDER, ""}};

static const char* const conditional_code_suffix[] = {
#define STRINGIFY(name, number) #name,
    X86_CONDITIONAL_SUFFIXES(STRINGIFY)
#undef STRINGIFY
};

#define STRINGIFY_NAME(name, code) #name,
static const char* const xmm_conditional_code_suffix[] = {
    XMM_CONDITIONAL_CODES(STRINGIFY_NAME)};
#undef STRINGIFY_NAME

enum InstructionType {
  NO_INSTR,
  ZERO_OPERANDS_INSTR,
  TWO_OPERANDS_INSTR,
  JUMP_CONDITIONAL_SHORT_INSTR,
  REGISTER_INSTR,
  PUSHPOP_INSTR,  // Has implicit 64-bit operand size.
  MOVE_REG_INSTR,
  CALL_JUMP_INSTR,
  SHORT_IMMEDIATE_INSTR
};

enum Prefixes {
  ESCAPE_PREFIX = 0x0F,
  OPERAND_SIZE_OVERRIDE_PREFIX = 0x66,
  ADDRESS_SIZE_OVERRIDE_PREFIX = 0x67,
  REPNE_PREFIX = 0xF2,
  REP_PREFIX = 0xF3,
  REPEQ_PREFIX = REP_PREFIX
};

struct XmmMnemonic {
  const char* ps_name;
  const char* pd_name;
  const char* ss_name;
  const char* sd_name;
};

#define XMM_INSTRUCTION_ENTRY(name, code)                                      \
  {#name "ps", #name "pd", #name "ss", #name "sd"},
static const XmmMnemonic xmm_instructions[] = {
    XMM_ALU_CODES(XMM_INSTRUCTION_ENTRY)};

struct InstructionDesc {
  const char* mnem;
  InstructionType type;
  OperandType op_order_;
  bool byte_size_operation;  // Fixed 8-bit operation.
};

class InstructionTable : public ValueObject {
 public:
  InstructionTable();
  const InstructionDesc& Get(uint8_t x) const { return instructions_[x]; }

 private:
  InstructionDesc instructions_[256];
  void Clear();
  void Init();
  void CopyTable(const ByteMnemonic bm[], InstructionType type);
  void SetTableRange(InstructionType type,
                     uint8_t start,
                     uint8_t end,
                     bool byte_size,
                     const char* mnem);
  void AddJumpConditionalShort();

  DISALLOW_COPY_AND_ASSIGN(InstructionTable);
};

InstructionTable::InstructionTable() {
  Clear();
  Init();
}

void InstructionTable::Clear() {
  for (int i = 0; i < 256; i++) {
    instructions_[i].mnem = "(bad)";
    instructions_[i].type = NO_INSTR;
    instructions_[i].op_order_ = UNSET_OP_ORDER;
    instructions_[i].byte_size_operation = false;
  }
}

void InstructionTable::Init() {
  CopyTable(two_operands_instr, TWO_OPERANDS_INSTR);
  CopyTable(zero_operands_instr, ZERO_OPERANDS_INSTR);
  CopyTable(call_jump_instr, CALL_JUMP_INSTR);
  CopyTable(short_immediate_instr, SHORT_IMMEDIATE_INSTR);
  AddJumpConditionalShort();
  SetTableRange(PUSHPOP_INSTR, 0x50, 0x57, false, "push");
  SetTableRange(PUSHPOP_INSTR, 0x58, 0x5F, false, "pop");
  SetTableRange(MOVE_REG_INSTR, 0xB8, 0xBF, false, "mov");
}

void InstructionTable::CopyTable(const ByteMnemonic bm[],
                                 InstructionType type) {
  for (int i = 0; bm[i].b >= 0; i++) {
    InstructionDesc* id = &instructions_[bm[i].b];
    id->mnem = bm[i].mnem;
    OperandType op_order = bm[i].op_order_;
    id->op_order_ =
        static_cast<OperandType>(op_order & ~BYTE_SIZE_OPERAND_FLAG);
    ASSERT(NO_INSTR == id->type);  // Information not already entered
    id->type = type;
    id->byte_size_operation = ((op_order & BYTE_SIZE_OPERAND_FLAG) != 0);
  }
}

void InstructionTable::SetTableRange(InstructionType type,
                                     uint8_t start,
                                     uint8_t end,
                                     bool byte_size,
                                     const char* mnem) {
  for (uint8_t b = start; b <= end; b++) {
    InstructionDesc* id = &instructions_[b];
    ASSERT(NO_INSTR == id->type);  // Information not already entered
    id->mnem = mnem;
    id->type = type;
    id->byte_size_operation = byte_size;
  }
}

void InstructionTable::AddJumpConditionalShort() {
  for (uint8_t b = 0x70; b <= 0x7F; b++) {
    InstructionDesc* id = &instructions_[b];
    ASSERT(NO_INSTR == id->type);  // Information not already entered
    id->mnem = NULL;               // Computed depending on condition code.
    id->type = JUMP_CONDITIONAL_SHORT_INSTR;
  }
}

static InstructionTable instruction_table;

static InstructionDesc cmov_instructions[16] = {
    {"cmovo", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovno", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovc", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovnc", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovz", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovnz", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovna", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmova", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovs", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovns", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovpe", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovpo", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovl", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovge", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovle", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false},
    {"cmovg", TWO_OPERANDS_INSTR, REG_OPER_OP_ORDER, false}};

//-------------------------------------------------
// DisassemblerX64 implementation.

static const int kMaxXmmRegisters = 16;
static const char* xmm_regs[kMaxXmmRegisters] = {
    "xmm0", "xmm1", "xmm2",  "xmm3",  "xmm4",  "xmm5",  "xmm6",  "xmm7",
    "xmm8", "xmm9", "xmm10", "xmm11", "xmm12", "xmm13", "xmm14", "xmm15"};

class DisassemblerX64 : public ValueObject {
 public:
  DisassemblerX64(char* buffer, intptr_t buffer_size)
      : buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0),
        rex_(0),
        operand_size_(0),
        group_1_prefix_(0),
        byte_size_operand_(false) {
    buffer_[buffer_pos_] = '\0';
  }

  virtual ~DisassemblerX64() {}

  int InstructionDecode(uword pc);

 private:
  enum OperandSize {
    BYTE_SIZE = 0,
    WORD_SIZE = 1,
    DOUBLEWORD_SIZE = 2,
    QUADWORD_SIZE = 3
  };

  void setRex(uint8_t rex) {
    ASSERT(0x40 == (rex & 0xF0));
    rex_ = rex;
  }

  bool rex() { return rex_ != 0; }

  bool rex_b() { return (rex_ & 0x01) != 0; }

  // Actual number of base register given the low bits and the rex.b state.
  int base_reg(int low_bits) { return low_bits | ((rex_ & 0x01) << 3); }

  bool rex_x() { return (rex_ & 0x02) != 0; }

  bool rex_r() { return (rex_ & 0x04) != 0; }

  bool rex_w() { return (rex_ & 0x08) != 0; }

  OperandSize operand_size() {
    if (byte_size_operand_) return BYTE_SIZE;
    if (rex_w()) return QUADWORD_SIZE;
    if (operand_size_ != 0) return WORD_SIZE;
    return DOUBLEWORD_SIZE;
  }

  const char* operand_size_code() {
#if defined(TARGET_ARCH_X64)
    return &"b\0w\0l\0q\0"[2 * operand_size()];
#else
    // We omit the 'l' suffix on IA32.
    return &"b\0w\0\0\0q\0"[2 * operand_size()];
#endif
  }

  // Disassembler helper functions.
  void get_modrm(uint8_t data, int* mod, int* regop, int* rm) {
    *mod = (data >> 6) & 3;
    *regop = ((data & 0x38) >> 3) | (rex_r() ? 8 : 0);
    *rm = (data & 7) | (rex_b() ? 8 : 0);
    ASSERT(*rm < kNumberOfCpuRegisters);
  }

  void get_sib(uint8_t data, int* scale, int* index, int* base) {
    *scale = (data >> 6) & 3;
    *index = ((data >> 3) & 7) | (rex_x() ? 8 : 0);
    *base = (data & 7) | (rex_b() ? 8 : 0);
    ASSERT(*base < kNumberOfCpuRegisters);
  }

  const char* NameOfCPURegister(int reg) const {
    return RegisterNames::RegisterName(static_cast<Register>(reg));
  }

  const char* NameOfByteCPURegister(int reg) const {
    return NameOfCPURegister(reg);
  }

  // A way to get rax or eax's name.
  const char* Rax() const { return NameOfCPURegister(0); }

  const char* NameOfXMMRegister(int reg) const {
    ASSERT((0 <= reg) && (reg < kMaxXmmRegisters));
    return xmm_regs[reg];
  }

  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  void PrintJump(uint8_t* pc, int32_t disp);
  void PrintAddress(uint8_t* addr);

  int PrintOperands(const char* mnem, OperandType op_order, uint8_t* data);

  typedef const char* (DisassemblerX64::*RegisterNameMapping)(int reg) const;

  int PrintRightOperandHelper(uint8_t* modrmp,
                              RegisterNameMapping register_name);
  int PrintRightOperand(uint8_t* modrmp);
  int PrintRightByteOperand(uint8_t* modrmp);
  int PrintRightXMMOperand(uint8_t* modrmp);
  void PrintDisp(int disp, const char* after);
  int PrintImmediate(uint8_t* data, OperandSize size, bool sign_extend = false);
  void PrintImmediateValue(int64_t value,
                           bool signed_value = false,
                           int byte_count = -1);
  int PrintImmediateOp(uint8_t* data);
  const char* TwoByteMnemonic(uint8_t opcode);
  int TwoByteOpcodeInstruction(uint8_t* data);
  int Print660F38Instruction(uint8_t* data);

  int F6F7Instruction(uint8_t* data);
  int ShiftInstruction(uint8_t* data);
  int JumpShort(uint8_t* data);
  int JumpConditional(uint8_t* data);
  int JumpConditionalShort(uint8_t* data);
  int SetCC(uint8_t* data);
  int FPUInstruction(uint8_t* data);
  int MemoryFPUInstruction(int escape_opcode, int regop, uint8_t* modrm_start);
  int RegisterFPUInstruction(int escape_opcode, uint8_t modrm_byte);

  bool DecodeInstructionType(uint8_t** data);

  void UnimplementedInstruction() { UNREACHABLE(); }

  char* buffer_;          // Decode instructions into this buffer.
  intptr_t buffer_size_;  // The size of the buffer_.
  intptr_t buffer_pos_;   // Current character position in the buffer_.

  // Prefixes parsed
  uint8_t rex_;
  uint8_t operand_size_;  // 0x66 or (if no group 3 prefix is present) 0x0.
  // 0xF2, 0xF3, or (if no group 1 prefix is present) 0.
  uint8_t group_1_prefix_;
  // Byte size operand override.
  bool byte_size_operand_;

  DISALLOW_COPY_AND_ASSIGN(DisassemblerX64);
};

// Append the str to the output buffer.
void DisassemblerX64::Print(const char* format, ...) {
  intptr_t available = buffer_size_ - buffer_pos_;
  if (available <= 1) {
    ASSERT(buffer_[buffer_pos_] == '\0');
    return;
  }
  char* buf = buffer_ + buffer_pos_;
  va_list args;
  va_start(args, format);
  int length = Utils::VSNPrint(buf, available, format, args);
  va_end(args);
  buffer_pos_ =
      (length >= available) ? (buffer_size_ - 1) : (buffer_pos_ + length);
  ASSERT(buffer_pos_ < buffer_size_);
}

int DisassemblerX64::PrintRightOperandHelper(
    uint8_t* modrmp,
    RegisterNameMapping direct_register_name) {
  int mod, regop, rm;
  get_modrm(*modrmp, &mod, &regop, &rm);
  RegisterNameMapping register_name =
      (mod == 3) ? direct_register_name : &DisassemblerX64::NameOfCPURegister;
  switch (mod) {
    case 0:
      if ((rm & 7) == 5) {
        int32_t disp = LoadUnaligned(reinterpret_cast<int32_t*>(modrmp + 1));
        Print("[rip");
        PrintDisp(disp, "]");
        return 5;
      } else if ((rm & 7) == 4) {
        // Codes for SIB byte.
        uint8_t sib = *(modrmp + 1);
        int scale, index, base;
        get_sib(sib, &scale, &index, &base);
        if (index == 4 && (base & 7) == 4 && scale == 0 /*times_1*/) {
          // index == rsp means no index. Only use sib byte with no index for
          // rsp and r12 base.
          Print("[%s]", NameOfCPURegister(base));
          return 2;
        } else if (base == 5) {
          // base == rbp means no base register (when mod == 0).
          int32_t disp = LoadUnaligned(reinterpret_cast<int32_t*>(modrmp + 2));
          Print("[%s*%d", NameOfCPURegister(index), 1 << scale);
          PrintDisp(disp, "]");
          return 6;
        } else if (index != 4 && base != 5) {
          // [base+index*scale]
          Print("[%s+%s*%d]", NameOfCPURegister(base), NameOfCPURegister(index),
                1 << scale);
          return 2;
        } else {
          UnimplementedInstruction();
          return 1;
        }
      } else {
        Print("[%s]", NameOfCPURegister(rm));
        return 1;
      }
      break;
    case 1:
      FALL_THROUGH;
    case 2:
      if ((rm & 7) == 4) {
        uint8_t sib = *(modrmp + 1);
        int scale, index, base;
        get_sib(sib, &scale, &index, &base);
        int disp = (mod == 2)
                       ? LoadUnaligned(reinterpret_cast<int32_t*>(modrmp + 2))
                       : *reinterpret_cast<int8_t*>(modrmp + 2);
        if (index == 4 && (base & 7) == 4 && scale == 0 /*times_1*/) {
          Print("[%s", NameOfCPURegister(base));
          PrintDisp(disp, "]");
        } else {
          Print("[%s+%s*%d", NameOfCPURegister(base), NameOfCPURegister(index),
                1 << scale);
          PrintDisp(disp, "]");
        }
        return mod == 2 ? 6 : 3;
      } else {
        // No sib.
        int disp = (mod == 2)
                       ? LoadUnaligned(reinterpret_cast<int32_t*>(modrmp + 1))
                       : *reinterpret_cast<int8_t*>(modrmp + 1);
        Print("[%s", NameOfCPURegister(rm));
        PrintDisp(disp, "]");
        return (mod == 2) ? 5 : 2;
      }
      break;
    case 3:
      Print("%s", (this->*register_name)(rm));
      return 1;
    default:
      UnimplementedInstruction();
      return 1;
  }
  UNREACHABLE();
}

int DisassemblerX64::PrintImmediate(uint8_t* data,
                                    OperandSize size,
                                    bool sign_extend) {
  int64_t value;
  int count;
  switch (size) {
    case BYTE_SIZE:
      if (sign_extend) {
        value = *reinterpret_cast<int8_t*>(data);
      } else {
        value = *data;
      }
      count = 1;
      break;
    case WORD_SIZE:
      if (sign_extend) {
        value = LoadUnaligned(reinterpret_cast<int16_t*>(data));
      } else {
        value = LoadUnaligned(reinterpret_cast<uint16_t*>(data));
      }
      count = 2;
      break;
    case DOUBLEWORD_SIZE:
    case QUADWORD_SIZE:
      if (sign_extend) {
        value = LoadUnaligned(reinterpret_cast<int32_t*>(data));
      } else {
        value = LoadUnaligned(reinterpret_cast<uint32_t*>(data));
      }
      count = 4;
      break;
    default:
      UNREACHABLE();
      value = 0;  // Initialize variables on all paths to satisfy the compiler.
      count = 0;
  }
  PrintImmediateValue(value, sign_extend, count);
  return count;
}

void DisassemblerX64::PrintImmediateValue(int64_t value,
                                          bool signed_value,
                                          int byte_count) {
  if ((value >= 0) && (value <= 9)) {
    Print("%" Pd64, value);
  } else if (signed_value && (value < 0) && (value >= -9)) {
    Print("-%" Pd64, -value);
  } else {
    if (byte_count == 1) {
      int8_t v8 = static_cast<int8_t>(value);
      if (v8 < 0 && signed_value) {
        Print("-%#" Px32, -static_cast<uint8_t>(v8));
      } else {
        Print("%#" Px32, static_cast<uint8_t>(v8));
      }
    } else if (byte_count == 2) {
      int16_t v16 = static_cast<int16_t>(value);
      if (v16 < 0 && signed_value) {
        Print("-%#" Px32, -static_cast<uint16_t>(v16));
      } else {
        Print("%#" Px32, static_cast<uint16_t>(v16));
      }
    } else if (byte_count == 4) {
      int32_t v32 = static_cast<int32_t>(value);
      if (v32 < 0 && signed_value) {
        Print("-%#010" Px32, -static_cast<uint32_t>(v32));
      } else {
        if (v32 > 0xffff) {
          Print("%#010" Px32, v32);
        } else {
          Print("%#" Px32, v32);
        }
      }
    } else if (byte_count == 8) {
      int64_t v64 = static_cast<int64_t>(value);
      if (v64 < 0 && signed_value) {
        Print("-%#018" Px64, -static_cast<uint64_t>(v64));
      } else {
        if (v64 > 0xffffffffll) {
          Print("%#018" Px64, v64);
        } else {
          Print("%#" Px64, v64);
        }
      }
    } else {
// Natural-sized immediates.
#if defined(TARGET_ARCH_X64)
      if (value < 0 && signed_value) {
        Print("-%#" Px64, -value);
      } else {
        Print("%#" Px64, value);
      }
#else
      int32_t v32 = static_cast<int32_t>(value);
      if (v32 < 0 && signed_value) {
        Print("-%#" Px32, -v32);
      } else {
        Print("%#" Px32, v32);
      }
#endif
    }
  }
}

void DisassemblerX64::PrintDisp(int disp, const char* after) {
  if (-disp > 0) {
    Print("-%#x", -disp);
  } else {
    Print("+%#x", disp);
  }
  if (after != NULL) Print("%s", after);
}

// Returns number of bytes used by machine instruction, including *data byte.
// Writes immediate instructions to 'tmp_buffer_'.
int DisassemblerX64::PrintImmediateOp(uint8_t* data) {
  bool byte_size_immediate = (*data & 0x03) != 1;
  uint8_t modrm = *(data + 1);
  int mod, regop, rm;
  get_modrm(modrm, &mod, &regop, &rm);
  const char* mnem = "Imm???";
  switch (regop) {
    case 0:
      mnem = "add";
      break;
    case 1:
      mnem = "or";
      break;
    case 2:
      mnem = "adc";
      break;
    case 3:
      mnem = "sbb";
      break;
    case 4:
      mnem = "and";
      break;
    case 5:
      mnem = "sub";
      break;
    case 6:
      mnem = "xor";
      break;
    case 7:
      mnem = "cmp";
      break;
    default:
      UnimplementedInstruction();
  }
  Print("%s%s ", mnem, operand_size_code());
  int count = PrintRightOperand(data + 1);
  Print(",");
  OperandSize immediate_size = byte_size_immediate ? BYTE_SIZE : operand_size();
  count +=
      PrintImmediate(data + 1 + count, immediate_size, byte_size_immediate);
  return 1 + count;
}

// Returns number of bytes used, including *data.
int DisassemblerX64::F6F7Instruction(uint8_t* data) {
  ASSERT(*data == 0xF7 || *data == 0xF6);
  uint8_t modrm = *(data + 1);
  int mod, regop, rm;
  get_modrm(modrm, &mod, &regop, &rm);
  static const char* mnemonics[] = {"test", NULL,   "not", "neg",
                                    "mul",  "imul", "div", "idiv"};
  const char* mnem = mnemonics[regop];
  if (mod == 3 && regop != 0) {
    if (regop > 3) {
      // These are instructions like idiv that implicitly use EAX and EDX as a
      // source and destination. We make this explicit in the disassembly.
      Print("%s%s (%s,%s),%s", mnem, operand_size_code(), Rax(),
            NameOfCPURegister(2), NameOfCPURegister(rm));
    } else {
      Print("%s%s %s", mnem, operand_size_code(), NameOfCPURegister(rm));
    }
    return 2;
  } else if (regop == 0) {
    Print("test%s ", operand_size_code());
    int count = PrintRightOperand(data + 1);  // Use name of 64-bit register.
    Print(",");
    count += PrintImmediate(data + 1 + count, operand_size());
    return 1 + count;
  } else if (regop >= 4) {
    Print("%s%s (%s,%s),", mnem, operand_size_code(), Rax(),
          NameOfCPURegister(2));
    return 1 + PrintRightOperand(data + 1);
  } else {
    UnimplementedInstruction();
    return 2;
  }
}

int DisassemblerX64::ShiftInstruction(uint8_t* data) {
  // C0/C1: Shift Imm8
  // D0/D1: Shift 1
  // D2/D3: Shift CL
  uint8_t op = *data & (~1);
  if (op != 0xD0 && op != 0xD2 && op != 0xC0) {
    UnimplementedInstruction();
    return 1;
  }
  uint8_t* modrm = data + 1;
  int mod, regop, rm;
  get_modrm(*modrm, &mod, &regop, &rm);
  regop &= 0x7;  // The REX.R bit does not affect the operation.
  int num_bytes = 1;
  const char* mnem = NULL;
  switch (regop) {
    case 0:
      mnem = "rol";
      break;
    case 1:
      mnem = "ror";
      break;
    case 2:
      mnem = "rcl";
      break;
    case 3:
      mnem = "rcr";
      break;
    case 4:
      mnem = "shl";
      break;
    case 5:
      mnem = "shr";
      break;
    case 7:
      mnem = "sar";
      break;
    default:
      UnimplementedInstruction();
      return num_bytes;
  }
  ASSERT(NULL != mnem);
  Print("%s%s ", mnem, operand_size_code());
  if (byte_size_operand_) {
    num_bytes += PrintRightByteOperand(modrm);
  } else {
    num_bytes += PrintRightOperand(modrm);
  }

  if (op == 0xD0) {
    Print(",1");
  } else if (op == 0xC0) {
    uint8_t imm8 = *(data + num_bytes);
    Print(",%d", imm8);
    num_bytes++;
  } else {
    ASSERT(op == 0xD2);
    Print(",cl");
  }
  return num_bytes;
}

int DisassemblerX64::PrintRightOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp, &DisassemblerX64::NameOfCPURegister);
}

int DisassemblerX64::PrintRightByteOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp,
                                 &DisassemblerX64::NameOfByteCPURegister);
}

int DisassemblerX64::PrintRightXMMOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp, &DisassemblerX64::NameOfXMMRegister);
}

// Returns number of bytes used including the current *data.
// Writes instruction's mnemonic, left and right operands to 'tmp_buffer_'.
int DisassemblerX64::PrintOperands(const char* mnem,
                                   OperandType op_order,
                                   uint8_t* data) {
  uint8_t modrm = *data;
  int mod, regop, rm;
  get_modrm(modrm, &mod, &regop, &rm);
  int advance = 0;
  const char* register_name = byte_size_operand_ ? NameOfByteCPURegister(regop)
                                                 : NameOfCPURegister(regop);
  switch (op_order) {
    case REG_OPER_OP_ORDER: {
      Print("%s%s %s,", mnem, operand_size_code(), register_name);
      advance = byte_size_operand_ ? PrintRightByteOperand(data)
                                   : PrintRightOperand(data);
      break;
    }
    case OPER_REG_OP_ORDER: {
      Print("%s%s ", mnem, operand_size_code());
      advance = byte_size_operand_ ? PrintRightByteOperand(data)
                                   : PrintRightOperand(data);
      Print(",%s", register_name);
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
  return advance;
}

void DisassemblerX64::PrintJump(uint8_t* pc, int32_t disp) {
  if (FLAG_disassemble_relative) {
    Print("%+d", disp);
  } else {
    PrintAddress(
        reinterpret_cast<uint8_t*>(reinterpret_cast<uintptr_t>(pc) + disp));
  }
}

void DisassemblerX64::PrintAddress(uint8_t* addr_byte_ptr) {
#if defined(TARGET_ARCH_X64)
  Print("%#018" Px64 "", reinterpret_cast<uint64_t>(addr_byte_ptr));
#else
  Print("%#010" Px32 "", reinterpret_cast<uint32_t>(addr_byte_ptr));
#endif

  // Try to print as stub name.
  uword addr = reinterpret_cast<uword>(addr_byte_ptr);
  const char* name_of_stub = StubCode::NameOfStub(addr);
  if (name_of_stub != NULL) {
    Print("  [stub: %s]", name_of_stub);
  }
}
// Returns number of bytes used, including *data.
int DisassemblerX64::JumpShort(uint8_t* data) {
  ASSERT(0xEB == *data);
  uint8_t b = *(data + 1);
  int32_t disp = static_cast<int8_t>(b) + 2;
  Print("jmp ");
  PrintJump(data, disp);
  return 2;
}

// Returns number of bytes used, including *data.
int DisassemblerX64::JumpConditional(uint8_t* data) {
  ASSERT(0x0F == *data);
  uint8_t cond = *(data + 1) & 0x0F;
  int32_t disp = LoadUnaligned(reinterpret_cast<int32_t*>(data + 2)) + 6;
  const char* mnem = conditional_code_suffix[cond];
  Print("j%s ", mnem);
  PrintJump(data, disp);
  return 6;  // includes 0x0F
}

// Returns number of bytes used, including *data.
int DisassemblerX64::JumpConditionalShort(uint8_t* data) {
  uint8_t cond = *data & 0x0F;
  uint8_t b = *(data + 1);
  int32_t disp = static_cast<int8_t>(b) + 2;
  const char* mnem = conditional_code_suffix[cond];
  Print("j%s ", mnem);
  PrintJump(data, disp);
  return 2;
}

// Returns number of bytes used, including *data.
int DisassemblerX64::SetCC(uint8_t* data) {
  ASSERT(0x0F == *data);
  uint8_t cond = *(data + 1) & 0x0F;
  const char* mnem = conditional_code_suffix[cond];
  Print("set%s%s ", mnem, operand_size_code());
  PrintRightByteOperand(data + 2);
  return 3;  // includes 0x0F
}

// Returns number of bytes used, including *data.
int DisassemblerX64::FPUInstruction(uint8_t* data) {
  uint8_t escape_opcode = *data;
  ASSERT(0xD8 == (escape_opcode & 0xF8));
  uint8_t modrm_byte = *(data + 1);

  if (modrm_byte >= 0xC0) {
    return RegisterFPUInstruction(escape_opcode, modrm_byte);
  } else {
    return MemoryFPUInstruction(escape_opcode, modrm_byte, data + 1);
  }
}

int DisassemblerX64::MemoryFPUInstruction(int escape_opcode,
                                          int modrm_byte,
                                          uint8_t* modrm_start) {
  const char* mnem = "?";
  int regop = (modrm_byte >> 3) & 0x7;  // reg/op field of modrm byte.
  switch (escape_opcode) {
    case 0xD9:
      switch (regop) {
        case 0:
          mnem = "fld_s";
          break;
        case 3:
          mnem = "fstp_s";
          break;
        case 5:
          mnem = "fldcw";
          break;
        case 7:
          mnem = "fnstcw";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    case 0xDB:
      switch (regop) {
        case 0:
          mnem = "fild_s";
          break;
        case 1:
          mnem = "fisttp_s";
          break;
        case 2:
          mnem = "fist_s";
          break;
        case 3:
          mnem = "fistp_s";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    case 0xDD:
      switch (regop) {
        case 0:
          mnem = "fld_d";
          break;
        case 3:
          mnem = "fstp_d";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    case 0xDF:
      switch (regop) {
        case 5:
          mnem = "fild_d";
          break;
        case 7:
          mnem = "fistp_d";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    default:
      UnimplementedInstruction();
  }
  Print("%s ", mnem);
  int count = PrintRightOperand(modrm_start);
  return count + 1;
}

int DisassemblerX64::RegisterFPUInstruction(int escape_opcode,
                                            uint8_t modrm_byte) {
  bool has_register = false;  // Is the FPU register encoded in modrm_byte?
  const char* mnem = "?";

  switch (escape_opcode) {
    case 0xD8:
      UnimplementedInstruction();
      break;

    case 0xD9:
      switch (modrm_byte & 0xF8) {
        case 0xC0:
          mnem = "fld";
          has_register = true;
          break;
        case 0xC8:
          mnem = "fxch";
          has_register = true;
          break;
        default:
          switch (modrm_byte) {
            case 0xE0:
              mnem = "fchs";
              break;
            case 0xE1:
              mnem = "fabs";
              break;
            case 0xE3:
              mnem = "fninit";
              break;
            case 0xE4:
              mnem = "ftst";
              break;
            case 0xE8:
              mnem = "fld1";
              break;
            case 0xEB:
              mnem = "fldpi";
              break;
            case 0xED:
              mnem = "fldln2";
              break;
            case 0xEE:
              mnem = "fldz";
              break;
            case 0xF0:
              mnem = "f2xm1";
              break;
            case 0xF1:
              mnem = "fyl2x";
              break;
            case 0xF2:
              mnem = "fptan";
              break;
            case 0xF5:
              mnem = "fprem1";
              break;
            case 0xF7:
              mnem = "fincstp";
              break;
            case 0xF8:
              mnem = "fprem";
              break;
            case 0xFB:
              mnem = "fsincos";
              break;
            case 0xFD:
              mnem = "fscale";
              break;
            case 0xFE:
              mnem = "fsin";
              break;
            case 0xFF:
              mnem = "fcos";
              break;
            default:
              UnimplementedInstruction();
          }
      }
      break;

    case 0xDA:
      if (modrm_byte == 0xE9) {
        mnem = "fucompp";
      } else {
        UnimplementedInstruction();
      }
      break;

    case 0xDB:
      if ((modrm_byte & 0xF8) == 0xE8) {
        mnem = "fucomi";
        has_register = true;
      } else if (modrm_byte == 0xE2) {
        mnem = "fclex";
      } else {
        UnimplementedInstruction();
      }
      break;

    case 0xDC:
      has_register = true;
      switch (modrm_byte & 0xF8) {
        case 0xC0:
          mnem = "fadd";
          break;
        case 0xE8:
          mnem = "fsub";
          break;
        case 0xC8:
          mnem = "fmul";
          break;
        case 0xF8:
          mnem = "fdiv";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    case 0xDD:
      has_register = true;
      switch (modrm_byte & 0xF8) {
        case 0xC0:
          mnem = "ffree";
          break;
        case 0xD8:
          mnem = "fstp";
          break;
        default:
          UnimplementedInstruction();
      }
      break;

    case 0xDE:
      if (modrm_byte == 0xD9) {
        mnem = "fcompp";
      } else {
        has_register = true;
        switch (modrm_byte & 0xF8) {
          case 0xC0:
            mnem = "faddp";
            break;
          case 0xE8:
            mnem = "fsubp";
            break;
          case 0xC8:
            mnem = "fmulp";
            break;
          case 0xF8:
            mnem = "fdivp";
            break;
          default:
            UnimplementedInstruction();
        }
      }
      break;

    case 0xDF:
      if (modrm_byte == 0xE0) {
        mnem = "fnstsw_ax";
      } else if ((modrm_byte & 0xF8) == 0xE8) {
        mnem = "fucomip";
        has_register = true;
      }
      break;

    default:
      UnimplementedInstruction();
  }

  if (has_register) {
    Print("%s st%d", mnem, modrm_byte & 0x7);
  } else {
    Print("%s", mnem);
  }
  return 2;
}

// TODO(srdjan): Should we add a branch hint argument?
bool DisassemblerX64::DecodeInstructionType(uint8_t** data) {
  uint8_t current;

  // Scan for prefixes.
  while (true) {
    current = **data;
    if (current == OPERAND_SIZE_OVERRIDE_PREFIX) {  // Group 3 prefix.
      operand_size_ = current;
#if defined(TARGET_ARCH_X64)
    } else if ((current & 0xF0) == 0x40) {
      // REX prefix.
      setRex(current);
// TODO(srdjan): Should we enable printing of REX.W?
// if (rex_w()) Print("REX.W ");
#endif
    } else if ((current & 0xFE) == 0xF2) {  // Group 1 prefix (0xF2 or 0xF3).
      group_1_prefix_ = current;
    } else if (current == 0xF0) {
      Print("lock ");
    } else {  // Not a prefix - an opcode.
      break;
    }
    (*data)++;
  }

  const InstructionDesc& idesc = instruction_table.Get(current);
  byte_size_operand_ = idesc.byte_size_operation;

  switch (idesc.type) {
    case ZERO_OPERANDS_INSTR:
      if (current >= 0xA4 && current <= 0xA7) {
        // String move or compare operations.
        if (group_1_prefix_ == REP_PREFIX) {
          // REP.
          Print("rep ");
        }
        if ((current & 0x01) == 0x01) {
          // Operation size: word, dword or qword
          switch (operand_size()) {
            case WORD_SIZE:
              Print("%sw", idesc.mnem);
              break;
            case DOUBLEWORD_SIZE:
              Print("%sl", idesc.mnem);
              break;
            case QUADWORD_SIZE:
              Print("%sq", idesc.mnem);
              break;
            default:
              UNREACHABLE();
          }
        } else {
          // Operation size: byte
          Print("%s", idesc.mnem);
        }
      } else if (current == 0x99 && rex_w()) {
        Print("cqo");  // Cdql is called cdq and cdqq is called cqo.
      } else {
        Print("%s", idesc.mnem);
      }
      (*data)++;
      break;

    case TWO_OPERANDS_INSTR:
      (*data)++;
      (*data) += PrintOperands(idesc.mnem, idesc.op_order_, *data);
      break;

    case JUMP_CONDITIONAL_SHORT_INSTR:
      (*data) += JumpConditionalShort(*data);
      break;

    case REGISTER_INSTR:
      Print("%s%s %s", idesc.mnem, operand_size_code(),
            NameOfCPURegister(base_reg(current & 0x07)));
      (*data)++;
      break;
    case PUSHPOP_INSTR:
      Print("%s %s", idesc.mnem, NameOfCPURegister(base_reg(current & 0x07)));
      (*data)++;
      break;
    case MOVE_REG_INSTR: {
      intptr_t addr = 0;
      int imm_bytes = 0;
      switch (operand_size()) {
        case WORD_SIZE:
          addr = LoadUnaligned(reinterpret_cast<int16_t*>(*data + 1));
          imm_bytes = 2;
          break;
        case DOUBLEWORD_SIZE:
          addr = LoadUnaligned(reinterpret_cast<int32_t*>(*data + 1));
          imm_bytes = 4;
          break;
        case QUADWORD_SIZE:
          addr = LoadUnaligned(reinterpret_cast<int64_t*>(*data + 1));
          imm_bytes = 8;
          break;
        default:
          UNREACHABLE();
      }
      (*data) += 1 + imm_bytes;
      Print("mov%s %s,", operand_size_code(),
            NameOfCPURegister(base_reg(current & 0x07)));
      PrintImmediateValue(addr, /* signed = */ false, imm_bytes);
      break;
    }

    case CALL_JUMP_INSTR: {
      int32_t disp = LoadUnaligned(reinterpret_cast<int32_t*>(*data + 1)) + 5;
      Print("%s ", idesc.mnem);
      PrintJump(*data, disp);
      (*data) += 5;
      break;
    }

    case SHORT_IMMEDIATE_INSTR: {
      Print("%s%s %s,", idesc.mnem, operand_size_code(), Rax());
      PrintImmediate(*data + 1, DOUBLEWORD_SIZE);
      (*data) += 5;
      break;
    }

    case NO_INSTR:
      return false;

    default:
      UNIMPLEMENTED();  // This type is not implemented.
  }
  return true;
}

int DisassemblerX64::Print660F38Instruction(uint8_t* current) {
  int mod, regop, rm;
  if (*current == 0x25) {
    get_modrm(*(current + 1), &mod, &regop, &rm);
    Print("pmovsxdq %s,", NameOfXMMRegister(regop));
    return 1 + PrintRightXMMOperand(current + 1);
  } else if (*current == 0x29) {
    get_modrm(*(current + 1), &mod, &regop, &rm);
    Print("pcmpeqq %s,", NameOfXMMRegister(regop));
    return 1 + PrintRightXMMOperand(current + 1);
  } else {
    UnimplementedInstruction();
    return 1;
  }
}

// Handle all two-byte opcodes, which start with 0x0F.
// These instructions may be affected by an 0x66, 0xF2, or 0xF3 prefix.
// We do not use any three-byte opcodes, which start with 0x0F38 or 0x0F3A.
int DisassemblerX64::TwoByteOpcodeInstruction(uint8_t* data) {
  uint8_t opcode = *(data + 1);
  uint8_t* current = data + 2;
  // At return, "current" points to the start of the next instruction.
  const char* mnemonic = TwoByteMnemonic(opcode);
  if (operand_size_ == 0x66) {
    // 0x66 0x0F prefix.
    int mod, regop, rm;
    if (opcode == 0xC6) {
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("shufpd %s, ", NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
      Print(" [%x]", *current);
      current++;
    } else if (opcode == 0x3A) {
      uint8_t third_byte = *current;
      current = data + 3;
      if (third_byte == 0x16) {
        get_modrm(*current, &mod, &regop, &rm);
        Print("pextrd ");  // reg/m32, xmm, imm8
        current += PrintRightOperand(current);
        Print(",%s,%d", NameOfXMMRegister(regop), (*current) & 7);
        current += 1;
      } else if (third_byte == 0x17) {
        get_modrm(*current, &mod, &regop, &rm);
        Print("extractps ");  // reg/m32, xmm, imm8
        current += PrintRightOperand(current);
        Print(", %s, %d", NameOfCPURegister(regop), (*current) & 3);
        current += 1;
      } else if (third_byte == 0x0b) {
        get_modrm(*current, &mod, &regop, &rm);
        // roundsd xmm, xmm/m64, imm8
        Print("roundsd %s, ", NameOfCPURegister(regop));
        current += PrintRightOperand(current);
        Print(", %d", (*current) & 3);
        current += 1;
      } else {
        UnimplementedInstruction();
      }
    } else {
      get_modrm(*current, &mod, &regop, &rm);
      if (opcode == 0x1f) {
        current++;
        if (rm == 4) {  // SIB byte present.
          current++;
        }
        if (mod == 1) {  // Byte displacement.
          current += 1;
        } else if (mod == 2) {  // 32-bit displacement.
          current += 4;
        }  // else no immediate displacement.
        Print("nop");
      } else if (opcode == 0x28) {
        Print("movapd %s, ", NameOfXMMRegister(regop));
        current += PrintRightXMMOperand(current);
      } else if (opcode == 0x29) {
        Print("movapd ");
        current += PrintRightXMMOperand(current);
        Print(", %s", NameOfXMMRegister(regop));
      } else if (opcode == 0x38) {
        current += Print660F38Instruction(current);
      } else if (opcode == 0x6E) {
        Print("mov%c %s,", rex_w() ? 'q' : 'd', NameOfXMMRegister(regop));
        current += PrintRightOperand(current);
      } else if (opcode == 0x6F) {
        Print("movdqa %s,", NameOfXMMRegister(regop));
        current += PrintRightXMMOperand(current);
      } else if (opcode == 0x7E) {
        Print("mov%c ", rex_w() ? 'q' : 'd');
        current += PrintRightOperand(current);
        Print(",%s", NameOfXMMRegister(regop));
      } else if (opcode == 0x7F) {
        Print("movdqa ");
        current += PrintRightXMMOperand(current);
        Print(",%s", NameOfXMMRegister(regop));
      } else if (opcode == 0xD6) {
        Print("movq ");
        current += PrintRightXMMOperand(current);
        Print(",%s", NameOfXMMRegister(regop));
      } else if (opcode == 0x50) {
        Print("movmskpd %s,", NameOfCPURegister(regop));
        current += PrintRightXMMOperand(current);
      } else if (opcode == 0xD7) {
        Print("pmovmskb %s,", NameOfCPURegister(regop));
        current += PrintRightXMMOperand(current);
      } else {
        const char* mnemonic = "?";
        if (opcode == 0x5A) {
          mnemonic = "cvtpd2ps";
        } else if (0x51 <= opcode && opcode <= 0x5F) {
          mnemonic = xmm_instructions[opcode & 0xF].pd_name;
        } else if (opcode == 0x14) {
          mnemonic = "unpcklpd";
        } else if (opcode == 0x15) {
          mnemonic = "unpckhpd";
        } else if (opcode == 0x2E) {
          mnemonic = "ucomisd";
        } else if (opcode == 0x2F) {
          mnemonic = "comisd";
        } else if (opcode == 0xFE) {
          mnemonic = "paddd";
        } else if (opcode == 0xFA) {
          mnemonic = "psubd";
        } else if (opcode == 0xEF) {
          mnemonic = "pxor";
        } else {
          UnimplementedInstruction();
        }
        Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
        current += PrintRightXMMOperand(current);
      }
    }
  } else if (group_1_prefix_ == 0xF2) {
    // Beginning of instructions with prefix 0xF2.

    if (opcode == 0x11 || opcode == 0x10) {
      // MOVSD: Move scalar double-precision fp to/from/between XMM registers.
      Print("movsd ");
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      if (opcode == 0x11) {
        current += PrintRightXMMOperand(current);
        Print(",%s", NameOfXMMRegister(regop));
      } else {
        Print("%s,", NameOfXMMRegister(regop));
        current += PrintRightXMMOperand(current);
      }
    } else if (opcode == 0x2A) {
      // CVTSI2SD: integer to XMM double conversion.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("%sd %s,", mnemonic, NameOfXMMRegister(regop));
      current += PrintRightOperand(current);
    } else if (opcode == 0x2C) {
      // CVTTSD2SI:
      // Convert with truncation scalar double-precision FP to integer.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("cvttsd2si%s %s,", operand_size_code(), NameOfCPURegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (opcode == 0x2D) {
      // CVTSD2SI: Convert scalar double-precision FP to integer.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("cvtsd2si%s %s,", operand_size_code(), NameOfCPURegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (0x51 <= opcode && opcode <= 0x5F) {
      // XMM arithmetic. Get the F2 0F prefix version of the mnemonic.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      const char* mnemonic =
          opcode == 0x5A ? "cvtsd2ss" : xmm_instructions[opcode & 0xF].sd_name;
      Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
    } else {
      UnimplementedInstruction();
    }
  } else if (group_1_prefix_ == 0xF3) {
    // Instructions with prefix 0xF3.
    if (opcode == 0x11 || opcode == 0x10) {
      // MOVSS: Move scalar double-precision fp to/from/between XMM registers.
      Print("movss ");
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      if (opcode == 0x11) {
        current += PrintRightOperand(current);
        Print(",%s", NameOfXMMRegister(regop));
      } else {
        Print("%s,", NameOfXMMRegister(regop));
        current += PrintRightOperand(current);
      }
    } else if (opcode == 0x2A) {
      // CVTSI2SS: integer to XMM single conversion.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("%ss %s,", mnemonic, NameOfXMMRegister(regop));
      current += PrintRightOperand(current);
    } else if (opcode == 0x2C || opcode == 0x2D) {
      bool truncating = (opcode & 1) == 0;
      // CVTTSS2SI/CVTSS2SI:
      // Convert (with truncation) scalar single-precision FP to dword integer.
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("cvt%sss2si%s %s,", truncating ? "t" : "", operand_size_code(),
            NameOfCPURegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (0x51 <= opcode && opcode <= 0x5F) {
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      const char* mnemonic =
          opcode == 0x5A ? "cvtss2sd" : xmm_instructions[opcode & 0xF].ss_name;
      Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (opcode == 0x7E) {
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("movq %s, ", NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (opcode == 0xE6) {
      int mod, regop, rm;
      get_modrm(*current, &mod, &regop, &rm);
      Print("cvtdq2pd %s,", NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
    } else if (opcode == 0xB8) {
      // POPCNT.
      current += PrintOperands(mnemonic, REG_OPER_OP_ORDER, current);
    } else if (opcode == 0xBD) {
      // LZCNT (rep BSR encoding).
      current += PrintOperands("lzcnt", REG_OPER_OP_ORDER, current);
    } else {
      UnimplementedInstruction();
    }
  } else if (opcode == 0x1F) {
    // NOP
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    current++;
    if (rm == 4) {  // SIB byte present.
      current++;
    }
    if (mod == 1) {  // Byte displacement.
      current += 1;
    } else if (mod == 2) {  // 32-bit displacement.
      current += 4;
    }  // else no immediate displacement.
    Print("nop");

  } else if (opcode == 0x28 || opcode == 0x2f) {
    // ...s xmm, xmm/m128
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    const char* mnemonic = opcode == 0x28 ? "movaps" : "comiss";
    Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
    current += PrintRightXMMOperand(current);
  } else if (opcode == 0x29) {
    // movaps xmm/m128, xmm
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    Print("movaps ");
    current += PrintRightXMMOperand(current);
    Print(",%s", NameOfXMMRegister(regop));
  } else if (opcode == 0x11) {
    // movups xmm/m128, xmm
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    Print("movups ");
    current += PrintRightXMMOperand(current);
    Print(",%s", NameOfXMMRegister(regop));
  } else if (opcode == 0x50) {
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    Print("movmskps %s,", NameOfCPURegister(regop));
    current += PrintRightXMMOperand(current);
  } else if (opcode == 0xA2 || opcode == 0x31) {
    // RDTSC or CPUID
    Print("%s", mnemonic);
  } else if ((opcode & 0xF0) == 0x40) {
    // CMOVcc: conditional move.
    int condition = opcode & 0x0F;
    const InstructionDesc& idesc = cmov_instructions[condition];
    byte_size_operand_ = idesc.byte_size_operation;
    current += PrintOperands(idesc.mnem, idesc.op_order_, current);
  } else if (0x10 <= opcode && opcode <= 0x16) {
    // ...ps xmm, xmm/m128
    static const char* mnemonics[] = {"movups",   NULL,       "movhlps", NULL,
                                      "unpcklps", "unpckhps", "movlhps"};
    const char* mnemonic = mnemonics[opcode - 0x10];
    if (mnemonic == NULL) {
      UnimplementedInstruction();
      mnemonic = "???";
    }
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
    current += PrintRightXMMOperand(current);
  } else if (0x51 <= opcode && opcode <= 0x5F) {
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    const char* mnemonic =
        opcode == 0x5A ? "cvtps2pd" : xmm_instructions[opcode & 0xF].ps_name;
    Print("%s %s,", mnemonic, NameOfXMMRegister(regop));
    current += PrintRightXMMOperand(current);
  } else if (opcode == 0xC2 || opcode == 0xC6) {
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    if (opcode == 0xC2) {
      Print("cmpps %s,", NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
      Print(" [%s]", xmm_conditional_code_suffix[*current]);
    } else {
      ASSERT(opcode == 0xC6);
      Print("shufps %s,", NameOfXMMRegister(regop));
      current += PrintRightXMMOperand(current);
      Print(" [%x]", *current);
    }
    current++;
  } else if ((opcode & 0xF0) == 0x80) {
    // Jcc: Conditional jump (branch).
    current = data + JumpConditional(data);

  } else if (opcode == 0xBE || opcode == 0xBF || opcode == 0xB6 ||
             opcode == 0xB7 || opcode == 0xAF || opcode == 0xB0 ||
             opcode == 0xB1 || opcode == 0xBC || opcode == 0xBD) {
    // Size-extending moves, IMUL, cmpxchg, BSF, BSR.
    current += PrintOperands(mnemonic, REG_OPER_OP_ORDER, current);
  } else if ((opcode & 0xF0) == 0x90) {
    // SETcc: Set byte on condition. Needs pointer to beginning of instruction.
    current = data + SetCC(data);
  } else if (((opcode & 0xFE) == 0xA4) || ((opcode & 0xFE) == 0xAC) ||
             (opcode == 0xAB) || (opcode == 0xA3)) {
    // SHLD, SHRD (double-prec. shift), BTS (bit test and set), BT (bit test).
    Print("%s%s ", mnemonic, operand_size_code());
    int mod, regop, rm;
    get_modrm(*current, &mod, &regop, &rm);
    current += PrintRightOperand(current);
    Print(",%s", NameOfCPURegister(regop));
    if ((opcode == 0xAB) || (opcode == 0xA3) || (opcode == 0xBD)) {
      // Done.
    } else if ((opcode == 0xA5) || (opcode == 0xAD)) {
      Print(",cl");
    } else {
      Print(",");
      current += PrintImmediate(current, BYTE_SIZE);
    }
  } else if (opcode == 0xBA && (*current & 0x60) == 0x60) {
    // bt? immediate instruction
    int r = (*current >> 3) & 7;
    static const char* const names[4] = {"bt", "bts", "btr", "btc"};
    Print("%s ", names[r - 4]);
    current += PrintRightOperand(current);
    uint8_t bit = *current++;
    Print(",%d", bit);
  } else {
    UnimplementedInstruction();
  }
  return static_cast<int>(current - data);
}

// Mnemonics for two-byte opcode instructions starting with 0x0F.
// The argument is the second byte of the two-byte opcode.
// Returns NULL if the instruction is not handled here.
const char* DisassemblerX64::TwoByteMnemonic(uint8_t opcode) {
  if (opcode == 0x5A) {
    return "cvtps2pd";
  } else if (0x51 <= opcode && opcode <= 0x5F) {
    return xmm_instructions[opcode & 0xF].ps_name;
  }
  if (0xA2 <= opcode && opcode <= 0xBF) {
    static const char* mnemonics[] = {
        "cpuid", "bt",   "shld",    "shld",    NULL,     NULL,
        NULL,    NULL,   NULL,      "bts",     "shrd",   "shrd",
        NULL,    "imul", "cmpxchg", "cmpxchg", NULL,     NULL,
        NULL,    NULL,   "movzxb",  "movzxw",  "popcnt", NULL,
        NULL,    NULL,   "bsf",     "bsr",     "movsxb", "movsxw"};
    return mnemonics[opcode - 0xA2];
  }
  switch (opcode) {
    case 0x12:
      return "movhlps";
    case 0x16:
      return "movlhps";
    case 0x1F:
      return "nop";
    case 0x2A:  // F2/F3 prefix.
      return "cvtsi2s";
    case 0x31:
      return "rdtsc";
    default:
      return NULL;
  }
}

int DisassemblerX64::InstructionDecode(uword pc) {
  uint8_t* data = reinterpret_cast<uint8_t*>(pc);

  const bool processed = DecodeInstructionType(&data);

  if (!processed) {
    switch (*data) {
      case 0xC2:
        Print("ret ");
        PrintImmediateValue(*reinterpret_cast<uint16_t*>(data + 1));
        data += 3;
        break;

      case 0xC8:
        Print("enter %d, %d", *reinterpret_cast<uint16_t*>(data + 1), data[3]);
        data += 4;
        break;

      case 0x69:
        FALL_THROUGH;
      case 0x6B: {
        int mod, regop, rm;
        get_modrm(*(data + 1), &mod, &regop, &rm);
        int32_t imm = *data == 0x6B
                          ? *(data + 2)
                          : LoadUnaligned(reinterpret_cast<int32_t*>(data + 2));
        Print("imul%s %s,%s,", operand_size_code(), NameOfCPURegister(regop),
              NameOfCPURegister(rm));
        PrintImmediateValue(imm);
        data += 2 + (*data == 0x6B ? 1 : 4);
        break;
      }

      case 0x81:
        FALL_THROUGH;
      case 0x83:  // 0x81 with sign extension bit set
        data += PrintImmediateOp(data);
        break;

      case 0x0F:
        data += TwoByteOpcodeInstruction(data);
        break;

      case 0x8F: {
        data++;
        int mod, regop, rm;
        get_modrm(*data, &mod, &regop, &rm);
        if (regop == 0) {
          Print("pop ");
          data += PrintRightOperand(data);
        }
      } break;

      case 0xFF: {
        data++;
        int mod, regop, rm;
        get_modrm(*data, &mod, &regop, &rm);
        const char* mnem = NULL;
        switch (regop) {
          case 0:
            mnem = "inc";
            break;
          case 1:
            mnem = "dec";
            break;
          case 2:
            mnem = "call";
            break;
          case 4:
            mnem = "jmp";
            break;
          case 6:
            mnem = "push";
            break;
          default:
            mnem = "???";
        }
        if (regop <= 1) {
          Print("%s%s ", mnem, operand_size_code());
        } else {
          Print("%s ", mnem);
        }
        data += PrintRightOperand(data);
      } break;

      case 0xC7:  // imm32, fall through
      case 0xC6:  // imm8
      {
        bool is_byte = *data == 0xC6;
        data++;
        if (is_byte) {
          Print("movb ");
          data += PrintRightByteOperand(data);
          Print(",");
          data += PrintImmediate(data, BYTE_SIZE);
        } else {
          Print("mov%s ", operand_size_code());
          data += PrintRightOperand(data);
          Print(",");
          data +=
              PrintImmediate(data, operand_size(), /* sign extend = */ true);
        }
      } break;

      case 0x80: {
        byte_size_operand_ = true;
        data += PrintImmediateOp(data);
      } break;

      case 0x88:  // 8bit, fall through
      case 0x89:  // 32bit
      {
        bool is_byte = *data == 0x88;
        int mod, regop, rm;
        data++;
        get_modrm(*data, &mod, &regop, &rm);
        if (is_byte) {
          Print("movb ");
          data += PrintRightByteOperand(data);
          Print(",%s", NameOfByteCPURegister(regop));
        } else {
          Print("mov%s ", operand_size_code());
          data += PrintRightOperand(data);
          Print(",%s", NameOfCPURegister(regop));
        }
      } break;

      case 0x90:
      case 0x91:
      case 0x92:
      case 0x93:
      case 0x94:
      case 0x95:
      case 0x96:
      case 0x97: {
        int reg = (*data & 0x7) | (rex_b() ? 8 : 0);
        if (reg == 0) {
          Print("nop");  // Common name for xchg rax,rax.
        } else {
          Print("xchg%s %s, %s", operand_size_code(), Rax(),
                NameOfCPURegister(reg));
        }
        data++;
      } break;
      case 0xB0:
      case 0xB1:
      case 0xB2:
      case 0xB3:
      case 0xB4:
      case 0xB5:
      case 0xB6:
      case 0xB7:
      case 0xB8:
      case 0xB9:
      case 0xBA:
      case 0xBB:
      case 0xBC:
      case 0xBD:
      case 0xBE:
      case 0xBF: {
        // mov reg8,imm8 or mov reg32,imm32
        uint8_t opcode = *data;
        data++;
        const bool is_not_8bit = opcode >= 0xB8;
        int reg = (opcode & 0x7) | (rex_b() ? 8 : 0);
        if (is_not_8bit) {
          Print("mov%s %s,", operand_size_code(), NameOfCPURegister(reg));
          data +=
              PrintImmediate(data, operand_size(), /* sign extend = */ false);
        } else {
          Print("movb %s,", NameOfByteCPURegister(reg));
          data += PrintImmediate(data, BYTE_SIZE, /* sign extend = */ false);
        }
        break;
      }
      case 0xFE: {
        data++;
        int mod, regop, rm;
        get_modrm(*data, &mod, &regop, &rm);
        if (regop == 1) {
          Print("decb ");
          data += PrintRightByteOperand(data);
        } else {
          UnimplementedInstruction();
        }
        break;
      }
      case 0x68:
        Print("push ");
        PrintImmediateValue(
            LoadUnaligned(reinterpret_cast<int32_t*>(data + 1)));
        data += 5;
        break;

      case 0x6A:
        Print("push ");
        PrintImmediateValue(*reinterpret_cast<int8_t*>(data + 1));
        data += 2;
        break;

      case 0xA1:
        FALL_THROUGH;
      case 0xA3:
        switch (operand_size()) {
          case DOUBLEWORD_SIZE: {
            PrintAddress(reinterpret_cast<uint8_t*>(
                *reinterpret_cast<int32_t*>(data + 1)));
            if (*data == 0xA1) {  // Opcode 0xA1
              Print("movzxlq %s,(", Rax());
              PrintAddress(reinterpret_cast<uint8_t*>(
                  *reinterpret_cast<int32_t*>(data + 1)));
              Print(")");
            } else {  // Opcode 0xA3
              Print("movzxlq (");
              PrintAddress(reinterpret_cast<uint8_t*>(
                  *reinterpret_cast<int32_t*>(data + 1)));
              Print("),%s", Rax());
            }
            data += 5;
            break;
          }
          case QUADWORD_SIZE: {
            // New x64 instruction mov rax,(imm_64).
            if (*data == 0xA1) {  // Opcode 0xA1
              Print("movq %s,(", Rax());
              PrintAddress(*reinterpret_cast<uint8_t**>(data + 1));
              Print(")");
            } else {  // Opcode 0xA3
              Print("movq (");
              PrintAddress(*reinterpret_cast<uint8_t**>(data + 1));
              Print("),%s", Rax());
            }
            data += 9;
            break;
          }
          default:
            UnimplementedInstruction();
            data += 2;
        }
        break;

      case 0xA8:
        Print("test al,");
        PrintImmediateValue(*reinterpret_cast<uint8_t*>(data + 1));
        data += 2;
        break;

      case 0xA9: {
        data++;
        Print("test%s %s,", operand_size_code(), Rax());
        data += PrintImmediate(data, operand_size());
        break;
      }
      case 0xD1:
        FALL_THROUGH;
      case 0xD3:
        FALL_THROUGH;
      case 0xC1:
        data += ShiftInstruction(data);
        break;
      case 0xD0:
        FALL_THROUGH;
      case 0xD2:
        FALL_THROUGH;
      case 0xC0:
        byte_size_operand_ = true;
        data += ShiftInstruction(data);
        break;

      case 0xD9:
        FALL_THROUGH;
      case 0xDA:
        FALL_THROUGH;
      case 0xDB:
        FALL_THROUGH;
      case 0xDC:
        FALL_THROUGH;
      case 0xDD:
        FALL_THROUGH;
      case 0xDE:
        FALL_THROUGH;
      case 0xDF:
        data += FPUInstruction(data);
        break;

      case 0xEB:
        data += JumpShort(data);
        break;

      case 0xF6:
        byte_size_operand_ = true;
        FALL_THROUGH;
      case 0xF7:
        data += F6F7Instruction(data);
        break;

      // These encodings for inc and dec are IA32 only, but we don't get here
      // on X64 - the REX prefix recoginizer catches them earlier.
      case 0x40:
      case 0x41:
      case 0x42:
      case 0x43:
      case 0x44:
      case 0x45:
      case 0x46:
      case 0x47:
        Print("inc %s", NameOfCPURegister(*data & 7));
        data += 1;
        break;

      case 0x48:
      case 0x49:
      case 0x4a:
      case 0x4b:
      case 0x4c:
      case 0x4d:
      case 0x4e:
      case 0x4f:
        Print("dec %s", NameOfCPURegister(*data & 7));
        data += 1;
        break;

#if defined(TARGET_ARCH_IA32)
      case 0x61:
        Print("popad");
        break;

      case 0x60:
        Print("pushad");
        break;
#endif

      default:
        UnimplementedInstruction();
        data += 1;
    }
  }  // !processed

  ASSERT(buffer_[buffer_pos_] == '\0');

  int instr_len = data - reinterpret_cast<uint8_t*>(pc);
  ASSERT(instr_len > 0);  // Ensure progress.

  return instr_len;
}

void Disassembler::DecodeInstruction(char* hex_buffer,
                                     intptr_t hex_size,
                                     char* human_buffer,
                                     intptr_t human_size,
                                     int* out_instr_len,
                                     const Code& code,
                                     Object** object,
                                     uword pc) {
  ASSERT(hex_size > 0);
  ASSERT(human_size > 0);
  DisassemblerX64 decoder(human_buffer, human_size);
  int instruction_length = decoder.InstructionDecode(pc);
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  int hex_index = 0;
  int remaining_size = hex_size - hex_index;
  for (int i = 0; (i < instruction_length) && (remaining_size > 2); ++i) {
    Utils::SNPrint(&hex_buffer[hex_index], remaining_size, "%02x", pc_ptr[i]);
    hex_index += 2;
    remaining_size -= 2;
  }
  hex_buffer[hex_index] = '\0';
  if (out_instr_len != nullptr) {
    *out_instr_len = instruction_length;
  }

  *object = NULL;
#if defined(TARGET_ARCH_X64)
  if (!code.IsNull()) {
    *object = &Object::Handle();
    if (!DecodeLoadObjectFromPoolOrThread(pc, code, *object)) {
      *object = NULL;
    }
  }
#else
  if (!code.IsNull() && code.is_alive()) {
    intptr_t offsets_length = code.pointer_offsets_length();
    for (intptr_t i = 0; i < offsets_length; i++) {
      uword addr = code.GetPointerOffsetAt(i) + code.PayloadStart();
      if ((pc <= addr) && (addr < (pc + instruction_length))) {
        *object =
            &Object::Handle(LoadUnaligned(reinterpret_cast<ObjectPtr*>(addr)));
        break;
      }
    }
  }
#endif
}

#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64) || defined (TARGET_ARCH_IA32)
