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

#if defined(TARGET_ARCH_ARM) || defined(TARGET_ARCH_ARM64)
DECLARE_FLAG(bool, use_far_branches);
#endif

class MemoryRegion;

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
};

// Forward declarations.
class Assembler;
class AssemblerFixup;
class AssemblerBuffer;

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
  static const int kMaxUnresolvedBranches = 20;
#else
  static const int kMaxUnresolvedBranches = 1;  // Unused on non-Intel.
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
  // incomming states are compatible.
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
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
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
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
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
#if defined(TARGET_ARCH_IA32) || defined(TARGET_ARCH_X64)
    // Variable-length instructions in ia32/x64 have unaligned immediates.
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
  static const intptr_t kMinimumGap = 32;

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

enum RestorePP { kRestoreCallerPP, kKeepCalleePP };

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

 protected:
  AssemblerBuffer buffer_;  // Contains position independent code.
  int32_t prologue_offset_;
  bool has_monomorphic_entry_;

  intptr_t unchecked_entry_offset_ = 0;

 private:
  GrowableArray<CodeComment*> comments_;
  ObjectPoolBuilder* object_pool_builder_;
};

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_ASSEMBLER_ASSEMBLER_BASE_H_
