// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_GRAPH_H_
#define RUNTIME_VM_OBJECT_GRAPH_H_

#include "vm/allocation.h"

namespace dart {

class Array;
class Isolate;
class Object;
class RawObject;
class WriteStream;

// Utility to traverse the object graph in an ordered fashion.
// Example uses:
// - find a retaining path from the isolate roots to a particular object, or
// - determine how much memory is retained by some particular object(s).
class ObjectGraph : public StackResource {
 public:
  class Stack;

  // Allows climbing the search tree all the way to the root.
  class StackIterator {
   public:
    // The object this iterator currently points to.
    RawObject* Get() const;
    // Returns false if there is no parent.
    bool MoveToParent();
    // Offset into parent for the pointer to current object. -1 if no parent.
    intptr_t OffsetFromParentInWords() const;

   private:
    StackIterator(const Stack* stack, intptr_t index)
        : stack_(stack), index_(index) {}
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
    virtual ~Visitor() {}
    // Visits the object pointed to by *it. The iterator is only valid
    // during this call. This method must not allocate from the heap or
    // trigger GC in any way.
    virtual Direction VisitObject(StackIterator* it) = 0;
  };

  explicit ObjectGraph(Thread* thread);
  ~ObjectGraph();

  // Visits all strongly reachable objects in the isolate's heap, in a
  // pre-order, depth first traversal.
  void IterateObjects(Visitor* visitor);

  // Like 'IterateObjects', but restricted to objects reachable from 'root'
  // (including 'root' itself).
  void IterateObjectsFrom(const Object& root, Visitor* visitor);
  void IterateObjectsFrom(intptr_t class_id, Visitor* visitor);

  // The number of bytes retained by 'obj'.
  intptr_t SizeRetainedByInstance(const Object& obj);
  intptr_t SizeReachableByInstance(const Object& obj);

  // The number of bytes retained by the set of all objects of the given class.
  intptr_t SizeRetainedByClass(intptr_t class_id);
  intptr_t SizeReachableByClass(intptr_t class_id);

  // Finds some retaining path from the isolate roots to 'obj'. Populates the
  // provided array with pairs of (object, offset from parent in words),
  // starting with 'obj' itself, as far as there is room. Returns the number
  // of objects on the full path. A null input array behaves like a zero-length
  // input array. The 'offset' of a root is -1.
  //
  // To break the trivial path, the handle 'obj' is temporarily cleared during
  // the search, but restored before returning. If no path is found (i.e., the
  // provided handle was the only way to reach the object), zero is returned.
  intptr_t RetainingPath(Object* obj, const Array& path);

  // Find the objects that reference 'obj'. Populates the provided array with
  // pairs of (object pointing to 'obj', offset of pointer in words), as far as
  // there is room. Returns the number of objects found.
  //
  // An object for which this function answers no inbound references might still
  // be live due to references from the stack or embedder handles.
  intptr_t InboundReferences(Object* obj, const Array& references);

  enum SnapshotRoots { kVM, kUser };

  // Write the isolate's object graph to 'stream'. Smis and nulls are omitted.
  // Returns the number of nodes in the stream, including the root.
  // If collect_garbage is false, the graph will include weakly-reachable
  // objects.
  // TODO(koda): Document format; support streaming/chunking.
  intptr_t Serialize(WriteStream* stream,
                     SnapshotRoots roots,
                     bool collect_garbage);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectGraph);
};

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_GRAPH_H_
