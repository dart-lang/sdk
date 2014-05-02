// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_OBJECT_GRAPH_H_
#define VM_OBJECT_GRAPH_H_

#include "vm/object.h"

namespace dart {

class Isolate;

// Utility to traverse the object graph in an ordered fashion.
// Example uses:
// - find a retaining path from the isolate roots to a particular object, or
// - determine how much memory is retained by some particular object(s).
class ObjectGraph {
 public:
  class Stack;

  // Allows climbing the search tree all the way to the root.
  class StackIterator {
   public:
    // The object this iterator currently points to.
    RawObject* Get() const;
    // Returns false if there is no parent.
    bool MoveToParent();
   private:
    StackIterator(const Stack* stack, intptr_t index)
        : stack_(stack), index_(index) { }
    const Stack* stack_;
    intptr_t index_;
    friend class ObjectGraph::Stack;
    DISALLOW_IMPLICIT_CONSTRUCTORS(StackIterator);
  };

  class Visitor {
   public:
    // Directs how the search should continue after visiting an object.
    enum Direction {
      kProceed,    // Recurse on this object's pointers.
      kBacktrack,  // Ignore this object's pointers.
      kAbort,      // Terminate the entire search immediately.
    };
    virtual ~Visitor() { }
    // Visits the object pointed to by *it. The iterator is only valid
    // during this call. This method must not allocate from the heap.
    virtual Direction VisitObject(StackIterator* it) = 0;
  };

  // No GC is allowed during the lifetime of an ObjectGraph instance.
  explicit ObjectGraph(Isolate* isolate);
  ~ObjectGraph();

  // Visits all strongly reachable objects in the isolate's heap, in a
  // pre-order, depth first traversal.
  void IterateObjects(Visitor* visitor);

  // Like 'IterateObjects', but restricted to objects reachable from 'root'
  // (including 'root' itself).
  void IterateObjectsFrom(const Object& root, Visitor* visitor);

 private:
  Isolate* isolate_;
  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectGraph);
};

}  // namespace dart

#endif  // VM_OBJECT_GRAPH_H_
