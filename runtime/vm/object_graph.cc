// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph.h"

#include "vm/dart.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/raw_object.h"
#include "vm/reusable_handles.h"
#include "vm/visitor.h"

namespace dart {

// The state of a pre-order, depth-first traversal of an object graph.
// When a node is visited, *all* its children are pushed to the stack at once.
// We insert a sentinel between the node and its children on the stack, to
// remember that the node has been visited. The node is kept on the stack while
// its children are processed, to give the visitor a complete chain of parents.
//
// TODO(koda): Potential optimizations:
// - Use tag bits for compact Node and sentinel representations.
class ObjectGraph::Stack : public ObjectPointerVisitor {
 public:
  explicit Stack(Isolate* isolate)
      : ObjectPointerVisitor(isolate), data_(kInitialCapacity) { }

  // Marks and pushes. Used to initialize this stack with roots.
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      if ((*current)->IsHeapObject() && !(*current)->IsMarked()) {
        (*current)->SetMarkBit();
        Node node;
        node.ptr = current;
        node.obj = *current;
        data_.Add(node);
      }
    }
  }

  // Traverses the object graph from the current state.
  void TraverseGraph(ObjectGraph::Visitor* visitor) {
    while (!data_.is_empty()) {
      Node node = data_.Last();
      if (node.ptr == kSentinel) {
        data_.RemoveLast();
        // The node below the sentinel has already been visited.
        data_.RemoveLast();
        continue;
      }
      RawObject* obj = node.obj;
      ASSERT(obj->IsHeapObject());
      Node sentinel;
      sentinel.ptr = kSentinel;
      data_.Add(sentinel);
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
  struct Node {
    RawObject** ptr;  // kSentinel for the sentinel node.
    RawObject* obj;
  };

  static RawObject** const kSentinel;
  static const intptr_t kInitialCapacity = 1024;
  static const intptr_t kNoParent = -1;

  intptr_t Parent(intptr_t index) const {
    // The parent is just below the next sentinel.
    for (intptr_t i = index; i >= 1; --i) {
      if (data_[i].ptr == kSentinel) {
        return i - 1;
      }
    }
    return kNoParent;
  }

  GrowableArray<Node> data_;
  friend class StackIterator;
  DISALLOW_COPY_AND_ASSIGN(Stack);
};


RawObject** const ObjectGraph::Stack::kSentinel = NULL;


RawObject* ObjectGraph::StackIterator::Get() const {
  return stack_->data_[index_].obj;
}


bool ObjectGraph::StackIterator::MoveToParent() {
  intptr_t parent = stack_->Parent(index_);
  if (parent == Stack::kNoParent) {
    return false;
  } else {
    index_ = parent;
    return true;
  }
}


intptr_t ObjectGraph::StackIterator::OffsetFromParentInWords() const {
  intptr_t parent_index = stack_->Parent(index_);
  if (parent_index == Stack::kNoParent) {
    return -1;
  }
  Stack::Node parent = stack_->data_[parent_index];
  uword parent_start = RawObject::ToAddr(parent.obj);
  Stack::Node child = stack_->data_[index_];
  ASSERT(child.obj == *child.ptr);
  uword child_ptr_addr = reinterpret_cast<uword>(child.ptr);
  intptr_t offset = child_ptr_addr - parent_start;
  if (offset > 0 && offset < parent.obj->Size()) {
    ASSERT(Utils::IsAligned(offset, kWordSize));
    return offset >> kWordSizeLog2;
  } else {
    // Some internal VM objects visit pointers not contained within the parent.
    // For instance, RawCode::VisitCodePointers visits pointers in instructions.
    ASSERT(!parent.obj->IsDartInstance());
    return -1;
  }
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


class RetainingPathVisitor : public ObjectGraph::Visitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  RetainingPathVisitor(RawObject* obj, const Array& path)
      : obj_(obj), path_(path), length_(0) {
    ASSERT(Isolate::Current()->no_gc_scope_depth() != 0);
  }

  intptr_t length() const { return length_; }

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    if (it->Get() != obj_) {
      return kProceed;
    } else {
      HANDLESCOPE(Isolate::Current());
      Object& current = Object::Handle();
      Smi& offset_from_parent = Smi::Handle();
      do {
        intptr_t obj_index = length_ * 2;
        intptr_t offset_index = obj_index + 1;
        if (!path_.IsNull() && offset_index < path_.Length()) {
          current = it->Get();
          path_.SetAt(obj_index, current);
          offset_from_parent = Smi::New(it->OffsetFromParentInWords());
          path_.SetAt(offset_index, offset_from_parent);
        }
        ++length_;
      } while (it->MoveToParent());
      return kAbort;
    }
  }

 private:
  RawObject* obj_;
  const Array& path_;
  intptr_t length_;
};


intptr_t ObjectGraph::RetainingPath(Object* obj, const Array& path) {
  NoGCScope no_gc_scope_;
  // To break the trivial path, the handle 'obj' is temporarily cleared during
  // the search, but restored before returning.
  RawObject* raw = obj->raw();
  *obj = Object::null();
  RetainingPathVisitor visitor(raw, path);
  IterateObjects(&visitor);
  *obj = raw;
  return visitor.length();
}


class InboundReferencesVisitor : public ObjectVisitor,
                                 public ObjectPointerVisitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  InboundReferencesVisitor(Isolate* isolate,
                           RawObject* target,
                           const Array& references,
                           Object* scratch)
    : ObjectVisitor(isolate), ObjectPointerVisitor(isolate), source_(NULL),
      target_(target), references_(references), scratch_(scratch), length_(0) {
    ASSERT(Isolate::Current()->no_gc_scope_depth() != 0);
  }

  intptr_t length() const { return length_; }

  virtual void VisitObject(RawObject* raw_obj) {
    source_ = raw_obj;
    raw_obj->VisitPointers(this);
  }

  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current_ptr = first; current_ptr <= last; current_ptr++) {
      RawObject* current_obj = *current_ptr;
      if (current_obj == target_) {
        intptr_t obj_index = length_ * 2;
        intptr_t offset_index = obj_index + 1;
        if (!references_.IsNull() && offset_index < references_.Length()) {
          *scratch_ = source_;
          references_.SetAt(obj_index, *scratch_);

          *scratch_ = Smi::New(0);
          uword source_start = RawObject::ToAddr(source_);
          uword current_ptr_addr = reinterpret_cast<uword>(current_ptr);
          intptr_t offset = current_ptr_addr - source_start;
          if (offset > 0 && offset < source_->Size()) {
            ASSERT(Utils::IsAligned(offset, kWordSize));
            *scratch_ = Smi::New(offset >> kWordSizeLog2);
          } else {
            // Some internal VM objects visit pointers not contained within the
            // parent. For instance, RawCode::VisitCodePointers visits pointers
            // in instructions.
            ASSERT(!source_->IsDartInstance());
            *scratch_ = Smi::New(-1);
          }
          references_.SetAt(offset_index, *scratch_);
        }
        ++length_;
      }
    }
  }

 private:
  RawObject* source_;
  RawObject* target_;
  const Array& references_;
  Object* scratch_;
  intptr_t length_;
};


intptr_t ObjectGraph::InboundReferences(Object* obj, const Array& references) {
  Object& scratch = Object::Handle();
  NoGCScope no_gc_scope_;
  InboundReferencesVisitor visitor(isolate(), obj->raw(), references, &scratch);
  isolate()->heap()->IterateObjects(&visitor);
  return visitor.length();
}


void WritePtr(RawObject* raw, WriteStream* stream) {
  ASSERT(raw->IsHeapObject());
  ASSERT(raw->IsOldObject());
  uword addr = RawObject::ToAddr(raw);
  ASSERT(Utils::IsAligned(addr, kObjectAlignment));
  // Using units of kObjectAlignment makes the ids fit into Smis when parsed
  // in the Dart code of the Observatory.
  // TODO(koda): Use delta-encoding/back-references to further compress this.
  stream->WriteUnsigned(addr / kObjectAlignment);
}


class WritePointerVisitor : public ObjectPointerVisitor {
 public:
  WritePointerVisitor(Isolate* isolate, WriteStream* stream)
      : ObjectPointerVisitor(isolate), stream_(stream), count_(0) {}
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      if (!(*current)->IsHeapObject() || (*current == Object::null())) {
        // Ignore smis and nulls for now.
        // TODO(koda): To track which field each pointer corresponds to,
        // we'll need to encode which fields were omitted here.
        continue;
      }
      WritePtr(*current, stream_);
      ++count_;
    }
  }

  intptr_t count() const { return count_; }

 private:
  WriteStream* stream_;
  intptr_t count_;
};


void WriteHeader(RawObject* raw, intptr_t size, intptr_t cid,
                 WriteStream* stream) {
  WritePtr(raw, stream);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  stream->WriteUnsigned(size);
  stream->WriteUnsigned(cid);
}


class WriteGraphVisitor : public ObjectGraph::Visitor {
 public:
  WriteGraphVisitor(Isolate* isolate, WriteStream* stream)
    : stream_(stream), ptr_writer_(isolate, stream), count_(0) {}

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* raw_obj = it->Get();
    Isolate* isolate = Isolate::Current();
    REUSABLE_OBJECT_HANDLESCOPE(isolate);
    Object& obj = isolate->ObjectHandle();
    obj = raw_obj;
    // Each object is a header + a zero-terminated list of its neighbors.
    WriteHeader(raw_obj, raw_obj->Size(), obj.GetClassId(), stream_);
    raw_obj->VisitPointers(&ptr_writer_);
    stream_->WriteUnsigned(0);
    ++count_;
    return kProceed;
  }

  intptr_t count() const { return count_; }

 private:
  WriteStream* stream_;
  WritePointerVisitor ptr_writer_;
  intptr_t count_;
};


void ObjectGraph::Serialize(WriteStream* stream) {
  // Current encoding assumes objects do not move, so promote everything to old.
  isolate()->heap()->new_space()->Evacuate();
  WriteGraphVisitor visitor(isolate(), stream);
  stream->WriteUnsigned(0);
  stream->WriteUnsigned(0);
  stream->WriteUnsigned(0);
  {
    WritePointerVisitor ptr_writer(isolate(), stream);
    isolate()->VisitObjectPointers(&ptr_writer, false, false);
  }
  stream->WriteUnsigned(0);
  IterateObjects(&visitor);
}

}  // namespace dart
