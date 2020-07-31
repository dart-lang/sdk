// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HEAP_VERIFIER_H_
#define RUNTIME_VM_HEAP_VERIFIER_H_

#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/handle_visitor.h"
#include "vm/handles.h"
#include "vm/thread.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class IsolateGroup;
class ObjectSet;

enum MarkExpectation { kForbidMarked, kAllowMarked, kRequireMarked };

class VerifyObjectVisitor : public ObjectVisitor {
 public:
  VerifyObjectVisitor(IsolateGroup* isolate_group,
                      ObjectSet* allocated_set,
                      MarkExpectation mark_expectation)
      : isolate_group_(isolate_group),
        allocated_set_(allocated_set),
        mark_expectation_(mark_expectation) {}

  virtual void VisitObject(ObjectPtr obj);

 private:
  IsolateGroup* isolate_group_;
  ObjectSet* allocated_set_;
  MarkExpectation mark_expectation_;

  DISALLOW_COPY_AND_ASSIGN(VerifyObjectVisitor);
};

// A sample object pointer visitor implementation which verifies that
// the pointers visited are contained in the isolate heap.
class VerifyPointersVisitor : public ObjectPointerVisitor {
 public:
  explicit VerifyPointersVisitor(IsolateGroup* isolate_group,
                                 ObjectSet* allocated_set)
      : ObjectPointerVisitor(isolate_group), allocated_set_(allocated_set) {}

  virtual void VisitPointers(ObjectPtr* first, ObjectPtr* last);

  static void VerifyPointers(MarkExpectation mark_expectation = kForbidMarked);

 private:
  ObjectSet* allocated_set_;

  DISALLOW_COPY_AND_ASSIGN(VerifyPointersVisitor);
};

class VerifyWeakPointersVisitor : public HandleVisitor {
 public:
  explicit VerifyWeakPointersVisitor(VerifyPointersVisitor* visitor)
      : HandleVisitor(Thread::Current()), visitor_(visitor) {}

  virtual void VisitHandle(uword addr);

 private:
  ObjectPointerVisitor* visitor_;

  ObjectSet* allocated_set;

  DISALLOW_COPY_AND_ASSIGN(VerifyWeakPointersVisitor);
};

#if defined(DEBUG)
class VerifyCanonicalVisitor : public ObjectVisitor {
 public:
  explicit VerifyCanonicalVisitor(Thread* thread);
  virtual void VisitObject(ObjectPtr obj);

 private:
  Thread* thread_;
  Instance& instanceHandle_;

  DISALLOW_COPY_AND_ASSIGN(VerifyCanonicalVisitor);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // RUNTIME_VM_HEAP_VERIFIER_H_
