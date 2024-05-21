// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_INCREMENTAL_COMPACTOR_H_
#define RUNTIME_VM_HEAP_INCREMENTAL_COMPACTOR_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class PageSpace;
class ObjectVisitor;
class IncrementalForwardingVisitor;

// An evacuating compactor that is incremental in the sense that building the
// remembered set is interleaved with the mutator. The evacuation and forwarding
// is not interleaved with the mutator, which would require a read barrier.
class GCIncrementalCompactor : public AllStatic {
 public:
  static void Prologue(PageSpace* old_space);
  static bool Epilogue(PageSpace* old_space);
  static void Abort(PageSpace* old_space);

 private:
  static bool SelectEvacuationCandidates(PageSpace* old_space);
  static void CheckFreeLists(PageSpace* old_space);

  static bool HasEvacuationCandidates(PageSpace* old_space);
  static void CheckPreEvacuate(PageSpace* old_space);
  static void Evacuate(PageSpace* old_space);
  static void CheckPostEvacuate(PageSpace* old_space);
  static void FreeEvacuatedPages(PageSpace* old_space);
  static void VerifyAfterIncrementalCompaction(PageSpace* old_space);
};

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_INCREMENTAL_COMPACTOR_H_
