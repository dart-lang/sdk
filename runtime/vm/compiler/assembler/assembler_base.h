// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_BASE_H_
#define RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_BASE_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "platform/unaligned.h"
#include "vm/allocation.h"
#include "vm/compiler/assembler/object_pool_builder.h"
#include "vm/compiler/runtime_api.h"
#include "vm/globals.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"

namespace dart {

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64) ||                  \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
DECLARE_FLAG(bool, use_far_branches);
#endif

class MemoryRegion;
class Slot;

namespace compiler {

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
// On ARM and ARM64 branch-link family of instructions puts return address
// into a dedicated register (LR), which called code will then preserve
// manually if needed. To ensure that LR is not clobbered accidentally we
// discourage direct use of the register and instead require users to wrap
// their code in one of the macroses below, which would verify that it is
// safe to modify LR.
// We use RELEASE_ASSERT instead of ASSERT because we use LR state (tracked
// by the assembler) to generate different code sequences for write barriers
// so we would like to ensure that incorrect code will trigger an assertion
// instead of producing incorrect code.

// Class representing the state of LR register. In addition to tracking
// whether LR currently contain return address or not it also tracks
// entered frames - and whether they preserved a return address or not.
class LRState {
 public:
  LRState(const LRState&) = default;
  LRState& operator=(const LRState&) = default;

  bool LRContainsReturnAddress() const {
    RELEASE_ASSERT(!IsUnknown());
    return (state_ & kLRContainsReturnAddressMask) != 0;
  }

  LRState SetLRContainsReturnAddress(bool v) const {
    RELEASE_ASSERT(!IsUnknown());
    return LRState(frames_, v ? (state_ | 1) : (state_ & ~1));
  }

  // Returns a |LRState| representing a state after pushing current value
  // of LR on the stack. LR is assumed clobberable in the new state.
  LRState EnterFrame() const {
    RELEASE_ASSERT(!IsUnknown());
    // 1 bit is used for LR state the rest for frame states.
    constexpr auto kMaxFrames = (sizeof(state_) * kBitsPerByte) - 1;
    RELEASE_ASSERT(frames_ < kMaxFrames);
    // LSB will be clear after the shift meaning that LR can be clobbered.
    return LRState(frames_ + 1, state_ << 1);
  }

  // Returns a |LRState| representing a state after popping  LR from the stack.
  // Note that for inner frames LR would usually be assumed cloberrable
  // even after leaving a frame. Only outerframe would restore return address
  // into LR.
  LRState LeaveFrame() const {
    RELEASE_ASSERT(!IsUnknown());
    RELEASE_ASSERT(frames_ > 0);
    return LRState(frames_ - 1, state_ >> 1);
  }

  bool IsUnknown() const { return *this == Unknown(); }

  static LRState Unknown() { return LRState(kUnknownMarker, kUnknownMarker); }

  static LRState OnEntry() { return LRState(0, 1); }

  static LRState Clobbered() { return LRState(0, 0); }

  bool operator==(const LRState& other) const {
    return frames_ == other.frames_ && state_ == other.state_;
  }

 private:
  LRState(uint8_t frames, uint8_t state) : frames_(frames), state_(state) {}

  // LR state is encoded in the LSB of state_ bitvector.
  static constexpr uint8_t kLRContainsReturnAddressMask = 1;

  static constexpr uint8_t kUnknownMarker = 0xFF;

  // Number of frames on the stack or kUnknownMarker when representing
  // Unknown state.
  uint8_t frames_ = 0;

  // Bit vector with frames_ + 1 bits: LSB represents LR state, other bits
  // represent state of LR in each entered frame. Normally this value would
  // just be (1 << frames_).
  uint8_t state_ = 1;
};

// READS_RETURN_ADDRESS_FROM_LR(...) macro verifies that LR contains return
// address before allowing to use it.
#define READS_RETURN_ADDRESS_FROM_LR(block)                                    \
  do {                                                                         \
    RELEASE_ASSERT(__ lr_state().LRContainsReturnAddress());                   \
    constexpr Register LR = LR_DO_NOT_USE_DIRECTLY;                            \
    USE(LR);                                                                   \
    block;                                                                     \
  } while (0)

// WRITES_RETURN_ADDRESS_TO_LR(...) macro verifies that LR contains return
// address before allowing to write into it. LR is considered to still
// contain return address after this operation.
#define WRITES_RETURN_ADDRESS_TO_LR(block) READS_RETURN_ADDRESS_FROM_LR(block)

// CLOBBERS_LR(...) checks that LR does *not* contain return address and it is
// safe to clobber it.
#define CLOBBERS_LR(block)                                                     \
  do {                                                                         \
    RELEASE_ASSERT(!(__ lr_state().LRContainsReturnAddress()));                \
    constexpr Register LR = LR_DO_NOT_USE_DIRECTLY;                            \
    USE(LR);                                                                   \
    block;                                                                     \
  } while (0)

// SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(...) checks that LR contains return
// address, executes |block| and marks that LR can be safely clobbered
// afterwards (assuming that |block| moved LR value onto into another register).
#define SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER(block)                       \
  do {                                                                         \
    READS_RETURN_ADDRESS_FROM_LR(block);                                       \
    __ set_lr_state(__ lr_state().SetLRContainsReturnAddress(false));          \
  } while (0)

// RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(...) checks that LR does not
// contain return address, executes |block| and marks LR as containing return
// address (assuming that |block| restored LR value from another register).
#define RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR(block)                     \
  do {                                                                         \
    CLOBBERS_LR(block);                                                        \
    __ set_lr_state(__ lr_state().SetLRContainsReturnAddress(true));           \
  } while (0)

// SPILLS_LR_TO_FRAME(...) executes |block| and updates tracked LR state to
// record that we entered a frame which preserved LR. LR can be clobbered
// afterwards.
#define SPILLS_LR_TO_FRAME(block)                                              \
  do {                                                                         \
    constexpr Register LR = LR_DO_NOT_USE_DIRECTLY;                            \
    USE(LR);                                                                   \
    block;                                                                     \
    __ set_lr_state(__ lr_state().EnterFrame());                               \
  } while (0)

// RESTORE_LR(...) checks that LR does not contain return address, executes
// |block| and updates tracked LR state to record that we exited a frame.
// Whether LR contains return address or not after this operation depends on
// the frame state (only the outermost frame usually restores LR).
#define RESTORES_LR_FROM_FRAME(block)                                          \
  do {                                                                         \
    CLOBBERS_LR(block);                                                        \
    __ set_lr_state(__ lr_state().LeaveFrame());                               \
  } while (0)
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)

enum OperandSize {
  // Architecture-independent constants.
  kByte,
  kUnsignedByte,
  kTwoBytes,  // Halfword (ARM), w(ord) (Intel)
  kUnsignedTwoBytes,
  kFourBytes,  // Word (ARM), l(ong) (Intel)
  kUnsignedFourBytes,
  kEightBytes,  // DoubleWord (ARM), q(uadword) (Intel)
  // ARM-specific constants.
  kSWord,
  kDWord,
  // 32-bit ARM specific constants.
  kWordPair,
  kRegList,
  // 64-bit ARM specific constants.
  kQWord,

#if defined(HAS_SMI_63_BITS)
  kObjectBytes = kEightBytes,
#else
  kObjectBytes = kFourBytes,
#endif
};

// For declaring default sizes in AssemblerBase.
#if defined(TARGET_ARCH_IS_64_BIT)
constexpr OperandSize kWordBytes = kEightBytes;
#else
constexpr OperandSize kWordBytes = kFourBytes;
#endif

// Forward declarations.
class Assembler;
class AssemblerFixup;
class AssemblerBuffer;
class Address;
class FieldAddress;

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
class Label : public ZoneAllocated {
 public:
  Label() {}
  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
  }

  intptr_t Position() const {
    ASSERT(IsBound());
    return position_;
  }

  bool IsBound() const { return position_ != -1; }
  bool IsUnused() const { return !IsBound() && !IsLinked(); }
  bool IsLinked() const {
    return unresolved_cb_ != -1 || unresolved_cj_ != -1 ||
           unresolved_b_ != -1 || unresolved_j_ != -1 || unresolved_far_ != -1;
  }

 private:
  int32_t position_ = -1;
  void BindTo(intptr_t position) {
    ASSERT(!IsBound());
    ASSERT(!IsLinked());
    position_ = position;
    ASSERT(IsBound());
  }

  // Linked lists of unresolved forward branches, threaded through the branch
  // instructions. The offset encoded in each unresolved branch the delta to the
  // next instruction in the list, terminated with 0 delta. Each branch class
  // has a separate list because the offset range of each is different.
#define DEFINE_BRANCH_CLASS(name)                                              \
  int32_t unresolved_##name##_ = -1;                                           \
  int32_t link_##name(int32_t position) {                                      \
    ASSERT(position > unresolved_##name##_);                                   \
    int32_t offset;                                                            \
    if (unresolved_##name##_ == -1) {                                          \
      offset = 0;                                                              \
    } else {                                                                   \
      offset = position - unresolved_##name##_;                                \
      ASSERT(offset > 0);                                                      \
    }                                                                          \
    unresolved_##name##_ = position;                                           \
    return offset;                                                             \
  }
  DEFINE_BRANCH_CLASS(cb);
  DEFINE_BRANCH_CLASS(cj);
  DEFINE_BRANCH_CLASS(b);
  DEFINE_BRANCH_CLASS(j);
  DEFINE_BRANCH_CLASS(far);

  friend class MicroAssembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};
#else
class Label : public ZoneAllocated {
 public:
  Label() : position_(0), unresolved_(0) {
#ifdef DEBUG
    for (int i = 0; i < kMaxUnresolvedBranches; i++) {
      unresolved_near_positions_[i] = -1;
    }
#endif  // DEBUG
  }

  ~Label() {
    // Assert if label is being destroyed with unresolved branches pending.
    ASSERT(!IsLinked());
    ASSERT(!HasNear());
  }

  // Returns the position for bound and linked labels. Cannot be used
  // for unused labels.
  intptr_t Position() const {
    ASSERT(!IsUnused());
    return IsBound() ? -position_ - kBias : position_ - kBias;
  }

  intptr_t LinkPosition() const {
    ASSERT(IsLinked());
    return position_ - kBias;
  }

  intptr_t NearPosition() {
    ASSERT(HasNear());
    return unresolved_near_positions_[--unresolved_];
  }

  bool IsBound() const { return position_ < 0; }
  bool IsUnused() const { return position_ == 0 && unresolved_ == 0; }
  bool IsLinked() const { return position_ > 0; }
  bool HasNear() const { return unresolved_ != 0; }

 private:
#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)
  static constexpr int kMaxUnresolvedBranches = 20;
#else
  static constexpr int kMaxUnresolvedBranches = 1;  // Unused on non-Intel.
#endif
  // Zero position_ means unused (neither bound nor linked to).
  // Thus we offset actual positions by the given bias to prevent zero
  // positions from occurring.
  // Note: we use target::kWordSize as a bias because on ARM
  // there are assertions that check that distance is aligned.
  static constexpr int kBias = 4;

  intptr_t position_;
  intptr_t unresolved_;
  intptr_t unresolved_near_positions_[kMaxUnresolvedBranches];
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  // On ARM/ARM64 we track LR state: whether it contains return address or
  // whether it can be clobbered. To make sure that our tracking it correct
  // for non linear code sequences we additionally verify at labels that
  // incoming states are compatible.
  LRState lr_state_ = LRState::Unknown();

  void UpdateLRState(LRState new_state) {
    if (lr_state_.IsUnknown()) {
      lr_state_ = new_state;
    } else {
      RELEASE_ASSERT(lr_state_ == new_state);
    }
  }
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)

  void Reinitialize() { position_ = 0; }

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  void BindTo(intptr_t position, LRState lr_state)
#else
  void BindTo(intptr_t position)
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  {
    ASSERT(!IsBound());
    ASSERT(!HasNear());
    position_ = -position - kBias;
    ASSERT(IsBound());
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    UpdateLRState(lr_state);
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  }

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  void LinkTo(intptr_t position, LRState lr_state)
#else
  void LinkTo(intptr_t position)
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  {
    ASSERT(!IsBound());
    position_ = position + kBias;
    ASSERT(IsLinked());
#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
    UpdateLRState(lr_state);
#endif  // defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
  }

  void NearLinkTo(intptr_t position) {
    ASSERT(!IsBound());
    ASSERT(unresolved_ < kMaxUnresolvedBranches);
    unresolved_near_positions_[unresolved_++] = position;
  }

  friend class Assembler;
  DISALLOW_COPY_AND_ASSIGN(Label);
};
#endif

// External labels keep a function pointer to allow them
// to be called from code generated by the assembler.
class ExternalLabel : public ValueObject {
 public:
  explicit ExternalLabel(uword address) : address_(address) {}

  bool is_resolved() const { return address_ != 0; }
  uword address() const {
    ASSERT(is_resolved());
    return address_;
  }

 private:
  const uword address_;
};

// Assembler fixups are positions in generated code that hold relocation
// information that needs to be processed before finalizing the code
// into executable memory.
class AssemblerFixup : public ZoneAllocated {
 public:
  virtual void Process(const MemoryRegion& region, intptr_t position) = 0;

  virtual bool IsPointerOffset() const = 0;

  // It would be ideal if the destructor method could be made private,
  // but the g++ compiler complains when this is subclassed.
  virtual ~AssemblerFixup() { UNREACHABLE(); }

 private:
  AssemblerFixup* previous_;
  intptr_t position_;

  AssemblerFixup* previous() const { return previous_; }
  void set_previous(AssemblerFixup* previous) { previous_ = previous; }

  intptr_t position() const { return position_; }
  void set_position(intptr_t position) { position_ = position; }

  friend class AssemblerBuffer;
};

// Assembler buffers are used to emit binary code. They grow on demand.
class AssemblerBuffer : public ValueObject {
 public:
  AssemblerBuffer();
  ~AssemblerBuffer();

  // Basic support for emitting, loading, and storing.
  template <typename T>
  void Emit(T value) {
    ASSERT(HasEnsuredCapacity());
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
    // Instruction parcels in RISC-V are only 2-byte aligned.
    StoreUnaligned(reinterpret_cast<T*>(cursor_), value);
#else
    // Other architecture have aligned, fixed-length instructions.
    *reinterpret_cast<T*>(cursor_) = value;
#endif
    cursor_ += sizeof(T);
  }

  template <typename T>
  void Remit() {
    ASSERT(Size() >= static_cast<intptr_t>(sizeof(T)));
    cursor_ -= sizeof(T);
  }

  // Return address to code at |position| bytes.
  uword Address(intptr_t position) { return contents_ + position; }

  template <typename T>
  T Load(intptr_t position) {
    ASSERT(position >= 0 &&
           position <= (Size() - static_cast<intptr_t>(sizeof(T))));
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
    // Instruction parcels in RISC-V are only 2-byte aligned.
    return LoadUnaligned(reinterpret_cast<T*>(contents_ + position));
#else
    // Other architecture have aligned, fixed-length instructions.
    return *reinterpret_cast<T*>(contents_ + position);
#endif
  }

  template <typename T>
  void Store(intptr_t position, T value) {
    ASSERT(position >= 0 &&
           position <= (Size() - static_cast<intptr_t>(sizeof(T))));
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64) ||                   \
    defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
    // Instruction parcels in RISC-V are only 2-byte aligned.
    StoreUnaligned(reinterpret_cast<T*>(contents_ + position), value);
#else
    // Other architecture have aligned, fixed-length instructions.
    *reinterpret_cast<T*>(contents_ + position) = value;
#endif
  }

  const ZoneGrowableArray<intptr_t>& pointer_offsets() const {
#if defined(DEBUG)
    ASSERT(fixups_processed_);
#endif
    return *pointer_offsets_;
  }

#if defined(TARGET_ARCH_IA32)
  // Emit an object pointer directly in the code.
  void EmitObject(const Object& object);
#endif

  // Emit a fixup at the current location.
  void EmitFixup(AssemblerFixup* fixup) {
    fixup->set_previous(fixup_);
    fixup->set_position(Size());
    fixup_ = fixup;
  }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const;

  // Get the size of the emitted code.
  intptr_t Size() const { return cursor_ - contents_; }
  uword contents() const { return contents_; }

  // Copy the assembled instructions into the specified memory block
  // and apply all fixups.
  void FinalizeInstructions(const MemoryRegion& region);

  // To emit an instruction to the assembler buffer, the EnsureCapacity helper
  // must be used to guarantee that the underlying data area is big enough to
  // hold the emitted instruction. Usage:
  //
  //     AssemblerBuffer buffer;
  //     AssemblerBuffer::EnsureCapacity ensured(&buffer);
  //     ... emit bytes for single instruction ...

#if defined(DEBUG)
  class EnsureCapacity : public ValueObject {
   public:
    explicit EnsureCapacity(AssemblerBuffer* buffer);
    ~EnsureCapacity();

   private:
    AssemblerBuffer* buffer_;
    intptr_t gap_;

    intptr_t ComputeGap() { return buffer_->Capacity() - buffer_->Size(); }
  };

  bool has_ensured_capacity_;
  bool HasEnsuredCapacity() const { return has_ensured_capacity_; }
#else
  class EnsureCapacity : public ValueObject {
   public:
    explicit EnsureCapacity(AssemblerBuffer* buffer) {
      if (buffer->cursor() >= buffer->limit()) buffer->ExtendCapacity();
    }
  };

  // When building the C++ tests, assertion code is enabled. To allow
  // asserting that the user of the assembler buffer has ensured the
  // capacity needed for emitting, we add a dummy method in non-debug mode.
  bool HasEnsuredCapacity() const { return true; }
#endif

  // Returns the position in the instruction stream.
  intptr_t GetPosition() const { return cursor_ - contents_; }

  void Reset() { cursor_ = contents_; }

 private:
  // The limit is set to kMinimumGap bytes before the end of the data area.
  // This leaves enough space for the longest possible instruction and allows
  // for a single, fast space check per instruction.
  static constexpr intptr_t kMinimumGap = 32;

  uword contents_;
  uword cursor_;
  uword limit_;
  AssemblerFixup* fixup_;
  ZoneGrowableArray<intptr_t>* pointer_offsets_;
#if defined(DEBUG)
  bool fixups_processed_;
#endif

  uword cursor() const { return cursor_; }
  uword limit() const { return limit_; }
  intptr_t Capacity() const {
    ASSERT(limit_ >= contents_);
    return (limit_ - contents_) + kMinimumGap;
  }

  // Process the fixup chain.
  void ProcessFixups(const MemoryRegion& region);

  // Compute the limit based on the data area and the capacity. See
  // description of kMinimumGap for the reasoning behind the value.
  static uword ComputeLimit(uword data, intptr_t capacity) {
    return data + capacity - kMinimumGap;
  }

  void ExtendCapacity();

  friend class AssemblerFixup;
};

class AssemblerBase : public StackResource {
 public:
  explicit AssemblerBase(ObjectPoolBuilder* object_pool_builder)
      : StackResource(ThreadState::Current()),
        prologue_offset_(-1),
        has_monomorphic_entry_(false),
        object_pool_builder_(object_pool_builder) {}
  virtual ~AssemblerBase();

  // Used for near/far jumps on IA32/X64, ignored for ARM.
  enum JumpDistance : bool {
    kFarJump = false,
    kNearJump = true,
  };

  intptr_t CodeSize() const { return buffer_.Size(); }

  uword CodeAddress(intptr_t offset) { return buffer_.Address(offset); }

  bool HasObjectPoolBuilder() const { return object_pool_builder_ != nullptr; }
  ObjectPoolBuilder& object_pool_builder() { return *object_pool_builder_; }

  intptr_t prologue_offset() const { return prologue_offset_; }
  bool has_monomorphic_entry() const { return has_monomorphic_entry_; }

  void Comment(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);
  static bool EmittingComments();

  virtual void Breakpoint() = 0;

  virtual void SmiTag(Register r) = 0;

  // If Smis are compressed and the Smi value in dst is non-negative, ensures
  // the upper bits are cleared. If Smis are not compressed, is a no-op.
  //
  // Since this operation only affects the unused upper bits when Smis are
  // compressed, it can be used on registers not allocated as writable.
  //
  // The behavior on the upper bits of signed compressed Smis is undefined.
#if defined(DART_COMPRESSED_POINTERS)
  virtual void ExtendNonNegativeSmi(Register dst) {
    // Default to sign extension and allow architecture-specific assemblers
    // where an alternative like zero-extension is preferred to override this.
    ExtendValue(dst, dst, kObjectBytes);
  }
#else
  void ExtendNonNegativeSmi(Register dst) {}
#endif

  // Extends a value of size sz in src to a value of size kWordBytes in dst.
  // That is, bits in the source register that are not part of the sz-sized
  // value are ignored, and if sz is signed, then the value is sign extended.
  //
  // Produces no instructions if dst and src are the same and sz is kWordBytes.
  virtual void ExtendValue(Register dst, Register src, OperandSize sz) = 0;

  // Extends a value of size sz in src to a tagged Smi value in dst.
  // That is, bits in the source register that are not part of the sz-sized
  // value are ignored, and if sz is signed, then the value is sign extended.
  virtual void ExtendAndSmiTagValue(Register dst,
                                    Register src,
                                    OperandSize sz) {
    ExtendValue(dst, src, sz);
    SmiTag(dst);
  }

  // Move the contents of src into dst.
  //
  // Produces no instructions if dst and src are the same.
  virtual void MoveRegister(Register dst, Register src) {
    ExtendValue(dst, src, kWordBytes);
  }

  // Move the contents of src into dst and tag the value in dst as a Smi.
  virtual void MoveAndSmiTagRegister(Register dst, Register src) {
    ExtendAndSmiTagValue(dst, src, kWordBytes);
  }

  // Inlined allocation in new space of an instance of an object whose instance
  // size is known at compile time with class ID 'cid'. The generated code has
  // no runtime calls. Jump to 'failure' if the instance cannot be allocated
  // here and should be done via runtime call instead.
  //
  // ObjectPtr to allocated instance is returned in 'instance_reg'.
  //
  // WARNING: The caller is responsible for initializing all GC-visible fields
  // of the object other than the tags field, which is initialized here.
  virtual void TryAllocateObject(intptr_t cid,
                                 intptr_t instance_size,
                                 Label* failure,
                                 JumpDistance distance,
                                 Register instance_reg,
                                 Register temp) = 0;

  // An alternative version of TryAllocateObject that takes a Class object
  // and passes the class id and instance size to TryAllocateObject along with
  // the other arguments.
  void TryAllocate(const Class& cls,
                   Label* failure,
                   JumpDistance distance,
                   Register instance_reg,
                   Register temp) {
    TryAllocateObject(target::Class::GetId(cls),
                      target::Class::GetInstanceSize(cls), failure, distance,
                      instance_reg, temp);
  }

  virtual void LoadFromOffset(Register dst,
                              const Address& address,
                              OperandSize sz = kWordBytes) = 0;
  // Does not use write barriers, use StoreIntoObject instead for boxed fields.
  virtual void StoreToOffset(Register src,
                             const Address& address,
                             OperandSize sz = kWordBytes) = 0;

  virtual void BranchIfSmi(Register reg,
                           Label* label,
                           JumpDistance distance = kFarJump) = 0;

  virtual void ArithmeticShiftRightImmediate(Register reg, intptr_t shift) = 0;
  virtual void CompareWords(Register reg1,
                            Register reg2,
                            intptr_t offset,
                            Register count,
                            Register temp,
                            Label* equals) = 0;

  enum CanBeSmi {
    kValueCanBeSmi,
    kValueIsNotSmi,
  };

  enum MemoryOrder {
    // All previous writes to memory in this thread must be visible to other
    // threads. Currently, only used for lazily populating hash indices in
    // shared const maps and sets.
    kRelease,

    // All other stores.
    kRelaxedNonAtomic,
  };

  virtual void LoadAcquire(Register reg,
                           Register address,
                           int32_t offset = 0,
                           OperandSize size = kWordBytes) = 0;

  virtual void LoadFieldAddressForOffset(Register reg,
                                         Register base,
                                         int32_t offset) = 0;

  virtual void LoadField(Register dst, const FieldAddress& address) = 0;
  virtual void LoadFieldFromOffset(Register reg,
                                   Register base,
                                   int32_t offset,
                                   OperandSize = kWordBytes) = 0;
  void LoadFromSlot(Register dst, Register base, const Slot& slot);

  virtual void StoreIntoObject(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      CanBeSmi can_be_smi = kValueCanBeSmi,
      MemoryOrder memory_order = kRelaxedNonAtomic) = 0;
  virtual void StoreIntoObjectNoBarrier(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      MemoryOrder memory_order = kRelaxedNonAtomic) = 0;
  // For native unboxed slots, both methods are the same, as no write barrier
  // is needed.
  void StoreToSlot(Register src, Register base, const Slot& slot);
  void StoreToSlotNoBarrier(Register src, Register base, const Slot& slot);

  // Loads a Smi, handling sign extension appropriately when compressed.
  // In DEBUG mode, also checks that the loaded value is a Smi and halts if not.
  virtual void LoadCompressedSmi(Register dst, const Address& slot) = 0;

  // Install pure virtual methods if using compressed pointers, to ensure that
  // these methods are overridden. If there are no compressed pointers, forward
  // to the uncompressed version.
#if defined(DART_COMPRESSED_POINTERS)
  virtual void LoadAcquireCompressed(Register dst,
                                     Register address,
                                     int32_t offset = 0) = 0;
  virtual void LoadCompressedField(Register dst,
                                   const FieldAddress& address) = 0;
  virtual void LoadCompressedFieldFromOffset(Register dst,
                                             Register base,
                                             int32_t offset) = 0;
  virtual void StoreCompressedIntoObject(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      CanBeSmi can_be_smi = kValueCanBeSmi,
      MemoryOrder memory_order = kRelaxedNonAtomic) = 0;
  virtual void StoreCompressedIntoObjectNoBarrier(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      MemoryOrder memory_order = kRelaxedNonAtomic) = 0;
#else
  virtual void LoadAcquireCompressed(Register dst,
                                     Register address,
                                     int32_t offset = 0) {
    LoadAcquire(dst, address, offset);
  }
  virtual void LoadCompressedField(Register dst, const FieldAddress& address) {
    LoadField(dst, address);
  }
  virtual void LoadCompressedFieldFromOffset(Register dst,
                                             Register base,
                                             int32_t offset) {
    LoadFieldFromOffset(dst, base, offset);
  }
  virtual void StoreCompressedIntoObject(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      CanBeSmi can_be_smi = kValueCanBeSmi,
      MemoryOrder memory_order = kRelaxedNonAtomic) {
    StoreIntoObject(object, dest, value, can_be_smi);
  }
  virtual void StoreCompressedIntoObjectNoBarrier(
      Register object,      // Object we are storing into.
      const Address& dest,  // Where we are storing into.
      Register value,       // Value we are storing.
      MemoryOrder memory_order = kRelaxedNonAtomic) {
    StoreIntoObjectNoBarrier(object, dest, value);
  }
#endif  // defined(DART_COMPRESSED_POINTERS)

  virtual void StoreRelease(Register src,
                            Register address,
                            int32_t offset = 0) = 0;

  // Truncates upper bits.
  virtual void LoadInt32FromBoxOrSmi(Register result, Register value) = 0;

#if !defined(TARGET_ARCH_IS_32_BIT)
  virtual void LoadInt64FromBoxOrSmi(Register result, Register value) = 0;
#endif

  // Truncates upper bits on 32 bit archs.
  void LoadWordFromBoxOrSmi(Register result, Register value) {
#if defined(TARGET_ARCH_IS_32_BIT)
    LoadInt32FromBoxOrSmi(result, value);
#else
    LoadInt64FromBoxOrSmi(result, value);
#endif
  }

  // Loads nullability from an AbstractType [type] to [dst].
  void LoadAbstractTypeNullability(Register dst, Register type);
  // Loads nullability from an AbstractType [type] and compares it
  // to [value]. Clobbers [scratch].
  void CompareAbstractTypeNullabilityWith(Register type,
                                          /*Nullability*/ int8_t value,
                                          Register scratch);

  virtual void CompareImmediate(Register reg,
                                target::word imm,
                                OperandSize width = kWordBytes) = 0;

  virtual void CompareWithMemoryValue(Register value,
                                      Address address,
                                      OperandSize size = kWordBytes) = 0;

  virtual void AndImmediate(Register dst, target::word imm) = 0;

  virtual void LsrImmediate(Register dst, int32_t shift) = 0;

  virtual void MulImmediate(Register dst,
                            target::word imm,
                            OperandSize = kWordBytes) = 0;

  // If src2 == kNoRegister, dst = dst & src1, otherwise dst = src1 & src2.
  virtual void AndRegisters(Register dst,
                            Register src1,
                            Register src2 = kNoRegister) = 0;

  // dst = dst << shift. On some architectures, we must use a specific register
  // for the shift, so either the shift register must be that specific register
  // or the architecture must define a TMP register, which is clobbered.
  virtual void LslRegister(Register dst, Register shift) = 0;

  // Performs CombineHashes from runtime/vm/hash.h on the hashes contained in
  // dst and other. Puts the result in dst. Clobbers other.
  //
  // Note: Only uses the lower 32 bits of the hashes and returns a 32 bit hash.
  virtual void CombineHashes(Register dst, Register other) = 0;
  // Performs FinalizeHash from runtime/vm/hash.h on the hash contained in
  // dst. May clobber scratch if provided, otherwise may clobber TMP.
  //
  // Note: Only uses the lower 32 bits of the hash and returns a 32 bit hash.
  void FinalizeHash(Register hash, Register scratch = TMP) {
    return FinalizeHashForSize(/*bit_size=*/kBitsPerInt32, hash, scratch);
  }
  // Performs FinalizeHash from runtime/vm/hash.h on the hash contained in
  // dst and returns the result, masked to a maximum of [bit_size] bits.
  // May clobber scratch if provided, otherwise may clobber TMP.
  //
  // Note: Only uses the lower 32 bits of the hash. Since the underlying
  // algorithm produces 32-bit values, assumes 0 < [bit_size] <= 32.
  virtual void FinalizeHashForSize(intptr_t bit_size,
                                   Register hash,
                                   Register scratch = TMP) = 0;

  void LoadTypeClassId(Register dst, Register src);

  virtual void EnsureHasClassIdInDEBUG(intptr_t cid,
                                       Register src,
                                       Register scratch,
                                       bool can_be_null = false) = 0;

  intptr_t InsertAlignedRelocation(BSS::Relocation reloc);

  void Unimplemented(const char* message);
  void Untested(const char* message);
  void Unreachable(const char* message);
  void Stop(const char* message);

  void FinalizeInstructions(const MemoryRegion& region) {
    buffer_.FinalizeInstructions(region);
  }

  // Count the fixups that produce a pointer offset, without processing
  // the fixups.
  intptr_t CountPointerOffsets() const { return buffer_.CountPointerOffsets(); }

  const ZoneGrowableArray<intptr_t>& GetPointerOffsets() const {
    return buffer_.pointer_offsets();
  }

  class CodeComment : public ZoneAllocated {
   public:
    CodeComment(intptr_t pc_offset, const String& comment)
        : pc_offset_(pc_offset), comment_(comment) {}

    intptr_t pc_offset() const { return pc_offset_; }
    const String& comment() const { return comment_; }

   private:
    intptr_t pc_offset_;
    const String& comment_;

    DISALLOW_COPY_AND_ASSIGN(CodeComment);
  };

  const GrowableArray<CodeComment*>& comments() const { return comments_; }

  void BindUncheckedEntryPoint() {
    ASSERT(unchecked_entry_offset_ == 0);
    unchecked_entry_offset_ = CodeSize();
  }

  // Returns the offset (from the very beginning of the instructions) to the
  // unchecked entry point (incl. prologue/frame setup, etc.).
  intptr_t UncheckedEntryOffset() const { return unchecked_entry_offset_; }

  enum RangeCheckCondition {
    kIfNotInRange = 0,
    kIfInRange = 1,
  };

  // Jumps to [target] if [condition] is satisfied.
  //
  // [low] and [high] are inclusive.
  // If [temp] is kNoRegister, then [value] is overwritten.
  // Note: Using a valid [temp] register generates an additional
  //       instruction on x64/ia32.
  virtual void RangeCheck(Register value,
                          Register temp,
                          intptr_t low,
                          intptr_t high,
                          RangeCheckCondition condition,
                          Label* target) = 0;

 protected:
  AssemblerBuffer buffer_;  // Contains position independent code.
  int32_t prologue_offset_;
  bool has_monomorphic_entry_;

  intptr_t unchecked_entry_offset_ = 0;

 private:
  GrowableArray<CodeComment*> comments_;
  ObjectPoolBuilder* object_pool_builder_;
};

// For leaf runtime calls. For non-leaf runtime calls, use
// Assembler::CallRuntime.
class LeafRuntimeScope : public ValueObject {
 public:
  // Enters a frame, saves registers, and aligns the stack according to the C
  // ABI.
  //
  // If [preserve_registers] is false, only registers normally preserved at a
  // Dart call will be preserved (SP, FP, THR, PP, CODE_REG, RA). Suitable for
  // use in IL instructions marked with LocationSummary::kCall.
  // If [preserve registers] is true, all registers allocatable by Dart (roughly
  // everything but TMP, TMP2) will be preserved. Suitable for non-call IL
  // instructions like the write barrier.
  LeafRuntimeScope(Assembler* assembler,
                   intptr_t frame_size,
                   bool preserve_registers);

  // Restores registers and leaves the frame.
  ~LeafRuntimeScope();

  // Sets the current tag, calls the runtime function, and restores the current
  // tag.
  void Call(const RuntimeEntry& entry, intptr_t argument_count);

 private:
  Assembler* const assembler_;
  const bool preserve_registers_;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_BASE_H_
