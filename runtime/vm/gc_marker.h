// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_GC_MARKER_H_
#define VM_GC_MARKER_H_

#include "vm/allocation.h"

namespace dart {

// Forward declarations.
class Heap;
class Isolate;
class MarkingVisitor;
class PageSpace;

// The class GCMarker is used to mark reachable old generation objects as part
// of the mark-sweep collection. The marking bit used is defined in RawObject.
class GCMarker : public ValueObject {
 public:
  explicit GCMarker(Heap* heap) : heap_(heap) { }
  ~GCMarker() { }

  void MarkObjects(Isolate* isolate, PageSpace* page_space);

 private:
  void Prologue(Isolate* isolate);
  void IterateRoots(Isolate* isolate, MarkingVisitor* visitor);
  void DrainMarkingStack(Isolate* isolate, MarkingVisitor* visitor);

  Heap* heap_;

  DISALLOW_IMPLICIT_CONSTRUCTORS(GCMarker);
};

}  // namespace dart

#endif  // VM_GC_MARKER_H_
