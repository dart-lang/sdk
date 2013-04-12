// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LOCATIONS_H_
#define VM_LOCATIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/bitfield.h"

namespace dart {

class BufferFormatter;
class Value;


enum Representation {
  kNoRepresentation,
  kTagged,
  kUntagged,
  kUnboxedDouble,
  kUnboxedMint,
  kUnboxedFloat32x4,
  kUnboxedUint32x4,
  kNumRepresentations
};


// Location objects are used to connect register allocator and code generator.
// Instruction templates used by code generator have a corresponding
// LocationSummary object which specifies expected location for every input
// and output.
// Each location is encoded as a single word: for non-constant locations
// low 3 bits denote location kind, rest is kind specific location payload
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
    kBitsForKind = 4,
    kBitsForPayload = kWordSize * kBitsPerByte - kBitsForKind,
  };

  static const uword kInvalidLocation = 0;
  static const uword kConstantMask = 0x3;

  static const intptr_t kMachineRegisterMask = 0x6;
  static const intptr_t kMachineRegister = 0x6;

 public:
  // Constant payload can overlap with kind field so Kind values
  // have to be chosen in a way that their last 2 bits are never
  // the same as kConstant.
  // Note that two locations with different kinds should never point to
  // the same place. For example kQuadStackSlot location should never intersect
  // with kDoubleStackSlot location.
  enum Kind {
    // This location is invalid.  Payload must be zero.
    kInvalid = 0,

    // Constant value. This location contains a tagged Object handle.
    kConstant = 1,

    // Unallocated location represents a location that is not fixed and can be
    // allocated by a register allocator.  Each unallocated location has
    // a policy that specifies what kind of location is suitable. Payload
    // contains register allocation policy.
    kUnallocated = 2,

    // Spill slots allocated by the register allocator.  Payload contains
    // a spill index.
    kStackSlot = 3,  // Word size slot.
    kDoubleStackSlot = 4,  // 64bit stack slot.
    kQuadStackSlot = 8,  // 128bit stack slot.

    // Register location represents a fixed register.  Payload contains
    // register code.
    kRegister = 6,

    // FpuRegister location represents a fixed fpu register.  Payload contains
    // its code.
    kFpuRegister = 7,
  };

  Location() : value_(kInvalidLocation) {
    ASSERT(IsInvalid());
  }

  Location(const Location& other) : ValueObject(), value_(other.value_) { }

  Location& operator=(const Location& other) {
    value_ = other.value_;
    return *this;
  }

  bool IsInvalid() const {
    return value_ == kInvalidLocation;
  }

  // Constants.
  bool IsConstant() const {
    ASSERT((kConstant & kConstantMask) == kConstant);
    return (value_ & kConstantMask) == kConstant;
  }

  static Location Constant(const Object& obj) {
    Location loc(reinterpret_cast<uword>(&obj) | kConstant);
    ASSERT(&obj == &loc.constant());
    return loc;
  }

  const Object& constant() const {
    ASSERT(IsConstant());
    return *reinterpret_cast<const Object*>(value_ & ~kConstantMask);
  }

  // Unallocated locations.
  enum Policy {
    kAny,
    kPrefersRegister,
    kRequiresRegister,
    kRequiresFpuRegister,
    kWritableRegister,
    kSameAsFirstInput,
  };

  bool IsUnallocated() const {
    return kind() == kUnallocated;
  }

  bool IsRegisterBeneficial() {
    return !Equals(Any());
  }

  static Location UnallocatedLocation(Policy policy) {
    return Location(kUnallocated, PolicyField::encode(policy));
  }

  // Any free register is suitable to replace this unallocated location.
  static Location Any() {
    return UnallocatedLocation(kAny);
  }

  static Location PrefersRegister() {
    return UnallocatedLocation(kPrefersRegister);
  }

  static Location RequiresRegister() {
    return UnallocatedLocation(kRequiresRegister);
  }

  static Location RequiresFpuRegister() {
    return UnallocatedLocation(kRequiresFpuRegister);
  }

  static Location WritableRegister() {
    return UnallocatedLocation(kWritableRegister);
  }

  // The location of the first input to the instruction will be
  // used to replace this unallocated location.
  static Location SameAsFirstInput() {
    return UnallocatedLocation(kSameAsFirstInput);
  }

  // Empty location. Used if there the location should be ignored.
  static Location NoLocation() {
    return Location();
  }

  Policy policy() const {
    ASSERT(IsUnallocated());
    return PolicyField::decode(payload());
  }

  // Register locations.
  static Location RegisterLocation(Register reg) {
    return Location(kRegister, reg);
  }

  bool IsRegister() const {
    return kind() == kRegister;
  }

  Register reg() const {
    ASSERT(IsRegister());
    return static_cast<Register>(payload());
  }

  // FpuRegister locations.
  static Location FpuRegisterLocation(FpuRegister reg) {
    return Location(kFpuRegister, reg);
  }

  bool IsFpuRegister() const {
    return kind() == kFpuRegister;
  }

  FpuRegister fpu_reg() const {
    ASSERT(IsFpuRegister());
    return static_cast<FpuRegister>(payload());
  }

  static bool IsMachineRegisterKind(Kind kind) {
    return (kind & kMachineRegisterMask) == kMachineRegister;
  }

  static Location MachineRegisterLocation(Kind kind,
                                          intptr_t reg) {
    if (kind == kRegister) {
      return RegisterLocation(static_cast<Register>(reg));
    } else {
      ASSERT(kind == kFpuRegister);
      return FpuRegisterLocation(static_cast<FpuRegister>(reg));
    }
  }

  bool IsMachineRegister() const {
    return IsMachineRegisterKind(kind());
  }

  intptr_t register_code() const {
    ASSERT(IsMachineRegister());
    return static_cast<intptr_t>(payload());
  }

  static uword EncodeStackIndex(intptr_t stack_index) {
    ASSERT((-kStackIndexBias <= stack_index) &&
           (stack_index < kStackIndexBias));
    return static_cast<uword>(kStackIndexBias + stack_index);
  }

  // Spill slots.
  static Location StackSlot(intptr_t stack_index) {
    uword payload = EncodeStackIndex(stack_index);
    Location loc(kStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsStackSlot() const {
    return kind() == kStackSlot;
  }

  static Location DoubleStackSlot(intptr_t stack_index) {
    uword payload = EncodeStackIndex(stack_index);
    Location loc(kDoubleStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsDoubleStackSlot() const {
    return kind() == kDoubleStackSlot;
  }

  static Location QuadStackSlot(intptr_t stack_index) {
    uword payload = EncodeStackIndex(stack_index);
    Location loc(kQuadStackSlot, payload);
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsQuadStackSlot() const {
    return kind() == kQuadStackSlot;
  }

  intptr_t stack_index() const {
    ASSERT(IsStackSlot() || IsDoubleStackSlot() || IsQuadStackSlot());
    // Decode stack index manually to preserve sign.
    return payload() - kStackIndexBias;
  }

  // Return a memory operand for stack slot locations.
  Address ToStackSlotAddress() const;

  // Constants.
  static Location RegisterOrConstant(Value* value);
  static Location RegisterOrSmiConstant(Value* value);
  static Location FixedRegisterOrConstant(Value* value, Register reg);
  static Location FixedRegisterOrSmiConstant(Value* value, Register reg);
  static Location AnyOrConstant(Value* value);

  const char* Name() const;
  void PrintTo(BufferFormatter* f) const;
  void Print() const;

  // Compare two locations.
  bool Equals(Location other) const {
    return value_ == other.value_;
  }

  // If current location is constant might return something that
  // is not equal to any Kind.
  Kind kind() const {
    return KindField::decode(value_);
  }

 private:
  explicit Location(uword value) : value_(value) { }

  Location(Kind kind, uword payload)
      : value_(KindField::encode(kind) | PayloadField::encode(payload)) { }

  uword payload() const {
    return PayloadField::decode(value_);
  }

  typedef BitField<Kind, 0, kBitsForKind> KindField;
  typedef BitField<uword, kBitsForKind, kBitsForPayload> PayloadField;

  // Layout for kUnallocated locations payload.
  typedef BitField<Policy, 0, 3> PolicyField;

  // Layout for stack slots.
  static const intptr_t kStackIndexBias =
      static_cast<intptr_t>(1) << (kBitsForPayload - 1);

  // Location either contains kind and payload fields or a tagged handle for
  // a constant locations. Values of enumeration Kind are selected in such a
  // way that none of them can be interpreted as a kConstant tag.
  uword value_;
};


class RegisterSet : public ValueObject {
 public:
  RegisterSet() : cpu_registers_(0), fpu_registers_(0) {
    ASSERT(kNumberOfCpuRegisters <= (kWordSize * kBitsPerByte));
    ASSERT(kNumberOfFpuRegisters <= (kWordSize * kBitsPerByte));
  }


  void Add(Location loc) {
    if (loc.IsRegister()) {
      cpu_registers_ |= (1 << loc.reg());
    } else if (loc.IsFpuRegister()) {
      fpu_registers_ |= (1 << loc.fpu_reg());
    }
  }

  void Remove(Location loc) {
    if (loc.IsRegister()) {
      cpu_registers_ &= ~(1 << loc.reg());
    } else if (loc.IsFpuRegister()) {
      fpu_registers_ &= ~(1 << loc.fpu_reg());
    }
  }

  bool ContainsRegister(Register reg) const {
    return (cpu_registers_ & (1 << reg)) != 0;
  }

  bool ContainsFpuRegister(FpuRegister fpu_reg) const {
    return (fpu_registers_ & (1 << fpu_reg)) != 0;
  }

  intptr_t fpu_regs_count() const {
    intptr_t count = 0;
    for (intptr_t reg_idx = 0; reg_idx < kNumberOfFpuRegisters; reg_idx++) {
      if (ContainsFpuRegister(static_cast<FpuRegister>(reg_idx))) {
        count++;
      }
    }
    return count;
  }

  intptr_t cpu_registers() const { return cpu_registers_; }
  intptr_t fpu_registers() const { return fpu_registers_; }

 private:
  intptr_t cpu_registers_;
  intptr_t fpu_registers_;

  DISALLOW_COPY_AND_ASSIGN(RegisterSet);
};


// Specification of locations for inputs and output.
class LocationSummary : public ZoneAllocated {
 public:
  enum ContainsCall {
    kNoCall,
    kCall,
    kCallOnSlowPath
  };

  LocationSummary(intptr_t input_count,
                  intptr_t temp_count,
                  LocationSummary::ContainsCall contains_call);

  intptr_t input_count() const {
    return input_locations_.length();
  }

  Location in(intptr_t index) const {
    return input_locations_[index];
  }

  Location* in_slot(intptr_t index) {
    return &input_locations_[index];
  }

  void set_in(intptr_t index, Location loc) {
    ASSERT(!always_calls() || loc.IsMachineRegister());
    input_locations_[index] = loc;
  }

  intptr_t temp_count() const {
    return temp_locations_.length();
  }

  Location temp(intptr_t index) const {
    return temp_locations_[index];
  }

  Location* temp_slot(intptr_t index) {
    return &temp_locations_[index];
  }

  void set_temp(intptr_t index, Location loc) {
    ASSERT(!always_calls() || loc.IsMachineRegister());
    temp_locations_[index] = loc;
  }

  void AddTemp(Location loc) {
    ASSERT(!always_calls() || loc.IsMachineRegister());
    temp_locations_.Add(loc);
  }

  Location out() const {
    return output_location_;
  }

  Location* out_slot() {
    return &output_location_;
  }

  void set_out(Location loc) {
    ASSERT(!always_calls() || (loc.IsMachineRegister() || loc.IsInvalid()));
    output_location_ = loc;
  }

  BitmapBuilder* stack_bitmap() const { return stack_bitmap_; }

  bool always_calls() const {
    return contains_call_ == kCall;
  }

  bool can_call() {
    return contains_call_ != kNoCall;
  }

  void PrintTo(BufferFormatter* f) const;

  static LocationSummary* Make(intptr_t input_count,
                               Location out,
                               ContainsCall contains_call);

  RegisterSet* live_registers() {
    return &live_registers_;
  }

 private:
  // TODO(vegorov): replace with ZoneArray.
  GrowableArray<Location> input_locations_;
  GrowableArray<Location> temp_locations_;
  Location output_location_;
  BitmapBuilder* stack_bitmap_;

  const ContainsCall contains_call_;
  RegisterSet live_registers_;
};


}  // namespace dart

#endif  // VM_LOCATIONS_H_
