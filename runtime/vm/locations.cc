// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/locations.h"

#include "vm/assembler.h"
#include "vm/il_printer.h"
#include "vm/log.h"
#include "vm/stack_frame.h"

namespace dart {

intptr_t RegisterSet::RegisterCount(intptr_t registers) {
  // Brian Kernighan's algorithm for counting the bits set.
  intptr_t count = 0;
  while (registers != 0) {
    ++count;
    registers &= (registers - 1);  // Clear the least significant bit set.
  }
  return count;
}

LocationSummary::LocationSummary(Zone* zone,
                                 intptr_t input_count,
                                 intptr_t temp_count,
                                 LocationSummary::ContainsCall contains_call)
    : num_inputs_(input_count),
      num_temps_(temp_count),
      stack_bitmap_(NULL),
      contains_call_(contains_call),
      live_registers_() {
#if defined(DEBUG)
  writable_inputs_ = 0;
#endif
  input_locations_ = zone->Alloc<Location>(num_inputs_);
  temp_locations_ = zone->Alloc<Location>(num_temps_);
}

LocationSummary* LocationSummary::Make(
    Zone* zone,
    intptr_t input_count,
    Location out,
    LocationSummary::ContainsCall contains_call) {
  LocationSummary* summary =
      new (zone) LocationSummary(zone, input_count, 0, contains_call);
  for (intptr_t i = 0; i < input_count; i++) {
    summary->set_in(i, Location::RequiresRegister());
  }
  summary->set_out(0, out);
  return summary;
}

Location Location::Pair(Location first, Location second) {
  PairLocation* pair_location = new PairLocation();
  ASSERT((reinterpret_cast<intptr_t>(pair_location) & kLocationTagMask) == 0);
  pair_location->SetAt(0, first);
  pair_location->SetAt(1, second);
  Location loc(reinterpret_cast<uword>(pair_location) | kPairLocationTag);
  return loc;
}

PairLocation* Location::AsPairLocation() const {
  ASSERT(IsPairLocation());
  return reinterpret_cast<PairLocation*>(value_ & ~kLocationTagMask);
}

Location Location::RegisterOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RequiresRegister();
}

Location Location::RegisterOrSmiConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::RequiresRegister();
}

Location Location::WritableRegisterOrSmiConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::WritableRegister();
}

Location Location::FixedRegisterOrConstant(Value* value, Register reg) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location Location::FixedRegisterOrSmiConstant(Value* value, Register reg) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location Location::AnyOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::Any();
}

// DBC does not have an notion of 'address' in its instruction set.
#if !defined(TARGET_ARCH_DBC)
Address Location::ToStackSlotAddress() const {
  const intptr_t index = stack_index();
  const Register base = base_reg();
  if (base == FPREG) {
    if (index < 0) {
      const intptr_t offset = (kParamEndSlotFromFp - index) * kWordSize;
      return Address(base, offset);
    } else {
      const intptr_t offset = (kFirstLocalSlotFromFp - index) * kWordSize;
      return Address(base, offset);
    }
  } else {
    ASSERT(base == SPREG);
    return Address(base, index * kWordSize);
  }
}
#endif

intptr_t Location::ToStackSlotOffset() const {
  const intptr_t index = stack_index();
  if (base_reg() == FPREG) {
    if (index < 0) {
      const intptr_t offset = (kParamEndSlotFromFp - index) * kWordSize;
      return offset;
    } else {
      const intptr_t offset = (kFirstLocalSlotFromFp - index) * kWordSize;
      return offset;
    }
  } else {
    ASSERT(base_reg() == SPREG);
    return index * kWordSize;
  }
}

const Object& Location::constant() const {
  return constant_instruction()->value();
}

const char* Location::Name() const {
  switch (kind()) {
    case kInvalid:
      return "?";
    case kRegister:
      return Assembler::RegisterName(reg());
    case kFpuRegister:
      return Assembler::FpuRegisterName(fpu_reg());
    case kStackSlot:
      return "S";
    case kDoubleStackSlot:
      return "DS";
    case kQuadStackSlot:
      return "QS";
    case kUnallocated:
      switch (policy()) {
        case kAny:
          return "A";
        case kPrefersRegister:
          return "P";
        case kRequiresRegister:
          return "R";
        case kRequiresFpuRegister:
          return "DR";
        case kWritableRegister:
          return "WR";
        case kSameAsFirstInput:
          return "0";
      }
      UNREACHABLE();
    default:
      if (IsConstant()) {
        return "C";
      } else {
        ASSERT(IsPairLocation());
        return "2P";
      }
  }
  return "?";
}

void Location::PrintTo(BufferFormatter* f) const {
  if (!FLAG_support_il_printer) {
    return;
  }
  if (kind() == kStackSlot) {
    f->Print("S%+" Pd "", stack_index());
  } else if (kind() == kDoubleStackSlot) {
    f->Print("DS%+" Pd "", stack_index());
  } else if (kind() == kQuadStackSlot) {
    f->Print("QS%+" Pd "", stack_index());
  } else if (IsPairLocation()) {
    f->Print("(");
    AsPairLocation()->At(0).PrintTo(f);
    f->Print(", ");
    AsPairLocation()->At(1).PrintTo(f);
    f->Print(")");
  } else {
    f->Print("%s", Name());
  }
}

const char* Location::ToCString() const {
  char buffer[1024];
  BufferFormatter bf(buffer, 1024);
  PrintTo(&bf);
  return Thread::Current()->zone()->MakeCopyOfString(buffer);
}

void Location::Print() const {
  if (kind() == kStackSlot) {
    THR_Print("S%+" Pd "", stack_index());
  } else {
    THR_Print("%s", Name());
  }
}

Location Location::Copy() const {
  if (IsPairLocation()) {
    PairLocation* pair = AsPairLocation();
    ASSERT(!pair->At(0).IsPairLocation());
    ASSERT(!pair->At(1).IsPairLocation());
    return Location::Pair(pair->At(0).Copy(), pair->At(1).Copy());
  } else {
    // Copy by value.
    return *this;
  }
}

Location Location::RemapForSlowPath(Definition* def,
                                    intptr_t* cpu_reg_slots,
                                    intptr_t* fpu_reg_slots) const {
  if (IsRegister()) {
    intptr_t index = cpu_reg_slots[reg()];
    ASSERT(index >= 0);
    return Location::StackSlot(index);
  } else if (IsFpuRegister()) {
    intptr_t index = fpu_reg_slots[fpu_reg()];
    ASSERT(index >= 0);
    switch (def->representation()) {
      case kUnboxedDouble:
        return Location::DoubleStackSlot(index);

      case kUnboxedFloat32x4:
      case kUnboxedInt32x4:
      case kUnboxedFloat64x2:
        return Location::QuadStackSlot(index);

      default:
        UNREACHABLE();
    }
  } else if (IsPairLocation()) {
    ASSERT(def->representation() == kUnboxedInt64);
    PairLocation* value_pair = AsPairLocation();
    intptr_t index_lo;
    intptr_t index_hi;

    if (value_pair->At(0).IsRegister()) {
      index_lo = cpu_reg_slots[value_pair->At(0).reg()];
    } else {
      ASSERT(value_pair->At(0).IsStackSlot());
      index_lo = value_pair->At(0).stack_index();
    }

    if (value_pair->At(1).IsRegister()) {
      index_hi = cpu_reg_slots[value_pair->At(1).reg()];
    } else {
      ASSERT(value_pair->At(1).IsStackSlot());
      index_hi = value_pair->At(1).stack_index();
    }

    return Location::Pair(Location::StackSlot(index_lo),
                          Location::StackSlot(index_hi));
  } else if (IsInvalid() && def->IsMaterializeObject()) {
    def->AsMaterializeObject()->RemapRegisters(cpu_reg_slots, fpu_reg_slots);
    return *this;
  }

  return *this;
}

void LocationSummary::PrintTo(BufferFormatter* f) const {
  if (!FLAG_support_il_printer) {
    return;
  }
  if (input_count() > 0) {
    f->Print(" (");
    for (intptr_t i = 0; i < input_count(); i++) {
      if (i != 0) f->Print(", ");
      in(i).PrintTo(f);
    }
    f->Print(")");
  }

  if (temp_count() > 0) {
    f->Print(" [");
    for (intptr_t i = 0; i < temp_count(); i++) {
      if (i != 0) f->Print(", ");
      temp(i).PrintTo(f);
    }
    f->Print("]");
  }

  if (!out(0).IsInvalid()) {
    f->Print(" => ");
    out(0).PrintTo(f);
  }

  if (always_calls()) f->Print(" C");
}

#if defined(DEBUG)
void LocationSummary::DiscoverWritableInputs() {
  if (!HasCallOnSlowPath()) {
    return;
  }

  for (intptr_t i = 0; i < input_count(); i++) {
    if (in(i).IsUnallocated() &&
        (in(i).policy() == Location::kWritableRegister)) {
      writable_inputs_ |= 1 << i;
    }
  }
}

void LocationSummary::CheckWritableInputs() {
  ASSERT(HasCallOnSlowPath());
  for (intptr_t i = 0; i < input_count(); i++) {
    if ((writable_inputs_ & (1 << i)) != 0) {
      // Writable registers have to be manually preserved because
      // with the right representation because register allocator does not know
      // how they are used within the instruction template.
      ASSERT(in(i).IsMachineRegister());
      ASSERT(live_registers()->Contains(in(i)));
    }
  }
}
#endif

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
