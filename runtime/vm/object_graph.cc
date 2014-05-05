// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph.h"

#include "vm/dart.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/visitor.h"

namespace dart {

// The state of a pre-order, depth-first traversal of an object graph.
// When a node is visited, *all* its children are pushed to the stack at once.
// We insert a sentinel between the node and its children on the stack, to
// remember that the node has been visited. The node is kept on the stack while
// its children are processed, to give the visitor a complete chain of parents.
//
// TODO(koda): Potential optimizations:
// - Linked chunks instead of std::vector.
// - Use smi/heap tag bit instead of full-word sentinel.
// - Extend RawObject with incremental iteration (one child at a time).
class ObjectGraph::Stack : public ObjectPointerVisitor {
 public:
  explicit Stack(Isolate* isolate)
      : ObjectPointerVisitor(isolate), data_(kInitialCapacity) { }

  // Marks and pushes. Used to initialize this stack with roots.
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      if ((*current)->IsHeapObject() && !(*current)->IsMarked()) {
        (*current)->SetMarkBit();
        data_.Add(*current);
      }
    }
  }

  // Traverses the object graph from the current state.
  void TraverseGraph(ObjectGraph::Visitor* visitor) {
    while (!data_.is_empty()) {
      RawObject* obj = data_.Last();
      if (obj == kSentinel) {
        data_.RemoveLast();
        // The node below the sentinel has already been visited.
        data_.RemoveLast();
        continue;
      }
      ASSERT(obj->IsHeapObject());
      data_.Add(kSentinel);
      StackIterator it(this, data_.length() - 2);
      switch (visitor->VisitObject(&it)) {
        case ObjectGraph::Visitor::kProceed:
          obj->VisitPointers(this);
          break;
        case ObjectGraph::Visitor::kBacktrack:
          break;
        case ObjectGraph::Visitor::kAbort:
          return;
      }
    }
  }

 private:
  static RawObject* const kSentinel;
  static const intptr_t kInitialCapacity = 1024;
  GrowableArray<RawObject*> data_;
  friend class StackIterator;
  DISALLOW_COPY_AND_ASSIGN(Stack);
};


// We only visit heap objects, so any Smi works as the sentinel.
RawObject* const ObjectGraph::Stack::kSentinel = Smi::New(0);


RawObject* ObjectGraph::StackIterator::Get() const {
  return stack_->data_[index_];
}


bool ObjectGraph::StackIterator::MoveToParent() {
  // The parent is just below the next sentinel.
  for (int i = index_; i >= 1; --i) {
    if (stack_->data_[i] == Stack::kSentinel) {
      index_ = i - 1;
      return true;
    }
  }
  return false;
}


class Unmarker : public ObjectVisitor {
 public:
  explicit Unmarker(Isolate* isolate) : ObjectVisitor(isolate) { }

  void VisitObject(RawObject* obj) {
    if (obj->IsMarked()) {
      obj->ClearMarkBit();
    }
  }

  static void UnmarkAll(Isolate* isolate) {
    Unmarker unmarker(isolate);
    isolate->heap()->IterateObjects(&unmarker);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(Unmarker);
};


ObjectGraph::ObjectGraph(Isolate* isolate)
    : StackResource(isolate) {
  // The VM isolate has all its objects pre-marked, so iterating over it
  // would be a no-op.
  ASSERT(isolate != Dart::vm_isolate());
  isolate->heap()->WriteProtectCode(false);
}


ObjectGraph::~ObjectGraph() {
  isolate()->heap()->WriteProtectCode(true);
}


void ObjectGraph::IterateObjects(ObjectGraph::Visitor* visitor) {
  NoGCScope no_gc_scope_;
  Stack stack(isolate());
  isolate()->VisitObjectPointers(&stack, false, false);
  stack.TraverseGraph(visitor);
  Unmarker::UnmarkAll(isolate());
}


void ObjectGraph::IterateObjectsFrom(const Object& root,
                                     ObjectGraph::Visitor* visitor) {
  NoGCScope no_gc_scope_;
  Stack stack(isolate());
  RawObject* root_raw = root.raw();
  stack.VisitPointer(&root_raw);
  stack.TraverseGraph(visitor);
  // TODO(koda): Optimize if we only visited a small subgraph.
  Unmarker::UnmarkAll(isolate());
}


class SizeVisitor : public ObjectGraph::Visitor {
 public:
  SizeVisitor() : size_(0) { }
  intptr_t size() const { return size_; }
  virtual bool ShouldSkip(RawObject* obj) const { return false; }
  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* obj = it->Get();
    if (ShouldSkip(obj)) {
      return kBacktrack;
    }
    size_ += obj->Size();
    return kProceed;
  }
 private:
  intptr_t size_;
};


class SizeExcludingObjectVisitor : public SizeVisitor {
 public:
  explicit SizeExcludingObjectVisitor(const Object& skip) : skip_(skip) { }
  virtual bool ShouldSkip(RawObject* obj) const { return obj == skip_.raw(); }
 private:
  const Object& skip_;
};


class SizeExcludingClassVisitor : public SizeVisitor {
 public:
  explicit SizeExcludingClassVisitor(intptr_t skip) : skip_(skip) { }
  virtual bool ShouldSkip(RawObject* obj) const {
    return obj->GetClassId() == skip_;
  }
 private:
  const intptr_t skip_;
};


intptr_t ObjectGraph::SizeRetainedByInstance(const Object& obj) {
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingObjectVisitor excluding_obj(obj);
  IterateObjects(&excluding_obj);
  intptr_t size_excluding_obj = excluding_obj.size();
  return size_total - size_excluding_obj;
}


intptr_t ObjectGraph::SizeRetainedByClass(intptr_t class_id) {
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingClassVisitor excluding_class(class_id);
  IterateObjects(&excluding_class);
  intptr_t size_excluding_class = excluding_class.size();
  return size_total - size_excluding_class;
}

}  // namespace dart
