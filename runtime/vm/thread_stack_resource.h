// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_STACK_RESOURCE_H_
#define RUNTIME_VM_THREAD_STACK_RESOURCE_H_

#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class Isolate;
class IsolateGroup;
class ThreadState;
class Thread;

class ThreadStackResource : public StackResource {
 public:
  explicit ThreadStackResource(Thread* T)
      : StackResource(reinterpret_cast<ThreadState*>(T)) {}

  ~ThreadStackResource();

  Thread* thread() const {
    return reinterpret_cast<Thread*>(StackResource::thread());
  }
  Isolate* isolate() const;
  IsolateGroup* isolate_group() const;
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_STACK_RESOURCE_H_
