// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/locations.h"
#include <limits>

#include "vm/class_id.h"
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/log.h"
#include "vm/stack_frame.h"

namespace dart {

compiler::OperandSize RepresentationUtils::OperandSize(Representation rep) {
  if (rep == kTagged) return compiler::kObjectBytes;

  // Untagged addresses are either loaded from and stored to word size native
  // fields or generated from already-extended tagged addresses when
  // compressed pointers are enabled.
  if (rep == kUntagged) return compiler::kWordBytes;

  if (IsUnboxedInteger(rep)) {
    switch (ValueSize(rep)) {
      case 8:
        ASSERT(!IsUnsignedInteger(rep));
        ASSERT_EQUAL(compiler::target::kWordSize, 8);
        return compiler::kEightBytes;
      case 4:
        return IsUnsignedInteger(rep) ? compiler::kUnsignedFourBytes
                                      : compiler::kFourBytes;
      case 2:
        return IsUnsignedInteger(rep) ? compiler::kUnsignedTwoBytes
                                      : compiler::kTwoBytes;
      case 1:
        return IsUnsignedInteger(rep) ? compiler::kUnsignedByte
                                      : compiler::kByte;
    }
  }

  UNREACHABLE();
  return compiler::kObjectBytes;
}

#define REP_MIN_VALUE_CLAUSE(name, ___, ____, type)                            \
  case k##name:                                                                \
    return static_cast<int64_t>(std::numeric_limits<type>::min());
int64_t RepresentationUtils::MinValue(Representation rep) {
  switch (rep) {
    FOR_EACH_INTEGER_REPRESENTATION_KIND(REP_MIN_VALUE_CLAUSE)
    default:
      UNREACHABLE();
      return kMinInt64;
  }
}
#undef REP_MIN_VALUE_CLAUSE

#define REP_MAX_VALUE_CLAUSE(name, ___, ____, type)                            \
  case k##name:                                                                \
    return static_cast<int64_t>(std::numeric_limits<type>::max());
int64_t RepresentationUtils::MaxValue(Representation rep) {
  switch (rep) {
    FOR_EACH_INTEGER_REPRESENTATION_KIND(REP_MAX_VALUE_CLAUSE)
    default:
      UNREACHABLE();
      return kMaxInt64;
  }
}
#undef REP_MAX_VALUE_CLAUSE

bool RepresentationUtils::IsRepresentable(Representation rep, int64_t value) {
  ASSERT(IsUnboxedInteger(rep));
  const intptr_t bit_size = ValueSize(rep) * kBitsPerByte;
  return IsUnsignedInteger(rep) ? Utils::IsUint(bit_size, value)
                                : Utils::IsInt(bit_size, value);
}

Representation RepresentationUtils::RepresentationOfArrayElement(
    classid_t cid) {
  if (IsTypedDataBaseClassId(cid)) {
    // Normalize typed data cids to the internal cid for the switch statement.
    cid = cid - ((cid - kFirstTypedDataCid) % kNumTypedDataCidRemainders) +
          kTypedDataCidRemainderInternal;
  }
  switch (cid) {
#define ARRAY_CASE(Name) case k##Name##Cid:
    CLASS_LIST_ARRAYS(ARRAY_CASE)
#undef ARRAY_CASE
    case kRecordCid:
    case kTypeArgumentsCid:
      return kTagged;
    case kTypedDataInt8ArrayCid:
      return kUnboxedInt8;
    case kOneByteStringCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid:
    case kExternalTypedDataUint8ArrayCid:
    case kExternalTypedDataUint8ClampedArrayCid:
      return kUnboxedUint8;
    case kTypedDataInt16ArrayCid:
      return kUnboxedInt16;
    case kTwoByteStringCid:
    case kTypedDataUint16ArrayCid:
      return kUnboxedUint16;
    case kTypedDataInt32ArrayCid:
      return kUnboxedInt32;
    case kTypedDataUint32ArrayCid:
      return kUnboxedUint32;
    case kTypedDataInt64ArrayCid:
    case kTypedDataUint64ArrayCid:
      return kUnboxedInt64;
    case kTypedDataFloat32ArrayCid:
      return kUnboxedFloat;
    case kTypedDataFloat64ArrayCid:
      return kUnboxedDouble;
    case kTypedDataInt32x4ArrayCid:
      return kUnboxedInt32x4;
    case kTypedDataFloat32x4ArrayCid:
      return kUnboxedFloat32x4;
    case kTypedDataFloat64x2ArrayCid:
      return kUnboxedFloat64x2;
    default:
      FATAL("Unexpected array cid %u", cid);
      return kTagged;
  }
}

const char* RepresentationUtils::ToCString(Representation repr) {
  switch (repr) {
#define REPR_CASE(Name, PrintName, __, ___)                                    \
  case k##Name:                                                                \
    return #PrintName;
    FOR_EACH_REPRESENTATION_KIND(REPR_CASE)
#undef KIND_CASE
    default:
      UNREACHABLE();
  }
  return nullptr;
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
      stack_bitmap_(nullptr),
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
             loc.policy() == Location::kRequiresStack);
    } else if (loc.IsPairLocation()) {
      ASSERT(!loc.AsPairLocation()->At(0).IsUnallocated() ||
             loc.AsPairLocation()->At(0).policy() == Location::kAny ||
             loc.AsPairLocation()->At(0).policy() == Location::kRequiresStack);
      ASSERT(!loc.AsPairLocation()->At(1).IsUnallocated() ||
             loc.AsPairLocation()->At(1).policy() == Location::kAny ||
             loc.AsPairLocation()->At(1).policy() == Location::kRequiresStack);
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

Location Location::ToSpRelative(intptr_t fp_to_sp_delta) const {
  if (IsPairLocation()) {
    auto pair = AsPairLocation();
    return Pair(pair->At(0).ToSpRelative(fp_to_sp_delta),
                pair->At(1).ToSpRelative(fp_to_sp_delta));
  }

  if (HasStackIndex()) {
    ASSERT(base_reg() == FPREG);
    uword payload = StackSlotBaseField::encode(SPREG) |
                    StackIndexField::encode(stack_index() - fp_to_sp_delta);
    return Location(kind(), payload);
  }

  return *this;
}

Location Location::ToEntrySpRelative() const {
  const auto fp_to_entry_sp_delta =
      (compiler::target::frame_layout.param_end_from_fp + 1) -
      compiler::target::frame_layout.last_param_from_entry_sp;
  return ToSpRelative(fp_to_entry_sp_delta);
}

Location Location::ToCallerSpRelative() const {
  const auto fp_to_caller_sp_delta =
      (compiler::target::frame_layout.param_end_from_fp + 1);
  return ToSpRelative(fp_to_caller_sp_delta);
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
  return ((constant != nullptr) &&
          compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RequiresRegister();
}

Location LocationRegisterOrSmiConstant(Value* value,
                                       intptr_t min_value,
                                       intptr_t max_value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if (constant == nullptr) {
    return Location::RequiresRegister();
  }
  if (!compiler::Assembler::IsSafeSmi(constant->value())) {
    return Location::RequiresRegister();
  }
  const intptr_t smi_value = value->BoundSmiConstant();
  if (smi_value < min_value || smi_value > max_value) {
    return Location::RequiresRegister();
  }
  return Location::Constant(constant);
}

Location LocationWritableRegisterOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != nullptr) &&
          compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::WritableRegister();
}

Location LocationWritableRegisterOrSmiConstant(Value* value,
                                               intptr_t min_value,
                                               intptr_t max_value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  if (constant == nullptr) {
    return Location::WritableRegister();
  }
  if (!compiler::Assembler::IsSafeSmi(constant->value())) {
    return Location::WritableRegister();
  }
  const intptr_t smi_value = value->BoundSmiConstant();
  if (smi_value < min_value || smi_value > max_value) {
    return Location::WritableRegister();
  }
  return Location::Constant(constant);
}

Location LocationFixedRegisterOrConstant(Value* value, Register reg) {
  ASSERT(((1 << reg) & kDartAvailableCpuRegs) != 0);
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != nullptr) &&
          compiler::Assembler::IsSafe(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location LocationFixedRegisterOrSmiConstant(Value* value, Register reg) {
  ASSERT(((1 << reg) & kDartAvailableCpuRegs) != 0);
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != nullptr) &&
          compiler::Assembler::IsSafeSmi(constant->value()))
             ? Location::Constant(constant)
             : Location::RegisterLocation(reg);
}

Location LocationAnyOrConstant(Value* value) {
  ConstantInstr* constant = value->definition()->AsConstant();
  return ((constant != nullptr) &&
          compiler::Assembler::IsSafe(constant->value()))
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
        case kWritableRegister:
          return "WR";
        case kSameAsFirstInput:
          return "0";
        case kRequiresStack:
          return "RS";
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
  if (kind() == kStackSlot || kind() == kDoubleStackSlot ||
      kind() == kQuadStackSlot) {
    const char* suffix = "";
    if (kind() == kDoubleStackSlot) {
      suffix = " f64";
    } else if (kind() == kQuadStackSlot) {
      suffix = " f128";
    }
    f->Printf("%s[%" Pd "]%s", base_reg() == FPREG ? "fp" : "sp", stack_index(),
              suffix);
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
  if (kind() == kStackSlot || kind() == kDoubleStackSlot ||
      kind() == kQuadStackSlot) {
    const char* suffix = "";
    if (kind() == kDoubleStackSlot) {
      suffix = " f64";
    } else if (kind() == kQuadStackSlot) {
      suffix = " f128";
    }
    THR_Print("%s[%" Pd "] %s", base_reg() == FPREG ? "fp" : "sp",
              stack_index(), suffix);
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
