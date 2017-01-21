// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MALLOC_HOOKS_H_
#define RUNTIME_VM_MALLOC_HOOKS_H_

#include "vm/globals.h"

namespace dart {

class MallocHooks {
  static void Init();

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(MallocHooks);
};

}  // namespace dart

#endif  // RUNTIME_VM_MALLOC_HOOKS_H_
