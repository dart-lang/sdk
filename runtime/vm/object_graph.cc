// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph.h"

#include "vm/dart.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/object.h"
#include "vm/object_store.h"
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
      : ObjectPointerVisitor(isolate), data_(kInitialCapacity) {}

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
  Unmarker() {}

  void VisitObject(RawObject* obj) {
    if (obj->IsMarked()) {
      obj->ClearMarkBit();
    }
  }

  static void UnmarkAll(Isolate* isolate) {
    Unmarker unmarker;
    isolate->heap()->VisitObjectsNoImagePages(&unmarker);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(Unmarker);
};

ObjectGraph::ObjectGraph(Thread* thread) : StackResource(thread) {
  // The VM isolate has all its objects pre-marked, so iterating over it
  // would be a no-op.
  ASSERT(thread->isolate() != Dart::vm_isolate());
}

ObjectGraph::~ObjectGraph() {}

void ObjectGraph::IterateObjects(ObjectGraph::Visitor* visitor) {
  NoSafepointScope no_safepoint_scope_;
  Stack stack(isolate());
  isolate()->VisitObjectPointers(&stack, false);
  stack.TraverseGraph(visitor);
  Unmarker::UnmarkAll(isolate());
}

void ObjectGraph::IterateObjectsFrom(const Object& root,
                                     ObjectGraph::Visitor* visitor) {
  NoSafepointScope no_safepoint_scope_;
  Stack stack(isolate());
  RawObject* root_raw = root.raw();
  stack.VisitPointer(&root_raw);
  stack.TraverseGraph(visitor);
  Unmarker::UnmarkAll(isolate());
}

class InstanceAccumulator : public ObjectVisitor {
 public:
  InstanceAccumulator(ObjectGraph::Stack* stack, intptr_t class_id)
      : stack_(stack), class_id_(class_id) {}

  void VisitObject(RawObject* obj) {
    if (obj->GetClassId() == class_id_) {
      RawObject* rawobj = obj;
      stack_->VisitPointer(&rawobj);
    }
  }

 private:
  ObjectGraph::Stack* stack_;
  const intptr_t class_id_;

  DISALLOW_COPY_AND_ASSIGN(InstanceAccumulator);
};

void ObjectGraph::IterateObjectsFrom(intptr_t class_id,
                                     ObjectGraph::Visitor* visitor) {
  NoSafepointScope no_safepoint_scope_;
  Stack stack(isolate());

  InstanceAccumulator accumulator(&stack, class_id);
  isolate()->heap()->VisitObjectsNoImagePages(&accumulator);

  stack.TraverseGraph(visitor);
  Unmarker::UnmarkAll(isolate());
}

class SizeVisitor : public ObjectGraph::Visitor {
 public:
  SizeVisitor() : size_(0) {}
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
  explicit SizeExcludingObjectVisitor(const Object& skip) : skip_(skip) {}
  virtual bool ShouldSkip(RawObject* obj) const { return obj == skip_.raw(); }

 private:
  const Object& skip_;
};

class SizeExcludingClassVisitor : public SizeVisitor {
 public:
  explicit SizeExcludingClassVisitor(intptr_t skip) : skip_(skip) {}
  virtual bool ShouldSkip(RawObject* obj) const {
    return obj->GetClassId() == skip_;
  }

 private:
  const intptr_t skip_;
};

intptr_t ObjectGraph::SizeRetainedByInstance(const Object& obj) {
  HeapIterationScope iteration_scope(true);
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingObjectVisitor excluding_obj(obj);
  IterateObjects(&excluding_obj);
  intptr_t size_excluding_obj = excluding_obj.size();
  return size_total - size_excluding_obj;
}

intptr_t ObjectGraph::SizeReachableByInstance(const Object& obj) {
  HeapIterationScope iteration_scope(true);
  SizeVisitor total;
  IterateObjectsFrom(obj, &total);
  return total.size();
}

intptr_t ObjectGraph::SizeRetainedByClass(intptr_t class_id) {
  HeapIterationScope iteration_scope(true);
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingClassVisitor excluding_class(class_id);
  IterateObjects(&excluding_class);
  intptr_t size_excluding_class = excluding_class.size();
  return size_total - size_excluding_class;
}

intptr_t ObjectGraph::SizeReachableByClass(intptr_t class_id) {
  HeapIterationScope iteration_scope(true);
  SizeVisitor total;
  IterateObjectsFrom(class_id, &total);
  return total.size();
}

class RetainingPathVisitor : public ObjectGraph::Visitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  RetainingPathVisitor(RawObject* obj, const Array& path)
      : thread_(Thread::Current()), obj_(obj), path_(path), length_(0) {
    ASSERT(Thread::Current()->no_safepoint_scope_depth() != 0);
  }

  intptr_t length() const { return length_; }

  bool ShouldSkip(RawObject* obj) {
    // A retaining path through ICData is never the only retaining path,
    // and it is less informative than its alternatives.
    intptr_t cid = obj->GetClassId();
    switch (cid) {
      case kICDataCid:
        return true;
      default:
        return false;
    }
  }

  bool ShouldStop(RawObject* obj) {
    // A static field is considered a root from a language point of view.
    if (obj->IsField()) {
      const Field& field = Field::Handle(static_cast<RawField*>(obj));
      return field.is_static();
    }
    return false;
  }

  void StartList() { was_last_array_ = false; }

  intptr_t HideNDescendant(RawObject* obj) {
    // A GrowableObjectArray overwrites its internal storage.
    // Keeping both of them in the list is redundant.
    if (was_last_array_ && obj->IsGrowableObjectArray()) {
      was_last_array_ = false;
      return 1;
    }
    // A LinkedHasMap overwrites its internal storage.
    // Keeping both of them in the list is redundant.
    if (was_last_array_ && obj->IsLinkedHashMap()) {
      was_last_array_ = false;
      return 1;
    }
    was_last_array_ = obj->IsArray();
    return 0;
  }

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    if (it->Get() != obj_) {
      if (ShouldSkip(it->Get())) {
        return kBacktrack;
      } else {
        return kProceed;
      }
    } else {
      HANDLESCOPE(thread_);
      Object& current = Object::Handle();
      Smi& offset_from_parent = Smi::Handle();
      StartList();
      do {
        // We collapse the backingstore of some internal objects.
        length_ -= HideNDescendant(it->Get());
        intptr_t obj_index = length_ * 2;
        intptr_t offset_index = obj_index + 1;
        if (!path_.IsNull() && offset_index < path_.Length()) {
          current = it->Get();
          path_.SetAt(obj_index, current);
          offset_from_parent = Smi::New(it->OffsetFromParentInWords());
          path_.SetAt(offset_index, offset_from_parent);
        }
        ++length_;
      } while (!ShouldStop(it->Get()) && it->MoveToParent());
      return kAbort;
    }
  }

 private:
  Thread* thread_;
  RawObject* obj_;
  const Array& path_;
  intptr_t length_;
  bool was_last_array_;
};

intptr_t ObjectGraph::RetainingPath(Object* obj, const Array& path) {
  NoSafepointScope no_safepoint_scope_;
  HeapIterationScope iteration_scope(true);
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
      : ObjectPointerVisitor(isolate),
        source_(NULL),
        target_(target),
        references_(references),
        scratch_(scratch),
        length_(0) {
    ASSERT(Thread::Current()->no_safepoint_scope_depth() != 0);
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
  NoSafepointScope no_safepoint_scope;
  InboundReferencesVisitor visitor(isolate(), obj->raw(), references, &scratch);
  isolate()->heap()->IterateObjects(&visitor);
  return visitor.length();
}

static void WritePtr(RawObject* raw, WriteStream* stream) {
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
  WritePointerVisitor(Isolate* isolate,
                      WriteStream* stream,
                      bool only_instances)
      : ObjectPointerVisitor(isolate),
        stream_(stream),
        only_instances_(only_instances),
        count_(0) {}
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      RawObject* object = *current;
      if (!object->IsHeapObject() || object->IsVMHeapObject()) {
        // Ignore smis and objects in the VM isolate for now.
        // TODO(koda): To track which field each pointer corresponds to,
        // we'll need to encode which fields were omitted here.
        continue;
      }
      if (only_instances_ && (object->GetClassId() < kInstanceCid)) {
        continue;
      }
      WritePtr(object, stream_);
      ++count_;
    }
  }

  intptr_t count() const { return count_; }

 private:
  WriteStream* stream_;
  bool only_instances_;
  intptr_t count_;
};

static void WriteHeader(RawObject* raw,
                        intptr_t size,
                        intptr_t cid,
                        WriteStream* stream) {
  WritePtr(raw, stream);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  stream->WriteUnsigned(size);
  stream->WriteUnsigned(cid);
}

class WriteGraphVisitor : public ObjectGraph::Visitor {
 public:
  WriteGraphVisitor(Isolate* isolate,
                    WriteStream* stream,
                    ObjectGraph::SnapshotRoots roots)
      : stream_(stream),
        ptr_writer_(isolate, stream, roots == ObjectGraph::kUser),
        roots_(roots),
        count_(0) {}

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    RawObject* raw_obj = it->Get();
    Thread* thread = Thread::Current();
    REUSABLE_OBJECT_HANDLESCOPE(thread);
    Object& obj = thread->ObjectHandle();
    obj = raw_obj;
    if ((roots_ == ObjectGraph::kVM) || obj.IsField() || obj.IsInstance() ||
        obj.IsContext()) {
      // Each object is a header + a zero-terminated list of its neighbors.
      WriteHeader(raw_obj, raw_obj->Size(), obj.GetClassId(), stream_);
      raw_obj->VisitPointers(&ptr_writer_);
      stream_->WriteUnsigned(0);
      ++count_;
    }
    return kProceed;
  }

  intptr_t count() const { return count_; }

 private:
  WriteStream* stream_;
  WritePointerVisitor ptr_writer_;
  ObjectGraph::SnapshotRoots roots_;
  intptr_t count_;
};

static void IterateUserFields(ObjectPointerVisitor* visitor) {
  Thread* thread = Thread::Current();
  // Scope to prevent handles create here from appearing as stack references.
  HANDLESCOPE(thread);
  Zone* zone = thread->zone();
  const GrowableObjectArray& libraries = GrowableObjectArray::Handle(
      zone, thread->isolate()->object_store()->libraries());
  Library& library = Library::Handle(zone);
  Object& entry = Object::Handle(zone);
  Class& cls = Class::Handle(zone);
  Array& fields = Array::Handle(zone);
  Field& field = Field::Handle(zone);
  for (intptr_t i = 0; i < libraries.Length(); i++) {
    library ^= libraries.At(i);
    DictionaryIterator entries(library);
    while (entries.HasNext()) {
      entry = entries.GetNext();
      if (entry.IsClass()) {
        cls ^= entry.raw();
        fields = cls.fields();
        for (intptr_t j = 0; j < fields.Length(); j++) {
          field ^= fields.At(j);
          RawObject* ptr = field.raw();
          visitor->VisitPointer(&ptr);
        }
      } else if (entry.IsField()) {
        field ^= entry.raw();
        RawObject* ptr = field.raw();
        visitor->VisitPointer(&ptr);
      }
    }
  }
}

intptr_t ObjectGraph::Serialize(WriteStream* stream,
                                SnapshotRoots roots,
                                bool collect_garbage) {
  if (collect_garbage) {
    isolate()->heap()->CollectAllGarbage();
  }
  // Current encoding assumes objects do not move, so promote everything to old.
  isolate()->heap()->new_space()->Evacuate();
  HeapIterationScope iteration_scope(true);

  RawObject* kRootAddress = reinterpret_cast<RawObject*>(kHeapObjectTag);
  const intptr_t kRootCid = kIllegalCid;
  RawObject* kStackAddress =
      reinterpret_cast<RawObject*>(kObjectAlignment + kHeapObjectTag);

  stream->WriteUnsigned(kObjectAlignment);
  stream->WriteUnsigned(kStackCid);

  if (roots == kVM) {
    // Write root "object".
    WriteHeader(kRootAddress, 0, kRootCid, stream);
    WritePointerVisitor ptr_writer(isolate(), stream, false);
    isolate()->VisitObjectPointers(&ptr_writer, false);
    stream->WriteUnsigned(0);
  } else {
    {
      // Write root "object".
      WriteHeader(kRootAddress, 0, kRootCid, stream);
      WritePointerVisitor ptr_writer(isolate(), stream, false);
      IterateUserFields(&ptr_writer);
      WritePtr(kStackAddress, stream);
      stream->WriteUnsigned(0);
    }

    {
      // Write stack "object".
      WriteHeader(kStackAddress, 0, kStackCid, stream);
      WritePointerVisitor ptr_writer(isolate(), stream, true);
      isolate()->VisitStackPointers(&ptr_writer, false);
      stream->WriteUnsigned(0);
    }
  }

  WriteGraphVisitor visitor(isolate(), stream, roots);
  IterateObjects(&visitor);

  intptr_t object_count = visitor.count();
  if (roots == kVM) {
    object_count += 1;  // root
  } else {
    object_count += 2;  // root and stack
  }
  return object_count;
}

}  // namespace dart
