// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_FRAME_LAYOUT_H_
#define RUNTIME_VM_FRAME_LAYOUT_H_

#include "platform/assert.h"
#include "platform/globals.h"

// FrameLayout structure captures configuration specific properties of the
// frame layout used by the runtime system and compiler.
//
// Runtime system uses runtime_frame_layout defined in stack_frame.h.
// Compiler uses compiler::target::frame_layout defined in runtime_api.h

namespace dart {

// Forward declarations.
class LocalVariable;

struct FrameLayout {
  // The offset (in words) from FP to the first object.
  int first_object_from_fp;

  // The offset (in words) from FP to the last fixed object.
  int last_fixed_object_from_fp;

  // The offset (in words) from FP to the slot past the last parameter.
  int param_end_from_fp;

  // The offset (in words) from SP on entry (before frame is setup) to
  // the last parameter.
  int last_param_from_entry_sp;

  // The offset (in words) from FP to the first local.
  int first_local_from_fp;

  // The fixed size of the frame.
  int dart_fixed_frame_size;

  // The offset (in words) from FP to the saved pool (if applicable).
  int saved_caller_pp_from_fp;

  // The offset (in words) from FP to the code object (if applicable).
  int code_from_fp;

  // Entry and exit frame layout.
  int exit_link_slot_from_entry_fp;

  // The number of fixed slots below the saved PC.
  int saved_below_pc() const { return -first_local_from_fp; }

  // Returns the FP-relative index where [variable] can be found (assumes
  // [variable] is not captured), in words.
  int FrameSlotForVariable(const LocalVariable* variable) const;

  // Returns the FP-relative index where [variable_index] can be found (assumes
  // [variable_index] comes from a [LocalVariable::index()], which is not
  // captured).
  int FrameSlotForVariableIndex(int index) const;

  // Returns the variable index from a FP-relative index.
  intptr_t VariableIndexForFrameSlot(intptr_t frame_slot) const {
    if (frame_slot <= first_local_from_fp) {
      return frame_slot - first_local_from_fp;
    } else {
      ASSERT(frame_slot > param_end_from_fp);
      return frame_slot - param_end_from_fp;
    }
  }

  // Called to initialize the stack frame layout during startup.
  static void Init();
};

}  // namespace dart

#endif  // RUNTIME_VM_FRAME_LAYOUT_H_
