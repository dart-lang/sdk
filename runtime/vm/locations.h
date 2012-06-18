// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LOCATIONS_H_
#define VM_LOCATIONS_H_

#include "vm/allocation.h"
#include "vm/assembler.h"
#include "vm/bitfield.h"

namespace dart {


// Location objects are used to connect register allocator and code generator.
// Instruction templates used by code generator have a corresponding
// LocationSummary object which specifies expected location for every input
// and output.
// Each location is encoded as a single word: low 2 bits denote location kind,
// rest is kind specific location payload e.g. for REGISTER kind payload is
// register code (value of the Register enumeration).
class Location : public ValueObject {
 public:
  enum Kind {
    kInvalid,

    // Unallocated location represents a location that is not fixed and can be
    // allocated by a register allocator.  Each unallocated location has
    // a policy that specifies what kind of location is suitable.
    kUnallocated,

    // Register location represents a fixed register.
    kRegister
  };

  Location() : value_(KindField::encode(kInvalid)) { }

  Kind kind() const { return KindField::decode(value_); }

  // Unallocated locations.
  enum Policy {
    kRequiresRegister,
    kSameAsFirstInput,
  };

  static Location UnallocatedLocation(Policy policy) {
    return Location(kUnallocated, PolicyField::encode(policy));
  }

  // Any free register is suitable to replace this unallocated location.
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
    ASSERT(kind() == kUnallocated);
    return PolicyField::decode(payload());
  }

  // Register locations.
  static Location RegisterLocation(Register reg) {
    return Location(kRegister, static_cast<uword>(reg));
  }

  Register reg() const {
    ASSERT(kind() == kRegister);
    return static_cast<Register>(payload());
  }

 private:
  Location(Kind kind, uword payload)
      : value_(KindField::encode(kind) | PayloadField::encode(payload)) { }

  uword payload() const {
    return PayloadField::decode(value_);
  }

  typedef BitField<Kind, 0, 2> KindField;
  typedef BitField<uword, 2, kWordSize * kBitsPerByte - 2> PayloadField;

  // Layout for kUnallocated locations payload.
  typedef BitField<Policy, 0, 1> PolicyField;

  // TODO(vegorov): choose fixed size for this field.
  uword value_;
};


// Specification of locations for inputs and output.
class LocationSummary : public ZoneAllocated {
 public:
  enum ContainsCall {
    kNoCall,
    kCall,
  };

  enum ContainsBranch {
    kNoBranch,
    kBranch
  };

  // TODO(vegorov): remove unsafe kNoCall default.
  LocationSummary(intptr_t input_count,
                  intptr_t temp_count,
                  ContainsCall call = kNoCall,
                  ContainsBranch branch = kNoBranch)
      : input_locations_(input_count),
        temp_locations_(temp_count),
        output_location_(),
        is_call_(call == kCall),
        is_branch_(branch == kBranch) {
    for (intptr_t i = 0; i < input_count; i++) {
      input_locations_.Add(Location());
    }
    for (intptr_t i = 0; i < temp_count; i++) {
      temp_locations_.Add(Location());
    }
  }

  intptr_t input_count() const {
    return input_locations_.length();
  }

  Location in(intptr_t index) const {
    return input_locations_[index];
  }

  void set_in(intptr_t index, Location loc) {
    input_locations_[index] = loc;
  }

  intptr_t temp_count() const {
    return temp_locations_.length();
  }

  Location temp(intptr_t index) const {
    return temp_locations_[index];
  }

  void set_temp(intptr_t index, Location loc) {
    temp_locations_[index] = loc;
  }

  Location out() const {
    return output_location_;
  }

  void set_out(Location loc) {
    output_location_ = loc;
  }

  bool is_call() const {
    return is_call_;
  }

  // TODO(vegorov): this is a temporary solution. Once we will start removing
  // comparison operations from the flow graph when they are fused with a branch
  // we should eliminate this.
  bool is_branch() const {
    return is_branch_;
  }

  static LocationSummary* Make(intptr_t input_count,
                               Location out,
                               ContainsCall contains_call = kNoCall,
                               ContainsBranch contains_branch = kNoBranch);

 private:
  // TODO(vegorov): replace with ZoneArray.
  GrowableArray<Location> input_locations_;
  GrowableArray<Location> temp_locations_;
  Location output_location_;

  const bool is_call_;
  const bool is_branch_;
};


}  // namespace dart

#endif  // VM_LOCATIONS_H_
