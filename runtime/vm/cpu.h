// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CPU_H_
#define VM_CPU_H_

#include "vm/allocation.h"

namespace dart {

// Forward Declarations.
class Error;
class Instance;


class CPU : public AllStatic {
 public:
  static void FlushICache(uword start, uword size);
  static const char* Id();
};

}  // namespace dart

#endif  // VM_CPU_H_
