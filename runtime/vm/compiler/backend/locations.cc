// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/locations.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/log.h"
#include "vm/stack_frame.h"

namespace dart {

#define REP_IN_SET_CLAUSE(name, __, ___)                                       \
  case k##name:                                                                \
    return true;
#define REP_SIZEOF_CLAUSE(name, __, type)                                      \
  case k##name:                                                                \
    return sizeof(type);
#define REP_IS_UNSIGNED_CLAUSE(name, unsigned, ___)                            \
  case k##name:                                                                \
    return unsigned;

bool RepresentationUtils::IsUnboxedInteger(Representation rep) {
  switch (rep) {
    FOR_EACH_INTEGER_REPRESENTATION_KIND(REP_IN_SET_CLAUSE)
    default:
      return false;
  }
}

bool RepresentationUtils::IsUnboxed(Representation rep) {
  switch (rep) {
    FOR_EACH_UNBOXED_REPRESENTATION_KIND(REP_IN_SET_CLAUSE)
    default:
      return false;
  }
}

size_t RepresentationUtils::ValueSize(Representation rep) {
  switch (rep) {
    FOR_EACH_SIMPLE_REPRESENTATION_KIND(REP_SIZEOF_CLAUSE)
    default:
      UNREACHABLE();
      return compiler::target::kWordSize;
  }
}

bool RepresentationUtils::IsUnsigned(Representation rep) {
  switch (rep) {
    FOR_EACH_SIMPLE_REPRESENTATION_KIND(REP_IS_UNSIGNED_CLAUSE)
    default:
      UNREACHABLE();
      return false;
  }
}

#undef REP_IS_UNSIGNED_CLAUSE
#undef REP_SIZEOF_CLAUSE
#undef REP_IN_SET_CLAUSE

const char* Location::RepresentationToCString(Representation repr) {
  switch (repr) {
#define REPR_CASE(Name, __, ___)                                               \
  case k##Name:                                                                \
    return #Name;
    FOR_EACH_REPRESENTATION_KIND(REPR_CASE)
#undef KIND_CASE
    default:
      UNREACHABLE();
  }
  return nullptr;
}

bool Location::ParseRepresentation(const char* str, Representation* out) {
  ASSERT(str != nullptr && out != nullptr);
#define KIND_CASE(Name, __, ___)                                               \
  if (strcmp(str, #Name) == 0) {                                               \
    *out = k##Name;                                                            \
    return true;                                                               \
  }
  FOR_EACH_REPRESENTATION_KIND(KIND_CASE)
#undef KIND_CASE
  return false;
}

intptr_t RegisterSet::RegisterCount(intptr_t registers) {
  // Brian Kernighan's algorithm for counting the bits set.
  intptr_t count = 0;
  while (registers != 0) {
    ++count;
    // Clear the least significant bit set.
    registers &= (static_cast<uintptr_t>(registers) - 1);
  }
  return count;
}

void RegisterSet::DebugPrint() {
  for (intptr_t i = 0; i < kNumberOfCpuRegisters; i++) {
    Register r = static_cast<Register>(i);
    if (ContainsRegister(r)) {
      THR_Print("%s %s\n", RegisterNames::RegisterName(r),
                IsTagged(r) ? "tagged" : "untagged");
    }
  }

  for (intptr_t i = 0; i < kNumberOfFpuRegisters; i++) {
    FpuRegister r = static_cast<FpuRegister>(i);
    if (ContainsFpuRegister(r)) {
      THR_Print("%s\n", RegisterNames::FpuRegisterName(r));
    }
  }
}

LocationSummary::LocationSummary(Zone* zone,
                                 intptr_t input_count,
                                 intptr_t temp_count,
                                 LocationSummary::ContainsCall contains_call)
    : num_inputs_(input_count),
      num_temps_(temp_count),
      output_location_(),  // out(0)->IsInvalid() unless later set.
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

static bool ValidOutputForAlwaysCalls(const Location& loc) {
  return loc.IsMachineRegister() || loc.IsInvalid() || loc.IsPairLocation();
}

void LocationSummary::set_in(intptr_t index, Location loc) {
  ASSERT(index >= 0);
  ASSERT(index < num_inputs_);
#if defined(DEBUG)
  // See FlowGraphAllocator::ProcessOneInstruction for explanation of these
  // restrictions.
  if (always_calls()) {
    if (loc.IsUnallocated()) {
      ASSERT(loc.policy() == Location::kAny ||
             loc.policy() == Location::kRequiresStackSlot);
    } else if (loc.IsPairLocation()) {
      ASSERT(!loc.AsPairLocation()->At(0).IsUnallocated() ||
             loc.AsPairLocation()->At(0).policy() == Location::kAny);
      ASSERT(!loc.AsPairLocation()->At(0).IsUnallocated() ||
             loc.AsPairLocation()->At(0).policy() == Location::kAny);
    }
    if (index == 0 && out(0).IsUnallocated() &&
        out(0).policy() == Location::kSameAsFirstInput) {
      ASSERT(ValidOutputForAlwaysCalls(loc));
    }
  }
#endif
  input_locations_[index] = loc;
}

void LocationSummary::set_out(intptr_t index, Location loc) {
  ASSERT(index == 0);
  ASSERT(!always_calls() || ValidOutputForAlwaysCalls(loc) ||
         (loc.IsUnallocated() && loc.policy() == Location::kSameAsFirstInput &&
          num_inputs_ > 0 && ValidOutputForAlwaysCalls(in(0))));
  output_location_ = loc;
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

Location Location::Component(intptr_t i) const {
  return AsPairLocation()->At(i);
}

Location LocationRegisterOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RequiresRegister();
}

Location LocationRegisterOrSmiConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) &&
          compiler::Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::RequiresRegister();
}

Location LocationWritableRegisterOrSmiConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) &&
          compiler::Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::WritableRegister();
}

Location LocationFixedRegisterOrConstant(Value* value, Register reg) {
  ASSERT(((1 << reg) & kDartAvailableCpuRegs) != 0);
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location LocationFixedRegisterOrSmiConstant(Value* value, Register reg) {
  ASSERT(((1 << reg) & kDartAvailableCpuRegs) != 0);
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) &&
          compiler::Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location LocationAnyOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != NULL) && compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::Any();
}

compiler::Address LocationToStackSlotAddress(Location loc) {
  return compiler::Address(loc.base_reg(), loc.ToStackSlotOffset());
}

intptr_t Location::ToStackSlotOffset() const {
  return stack_index() * compiler::target::kWordSize;
}

const Object& Location::constant() const {
  return constant_instruction()->value();
}

const char* Location::Name() const {
  switch (kind()) {
    case kInvalid:
      return "?";
    case kRegister:
      return RegisterNames::RegisterName(reg());
    case kFpuRegister:
      return RegisterNames::FpuRegisterName(fpu_reg());
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
        case kRequiresStackSlot:
          return "RS";
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

void Location::PrintTo(BaseTextBuffer* f) const {
  if (!FLAG_support_il_printer) {
    return;
  }
  if (kind() == kStackSlot) {
    f->Printf("S%+" Pd "", stack_index());
  } else if (kind() == kDoubleStackSlot) {
    f->Printf("DS%+" Pd "", stack_index());
  } else if (kind() == kQuadStackSlot) {
    f->Printf("QS%+" Pd "", stack_index());
  } else if (IsPairLocation()) {
    f->AddString("(");
    AsPairLocation()->At(0).PrintTo(f);
    f->AddString(", ");
    AsPairLocation()->At(1).PrintTo(f);
    f->AddString(")");
  } else {
    f->Printf("%s", Name());
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

Location LocationArgumentsDescriptorLocation() {
  return Location::RegisterLocation(ARGS_DESC_REG);
}

Location LocationExceptionLocation() {
  return Location::RegisterLocation(kExceptionObjectReg);
}

Location LocationStackTraceLocation() {
  return Location::RegisterLocation(kStackTraceObjectReg);
}

Location LocationRemapForSlowPath(Location loc,
                                  Definition* def,
                                  intptr_t* cpu_reg_slots,
                                  intptr_t* fpu_reg_slots) {
  if (loc.IsRegister()) {
    intptr_t index = cpu_reg_slots[loc.reg()];
    ASSERT(index >= 0);
    return Location::StackSlot(
        compiler::target::frame_layout.FrameSlotForVariableIndex(-index),
        FPREG);
  } else if (loc.IsFpuRegister()) {
    intptr_t index = fpu_reg_slots[loc.fpu_reg()];
    ASSERT(index >= 0);
    switch (def->representation()) {
      case kUnboxedDouble:  // SlowPathEnvironmentFor sees _one_ register
      case kUnboxedFloat:   // both for doubles and floats.
        return Location::DoubleStackSlot(
            compiler::target::frame_layout.FrameSlotForVariableIndex(-index),
            FPREG);

      case kUnboxedFloat32x4:
      case kUnboxedInt32x4:
      case kUnboxedFloat64x2:
        return Location::QuadStackSlot(
            compiler::target::frame_layout.FrameSlotForVariableIndex(-index),
            FPREG);

      default:
        UNREACHABLE();
    }
  } else if (loc.IsPairLocation()) {
    ASSERT(def->representation() == kUnboxedInt64);
    PairLocation* value_pair = loc.AsPairLocation();
    intptr_t index_lo;
    intptr_t index_hi;

    if (value_pair->At(0).IsRegister()) {
      index_lo = compiler::target::frame_layout.FrameSlotForVariableIndex(
          -cpu_reg_slots[value_pair->At(0).reg()]);
    } else {
      ASSERT(value_pair->At(0).IsStackSlot());
      index_lo = value_pair->At(0).stack_index();
    }

    if (value_pair->At(1).IsRegister()) {
      index_hi = compiler::target::frame_layout.FrameSlotForVariableIndex(
          -cpu_reg_slots[value_pair->At(1).reg()]);
    } else {
      ASSERT(value_pair->At(1).IsStackSlot());
      index_hi = value_pair->At(1).stack_index();
    }

    return Location::Pair(Location::StackSlot(index_lo, FPREG),
                          Location::StackSlot(index_hi, FPREG));
  } else if (loc.IsInvalid() && def->IsMaterializeObject()) {
    def->AsMaterializeObject()->RemapRegisters(cpu_reg_slots, fpu_reg_slots);
    return loc;
  }

  return loc;
}

void LocationSummary::PrintTo(BaseTextBuffer* f) const {
  if (!FLAG_support_il_printer) {
    return;
  }
  if (input_count() > 0) {
    f->AddString(" (");
    for (intptr_t i = 0; i < input_count(); i++) {
      if (i != 0) f->AddString(", ");
      in(i).PrintTo(f);
    }
    f->AddString(")");
  }

  if (temp_count() > 0) {
    f->AddString(" [");
    for (intptr_t i = 0; i < temp_count(); i++) {
      if (i != 0) f->AddString(", ");
      temp(i).PrintTo(f);
    }
    f->AddString("]");
  }

  if (!out(0).IsInvalid()) {
    f->AddString(" => ");
    out(0).PrintTo(f);
  }

  if (always_calls()) f->AddString(" C");
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
