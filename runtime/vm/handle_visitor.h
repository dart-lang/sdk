// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HANDLE_VISITOR_H_
#define RUNTIME_VM_HANDLE_VISITOR_H_

#include "vm/allocation.h"

namespace dart {

class HandleVisitor {
 public:
  HandleVisitor() {}
  virtual ~HandleVisitor() {}

  virtual void VisitHandle(uword addr) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(HandleVisitor);
};

}  // namespace dart

#endif  // RUNTIME_VM_HANDLE_VISITOR_H_
