// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/flow_graph_compiler.h"
#include "vm/locations.h"

#define __ compiler->assembler()->

namespace dart {


#define DEFINE_UNIMPLEMENTED(ShortName, ClassName)                    \
  LocationSummary* ClassName::MakeLocationSummary() const {           \
    UNIMPLEMENTED();                                                  \
    return NULL;                                                      \
  }                                                                   \
                                                                      \
  void ClassName::EmitNativeCode(FlowGraphCompiler* compiler) {       \
    UNIMPLEMENTED();                                                  \
  }

FOR_EACH_COMPUTATION(DEFINE_UNIMPLEMENTED)

void BindInstr::EmitNativeCode(FlowGraphCompiler* compiler) {
  UNIMPLEMENTED();
}


}  // namespace dart

#undef __

#endif  // defined TARGET_ARCH_X64
