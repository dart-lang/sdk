// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM64_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM64_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_H_
#error Do not include assembler_arm64.h directly; use assembler.h instead.
#endif

#include <functional>

#include "platform/assert.h"
#include "platform/utils.h"
#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler_base.h"
#include "vm/constants.h"
#include "vm/hash_map.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class FlowGraphCompiler;
class RuntimeEntry;
class RegisterSet;

namespace compiler {

static inline int Log2OperandSizeBytes(OperandSize os) {
  switch (os) {
    case kByte:
    case kUnsignedByte:
      return 0;
    case kTwoBytes:
    case kUnsignedTwoBytes:
      return 1;
    case kFourBytes:
    case kUnsignedFourBytes:
    case kSWord:
      return 2;
    case kEightBytes:
    case kDWord:
      return 3;
    case kQWord:
      return 4;
    default:
      UNREACHABLE();
      break;
  }
  return -1;
}

static inline bool IsSignedOperand(OperandSize os) {
  switch (os) {
    case kByte:
    case kTwoBytes:
    case kFourBytes:
      return true;
    case kUnsignedByte:
    case kUnsignedTwoBytes:
    case kUnsignedFourBytes:
    case kEightBytes:
    case kSWord:
    case kDWord:
    case kQWord:
      return false;
    default:
      UNREACHABLE();
      break;
  }
  return false;
}
class Immediate : public ValueObject {
 public:
  explicit Immediate(int64_t value) : value_(value) {}

  Immediate(const Immediate& other) : ValueObject(), value_(other.value_) {}
  Immediate& operator=(const Immediate& other) {
    value_ = other.value_;
    return *this;
  }

 private:
  int64_t value_;

  int64_t value() const { return value_; }

  friend class Assembler;
};

class Arm64Encode : public AllStatic {
 public:
  static inline uint32_t Rd(Register rd) {
    ASSERT(rd <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rd)) << kRdShift;
  }

  static inline uint32_t Rm(Register rm) {
    ASSERT(rm <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rm)) << kRmShift;
  }

  static inline uint32_t Rn(Register rn) {
    ASSERT(rn <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rn)) << kRnShift;
  }

  static inline uint32_t Ra(Register ra) {
    ASSERT(ra <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(ra)) << kRaShift;
  }

  static inline uint32_t Rs(Register rs) {
    ASSERT(rs <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rs)) << kRsShift;
  }

  static inline uint32_t Rt(Register rt) {
    ASSERT(rt <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rt)) << kRtShift;
  }

  static inline uint32_t Rt2(Register rt2) {
    ASSERT(rt2 <= ZR);
    return static_cast<uint32_t>(ConcreteRegister(rt2)) << kRt2Shift;
  }
};

class Address : public ValueObject {
 public:
  Address(const Address& other)
      : ValueObject(),
        encoding_(other.encoding_),
        type_(other.type_),
        base_(other.base_),
        log2sz_(other.log2sz_) {}

  Address& operator=(const Address& other) {
    encoding_ = other.encoding_;
    type_ = other.type_;
    base_ = other.base_;
    log2sz_ = other.log2sz_;
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

  // If we are doing pre-/post-indexing, and the base and result registers are
  // the same, then the result is unpredictable. This kind of instruction is
  // actually illegal on some microarchitectures.
  bool can_writeback_to(Register r) const {
    if (type() == PreIndex || type() == PostIndex || type() == PairPreIndex ||
        type() == PairPostIndex) {
      return base() != r;
    }
    return true;
  }

  // Offset is in bytes. For the unsigned imm12 case, we unscale based on the
  // operand size, and assert that offset is aligned accordingly.
  // For the smaller signed imm9 case, the offset is the number of bytes, but
  // is unscaled.
  Address(Register rn,
          int32_t offset = 0,
          AddressType at = Offset,
          OperandSize sz = kEightBytes) {
    ASSERT((rn != kNoRegister) && (rn != R31) && (rn != ZR));
    ASSERT(CanHoldOffset(offset, at, sz));
    log2sz_ = -1;
    const int32_t scale = Log2OperandSizeBytes(sz);
    if ((at == Offset) && Utils::IsUint(12 + scale, offset) &&
        (offset == ((offset >> scale) << scale))) {
      encoding_ =
          B24 | ((offset >> scale) << kImm12Shift) | Arm64Encode::Rn(rn);
      if (offset != 0) {
        log2sz_ = scale;
      }
    } else if ((at == Offset) && Utils::IsInt(9, offset)) {
      encoding_ = ((offset & 0x1ff) << kImm9Shift) | Arm64Encode::Rn(rn);
    } else if ((at == PreIndex) || (at == PostIndex)) {
      ASSERT(Utils::IsInt(9, offset));
      int32_t idx = (at == PostIndex) ? B10 : (B11 | B10);
      encoding_ = idx | ((offset & 0x1ff) << kImm9Shift) | Arm64Encode::Rn(rn);
    } else {
      ASSERT((at == PairOffset) || (at == PairPreIndex) ||
             (at == PairPostIndex));
      ASSERT(Utils::IsInt(7 + scale, offset) &&
             (static_cast<uint32_t>(offset) ==
              ((static_cast<uint32_t>(offset) >> scale) << scale)));
      int32_t idx = 0;
      switch (at) {
        case PairPostIndex:
          idx = B23;
          break;
        case PairPreIndex:
          idx = B24 | B23;
          break;
        case PairOffset:
          idx = B24;
          break;
        default:
          UNREACHABLE();
          break;
      }
      encoding_ =
          idx |
          ((static_cast<uint32_t>(offset >> scale) << kImm7Shift) & kImm7Mask) |
          Arm64Encode::Rn(rn);
      if (offset != 0) {
        log2sz_ = scale;
      }
    }
    type_ = at;
    base_ = ConcreteRegister(rn);
  }

  // This addressing mode does not exist.
  Address(Register rn,
          Register offset,
          AddressType at,
          OperandSize sz = kEightBytes);

  static bool CanHoldOffset(int32_t offset,
                            AddressType at = Offset,
                            OperandSize sz = kEightBytes) {
    if (at == Offset) {
      // Offset fits in 12 bit unsigned and has right alignment for sz,
      // or fits in 9 bit signed offset with no alignment restriction.
      const int32_t scale = Log2OperandSizeBytes(sz);
      return (Utils::IsUint(12 + scale, offset) &&
              (offset == ((offset >> scale) << scale))) ||
             (Utils::IsInt(9, offset));
    } else if (at == PCOffset) {
      return Utils::IsInt(21, offset) && (offset == ((offset >> 2) << 2));
    } else if ((at == PreIndex) || (at == PostIndex)) {
      return Utils::IsInt(9, offset);
    } else {
      ASSERT((at == PairOffset) || (at == PairPreIndex) ||
             (at == PairPostIndex));
      const int32_t scale = Log2OperandSizeBytes(sz);
      return (Utils::IsInt(7 + scale, offset) &&
              (static_cast<uint32_t>(offset) ==
               ((static_cast<uint32_t>(offset) >> scale) << scale)));
    }
  }

  // PC-relative load address.
  static Address PC(int32_t pc_off) {
    ASSERT(CanHoldOffset(pc_off, PCOffset));
    Address addr;
    addr.encoding_ = (((pc_off >> 2) << kImm19Shift) & kImm19Mask);
    addr.base_ = kNoRegister;
    addr.type_ = PCOffset;
    addr.log2sz_ = -1;
    return addr;
  }

  static Address Pair(Register rn,
                      int32_t offset = 0,
                      AddressType at = PairOffset,
                      OperandSize sz = kEightBytes) {
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
  Address(Register rn,
          Register rm,
          Extend ext = UXTX,
          Scaling scale = Unscaled) {
    ASSERT((rn != R31) && (rn != ZR));
    ASSERT((rm != R31) && (rm != CSP));
    // Can only scale when ext = UXTX.
    ASSERT((scale != Scaled) || (ext == UXTX));
    ASSERT((ext == UXTW) || (ext == UXTX) || (ext == SXTW) || (ext == SXTX));
    const int32_t s = (scale == Scaled) ? B12 : 0;
    encoding_ = B21 | B11 | s | Arm64Encode::Rn(rn) | Arm64Encode::Rm(rm) |
                (static_cast<int32_t>(ext) << kExtendTypeShift);
    type_ = Reg;
    base_ = ConcreteRegister(rn);
    log2sz_ = -1;  // Any.
  }

  static OperandSize OperandSizeFor(intptr_t cid) {
    switch (cid) {
      case kArrayCid:
      case kImmutableArrayCid:
      case kTypeArgumentsCid:
        return kFourBytes;
      case kOneByteStringCid:
      case kExternalOneByteStringCid:
        return kByte;
      case kTwoByteStringCid:
      case kExternalTwoByteStringCid:
        return kTwoBytes;
      case kTypedDataInt8ArrayCid:
        return kByte;
      case kTypedDataUint8ArrayCid:
      case kTypedDataUint8ClampedArrayCid:
      case kExternalTypedDataUint8ArrayCid:
      case kExternalTypedDataUint8ClampedArrayCid:
        return kUnsignedByte;
      case kTypedDataInt16ArrayCid:
        return kTwoBytes;
      case kTypedDataUint16ArrayCid:
        return kUnsignedTwoBytes;
      case kTypedDataInt32ArrayCid:
        return kFourBytes;
      case kTypedDataUint32ArrayCid:
        return kUnsignedFourBytes;
      case kTypedDataInt64ArrayCid:
      case kTypedDataUint64ArrayCid:
        return kDWord;
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
  int32_t log2sz_;  // Required log2 of operand size (-1 means any).

  friend class Assembler;
};

class FieldAddress : public Address {
 public:
  FieldAddress(Register base, int32_t disp, OperandSize sz = kEightBytes)
      : Address(base, disp - kHeapObjectTag, Offset, sz) {}

  // This addressing mode does not exist.
  FieldAddress(Register base, Register disp, OperandSize sz = kEightBytes);

  FieldAddress(const FieldAddress& other) : Address(other) {}

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
  Operand() : encoding_(-1), type_(Unknown) {}

  // Data-processing operands - Copy constructor.
  Operand(const Operand& other)
      : ValueObject(), encoding_(other.encoding_), type_(other.type_) {}

  Operand& operator=(const Operand& other) {
    type_ = other.type_;
    encoding_ = other.encoding_;
    return *this;
  }

  explicit Operand(Register rm) {
    ASSERT((rm != R31) && (rm != CSP));
    encoding_ = Arm64Encode::Rm(rm);
    type_ = Shifted;
  }

  Operand(Register rm, Shift shift, int32_t imm) {
    ASSERT(Utils::IsUint(6, imm));
    ASSERT((rm != R31) && (rm != CSP));
    encoding_ = (imm << kImm6Shift) | Arm64Encode::Rm(rm) |
                (static_cast<int32_t>(shift) << kShiftTypeShift);
    type_ = Shifted;
  }

  // This operand type does not exist.
  Operand(Register rm, Shift shift, Register r);

  Operand(Register rm, Extend extend, int32_t imm) {
    ASSERT(Utils::IsUint(3, imm));
    ASSERT((rm != R31) && (rm != CSP));
    encoding_ = B21 | Arm64Encode::Rm(rm) |
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
  // imm_r.  Takes s before r like DecodeBitMasks from Appendix G but unlike
  // the disassembly of the *bfm instructions.
  Operand(uint8_t n, int8_t imm_s, int8_t imm_r) {
    ASSERT((n == 1) || (n == 0));
    ASSERT(Utils::IsUint(6, imm_s) && Utils::IsUint(6, imm_r));
    type_ = BitfieldImm;
    encoding_ = (static_cast<int32_t>(n) << kNShift) |
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
  uint32_t encoding() const { return encoding_; }
  OperandType type() const { return type_; }

  uint32_t encoding_;
  OperandType type_;

  friend class Assembler;
};

class Assembler : public AssemblerBase {
 public:
  explicit Assembler(ObjectPoolBuilder* object_pool_builder,
                     bool use_far_branches = false);
  ~Assembler() {}

  void PushRegister(Register r) { Push(r); }
  void PopRegister(Register r) { Pop(r); }

  void PushRegisterPair(Register r0, Register r1) { PushPair(r0, r1); }
  void PopRegisterPair(Register r0, Register r1) { PopPair(r0, r1); }

  void PushRegisters(const RegisterSet& registers);
  void PopRegisters(const RegisterSet& registers);

  // Push all registers which are callee-saved according to the ARM64 ABI.
  void PushNativeCalleeSavedRegisters();

  // Pop all registers which are callee-saved according to the ARM64 ABI.
  void PopNativeCalleeSavedRegisters();

  void MoveRegister(Register rd, Register rn) {
    if (rd != rn) {
      mov(rd, rn);
    }
  }

  void Drop(intptr_t stack_elements) {
    ASSERT(stack_elements >= 0);
    if (stack_elements > 0) {
      AddImmediate(SP, SP, stack_elements * target::kWordSize);
    }
  }

  void Bind(Label* label);
  // Unconditional jump to a given label. [distance] is ignored on ARM.
  void Jump(Label* label, JumpDistance distance = kFarJump) { b(label); }
  // Unconditional jump to a given address in memory. Clobbers TMP.
  void Jump(const Address& address) {
    ldr(TMP, address);
    br(TMP);
  }

  void LoadField(Register dst, FieldAddress address) { ldr(dst, address); }
  void LoadMemoryValue(Register dst, Register base, int32_t offset) {
    LoadFromOffset(dst, base, offset, kEightBytes);
  }
  void StoreMemoryValue(Register src, Register base, int32_t offset) {
    StoreToOffset(src, base, offset, kEightBytes);
  }
  void LoadAcquire(Register dst, Register address, int32_t offset = 0) {
    if (offset != 0) {
      AddImmediate(TMP2, address, offset);
      ldar(dst, TMP2);
    } else {
      ldar(dst, address);
    }
  }
  void StoreRelease(Register src, Register address, int32_t offset = 0) {
    if (offset != 0) {
      AddImmediate(TMP2, address, offset);
      stlr(src, TMP2);
    } else {
      stlr(src, address);
    }
  }

  void CompareWithFieldValue(Register value, FieldAddress address) {
    CompareWithMemoryValue(value, address);
  }

  void CompareWithMemoryValue(Register value, Address address) {
    ldr(TMP, address);
    cmp(value, Operand(TMP));
  }

  void CompareTypeNullabilityWith(Register type, int8_t value) {
    ldr(TMP,
        FieldAddress(type, compiler::target::Type::nullability_offset(), kByte),
        kUnsignedByte);
    cmp(TMP, Operand(value));
  }

  bool use_far_branches() const {
    return FLAG_use_far_branches || use_far_branches_;
  }

  void set_use_far_branches(bool b) { use_far_branches_ = b; }

  // Debugging and bringup support.
  void Breakpoint() override { brk(0); }

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // In debug mode, this generates code to check that:
  //   FP + kExitLinkSlotFromEntryFp == SP
  // or triggers breakpoint otherwise.
  void EmitEntryFrameVerification();

  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kEntryPointToPcMarkerOffset = 0;
  static intptr_t EntryPointToPcMarkerOffset() {
    return kEntryPointToPcMarkerOffset;
  }

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);
  void Emit64(int64_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return target::IsSmi(object); }

  // Addition and subtraction.
  // For add and sub, to use CSP for rn, o must be of type Operand::Extend.
  // For an unmodified rm in this case, use Operand(rm, UXTX, 0);
  void add(Register rd, Register rn, Operand o) {
    AddSubHelper(kEightBytes, false, false, rd, rn, o);
  }
  void adds(Register rd, Register rn, Operand o) {
    AddSubHelper(kEightBytes, true, false, rd, rn, o);
  }
  void addw(Register rd, Register rn, Operand o) {
    AddSubHelper(kFourBytes, false, false, rd, rn, o);
  }
  void addsw(Register rd, Register rn, Operand o) {
    AddSubHelper(kFourBytes, true, false, rd, rn, o);
  }
  void sub(Register rd, Register rn, Operand o) {
    AddSubHelper(kEightBytes, false, true, rd, rn, o);
  }
  void subs(Register rd, Register rn, Operand o) {
    AddSubHelper(kEightBytes, true, true, rd, rn, o);
  }
  void subw(Register rd, Register rn, Operand o) {
    AddSubHelper(kFourBytes, false, true, rd, rn, o);
  }
  void subsw(Register rd, Register rn, Operand o) {
    AddSubHelper(kFourBytes, true, true, rd, rn, o);
  }

  // Addition and subtraction with carry.
  void adc(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kEightBytes, false, false, rd, rn, rm);
  }
  void adcs(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kEightBytes, true, false, rd, rn, rm);
  }
  void adcw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kFourBytes, false, false, rd, rn, rm);
  }
  void adcsw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kFourBytes, true, false, rd, rn, rm);
  }
  void sbc(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kEightBytes, false, true, rd, rn, rm);
  }
  void sbcs(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kEightBytes, true, true, rd, rn, rm);
  }
  void sbcw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kFourBytes, false, true, rd, rn, rm);
  }
  void sbcsw(Register rd, Register rn, Register rm) {
    AddSubWithCarryHelper(kFourBytes, true, true, rd, rn, rm);
  }

  // PC relative immediate add. imm is in bytes.
  void adr(Register rd, const Immediate& imm) { EmitPCRelOp(ADR, rd, imm); }

  // Bitfield operations.
  // Bitfield move.
  // If s >= r then Rd[s-r:0] := Rn[s:r], else Rd[bitwidth+s-r:bitwidth-r] :=
  // Rn[s:0].
  void bfm(Register rd,
           Register rn,
           int r_imm,
           int s_imm,
           OperandSize size = kEightBytes) {
    EmitBitfieldOp(BFM, rd, rn, r_imm, s_imm, size);
  }

  // Signed bitfield move.
  void sbfm(Register rd,
            Register rn,
            int r_imm,
            int s_imm,
            OperandSize size = kEightBytes) {
    EmitBitfieldOp(SBFM, rd, rn, r_imm, s_imm, size);
  }

  // Unsigned bitfield move.
  void ubfm(Register rd,
            Register rn,
            int r_imm,
            int s_imm,
            OperandSize size = kEightBytes) {
    EmitBitfieldOp(UBFM, rd, rn, r_imm, s_imm, size);
  }

  // Bitfield insert.  Takes the low width bits and replaces bits in rd with
  // them, starting at low_bit.
  void bfi(Register rd,
           Register rn,
           int low_bit,
           int width,
           OperandSize size = kEightBytes) {
    int wordsize = size == kEightBytes ? 64 : 32;
    EmitBitfieldOp(BFM, rd, rn, -low_bit & (wordsize - 1), width - 1, size);
  }

  // Bitfield extract and insert low.  Takes width bits, starting at low_bit and
  // replaces the low width bits of rd with them.
  void bfxil(Register rd,
             Register rn,
             int low_bit,
             int width,
             OperandSize size = kEightBytes) {
    EmitBitfieldOp(BFM, rd, rn, low_bit, low_bit + width - 1, size);
  }

  // Signed bitfield insert in zero.  Takes the low width bits, sign extends
  // them and writes them to rd, starting at low_bit, and zeroing bits below
  // that.
  void sbfiz(Register rd,
             Register rn,
             int low_bit,
             int width,
             OperandSize size = kEightBytes) {
    int wordsize = size == kEightBytes ? 64 : 32;
    EmitBitfieldOp(SBFM, rd, rn, (wordsize - low_bit) & (wordsize - 1),
                   width - 1, size);
  }

  // Signed bitfield extract.  Takes width bits, starting at low_bit, sign
  // extends them and writes them to rd, starting at the lowest bit.
  void sbfx(Register rd,
            Register rn,
            int low_bit,
            int width,
            OperandSize size = kEightBytes) {
    EmitBitfieldOp(SBFM, rd, rn, low_bit, low_bit + width - 1, size);
  }

  // Unsigned bitfield insert in zero.  Takes the low width bits and writes
  // them to rd, starting at low_bit, and zeroing bits above and below.
  void ubfiz(Register rd,
             Register rn,
             int low_bit,
             int width,
             OperandSize size = kEightBytes) {
    int wordsize = size == kEightBytes ? 64 : 32;
    ASSERT(width > 0);
    ASSERT(low_bit < wordsize);
    EmitBitfieldOp(UBFM, rd, rn, (-low_bit) & (wordsize - 1), width - 1, size);
  }

  // Unsigned bitfield extract.  Takes the width bits, starting at low_bit and
  // writes them to the low bits of rd zeroing bits above.
  void ubfx(Register rd,
            Register rn,
            int low_bit,
            int width,
            OperandSize size = kEightBytes) {
    EmitBitfieldOp(UBFM, rd, rn, low_bit, low_bit + width - 1, size);
  }

  // Sign extend byte->64 bit.
  void sxtb(Register rd, Register rn) {
    EmitBitfieldOp(SBFM, rd, rn, 0, 7, kEightBytes);
  }

  // Sign extend halfword->64 bit.
  void sxth(Register rd, Register rn) {
    EmitBitfieldOp(SBFM, rd, rn, 0, 15, kEightBytes);
  }

  // Sign extend word->64 bit.
  void sxtw(Register rd, Register rn) {
    EmitBitfieldOp(SBFM, rd, rn, 0, 31, kEightBytes);
  }

  // Zero/unsigned extend byte->64 bit.
  void uxtb(Register rd, Register rn) {
    EmitBitfieldOp(UBFM, rd, rn, 0, 7, kEightBytes);
  }

  // Zero/unsigned extend halfword->64 bit.
  void uxth(Register rd, Register rn) {
    EmitBitfieldOp(UBFM, rd, rn, 0, 15, kEightBytes);
  }

  // Zero/unsigned extend word->64 bit.
  void uxtw(Register rd, Register rn) {
    EmitBitfieldOp(UBFM, rd, rn, 0, 31, kEightBytes);
  }

  // Logical immediate operations.
  void andi(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDI, rd, rn, imm_op, kEightBytes);
  }
  void orri(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ORRI, rd, rn, imm_op, kEightBytes);
  }
  void eori(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(EORI, rd, rn, imm_op, kEightBytes);
  }
  void andis(Register rd, Register rn, const Immediate& imm) {
    Operand imm_op;
    const bool immok =
        Operand::IsImmLogical(imm.value(), kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDIS, rd, rn, imm_op, kEightBytes);
  }

  // Logical (shifted) register operations.
  void and_(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(AND, rd, rn, o, kEightBytes);
  }
  void andw_(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(AND, rd, rn, o, kFourBytes);
  }
  void bic(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(BIC, rd, rn, o, kEightBytes);
  }
  void orr(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORR, rd, rn, o, kEightBytes);
  }
  void orrw(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORR, rd, rn, o, kFourBytes);
  }
  void orn(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORN, rd, rn, o, kEightBytes);
  }
  void ornw(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ORN, rd, rn, o, kFourBytes);
  }
  void eor(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EOR, rd, rn, o, kEightBytes);
  }
  void eorw(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EOR, rd, rn, o, kFourBytes);
  }
  void eon(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(EON, rd, rn, o, kEightBytes);
  }
  void ands(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(ANDS, rd, rn, o, kEightBytes);
  }
  void bics(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(BICS, rd, rn, o, kEightBytes);
  }

  // Count leading zero bits.
  void clz(Register rd, Register rn) {
    EmitMiscDP1Source(CLZ, rd, rn, kEightBytes);
  }

  // Reverse bits.
  void rbit(Register rd, Register rn) {
    EmitMiscDP1Source(RBIT, rd, rn, kEightBytes);
  }

  // Misc. arithmetic.
  void udiv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(UDIV, rd, rn, rm, kEightBytes);
  }
  void sdiv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(SDIV, rd, rn, rm, kEightBytes);
  }
  void lslv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSLV, rd, rn, rm, kEightBytes);
  }
  void lsrv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSRV, rd, rn, rm, kEightBytes);
  }
  void asrv(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(ASRV, rd, rn, rm, kEightBytes);
  }
  void lslvw(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSLV, rd, rn, rm, kFourBytes);
  }
  void lsrvw(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(LSRV, rd, rn, rm, kFourBytes);
  }
  void asrvw(Register rd, Register rn, Register rm) {
    EmitMiscDP2Source(ASRV, rd, rn, rm, kFourBytes);
  }
  void madd(Register rd,
            Register rn,
            Register rm,
            Register ra,
            OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(MADD, rd, rn, rm, ra, sz);
  }
  void msub(Register rd,
            Register rn,
            Register rm,
            Register ra,
            OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(MSUB, rd, rn, rm, ra, sz);
  }
  void smulh(Register rd,
             Register rn,
             Register rm,
             OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(SMULH, rd, rn, rm, R31, sz);
  }
  void umulh(Register rd,
             Register rn,
             Register rm,
             OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(UMULH, rd, rn, rm, R31, sz);
  }
  void umaddl(Register rd,
              Register rn,
              Register rm,
              Register ra,
              OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(UMADDL, rd, rn, rm, ra, sz);
  }
  void umull(Register rd,
             Register rn,
             Register rm,
             OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(UMADDL, rd, rn, rm, ZR, sz);
  }
  void smaddl(Register rd,
              Register rn,
              Register rm,
              Register ra,
              OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(SMADDL, rd, rn, rm, ra, sz);
  }
  void smull(Register rd,
             Register rn,
             Register rm,
             OperandSize sz = kEightBytes) {
    EmitMiscDP3Source(SMADDL, rd, rn, rm, ZR, sz);
  }

  // Move wide immediate.
  void movk(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVK, crd, imm, hw_idx, kEightBytes);
  }
  void movn(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVN, crd, imm, hw_idx, kEightBytes);
  }
  void movz(Register rd, const Immediate& imm, int hw_idx) {
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVZ, crd, imm, hw_idx, kEightBytes);
  }

  // Loads and Stores.
  void ldr(Register rt, Address a, OperandSize sz = kEightBytes) {
    ASSERT((a.type() != Address::PairOffset) &&
           (a.type() != Address::PairPostIndex) &&
           (a.type() != Address::PairPreIndex));
    if (a.type() == Address::PCOffset) {
      ASSERT(sz == kEightBytes);
      EmitLoadRegLiteral(LDRpc, rt, a, sz);
    } else {
      if (IsSignedOperand(sz)) {
        EmitLoadStoreReg(LDRS, rt, a, sz);
      } else {
        EmitLoadStoreReg(LDR, rt, a, sz);
      }
    }
  }
  void str(Register rt, Address a, OperandSize sz = kEightBytes) {
    ASSERT((a.type() != Address::PairOffset) &&
           (a.type() != Address::PairPostIndex) &&
           (a.type() != Address::PairPreIndex));
    EmitLoadStoreReg(STR, rt, a, sz);
  }

  void ldp(Register rt, Register rt2, Address a, OperandSize sz = kEightBytes) {
    ASSERT((a.type() == Address::PairOffset) ||
           (a.type() == Address::PairPostIndex) ||
           (a.type() == Address::PairPreIndex));
    EmitLoadStoreRegPair(LDP, rt, rt2, a, sz);
  }
  void stp(Register rt, Register rt2, Address a, OperandSize sz = kEightBytes) {
    ASSERT((a.type() == Address::PairOffset) ||
           (a.type() == Address::PairPostIndex) ||
           (a.type() == Address::PairPreIndex));
    EmitLoadStoreRegPair(STP, rt, rt2, a, sz);
  }

  void ldxr(Register rt, Register rn, OperandSize size = kEightBytes) {
    // rt = value
    // rn = address
    EmitLoadStoreExclusive(LDXR, R31, rn, rt, size);
  }
  void stxr(Register rs,
            Register rt,
            Register rn,
            OperandSize size = kEightBytes) {
    // rs = status (1 = failure, 0 = success)
    // rt = value
    // rn = address
    EmitLoadStoreExclusive(STXR, rs, rn, rt, size);
  }
  void clrex() {
    const int32_t encoding = static_cast<int32_t>(CLREX);
    Emit(encoding);
  }

  void ldar(Register rt, Register rn, OperandSize sz = kEightBytes) {
    EmitLoadStoreExclusive(LDAR, R31, rn, rt, sz);
  }

  void stlr(Register rt, Register rn, OperandSize sz = kEightBytes) {
    EmitLoadStoreExclusive(STLR, R31, rn, rt, sz);
  }

  // Conditional select.
  void csel(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSEL, rd, rn, rm, cond, kEightBytes);
  }
  void csinc(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSINC, rd, rn, rm, cond, kEightBytes);
  }
  void cinc(Register rd, Register rn, Condition cond) {
    csinc(rd, rn, rn, InvertCondition(cond));
  }
  void cset(Register rd, Condition cond) {
    csinc(rd, ZR, ZR, InvertCondition(cond));
  }
  void csinv(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSINV, rd, rn, rm, cond, kEightBytes);
  }
  void cinv(Register rd, Register rn, Condition cond) {
    csinv(rd, rn, rn, InvertCondition(cond));
  }
  void csetm(Register rd, Condition cond) {
    csinv(rd, ZR, ZR, InvertCondition(cond));
  }
  void csneg(Register rd, Register rn, Register rm, Condition cond) {
    EmitConditionalSelect(CSNEG, rd, rn, rm, cond, kEightBytes);
  }
  void cneg(Register rd, Register rn, Condition cond) {
    EmitConditionalSelect(CSNEG, rd, rn, rn, InvertCondition(cond),
                          kEightBytes);
  }

  // Comparison.
  // rn cmp o.
  // For add and sub, to use CSP for rn, o must be of type Operand::Extend.
  // For an unmodified rm in this case, use Operand(rm, UXTX, 0);
  void cmp(Register rn, Operand o) { subs(ZR, rn, o); }
  void cmpw(Register rn, Operand o) { subsw(ZR, rn, o); }
  // rn cmp -o.
  void cmn(Register rn, Operand o) { adds(ZR, rn, o); }

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
    EmitConditionalBranch(BCOND, cond, label);
  }

  void b(int32_t offset) { EmitUnconditionalBranchOp(B, offset); }
  void bl(int32_t offset) {
    // CLOBBERS_LR uses __ to access the assembler.
#define __ this->
    CLOBBERS_LR(EmitUnconditionalBranchOp(BL, offset));
#undef __
  }

  // Branches to the given label if the condition holds.
  // [distance] is ignored on ARM.
  void BranchIf(Condition condition,
                Label* label,
                JumpDistance distance = kFarJump) {
    b(label, condition);
  }
  void BranchIfZero(Register rn,
                    Label* label,
                    JumpDistance distance = kFarJump) {
    cbz(label, rn);
  }

  void cbz(Label* label, Register rt, OperandSize sz = kEightBytes) {
    EmitCompareAndBranch(CBZ, rt, label, sz);
  }

  void cbnz(Label* label, Register rt, OperandSize sz = kEightBytes) {
    EmitCompareAndBranch(CBNZ, rt, label, sz);
  }

  // Generate 64-bit compare with zero and branch when condition allows to use
  // a single instruction: cbz/cbnz/tbz/tbnz.
  bool CanGenerateXCbzTbz(Register rn, Condition cond);
  void GenerateXCbzTbz(Register rn, Condition cond, Label* label);

  // Test bit and branch if zero.
  void tbz(Label* label, Register rt, intptr_t bit_number) {
    EmitTestAndBranch(TBZ, rt, bit_number, label);
  }
  void tbnz(Label* label, Register rt, intptr_t bit_number) {
    EmitTestAndBranch(TBNZ, rt, bit_number, label);
  }

  // Branch, link, return.
  void br(Register rn) { EmitUnconditionalBranchRegOp(BR, rn); }
  void blr(Register rn) {
    // CLOBBERS_LR uses __ to access the assembler.
#define __ this->
    CLOBBERS_LR(EmitUnconditionalBranchRegOp(BLR, rn));
#undef __
  }
  void ret(Register rn = kNoRegister2) {
    if (rn == kNoRegister2) {
      // READS_RETURN_ADDRESS_FROM_LR uses __ to access the assembler.
#define __ this->
      READS_RETURN_ADDRESS_FROM_LR(rn = LR);
#undef __
    }
    EmitUnconditionalBranchRegOp(RET, rn);
  }

  // Breakpoint.
  void brk(uint16_t imm) { EmitExceptionGenOp(BRK, imm); }

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
  void fmovsr(VRegister vd, Register rn) {
    ASSERT(rn != R31);
    ASSERT(rn != CSP);
    const Register crn = ConcreteRegister(rn);
    EmitFPIntCvtOp(FMOVSR, static_cast<Register>(vd), crn, kFourBytes);
  }
  void fmovrs(Register rd, VRegister vn) {
    ASSERT(rd != R31);
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitFPIntCvtOp(FMOVRS, crd, static_cast<Register>(vn), kFourBytes);
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
    EmitFPIntCvtOp(SCVTFD, static_cast<Register>(vd), crn, kFourBytes);
  }
  void fcvtzds(Register rd, VRegister vn) {
    ASSERT(rd != R31);
    ASSERT(rd != CSP);
    const Register crd = ConcreteRegister(rd);
    EmitFPIntCvtOp(FCVTZDS, crd, static_cast<Register>(vn));
  }
  void fmovdd(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FMOVDD, vd, vn); }
  void fabsd(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FABSD, vd, vn); }
  void fnegd(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FNEGD, vd, vn); }
  void fsqrtd(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FSQRTD, vd, vn); }
  void fcvtsd(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FCVTSD, vd, vn); }
  void fcvtds(VRegister vd, VRegister vn) { EmitFPOneSourceOp(FCVTDS, vd, vn); }
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
  void fcmpd(VRegister vn, VRegister vm) { EmitFPCompareOp(FCMPD, vn, vm); }
  void fcmpdz(VRegister vn) { EmitFPCompareOp(FCMPZD, vn, V0); }
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
  void vnot(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VNOT, vd, vn); }
  void vabss(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VABSS, vd, vn); }
  void vabsd(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VABSD, vd, vn); }
  void vnegs(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VNEGS, vd, vn); }
  void vnegd(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VNEGD, vd, vn); }
  void vsqrts(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VSQRTS, vd, vn); }
  void vsqrtd(VRegister vd, VRegister vn) { EmitSIMDTwoRegOp(VSQRTD, vd, vn); }
  void vrecpes(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VRECPES, vd, vn);
  }
  void vrsqrtes(VRegister vd, VRegister vn) {
    EmitSIMDTwoRegOp(VRSQRTES, vd, vn);
  }
  void vdupw(VRegister vd, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VDUPI, vd, vn, kFourBytes, 0, 0);
  }
  void vdupx(VRegister vd, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VDUPI, vd, vn, kEightBytes, 0, 0);
  }
  void vdups(VRegister vd, VRegister vn, int32_t idx) {
    EmitSIMDCopyOp(VDUP, vd, vn, kSWord, 0, idx);
  }
  void vdupd(VRegister vd, VRegister vn, int32_t idx) {
    EmitSIMDCopyOp(VDUP, vd, vn, kDWord, 0, idx);
  }
  void vinsw(VRegister vd, int32_t didx, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VINSI, vd, vn, kFourBytes, 0, didx);
  }
  void vinsx(VRegister vd, int32_t didx, Register rn) {
    const VRegister vn = static_cast<VRegister>(rn);
    EmitSIMDCopyOp(VINSI, vd, vn, kEightBytes, 0, didx);
  }
  void vinss(VRegister vd, int32_t didx, VRegister vn, int32_t sidx) {
    EmitSIMDCopyOp(VINS, vd, vn, kSWord, sidx, didx);
  }
  void vinsd(VRegister vd, int32_t didx, VRegister vn, int32_t sidx) {
    EmitSIMDCopyOp(VINS, vd, vn, kDWord, sidx, didx);
  }
  void vmovrs(Register rd, VRegister vn, int32_t sidx) {
    const VRegister vd = static_cast<VRegister>(rd);
    EmitSIMDCopyOp(VMOVW, vd, vn, kFourBytes, 0, sidx);
  }
  void vmovrd(Register rd, VRegister vn, int32_t sidx) {
    const VRegister vd = static_cast<VRegister>(rd);
    EmitSIMDCopyOp(VMOVX, vd, vn, kEightBytes, 0, sidx);
  }

  // Aliases.
  void mov(Register rd, Register rn) {
    if ((rd == CSP) || (rn == CSP)) {
      add(rd, rn, Operand(0));
    } else {
      orr(rd, ZR, Operand(rn));
    }
  }
  void movw(Register rd, Register rn) {
    if ((rd == CSP) || (rn == CSP)) {
      addw(rd, rn, Operand(0));
    } else {
      orrw(rd, ZR, Operand(rn));
    }
  }
  void vmov(VRegister vd, VRegister vn) { vorr(vd, vn, vn); }
  void mvn(Register rd, Register rm) { orn(rd, ZR, Operand(rm)); }
  void mvnw(Register rd, Register rm) { ornw(rd, ZR, Operand(rm)); }
  void neg(Register rd, Register rm) { sub(rd, ZR, Operand(rm)); }
  void negs(Register rd, Register rm) { subs(rd, ZR, Operand(rm)); }
  void negsw(Register rd, Register rm) { subsw(rd, ZR, Operand(rm)); }
  void mul(Register rd, Register rn, Register rm) {
    madd(rd, rn, rm, ZR, kEightBytes);
  }
  void mulw(Register rd, Register rn, Register rm) {
    madd(rd, rn, rm, ZR, kFourBytes);
  }
  void Push(Register reg) {
    ASSERT(reg != PP);  // Only push PP with TagAndPushPP().
    str(reg, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  }
  void Pop(Register reg) {
    ASSERT(reg != PP);  // Only pop PP with PopAndUntagPP().
    ldr(reg, Address(SP, 1 * target::kWordSize, Address::PostIndex));
  }
  void PushPair(Register low, Register high) {
    stp(low, high, Address(SP, -2 * target::kWordSize, Address::PairPreIndex));
  }
  void PopPair(Register low, Register high) {
    ldp(low, high, Address(SP, 2 * target::kWordSize, Address::PairPostIndex));
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
    str(TMP, Address(SP, -1 * target::kWordSize, Address::PreIndex));
  }
  void TagAndPushPPAndPcMarker() {
    COMPILE_ASSERT(CODE_REG != TMP2);
    // Add the heap object tag back to PP before putting it on the stack.
    add(TMP2, PP, Operand(kHeapObjectTag));
    stp(TMP2, CODE_REG,
        Address(SP, -2 * target::kWordSize, Address::PairPreIndex));
  }
  void PopAndUntagPP() {
    ldr(PP, Address(SP, 1 * target::kWordSize, Address::PostIndex));
    sub(PP, PP, Operand(kHeapObjectTag));
    // The caller of PopAndUntagPP() must explicitly allow use of popped PP.
    set_constant_pool_allowed(false);
  }
  void tst(Register rn, Operand o) { ands(ZR, rn, o); }
  void tsti(Register rn, const Immediate& imm) { andis(ZR, rn, imm); }

  void LslImmediate(Register rd,
                    Register rn,
                    int shift,
                    OperandSize sz = kEightBytes) {
    const int reg_size =
        (sz == kEightBytes) ? kXRegSizeInBits : kWRegSizeInBits;
    ubfm(rd, rn, (reg_size - shift) % reg_size, reg_size - shift - 1, sz);
  }
  void LsrImmediate(Register rd,
                    Register rn,
                    int shift,
                    OperandSize sz = kEightBytes) {
    const int reg_size =
        (sz == kEightBytes) ? kXRegSizeInBits : kWRegSizeInBits;
    ubfm(rd, rn, shift, reg_size - 1, sz);
  }
  void AsrImmediate(Register rd, Register rn, int shift) {
    const int reg_size = kXRegSizeInBits;
    sbfm(rd, rn, shift, reg_size - 1);
  }

  void VRecps(VRegister vd, VRegister vn);
  void VRSqrts(VRegister vd, VRegister vn);

  void SmiUntag(Register reg) { AsrImmediate(reg, reg, kSmiTagSize); }
  void SmiUntag(Register dst, Register src) {
    AsrImmediate(dst, src, kSmiTagSize);
  }
  void SmiTag(Register reg) { LslImmediate(reg, reg, kSmiTagSize); }
  void SmiTag(Register dst, Register src) {
    LslImmediate(dst, src, kSmiTagSize);
  }

  // For ARM, the near argument is ignored.
  void BranchIfNotSmi(Register reg,
                      Label* label,
                      JumpDistance distance = kFarJump) {
    tbnz(label, reg, kSmiTag);
  }

  // For ARM, the near argument is ignored.
  void BranchIfSmi(Register reg,
                   Label* label,
                   JumpDistance distance = kFarJump) {
    tbz(label, reg, kSmiTag);
  }

  void Branch(const Code& code,
              Register pp,
              ObjectPoolBuilderEntry::Patchability patchable =
                  ObjectPoolBuilderEntry::kNotPatchable);

  void BranchLink(const Code& code,
                  ObjectPoolBuilderEntry::Patchability patchable =
                      ObjectPoolBuilderEntry::kNotPatchable,
                  CodeEntryKind entry_kind = CodeEntryKind::kNormal);

  void BranchLinkPatchable(const Code& code,
                           CodeEntryKind entry_kind = CodeEntryKind::kNormal) {
    BranchLink(code, ObjectPoolBuilderEntry::kPatchable, entry_kind);
  }
  void BranchLinkToRuntime();

  // Emit a call that shares its object pool entries with other calls
  // that have the same equivalence marker.
  void BranchLinkWithEquivalence(
      const Code& code,
      const Object& equivalence,
      CodeEntryKind entry_kind = CodeEntryKind::kNormal);

  void Call(Address target) {
    // CLOBBERS_LR uses __ to access the assembler.
#define __ this->
    CLOBBERS_LR({
      ldr(LR, target);
      blr(LR);
    });
#undef __
  }
  void Call(const Code& code) { BranchLink(code); }

  void CallCFunction(Address target) { Call(target); }

  void AddImmediate(Register dest, int64_t imm) {
    AddImmediate(dest, dest, imm);
  }

  // Macros accepting a pp Register argument may attempt to load values from
  // the object pool when possible. Unless you are sure that the untagged object
  // pool pointer is in another register, or that it is not available at all,
  // PP should be passed for pp. `dest` can be TMP2, `rn` cannot.
  void AddImmediate(Register dest, Register rn, int64_t imm);
  void AddImmediateSetFlags(Register dest,
                            Register rn,
                            int64_t imm,
                            OperandSize sz = kEightBytes);
  void SubImmediateSetFlags(Register dest,
                            Register rn,
                            int64_t imm,
                            OperandSize sz = kEightBytes);
  void AndImmediate(Register rd, Register rn, int64_t imm);
  void OrImmediate(Register rd, Register rn, int64_t imm);
  void XorImmediate(Register rd, Register rn, int64_t imm);
  void TestImmediate(Register rn, int64_t imm);
  void CompareImmediate(Register rn, int64_t imm);

  void LoadFromOffset(Register dest,
                      const Address& address,
                      OperandSize sz = kEightBytes);
  void LoadFromOffset(Register dest,
                      Register base,
                      int32_t offset,
                      OperandSize sz = kEightBytes);
  void LoadFieldFromOffset(Register dest,
                           Register base,
                           int32_t offset,
                           OperandSize sz = kEightBytes) {
    LoadFromOffset(dest, base, offset - kHeapObjectTag, sz);
  }
  // For loading indexed payloads out of tagged objects like Arrays. If the
  // payload objects are word-sized, use TIMES_HALF_WORD_SIZE if the contents of
  // [index] is a Smi, otherwise TIMES_WORD_SIZE if unboxed.
  void LoadIndexedPayload(Register dest,
                          Register base,
                          int32_t payload_offset,
                          Register index,
                          ScaleFactor scale,
                          OperandSize sz = kEightBytes) {
    add(dest, base, Operand(index, LSL, scale));
    LoadFromOffset(dest, dest, payload_offset - kHeapObjectTag, sz);
  }
  void LoadSFromOffset(VRegister dest, Register base, int32_t offset);
  void LoadDFromOffset(VRegister dest, Register base, int32_t offset);
  void LoadDFieldFromOffset(VRegister dest, Register base, int32_t offset) {
    LoadDFromOffset(dest, base, offset - kHeapObjectTag);
  }
  void LoadQFromOffset(VRegister dest, Register base, int32_t offset);
  void LoadQFieldFromOffset(VRegister dest, Register base, int32_t offset) {
    LoadQFromOffset(dest, base, offset - kHeapObjectTag);
  }

  void LoadFromStack(Register dst, intptr_t depth);
  void StoreToStack(Register src, intptr_t depth);
  void CompareToStack(Register src, intptr_t depth);

  void StoreToOffset(Register src,
                     Register base,
                     int32_t offset,
                     OperandSize sz = kEightBytes);
  void StoreFieldToOffset(Register src,
                          Register base,
                          int32_t offset,
                          OperandSize sz = kEightBytes) {
    StoreToOffset(src, base, offset - kHeapObjectTag, sz);
  }

  void StoreSToOffset(VRegister src, Register base, int32_t offset);
  void StoreDToOffset(VRegister src, Register base, int32_t offset);
  void StoreDFieldToOffset(VRegister src, Register base, int32_t offset) {
    StoreDToOffset(src, base, offset - kHeapObjectTag);
  }
  void StoreQToOffset(VRegister src, Register base, int32_t offset);
  void StoreQFieldToOffset(VRegister src, Register base, int32_t offset) {
    StoreQToOffset(src, base, offset - kHeapObjectTag);
  }

  enum CanBeSmi {
    kValueIsNotSmi,
    kValueCanBeSmi,
  };

  // Store into a heap object and apply the generational and incremental write
  // barriers. All stores into heap objects must pass through this function or,
  // if the value can be proven either Smi or old-and-premarked, its NoBarrier
  // variants.
  // Preserves object and value registers.
  void StoreIntoObject(Register object,
                       const Address& dest,
                       Register value,
                       CanBeSmi can_value_be_smi = kValueCanBeSmi);
  void StoreIntoArray(Register object,
                      Register slot,
                      Register value,
                      CanBeSmi can_value_be_smi = kValueCanBeSmi);

  void StoreIntoObjectOffset(Register object,
                             int32_t offset,
                             Register value,
                             CanBeSmi can_value_be_smi = kValueCanBeSmi);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                Register value);
  void StoreIntoObjectOffsetNoBarrier(Register object,
                                      int32_t offset,
                                      Register value);
  void StoreIntoObjectNoBarrier(Register object,
                                const Address& dest,
                                const Object& value);
  void StoreIntoObjectOffsetNoBarrier(Register object,
                                      int32_t offset,
                                      const Object& value);

  // Stores a non-tagged value into a heap object.
  void StoreInternalPointer(Register object,
                            const Address& dest,
                            Register value);

  // Object pool, loading from pool, etc.
  void LoadPoolPointer(Register pp = PP);

  bool constant_pool_allowed() const { return constant_pool_allowed_; }
  void set_constant_pool_allowed(bool b) { constant_pool_allowed_ = b; }

  compiler::LRState lr_state() const { return lr_state_; }
  void set_lr_state(compiler::LRState state) { lr_state_ = state; }

  intptr_t FindImmediate(int64_t imm);
  bool CanLoadFromObjectPool(const Object& object) const;
  void LoadNativeEntry(Register dst,
                       const ExternalLabel* label,
                       ObjectPoolBuilderEntry::Patchability patchable);
  void LoadIsolate(Register dst);

  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadObject(Register dst, const Object& obj);
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadUniqueObject(Register dst, const Object& obj);
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadImmediate(Register reg, int64_t imm);

  void LoadDImmediate(VRegister reg, double immd);

  // Load word from pool from the given offset using encoding that
  // InstructionPattern::DecodeLoadWordFromPool can decode.
  //
  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadWordFromPoolIndex(Register dst, intptr_t index, Register pp = PP);

  void LoadDoubleWordFromPoolIndex(Register lower,
                                   Register upper,
                                   intptr_t index);

  void PushObject(const Object& object) {
    if (IsSameObject(compiler::NullObject(), object)) {
      Push(NULL_REG);
    } else {
      LoadObject(TMP, object);
      Push(TMP);
    }
  }
  void PushImmediate(int64_t immediate) {
    LoadImmediate(TMP, immediate);
    Push(TMP);
  }
  void CompareObject(Register reg, const Object& object);

  void ExtractClassIdFromTags(Register result, Register tags);
  void ExtractInstanceSizeFromTags(Register result, Register tags);

  void LoadClassId(Register result, Register object);
  void LoadClassById(Register result, Register class_id);
  void CompareClassId(Register object,
                      intptr_t class_id,
                      Register scratch = kNoRegister);
  // Note: input and output registers must be different.
  void LoadClassIdMayBeSmi(Register result, Register object);
  void LoadTaggedClassIdMayBeSmi(Register result, Register object);

  // Reserve specifies how much space to reserve for the Dart stack.
  void SetupDartSP(intptr_t reserve = 4096);
  void SetupCSPFromThread(Register thr);
  void RestoreCSP();

  void EnterFrame(intptr_t frame_size);
  void LeaveFrame();
  void Ret() { ret(); }

  // Emit code to transition between generated mode and native mode.
  //
  // These require and ensure that CSP and SP are equal and aligned and require
  // a scratch register (in addition to TMP/TMP2).

  void TransitionGeneratedToNative(Register destination_address,
                                   Register new_exit_frame,
                                   Register new_exit_through_ffi,
                                   bool enter_safepoint);
  void TransitionNativeToGenerated(Register scratch, bool exit_safepoint);
  void EnterSafepoint(Register scratch);
  void ExitSafepoint(Register scratch);

  void CheckCodePointer();
  void RestoreCodePointer();

  // Restores the values of the registers that are blocked to cache some values
  // e.g. BARRIER_MASK and NULL_REG.
  void RestorePinnedRegisters();

  void SetupGlobalPoolAndDispatchTable();

  void EnterDartFrame(intptr_t frame_size, Register new_pp = kNoRegister);
  void EnterOsrFrame(intptr_t extra_size, Register new_pp = kNoRegister);
  void LeaveDartFrame(RestorePP restore_pp = kRestoreCallerPP);

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

  // Helper method for performing runtime calls from callers requiring manual
  // register preservation is required (e.g. outside IL instructions marked
  // as calling).
  class CallRuntimeScope : public ValueObject {
   public:
    CallRuntimeScope(Assembler* assembler,
                     const RuntimeEntry& entry,
                     intptr_t frame_size,
                     bool preserve_registers = true)
        : CallRuntimeScope(assembler,
                           entry,
                           frame_size,
                           preserve_registers,
                           /*caller=*/nullptr) {}

    CallRuntimeScope(Assembler* assembler,
                     const RuntimeEntry& entry,
                     intptr_t frame_size,
                     Address caller,
                     bool preserve_registers = true)
        : CallRuntimeScope(assembler,
                           entry,
                           frame_size,
                           preserve_registers,
                           &caller) {}

    void Call(intptr_t argument_count);

    ~CallRuntimeScope();

   private:
    CallRuntimeScope(Assembler* assembler,
                     const RuntimeEntry& entry,
                     intptr_t frame_size,
                     bool preserve_registers,
                     const Address* caller);

    Assembler* const assembler_;
    const RuntimeEntry& entry_;
    const bool preserve_registers_;
    const bool restore_code_reg_;
  };

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  void EnterStubFrame();
  void LeaveStubFrame();

  // Set up a frame for calling a C function.
  // Automatically save the pinned registers in Dart which are not callee-
  // saved in the native calling convention.
  // Use together with CallCFunction.
  void EnterCFrame(intptr_t frame_space);
  void LeaveCFrame();

  void MonomorphicCheckedEntryJIT();
  void MonomorphicCheckedEntryAOT();
  void BranchOnMonomorphicCheckedEntryJIT(Label* label);

  // If allocation tracing for |cid| is enabled, will jump to |trace| label,
  // which will allocate in the runtime where tracing occurs.
  void MaybeTraceAllocation(intptr_t cid, Register temp_reg, Label* trace);

  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  // Result:
  //   * [instance_reg] will contain allocated new-space object
  //   * [top_reg] will contain Thread::top_offset()
  void TryAllocate(const Class& cls,
                   Label* failure,
                   Register instance_reg,
                   Register top_reg,
                   bool tag_result = true);

  void TryAllocateArray(intptr_t cid,
                        intptr_t instance_size,
                        Label* failure,
                        Register instance,
                        Register end_address,
                        Register temp1,
                        Register temp2);

  // This emits an PC-relative call of the form "bl <offset>".  The offset
  // is not yet known and needs therefore relocation to the right place before
  // the code can be used.
  //
  // The neccessary information for the "linker" (i.e. the relocation
  // information) is stored in [CodeLayout::static_calls_target_table_]: an
  // entry of the form
  //
  //   (Code::kPcRelativeCall & pc_offset, <target-code>, <target-function>)
  //
  // will be used during relocation to fix the offset.
  //
  // The provided [offset_into_target] will be added to calculate the final
  // destination.  It can be used e.g. for calling into the middle of a
  // function.
  void GenerateUnRelocatedPcRelativeCall(intptr_t offset_into_target = 0);

  // This emits an PC-relative tail call of the form "b <offset>".
  //
  // See also above for the pc-relative call.
  void GenerateUnRelocatedPcRelativeTailCall(intptr_t offset_into_target = 0);

  Address ElementAddressForIntIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    Register array,
                                    intptr_t index) const;
  void ComputeElementAddressForIntIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        Register array,
                                        intptr_t index);
  Address ElementAddressForRegIndex(bool is_external,
                                    intptr_t cid,
                                    intptr_t index_scale,
                                    bool index_unboxed,
                                    Register array,
                                    Register index,
                                    Register temp);

  // Special version of ElementAddressForRegIndex for the case when cid and
  // operand size for the target load don't match (e.g. when loading a few
  // elements of the array with one load).
  Address ElementAddressForRegIndexWithSize(bool is_external,
                                            intptr_t cid,
                                            OperandSize size,
                                            intptr_t index_scale,
                                            bool index_unboxed,
                                            Register array,
                                            Register index,
                                            Register temp);

  void ComputeElementAddressForRegIndex(Register address,
                                        bool is_external,
                                        intptr_t cid,
                                        intptr_t index_scale,
                                        bool index_unboxed,
                                        Register array,
                                        Register index);

  void LoadFieldAddressForRegOffset(Register address,
                                    Register instance,
                                    Register offset_in_words_as_smi);

  // Returns object data offset for address calculation; for heap objects also
  // accounts for the tag.
  static int32_t HeapDataOffset(bool is_external, intptr_t cid) {
    return is_external
               ? 0
               : (target::Instance::DataOffsetFor(cid) - kHeapObjectTag);
  }

  static int32_t EncodeImm26BranchOffset(int64_t imm, int32_t instr) {
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off = (((imm32 >> 2) << kImm26Shift) & kImm26Mask);
    return (instr & ~kImm26Mask) | off;
  }

  static int64_t DecodeImm26BranchOffset(int32_t instr) {
    const int32_t off = (((instr & kImm26Mask) >> kImm26Shift) << 6) >> 4;
    return static_cast<int64_t>(off);
  }

 private:
  bool use_far_branches_;

  bool constant_pool_allowed_;

  compiler::LRState lr_state_ = compiler::LRState::OnEntry();

  void LoadWordFromPoolIndexFixed(Register dst, intptr_t index);

  // Note: the function never clobbers TMP, TMP2 scratch registers.
  void LoadObjectHelper(Register dst, const Object& obj, bool is_unique);

  void AddSubHelper(OperandSize os,
                    bool set_flags,
                    bool subtract,
                    Register rd,
                    Register rn,
                    Operand o) {
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

  void AddSubWithCarryHelper(OperandSize sz,
                             bool set_flags,
                             bool subtract,
                             Register rd,
                             Register rn,
                             Register rm) {
    ASSERT((rd != R31) && (rn != R31) && (rm != R31));
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t op = subtract ? SBC : ADC;
    const int32_t encoding = op | size | s | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | Arm64Encode::Rm(rm);
    Emit(encoding);
  }

  void EmitAddSubImmOp(AddSubImmOp op,
                       Register rd,
                       Register rn,
                       Operand o,
                       OperandSize sz,
                       bool set_flags) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding = op | size | s | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | o.encoding();
    Emit(encoding);
  }

  // Follows the *bfm instructions in taking r before s (unlike the Operand
  // constructor, which follows DecodeBitMasks from Appendix G).
  void EmitBitfieldOp(BitfieldOp op,
                      Register rd,
                      Register rn,
                      int r_imm,
                      int s_imm,
                      OperandSize size) {
    if (size != kEightBytes) {
      ASSERT(size == kFourBytes);
      ASSERT(r_imm < 32 && s_imm < 32);
    } else {
      ASSERT(r_imm < 64 && s_imm < 64);
    }
    const int32_t instr = op | (size == kEightBytes ? Bitfield64 : 0);
    const int32_t encoding = instr | Operand(0, s_imm, r_imm).encoding() |
                             Arm64Encode::Rd(rd) | Arm64Encode::Rn(rn);
    Emit(encoding);
  }

  void EmitLogicalImmOp(LogicalImmOp op,
                        Register rd,
                        Register rn,
                        Operand o,
                        OperandSize sz) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT(rn != CSP);
    ASSERT((op == ANDIS) || (rd != ZR));   // op != ANDIS => rd != ZR.
    ASSERT((op != ANDIS) || (rd != CSP));  // op == ANDIS => rd != CSP.
    ASSERT(o.type() == Operand::BitfieldImm);
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding =
        op | size | Arm64Encode::Rd(rd) | Arm64Encode::Rn(rn) | o.encoding();
    Emit(encoding);
  }

  void EmitLogicalShiftOp(LogicalShiftOp op,
                          Register rd,
                          Register rn,
                          Operand o,
                          OperandSize sz) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT((rd != CSP) && (rn != CSP));
    ASSERT(o.type() == Operand::Shifted);
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding =
        op | size | Arm64Encode::Rd(rd) | Arm64Encode::Rn(rn) | o.encoding();
    Emit(encoding);
  }

  void EmitAddSubShiftExtOp(AddSubShiftExtOp op,
                            Register rd,
                            Register rn,
                            Operand o,
                            OperandSize sz,
                            bool set_flags) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t s = set_flags ? B29 : 0;
    const int32_t encoding = op | size | s | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | o.encoding();
    Emit(encoding);
  }

  int32_t BindImm19Branch(int64_t position, int64_t dest);
  int32_t BindImm14Branch(int64_t position, int64_t dest);

  int32_t EncodeImm19BranchOffset(int64_t imm, int32_t instr) {
    if (!CanEncodeImm19BranchOffset(imm)) {
      ASSERT(!use_far_branches());
      BailoutWithBranchOffsetError();
    }
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off =
        ((static_cast<uint32_t>(imm32 >> 2) << kImm19Shift) & kImm19Mask);
    return (instr & ~kImm19Mask) | off;
  }

  int64_t DecodeImm19BranchOffset(int32_t instr) {
    int32_t insns = (static_cast<uint32_t>(instr) & kImm19Mask) >> kImm19Shift;
    const int32_t off = static_cast<int32_t>(insns << 13) >> 11;
    return static_cast<int64_t>(off);
  }

  int32_t EncodeImm14BranchOffset(int64_t imm, int32_t instr) {
    if (!CanEncodeImm14BranchOffset(imm)) {
      ASSERT(!use_far_branches());
      BailoutWithBranchOffsetError();
    }
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off =
        ((static_cast<uint32_t>(imm32 >> 2) << kImm14Shift) & kImm14Mask);
    return (instr & ~kImm14Mask) | off;
  }

  int64_t DecodeImm14BranchOffset(int32_t instr) {
    int32_t insns = (static_cast<uint32_t>(instr) & kImm14Mask) >> kImm14Shift;
    const int32_t off = static_cast<int32_t>(insns << 18) >> 16;
    return static_cast<int64_t>(off);
  }

  bool IsConditionalBranch(int32_t instr) {
    return (instr & ConditionalBranchMask) ==
           (ConditionalBranchFixed & ConditionalBranchMask);
  }

  bool IsCompareAndBranch(int32_t instr) {
    return (instr & CompareAndBranchMask) ==
           (CompareAndBranchFixed & CompareAndBranchMask);
  }

  bool IsTestAndBranch(int32_t instr) {
    return (instr & TestAndBranchMask) ==
           (TestAndBranchFixed & TestAndBranchMask);
  }

  Condition DecodeImm19BranchCondition(int32_t instr) {
    if (IsConditionalBranch(instr)) {
      return static_cast<Condition>((instr & kCondMask) >> kCondShift);
    }
    ASSERT(IsCompareAndBranch(instr));
    return (instr & B24) ? EQ : NE;  // cbz : cbnz
  }

  int32_t EncodeImm19BranchCondition(Condition cond, int32_t instr) {
    if (IsConditionalBranch(instr)) {
      const int32_t c_imm = static_cast<int32_t>(cond);
      return (instr & ~kCondMask) | (c_imm << kCondShift);
    }
    ASSERT(IsCompareAndBranch(instr));
    return (instr & ~B24) | (cond == EQ ? B24 : 0);  // cbz : cbnz
  }

  Condition DecodeImm14BranchCondition(int32_t instr) {
    ASSERT(IsTestAndBranch(instr));
    return (instr & B24) ? EQ : NE;  // tbz : tbnz
  }

  int32_t EncodeImm14BranchCondition(Condition cond, int32_t instr) {
    ASSERT(IsTestAndBranch(instr));
    return (instr & ~B24) | (cond == EQ ? B24 : 0);  // tbz : tbnz
  }

  void EmitCompareAndBranchOp(CompareAndBranchOp op,
                              Register rt,
                              int64_t imm,
                              OperandSize sz) {
    // EncodeImm19BranchOffset will longjump out if the offset does not fit in
    // 19 bits.
    const int32_t encoded_offset = EncodeImm19BranchOffset(imm, 0);
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    ASSERT(Utils::IsInt(21, imm) && ((imm & 0x3) == 0));
    ASSERT((rt != CSP) && (rt != R31));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding = op | size | Arm64Encode::Rt(rt) | encoded_offset;
    Emit(encoding);
  }

  void EmitTestAndBranchOp(TestAndBranchOp op,
                           Register rt,
                           intptr_t bit_number,
                           int64_t imm) {
    // EncodeImm14BranchOffset will longjump out if the offset does not fit in
    // 14 bits.
    const int32_t encoded_offset = EncodeImm14BranchOffset(imm, 0);
    ASSERT((bit_number >= 0) && (bit_number <= 63));
    ASSERT(Utils::IsInt(16, imm) && ((imm & 0x3) == 0));
    ASSERT((rt != CSP) && (rt != R31));
    const Register crt = ConcreteRegister(rt);
    int32_t bit_number_low = bit_number & 0x1f;
    int32_t bit_number_hi = (bit_number & 0x20) >> 5;
    const int32_t encoding =
        op | (bit_number_low << 19) | (bit_number_hi << 31) |
        (static_cast<int32_t>(crt) << kRtShift) | encoded_offset;
    Emit(encoding);
  }

  void EmitConditionalBranchOp(ConditionalBranchOp op,
                               Condition cond,
                               int64_t imm) {
    const int32_t off = EncodeImm19BranchOffset(imm, 0);
    const int32_t encoding =
        op | (static_cast<int32_t>(cond) << kCondShift) | off;
    Emit(encoding);
  }

  bool CanEncodeImm19BranchOffset(int64_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    return Utils::IsInt(21, offset);
  }

  bool CanEncodeImm14BranchOffset(int64_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    return Utils::IsInt(16, offset);
  }

  void EmitConditionalBranch(ConditionalBranchOp op,
                             Condition cond,
                             Label* label) {
    if (label->IsBound()) {
      const int64_t dest = label->Position() - buffer_.Size();
      if (use_far_branches() && !CanEncodeImm19BranchOffset(dest)) {
        if (cond == AL) {
          // If the condition is AL, we must always branch to dest. There is
          // no need for a guard branch.
          b(dest);
        } else {
          EmitConditionalBranchOp(op, InvertCondition(cond),
                                  2 * Instr::kInstrSize);
          // Make a new dest that takes the new position into account after the
          // inverted test.
          const int64_t dest = label->Position() - buffer_.Size();
          b(dest);
        }
      } else {
        EmitConditionalBranchOp(op, cond, dest);
      }
      label->UpdateLRState(lr_state());
    } else {
      const int64_t position = buffer_.Size();
      if (use_far_branches()) {
        // When cond is AL, this guard branch will be rewritten as a nop when
        // the label is bound. We don't write it as a nop initially because it
        // makes the decoding code in Bind simpler.
        EmitConditionalBranchOp(op, InvertCondition(cond),
                                2 * Instr::kInstrSize);
        b(label->position_);
      } else {
        EmitConditionalBranchOp(op, cond, label->position_);
      }
      label->LinkTo(position, lr_state());
    }
  }

  void EmitCompareAndBranch(CompareAndBranchOp op,
                            Register rt,
                            Label* label,
                            OperandSize sz) {
    if (label->IsBound()) {
      const int64_t dest = label->Position() - buffer_.Size();
      if (use_far_branches() && !CanEncodeImm19BranchOffset(dest)) {
        EmitCompareAndBranchOp(op == CBZ ? CBNZ : CBZ, rt,
                               2 * Instr::kInstrSize, sz);
        // Make a new dest that takes the new position into account after the
        // inverted test.
        const int64_t dest = label->Position() - buffer_.Size();
        b(dest);
      } else {
        EmitCompareAndBranchOp(op, rt, dest, sz);
      }
      label->UpdateLRState(lr_state());
    } else {
      const int64_t position = buffer_.Size();
      if (use_far_branches()) {
        EmitCompareAndBranchOp(op == CBZ ? CBNZ : CBZ, rt,
                               2 * Instr::kInstrSize, sz);
        b(label->position_);
      } else {
        EmitCompareAndBranchOp(op, rt, label->position_, sz);
      }
      label->LinkTo(position, lr_state());
    }
  }

  void EmitTestAndBranch(TestAndBranchOp op,
                         Register rt,
                         intptr_t bit_number,
                         Label* label) {
    if (label->IsBound()) {
      const int64_t dest = label->Position() - buffer_.Size();
      if (use_far_branches() && !CanEncodeImm14BranchOffset(dest)) {
        EmitTestAndBranchOp(op == TBZ ? TBNZ : TBZ, rt, bit_number,
                            2 * Instr::kInstrSize);
        // Make a new dest that takes the new position into account after the
        // inverted test.
        const int64_t dest = label->Position() - buffer_.Size();
        b(dest);
      } else {
        EmitTestAndBranchOp(op, rt, bit_number, dest);
      }
      label->UpdateLRState(lr_state());
    } else {
      int64_t position = buffer_.Size();
      if (use_far_branches()) {
        EmitTestAndBranchOp(op == TBZ ? TBNZ : TBZ, rt, bit_number,
                            2 * Instr::kInstrSize);
        b(label->position_);
      } else {
        EmitTestAndBranchOp(op, rt, bit_number, label->position_);
      }
      label->LinkTo(position, lr_state());
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
    const int32_t encoding = op | Arm64Encode::Rn(rn);
    Emit(encoding);
  }

  static int32_t ExceptionGenOpEncoding(ExceptionGenOp op, uint16_t imm) {
    return op | (static_cast<int32_t>(imm) << kImm16Shift);
  }

  void EmitExceptionGenOp(ExceptionGenOp op, uint16_t imm) {
    Emit(ExceptionGenOpEncoding(op, imm));
  }

  void EmitMoveWideOp(MoveWideOp op,
                      Register rd,
                      const Immediate& imm,
                      int hw_idx,
                      OperandSize sz) {
    ASSERT((hw_idx >= 0) && (hw_idx <= 3));
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding =
        op | size | Arm64Encode::Rd(rd) |
        (static_cast<int32_t>(hw_idx) << kHWShift) |
        (static_cast<int32_t>(imm.value() & 0xffff) << kImm16Shift);
    Emit(encoding);
  }

  void EmitLoadStoreExclusive(LoadStoreExclusiveOp op,
                              Register rs,
                              Register rn,
                              Register rt,
                              OperandSize sz = kEightBytes) {
    ASSERT(sz == kEightBytes || sz == kFourBytes);
    const int32_t size = B31 | (sz == kEightBytes ? B30 : 0);

    ASSERT((rs != kNoRegister) && (rs != ZR));
    ASSERT((rn != kNoRegister) && (rn != ZR));
    ASSERT((rt != kNoRegister) && (rt != ZR));

    const int32_t encoding = op | size | Arm64Encode::Rs(rs) |
                             Arm64Encode::Rt2(R31) | Arm64Encode::Rn(rn) |
                             Arm64Encode::Rt(rt);

    Emit(encoding);
  }

  void EmitLoadStoreReg(LoadStoreRegOp op,
                        Register rt,
                        Address a,
                        OperandSize sz) {
    // Unpredictable, illegal on some microarchitectures.
    ASSERT((op != LDR && op != STR && op != LDRS) || a.can_writeback_to(rt));

    const int32_t size = Log2OperandSizeBytes(sz);
    ASSERT(a.log2sz_ == -1 || a.log2sz_ == size);
    const int32_t encoding =
        op | ((size & 0x3) << kSzShift) | Arm64Encode::Rt(rt) | a.encoding();
    Emit(encoding);
  }

  void EmitLoadRegLiteral(LoadRegLiteralOp op,
                          Register rt,
                          Address a,
                          OperandSize sz) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    ASSERT(a.log2sz_ == -1 || a.log2sz_ == Log2OperandSizeBytes(sz));
    ASSERT((rt != CSP) && (rt != R31));
    const int32_t size = (sz == kEightBytes) ? B30 : 0;
    const int32_t encoding = op | size | Arm64Encode::Rt(rt) | a.encoding();
    Emit(encoding);
  }

  void EmitLoadStoreRegPair(LoadStoreRegPairOp op,
                            Register rt,
                            Register rt2,
                            Address a,
                            OperandSize sz) {
    // Unpredictable, illegal on some microarchitectures.
    ASSERT(a.can_writeback_to(rt) && a.can_writeback_to(rt2));
    ASSERT(op != LDP || rt != rt2);

    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    ASSERT(a.log2sz_ == -1 || a.log2sz_ == Log2OperandSizeBytes(sz));
    ASSERT((rt != CSP) && (rt != R31));
    ASSERT((rt2 != CSP) && (rt2 != R31));
    int32_t opc = 0;
    switch (sz) {
      case kEightBytes:
        opc = B31;
        break;
      case kFourBytes:
        opc = B30;
        break;
      case kUnsignedFourBytes:
        opc = 0;
        break;
      default:
        UNREACHABLE();
        break;
    }
    const int32_t encoding =
        opc | op | Arm64Encode::Rt(rt) | Arm64Encode::Rt2(rt2) | a.encoding();
    Emit(encoding);
  }

  void EmitPCRelOp(PCRelOp op, Register rd, const Immediate& imm) {
    ASSERT(Utils::IsInt(21, imm.value()));
    ASSERT((rd != R31) && (rd != CSP));
    const int32_t loimm = (imm.value() & 0x3) << 29;
    const int32_t hiimm =
        (static_cast<uint32_t>(imm.value() >> 2) << kImm19Shift) & kImm19Mask;
    const int32_t encoding = op | loimm | hiimm | Arm64Encode::Rd(rd);
    Emit(encoding);
  }

  void EmitMiscDP1Source(MiscDP1SourceOp op,
                         Register rd,
                         Register rn,
                         OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP));
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding =
        op | size | Arm64Encode::Rd(rd) | Arm64Encode::Rn(rn);
    Emit(encoding);
  }

  void EmitMiscDP2Source(MiscDP2SourceOp op,
                         Register rd,
                         Register rn,
                         Register rm,
                         OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding = op | size | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | Arm64Encode::Rm(rm);
    Emit(encoding);
  }

  void EmitMiscDP3Source(MiscDP3SourceOp op,
                         Register rd,
                         Register rn,
                         Register rm,
                         Register ra,
                         OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP) && (ra != CSP));
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding = op | size | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | Arm64Encode::Rm(rm) |
                             Arm64Encode::Ra(ra);
    Emit(encoding);
  }

  void EmitConditionalSelect(ConditionalSelectOp op,
                             Register rd,
                             Register rn,
                             Register rm,
                             Condition cond,
                             OperandSize sz) {
    ASSERT((rd != CSP) && (rn != CSP) && (rm != CSP));
    ASSERT((sz == kEightBytes) || (sz == kFourBytes) ||
           (sz == kUnsignedFourBytes));
    const int32_t size = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding = op | size | Arm64Encode::Rd(rd) |
                             Arm64Encode::Rn(rn) | Arm64Encode::Rm(rm) |
                             (static_cast<int32_t>(cond) << kSelCondShift);
    Emit(encoding);
  }

  void EmitFPImm(FPImmOp op, VRegister vd, uint8_t imm8) {
    const int32_t encoding =
        op | (static_cast<int32_t>(vd) << kVdShift) | (imm8 << kImm8Shift);
    Emit(encoding);
  }

  void EmitFPIntCvtOp(FPIntCvtOp op,
                      Register rd,
                      Register rn,
                      OperandSize sz = kEightBytes) {
    ASSERT((sz == kEightBytes) || (sz == kFourBytes));
    const int32_t sfield = (sz == kEightBytes) ? B31 : 0;
    const int32_t encoding =
        op | Arm64Encode::Rd(rd) | Arm64Encode::Rn(rn) | sfield;
    Emit(encoding);
  }

  void EmitFPOneSourceOp(FPOneSourceOp op, VRegister vd, VRegister vn) {
    const int32_t encoding = op | (static_cast<int32_t>(vd) << kVdShift) |
                             (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  void EmitFPTwoSourceOp(FPTwoSourceOp op,
                         VRegister vd,
                         VRegister vn,
                         VRegister vm) {
    const int32_t encoding = op | (static_cast<int32_t>(vd) << kVdShift) |
                             (static_cast<int32_t>(vn) << kVnShift) |
                             (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitFPCompareOp(FPCompareOp op, VRegister vn, VRegister vm) {
    const int32_t encoding = op | (static_cast<int32_t>(vn) << kVnShift) |
                             (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitSIMDThreeSameOp(SIMDThreeSameOp op,
                           VRegister vd,
                           VRegister vn,
                           VRegister vm) {
    const int32_t encoding = op | (static_cast<int32_t>(vd) << kVdShift) |
                             (static_cast<int32_t>(vn) << kVnShift) |
                             (static_cast<int32_t>(vm) << kVmShift);
    Emit(encoding);
  }

  void EmitSIMDCopyOp(SIMDCopyOp op,
                      VRegister vd,
                      VRegister vn,
                      OperandSize sz,
                      int32_t idx4,
                      int32_t idx5) {
    const int32_t shift = Log2OperandSizeBytes(sz);
    const int32_t imm5 = ((idx5 << (shift + 1)) | (1 << shift)) & 0x1f;
    const int32_t imm4 = (idx4 << shift) & 0xf;
    const int32_t encoding = op | (imm5 << kImm5Shift) | (imm4 << kImm4Shift) |
                             (static_cast<int32_t>(vd) << kVdShift) |
                             (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  void EmitSIMDTwoRegOp(SIMDTwoRegOp op, VRegister vd, VRegister vn) {
    const int32_t encoding = op | (static_cast<int32_t>(vd) << kVdShift) |
                             (static_cast<int32_t>(vn) << kVnShift);
    Emit(encoding);
  }

  enum BarrierFilterMode {
    // Filter falls through into the barrier update code. Target label
    // is a "after-store" label.
    kJumpToNoUpdate,

    // Filter falls through to the "after-store" code. Target label
    // is barrier update code label.
    kJumpToBarrier,
  };

  void StoreIntoObjectFilter(Register object,
                             Register value,
                             Label* label,
                             CanBeSmi can_be_smi,
                             BarrierFilterMode barrier_filter_mode);

  // Note: leaf call sequence uses some abi callee save registers as scratch
  // so they should be manually preserved.
  void EnterCallRuntimeFrame(intptr_t frame_size, bool is_leaf);
  void LeaveCallRuntimeFrame(bool is_leaf);

  friend class dart::FlowGraphCompiler;
  std::function<void(Register reg)> generate_invoke_write_barrier_wrapper_;
  std::function<void()> generate_invoke_array_write_barrier_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_ARM64_H_
