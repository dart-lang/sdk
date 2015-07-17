// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BASE_ISOLATE_H_
#define VM_BASE_ISOLATE_H_

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

  int32_t no_safepoint_scope_depth() const {
#if defined(DEBUG)
    return no_safepoint_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ < INT_MAX);
    no_safepoint_scope_depth_ += 1;
#endif
  }

  void DecrementNoSafepointScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_safepoint_scope_depth_ > 0);
    no_safepoint_scope_depth_ -= 1;
#endif
  }

  int32_t no_callback_scope_depth() const {
    return no_callback_scope_depth_;
  }

  void IncrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ < INT_MAX);
    no_callback_scope_depth_ += 1;
  }

  void DecrementNoCallbackScopeDepth() {
    ASSERT(no_callback_scope_depth_ > 0);
    no_callback_scope_depth_ -= 1;
  }

#if defined(DEBUG)
  static void AssertCurrent(BaseIsolate* isolate);
#endif

 protected:
  BaseIsolate()
      : mutator_thread_(NULL),
#if defined(DEBUG)
        no_safepoint_scope_depth_(0),
#endif
        no_callback_scope_depth_(0)
  {}

  ~BaseIsolate() {
    // Do not delete stack resources: top_resource_ and current_zone_.
  }

  Thread* mutator_thread_;
#if defined(DEBUG)
  int32_t no_safepoint_scope_depth_;
#endif
  int32_t no_callback_scope_depth_;

 private:
  // During migration, some deprecated interfaces will default to using the
  // mutator_thread_ (can't use accessor in Isolate due to circular deps).
  friend class StackResource;
  DISALLOW_COPY_AND_ASSIGN(BaseIsolate);
};

}  // namespace dart

#endif  // VM_BASE_ISOLATE_H_
