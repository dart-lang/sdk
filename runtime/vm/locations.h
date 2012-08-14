// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LOCATIONS_H_
#define VM_LOCATIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/bitfield.h"

namespace dart {

class BufferFormatter;

// Location objects are used to connect register allocator and code generator.
// Instruction templates used by code generator have a corresponding
// LocationSummary object which specifies expected location for every input
// and output.
// Each location is encoded as a single word: for non-constant locations
// low 3 bits denote location kind, rest is kind specific location payload
// e.g. for REGISTER kind payload is register code (value of the Register
// enumeration), constant locations contain a tagged (low 2 bits are set to 01)
// Object handle
class Location : public ValueObject {
 private:
  enum {
    // Number of bits required to encode Kind value.
    kBitsForKind = 3,
    kBitsForPayload = kWordSize * kBitsPerByte - kBitsForKind,
  };

  static const uword kInvalidLocation = 0;
  static const uword kConstantMask = 0x3;
  static const intptr_t kStackIndexBias =
      static_cast<intptr_t>(1) << (kBitsForPayload - 1);

 public:
  // Constant payload can overlap with kind field so Kind values
  // have to be chosen in a way that their last 2 bits are never
  // the same as kConstant.
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

    // Register location represents a fixed register.  Payload contains
    // register code.
    kRegister = 3,

    // Spill slot allocated by the register allocator.  Payload contains
    // a spill index.
    kStackSlot = 4,
  };

  Location() : value_(kInvalidLocation) {
    ASSERT(IsInvalid());
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
  // TODO(vegorov): writable register policy?
  enum Policy {
    kAny,
    kPrefersRegister,
    kRequiresRegister,
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
    return Location(kRegister, static_cast<uword>(reg));
  }

  bool IsRegister() const {
    return kind() == kRegister;
  }

  Register reg() const {
    ASSERT(IsRegister());
    return static_cast<Register>(payload());
  }

  // Spill slots.
  static Location StackSlot(intptr_t stack_index) {
    ASSERT((-kStackIndexBias <= stack_index) &&
           (stack_index < kStackIndexBias));
    Location loc(kStackSlot, static_cast<uword>(kStackIndexBias + stack_index));
    // Ensure that sign is preserved.
    ASSERT(loc.stack_index() == stack_index);
    return loc;
  }

  bool IsStackSlot() const {
    return kind() == kStackSlot;
  }

  intptr_t stack_index() const {
    ASSERT(IsStackSlot());
    // Decode stack index manually to preserve sign.
    return payload() - kStackIndexBias;
  }

  const char* Name() const;
  void PrintTo(BufferFormatter* f) const;
  void Print() const;

  // Compare two locations.
  bool Equals(Location other) const {
    return value_ == other.value_;
  }

 private:
  explicit Location(uword value) : value_(value) { }

  Location(Kind kind, uword payload)
      : value_(KindField::encode(kind) | PayloadField::encode(payload)) { }

  uword payload() const {
    return PayloadField::decode(value_);
  }

  // If current location is constant might return something that
  // is not equal to any Kind.
  Kind kind() const {
    return KindField::decode(value_);
  }

  typedef BitField<Kind, 0, kBitsForKind> KindField;
  typedef BitField<uword, kBitsForKind, kBitsForPayload> PayloadField;

  // Layout for kUnallocated locations payload.
  typedef BitField<Policy, 0, 2> PolicyField;

  // Location either contains kind and payload fields or a tagged handle for
  // a constant locations. Values of enumeration Kind are selected in such a
  // way that none of them can be interpreted as a kConstant tag.
  uword value_;
};


// Specification of locations for inputs and output.
class LocationSummary : public ZoneAllocated {
 public:
  enum ContainsCall {
    kNoCall,
    kCall,
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
    ASSERT(!is_call() || loc.IsRegister());
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
    ASSERT(!is_call() || loc.IsRegister());
    temp_locations_[index] = loc;
  }

  Location out() const {
    return output_location_;
  }

  Location* out_slot() {
    return &output_location_;
  }


  void set_out(Location loc) {
    ASSERT(!is_call() || loc.IsRegister());
    output_location_ = loc;
  }

  BitmapBuilder* stack_bitmap() const { return stack_bitmap_; }

  bool is_call() const {
    return is_call_;
  }

  void PrintTo(BufferFormatter* f) const;

  static LocationSummary* Make(intptr_t input_count,
                               Location out,
                               LocationSummary::ContainsCall contains_call);

 private:
  // TODO(vegorov): replace with ZoneArray.
  GrowableArray<Location> input_locations_;
  GrowableArray<Location> temp_locations_;
  Location output_location_;
  BitmapBuilder* stack_bitmap_;
  const bool is_call_;
};


}  // namespace dart

#endif  // VM_LOCATIONS_H_
