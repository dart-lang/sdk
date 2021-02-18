// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
#define RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/tagged_pointer.h"

namespace dart {

class IsolateGroup;

class ReversePc : public AllStatic {
 public:
  static CodePtr Lookup(IsolateGroup* group,
                        uword pc,
                        bool is_return_address = false);
};

}  // namespace dart

#endif  // RUNTIME_VM_REVERSE_PC_LOOKUP_CACHE_H_
