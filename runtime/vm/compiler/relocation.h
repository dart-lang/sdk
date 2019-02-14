// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_RELOCATION_H_
#define RUNTIME_VM_COMPILER_RELOCATION_H_

#include "vm/allocation.h"
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/type_testing_stubs.h"
#include "vm/visitor.h"

namespace dart {

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_DBC) &&                  \
    !defined(TARGET_ARCH_IA32)

// Relocates the given code objects by patching the instructions with the
// correct pc offsets.
//
// Produces a set of [ImageWriterCommand]s which tell the image writer in which
// order (and at which offset) to emit instructions.
class CodeRelocator : public StackResource {
 public:
  // Relocates instructions of the code objects provided by patching any
  // pc-relative calls/jumps.
  //
  // Populates the image writer command array which must be used later to write
  // the ".text" segment.
  static void Relocate(Thread* thread,
                       GrowableArray<RawCode*>* code_objects,
                       GrowableArray<ImageWriterCommand>* commands,
                       bool is_vm_isolate) {
    CodeRelocator relocator(thread, code_objects, commands);
    relocator.Relocate(is_vm_isolate);
  }

 private:
  CodeRelocator(Thread* thread,
                GrowableArray<RawCode*>* code_objects,
                GrowableArray<ImageWriterCommand>* commands)
      : StackResource(thread),
        code_objects_(code_objects),
        commands_(commands) {}

  void Relocate(bool is_vm_isolate);

  GrowableArray<RawCode*>* code_objects_;
  GrowableArray<ImageWriterCommand>* commands_;
};

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_DBC) &&           \
        // !defined(TARGET_ARCH_IA32)

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_RELOCATION_H_
