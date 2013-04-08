// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_ARM_H_
#define VM_ASSEMBLER_ARM_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_arm.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_arm.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;

class Label : public ValueObject {
 public:
  Label() : position_(0) { }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  int Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  int position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(int position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(int position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class CPUFeatures : public AllStatic {
 public:
  static void InitOnce();
  static bool double_truncate_round_supported() {
    UNIMPLEMENTED();
    return false;
  }
  static bool integer_division_supported();
#if defined(USING_SIMULATOR)
  static void set_integer_division_supported(bool supported);
#endif
 private:
  static bool integer_division_supported_;
#if defined(DEBUG)
  static bool initialized_;
#endif
};


// Encodes Addressing Mode 1 - Data-processing operands.
class ShifterOperand : public ValueObject {
 public:
  // Data-processing operands - Uninitialized.
  ShifterOperand() : type_(-1), encoding_(-1) { }

  // Data-processing operands - Copy constructor.
  ShifterOperand(const ShifterOperand& other)
      : ValueObject(), type_(other.type_), encoding_(other.encoding_) { }

  // Data-processing operands - Assignment operator.
  ShifterOperand& operator=(const ShifterOperand& other) {
    type_ = other.type_;
    encoding_ = other.encoding_;
    return *this;
  }

  // Data-processing operands - Immediate.
  explicit ShifterOperand(uint32_t immediate) {
    ASSERT(immediate < (1 << kImmed8Bits));
    type_ = 1;
    encoding_ = immediate;
  }

  // Data-processing operands - Rotated immediate.
  ShifterOperand(uint32_t rotate, uint32_t immed8) {
    ASSERT((rotate < (1 << kRotateBits)) && (immed8 < (1 << kImmed8Bits)));
    type_ = 1;
    encoding_ = (rotate << kRotateShift) | (immed8 << kImmed8Shift);
  }

  // Data-processing operands - Register.
  explicit ShifterOperand(Register rm) {
    type_ = 0;
    encoding_ = static_cast<uint32_t>(rm);
  }

  // Data-processing operands - Logical shift/rotate by immediate.
  ShifterOperand(Register rm, Shift shift, uint32_t shift_imm) {
    ASSERT(shift_imm < (1 << kShiftImmBits));
    type_ = 0;
    encoding_ = shift_imm << kShiftImmShift |
                static_cast<uint32_t>(shift) << kShiftShift |
                static_cast<uint32_t>(rm);
  }

  // Data-processing operands - Logical shift/rotate by register.
  ShifterOperand(Register rm, Shift shift, Register rs) {
    type_ = 0;
    encoding_ = static_cast<uint32_t>(rs) << kShiftRegisterShift |
                static_cast<uint32_t>(shift) << kShiftShift | (1 << 4) |
                static_cast<uint32_t>(rm);
  }

  static bool CanHold(uint32_t immediate, ShifterOperand* shifter_op) {
    // Avoid the more expensive test for frequent small immediate values.
    if (immediate < (1 << kImmed8Bits)) {
      shifter_op->type_ = 1;
      shifter_op->encoding_ = (0 << kRotateShift) | (immediate << kImmed8Shift);
      return true;
    }
    // Note that immediate must be unsigned for the test to work correctly.
    for (int rot = 0; rot < 16; rot++) {
      uint32_t imm8 = (immediate << 2*rot) | (immediate >> (32 - 2*rot));
      if (imm8 < (1 << kImmed8Bits)) {
        shifter_op->type_ = 1;
        shifter_op->encoding_ = (rot << kRotateShift) | (imm8 << kImmed8Shift);
        return true;
      }
    }
    return false;
  }

 private:
  bool is_valid() const { return (type_ == 0) || (type_ == 1); }

  uint32_t type() const {
    ASSERT(is_valid());
    return type_;
  }

  uint32_t encoding() const {
    ASSERT(is_valid());
    return encoding_;
  }

  uint32_t type_;  // Encodes the type field (bits 27-25) in the instruction.
  uint32_t encoding_;

  friend class Assembler;
  friend class Address;
};


enum LoadOperandType {
  kLoadSignedByte,
  kLoadUnsignedByte,
  kLoadSignedHalfword,
  kLoadUnsignedHalfword,
  kLoadWord,
  kLoadWordPair,
  kLoadSWord,
  kLoadDWord
};


enum StoreOperandType {
  kStoreByte,
  kStoreHalfword,
  kStoreWord,
  kStoreWordPair,
  kStoreSWord,
  kStoreDWord
};


// Load/store multiple addressing mode.
enum BlockAddressMode {
  // bit encoding P U W
  DA           = (0|0|0) << 21,  // decrement after
  IA           = (0|4|0) << 21,  // increment after
  DB           = (8|0|0) << 21,  // decrement before
  IB           = (8|4|0) << 21,  // increment before
  DA_W         = (0|0|1) << 21,  // decrement after with writeback to base
  IA_W         = (0|4|1) << 21,  // increment after with writeback to base
  DB_W         = (8|0|1) << 21,  // decrement before with writeback to base
  IB_W         = (8|4|1) << 21   // increment before with writeback to base
};


class Address : public ValueObject {
 public:
  enum OffsetKind {
    Immediate,
    ShiftedRegister,
  };

  // Memory operand addressing mode
  enum Mode {
    // bit encoding P U W
    Offset       = (8|4|0) << 21,  // offset (w/o writeback to base)
    PreIndex     = (8|4|1) << 21,  // pre-indexed addressing with writeback
    PostIndex    = (0|4|0) << 21,  // post-indexed addressing with writeback
    NegOffset    = (8|0|0) << 21,  // negative offset (w/o writeback to base)
    NegPreIndex  = (8|0|1) << 21,  // negative pre-indexed with writeback
    NegPostIndex = (0|0|0) << 21   // negative post-indexed with writeback
  };

  Address(const Address& other)
      : ValueObject(), encoding_(other.encoding_), kind_(other.kind_) {
  }

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    kind_ = other.kind_;
    return *this;
  }

  explicit Address(Register rn, int32_t offset = 0, Mode am = Offset) {
    ASSERT(Utils::IsAbsoluteUint(12, offset));
    kind_ = Immediate;
    if (offset < 0) {
      encoding_ = (am ^ (1 << kUShift)) | -offset;  // Flip U to adjust sign.
    } else {
      encoding_ = am | offset;
    }
    encoding_ |= static_cast<uint32_t>(rn) << kRnShift;
  }

  Address(Register rn, Register rm,
          Shift shift = LSL, uint32_t shift_imm = 0, Mode am = Offset) {
    ShifterOperand so(rm, shift, shift_imm);

    kind_ = ShiftedRegister;
    encoding_ = so.encoding() | am | (static_cast<uint32_t>(rn) << kRnShift);
  }

  static bool CanHoldLoadOffset(LoadOperandType type,
                                int32_t offset,
                                int32_t* offset_mask);
  static bool CanHoldStoreOffset(StoreOperandType type,
                                 int32_t offset,
                                 int32_t* offset_mask);

 private:
  uint32_t encoding() const { return encoding_; }

  // Encoding for addressing mode 3.
  uint32_t encoding3() const;

  // Encoding for vfp load/store addressing.
  uint32_t vencoding() const;

  OffsetKind kind() const { return kind_; }

  uint32_t encoding_;

  OffsetKind kind_;

  friend class Assembler;
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) { }

  FieldAddress(const FieldAddress& other) : Address(other) { }

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


class Assembler : public ValueObject {
 public:
  Assembler()
      : buffer_(),
        object_pool_(GrowableObjectArray::Handle()),
        prologue_offset_(-1),
        comments_() { }
  ~Assembler() { }

  void PopRegister(Register r) { Pop(r); }

  void Bind(Label* label);

  // Misc. functionality
  int CodeSize() const { return buffer_.Size(); }
  int prologue_offset() const { return prologue_offset_; }
  const ZoneGrowableArray<int>& GetPointerOffsets() const {
    ASSERT(buffer_.pointer_offsets().length() == 0);  // No pointers in code.
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, int length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  // Data-processing instructions.
  void and_(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void eor(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void sub(Register rd, Register rn, ShifterOperand so, Condition cond = AL);
  void subs(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void rsb(Register rd, Register rn, ShifterOperand so, Condition cond = AL);
  void rsbs(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void add(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void adds(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void adc(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void sbc(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void rsc(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void tst(Register rn, ShifterOperand so, Condition cond = AL);

  void teq(Register rn, ShifterOperand so, Condition cond = AL);

  void cmp(Register rn, ShifterOperand so, Condition cond = AL);

  void cmn(Register rn, ShifterOperand so, Condition cond = AL);

  void orr(Register rd, Register rn, ShifterOperand so, Condition cond = AL);
  void orrs(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void mov(Register rd, ShifterOperand so, Condition cond = AL);
  void movs(Register rd, ShifterOperand so, Condition cond = AL);

  void bic(Register rd, Register rn, ShifterOperand so, Condition cond = AL);

  void mvn(Register rd, ShifterOperand so, Condition cond = AL);
  void mvns(Register rd, ShifterOperand so, Condition cond = AL);

  // Miscellaneous data-processing instructions.
  void clz(Register rd, Register rm, Condition cond = AL);
  void movw(Register rd, uint16_t imm16, Condition cond = AL);
  void movt(Register rd, uint16_t imm16, Condition cond = AL);

  // Multiply instructions.
  void mul(Register rd, Register rn, Register rm, Condition cond = AL);
  void muls(Register rd, Register rn, Register rm, Condition cond = AL);
  void mla(Register rd, Register rn, Register rm, Register ra,
           Condition cond = AL);
  void mls(Register rd, Register rn, Register rm, Register ra,
           Condition cond = AL);
  void umull(Register rd_lo, Register rd_hi, Register rn, Register rm,
             Condition cond = AL);

  // Division instructions.
  void sdiv(Register rd, Register rn, Register rm, Condition cond = AL);
  void udiv(Register rd, Register rn, Register rm, Condition cond = AL);

  // Load/store instructions.
  void ldr(Register rd, Address ad, Condition cond = AL);
  void str(Register rd, Address ad, Condition cond = AL);

  void ldrb(Register rd, Address ad, Condition cond = AL);
  void strb(Register rd, Address ad, Condition cond = AL);

  void ldrh(Register rd, Address ad, Condition cond = AL);
  void strh(Register rd, Address ad, Condition cond = AL);

  void ldrsb(Register rd, Address ad, Condition cond = AL);
  void ldrsh(Register rd, Address ad, Condition cond = AL);

  void ldrd(Register rd, Address ad, Condition cond = AL);
  void strd(Register rd, Address ad, Condition cond = AL);

  void ldm(BlockAddressMode am, Register base,
           RegList regs, Condition cond = AL);
  void stm(BlockAddressMode am, Register base,
           RegList regs, Condition cond = AL);

  void ldrex(Register rd, Register rn, Condition cond = AL);
  void strex(Register rd, Register rt, Register rn, Condition cond = AL);

  // Miscellaneous instructions.
  void clrex();
  void nop(Condition cond = AL);

  // Note that gdb sets breakpoints using the undefined instruction 0xe7f001f0.
  void bkpt(uint16_t imm16, Condition cond = AL);
  void svc(uint32_t imm24, Condition cond = AL);

  // Floating point instructions (VFPv3-D16 and VFPv3-D32 profiles).
  void vmovsr(SRegister sn, Register rt, Condition cond = AL);
  void vmovrs(Register rt, SRegister sn, Condition cond = AL);
  void vmovsrr(SRegister sm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrs(Register rt, Register rt2, SRegister sm, Condition cond = AL);
  void vmovdrr(DRegister dm, Register rt, Register rt2, Condition cond = AL);
  void vmovrrd(Register rt, Register rt2, DRegister dm, Condition cond = AL);
  void vmovs(SRegister sd, SRegister sm, Condition cond = AL);
  void vmovd(DRegister dd, DRegister dm, Condition cond = AL);

  // Returns false if the immediate cannot be encoded.
  bool vmovs(SRegister sd, float s_imm, Condition cond = AL);
  bool vmovd(DRegister dd, double d_imm, Condition cond = AL);

  void vldrs(SRegister sd, Address ad, Condition cond = AL);
  void vstrs(SRegister sd, Address ad, Condition cond = AL);
  void vldrd(DRegister dd, Address ad, Condition cond = AL);
  void vstrd(DRegister dd, Address ad, Condition cond = AL);

  void vldms(BlockAddressMode am, Register base,
             SRegister first, SRegister last, Condition cond = AL);
  void vstms(BlockAddressMode am, Register base,
             SRegister first, SRegister last, Condition cond = AL);

  void vldmd(BlockAddressMode am, Register base,
             DRegister first, DRegister last, Condition cond = AL);
  void vstmd(BlockAddressMode am, Register base,
             DRegister first, DRegister last, Condition cond = AL);

  void vadds(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vaddd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vsubs(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vsubd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vmuls(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmuld(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vmlas(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmlad(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vmlss(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vmlsd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);
  void vdivs(SRegister sd, SRegister sn, SRegister sm, Condition cond = AL);
  void vdivd(DRegister dd, DRegister dn, DRegister dm, Condition cond = AL);

  void vabss(SRegister sd, SRegister sm, Condition cond = AL);
  void vabsd(DRegister dd, DRegister dm, Condition cond = AL);
  void vnegs(SRegister sd, SRegister sm, Condition cond = AL);
  void vnegd(DRegister dd, DRegister dm, Condition cond = AL);
  void vsqrts(SRegister sd, SRegister sm, Condition cond = AL);
  void vsqrtd(DRegister dd, DRegister dm, Condition cond = AL);

  void vcvtsd(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtds(DRegister dd, SRegister sm, Condition cond = AL);
  void vcvtis(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtid(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtsi(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtdi(DRegister dd, SRegister sm, Condition cond = AL);
  void vcvtus(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtud(SRegister sd, DRegister dm, Condition cond = AL);
  void vcvtsu(SRegister sd, SRegister sm, Condition cond = AL);
  void vcvtdu(DRegister dd, SRegister sm, Condition cond = AL);

  void vcmps(SRegister sd, SRegister sm, Condition cond = AL);
  void vcmpd(DRegister dd, DRegister dm, Condition cond = AL);
  void vcmpsz(SRegister sd, Condition cond = AL);
  void vcmpdz(DRegister dd, Condition cond = AL);
  void vmstat(Condition cond = AL);  // VMRS APSR_nzcv, FPSCR

  // Branch instructions.
  void b(Label* label, Condition cond = AL);
  void bl(Label* label, Condition cond = AL);
  void bx(Register rm, Condition cond = AL);
  void blx(Register rm, Condition cond = AL);

  // Move to ARM core register from Coprocessor.
  void mrc(Register rd, int32_t coproc, int32_t opc1,
           int32_t crn, int32_t crm, int32_t opc2, Condition cond = AL);

  // Macros.
  // Branch to an entry address. Call sequence is never patched.
  void Branch(const ExternalLabel* label, Condition cond = AL);

  // Branch to an entry address. Call sequence can be patched or even replaced.
  void BranchPatchable(const ExternalLabel* label);

  // Branch and link to an entry address. Call sequence is never patched.
  void BranchLink(const ExternalLabel* label);

  // Branch and link to an entry address. Call sequence can be patched.
  void BranchLinkPatchable(const ExternalLabel* label);

  // Branch and link to entry after storing return address at ad.
  // Call sequence is never patched.
  void BranchLinkStore(const ExternalLabel* label, Address ad);

  // Branch and link to [base + offset]. Call sequence is never patched.
  void BranchLinkOffset(Register base, int32_t offset);

  // Add signed immediate value to rd. May clobber IP.
  void AddImmediate(Register rd, int32_t value, Condition cond = AL);
  void AddImmediate(Register rd, Register rn, int32_t value,
                    Condition cond = AL);
  void AddImmediateSetFlags(Register rd, Register rn, int32_t value,
                            Condition cond = AL);
  void AddImmediateWithCarry(Register rd, Register rn, int32_t value,
                             Condition cond = AL);

  // Compare rn with signed immediate value. May clobber IP.
  void CompareImmediate(Register rn, int32_t value, Condition cond = AL);

  // Load and Store. May clobber IP.
  void LoadImmediate(Register rd, int32_t value, Condition cond = AL);
  void LoadSImmediate(SRegister sd, float value, Condition cond = AL);
  void LoadDImmediate(DRegister dd, double value,
                      Register scratch, Condition cond = AL);

  void MarkExceptionHandler(Label* label);

  void Drop(intptr_t stack_elements);

  void LoadObject(Register rd, const Object& object);
  void PushObject(const Object& object);
  void CompareObject(Register rn, const Object& object);

  void StoreIntoObject(Register object,  // Object we are storing into.
                       const Address& dest,  // Where we are storing into.
                       Register value,  // Value we are storing.
                       bool can_value_be_smi = true);

  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void LoadClass(Register result, Register object, Register scratch);
  void CompareClassId(Register object, intptr_t class_id, Register scratch);

  void LoadWordFromPoolOffset(Register rd, int32_t offset);
  void LoadFromOffset(LoadOperandType type,
                      Register reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);
  void StoreToOffset(StoreOperandType type,
                     Register reg,
                     Register base,
                     int32_t offset,
                     Condition cond = AL);
  void LoadSFromOffset(SRegister reg,
                       Register base,
                       int32_t offset,
                       Condition cond = AL);
  void StoreSToOffset(SRegister reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);
  void LoadDFromOffset(DRegister reg,
                       Register base,
                       int32_t offset,
                       Condition cond = AL);
  void StoreDToOffset(DRegister reg,
                      Register base,
                      int32_t offset,
                      Condition cond = AL);

  void Push(Register rd, Condition cond = AL);
  void Pop(Register rd, Condition cond = AL);

  void PushList(RegList regs, Condition cond = AL);
  void PopList(RegList regs, Condition cond = AL);

  void Mov(Register rd, Register rm, Condition cond = AL);

  // Convenience shift instructions. Use mov instruction with shifter operand
  // for variants setting the status flags or using a register shift count.
  void Lsl(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Lsr(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Asr(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Ror(Register rd, Register rm, uint32_t shift_imm, Condition cond = AL);
  void Rrx(Register rd, Register rm, Condition cond = AL);

  void SmiTag(Register reg, Condition cond = AL) {
    Lsl(reg, reg, kSmiTagSize, cond);
  }

  void SmiUntag(Register reg, Condition cond = AL) {
    Asr(reg, reg, kSmiTagSize, cond);
  }

  // Function frame setup and tear down.
  void EnterFrame(RegList regs, intptr_t frame_space);
  void LeaveFrame(RegList regs);
  void Ret();
  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Create a frame for calling into runtime that preserves all volatile
  // registers.  Frame's SP is guaranteed to be correctly aligned and
  // frame_space bytes are reserved under it.
  void EnterCallRuntimeFrame(intptr_t frame_space);
  void LeaveCallRuntimeFrame();

  void CallRuntime(const RuntimeEntry& entry);

  // Set up a Dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame();

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(bool uses_pp = false);
  void LeaveStubFrame(bool uses_pp = false);

  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kOffsetOfSavedPCfromEntrypoint = Instr::kPCReadOffset;

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   bool near_jump,
                   Register instance_reg);

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

 private:
  AssemblerBuffer buffer_;  // Contains position independent code.
  GrowableObjectArray& object_pool_;  // Objects and patchable jump targets.
  int32_t prologue_offset_;

  int32_t AddObject(const Object& obj);
  int32_t AddExternalLabel(const ExternalLabel* label);

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) { }

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  GrowableArray<CodeComment*> comments_;

  void EmitType01(Condition cond,
                  int type,
                  Opcode opcode,
                  int set_cc,
                  Register rn,
                  Register rd,
                  ShifterOperand so);

  void EmitType5(Condition cond, int32_t offset, bool link);

  void EmitMemOp(Condition cond,
                 bool load,
                 bool byte,
                 Register rd,
                 Address ad);

  void EmitMemOpAddressMode3(Condition cond,
                             int32_t mode,
                             Register rd,
                             Address ad);

  void EmitMultiMemOp(Condition cond,
                      BlockAddressMode am,
                      bool load,
                      Register base,
                      RegList regs);

  void EmitShiftImmediate(Condition cond,
                          Shift opcode,
                          Register rd,
                          Register rm,
                          ShifterOperand so);

  void EmitShiftRegister(Condition cond,
                         Shift opcode,
                         Register rd,
                         Register rm,
                         ShifterOperand so);

  void EmitMulOp(Condition cond,
                 int32_t opcode,
                 Register rd,
                 Register rn,
                 Register rm,
                 Register rs);

  void EmitDivOp(Condition cond,
                 int32_t opcode,
                 Register rd,
                 Register rn,
                 Register rm);

  void EmitMultiVSMemOp(Condition cond,
                        BlockAddressMode am,
                        bool load,
                        Register base,
                        SRegister start,
                        uint32_t count);

  void EmitMultiVDMemOp(Condition cond,
                        BlockAddressMode am,
                        bool load,
                        Register base,
                        DRegister start,
                        int32_t count);

  void EmitVFPsss(Condition cond,
                  int32_t opcode,
                  SRegister sd,
                  SRegister sn,
                  SRegister sm);

  void EmitVFPddd(Condition cond,
                  int32_t opcode,
                  DRegister dd,
                  DRegister dn,
                  DRegister dm);

  void EmitVFPsd(Condition cond,
                 int32_t opcode,
                 SRegister sd,
                 DRegister dm);

  void EmitVFPds(Condition cond,
                 int32_t opcode,
                 DRegister dd,
                 SRegister sm);

  void EmitBranch(Condition cond, Label* label, bool link);
  static int32_t EncodeBranchOffset(int32_t offset, int32_t inst);
  static int DecodeBranchOffset(int32_t inst);
  int32_t EncodeTstOffset(int32_t offset, int32_t inst);
  int DecodeTstOffset(int32_t inst);

  void StoreIntoObjectFilter(Register object, Register value, Label* no_update);

  // Shorter filtering sequence that assumes that value is not a smi.
  void StoreIntoObjectFilterNoSmi(Register object,
                                  Register value,
                                  Label* no_update);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM_H_
