// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/disassembler.h"

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/heap.h"
#include "vm/os.h"
#include "vm/stack_frame.h"
#include "vm/stub_code.h"

namespace dart {

// Tables used for decoding of x86 instructions.
enum OperandOrder {
  UNSET_OP_ORDER = 0,
  REG_OPER_OP_ORDER,
  OPER_REG_OP_ORDER
};


struct ByteMnemonic {
  int b;  // -1 terminates, otherwise must be in range (0..255)
  const char* mnem;
  OperandOrder op_order_;
};


static ByteMnemonic two_operands_instr[] = {
  {0x01, "add", OPER_REG_OP_ORDER},
  {0x03, "add", REG_OPER_OP_ORDER},
  {0x09, "or", OPER_REG_OP_ORDER},
  {0x0B, "or", REG_OPER_OP_ORDER},
  {0x11, "adc", OPER_REG_OP_ORDER},
  {0x13, "adc", REG_OPER_OP_ORDER},
  {0x19, "sbb", OPER_REG_OP_ORDER},
  {0x1B, "sbb", REG_OPER_OP_ORDER},
  {0x21, "and", OPER_REG_OP_ORDER},
  {0x23, "and", REG_OPER_OP_ORDER},
  {0x29, "sub", OPER_REG_OP_ORDER},
  {0x2B, "sub", REG_OPER_OP_ORDER},
  {0x31, "xor", OPER_REG_OP_ORDER},
  {0x33, "xor", REG_OPER_OP_ORDER},
  {0x39, "cmp", OPER_REG_OP_ORDER},
  {0x3B, "cmp", REG_OPER_OP_ORDER},
  {0x85, "test", REG_OPER_OP_ORDER},
  {0x87, "xchg", REG_OPER_OP_ORDER},
  {0x8A, "mov_b", REG_OPER_OP_ORDER},
  {0x8B, "mov", REG_OPER_OP_ORDER},
  {0x8D, "lea", REG_OPER_OP_ORDER},
  {-1, "", UNSET_OP_ORDER}
};


static ByteMnemonic zero_operands_instr[] = {
  {0xC3, "ret", UNSET_OP_ORDER},
  {0xC9, "leave", UNSET_OP_ORDER},
  {0x90, "nop", UNSET_OP_ORDER},
  {0xF4, "hlt", UNSET_OP_ORDER},
  {0xCC, "int3", UNSET_OP_ORDER},
  {0x60, "pushad", UNSET_OP_ORDER},
  {0x61, "popad", UNSET_OP_ORDER},
  {0x9C, "pushfd", UNSET_OP_ORDER},
  {0x9D, "popfd", UNSET_OP_ORDER},
  {0x9E, "sahf", UNSET_OP_ORDER},
  {0x99, "cdq", UNSET_OP_ORDER},
  {0x9B, "fwait", UNSET_OP_ORDER},
  {-1, "", UNSET_OP_ORDER}
};


static ByteMnemonic call_jump_instr[] = {
  {0xE8, "call", UNSET_OP_ORDER},
  {0xE9, "jmp", UNSET_OP_ORDER},
  {-1, "", UNSET_OP_ORDER}
};


static ByteMnemonic short_immediate_instr[] = {
  {0x05, "add", UNSET_OP_ORDER},
  {0x0D, "or", UNSET_OP_ORDER},
  {0x15, "adc", UNSET_OP_ORDER},
  {0x25, "and", UNSET_OP_ORDER},
  {0x2D, "sub", UNSET_OP_ORDER},
  {0x35, "xor", UNSET_OP_ORDER},
  {0x3D, "cmp", UNSET_OP_ORDER},
  {-1, "", UNSET_OP_ORDER}
};


static const char* jump_conditional_mnem[] = {
  /*0*/ "jo", "jno", "jc", "jnc",
  /*4*/ "jz", "jnz", "jna", "ja",
  /*8*/ "js", "jns", "jpe", "jpo",
  /*12*/ "jl", "jnl", "jng", "jg"
};


static const char* set_conditional_mnem[] = {
  /*0*/ "seto", "setno", "setc", "setnc",
  /*4*/ "setz", "setnz", "setna", "seta",
  /*8*/ "sets", "setns", "setpe", "setpo",
  /*12*/ "setl", "setnl", "setng", "setg"
};


static const char* conditional_move_mnem[] = {
  /*0*/ "cmovo", "cmovno", "cmovc", "cmovnc",
  /*4*/ "cmovz", "cmovnz", "cmovna", "cmova",
  /*8*/ "cmovs", "cmovns", "cmovpe", "cmovpo",
  /*12*/ "cmovl", "cmovnl", "cmovng", "cmovg"
};


enum InstructionType {
  NO_INSTR,
  ZERO_OPERANDS_INSTR,
  TWO_OPERANDS_INSTR,
  JUMP_CONDITIONAL_SHORT_INSTR,
  REGISTER_INSTR,
  MOVE_REG_INSTR,
  CALL_JUMP_INSTR,
  SHORT_IMMEDIATE_INSTR
};


struct InstructionDesc {
  const char* mnem;
  InstructionType type;
  OperandOrder op_order_;
};


class InstructionTable : public ValueObject {
 public:
  InstructionTable();
  const InstructionDesc& Get(uint8_t x) const { return instructions_[x]; }

 private:
  InstructionDesc instructions_[256];
  void Clear();
  void Init();
  void CopyTable(ByteMnemonic bm[], InstructionType type);
  void SetTableRange(InstructionType type,
                     uint8_t start,
                     uint8_t end,
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
    instructions_[i].mnem = "";
    instructions_[i].type = NO_INSTR;
    instructions_[i].op_order_ = UNSET_OP_ORDER;
  }
}


void InstructionTable::Init() {
  CopyTable(two_operands_instr, TWO_OPERANDS_INSTR);
  CopyTable(zero_operands_instr, ZERO_OPERANDS_INSTR);
  CopyTable(call_jump_instr, CALL_JUMP_INSTR);
  CopyTable(short_immediate_instr, SHORT_IMMEDIATE_INSTR);
  AddJumpConditionalShort();
  SetTableRange(REGISTER_INSTR, 0x40, 0x47, "inc");
  SetTableRange(REGISTER_INSTR, 0x48, 0x4F, "dec");
  SetTableRange(REGISTER_INSTR, 0x50, 0x57, "push");
  SetTableRange(REGISTER_INSTR, 0x58, 0x5F, "pop");
  SetTableRange(REGISTER_INSTR, 0x91, 0x97, "xchg eax,");  // 0x90 is nop.
  SetTableRange(MOVE_REG_INSTR, 0xB8, 0xBF, "mov");
}


void InstructionTable::CopyTable(ByteMnemonic bm[], InstructionType type) {
  for (int i = 0; bm[i].b >= 0; i++) {
    InstructionDesc* id = &instructions_[bm[i].b];
    id->mnem = bm[i].mnem;
    id->op_order_ = bm[i].op_order_;
    ASSERT(id->type == NO_INSTR);  // Information already entered
    id->type = type;
  }
}


void InstructionTable::SetTableRange(InstructionType type,
                                     uint8_t start,
                                     uint8_t end,
                                     const char* mnem) {
  for (uint8_t b = start; b <= end; b++) {
    InstructionDesc* id = &instructions_[b];
    ASSERT(id->type == NO_INSTR);  // Information already entered
    id->mnem = mnem;
    id->type = type;
  }
}


void InstructionTable::AddJumpConditionalShort() {
  for (uint8_t b = 0x70; b <= 0x7F; b++) {
    InstructionDesc* id = &instructions_[b];
    ASSERT(id->type == NO_INSTR);  // Information already entered
    id->mnem = jump_conditional_mnem[b & 0x0F];
    id->type = JUMP_CONDITIONAL_SHORT_INSTR;
  }
}


static InstructionTable instruction_table;


// Mnemonics for instructions 0xF0 byte.
// Returns NULL if the instruction is not handled here.
static const char* F0Mnem(uint8_t f0byte) {
  switch (f0byte) {
    case 0x12: return "movhlps";
    case 0x14: return "unpcklps";
    case 0x15: return "unpckhps";
    case 0x16: return "movlhps";
    case 0xA2: return "cpuid";
    case 0x31: return "rdtsc";
    case 0xBE: return "movsx_b";
    case 0xBF: return "movsx_w";
    case 0xB6: return "movzx_b";
    case 0xB7: return "movzx_w";
    case 0xAF: return "imul";
    case 0xA4:  // Fall through.
    case 0xA5: return "shld";
    case 0xAC:  // Fall through.
    case 0xAD: return "shrd";
    case 0xAB: return "bts";
    case 0xBD: return "bsr";
    case 0xB1: return "cmpxchg";
    case 0x50: return "movmskps";
    case 0x51: return "sqrtps";
    case 0x52: return "rqstps";
    case 0x53: return "rcpps";
    case 0x54: return "andps";
    case 0x56: return "orps";
    case 0x57: return "xorps";
    case 0x58: return "addps";
    case 0x59: return "mulps";
    case 0x5A: return "cvtps2pd";
    case 0x5C: return "subps";
    case 0x5D: return "minps";
    case 0x5E: return "divps";
    case 0x5F: return "maxps";
    case 0x28: return "movaps";
    case 0x10: return "movups";
    case 0x11: return "movups";
    default: return NULL;
  }
}

static const char* PackedDoubleMnemonic(uint8_t data) {
  const char* mnemonic = NULL;
  if (data == 0xFE) mnemonic = "paddd ";
  if (data == 0xFA) mnemonic = "psubd ";
  if (data == 0x2F) mnemonic = "comisd ";
  if (data == 0x58) mnemonic = "addpd ";
  if (data == 0x5C) mnemonic = "subpd ";
  if (data == 0x59) mnemonic = "mulpd ";
  if (data == 0x5E) mnemonic = "divpd ";
  if (data == 0x5D) mnemonic = "minpd ";
  if (data == 0x5F) mnemonic = "maxpd ";
  if (data == 0x51) mnemonic = "sqrtpd ";
  if (data == 0x5A) mnemonic = "cvtpd2ps ";
  ASSERT(mnemonic != NULL);
  return mnemonic;
}


static bool IsTwoXmmRegInstruction(uint8_t f0byte) {
  return f0byte == 0x28 || f0byte == 0x11 || f0byte == 0x12 ||
         f0byte == 0x14 || f0byte == 0x15 || f0byte == 0x16 ||
         f0byte == 0x51 || f0byte == 0x52 || f0byte == 0x53 ||
         f0byte == 0x54 || f0byte == 0x56 || f0byte == 0x58 ||
         f0byte == 0x59 || f0byte == 0x5C || f0byte == 0x5D ||
         f0byte == 0x5E || f0byte == 0x5F || f0byte == 0x5A;
}


// The implementation of x86 decoding based on the above tables.
class X86Decoder : public ValueObject {
 public:
  X86Decoder(char* buffer, intptr_t buffer_size)
      : buffer_(buffer),
        buffer_size_(buffer_size),
        buffer_pos_(0) {
    buffer_[buffer_pos_] = '\0';
  }

  ~X86Decoder() {}

  // Writes one disassembled instruction into the buffer (0-terminated).
  // Returns the length of the disassembled machine instruction in bytes.
  int InstructionDecode(uword pc);

 private:
  enum {
    eax = 0,
    ecx = 1,
    edx = 2,
    ebx = 3,
    esp = 4,
    ebp = 5,
    esi = 6,
    edi = 7
  };

  // Bottleneck functions to print into the out_buffer.
  void PrintInt(int value);
  void PrintHex(int value);
  void Print(const char* str);
  const char* GetBranchPrefix(uint8_t** data);

  bool DecodeInstructionType(const InstructionDesc& idesc,
                             const char* branch_hint,
                             uint8_t** data);

  // Printing of common values.
  void PrintCPURegister(int reg);
  void PrintCPUByteRegister(int reg);
  void PrintXmmRegister(int reg);
  void PrintXmmComparison(int comparison);
  void PrintAddress(uword addr);

  typedef void (X86Decoder::*RegisterNamePrinter)(int reg);

  int PrintRightOperandHelper(uint8_t* modrmp,
                              RegisterNamePrinter register_printer);
  int PrintRightOperand(uint8_t* modrmp);
  int PrintRightXmmOperand(uint8_t* modrmp);
  int PrintRightByteOperand(uint8_t* modrmp);
  int PrintOperands(const char* mnem, OperandOrder op_order, uint8_t* data);
  int PrintImmediateOp(uint8_t* data);

  // Handle special encodings.
  int JumpShort(uint8_t* data);
  int JumpConditional(uint8_t* data, const char* comment);
  int JumpConditionalShort(uint8_t* data, const char* comment);
  int SetCC(uint8_t* data);
  int CMov(uint8_t* data);
  int D1D3C1Instruction(uint8_t* data);
  uint8_t* F3Instruction(uint8_t* data);
  int F7Instruction(uint8_t* data);
  int FPUInstruction(uint8_t* data);
  uint8_t* SSEInstruction(uint8_t prefix, uint8_t primary, uint8_t* data);
  int BitwisePDInstruction(uint8_t* data);
  int Packed660F38Instruction(uint8_t* data);
  int DecodeEnter(uint8_t* data);
  void CheckPrintStop(uint8_t* data);

  // Disassembler helper functions.
  static void GetModRm(uint8_t data, int* mod, int* regop, int* rm) {
    *mod = (data >> 6) & 3;
    *regop = (data & 0x38) >> 3;
    *rm = data & 7;
  }

  static void GetSib(uint8_t data, int* scale, int* index, int* base) {
    *scale = (data >> 6) & 3;
    *index = (data >> 3) & 7;
    *base = data & 7;
  }


  // Convenience functions.
  char* get_buffer() const { return buffer_; }
  char* current_position_in_buffer() { return buffer_ + buffer_pos_; }
  intptr_t remaining_size_in_buffer() { return buffer_size_ - buffer_pos_; }

  char* buffer_;  // Decode instructions into this buffer.
  intptr_t buffer_size_;  // The size of the buffer_.
  intptr_t buffer_pos_;  // Current character position in the buffer_.

  DISALLOW_COPY_AND_ASSIGN(X86Decoder);
};


void X86Decoder::PrintInt(int value) {
  char int_buffer[16];
  OS::SNPrint(int_buffer, sizeof(int_buffer), "%#x", value);
  Print(int_buffer);
}


// Append the int value (printed in hex) to the output buffer.
void X86Decoder::PrintHex(int value) {
  char hex_buffer[16];
  OS::SNPrint(hex_buffer, sizeof(hex_buffer), "%#x", value);
  Print(hex_buffer);
}


// Append the str to the output buffer.
void X86Decoder::Print(const char* str) {
  char cur = *str++;
  while (cur != '\0' && (buffer_pos_ < (buffer_size_ - 1))) {
    buffer_[buffer_pos_++] = cur;
    cur = *str++;
  }
  buffer_[buffer_pos_] = '\0';
}


static const int kMaxCPURegisters = 8;
static const char* cpu_regs[kMaxCPURegisters] = {
  "eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi"
};

static const int kMaxByteCPURegisters = 8;
static const char* byte_cpu_regs[kMaxByteCPURegisters] = {
  "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh"
};

static const int kMaxXmmRegisters = 8;
static const char* xmm_regs[kMaxXmmRegisters] = {
  "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7"
};

void X86Decoder::PrintCPURegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kMaxCPURegisters);
  Print(cpu_regs[reg]);
}


void X86Decoder::PrintCPUByteRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kMaxByteCPURegisters);
  Print(byte_cpu_regs[reg]);
}


void X86Decoder::PrintXmmRegister(int reg) {
  ASSERT(0 <= reg);
  ASSERT(reg < kMaxXmmRegisters);
  Print(xmm_regs[reg]);
}

void X86Decoder::PrintXmmComparison(int comparison) {
  ASSERT(0 <= comparison);
  ASSERT(comparison < 8);
  static const char* comparisons[8] = {
    "eq", "lt", "le", "unordered", "not eq", "not lt", "not le", "ordered"
  };
  Print(comparisons[comparison]);
}


static const char* ObjectToCStringNoGC(const Object& obj) {
  if (obj.IsSmi() ||
      obj.IsMint() ||
      obj.IsDouble() ||
      obj.IsString() ||
      obj.IsNull() ||
      obj.IsBool() ||
      obj.IsClass() ||
      obj.IsFunction() ||
      obj.IsICData() ||
      obj.IsField()) {
    return obj.ToCString();
  }

  const Class& clazz = Class::Handle(obj.clazz());
  const char* full_class_name = clazz.ToCString();
  const char* format = "instance of %s";
  intptr_t len = OS::SNPrint(NULL, 0, format, full_class_name) + 1;
  char* chars = Isolate::Current()->current_zone()->Alloc<char>(len);
  OS::SNPrint(chars, len, format, full_class_name);
  return chars;
}


void X86Decoder::PrintAddress(uword addr) {
  char addr_buffer[32];
  OS::SNPrint(addr_buffer, sizeof(addr_buffer), "%#" Px "", addr);
  Print(addr_buffer);
  // Try to print as heap object or stub name
  if (((addr & kSmiTagMask) == kHeapObjectTag) &&
      reinterpret_cast<RawObject*>(addr)->IsOldObject() &&
      !Isolate::Current()->heap()->CodeContains(addr) &&
      Disassembler::CanFindOldObject(addr)) {
    NoGCScope no_gc;
    const Object& obj = Object::Handle(reinterpret_cast<RawObject*>(addr));
    if (obj.IsArray()) {
      const Array& arr = Array::Cast(obj);
      intptr_t len = arr.Length();
      if (len > 5) len = 5;  // Print a max of 5 elements.
      Print("  Array[");
      int i = 0;
      Object& element = Object::Handle();
      while (i < len) {
        element = arr.At(i);
        if (i > 0) Print(", ");
        Print(ObjectToCStringNoGC(element));
        i++;
      }
      if (i < arr.Length()) Print(", ...");
      Print("]");
      return;
    }
    Print("  '");
    Print(ObjectToCStringNoGC(obj));
    Print("'");
  } else {
    // 'addr' is not an object, but probably a code address.
    const char* name_of_stub = StubCode::NameOfStub(addr);
    if (name_of_stub != NULL) {
      Print("  [stub: ");
      Print(name_of_stub);
      Print("]");
    } else {
      // Print only if jumping to entry point.
      const Code& code = Code::Handle(Code::LookupCode(addr));
      if (!code.IsNull() && (code.EntryPoint() == addr)) {
        const String& name = String::Handle(code.PrettyName());
        const char* name_c = name.ToCString();
        Print(" [");
        Print(name_c);
        Print("]");
      }
    }
  }
}


int X86Decoder::PrintRightOperandHelper(uint8_t* modrmp,
                                        RegisterNamePrinter register_printer) {
  int mod, regop, rm;
  GetModRm(*modrmp, &mod, &regop, &rm);
  switch (mod) {
    case 0:
      if (rm == ebp) {
        int32_t disp = *reinterpret_cast<int32_t*>(modrmp+1);
        Print("[");
        PrintHex(disp);
        Print("]");
        return 5;
      } else if (rm == esp) {
        uint8_t sib = *(modrmp + 1);
        int scale, index, base;
        GetSib(sib, &scale, &index, &base);
        if (index == esp && base == esp && scale == 0 /*times_1*/) {
          Print("[");
          PrintCPURegister(rm);
          Print("]");
          return 2;
        } else if (base == ebp) {
          int32_t disp = *reinterpret_cast<int32_t*>(modrmp + 2);
          Print("[");
          PrintCPURegister(index);
          Print("*");
          PrintInt(1 << scale);
          if (disp < 0) {
            Print("-");
            disp = -disp;
          } else {
            Print("+");
          }
          PrintHex(disp);
           Print("]");
          return 6;
        } else if (index != esp && base != ebp) {
          // [base+index*scale]
          Print("[");
          PrintCPURegister(base);
          Print("+");
          PrintCPURegister(index);
          Print("*");
          PrintInt(1 << scale);
          Print("]");
          return 2;
        } else {
          UNIMPLEMENTED();
          return 1;
        }
      } else {
        Print("[");
        PrintCPURegister(rm);
        Print("]");
        return 1;
      }
      break;
    case 1:  // fall through
    case 2:
      if (rm == esp) {
        uint8_t sib = *(modrmp + 1);
        int scale, index, base;
        GetSib(sib, &scale, &index, &base);
        int disp = (mod == 2) ?
                   *reinterpret_cast<int32_t*>(modrmp + 2) :
                   *reinterpret_cast<int8_t*>(modrmp + 2);
        if (index == base && index == rm /*esp*/ && scale == 0 /*times_1*/) {
          Print("[");
          PrintCPURegister(rm);
          if (disp < 0) {
            Print("-");
            disp = -disp;
          } else {
            Print("+");
          }
          PrintHex(disp);
          Print("]");
        } else {
          Print("[");
          PrintCPURegister(base);
          Print("+");
          PrintCPURegister(index);
          Print("*");
          PrintInt(1 << scale);
          if (disp < 0) {
            Print("-");
            disp = -disp;
          } else {
            Print("+");
          }
          PrintHex(disp);
          Print("]");
        }
        return mod == 2 ? 6 : 3;
      } else {
        // No sib.
        int disp = (mod == 2) ?
                   *reinterpret_cast<int32_t*>(modrmp + 1) :
                   *reinterpret_cast<int8_t*>(modrmp + 1);
        Print("[");
        PrintCPURegister(rm);
        if (disp < 0) {
          Print("-");
          disp = -disp;
        } else {
          Print("+");
        }
        PrintHex(disp);
        Print("]");
        return mod == 2 ? 5 : 2;
      }
      break;
    case 3:
      (this->*register_printer)(rm);
      return 1;
    default:
      UNIMPLEMENTED();
      return 1;
  }
  UNREACHABLE();
}


int X86Decoder::PrintRightOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp, &X86Decoder::PrintCPURegister);
}


int X86Decoder::PrintRightXmmOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp, &X86Decoder::PrintXmmRegister);
}


int X86Decoder::PrintRightByteOperand(uint8_t* modrmp) {
  return PrintRightOperandHelper(modrmp, &X86Decoder::PrintCPUByteRegister);
}


int X86Decoder::PrintOperands(const char* mnem,
                              OperandOrder op_order,
                              uint8_t* data) {
  uint8_t modrm = *data;
  int mod, regop, rm;
  GetModRm(modrm, &mod, &regop, &rm);
  int advance = 0;
  switch (op_order) {
    case REG_OPER_OP_ORDER: {
      Print(mnem);
      Print(" ");
      PrintCPURegister(regop);
      Print(",");
      advance = PrintRightOperand(data);
      break;
    }
    case OPER_REG_OP_ORDER: {
      Print(mnem);
      Print(" ");
      advance = PrintRightOperand(data);
      Print(",");
      PrintCPURegister(regop);
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
  return advance;
}


int X86Decoder::PrintImmediateOp(uint8_t* data) {
  bool sign_extension_bit = (*data & 0x02) != 0;
  uint8_t modrm = *(data+1);
  int mod, regop, rm;
  GetModRm(modrm, &mod, &regop, &rm);
  const char* mnem = "Imm???";
  switch (regop) {
    case 0: mnem = "add"; break;
    case 1: mnem = "or"; break;
    case 2: mnem = "adc"; break;
    case 3: mnem = "sbb"; break;
    case 4: mnem = "and"; break;
    case 5: mnem = "sub"; break;
    case 6: mnem = "xor"; break;
    case 7: mnem = "cmp"; break;
    default: UNIMPLEMENTED();
  }
  Print(mnem);
  Print(" ");
  int count = PrintRightOperand(data+1);
  if (sign_extension_bit) {
    Print(",");
    PrintHex(*(data + 1 + count));
    return 1 + count + 1 /*int8*/;
  } else {
    Print(",");
    PrintHex(*reinterpret_cast<int32_t*>(data + 1 + count));
    return 1 + count + 4 /*int32_t*/;
  }
}


int X86Decoder::DecodeEnter(uint8_t* data) {
  uint16_t size = *reinterpret_cast<uint16_t*>(data + 1);
  uint8_t level = *reinterpret_cast<uint8_t*>(data + 3);
  Print("enter ");
  PrintInt(size);
  Print(", ");
  PrintInt(level);
  return 4;
}


// Returns number of bytes used, including *data.
int X86Decoder::JumpShort(uint8_t* data) {
  ASSERT(*data == 0xEB);
  uint8_t b = *(data+1);
  uword dest = reinterpret_cast<uword>(data) + static_cast<int8_t>(b) + 2;
  Print("jmp ");
  PrintAddress(dest);
  return 2;
}


// Returns number of bytes used, including *data.
int X86Decoder::JumpConditional(uint8_t* data, const char* comment) {
  ASSERT(*data == 0x0F);
  uint8_t cond = *(data+1) & 0x0F;
  uword dest = reinterpret_cast<uword>(data) +
               *reinterpret_cast<int32_t*>(data+2) + 6;
  const char* mnem = jump_conditional_mnem[cond];
  Print(mnem);
  Print(" ");
  PrintAddress(dest);
  if (comment != NULL) {
    Print(", ");
    Print(comment);
  }
  return 6;  // includes 0x0F
}


// Returns number of bytes used, including *data.
int X86Decoder::JumpConditionalShort(uint8_t* data, const char* comment) {
  uint8_t cond = *data & 0x0F;
  uint8_t b = *(data+1);
  word dest = reinterpret_cast<uword>(data) + static_cast<int8_t>(b) + 2;
  const char* mnem = jump_conditional_mnem[cond];
  Print(mnem);
  Print(" ");
  PrintAddress(dest);
  if (comment != NULL) {
    Print(", ");
    Print(comment);
  }
  return 2;
}


// Returns number of bytes used, including *data.
int X86Decoder::SetCC(uint8_t* data) {
  ASSERT(*data == 0x0F);
  uint8_t cond = *(data+1) & 0x0F;
  const char* mnem = set_conditional_mnem[cond];
  Print(mnem);
  Print(" ");
  PrintRightByteOperand(data+2);
  return 3;  // includes 0x0F
}


// Returns number of bytes used, including *data.
int X86Decoder::CMov(uint8_t* data) {
  ASSERT(*data == 0x0F);
  uint8_t cond = *(data + 1) & 0x0F;
  const char* mnem = conditional_move_mnem[cond];
  int op_size = PrintOperands(mnem, REG_OPER_OP_ORDER, data + 2);
  return 2 + op_size;  // includes 0x0F
}


int X86Decoder::D1D3C1Instruction(uint8_t* data) {
  uint8_t op = *data;
  ASSERT(op == 0xD1 || op == 0xD3 || op == 0xC1);
  int mod, regop, rm;
  GetModRm(*(data+1), &mod, &regop, &rm);
  int num_bytes = 1;
  const char* mnem = NULL;
  switch (regop) {
    case 2: mnem = "rcl"; break;
    case 4: mnem = "shl"; break;
    case 5: mnem = "shr"; break;
    case 7: mnem = "sar"; break;
    default: UNIMPLEMENTED();
  }
  ASSERT(mnem != NULL);
  Print(mnem);
  Print(" ");

  if (op == 0xD1) {
    num_bytes += PrintRightOperand(data+1);
    Print(", 1");
  } else if (op == 0xC1) {
    num_bytes += PrintRightOperand(data+1);
    Print(", ");
    PrintInt(*(data+2));
    num_bytes++;
  } else {
    ASSERT(op == 0xD3);
    num_bytes += PrintRightOperand(data+1);
    Print(", cl");
  }
  return num_bytes;
}


uint8_t* X86Decoder::F3Instruction(uint8_t* data) {
  if (*(data+1) == 0x0F) {
    uint8_t b2 = *(data+2);
    switch (b2) {
      case 0x2C: {
        data += 3;
        data += PrintOperands("cvttss2si", REG_OPER_OP_ORDER, data);
        break;
      }
      case 0x2A: {
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        Print("cvtsi2ss ");
        PrintXmmRegister(regop);
        Print(",");
        data += PrintRightOperand(data);
        break;
      }
      case 0x2D: {
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        Print("cvtss2si ");
        PrintCPURegister(regop);
        Print(",");
        data += PrintRightXmmOperand(data);
        break;
      }
      case 0x11: {
        // movss xmm <- address
        Print("movss ");
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        data += PrintRightXmmOperand(data);
        Print(",");
        PrintXmmRegister(regop);
        break;
      }
      case 0x10: {
        // movss address <- xmm
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        Print("movss ");
        PrintXmmRegister(regop);
        Print(",");
        data += PrintRightOperand(data);
        break;
      }
      case 0x51:  // Fall through.
      case 0x58:  // Fall through.
      case 0x59:  // Fall through.
      case 0x5A:  // Fall through.
      case 0x5C:  // Fall through.
      case 0x5E:  // Fall through.
      case 0xE6: {
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        const char* mnem = "?? 0xF3";
        switch (b2) {
          case 0x51: mnem = "sqrtss"; break;
          case 0x58: mnem = "addss"; break;
          case 0x59: mnem = "mulss"; break;
          case 0x5A: mnem = "cvtss2sd"; break;
          case 0x5C: mnem = "subss"; break;
          case 0x5E: mnem = "divss"; break;
          case 0xE6: mnem = "cvtdq2pd"; break;
          default: UNIMPLEMENTED();
        }
        Print(mnem);
        Print(" ");
        PrintXmmRegister(regop);
        Print(",");
        data += PrintRightXmmOperand(data);
        break;
      }
      case 0x7E: {
        data += 3;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        Print("movq ");
        PrintXmmRegister(regop);
        Print(",");
        data += PrintRightOperand(data);
        break;
      }
      default:
        UNIMPLEMENTED();
    }
  } else if (*(data+1) == 0xA4) {
    Print("rep_movsb");
    data += 2;
  } else {
    UNIMPLEMENTED();
  }
  return data;
}


// Returns number of bytes used, including *data.
int X86Decoder::F7Instruction(uint8_t* data) {
  ASSERT(*data == 0xF7);
  uint8_t modrm = *(data+1);
  int mod, regop, rm;
  GetModRm(modrm, &mod, &regop, &rm);
  if (mod == 3 && regop != 0) {
    const char* mnem = NULL;
    switch (regop) {
      case 2: mnem = "not"; break;
      case 3: mnem = "neg"; break;
      case 4: mnem = "mul"; break;
      case 5: mnem = "imul"; break;
      case 7: mnem = "idiv"; break;
      default: UNIMPLEMENTED();
    }
    Print(mnem);
    Print(" ");
    PrintCPURegister(rm);
    return 2;
  } else if (mod == 3 && regop == eax) {
    int32_t imm = *reinterpret_cast<int32_t*>(data+2);
    Print("test ");
    PrintCPURegister(rm);
    Print(",");
    PrintHex(imm);
    return 6;
  } else if (regop == eax) {
    Print("test ");
    int count = PrintRightOperand(data+1);
    int32_t imm = *reinterpret_cast<int32_t*>(data+1+count);
    Print(",");
    PrintHex(imm);
    return 1+count+4 /*int32_t*/;
  } else if (regop == 5) {
    Print("imul ");
    int count = PrintRightOperand(data + 1);
    return 1 + count;
  } else if (regop == 4) {
    Print("mul ");
    int count = PrintRightOperand(data + 1);
    return 1 + count;
  } else {
    OS::Print("F7 Instr regop %d\n", regop);
    UNIMPLEMENTED();
    return 2;
  }
}

// Returns number of bytes used, including *data.
int X86Decoder::FPUInstruction(uint8_t* data) {
  uint8_t b1 = *data;
  uint8_t b2 = *(data + 1);
  if (b1 == 0xD9) {
    const char* mnem = NULL;
    switch (b2) {
      case 0xE0: mnem = "fchs"; break;
      case 0xE1: mnem = "fabs"; break;
      case 0xE4: mnem = "ftst"; break;
      case 0xE8: mnem = "fld1"; break;
      case 0xEE: mnem = "fldz"; break;
      case 0xF2: mnem = "fptan"; break;
      case 0xF5: mnem = "fprem1"; break;
      case 0xF8: mnem = "fprem"; break;
      case 0xF7: mnem = "fincstp"; break;
      case 0xFE: mnem = "fsin"; break;
      case 0xFF: mnem = "fcos"; break;
    }
    if (mnem != NULL) {
      Print(mnem);
      return 2;
    } else if ((b2 & 0xF8) == 0xC8) {
      Print("fxch st");
      PrintInt(b2 & 0x7);
      return 2;
    } else {
      int mod, regop, rm;
      GetModRm(*(data+1), &mod, &regop, &rm);
      const char* mnem = "? FPU 0xD9";
      switch (regop) {
        case 0: mnem = "fld_s"; break;
        case 3: mnem = "fstp_s"; break;
        case 5: mnem = "fldcw"; break;
        case 7: mnem = "fnstcw"; break;
        default: UNIMPLEMENTED();
      }
      Print(mnem);
      Print(" ");
      int count = PrintRightOperand(data + 1);
      return count + 1;
    }
  } else if (b1 == 0xDD) {
    if ((b2 & 0xF8) == 0xC0) {
      Print("ffree st");
      PrintInt(b2 & 0x7);
      return 2;
    } else {
      int mod, regop, rm;
      GetModRm(*(data+1), &mod, &regop, &rm);
      const char* mnem = "? FPU 0xDD";
      switch (regop) {
        case 0: mnem = "fld_d"; break;
        case 3: mnem = "fstp_d"; break;
       default: UNIMPLEMENTED();
      }
      Print(mnem);
      Print(" ");
      int count = PrintRightOperand(data + 1);
      return count + 1;
    }
  } else if (b1 == 0xDB) {
    int mod, regop, rm;
    GetModRm(*(data+1), &mod, &regop, &rm);
    const char* mnem = "? FPU 0xDB";
    switch (regop) {
      case 0: mnem = "fild_s"; break;
      case 2: mnem = "fist_s"; break;
      case 3: mnem = "fistp_s"; break;
      default: UNIMPLEMENTED();
    }
    Print(mnem);
    Print(" ");
    int count = PrintRightOperand(data + 1);
    return count + 1;
  } else if (b1 == 0xDF) {
    if (b2 == 0xE0) {
      Print("fnstsw_ax");
      return 2;
    }
    int mod, regop, rm;
    GetModRm(*(data+1), &mod, &regop, &rm);
    const char* mnem = "? FPU 0xDF";
    switch (regop) {
      case 5: mnem = "fild_d"; break;
      case 7: mnem = "fistp_d"; break;
      default: UNIMPLEMENTED();
    }
    Print(mnem);
    Print(" ");
    int count = PrintRightOperand(data + 1);
    return count + 1;
  } else if (b1 == 0xDC || b1 == 0xDE) {
    bool is_pop = (b1 == 0xDE);
    if (is_pop && b2 == 0xD9) {
      Print("fcompp");
      return 2;
    }
    const char* mnem = "FP0xDC";
    switch (b2 & 0xF8) {
      case 0xC0: mnem = "fadd"; break;
      case 0xE8: mnem = "fsub"; break;
      case 0xC8: mnem = "fmul"; break;
      case 0xF8: mnem = "fdiv"; break;
      default: UNIMPLEMENTED();
    }
    Print(mnem);
    Print(is_pop ? "p" : "");
    Print(" st");
    PrintInt(b2 & 0x7);
    return 2;
  } else if (b1 == 0xDA && b2 == 0xE9) {
    const char* mnem = "fucompp";
    Print(mnem);
    return 2;
  }
  Print("Unknown FP instruction");
  return 2;
}


uint8_t* X86Decoder::SSEInstruction(uint8_t prefix, uint8_t primary,
                                    uint8_t* data) {
  ASSERT(prefix == 0x0F);
  int mod, regop, rm;
  if (primary == 0x10) {
    GetModRm(*data, &mod, &regop, &rm);
    Print("movups ");
    PrintXmmRegister(regop);
    Print(",");
    data += PrintRightOperand(data);
  } else if (primary == 0x11) {
    int mod, regop, rm;
    GetModRm(*data, &mod, &regop, &rm);
    Print("movups ");
    data += PrintRightXmmOperand(data);
    Print(",");
    PrintXmmRegister(regop);
  } else if (IsTwoXmmRegInstruction(primary)) {
    const char* f0mnem = F0Mnem(primary);
    int mod, regop, rm;
    GetModRm(*data, &mod, &regop, &rm);
    Print(f0mnem);
    Print(" ");
    PrintXmmRegister(regop);
    Print(",");
    data += PrintRightXmmOperand(data);
  }
  return data;
}


int X86Decoder::BitwisePDInstruction(uint8_t* data) {
  const char* mnem = (*data == 0x57)
      ? "xorpd"
      : (*data == 0x56)
        ? "orpd"
        : "andpd";
  int mod, regop, rm;
  GetModRm(*(data+1), &mod, &regop, &rm);
  Print(mnem);
  Print(" ");
  PrintXmmRegister(regop);
  Print(",");
  return 1 + PrintRightXmmOperand(data+1);
}


int X86Decoder::Packed660F38Instruction(uint8_t* data) {
  if (*(data+1) == 0x25) {
    Print("pmovsxdq ");
    int mod, regop, rm;
    GetModRm(*(data+2), &mod, &regop, &rm);
    PrintXmmRegister(regop);
    Print(",");
    return 2 + PrintRightXmmOperand(data+2);
  } else if (*(data+1) == 0x29) {
    Print("pcmpeqq ");
    int mod, regop, rm;
    GetModRm(*(data+2), &mod, &regop, &rm);
    PrintXmmRegister(regop);
    Print(",");
    return 2 + PrintRightXmmOperand(data+2);
  }
  UNREACHABLE();
  return 1;
}


// Called when disassembling test eax, 0xXXXXX.
void X86Decoder::CheckPrintStop(uint8_t* data) {
  // Recognize stop pattern.
  if (*reinterpret_cast<uint8_t*>(data + 5) == 0xCC) {
    Print("  STOP:'");
    const char* text = *reinterpret_cast<const char**>(data + 1);
    Print(text);
    Print("'");
  }
}

const char* X86Decoder::GetBranchPrefix(uint8_t** data) {
  // We use these two prefixes only with branch prediction
  switch (**data) {
    case 0x3E:  // ds
      (*data)++;
      return "predicted taken";
    case 0x2E:  // cs
      (*data)++;
      return "predicted not taken";
    case 0xF0:  // lock
      Print("lock ");
      (*data)++;
      return NULL;
    default:  // Ignore all other instructions.
      return NULL;
  }
}


bool X86Decoder::DecodeInstructionType(const InstructionDesc& idesc,
                                       const char* branch_hint,
                                       uint8_t** data) {
  switch (idesc.type) {
    case ZERO_OPERANDS_INSTR:
      Print(idesc.mnem);
      (*data)++;
      return true;

    case TWO_OPERANDS_INSTR:
      (*data)++;
      (*data) += PrintOperands(idesc.mnem, idesc.op_order_, *data);
      return true;

    case JUMP_CONDITIONAL_SHORT_INSTR:
      (*data) += JumpConditionalShort(*data, branch_hint);
      return true;

    case REGISTER_INSTR:
      Print(idesc.mnem);
      Print(" ");
      PrintCPURegister(**data & 0x07);
      (*data)++;
      return true;

    case MOVE_REG_INSTR: {
      uword addr = *reinterpret_cast<uword*>(*data+1);
      Print("mov ");
      PrintCPURegister(**data & 0x07),
      Print(",");
      PrintAddress(addr);
      (*data) += 5;
      return true;
    }

    case CALL_JUMP_INSTR: {
      uword addr = reinterpret_cast<uword>(*data) +
                   *reinterpret_cast<uword*>(*data+1) + 5;
      Print(idesc.mnem);
      Print(" ");
      PrintAddress(addr);
      (*data) += 5;
      return true;
    }

    case SHORT_IMMEDIATE_INSTR: {
      uword addr = *reinterpret_cast<uword*>(*data+1);
      Print(idesc.mnem);
      Print(" eax, ");
      PrintAddress(addr);
      (*data) += 5;
      return true;
    }

    case NO_INSTR:
      return false;

    default:
      UNIMPLEMENTED();  // This type is not implemented.
      return false;
  }
}


int X86Decoder::InstructionDecode(uword pc) {
  uint8_t* data = reinterpret_cast<uint8_t*>(pc);
  // Check for hints.
  const char* branch_hint = GetBranchPrefix(&data);
  const InstructionDesc& idesc = instruction_table.Get(*data);
  // Will be set to false if the current instruction
  // is not in 'instructions' table.
  bool processed = DecodeInstructionType(idesc, branch_hint, &data);
  //----------------------------
  if (!processed) {
    switch (*data) {
      case 0xC2:
        Print("ret ");
        PrintHex(*reinterpret_cast<uint16_t*>(data+1));
        data += 3;
        break;

      case 0x69:  // fall through
      case 0x6B:
      { int mod, regop, rm;
        GetModRm(*(data+1), &mod, &regop, &rm);
        int32_t imm =
        *data == 0x6B ? *(data+2) : *reinterpret_cast<int32_t*>(data+2);
        Print("imul ");
        PrintCPURegister(regop);
        Print(",");
        PrintCPURegister(rm);
        Print(",");
        PrintHex(imm);
        data += 2 + (*data == 0x6B ? 1 : 4);
      }
        break;

      case 0xF6:
      { int mod, regop, rm;
        GetModRm(*(data+1), &mod, &regop, &rm);
        if ((mod == 3) && (regop == eax)) {
          Print("test_b ");
          PrintCPURegister(rm);
          Print(",");
          PrintHex(*(data+2));
        } else {
          UNIMPLEMENTED();
        }
        data += 3;
      }
        break;

      case 0x81:  // fall through
      case 0x83:  // 0x81 with sign extension bit set
        data += PrintImmediateOp(data);
        break;

      case 0x0F:
      { uint8_t f0byte = *(data+1);
        const char* f0mnem = F0Mnem(f0byte);
        if (f0byte == 0xA2 || f0byte == 0x31) {
          Print(f0mnem);
          data += 2;
        } else if ((f0byte & 0xF0) == 0x80) {
          data += JumpConditional(data, branch_hint);
        } else if (f0byte == 0xBE || f0byte == 0xBF || f0byte == 0xB6 ||
                   f0byte == 0xB7 || f0byte == 0xAF || f0byte == 0xBD) {
          data += 2;
          data += PrintOperands(f0mnem, REG_OPER_OP_ORDER, data);
        } else if (f0byte == 0x57) {
          data += 2;
          int mod, regop, rm;
          GetModRm(*data, &mod, &regop, &rm);
          Print(f0mnem);
          Print(" ");
          PrintXmmRegister(regop);
          Print(",");
          data += PrintRightXmmOperand(data);
        } else if (f0byte == 0xB1) {
          data += 2;
          data += PrintOperands(f0mnem, OPER_REG_OP_ORDER, data);
        } else if ((f0byte & 0xF0) == 0x90) {
          data += SetCC(data);
        } else if ((f0byte & 0xF0) == 0x40) {
          data += CMov(data);
        } else if (f0byte == 0x2F) {
          data += 2;
          int mod, regop, rm;
          GetModRm(*data, &mod, &regop, &rm);
          Print("comiss ");
          PrintXmmRegister(regop);
          Print(",");
          PrintXmmRegister(rm);
          data++;
        } else if (f0byte == 0x1F) {
          if (*(data+2) == 0x00) {
            Print("nop");
            data += 3;
          } else if (*(data+2) == 0x40 && *(data+3) == 0x00) {
            Print("nop");
            data += 4;
          } else if (*(data+2) == 0x44 &&
                     *(data+3) == 0x00 &&
                     *(data+4) == 0x00) {
            Print("nop");
            data += 5;
          } else if (*(data+2) == 0x80 &&
                     *(data+3) == 0x00 &&
                     *(data+3) == 0x00 &&
                     *(data+3) == 0x00 &&
                     *(data+4) == 0x00) {
            Print("nop");
            data += 7;
          } else if (*(data+2) == 0x84 &&
                     *(data+3) == 0x00 &&
                     *(data+3) == 0x00 &&
                     *(data+3) == 0x00 &&
                     *(data+3) == 0x00 &&
                     *(data+4) == 0x00) {
            Print("nop");
            data += 8;
          } else {
            UNIMPLEMENTED();
          }
        } else {
          data += 2;
          if (f0byte == 0xAB || f0byte == 0xA4 || f0byte == 0xA5 ||
              f0byte == 0xAC || f0byte == 0xAD) {
            // shrd, shld, bts
            Print(f0mnem);
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print(" ");
            data += PrintRightOperand(data);
            Print(",");
            PrintCPURegister(regop);
            if (f0byte == 0xAB) {
              // Done.
            } else if (f0byte == 0xA5 || f0byte == 0xAD) {
              Print(",cl");
            } else {
              Print(", ");
              PrintInt(*(data++));
            }
          } else if ((f0byte == 0x10) || (f0byte == 0x11) ||
                     IsTwoXmmRegInstruction(f0byte)) {
            data = SSEInstruction(0x0F, f0byte, data);
          } else if (f0byte == 0x50) {
            Print("movmskps ");
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            PrintCPURegister(regop);
            Print(",");
            data += PrintRightXmmOperand(data);
          } else if (f0byte == 0xC2 || f0byte == 0xC6) {
            if (f0byte == 0xC2)
              Print("cmpps ");
            else
              Print("shufps ");
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print(" ");
            PrintXmmRegister(regop);
            Print(",");
            data += PrintRightXmmOperand(data);
            int comparison = *data;
            Print(" [");
            PrintHex(comparison);
            Print("]");
            data++;
          } else {
            UNIMPLEMENTED();
          }
        }
      }
        break;

      case 0x8F:
      { data++;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        if (regop == eax) {
          Print("pop ");
          data += PrintRightOperand(data);
        }
      }
        break;

      case 0xFF:
      { data++;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        const char* mnem = NULL;
        switch (regop) {
          case esi: mnem = "push"; break;
          case eax: mnem = "inc"; break;
          case ecx: mnem = "dec"; break;
          case edx: mnem = "call"; break;
          case esp: mnem = "jmp"; break;
          default: mnem = "??? 0xFF";
        }
        Print(mnem);
        Print(" ");
        data += PrintRightOperand(data);
      }
        break;

      case 0xC7:  // imm32, fall through
      case 0xC6:  // imm8
      { bool is_byte = *data == 0xC6;
        data++;
        Print(is_byte ? "mov_b" : "mov");
        Print(" ");
        data += PrintRightOperand(data);
        int32_t imm = is_byte ? *data : *reinterpret_cast<int32_t*>(data);
        Print(",");
        PrintHex(imm);
        data += is_byte ? 1 : 4;
      }
        break;

      case 0x80:
      { data++;
        Print("cmpb ");
        data += PrintRightOperand(data);
        int32_t imm = *data;
        Print(",");
        PrintHex(imm);
        data++;
      }
        break;

      case 0x88:  // 8bit, fall through
      case 0x89:  // 32bit
      { bool is_byte = *data == 0x88;
        int mod, regop, rm;
        data++;
        GetModRm(*data, &mod, &regop, &rm);
        Print(is_byte ? "mov_b" : "mov");
        Print(" ");
        data += PrintRightOperand(data);
        Print(",");
        PrintCPURegister(regop);
      }
        break;

      case 0x66:  // prefix
        data++;
        if (*data == 0x8B) {
          data++;
          data += PrintOperands("mov_w", REG_OPER_OP_ORDER, data);
        } else if (*data == 0x89) {
          data++;
          int mod, regop, rm;
          GetModRm(*data, &mod, &regop, &rm);
          Print("mov_w ");
          data += PrintRightOperand(data);
          Print(",");
          PrintCPURegister(regop);
        } else if (*data == 0x0F) {
          data++;
          if (*data == 0X6E) {
            data++;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print("movd ");
            PrintXmmRegister(regop);
            Print(",");
            PrintCPURegister(rm);
            data++;
          } else if (*data == 0X7E) {
            data++;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print("movd ");
            PrintCPURegister(rm);
            Print(",");
            PrintXmmRegister(regop);
            data++;
          } else if (*data == 0xD6) {
            data++;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print("movq ");
            data += PrintRightOperand(data);
            Print(",");
            PrintXmmRegister(regop);
          } else if (*data == 0x57 || *data == 0x56 || *data == 0x54) {
            data += BitwisePDInstruction(data);
          } else if (*data == 0x1F &&
                     *(data+1) == 0x44 &&
                     *(data+2) == 0x00 &&
                     *(data+3) == 0x00) {
            data += 4;
            Print("nop");
          } else if (*data == 0x50) {
            Print("movmskpd ");
            data++;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            PrintCPURegister(regop);
            Print(",");
            data += PrintRightXmmOperand(data);
          } else if (*data == 0x3A && *(data+1) == 0x16) {
            Print("pextrd ");
            data += 2;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            PrintCPURegister(rm);
            Print(",");
            PrintXmmRegister(regop);
            Print(",");
            PrintHex(*(data+1));
            data += 2;
          } else if (*data == 0x38) {
            data += Packed660F38Instruction(data);
          } else if (*data == 0xEF) {
            int mod, regop, rm;
            GetModRm(*(data+1), &mod, &regop, &rm);
            Print("pxor ");
            PrintXmmRegister(regop);
            Print(",");
            PrintXmmRegister(rm);
            data += 2;
          } else if (*data == 0x3A) {
            data++;
            if (*data == 0x0B) {
              data++;
              int mod, regop, rm;
              GetModRm(*data, &mod, &regop, &rm);
              Print("roundsd ");
              PrintXmmRegister(regop);
              Print(", ");
              PrintXmmRegister(rm);
              Print(", ");
              PrintInt(data[1] & 3);
              data += 2;
            } else {
              UNIMPLEMENTED();
            }
          } else if (*data == 0x14) {
            int mod, regop, rm;
            GetModRm(*(data+1), &mod, &regop, &rm);
            Print("unpcklpd ");
            PrintXmmRegister(regop);
            Print(",");
            PrintXmmRegister(rm);
            data += 2;
          } else if (*data == 0x15) {
            int mod, regop, rm;
            GetModRm(*(data+1), &mod, &regop, &rm);
            Print("unpckhpd ");
            PrintXmmRegister(regop);
            Print(",");
            PrintXmmRegister(rm);
            data += 2;
          } else if ((*data == 0xFE) || (*data == 0xFA) || (*data == 0x2F) ||
                     (*data == 0x58) || (*data == 0x5C) || (*data == 0x59) ||
                     (*data == 0x5E) || (*data == 0x5D) || (*data == 0x5F) ||
                     (*data == 0x51) || (*data == 0x5A)) {
            const char* mnemonic = PackedDoubleMnemonic(*data);
            int mod, regop, rm;
            GetModRm(*(data+1), &mod, &regop, &rm);
            Print(mnemonic);
            PrintXmmRegister(regop);
            Print(",");
            PrintXmmRegister(rm);
            data += 2;
          } else if (*data == 0xC6) {
            int mod, regop, rm;
            data++;
            GetModRm(*data, &mod, &regop, &rm);
            Print("shufpd ");
            PrintXmmRegister(regop);
            Print(",");
            data += PrintRightXmmOperand(data);
            int comparison = *data;
            Print(" [");
            PrintHex(comparison);
            Print("]");
            data++;
          } else {
              UNIMPLEMENTED();
          }
        } else if (*data == 0x90) {
          data++;
          Print("nop");
        } else {
          UNIMPLEMENTED();
        }
        break;

      case 0xFE:
      { data++;
        int mod, regop, rm;
        GetModRm(*data, &mod, &regop, &rm);
        if (mod == 3 && regop == ecx) {
          Print("dec_b ");
          PrintCPURegister(rm);
        } else {
          UNIMPLEMENTED();
        }
        data++;
      }
        break;

      case 0x68:
        Print("push ");
        PrintHex(*reinterpret_cast<int32_t*>(data+1));
        data += 5;
        break;

      case 0x6A:
        Print("push ");
        PrintHex(*reinterpret_cast<int8_t*>(data + 1));
        data += 2;
        break;

      case 0xA8:
        Print("test al,");
        PrintHex(*reinterpret_cast<uint8_t*>(data+1));
        data += 2;
        break;

      case 0xA9:
        Print("test eax,");
        PrintHex(*reinterpret_cast<int32_t*>(data+1));
        CheckPrintStop(data);
        data += 5;
        break;

      case 0xD1:  // fall through
      case 0xD3:  // fall through
      case 0xC1:
        data += D1D3C1Instruction(data);
        break;

      case 0xD9:  // fall through
      case 0xDA:  // fall through
      case 0xDB:  // fall through
      case 0xDC:  // fall through
      case 0xDD:  // fall through
      case 0xDE:  // fall through
      case 0xDF:
        data += FPUInstruction(data);
        break;

      case 0xEB:
        data += JumpShort(data);
        break;

      case 0xF3:
        data = F3Instruction(data);
        break;
      case 0xF2: {
        if (*(data+1) == 0x0F) {
          uint8_t b2 = *(data+2);
          if (b2 == 0x11) {
            Print("movsd ");
            data += 3;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            data += PrintRightXmmOperand(data);
            Print(",");
            PrintXmmRegister(regop);
          } else if (b2 == 0x10) {
            data += 3;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            Print("movsd ");
            PrintXmmRegister(regop);
            Print(",");
            data += PrintRightOperand(data);
          } else {
            const char* mnem = "? 0xF2";
            switch (b2) {
              case 0x2A: mnem = "cvtsi2sd"; break;
              case 0x2C: mnem = "cvttsd2si"; break;
              case 0x2D: mnem = "cvtsd2i"; break;
              case 0x51: mnem = "sqrtsd"; break;
              case 0x58: mnem = "addsd"; break;
              case 0x59: mnem = "mulsd"; break;
              case 0x5A: mnem = "cvtsd2ss"; break;
              case 0x5C: mnem = "subsd"; break;
              case 0x5E: mnem = "divsd"; break;
              default: UNIMPLEMENTED();
            }
            data += 3;
            int mod, regop, rm;
            GetModRm(*data, &mod, &regop, &rm);
            if (b2 == 0x2A) {
              Print(mnem);
              Print(" ");
              PrintXmmRegister(regop);
              Print(",");
              data += PrintRightOperand(data);
            } else if ((b2 == 0x2D) || (b2 == 0x2C)) {
              Print(mnem);
              Print(" ");
              PrintCPURegister(regop);
              Print(",");
              PrintXmmRegister(rm);
              data++;
            } else {
              Print(mnem);
              Print(" ");
              PrintXmmRegister(regop);
              Print(",");
              data += PrintRightXmmOperand(data);
            }
          }
        } else {
          UNIMPLEMENTED();
        }
        break;
      }
      case 0xF7:
        data += F7Instruction(data);
        break;

      case 0xC8:
        data += DecodeEnter(data);
        break;

      default:
        OS::Print("Unknown case %#x\n", *data);
        UNIMPLEMENTED();
    }
  }

  int instr_len = data - reinterpret_cast<uint8_t*>(pc);
  ASSERT(instr_len > 0);  // Ensure progress.

  return instr_len;
}


void Disassembler::DecodeInstruction(char* hex_buffer, intptr_t hex_size,
                                     char* human_buffer, intptr_t human_size,
                                     int* out_instr_len, uword pc) {
  ASSERT(hex_size > 0);
  ASSERT(human_size > 0);
  X86Decoder decoder(human_buffer, human_size);
  int instruction_length = decoder.InstructionDecode(pc);
  uint8_t* pc_ptr = reinterpret_cast<uint8_t*>(pc);
  int hex_index = 0;
  int remaining_size = hex_size - hex_index;
  for (int i = 0; (i < instruction_length) && (remaining_size > 2); ++i) {
    OS::SNPrint(&hex_buffer[hex_index], remaining_size, "%02x", pc_ptr[i]);
    hex_index += 2;
    remaining_size -= 2;
  }
  hex_buffer[hex_index] = '\0';
  if (out_instr_len) {
    *out_instr_len = instruction_length;
  }
}


void Disassembler::Disassemble(uword start,
                               uword end,
                               DisassemblyFormatter* formatter,
                               const Code::Comments& comments) {
  ASSERT(formatter != NULL);
  char hex_buffer[kHexadecimalBufferSize];  // Instruction in hexadecimal form.
  char human_buffer[kUserReadableBufferSize];  // Human-readable instruction.
  uword pc = start;
  intptr_t comment_finger = 0;
  while (pc < end) {
    const intptr_t offset = pc - start;
    while (comment_finger < comments.Length() &&
           comments.PCOffsetAt(comment_finger) <= offset) {
      formatter->Print(
          "        ;; %s\n",
          String::Handle(comments.CommentAt(comment_finger)).ToCString());
      comment_finger++;
    }
    int instruction_length;
    DecodeInstruction(hex_buffer,
                      sizeof(hex_buffer),
                      human_buffer,
                      sizeof(human_buffer),
                      &instruction_length, pc);
    formatter->ConsumeInstruction(hex_buffer,
                                  sizeof(hex_buffer),
                                  human_buffer,
                                  sizeof(human_buffer),
                                  pc);
    pc += instruction_length;
  }

  return;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
