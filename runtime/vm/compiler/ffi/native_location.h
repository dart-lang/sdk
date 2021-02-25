// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_
#define RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

#include "platform/assert.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/runtime_api.h"
#include "vm/constants.h"
#include "vm/growable_array.h"

#if !defined(FFI_UNIT_TESTS)
#include "vm/compiler/backend/locations.h"
#endif

namespace dart {

class BaseTextBuffer;

namespace compiler {

namespace ffi {

class NativeRegistersLocation;
class NativeFpuRegistersLocation;
class NativeStackLocation;
class MultipleNativeLocations;
class PointerToMemoryLocation;

// NativeLocation objects are used in the FFI to describe argument and return
// value locations in all native ABIs that the FFI supports.
//
// NativeLocations contain two NativeTypes.
// * The payload type.
// * The container type, equal to or larger than the payload. If the
//   container is larger than the payload, the upper bits are defined by sign
//   or zero extension.
//   Container type is also used to denote an integer container when floating
//   point values are passed in integer registers.
//
// NativeLocations can express things that dart::Locations cannot express:
// * Multiple consecutive registers.
// * Multiple sizes of FPU registers (e.g. S, D, and Q on Arm32).
// * Arbitrary byte-size stack locations, at byte-size offsets.
//   (The Location class uses word-size offsets.)
// * Pointers to a memory location.
// * Split between multiple registers and stack.
//
// NativeLocations cannot express the following dart::Locations:
// * No PairLocations. Instead, NativeRegistersLocations can have multiple
//   registers, and NativeStackLocations can have arbitrary types.
// * No ConstantLocations.
//
// NativeLocation does not satisfy the invariant of Location: bitwise
// inequality cannot be used to determine disjointness.
class NativeLocation : public ZoneAllocated {
 public:
#if !defined(FFI_UNIT_TESTS)
  static bool LocationCanBeExpressed(Location loc, Representation rep);
  static NativeLocation& FromLocation(Zone* zone,
                                      Location loc,
                                      Representation rep);
  static NativeLocation& FromPairLocation(Zone* zone,
                                          Location loc,
                                          Representation rep,
                                          intptr_t index);
#endif

  // The type of the data at this location.
  const NativeType& payload_type() const { return payload_type_; }

  // The location container size, possibly larger than data.
  //
  // If the container is larger than the data, the remaining bits are _not_
  // undefined. For example a uint8 inside a uint32 has the upper 24 bits set
  // to 0. Effectively allowing the value to be read as uint8, uint16 and
  // uint32.
  const NativeType& container_type() const { return container_type_; }

  virtual NativeLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const = 0;

#if defined(TARGET_ARCH_ARM)
  const NativeLocation& WidenToQFpuRegister(Zone* zone) const;
#endif  // defined(TARGET_ARCH_ARM)

  NativeLocation& WidenTo4Bytes(Zone* zone) const;

  virtual bool IsRegisters() const { return false; }
  virtual bool IsFpuRegisters() const { return false; }
  virtual bool IsStack() const { return false; }
  virtual bool IsMultiple() const { return false; }
  virtual bool IsPointerToMemory() const { return false; }

  virtual bool IsExpressibleAsLocation() const { return false; }
#if !defined(FFI_UNIT_TESTS)
  virtual Location AsLocation() const {
    ASSERT(IsExpressibleAsLocation());
    UNREACHABLE();
  }
#endif

  virtual void PrintTo(BaseTextBuffer* f) const;
  const char* ToCString(Zone* zone) const;
#if !defined(FFI_UNIT_TESTS)
  const char* ToCString() const;
#endif

  const NativeRegistersLocation& AsRegisters() const;
  const NativeFpuRegistersLocation& AsFpuRegisters() const;
  const NativeStackLocation& AsStack() const;
  const MultipleNativeLocations& AsMultiple() const;
  const PointerToMemoryLocation& AsPointerToMemory() const;

  // Retrieve one part from this location when it is split into multiple parts.
  virtual NativeLocation& Split(Zone* zone,
                                intptr_t num_parts,
                                intptr_t index) const {
    UNREACHABLE();
  }

  // Return the top of the stack in bytes. Recurses over its constituents when
  // MultipleNativeLocations.
  virtual intptr_t StackTopInBytes() const { return 0; }

  // Equality of location, ignores the payload and container native types.
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
  NativeRegistersLocation(Zone* zone,
                          const NativeType& payload_type,
                          const NativeType& container_type,
                          Register reg)
      : NativeLocation(payload_type, container_type) {
    regs_ = new (zone) ZoneGrowableArray<Register>(zone, 1);
    regs_->Add(reg);
  }
  NativeRegistersLocation(Zone* zone,
                          const NativeType& payload_type,
                          const NativeType& container_type,
                          Register register1,
                          Register register2)
      : NativeLocation(payload_type, container_type) {
    regs_ = new (zone) ZoneGrowableArray<Register>(zone, 2);
    regs_->Add(register1);
    regs_->Add(register2);
  }
  virtual ~NativeRegistersLocation() {}

  virtual NativeRegistersLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const {
    return *new (zone)
        NativeRegistersLocation(new_payload_type, new_container_type, regs_);
  }

  virtual bool IsRegisters() const { return true; }
  virtual bool IsExpressibleAsLocation() const {
    return num_regs() == 1 || num_regs() == 2;
  }
#if !defined(FFI_UNIT_TESTS)
  virtual Location AsLocation() const;
#endif
  intptr_t num_regs() const { return regs_->length(); }
  Register reg_at(intptr_t index) const { return regs_->At(index); }

  virtual NativeRegistersLocation& Split(Zone* zone,
                                         intptr_t num_parts,
                                         intptr_t index) const;

  virtual void PrintTo(BaseTextBuffer* f) const;

  virtual bool Equals(const NativeLocation& other) const;

 private:
  ZoneGrowableArray<Register>* regs_;

  DISALLOW_COPY_AND_ASSIGN(NativeRegistersLocation);
};

enum FpuRegisterKind {
  kQuadFpuReg,    // 16 bytes
  kDoubleFpuReg,  //  8 bytes, a double
  kSingleFpuReg   //  4 bytes, a float
};

intptr_t SizeFromFpuRegisterKind(FpuRegisterKind kind);
FpuRegisterKind FpuRegisterKindFromSize(intptr_t size_in_bytes);

class NativeFpuRegistersLocation : public NativeLocation {
 public:
  NativeFpuRegistersLocation(const NativeType& payload_type,
                             const NativeType& container_type,
                             FpuRegisterKind fpu_reg_kind,
                             intptr_t fpu_register)
      : NativeLocation(payload_type, container_type),
        fpu_reg_kind_(fpu_reg_kind),
        fpu_reg_(fpu_register) {}
  NativeFpuRegistersLocation(const NativeType& payload_type,
                             const NativeType& container_type,
                             FpuRegister fpu_register)
      : NativeLocation(payload_type, container_type),
        fpu_reg_kind_(kQuadFpuReg),
        fpu_reg_(fpu_register) {}
#if defined(TARGET_ARCH_ARM)
  NativeFpuRegistersLocation(const NativeType& payload_type,
                             const NativeType& container_type,
                             DRegister fpu_register)
      : NativeLocation(payload_type, container_type),
        fpu_reg_kind_(kDoubleFpuReg),
        fpu_reg_(fpu_register) {}
  NativeFpuRegistersLocation(const NativeType& payload_type,
                             const NativeType& container_type,
                             SRegister fpu_register)
      : NativeLocation(payload_type, container_type),
        fpu_reg_kind_(kSingleFpuReg),
        fpu_reg_(fpu_register) {}
#endif  // defined(TARGET_ARCH_ARM)
  virtual ~NativeFpuRegistersLocation() {}

  virtual NativeFpuRegistersLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const {
    return *new (zone) NativeFpuRegistersLocation(
        new_payload_type, new_container_type, fpu_reg_kind_, fpu_reg_);
  }
  virtual bool IsFpuRegisters() const { return true; }
  virtual bool IsExpressibleAsLocation() const {
    return fpu_reg_kind_ == kQuadFpuReg;
  }
#if !defined(FFI_UNIT_TESTS)
  virtual Location AsLocation() const {
    ASSERT(IsExpressibleAsLocation());
    return Location::FpuRegisterLocation(fpu_reg());
  }
#endif
  FpuRegisterKind fpu_reg_kind() const { return fpu_reg_kind_; }
  FpuRegister fpu_reg() const {
    ASSERT(fpu_reg_kind_ == kQuadFpuReg);
    return static_cast<FpuRegister>(fpu_reg_);
  }
#if defined(TARGET_ARCH_ARM)
  DRegister fpu_d_reg() const {
    ASSERT(fpu_reg_kind_ == kDoubleFpuReg);
    return static_cast<DRegister>(fpu_reg_);
  }
  SRegister fpu_s_reg() const {
    ASSERT(fpu_reg_kind_ == kSingleFpuReg);
    return static_cast<SRegister>(fpu_reg_);
  }
  DRegister fpu_as_d_reg() const;
  SRegister fpu_as_s_reg() const;

  bool IsLowestBits() const;
#endif  // defined(TARGET_ARCH_ARM)

  virtual void PrintTo(BaseTextBuffer* f) const;

  virtual bool Equals(const NativeLocation& other) const;

 private:
  FpuRegisterKind fpu_reg_kind_;
  intptr_t fpu_reg_;
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

  virtual NativeStackLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const {
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

#if !defined(FFI_UNIT_TESTS)
  virtual Location AsLocation() const;

  // ConstantInstr expects DoubleStackSlot for doubles, even on 64-bit systems.
  //
  // So this return a wrong-sized Location on purpose.
  Location AsDoubleStackSlotLocation() const {
    ASSERT(compiler::target::kWordSize == 8);
    return Location::DoubleStackSlot(offset_in_words(), base_register_);
  }
#endif

  virtual NativeStackLocation& Split(Zone* zone,
                                     intptr_t num_parts,
                                     intptr_t index) const;

  virtual intptr_t StackTopInBytes() const {
    return offset_in_bytes() + container_type().SizeInBytes();
  }

  virtual void PrintTo(BaseTextBuffer* f) const;

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

// The location of a pointer pointing to a compound.
//
// For arguments a pointer to a copy of an object. The backing copy of the
// object typically resides on the stack.
//
// For return values a pointer to empty space that should hold the object. This
// space also typically resides on the stack.
class PointerToMemoryLocation : public NativeLocation {
 public:
  PointerToMemoryLocation(const NativeLocation& pointer_location,
                          const NativeCompoundType& object_pointed_to)
      : NativeLocation(object_pointed_to, object_pointed_to),
        pointer_location_(pointer_location),
        pointer_return_location_(pointer_location) {
    ASSERT(pointer_location.IsRegisters() || pointer_location.IsStack());
  }
  PointerToMemoryLocation(const NativeLocation& pointer_location,
                          const NativeLocation& pointer_return_location,
                          const NativeCompoundType& object_pointed_to)
      : NativeLocation(object_pointed_to, object_pointed_to),
        pointer_location_(pointer_location),
        pointer_return_location_(pointer_return_location) {
    ASSERT(pointer_location.IsRegisters() || pointer_location.IsStack());
  }

  virtual ~PointerToMemoryLocation() {}

  virtual bool IsPointerToMemory() const { return true; }

  virtual void PrintTo(BaseTextBuffer* f) const;

  virtual bool Equals(const NativeLocation& other) const;

  virtual NativeLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const {
    UNREACHABLE();
  }

  virtual intptr_t StackTopInBytes() const {
    return pointer_location().StackTopInBytes();
  }

  // The location where the pointer is passed to the function.
  const NativeLocation& pointer_location() const { return pointer_location_; }

  // The location where the pointer is returned from the function.
  const NativeLocation& pointer_return_location() const {
    return pointer_return_location_;
  }

 private:
  const NativeLocation& pointer_location_;
  // The return location is only in use for return values, not for arguments.
  const NativeLocation& pointer_return_location_;

  DISALLOW_COPY_AND_ASSIGN(PointerToMemoryLocation);
};

using NativeLocations = ZoneGrowableArray<const NativeLocation*>;

// A struct broken up over multiple native locations.
class MultipleNativeLocations : public NativeLocation {
 public:
  MultipleNativeLocations(const NativeCompoundType& payload_type,
                          const NativeLocations& locations)
      : NativeLocation(payload_type, payload_type), locations_(locations) {}
  virtual ~MultipleNativeLocations() {}

  virtual bool IsMultiple() const { return true; }

  virtual void PrintTo(BaseTextBuffer* f) const;

  virtual NativeLocation& WithOtherNativeType(
      Zone* zone,
      const NativeType& new_payload_type,
      const NativeType& new_container_type) const {
    UNREACHABLE();
  }

  virtual intptr_t StackTopInBytes() const;

  const NativeLocations& locations() const { return locations_; }

 private:
  const NativeLocations& locations_;
  DISALLOW_COPY_AND_ASSIGN(MultipleNativeLocations);
};

#if !defined(FFI_UNIT_TESTS)
// Return a memory operand for stack slot locations.
compiler::Address NativeLocationToStackSlotAddress(
    const NativeStackLocation& loc);
#endif

}  // namespace ffi

}  // namespace compiler

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_NATIVE_LOCATION_H_
