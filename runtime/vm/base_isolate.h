// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_BASE_ISOLATE_H_
#define VM_BASE_ISOLATE_H_

namespace dart {

class HandleScope;
class StackResource;
class Zone;

// A BaseIsolate contains just enough functionality to allocate
// StackResources.  This allows us to inline the StackResource
// constructor/destructor for performance.
class BaseIsolate {
 public:
  StackResource* top_resource() const { return top_resource_; }
  void set_top_resource(StackResource* value) { top_resource_ = value; }

  Zone* current_zone() const { return current_zone_; }
  void set_current_zone(Zone* zone) { current_zone_ = zone; }

  HandleScope* top_handle_scope() const {
#if defined(DEBUG)
    return top_handle_scope_;
#else
    return 0;
#endif
  }

  void set_top_handle_scope(HandleScope* handle_scope) {
#if defined(DEBUG)
    top_handle_scope_ = handle_scope;
#endif
  }

  int32_t no_handle_scope_depth() const {
#if defined(DEBUG)
    return no_handle_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ < INT_MAX);
    no_handle_scope_depth_ += 1;
#endif
  }

  void DecrementNoHandleScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_handle_scope_depth_ > 0);
    no_handle_scope_depth_ -= 1;
#endif
  }

  int32_t no_gc_scope_depth() const {
#if defined(DEBUG)
    return no_gc_scope_depth_;
#else
    return 0;
#endif
  }

  void IncrementNoGCScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_gc_scope_depth_ < INT_MAX);
    no_gc_scope_depth_ += 1;
#endif
  }

  void DecrementNoGCScopeDepth() {
#if defined(DEBUG)
    ASSERT(no_gc_scope_depth_ > 0);
    no_gc_scope_depth_ -= 1;
#endif
  }

#if defined(DEBUG)
  static void AssertCurrent(BaseIsolate* isolate);
#endif

 protected:
  BaseIsolate()
      : top_resource_(NULL),
#if defined(DEBUG)
        current_zone_(NULL),
        top_handle_scope_(NULL),
        no_handle_scope_depth_(0),
        no_gc_scope_depth_(0)
#else
        current_zone_(NULL)
#endif
  {}

  ~BaseIsolate() {
    // Do not delete stack resources: top_resource_ and current_zone_.
  }

  StackResource* top_resource_;
  Zone* current_zone_;
#if defined(DEBUG)
  HandleScope* top_handle_scope_;
  int32_t no_handle_scope_depth_;
  int32_t no_gc_scope_depth_;
#endif

  DISALLOW_COPY_AND_ASSIGN(BaseIsolate);
};

}  // namespace dart

#endif  // VM_BASE_ISOLATE_H_
