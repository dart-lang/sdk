// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_calling_convention.h"

#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/zone_text_buffer.h"

#if !defined(FFI_UNIT_TESTS)
#include "vm/cpu.h"
#endif

namespace dart {

namespace compiler {

namespace ffi {

const intptr_t kNoFpuRegister = -1;

#if !defined(FFI_UNIT_TESTS)
// In Soft FP and vararg calls, floats and doubles get passed in integer
// registers.
static bool SoftFpAbi(bool has_varargs, bool is_result) {
#if defined(TARGET_ARCH_ARM)
  if (has_varargs) {
    return true;
  }
  return !TargetCPUFeatures::hardfp_supported();
#elif defined(TARGET_ARCH_ARM64) && defined(DART_TARGET_OS_WINDOWS)
  return has_varargs && !is_result;
#else
  return false;
#endif
}
#else  // !defined(FFI_UNIT_TESTS)
static bool SoftFpAbi(bool has_varargs, bool is_result) {
#if defined(TARGET_ARCH_ARM) && defined(DART_TARGET_OS_ANDROID)
  return true;
#elif defined(TARGET_ARCH_ARM)
  return has_varargs;
#elif defined(TARGET_ARCH_ARM64) && defined(DART_TARGET_OS_WINDOWS)
  return has_varargs && !is_result;
#else
  return false;
#endif
}
#endif  // !defined(FFI_UNIT_TESTS)

static const NativeType& ConvertFloatToInt(Zone* zone, const NativeType& type) {
  ASSERT(type.IsFloat());
  if (type.SizeInBytes() == 4) {
    return *new (zone) NativePrimitiveType(kInt32);
  }
  ASSERT(type.SizeInBytes() == 8);
  return *new (zone) NativePrimitiveType(kInt64);
}

// In Soft FP, floats are treated as 4 byte ints, and doubles as 8 byte ints.
static const NativeType& ConvertIfSoftFp(Zone* zone,
                                         const NativeType& type,
                                         bool has_varargs,
                                         bool is_result = false) {
  if (SoftFpAbi(has_varargs, is_result) && type.IsFloat()) {
    return ConvertFloatToInt(zone, type);
  }
  return type;
}

// The native dual of `kUnboxedFfiIntPtr`.
//
// It has the same signedness as `kUnboxedFfiIntPtr` to avoid sign conversions
// when converting between both.
const PrimitiveType kFfiIntPtr =
    compiler::target::kWordSize == 8 ? kInt64 : kUint32;

// Represents the state of a stack frame going into a call, between allocations
// of argument locations.
class ArgumentAllocator : public ValueObject {
 public:
  explicit ArgumentAllocator(Zone* zone, bool has_varargs)
      : has_varargs_(has_varargs), zone_(zone) {}

  const NativeLocation& AllocateArgumentVariadic(const NativeType& payload_type,
                                                 bool is_first_vararg = false,
                                                 bool is_vararg = false) {
#if defined(TARGET_ARCH_ARM64) &&                                              \
    (defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS))
    if (is_first_vararg) {
      // Block all registers.
      BlockAllFpuRegisters();
      cpu_regs_used = CallingConventions::kNumArgRegs;
    }
#endif
#if defined(TARGET_ARCH_RISCV64) || defined(TARGET_ARCH_RISCV32)
    if (is_first_vararg) {
      // Block all FPU registers.
      BlockAllFpuRegisters();
    }
#endif
    const auto& result = AllocateArgument(payload_type, is_vararg);
#if defined(TARGET_ARCH_X64) && defined(DART_TARGET_OS_WINDOWS)
    if (has_varargs_) {
      if (result.IsRegisters()) {
        // If an integer register is used, block the corresponding xmm register.
        ASSERT(CallingConventions::kArgumentIntRegXorFpuReg);
      } else if (result.IsFpuRegisters()) {
        // If an xmm register is used, also the corresponding integer register.
        ASSERT(CallingConventions::kArgumentIntRegXorFpuReg);
        const auto& fpu_reg_location = result.AsFpuRegisters();
        const FpuRegisterKind kind = kQuadFpuReg;
        ASSERT(fpu_reg_location.fpu_reg_kind() == kind);
        FpuRegister fpu_register = fpu_reg_location.fpu_reg();
        const intptr_t reg_index = fpu_register;
        ASSERT(cpu_regs_used == reg_index + 1);
        Register cpu_register =
            CallingConventions::ArgumentRegisters[reg_index];
        const auto& container_type = ConvertFloatToInt(zone_, payload_type);
        const auto& cpu_reg_location = *new (zone_) NativeRegistersLocation(
            zone_, payload_type, container_type, cpu_register);
        return *new (zone_)
            BothNativeLocations(fpu_reg_location, cpu_reg_location);
      }
    }
#endif
    return result;
  }

 private:
  const NativeLocation& AllocateArgument(const NativeType& payload_type,

                                         bool is_vararg = false) {
    const auto& payload_type_converted =
        ConvertIfSoftFp(zone_, payload_type, has_varargs_);
    if (payload_type_converted.IsFloat()) {
      return AllocateFloat(payload_type, is_vararg);
    }
    if (payload_type_converted.IsInt()) {
      return AllocateInt(payload_type, is_vararg);
    }

    // Compounds are laid out differently per ABI, so they are implemented
    // per ABI.
    //
    // Compounds always have a PointerToMemory, Stack, or Multiple location,
    // even if the parts of a compound fit in 1 cpu or fpu register it will
    // be nested in a MultipleNativeLocations.
    const NativeCompoundType& compound_type = payload_type.AsCompound();
    return AllocateCompound(compound_type, is_vararg, /*is_result*/ false);
  }

  const NativeLocation& AllocateFloat(const NativeType& payload_type,
                                      bool is_vararg) {
    const auto kind = FpuRegKind(payload_type);
    const intptr_t reg_index = FirstFreeFpuRegisterIndex(kind);
    if (reg_index != kNoFpuRegister) {
      AllocateFpuRegisterAtIndex(kind, reg_index);
      if (CallingConventions::kArgumentIntRegXorFpuReg) {
        cpu_regs_used++;
      }
#if defined(TARGET_ARCH_ARM)
      if (kind == kSingleFpuReg) {
        return *new (zone_)
            NativeFpuRegistersLocation(payload_type, payload_type, kind,
                                       static_cast<SRegister>(reg_index));
      }
      if (kind == kDoubleFpuReg) {
        return *new (zone_)
            NativeFpuRegistersLocation(payload_type, payload_type, kind,
                                       static_cast<DRegister>(reg_index));
      }
#endif
      ASSERT(kind == kQuadFpuReg);
      FpuRegister reg = CallingConventions::FpuArgumentRegisters[reg_index];
      return *new (zone_)
          NativeFpuRegistersLocation(payload_type, payload_type, reg);
    }

#if defined(TARGET_ARCH_RISCV64)
    // After using up F registers, start bitcasting to X registers.
    if (HasAvailableCpuRegisters(1)) {
      const Register reg = AllocateCpuRegister();
      const auto& container_type = ConvertFloatToInt(zone_, payload_type);
      return *new (zone_)
          NativeRegistersLocation(zone_, payload_type, container_type, reg);
    }
#elif defined(TARGET_ARCH_RISCV32)
    // After using up F registers, start bitcasting to X register (pairs).
    if (((payload_type.SizeInBytes() == 4) && HasAvailableCpuRegisters(1)) ||
        ((payload_type.SizeInBytes() == 8) && HasAvailableCpuRegisters(2))) {
      const auto& container_type = ConvertFloatToInt(zone_, payload_type);
      return AllocateInt(payload_type, container_type, is_vararg);
    }
#endif

    BlockAllFpuRegisters();
    if (CallingConventions::kArgumentIntRegXorFpuReg) {
      ASSERT(cpu_regs_used == CallingConventions::kNumArgRegs);
    }
    return AllocateStack(payload_type);
  }

  const NativeLocation& AllocateInt(const NativeType& payload_type,
                                    const NativeType& container_type,
                                    bool is_vararg) {
    if (target::kWordSize == 4 && payload_type.SizeInBytes() == 8) {
      if (CallingConventions::kArgumentRegisterAlignment ==
              kAlignedToWordSizeAndValueSize ||
          (is_vararg && CallingConventions::kArgumentRegisterAlignmentVarArgs ==
                            kAlignedToWordSizeAndValueSize)) {
        cpu_regs_used += cpu_regs_used % 2;
      }
      if (cpu_regs_used + 2 <= CallingConventions::kNumArgRegs) {
        const Register register_1 = AllocateCpuRegister();
        const Register register_2 = AllocateCpuRegister();
        return *new (zone_) NativeRegistersLocation(
            zone_, payload_type, container_type, register_1, register_2);
      }
    } else {
      ASSERT(payload_type.SizeInBytes() <= target::kWordSize);
      if (cpu_regs_used + 1 <= CallingConventions::kNumArgRegs) {
        return *new (zone_) NativeRegistersLocation(
            zone_, payload_type, container_type, AllocateCpuRegister());
      }
    }
    return AllocateStack(payload_type);
  }

  // Constructs a container type.
  const NativeLocation& AllocateInt(const NativeType& payload_type,
                                    bool is_vararg) {
    const auto& payload_type_converted =
        ConvertIfSoftFp(zone_, payload_type, has_varargs_);

    // Some calling conventions require the callee to make the lowest 32 bits
    // in registers non-garbage.
    const auto& container_type =
        CallingConventions::kArgumentRegisterExtension == kExtendedTo4
            ? payload_type_converted.WidenTo4Bytes(zone_)
            : payload_type_converted;

    return AllocateInt(payload_type, container_type, is_vararg);
  }

#if defined(TARGET_ARCH_X64) && !defined(DART_TARGET_OS_WINDOWS)
  // If fits in two fpu and/or cpu registers, transfer in those. Otherwise,
  // transfer on stack.
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    const intptr_t size = payload_type.SizeInBytes();
    if (size <= 16 && size > 0 && !payload_type.ContainsUnalignedMembers()) {
      intptr_t required_regs =
          payload_type.NumberOfWordSizeChunksNotOnlyFloat();
      intptr_t required_xmm_regs =
          payload_type.NumberOfWordSizeChunksOnlyFloat();
      const bool regs_available =
          cpu_regs_used + required_regs <= CallingConventions::kNumArgRegs;
      const bool fpu_regs_available =
          FirstFreeFpuRegisterIndex(kQuadFpuReg) != kNoFpuRegister &&
          FirstFreeFpuRegisterIndex(kQuadFpuReg) + required_xmm_regs <=
              CallingConventions::kNumFpuArgRegs;
      if (regs_available && fpu_regs_available) {
        // Transfer in registers.
        NativeLocations& multiple_locations = *new (zone_) NativeLocations(
            zone_, required_regs + required_xmm_regs);
        for (intptr_t offset = 0; offset < size;
             offset += compiler::target::kWordSize) {
          if (payload_type.ContainsOnlyFloats(Range::StartAndEnd(
                  offset, Utils::Minimum<intptr_t>(size, offset + 8)))) {
            const intptr_t reg_index = FirstFreeFpuRegisterIndex(kQuadFpuReg);
            AllocateFpuRegisterAtIndex(kQuadFpuReg, reg_index);
            const auto& type = *new (zone_) NativePrimitiveType(kDouble);
            multiple_locations.Add(new (zone_) NativeFpuRegistersLocation(
                type, type, kQuadFpuReg, reg_index));
          } else {
            const auto& type = *new (zone_) NativePrimitiveType(kInt64);
            multiple_locations.Add(new (zone_) NativeRegistersLocation(
                zone_, type, type, AllocateCpuRegister()));
          }
        }
        return *new (zone_)
            MultipleNativeLocations(payload_type, multiple_locations);
      }
    }
    return AllocateStack(payload_type);
  }
#endif  // defined(TARGET_ARCH_X64) && !defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_X64) && defined(DART_TARGET_OS_WINDOWS)
  // If struct fits in a single register and size is a power of two, then
  // use a single register and sign extend.
  // Otherwise, pass a pointer to a copy.
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    const NativeCompoundType& compound_type = payload_type.AsCompound();
    const intptr_t size = compound_type.SizeInBytes();
    if (size <= 8 && Utils::IsPowerOfTwo(size)) {
      if (cpu_regs_used < CallingConventions::kNumArgRegs) {
        NativeLocations& multiple_locations =
            *new (zone_) NativeLocations(zone_, 1);
        const auto& type = *new (zone_) NativePrimitiveType(
            PrimitiveTypeFromSizeInBytes(size));
        multiple_locations.Add(new (zone_) NativeRegistersLocation(
            zone_, type, type, AllocateCpuRegister()));
        return *new (zone_)
            MultipleNativeLocations(compound_type, multiple_locations);
      }

    } else if (size > 0) {
      // Pointer in register if available, else pointer on stack.
      const auto& pointer_type = *new (zone_) NativePrimitiveType(kFfiIntPtr);
      const auto& pointer_location = AllocateArgument(pointer_type);
      return *new (zone_)
          PointerToMemoryLocation(pointer_location, compound_type);
    }

    return AllocateStack(payload_type);
  }
#endif  // defined(TARGET_ARCH_X64) && defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_IA32)
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    return AllocateStack(payload_type);
  }
#endif  // defined(TARGET_ARCH_IA32)

#if defined(TARGET_ARCH_ARM)
  // Transfer homogeneous floats in FPU registers, and allocate the rest
  // in 4 or 8 size chunks in registers and stack.
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    const auto& compound_type = payload_type.AsCompound();
    if (compound_type.ContainsHomogeneousFloats() &&
        !SoftFpAbi(has_varargs_, is_result) &&
        compound_type.NumPrimitiveMembersRecursive() <= 4) {
      const auto& elem_type = compound_type.FirstPrimitiveMember();
      const intptr_t size = compound_type.SizeInBytes();
      const intptr_t elem_size = elem_type.SizeInBytes();
      const auto reg_kind = FpuRegisterKindFromSize(elem_size);
      ASSERT(size % elem_size == 0);
      const intptr_t num_registers = size / elem_size;
      const intptr_t first_reg =
          FirstFreeFpuRegisterIndex(reg_kind, num_registers);
      if (first_reg != kNoFpuRegister) {
        AllocateFpuRegisterAtIndex(reg_kind, first_reg, num_registers);

        NativeLocations& multiple_locations =
            *new (zone_) NativeLocations(zone_, num_registers);
        for (int i = 0; i < num_registers; i++) {
          const intptr_t reg_index = first_reg + i;
          multiple_locations.Add(new (zone_) NativeFpuRegistersLocation(
              elem_type, elem_type, reg_kind, reg_index));
        }
        return *new (zone_)
            MultipleNativeLocations(compound_type, multiple_locations);

      } else {
        BlockAllFpuRegisters();
        return AllocateStack(payload_type);
      }
    } else {
      const intptr_t chunk_size = payload_type.AlignmentInBytesStack();
      ASSERT(chunk_size == 4 || chunk_size == 8);
      const intptr_t size_rounded =
          Utils::RoundUp(payload_type.SizeInBytes(), chunk_size);
      const intptr_t num_chunks = size_rounded / chunk_size;
      const auto& chuck_type =
          *new (zone_) NativePrimitiveType(chunk_size == 4 ? kInt32 : kInt64);

      NativeLocations& multiple_locations =
          *new (zone_) NativeLocations(zone_, num_chunks);
      for (int i = 0; i < num_chunks; i++) {
        const auto& allocated_chunk = &AllocateArgument(chuck_type);
        // The last chunk should not be 8 bytes, if the struct only has 4
        // remaining bytes to be allocated.
        if (i == num_chunks - 1 && chunk_size == 8 &&
            Utils::RoundUp(payload_type.SizeInBytes(), 4) % 8 == 4) {
          const auto& small_chuck_type = *new (zone_) NativePrimitiveType(
              chunk_size == 4 ? kInt32 : kInt64);
          multiple_locations.Add(&allocated_chunk->WithOtherNativeType(
              zone_, small_chuck_type, small_chuck_type));
        } else {
          multiple_locations.Add(allocated_chunk);
        }
      }
      return *new (zone_)
          MultipleNativeLocations(compound_type, multiple_locations);
    }
  }
#endif  // defined(TARGET_ARCH_ARM)

#if defined(TARGET_ARCH_ARM64)
  // Slightly different from Arm32. FPU registers don't alias the same way,
  // structs up to 16 bytes block remaining registers if they do not fit in
  // registers, and larger structs go on stack always.
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    const auto& compound_type = payload_type.AsCompound();
    const intptr_t size = compound_type.SizeInBytes();
    if (compound_type.ContainsHomogeneousFloats() &&
        !SoftFpAbi(has_varargs_, is_result) &&
        compound_type.NumPrimitiveMembersRecursive() <= 4) {
      const auto& elem_type = compound_type.FirstPrimitiveMember();
      const intptr_t elem_size = elem_type.SizeInBytes();
      const auto reg_kind = kQuadFpuReg;
      ASSERT(size % elem_size == 0);
      const intptr_t num_registers = size / elem_size;
      const intptr_t first_reg =
          FirstFreeFpuRegisterIndex(reg_kind, num_registers);
      if (first_reg != kNoFpuRegister) {
        AllocateFpuRegisterAtIndex(reg_kind, first_reg, num_registers);

        NativeLocations& multiple_locations =
            *new (zone_) NativeLocations(zone_, num_registers);
        for (int i = 0; i < num_registers; i++) {
          const intptr_t reg_index = first_reg + i;
          multiple_locations.Add(new (zone_) NativeFpuRegistersLocation(
              elem_type, elem_type, reg_kind, reg_index));
        }
        return *new (zone_)
            MultipleNativeLocations(compound_type, multiple_locations);
      }
      BlockAllFpuRegisters();
      return AllocateStack(payload_type, is_vararg);
    }

    if (size <= 16) {
      const intptr_t size_rounded = Utils::RoundUp(size, 8);
      const intptr_t num_chunks = size_rounded / 8;
      ASSERT((num_chunks == 1) || (num_chunks == 2));

      // All-or-none: block any leftover registers.
#if defined(DART_TARGET_OS_WINDOWS)
      if (!HasAvailableCpuRegisters(num_chunks) && !is_vararg) {
        cpu_regs_used = CallingConventions::kNumArgRegs;
      }
#else
      if (!HasAvailableCpuRegisters(num_chunks)) {
        cpu_regs_used = CallingConventions::kNumArgRegs;
      }
#endif

      const auto& chunk_type = *new (zone_) NativePrimitiveType(kInt64);

      NativeLocations& multiple_locations =
          *new (zone_) NativeLocations(zone_, num_chunks);
      for (int i = 0; i < num_chunks; i++) {
        const auto& allocated_chunk = &AllocateArgument(chunk_type, is_vararg);
        multiple_locations.Add(allocated_chunk);
      }
      return *new (zone_)
          MultipleNativeLocations(compound_type, multiple_locations);
    }

    const auto& pointer_location =
        AllocateArgument(*new (zone_) NativePrimitiveType(kInt64));
    return *new (zone_)
        PointerToMemoryLocation(pointer_location, compound_type);
  }
#endif  // defined(TARGET_ARCH_ARM64)

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
  // See RISC-V ABIs Specification
  // https://github.com/riscv-non-isa/riscv-elf-psabi-doc/releases
  const NativeLocation& AllocateCompound(const NativeCompoundType& payload_type,
                                         bool is_vararg,
                                         bool is_result) {
    const auto& compound_type = payload_type.AsCompound();

    // 2.2. Hardware Floating-point Calling Convention.
    const NativePrimitiveType* first = nullptr;
    const NativePrimitiveType* second = nullptr;
    const intptr_t num_primitive_members =
        compound_type.PrimitivePairMembers(&first, &second);

    // If exactly one floating-point member, pass like a scalar.
    if ((num_primitive_members == 1) && first->IsFloat()) {
      NativeLocations& multiple_locations =
          *new (zone_) NativeLocations(zone_, 1);
      multiple_locations.Add(&AllocateArgument(*first));
      return *new (zone_)
          MultipleNativeLocations(compound_type, multiple_locations);
    }

    if (num_primitive_members == 2) {
      if (first->IsFloat() && second->IsFloat()) {
        // If exactly two floating-point members, pass like two scalars if two F
        // registers are available.
        if (HasAvailableFpuRegisters(2)) {
          NativeLocations& multiple_locations =
              *new (zone_) NativeLocations(zone_, 2);
          multiple_locations.Add(&AllocateArgument(*first));
          multiple_locations.Add(&AllocateArgument(*second));
          return *new (zone_)
              MultipleNativeLocations(compound_type, multiple_locations);
        }
      } else if (first->IsFloat() || second->IsFloat()) {
        // If exactly two members, one is integer and one is float in either
        // order, pass like two scalars if both an X and F register are
        // available.
        if (HasAvailableFpuRegisters(1) && HasAvailableCpuRegisters(1)) {
          NativeLocations& multiple_locations =
              *new (zone_) NativeLocations(zone_, 2);
          multiple_locations.Add(&AllocateArgument(*first));
          multiple_locations.Add(&AllocateArgument(*second));
          return *new (zone_)
              MultipleNativeLocations(compound_type, multiple_locations);
        }
      }
    }

    // 2.1. Integer Calling Convention.
    const auto& pointer_type = *new (zone_) NativePrimitiveType(kFfiIntPtr);
    const intptr_t size = compound_type.SizeInBytes();

    // If total size is <= XLEN, passed like an XLEN scalar: use a register if
    // available or pass by value on the stack.
    if (size <= target::kWordSize) {
      NativeLocations& multiple_locations =
          *new (zone_) NativeLocations(zone_, 1);
      multiple_locations.Add(&AllocateArgument(pointer_type));
      return *new (zone_)
          MultipleNativeLocations(compound_type, multiple_locations);
    }

    // If total size is <= 2*XLEN, passed like two XLEN scalars: use registers
    // if available or pass by value on the stack. If only one register is
    // available, pass the low part by register and the high part on the
    // stack.
    if (size <= 2 * target::kWordSize) {
      NativeLocations& multiple_locations =
          *new (zone_) NativeLocations(zone_, 2);
      multiple_locations.Add(&AllocateArgument(pointer_type));
      multiple_locations.Add(&AllocateArgument(pointer_type));
      return *new (zone_)
          MultipleNativeLocations(compound_type, multiple_locations);
    }

    // Otherwise, passed by reference.
    const auto& pointer_location = AllocateArgument(pointer_type);
    return *new (zone_)
        PointerToMemoryLocation(pointer_location, compound_type);
  }
#endif

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

  const NativeLocation& AllocateStack(const NativeType& payload_type,
                                      bool is_vararg = false) {
    align_stack(payload_type.AlignmentInBytesStack(is_vararg));
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
    align_stack(payload_type.AlignmentInBytesStack(is_vararg));
    return result;
  }

  void align_stack(intptr_t alignment) {
    stack_height_in_bytes = Utils::RoundUp(stack_height_in_bytes, alignment);
  }

  int NumFpuRegisters(FpuRegisterKind kind) const {
#if defined(TARGET_ARCH_ARM)
    if (has_varargs_) return 0;
    if (kind == kSingleFpuReg) return CallingConventions::kNumSFpuArgRegs;
    if (kind == kDoubleFpuReg) return CallingConventions::kNumDFpuArgRegs;
#endif  // defined(TARGET_ARCH_ARM)
    if (kind == kQuadFpuReg) return CallingConventions::kNumFpuArgRegs;
    UNREACHABLE();
  }

  // If no register is free, returns -1.
  int FirstFreeFpuRegisterIndex(FpuRegisterKind kind, int amount = 1) const {
    const intptr_t size = SizeFromFpuRegisterKind(kind) / 4;
    ASSERT(size == 1 || size == 2 || size == 4);
    if (fpu_reg_parts_used == -1) return kNoFpuRegister;
    const intptr_t mask = (1 << (size * amount)) - 1;
    intptr_t index = 0;
    while (index + amount <= NumFpuRegisters(kind)) {
      const intptr_t mask_shifted = mask << (index * size);
      if ((fpu_reg_parts_used & mask_shifted) == 0) {
        return index;
      }
      index++;
    }
    return kNoFpuRegister;
  }

  void AllocateFpuRegisterAtIndex(FpuRegisterKind kind,
                                  int index,
                                  int amount = 1) {
    const intptr_t size = SizeFromFpuRegisterKind(kind) / 4;
    ASSERT(size == 1 || size == 2 || size == 4);
    const intptr_t mask = (1 << size * amount) - 1;
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

  bool HasAvailableCpuRegisters(intptr_t count) const {
    return cpu_regs_used + count <= CallingConventions::kNumArgRegs;
  }
  bool HasAvailableFpuRegisters(intptr_t count) const {
    return FirstFreeFpuRegisterIndex(kQuadFpuReg, count) != kNoFpuRegister;
  }

  intptr_t cpu_regs_used = 0;
  // Every bit denotes 32 bits of FPU registers.
  intptr_t fpu_reg_parts_used = 0;
  intptr_t stack_height_in_bytes = 0;
  const bool has_varargs_;
  Zone* zone_;
};

// Location for the arguments of a C signature function.
static NativeLocations& ArgumentLocations(
    Zone* zone,
    const ZoneGrowableArray<const NativeType*>& arg_reps,
    const NativeLocation& return_location,
    intptr_t var_args_index) {
  intptr_t num_arguments = arg_reps.length();
  auto& result = *new (zone) NativeLocations(zone, num_arguments);

  // Loop through all arguments and assign a register or a stack location.
  // Allocate result pointer for composite returns first.
  const bool has_varargs =
      var_args_index != NativeFunctionType::kNoVariadicArguments;
  ArgumentAllocator frame_state(zone, has_varargs);
#if !defined(TARGET_ARCH_ARM64)
  // Arm64 allocates the pointer in R8, which is not an argument location.
  if (return_location.IsPointerToMemory()) {
    const auto& pointer_location =
        return_location.AsPointerToMemory().pointer_location();
    const auto& pointer_location_allocated =
        frame_state.AllocateArgumentVariadic(pointer_location.payload_type());
    ASSERT(pointer_location.Equals(pointer_location_allocated));
  }
#endif

  for (intptr_t i = 0; i < num_arguments; i++) {
    const NativeType& rep = *arg_reps[i];
    const bool is_first_vararg = has_varargs && i == var_args_index;
    const bool is_vararg = has_varargs && i >= var_args_index;
    result.Add(
        &frame_state.AllocateArgumentVariadic(rep, is_first_vararg, is_vararg));
  }
  return result;
}

#if !defined(TARGET_ARCH_IA32)
static const NativeLocation& PointerToMemoryResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type) {
  const auto& pointer_type = *new (zone) NativePrimitiveType(kFfiIntPtr);
  const auto& pointer_location = *new (zone) NativeRegistersLocation(
      zone, pointer_type, pointer_type,
      CallingConventions::kPointerToReturnStructRegisterCall);
  const auto& pointer_return_location = *new (zone) NativeRegistersLocation(
      zone, pointer_type, pointer_type,
      CallingConventions::kPointerToReturnStructRegisterReturn);
  return *new (zone) PointerToMemoryLocation(
      pointer_location, pointer_return_location, payload_type);
}
#endif  // !defined(TARGET_ARCH_IA32)

#if defined(TARGET_ARCH_IA32)
// ia32 Passes pointers to result locations on the stack.
static const NativeLocation& PointerToMemoryResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type) {
  const auto& pointer_type = *new (zone) NativePrimitiveType(kFfiIntPtr);
  const auto& pointer_location = *new (zone) NativeStackLocation(
      pointer_type, pointer_type, CallingConventions::kStackPointerRegister, 0);
  const auto& pointer_return_location = *new (zone) NativeRegistersLocation(
      zone, pointer_type, pointer_type,
      CallingConventions::kPointerToReturnStructRegisterReturn);
  return *new (zone) PointerToMemoryLocation(
      pointer_location, pointer_return_location, payload_type);
}
#endif  // defined(TARGET_ARCH_IA32)

#if defined(TARGET_ARCH_X64) && !defined(DART_TARGET_OS_WINDOWS)
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  const intptr_t size = payload_type.SizeInBytes();
  if (size <= 16 && size > 0 && !payload_type.ContainsUnalignedMembers()) {
    // Allocate the same as argument, but use return registers instead of
    // argument registers.
    NativeLocations& multiple_locations =
        *new (zone) NativeLocations(zone, size > 8 ? 2 : 1);
    intptr_t used_regs = 0;
    intptr_t used_xmm_regs = 0;

    const auto& double_type = *new (zone) NativePrimitiveType(kDouble);
    const auto& int64_type = *new (zone) NativePrimitiveType(kInt64);

    const bool first_half_in_xmm = payload_type.ContainsOnlyFloats(
        Range::StartAndEnd(0, Utils::Minimum<intptr_t>(size, 8)));
    if (first_half_in_xmm) {
      multiple_locations.Add(new (zone) NativeFpuRegistersLocation(
          double_type, double_type, kQuadFpuReg,
          CallingConventions::kReturnFpuReg));
      used_xmm_regs++;
    } else {
      multiple_locations.Add(new (zone) NativeRegistersLocation(
          zone, int64_type, int64_type, CallingConventions::kReturnReg));
      used_regs++;
    }
    if (size > 8) {
      const bool second_half_in_xmm = payload_type.ContainsOnlyFloats(
          Range::StartAndEnd(8, Utils::Minimum<intptr_t>(size, 16)));
      if (second_half_in_xmm) {
        const FpuRegister reg = used_xmm_regs == 0
                                    ? CallingConventions::kReturnFpuReg
                                    : CallingConventions::kSecondReturnFpuReg;
        multiple_locations.Add(new (zone) NativeFpuRegistersLocation(
            double_type, double_type, kQuadFpuReg, reg));
        used_xmm_regs++;
      } else {
        const Register reg = used_regs == 0
                                 ? CallingConventions::kReturnReg
                                 : CallingConventions::kSecondReturnReg;
        multiple_locations.Add(new (zone) NativeRegistersLocation(
            zone, int64_type, int64_type, reg));
        used_regs++;
      }
    }
    return *new (zone)
        MultipleNativeLocations(payload_type, multiple_locations);
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_X64) && !defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_X64) && defined(DART_TARGET_OS_WINDOWS)
// If struct fits in a single register do that, and sign extend.
// Otherwise, pass a pointer to memory.
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  const intptr_t size = payload_type.SizeInBytes();
  if (size <= 8 && size > 0 && Utils::IsPowerOfTwo(size)) {
    NativeLocations& multiple_locations = *new (zone) NativeLocations(zone, 1);
    const auto& type =
        *new (zone) NativePrimitiveType(PrimitiveTypeFromSizeInBytes(size));
    multiple_locations.Add(new (zone) NativeRegistersLocation(
        zone, type, type, CallingConventions::kReturnReg));
    return *new (zone)
        MultipleNativeLocations(payload_type, multiple_locations);
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_X64) && defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_IA32) && !defined(DART_TARGET_OS_WINDOWS)
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_IA32) && !defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_IA32) && defined(DART_TARGET_OS_WINDOWS)
// Windows uses up to two return registers, while Linux does not.
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  const intptr_t size = payload_type.SizeInBytes();
  if (size <= 8 && Utils::IsPowerOfTwo(size)) {
    NativeLocations& multiple_locations =
        *new (zone) NativeLocations(zone, size > 4 ? 2 : 1);
    const auto& type = *new (zone) NativePrimitiveType(kUint32);
    multiple_locations.Add(new (zone) NativeRegistersLocation(
        zone, type, type, CallingConventions::kReturnReg));
    if (size > 4) {
      multiple_locations.Add(new (zone) NativeRegistersLocation(
          zone, type, type, CallingConventions::kSecondReturnReg));
    }
    return *new (zone)
        MultipleNativeLocations(payload_type, multiple_locations);
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_IA32) && defined(DART_TARGET_OS_WINDOWS)

#if defined(TARGET_ARCH_ARM)
// Arm passes homogenous float return values in FPU registers and small
// composites in a single integer register. The rest is stored into the
// location passed in by pointer.
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  const intptr_t num_members = payload_type.NumPrimitiveMembersRecursive();
  if (payload_type.ContainsHomogeneousFloats() &&
      !SoftFpAbi(has_varargs, /*is_result*/ true) && num_members <= 4) {
    NativeLocations& multiple_locations =
        *new (zone) NativeLocations(zone, num_members);
    for (int i = 0; i < num_members; i++) {
      const auto& member = payload_type.FirstPrimitiveMember();
      multiple_locations.Add(new (zone) NativeFpuRegistersLocation(
          member, member, FpuRegisterKindFromSize(member.SizeInBytes()), i));
    }
    return *new (zone)
        MultipleNativeLocations(payload_type, multiple_locations);
  }
  const intptr_t size = payload_type.SizeInBytes();
  if (size <= 4) {
    NativeLocations& multiple_locations = *new (zone) NativeLocations(zone, 1);
    const auto& type = *new (zone) NativePrimitiveType(kUint32);
    multiple_locations.Add(new (zone)
                               NativeRegistersLocation(zone, type, type, R0));
    return *new (zone)
        MultipleNativeLocations(payload_type, multiple_locations);
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_ARM)

#if defined(TARGET_ARCH_ARM64)
// If allocated to integer or fpu registers as argument, same for return,
// otherwise a pointer to the result location is passed in.
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  ArgumentAllocator frame_state(zone, has_varargs);
  const auto& location_as_argument =
      frame_state.AllocateArgumentVariadic(payload_type);
  if (!location_as_argument.IsStack() &&
      !location_as_argument.IsPointerToMemory()) {
    return location_as_argument;
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_ARM64)

#if defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)
static const NativeLocation& CompoundResultLocation(
    Zone* zone,
    const NativeCompoundType& payload_type,
    bool has_varargs) {
  // First or first and second argument registers if it fits, otherwise a
  // pointer to the result location is passed in.
  ArgumentAllocator frame_state(zone, has_varargs);
  const auto& location_as_argument =
      frame_state.AllocateArgumentVariadic(payload_type);
  if (!location_as_argument.IsStack() &&
      !location_as_argument.IsPointerToMemory()) {
    return location_as_argument;
  }
  return PointerToMemoryResultLocation(zone, payload_type);
}
#endif  // defined(TARGET_ARCH_RISCV32) || defined(TARGET_ARCH_RISCV64)

// Location for the result of a C signature function.
static const NativeLocation& ResultLocation(Zone* zone,
                                            const NativeType& payload_type,
                                            bool has_varargs) {
  const auto& payload_type_converted =
      ConvertIfSoftFp(zone, payload_type, has_varargs, /*is_result*/ true);
  const auto& container_type =
      CallingConventions::kReturnRegisterExtension == kExtendedTo4
          ? payload_type_converted.WidenTo4Bytes(zone)
          : payload_type_converted;

  if (container_type.IsFloat()) {
    return *new (zone) NativeFpuRegistersLocation(
        payload_type, container_type, CallingConventions::kReturnFpuReg);
  }

  if (container_type.IsInt() || container_type.IsVoid()) {
    if (container_type.SizeInBytes() == 8 && target::kWordSize == 4) {
      return *new (zone) NativeRegistersLocation(
          zone, payload_type, container_type, CallingConventions::kReturnReg,
          CallingConventions::kSecondReturnReg);
    }

    ASSERT(container_type.SizeInBytes() <= target::kWordSize);
    return *new (zone) NativeRegistersLocation(
        zone, payload_type, container_type, CallingConventions::kReturnReg);
  }

  // Compounds are laid out differently per ABI, so they are implemented
  // per ABI.
  const auto& compound_type = payload_type.AsCompound();
  return CompoundResultLocation(zone, compound_type, has_varargs);
}

const NativeCallingConvention& NativeCallingConvention::FromSignature(
    Zone* zone,
    const NativeFunctionType& signature) {
  const bool contains_varargs = signature.variadic_arguments_index() !=
                                NativeFunctionType::kNoVariadicArguments;
  // With struct return values, a possible pointer to a return value can
  // occupy an argument position. Hence, allocate return value first.
  const auto& return_location =
      ResultLocation(zone, signature.return_type(), contains_varargs);
  const auto& argument_locations =
      ArgumentLocations(zone, signature.argument_types(), return_location,
                        signature.variadic_arguments_index());
  return *new (zone) NativeCallingConvention(argument_locations,
                                             return_location, contains_varargs);
}

intptr_t NativeCallingConvention::StackTopInBytes() const {
  const intptr_t num_arguments = argument_locations_.length();
  intptr_t max_height_in_bytes = 0;
  for (intptr_t i = 0; i < num_arguments; i++) {
    max_height_in_bytes = Utils::Maximum(
        max_height_in_bytes, argument_locations_[i]->StackTopInBytes());
  }
  if (return_location_.IsPointerToMemory()) {
    const auto& ret_loc = return_location_.AsPointerToMemory();
    max_height_in_bytes =
        Utils::Maximum(max_height_in_bytes, ret_loc.StackTopInBytes());
  }
  return Utils::RoundUp(max_height_in_bytes, compiler::target::kWordSize);
}

void NativeCallingConvention::PrintTo(BaseTextBuffer* f,
                                      bool multi_line) const {
  if (!multi_line) {
    f->AddString("(");
  }
  for (intptr_t i = 0; i < argument_locations_.length(); i++) {
    if (i > 0) {
      if (multi_line) {
        f->AddString("\n");
      } else {
        f->AddString(", ");
      }
    }
    argument_locations_[i]->PrintTo(f);
  }
  if (multi_line) {
    f->AddString("\n=>\n");
  } else {
    f->AddString(") => ");
  }
  return_location_.PrintTo(f);
  if (multi_line) {
    f->AddString("\n");
  }
}

const char* NativeCallingConvention::ToCString(Zone* zone,
                                               bool multi_line) const {
  ZoneTextBuffer textBuffer(zone);
  PrintTo(&textBuffer, multi_line);
  return textBuffer.buffer();
}

#if !defined(FFI_UNIT_TESTS)
const char* NativeCallingConvention::ToCString(bool multi_line) const {
  return ToCString(Thread::Current()->zone(), multi_line);
}
#endif

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
