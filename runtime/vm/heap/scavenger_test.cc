// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/heap/scavenger.h"
#include "platform/assert.h"
#include "vm/unit_test.h"
#include "vm/visitor.h"

namespace dart {

// Expects to visit no objects (since the space should be empty).
class FailingObjectVisitor : public ObjectVisitor {
 public:
  FailingObjectVisitor() {}
  void VisitObject(ObjectPtr obj) override { EXPECT(false); }
};

// Expects to visit no objects (since the space should be empty).
class FailingObjectPointerVisitor : public ObjectPointerVisitor {
 public:
  FailingObjectPointerVisitor() : ObjectPointerVisitor(nullptr) {}
  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    EXPECT(false);
  }
#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    EXPECT(false);
  }
#endif
};

// Expects to visit no objects (since the space should be empty).
class FailingFindObjectVisitor : public FindObjectVisitor {
 public:
  FailingFindObjectVisitor() {}
  virtual bool FindObject(ObjectPtr obj) const {
    EXPECT(false);
    return false;
  }
};

}  // namespace dart
