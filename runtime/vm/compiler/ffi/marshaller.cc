// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/marshaller.h"

#include "vm/compiler/ffi/frame_rebase.h"
#include "vm/raw_object.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"

namespace dart {

namespace compiler {

namespace ffi {

#if !defined(DART_PRECOMPILED_RUNTIME)

ZoneGrowableArray<Location>*
CallbackArgumentTranslator::TranslateArgumentLocations(
    const ZoneGrowableArray<Location>& arg_locs) {
  auto& pushed_locs = *(new ZoneGrowableArray<Location>(arg_locs.length()));

  CallbackArgumentTranslator translator;
  for (intptr_t i = 0, n = arg_locs.length(); i < n; i++) {
    translator.AllocateArgument(arg_locs[i]);
  }
  for (intptr_t i = 0, n = arg_locs.length(); i < n; ++i) {
    pushed_locs.Add(translator.TranslateArgument(arg_locs[i]));
  }

  return &pushed_locs;
}

void CallbackArgumentTranslator::AllocateArgument(Location arg) {
  if (arg.IsPairLocation()) {
    AllocateArgument(arg.Component(0));
    AllocateArgument(arg.Component(1));
    return;
  }
  if (arg.HasStackIndex()) return;
  ASSERT(arg.IsRegister() || arg.IsFpuRegister());
  if (arg.IsRegister()) {
    argument_slots_required_++;
  } else {
    argument_slots_required_ += 8 / target::kWordSize;
  }
}

Location CallbackArgumentTranslator::TranslateArgument(Location arg) {
  if (arg.IsPairLocation()) {
    const Location low = TranslateArgument(arg.Component(0));
    const Location high = TranslateArgument(arg.Component(1));
    return Location::Pair(low, high);
  }

  if (arg.HasStackIndex()) {
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
        /*stack_delta=*/argument_slots_required_ + stack_delta);
    return rebase.Rebase(arg);
  }

  if (arg.IsRegister()) {
    return Location::StackSlot(argument_slots_used_++, SPREG);
  }

  ASSERT(arg.IsFpuRegister());
  const Location result =
      Location::DoubleStackSlot(argument_slots_used_, SPREG);
  argument_slots_used_ += 8 / target::kWordSize;
  return result;
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace ffi

}  // namespace compiler

}  // namespace dart
