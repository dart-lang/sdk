// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PRECOMPILER_H_
#define VM_PRECOMPILER_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class RawError;

class Precompiler : public AllStatic {
 public:
  static RawError* CompileAll();
};

}  // namespace dart

#endif  // VM_PRECOMPILER_H_
