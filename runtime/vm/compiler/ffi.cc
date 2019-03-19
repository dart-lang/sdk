// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi.h"

namespace dart {

namespace compiler {

namespace ffi {

#if defined(TARGET_ARCH_X64)

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

// Takes a list of argument representations, and converts it to a list of
// argument locations based on calling convention.
ZoneGrowableArray<Location>* ArgumentLocations(
    const ZoneGrowableArray<Representation>& arg_reps) {
  intptr_t num_arguments = arg_reps.length();
  auto result = new ZoneGrowableArray<Location>(num_arguments);
  result->FillWith(Location(), 0, num_arguments);
  Location* data = result->data();

  // Loop through all arguments and assign a register or a stack location.
  intptr_t regs_used = 0;
  intptr_t xmm_regs_used = 0;
  intptr_t nth_stack_argument = 0;
  bool on_stack;
  for (intptr_t i = 0; i < num_arguments; i++) {
    on_stack = true;
    switch (arg_reps.At(i)) {
      case kUnboxedInt32:
      case kUnboxedUint32:
      case kUnboxedInt64:
        if (regs_used < CallingConventions::kNumArgRegs) {
          data[i] = Location::RegisterLocation(
              CallingConventions::ArgumentRegisters[regs_used]);
          regs_used++;
          if (CallingConventions::kArgumentIntRegXorXmmReg) {
            xmm_regs_used++;
          }
          on_stack = false;
        }
        break;
      case kUnboxedFloat:
      case kUnboxedDouble:
        if (xmm_regs_used < CallingConventions::kNumXmmArgRegs) {
          data[i] = Location::FpuRegisterLocation(
              CallingConventions::XmmArgumentRegisters[xmm_regs_used]);
          xmm_regs_used++;
          if (CallingConventions::kArgumentIntRegXorXmmReg) {
            regs_used++;
          }
          on_stack = false;
        }
        break;
      default:
        UNREACHABLE();
    }
    if (on_stack) {
      data[i] = Location::StackSlot(nth_stack_argument, RSP);
      nth_stack_argument++;
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
    case kUnboxedInt64:
      return Location::RegisterLocation(CallingConventions::kReturnReg);
    case kUnboxedFloat:
    case kUnboxedDouble:
      return Location::FpuRegisterLocation(CallingConventions::kReturnFpuReg);
    default:
      UNREACHABLE();
  }
}

intptr_t NumStackArguments(const ZoneGrowableArray<Location>& locations) {
  intptr_t num_arguments = locations.length();
  intptr_t num_stack_arguments = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    if (locations.At(i).IsStackSlot()) {
      num_stack_arguments++;
    }
  }
  return num_stack_arguments;
}

#else

size_t ElementSizeInBytes(intptr_t class_id) {
  UNREACHABLE();
}

#endif

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
