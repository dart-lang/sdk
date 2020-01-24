// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_calling_convention.h"

#include "vm/compiler/ffi/frame_rebase.h"
#include "vm/log.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

#if !defined(DART_PRECOMPILED_RUNTIME)

Representation TypeRepresentation(classid_t class_id) {
  switch (class_id) {
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
      return kUnboxedIntPtr;
    case kFfiPointerCid:
    case kFfiVoidCid:
      return kUnboxedFfiIntPtr;
    default:
      UNREACHABLE();
  }
}

SmallRepresentation TypeSmallRepresentation(const AbstractType& ffi_type) {
  switch (ffi_type.type_class_id()) {
    case kFfiInt8Cid:
      return kSmallUnboxedInt8;
    case kFfiInt16Cid:
      return kSmallUnboxedInt16;
    case kFfiUint8Cid:
      return kSmallUnboxedUint8;
    case kFfiUint16Cid:
      return kSmallUnboxedUint16;
    default:
      return kNoSmallRepresentation;
  }
}

bool NativeTypeIsVoid(const AbstractType& result_type) {
  return result_type.type_class_id() == kFfiVoidCid;
}

bool NativeTypeIsPointer(const AbstractType& result_type) {
  return result_type.type_class_id() == kFfiPointerCid;
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
    Representation rep = TypeRepresentation(arg_type.type_class_id());
    // In non simulator mode host::CallingConventions == CallingConventions.
    // In simulator mode convert arguments to host representation.
    if (rep == kUnboxedFloat && CallingConventions::kAbiSoftFP) {
      rep = kUnboxedInt32;
    } else if (rep == kUnboxedDouble && CallingConventions::kAbiSoftFP) {
      rep = kUnboxedInt64;
    }
    result->Add(rep);
  }
  return result;
}

Representation ResultRepresentation(const Function& signature) {
  AbstractType& arg_type = AbstractType::Handle(signature.result_type());
  Representation rep = TypeRepresentation(arg_type.type_class_id());
  if (rep == kUnboxedFloat && CallingConventions::kAbiSoftFP) {
    rep = kUnboxedInt32;
  } else if (rep == kUnboxedDouble && CallingConventions::kAbiSoftFP) {
    rep = kUnboxedInt64;
  }
  return rep;
}

// Represents the state of a stack frame going into a call, between allocations
// of argument locations. Acts like a register allocator but for arguments in
// the native ABI.
class ArgumentAllocator : public ValueObject {
 public:
  Location AllocateArgument(Representation rep) {
    switch (rep) {
      case kUnboxedFloat:
      case kUnboxedDouble: {
        Location result = AllocateFpuRegister();
        if (!result.IsUnallocated()) return result;
        break;
      }
      case kUnboxedInt64:
      case kUnboxedUint32:
      case kUnboxedInt32: {
        Location result = rep == kUnboxedInt64 && target::kWordSize == 4
                              ? AllocateAlignedRegisterPair()
                              : AllocateCpuRegister();
        if (!result.IsUnallocated()) return result;
        break;
      }
      default:
        UNREACHABLE();
    }

    // Argument must be spilled.
    if (rep == kUnboxedInt64 && target::kWordSize == 4) {
      return AllocateAlignedStackSlots(rep);
    } else if (rep == kUnboxedDouble) {
      // By convention, we always use DoubleStackSlot for doubles, even on
      // 64-bit systems.
      ASSERT(!CallingConventions::kAlignArguments);
      return AllocateDoubleStackSlot();
    } else {
      return AllocateStackSlot();
    }
  }

 private:
  Location AllocateStackSlot() {
    return Location::StackSlot(stack_height_in_slots++,
                               CallingConventions::kStackPointerRegister);
  }

  Location AllocateDoubleStackSlot() {
    const Location result = Location::DoubleStackSlot(
        stack_height_in_slots, CallingConventions::kStackPointerRegister);
    stack_height_in_slots += 8 / target::kWordSize;
    return result;
  }

  // Allocates a pair of stack slots where the first stack slot is aligned to an
  // 8-byte boundary, if necessary.
  Location AllocateAlignedStackSlots(Representation rep) {
    if (CallingConventions::kAlignArguments && target::kWordSize == 4) {
      stack_height_in_slots += stack_height_in_slots % 2;
    }

    Location result;
    if (rep == kUnboxedDouble) {
      result = Location::DoubleStackSlot(
          stack_height_in_slots, CallingConventions::kStackPointerRegister);
      stack_height_in_slots += 2;
    } else {
      const Location low = AllocateStackSlot();
      const Location high = AllocateStackSlot();
      result = Location::Pair(low, high);
    }
    return result;
  }

  Location AllocateFpuRegister() {
    if (fpu_regs_used == CallingConventions::kNumFpuArgRegs) {
      return Location::RequiresFpuRegister();
    }

    const Location result = Location::FpuRegisterLocation(
        CallingConventions::FpuArgumentRegisters[fpu_regs_used]);
    fpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      cpu_regs_used++;
    }
    return result;
  }

  Location AllocateCpuRegister() {
    if (cpu_regs_used == CallingConventions::kNumArgRegs) {
      return Location::RequiresRegister();
    }

    const Location result = Location::RegisterLocation(
        CallingConventions::ArgumentRegisters[cpu_regs_used]);
    cpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      fpu_regs_used++;
    }
    return result;
  }

  // Allocates a pair of registers where the first register index is even, if
  // necessary.
  Location AllocateAlignedRegisterPair() {
    if (CallingConventions::kAlignArguments) {
      cpu_regs_used += cpu_regs_used % 2;
    }
    if (cpu_regs_used > CallingConventions::kNumArgRegs - 2) {
      return Location::Any();
    }
    return Location::Pair(AllocateCpuRegister(), AllocateCpuRegister());
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
  ArgumentAllocator frame_state;
  for (intptr_t i = 0; i < num_arguments; i++) {
    Representation rep = arg_reps[i];
    result->Add(frame_state.AllocateArgument(rep));
  }
  return result;
}

Location ResultLocation(Representation result_rep) {
  switch (result_rep) {
    case kUnboxedFloat:
    case kUnboxedDouble:
#if defined(TARGET_ARCH_IA32)
      // The result is returned in ST0, but we don't allocate ST registers, so
      // the FFI trampoline will move it to XMM0.
      return Location::FpuRegisterLocation(XMM0);
#else
      return Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg);
#endif
    case kUnboxedInt32:
    case kUnboxedUint32:
      return Location::RegisterLocation(CallingConventions::kReturnReg);
    case kUnboxedInt64:
      if (target::kWordSize == 4) {
        return Location::Pair(
            Location::RegisterLocation(CallingConventions::kReturnReg),
            Location::RegisterLocation(CallingConventions::kSecondReturnReg));
      } else {
        return Location::RegisterLocation(CallingConventions::kReturnReg);
      }
    default:
      UNREACHABLE();
  }
}

// Accounts for alignment, where some stack slots are used as padding.
intptr_t NumStackSlots(const ZoneGrowableArray<Location>& locations) {
  intptr_t num_arguments = locations.length();
  intptr_t max_height_in_slots = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    intptr_t height = 0;
    if (locations.At(i).IsStackSlot()) {
      height = locations.At(i).stack_index() + 1;
    } else if (locations.At(i).IsDoubleStackSlot()) {
      height = locations.At(i).stack_index() + 8 / target::kWordSize;
    } else if (locations.At(i).IsPairLocation()) {
      const Location first = locations.At(i).AsPairLocation()->At(0);
      const Location second = locations.At(i).AsPairLocation()->At(1);
      height =
          Utils::Maximum(first.IsStackSlot() ? first.stack_index() + 1 : 0,
                         second.IsStackSlot() ? second.stack_index() + 1 : 0);
    }
    max_height_in_slots = Utils::Maximum(height, max_height_in_slots);
  }
  return max_height_in_slots;
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
