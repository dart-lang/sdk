// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/marshaller.h"

#include "vm/compiler/ffi/frame_rebase.h"
#include "vm/compiler/ffi/native_location.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

bool BaseMarshaller::ContainsHandles() const {
  return dart_signature_.FfiCSignatureContainsHandles();
}

Location CallMarshaller::LocInFfiCall(intptr_t arg_index) const {
  if (arg_index == kResultIndex) {
    return Location(arg_index).AsLocation();
  }

  // Floating point values are never split: they are either in a single "FPU"
  // register or a contiguous 64-bit slot on the stack. Unboxed 64-bit integer
  // values, in contrast, can be split between any two registers on a 32-bit
  // system.
  //
  // There is an exception for iOS and Android 32-bit ARM, where
  // floating-point values are treated as integers as far as the calling
  // convention is concerned. However, the representation of these arguments
  // are set to kUnboxedInt32 or kUnboxedInt64 already, so we don't have to
  // account for that here.
  const bool is_atomic = RepInFfiCall(arg_index) == kUnboxedDouble ||
                         RepInFfiCall(arg_index) == kUnboxedFloat;

  const NativeLocation& loc = this->Location(arg_index);
  // Don't pin stack locations, they need to be moved anyway.
  if (loc.IsStack()) {
    if (loc.payload_type().SizeInBytes() == 2 * compiler::target::kWordSize &&
        !is_atomic) {
      return Location::Pair(Location::Any(), Location::Any());
    }
    return Location::Any();
  }

#if defined(TARGET_ARCH_ARM)
  // Only pin FPU register if it is the lowest bits.
  if (loc.IsFpuRegisters()) {
    const auto& fpu_loc = loc.AsFpuRegisters();
    if (fpu_loc.IsLowestBits()) {
      return fpu_loc.WidenToQFpuRegister(zone_).AsLocation();
    }
    return Location::Any();
  }
#endif  // defined(TARGET_ARCH_ARM)

  return loc.AsLocation();
}

// This classes translates the ABI location of arguments into the locations they
// will inhabit after entry-frame setup in the invocation of a native callback.
//
// Native -> Dart callbacks must push all the arguments before executing any
// Dart code because the reading the Thread from TLS requires calling a native
// stub, and the argument registers are volatile on all ABIs we support.
//
// To avoid complicating initial definitions, all callback arguments are read
// off the stack from their pushed locations, so this class updates the argument
// positions to account for this.
//
// See 'NativeEntryInstr::EmitNativeCode' for details.
class CallbackArgumentTranslator : public ValueObject {
 public:
  static NativeLocations& TranslateArgumentLocations(
      const NativeLocations& arg_locs,
      Zone* zone) {
    auto& pushed_locs = *(new NativeLocations(arg_locs.length()));

    CallbackArgumentTranslator translator;
    for (intptr_t i = 0, n = arg_locs.length(); i < n; i++) {
      translator.AllocateArgument(*arg_locs[i]);
    }
    for (intptr_t i = 0, n = arg_locs.length(); i < n; ++i) {
      pushed_locs.Add(&translator.TranslateArgument(*arg_locs[i], zone));
    }

    return pushed_locs;
  }

 private:
  void AllocateArgument(const NativeLocation& arg) {
    if (arg.IsStack()) return;

    ASSERT(arg.IsRegisters() || arg.IsFpuRegisters());
    if (arg.IsRegisters()) {
      argument_slots_required_ += arg.AsRegisters().num_regs();
    } else {
      argument_slots_required_ += 8 / target::kWordSize;
    }
  }

  const NativeLocation& TranslateArgument(const NativeLocation& arg,
                                          Zone* zone) {
    if (arg.IsStack()) {
      // Add extra slots after the saved arguments for the return address and
      // frame pointer of the dummy arguments frame, which will be between the
      // saved argument registers and stack arguments. Also add slots for the
      // shadow space if present (factored into
      // kCallbackSlotsBeforeSavedArguments).
      //
      // Finally, if we are using NativeCallbackTrampolines, factor in the extra
      // stack space corresponding to those trampolines' frames (above the entry
      // frame).
      intptr_t stack_delta = kCallbackSlotsBeforeSavedArguments;
      if (NativeCallbackTrampolines::Enabled()) {
        stack_delta += StubCodeCompiler::kNativeCallbackTrampolineStackDelta;
      }
      FrameRebase rebase(
          /*old_base=*/SPREG, /*new_base=*/SPREG,
          /*stack_delta=*/(argument_slots_required_ + stack_delta) *
              compiler::target::kWordSize,
          zone);
      return rebase.Rebase(arg);
    }

    if (arg.IsRegisters()) {
      const auto& result = *new (zone) NativeStackLocation(
          arg.payload_type(), arg.container_type(), SPREG,
          argument_slots_used_ * compiler::target::kWordSize);
      argument_slots_used_ += arg.AsRegisters().num_regs();
      return result;
    }

    ASSERT(arg.IsFpuRegisters());
    const auto& result = *new (zone) NativeStackLocation(
        arg.payload_type(), arg.container_type(), SPREG,
        argument_slots_used_ * compiler::target::kWordSize);
    argument_slots_used_ += 8 / target::kWordSize;
    return result;
  }

  intptr_t argument_slots_used_ = 0;
  intptr_t argument_slots_required_ = 0;
};

CallbackMarshaller::CallbackMarshaller(Zone* zone,
                                       const Function& dart_signature)
    : BaseMarshaller(zone, dart_signature),
      callback_locs_(
          CallbackArgumentTranslator::TranslateArgumentLocations(arg_locs_,
                                                                 zone_)) {}

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
