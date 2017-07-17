// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/scavenger.h"
#include "platform/assert.h"
#include "vm/unit_test.h"
#include "vm/visitor.h"

namespace dart {

// Expects to visit no objects (since the space should be empty).
class FailingObjectVisitor : public ObjectVisitor {
 public:
  FailingObjectVisitor() {}
  virtual void VisitObject(RawObject* obj) { EXPECT(false); }
};

// Expects to visit no objects (since the space should be empty).
class FailingObjectPointerVisitor : public ObjectPointerVisitor {
 public:
  FailingObjectPointerVisitor() : ObjectPointerVisitor(NULL) {}
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    EXPECT(false);
  }
};

// Expects to visit no objects (since the space should be empty).
class FailingFindObjectVisitor : public FindObjectVisitor {
 public:
  FailingFindObjectVisitor() {}
  virtual bool FindObject(RawObject* obj) const {
    EXPECT(false);
    return false;
  }
};

}  // namespace dart
