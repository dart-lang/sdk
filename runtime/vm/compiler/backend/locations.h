// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_H_
#define RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "vm/allocation.h"
#include "vm/bitfield.h"
#include "vm/bitmap.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/constants.h"
#include "vm/cpu.h"

namespace dart {

class BaseTextBuffer;
class ConstantInstr;
class Definition;
class FlowGraphDeserializer;
class FlowGraphSerializer;
class PairLocation;
class Value;

// All unboxed integer representations.
// Format: (representation name, is unsigned, value type)
#define FOR_EACH_INTEGER_REPRESENTATION_KIND(M)                                \
  M(UnboxedUint8, true, uint8_t)                                               \
  M(UnboxedUint16, true, uint16_t)                                             \
  M(UnboxedInt32, false, int32_t)                                              \
  M(UnboxedUint32, true, uint32_t)                                             \
  M(UnboxedInt64, false, int64_t)

// All unboxed representations.
// Format: (representation name, is unsigned, value type)
#define FOR_EACH_UNBOXED_REPRESENTATION_KIND(M)                                \
  M(UnboxedDouble, false, double_t)                                            \
  M(UnboxedFloat, false, float_t)                                              \
  FOR_EACH_INTEGER_REPRESENTATION_KIND(M)                                      \
  M(UnboxedFloat32x4, false, simd128_value_t)                                  \
  M(UnboxedInt32x4, false, simd128_value_t)                                    \
  M(UnboxedFloat64x2, false, simd128_value_t)

// All representations that represent a single boxed or unboxed value.
// (Note that packed SIMD values are considered a single value here.)
// Format: (representation name, is unsigned, value type)
#define FOR_EACH_SIMPLE_REPRESENTATION_KIND(M)                                 \
  M(Tagged, false, compiler::target::word)                                     \
  M(Untagged, false, compiler::target::word)                                   \
  FOR_EACH_UNBOXED_REPRESENTATION_KIND(M)

// All representations, including sentinel and multi-value representations.
// Format: (representation name, _, _)  (only the name is guaranteed to exist)
// Ordered so that NoRepresentation is first (and thus 0 in the enum).
#define FOR_EACH_REPRESENTATION_KIND(M)                                        \
  M(NoRepresentation, _, _)                                                    \
  FOR_EACH_SIMPLE_REPRESENTATION_KIND(M)                                       \
  M(PairOfTagged, _, _)

enum Representation {
#define DECLARE_REPRESENTATION(name, __, ___) k##name,
  FOR_EACH_REPRESENTATION_KIND(DECLARE_REPRESENTATION)
#undef DECLARE_REPRESENTATION
      kNumRepresentations
};

static constexpr intptr_t kMaxLocationCount = 2;

inline intptr_t LocationCount(Representation rep) {
  switch (rep) {
    case kPairOfTagged:
      return 2;
    case kUnboxedInt64:
      return compiler::target::kWordSize == 8 ? 1 : 2;
    default:
      return 1;
  }
}

struct RepresentationUtils : AllStatic {
  // Whether the representation is for a type of unboxed integer.
  static bool IsUnboxedInteger(Representation rep);

  // Whether the representation is for a type of unboxed value.
  static bool IsUnboxed(Representation rep);

  // The size of values described by this representation.
  static size_t ValueSize(Representation rep);

  // Whether the values described by this representation are unsigned integers.
  static bool IsUnsigned(Representation rep);

  static compiler::OperandSize OperandSize(Representation rep);
};

// The representation for word-sized unboxed fields.
static constexpr Representation kUnboxedWord =
    compiler::target::kWordSize == 4 ? kUnboxedInt32 : kUnboxedInt64;
// The representation for unsigned word-sized unboxed fields.
//
// Note: kUnboxedUword is identical to kUnboxedWord until range analysis can
// handle unsigned 64-bit ranges. This means that range analysis will give
// signed results for unboxed uword field values.
static constexpr Representation kUnboxedUword = kUnboxedWord;

// 'UnboxedFfiIntPtr' should be able to hold a pointer of the target word-size.
// On a 32-bit platform, it's an unsigned 32-bit int because it should be
// zero-extended to 64-bits, not sign-extended (pointers are inherently
// unsigned).
//
// Issue(36370): Use [kUnboxedIntPtr] instead.
static constexpr Representation kUnboxedFfiIntPtr =
    compiler::target::kWordSize == 4 ? kUnboxedUint32 : kUnboxedInt64;

// The representation which can be used for native pointers. We use signed 32/64
// bit representation to be able to do arithmetic on pointers.
static constexpr Representation kUnboxedIntPtr = kUnboxedWord;

// Location objects are used to connect register allocator and code generator.
// Instruction templates used by code generator have a corresponding
// LocationSummary object which specifies expected location for every input
// and output.
// Each location is encoded as a single word: for non-constant locations
// low 4 bits denote location kind, rest is kind specific location payload
// e.g. for REGISTER kind payload is register code (value of the Register
// enumeration), constant locations contain a tagged (low 2 bits are set to 01)
// Object handle.
//
// Locations must satisfy the following invariant: if two locations' encodings
// are bitwise unequal then these two locations are guaranteed to be disjoint.
// Properties like representation belong to the value that is stored in
// the location not to the location itself.
class Location : public ValueObject {
 private:
  enum {
    // Number of bits required to encode Kind value.
    kKindBitsPos = 0,
    kKindBitsSize = 5,

    kPayloadBitsPos = kKindBitsPos + kKindBitsSize,
    kPayloadBitsSize = kBitsPerWord - kPayloadBitsPos,
  };

  static constexpr uword kInvalidLocation = 0;
  static constexpr uword kLocationTagMask = 0x3;

 public:
  static bool ParseRepresentation(const char* str, Representation* out);
  static const char* RepresentationToCString(Representation repr);

  // Constant payload can overlap with kind field so Kind values
  // have to be chosen in a way that their last 2 bits are never
  // the same as kConstantTag or kPairLocationTag.
  // Note that two locations with different kinds should never point to
  // the same place. For example kQuadStackSlot location should never intersect
  // with kDoubleStackSlot location.
  enum Kind : intptr_t {
    // This location is invalid.  Payload must be zero.
    kInvalid = 0,

    // Constant value. This location contains a tagged Object handle.
    kConstantTag = 1,

    // This location contains a tagged pointer to a PairLocation.
    kPairLocationTag = 2,

    // Unallocated location represents a location that is not fixed and can be
    // allocated by a register allocator.  Each unallocated location has
    // a policy that specifies what kind of location is suitable. Payload
    // contains register allocation policy.
    kUnallocated = 1 << 2,

    // Spill slots allocated by the register allocator.  Payload contains
    // a spill index.
    kStackSlot = 2 << 2,        // Word size slot.
    kDoubleStackSlot = 3 << 2,  // 64bit stack slot.
    kQuadStackSlot = 4 << 2,    // 128bit stack slot.

    // Register location represents a fixed register.  Payload contains
    // register code.
    kRegister = 5 << 2,

    // FpuRegister location represents a fixed fpu register.  Payload contains
    // its code.
    kFpuRegister = 6 << 2,
  };

  Location() : value_(kInvalidLocation) {
    // Verify that non-tagged location kinds do not interfere with location tags
    // (kConstantTag and kPairLocationTag).
    COMPILE_ASSERT((kInvalid & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kInvalid & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kUnallocated & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kUnallocated & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kStackSlot & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kStackSlot & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kDoubleStackSlot & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kDoubleStackSlot & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kQuadStackSlot & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kQuadStackSlot & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kRegister & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kRegister & kLocationTagMask) != kPairLocationTag);

    COMPILE_ASSERT((kFpuRegister & kLocationTagMask) != kConstantTag);
    COMPILE_ASSERT((kFpuRegister & kLocationTagMask) != kPairLocationTag);

    // Verify tags and tagmask.
    COMPILE_ASSERT((kConstantTag & kLocationTagMask) == kConstantTag);

    COMPILE_ASSERT((kPairLocationTag & kLocationTagMask) == kPairLocationTag);

    ASSERT(IsInvalid());
  }

  Location(const Location& other) : ValueObject(), value_(other.value_) {}

  Location& operator=(const Location& other) {
    value_ = other.value_;
    return *this;
  }

  bool IsInvalid() const { return value_ == kInvalidLocation; }

  // Constants.
  bool IsConstant() const { return (value_ & kConstantTag) == kConstantTag; }

  static Location Constant(const ConstantInstr* obj, int pair_index = 0) {
    ASSERT((pair_index == 0) || (pair_index == 1));
    Location loc(reinterpret_cast<uword>(obj) |
                 (pair_index != 0 ? static_cast<uword>(kPairLocationTag) : 0) |
                 static_cast<uword>(kConstantTag));
    ASSERT(obj == loc.constant_instruction());
    ASSERT(loc.pair_index() == pair_index);
    return loc;
  }

  intptr_t pair_index() const {
    ASSERT(IsConstant());
    return (value_ & kPairLocationTag) != 0 ? 1 : 0;
  }

  ConstantInstr* constant_instruction() const {
    ASSERT(IsConstant());
    return reinterpret_cast<ConstantInstr*>(value_ & ~kLocationTagMask);
  }

  const Object& constant() const;

  bool IsPairLocation() const {
    return (value_ & kLocationTagMask) == kPairLocationTag;
  }

  static Location Pair(Location first, Location second);

  PairLocation* AsPairLocation() const;

  // For pair locations, returns the ith component (for i in {0, 1}).
  Location Component(intptr_t i) const;

  // Unallocated locations.
  enum Policy {
    kAny,
    kPrefersRegister,
    kRequiresRegister,
    kRequiresFpuRegister,
    kWritableRegister,
    kSameAsFirstInput,
  };

  bool IsUnallocated() const { return kind() == kUnallocated; }

  bool IsRegisterBeneficial() { return !Equals(Any()); }

  static Location UnallocatedLocation(Policy policy) {
    return Location(kUnallocated, PolicyField::encode(policy));
  }

  // Any free register is suitable to replace this unallocated location.
  static Location Any() { return UnallocatedLocation(kAny); }

  static Location PrefersRegister() {
    return UnallocatedLocation(kPrefersRegister);
  }

  // Blocks a CPU register for the entirety of the IL instruction.
  //
  // The register value _must_ be preserved by the machine code.
  static Location RequiresRegister() {
    return UnallocatedLocation(kRequiresRegister);
  }

  static Location RequiresFpuRegister() {
    return UnallocatedLocation(kRequiresFpuRegister);
  }

  // Blocks a CPU register for the entirety of the IL instruction.
  //
  // The register value does not have to be preserved by the machine code.
  static Location WritableRegister() {
    return UnallocatedLocation(kWritableRegister);
  }

  // The location of the first input to the instruction will be
  // used to replace this unallocated location.
  static Location SameAsFirstInput() {
    return UnallocatedLocation(kSameAsFirstInput);
  }

  // Empty location. Used if there the location should be ignored.
  static Location NoLocation() { return Location(); }

  Policy policy() const {
    ASSERT(IsUnallocated());
    return PolicyField::decode(payload());
  }

  // Blocks `reg` for the entirety of the IL instruction.
  //
  // The register value does not have to be preserved by the machine code.
  // TODO(https://dartbug.com/51409): Rename to WritableRegisterLocation.
  static Location RegisterLocation(Register reg) {
    return Location(kRegister, reg);
  }

  bool IsRegister() const { return kind() == kRegister; }

  Register reg() const {
    ASSERT(IsRegister());
    return static_cast<Register>(payload());
  }

  // FpuRegister locations.
  static Location FpuRegisterLocation(FpuRegister reg) {
    return Location(kFpuRegister, reg);
  }

  bool IsFpuRegister() const { return kind() == kFpuRegister; }

  FpuRegister fpu_reg() const {
    ASSERT(IsFpuRegister());
    return static_cast<FpuRegister>(payload());
  }

  static bool IsMachineRegisterKind(Kind kind) {
    return (kind == kRegister) || (kind == kFpuRegister);
  }

  static Location MachineRegisterLocation(Kind kind, intptr_t reg) {
    if (kind == kRegister) {
      return RegisterLocation(static_cast<Register>(reg));
    } else {
      ASSERT(kind == kFpuRegister);
      return FpuRegisterLocation(static_cast<FpuRegister>(reg));
    }
  }

  bool IsMachineRegister() const { return IsMachineRegisterKind(kind()); }

  intptr_t register_code() const {
    ASSERT(IsMachineRegister());
    return static_cast<intptr_t>(payload());
  }

  static uword EncodeStackIndex(intptr_t stack_index) {
    ASSERT((-kStackIndexBias <= stack_index) &&
           (stack_index < kStackIndexBias));
    return static_cast<uword>(kStackIndexBias + stack_index);
  }

  static Location StackSlot(intptr_t stack_index, Register base) {
    uword payload = StackSlotBaseField::encode(base) |
                    StackIndexField::encode(EncodeStackIndex(stack_index));
    Location loc(kStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsStackSlot() const { return kind() == kStackSlot; }

  static Location DoubleStackSlot(intptr_t stack_index, Register base) {
    uword payload = StackSlotBaseField::encode(base) |
                    StackIndexField::encode(EncodeStackIndex(stack_index));
    Location loc(kDoubleStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsDoubleStackSlot() const { return kind() == kDoubleStackSlot; }

  static Location QuadStackSlot(intptr_t stack_index, Register base) {
    uword payload = StackSlotBaseField::encode(base) |
                    StackIndexField::encode(EncodeStackIndex(stack_index));
    Location loc(kQuadStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsQuadStackSlot() const { return kind() == kQuadStackSlot; }

  Register base_reg() const {
    ASSERT(HasStackIndex());
    return StackSlotBaseField::decode(payload());
  }

  intptr_t stack_index() const {
    ASSERT(HasStackIndex());
    // Decode stack index manually to preserve sign.
    return StackIndexField::decode(payload()) - kStackIndexBias;
  }

  bool HasStackIndex() const {
    return IsStackSlot() || IsDoubleStackSlot() || IsQuadStackSlot();
  }

  // Returns the offset from the frame pointer for stack slot locations.
  intptr_t ToStackSlotOffset() const;

  const char* Name() const;
  void PrintTo(BaseTextBuffer* f) const;
  void Print() const;
  const char* ToCString() const;

  // Compare two locations.
  bool Equals(Location other) const { return value_ == other.value_; }

  // If current location is constant might return something that
  // is not equal to any Kind.
  Kind kind() const { return KindField::decode(value_); }

  Location Copy() const;

  void Write(FlowGraphSerializer* s) const;
  static Location Read(FlowGraphDeserializer* d);

 private:
  explicit Location(uword value) : value_(value) {}

  void set_stack_index(intptr_t index) {
    ASSERT(HasStackIndex());
    value_ = PayloadField::update(
        StackIndexField::update(EncodeStackIndex(index), payload()), value_);
  }

  void set_base_reg(Register reg) {
    ASSERT(HasStackIndex());
    value_ = PayloadField::update(StackSlotBaseField::update(reg, payload()),
                                  value_);
  }

  Location(Kind kind, uword payload)
      : value_(KindField::encode(kind) | PayloadField::encode(payload)) {}

  uword payload() const { return PayloadField::decode(value_); }

  class KindField : public BitField<uword, Kind, kKindBitsPos, kKindBitsSize> {
  };
  class PayloadField
      : public BitField<uword, uword, kPayloadBitsPos, kPayloadBitsSize> {};

  // Layout for kUnallocated locations payload.
  typedef BitField<uword, Policy, 0, 3> PolicyField;

// Layout for stack slots.
#if defined(ARCH_IS_64_BIT)
  static constexpr intptr_t kBitsForBaseReg = 6;
#else
  static constexpr intptr_t kBitsForBaseReg = 5;
#endif
  static constexpr intptr_t kBitsForStackIndex =
      kPayloadBitsSize - kBitsForBaseReg;
  class StackSlotBaseField
      : public BitField<uword, Register, 0, kBitsForBaseReg> {};
  class StackIndexField
      : public BitField<uword, intptr_t, kBitsForBaseReg, kBitsForStackIndex> {
  };
  COMPILE_ASSERT(1 << kBitsForBaseReg >= kNumberOfCpuRegisters);

  static constexpr intptr_t kStackIndexBias = static_cast<intptr_t>(1)
                                              << (kBitsForStackIndex - 1);

  // Location either contains kind and payload fields or a tagged handle for
  // a constant locations. Values of enumeration Kind are selected in such a
  // way that none of them can be interpreted as a kConstant tag.
  uword value_;
};

Location LocationArgumentsDescriptorLocation();
Location LocationExceptionLocation();
Location LocationStackTraceLocation();
// Constants.
Location LocationRegisterOrConstant(Value* value);
Location LocationRegisterOrSmiConstant(
    Value* value,
    intptr_t min_value = compiler::target::kSmiMin,
    intptr_t max_value = compiler::target::kSmiMax);
Location LocationWritableRegisterOrSmiConstant(
    Value* value,
    intptr_t min_value = compiler::target::kSmiMin,
    intptr_t max_value = compiler::target::kSmiMax);
Location LocationFixedRegisterOrConstant(Value* value, Register reg);
Location LocationFixedRegisterOrSmiConstant(Value* value, Register reg);
Location LocationAnyOrConstant(Value* value);

Location LocationRemapForSlowPath(Location loc,
                                  Definition* def,
                                  intptr_t* cpu_reg_slots,
                                  intptr_t* fpu_reg_slots);

// Return a memory operand for stack slot locations.
compiler::Address LocationToStackSlotAddress(Location loc);

class PairLocation : public ZoneAllocated {
 public:
  PairLocation() {
    for (intptr_t i = 0; i < kPairLength; i++) {
      ASSERT(locations_[i].IsInvalid());
    }
  }

  intptr_t length() const { return kPairLength; }

  Location At(intptr_t i) const {
    ASSERT(i >= 0);
    ASSERT(i < kPairLength);
    return locations_[i];
  }

  void SetAt(intptr_t i, Location loc) {
    ASSERT(i >= 0);
    ASSERT(i < kPairLength);
    locations_[i] = loc;
  }

  Location* SlotAt(intptr_t i) {
    ASSERT(i >= 0);
    ASSERT(i < kPairLength);
    return &locations_[i];
  }

 private:
  static constexpr intptr_t kPairLength = 2;
  Location locations_[kPairLength];
};

template <typename T>
class SmallSet {
 public:
  SmallSet() : data_(0) {}

  explicit SmallSet(uintptr_t data) : data_(data) {}

  bool Contains(T value) const { return (data_ & ToMask(value)) != 0; }

  void Add(T value) { data_ |= ToMask(value); }

  void Remove(T value) { data_ &= ~ToMask(value); }

  bool IsEmpty() const { return data_ == 0; }

  void Clear() { data_ = 0; }

  uintptr_t data() const { return data_; }

 private:
  static uintptr_t ToMask(T value) {
    ASSERT(static_cast<uintptr_t>(value) < (kWordSize * kBitsPerByte));
    return static_cast<uintptr_t>(1) << static_cast<uintptr_t>(value);
  }

  uintptr_t data_;
};

class RegisterSet : public ValueObject {
 public:
  RegisterSet()
      : cpu_registers_(), untagged_cpu_registers_(), fpu_registers_() {
    ASSERT(kNumberOfCpuRegisters <= (kWordSize * kBitsPerByte));
    ASSERT(kNumberOfFpuRegisters <= (kWordSize * kBitsPerByte));
  }

  explicit RegisterSet(uintptr_t cpu_register_mask, uintptr_t fpu_register_mask)
      : RegisterSet() {
    AddTaggedRegisters(cpu_register_mask, fpu_register_mask);
  }

  void AddAllNonReservedRegisters(bool include_fpu_registers) {
    for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
      if ((kReservedCpuRegisters & (1 << i)) != 0u) continue;
      Add(Location::RegisterLocation(static_cast<Register>(i)));
    }

    if (include_fpu_registers) {
      for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; --i) {
        Add(Location::FpuRegisterLocation(static_cast<FpuRegister>(i)));
      }
    }
  }

  // Adds all registers which don't have a special purpose (e.g. FP, SP, PC,
  // CSP, etc.).
  void AddAllGeneralRegisters() {
    for (intptr_t i = kNumberOfCpuRegisters - 1; i >= 0; --i) {
      Register reg = static_cast<Register>(i);
      if (reg == FPREG || reg == SPREG) continue;
#if defined(TARGET_ARCH_ARM)
      if (reg == PC) continue;
#elif defined(TARGET_ARCH_ARM64)
      if (reg == R31) continue;
#elif defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
      if (reg == ZR || reg == TP || reg == GP) continue;
#endif
      Add(Location::RegisterLocation(reg));
    }

    for (intptr_t i = kNumberOfFpuRegisters - 1; i >= 0; --i) {
      Add(Location::FpuRegisterLocation(static_cast<FpuRegister>(i)));
    }
  }

  void AddAllArgumentRegisters() {
    // All (native) arguments are passed on the stack in IA32.
#if !defined(TARGET_ARCH_IA32)
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
      const Register reg = static_cast<Register>(i);
      if (IsArgumentRegister(reg)) {
        Add(Location::RegisterLocation(reg));
      }
    }
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      const FpuRegister reg = static_cast<FpuRegister>(i);
      if (IsFpuArgumentRegister(reg)) {
        Add(Location::FpuRegisterLocation(reg));
      }
    }
#endif
  }

  void AddTaggedRegisters(uintptr_t cpu_register_mask,
                          uintptr_t fpu_register_mask) {
    for (intptr_t i = 0; i < kNumberOfCpuRegisters; ++i) {
      if (Utils::TestBit(cpu_register_mask, i)) {
        const Register reg = static_cast<Register>(i);
        Add(Location::RegisterLocation(reg));
      }
    }
    for (intptr_t i = 0; i < kNumberOfFpuRegisters; ++i) {
      if (Utils::TestBit(fpu_register_mask, i)) {
        const FpuRegister reg = static_cast<FpuRegister>(i);
        Add(Location::FpuRegisterLocation(reg));
      }
    }
  }

  void Add(Location loc, Representation rep = kTagged) {
    if (loc.IsRegister()) {
      cpu_registers_.Add(loc.reg());
      if (rep != kTagged) {
        // CPU register contains an untagged value.
        MarkUntagged(loc);
      }
    } else if (loc.IsFpuRegister()) {
      fpu_registers_.Add(loc.fpu_reg());
    }
  }

  void Remove(Location loc) {
    if (loc.IsRegister()) {
      cpu_registers_.Remove(loc.reg());
    } else if (loc.IsFpuRegister()) {
      fpu_registers_.Remove(loc.fpu_reg());
    }
  }

  bool Contains(Location loc) {
    if (loc.IsRegister()) {
      return ContainsRegister(loc.reg());
    } else if (loc.IsFpuRegister()) {
      return ContainsFpuRegister(loc.fpu_reg());
    } else {
      UNREACHABLE();
      return false;
    }
  }

  void DebugPrint();

  void MarkUntagged(Location loc) {
    ASSERT(loc.IsRegister());
    untagged_cpu_registers_.Add(loc.reg());
  }

  bool HasUntaggedValues() const {
    return !untagged_cpu_registers_.IsEmpty() || !fpu_registers_.IsEmpty();
  }

  bool IsTagged(Register reg) const {
    return !untagged_cpu_registers_.Contains(reg);
  }

  bool ContainsRegister(Register reg) const {
    return cpu_registers_.Contains(reg);
  }

  bool ContainsFpuRegister(FpuRegister fpu_reg) const {
    return fpu_registers_.Contains(fpu_reg);
  }

  intptr_t CpuRegisterCount() const { return RegisterCount(cpu_registers()); }
  intptr_t FpuRegisterCount() const { return RegisterCount(fpu_registers()); }

  bool IsEmpty() const {
    return CpuRegisterCount() == 0 && FpuRegisterCount() == 0;
  }

  static intptr_t RegisterCount(intptr_t registers);
  static bool Contains(uintptr_t register_set, intptr_t reg) {
    return (register_set & (static_cast<uintptr_t>(1) << reg)) != 0;
  }

  uintptr_t cpu_registers() const { return cpu_registers_.data(); }
  uintptr_t fpu_registers() const { return fpu_registers_.data(); }

  void Clear() {
    cpu_registers_.Clear();
    fpu_registers_.Clear();
    untagged_cpu_registers_.Clear();
  }

  void Write(FlowGraphSerializer* s) const;
  explicit RegisterSet(FlowGraphDeserializer* d);

 private:
  SmallSet<Register> cpu_registers_;
  SmallSet<Register> untagged_cpu_registers_;
  SmallSet<FpuRegister> fpu_registers_;

  DISALLOW_COPY_AND_ASSIGN(RegisterSet);
};

// Specification of locations for inputs and output.
class LocationSummary : public ZoneAllocated {
 public:
  enum ContainsCall {
    // Used registers must be reserved as tmp.
    kNoCall,
    // Registers have been saved and can be used without reservation.
    kCall,
    // Registers will be saved by the callee.
    kCallCalleeSafe,
    // Used registers must be reserved as tmp.
    kCallOnSlowPath,
    // Registers used to invoke shared stub must be reserved as tmp.
    kCallOnSharedSlowPath,
    // Location is a native leaf call so any register not in the native ABI
    // callee-save (or input/output/tmp) set might get clobbered.
    kNativeLeafCall
  };

  LocationSummary(Zone* zone,
                  intptr_t input_count,
                  intptr_t temp_count,
                  LocationSummary::ContainsCall contains_call);

  intptr_t input_count() const { return num_inputs_; }

  Location in(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < num_inputs_);
    return input_locations_[index];
  }

  Location* in_slot(intptr_t index) {
    ASSERT(index >= 0);
    ASSERT(index < num_inputs_);
    return &input_locations_[index];
  }

  void set_in(intptr_t index, Location loc);

  intptr_t temp_count() const { return num_temps_; }

  Location temp(intptr_t index) const {
    ASSERT(index >= 0);
    ASSERT(index < num_temps_);
    return temp_locations_[index];
  }

  Location* temp_slot(intptr_t index) {
    ASSERT(index >= 0);
    ASSERT(index < num_temps_);
    return &temp_locations_[index];
  }

  void set_temp(intptr_t index, Location loc) {
    ASSERT(index >= 0);
    ASSERT(index < num_temps_);
    ASSERT(!always_calls() || loc.IsMachineRegister());
    temp_locations_[index] = loc;
  }

  intptr_t output_count() const { return 1; }

  Location out(intptr_t index) const {
    ASSERT(index == 0);
    return output_location_;
  }

  Location* out_slot(intptr_t index) {
    ASSERT(index == 0);
    return &output_location_;
  }

  void set_out(intptr_t index, Location loc);

  const BitmapBuilder& stack_bitmap() { return EnsureStackBitmap(); }
  void SetStackBit(intptr_t index) { EnsureStackBitmap().Set(index, true); }

  bool always_calls() const {
    return contains_call_ == kCall || contains_call_ == kCallCalleeSafe;
  }

  bool callee_safe_call() const { return contains_call_ == kCallCalleeSafe; }

  bool can_call() { return contains_call_ != kNoCall; }

  bool HasCallOnSlowPath() { return can_call() && !always_calls(); }

  bool call_on_shared_slow_path() const {
    return contains_call_ == kCallOnSharedSlowPath;
  }

  bool native_leaf_call() const { return contains_call_ == kNativeLeafCall; }

  void PrintTo(BaseTextBuffer* f) const;

  static LocationSummary* Make(Zone* zone,
                               intptr_t input_count,
                               Location out,
                               ContainsCall contains_call);

  RegisterSet* live_registers() { return &live_registers_; }

#if defined(DEBUG)
  // Debug only verification that ensures that writable registers are correctly
  // preserved on the slow path.
  void DiscoverWritableInputs();
  void CheckWritableInputs();
#endif

  void Write(FlowGraphSerializer* s) const;
  explicit LocationSummary(FlowGraphDeserializer* d);

 private:
  BitmapBuilder& EnsureStackBitmap() {
    if (stack_bitmap_ == nullptr) {
      stack_bitmap_ = new BitmapBuilder();
    }
    return *stack_bitmap_;
  }

  const intptr_t num_inputs_;
  Location* input_locations_;
  const intptr_t num_temps_;
  Location* temp_locations_;
  Location output_location_;

  BitmapBuilder* stack_bitmap_;

  const ContainsCall contains_call_;
  RegisterSet live_registers_;

#if defined(DEBUG)
  intptr_t writable_inputs_;
#endif
};

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_BACKEND_LOCATIONS_H_
