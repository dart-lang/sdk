// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_

#include "vm/compiler/backend/locations.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/growable_array.h"
#include "vm/thread.h"

namespace dart {

class BufferFormatter;

namespace compiler {

namespace ffi {

class NativeRegistersLocation;
class NativeFpuRegistersLocation;
class NativeStackLocation;

// NativeLocation objects are used in the FFI to describe argument and return
// value locations in all native ABIs that the FFI supports.
//
// NativeLocations contain two NativeTypes.
// * The payload representation.
// * The container representation, equal to or larger than the payload. If the
//   container is larger than the payload, the upper bits are defined by sign
//   or zero extension.
//
// NativeLocations can express things that dart::Locations cannot express:
// * Multiple consecutive registers.
// * Multiple sizes of FPU registers (e.g. S, D, and Q on Arm32).
// * Arbitrary byte-size stack locations, at byte-size offsets.
//   (The Location class uses word-size offsets.)
// * Pointers including a backing location on the stack.
// * No location.
// * Split between multiple registers and stack.
//
// NativeLocations cannot express the following dart::Locations:
// * No PairLocations. Instead, NativeRegistersLocations can have multiple
//   registers, and NativeStackLocations can have arbitrary representations.
// * No ConstantLocations.
//
// NativeLocation does not satisfy the invariant of Location: bitwise
// inequality cannot be used to determine disjointness.
class NativeLocation : public ZoneAllocated {
 public:
  static bool LocationCanBeExpressed(Location loc, Representation rep);
  static NativeLocation& FromLocation(Location loc,
                                      Representation rep,
                                      Zone* zone);
  static NativeLocation& FromPairLocation(Location loc,
                                          Representation rep,
                                          intptr_t index,
                                          Zone* zone);

  // The representation of the data at this location.
  const NativeType& payload_type() const { return payload_type_; }

  // The location container size, possibly larger than data.
  //
  // If the container is larger than the data, the remaining bits are _not_
  // undefined. For example a uint8 inside a uint32 has the upper 24 bits set
  // to 0. Effectively allowing the value to be read as uint8, uint16 and
  // uint32.
  const NativeType& container_type() const { return container_type_; }

  virtual NativeLocation& WithOtherRep(const NativeType& new_payload_type,
                                       const NativeType& new_container_type,
                                       Zone* zone) const = 0;

  NativeLocation& WidenTo4Bytes(Zone* zone) const;

  virtual bool IsRegisters() const { return false; }
  virtual bool IsFpuRegisters() const { return false; }
  virtual bool IsStack() const { return false; }

  virtual bool IsExpressibleAsLocation() const { return false; }
  virtual Location AsLocation() const {
    ASSERT(IsExpressibleAsLocation());
    UNREACHABLE();
  }

  virtual void PrintTo(BufferFormatter* f) const;
  const char* ToCString() const;

  const NativeRegistersLocation& AsRegisters() const;
  const NativeFpuRegistersLocation& AsFpuRegisters() const;
  const NativeStackLocation& AsStack() const;

  virtual NativeLocation& Split(intptr_t index, Zone* zone) const {
    ASSERT(index == 0 || index == 1);
    UNREACHABLE();
  }

  // Equality of location, ignores the payload and container representations.
  virtual bool Equals(const NativeLocation& other) const { UNREACHABLE(); }

  virtual ~NativeLocation() {}

 protected:
  NativeLocation(const NativeType& payload_type,
                 const NativeType& container_type)
      : payload_type_(payload_type), container_type_(container_type) {}

 private:
  const NativeType& payload_type_;
  // The location container size, possibly larger than data.
  //
  // If the container is larger than the data, the remaining bits are _not_
  // undefined. For example a uint8 inside a uint32 has the upper 24 bits set
  // to 0. Effectively allowing the value to be read as uint8, uint16 and
  // uint32.
  const NativeType& container_type_;
};

class NativeRegistersLocation : public NativeLocation {
 public:
  NativeRegistersLocation(const NativeType& payload_type,
                          const NativeType& container_type,
                          ZoneGrowableArray<Register>* registers)
      : NativeLocation(payload_type, container_type), regs_(registers) {}
  NativeRegistersLocation(const NativeType& payload_type,
                          const NativeType& container_type,
                          Register reg)
      : NativeLocation(payload_type, container_type) {
    regs_ = new ZoneGrowableArray<Register>();
    regs_->Add(reg);
  }
  NativeRegistersLocation(const NativeType& payload_type,
                          const NativeType& container_type,
                          Register register1,
                          Register register2)
      : NativeLocation(payload_type, container_type) {
    regs_ = new ZoneGrowableArray<Register>();
    regs_->Add(register1);
    regs_->Add(register2);
  }
  virtual ~NativeRegistersLocation() {}

  virtual NativeRegistersLocation& WithOtherRep(
      const NativeType& new_payload_type,
      const NativeType& new_container_type,
      Zone* zone) const {
    return *new (zone)
        NativeRegistersLocation(new_payload_type, new_container_type, regs_);
  }

  virtual bool IsRegisters() const { return true; }
  virtual bool IsExpressibleAsLocation() const {
    return num_regs() == 1 || num_regs() == 2;
  }
  virtual Location AsLocation() const;
  intptr_t num_regs() const { return regs_->length(); }
  Register reg_at(intptr_t index) const { return regs_->At(index); }

  virtual NativeRegistersLocation& Split(intptr_t index, Zone* zone) const;

  virtual void PrintTo(BufferFormatter* f) const;

  virtual bool Equals(const NativeLocation& other) const;

 private:
  ZoneGrowableArray<Register>* regs_;

  DISALLOW_COPY_AND_ASSIGN(NativeRegistersLocation);
};

class NativeFpuRegistersLocation : public NativeLocation {
 public:
  NativeFpuRegistersLocation(const NativeType& payload_type,
                             const NativeType& container_type,
                             FpuRegister fpu_register)
      : NativeLocation(payload_type, container_type), fpu_reg_(fpu_register) {
    ASSERT(container_type.IsFloat());
    // Currently we do not store ints in floating point registers.
    ASSERT(container_type.Equals(payload_type));
  }
  virtual ~NativeFpuRegistersLocation() {}

  virtual NativeFpuRegistersLocation& WithOtherRep(
      const NativeType& new_payload_type,
      const NativeType& new_container_type,
      Zone* zone) const {
    return *new (zone) NativeFpuRegistersLocation(new_payload_type,
                                                  new_container_type, fpu_reg_);
  }

  virtual bool IsFpuRegisters() const { return true; }
  virtual bool IsExpressibleAsLocation() const { return true; }
  virtual Location AsLocation() const {
    ASSERT(IsExpressibleAsLocation());
    return Location::FpuRegisterLocation(fpu_reg_);
  }
  FpuRegister fpu_reg() const { return fpu_reg_; }

  virtual void PrintTo(BufferFormatter* f) const;

  virtual bool Equals(const NativeLocation& other) const;

 private:
  // TODO(36309): Support having multiple fpu registers.
  FpuRegister fpu_reg_;

  DISALLOW_COPY_AND_ASSIGN(NativeFpuRegistersLocation);
};

class NativeStackLocation : public NativeLocation {
 public:
  NativeStackLocation(const NativeType& payload_type,
                      const NativeType& container_type,
                      Register base_register,
                      intptr_t offset_in_bytes)
      : NativeLocation(payload_type, container_type),
        base_register_(base_register),
        offset_in_bytes_(offset_in_bytes) {}
  virtual ~NativeStackLocation() {}

  virtual NativeStackLocation& WithOtherRep(
      const NativeType& new_payload_type,
      const NativeType& new_container_type,
      Zone* zone) const {
    return *new (zone) NativeStackLocation(new_payload_type, new_container_type,
                                           base_register_, offset_in_bytes_);
  }

  virtual bool IsStack() const { return true; }
  virtual bool IsExpressibleAsLocation() const {
    const intptr_t size = payload_type().SizeInBytes();
    const intptr_t size_slots = size / compiler::target::kWordSize;
    return offset_in_bytes_ % compiler::target::kWordSize == 0 &&
           size % compiler::target::kWordSize == 0 &&
           (size_slots == 1 || size_slots == 2);
  }
  virtual Location AsLocation() const;

  // ConstantInstr expects DoubleStackSlot for doubles, even on 64-bit systems.
  //
  // So this return a wrong-sized Location on purpose.
  Location AsDoubleStackSlotLocation() const {
    ASSERT(compiler::target::kWordSize == 8);
    return Location::DoubleStackSlot(offset_in_words(), base_register_);
  }

  virtual NativeStackLocation& Split(intptr_t index, Zone* zone) const;

  virtual void PrintTo(BufferFormatter* f) const;

  virtual bool Equals(const NativeLocation& other) const;

  Register base_register() const { return base_register_; }
  intptr_t offset_in_bytes() const { return offset_in_bytes_; }

 private:
  intptr_t offset_in_words() const {
    ASSERT(offset_in_bytes_ % compiler::target::kWordSize == 0);
    return offset_in_bytes_ / compiler::target::kWordSize;
  }

  Register base_register_;
  intptr_t offset_in_bytes_;

  DISALLOW_COPY_AND_ASSIGN(NativeStackLocation);
};

// Return a memory operand for stack slot locations.
compiler::Address NativeLocationToStackSlotAddress(
    const NativeStackLocation& loc);

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_
