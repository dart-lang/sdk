// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Classes that describe assembly patterns as used by inline caches.

#ifndef RUNTIME_VM_INSTRUCTIONS_KBC_H_
#define RUNTIME_VM_INSTRUCTIONS_KBC_H_

#include "vm/globals.h"
#if !defined(DART_PRECOMPILED_RUNTIME)

#include "vm/object.h"

namespace dart {

class KBCNativeCallPattern : public AllStatic {
 public:
  static TypedDataPtr GetNativeEntryDataAt(uword pc, const Bytecode& bytecode);
};

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart

#endif  // RUNTIME_VM_INSTRUCTIONS_KBC_H_
