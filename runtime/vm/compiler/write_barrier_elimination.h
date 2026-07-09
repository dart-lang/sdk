// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COMPILER_WRITE_BARRIER_ELIMINATION_H_
#define RUNTIME_VM_COMPILER_WRITE_BARRIER_ELIMINATION_H_

#if defined(DART_PRECOMPILED_RUNTIME)
#error "AOT runtime should not use compiler sources (including header files)"
#endif  // defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

class FlowGraph;
void EliminateWriteBarriers(FlowGraph* flow_graph);

}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_WRITE_BARRIER_ELIMINATION_H_
