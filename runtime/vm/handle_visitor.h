// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HANDLE_VISITOR_H_
#define RUNTIME_VM_HANDLE_VISITOR_H_

#include "vm/allocation.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

class Thread;

class HandleVisitor {
 public:
  explicit HandleVisitor(Thread* thread) : thread_(thread) {}
  virtual ~HandleVisitor() {}

  Thread* thread() const { return thread_; }

  virtual void VisitHandle(uword addr) = 0;

 private:
  Thread* thread_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(HandleVisitor);
};

}  // namespace dart

#endif  // RUNTIME_VM_HANDLE_VISITOR_H_
