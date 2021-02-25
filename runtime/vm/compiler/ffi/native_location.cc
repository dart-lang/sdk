// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_location.h"

#include "vm/zone_text_buffer.h"

namespace dart {

namespace compiler {

namespace ffi {

#if !defined(FFI_UNIT_TESTS)
bool NativeLocation::LocationCanBeExpressed(Location loc, Representation rep) {
  switch (loc.kind()) {
    case Location::Kind::kRegister:
    case Location::Kind::kFpuRegister:
    case Location::Kind::kStackSlot:
    case Location::Kind::kDoubleStackSlot:
      return true;
    default:
      break;
  }
  if (loc.IsPairLocation()) {
    return false;
  }
  return false;
}

NativeLocation& NativeLocation::FromLocation(Zone* zone,
                                             Location loc,
                                             Representation rep) {
  ASSERT(LocationCanBeExpressed(loc, rep));

  const NativeType& native_rep =
      NativeType::FromUnboxedRepresentation(zone, rep);

  switch (loc.kind()) {
    case Location::Kind::kRegister:
      return *new (zone)
          NativeRegistersLocation(zone, native_rep, native_rep, loc.reg());
    case Location::Kind::kFpuRegister:
      return *new (zone)
          NativeFpuRegistersLocation(native_rep, native_rep, loc.fpu_reg());
    case Location::Kind::kStackSlot:
      return *new (zone)
          NativeStackLocation(native_rep, native_rep, loc.base_reg(),
                              loc.stack_index() * compiler::target::kWordSize);
    case Location::Kind::kDoubleStackSlot:
      return *new (zone)
          NativeStackLocation(native_rep, native_rep, loc.base_reg(),
                              loc.stack_index() * compiler::target::kWordSize);
    default:
      break;
  }

  UNREACHABLE();
}

NativeLocation& NativeLocation::FromPairLocation(Zone* zone,
                                                 Location pair_loc,
                                                 Representation pair_rep,
                                                 intptr_t index) {
  ASSERT(pair_loc.IsPairLocation());
  ASSERT(index == 0 || index == 1);
  const Representation rep =
      NativeType::FromUnboxedRepresentation(zone, pair_rep)
          .Split(zone, index)
          .AsRepresentation();
  const Location loc = pair_loc.AsPairLocation()->At(index);
  return FromLocation(zone, loc, rep);
}
#endif

const NativeRegistersLocation& NativeLocation::AsRegisters() const {
  ASSERT(IsRegisters());
  return static_cast<const NativeRegistersLocation&>(*this);
}

const NativeFpuRegistersLocation& NativeLocation::AsFpuRegisters() const {
  ASSERT(IsFpuRegisters());
  return static_cast<const NativeFpuRegistersLocation&>(*this);
}

const NativeStackLocation& NativeLocation::AsStack() const {
  ASSERT(IsStack());
  return static_cast<const NativeStackLocation&>(*this);
}

const MultipleNativeLocations& NativeLocation::AsMultiple() const {
  ASSERT(IsMultiple());
  return static_cast<const MultipleNativeLocations&>(*this);
}

const PointerToMemoryLocation& NativeLocation::AsPointerToMemory() const {
  ASSERT(IsPointerToMemory());
  return static_cast<const PointerToMemoryLocation&>(*this);
}

#if !defined(FFI_UNIT_TESTS)
Location NativeRegistersLocation::AsLocation() const {
  ASSERT(IsExpressibleAsLocation());
  switch (num_regs()) {
    case 1:
      return Location::RegisterLocation(regs_->At(0));
    case 2:
      return Location::Pair(Location::RegisterLocation(regs_->At(0)),
                            Location::RegisterLocation(regs_->At(1)));
  }
  UNREACHABLE();
}

Location NativeStackLocation::AsLocation() const {
  ASSERT(IsExpressibleAsLocation());
  if (payload_type().IsInt()) {
    const intptr_t size = payload_type().SizeInBytes();
    const intptr_t size_slots = size / compiler::target::kWordSize;
    switch (size_slots) {
      case 1:
        return Location::StackSlot(offset_in_words(), base_register_);
      case 2:
        return Location::Pair(
            Location::StackSlot(offset_in_words(), base_register_),
            Location::StackSlot(offset_in_words() + 1, base_register_));
    }
  } else {
    ASSERT(payload_type().IsFloat());
    if (payload_type().AsPrimitive().representation() == kFloat) {
      return Location::StackSlot(offset_in_words(), base_register_);
    } else {
      ASSERT(payload_type().AsPrimitive().representation() == kDouble);
      return Location::DoubleStackSlot(offset_in_words(), base_register_);
    }
  }
  UNREACHABLE();
}
#endif

NativeRegistersLocation& NativeRegistersLocation::Split(Zone* zone,
                                                        intptr_t num_parts,
                                                        intptr_t index) const {
  ASSERT(num_parts == 2);
  ASSERT(num_regs() == num_parts);
  return *new (zone) NativeRegistersLocation(
      zone, payload_type().Split(zone, index),
      container_type().Split(zone, index), reg_at(index));
}

NativeStackLocation& NativeStackLocation::Split(Zone* zone,
                                                intptr_t num_parts,
                                                intptr_t index) const {
  const intptr_t size = payload_type().SizeInBytes();

  if (payload_type().IsPrimitive()) {
    ASSERT(num_parts == 2);
    return *new (zone) NativeStackLocation(
        payload_type().Split(zone, index), container_type().Split(zone, index),
        base_register_, offset_in_bytes_ + size / num_parts * index);
  } else {
    const intptr_t size_rounded_up =
        Utils::RoundUp(size, compiler::target::kWordSize);
    ASSERT(size_rounded_up / compiler::target::kWordSize == num_parts);

    // Blocks of compiler::target::kWordSize.
    return *new (zone) NativeStackLocation(
        *new (zone) NativePrimitiveType(
            compiler::target::kWordSize == 8 ? kInt64 : kInt32),
        *new (zone) NativePrimitiveType(
            compiler::target::kWordSize == 8 ? kInt64 : kInt32),
        base_register_, offset_in_bytes_ + compiler::target::kWordSize * index);
  }
}

intptr_t MultipleNativeLocations::StackTopInBytes() const {
  intptr_t height = 0;
  for (int i = 0; i < locations_.length(); i++) {
    height = Utils::Maximum(height, locations_[i]->StackTopInBytes());
  }
  return height;
}

NativeLocation& NativeLocation::WidenTo4Bytes(Zone* zone) const {
  return WithOtherNativeType(zone, payload_type().WidenTo4Bytes(zone),
                             container_type().WidenTo4Bytes(zone));
}

#if defined(TARGET_ARCH_ARM)
const NativeLocation& NativeLocation::WidenToQFpuRegister(Zone* zone) const {
  if (!IsFpuRegisters()) {
    return *this;
  }
  const auto& fpu_loc = AsFpuRegisters();
  switch (fpu_loc.fpu_reg_kind()) {
    case kQuadFpuReg:
      return *this;
    case kDoubleFpuReg: {
      return *new (zone) NativeFpuRegistersLocation(
          payload_type_, container_type_, QRegisterOf(fpu_loc.fpu_d_reg()));
    }
    case kSingleFpuReg: {
      return *new (zone) NativeFpuRegistersLocation(
          payload_type_, container_type_, QRegisterOf(fpu_loc.fpu_s_reg()));
    }
  }
  UNREACHABLE();
}
#endif  // defined(TARGET_ARCH_ARM)

bool NativeRegistersLocation::Equals(const NativeLocation& other) const {
  if (!other.IsRegisters()) {
    return false;
  }
  const auto& other_regs = other.AsRegisters();
  if (other_regs.num_regs() != num_regs()) {
    return false;
  }
  for (intptr_t i = 0; i < num_regs(); i++) {
    if (other_regs.reg_at(i) != reg_at(i)) {
      return false;
    }
  }
  return true;
}

bool NativeFpuRegistersLocation::Equals(const NativeLocation& other) const {
  if (!other.IsFpuRegisters()) {
    return false;
  }
  return other.AsFpuRegisters().fpu_reg_ == fpu_reg_;
}

bool NativeStackLocation::Equals(const NativeLocation& other) const {
  if (!other.IsStack()) {
    return false;
  }
  const auto& other_stack = other.AsStack();
  if (other_stack.base_register_ != base_register_) {
    return false;
  }
  return other_stack.offset_in_bytes_ == offset_in_bytes_;
}

bool PointerToMemoryLocation::Equals(const NativeLocation& other) const {
  if (!other.IsPointerToMemory()) {
    return false;
  }
  const auto& other_pointer = other.AsPointerToMemory();
  if (!other_pointer.pointer_location_.Equals(pointer_location_)) {
    return false;
  }
  return other_pointer.payload_type().Equals(payload_type());
}

#if !defined(FFI_UNIT_TESTS)
compiler::Address NativeLocationToStackSlotAddress(
    const NativeStackLocation& loc) {
  return compiler::Address(loc.base_register(), loc.offset_in_bytes());
}
#endif

static void PrintRepresentations(BaseTextBuffer* f, const NativeLocation& loc) {
  f->AddString(" ");
  loc.container_type().PrintTo(f, /*multi_line=*/false, /*verbose=*/false);
  if (!loc.container_type().Equals(loc.payload_type())) {
    f->AddString("[");
    loc.payload_type().PrintTo(f, /*multi_line=*/false, /*verbose=*/false);
    f->AddString("]");
  }
}

void NativeLocation::PrintTo(BaseTextBuffer* f) const {
  f->AddString("I");
  PrintRepresentations(f, *this);
}

void NativeRegistersLocation::PrintTo(BaseTextBuffer* f) const {
  if (num_regs() == 1) {
    f->Printf("%s", RegisterNames::RegisterName(regs_->At(0)));
  } else {
    f->AddString("(");
    for (intptr_t i = 0; i < num_regs(); i++) {
      if (i != 0) {
        f->Printf(", ");
      }
      f->Printf("%s", RegisterNames::RegisterName(regs_->At(i)));
    }
    f->AddString(")");
  }
  PrintRepresentations(f, *this);
}

void NativeFpuRegistersLocation::PrintTo(BaseTextBuffer* f) const {
  switch (fpu_reg_kind()) {
    case kQuadFpuReg:
      f->Printf("%s", RegisterNames::FpuRegisterName(fpu_reg()));
      break;
#if defined(TARGET_ARCH_ARM)
    case kDoubleFpuReg:
      f->Printf("%s", RegisterNames::FpuDRegisterName(fpu_d_reg()));
      break;
    case kSingleFpuReg:
      f->Printf("%s", RegisterNames::FpuSRegisterName(fpu_s_reg()));
      break;
#endif  // defined(TARGET_ARCH_ARM)
    default:
      UNREACHABLE();
  }

  PrintRepresentations(f, *this);
}

void NativeStackLocation::PrintTo(BaseTextBuffer* f) const {
  f->Printf("S%+" Pd, offset_in_bytes_);
  PrintRepresentations(f, *this);
}

const char* NativeLocation::ToCString(Zone* zone) const {
  ZoneTextBuffer textBuffer(zone);
  PrintTo(&textBuffer);
  return textBuffer.buffer();
}

void PointerToMemoryLocation::PrintTo(BaseTextBuffer* f) const {
  f->Printf("P(");
  pointer_location().PrintTo(f);
  if (!pointer_location().Equals(pointer_return_location())) {
    f->Printf(", ret:");
    pointer_return_location().PrintTo(f);
  }
  f->Printf(")");
  PrintRepresentations(f, *this);
}

void MultipleNativeLocations::PrintTo(BaseTextBuffer* f) const {
  f->Printf("M(");
  for (intptr_t i = 0; i < locations_.length(); i++) {
    if (i != 0) f->Printf(", ");
    locations_[i]->PrintTo(f);
  }
  f->Printf(")");
  PrintRepresentations(f, *this);
}

#if !defined(FFI_UNIT_TESTS)
const char* NativeLocation::ToCString() const {
  return ToCString(Thread::Current()->zone());
}
#endif

intptr_t SizeFromFpuRegisterKind(enum FpuRegisterKind kind) {
  switch (kind) {
    case kQuadFpuReg:
      return 16;
    case kDoubleFpuReg:
      return 8;
    case kSingleFpuReg:
      return 4;
  }
  UNREACHABLE();
}
enum FpuRegisterKind FpuRegisterKindFromSize(intptr_t size_in_bytes) {
  switch (size_in_bytes) {
    case 16:
      return kQuadFpuReg;
    case 8:
      return kDoubleFpuReg;
    case 4:
      return kSingleFpuReg;
  }
  UNREACHABLE();
}

#if defined(TARGET_ARCH_ARM)
DRegister NativeFpuRegistersLocation::fpu_as_d_reg() const {
  switch (fpu_reg_kind_) {
    case kQuadFpuReg:
      return EvenDRegisterOf(fpu_reg());
    case kDoubleFpuReg:
      return fpu_d_reg();
    case kSingleFpuReg:
      return DRegisterOf(fpu_s_reg());
  }
  UNREACHABLE();
}

SRegister NativeFpuRegistersLocation::fpu_as_s_reg() const {
  switch (fpu_reg_kind_) {
    case kQuadFpuReg:
      return EvenSRegisterOf(EvenDRegisterOf(fpu_reg()));
    case kDoubleFpuReg:
      return EvenSRegisterOf(fpu_d_reg());
    case kSingleFpuReg:
      return fpu_s_reg();
  }
  UNREACHABLE();
}

bool NativeFpuRegistersLocation::IsLowestBits() const {
  switch (fpu_reg_kind()) {
    case kQuadFpuReg:
      return true;
    case kDoubleFpuReg: {
      return fpu_d_reg() % 2 == 0;
    }
    case kSingleFpuReg: {
      return fpu_s_reg() % 4 == 0;
    }
  }
  UNREACHABLE();
}
#endif  // defined(TARGET_ARCH_ARM)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
