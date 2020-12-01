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
  void AssertCurrentThreadIsMutator() const;
#else
  void AssertCurrentThreadIsMutator() const {}
#endif  // DEBUG

#if defined(DEBUG)
  static void AssertCurrent(BaseIsolate* isolate);
#endif

 protected:
  BaseIsolate() {}

  ~BaseIsolate() {
    // Do not delete stack resources: top_resource_ and current_zone_.
  }

  Thread* scheduled_mutator_thread_ = nullptr;

  // TODO(asiva): Currently we treat a mutator thread as a special thread
  // and always schedule execution of Dart code on the same mutator thread
  // object. The ApiLocalScope has been made thread specific but we still
  // have scenarios where we do a temporary exit of an Isolate with live
  // zones/handles in the API scope :
  // - Dart_RunLoop()
  // - IsolateSaver in Dart_NewNativePort
  // We probably need a mechanism to return to the specific thread only
  // for these specific cases. We should also determine if the embedder
  // should allow exiting an isolate with live state in zones/handles in
  // which case a new API for returning to the specific thread needs to be
  // added.
  Thread* mutator_thread_ = nullptr;

 private:
  DISALLOW_COPY_AND_ASSIGN(BaseIsolate);
};

}  // namespace dart

#endif  // RUNTIME_VM_BASE_ISOLATE_H_
