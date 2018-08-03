// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_DBC.
#if defined(TARGET_ARCH_DBC)

#include "vm/compiler/intrinsifier.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/cpu.h"
#include "vm/dart_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/regexp_assembler.h"
#include "vm/simulator.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, interpret_irregexp);

intptr_t Intrinsifier::ParameterSlotFromSp() {
  return -1;
}

#define DEFINE_FUNCTION(class_name, test_function_name, enum_name, type, fp)   \
  void Intrinsifier::enum_name(Assembler* assembler) {                         \
    if (Simulator::IsSupportedIntrinsic(Simulator::k##enum_name##Intrinsic)) { \
      assembler->Intrinsic(Simulator::k##enum_name##Intrinsic);                \
    }                                                                          \
  }

ALL_INTRINSICS_LIST(DEFINE_FUNCTION)
GRAPH_INTRINSICS_LIST(DEFINE_FUNCTION)
#undef DEFINE_FUNCTION

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
