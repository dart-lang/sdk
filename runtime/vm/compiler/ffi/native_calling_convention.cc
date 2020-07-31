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

// Argument #0 is the function pointer.
const intptr_t kNativeParamsStartAt = 1;

const intptr_t kNoFpuRegister = -1;

// In Soft FP, floats and doubles get passed in integer registers.
static bool SoftFpAbi() {
#if defined(TARGET_ARCH_ARM)
  return !TargetCPUFeatures::hardfp_supported();
#else
  return false;
#endif
}

// In Soft FP, floats are treated as 4 byte ints, and doubles as 8 byte ints.
static const NativeType& ConvertIfSoftFp(const NativeType& rep, Zone* zone) {
  if (SoftFpAbi() && rep.IsFloat()) {
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
    const auto& payload_type_converted = ConvertIfSoftFp(payload_type, zone_);
    if (payload_type_converted.IsFloat()) {
      const auto kind = FpuRegKind(payload_type);
      const intptr_t reg_index = FirstFreeFpuRegisterIndex(kind);
      if (reg_index != kNoFpuRegister) {
        AllocateFpuRegisterAtIndex(kind, reg_index);
        if (CallingConventions::kArgumentIntRegXorFpuReg) {
          cpu_regs_used++;
        }
        return *new (zone_) NativeFpuRegistersLocation(
            payload_type, payload_type, kind, reg_index);
      } else {
        BlockAllFpuRegisters();
        if (CallingConventions::kArgumentIntRegXorFpuReg) {
          ASSERT(cpu_regs_used == CallingConventions::kNumArgRegs);
        }
      }
    } else {
      ASSERT(payload_type_converted.IsInt());
      // Some calling conventions require the callee to make the lowest 32 bits
      // in registers non-garbage.
      const auto& container_type =
          CallingConventions::kArgumentRegisterExtension == kExtendedTo4
              ? payload_type_converted.WidenTo4Bytes(zone_)
              : payload_type_converted;
      if (target::kWordSize == 4 && payload_type.SizeInBytes() == 8) {
        if (CallingConventions::kArgumentRegisterAlignment ==
            kAlignedToWordSizeBut8AlignedTo8) {
          cpu_regs_used += cpu_regs_used % 2;
        }
        if (cpu_regs_used + 2 <= CallingConventions::kNumArgRegs) {
          const Register register_1 = AllocateCpuRegister();
          const Register register_2 = AllocateCpuRegister();
          return *new (zone_) NativeRegistersLocation(
              payload_type, container_type, register_1, register_2);
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
  static FpuRegisterKind FpuRegKind(const NativeType& payload_type) {
#if defined(TARGET_ARCH_ARM)
    return FpuRegisterKindFromSize(payload_type.SizeInBytes());
#else
    return kQuadFpuReg;
#endif
  }

  Register AllocateCpuRegister() {
    RELEASE_ASSERT(cpu_regs_used >= 0);  // Avoids -Werror=array-bounds in GCC.
    ASSERT(cpu_regs_used < CallingConventions::kNumArgRegs);

    const auto result = CallingConventions::ArgumentRegisters[cpu_regs_used];
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      AllocateFpuRegisterAtIndex(kQuadFpuReg, cpu_regs_used);
    }
    cpu_regs_used++;
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

  int NumFpuRegisters(FpuRegisterKind kind) {
#if defined(TARGET_ARCH_ARM)
    if (SoftFpAbi()) return 0;
    if (kind == kSingleFpuReg) return CallingConventions::kNumSFpuArgRegs;
    if (kind == kDoubleFpuReg) return CallingConventions::kNumDFpuArgRegs;
#endif  // defined(TARGET_ARCH_ARM)
    if (kind == kQuadFpuReg) return CallingConventions::kNumFpuArgRegs;
    UNREACHABLE();
  }

  // If no register is free, returns -1.
  int FirstFreeFpuRegisterIndex(FpuRegisterKind kind) {
    const intptr_t size = SizeFromFpuRegisterKind(kind) / 4;
    ASSERT(size == 1 || size == 2 || size == 4);
    if (fpu_reg_parts_used == -1) return kNoFpuRegister;
    const intptr_t mask = (1 << size) - 1;
    intptr_t index = 0;
    while (index < NumFpuRegisters(kind)) {
      const intptr_t mask_shifted = mask << (index * size);
      if ((fpu_reg_parts_used & mask_shifted) == 0) {
        return index;
      }
      index++;
    }
    return kNoFpuRegister;
  }

  void AllocateFpuRegisterAtIndex(FpuRegisterKind kind, int index) {
    const intptr_t size = SizeFromFpuRegisterKind(kind) / 4;
    ASSERT(size == 1 || size == 2 || size == 4);
    const intptr_t mask = (1 << size) - 1;
    const intptr_t mask_shifted = (mask << (index * size));
    ASSERT((mask_shifted & fpu_reg_parts_used) == 0);
    fpu_reg_parts_used |= mask_shifted;
  }

  // > The back-filling continues only so long as no VFP CPRC has been
  // > allocated to a slot on the stack.
  // Procedure Call Standard for the Arm Architecture, Release 2019Q1.1
  // Chapter 7.1 page 28. https://developer.arm.com/docs/ihi0042/h
  //
  // Irrelevant on Android and iOS, as those are both SoftFP.
  // > For floating-point arguments, the Base Standard variant of the
  // > Procedure Call Standard is used. In this variant, floating-point
  // > (and vector) arguments are passed in general purpose registers
  // > (GPRs) instead of in VFP registers)
  // https://developer.apple.com/library/archive/documentation/Xcode/Conceptual/iPhoneOSABIReference/Articles/ARMv7FunctionCallingConventions.html#//apple_ref/doc/uid/TP40009022-SW1
  void BlockAllFpuRegisters() {
    // Set all bits to 1.
    fpu_reg_parts_used = -1;
  }

  intptr_t cpu_regs_used = 0;
  // Every bit denotes 32 bits of FPU registers.
  intptr_t fpu_reg_parts_used = 0;
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
  const auto& payload_type_converted = ConvertIfSoftFp(payload_type, zone);
  const auto& container_type =
      CallingConventions::kReturnRegisterExtension == kExtendedTo4
          ? payload_type_converted.WidenTo4Bytes(zone)
          : payload_type_converted;
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

AbstractTypePtr NativeCallingConvention::CType(intptr_t arg_index) const {
  if (arg_index == kResultIndex) {
    return c_signature_.result_type();
  }

  // Skip #0 argument, the function pointer.
  return c_signature_.ParameterTypeAt(arg_index + kNativeParamsStartAt);
}

intptr_t NativeCallingConvention::StackTopInBytes() const {
  const intptr_t num_arguments = arg_locs_.length();
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

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
