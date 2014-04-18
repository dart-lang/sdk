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
#include "vm/object.h"
#include "vm/simulator.h"

namespace dart {

// Forward declarations.
class RuntimeEntry;

// TODO(zra): Label, Address, and FieldAddress are copied from ARM,
// they must be adapted to ARM64.
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
    const Register crn = ConcreteRegister(rn);
    const int32_t scale = Log2OperandSizeBytes(sz);
    if (Utils::IsUint(12 + scale, offset) && (at == Offset)) {
      ASSERT(offset == ((offset >> scale) << scale));
      encoding_ =
          B24 |
          ((offset >> scale) << kImm12Shift) |
          (static_cast<int32_t>(crn) << kRnShift);
    } else {
      ASSERT(Utils::IsInt(9, offset));
      ASSERT((at == PreIndex) || (at == PostIndex));
      int32_t idx = (at == PostIndex) ? B10 : (B11 | B10);
      encoding_ =
          idx |
          ((offset & 0x1ff) << kImm9Shift) |
          (static_cast<int32_t>(crn) << kRnShift);
    }
    type_ = at;
    base_ = crn;
  }

  static bool CanHoldOffset(int32_t offset, AddressType at = Offset,
                            OperandSize sz = kDoubleWord) {
    if (at == Offset) {
      // Fits in 12 bit unsigned and right alignment for sz.
      const int32_t scale = Log2OperandSizeBytes(sz);
      return Utils::IsUint(12 + scale, offset) &&
             (offset == ((offset >> scale) << scale));
    } else if (at == PCOffset) {
      return Utils::IsInt(21, offset) &&
             (offset == ((offset >> 2) << 2));
    } else {
      ASSERT((at == PreIndex) || (at == PostIndex));
      return Utils::IsInt(9, offset);
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

  // Base register rn with offset rm. rm is sign-extended according to ext.
  // If ext is UXTX, rm may be optionally scaled by the
  // Log2OperandSize (specified by the instruction).
  Address(Register rn, Register rm, Extend ext = UXTX, bool scaled = false) {
    ASSERT((rn != R31) && (rn != ZR));
    ASSERT((rm != R31) && (rm != SP));
    ASSERT(!scaled || (ext == UXTX));  // Can only scale when ext = UXTX.
    ASSERT((ext == UXTW) || (ext == UXTX) || (ext == SXTW) || (ext == SXTX));
    const Register crn = ConcreteRegister(rn);
    const Register crm = ConcreteRegister(rm);
    const int32_t s = scaled ? B12 : 0;
    encoding_ =
        B21 | B11 | s |
        (static_cast<int32_t>(crn) << kRnShift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(ext) << kExtendTypeShift);
    type_ = Reg;
    base_ = crn;
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
  FieldAddress(Register base, int32_t disp)
      : Address(base, disp - kHeapObjectTag) { }

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
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ = (static_cast<int32_t>(crm) << kRmShift);
    type_ = Shifted;
  }

  Operand(Register rm, Shift shift, int32_t imm) {
    ASSERT(Utils::IsUint(6, imm));
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        (imm << kImm6Shift) |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(shift) << kShiftTypeShift);
    type_ = Shifted;
  }

  Operand(Register rm, Extend extend, int32_t imm) {
    ASSERT(Utils::IsUint(3, imm));
    ASSERT((rm != R31) && (rm != SP));
    const Register crm = ConcreteRegister(rm);
    encoding_ =
        B21 |
        (static_cast<int32_t>(crm) << kRmShift) |
        (static_cast<int32_t>(extend) << kExtendTypeShift) |
        ((imm & 0x7) << kImm3Shift);
    type_ = Extended;
  }

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

  const Code::Comments& GetCodeComments() const;

  static const char* RegisterName(Register reg);

  static const char* FpuRegisterName(FpuRegister reg);

  void SetPrologueOffset() {
    if (prologue_offset_ == -1) {
      prologue_offset_ = CodeSize();
    }
  }

  void ReserveAlignedFrameSpace(intptr_t frame_space);

  // TODO(zra): Make sure this is right.
  // Instruction pattern from entrypoint is used in Dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kEntryPointToPcMarkerOffset = 0;

  // Emit data (e.g encoded instruction or immediate) in instruction stream.
  void Emit(int32_t value);

  // On some other platforms, we draw a distinction between safe and unsafe
  // smis.
  static bool IsSafe(const Object& object) { return true; }
  static bool IsSafeSmi(const Object& object) { return object.IsSmi(); }

  // Addition and subtraction.
  void add(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, false, rd, rn, o);
  }
  void adds(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, true, false, rd, rn, o);
  }
  void addw(Register rd, Register rn, Operand o) {
    AddSubHelper(kWord, false, false, rd, rn, o);
  }
  void sub(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, false, true, rd, rn, o);
  }
  void subs(Register rd, Register rn, Operand o) {
    AddSubHelper(kDoubleWord, true, true, rd, rn, o);
  }

  // PC relative immediate add. imm is in bytes.
  void adr(Register rd, int64_t imm) {
    EmitPCRelOp(ADR, rd, imm);
  }

  // Logical immediate operations.
  // TODO(zra): Add macros that check IsImmLogical, and fall back on a longer
  // sequence on failure.
  void andi(Register rd, Register rn, uint64_t imm) {
    Operand imm_op;
    const bool immok = Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDI, rd, rn, imm_op, kDoubleWord);
  }
  void orri(Register rd, Register rn, uint64_t imm) {
    Operand imm_op;
    const bool immok = Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ORRI, rd, rn, imm_op, kDoubleWord);
  }
  void eori(Register rd, Register rn, uint64_t imm) {
    Operand imm_op;
    const bool immok = Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(EORI, rd, rn, imm_op, kDoubleWord);
  }
  void andis(Register rd, Register rn, uint64_t imm) {
    Operand imm_op;
    const bool immok = Operand::IsImmLogical(imm, kXRegSizeInBits, &imm_op);
    ASSERT(immok);
    EmitLogicalImmOp(ANDIS, rd, rn, imm_op, kDoubleWord);
  }

  // Logical (shifted) register operations.
  void and_(Register rd, Register rn, Operand o) {
    EmitLogicalShiftOp(AND, rd, rn, o, kDoubleWord);
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

  // Move wide immediate.
  void movk(Register rd, uint16_t imm, int hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVK, crd, imm, hw_idx, kDoubleWord);
  }
  void movn(Register rd, uint16_t imm, int hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVN, crd, imm, hw_idx, kDoubleWord);
  }
  void movz(Register rd, uint16_t imm, int hw_idx) {
    ASSERT(rd != SP);
    const Register crd = ConcreteRegister(rd);
    EmitMoveWideOp(MOVZ, crd, imm, hw_idx, kDoubleWord);
  }

  // Loads and Stores.
  void ldr(Register rt, Address a) {
    if (a.type() == Address::PCOffset) {
      EmitLoadRegLiteral(LDRpc, rt, a, kDoubleWord);
    } else {
      // If we are doing pre-/post-indexing, and the base and result registers
      // are the same, then the result of the load will be clobbered by the
      // writeback, which is unlikely to be useful.
      ASSERT(((a.type() != Address::PreIndex) &&
              (a.type() != Address::PostIndex)) ||
             (rt != a.base()));
      EmitLoadStoreReg(LDR, rt, a, kDoubleWord);
    }
  }
  void str(Register rt, Address a) {
    EmitLoadStoreReg(STR, rt, a, kDoubleWord);
  }

  // Comparison.
  // rn cmp o.
  void cmp(Register rn, Operand o) {
    subs(ZR, rn, o);
  }
  // rn cmp -o.
  void cmn(Register rn, Operand o) {
    adds(ZR, rn, o);
  }

  // Conditional branch.
  void b(Label* label, Condition cond = AL) {
    EmitBranch(BCOND, cond, label);
  }

  // TODO(zra): branch and link with imm26 offset.
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

  // Aliases.
  void mov(Register rd, Register rn) {
    if ((rd == SP) || (rn == SP)) {
      add(rd, rn, Operand(0));
    } else {
      orr(rd, ZR, Operand(rn));
    }
  }
  void mvn(Register rd, Register rm) {
    orr(rd, ZR, Operand(rm));
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
    ASSERT(reg != PP);  // Only push PP with PushPP().
    str(reg, Address(SP, -1 * kWordSize, Address::PreIndex));
  }
  void Pop(Register reg) {
    ASSERT(reg != PP);  // Only pop PP with PopPP().
    ldr(reg, Address(SP, 1 * kWordSize, Address::PostIndex));
  }
  void PushPP() {
    // Add the heap object tag back to PP before putting it on the stack.
    add(PP, PP, Operand(kHeapObjectTag));
    str(PP, Address(SP, -1 * kWordSize, Address::PreIndex));
  }
  void PopPP() {
    ldr(PP, Address(SP, 1 * kWordSize, Address::PostIndex));
    sub(PP, PP, Operand(kHeapObjectTag));
  }
  void tst(Register rn, Operand o) {
    ands(ZR, rn, o);
  }
  void tsti(Register rn, uint64_t imm) {
    andis(ZR, rn, imm);
  }

  void SmiUntag(Register reg) {
    add(reg, ZR, Operand(reg, ASR, kSmiTagSize));
  }

  // Branching to ExternalLabels.
  void Branch(const ExternalLabel* label) {
    LoadExternalLabel(TMP, label, kPatchable, PP);
    br(TMP);
  }

  void BranchPatchable(const ExternalLabel* label) {
    LoadPatchableImmediate(TMP, label->address());
    br(TMP);
  }

  void BranchLink(const ExternalLabel* label, Register pp) {
    if (Isolate::Current() == Dart::vm_isolate()) {
      LoadImmediate(TMP, label->address(), kNoRegister);
      blr(TMP);
    } else {
      LoadExternalLabel(TMP, label, kNotPatchable, pp);
      blr(TMP);
    }
  }

  void BranchLinkPatchable(const ExternalLabel* label) {
    LoadExternalLabel(TMP, label, kPatchable, PP);
    blr(TMP);
  }

  // Macros accepting a pp Register argument may attempt to load values from
  // the object pool when possible. Unless you are sure that the untagged object
  // pool pointer is in another register, or that it is not available at all,
  // PP should be passed for pp.
  void AddImmediate(Register dest, Register rn, int64_t imm, Register pp);
  void CompareImmediate(Register rn, int64_t imm, Register pp);
  void LoadFromOffset(Register dest, Register base, int32_t offset);
  void LoadFieldFromOffset(Register dest, Register base, int32_t offset) {
    LoadFromOffset(dest, base, offset - kHeapObjectTag);
  }
  void StoreToOffset(Register dest, Register base, int32_t offset);
  void StoreFieldToOffset(Register dest, Register base, int32_t offset) {
    StoreToOffset(dest, base, offset - kHeapObjectTag);
  }

  // Object pool, loading from pool, etc.
  void LoadPoolPointer(Register pp);

  enum Patchability {
    kPatchable,
    kNotPatchable,
  };

  void LoadWordFromPoolOffset(Register dst, Register pp, uint32_t offset);
  intptr_t FindExternalLabel(const ExternalLabel* label,
                             Patchability patchable);
  intptr_t FindObject(const Object& obj, Patchability patchable);
  intptr_t FindImmediate(int64_t imm);
  bool CanLoadObjectFromPool(const Object& object);
  bool CanLoadImmediateFromPool(int64_t imm, Register pp);
  void LoadExternalLabel(Register dst, const ExternalLabel* label,
                         Patchability patchable, Register pp);
  void LoadObject(Register dst, const Object& obj, Register pp);
  void LoadDecodableImmediate(Register reg, int64_t imm, Register pp);
  void LoadPatchableImmediate(Register reg, int64_t imm);
  void LoadImmediate(Register reg, int64_t imm, Register pp);

  void PushObject(const Object& object, Register pp) {
    LoadObject(TMP, object, pp);
    Push(TMP);
  }

  void EnterFrame(intptr_t frame_size);
  void LeaveFrame();

  void EnterDartFrame(intptr_t frame_size);
  void LeaveDartFrame();

  void CallRuntime(const RuntimeEntry& entry, intptr_t argument_count);

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

  void AddSubHelper(OperandSize os, bool set_flags, bool subtract,
                    Register rd, Register rn, Operand o) {
    ASSERT((rd != R31) && (rn != R31));
    const Register crd = ConcreteRegister(rd);
    const Register crn = ConcreteRegister(rn);
    if (o.type() == Operand::Immediate) {
      ASSERT(rn != ZR);
      EmitAddSubImmOp(subtract ? SUBI : ADDI, crd, crn, o, os, set_flags);
    } else if (o.type() == Operand::Shifted) {
      ASSERT((rd != SP) && (rn != SP));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    } else {
      ASSERT(o.type() == Operand::Extended);
      ASSERT((rd != SP) && (rn != ZR));
      EmitAddSubShiftExtOp(subtract ? SUB : ADD, crd, crn, o, os, set_flags);
    }
  }

  void EmitAddSubImmOp(AddSubImmOp op, Register rd, Register rn,
                       Operand o, OperandSize sz, bool set_flags) {
    ASSERT((sz == kDoubleWord) || (sz == kWord));
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
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT(rn != SP);
    ASSERT((op == ANDIS) || (rd != ZR));  // op != ANDIS => rd != ZR.
    ASSERT((op != ANDIS) || (rd != SP));  // op == ANDIS => rd != SP.
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
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    ASSERT((rd != R31) && (rn != R31));
    ASSERT((rd != SP) && (rn != SP));
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
    ASSERT((sz == kDoubleWord) || (sz == kWord));
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
    const int32_t imm32 = static_cast<int32_t>(imm);
    const int32_t off = (((imm32 >> 2) << kImm19Shift) & kImm19Mask);
    return (instr & ~kImm19Mask) | off;
  }

  int64_t DecodeImm19BranchOffset(int32_t instr) {
    const int32_t off = (((instr >> kImm19Shift) & kImm19Shift) << 13) >> 13;
    return static_cast<int64_t>(off);
  }

  void EmitCompareAndBranch(CompareAndBranchOp op, Register rt, int64_t imm,
                            OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    ASSERT(Utils::IsInt(21, imm) && ((imm & 0x3) == 0));
    ASSERT((rt != SP) && (rt != R31));
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
    ASSERT(Utils::IsInt(21, imm) && ((imm & 0x3) == 0));
    const int32_t encoding =
        op |
        (static_cast<int32_t>(cond) << kCondShift) |
        (((imm >> 2) << kImm19Shift) & kImm19Mask);
    Emit(encoding);
  }

  bool CanEncodeImm19BranchOffset(int64_t offset) {
    ASSERT(Utils::IsAligned(offset, 4));
    return Utils::IsInt(19, offset);
  }

  // TODO(zra): Implement far branches. Requires loading large immediates.
  void EmitBranch(ConditionalBranchOp op, Condition cond, Label* label) {
    if (label->IsBound()) {
      const int64_t dest = label->Position() - buffer_.Size();
      ASSERT(CanEncodeImm19BranchOffset(dest));
      EmitConditionalBranch(op, cond, dest);
    } else {
      const int64_t position = buffer_.Size();
      ASSERT(CanEncodeImm19BranchOffset(position));
      EmitConditionalBranch(op, cond, label->position_);
      label->LinkTo(position);
    }
  }

  void EmitUnconditionalBranchRegOp(UnconditionalBranchRegOp op, Register rn) {
    ASSERT((rn != SP) && (rn != R31));
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

  void EmitMoveWideOp(MoveWideOp op, Register rd, uint16_t imm, int hw_idx,
                      OperandSize sz) {
    ASSERT((hw_idx >= 0) && (hw_idx <= 3));
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    const int32_t size = (sz == kDoubleWord) ? B31 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(rd) << kRdShift) |
        (static_cast<int32_t>(hw_idx) << kHWShift) |
        (static_cast<int32_t>(imm) << kImm16Shift);
    Emit(encoding);
  }

  void EmitLoadStoreReg(LoadStoreRegOp op, Register rt, Address a,
                        OperandSize sz) {
    const Register crt = ConcreteRegister(rt);
    const int32_t size = Log2OperandSizeBytes(sz);
    const int32_t encoding =
        op | (size << kSzShift) |
        (static_cast<int32_t>(crt) << kRtShift) |
        a.encoding();
    Emit(encoding);
  }

  void EmitLoadRegLiteral(LoadRegLiteralOp op, Register rt, Address a,
                          OperandSize sz) {
    ASSERT((sz == kDoubleWord) || (sz == kWord));
    ASSERT((rt != SP) && (rt != R31));
    const Register crt = ConcreteRegister(rt);
    const int32_t size = (sz == kDoubleWord) ? B30 : 0;
    const int32_t encoding =
        op | size |
        (static_cast<int32_t>(crt) << kRtShift) |
        a.encoding();
    Emit(encoding);
  }

  void EmitPCRelOp(PCRelOp op, Register rd, int64_t imm) {
    ASSERT(Utils::IsInt(21, imm));
    ASSERT((rd != R31) && (rd != SP));
    const Register crd = ConcreteRegister(rd);
    const int32_t loimm = (imm & 0x3) << 29;
    const int32_t hiimm = ((imm >> 2) << kImm19Shift) & kImm19Mask;
    const int32_t encoding =
        op | loimm | hiimm |
        (static_cast<int32_t>(crd) << kRdShift);
    Emit(encoding);
  }

  void EmitMiscDP2Source(MiscDP2SourceOp op,
                         Register rd, Register rn, Register rm,
                         OperandSize sz) {
    ASSERT((rd != SP) && (rn != SP) && (rm != SP));
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
    ASSERT((rd != SP) && (rn != SP) && (rm != SP) && (ra != SP));
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

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(Assembler);
};

}  // namespace dart

#endif  // VM_ASSEMBLER_ARM64_H_
