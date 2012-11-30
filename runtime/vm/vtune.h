// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_VTUNE_H_
#define VM_VTUNE_H_

#include "vm/code_observers.h"

namespace dart {

#if defined(DART_VTUNE_SUPPORT)
class VTuneCodeObserver : public CodeObserver {
 public:
  virtual bool IsActive() const;

  virtual void Notify(const char* name,
                      uword base,
                      uword prologue_offset,
                      uword size,
                      bool optimized);
};
#endif


}  // namespace dart

#endif  // VM_VTUNE_H_
