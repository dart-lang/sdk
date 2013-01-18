// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// The class 'AssemblerMacros' contains assembler instruction groups that
// are used in Dart.

#ifndef VM_ASSEMBLER_MACROS_ARM_H_
#define VM_ASSEMBLER_MACROS_ARM_H_

#ifndef VM_ASSEMBLER_MACROS_H_
#error Do not include assembler_macros_arm.h directly; use assembler_macros.h.
#endif

#include "vm/allocation.h"
#include "vm/constants_arm.h"

namespace dart {

// Forward declarations.
class Assembler;
class Class;
class Label;

class AssemblerMacros : public AllStatic {
 public:
  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Allocated instance is returned in 'instance_reg'.
  // Only the tags field of the object is initialized.
  static void TryAllocate(Assembler* assembler,
                          const Class& cls,
                          Label* failure,
                          bool near_jump,
                          Register instance_reg);

  // Set up a dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  static void EnterDartFrame(Assembler* assembler, intptr_t frame_size);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  static void EnterStubFrame(Assembler* assembler);

  // Instruction pattern from entrypoint is used in dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  static const intptr_t kOffsetOfSavedPCfromEntrypoint = -1;  // UNIMPLEMENTED.
};

}  // namespace dart.

#endif  // VM_ASSEMBLER_MACROS_ARM_H_

