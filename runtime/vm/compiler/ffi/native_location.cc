// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_location.h"

#include "vm/compiler/backend/il_printer.h"

namespace dart {

namespace compiler {

namespace ffi {

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
    // TODO(36730): We could possibly consume a pair location as struct.
    return false;
  }
  return false;
}

NativeLocation& NativeLocation::FromLocation(Location loc,
                                             Representation rep,
                                             Zone* zone) {
  // TODO(36730): We could possibly consume a pair location as struct.
  ASSERT(LocationCanBeExpressed(loc, rep));

  const NativeType& native_rep =
      NativeType::FromUnboxedRepresentation(rep, zone);

  switch (loc.kind()) {
    case Location::Kind::kRegister:
      return *new (zone)
          NativeRegistersLocation(native_rep, native_rep, loc.reg());
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

// TODO(36730): Remove when being able to consume as struct.
NativeLocation& NativeLocation::FromPairLocation(Location pair_loc,
                                                 Representation pair_rep,
                                                 intptr_t index,
                                                 Zone* zone) {
  ASSERT(pair_loc.IsPairLocation());
  ASSERT(index == 0 || index == 1);
  const Representation rep =
      NativeType::FromUnboxedRepresentation(pair_rep, zone)
          .Split(index, zone)
          .AsRepresentation();
  const Location loc = pair_loc.AsPairLocation()->At(index);
  return FromLocation(loc, rep, zone);
}

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
    if (payload_type().AsFundamental().representation() == kFloat) {
      return Location::StackSlot(offset_in_words(), base_register_);
    } else {
      ASSERT(payload_type().AsFundamental().representation() == kDouble);
      return Location::DoubleStackSlot(offset_in_words(), base_register_);
    }
  }
  UNREACHABLE();
}
NativeRegistersLocation& NativeRegistersLocation::Split(intptr_t index,
                                                        Zone* zone) const {
  ASSERT(num_regs() == 2);
  return *new (zone) NativeRegistersLocation(
      payload_type().Split(index, zone), container_type().Split(index, zone),
      reg_at(index));
}

NativeStackLocation& NativeStackLocation::Split(intptr_t index,
                                                Zone* zone) const {
  ASSERT(index == 0 || index == 1);
  const intptr_t size = payload_type().SizeInBytes();

  return *new (zone) NativeStackLocation(
      payload_type().Split(index, zone), container_type().Split(index, zone),
      base_register_, offset_in_bytes_ + size / 2 * index);
}

NativeLocation& NativeLocation::WidenTo4Bytes(Zone* zone) const {
  return WithOtherNativeType(payload_type().WidenTo4Bytes(zone),
                             container_type().WidenTo4Bytes(zone), zone);
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

compiler::Address NativeLocationToStackSlotAddress(
    const NativeStackLocation& loc) {
  return compiler::Address(loc.base_register(), loc.offset_in_bytes());
}

static void PrintRepresentations(BufferFormatter* f,
                                 const NativeLocation& loc) {
  f->Print(" ");
  loc.container_type().PrintTo(f);
  if (!loc.container_type().Equals(loc.payload_type())) {
    f->Print("[");
    loc.payload_type().PrintTo(f);
    f->Print("]");
  }
}

void NativeLocation::PrintTo(BufferFormatter* f) const {
  f->Print("I");
  PrintRepresentations(f, *this);
}

void NativeRegistersLocation::PrintTo(BufferFormatter* f) const {
  if (num_regs() == 1) {
    f->Print("%s", RegisterNames::RegisterName(regs_->At(0)));
  } else {
    f->Print("(");
    for (intptr_t i = 0; i < num_regs(); i++) {
      if (i != 0) f->Print(", ");
      f->Print("%s", RegisterNames::RegisterName(regs_->At(i)));
    }
    f->Print(")");
  }
  PrintRepresentations(f, *this);
}

void NativeFpuRegistersLocation::PrintTo(BufferFormatter* f) const {
  switch (fpu_reg_kind()) {
    case kQuadFpuReg:
      f->Print("%s", RegisterNames::FpuRegisterName(fpu_reg()));
      break;
#if defined(TARGET_ARCH_ARM)
    case kDoubleFpuReg:
      f->Print("%s", RegisterNames::FpuDRegisterName(fpu_d_reg()));
      break;
    case kSingleFpuReg:
      f->Print("%s", RegisterNames::FpuSRegisterName(fpu_s_reg()));
      break;
#endif  // defined(TARGET_ARCH_ARM)
    default:
      UNREACHABLE();
  }

  PrintRepresentations(f, *this);
}

void NativeStackLocation::PrintTo(BufferFormatter* f) const {
  f->Print("S%+" Pd, offset_in_bytes_);
  PrintRepresentations(f, *this);
}

const char* NativeLocation::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

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
