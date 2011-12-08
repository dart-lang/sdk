// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// The class 'AssemblerMacros' contains assembler instruction groups that
// are used in Dart.

#ifndef VM_ASSEMBLER_MACROS_X64_H_
#define VM_ASSEMBLER_MACROS_X64_H_

#ifndef VM_ASSEMBLER_MACROS_H_
#error Do not include assembler_macros_x64.h directly; use assembler_macros.h.
#endif

#include "vm/allocation.h"
#include "vm/constants_x64.h"

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
};

}  // namespace dart.

#endif  // VM_ASSEMBLER_MACROS_X64_H_
