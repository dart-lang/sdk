// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/backend/dart_calling_conventions.h"

#include <array>

#include "vm/compiler/runtime_api.h"
#include "vm/object.h"

namespace dart {

namespace compiler {

namespace {
template <typename R, size_t N>
class SimpleAllocator {
 public:
  explicit SimpleAllocator(const R (&regs)[N]) : regs_(regs) {
    // C++ does not allow zero length arrays - so we use an array with a single
    // kNoRegister element as a replacement.
    if (N == 1 && regs_[0] == -1) {
      next_ = N;
    }
  }

  R Allocate() { return next_ < N ? regs_[next_++] : static_cast<R>(-1); }

  std::pair<R, R> AllocatePair() {
    if ((next_ + 2) <= N) {
      const auto lo = Allocate();
      const auto hi = Allocate();
      return {lo, hi};
    }
    return {static_cast<R>(-1), static_cast<R>(-1)};
  }

 private:
  const R (&regs_)[N];
  size_t next_ = 0;
};

template <typename R, size_t N>
SimpleAllocator(const R (&)[N]) -> SimpleAllocator<R, N>;

}  // namespace

intptr_t ComputeCallingConvention(
    Zone* zone,
    const Function& target,
    intptr_t argc,
    std::function<Representation(intptr_t)> argument_rep,
    bool should_assign_stack_locations,
    ParameterInfoArray* parameter_info) {
  SimpleAllocator cpu_allocator(DartCallingConvention::kCpuRegistersForArgs);
  SimpleAllocator fpu_allocator(DartCallingConvention::kFpuRegistersForArgs);

  if (parameter_info != nullptr) {
    parameter_info->TruncateTo(0);
    parameter_info->EnsureLength(argc, {});
  }

  const intptr_t max_arguments_in_registers =
      !target.IsNull() ? target.MaxNumberOfParametersInRegisters(zone) : 0;

  // First allocate all register parameters and compute the size of
  // parameters on the stack.
  intptr_t stack_parameters_size_in_words = 0;
  for (intptr_t i = 0; i < argc; ++i) {
    auto rep = argument_rep(i);

    Location location;
    if (i < max_arguments_in_registers) {
      switch (rep) {
        case kUnboxedInt64:
#if defined(TARGET_ARCH_IS_32_BIT)
          if (auto [lo_reg, hi_reg] = cpu_allocator.AllocatePair();
              hi_reg != kNoRegister) {
            location = Location::Pair(Location::RegisterLocation(lo_reg),
                                      Location::RegisterLocation(hi_reg));
#else
          if (auto reg = cpu_allocator.Allocate(); reg != kNoRegister) {
            location = Location::RegisterLocation(reg);
#endif
          }
          break;

        case kUnboxedDouble:
          if (auto reg = fpu_allocator.Allocate(); reg != kNoFpuRegister) {
            location = Location::FpuRegisterLocation(reg);
          }
          break;

        case kTagged:
          if (auto reg = cpu_allocator.Allocate(); reg != kNoRegister) {
            location = Location::RegisterLocation(reg);
          }
          break;

        default:
          UNREACHABLE();
          break;
      }
    }

    if (location.IsInvalid()) {
      intptr_t size_in_words;
      switch (rep) {
        case kUnboxedInt64:
          size_in_words = compiler::target::kIntSpillFactor;
          break;

        case kUnboxedDouble:
          size_in_words = compiler::target::kDoubleSpillFactor;
          break;

        case kTagged:
          size_in_words = 1;
          break;

        default:
          UNREACHABLE();
          break;
      }
      stack_parameters_size_in_words += size_in_words;
    }

    if (parameter_info != nullptr) {
      (*parameter_info)[i] = {location, rep};
    }
  }

  if (parameter_info == nullptr || !should_assign_stack_locations) {
    return stack_parameters_size_in_words;
  }

  // Now that we allocated all register parameters, allocate all other
  // parameters to the stack.
  const intptr_t offset_to_last_parameter_slot_from_fp =
      (compiler::target::frame_layout.param_end_from_fp + 1);
  intptr_t offset_in_words_from_fp = offset_to_last_parameter_slot_from_fp;
  for (intptr_t i = argc - 1; i >= 0; --i) {
    auto& [location, representation] = (*parameter_info)[i];
    if (!location.IsInvalid()) {
      continue;  // Already allocated to a register.
    }

    switch (representation) {
      case kUnboxedInt64:
        if (compiler::target::kIntSpillFactor == 1) {
          location = Location::StackSlot(offset_in_words_from_fp, FPREG);
        } else {
          ASSERT(compiler::target::kIntSpillFactor == 2);
          location = Location::Pair(
              Location::StackSlot(offset_in_words_from_fp, FPREG),
              Location::StackSlot(offset_in_words_from_fp + 1, FPREG));
        }
        offset_in_words_from_fp += compiler::target::kIntSpillFactor;
        break;

      case kUnboxedDouble:
        location = Location::DoubleStackSlot(offset_in_words_from_fp, FPREG);
        offset_in_words_from_fp += compiler::target::kDoubleSpillFactor;
        break;

      case kTagged:
        location = Location::StackSlot(offset_in_words_from_fp, FPREG);
        offset_in_words_from_fp += 1;
        break;

      default:
        UNREACHABLE();
        break;
    }
  }

  RELEASE_ASSERT(
      (offset_in_words_from_fp - offset_to_last_parameter_slot_from_fp) ==
      stack_parameters_size_in_words);

  return stack_parameters_size_in_words;
}

}  // namespace compiler

}  // namespace dart
