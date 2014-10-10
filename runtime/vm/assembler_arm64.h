// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_ASSEMBLER_ARM64_H_
#define VM_ASSEMBLER_ARM64_H_

#ifndef VM_ASSEMBLER_H_
#error Do not include assembler_arm64.h directly; use assembler.h instead.
#endif

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/constants_arm64.h"
#include "vm/hash_map.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;

class Immediate : public ValueObject {
 public:
  explicit Immediate(int64_t value) : value_(value) { }

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) { }
  Immediate& operator=(const Immediate& other) {
    value_ = other.value_;
    return *this;
  }

 private:
  int64_t value_;

  int64_t value() const { return value_; }

  friend class Assembler;
};


class Label : public ValueObject {
 public:
  Label() : position_(0) { }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  intptr_t Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kWordSize : position_ - kWordSize;
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0; }
  bool IsLinked() const { return position_ > 0; }

 private:
  intptr_t position_;

  void Reinitialize() {
    position_ = 0;
  }

  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = -position - kWordSize;
    ASSERT(IsBound());
  }

  void LinkTo(intptr_t position) {
    ASSERT(!IsBound());
    position_ = position + kWordSize;
    ASSERT(IsLinked());
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};


class Address : public ValueObject {
 public:
  Address(const Address& other)
      : ValueObject(),
        encoding_(other.encoding_),
        type_(other.type_),
        base_(other.base_) {
  }

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    type_ = other.type_;
    base_ = other.base_;
    return *this;
  }

  enum AddressType {
    Offset,
    PreIndex,
    PostIndex,
    PairOffset,
    PairPreIndex,
    PairPostIndex,
    Reg,
    PCOffset,
    Unknown,
  };

  // Offset is in bytes. For the unsigned imm12 case, we unscale based on the
  // operand size, and assert that offset is aligned accordingly.
  // For the smaller signed imm9 case, the offset is the number of bytes, but
  // is unscaled.
  Address(Register rn, int32_t offset = 0, AddressType at = Offset,
          OperandSize sz = kDoubleWord) {
    ASSERT((rn != R31) && (rn != ZR));
    ASSERT(CanHoldOffset(offset, at, sz));
    const Register crn = ConcreteRegister(rn);
    const int32_t scale = Log2OperandSizeBytes(sz);
    if ((at == Offset) &&
         Utils::IsUint(12 + scale, offset) &&
        (offset == ((offset >> scale) << scale))) {
      encoding_ =
          B24 |
          ((offset >> scale) << kImm12Shift) |
          (static_cast<int32_t>(crn) << kRnShift);
    } else if ((at == Offset) &&
               Utils::IsInt(9, offset)) {
      encoding_ =
          ((offset & 0x1ff) << kImm9Shift) |
          (static_cast<int32_t>(crn) << kRnShift);
    } else if ((at == PreIndex) || (at == PostIndex)) {
      ASSERT(Utils::IsInt(9, offset));
      int32_t idx = (at == PostIndex) ? B10 : (B11 | B10);
      encoding_ =
          idx |
          ((offset & 0x1ff) << kImm9Shift) |
          (static_cast<int32_t>(crn) << kRnShift);
    } else {
      ASSERT((at == PairOffset) || (at == PairPreIndex) ||
             (at == PairPostIndex));
      ASSERT(Utils::IsInt(7 + scale, offset) &&
             (offset == ((offset >> scale) << scale)));
      int32_t idx = 0;
      switch (at) {
        case PairPostIndex: idx = B23; break;
        case PairPreIndex: idx = B24 | B23; break;
        case PairOffset: idx = B24; break;
        default: UNREACHABLE(); break;
      }
      encoding_ =
        idx |
        (((offset >> scale) << kImm7Shift) & kImm7Mask) |
        (static_cast<int32_t>(crn) << kRnShift);
    }
    type_ = at;
    base_ = crn;
  }

  // This addressing mode does not exist.
  Address(Register rn, Register offset, AddressType at,
          OperandSize sz = kDoubleWord);

  static bool CanHoldOffset(int32_t offset, AddressType at = Offset,
                            OperandSize sz = kDoubleWord) {
    if (at == Offset) {
      // Offset fits in 12 bit unsigned and has right alignment for sz,
      // or fits in 9 bit signed offset with no alignment restriction.
      const int32_t scale = Log2OperandSizeBytes(sz);
      return (Utils::IsUint(12 + scale, offset) &&
              (offset == ((offset >> scale) << scale))) ||
             (Utils::IsInt(9, offset));
    } else if (at == PCOffset) {
      return Utils::IsInt(21, offset) &&
             (offset == ((offset >> 2) << 2));
    } else if ((at == PreIndex) || (at == PostIndex)) {
      return Utils::IsInt(9, offset);
    } else {
      ASSERT((at == PairOffset) || (at == PairPreIndex) ||
             (at == PairPostIndex));
      const int32_t scale = Log2OperandSizeBytes(sz);
      return (Utils::IsInt(7 + scale, offset) &&
              (offset == ((offset >> scale) << scale)));
    }
  }

  // PC-relative load address.
  static Address PC(int32_t pc_off) {
    ASSERT(CanHoldOffset(pc_off, PCOffset));
    Address addr;
    addr.encoding_ = (((pc_off >> 2) << kImm19Shift) & kImm19Mask);
    addr.base_ = kNoRegister;
    addr.type_ = PCOffset;
    return addr;
  }

  static Address Pair(Register rn,
                      int32_t offset = 0,
                      AddressType at = PairOffset,
                      OperandSize sz = kDoubleWord) {
    return Address(rn, offset, at, sz);
  }

  // This addressing mode does not exist.
  static Address PC(Register r);

  enum Scaling {
    Unscaled,
    Scaled,
  };

  // Base register rn with offset rm. rm is sign-extended according to ext.
  // If ext is UXTX, rm may be optionally scaled by the
  // Log2OperandSize (specified by the instruction).
  Address(Register rn, Register rm,
          Extend ext = UXTX, Scaling scale = Unscaled) {
    ASSERT((rn != R31) && (rn != ZR));
    ASSERT((rm != R31) && (rm != CSP));
    // Can only scale when ext = UXTX.
    ASSERT((scale != Scaled) || (ext == UXTX));
    ASSERT((ext == UXTW) || (ext == UXTX) || (ext == SXTW) || (ext == SXTX));
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const int32_t s = (scale == Scaled) ? B12 : 0;
    encoding_ =
        B21 | B11 | s |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(ext) << kExtendTypeShift);
    type_ = Reg;
    base_ = crn;
  }

  static OperandSize OperandSizeFor(intptr_t cid) {
    switch (cid) {
      case kArrayCid:
      case kImmutableArrayCid:
        return kWord;
      case kOneByteStringCid:
        return kByte;
      case kTwoByteStringCid:
        return kHalfword;
      case kTypedDataInt8ArrayCid:
        return kByte;
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        return kUnsignedByte;
      case kTypedDataInt16ArrayCid:
        return kHalfword;
      case kTypedDataUint16ArrayCid:
        return kUnsignedHalfword;
      case kTypedDataInt32ArrayCid:
        return kWord;
      case kTypedDataUint32ArrayCid:
        return kUnsignedWord;
      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
        UNREACHABLE();
        return kByte;
      case kTypedDataFloat32ArrayCid:
        return kSWord;
      case kTypedDataFloat64ArrayCid:
        return kDWord;
      case kTypedDataFloat32x4ArrayCid:
      case kTypedDataInt32x4ArrayCid:
      case kTypedDataFloat64x2ArrayCid:
        return kQWord;
      case kTypedDataInt8ArrayViewCid:
        UNREACHABLE();
        return kByte;
      default:
        UNREACHABLE();
        return kByte;
    }
  }

 private:
  uint32_t encoding() const { return encoding_; }
  AddressType type() const { return type_; }
  Register base() const { return base_; }

  Address() : encoding_(0), type_(Unknown), base_(kNoRegister) {}

  uint32_t encoding_;
  AddressType type_;
  Register base_;

  friend class Assembler;
};


class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp, OperandSize sz = kDoubleWord)
      : Address(base, disp - kHeapObjectTag, Offset, sz) { }

  // This addressing mode does not exist.
  FieldAddress(Register base, Register disp, OperandSize sz = kDoubleWord);

  FieldAddress(const FieldAddress& other) : Address(other) { }

  FieldAddress& operator=(const FieldAddress& other) {
    Address::operator=(other);
    return *this;
  }
};


class Operand : public ValueObject {
 public:
  enum OperandType {
    Shifted,
    Extended,
    Immediate,
    BitfieldImm,
    Unknown,
  };

  // Data-processing operand - Uninitialized.
  Operand() : encoding_(-1), type_(Unknown) { }

  // Data-processing operands - Copy constructor.
  Operand(const Operand& other)
      : ValueObject(), encoding_(other.encoding_), type_(other.type_) { }

  Operand& operator=(const Operand& other) {
    type_ = other.type_;
    encoding_ = other.encoding_;
    return *this;
  }

  explicit Operand(Register rm) {
    ASSERT((rm != R31) && (rm != CSP));
    const Register crm = ConcreteRegister(rm);
    encoding_ = (static_cast<int32_t>(crm) << kRmShift);
    type_ = Shifted;
  }

  Operand(Register rm, Shift shift, int32_t imm) {
    ASSERT(Utils::IsUint(6, imm));
    ASSERT((rm != R31) && (rm != CSP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        (imm << kImm6Shift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(shift) << kShiftTypeShift);
    type_ = Shifted;
  }

  // This operand type does not exist.
  Operand(Register rm, Shift shift, Register r);

  Operand(Register rm, Extend extend, int32_t imm) {
    ASSERT(Utils::IsUint(3, imm));
    ASSERT((rm != R31) && (rm != CSP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        B21 |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(extend) << kExtendTypeShift) |
        ((imm & 0x7) << kImm3Shift);
    type_ = Extended;
  }

  // This operand type does not exist.
  Operand(Register rm, Extend extend, Register r);

  explicit Operand(int32_t imm) {
    if (Utils::IsUint(12, imm)) {
      encoding_ = imm << kImm12Shift;
    } else {
      // imm only has bits in [12, 24) set.
      ASSERT(((imm & 0xfff) == 0) && (Utils::IsUint(12, imm >> 12)));
      encoding_ = B22 | ((imm >> 12) << kImm12Shift);
    }
    type_ = Immediate;
  }

  // Encodes the value of an immediate for a logical operation.
  // Since these values are difficult to craft by hand, instead pass the
  // logical mask to the function IsImmLogical to get n, imm_s, and
  // imm_r.
  Operand(uint8_t n, int8_t imm_s, int8_t imm_r) {
    ASSERT((n == 1) || (n == 0));
    ASSERT(Utils::IsUint(6, imm_s) && Utils::IsUint(6, imm_r));
    type_ = BitfieldImm;
    encoding_ =
      (static_cast<int32_t>(n) << kNShift) |
      (static_cast<int32_t>(imm_s) << kImmSShift) |
      (static_cast<int32_t>(imm_r) << kImmRShift);
  }

  // Test if a given value can be encoded in the immediate field of a logical
  // instruction.
  // If it can be encoded, the function returns true, and values pointed to by
  // n, imm_s and imm_r are updated with immediates encoded in the format
  // required by the corresponding fields in the logical instruction.
  // If it can't be encoded, the function returns false, and the operand is
  // undefined.
  static bool IsImmLogical(uint64_t value, uint8_t width, Operand* imm_op);

  // An immediate imm can be an operand to add/sub when the return value is
  // Immediate, or a logical operation over sz bits when the return value is
  // BitfieldImm. If the return value is Unknown, then the immediate can't be
  // used as an operand in either instruction. The encoded operand is written
  // to op.
  static OperandType CanHold(int64_t imm, uint8_t sz, Operand* op) {
    ASSERT(op != NULL);
    ASSERT((sz == kXRegSizeInBits) || (sz == kWRegSizeInBits));
    if (Utils::IsUint(12, imm)) {
      op->encoding_ = imm << kImm12Shift;
      op->type_ = Immediate;
    } else if (((imm & 0xfff) == 0) && (Utils::IsUint(12, imm >> 12))) {
      op->encoding_ = B22 | ((imm >> 12) << kImm12Shift);
      op->type_ = Immediate;
    } else if (IsImmLogical(imm, sz, op)) {
      op->type_ = BitfieldImm;
    } else {
      op->encoding_ = 0;
      op->type_ = Unknown;
    }
    return op->type_;
  }

 private:
  uint32_t encoding() const {
    return encoding_;
  }
  OperandType type() const {
    return type_;
  }

  uint32_t encoding_;
  OperandType type_;

  friend class Assembler;
};


class Assembler : public ValueObject {
 public:
  explicit Assembler(bool use_far_branches = false);
  ~Assembler() { }

  void PopRegister(Register r) {
    Pop(r);
  }

  void Drop(intptr_t stack_elements) {
    add(SP, SP, Operand(stack_elements * kWordSize));
  }

  void Bind(Label* label);
  void Jump(Label* label) { b(label); }

  // Misc. functionality
  intptr_t CodeSize() const { return buffer_.Size(); }
  intptr_t prologue_offset() const { return prologue_offset_; }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.  On ARM64 there are no pointers in code.
  intptr_t CountPointerOffsets() const { return 0; }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    ASSERT(buffer_.pointer_offsets().length() == 0);  // No pointers in code.
    return buffer_.pointer_offsets();
  }
  const GrowableObjectArray& object_pool() const { return object_pool_; }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) {
    ASSERT(buffer_.Size() == 0);
    use_far_branches_ = b;
  }

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Debugging and bringup support.
  void Stop(const char* message);
  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);

  static void InitializeMemoryWithBreakpoints(uword data, intptr_t length);

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  static bool EmittingComments();

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kEntryPointToPcMarkerOffset = 0;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

  // Addition and subtraction.
  // For add and sub, to use CSP for rn, o must be of type Operand::Extend.
  // For an unmodified rm in this case, use Operand(rm, UXTX, 0);
  void add(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, false, rd, rn, o);
  }
  void adds(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, true, false, rd, rn, o);
  }
  void addw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, false, false, rd, rn, o);
  }
  void addsw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, true, false, rd, rn, o);
  }
  void sub(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, true, rd, rn, o);
  }
  void subs(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, true, true, rd, rn, o);
  }
  void subw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, false, true, rd, rn, o);
  }
  void subsw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, true, true, rd, rn, o);
  }

  // Addition and subtraction with carry.
  void adc(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kDoubleWord, false, false, rd, rn, rm);
  }
  void adcs(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kDoubleWord, true, false, rd, rn, rm);
  }
  void adcw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kWord, false, false, rd, rn, rm);
  }
  void adcsw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kWord, true, false, rd, rn, rm);
  }
  void sbc(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kDoubleWord, false, true, rd, rn, rm);
  }
  void sbcs(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kDoubleWord, true, true, rd, rn, rm);
  }
  void sbcw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kWord, false, true, rd, rn, rm);
  }
  void sbcsw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kWord, true, true, rd, rn, rm);
  }

  // PC relative immediate add. imm is in bytes.
  void adr(Register rd, const Immediate& imm) {
    EmitPCRelOp(ADR, rd, imm);
  }

  // Logical immediate operations.
  void andi(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDI, rd, rn, imm_op, kDoubleWord);
  }
  void orri(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ORRI, rd, rn, imm_op, kDoubleWord);
  }
  void eori(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(EORI, rd, rn, imm_op, kDoubleWord);
  }
  void andis(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDIS, rd, rn, imm_op, kDoubleWord);
  }

  // Logical (shifted) register operations.
  void and_(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(AND, rd, rn, o, kDoubleWord);
  }
  void andw_(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(AND, rd, rn, o, kWord);
  }
  void bic(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(BIC, rd, rn, o, kDoubleWord);
  }
  void orr(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORR, rd, rn, o, kDoubleWord);
  }
  void orn(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORN, rd, rn, o, kDoubleWord);
  }
  void eor(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EOR, rd, rn, o, kDoubleWord);
  }
  void eorw(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EOR, rd, rn, o, kWord);
  }
  void eon(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EON, rd, rn, o, kDoubleWord);
  }
  void ands(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ANDS, rd, rn, o, kDoubleWord);
  }
  void bics(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(BICS, rd, rn, o, kDoubleWord);
  }

  // Misc. arithmetic.
  void udiv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(UDIV, rd, rn, rm, kDoubleWord);
  }
  void sdiv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(SDIV, rd, rn, rm, kDoubleWord);
  }
  void lslv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSLV, rd, rn, rm, kDoubleWord);
  }
  void lsrv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSRV, rd, rn, rm, kDoubleWord);
  }
  void asrv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(ASRV, rd, rn, rm, kDoubleWord);
  }
  void madd(Register rd, Register rn, Register rm, Register ra) {
    EmitMiscDP3Source(MADD, rd, rn, rm, ra, kDoubleWord);
  }
  void msub(Register rd, Register rn, Register rm, Register ra) {
    EmitMiscDP3Source(MSUB, rd, rn, rm, ra, kDoubleWord);
  }
  void smulh(Register rd, Register rn, Register rm) {
    EmitMiscDP3Source(SMULH, rd, rn, rm, R0, kDoubleWord);
  }

  // Move wide immediate.
  void movk(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVK, crd, imm, hw_idx, kDoubleWord);
  }
  void movn(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVN, crd, imm, hw_idx, kDoubleWord);
  }
  void movz(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVZ, crd, imm, hw_idx, kDoubleWord);
  }

  // Loads and Stores.
  void ldr(Register rt, Address a, OperandSize sz = kDoubleWord) {
    ASSERT((a.type() != Address::PairOffset) &&
           (a.type() != Address::PairPostIndex) &&
           (a.type() != Address::PairPreIndex));
    if (a.type() == Address::PCOffset) {
      ASSERT(sz == kDoubleWord);
      EmitLoadRegLiteral(LDRpc, rt, a, sz);
    } else {
      // If we are doing pre-/post-indexing, and the base and result registers
      // are the same, then the result of the load will be clobbered by the
      // writeback, which is unlikely to be useful.
      ASSERT(((a.type() != Address::PreIndex) &&
              (a.type() != Address::PostIndex)) ||
             (rt != a.base()));
      if (IsSignedOperand(sz)) {
        EmitLoadStoreReg(LDRS, rt, a, sz);
      } else {
        EmitLoadStoreReg(LDR, rt, a, sz);
      }
    }
  }
  void str(Register rt, Address a, OperandSize sz = kDoubleWord) {
    ASSERT((a.type() != Address::PairOffset) &&
           (a.type() != Address::PairPostIndex) &&
           (a.type() != Address::PairPreIndex));
    EmitLoadStoreReg(STR, rt, a, sz);
  }

  void ldp(Register rt, Register rt2, Address a, OperandSize sz = kDoubleWord) {
    ASSERT((a.type() == Address::PairOffset) ||
           (a.type() == Address::PairPostIndex) ||
           (a.type() == Address::PairPreIndex));
    EmitLoadStoreRegPair(LDP, rt, rt2, a, sz);
  }
  void stp(Register rt, Register rt2, Address a, OperandSize sz = kDoubleWord) {
    ASSERT((a.type() == Address::PairOffset) ||
           (a.type() == Address::PairPostIndex) ||
           (a.type() == Address::PairPreIndex));
    EmitLoadStoreRegPair(STP, rt, rt2, a, sz);
  }

  // Conditional select.
  void csel(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSEL, rd, rn, rm, cond, kDoubleWord);
  }
  void csinc(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSINC, rd, rn, rm, cond, kDoubleWord);
  }
  void cinc(Register rd, Register rn, Condition cond) {
    csinc(rd, rn, rn, InvertCondition(cond));
  }
  void cset(Register rd, Condition cond) {
    csinc(rd, ZR, ZR, InvertCondition(cond));
  }
  void csinv(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSINV, rd, rn, rm, cond, kDoubleWord);
  }
  void cinv(Register rd, Register rn, Condition cond) {
    csinv(rd, rn, rn, InvertCondition(cond));
  }
  void csetm(Register rd, Condition cond) {
    csinv(rd, ZR, ZR, InvertCondition(cond));
  }

  // Comparison.
  // rn cmp o.
  // For add and sub, to use CSP for rn, o must be of type Operand::Extend.
  // For an unmodified rm in this case, use Operand(rm, UXTX, 0);
  void cmp(Register rn, Operand o) {
    subs(ZR, rn, o);
  }
  // rn cmp -o.
  void cmn(Register rn, Operand o) {
    adds(ZR, rn, o);
  }

  void CompareRegisters(Register rn, Register rm) {
    if (rn == CSP) {
      // UXTX 0 on a 64-bit register (rm) is a nop, but forces R31 to be
      // interpreted as CSP.
      cmp(CSP, Operand(rm, UXTX, 0));
    } else {
      cmp(rn, Operand(rm));
    }
  }

  // Conditional branch.
  void b(Label* label, Condition cond = AL) {
    EmitBranch(BCOND, cond, label);
  }

  void b(int32_t offset) {
    EmitUnconditionalBranchOp(B, offset);
  }
  void bl(int32_t offset) {
    EmitUnconditionalBranchOp(BL, offset);
  }

  // TODO(zra): cbz, cbnz.

  // Branch, link, return.
  void br(Register rn) {
    EmitUnconditionalBranchRegOp(BR, rn);
  }
  void blr(Register rn) {
    EmitUnconditionalBranchRegOp(BLR, rn);
  }
  void ret(Register rn = R30) {
    EmitUnconditionalBranchRegOp(RET, rn);
  }

  // Exceptions.
  void hlt(uint16_t imm) {
    EmitExceptionGenOp(HLT, imm);
  }
  void brk(uint16_t imm) {
    EmitExceptionGenOp(BRK, imm);
  }

  // Double floating point.
  bool fmovdi(VRegister vd, double immd) {
    int64_t imm64 = bit_cast<int64_t, double>(immd);
    const uint8_t bit7 = imm64 >> 63;
    const uint8_t bit6 = (~(imm64 >> 62)) & 0x1;
    const uint8_t bit54 = (imm64 >> 52) & 0x3;
    const uint8_t bit30 = (imm64 >> 48) & 0xf;
    const uint8_t imm8 = (bit7 << 7) | (bit6 << 6) | (bit54 << 4) | bit30;
    const int64_t expimm8 = Instr::VFPExpandImm(imm8);
    if (imm64 != expimm8) {
      return false;
    }
    EmitFPImm(FMOVDI, vd, imm8);
    return true;
  }
  void fmovdr(VRegister vd, Register rn) {
    ASSERT(rn != R31);
    ASSERT(rn != CSP);
    const Register crn = ConcreteRegister(rn);
    EmitFPIntCvtOp(FMOVDR, static_cast<Register>(vd), crn);
  }
  void fmovrd(Register rd, VRegister vn) {
    ASSERT(rd != R31);
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitFPIntCvtOp(FMOVRD, crd, static_cast<Register>(vn));
  }
  void scvtfdx(VRegister vd, Register rn) {
    ASSERT(rn != R31);
    ASSERT(rn != CSP);
    const Register crn = ConcreteRegister(rn);
    EmitFPIntCvtOp(SCVTFD, static_cast<Register>(vd), crn);
  }
  void scvtfdw(VRegister vd, Register rn) {
    ASSERT(rn != R31);
    ASSERT(rn != CSP);
    const Register crn = ConcreteRegister(rn);
    EmitFPIntCvtOp(SCVTFD, static_cast<Register>(vd), crn, kWord);
  }
  void fcvtzds(Register rd, VRegister vn) {
    ASSERT(rd != R31);
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitFPIntCvtOp(FCVTZDS, crd, static_cast<Register>(vn));
  }
  void fmovdd(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FMOVDD, vd, vn);
  }
  void fabsd(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FABSD, vd, vn);
  }
  void fnegd(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FNEGD, vd, vn);
  }
  void fsqrtd(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FSQRTD, vd, vn);
  }
  void fcvtsd(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FCVTSD, vd, vn);
  }
  void fcvtds(VRegister vd, VRegister vn) {
    EmitFPOneSourceOp(FCVTDS, vd, vn);
  }
  void fldrq(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FLDRQ, static_cast<Register>(vt), a, kByte);
  }
  void fstrq(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FSTRQ, static_cast<Register>(vt), a, kByte);
  }
  void fldrd(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FLDR, static_cast<Register>(vt), a, kDWord);
  }
  void fstrd(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FSTR, static_cast<Register>(vt), a, kDWord);
  }
  void fldrs(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FLDR, static_cast<Register>(vt), a, kSWord);
  }
  void fstrs(VRegister vt, Address a) {
    ASSERT(a.type() != Address::PCOffset);
    EmitLoadStoreReg(FSTR, static_cast<Register>(vt), a, kSWord);
  }
  void fcmpd(VRegister vn, VRegister vm) {
    EmitFPCompareOp(FCMPD, vn, vm);
  }
  void fcmpdz(VRegister vn) {
    EmitFPCompareOp(FCMPZD, vn, V0);
  }
  void fmuld(VRegister vd, VRegister vn, VRegister vm) {
    EmitFPTwoSourceOp(FMULD, vd, vn, vm);
  }
  void fdivd(VRegister vd, VRegister vn, VRegister vm) {
    EmitFPTwoSourceOp(FDIVD, vd, vn, vm);
  }
  void faddd(VRegister vd, VRegister vn, VRegister vm) {
    EmitFPTwoSourceOp(FADDD, vd, vn, vm);
  }
  void fsubd(VRegister vd, VRegister vn, VRegister vm) {
    EmitFPTwoSourceOp(FSUBD, vd, vn, vm);
  }

  // SIMD operations.
  void vand(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VAND, vd, vn, vm);
  }
  void vorr(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VORR, vd, vn, vm);
  }
  void veor(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VEOR, vd, vn, vm);
  }
  void vaddw(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VADDW, vd, vn, vm);
  }
  void vaddx(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VADDX, vd, vn, vm);
  }
  void vsubw(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VSUBW, vd, vn, vm);
  }
  void vsubx(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VSUBX, vd, vn, vm);
  }
  void vadds(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VADDS, vd, vn, vm);
  }
  void vaddd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VADDD, vd, vn, vm);
  }
  void vsubs(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VSUBS, vd, vn, vm);
  }
  void vsubd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VSUBD, vd, vn, vm);
  }
  void vmuls(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMULS, vd, vn, vm);
  }
  void vmuld(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMULD, vd, vn, vm);
  }
  void vdivs(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VDIVS, vd, vn, vm);
  }
  void vdivd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VDIVD, vd, vn, vm);
  }
  void vceqs(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCEQS, vd, vn, vm);
  }
  void vceqd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCEQD, vd, vn, vm);
  }
  void vcgts(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCGTS, vd, vn, vm);
  }
  void vcgtd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCGTD, vd, vn, vm);
  }
  void vcges(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCGES, vd, vn, vm);
  }
  void vcged(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VCGED, vd, vn, vm);
  }
  void vmins(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMINS, vd, vn, vm);
  }
  void vmind(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMIND, vd, vn, vm);
  }
  void vmaxs(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMAXS, vd, vn, vm);
  }
  void vmaxd(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VMAXD, vd, vn, vm);
  }
  void vrecpss(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VRECPSS, vd, vn, vm);
  }
  void vrsqrtss(VRegister vd, VRegister vn, VRegister vm) {
    EmitSIMDThreeSameOp(VRSQRTSS, vd, vn, vm);
  }
  void vnot(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VNOT, vd, vn);
  }
  void vabss(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VABSS, vd, vn);
  }
  void vabsd(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VABSD, vd, vn);
  }
  void vnegs(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VNEGS, vd, vn);
  }
  void vnegd(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VNEGD, vd, vn);
  }
  void vsqrts(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VSQRTS, vd, vn);
  }
  void vsqrtd(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VSQRTD, vd, vn);
  }
  void vrecpes(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VRECPES, vd, vn);
  }
  void vrsqrtes(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VRSQRTES, vd, vn);
  }
  void vdupw(VRegister vd, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VDUPI, vd, vn, kWord, 0, 0);
  }
  void vdupx(VRegister vd, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VDUPI, vd, vn, kDoubleWord, 0, 0);
  }
  void vdups(VRegister vd, VRegister vn, int32_t idx) {
    EmitSIMDCopyOp(VDUP, vd, vn, kSWord, 0, idx);
  }
  void vdupd(VRegister vd, VRegister vn, int32_t idx) {
    EmitSIMDCopyOp(VDUP, vd, vn, kDWord, 0, idx);
  }
  void vinsw(VRegister vd, int32_t didx, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VINSI, vd, vn, kWord, 0, didx);
  }
  void vinsx(VRegister vd, int32_t didx, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VINSI, vd, vn, kDoubleWord, 0, didx);
  }
  void vinss(VRegister vd, int32_t didx, VRegister vn, int32_t sidx) {
    EmitSIMDCopyOp(VINS, vd, vn, kSWord, sidx, didx);
  }
  void vinsd(VRegister vd, int32_t didx, VRegister vn, int32_t sidx) {
    EmitSIMDCopyOp(VINS, vd, vn, kDWord, sidx, didx);
  }
  void vmovrs(Register rd, VRegister vn, int32_t sidx) {
    const VRegister vd = static_cast<VRegister>(rd);
    EmitSIMDCopyOp(VMOVW, vd, vn, kWord, 0, sidx);
  }
  void vmovrd(Register rd, VRegister vn, int32_t sidx) {
    const VRegister vd = static_cast<VRegister>(rd);
    EmitSIMDCopyOp(VMOVX, vd, vn, kDoubleWord, 0, sidx);
  }

  // Aliases.
  void mov(Register rd, Register rn) {
    if ((rd == CSP) || (rn == CSP)) {
      add(rd, rn, Operand(0));
    } else {
      orr(rd, ZR, Operand(rn));
    }
  }
  void vmov(VRegister vd, VRegister vn) {
    vorr(vd, vn, vn);
  }
  void mvn(Register rd, Register rm) {
    orn(rd, ZR, Operand(rm));
  }
  void neg(Register rd, Register rm) {
    sub(rd, ZR, Operand(rm));
  }
  void negs(Register rd, Register rm) {
    subs(rd, ZR, Operand(rm));
  }
  void mul(Register rd, Register rn, Register rm) {
    madd(rd, rn, rm, ZR);
  }
  void Push(Register reg) {
    ASSERT(reg != PP);  // Only push PP with TagAndPushPP().
    str(reg, Address(SP, -1 * kWordSize, Address::PreIndex));
  }
  void Pop(Register reg) {
    ASSERT(reg != PP);  // Only pop PP with PopAndUntagPP().
    ldr(reg, Address(SP, 1 * kWordSize, Address::PostIndex));
  }
  void PushPair(Register first, Register second) {
    ASSERT((first != PP) && (second != PP));
    stp(second, first, Address(SP, -2 * kWordSize, Address::PairPreIndex));
  }
  void PopPair(Register first, Register second) {
    ASSERT((first != PP) && (second != PP));
    ldp(second, first, Address(SP, 2 * kWordSize, Address::PairPostIndex));
  }
  void PushFloat(VRegister reg) {
    fstrs(reg, Address(SP, -1 * kFloatSize, Address::PreIndex));
  }
  void PushDouble(VRegister reg) {
    fstrd(reg, Address(SP, -1 * kDoubleSize, Address::PreIndex));
  }
  void PushQuad(VRegister reg) {
    fstrq(reg, Address(SP, -1 * kQuadSize, Address::PreIndex));
  }
  void PopFloat(VRegister reg) {
    fldrs(reg, Address(SP, 1 * kFloatSize, Address::PostIndex));
  }
  void PopDouble(VRegister reg) {
    fldrd(reg, Address(SP, 1 * kDoubleSize, Address::PostIndex));
  }
  void PopQuad(VRegister reg) {
    fldrq(reg, Address(SP, 1 * kQuadSize, Address::PostIndex));
  }
  void TagAndPushPP() {
    // Add the heap object tag back to PP before putting it on the stack.
    add(TMP, PP, Operand(kHeapObjectTag));
    str(TMP, Address(SP, -1 * kWordSize, Address::PreIndex));
  }
  void TagAndPushPPAndPcMarker(Register pc_marker_reg) {
    ASSERT(pc_marker_reg != TMP2);
    // Add the heap object tag back to PP before putting it on the stack.
    add(TMP2, PP, Operand(kHeapObjectTag));
    stp(TMP2, pc_marker_reg,
        Address(SP, -2 * kWordSize, Address::PairPreIndex));
  }
  void PopAndUntagPP() {
    ldr(PP, Address(SP, 1 * kWordSize, Address::PostIndex));
    sub(PP, PP, Operand(kHeapObjectTag));
  }
  void tst(Register rn, Operand o) {
    ands(ZR, rn, o);
  }
  void tsti(Register rn, const Immediate& imm) {
    andis(ZR, rn, imm);
  }

  void LslImmediate(Register rd, Register rn, int shift) {
    add(rd, ZR, Operand(rn, LSL, shift));
  }
  void LsrImmediate(Register rd, Register rn, int shift) {
    add(rd, ZR, Operand(rn, LSR, shift));
  }
  void AsrImmediate(Register rd, Register rn, int shift) {
    add(rd, ZR, Operand(rn, ASR, shift));
  }

  void VRecps(VRegister vd, VRegister vn);
  void VRSqrts(VRegister vd, VRegister vn);

  void SmiUntag(Register reg) {
    AsrImmediate(reg, reg, kSmiTagSize);
  }
  void SmiUntag(Register dst, Register src) {
    AsrImmediate(dst, src, kSmiTagSize);
  }
  void SmiTag(Register reg) {
    LslImmediate(reg, reg, kSmiTagSize);
  }
  void SmiTag(Register dst, Register src) {
    LslImmediate(dst, src, kSmiTagSize);
  }

  // Branching to ExternalLabels.
  void Branch(const ExternalLabel* label, Register pp) {
    LoadExternalLabel(TMP, label, kNotPatchable, pp);
    br(TMP);
  }

  // Fixed length branch to label.
  void BranchPatchable(const ExternalLabel* label) {
    // TODO(zra): Use LoadExternalLabelFixed if possible.
    LoadImmediateFixed(TMP, label->address());
    br(TMP);
  }

  void BranchLink(const ExternalLabel* label, Register pp) {
    LoadExternalLabel(TMP, label, kNotPatchable, pp);
    blr(TMP);
  }

  // BranchLinkPatchable must be a fixed-length sequence so we can patch it
  // with the debugger.
  void BranchLinkPatchable(const ExternalLabel* label) {
    LoadExternalLabelFixed(TMP, label, kPatchable, PP);
    blr(TMP);
  }

  // Macros accepting a pp Register argument may attempt to load values from
  // the object pool when possible. Unless you are sure that the untagged object
  // pool pointer is in another register, or that it is not available at all,
  // PP should be passed for pp.
  void AddImmediate(Register dest, Register rn, int64_t imm, Register pp);
  void AddImmediateSetFlags(
      Register dest, Register rn, int64_t imm, Register pp);
  void SubImmediateSetFlags(
      Register dest, Register rn, int64_t imm, Register pp);
  void AndImmediate(Register rd, Register rn, int64_t imm, Register pp);
  void OrImmediate(Register rd, Register rn, int64_t imm, Register pp);
  void XorImmediate(Register rd, Register rn, int64_t imm, Register pp);
  void TestImmediate(Register rn, int64_t imm, Register pp);
  void CompareImmediate(Register rn, int64_t imm, Register pp);

  void LoadFromOffset(Register dest, Register base, int32_t offset,
                      Register pp, OperandSize sz = kDoubleWord);
  void LoadFieldFromOffset(Register dest, Register base, int32_t offset,
                           Register pp, OperandSize sz = kDoubleWord) {
    LoadFromOffset(dest, base, offset - kHeapObjectTag, pp, sz);
  }
  void LoadDFromOffset(
      VRegister dest, Register base, int32_t offset, Register pp);
  void LoadDFieldFromOffset(
      VRegister dest, Register base, int32_t offset, Register pp) {
    LoadDFromOffset(dest, base, offset - kHeapObjectTag, pp);
  }
  void LoadQFromOffset(
      VRegister dest, Register base, int32_t offset, Register pp);
  void LoadQFieldFromOffset(
      VRegister dest, Register base, int32_t offset, Register pp) {
    LoadQFromOffset(dest, base, offset - kHeapObjectTag, pp);
  }

  void StoreToOffset(Register src, Register base, int32_t offset,
                     Register pp, OperandSize sz = kDoubleWord);
  void StoreFieldToOffset(Register src, Register base, int32_t offset,
                          Register pp, OperandSize sz = kDoubleWord) {
    StoreToOffset(src, base, offset - kHeapObjectTag, pp, sz);
  }
  void StoreDToOffset(
      VRegister src, Register base, int32_t offset, Register pp);
  void StoreDFieldToOffset(
      VRegister src, Register base, int32_t offset, Register pp) {
    StoreDToOffset(src, base, offset - kHeapObjectTag, pp);
  }
  void StoreQToOffset(
      VRegister src, Register base, int32_t offset, Register pp);
  void StoreQFieldToOffset(
      VRegister src, Register base, int32_t offset, Register pp) {
    StoreQToOffset(src, base, offset - kHeapObjectTag, pp);
  }

  // Storing into an object.
  void StoreIntoObject(Register object,
                       const Address& dest,
                       Register value,
                       bool can_value_be_smi = true);
  void StoreIntoObjectOffset(Register object,
                             int32_t offset,
                             Register value,
                             Register pp,
                             bool can_value_be_smi = true);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectOffsetNoBarrier(Register object,
                                      int32_t offset,
                                      Register value,
                                      Register pp);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);
  void StoreIntoObjectOffsetNoBarrier(Register object,
                                      int32_t offset,
                                      const Object& value,
                                      Register pp);

  // Object pool, loading from pool, etc.
  void LoadPoolPointer(Register pp);

  // Index of constant pool entries pointing to debugger stubs.
  static const int kICCallBreakpointCPIndex = 5;
  static const int kClosureCallBreakpointCPIndex = 6;
  static const int kRuntimeCallBreakpointCPIndex = 7;

  enum Patchability {
    kPatchable,
    kNotPatchable,
  };

  bool allow_constant_pool() const {
    return allow_constant_pool_;
  }
  void set_allow_constant_pool(bool b) {
    allow_constant_pool_ = b;
  }

  void LoadWordFromPoolOffset(Register dst, Register pp, uint32_t offset);
  void LoadWordFromPoolOffsetFixed(Register dst, Register pp, uint32_t offset);
  intptr_t FindExternalLabel(const ExternalLabel* label,
                             Patchability patchable);
  intptr_t FindObject(const Object& obj, Patchability patchable);
  intptr_t FindImmediate(int64_t imm);
  bool CanLoadObjectFromPool(const Object& object);
  bool CanLoadImmediateFromPool(int64_t imm, Register pp);
  void LoadExternalLabel(Register dst, const ExternalLabel* label,
                         Patchability patchable, Register pp);
  void LoadExternalLabelFixed(Register dst,
                              const ExternalLabel* label,
                              Patchability patchable,
                              Register pp);
  void LoadIsolate(Register dst, Register pp);
  void LoadObject(Register dst, const Object& obj, Register pp);
  void LoadDecodableImmediate(Register reg, int64_t imm, Register pp);
  void LoadImmediateFixed(Register reg, int64_t imm);
  void LoadImmediate(Register reg, int64_t imm, Register pp);
  void LoadDImmediate(VRegister reg, double immd, Register pp);

  void PushObject(const Object& object, Register pp) {
    LoadObject(TMP, object, pp);
    Push(TMP);
  }
  void CompareObject(Register reg, const Object& object, Register pp);

  void LoadClassId(Register result, Register object, Register pp);
  void LoadClassById(Register result, Register class_id, Register pp);
  void LoadClass(Register result, Register object, Register pp);
  void CompareClassId(Register object, intptr_t class_id, Register pp);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  void EnterFrame(intptr_t frame_size);
  void LeaveFrame();

  // When entering Dart code from C++, we copy the system stack pointer (CSP)
  // to the Dart stack pointer (SP), and reserve a little space for the stack
  // to grow.
  void SetupDartSP(intptr_t reserved_space) {
    ASSERT(Utils::IsAligned(reserved_space, 16));
    mov(SP, CSP);
    sub(CSP, CSP, Operand(reserved_space));
  }

  void EnterDartFrame(intptr_t frame_size);
  void EnterDartFrameWithInfo(intptr_t frame_size, Register new_pp);
  void EnterOsrFrame(intptr_t extra_size, Register new_pp);
  void LeaveDartFrame();

  void EnterCallRuntimeFrame(intptr_t frame_size);
  void LeaveCallRuntimeFrame();
  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame(bool load_pp = false);
  void LeaveStubFrame();

  void UpdateAllocationStats(intptr_t cid,
                             Register pp,
                             Heap::Space space);

  void UpdateAllocationStatsWithSize(intptr_t cid,
                                     Register size_reg,
                                     Register pp,
                                     Heap::Space space);

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   Register instance_reg,
                   Register temp_reg,
                   Register pp);

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2);

  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const;
  Address ElementAddressForRegIndex(bool is_load,
                                    bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    Register index);

 private:
  AssemblerBuffer buffer_;  // Contains position independent code.

  // Objects and patchable jump targets.
  GrowableObjectArray& object_pool_;

  // Patchability of pool entries.
  GrowableArray<Patchability> patchable_pool_entries_;

  // Pair type parameter for DirectChainedHashMap.
  class ObjIndexPair {
   public:
    // TODO(zra): A WeakTable should be used here instead, but then it would
    // also have to be possible to register and de-register WeakTables with the
    // heap. Also, the Assembler would need to become a StackResource.
    // Issue 13305. In the meantime...
    // CAUTION: the RawObject* below is only safe because:
    // The HashMap that will use this pair type will not contain any RawObject*
    // keys that are not in the object_pool_ array. Since the keys will be
    // visited by the GC when it visits the object_pool_, and since all objects
    // in the object_pool_ are Old (and so will not be moved) the GC does not
    // also need to visit the keys here in the HashMap.

    // Typedefs needed for the DirectChainedHashMap template.
    typedef RawObject* Key;
    typedef intptr_t Value;
    typedef ObjIndexPair Pair;

    ObjIndexPair(Key key, Value value) : key_(key), value_(value) { }

    static Key KeyOf(Pair kv) { return kv.key_; }

    static Value ValueOf(Pair kv) { return kv.value_; }

    static intptr_t Hashcode(Key key) {
      return reinterpret_cast<intptr_t>(key) >> kObjectAlignmentLog2;
    }

    static inline bool IsKeyEqual(Pair kv, Key key) {
      return kv.key_ == key;
    }

   private:
    Key key_;
    Value value_;
  };

  // Hashmap for fast lookup in object pool.
  DirectChainedHashMap<ObjIndexPair> object_pool_index_table_;

  int32_t prologue_offset_;

  bool use_far_branches_;

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

  bool allow_constant_pool_;

  void AddSubHelper(OperandSize os, bool set_flags, bool subtract,
                    Register rd, Register rn, Operand o) {
    ASSERT((rd != R31) && (rn != R31));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    if (o.type() == Operand::Immediate) {
      ASSERT(rn != ZR);
      EmitAddSubImmOp(subtract ? SUBI : ADDI, crd, crn, o, os, set_flags);
    } else if (o.type() == Operand::Shifted) {
      ASSERT((rd != CSP) && (rn != CSP));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    } else {
      ASSERT(o.type() == Operand::Extended);
      ASSERT((rd != CSP) && (rn != ZR));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    }
  }

  void AddSubWithCarryHelper(OperandSize sz, bool set_flags, bool subtract,
                             Register rd, Register rn, Register rm) {
    ASSERT((rd != R31) && (rn != R31) && (rm != R31));
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t op = subtract ? SBC : ADC;
    const int32_t encoding =
        op | size | s |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift);
    Emit(encoding);
  }

  void EmitAddSubImmOp(AddSubImmOp op, Register rd, Register rn,
                       Operand o, OperandSize sz, bool set_flags) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding =
        op | size | s |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(rn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  void EmitLogicalImmOp(LogicalImmOp op, Register rd, Register rn,
                        Operand o, OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT(rn != CSP);
    ASSERT((op == ANDIS) || (rd != ZR));  // op != ANDIS => rd != ZR.
    ASSERT((op != ANDIS) || (rd != CSP));  // op == ANDIS => rd != CSP.
    ASSERT(o.type() == Operand::BitfieldImm);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  void EmitLogicalShiftOp(LogicalShiftOp op,
                          Register rd, Register rn, Operand o, OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT((rd != CSP) && (rn != CSP));
    ASSERT(o.type() == Operand::Shifted);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  void EmitAddSubShiftExtOp(AddSubShiftExtOp op,
                            Register rd, Register rn, Operand o,
                            OperandSize sz, bool set_flags) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding =
        op | size | s |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(rn) << kRnShift) |
        o.encoding();
    Emit(encoding);
  }

  int32_t EncodeImm19BranchOffset(int64_t imm, int32_t instr) {
    if (!CanEncodeImm19BranchOffset(imm)) {
      ASSERT(!use_far_branches());
      Isolate::Current()->long_jump_base()->Jump(
          1, Object::branch_offset_error());
    }
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off = (((imm32 >> 2) << kImm19Shift) & kImm19Mask);
    return (instr & ~kImm19Mask) | off;
  }

  int64_t DecodeImm19BranchOffset(int32_t instr) {
    const int32_t off = (((instr & kImm19Mask) >> kImm19Shift) << 13) >> 11;
    return static_cast<int64_t>(off);
  }

  Condition DecodeImm19BranchCondition(int32_t instr) {
    return static_cast<Condition>((instr & kCondMask) >> kCondShift);
  }

  int32_t EncodeImm19BranchCondition(Condition cond, int32_t instr) {
    const int32_t c_imm = static_cast<int32_t>(cond);
    return (instr & ~kCondMask) | (c_imm << kCondShift);
  }

  int32_t EncodeImm26BranchOffset(int64_t imm, int32_t instr) {
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off = (((imm32 >> 2) << kImm26Shift) & kImm26Mask);
    return (instr & ~kImm26Mask) | off;
  }

  int64_t DecodeImm26BranchOffset(int32_t instr) {
    const int32_t off = (((instr & kImm26Mask) >> kImm26Shift) << 6) >> 4;
    return static_cast<int64_t>(off);
  }

  void EmitCompareAndBranch(CompareAndBranchOp op, Register rt, int64_t imm,
                            OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    ASSERT(Utils::IsInt(21, imm) && ((imm & 0x3) == 0));
    ASSERT((rt != CSP) && (rt != R31));
    const Register crt = ConcreteRegister(rt);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoded_offset = EncodeImm19BranchOffset(imm, 0);
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crt) << kRtShift) |
        encoded_offset;
    Emit(encoding);
  }

  void EmitConditionalBranch(ConditionalBranchOp op, Condition cond,
                             int64_t imm) {
    const int32_t off = EncodeImm19BranchOffset(imm, 0);
    const int32_t encoding =
        op |
        (static_cast<int32_t>(cond) << kCondShift) |
        off;
    Emit(encoding);
  }

  bool CanEncodeImm19BranchOffset(int64_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    return Utils::IsInt(21, offset);
  }

  void EmitBranch(ConditionalBranchOp op, Condition cond, Label* label) {
    if (label->IsBound()) {
      const int64_t dest = label->Position() - buffer_.Size();
      if (use_far_branches() && !CanEncodeImm19BranchOffset(dest)) {
        if (cond == AL) {
          // If the condition is AL, we must always branch to dest. There is
          // no need for a guard branch.
          b(dest);
        } else {
          EmitConditionalBranch(
              op, InvertCondition(cond), 2 * Instr::kInstrSize);
          b(dest);
        }
      } else {
        EmitConditionalBranch(op, cond, dest);
      }
    } else {
      const int64_t position = buffer_.Size();
      if (use_far_branches()) {
        // When cond is AL, this guard branch will be rewritten as a nop when
        // the label is bound. We don't write it as a nop initially because it
        // makes the decoding code in Bind simpler.
        EmitConditionalBranch(op, InvertCondition(cond), 2 * Instr::kInstrSize);
        b(label->position_);
      } else {
        EmitConditionalBranch(op, cond, label->position_);
      }
      label->LinkTo(position);
    }
  }

  bool CanEncodeImm26BranchOffset(int64_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    return Utils::IsInt(26, offset);
  }

  void EmitUnconditionalBranchOp(UnconditionalBranchOp op, int64_t offset) {
    ASSERT(CanEncodeImm26BranchOffset(offset));
    const int32_t off = ((offset >> 2) << kImm26Shift) & kImm26Mask;
    const int32_t encoding = op | off;
    Emit(encoding);
  }

  void EmitUnconditionalBranchRegOp(UnconditionalBranchRegOp op, Register rn) {
    ASSERT((rn != CSP) && (rn != R31));
    const Register crn = ConcreteRegister(rn);
    const int32_t encoding =
        op | (static_cast<int32_t>(crn) << kRnShift);
    Emit(encoding);
  }

  void EmitExceptionGenOp(ExceptionGenOp op, uint16_t imm) {
    const int32_t encoding =
        op | (static_cast<int32_t>(imm) << kImm16Shift);
    Emit(encoding);
  }

  void EmitMoveWideOp(MoveWideOp op, Register rd, const Immediate& imm,
                      int hw_idx, OperandSize sz) {
    ASSERT((hw_idx >= 0) && (hw_idx <= 3));
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(hw_idx) << kHWShift) |
        (static_cast<int32_t>(imm.value() & 0xffff) << kImm16Shift);
    Emit(encoding);
  }

  void EmitLoadStoreReg(LoadStoreRegOp op, Register rt, Address a,
                        OperandSize sz) {
    const Register crt = ConcreteRegister(rt);
    const int32_t size = Log2OperandSizeBytes(sz);
    const int32_t encoding =
        op | ((size & 0x3) << kSzShift) |
        (static_cast<int32_t>(crt) << kRtShift) |
        a.encoding();
    Emit(encoding);
  }

  void EmitLoadRegLiteral(LoadRegLiteralOp op, Register rt, Address a,
                          OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    ASSERT((rt != CSP) && (rt != R31));
    const Register crt = ConcreteRegister(rt);
    const int32_t size = (sz == kDoubleWord) ? B30 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crt) << kRtShift) |
        a.encoding();
    Emit(encoding);
  }

  void EmitLoadStoreRegPair(LoadStoreRegPairOp op,
                            Register rt, Register rt2, Address a,
                            OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    ASSERT((rt != CSP) && (rt != R31));
    ASSERT((rt2 != CSP) && (rt2 != R31));
    const Register crt = ConcreteRegister(rt);
    const Register crt2 = ConcreteRegister(rt2);
    int32_t opc = 0;
    switch (sz) {
      case kDoubleWord: opc = B31; break;
      case kWord: opc = B30; break;
      case kUnsignedWord: opc = 0; break;
      default: UNREACHABLE(); break;
    }
    const int32_t encoding =
      opc | op |
      (static_cast<int32_t>(crt) << kRtShift) |
      (static_cast<int32_t>(crt2) << kRt2Shift) |
      a.encoding();
    Emit(encoding);
  }

  void EmitPCRelOp(PCRelOp op, Register rd, const Immediate& imm) {
    ASSERT(Utils::IsInt(21, imm.value()));
    ASSERT((rd != R31) && (rd != CSP));
    const Register crd = ConcreteRegister(rd);
    const int32_t loimm = (imm.value() & 0x3) << 29;
    const int32_t hiimm = ((imm.value() >> 2) << kImm19Shift) & kImm19Mask;
    const int32_t encoding =
        op | loimm | hiimm |
        (static_cast<int32_t>(crd) << kRdShift);
    Emit(encoding);
  }

  void EmitMiscDP2Source(MiscDP2SourceOp op,
                         Register rd, Register rn, Register rm,
                         OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift);
    Emit(encoding);
  }

  void EmitMiscDP3Source(MiscDP3SourceOp op,
                         Register rd, Register rn, Register rm, Register ra,
                         OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP) && (ra != CSP));
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const Register cra = ConcreteRegister(ra);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(cra) << kRaShift);
    Emit(encoding);
  }

  void EmitConditionalSelect(ConditionalSelectOp op,
                             Register rd, Register rn, Register rm,
                             Condition cond, OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    ASSERT((sz == kDoubleWord) || (sz == kWord) || (sz == kUnsignedWord));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crd) << kRdShift) |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(cond) << kSelCondShift);
    Emit(encoding);
  }

  void EmitFPImm(FPImmOp op, VRegister vd, uint8_t imm8) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vd) << kVdShift) |
        (imm8 << kImm8Shift);
    Emit(encoding);
  }

  void EmitFPIntCvtOp(FPIntCvtOp op, Register rd, Register rn,
                      OperandSize sz = kDoubleWord) {
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    const int32_t sfield = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(rn) << kRnShift) |
        sfield;
    Emit(encoding);
  }

  void EmitFPOneSourceOp(FPOneSourceOp op, VRegister vd, VRegister vn) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vd) << kVdShift) |
        (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  void EmitFPTwoSourceOp(FPTwoSourceOp op,
                         VRegister vd, VRegister vn, VRegister vm) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vd) << kVdShift) |
        (static_cast<int32_t>(vn) << kVnShift) |
        (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitFPCompareOp(FPCompareOp op, VRegister vn, VRegister vm) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vn) << kVnShift) |
        (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitSIMDThreeSameOp(SIMDThreeSameOp op,
                           VRegister vd, VRegister vn, VRegister vm) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vd) << kVdShift) |
        (static_cast<int32_t>(vn) << kVnShift) |
        (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitSIMDCopyOp(SIMDCopyOp op, VRegister vd, VRegister vn, OperandSize sz,
                      int32_t idx4, int32_t idx5) {
    const int32_t shift = Log2OperandSizeBytes(sz);
    const int32_t imm5 = ((idx5 << (shift + 1)) | (1 << shift)) & 0x1f;
    const int32_t imm4 = (idx4 << shift) & 0xf;
    const int32_t encoding =
        op |
        (imm5 << kImm5Shift) |
        (imm4 << kImm4Shift) |
        (static_cast<int32_t>(vd) << kVdShift) |
        (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  void EmitSIMDTwoRegOp(SIMDTwoRegOp op, VRegister vd, VRegister vn) {
    const int32_t encoding =
        op |
        (static_cast<int32_t>(vd) << kVdShift) |
        (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  void StoreIntoObjectFilter(Register object, Register value, Label* no_update);

  // Shorter filtering sequence that assumes that value is not a smi.
  void StoreIntoObjectFilterNoSmi(Register object,
                                  Register value,
                                  Label* no_update);

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM64_H_
