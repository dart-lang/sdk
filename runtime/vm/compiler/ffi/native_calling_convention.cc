// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_calling_convention.h"

#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/log.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

#if !defined(DART_PRECOMPILED_RUNTIME)

// Argument #0 is the function pointer.
const intptr_t kNativeParamsStartAt = 1;

bool RequiresSoftFpConversion(const NativeType& in) {
  return CallingConventions::kAbiSoftFP && in.IsFloat();
}

const NativeType& ConvertToSoftFp(const NativeType& rep, Zone* zone) {
  if (RequiresSoftFpConversion(rep)) {
    ASSERT(rep.IsFloat());
    if (rep.SizeInBytes() == 4) {
      return *new (zone) NativeFundamentalType(kInt32);
    }
    if (rep.SizeInBytes() == 8) {
      return *new (zone) NativeFundamentalType(kInt64);
    }
  }
  return rep;
}

// Representations of the arguments to a C signature function.
static ZoneGrowableArray<const NativeType*>& ArgumentRepresentations(
    const Function& signature,
    Zone* zone) {
  const intptr_t num_arguments =
      signature.num_fixed_parameters() - kNativeParamsStartAt;
  auto& result = *new ZoneGrowableArray<const NativeType*>(zone, num_arguments);
  for (intptr_t i = 0; i < num_arguments; i++) {
    AbstractType& arg_type = AbstractType::Handle(
        zone, signature.ParameterTypeAt(i + kNativeParamsStartAt));
    const auto& rep = NativeType::FromAbstractType(arg_type, zone);
    result.Add(&rep);
  }
  return result;
}

// Representation of the result of a C signature function.
static NativeType& ResultRepresentation(const Function& signature, Zone* zone) {
  AbstractType& result_type =
      AbstractType::Handle(zone, signature.result_type());
  return NativeType::FromAbstractType(result_type, zone);
}

// Represents the state of a stack frame going into a call, between allocations
// of argument locations.
class ArgumentAllocator : public ValueObject {
 public:
  explicit ArgumentAllocator(Zone* zone) : zone_(zone) {}

  const NativeLocation& AllocateArgument(const NativeType& payload_type) {
    const auto& payload_type_softfp = ConvertToSoftFp(payload_type, zone_);
    if (payload_type_softfp.IsFloat()) {
      if (fpu_regs_used < CallingConventions::kNumFpuArgRegs) {
        return AllocateFpuRegister(payload_type);
      }
    } else {
      ASSERT(payload_type_softfp.IsInt());
      // Some calling conventions require the callee to make the lowest 32 bits
      // in registers non-garbage.
      const auto& container_type =
          CallingConventions::kArgumentRegisterExtension == kExtendedTo4
              ? payload_type_softfp.WidenTo4Bytes(zone_)
              : payload_type_softfp;
      if (target::kWordSize == 4 && payload_type.SizeInBytes() == 8) {
        if (CallingConventions::kArgumentRegisterAlignment ==
            kAlignedToWordSizeBut8AlignedTo8) {
          cpu_regs_used += cpu_regs_used % 2;
        }
        if (cpu_regs_used + 2 <= CallingConventions::kNumArgRegs) {
          return *new (zone_) NativeRegistersLocation(
              payload_type, container_type, AllocateCpuRegister(),
              AllocateCpuRegister());
        }
      } else {
        ASSERT(payload_type.SizeInBytes() <= target::kWordSize);
        if (cpu_regs_used + 1 <= CallingConventions::kNumArgRegs) {
          return *new (zone_) NativeRegistersLocation(
              payload_type, container_type, AllocateCpuRegister());
        }
      }
    }

    return AllocateStack(payload_type);
  }

 private:
  NativeLocation& AllocateFpuRegister(const NativeType& payload_type) {
    ASSERT(fpu_regs_used < CallingConventions::kNumFpuArgRegs);

    NativeLocation& result = *new (zone_) NativeFpuRegistersLocation(
        payload_type, payload_type,
        CallingConventions::FpuArgumentRegisters[fpu_regs_used]);
    fpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      cpu_regs_used++;
    }
    return result;
  }

  Register AllocateCpuRegister() {
    ASSERT(cpu_regs_used < CallingConventions::kNumArgRegs);

    const auto result = CallingConventions::ArgumentRegisters[cpu_regs_used];
    cpu_regs_used++;
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      fpu_regs_used++;
    }
    return result;
  }

  const NativeLocation& AllocateStack(const NativeType& payload_type) {
    align_stack(payload_type.AlignmentInBytesStack());
    const intptr_t size = payload_type.SizeInBytes();
    // If the stack arguments are not packed, the 32 lowest bits should not
    // contain garbage.
    const auto& container_type =
        CallingConventions::kArgumentStackExtension == kExtendedTo4
            ? payload_type.WidenTo4Bytes(zone_)
            : payload_type;
    const auto& result = *new (zone_) NativeStackLocation(
        payload_type, container_type, CallingConventions::kStackPointerRegister,
        stack_height_in_bytes);
    stack_height_in_bytes += size;
    return result;
  }

  void align_stack(intptr_t alignment) {
    stack_height_in_bytes = Utils::RoundUp(stack_height_in_bytes, alignment);
  }

  intptr_t cpu_regs_used = 0;
  intptr_t fpu_regs_used = 0;
  intptr_t stack_height_in_bytes = 0;
  Zone* zone_;
};

// Location for the arguments of a C signature function.
static NativeLocations& ArgumentLocations(
    const ZoneGrowableArray<const NativeType*>& arg_reps,
    Zone* zone) {
  intptr_t num_arguments = arg_reps.length();
  auto& result = *new NativeLocations(zone, num_arguments);

  // Loop through all arguments and assign a register or a stack location.
  ArgumentAllocator frame_state(zone);
  for (intptr_t i = 0; i < num_arguments; i++) {
    const NativeType& rep = *arg_reps[i];
    result.Add(&frame_state.AllocateArgument(rep));
  }
  return result;
}

// Location for the result of a C signature function.
static NativeLocation& ResultLocation(const NativeType& payload_type,
                                      Zone* zone) {
  const auto& payload_type_softfp = ConvertToSoftFp(payload_type, zone);
  const auto& container_type =
      CallingConventions::kArgumentRegisterExtension == kExtendedTo4
          ? payload_type_softfp.WidenTo4Bytes(zone)
          : payload_type_softfp;
  if (container_type.IsFloat()) {
    return *new (zone) NativeFpuRegistersLocation(
        payload_type, container_type, CallingConventions::kReturnFpuReg);
  }

  ASSERT(container_type.IsInt() || container_type.IsVoid());
  if (container_type.SizeInBytes() == 8 && target::kWordSize == 4) {
    return *new (zone) NativeRegistersLocation(
        payload_type, container_type, CallingConventions::kReturnReg,
        CallingConventions::kSecondReturnReg);
  }

  ASSERT(container_type.SizeInBytes() <= target::kWordSize);
  return *new (zone) NativeRegistersLocation(payload_type, container_type,
                                             CallingConventions::kReturnReg);
}

NativeCallingConvention::NativeCallingConvention(Zone* zone,
                                                 const Function& c_signature)
    : zone_(ASSERT_NOTNULL(zone)),
      c_signature_(c_signature),
      arg_locs_(ArgumentLocations(ArgumentRepresentations(c_signature_, zone_),
                                  zone_)),
      result_loc_(
          ResultLocation(ResultRepresentation(c_signature_, zone_), zone_)) {}

intptr_t NativeCallingConvention::num_args() const {
  ASSERT(c_signature_.NumOptionalParameters() == 0);
  ASSERT(c_signature_.NumOptionalPositionalParameters() == 0);

  // Subtract the #0 argument, the function pointer.
  return c_signature_.num_fixed_parameters() - kNativeParamsStartAt;
}

RawAbstractType* NativeCallingConvention::Type(intptr_t arg_index) const {
  if (arg_index == kResultIndex) {
    return c_signature_.result_type();
  }

  // Skip #0 argument, the function pointer.
  return c_signature_.ParameterTypeAt(arg_index + kNativeParamsStartAt);
}

intptr_t NativeCallingConvention::StackTopInBytes() const {
  intptr_t num_arguments = arg_locs_.length();
  intptr_t max_height_in_bytes = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    if (Location(i).IsStack()) {
      const intptr_t height = Location(i).AsStack().offset_in_bytes() +
                              Location(i).container_type().SizeInBytes();
      max_height_in_bytes = Utils::Maximum(height, max_height_in_bytes);
    }
  }
  return Utils::RoundUp(max_height_in_bytes, compiler::target::kWordSize);
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
