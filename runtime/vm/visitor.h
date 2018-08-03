// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VISITOR_H_
#define RUNTIME_VM_VISITOR_H_

#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/growable_array.h"

namespace dart {

// Forward declarations.
class Isolate;
class RawObject;
class RawFunction;

// An object pointer visitor interface.
class ObjectPointerVisitor {
 public:
  explicit ObjectPointerVisitor(Isolate* isolate) : isolate_(isolate) {}
  virtual ~ObjectPointerVisitor() {}

  Isolate* isolate() const { return isolate_; }

  // Range of pointers to visit 'first' <= pointer <= 'last'.
  virtual void VisitPointers(RawObject** first, RawObject** last) = 0;

  virtual bool visit_function_code() const { return true; }
  virtual void add_skipped_code_function(RawFunction* funct) { UNREACHABLE(); }
  // len argument is the number of pointers to visit starting from 'p'.
  void VisitPointers(RawObject** p, intptr_t len) {
    VisitPointers(p, (p + len - 1));
  }

  void VisitPointer(RawObject** p) { VisitPointers(p, p); }

 private:
  Isolate* isolate_;
  NoSafepointScope no_safepoints_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectPointerVisitor);
};

// An object visitor interface.
class ObjectVisitor {
 public:
  ObjectVisitor() {}

  virtual ~ObjectVisitor() {}

  // Invoked for each object.
  virtual void VisitObject(RawObject* obj) = 0;

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
  virtual bool FindObject(RawObject* obj) const = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(FindObjectVisitor);
};

}  // namespace dart

#endif  // RUNTIME_VM_VISITOR_H_
