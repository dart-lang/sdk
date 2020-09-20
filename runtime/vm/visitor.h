// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VISITOR_H_
#define RUNTIME_VM_VISITOR_H_

#include "vm/allocation.h"
#include "vm/class_table.h"
#include "vm/globals.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Isolate;
class IsolateGroup;

// An object pointer visitor interface.
class ObjectPointerVisitor {
 public:
  explicit ObjectPointerVisitor(IsolateGroup* isolate_group);
  virtual ~ObjectPointerVisitor() {}

  IsolateGroup* isolate_group() const { return isolate_group_; }

  // Visit pointers inside the given typed data [view].
  //
  // Range of pointers to visit 'first' <= pointer <= 'last'.
  virtual void VisitTypedDataViewPointers(TypedDataViewPtr view,
                                          ObjectPtr* first,
                                          ObjectPtr* last) {
    VisitPointers(first, last);
  }

  // Range of pointers to visit 'first' <= pointer <= 'last'.
  virtual void VisitPointers(ObjectPtr* first, ObjectPtr* last) = 0;

  // len argument is the number of pointers to visit starting from 'p'.
  void VisitPointers(ObjectPtr* p, intptr_t len) {
    VisitPointers(p, (p + len - 1));
  }

  void VisitPointer(ObjectPtr* p) { VisitPointers(p, p); }

  const char* gc_root_type() const { return gc_root_type_; }
  void set_gc_root_type(const char* gc_root_type) {
    gc_root_type_ = gc_root_type;
  }

  void clear_gc_root_type() { gc_root_type_ = "unknown"; }

  virtual bool visit_weak_persistent_handles() const { return false; }

  // When visiting objects to build retaining paths, trace field values
  // through fields.
  // Otherwise trace field values through isolate's field_table.
  virtual bool trace_values_through_fields() const { return false; }

  const SharedClassTable* shared_class_table() const {
    return shared_class_table_;
  }

 private:
  IsolateGroup* isolate_group_;
  const char* gc_root_type_;
  SharedClassTable* shared_class_table_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectPointerVisitor);
};

// An object visitor interface.
class ObjectVisitor {
 public:
  ObjectVisitor() {}

  virtual ~ObjectVisitor() {}

  // Invoked for each object.
  virtual void VisitObject(ObjectPtr obj) = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(ObjectVisitor);
};

// An object finder visitor interface.
class FindObjectVisitor {
 public:
  FindObjectVisitor() {}
  virtual ~FindObjectVisitor() {}

  // Allow to specify a address filter.
  virtual uword filter_addr() const { return 0; }
  bool VisitRange(uword begin_addr, uword end_addr) const {
    uword addr = filter_addr();
    return (addr == 0) || ((begin_addr <= addr) && (addr < end_addr));
  }

  // Check if object matches find condition.
  virtual bool FindObject(ObjectPtr obj) const = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(FindObjectVisitor);
};

}  // namespace dart

#endif  // RUNTIME_VM_VISITOR_H_
