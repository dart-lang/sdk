// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PENDING_DEOPTS_H_
#define RUNTIME_VM_PENDING_DEOPTS_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include "vm/growable_array.h"

namespace dart {

class PendingLazyDeopt {
 public:
  PendingLazyDeopt(uword fp, uword pc) : fp_(fp), pc_(pc) {}
  uword fp() { return fp_; }
  uword pc() { return pc_; }
  void set_pc(uword pc) { pc_ = pc; }

 private:
  uword fp_;
  uword pc_;
};

class PendingDeopts {
 public:
  enum ClearReason {
    kClearDueToThrow,
    kClearDueToDeopt,
  };
  PendingDeopts();
  ~PendingDeopts();

  bool HasPendingDeopts() { return pending_deopts_->length() > 0; }

  void AddPendingDeopt(uword fp, uword pc);
  uword FindPendingDeopt(uword fp);
  void ClearPendingDeoptsBelow(uword fp, ClearReason reason);
  void ClearPendingDeoptsAtOrBelow(uword fp, ClearReason reason);
  uword RemapExceptionPCForDeopt(uword program_counter, uword frame_pointer);

 private:
  MallocGrowableArray<PendingLazyDeopt>* pending_deopts_;
};

}  // namespace dart

#endif  // RUNTIME_VM_PENDING_DEOPTS_H_
