// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi.h"
#include "vm/compiler/runtime_api.h"

namespace dart {

namespace compiler {

namespace ffi {

#if defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_ARM64) ||                  \
    defined(TARGET_ARCH_IA32)

static const size_t kSizeUnknown = 0;

static const intptr_t kNumElementSizes = kFfiVoidCid - kFfiPointerCid + 1;

static const size_t element_size_table[kNumElementSizes] = {
    target::kWordSize,  // kFfiPointerCid
    kSizeUnknown,       // kFfiNativeFunctionCid
    1,                  // kFfiInt8Cid
    2,                  // kFfiInt16Cid
    4,                  // kFfiInt32Cid
    8,                  // kFfiInt64Cid
    1,                  // kFfiUint8Cid
    2,                  // kFfiUint16Cid
    4,                  // kFfiUint32Cid
    8,                  // kFfiUint64Cid
    target::kWordSize,  // kFfiIntPtrCid
    4,                  // kFfiFloatCid
    8,                  // kFfiDoubleCid
    kSizeUnknown,       // kFfiVoidCid
};

size_t ElementSizeInBytes(intptr_t class_id) {
  ASSERT(class_id != kFfiNativeFunctionCid);
  ASSERT(class_id != kFfiVoidCid);
  if (!RawObject::IsFfiTypeClassId(class_id)) {
    // subtype of Pointer
    class_id = kFfiPointerCid;
  }
  intptr_t index = class_id - kFfiPointerCid;
  return element_size_table[index];
}

#if !defined(DART_PRECOMPILED_RUNTIME)

Representation TypeRepresentation(const AbstractType& result_type) {
  switch (result_type.type_class_id()) {
    case kFfiFloatCid:
      return kUnboxedFloat;
    case kFfiDoubleCid:
      return kUnboxedDouble;
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
      return kUnboxedInt32;
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
      return kUnboxedUint32;
    case kFfiInt64Cid:
    case kFfiUint64Cid:
      return kUnboxedInt64;
    case kFfiIntPtrCid:
    case kFfiPointerCid:
    default:  // Subtypes of Pointer.
      return kUnboxedIntPtr;
  }
}

bool NativeTypeIsVoid(const AbstractType& result_type) {
  return result_type.type_class_id() == kFfiVoidCid;
}

bool NativeTypeIsPointer(const AbstractType& result_type) {
  switch (result_type.type_class_id()) {
    case kFfiVoidCid:
    case kFfiFloatCid:
    case kFfiDoubleCid:
    case kFfiInt8Cid:
    case kFfiInt16Cid:
    case kFfiInt32Cid:
    case kFfiUint8Cid:
    case kFfiUint16Cid:
    case kFfiUint32Cid:
    case kFfiInt64Cid:
    case kFfiUint64Cid:
    case kFfiIntPtrCid:
      return false;
    case kFfiPointerCid:
    default:
      return true;
  }
}

// Converts a Ffi [signature] to a list of Representations.
// Note that this ignores first argument (receiver) which is dynamic.
ZoneGrowableArray<Representation>* ArgumentRepresentations(
    const Function& signature) {
  intptr_t num_arguments = signature.num_fixed_parameters() - 1;
  auto result = new ZoneGrowableArray<Representation>(num_arguments);
  for (intptr_t i = 0; i < num_arguments; i++) {
    AbstractType& arg_type =
        AbstractType::Handle(signature.ParameterTypeAt(i + 1));
    result->Add(TypeRepresentation(arg_type));
  }
  return result;
}

// Represents the state of a stack frame going into a call, between allocations
// of argument locations. Acts like a register allocator but for arguments in
// the native ABI.
class ArgumentFrameState : public ValueObject {
 public:
  Location AllocateArgument(Representation rep) {
    switch (rep) {
      case kUnboxedInt64:
      case kUnboxedUint32:
      case kUnboxedInt32:
        if (rep == kUnboxedInt64) {
          ASSERT(compiler::target::kWordSize == 8);
        }
        if (cpu_regs_used < CallingConventions::kNumArgRegs) {
          Location result = Location::RegisterLocation(
              CallingConventions::ArgumentRegisters[cpu_regs_used]);
          cpu_regs_used++;
          if (CallingConventions::kArgumentIntRegXorFpuReg) {
            fpu_regs_used++;
          }
          return result;
        }
        break;
      case kUnboxedFloat:
      case kUnboxedDouble:
        if (fpu_regs_used < CallingConventions::kNumFpuArgRegs) {
          Location result = Location::FpuRegisterLocation(
              CallingConventions::FpuArgumentRegisters[fpu_regs_used]);
          fpu_regs_used++;
          if (CallingConventions::kArgumentIntRegXorFpuReg) {
            cpu_regs_used++;
          }
          return result;
        }
        break;
      default:
        UNREACHABLE();
    }

    // Argument must be spilled.
    const intptr_t stack_slots_needed =
        rep == kUnboxedDouble || rep == kUnboxedInt64
            ? 8 / compiler::target::kWordSize
            : 1;
    Location result =
        stack_slots_needed == 1
            ? Location::StackSlot(stack_height_in_slots, SPREG)
            : Location::DoubleStackSlot(stack_height_in_slots, SPREG);
    stack_height_in_slots += stack_slots_needed;
    return result;
  }

  intptr_t cpu_regs_used = 0;
  intptr_t fpu_regs_used = 0;
  intptr_t stack_height_in_slots = 0;
};

// Takes a list of argument representations, and converts it to a list of
// argument locations based on calling convention.
ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps) {
  intptr_t num_arguments = arg_reps.length();
  auto result = new ZoneGrowableArray<Location>(num_arguments);

  // Loop through all arguments and assign a register or a stack location.
  ArgumentFrameState frame_state;
  for (intptr_t i = 0; i < num_arguments; i++) {
    Representation rep = arg_reps[i];
    if (rep == kUnboxedInt64 && compiler::target::kWordSize < 8) {
      Location low_bits_loc = frame_state.AllocateArgument(kUnboxedInt32);
      Location high_bits_loc = frame_state.AllocateArgument(kUnboxedInt32);
      ASSERT(low_bits_loc.IsStackSlot() == high_bits_loc.IsStackSlot());
      result->Add(Location::Pair(low_bits_loc, high_bits_loc));
    } else {
      result->Add(frame_state.AllocateArgument(rep));
    }
  }
  return result;
}

Representation ResultRepresentation(const Function& signature) {
  AbstractType& arg_type = AbstractType::Handle(signature.result_type());
  return TypeRepresentation(arg_type);
}

Location ResultLocation(Representation result_rep) {
  switch (result_rep) {
    case kUnboxedInt32:
    case kUnboxedUint32:
      return Location::RegisterLocation(CallingConventions::kReturnReg);
    case kUnboxedInt64:
      if (compiler::target::kWordSize == 4) {
        return Location::Pair(
            Location::RegisterLocation(CallingConventions::kReturnReg),
            Location::RegisterLocation(CallingConventions::kSecondReturnReg));
      } else {
        return Location::RegisterLocation(CallingConventions::kReturnReg);
      }
    case kUnboxedFloat:
    case kUnboxedDouble:
#if defined(TARGET_ARCH_IA32)
      // The result is returned in ST0, but we don't allocate ST registers, so
      // the FFI trampoline will move it to XMM0.
      return Location::FpuRegisterLocation(XMM0);
#else
      return Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg);
#endif
    default:
      UNREACHABLE();
  }
}

intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations) {
  intptr_t num_arguments = locations.length();
  intptr_t num_stack_slots = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    if (locations.At(i).IsStackSlot()) {
      num_stack_slots++;
    } else if (locations.At(i).IsDoubleStackSlot()) {
      num_stack_slots += 8 / compiler::target::kWordSize;
    } else if (locations.At(i).IsPairLocation()) {
      num_stack_slots +=
          locations.At(i).AsPairLocation()->At(0).IsStackSlot() ? 1 : 0;
      num_stack_slots +=
          locations.At(i).AsPairLocation()->At(1).IsStackSlot() ? 1 : 0;
    }
  }
  return num_stack_slots;
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#else

size_t ElementSizeInBytes(intptr_t class_id) {
  UNREACHABLE();
}

#endif  // defined(TARGET_ARCH_X64) || defined(TARGET_ARCH_IA32)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
