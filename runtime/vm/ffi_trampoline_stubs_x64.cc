// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(dacoharkes): Move this into compiler namespace.

#include "vm/class_id.h"
#include "vm/globals.h"

#include "vm/stub_code.h"

#if defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/ffi.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/constants_x64.h"
#include "vm/dart_entry.h"
#include "vm/heap/heap.h"
#include "vm/heap/scavenger.h"
#include "vm/instructions.h"
#include "vm/object_store.h"
#include "vm/resolver.h"
#include "vm/stack_frame.h"
#include "vm/tags.h"
#include "vm/type_testing_stubs.h"

#define __ assembler->

namespace dart {

void GenerateFfiInverseTrampoline(Assembler* assembler,
                                  const Function& signature,
                                  void* dart_entry_point) {
  ZoneGrowableArray<Representation>* arg_representations =
      compiler::ffi::ArgumentRepresentations(signature);
  ZoneGrowableArray<Location>* arg_locations =
      compiler::ffi::ArgumentLocations(*arg_representations);

  intptr_t num_dart_arguments = signature.num_fixed_parameters();
  intptr_t num_arguments = num_dart_arguments - 1;  // Ignore closure.

  // TODO(dacoharkes): Implement this.
  // https://github.com/dart-lang/sdk/issues/35761
  // Look at StubCode::GenerateInvokeDartCodeStub.

  __ int3();

  for (intptr_t i = 0; i < num_arguments; i++) {
    Register reg = arg_locations->At(i).reg();
    __ SmiTag(reg);
  }

  __ movq(RBX, Immediate(reinterpret_cast<intptr_t>(dart_entry_point)));

  __ int3();

  __ call(RBX);

  __ int3();
}

}  // namespace dart

#endif  // defined(TARGET_ARCH_X64) && !defined(DART_PRECOMPILED_RUNTIME)
