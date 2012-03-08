// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GC_CALLBACKS_H_
#define VM_GC_CALLBACKS_H_

#include "include/dart_api.h"
#include "platform/utils.h"

namespace dart {

// A container for garbage collection callback function pointers.
// Pointers to the callback methods are stored within linked list
// nodes managed by the container.
template<typename T>
class GcCallbacks {
 public:
  GcCallbacks() : head_(NULL) {
  }

  ~GcCallbacks() {
    while (head_ != NULL) {
      Link* prev = head_;
      head_ = head_->next_;
      delete prev;
    }
  }

  // Adds a new callback to the list.  The new callback must not
  // already be present in the list.
  void Add(T callback) {
    ASSERT(callback != NULL);
    Link* link = new Link(callback, head_);
    head_ = link;
  }

  // Removes a callback from the list.  The callback must be present
  // in the list.
  void Remove(T callback) {
    ASSERT(callback != NULL);
    if (head_ == NULL) return;
    Link* prev = head_;
    Link* curr = head_->next_;
    if (prev->callback_ == callback) {
      head_ = curr;
      delete prev;
      return;
    }
    while (curr != NULL) {
      if (curr->callback_ == callback) {
        prev->next_ = curr->next_;
        delete curr;
        return;
      }
      prev = curr;
      curr = curr->next_;
    }
  }

  // Iterates through all of the callbacks in the list and invokes
  // their callback methods.
  void Invoke() const {
    for (Link* curr = head_; curr != NULL; curr = curr->next_) {
      (*curr->callback_)();
    }
  }

  // Returns the number of callbacks stored in the list.
  intptr_t Count() const {
    intptr_t sum = 0;
    for (Link* curr = head_; curr != NULL; curr = curr->next_) {
      ++sum;
    }
    return sum;
  }

  // Returns true if the specified callback is present in the
  // container.
  bool Contains(T callback) const {
    for (Link* curr = head_; curr != NULL; curr = curr->next_) {
      if (curr->callback_ == callback) {
        return true;
      }
    }
    return false;
  }

 private:
  // A linked-list element.
  struct Link {
    Link(T callback, Link* next) : callback_(callback), next_(next) {
    }
    T callback_;
    Link* next_;
  };

  Link* head_;
};


// A container for storing garbage collection prologue methods.
class GcPrologueCallbacks : public GcCallbacks<Dart_GcPrologueCallback> {};


// A container for storing garbage collection epilogue methods.
class GcEpilogueCallbacks : public GcCallbacks<Dart_GcEpilogueCallback> {};

};  // namespace dart

#endif  // VM_GC_CALLBACKS_H_
