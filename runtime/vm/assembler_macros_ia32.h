// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// The class 'AssemblerMacros' contains assembler instruction groups that
// are used in Dart.

#ifndef VM_ASSEMBLER_MACROS_IA32_H_
#define VM_ASSEMBLER_MACROS_IA32_H_

#ifndef VM_ASSEMBLER_MACROS_H_
#error Do not include assembler_macros_ia32.h directly; use assembler_macros.h.
#endif

#include "vm/allocation.h"
#include "vm/constants_ia32.h"

namespace dart {

// Forward declarations.
class Assembler;
class Class;
class Label;

class AssemblerMacros : public AllStatic {
 public:
  // Inlined allocation of an instance of class 'cls', code has no runtime
  // calls. Jump to 'failure' if the instance cannot be allocated here.
  // Class must be loaded in 'class_reg'. Allocated instance is returned
  // in 'instance_reg'. Only the class field of the object is initialized.
  // 'class_reg' and 'instance_reg' may not be the same register.
  static void TryAllocate(Assembler* assembler,
                          const Class& cls,
                          Register class_reg,
                          Label* failure,
                          Register instance_reg);

  // Set up a dart frame on entry with a frame pointer and PC information to
  // enable easy access to the RawInstruction object of code corresponding
  // to this frame.
  // The dart frame layout is as follows:
  //   ....
  //   ret PC
  //   saved EBP     <=== EBP
  //   pc (used to derive the RawInstruction Object of the dart code)
  //   locals space  <=== ESP
  //   .....
  // This code sets this up with the sequence:
  //   pushl ebp
  //   movl ebp, esp
  //   call L
  //   L: <code to adjust saved pc if there is any intrinsification code>
  //   .....
  static void EnterDartFrame(Assembler* assembler, intptr_t frame_size);

  // Set up a stub frame so that the stack traversal code can easily identify
  // a stub frame.
  // The stub frame layout is as follows:
  //   ....
  //   ret PC
  //   saved EBP
  //   0 (used to indicate frame is a stub frame)
  //   .....
  // This code sets this up with the sequence:
  //   pushl ebp
  //   movl ebp, esp
  //   pushl immediate(0)
  //   .....
  static void EnterStubFrame(Assembler* assembler);

  // Instruction pattern from entrypoint is used in dart frame prologs
  // to set up the frame and save a PC which can be used to figure out the
  // RawInstruction object corresponding to the code running in the frame.
  // entrypoint:
  //   pushl ebp          (size is 1 byte)
  //   movl ebp, esp      (size is 2 bytes)
  //   call L             (size is 5 bytes)
  //   L:
  static const intptr_t kOffsetOfSavedPCfromEntrypoint = 8;
};

}  // namespace dart.

#endif  // VM_ASSEMBLER_MACROS_IA32_H_
