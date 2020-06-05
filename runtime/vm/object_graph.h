// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OBJECT_GRAPH_H_
#define RUNTIME_VM_OBJECT_GRAPH_H_

#include <memory>

#include "vm/allocation.h"
#include "vm/dart_api_state.h"
#include "vm/thread_stack_resource.h"

namespace dart {

class Array;
class Object;
class CountingPage;

#if !defined(PRODUCT)

// Utility to traverse the object graph in an ordered fashion.
// Example uses:
// - find a retaining path from the isolate roots to a particular object, or
// - determine how much memory is retained by some particular object(s).
class ObjectGraph : public ThreadStackResource {
 public:
  class Stack;

  // Allows climbing the search tree all the way to the root.
  class StackIterator {
   public:
    // The object this iterator currently points to.
    ObjectPtr Get() const;
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

    virtual bool visit_weak_persistent_handles() const { return false; }

    const char* gc_root_type = NULL;
    bool is_traversing = false;
  };

  typedef struct {
    intptr_t length;
    const char* gc_root_type;
  } RetainingPathResult;

  explicit ObjectGraph(Thread* thread);
  ~ObjectGraph();

  // Visits all strongly reachable objects in the isolate's heap, in a
  // pre-order, depth first traversal.
  void IterateObjects(Visitor* visitor);
  void IterateUserObjects(Visitor* visitor);

  // Like 'IterateObjects', but restricted to objects reachable from 'root'
  // (including 'root' itself).
  void IterateObjectsFrom(const Object& root, Visitor* visitor);
  void IterateObjectsFrom(intptr_t class_id,
                          HeapIterationScope* iteration,
                          Visitor* visitor);

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
  RetainingPathResult RetainingPath(Object* obj, const Array& path);

  // Find the objects that reference 'obj'. Populates the provided array with
  // pairs of (object pointing to 'obj', offset of pointer in words), as far as
  // there is room. Returns the number of objects found.
  //
  // An object for which this function answers no inbound references might still
  // be live due to references from the stack or embedder handles.
  intptr_t InboundReferences(Object* obj, const Array& references);

 private:
  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectGraph);
};

// Generates a dump of the heap, whose format is described in
// runtime/vm/service/heap_snapshot.md.
class HeapSnapshotWriter : public ThreadStackResource {
 public:
  explicit HeapSnapshotWriter(Thread* thread) : ThreadStackResource(thread) {}

  void WriteSigned(int64_t value) {
    EnsureAvailable((sizeof(value) * kBitsPerByte) / 7 + 1);

    bool is_last_part = false;
    while (!is_last_part) {
      uint8_t part = value & 0x7F;
      value >>= 7;
      if ((value == 0 && (part & 0x40) == 0) ||
          (value == static_cast<intptr_t>(-1) && (part & 0x40) != 0)) {
        is_last_part = true;
      } else {
        part |= 0x80;
      }
      buffer_[size_++] = part;
    }
  }

  void WriteUnsigned(uintptr_t value) {
    EnsureAvailable((sizeof(value) * kBitsPerByte) / 7 + 1);

    bool is_last_part = false;
    while (!is_last_part) {
      uint8_t part = value & 0x7F;
      value >>= 7;
      if (value == 0) {
        is_last_part = true;
      } else {
        part |= 0x80;
      }
      buffer_[size_++] = part;
    }
  }

  void WriteBytes(const void* bytes, intptr_t len) {
    EnsureAvailable(len);
    memmove(&buffer_[size_], bytes, len);
    size_ += len;
  }

  void ScrubAndWriteUtf8(char* value) {
    intptr_t len = strlen(value);
    for (intptr_t i = len - 1; i >= 0; i--) {
      if (value[i] == '@') {
        value[i] = '\0';
      }
    }
    WriteUtf8(value);
  }

  void WriteUtf8(const char* value) {
    intptr_t len = strlen(value);
    WriteUnsigned(len);
    WriteBytes(value, len);
  }

  void AssignObjectId(ObjectPtr obj);
  intptr_t GetObjectId(ObjectPtr obj) const;
  void ClearObjectIds();
  void CountReferences(intptr_t count);
  void CountExternalProperty();

  void Write();

 private:
  static const intptr_t kMetadataReservation = 512;
  static const intptr_t kPreferredChunkSize = MB;

  void SetupCountingPages();
  bool OnImagePage(ObjectPtr obj) const;
  CountingPage* FindCountingPage(ObjectPtr obj) const;

  void EnsureAvailable(intptr_t needed);
  void Flush(bool last = false);

  uint8_t* buffer_ = nullptr;
  intptr_t size_ = 0;
  intptr_t capacity_ = 0;

  intptr_t class_count_ = 0;
  intptr_t object_count_ = 0;
  intptr_t reference_count_ = 0;
  intptr_t external_property_count_ = 0;

  struct ImagePageRange {
    uword base;
    uword size;
  };
  // There are up to 4 images to consider:
  // {instructions, data} x {vm isolate, current isolate}
  static const intptr_t kMaxImagePages = 4;
  ImagePageRange image_page_ranges_[kMaxImagePages];

  DISALLOW_COPY_AND_ASSIGN(HeapSnapshotWriter);
};

class CountObjectsVisitor : public ObjectVisitor, public HandleVisitor {
 public:
  CountObjectsVisitor(Thread* thread, intptr_t class_count);
  ~CountObjectsVisitor() {}

  void VisitObject(ObjectPtr obj);
  void VisitHandle(uword addr);

  std::unique_ptr<intptr_t[]> new_count_;
  std::unique_ptr<intptr_t[]> new_size_;
  std::unique_ptr<intptr_t[]> new_external_size_;
  std::unique_ptr<intptr_t[]> old_count_;
  std::unique_ptr<intptr_t[]> old_size_;
  std::unique_ptr<intptr_t[]> old_external_size_;

  DISALLOW_COPY_AND_ASSIGN(CountObjectsVisitor);
};

#endif  // !defined(PRODUCT)

}  // namespace dart

#endif  // RUNTIME_VM_OBJECT_GRAPH_H_
