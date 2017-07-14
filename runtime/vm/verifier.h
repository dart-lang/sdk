// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_VERIFIER_H_
#define RUNTIME_VM_VERIFIER_H_

#include "vm/flags.h"
#include "vm/globals.h"
#include "vm/handles.h"
#include "vm/visitor.h"

namespace dart {

// Forward declarations.
class Isolate;
class ObjectSet;
class RawObject;

enum MarkExpectation { kForbidMarked, kAllowMarked, kRequireMarked };

class VerifyObjectVisitor : public ObjectVisitor {
 public:
  VerifyObjectVisitor(Isolate* isolate,
                      ObjectSet* allocated_set,
                      MarkExpectation mark_expectation)
      : isolate_(isolate),
        allocated_set_(allocated_set),
        mark_expectation_(mark_expectation) {}

  virtual void VisitObject(RawObject* obj);

 private:
  Isolate* isolate_;
  ObjectSet* allocated_set_;
  MarkExpectation mark_expectation_;

  DISALLOW_COPY_AND_ASSIGN(VerifyObjectVisitor);
};

// A sample object pointer visitor implementation which verifies that
// the pointers visited are contained in the isolate heap.
class VerifyPointersVisitor : public ObjectPointerVisitor {
 public:
  explicit VerifyPointersVisitor(Isolate* isolate, ObjectSet* allocated_set)
      : ObjectPointerVisitor(isolate), allocated_set_(allocated_set) {}

  virtual void VisitPointers(RawObject** first, RawObject** last);

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
  virtual void VisitObject(RawObject* obj);

 private:
  Thread* thread_;
  Instance& instanceHandle_;

  DISALLOW_COPY_AND_ASSIGN(VerifyCanonicalVisitor);
};
#endif  // defined(DEBUG)

}  // namespace dart

#endif  // RUNTIME_VM_VERIFIER_H_
