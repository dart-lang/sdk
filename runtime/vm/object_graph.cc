// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph.h"

#include "vm/dart.h"
#include "vm/dart_api_state.h"
#include "vm/growable_array.h"
#include "vm/isolate.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/profiler.h"
#include "vm/raw_object.h"
#include "vm/raw_object_fields.h"
#include "vm/reusable_handles.h"
#include "vm/visitor.h"

namespace dart {

#if !defined(PRODUCT)

static bool IsUserClass(intptr_t cid) {
  if (cid == kContextCid) return true;
  if (cid == kTypeArgumentsCid) return false;
  return cid >= kInstanceCid;
}

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
  explicit Stack(IsolateGroup* isolate_group)
      : ObjectPointerVisitor(isolate_group),
        include_vm_objects_(true),
        data_(kInitialCapacity) {
    object_ids_ = new WeakTable();
  }
  ~Stack() {
    delete object_ids_;
    object_ids_ = nullptr;
  }

  // Marks and pushes. Used to initialize this stack with roots.
  // We can use ObjectIdTable normally used by serializers because it
  // won't be in use while handling a service request (ObjectGraph's only use).
  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      if ((*current)->IsHeapObject() && !(*current)->InVMIsolateHeap() &&
          object_ids_->GetValueExclusive(*current) == 0) {  // not visited yet
        if (!include_vm_objects_ && !IsUserClass((*current)->GetClassId())) {
          continue;
        }
        object_ids_->SetValueExclusive(*current, 1);
        Node node;
        node.ptr = current;
        node.obj = *current;
        node.gc_root_type = gc_root_type();
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
      visitor->gc_root_type = node.gc_root_type;
      Visitor::Direction direction = visitor->VisitObject(&it);
      if (direction == ObjectGraph::Visitor::kAbort) {
        break;
      }
      if (direction == ObjectGraph::Visitor::kProceed) {
        set_gc_root_type(node.gc_root_type);
        obj->VisitPointers(this);
        clear_gc_root_type();
      }
    }
  }

  virtual bool visit_weak_persistent_handles() const {
    return visit_weak_persistent_handles_;
  }

  void set_visit_weak_persistent_handles(bool value) {
    visit_weak_persistent_handles_ = value;
  }

  bool include_vm_objects_;

 private:
  struct Node {
    RawObject** ptr;  // kSentinel for the sentinel node.
    RawObject* obj;
    const char* gc_root_type;
  };

  bool visit_weak_persistent_handles_ = false;
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

  // During the iteration of the heap we are already at a safepoint, so there is
  // no need to let the GC know about [object_ids_] (i.e. GC cannot run while we
  // use [object_ids]).
  WeakTable* object_ids_ = nullptr;
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
  if (offset > 0 && offset < parent.obj->HeapSize()) {
    ASSERT(Utils::IsAligned(offset, kWordSize));
    return offset >> kWordSizeLog2;
  } else {
    // Some internal VM objects visit pointers not contained within the parent.
    // For instance, RawCode::VisitCodePointers visits pointers in instructions.
    ASSERT(!parent.obj->IsDartInstance());
    return -1;
  }
}

static void IterateUserFields(ObjectPointerVisitor* visitor) {
  visitor->set_gc_root_type("user global");
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
  visitor->clear_gc_root_type();
}

ObjectGraph::ObjectGraph(Thread* thread) : ThreadStackResource(thread) {
  // The VM isolate has all its objects pre-marked, so iterating over it
  // would be a no-op.
  ASSERT(thread->isolate() != Dart::vm_isolate());
}

ObjectGraph::~ObjectGraph() {}

void ObjectGraph::IterateObjects(ObjectGraph::Visitor* visitor) {
  Stack stack(isolate_group());
  stack.set_visit_weak_persistent_handles(
      visitor->visit_weak_persistent_handles());
  isolate_group()->VisitObjectPointers(&stack,
                                       ValidationPolicy::kDontValidateFrames);
  stack.TraverseGraph(visitor);
}

void ObjectGraph::IterateUserObjects(ObjectGraph::Visitor* visitor) {
  Stack stack(isolate_group());
  stack.set_visit_weak_persistent_handles(
      visitor->visit_weak_persistent_handles());
  IterateUserFields(&stack);
  stack.include_vm_objects_ = false;
  stack.TraverseGraph(visitor);
}

void ObjectGraph::IterateObjectsFrom(const Object& root,
                                     ObjectGraph::Visitor* visitor) {
  Stack stack(isolate_group());
  stack.set_visit_weak_persistent_handles(
      visitor->visit_weak_persistent_handles());
  RawObject* root_raw = root.raw();
  stack.VisitPointer(&root_raw);
  stack.TraverseGraph(visitor);
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
  HeapIterationScope iteration(thread());
  Stack stack(isolate_group());

  InstanceAccumulator accumulator(&stack, class_id);
  iteration.IterateObjectsNoImagePages(&accumulator);

  stack.TraverseGraph(visitor);
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
    size_ += obj->HeapSize();
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
  HeapIterationScope iteration_scope(Thread::Current(), true);
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingObjectVisitor excluding_obj(obj);
  IterateObjects(&excluding_obj);
  intptr_t size_excluding_obj = excluding_obj.size();
  return size_total - size_excluding_obj;
}

intptr_t ObjectGraph::SizeReachableByInstance(const Object& obj) {
  HeapIterationScope iteration_scope(Thread::Current(), true);
  SizeVisitor total;
  IterateObjectsFrom(obj, &total);
  return total.size();
}

intptr_t ObjectGraph::SizeRetainedByClass(intptr_t class_id) {
  HeapIterationScope iteration_scope(Thread::Current(), true);
  SizeVisitor total;
  IterateObjects(&total);
  intptr_t size_total = total.size();
  SizeExcludingClassVisitor excluding_class(class_id);
  IterateObjects(&excluding_class);
  intptr_t size_excluding_class = excluding_class.size();
  return size_total - size_excluding_class;
}

intptr_t ObjectGraph::SizeReachableByClass(intptr_t class_id) {
  HeapIterationScope iteration_scope(Thread::Current(), true);
  SizeVisitor total;
  IterateObjectsFrom(class_id, &total);
  return total.size();
}

class RetainingPathVisitor : public ObjectGraph::Visitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  RetainingPathVisitor(RawObject* obj, const Array& path)
      : thread_(Thread::Current()), obj_(obj), path_(path), length_(0) {
  }

  intptr_t length() const { return length_; }
  virtual bool visit_weak_persistent_handles() const { return true; }

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

ObjectGraph::RetainingPathResult ObjectGraph::RetainingPath(Object* obj,
                                                            const Array& path) {
  HeapIterationScope iteration_scope(Thread::Current(), true);
  // To break the trivial path, the handle 'obj' is temporarily cleared during
  // the search, but restored before returning.
  RawObject* raw = obj->raw();
  *obj = Object::null();
  RetainingPathVisitor visitor(raw, path);
  IterateUserObjects(&visitor);
  if (visitor.length() == 0) {
    IterateObjects(&visitor);
  }
  *obj = raw;
  return {visitor.length(), visitor.gc_root_type};
}

class InboundReferencesVisitor : public ObjectVisitor,
                                 public ObjectPointerVisitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  InboundReferencesVisitor(Isolate* isolate,
                           RawObject* target,
                           const Array& references,
                           Object* scratch)
      : ObjectPointerVisitor(isolate->group()),
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
          if (offset > 0 && offset < source_->HeapSize()) {
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
  HeapIterationScope iteration(Thread::Current());
  NoSafepointScope no_safepoint;
  InboundReferencesVisitor visitor(isolate(), obj->raw(), references, &scratch);
  iteration.IterateObjects(&visitor);
  return visitor.length();
}

// Each HeapPage is divided into blocks of size kBlockSize. Each object belongs
// to the block containing its header word.
// When generating a heap snapshot, we assign objects sequential ids in heap
// iteration order. A bitvector is computed that indicates the number of objects
// in each block, so the id of any object in the block can be found be adding
// the number of bits set before the object to the block's first id.
// Compare ForwardingBlock used for heap compaction.
class CountingBlock {
 public:
  void Clear() {
    base_count_ = 0;
    count_bitvector_ = 0;
  }

  intptr_t Lookup(uword addr) const {
    uword block_offset = addr & ~kBlockMask;
    intptr_t bitvector_shift = block_offset >> kObjectAlignmentLog2;
    ASSERT(bitvector_shift < kBitsPerWord);
    uword preceding_bitmask = (static_cast<uword>(1) << bitvector_shift) - 1;
    return base_count_ +
           Utils::CountOneBitsWord(count_bitvector_ & preceding_bitmask);
  }

  void Record(uword old_addr, intptr_t id) {
    if (base_count_ == 0) {
      ASSERT(count_bitvector_ == 0);
      base_count_ = id;  // First object in the block.
    }

    uword block_offset = old_addr & ~kBlockMask;
    intptr_t bitvector_shift = block_offset >> kObjectAlignmentLog2;
    ASSERT(bitvector_shift < kBitsPerWord);
    count_bitvector_ |= static_cast<uword>(1) << bitvector_shift;
  }

 private:
  intptr_t base_count_;
  uword count_bitvector_;
  COMPILE_ASSERT(kBitVectorWordsPerBlock == 1);

  DISALLOW_COPY_AND_ASSIGN(CountingBlock);
};

class CountingPage {
 public:
  void Clear() {
    for (intptr_t i = 0; i < kBlocksPerPage; i++) {
      blocks_[i].Clear();
    }
  }

  intptr_t Lookup(uword addr) { return BlockFor(addr)->Lookup(addr); }
  void Record(uword addr, intptr_t id) {
    return BlockFor(addr)->Record(addr, id);
  }

  CountingBlock* BlockFor(uword addr) {
    intptr_t page_offset = addr & ~kPageMask;
    intptr_t block_number = page_offset / kBlockSize;
    ASSERT(block_number >= 0);
    ASSERT(block_number <= kBlocksPerPage);
    return &blocks_[block_number];
  }

 private:
  CountingBlock blocks_[kBlocksPerPage];

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(CountingPage);
};

void HeapSnapshotWriter::EnsureAvailable(intptr_t needed) {
  intptr_t available = capacity_ - size_;
  if (available >= needed) {
    return;
  }

  if (buffer_ != nullptr) {
    Flush();
  }
  ASSERT(buffer_ == nullptr);

  intptr_t chunk_size = kPreferredChunkSize;
  if (chunk_size < needed + kMetadataReservation) {
    chunk_size = needed + kMetadataReservation;
  }
  buffer_ = reinterpret_cast<uint8_t*>(malloc(chunk_size));
  size_ = kMetadataReservation;
  capacity_ = chunk_size;
}

void HeapSnapshotWriter::Flush(bool last) {
  if (size_ == 0 && !last) {
    return;
  }

  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("jsonrpc", "2.0");
    jsobj.AddProperty("method", "streamNotify");
    {
      JSONObject params(&jsobj, "params");
      params.AddProperty("streamId", Service::heapsnapshot_stream.id());
      {
        JSONObject event(&params, "event");
        event.AddProperty("type", "Event");
        event.AddProperty("kind", "HeapSnapshot");
        event.AddProperty("isolate", thread()->isolate());
        event.AddPropertyTimeMillis("timestamp", OS::GetCurrentTimeMillis());
        event.AddProperty("last", last);
      }
    }
  }

  Service::SendEventWithData(Service::heapsnapshot_stream.id(), "HeapSnapshot",
                             kMetadataReservation, js.buffer()->buf(),
                             js.buffer()->length(), buffer_, size_);
  buffer_ = nullptr;
  size_ = 0;
  capacity_ = 0;
}

void HeapSnapshotWriter::SetupCountingPages() {
  for (intptr_t i = 0; i < kMaxImagePages; i++) {
    image_page_ranges_[i].base = 0;
    image_page_ranges_[i].size = 0;
  }
  intptr_t next_offset = 0;
  HeapPage* image_page = Dart::vm_isolate()->heap()->old_space()->image_pages_;
  while (image_page != NULL) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }
  image_page = isolate()->heap()->old_space()->image_pages_;
  while (image_page != NULL) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }

  HeapPage* page = isolate()->heap()->old_space()->pages_;
  while (page != NULL) {
    page->forwarding_page();
    CountingPage* counting_page =
        reinterpret_cast<CountingPage*>(page->forwarding_page());
    ASSERT(counting_page != NULL);
    counting_page->Clear();
    page = page->next();
  }
}

bool HeapSnapshotWriter::OnImagePage(RawObject* obj) const {
  const uword addr = RawObject::ToAddr(obj);
  for (intptr_t i = 0; i < kMaxImagePages; i++) {
    if ((addr - image_page_ranges_[i].base) < image_page_ranges_[i].size) {
      return true;
    }
  }
  return false;
}

CountingPage* HeapSnapshotWriter::FindCountingPage(RawObject* obj) const {
  if (obj->IsOldObject() && !OnImagePage(obj)) {
    // On a regular or large page.
    HeapPage* page = HeapPage::Of(obj);
    return reinterpret_cast<CountingPage*>(page->forwarding_page());
  }

  // On an image page or in new space.
  return nullptr;
}

void HeapSnapshotWriter::AssignObjectId(RawObject* obj) {
  ASSERT(obj->IsHeapObject());

  CountingPage* counting_page = FindCountingPage(obj);
  if (counting_page != nullptr) {
    // Likely: object on an ordinary page.
    counting_page->Record(RawObject::ToAddr(obj), ++object_count_);
  } else {
    // Unlikely: new space object, or object on a large or image page.
    thread()->heap()->SetObjectId(obj, ++object_count_);
  }
}

intptr_t HeapSnapshotWriter::GetObjectId(RawObject* obj) const {
  if (!obj->IsHeapObject()) {
    return 0;
  }

  if (FLAG_write_protect_code && obj->IsInstructions() && !OnImagePage(obj)) {
    // A non-writable alias mapping may exist for instruction pages.
    obj = HeapPage::ToWritable(obj);
  }

  CountingPage* counting_page = FindCountingPage(obj);
  intptr_t id;
  if (counting_page != nullptr) {
    // Likely: object on an ordinary page.
    id = counting_page->Lookup(RawObject::ToAddr(obj));
  } else {
    // Unlikely: new space object, or object on a large or image page.
    id = thread()->heap()->GetObjectId(obj);
  }
  ASSERT(id != 0);
  return id;
}

void HeapSnapshotWriter::ClearObjectIds() {
  thread()->heap()->ResetObjectIdTable();
}

void HeapSnapshotWriter::CountReferences(intptr_t count) {
  reference_count_ += count;
}

void HeapSnapshotWriter::CountExternalProperty() {
  external_property_count_ += 1;
}

class Pass1Visitor : public ObjectVisitor,
                     public ObjectPointerVisitor,
                     public HandleVisitor {
 public:
  explicit Pass1Visitor(HeapSnapshotWriter* writer)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        HandleVisitor(Thread::Current()),
        writer_(writer) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsPseudoObject()) return;

    writer_->AssignObjectId(obj);
    obj->VisitPointers(this);
  }

  void VisitPointers(RawObject** from, RawObject** to) {
    intptr_t count = to - from + 1;
    ASSERT(count >= 0);
    writer_->CountReferences(count);
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* weak_persistent_handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (!weak_persistent_handle->raw()->IsHeapObject()) {
      return;  // Free handle.
    }

    writer_->CountExternalProperty();
  }

 private:
  HeapSnapshotWriter* const writer_;

  DISALLOW_COPY_AND_ASSIGN(Pass1Visitor);
};

enum NonReferenceDataTags {
  kNoData = 0,
  kNullData,
  kBoolData,
  kIntData,
  kDoubleData,
  kLatin1Data,
  kUTF16Data,
  kLengthData,
  kNameData,
};

static const intptr_t kMaxStringElements = 128;

class Pass2Visitor : public ObjectVisitor,
                     public ObjectPointerVisitor,
                     public HandleVisitor {
 public:
  explicit Pass2Visitor(HeapSnapshotWriter* writer)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        HandleVisitor(Thread::Current()),
        isolate_(thread()->isolate()),
        writer_(writer) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsPseudoObject()) return;

    intptr_t cid = obj->GetClassId();
    writer_->WriteUnsigned(cid);
    writer_->WriteUnsigned(discount_sizes_ ? 0 : obj->HeapSize());

    if (cid == kNullCid) {
      writer_->WriteUnsigned(kNullData);
    } else if (cid == kBoolCid) {
      writer_->WriteUnsigned(kBoolData);
      writer_->WriteUnsigned(
          static_cast<uintptr_t>(static_cast<RawBool*>(obj)->ptr()->value_));
    } else if (cid == kSmiCid) {
      UNREACHABLE();
    } else if (cid == kMintCid) {
      writer_->WriteUnsigned(kIntData);
      writer_->WriteSigned(static_cast<RawMint*>(obj)->ptr()->value_);
    } else if (cid == kDoubleCid) {
      writer_->WriteUnsigned(kDoubleData);
      writer_->WriteBytes(&(static_cast<RawDouble*>(obj)->ptr()->value_),
                          sizeof(double));
    } else if (cid == kOneByteStringCid) {
      RawOneByteString* str = static_cast<RawOneByteString*>(obj);
      intptr_t len = Smi::Value(str->ptr()->length_);
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kLatin1Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->ptr()->data()[0], trunc_len);
    } else if (cid == kExternalOneByteStringCid) {
      RawExternalOneByteString* str =
          static_cast<RawExternalOneByteString*>(obj);
      intptr_t len = Smi::Value(str->ptr()->length_);
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kLatin1Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->ptr()->external_data_[0], trunc_len);
    } else if (cid == kTwoByteStringCid) {
      RawTwoByteString* str = static_cast<RawTwoByteString*>(obj);
      intptr_t len = Smi::Value(str->ptr()->length_);
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kUTF16Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->ptr()->data()[0], trunc_len * 2);
    } else if (cid == kExternalTwoByteStringCid) {
      RawExternalTwoByteString* str =
          static_cast<RawExternalTwoByteString*>(obj);
      intptr_t len = Smi::Value(str->ptr()->length_);
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kUTF16Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->ptr()->external_data_[0], trunc_len * 2);
    } else if (cid == kArrayCid || cid == kImmutableArrayCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<RawArray*>(obj)->ptr()->length_));
    } else if (cid == kGrowableObjectArrayCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(Smi::Value(
          static_cast<RawGrowableObjectArray*>(obj)->ptr()->length_));
    } else if (cid == kLinkedHashMapCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<RawLinkedHashMap*>(obj)->ptr()->used_data_));
    } else if (cid == kObjectPoolCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(static_cast<RawObjectPool*>(obj)->ptr()->length_);
    } else if (RawObject::IsTypedDataClassId(cid)) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<RawTypedData*>(obj)->ptr()->length_));
    } else if (RawObject::IsExternalTypedDataClassId(cid)) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<RawExternalTypedData*>(obj)->ptr()->length_));
    } else if (cid == kFunctionCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<RawFunction*>(obj)->ptr()->name_);
    } else if (cid == kCodeCid) {
      RawObject* owner = static_cast<RawCode*>(obj)->ptr()->owner_;
      if (owner->IsFunction()) {
        writer_->WriteUnsigned(kNameData);
        ScrubAndWriteUtf8(static_cast<RawFunction*>(owner)->ptr()->name_);
      } else if (owner->IsClass()) {
        writer_->WriteUnsigned(kNameData);
        ScrubAndWriteUtf8(static_cast<RawClass*>(owner)->ptr()->name_);
      } else {
        writer_->WriteUnsigned(kNoData);
      }
    } else if (cid == kFieldCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<RawField*>(obj)->ptr()->name_);
    } else if (cid == kClassCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<RawClass*>(obj)->ptr()->name_);
    } else if (cid == kLibraryCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<RawLibrary*>(obj)->ptr()->url_);
    } else if (cid == kScriptCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<RawScript*>(obj)->ptr()->url_);
    } else {
      writer_->WriteUnsigned(kNoData);
    }

    DoCount();
    obj->VisitPointersPrecise(isolate_, this);
    DoWrite();
    obj->VisitPointersPrecise(isolate_, this);
  }

  void ScrubAndWriteUtf8(RawString* str) {
    if (str == String::null()) {
      writer_->WriteUtf8("null");
    } else {
      String handle;
      handle = str;
      char* value = handle.ToMallocCString();
      writer_->ScrubAndWriteUtf8(value);
      free(value);
    }
  }

  void set_discount_sizes(bool value) { discount_sizes_ = value; }

  void DoCount() {
    writing_ = false;
    counted_ = 0;
    written_ = 0;
  }
  void DoWrite() {
    writing_ = true;
    writer_->WriteUnsigned(counted_);
  }

  void VisitPointers(RawObject** from, RawObject** to) {
    if (writing_) {
      for (RawObject** ptr = from; ptr <= to; ptr++) {
        RawObject* target = *ptr;
        written_++;
        total_++;
        writer_->WriteUnsigned(writer_->GetObjectId(target));
      }
    } else {
      intptr_t count = to - from + 1;
      ASSERT(count >= 0);
      counted_ += count;
    }
  }

  void VisitHandle(uword addr) {
    FinalizablePersistentHandle* weak_persistent_handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (!weak_persistent_handle->raw()->IsHeapObject()) {
      return;  // Free handle.
    }

    writer_->WriteUnsigned(writer_->GetObjectId(weak_persistent_handle->raw()));
    writer_->WriteUnsigned(weak_persistent_handle->external_size());
    // Attempt to include a native symbol name.
    auto const name = NativeSymbolResolver::LookupSymbolName(
        reinterpret_cast<uword>(weak_persistent_handle->callback()), nullptr);
    writer_->WriteUtf8((name == nullptr) ? "Unknown native function" : name);
    if (name != nullptr) {
      NativeSymbolResolver::FreeSymbolName(name);
    }
  }

 private:
  // TODO(dartbug.com/36097): Once the shared class table contains more
  // information than just the size (i.e. includes an immutable class
  // descriptor), we can remove this dependency on the current isolate.
  Isolate* isolate_;
  HeapSnapshotWriter* const writer_;
  bool writing_ = false;
  intptr_t counted_ = 0;
  intptr_t written_ = 0;
  intptr_t total_ = 0;
  bool discount_sizes_ = false;

  DISALLOW_COPY_AND_ASSIGN(Pass2Visitor);
};

void HeapSnapshotWriter::Write() {
  HeapIterationScope iteration(thread());

  WriteBytes("dartheap", 8);  // Magic value.
  WriteUnsigned(0);           // Flags.
  WriteUtf8(isolate()->name());
  Heap* H = thread()->heap();

  {
    intptr_t used = H->TotalUsedInWords() << kWordSizeLog2;
    intptr_t capacity = H->TotalCapacityInWords() << kWordSizeLog2;
    intptr_t external = H->TotalExternalInWords() << kWordSizeLog2;
    intptr_t image = H->old_space()->ImageInWords() << kWordSizeLog2;
    WriteUnsigned(used + image);
    WriteUnsigned(capacity + image);
    WriteUnsigned(external);
  }

  {
    HANDLESCOPE(thread());
    ClassTable* class_table = isolate()->class_table();
    class_count_ = class_table->NumCids() - 1;

    Class& cls = Class::Handle();
    Library& lib = Library::Handle();
    String& str = String::Handle();
    Array& fields = Array::Handle();
    Field& field = Field::Handle();

    WriteUnsigned(class_count_);
    for (intptr_t cid = 1; cid <= class_count_; cid++) {
      if (!class_table->HasValidClassAt(cid)) {
        WriteUnsigned(0);  // Flags
        WriteUtf8("");     // Name
        WriteUtf8("");     // Library name
        WriteUtf8("");     // Library uri
        WriteUtf8("");     // Reserved
        WriteUnsigned(0);  // Field count
      } else {
        cls = class_table->At(cid);
        WriteUnsigned(0);  // Flags
        str = cls.Name();
        ScrubAndWriteUtf8(const_cast<char*>(str.ToCString()));
        lib = cls.library();
        if (lib.IsNull()) {
          WriteUtf8("");
          WriteUtf8("");
        } else {
          str = lib.name();
          ScrubAndWriteUtf8(const_cast<char*>(str.ToCString()));
          str = lib.url();
          ScrubAndWriteUtf8(const_cast<char*>(str.ToCString()));
        }
        WriteUtf8("");  // Reserved

        intptr_t field_count = 0;
        intptr_t min_offset = kIntptrMax;
        for (intptr_t j = 0; OffsetsTable::offsets_table[j].class_id != -1;
             j++) {
          if (OffsetsTable::offsets_table[j].class_id == cid) {
            field_count++;
            intptr_t offset = OffsetsTable::offsets_table[j].offset;
            min_offset = Utils::Minimum(min_offset, offset);
          }
        }
        if (cls.is_finalized()) {
          do {
            fields = cls.fields();
            if (!fields.IsNull()) {
              for (intptr_t i = 0; i < fields.Length(); i++) {
                field ^= fields.At(i);
                if (field.is_instance()) {
                  field_count++;
                }
              }
            }
            cls = cls.SuperClass();
          } while (!cls.IsNull());
          cls = class_table->At(cid);
        }

        WriteUnsigned(field_count);
        for (intptr_t j = 0; OffsetsTable::offsets_table[j].class_id != -1;
             j++) {
          if (OffsetsTable::offsets_table[j].class_id == cid) {
            intptr_t flags = 1;  // Strong.
            WriteUnsigned(flags);
            intptr_t offset = OffsetsTable::offsets_table[j].offset;
            intptr_t index = (offset - min_offset) / kWordSize;
            ASSERT(index >= 0);
            WriteUnsigned(index);
            WriteUtf8(OffsetsTable::offsets_table[j].field_name);
            WriteUtf8("");  // Reserved
          }
        }
        if (cls.is_finalized()) {
          do {
            fields = cls.fields();
            if (!fields.IsNull()) {
              for (intptr_t i = 0; i < fields.Length(); i++) {
                field ^= fields.At(i);
                if (field.is_instance()) {
                  intptr_t flags = 1;  // Strong.
                  WriteUnsigned(flags);
                  intptr_t index = field.HostOffset() / kWordSize - 1;
                  ASSERT(index >= 0);
                  WriteUnsigned(index);
                  str = field.name();
                  ScrubAndWriteUtf8(const_cast<char*>(str.ToCString()));
                  WriteUtf8("");  // Reserved
                }
              }
            }
            cls = cls.SuperClass();
          } while (!cls.IsNull());
          cls = class_table->At(cid);
        }
      }
    }
  }

  SetupCountingPages();

  {
    Pass1Visitor visitor(this);

    // Root "object".
    ++object_count_;
    isolate()->VisitObjectPointers(&visitor,
                                   ValidationPolicy::kDontValidateFrames);

    // Heap objects.
    iteration.IterateVMIsolateObjects(&visitor);
    iteration.IterateObjects(&visitor);

    // External properties.
    isolate()->group()->VisitWeakPersistentHandles(&visitor);
  }

  {
    Pass2Visitor visitor(this);

    WriteUnsigned(reference_count_);
    WriteUnsigned(object_count_);

    // Root "object".
    WriteUnsigned(0);  // cid
    WriteUnsigned(0);  // shallowSize
    WriteUnsigned(kNoData);
    visitor.DoCount();
    isolate()->VisitObjectPointers(&visitor,
                                   ValidationPolicy::kDontValidateFrames);
    visitor.DoWrite();
    isolate()->VisitObjectPointers(&visitor,
                                   ValidationPolicy::kDontValidateFrames);

    // Heap objects.
    visitor.set_discount_sizes(true);
    iteration.IterateVMIsolateObjects(&visitor);
    visitor.set_discount_sizes(false);
    iteration.IterateObjects(&visitor);

    // External properties.
    WriteUnsigned(external_property_count_);
    isolate()->group()->VisitWeakPersistentHandles(&visitor);
  }

  {
    WriteUtf8("RSS");
    WriteUnsigned(Service::CurrentRSS());

    WriteUtf8("Dart Profiler Samples");
    WriteUnsigned(Profiler::Size());

    WriteUtf8("Dart Timeline Events");
    WriteUnsigned(Timeline::recorder()->Size());

    class WriteIsolateHeaps : public IsolateVisitor {
     public:
      explicit WriteIsolateHeaps(HeapSnapshotWriter* writer)
          : writer_(writer) {}

      virtual void VisitIsolate(Isolate* isolate) {
        writer_->WriteUtf8(isolate->name());
        writer_->WriteUnsigned((isolate->heap()->TotalCapacityInWords() +
                                isolate->heap()->TotalExternalInWords()) *
                               kWordSize);
      }

     private:
      HeapSnapshotWriter* const writer_;
    };
    WriteIsolateHeaps visitor(this);
    Isolate::VisitIsolates(&visitor);
  }

  ClearObjectIds();
  Flush(true);
}

CountObjectsVisitor::CountObjectsVisitor(Thread* thread, intptr_t class_count)
    : ObjectVisitor(),
      HandleVisitor(thread),
      new_count_(new intptr_t[class_count]),
      new_size_(new intptr_t[class_count]),
      new_external_size_(new intptr_t[class_count]),
      old_count_(new intptr_t[class_count]),
      old_size_(new intptr_t[class_count]),
      old_external_size_(new intptr_t[class_count]) {
  memset(new_count_.get(), 0, class_count * sizeof(intptr_t));
  memset(new_size_.get(), 0, class_count * sizeof(intptr_t));
  memset(new_external_size_.get(), 0, class_count * sizeof(intptr_t));
  memset(old_count_.get(), 0, class_count * sizeof(intptr_t));
  memset(old_size_.get(), 0, class_count * sizeof(intptr_t));
  memset(old_external_size_.get(), 0, class_count * sizeof(intptr_t));
}

void CountObjectsVisitor::VisitObject(RawObject* obj) {
  intptr_t cid = obj->GetClassId();
  intptr_t size = obj->HeapSize();
  if (obj->IsNewObject()) {
    new_count_[cid] += 1;
    new_size_[cid] += size;
  } else {
    old_count_[cid] += 1;
    old_size_[cid] += size;
  }
}

void CountObjectsVisitor::VisitHandle(uword addr) {
  FinalizablePersistentHandle* handle =
      reinterpret_cast<FinalizablePersistentHandle*>(addr);
  RawObject* obj = handle->raw();
  if (!obj->IsHeapObject()) {
    return;
  }
  intptr_t cid = obj->GetClassId();
  intptr_t size = handle->external_size();
  if (obj->IsNewObject()) {
    new_external_size_[cid] += size;
  } else {
    old_external_size_[cid] += size;
  }
}

#endif  // !defined(PRODUCT)

}  // namespace dart
