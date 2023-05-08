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

#if defined(DART_ENABLE_HEAP_SNAPSHOT_WRITER)

static bool IsUserClass(intptr_t cid) {
  if (cid == kContextCid) return true;
  if (cid == kTypeArgumentsCid) return false;
  return !IsInternalOnlyClassId(cid);
}

// A slot in the fixed-size portion of a heap object.
//
// This may be a regulard dart field, a unboxed dart field or
// a slot of any type in a predefined layout.
struct ObjectSlot {
  uint16_t offset;
  bool is_compressed_pointer;
  const char* name;
  ObjectSlot(uint16_t offset, bool is_compressed_pointer, const char* name)
      : offset(offset),
        is_compressed_pointer(is_compressed_pointer),
        name(name) {}
};

class ObjectSlots {
 public:
  using ObjectSlotsType = ZoneGrowableArray<ObjectSlot>;

  explicit ObjectSlots(Thread* thread) {
    auto class_table = thread->isolate_group()->class_table();
    const intptr_t class_count = class_table->NumCids();

    HANDLESCOPE(thread);
    auto& cls = Class::Handle(thread->zone());
    auto& fields = Array::Handle(thread->zone());
    auto& field = Field::Handle(thread->zone());
    auto& name = String::Handle(thread->zone());

    cid2object_slots_.FillWith(nullptr, 0, class_count);
    contains_only_tagged_words_.FillWith(false, 0, class_count);

    for (intptr_t cid = 1; cid < class_count; cid++) {
      if (!class_table->HasValidClassAt(cid)) continue;

      // Non-finalized classes are abstract, so we will not collect any field
      // information for them.
      cls = class_table->At(cid);
      if (!cls.is_finalized()) continue;

      auto slots = cid2object_slots_[cid] = new ObjectSlotsType();
      for (const auto& entry : OffsetsTable::offsets_table()) {
        if (entry.class_id == cid) {
          slots->Add(ObjectSlot(entry.offset, entry.is_compressed_pointer,
                                entry.field_name));
        }
      }

      // The VM doesn't define a layout for the object, so it's a regular Dart
      // class.
      if (slots->is_empty()) {
        // If the class has native fields, the native fields array is the first
        // field and therefore starts after the `kWordSize` tagging word.
        if (cls.num_native_fields() > 0) {
          slots->Add(ObjectSlot(kWordSize, true, "native_fields"));
        }
        // If the class or any super class is generic, it will have a type
        // arguments vector.
        const auto tav_offset = cls.host_type_arguments_field_offset();
        if (tav_offset != Class::kNoTypeArguments) {
          slots->Add(ObjectSlot(tav_offset, true, "type_arguments"));
        }

        // Add slots for all user-defined instance fields in the hierarchy.
        while (!cls.IsNull()) {
          fields = cls.fields();
          if (!fields.IsNull()) {
            for (intptr_t i = 0; i < fields.Length(); ++i) {
              field ^= fields.At(i);
              if (!field.is_instance()) continue;
              name = field.name();
              // If the field is unboxed, we don't know the size of it (may be
              // multiple words) - but that doesn't matter because
              //   a) we will process instances using the slots we collect
              //     (instead of regular GC visitor);
              //   b) we will not write the value of the field and instead treat
              //     it like a dummy reference to 0 (like we do with Smis).
              slots->Add(ObjectSlot(field.HostOffset(), !field.is_unboxed(),
                                    name.ToCString()));
            }
          }
          cls = cls.SuperClass();
        }
      }

      // We sort the slots, so we'll visit the slots in memory order.
      slots->Sort([](const ObjectSlot* a, const ObjectSlot* b) {
        return a->offset - b->offset;
      });

      // As optimization as well as to support variable-length data, we remember
      // whether this class has only pure tagged pointers in it, then we can
      // safely use regular GC visitors.
      bool contains_only_tagged_words = true;
      for (auto& slot : *slots) {
        if (!slot.is_compressed_pointer) {
          contains_only_tagged_words = false;
          break;
        }
      }
#if defined(DEBUG)
      // For pure pointer objects, the slots have to start after tagging word
      // and be without holes (otherwise, e.g. if a slot was not declared,
      // the visitors will visit them but we won't emit the field description in
      // the heap snapshot).
      if (contains_only_tagged_words) {
        intptr_t expected_offset = kWordSize;
        for (auto& slot : *slots) {
          RELEASE_ASSERT(slot.offset = expected_offset);
          expected_offset += kCompressedWordSize;
        }
      }
      ASSERT(contains_only_tagged_words ||
             (cid != kArrayCid && cid != kImmutableArrayCid));
#endif  // defined(DEBUG)

      contains_only_tagged_words_[cid] = contains_only_tagged_words;
    }
  }

  const ObjectSlotsType* ObjectSlotsFor(intptr_t cid) const {
    return cid2object_slots_[cid];
  }

  // Returns `true` if all fields are tagged (i.e. no unboxed fields).
  bool ContainsOnlyTaggedPointers(intptr_t cid) {
    return contains_only_tagged_words_[cid];
  }

 private:
  GrowableArray<ObjectSlotsType*> cid2object_slots_;
  GrowableArray<bool> contains_only_tagged_words_;
};

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

  bool trace_values_through_fields() const override { return true; }

  // Marks and pushes. Used to initialize this stack with roots.
  // We can use ObjectIdTable normally used by serializers because it
  // won't be in use while handling a service request (ObjectGraph's only use).
  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (ObjectPtr* current = first; current <= last; ++current) {
      Visit(current, *current);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    for (CompressedObjectPtr* current = first; current <= last; ++current) {
      Visit(current, current->Decompress(heap_base));
    }
  }
#endif

  void Visit(void* ptr, ObjectPtr obj) {
    if (obj->IsHeapObject() && !obj->untag()->InVMIsolateHeap() &&
        object_ids_->GetValueExclusive(obj) == 0) {  // not visited yet
      if (!include_vm_objects_ && !IsUserClass(obj->GetClassId())) {
        return;
      }
      object_ids_->SetValueExclusive(obj, 1);
      Node node;
      node.ptr = ptr;
      node.obj = obj;
      node.gc_root_type = gc_root_type();
      data_.Add(node);
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
      ObjectPtr obj = node.obj;
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
        obj->untag()->VisitPointers(this);
        clear_gc_root_type();
      }
    }
  }

  bool visit_weak_persistent_handles() const override {
    return visit_weak_persistent_handles_;
  }

  void set_visit_weak_persistent_handles(bool value) {
    visit_weak_persistent_handles_ = value;
  }

  bool include_vm_objects_;

 private:
  struct Node {
    void* ptr;  // kSentinel for the sentinel node.
    ObjectPtr obj;
    const char* gc_root_type;
  };

  bool visit_weak_persistent_handles_ = false;
  static ObjectPtr* const kSentinel;
  static constexpr intptr_t kInitialCapacity = 1024;
  static constexpr intptr_t kNoParent = -1;

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

ObjectPtr* const ObjectGraph::Stack::kSentinel = nullptr;

ObjectPtr ObjectGraph::StackIterator::Get() const {
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

intptr_t ObjectGraph::StackIterator::OffsetFromParent() const {
  intptr_t parent_index = stack_->Parent(index_);
  if (parent_index == Stack::kNoParent) {
    return -1;
  }
  Stack::Node parent = stack_->data_[parent_index];
  uword parent_start = UntaggedObject::ToAddr(parent.obj);
  Stack::Node child = stack_->data_[index_];
  uword child_ptr_addr = reinterpret_cast<uword>(child.ptr);
  intptr_t offset = child_ptr_addr - parent_start;
  if (offset > 0 && offset < parent.obj->untag()->HeapSize()) {
    return offset;
  } else {
    // Some internal VM objects visit pointers not contained within the parent.
    // For instance, UntaggedCode::VisitCodePointers visits pointers in
    // instructions.
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
      zone, thread->isolate_group()->object_store()->libraries());
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
        cls ^= entry.ptr();
        fields = cls.fields();
        for (intptr_t j = 0; j < fields.Length(); j++) {
          field ^= fields.At(j);
          ObjectPtr ptr = field.ptr();
          visitor->VisitPointer(&ptr);
        }
      } else if (entry.IsField()) {
        field ^= entry.ptr();
        ObjectPtr ptr = field.ptr();
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
  ObjectPtr root_raw = root.ptr();
  stack.VisitPointer(&root_raw);
  stack.TraverseGraph(visitor);
}

class InstanceAccumulator : public ObjectVisitor {
 public:
  InstanceAccumulator(ObjectGraph::Stack* stack, intptr_t class_id)
      : stack_(stack), class_id_(class_id) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->GetClassId() == class_id_) {
      ObjectPtr rawobj = obj;
      stack_->VisitPointer(&rawobj);
    }
  }

 private:
  ObjectGraph::Stack* stack_;
  const intptr_t class_id_;

  DISALLOW_COPY_AND_ASSIGN(InstanceAccumulator);
};

void ObjectGraph::IterateObjectsFrom(intptr_t class_id,
                                     HeapIterationScope* iteration,
                                     ObjectGraph::Visitor* visitor) {
  Stack stack(isolate_group());

  InstanceAccumulator accumulator(&stack, class_id);
  iteration->IterateObjectsNoImagePages(&accumulator);

  stack.TraverseGraph(visitor);
}

class SizeVisitor : public ObjectGraph::Visitor {
 public:
  SizeVisitor() : size_(0) {}
  intptr_t size() const { return size_; }
  virtual bool ShouldSkip(ObjectPtr obj) const { return false; }
  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    ObjectPtr obj = it->Get();
    if (ShouldSkip(obj)) {
      return kBacktrack;
    }
    size_ += obj->untag()->HeapSize();
    return kProceed;
  }

 private:
  intptr_t size_;
};

class SizeExcludingObjectVisitor : public SizeVisitor {
 public:
  explicit SizeExcludingObjectVisitor(const Object& skip) : skip_(skip) {}
  virtual bool ShouldSkip(ObjectPtr obj) const { return obj == skip_.ptr(); }

 private:
  const Object& skip_;
};

class SizeExcludingClassVisitor : public SizeVisitor {
 public:
  explicit SizeExcludingClassVisitor(intptr_t skip) : skip_(skip) {}
  virtual bool ShouldSkip(ObjectPtr obj) const {
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
  IterateObjectsFrom(class_id, &iteration_scope, &total);
  return total.size();
}

class RetainingPathVisitor : public ObjectGraph::Visitor {
 public:
  // We cannot use a GrowableObjectArray, since we must not trigger GC.
  RetainingPathVisitor(ObjectPtr obj, const Array& path)
      : thread_(Thread::Current()), obj_(obj), path_(path), length_(0) {}

  intptr_t length() const { return length_; }
  virtual bool visit_weak_persistent_handles() const { return true; }

  bool ShouldSkip(ObjectPtr obj) {
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

  bool ShouldStop(ObjectPtr obj) {
    // A static field is considered a root from a language point of view.
    if (obj->IsField()) {
      const Field& field = Field::Handle(static_cast<FieldPtr>(obj));
      return field.is_static();
    }
    return false;
  }

  void StartList() { was_last_array_ = false; }

  intptr_t HideNDescendant(ObjectPtr obj) {
    // A GrowableObjectArray overwrites its internal storage.
    // Keeping both of them in the list is redundant.
    if (was_last_array_ && obj->IsGrowableObjectArray()) {
      was_last_array_ = false;
      return 1;
    }
    // A LinkedHasMap overwrites its internal storage.
    // Keeping both of them in the list is redundant.
    if (was_last_array_ && obj->IsMap()) {
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
          offset_from_parent = Smi::New(it->OffsetFromParent());
          path_.SetAt(offset_index, offset_from_parent);
        }
        ++length_;
      } while (!ShouldStop(it->Get()) && it->MoveToParent());
      return kAbort;
    }
  }

 private:
  Thread* thread_;
  ObjectPtr obj_;
  const Array& path_;
  intptr_t length_;
  bool was_last_array_;
};

ObjectGraph::RetainingPathResult ObjectGraph::RetainingPath(Object* obj,
                                                            const Array& path) {
  HeapIterationScope iteration_scope(Thread::Current(), true);
  // To break the trivial path, the handle 'obj' is temporarily cleared during
  // the search, but restored before returning.
  ObjectPtr raw = obj->ptr();
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
                           ObjectPtr target,
                           const Array& references,
                           Object* scratch)
      : ObjectPointerVisitor(isolate->group()),
        source_(nullptr),
        target_(target),
        references_(references),
        scratch_(scratch),
        length_(0) {
    ASSERT(Thread::Current()->no_safepoint_scope_depth() != 0);
  }

  bool trace_values_through_fields() const override { return true; }

  intptr_t length() const { return length_; }

  void VisitObject(ObjectPtr raw_obj) override {
    source_ = raw_obj;
    raw_obj->untag()->VisitPointers(this);
  }

  void VisitPointers(ObjectPtr* first, ObjectPtr* last) override {
    for (ObjectPtr* current_ptr = first; current_ptr <= last; current_ptr++) {
      ObjectPtr current_obj = *current_ptr;
      if (current_obj == target_) {
        intptr_t obj_index = length_ * 2;
        intptr_t offset_index = obj_index + 1;
        if (!references_.IsNull() && offset_index < references_.Length()) {
          *scratch_ = source_;
          references_.SetAt(obj_index, *scratch_);

          *scratch_ = Smi::New(0);
          uword source_start = UntaggedObject::ToAddr(source_);
          uword current_ptr_addr = reinterpret_cast<uword>(current_ptr);
          intptr_t offset = current_ptr_addr - source_start;
          if (offset > 0 && offset < source_->untag()->HeapSize()) {
            *scratch_ = Smi::New(offset);
          } else {
            // Some internal VM objects visit pointers not contained within the
            // parent. For instance, UntaggedCode::VisitCodePointers visits
            // pointers in instructions.
            ASSERT(!source_->IsDartInstance());
            *scratch_ = Smi::New(-1);
          }
          references_.SetAt(offset_index, *scratch_);
        }
        ++length_;
      }
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* first,
                               CompressedObjectPtr* last) override {
    for (CompressedObjectPtr* current_ptr = first; current_ptr <= last;
         current_ptr++) {
      ObjectPtr current_obj = current_ptr->Decompress(heap_base);
      if (current_obj == target_) {
        intptr_t obj_index = length_ * 2;
        intptr_t offset_index = obj_index + 1;
        if (!references_.IsNull() && offset_index < references_.Length()) {
          *scratch_ = source_;
          references_.SetAt(obj_index, *scratch_);

          *scratch_ = Smi::New(0);
          uword source_start = UntaggedObject::ToAddr(source_);
          uword current_ptr_addr = reinterpret_cast<uword>(current_ptr);
          intptr_t offset = current_ptr_addr - source_start;
          if (offset > 0 && offset < source_->untag()->HeapSize()) {
            *scratch_ = Smi::New(offset);
          } else {
            // Some internal VM objects visit pointers not contained within the
            // parent. For instance, UntaggedCode::VisitCodePointers visits
            // pointers in instructions.
            ASSERT(!source_->IsDartInstance());
            *scratch_ = Smi::New(-1);
          }
          references_.SetAt(offset_index, *scratch_);
        }
        ++length_;
      }
    }
  }
#endif

 private:
  ObjectPtr source_;
  ObjectPtr target_;
  const Array& references_;
  Object* scratch_;
  intptr_t length_;
};

intptr_t ObjectGraph::InboundReferences(Object* obj, const Array& references) {
  Object& scratch = Object::Handle();
  HeapIterationScope iteration(Thread::Current());
  NoSafepointScope no_safepoint;
  InboundReferencesVisitor visitor(isolate(), obj->ptr(), references, &scratch);
  iteration.IterateObjects(&visitor);
  return visitor.length();
}

// Each Page is divided into blocks of size kBlockSize. Each object belongs
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
  const intptr_t reserved_prefix = writer_->ReserveChunkPrefixSize();
  if (chunk_size < (reserved_prefix + needed)) {
    chunk_size = reserved_prefix + needed;
  }
  buffer_ = reinterpret_cast<uint8_t*>(malloc(chunk_size));
  size_ = reserved_prefix;
  capacity_ = chunk_size;
}

void HeapSnapshotWriter::Flush(bool last) {
  if (size_ == 0 && !last) {
    return;
  }

  writer_->WriteChunk(buffer_, size_, last);

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
  Page* image_page =
      Dart::vm_isolate_group()->heap()->old_space()->image_pages_;
  while (image_page != nullptr) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }
  image_page = isolate_group()->heap()->old_space()->image_pages_;
  while (image_page != nullptr) {
    RELEASE_ASSERT(next_offset <= kMaxImagePages);
    image_page_ranges_[next_offset].base = image_page->object_start();
    image_page_ranges_[next_offset].size =
        image_page->object_end() - image_page->object_start();
    image_page = image_page->next();
    next_offset++;
  }

  Page* page = isolate_group()->heap()->old_space()->pages_;
  while (page != nullptr) {
    page->forwarding_page();
    CountingPage* counting_page =
        reinterpret_cast<CountingPage*>(page->forwarding_page());
    ASSERT(counting_page != nullptr);
    counting_page->Clear();
    page = page->next();
  }
}

bool HeapSnapshotWriter::OnImagePage(ObjectPtr obj) const {
  const uword addr = UntaggedObject::ToAddr(obj);
  for (intptr_t i = 0; i < kMaxImagePages; i++) {
    if ((addr - image_page_ranges_[i].base) < image_page_ranges_[i].size) {
      return true;
    }
  }
  return false;
}

CountingPage* HeapSnapshotWriter::FindCountingPage(ObjectPtr obj) const {
  if (obj->IsOldObject() && !OnImagePage(obj)) {
    // On a regular or large page.
    Page* page = Page::Of(obj);
    return reinterpret_cast<CountingPage*>(page->forwarding_page());
  }

  // On an image page or in new space.
  return nullptr;
}

void HeapSnapshotWriter::AssignObjectId(ObjectPtr obj) {
  if (!obj->IsHeapObject()) {
    thread()->heap()->SetObjectId(obj, ++object_count_);
    return;
  }

  CountingPage* counting_page = FindCountingPage(obj);
  if (counting_page != nullptr) {
    // Likely: object on an ordinary page.
    counting_page->Record(UntaggedObject::ToAddr(obj), ++object_count_);
  } else {
    // Unlikely: new space object, or object on a large or image page.
    thread()->heap()->SetObjectId(obj, ++object_count_);
  }
}

intptr_t HeapSnapshotWriter::GetObjectId(ObjectPtr obj) const {
  if (!obj->IsHeapObject()) {
    intptr_t id = thread()->heap()->GetObjectId(obj);
    ASSERT(id != 0);
    return id;
  }

  if (FLAG_write_protect_code && obj->IsInstructions() && !OnImagePage(obj)) {
    // A non-writable alias mapping may exist for instruction pages.
    obj = Page::ToWritable(obj);
  }

  CountingPage* counting_page = FindCountingPage(obj);
  intptr_t id;
  if (counting_page != nullptr) {
    // Likely: object on an ordinary page.
    id = counting_page->Lookup(UntaggedObject::ToAddr(obj));
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

void HeapSnapshotWriter::AddSmi(SmiPtr smi) {
  if (thread()->heap()->GetObjectId(smi) == WeakTable::kNoValue) {
    thread()->heap()->SetObjectId(smi, -1);
    smis_.Add(smi);
  }
}

class Pass1Visitor : public ObjectVisitor,
                     public ObjectPointerVisitor,
                     public HandleVisitor {
 public:
  explicit Pass1Visitor(HeapSnapshotWriter* writer, ObjectSlots* object_slots)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        HandleVisitor(Thread::Current()),
        writer_(writer),
        object_slots_(object_slots) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) return;

    writer_->AssignObjectId(obj);
    const auto cid = obj->GetClassId();

    if (object_slots_->ContainsOnlyTaggedPointers(cid)) {
      obj->untag()->VisitPointersPrecise(this);
    } else {
      for (auto& slot : *object_slots_->ObjectSlotsFor(cid)) {
        if (slot.is_compressed_pointer) {
          auto target = reinterpret_cast<CompressedObjectPtr*>(
              UntaggedObject::ToAddr(obj->untag()) + slot.offset);
          VisitCompressedPointers(obj->heap_base(), target, target);
        } else {
          writer_->CountReferences(1);
        }
      }
    }
  }

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = *ptr;
      if (!obj->IsHeapObject()) {
        writer_->AddSmi(static_cast<SmiPtr>(obj));
      }
      writer_->CountReferences(1);
    }
  }

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
      ObjectPtr obj = ptr->Decompress(heap_base);
      if (!obj->IsHeapObject()) {
        writer_->AddSmi(static_cast<SmiPtr>(obj));
      }
      writer_->CountReferences(1);
    }
  }
#endif

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* weak_persistent_handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (!weak_persistent_handle->ptr()->IsHeapObject()) {
      return;  // Free handle.
    }

    writer_->CountExternalProperty();
  }

 private:
  HeapSnapshotWriter* const writer_;
  ObjectSlots* object_slots_;

  DISALLOW_COPY_AND_ASSIGN(Pass1Visitor);
};

class CountImagePageRefs : public ObjectVisitor {
 public:
  CountImagePageRefs() : ObjectVisitor() {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) return;
    count_++;
  }
  intptr_t count() const { return count_; }

 private:
  intptr_t count_ = 0;

  DISALLOW_COPY_AND_ASSIGN(CountImagePageRefs);
};

class WriteImagePageRefs : public ObjectVisitor {
 public:
  explicit WriteImagePageRefs(HeapSnapshotWriter* writer)
      : ObjectVisitor(), writer_(writer) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) return;
#if defined(DEBUG)
    count_++;
#endif
    writer_->WriteUnsigned(writer_->GetObjectId(obj));
  }
#if defined(DEBUG)
  intptr_t count() const { return count_; }
#endif

 private:
  HeapSnapshotWriter* const writer_;
#if defined(DEBUG)
  intptr_t count_ = 0;
#endif

  DISALLOW_COPY_AND_ASSIGN(WriteImagePageRefs);
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

static constexpr intptr_t kMaxStringElements = 128;

enum ExtraCids {
  kRootExtraCid = 1,  // 1-origin
  kImagePageExtraCid = 2,
  kIsolateExtraCid = 3,

  kNumExtraCids = 3,
};

class Pass2Visitor : public ObjectVisitor,
                     public ObjectPointerVisitor,
                     public HandleVisitor {
 public:
  explicit Pass2Visitor(HeapSnapshotWriter* writer, ObjectSlots* object_slots)
      : ObjectVisitor(),
        ObjectPointerVisitor(IsolateGroup::Current()),
        HandleVisitor(Thread::Current()),
        writer_(writer),
        object_slots_(object_slots) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) return;

    intptr_t cid = obj->GetClassId();
    writer_->WriteUnsigned(cid + kNumExtraCids);
    writer_->WriteUnsigned(discount_sizes_ ? 0 : obj->untag()->HeapSize());

    if (cid == kNullCid) {
      writer_->WriteUnsigned(kNullData);
    } else if (cid == kBoolCid) {
      writer_->WriteUnsigned(kBoolData);
      writer_->WriteUnsigned(
          static_cast<uintptr_t>(static_cast<BoolPtr>(obj)->untag()->value_));
    } else if (cid == kSentinelCid) {
      if (obj == Object::sentinel().ptr()) {
        writer_->WriteUnsigned(kNameData);
        writer_->WriteUtf8("uninitialized");
      } else if (obj == Object::transition_sentinel().ptr()) {
        writer_->WriteUnsigned(kNameData);
        writer_->WriteUtf8("initializing");
      } else {
        writer_->WriteUnsigned(kNoData);
      }
    } else if (cid == kSmiCid) {
      UNREACHABLE();
    } else if (cid == kMintCid) {
      writer_->WriteUnsigned(kIntData);
      writer_->WriteSigned(static_cast<MintPtr>(obj)->untag()->value_);
    } else if (cid == kDoubleCid) {
      writer_->WriteUnsigned(kDoubleData);
      writer_->WriteBytes(&(static_cast<DoublePtr>(obj)->untag()->value_),
                          sizeof(double));
    } else if (cid == kOneByteStringCid) {
      OneByteStringPtr str = static_cast<OneByteStringPtr>(obj);
      intptr_t len = Smi::Value(str->untag()->length());
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kLatin1Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->untag()->data()[0], trunc_len);
    } else if (cid == kExternalOneByteStringCid) {
      ExternalOneByteStringPtr str = static_cast<ExternalOneByteStringPtr>(obj);
      intptr_t len = Smi::Value(str->untag()->length());
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kLatin1Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->untag()->external_data_[0], trunc_len);
    } else if (cid == kTwoByteStringCid) {
      TwoByteStringPtr str = static_cast<TwoByteStringPtr>(obj);
      intptr_t len = Smi::Value(str->untag()->length());
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kUTF16Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->untag()->data()[0], trunc_len * 2);
    } else if (cid == kExternalTwoByteStringCid) {
      ExternalTwoByteStringPtr str = static_cast<ExternalTwoByteStringPtr>(obj);
      intptr_t len = Smi::Value(str->untag()->length());
      intptr_t trunc_len = Utils::Minimum(len, kMaxStringElements);
      writer_->WriteUnsigned(kUTF16Data);
      writer_->WriteUnsigned(len);
      writer_->WriteUnsigned(trunc_len);
      writer_->WriteBytes(&str->untag()->external_data_[0], trunc_len * 2);
    } else if (cid == kArrayCid || cid == kImmutableArrayCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<ArrayPtr>(obj)->untag()->length()));
    } else if (cid == kGrowableObjectArrayCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(Smi::Value(
          static_cast<GrowableObjectArrayPtr>(obj)->untag()->length()));
    } else if (cid == kMapCid || cid == kConstMapCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<MapPtr>(obj)->untag()->used_data()));
    } else if (cid == kSetCid || cid == kConstSetCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<SetPtr>(obj)->untag()->used_data()));
    } else if (cid == kObjectPoolCid) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(static_cast<ObjectPoolPtr>(obj)->untag()->length_);
    } else if (IsTypedDataClassId(cid)) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(
          Smi::Value(static_cast<TypedDataPtr>(obj)->untag()->length()));
    } else if (IsExternalTypedDataClassId(cid)) {
      writer_->WriteUnsigned(kLengthData);
      writer_->WriteUnsigned(Smi::Value(
          static_cast<ExternalTypedDataPtr>(obj)->untag()->length()));
    } else if (cid == kFunctionCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<FunctionPtr>(obj)->untag()->name());
    } else if (cid == kCodeCid) {
      ObjectPtr owner = static_cast<CodePtr>(obj)->untag()->owner_;
      if (!owner->IsHeapObject()) {
        // Precompiler removed owner object from the snapshot,
        // only leaving Smi classId.
        writer_->WriteUnsigned(kNoData);
      } else if (owner->IsFunction()) {
        writer_->WriteUnsigned(kNameData);
        ScrubAndWriteUtf8(static_cast<FunctionPtr>(owner)->untag()->name());
      } else if (owner->IsClass()) {
        writer_->WriteUnsigned(kNameData);
        ScrubAndWriteUtf8(static_cast<ClassPtr>(owner)->untag()->name());
      } else {
        writer_->WriteUnsigned(kNoData);
      }
    } else if (cid == kFieldCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<FieldPtr>(obj)->untag()->name());
    } else if (cid == kClassCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<ClassPtr>(obj)->untag()->name());
    } else if (cid == kLibraryCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<LibraryPtr>(obj)->untag()->url());
    } else if (cid == kScriptCid) {
      writer_->WriteUnsigned(kNameData);
      ScrubAndWriteUtf8(static_cast<ScriptPtr>(obj)->untag()->url());
    } else if (cid == kTypeArgumentsCid) {
      // Handle scope so we do not change the root set.
      // We are assuming that TypeArguments::PrintSubvectorName never allocates
      // objects or zone handles.
      HANDLESCOPE(thread());
      const TypeArguments& args =
          TypeArguments::Handle(static_cast<TypeArgumentsPtr>(obj));
      TextBuffer buffer(128);
      args.PrintSubvectorName(0, args.Length(), TypeArguments::kScrubbedName,
                              &buffer);
      writer_->WriteUnsigned(kNameData);
      writer_->WriteUtf8(buffer.buffer());
    } else {
      writer_->WriteUnsigned(kNoData);
    }

    if (object_slots_->ContainsOnlyTaggedPointers(cid)) {
      DoCount();
      obj->untag()->VisitPointersPrecise(this);
      DoWrite();
      obj->untag()->VisitPointersPrecise(this);
    } else {
      auto slots = object_slots_->ObjectSlotsFor(cid);
      DoCount();
      counted_ += slots->length();
      DoWrite();
      for (auto& slot : *slots) {
        if (slot.is_compressed_pointer) {
          auto target = reinterpret_cast<CompressedObjectPtr*>(
              UntaggedObject::ToAddr(obj->untag()) + slot.offset);
          VisitCompressedPointers(obj->heap_base(), target, target);
        } else {
          writer_->WriteUnsigned(0);
        }
        written_++;
        total_++;
      }
    }
  }

  void ScrubAndWriteUtf8(StringPtr str) {
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

  void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
    if (writing_) {
      for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
        ObjectPtr target = *ptr;
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

#if defined(DART_COMPRESSED_POINTERS)
  void VisitCompressedPointers(uword heap_base,
                               CompressedObjectPtr* from,
                               CompressedObjectPtr* to) override {
    if (writing_) {
      for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
        ObjectPtr target = ptr->Decompress(heap_base);
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
#endif

  void VisitHandle(uword addr) override {
    FinalizablePersistentHandle* weak_persistent_handle =
        reinterpret_cast<FinalizablePersistentHandle*>(addr);
    if (!weak_persistent_handle->ptr()->IsHeapObject()) {
      return;  // Free handle.
    }

    writer_->WriteUnsigned(writer_->GetObjectId(weak_persistent_handle->ptr()));
    writer_->WriteUnsigned(weak_persistent_handle->external_size());
    // Attempt to include a native symbol name.
    auto const name = NativeSymbolResolver::LookupSymbolName(
        reinterpret_cast<uword>(weak_persistent_handle->callback()), nullptr);
    writer_->WriteUtf8((name == nullptr) ? "Unknown native function" : name);
    if (name != nullptr) {
      NativeSymbolResolver::FreeSymbolName(name);
    }
  }

  void CountExtraRefs(intptr_t count) {
    ASSERT(!writing_);
    counted_ += count;
  }
  void WriteExtraRef(intptr_t oid) {
    ASSERT(writing_);
    written_++;
    writer_->WriteUnsigned(oid);
  }

 private:
  IsolateGroup* isolate_group_;
  HeapSnapshotWriter* const writer_;
  ObjectSlots* object_slots_;
  bool writing_ = false;
  intptr_t counted_ = 0;
  intptr_t written_ = 0;
  intptr_t total_ = 0;
  bool discount_sizes_ = false;

  DISALLOW_COPY_AND_ASSIGN(Pass2Visitor);
};

class Pass3Visitor : public ObjectVisitor {
 public:
  explicit Pass3Visitor(HeapSnapshotWriter* writer)
      : ObjectVisitor(), thread_(Thread::Current()), writer_(writer) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsPseudoObject()) {
      return;
    }
    writer_->WriteUnsigned(
        HeapSnapshotWriter::GetHeapSnapshotIdentityHash(thread_, obj));
  }

 private:
  Thread* thread_;
  HeapSnapshotWriter* const writer_;

  DISALLOW_COPY_AND_ASSIGN(Pass3Visitor);
};

class CollectStaticFieldNames : public ObjectVisitor {
 public:
  CollectStaticFieldNames(intptr_t field_table_size,
                          const char** field_table_names)
      : ObjectVisitor(),
        field_table_size_(field_table_size),
        field_table_names_(field_table_names),
        field_(Field::Handle()) {}

  void VisitObject(ObjectPtr obj) override {
    if (obj->IsField()) {
      field_ ^= obj;
      if (field_.is_static()) {
        intptr_t id = field_.field_id();
        if (id > 0) {
          ASSERT(id < field_table_size_);
          field_table_names_[id] = field_.UserVisibleNameCString();
        }
      }
    }
  }

 private:
  intptr_t field_table_size_;
  const char** field_table_names_;
  Field& field_;

  DISALLOW_COPY_AND_ASSIGN(CollectStaticFieldNames);
};

void VmServiceHeapSnapshotChunkedWriter::WriteChunk(uint8_t* buffer,
                                                    intptr_t size,
                                                    bool last) {
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
                             kMetadataReservation, js.buffer()->buffer(),
                             js.buffer()->length(), buffer, size);
}

FileHeapSnapshotWriter::FileHeapSnapshotWriter(Thread* thread,
                                               const char* filename,
                                               bool* success)
    : ChunkedWriter(thread), success_(success) {
  auto open = Dart::file_open_callback();
  auto write = Dart::file_write_callback();
  auto close = Dart::file_close_callback();
  if (open != nullptr && write != nullptr && close != nullptr) {
    file_ = open(filename, /*write=*/true);
  }
  // If we have open/write/close callbacks we assume it can be done
  // successfully. (Those embedder-provided callbacks currently don't allow
  // signaling of failure conditions)
  if (success_ != nullptr) *success_ = file_ != nullptr;
}

FileHeapSnapshotWriter::~FileHeapSnapshotWriter() {
  if (file_ != nullptr) {
    Dart::file_close_callback()(file_);
  }
}

void FileHeapSnapshotWriter::WriteChunk(uint8_t* buffer,
                                        intptr_t size,
                                        bool last) {
  if (file_ != nullptr) {
    Dart::file_write_callback()(buffer, size, file_);
  }
  free(buffer);
}

CallbackHeapSnapshotWriter::CallbackHeapSnapshotWriter(
    Thread* thread,
    Dart_HeapSnapshotWriteChunkCallback callback,
    void* context)
    : ChunkedWriter(thread), callback_(callback), context_(context) {}

CallbackHeapSnapshotWriter::~CallbackHeapSnapshotWriter() {}

void CallbackHeapSnapshotWriter::WriteChunk(uint8_t* buffer,
                                            intptr_t size,
                                            bool last) {
  callback_(context_, buffer, size, last);
}

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

  ObjectSlots object_slots(thread());

  {
    HANDLESCOPE(thread());
    ClassTable* class_table = isolate_group()->class_table();
    class_count_ = class_table->NumCids() - 1;

    Class& cls = Class::Handle();
    Library& lib = Library::Handle();
    String& str = String::Handle();

    intptr_t field_table_size = isolate()->field_table()->NumFieldIds();
    const char** field_table_names =
        thread()->zone()->Alloc<const char*>(field_table_size);
    for (intptr_t i = 0; i < field_table_size; i++) {
      field_table_names[i] = nullptr;
    }
    {
      CollectStaticFieldNames visitor(field_table_size, field_table_names);
      iteration.IterateObjects(&visitor);
    }

    WriteUnsigned(class_count_ + kNumExtraCids);
    {
      ASSERT(kRootExtraCid == 1);
      WriteUnsigned(0);   // Flags
      WriteUtf8("Root");  // Name
      WriteUtf8("");      // Library name
      WriteUtf8("");      // Library uri
      WriteUtf8("");      // Reserved
      WriteUnsigned(0);   // Field count
    }
    {
      ASSERT(kImagePageExtraCid == 2);
      WriteUnsigned(0);              // Flags
      WriteUtf8("Read-Only Pages");  // Name
      WriteUtf8("");                 // Library name
      WriteUtf8("");                 // Library uri
      WriteUtf8("");                 // Reserved
      WriteUnsigned(0);              // Field count
    }
    {
      ASSERT(kIsolateExtraCid == 3);
      WriteUnsigned(0);      // Flags
      WriteUtf8("Isolate");  // Name
      WriteUtf8("");         // Library name
      WriteUtf8("");         // Library uri
      WriteUtf8("");         // Reserved

      WriteUnsigned(field_table_size);  // Field count
      for (intptr_t i = 0; i < field_table_size; i++) {
        intptr_t flags = 1;  // Strong.
        WriteUnsigned(flags);
        WriteUnsigned(i);  // Index.
        const char* name = field_table_names[i];
        WriteUtf8(name == nullptr ? "" : name);
        WriteUtf8("");  // Reserved
      }
    }

    ASSERT(kNumExtraCids == 3);
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

        if (auto slots = object_slots.ObjectSlotsFor(cid)) {
          WriteUnsigned(slots->length());
          for (intptr_t index = 0; index < slots->length(); ++index) {
            const auto& slot = (*slots)[index];
            const intptr_t kStrongFlag = 1;
            WriteUnsigned(kStrongFlag);
            WriteUnsigned(index);
            ScrubAndWriteUtf8(const_cast<char*>(slot.name));
            WriteUtf8("");  // Reserved
          }
        } else {
          // May be an abstract class.
          ASSERT(!cls.is_finalized());
          WriteUnsigned(0);
        }
      }
    }
  }

  SetupCountingPages();

  intptr_t num_isolates = 0;
  intptr_t num_image_objects = 0;
  {
    Pass1Visitor visitor(this, &object_slots);

    // Root "objects".
    {
      ++object_count_;
      isolate_group()->VisitSharedPointers(&visitor);
    }
    {
      ++object_count_;
      CountImagePageRefs visitor;
      H->old_space()->VisitObjectsImagePages(&visitor);
      num_image_objects = visitor.count();
      CountReferences(num_image_objects);
    }
    {
      isolate_group()->ForEachIsolate(
          [&](Isolate* isolate) {
            ++object_count_;
            isolate->VisitObjectPointers(&visitor,
                                         ValidationPolicy::kDontValidateFrames);
            isolate->VisitStackPointers(&visitor,
                                        ValidationPolicy::kDontValidateFrames);
            ++num_isolates;
          },
          /*at_safepoint=*/true);
    }
    CountReferences(1);             // Root -> Image Pages
    CountReferences(num_isolates);  // Root -> Isolate

    // Heap objects.
    iteration.IterateVMIsolateObjects(&visitor);
    iteration.IterateObjects(&visitor);

    // External properties.
    isolate()->group()->VisitWeakPersistentHandles(&visitor);

    // Smis.
    for (SmiPtr smi : smis_) {
      AssignObjectId(smi);
    }
  }

  {
    Pass2Visitor visitor(this, &object_slots);

    WriteUnsigned(reference_count_);
    WriteUnsigned(object_count_);

    // Root "objects".
    {
      WriteUnsigned(kRootExtraCid);
      WriteUnsigned(0);  // shallowSize
      WriteUnsigned(kNoData);
      visitor.DoCount();
      isolate_group()->VisitSharedPointers(&visitor);
      visitor.CountExtraRefs(num_isolates + 1);
      visitor.DoWrite();
      isolate_group()->VisitSharedPointers(&visitor);
      visitor.WriteExtraRef(2);  // Root -> Image Pages
      for (intptr_t i = 0; i < num_isolates; i++) {
        // 0 = sentinel, 1 = root, 2 = image pages, 2+ = isolates
        visitor.WriteExtraRef(i + 3);
      }
    }
    {
      WriteUnsigned(kImagePageExtraCid);
      WriteUnsigned(0);  // shallowSize
      WriteUnsigned(kNoData);
      WriteUnsigned(num_image_objects);
      WriteImagePageRefs visitor(this);
      H->old_space()->VisitObjectsImagePages(&visitor);
      DEBUG_ASSERT(visitor.count() == num_image_objects);
    }
    isolate_group()->ForEachIsolate(
        [&](Isolate* isolate) {
          WriteUnsigned(kIsolateExtraCid);
          WriteUnsigned(0);  // shallowSize
          WriteUnsigned(kNameData);
          WriteUtf8(
              OS::SCreate(thread()->zone(), "%" Pd64, isolate->main_port()));
          visitor.DoCount();
          isolate->VisitObjectPointers(&visitor,
                                       ValidationPolicy::kDontValidateFrames);
          isolate->VisitStackPointers(&visitor,
                                      ValidationPolicy::kDontValidateFrames);
          visitor.DoWrite();
          isolate->VisitObjectPointers(&visitor,
                                       ValidationPolicy::kDontValidateFrames);
          isolate->VisitStackPointers(&visitor,
                                      ValidationPolicy::kDontValidateFrames);
        },
        /*at_safepoint=*/true);

    // Heap objects.
    visitor.set_discount_sizes(true);
    iteration.IterateVMIsolateObjects(&visitor);
    visitor.set_discount_sizes(false);
    iteration.IterateObjects(&visitor);

    // Smis.
    for (SmiPtr smi : smis_) {
      WriteUnsigned(kSmiCid + kNumExtraCids);
      WriteUnsigned(0);  // Heap size.
      WriteUnsigned(kIntData);
      WriteUnsigned(Smi::Value(smi));
      WriteUnsigned(0);  // No slots.
    }

    // External properties.
    WriteUnsigned(external_property_count_);
    isolate()->group()->VisitWeakPersistentHandles(&visitor);
  }

  {
    // Identity hash codes
    Pass3Visitor visitor(this);

    WriteUnsigned(0);  // Root fake object.
    WriteUnsigned(0);  // Image pages fake object.
    isolate_group()->ForEachIsolate(
        [&](Isolate* isolate) {
          WriteUnsigned(0);  // Isolate fake object.
        },
        /*at_safepoint=*/true);

    // Handle visit rest of the objects.
    iteration.IterateVMIsolateObjects(&visitor);
    iteration.IterateObjects(&visitor);
    for (SmiPtr smi : smis_) {
      USE(smi);
      WriteUnsigned(0);  // No identity hash.
    }
  }

  ClearObjectIds();
  Flush(true);
}

uint32_t HeapSnapshotWriter::GetHeapSnapshotIdentityHash(Thread* thread,
                                                         ObjectPtr obj) {
  if (!obj->IsHeapObject()) return 0;
  intptr_t cid = obj->GetClassId();
  uint32_t hash = 0;
  switch (cid) {
    case kForwardingCorpse:
    case kFreeListElement:
    case kSmiCid:
      UNREACHABLE();
    case kArrayCid:
    case kBoolCid:
    case kCodeSourceMapCid:
    case kCompressedStackMapsCid:
    case kDoubleCid:
    case kExternalOneByteStringCid:
    case kExternalTwoByteStringCid:
    case kGrowableObjectArrayCid:
    case kImmutableArrayCid:
    case kConstMapCid:
    case kConstSetCid:
    case kInstructionsCid:
    case kInstructionsSectionCid:
    case kInstructionsTableCid:
    case kMapCid:
    case kSetCid:
    case kMintCid:
    case kNeverCid:
    case kSentinelCid:
    case kNullCid:
    case kObjectPoolCid:
    case kOneByteStringCid:
    case kPcDescriptorsCid:
    case kTwoByteStringCid:
    case kVoidCid:
      // Don't provide hash codes for objects with the above CIDs in order
      // to try and avoid having to initialize identity hash codes for common
      // primitives and types that don't have hash codes.
      break;
    default: {
      hash = GetHashHelper(thread, obj);
    }
  }
  return hash;
}

// Generates a random value which can serve as an identity hash.
// It must be a non-zero smi value (see also [Object._objectHashCode]).
static uint32_t GenerateHash(Random* random) {
  uint32_t hash;
  do {
    hash = random->NextUInt32();
  } while (hash == 0 || (kSmiBits < 32 && !Smi::IsValid(hash)));
  return hash;
}

uint32_t HeapSnapshotWriter::GetHashHelper(Thread* thread, ObjectPtr obj) {
  uint32_t hash;
#if defined(HASH_IN_OBJECT_HEADER)
  hash = Object::GetCachedHash(obj);
  if (hash == 0) {
    ASSERT(!thread->heap()->old_space()->IsObjectFromImagePages(obj));
    hash = GenerateHash(thread->random());
    Object::SetCachedHashIfNotSet(obj, hash);
  }
#else
  Heap* heap = thread->heap();
  hash = heap->GetHash(obj);
  if (hash == 0) {
    ASSERT(!heap->old_space()->IsObjectFromImagePages(obj));
    hash = GenerateHash(thread->random());
    heap->SetHashIfNotSet(obj, hash);
  }
#endif
  return hash;
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

void CountObjectsVisitor::VisitObject(ObjectPtr obj) {
  intptr_t cid = obj->GetClassId();
  intptr_t size = obj->untag()->HeapSize();
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
  ObjectPtr obj = handle->ptr();
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

#endif  // defined(DART_ENABLE_HEAP_SNAPSHOT_WRITER)

}  // namespace dart
