// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_BASE_ISOLATE_H_
#define RUNTIME_VM_BASE_ISOLATE_H_

#include "platform/assert.h"
#include "vm/globals.h"

namespace dart {

class HandleScope;
class StackResource;
class Thread;
class Zone;

// A BaseIsolate contains just enough functionality to allocate
// StackResources.  This allows us to inline the StackResource
// constructor/destructor for performance.
class BaseIsolate {
 public:
#if defined(DEBUG)
  static void AssertCurrent(BaseIsolate* isolate);
#endif

 protected:
  BaseIsolate() {}

  ~BaseIsolate() {
    // Do not delete stack resources: top_resource_ and current_zone_.
  }

  Thread* scheduled_mutator_thread_ = nullptr;

  // Stores the saved [Thread] object of a mutator. Mutators may retain their
  // thread even when being descheduled (e.g. due to having an active stack).
  Thread* mutator_thread_ = nullptr;

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseIsolate);
};

}  // namespace dart

#endif  // RUNTIME_VM_BASE_ISOLATE_H_
