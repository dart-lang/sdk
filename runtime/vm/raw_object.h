// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RAW_OBJECT_H_
#define RUNTIME_VM_RAW_OBJECT_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include "platform/assert.h"
#include "platform/atomic.h"
#include "platform/thread_sanitizer.h"
#include "vm/class_id.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/pointer_tagging.h"
#include "vm/snapshot.h"
#include "vm/tagged_pointer.h"
#include "vm/token.h"
#include "vm/token_position.h"

namespace dart {

// For now there are no compressed pointers.
typedef ObjectPtr RawCompressed;

// Forward declarations.
class Isolate;
class IsolateGroup;
#define DEFINE_FORWARD_DECLARATION(clazz) class clazz##Layout;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class CodeStatistics;

#define VISIT_FROM(type, first)                                                \
  type* from() { return reinterpret_cast<type*>(&first); }

#define VISIT_TO(type, last)                                                   \
  type* to() { return reinterpret_cast<type*>(&last); }

#define VISIT_TO_LENGTH(type, last)                                            \
  type* to(intptr_t length) { return reinterpret_cast<type*>(last); }

#define VISIT_NOTHING() int NothingToVisit();

#define ASSERT_UNCOMPRESSED(Type)                                              \
  ASSERT(SIZE_OF_DEREFERENCED_RETURNED_VALUE(Type##Layout, from) == kWordSize)

// For now there are no compressed pointers, so this assert is the same as
// the above.
#define ASSERT_COMPRESSED(Type)                                                \
  ASSERT(SIZE_OF_DEREFERENCED_RETURNED_VALUE(Type##Layout, from) == kWordSize)

#define ASSERT_NOTHING_TO_VISIT(Type)                                          \
  ASSERT(SIZE_OF_RETURNED_VALUE(Type##Layout, NothingToVisit) == sizeof(int))

enum TypedDataElementType {
#define V(name) k##name##Element,
  CLASS_LIST_TYPED_DATA(V)
#undef V
};

#define SNAPSHOT_WRITER_SUPPORT()                                              \
  void WriteTo(SnapshotWriter* writer, intptr_t object_id,                     \
               Snapshot::Kind kind, bool as_reference);                        \
  friend class SnapshotWriter;

#define VISITOR_SUPPORT(object)                                                \
  static intptr_t Visit##object##Pointers(object##Ptr raw_obj,                 \
                                          ObjectPointerVisitor* visitor);

#define HEAP_PROFILER_SUPPORT() friend class HeapProfiler;

#define RAW_OBJECT_IMPLEMENTATION(object)                                      \
 private: /* NOLINT */                                                         \
  VISITOR_SUPPORT(object)                                                      \
  friend class object;                                                         \
  friend class ObjectLayout;                                                   \
  friend class Heap;                                                           \
  friend class Interpreter;                                                    \
  friend class InterpreterHelpers;                                             \
  friend class Simulator;                                                      \
  friend class SimulatorHelpers;                                               \
  friend class OffsetsTable;                                                   \
  DISALLOW_ALLOCATION();                                                       \
  DISALLOW_IMPLICIT_CONSTRUCTORS(object##Layout)

#define RAW_HEAP_OBJECT_IMPLEMENTATION(object)                                 \
 private:                                                                      \
  RAW_OBJECT_IMPLEMENTATION(object);                                           \
  SNAPSHOT_WRITER_SUPPORT()                                                    \
  HEAP_PROFILER_SUPPORT()                                                      \
  friend class object##SerializationCluster;                                   \
  friend class object##DeserializationCluster;                                 \
  friend class Serializer;                                                     \
  friend class Deserializer;                                                   \
  friend class Pass2Visitor;

// RawObject is the base class of all raw objects; even though it carries the
// tags_ field not all raw objects are allocated in the heap and thus cannot
// be dereferenced (e.g. RawSmi).
class ObjectLayout {
 public:
  // The tags field which is a part of the object header uses the following
  // bit fields for storing tags.
  enum TagBits {
    kCardRememberedBit = 0,
    kOldAndNotMarkedBit = 1,      // Incremental barrier target.
    kNewBit = 2,                  // Generational barrier target.
    kOldBit = 3,                  // Incremental barrier source.
    kOldAndNotRememberedBit = 4,  // Generational barrier source.
    kCanonicalBit = 5,
    kReservedTagPos = 6,
    kReservedTagSize = 2,

    kSizeTagPos = kReservedTagPos + kReservedTagSize,  // = 8
    kSizeTagSize = 8,
    kClassIdTagPos = kSizeTagPos + kSizeTagSize,  // = 16
    kClassIdTagSize = 16,
#if defined(HASH_IN_OBJECT_HEADER)
    kHashTagPos = kClassIdTagPos + kClassIdTagSize,  // = 32
    kHashTagSize = 16,
#endif
  };

  static const intptr_t kGenerationalBarrierMask = 1 << kNewBit;
  static const intptr_t kIncrementalBarrierMask = 1 << kOldAndNotMarkedBit;
  static const intptr_t kBarrierOverlapShift = 2;
  COMPILE_ASSERT(kOldAndNotMarkedBit + kBarrierOverlapShift == kOldBit);
  COMPILE_ASSERT(kNewBit + kBarrierOverlapShift == kOldAndNotRememberedBit);

  // The bit in the Smi tag position must be something that can be set to 0
  // for a dead filler object of either generation.
  // See Object::MakeUnusedSpaceTraversable.
  COMPILE_ASSERT(kCardRememberedBit == 0);

  COMPILE_ASSERT(8 * sizeof(uint16_t) == kClassIdTagSize);

  // Encodes the object size in the tag in units of object alignment.
  class SizeTag {
   public:
    typedef intptr_t Type;

    static constexpr intptr_t kMaxSizeTagInUnitsOfAlignment =
        ((1 << ObjectLayout::kSizeTagSize) - 1);
    static constexpr intptr_t kMaxSizeTag =
        kMaxSizeTagInUnitsOfAlignment * kObjectAlignment;

    static UNLESS_DEBUG(constexpr) uword encode(intptr_t size) {
      return SizeBits::encode(SizeToTagValue(size));
    }

    static constexpr uword decode(uword tag) {
      return TagValueToSize(SizeBits::decode(tag));
    }

    static UNLESS_DEBUG(constexpr) uword update(intptr_t size, uword tag) {
      return SizeBits::update(SizeToTagValue(size), tag);
    }

    static UNLESS_DEBUG(constexpr) bool SizeFits(intptr_t size) {
      DEBUG_ASSERT(Utils::IsAligned(size, kObjectAlignment));
      return (size <= kMaxSizeTag);
    }

   private:
    // The actual unscaled bit field used within the tag field.
    class SizeBits
        : public BitField<uint32_t, intptr_t, kSizeTagPos, kSizeTagSize> {};

    static UNLESS_DEBUG(constexpr) intptr_t SizeToTagValue(intptr_t size) {
      DEBUG_ASSERT(Utils::IsAligned(size, kObjectAlignment));
      return !SizeFits(size) ? 0 : (size >> kObjectAlignmentLog2);
    }
    static constexpr intptr_t TagValueToSize(intptr_t value) {
      return value << kObjectAlignmentLog2;
    }
  };

  class ClassIdTag
      : public BitField<uint32_t, intptr_t, kClassIdTagPos, kClassIdTagSize> {};

  class CardRememberedBit
      : public BitField<uint32_t, bool, kCardRememberedBit, 1> {};

  class OldAndNotMarkedBit
      : public BitField<uint32_t, bool, kOldAndNotMarkedBit, 1> {};

  class NewBit : public BitField<uint32_t, bool, kNewBit, 1> {};

  class CanonicalBit : public BitField<uint32_t, bool, kCanonicalBit, 1> {};

  class OldBit : public BitField<uint32_t, bool, kOldBit, 1> {};

  class OldAndNotRememberedBit
      : public BitField<uint32_t, bool, kOldAndNotRememberedBit, 1> {};

  class ReservedBits
      : public BitField<uint32_t, intptr_t, kReservedTagPos, kReservedTagSize> {
  };

  class Tags {
   public:
    Tags() : tags_(0) {}

    NO_SANITIZE_THREAD
    operator uint32_t() const {
      return *reinterpret_cast<const uint32_t*>(&tags_);
    }

    NO_SANITIZE_THREAD
    uint32_t operator=(uint32_t tags) {
      return *reinterpret_cast<uint32_t*>(&tags_) = tags;
    }

    NO_SANITIZE_THREAD
    bool StrongCAS(uint32_t old_tags, uint32_t new_tags) {
      return tags_.compare_exchange_strong(old_tags, new_tags,
                                           std::memory_order_relaxed);
    }

    NO_SANITIZE_THREAD
    bool WeakCAS(uint32_t old_tags, uint32_t new_tags) {
      return tags_.compare_exchange_weak(old_tags, new_tags,
                                         std::memory_order_relaxed);
    }

    template <class TagBitField>
    NO_SANITIZE_THREAD typename TagBitField::Type Read() const {
      return TagBitField::decode(*reinterpret_cast<const uint32_t*>(&tags_));
    }

    template <class TagBitField>
    NO_SANITIZE_THREAD void UpdateBool(bool value) {
      if (value) {
        tags_.fetch_or(TagBitField::encode(true), std::memory_order_relaxed);
      } else {
        tags_.fetch_and(~TagBitField::encode(true), std::memory_order_relaxed);
      }
    }

    template <class TagBitField>
    NO_SANITIZE_THREAD void UpdateUnsynchronized(
        typename TagBitField::Type value) {
      *reinterpret_cast<uint32_t*>(&tags_) =
          TagBitField::update(value, *reinterpret_cast<uint32_t*>(&tags_));
    }

    template <class TagBitField>
    NO_SANITIZE_THREAD bool TryAcquire() {
      uint32_t mask = TagBitField::encode(true);
      uint32_t old_tags = tags_.fetch_or(mask, std::memory_order_relaxed);
      return !TagBitField::decode(old_tags);
    }

    template <class TagBitField>
    NO_SANITIZE_THREAD bool TryClear() {
      uint32_t mask = ~TagBitField::encode(true);
      uint32_t old_tags = tags_.fetch_and(mask, std::memory_order_relaxed);
      return TagBitField::decode(old_tags);
    }

   private:
    std::atomic<uint32_t> tags_;
    COMPILE_ASSERT(sizeof(std::atomic<uint32_t>) == sizeof(uint32_t));
  };

  // Assumes this is a heap object.
  bool IsNewObject() const {
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kObjectAlignmentMask) == kNewObjectAlignmentOffset;
  }
  // Assumes this is a heap object.
  bool IsOldObject() const {
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kObjectAlignmentMask) == kOldObjectAlignmentOffset;
  }

  // Support for GC marking bit. Marked objects are either grey (not yet
  // visited) or black (already visited).
  bool IsMarked() const {
    ASSERT(IsOldObject());
    return !tags_.Read<OldAndNotMarkedBit>();
  }
  void SetMarkBit() {
    ASSERT(IsOldObject());
    ASSERT(!IsMarked());
    tags_.UpdateBool<OldAndNotMarkedBit>(false);
  }
  void SetMarkBitUnsynchronized() {
    ASSERT(IsOldObject());
    ASSERT(!IsMarked());
    tags_.UpdateUnsynchronized<OldAndNotMarkedBit>(false);
  }
  void ClearMarkBit() {
    ASSERT(IsOldObject());
    ASSERT(IsMarked());
    tags_.UpdateBool<OldAndNotMarkedBit>(true);
  }
  // Returns false if the bit was already set.
  DART_WARN_UNUSED_RESULT
  bool TryAcquireMarkBit() {
    ASSERT(IsOldObject());
    return tags_.TryClear<OldAndNotMarkedBit>();
  }

  // Canonical objects have the property that two canonical objects are
  // logically equal iff they are the same object (pointer equal).
  bool IsCanonical() const { return tags_.Read<CanonicalBit>(); }
  void SetCanonical() { tags_.UpdateBool<CanonicalBit>(true); }
  void ClearCanonical() { tags_.UpdateBool<CanonicalBit>(false); }

  bool InVMIsolateHeap() const;

  // Support for GC remembered bit.
  bool IsRemembered() const {
    ASSERT(IsOldObject());
    return !tags_.Read<OldAndNotRememberedBit>();
  }
  void SetRememberedBit() {
    ASSERT(!IsRemembered());
    ASSERT(!IsCardRemembered());
    tags_.UpdateBool<OldAndNotRememberedBit>(false);
  }
  void ClearRememberedBit() {
    ASSERT(IsOldObject());
    tags_.UpdateBool<OldAndNotRememberedBit>(true);
  }

  DART_FORCE_INLINE
  void AddToRememberedSet(Thread* thread) {
    ASSERT(!this->IsRemembered());
    this->SetRememberedBit();
    thread->StoreBufferAddObject(ObjectPtr(this));
  }

  bool IsCardRemembered() const { return tags_.Read<CardRememberedBit>(); }
  void SetCardRememberedBitUnsynchronized() {
    ASSERT(!IsRemembered());
    ASSERT(!IsCardRemembered());
    tags_.UpdateUnsynchronized<CardRememberedBit>(true);
  }

  intptr_t GetClassId() const { return tags_.Read<ClassIdTag>(); }

  intptr_t HeapSize() const {
    uint32_t tags = tags_;
    intptr_t result = SizeTag::decode(tags);
    if (result != 0) {
#if defined(DEBUG)
      // TODO(22501) Array::MakeFixedLength has a race with this code: we might
      // have loaded tags field and then MakeFixedLength could have updated it
      // leading to inconsistency between HeapSizeFromClass() and
      // SizeTag::decode(tags). We are working around it by reloading tags_ and
      // recomputing size from tags.
      const intptr_t size_from_class = HeapSizeFromClass(tags);
      if ((result > size_from_class) && (GetClassId() == kArrayCid) &&
          (tags_ != tags)) {
        result = SizeTag::decode(tags_);
      }
      ASSERT(result == size_from_class);
#endif
      return result;
    }
    result = HeapSizeFromClass(tags);
    ASSERT(result > SizeTag::kMaxSizeTag);
    return result;
  }

  // This variant must not deference this->tags_.
  intptr_t HeapSize(uint32_t tags) const {
    intptr_t result = SizeTag::decode(tags);
    if (result != 0) {
      return result;
    }
    result = HeapSizeFromClass(tags);
    ASSERT(result > SizeTag::kMaxSizeTag);
    return result;
  }

  bool Contains(uword addr) const {
    intptr_t this_size = HeapSize();
    uword this_addr = ObjectLayout::ToAddr(this);
    return (addr >= this_addr) && (addr < (this_addr + this_size));
  }

  void Validate(IsolateGroup* isolate_group) const;
  bool FindObject(FindObjectVisitor* visitor);

  // This function may access the class-ID in the header, but it cannot access
  // the actual class object, because the sliding compactor uses this function
  // while the class objects are being moved.
  intptr_t VisitPointers(ObjectPointerVisitor* visitor) {
    // Fall back to virtual variant for predefined classes
    intptr_t class_id = GetClassId();
    if (class_id < kNumPredefinedCids) {
      return VisitPointersPredefined(visitor, class_id);
    }

    // Calculate the first and last raw object pointer fields.
    intptr_t instance_size = HeapSize();
    uword obj_addr = ToAddr(this);
    uword from = obj_addr + sizeof(ObjectLayout);
    uword to = obj_addr + instance_size - kWordSize;
    const auto first = reinterpret_cast<ObjectPtr*>(from);
    const auto last = reinterpret_cast<ObjectPtr*>(to);

#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
    const auto unboxed_fields_bitmap =
        visitor->shared_class_table()->GetUnboxedFieldsMapAt(class_id);

    if (!unboxed_fields_bitmap.IsEmpty()) {
      intptr_t bit = sizeof(ObjectLayout) / kWordSize;
      for (ObjectPtr* current = first; current <= last; current++) {
        if (!unboxed_fields_bitmap.Get(bit++)) {
          visitor->VisitPointer(current);
        }
      }
    } else {
      visitor->VisitPointers(first, last);
    }
#else
    // Call visitor function virtually
    visitor->VisitPointers(first, last);
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)

    return instance_size;
  }

  template <class V>
  intptr_t VisitPointersNonvirtual(V* visitor) {
    // Fall back to virtual variant for predefined classes
    intptr_t class_id = GetClassId();
    if (class_id < kNumPredefinedCids) {
      return VisitPointersPredefined(visitor, class_id);
    }

    // Calculate the first and last raw object pointer fields.
    intptr_t instance_size = HeapSize();
    uword obj_addr = ToAddr(this);
    uword from = obj_addr + sizeof(ObjectLayout);
    uword to = obj_addr + instance_size - kWordSize;
    const auto first = reinterpret_cast<ObjectPtr*>(from);
    const auto last = reinterpret_cast<ObjectPtr*>(to);

#if defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)
    const auto unboxed_fields_bitmap =
        visitor->shared_class_table()->GetUnboxedFieldsMapAt(class_id);

    if (!unboxed_fields_bitmap.IsEmpty()) {
      intptr_t bit = sizeof(ObjectLayout) / kWordSize;
      for (ObjectPtr* current = first; current <= last; current++) {
        if (!unboxed_fields_bitmap.Get(bit++)) {
          visitor->V::VisitPointers(current, current);
        }
      }
    } else {
      visitor->V::VisitPointers(first, last);
    }
#else
    // Call visitor function non-virtually
    visitor->V::VisitPointers(first, last);
#endif  // defined(SUPPORT_UNBOXED_INSTANCE_FIELDS)

    return instance_size;
  }

  // This variant ensures that we do not visit the extra slot created from
  // rounding up instance sizes up to the allocation unit.
  void VisitPointersPrecise(Isolate* isolate, ObjectPointerVisitor* visitor);

  static ObjectPtr FromAddr(uword addr) {
    // We expect the untagged address here.
    ASSERT((addr & kSmiTagMask) != kHeapObjectTag);
    return static_cast<ObjectPtr>(addr + kHeapObjectTag);
  }

  static uword ToAddr(const ObjectLayout* raw_obj) {
    return reinterpret_cast<uword>(raw_obj);
  }
  static uword ToAddr(const ObjectPtr raw_obj) {
    return static_cast<uword>(raw_obj) - kHeapObjectTag;
  }

  static bool IsCanonical(intptr_t value) {
    return CanonicalBit::decode(value);
  }

 private:
  Tags tags_;  // Various object tags (bits).
#if defined(HASH_IN_OBJECT_HEADER)
  // On 64 bit there is a hash field in the header for the identity hash.
  uint32_t hash_;
#elif defined(IS_SIMARM_X64)
  // On simarm_x64 the hash isn't used, but we need the padding anyway so that
  // the object layout fits assumptions made about X64.
  uint32_t padding_;
#endif

  intptr_t VisitPointersPredefined(ObjectPointerVisitor* visitor,
                                   intptr_t class_id);

  intptr_t HeapSizeFromClass(uint32_t tags) const;

  void SetClassId(intptr_t new_cid) {
    tags_.UpdateUnsynchronized<ClassIdTag>(new_cid);
  }

  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in Object, to ensure that the
  // write barrier is correctly applied.

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  type LoadPointer(type const* addr) {
    return reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->load(order);
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StorePointer(type const* addr, type value) {
    reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->store(value, order);
    if (value->IsHeapObject()) {
      CheckHeapPointerStore(value, Thread::Current());
    }
  }

  template <typename type>
  void StorePointer(type const* addr, type value, Thread* thread) {
    *const_cast<type*>(addr) = value;
    if (value->IsHeapObject()) {
      CheckHeapPointerStore(value, thread);
    }
  }

  template <typename type>
  void StorePointerUnaligned(type const* addr, type value, Thread* thread) {
    StoreUnaligned(const_cast<type*>(addr), value);
    if (value->IsHeapObject()) {
      CheckHeapPointerStore(value, thread);
    }
  }

  DART_FORCE_INLINE
  void CheckHeapPointerStore(ObjectPtr value, Thread* thread) {
    uint32_t source_tags = this->tags_;
    uint32_t target_tags = value->ptr()->tags_;
    if (((source_tags >> kBarrierOverlapShift) & target_tags &
         thread->write_barrier_mask()) != 0) {
      if (value->IsNewObject()) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        AddToRememberedSet(thread);
      } else {
        // Incremental barrier: record when a store creates an
        // old -> old-and-not-marked reference.
        ASSERT(value->IsOldObject());
#if !defined(TARGET_ARCH_IA32)
        if (ClassIdTag::decode(target_tags) == kInstructionsCid) {
          // Instruction pages may be non-writable. Defer marking.
          thread->DeferredMarkingStackAddObject(value);
          return;
        }
#endif
        if (value->ptr()->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StoreArrayPointer(type const* addr, type value) {
    reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->store(value, order);
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, Thread::Current());
    }
  }

  template <typename type>
  void StoreArrayPointer(type const* addr, type value, Thread* thread) {
    *const_cast<type*>(addr) = value;
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, thread);
    }
  }

  template <typename type>
  DART_FORCE_INLINE void CheckArrayPointerStore(type const* addr,
                                                ObjectPtr value,
                                                Thread* thread) {
    uint32_t source_tags = this->tags_;
    uint32_t target_tags = value->ptr()->tags_;
    if (((source_tags >> kBarrierOverlapShift) & target_tags &
         thread->write_barrier_mask()) != 0) {
      if (value->IsNewObject()) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        ASSERT(!this->IsRemembered());
        if (this->IsCardRemembered()) {
          RememberCard(reinterpret_cast<ObjectPtr const*>(addr));
        } else {
          this->SetRememberedBit();
          thread->StoreBufferAddObject(static_cast<ObjectPtr>(this));
        }
      } else {
        // Incremental barrier: record when a store creates an
        // old -> old-and-not-marked reference.
        ASSERT(value->IsOldObject());
#if !defined(TARGET_ARCH_IA32)
        if (ClassIdTag::decode(target_tags) == kInstructionsCid) {
          // Instruction pages may be non-writable. Defer marking.
          thread->DeferredMarkingStackAddObject(value);
          return;
        }
#endif
        if (value->ptr()->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  void StoreSmi(SmiPtr const* addr, SmiPtr value) {
    // Can't use Contains, as array length is initialized through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= ObjectLayout::ToAddr(this));
    *const_cast<SmiPtr*>(addr) = value;
  }
  NO_SANITIZE_THREAD
  void StoreSmiIgnoreRace(SmiPtr const* addr, SmiPtr value) {
    // Can't use Contains, as array length is initialized through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= ObjectLayout::ToAddr(this));
    *const_cast<SmiPtr*>(addr) = value;
  }

 protected:
  friend class StoreBufferUpdateVisitor;  // RememberCard
  void RememberCard(ObjectPtr const* slot);

  friend class Array;
  friend class ByteBuffer;
  friend class CidRewriteVisitor;
  friend class Closure;
  friend class Code;
  friend class Pointer;
  friend class Double;
  friend class DynamicLibrary;
  friend class ForwardPointersVisitor;  // StorePointer
  friend class FreeListElement;
  friend class Function;
  friend class GCMarker;
  friend class ExternalTypedData;
  friend class ForwardList;
  friend class GrowableObjectArray;  // StorePointer
  friend class Heap;
  friend class ClassStatsVisitor;
  template <bool>
  friend class MarkingVisitorBase;
  friend class Mint;
  friend class Object;
  friend class OneByteString;  // StoreSmi
  friend class InstanceLayout;
  friend class Scavenger;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class ImageReader;  // tags_ check
  friend class ImageWriter;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class SnapshotReader;
  friend class Deserializer;
  friend class SnapshotWriter;
  friend class String;
  friend class WeakProperty;            // StorePointer
  friend class Instance;                // StorePointer
  friend class StackFrame;              // GetCodeObject assertion.
  friend class CodeLookupTableBuilder;  // profiler
  friend class Interpreter;
  friend class InterpreterHelpers;
  friend class Simulator;
  friend class SimulatorHelpers;
  friend class ObjectLocator;
  friend class WriteBarrierUpdateVisitor;  // CheckHeapPointerStore
  friend class OffsetsTable;
  friend class Object;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ObjectLayout);
};

inline intptr_t ObjectPtr::GetClassId() const {
  return ptr()->GetClassId();
}

class ClassLayout : public ObjectLayout {
 public:
  enum ClassFinalizedState {
    kAllocated = 0,  // Initial state.
    kPreFinalized,   // VM classes: size precomputed, but no checks done.
    kFinalized,      // Class parsed, code compiled, not ready for allocation.
    kAllocateFinalized,  // CHA invalidated, class is ready for allocation.
  };
  enum ClassLoadingState {
    // Class object is created, but it is not filled up.
    // At this state class can only be used as a forward reference during
    // class loading.
    kNameOnly = 0,
    // Class declaration information such as type parameters, supertype and
    // implemented interfaces are loaded. However, types in the class are
    // not finalized yet.
    kDeclarationLoaded,
    // Types in the class are finalized. At this point, members can be loaded
    // and class can be finalized.
    kTypeFinalized,
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Class);

  VISIT_FROM(ObjectPtr, name_);
  StringPtr name_;
  StringPtr user_name_;
  ArrayPtr functions_;
  ArrayPtr functions_hash_table_;
  ArrayPtr fields_;
  ArrayPtr offset_in_words_to_field_;
  ArrayPtr interfaces_;  // Array of AbstractType.
  ScriptPtr script_;
  LibraryPtr library_;
  TypeArgumentsPtr type_parameters_;  // Array of TypeParameter.
  AbstractTypePtr super_type_;
  FunctionPtr signature_function_;  // Associated function for typedef class.
  ArrayPtr constants_;        // Canonicalized const instances of this class.
  TypePtr declaration_type_;  // Declaration type for this class.
  ArrayPtr invocation_dispatcher_cache_;  // Cache for dispatcher functions.
  CodePtr allocation_stub_;  // Stub code for allocation of instances.
  GrowableObjectArrayPtr direct_implementors_;  // Array of Class.
  GrowableObjectArrayPtr direct_subclasses_;    // Array of Class.
  ArrayPtr dependent_code_;                     // CHA optimized codes.
  VISIT_TO(ObjectPtr, dependent_code_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&allocation_stub_);
      case Snapshot::kFull:
        return reinterpret_cast<ObjectPtr*>(&direct_subclasses_);
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&dependent_code_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  TokenPosition token_pos_;
  TokenPosition end_token_pos_;

  classid_t id_;                // Class Id, also index in the class table.
  int16_t num_type_arguments_;  // Number of type arguments in flattened vector.
  uint16_t num_native_fields_;
  uint32_t state_bits_;

  // Size if fixed len or 0 if variable len.
  int32_t host_instance_size_in_words_;

  // Offset of type args fld.
  int32_t host_type_arguments_field_offset_in_words_;

  // Offset of the next instance field.
  int32_t host_next_field_offset_in_words_;

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Size if fixed len or 0 if variable len (target).
  int32_t target_instance_size_in_words_;

  // Offset of type args fld.
  int32_t target_type_arguments_field_offset_in_words_;

  // Offset of the next instance field (target).
  int32_t target_next_field_offset_in_words_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if !defined(DART_PRECOMPILED_RUNTIME)
  typedef BitField<uint32_t, bool, 0, 1> IsDeclaredInBytecode;
  typedef BitField<uint32_t, uint32_t, 1, 31> BinaryDeclarationOffset;
  uint32_t binary_declaration_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  friend class Instance;
  friend class Isolate;
  friend class Object;
  friend class InstanceLayout;
  friend class InstructionsLayout;
  friend class TypeArgumentsLayout;
  friend class SnapshotReader;
  friend class InstanceSerializationCluster;
  friend class CidRewriteVisitor;
};

class PatchClassLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PatchClass);

  VISIT_FROM(ObjectPtr, patched_class_);
  ClassPtr patched_class_;
  ClassPtr origin_class_;
  ScriptPtr script_;
  ExternalTypedDataPtr library_kernel_data_;
  VISIT_TO(ObjectPtr, library_kernel_data_);

  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&script_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&library_kernel_data_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  NOT_IN_PRECOMPILED(intptr_t library_kernel_offset_);

  friend class Function;
};

class FunctionLayout : public ObjectLayout {
 public:
  // When you add a new kind, please also update the observatory to account
  // for the new string returned by KindToCString().
  // - runtime/observatory/lib/src/models/objects/function.dart (FunctionKind)
  // - runtime/observatory/lib/src/elements/function_view.dart
  //   (_functionKindToString)
  // - runtime/observatory/lib/src/service/object.dart (stringToFunctionKind)
#define FOR_EACH_RAW_FUNCTION_KIND(V)                                          \
  /* an ordinary or operator method */                                         \
  V(RegularFunction)                                                           \
  /* a user-declared closure function */                                       \
  V(ClosureFunction)                                                           \
  /* an implicit closure (i.e., tear-off) */                                   \
  V(ImplicitClosureFunction)                                                   \
  /* a signature only without actual code */                                   \
  V(SignatureFunction)                                                         \
  /* getter functions e.g: get foo() { .. } */                                 \
  V(GetterFunction)                                                            \
  /* setter functions e.g: set foo(..) { .. } */                               \
  V(SetterFunction)                                                            \
  /* a generative (is_static=false) or factory (is_static=true) constructor */ \
  V(Constructor)                                                               \
  /* an implicit getter for instance fields */                                 \
  V(ImplicitGetter)                                                            \
  /* an implicit setter for instance fields */                                 \
  V(ImplicitSetter)                                                            \
  /* represents an implicit getter for static fields with initializers */      \
  V(ImplicitStaticGetter)                                                      \
  /* the initialization expression for a static or instance field */           \
  V(FieldInitializer)                                                          \
  /* return a closure on the receiver for tear-offs */                         \
  V(MethodExtractor)                                                           \
  /* builds an Invocation and invokes noSuchMethod */                          \
  V(NoSuchMethodDispatcher)                                                    \
  /* invokes a field as a closure (i.e., call-through-getter) */               \
  V(InvokeFieldDispatcher)                                                     \
  /* a generated irregexp matcher function. */                                 \
  V(IrregexpFunction)                                                          \
  /* a forwarder which performs type checks for arguments of a dynamic call */ \
  /* (i.e., those checks omitted by the caller for interface calls). */        \
  V(DynamicInvocationForwarder)                                                \
  V(FfiTrampoline)

  enum Kind {
#define KIND_DEFN(Name) k##Name,
    FOR_EACH_RAW_FUNCTION_KIND(KIND_DEFN)
#undef KIND_DEFN
  };

  static const char* KindToCString(Kind k) {
    switch (k) {
#define KIND_CASE(Name)                                                        \
  case Kind::k##Name:                                                          \
    return #Name;
      FOR_EACH_RAW_FUNCTION_KIND(KIND_CASE)
#undef KIND_CASE
      default:
        UNREACHABLE();
        return nullptr;
    }
  }

  static bool ParseKind(const char* str, Kind* out) {
#define KIND_CASE(Name)                                                        \
  if (strcmp(str, #Name) == 0) {                                               \
    *out = Kind::k##Name;                                                      \
    return true;                                                               \
  }
    FOR_EACH_RAW_FUNCTION_KIND(KIND_CASE)
#undef KIND_CASE
    return false;
  }

  enum AsyncModifier {
    kNoModifier = 0x0,
    kAsyncBit = 0x1,
    kGeneratorBit = 0x2,
    kAsync = kAsyncBit,
    kSyncGen = kGeneratorBit,
    kAsyncGen = kAsyncBit | kGeneratorBit,
  };

  // Wraps a 64-bit integer to represent the bitmap for unboxed parameters and
  // return value. Two bits are used for each of them - the first one indicates
  // whether this value is unboxed or not, and the second one says whether it is
  // an integer or a double. It includes the two bits for the receiver, even
  // though currently we do not have information from TFA that allows the
  // receiver to be unboxed.
  class UnboxedParameterBitmap {
   public:
    static constexpr intptr_t kBitsPerParameter = 2;
    static constexpr intptr_t kCapacity =
        (kBitsPerByte * sizeof(uint64_t)) / kBitsPerParameter;

    UnboxedParameterBitmap() : bitmap_(0) {}
    explicit UnboxedParameterBitmap(uint64_t bitmap) : bitmap_(bitmap) {}
    UnboxedParameterBitmap(const UnboxedParameterBitmap&) = default;
    UnboxedParameterBitmap& operator=(const UnboxedParameterBitmap&) = default;

    DART_FORCE_INLINE bool IsUnboxed(intptr_t position) const {
      if (position >= kCapacity) {
        return false;
      }
      ASSERT(Utils::TestBit(bitmap_, 2 * position) ||
             !Utils::TestBit(bitmap_, 2 * position + 1));
      return Utils::TestBit(bitmap_, 2 * position);
    }
    DART_FORCE_INLINE bool IsUnboxedInteger(intptr_t position) const {
      if (position >= kCapacity) {
        return false;
      }
      return Utils::TestBit(bitmap_, 2 * position) &&
             !Utils::TestBit(bitmap_, 2 * position + 1);
    }
    DART_FORCE_INLINE bool IsUnboxedDouble(intptr_t position) const {
      if (position >= kCapacity) {
        return false;
      }
      return Utils::TestBit(bitmap_, 2 * position) &&
             Utils::TestBit(bitmap_, 2 * position + 1);
    }
    DART_FORCE_INLINE void SetUnboxedInteger(intptr_t position) {
      ASSERT(position < kCapacity);
      bitmap_ |= Utils::Bit<decltype(bitmap_)>(2 * position);
      ASSERT(!Utils::TestBit(bitmap_, 2 * position + 1));
    }
    DART_FORCE_INLINE void SetUnboxedDouble(intptr_t position) {
      ASSERT(position < kCapacity);
      bitmap_ |= Utils::Bit<decltype(bitmap_)>(2 * position);
      bitmap_ |= Utils::Bit<decltype(bitmap_)>(2 * position + 1);
    }
    DART_FORCE_INLINE uint64_t Value() const { return bitmap_; }
    DART_FORCE_INLINE bool IsEmpty() const { return bitmap_ == 0; }
    DART_FORCE_INLINE void Reset() { bitmap_ = 0; }

   private:
    uint64_t bitmap_;
  };

  static constexpr intptr_t kMaxFixedParametersBits = 15;
  static constexpr intptr_t kMaxOptionalParametersBits = 14;

 private:
  friend class Class;

  RAW_HEAP_OBJECT_IMPLEMENTATION(Function);

  uword entry_point_;            // Accessed from generated code.
  uword unchecked_entry_point_;  // Accessed from generated code.

  VISIT_FROM(ObjectPtr, name_);
  StringPtr name_;
  ObjectPtr owner_;  // Class or patch class or mixin class
                     // where this function is defined.
  AbstractTypePtr result_type_;
  ArrayPtr parameter_types_;
  ArrayPtr parameter_names_;
  TypeArgumentsPtr type_parameters_;  // Array of TypeParameter.
  ObjectPtr data_;  // Additional data specific to the function kind. See
                    // Function::set_data() for details.
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&data_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  ArrayPtr ic_data_array_;  // ICData of unoptimized code.
  ObjectPtr* to_no_code() {
    return reinterpret_cast<ObjectPtr*>(&ic_data_array_);
  }
  CodePtr code_;  // Currently active code. Accessed from generated code.
  NOT_IN_PRECOMPILED(BytecodePtr bytecode_);
  NOT_IN_PRECOMPILED(CodePtr unoptimized_code_);  // Unoptimized code, keep it
                                                  // after optimization.
#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(ObjectPtr, code_);
#else
  VISIT_TO(ObjectPtr, unoptimized_code_);
#endif

  NOT_IN_PRECOMPILED(TokenPosition token_pos_);
  NOT_IN_PRECOMPILED(TokenPosition end_token_pos_);
  uint32_t kind_tag_;  // See Function::KindTagBits.
  uint32_t packed_fields_;

  typedef BitField<uint32_t, bool, 0, 1> PackedHasNamedOptionalParameters;
  typedef BitField<uint32_t,
                   bool,
                   PackedHasNamedOptionalParameters::kNextBit,
                   1>
      OptimizableBit;
  typedef BitField<uint32_t, bool, OptimizableBit::kNextBit, 1>
      BackgroundOptimizableBit;
  typedef BitField<uint32_t,
                   uint16_t,
                   BackgroundOptimizableBit::kNextBit,
                   kMaxFixedParametersBits>
      PackedNumFixedParameters;
  typedef BitField<uint32_t,
                   uint16_t,
                   PackedNumFixedParameters::kNextBit,
                   kMaxOptionalParametersBits>
      PackedNumOptionalParameters;
  static_assert(PackedNumOptionalParameters::kNextBit <=
                    kBitsPerWord * sizeof(decltype(packed_fields_)),
                "FunctionLayout::packed_fields_ bitfields don't align.");

#define JIT_FUNCTION_COUNTERS(F)                                               \
  F(intptr_t, int32_t, usage_counter)                                          \
  F(intptr_t, uint16_t, optimized_instruction_count)                           \
  F(intptr_t, uint16_t, optimized_call_site_count)                             \
  F(int8_t, int8_t, deoptimization_counter)                                    \
  F(intptr_t, int8_t, state_bits)                                              \
  F(int, int8_t, inlining_depth)

#if !defined(DART_PRECOMPILED_RUNTIME)
  typedef BitField<uint32_t, bool, 0, 1> IsDeclaredInBytecode;
  typedef BitField<uint32_t, uint32_t, 1, 31> BinaryDeclarationOffset;
  uint32_t binary_declaration_;

#define DECLARE(return_type, type, name) type name##_;
  JIT_FUNCTION_COUNTERS(DECLARE)
#undef DECLARE

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  NOT_IN_PRECOMPILED(UnboxedParameterBitmap unboxed_parameters_info_);
};

class ClosureDataLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ClosureData);

  VISIT_FROM(ObjectPtr, context_scope_);
  ContextScopePtr context_scope_;
  FunctionPtr parent_function_;  // Enclosing function of this local function.
  TypePtr signature_type_;
  InstancePtr closure_;  // Closure object for static implicit closures.
  VISIT_TO(ObjectPtr, closure_);

  friend class Function;
};

class SignatureDataLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(SignatureData);

  VISIT_FROM(ObjectPtr, parent_function_);
  FunctionPtr parent_function_;  // Enclosing function of this sig. function.
  TypePtr signature_type_;
  VISIT_TO(ObjectPtr, signature_type_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class Function;
};

class RedirectionDataLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(RedirectionData);

  VISIT_FROM(ObjectPtr, type_);
  TypePtr type_;
  StringPtr identifier_;
  FunctionPtr target_;
  VISIT_TO(ObjectPtr, target_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class FfiTrampolineDataLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(FfiTrampolineData);

  VISIT_FROM(ObjectPtr, signature_type_);
  TypePtr signature_type_;
  FunctionPtr c_signature_;

  // Target Dart method for callbacks, otherwise null.
  FunctionPtr callback_target_;

  // For callbacks, value to return if Dart target throws an exception.
  InstancePtr callback_exceptional_return_;

  VISIT_TO(ObjectPtr, callback_exceptional_return_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Callback id for callbacks.
  //
  // The callbacks ids are used so that native callbacks can lookup their own
  // code objects, since native code doesn't pass code objects into function
  // calls. The callback id is also used to for verifying that callbacks are
  // called on the correct isolate. See DLRT_VerifyCallbackIsolate for details.
  //
  // Will be 0 for non-callbacks. Check 'callback_target_' to determine if this
  // is a callback or not.
  uint32_t callback_id_;
};

class FieldLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Field);

  VISIT_FROM(ObjectPtr, name_);
  StringPtr name_;
  ObjectPtr owner_;  // Class or patch class or mixin class
                     // where this field is defined or original field.
  AbstractTypePtr type_;
  FunctionPtr initializer_function_;  // Static initializer function.

  // - for instance fields: offset in words to the value in the class instance.
  // - for static fields: index into field_table.
  SmiPtr host_offset_or_field_id_;

  // When generating APPJIT snapshots after running the application it is
  // necessary to save the initial value of static fields so that we can
  // restore the value back to the original initial value.
  NOT_IN_PRECOMPILED(InstancePtr saved_initial_value_);  // Saved initial value
  SmiPtr guarded_list_length_;
  ArrayPtr dependent_code_;
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&initializer_function_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(ObjectPtr, dependent_code_);
#else
  SubtypeTestCachePtr type_test_cache_;  // For type test in implicit setter.
  VISIT_TO(ObjectPtr, type_test_cache_);
#endif
  TokenPosition token_pos_;
  TokenPosition end_token_pos_;
  uint16_t guarded_cid_;
  uint16_t is_nullable_;  // kNullCid if field can contain null value and
                          // kInvalidCid otherwise.

#if !defined(DART_PRECOMPILED_RUNTIME)
  typedef BitField<uint32_t, bool, 0, 1> IsDeclaredInBytecode;
  typedef BitField<uint32_t, uint32_t, 1, 31> BinaryDeclarationOffset;
  uint32_t binary_declaration_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Offset to the guarded length field inside an instance of class matching
  // guarded_cid_. Stored corrected by -kHeapObjectTag to simplify code
  // generated on platforms with weak addressing modes (ARM).
  int8_t guarded_list_length_in_object_offset_;

  // Runtime tracking state of exactness of type annotation of this field.
  // See StaticTypeExactnessState for the meaning and possible values in this
  // field.
  int8_t static_type_exactness_state_;

  uint16_t kind_bits_;  // static, final, const, has initializer....

#if !defined(DART_PRECOMPILED_RUNTIME)
  // for instance fields, the offset in words in the target architecture
  int32_t target_offset_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  friend class CidRewriteVisitor;
  friend class GuardFieldClassInstr;     // For sizeof(guarded_cid_/...)
  friend class LoadFieldInstr;           // For sizeof(guarded_cid_/...)
  friend class StoreInstanceFieldInstr;  // For sizeof(guarded_cid_/...)
};

class ScriptLayout : public ObjectLayout {
 public:
  enum {
    kLazyLookupSourceAndLineStartsPos = 0,
    kLazyLookupSourceAndLineStartsSize = 1,
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Script);

  VISIT_FROM(ObjectPtr, url_);
  StringPtr url_;
  StringPtr resolved_url_;
  ArrayPtr compile_time_constants_;
  TypedDataPtr line_starts_;
  ArrayPtr debug_positions_;
  KernelProgramInfoPtr kernel_program_info_;
  StringPtr source_;
  VISIT_TO(ObjectPtr, source_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&url_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&kernel_program_info_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  int32_t line_offset_;
  int32_t col_offset_;

  using LazyLookupSourceAndLineStartsBit =
      BitField<uint8_t,
               bool,
               kLazyLookupSourceAndLineStartsPos,
               kLazyLookupSourceAndLineStartsSize>;
  uint8_t flags_;

  intptr_t kernel_script_index_;
  int64_t load_timestamp_;
};

class LibraryLayout : public ObjectLayout {
  enum LibraryState {
    kAllocated,       // Initial state.
    kLoadRequested,   // Compiler or script requested load of library.
    kLoadInProgress,  // Library is in the process of being loaded.
    kLoaded,          // Library is loaded.
  };

  enum LibraryFlags {
    kDartSchemeBit = 0,
    kDebuggableBit,        // True if debugger can stop in library.
    kInFullSnapshotBit,    // True if library is in a full snapshot.
    kNnbdBit,              // True if library is non nullable by default.
    kNnbdCompiledModePos,  // Encodes nnbd compiled mode of constants in lib.
    kNnbdCompiledModeSize = 2,
    kNumFlagBits = kNnbdCompiledModePos + kNnbdCompiledModeSize,
  };
  COMPILE_ASSERT(kNumFlagBits <= (sizeof(uint8_t) * kBitsPerByte));
  class DartSchemeBit : public BitField<uint8_t, bool, kDartSchemeBit, 1> {};
  class DebuggableBit : public BitField<uint8_t, bool, kDebuggableBit, 1> {};
  class InFullSnapshotBit
      : public BitField<uint8_t, bool, kInFullSnapshotBit, 1> {};
  class NnbdBit : public BitField<uint8_t, bool, kNnbdBit, 1> {};
  class NnbdCompiledModeBits : public BitField<uint8_t,
                                               uint8_t,
                                               kNnbdCompiledModePos,
                                               kNnbdCompiledModeSize> {};

  RAW_HEAP_OBJECT_IMPLEMENTATION(Library);

  VISIT_FROM(ObjectPtr, name_);
  StringPtr name_;
  StringPtr url_;
  StringPtr private_key_;
  ArrayPtr dictionary_;              // Top-level names in this library.
  GrowableObjectArrayPtr metadata_;  // Metadata on classes, methods etc.
  ClassPtr toplevel_class_;          // Class containing top-level elements.
  GrowableObjectArrayPtr used_scripts_;
  LoadingUnitPtr loading_unit_;
  ArrayPtr imports_;  // List of Namespaces imported without prefix.
  ArrayPtr exports_;  // List of re-exported Namespaces.
  ArrayPtr dependencies_;
  ExternalTypedDataPtr kernel_data_;
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&exports_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&kernel_data_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  ArrayPtr resolved_names_;  // Cache of resolved names in library scope.
  ArrayPtr exported_names_;  // Cache of exported names by library.
  ArrayPtr loaded_scripts_;  // Array of scripts loaded in this library.
  VISIT_TO(ObjectPtr, loaded_scripts_);

  Dart_NativeEntryResolver native_entry_resolver_;  // Resolves natives.
  Dart_NativeEntrySymbol native_entry_symbol_resolver_;
  classid_t index_;       // Library id number.
  uint16_t num_imports_;  // Number of entries in imports_.
  int8_t load_state_;     // Of type LibraryState.
  uint8_t flags_;         // BitField for LibraryFlags.

#if !defined(DART_PRECOMPILED_RUNTIME)
  typedef BitField<uint32_t, bool, 0, 1> IsDeclaredInBytecode;
  typedef BitField<uint32_t, uint32_t, 1, 31> BinaryDeclarationOffset;
  uint32_t binary_declaration_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  friend class Class;
  friend class Isolate;
};

class NamespaceLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Namespace);

  VISIT_FROM(ObjectPtr, library_);
  LibraryPtr library_;       // library with name dictionary.
  ArrayPtr show_names_;      // list of names that are exported.
  ArrayPtr hide_names_;      // list of names that are hidden.
  FieldPtr metadata_field_;  // remembers the token pos of metadata if any,
                             // and the metadata values if computed.
  VISIT_TO(ObjectPtr, metadata_field_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class KernelProgramInfoLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(KernelProgramInfo);

  VISIT_FROM(ObjectPtr, string_offsets_);
  TypedDataPtr string_offsets_;
  ExternalTypedDataPtr string_data_;
  TypedDataPtr canonical_names_;
  ExternalTypedDataPtr metadata_payloads_;
  ExternalTypedDataPtr metadata_mappings_;
  ArrayPtr scripts_;
  ArrayPtr constants_;
  ArrayPtr bytecode_component_;
  GrowableObjectArrayPtr potential_natives_;
  GrowableObjectArrayPtr potential_pragma_functions_;
  ExternalTypedDataPtr constants_table_;
  ArrayPtr libraries_cache_;
  ArrayPtr classes_cache_;
  ObjectPtr retained_kernel_blob_;
  VISIT_TO(ObjectPtr, retained_kernel_blob_);

  uint32_t kernel_binary_version_;

  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    return reinterpret_cast<ObjectPtr*>(&constants_table_);
  }
};

class WeakSerializationReferenceLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakSerializationReference);

#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_NOTHING();
  uint16_t cid_;
#else
  VISIT_FROM(ObjectPtr, target_);
  ObjectPtr target_;
  VISIT_TO(ObjectPtr, target_);
#endif
};

class CodeLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Code);

  // When in the precompiled runtime, there is no disabling of Code objects
  // and thus no active_instructions_ field. Thus, the entry point caches are
  // only set once during deserialization. If not using bare instructions,
  // the caches should match the entry points for instructions_.
  //
  // Otherwise, they should contain entry points for active_instructions_.

  uword entry_point_;  // Accessed from generated code.

  // In AOT this entry-point supports switchable calls. It checks the type of
  // the receiver on entry to the function and calls a stub to patch up the
  // caller if they mismatch.
  uword monomorphic_entry_point_;  // Accessed from generated code (AOT only).

  // Entry-point used from call-sites with some additional static information.
  // The exact behavior of this entry-point depends on the kind of function:
  //
  // kRegularFunction/kSetter/kGetter:
  //
  //   Call-site is assumed to know that the (type) arguments are invariantly
  //   type-correct against the actual runtime-type of the receiver. For
  //   instance, this entry-point is used for invocations against "this" and
  //   invocations from IC stubs that test the class type arguments.
  //
  // kClosureFunction:
  //
  //   Call-site is assumed to pass the correct number of positional and type
  //   arguments (except in the case of partial instantiation, when the type
  //   arguments are omitted). All (type) arguments are assumed to match the
  //   corresponding (type) parameter types (bounds).
  //
  // kImplicitClosureFunction:
  //
  //   Similar to kClosureFunction, except that the types (bounds) of the (type)
  //   arguments are expected to match the *runtime signature* of the closure,
  //   which (unlike with kClosureFunction) may have more general (type)
  //   parameter types (bounds) than the declared type of the forwarded method.
  //
  // In many cases a distinct static entry-point will not be created for a
  // function if it would not be able to skip a lot of work (e.g., no argument
  // type checks are necessary or this Code belongs to a stub). In this case
  // 'unchecked_entry_point_' will refer to the same position as 'entry_point_'.
  //
  uword unchecked_entry_point_;              // Accessed from generated code.
  uword monomorphic_unchecked_entry_point_;  // Accessed from generated code.

  VISIT_FROM(ObjectPtr, object_pool_);
  ObjectPoolPtr object_pool_;     // Accessed from generated code.
  InstructionsPtr instructions_;  // Accessed from generated code.
  // If owner_ is Function::null() the owner is a regular stub.
  // If owner_ is a Class the owner is the allocation stub for that class.
  // Else, owner_ is a regular Dart Function.
  ObjectPtr owner_;  // Function, Null, or a Class.
  ExceptionHandlersPtr exception_handlers_;
  PcDescriptorsPtr pc_descriptors_;
  // If FLAG_precompiled_mode, then this field contains
  //   TypedDataPtr catch_entry_moves_maps
  // Otherwise, it is
  //   SmiPtr num_variables
  ObjectPtr catch_entry_;
  CompressedStackMapsPtr compressed_stackmaps_;
  ArrayPtr inlined_id_to_function_;
  CodeSourceMapPtr code_source_map_;
  NOT_IN_PRECOMPILED(InstructionsPtr active_instructions_);
  NOT_IN_PRECOMPILED(ArrayPtr deopt_info_array_);
  // (code-offset, function, code) triples.
  NOT_IN_PRECOMPILED(ArrayPtr static_calls_target_table_);
  // If return_address_metadata_ is a Smi, it is the offset to the prologue.
  // Else, return_address_metadata_ is null.
  NOT_IN_PRODUCT(ObjectPtr return_address_metadata_);
  NOT_IN_PRODUCT(LocalVarDescriptorsPtr var_descriptors_);
  NOT_IN_PRODUCT(ArrayPtr comments_);

#if !defined(PRODUCT)
  VISIT_TO(ObjectPtr, comments_);
#elif defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(ObjectPtr, code_source_map_);
#else
  VISIT_TO(ObjectPtr, static_calls_target_table_);
#endif

  // Compilation timestamp.
  NOT_IN_PRODUCT(alignas(8) int64_t compile_timestamp_);

  // state_bits_ is a bitfield with three fields:
  // The optimized bit, the alive bit, and a count of the number of pointer
  // offsets.
  // Alive: If true, the embedded object pointers will be visited during GC.
  int32_t state_bits_;
  // Caches the unchecked entry point offset for instructions_, in case we need
  // to reset the active_instructions_ to instructions_.
  NOT_IN_PRECOMPILED(uint32_t unchecked_offset_);
  // Stores the instructions length when not using RawInstructions objects.
  ONLY_IN_PRECOMPILED(uint32_t instructions_length_);

  // Variable length data follows here.
  int32_t* data() { OPEN_ARRAY_START(int32_t, int32_t); }
  const int32_t* data() const { OPEN_ARRAY_START(int32_t, int32_t); }

  static bool ContainsPC(const ObjectPtr raw_obj, uword pc);

  friend class Function;
  template <bool>
  friend class MarkingVisitorBase;
  friend class StackFrame;
  friend class Profiler;
  friend class FunctionDeserializationCluster;
  friend class CallSiteResetter;
};

class BytecodeLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bytecode);

  uword instructions_;
  intptr_t instructions_size_;

  VISIT_FROM(ObjectPtr, object_pool_);
  ObjectPoolPtr object_pool_;
  FunctionPtr function_;
  ArrayPtr closures_;
  ExceptionHandlersPtr exception_handlers_;
  PcDescriptorsPtr pc_descriptors_;
  NOT_IN_PRODUCT(LocalVarDescriptorsPtr var_descriptors_);
#if defined(PRODUCT)
  VISIT_TO(ObjectPtr, pc_descriptors_);
#else
  VISIT_TO(ObjectPtr, var_descriptors_);
#endif

  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    return reinterpret_cast<ObjectPtr*>(&pc_descriptors_);
  }

  int32_t instructions_binary_offset_;
  int32_t source_positions_binary_offset_;
  int32_t local_variables_binary_offset_;

  static bool ContainsPC(ObjectPtr raw_obj, uword pc);

  friend class Function;
  friend class StackFrame;
};

class ObjectPoolLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ObjectPool);

  intptr_t length_;

  struct Entry {
    union {
      ObjectPtr raw_obj_;
      uword raw_value_;
    };
  };
  Entry* data() { OPEN_ARRAY_START(Entry, Entry); }
  Entry const* data() const { OPEN_ARRAY_START(Entry, Entry); }

  // The entry bits are located after the last entry. They are encoded versions
  // of `ObjectPool::TypeBits() | ObjectPool::PatchabililtyBit()`.
  uint8_t* entry_bits() { return reinterpret_cast<uint8_t*>(&data()[length_]); }
  uint8_t const* entry_bits() const {
    return reinterpret_cast<uint8_t const*>(&data()[length_]);
  }

  friend class Object;
  friend class CodeSerializationCluster;
};

class InstructionsLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instructions);
  VISIT_NOTHING();

  // Instructions size in bytes and flags.
  // Currently, only flag indicates 1 or 2 entry points.
  uint32_t size_and_flags_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  // Private helper function used while visiting stack frames. The
  // code which iterates over dart frames is also called during GC and
  // is not allowed to create handles.
  static bool ContainsPC(const InstructionsPtr raw_instr, uword pc);

  friend class CodeLayout;
  friend class FunctionLayout;
  friend class Code;
  friend class StackFrame;
  template <bool>
  friend class MarkingVisitorBase;
  friend class Function;
  friend class ImageReader;
  friend class ImageWriter;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
};

// Used only to provide memory accounting for the bare instruction payloads
// we serialize, since they are no longer part of RawInstructions objects.
class InstructionsSectionLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(InstructionsSection);
  VISIT_NOTHING();

  // Instructions section payload length in bytes.
  uword payload_length_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
};

class PcDescriptorsLayout : public ObjectLayout {
 public:
// The macro argument V is passed two arguments, the raw name of the enum value
// and the initialization expression used within the enum definition.  The uses
// of enum values inside the initialization expression are hardcoded currently,
// so the second argument is useless outside the enum definition and should be
// dropped by other users of this macro.
#define FOR_EACH_RAW_PC_DESCRIPTOR(V)                                          \
  /* Deoptimization continuation point. */                                     \
  V(Deopt, 1)                                                                  \
  /* IC call. */                                                               \
  V(IcCall, kDeopt << 1)                                                       \
  /* Call to a known target via stub. */                                       \
  V(UnoptStaticCall, kIcCall << 1)                                             \
  /* Runtime call. */                                                          \
  V(RuntimeCall, kUnoptStaticCall << 1)                                        \
  /* OSR entry point in unopt. code. */                                        \
  V(OsrEntry, kRuntimeCall << 1)                                               \
  /* Call rewind target address. */                                            \
  V(Rewind, kOsrEntry << 1)                                                    \
  /* Target-word-size relocation. */                                           \
  V(BSSRelocation, kRewind << 1)                                               \
  V(Other, kBSSRelocation << 1)                                                \
  V(AnyKind, -1)

  enum Kind {
#define ENUM_DEF(name, init) k##name = init,
    FOR_EACH_RAW_PC_DESCRIPTOR(ENUM_DEF)
#undef ENUM_DEF
        kLastKind = kOther,
  };

  static const char* KindToCString(Kind k);
  static bool ParseKind(const char* cstr, Kind* out);

  // Used to represent the absense of a yield index in PcDescriptors.
  static constexpr intptr_t kInvalidYieldIndex = -1;

  class KindAndMetadata {
   public:
    // Most of the time try_index will be small and merged field will fit into
    // one byte.
    static uint32_t Encode(intptr_t kind,
                           intptr_t try_index,
                           intptr_t yield_index) {
      return KindShiftBits::encode(Utils::ShiftForPowerOfTwo(kind)) |
             TryIndexBits::encode(try_index + 1) |
             YieldIndexBits::encode(yield_index + 1);
    }

    static intptr_t DecodeKind(uint32_t kind_and_metadata) {
      return 1 << KindShiftBits::decode(kind_and_metadata);
    }

    static intptr_t DecodeTryIndex(uint32_t kind_and_metadata) {
      return TryIndexBits::decode(kind_and_metadata) - 1;
    }

    static intptr_t DecodeYieldIndex(uint32_t kind_and_metadata) {
      return YieldIndexBits::decode(kind_and_metadata) - 1;
    }

   private:
    static const intptr_t kKindShiftSize = 3;
    static const intptr_t kTryIndexSize = 10;
    static const intptr_t kYieldIndexSize = 32 - kKindShiftSize - kTryIndexSize;

    class KindShiftBits
        : public BitField<uint32_t, intptr_t, 0, kKindShiftSize> {};
    class TryIndexBits : public BitField<uint32_t,
                                         intptr_t,
                                         KindShiftBits::kNextBit,
                                         kTryIndexSize> {};
    class YieldIndexBits : public BitField<uint32_t,
                                           intptr_t,
                                           TryIndexBits::kNextBit,
                                           kYieldIndexSize> {};
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PcDescriptors);
  VISIT_NOTHING();

  // Number of descriptors.  This only needs to be an int32_t, but we make it a
  // uword so that the variable length data is 64 bit aligned on 64 bit
  // platforms.
  uword length_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, intptr_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, intptr_t); }

  friend class Object;
  friend class ImageWriter;
};

// CodeSourceMap encodes a mapping from code PC ranges to source token
// positions and the stack of inlined functions.
class CodeSourceMapLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(CodeSourceMap);
  VISIT_NOTHING();

  // Length in bytes.  This only needs to be an int32_t, but we make it a uword
  // so that the variable length data is 64 bit aligned on 64 bit platforms.
  uword length_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, intptr_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, intptr_t); }

  friend class Object;
  friend class ImageWriter;
};

// RawCompressedStackMaps is a compressed representation of the stack maps
// for certain PC offsets into a set of instructions, where a stack map is a bit
// map that marks each live object index starting from the base of the frame.
class CompressedStackMapsLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(CompressedStackMaps);
  VISIT_NOTHING();

  // The most significant bits are the length of the encoded payload, in bytes.
  // The low bits determine the expected payload contents, as described below.
  uint32_t flags_and_size_;

  // Variable length data follows here. The contents of the payload depend on
  // the type of CompressedStackMaps (CSM) being represented. There are three
  // major types of CSM:
  //
  // 1) GlobalTableBit = false, UsesTableBit = false: CSMs that include all
  //    information about the stack maps. The payload for these contain tightly
  //    packed entries with the following information:
  //
  //   * A header containing the following three pieces of information:
  //     * An unsigned integer representing the PC offset as a delta from the
  //       PC offset of the previous entry (from 0 for the first entry).
  //     * An unsigned integer representing the number of bits used for
  //       spill slot entries.
  //     * An unsigned integer representing the number of bits used for other
  //       entries.
  //   * The body containing the bits for the stack map. The length of the body
  //     in bits is the sum of the spill slot and non-spill slot bit counts.
  //
  // 2) GlobalTableBit = false, UsesTableBit = true: CSMs where the majority of
  //    the stack map information has been offloaded and canonicalized into a
  //    global table. The payload contains tightly packed entries with the
  //    following information:
  //
  //   * A header containing just an unsigned integer representing the PC offset
  //     delta as described above.
  //   * The body is just an unsigned integer containing the offset into the
  //     payload for the global table.
  //
  // 3) GlobalTableBit = true, UsesTableBit = false: A CSM implementing the
  //    global table. Here, the payload contains tightly packed entries with
  //    the following information:
  //
  //   * A header containing the following two pieces of information:
  //     * An unsigned integer representing the number of bits used for
  //       spill slot entries.
  //     * An unsigned integer representing the number of bits used for other
  //       entries.
  //   * The body containing the bits for the stack map. The length of the body
  //     in bits is the sum of the spill slot and non-spill slot bit counts.
  //
  // In all types of CSM, each unsigned integer is LEB128 encoded, as generally
  // they tend to fit in a single byte or two. Thus, entry headers are not a
  // fixed length, and currently there is no random access of entries.  In
  // addition, PC offsets are currently encoded as deltas, which also inhibits
  // random access without accessing previous entries. That means to find an
  // entry for a given PC offset, a linear search must be done where the payload
  // is decoded up to the entry whose PC offset is >= the given PC.

  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }

  class GlobalTableBit : public BitField<uint32_t, bool, 0, 1> {};
  class UsesTableBit
      : public BitField<uint32_t, bool, GlobalTableBit::kNextBit, 1> {};
  class SizeField : public BitField<uint32_t,
                                    uint32_t,
                                    UsesTableBit::kNextBit,
                                    sizeof(flags_and_size_) * kBitsPerByte -
                                        UsesTableBit::kNextBit> {};

  friend class ImageWriter;
};

class LocalVarDescriptorsLayout : public ObjectLayout {
 public:
  enum VarInfoKind {
    kStackVar = 1,
    kContextVar,
    kContextLevel,
    kSavedCurrentContext,
  };

  enum {
    kKindPos = 0,
    kKindSize = 8,
    kIndexPos = kKindPos + kKindSize,
    // Since there are 24 bits for the stack slot index, Functions can have
    // only ~16.7 million stack slots.
    kPayloadSize = sizeof(int32_t) * kBitsPerByte,
    kIndexSize = kPayloadSize - kIndexPos,
    kIndexBias = 1 << (kIndexSize - 1),
    kMaxIndex = (1 << (kIndexSize - 1)) - 1,
  };

  class IndexBits : public BitField<int32_t, int32_t, kIndexPos, kIndexSize> {};
  class KindBits : public BitField<int32_t, int8_t, kKindPos, kKindSize> {};

  struct VarInfo {
    int32_t index_kind;  // Bitfield for slot index on stack or in context,
                         // and Entry kind of type VarInfoKind.
    TokenPosition declaration_pos;  // Token position of declaration.
    TokenPosition begin_pos;        // Token position of scope start.
    TokenPosition end_pos;          // Token position of scope end.
    int16_t scope_id;               // Scope to which the variable belongs.

    VarInfoKind kind() const {
      return static_cast<VarInfoKind>(KindBits::decode(index_kind));
    }
    void set_kind(VarInfoKind kind) {
      index_kind = KindBits::update(kind, index_kind);
    }
    int32_t index() const { return IndexBits::decode(index_kind) - kIndexBias; }
    void set_index(int32_t index) {
      index_kind = IndexBits::update(index + kIndexBias, index_kind);
    }
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(LocalVarDescriptors);
  // Number of descriptors. This only needs to be an int32_t, but we make it a
  // uword so that the variable length data is 64 bit aligned on 64 bit
  // platforms.
  uword num_entries_;

  VISIT_FROM(ObjectPtr, names()[0]);
  StringPtr* names() {
    // Array of [num_entries_] variable names.
    OPEN_ARRAY_START(StringPtr, StringPtr);
  }
  StringPtr* nameAddrAt(intptr_t i) { return &(names()[i]); }
  VISIT_TO_LENGTH(ObjectPtr, nameAddrAt(length - 1));

  // Variable info with [num_entries_] entries.
  VarInfo* data() {
    return reinterpret_cast<VarInfo*>(nameAddrAt(num_entries_));
  }

  friend class Object;
};

class ExceptionHandlersLayout : public ObjectLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers);

  // Number of exception handler entries.
  int32_t num_entries_;

  // Array with [num_entries_] entries. Each entry is an array of all handled
  // exception types.
  VISIT_FROM(ObjectPtr, handled_types_data_)
  ArrayPtr handled_types_data_;
  VISIT_TO_LENGTH(ObjectPtr, &handled_types_data_);

  // Exception handler info of length [num_entries_].
  const ExceptionHandlerInfo* data() const {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }
  ExceptionHandlerInfo* data() {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }

  friend class Object;
};

class ContextLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Context);

  int32_t num_variables_;

  VISIT_FROM(ObjectPtr, parent_);
  ContextPtr parent_;

  // Variable length data follows here.
  ObjectPtr* data() { OPEN_ARRAY_START(ObjectPtr, ObjectPtr); }
  ObjectPtr const* data() const { OPEN_ARRAY_START(ObjectPtr, ObjectPtr); }
  VISIT_TO_LENGTH(ObjectPtr, &data()[length - 1]);

  friend class Object;
  friend class SnapshotReader;
};

class ContextScopeLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ContextScope);

  // TODO(iposva): Switch to conventional enum offset based structure to avoid
  // alignment mishaps.
  struct VariableDesc {
    SmiPtr declaration_token_pos;
    SmiPtr token_pos;
    StringPtr name;
    SmiPtr flags;
    static constexpr intptr_t kIsFinal = 0x1;
    static constexpr intptr_t kIsConst = 0x2;
    static constexpr intptr_t kIsLate = 0x4;
    SmiPtr late_init_offset;
    union {
      AbstractTypePtr type;
      InstancePtr value;  // iff is_const is true
    };
    SmiPtr context_index;
    SmiPtr context_level;
  };

  int32_t num_variables_;
  bool is_implicit_;  // true, if this context scope is for an implicit closure.

  ObjectPtr* from() {
    VariableDesc* begin = const_cast<VariableDesc*>(VariableDescAddr(0));
    return reinterpret_cast<ObjectPtr*>(begin);
  }
  // Variable length data follows here.
  ObjectPtr const* data() const { OPEN_ARRAY_START(ObjectPtr, ObjectPtr); }
  const VariableDesc* VariableDescAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables_ + 1));
    // data() points to the first component of the first descriptor.
    return &(reinterpret_cast<const VariableDesc*>(data())[index]);
  }
  ObjectPtr* to(intptr_t num_vars) {
    uword end = reinterpret_cast<uword>(VariableDescAddr(num_vars));
    // 'end' is the address just beyond the last descriptor, so step back.
    return reinterpret_cast<ObjectPtr*>(end - kWordSize);
  }
  ObjectPtr* to_snapshot(Snapshot::Kind kind, intptr_t num_vars) {
    return to(num_vars);
  }

  friend class Object;
  friend class ClosureDataLayout;
  friend class SnapshotReader;
};

class ParameterTypeCheckLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ParameterTypeCheck);
  intptr_t index_;
  VISIT_FROM(ObjectPtr, param_);
  AbstractTypePtr param_;
  AbstractTypePtr type_or_bound_;
  StringPtr name_;
  SubtypeTestCachePtr cache_;
  VISIT_TO(ObjectPtr, cache_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class SingleTargetCacheLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache);
  VISIT_FROM(ObjectPtr, target_);
  CodePtr target_;
  VISIT_TO(ObjectPtr, target_);
  uword entry_point_;
  uint16_t lower_limit_;
  uint16_t upper_limit_;
};

class MonomorphicSmiableCallLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MonomorphicSmiableCall);
  VISIT_FROM(ObjectPtr, target_);
  CodePtr target_;  // Entrypoint PC in bare mode, Code in non-bare mode.
  VISIT_TO(ObjectPtr, target_);
  uword expected_cid_;
  uword entrypoint_;
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

// Abstract base class for RawICData/RawMegamorphicCache
class CallSiteDataLayout : public ObjectLayout {
 protected:
  StringPtr target_name_;  // Name of target function.
  // arg_descriptor in RawICData and in RawMegamorphicCache should be
  // in the same position so that NoSuchMethod can access it.
  ArrayPtr args_descriptor_;  // Arguments descriptor.
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(CallSiteData)
};

class UnlinkedCallLayout : public CallSiteDataLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnlinkedCall);
  VISIT_FROM(ObjectPtr, target_name_);
  VISIT_TO(ObjectPtr, args_descriptor_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  bool can_patch_to_monomorphic_;
};

class ICDataLayout : public CallSiteDataLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ICData);
  VISIT_FROM(ObjectPtr, target_name_);
  ArrayPtr entries_;  // Contains class-ids, target and count.
  // Static type of the receiver, if instance call and available.
  NOT_IN_PRECOMPILED(AbstractTypePtr receivers_static_type_);
  ObjectPtr owner_;  // Parent/calling function or original IC of cloned IC.
  VISIT_TO(ObjectPtr, owner_);
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&entries_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return to();
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  NOT_IN_PRECOMPILED(int32_t deopt_id_);
  uint32_t state_bits_;  // Number of arguments tested in IC, deopt reasons.
};

class MegamorphicCacheLayout : public CallSiteDataLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache);
  VISIT_FROM(ObjectPtr, target_name_)
  ArrayPtr buckets_;
  SmiPtr mask_;
  VISIT_TO(ObjectPtr, mask_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  int32_t filled_entry_count_;
};

class SubtypeTestCacheLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache);
  VISIT_FROM(ObjectPtr, cache_);
  ArrayPtr cache_;
  VISIT_TO(ObjectPtr, cache_);
};

class LoadingUnitLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LoadingUnit);
  VISIT_FROM(ObjectPtr, parent_);
  LoadingUnitPtr parent_;
  ArrayPtr base_objects_;
  VISIT_TO(ObjectPtr, base_objects_);
  int32_t id_;
  bool load_issued_;
  bool loaded_;
};

class ErrorLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Error);
};

class ApiErrorLayout : public ErrorLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ApiError);

  VISIT_FROM(ObjectPtr, message_)
  StringPtr message_;
  VISIT_TO(ObjectPtr, message_)
};

class LanguageErrorLayout : public ErrorLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LanguageError);

  VISIT_FROM(ObjectPtr, previous_error_)
  ErrorPtr previous_error_;  // May be null.
  ScriptPtr script_;
  StringPtr message_;
  StringPtr formatted_message_;  // Incl. previous error's formatted message.
  VISIT_TO(ObjectPtr, formatted_message_)
  TokenPosition token_pos_;  // Source position in script_.
  bool report_after_token_;  // Report message at or after the token.
  int8_t kind_;              // Of type Report::Kind.

  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class UnhandledExceptionLayout : public ErrorLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnhandledException);

  VISIT_FROM(ObjectPtr, exception_)
  InstancePtr exception_;
  InstancePtr stacktrace_;
  VISIT_TO(ObjectPtr, stacktrace_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class UnwindErrorLayout : public ErrorLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnwindError);

  VISIT_FROM(ObjectPtr, message_)
  StringPtr message_;
  VISIT_TO(ObjectPtr, message_)
  bool is_user_initiated_;
};

class InstanceLayout : public ObjectLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instance);
};

class LibraryPrefixLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix);

  VISIT_FROM(ObjectPtr, name_)
  StringPtr name_;       // Library prefix name.
  LibraryPtr importer_;  // Library which declares this prefix.
  ArrayPtr imports_;     // Libraries imported with this prefix.
  VISIT_TO(ObjectPtr, imports_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<ObjectPtr*>(&imports_);
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&importer_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  uint16_t num_imports_;  // Number of library entries in libraries_.
  bool is_deferred_load_;
  bool is_loaded_;
};

class TypeArgumentsLayout : public InstanceLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeArguments);

  VISIT_FROM(ObjectPtr, instantiations_)
  // The instantiations_ array remains empty for instantiated type arguments.
  ArrayPtr instantiations_;  // Of 3-tuple: 2 instantiators, result.
  SmiPtr length_;
  SmiPtr hash_;
  SmiPtr nullability_;

  // Variable length data follows here.
  AbstractTypePtr const* types() const {
    OPEN_ARRAY_START(AbstractTypePtr, AbstractTypePtr);
  }
  AbstractTypePtr* types() {
    OPEN_ARRAY_START(AbstractTypePtr, AbstractTypePtr);
  }
  ObjectPtr* to(intptr_t length) {
    return reinterpret_cast<ObjectPtr*>(&types()[length - 1]);
  }

  friend class Object;
  friend class SnapshotReader;
};

class AbstractTypeLayout : public InstanceLayout {
 public:
  enum TypeState {
    kAllocated,                // Initial state.
    kBeingFinalized,           // In the process of being finalized.
    kFinalizedInstantiated,    // Instantiated type ready for use.
    kFinalizedUninstantiated,  // Uninstantiated type ready for use.
  };

 protected:
  uword type_test_stub_entry_point_;  // Accessed from generated code.
  CodePtr type_test_stub_;  // Must be the last field, since subclasses use it
                            // in their VISIT_FROM.

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(AbstractType);

  friend class ObjectStore;
  friend class StubCode;
};

class TypeLayout : public AbstractTypeLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Type);

  VISIT_FROM(ObjectPtr, type_test_stub_)
  SmiPtr type_class_id_;
  TypeArgumentsPtr arguments_;
  SmiPtr hash_;
  // This type object represents a function type if its signature field is a
  // non-null function object.
  FunctionPtr signature_;  // If not null, this type is a function type.
  VISIT_TO(ObjectPtr, signature_)
  TokenPosition token_pos_;
  int8_t type_state_;
  int8_t nullability_;

  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class CidRewriteVisitor;
  friend class TypeArgumentsLayout;
};

class TypeRefLayout : public AbstractTypeLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeRef);

  VISIT_FROM(ObjectPtr, type_test_stub_)
  AbstractTypePtr type_;  // The referenced type.
  VISIT_TO(ObjectPtr, type_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class TypeParameterLayout : public AbstractTypeLayout {
 public:
  enum {
    kFinalizedBit = 0,
    kGenericCovariantImplBit,
    kDeclarationBit,
  };
  class FinalizedBit : public BitField<uint8_t, bool, kFinalizedBit, 1> {};
  class GenericCovariantImplBit
      : public BitField<uint8_t, bool, kGenericCovariantImplBit, 1> {};
  class DeclarationBit : public BitField<uint8_t, bool, kDeclarationBit, 1> {};

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameter);

  VISIT_FROM(ObjectPtr, type_test_stub_)
  StringPtr name_;
  SmiPtr hash_;
  AbstractTypePtr bound_;  // ObjectType if no explicit bound specified.
  FunctionPtr parameterized_function_;
  VISIT_TO(ObjectPtr, parameterized_function_)
  uint16_t parameterized_class_id_;
  TokenPosition token_pos_;
  int16_t index_;
  uint8_t flags_;
  int8_t nullability_;

  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class CidRewriteVisitor;
};

class ClosureLayout : public InstanceLayout {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Closure);

  // No instance fields should be declared before the following fields whose
  // offsets must be identical in Dart and C++.

  // The following fields are also declared in the Dart source of class
  // _Closure.
  VISIT_FROM(RawCompressed, instantiator_type_arguments_)
  TypeArgumentsPtr instantiator_type_arguments_;
  TypeArgumentsPtr function_type_arguments_;
  TypeArgumentsPtr delayed_type_arguments_;
  FunctionPtr function_;
  ContextPtr context_;
  SmiPtr hash_;

  VISIT_TO(RawCompressed, hash_)

  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Note that instantiator_type_arguments_, function_type_arguments_ and
  // delayed_type_arguments_ are used to instantiate the signature of function_
  // when this closure is involved in a type test. In other words, these fields
  // define the function type of this closure instance.
  //
  // function_type_arguments_ and delayed_type_arguments_ may also be used when
  // invoking the closure. Whereas the source frontend will save a copy of the
  // function's type arguments in the closure's context and only use the
  // function_type_arguments_ field for type tests, the kernel frontend will use
  // the function_type_arguments_ vector here directly.
  //
  // If this closure is generic, it can be invoked with function type arguments
  // that will be processed in the prolog of the closure function_. For example,
  // if the generic closure function_ has a generic parent function, the
  // passed-in function type arguments get concatenated to the function type
  // arguments of the parent that are found in the context_.
  //
  // delayed_type_arguments_ is used to support the partial instantiation
  // feature. When this field is set to any value other than
  // Object::empty_type_arguments(), the types in this vector will be passed as
  // type arguments to the closure when invoked. In this case there may not be
  // any type arguments passed directly (or NSM will be invoked instead).
};

class NumberLayout : public InstanceLayout {
  RAW_OBJECT_IMPLEMENTATION(Number);
};

class IntegerLayout : public NumberLayout {
  RAW_OBJECT_IMPLEMENTATION(Integer);
};

class SmiLayout : public IntegerLayout {
  RAW_OBJECT_IMPLEMENTATION(Smi);
};

class MintLayout : public IntegerLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Mint);
  VISIT_NOTHING();

  ALIGN8 int64_t value_;

  friend class Api;
  friend class Class;
  friend class Integer;
  friend class SnapshotReader;
};
COMPILE_ASSERT(sizeof(MintLayout) == 16);

class DoubleLayout : public NumberLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Double);
  VISIT_NOTHING();

  ALIGN8 double value_;

  friend class Api;
  friend class SnapshotReader;
  friend class Class;
};
COMPILE_ASSERT(sizeof(DoubleLayout) == 16);

class StringLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(String);

 protected:
  VISIT_FROM(ObjectPtr, length_)
  SmiPtr length_;
#if !defined(HASH_IN_OBJECT_HEADER)
  SmiPtr hash_;
  VISIT_TO(ObjectPtr, hash_)
#else
  VISIT_TO(ObjectPtr, length_)
#endif

 private:
  friend class Library;
  friend class OneByteStringSerializationCluster;
  friend class TwoByteStringSerializationCluster;
  friend class OneByteStringDeserializationCluster;
  friend class TwoByteStringDeserializationCluster;
  friend class RODataSerializationCluster;
  friend class ImageWriter;
};

class OneByteStringLayout : public StringLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(OneByteString);
  VISIT_NOTHING();

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class ApiMessageReader;
  friend class RODataSerializationCluster;
  friend class SnapshotReader;
  friend class String;
};

class TwoByteStringLayout : public StringLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TwoByteString);
  VISIT_NOTHING();

  // Variable length data follows here.
  uint16_t* data() { OPEN_ARRAY_START(uint16_t, uint16_t); }
  const uint16_t* data() const { OPEN_ARRAY_START(uint16_t, uint16_t); }

  friend class RODataSerializationCluster;
  friend class SnapshotReader;
  friend class String;
};

// Abstract base class for RawTypedData/RawExternalTypedData/RawTypedDataView/
// Pointer.
//
// TypedData extends this with a length field, while Pointer extends this with
// TypeArguments field.
class PointerBaseLayout : public InstanceLayout {
 protected:
  // The contents of [data_] depends on what concrete subclass is used:
  //
  //  - RawTypedData: Start of the payload.
  //  - RawExternalTypedData: Start of the C-heap payload.
  //  - RawTypedDataView: The [data_] field of the backing store for the view
  //    plus the [offset_in_bytes_] the view has.
  //  - RawPointer: Pointer into C memory (no length specified).
  //
  // During allocation or snapshot reading the [data_] can be temporarily
  // nullptr (which is the case for views which just got created but haven't
  // gotten the backing store set).
  uint8_t* data_;

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PointerBase);
};

// Abstract base class for RawTypedData/RawExternalTypedData/RawTypedDataView.
class TypedDataBaseLayout : public PointerBaseLayout {
 protected:
  // The length of the view in element sizes (obtainable via
  // [TypedDataBase::ElementSizeInBytes]).
  SmiPtr length_;

 private:
  friend class TypedDataViewLayout;
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedDataBase);
};

class TypedDataLayout : public TypedDataBaseLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedData);

 public:
  static intptr_t payload_offset() {
    return OFFSET_OF_RETURNED_VALUE(TypedDataLayout, internal_data);
  }

  // Recompute [data_] pointer to internal data.
  void RecomputeDataField() { data_ = internal_data(); }

 protected:
  VISIT_FROM(RawCompressed, length_)
  VISIT_TO_LENGTH(RawCompressed, &length_)

  // Variable length data follows here.

  uint8_t* internal_data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* internal_data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }

  uint8_t* data() {
    ASSERT(data_ == internal_data());
    return data_;
  }
  const uint8_t* data() const {
    ASSERT(data_ == internal_data());
    return data_;
  }

  friend class Api;
  friend class Instance;
  friend class NativeEntryData;
  friend class Object;
  friend class ObjectPool;
  friend class ObjectPoolDeserializationCluster;
  friend class ObjectPoolSerializationCluster;
  friend class ObjectPoolLayout;
  friend class SnapshotReader;
};

// All _*ArrayView/_ByteDataView classes share the same layout.
class TypedDataViewLayout : public TypedDataBaseLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedDataView);

 public:
  // Recompute [data_] based on internal/external [typed_data_].
  void RecomputeDataField() {
    const intptr_t offset_in_bytes = RawSmiValue(offset_in_bytes_);
    uint8_t* payload = typed_data_->ptr()->data_;
    data_ = payload + offset_in_bytes;
  }

  // Recopute [data_] based on internal [typed_data_] - needs to be called by GC
  // whenever the backing store moved.
  //
  // NOTICE: This method assumes [this] is the forwarded object and the
  // [typed_data_] pointer points to the new backing store. The backing store's
  // fields don't need to be valid - only it's address.
  void RecomputeDataFieldForInternalTypedData() {
    const intptr_t offset_in_bytes = RawSmiValue(offset_in_bytes_);
    uint8_t* payload = reinterpret_cast<uint8_t*>(
        ObjectLayout::ToAddr(typed_data_) + TypedDataLayout::payload_offset());
    data_ = payload + offset_in_bytes;
  }

  void ValidateInnerPointer() {
    if (typed_data_->ptr()->GetClassId() == kNullCid) {
      // The view object must have gotten just initialized.
      if (data_ != nullptr || RawSmiValue(offset_in_bytes_) != 0 ||
          RawSmiValue(length_) != 0) {
        FATAL("RawTypedDataView has invalid inner pointer.");
      }
    } else {
      const intptr_t offset_in_bytes = RawSmiValue(offset_in_bytes_);
      uint8_t* payload = typed_data_->ptr()->data_;
      if ((payload + offset_in_bytes) != data_) {
        FATAL("RawTypedDataView has invalid inner pointer.");
      }
    }
  }

 protected:
  VISIT_FROM(ObjectPtr, length_)
  TypedDataBasePtr typed_data_;
  SmiPtr offset_in_bytes_;
  VISIT_TO(ObjectPtr, offset_in_bytes_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class Api;
  friend class Object;
  friend class ObjectPoolDeserializationCluster;
  friend class ObjectPoolSerializationCluster;
  friend class ObjectPoolLayout;
  friend class GCCompactor;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class SnapshotReader;
};

class ExternalOneByteStringLayout : public StringLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalOneByteString);

  const uint8_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class ExternalTwoByteStringLayout : public StringLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTwoByteString);

  const uint16_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class BoolLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bool);
  VISIT_NOTHING();

  bool value_;

  friend class Object;
};

class ArrayLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Array);

  VISIT_FROM(RawCompressed, type_arguments_)
  TypeArgumentsPtr type_arguments_;
  SmiPtr length_;
  // Variable length data follows here.
  ObjectPtr* data() { OPEN_ARRAY_START(ObjectPtr, ObjectPtr); }
  ObjectPtr const* data() const { OPEN_ARRAY_START(ObjectPtr, ObjectPtr); }
  VISIT_TO_LENGTH(RawCompressed, &data()[length - 1])

  friend class LinkedHashMapSerializationCluster;
  friend class LinkedHashMapDeserializationCluster;
  friend class CodeSerializationCluster;
  friend class CodeDeserializationCluster;
  friend class Deserializer;
  friend class CodeLayout;
  friend class ImmutableArrayLayout;
  friend class SnapshotReader;
  friend class GrowableObjectArray;
  friend class LinkedHashMap;
  friend class LinkedHashMapLayout;
  friend class Object;
  friend class ICData;            // For high performance access.
  friend class SubtypeTestCache;  // For high performance access.

  friend class OldPage;
};

class ImmutableArrayLayout : public ArrayLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ImmutableArray);

  friend class SnapshotReader;
};

class GrowableObjectArrayLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray);

  VISIT_FROM(RawCompressed, type_arguments_)
  TypeArgumentsPtr type_arguments_;
  SmiPtr length_;
  ArrayPtr data_;
  VISIT_TO(RawCompressed, data_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class SnapshotReader;
};

class LinkedHashMapLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LinkedHashMap);

  VISIT_FROM(RawCompressed, type_arguments_)
  TypeArgumentsPtr type_arguments_;
  TypedDataPtr index_;
  SmiPtr hash_mask_;
  ArrayPtr data_;
  SmiPtr used_data_;
  SmiPtr deleted_keys_;
  VISIT_TO(RawCompressed, deleted_keys_)

  friend class SnapshotReader;
};

class Float32x4Layout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float32x4);
  VISIT_NOTHING();

  ALIGN8 float value_[4];

  friend class SnapshotReader;
  friend class Class;

 public:
  float x() const { return value_[0]; }
  float y() const { return value_[1]; }
  float z() const { return value_[2]; }
  float w() const { return value_[3]; }
};
COMPILE_ASSERT(sizeof(Float32x4Layout) == 24);

class Int32x4Layout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int32x4);
  VISIT_NOTHING();

  ALIGN8 int32_t value_[4];

  friend class SnapshotReader;

 public:
  int32_t x() const { return value_[0]; }
  int32_t y() const { return value_[1]; }
  int32_t z() const { return value_[2]; }
  int32_t w() const { return value_[3]; }
};
COMPILE_ASSERT(sizeof(Int32x4Layout) == 24);

class Float64x2Layout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float64x2);
  VISIT_NOTHING();

  ALIGN8 double value_[2];

  friend class SnapshotReader;
  friend class Class;

 public:
  double x() const { return value_[0]; }
  double y() const { return value_[1]; }
};
COMPILE_ASSERT(sizeof(Float64x2Layout) == 24);

// Define an aliases for intptr_t.
#if defined(ARCH_IS_32_BIT)
#define kIntPtrCid kTypedDataInt32ArrayCid
#define SetIntPtr SetInt32
#elif defined(ARCH_IS_64_BIT)
#define kIntPtrCid kTypedDataInt64ArrayCid
#define SetIntPtr SetInt64
#else
#error Architecture is not 32-bit or 64-bit.
#endif  // ARCH_IS_32_BIT

class ExternalTypedDataLayout : public TypedDataBaseLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData);

 protected:
  VISIT_FROM(RawCompressed, length_)
  VISIT_TO(RawCompressed, length_)

  friend class BytecodeLayout;
};

class PointerLayout : public PointerBaseLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Pointer);

  VISIT_FROM(RawCompressed, type_arguments_)
  TypeArgumentsPtr type_arguments_;
  VISIT_TO(RawCompressed, type_arguments_)

  friend class Pointer;
};

class DynamicLibraryLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(DynamicLibrary);
  VISIT_NOTHING();
  void* handle_;

  friend class DynamicLibrary;
};

// VM implementations of the basic types in the isolate.
class alignas(8) CapabilityLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Capability);
  VISIT_NOTHING();
  uint64_t id_;
};

class alignas(8) SendPortLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SendPort);
  VISIT_NOTHING();
  Dart_Port id_;
  Dart_Port origin_id_;

  friend class ReceivePort;
};

class ReceivePortLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ReceivePort);

  VISIT_FROM(ObjectPtr, send_port_)
  SendPortPtr send_port_;
  InstancePtr handler_;
  VISIT_TO(ObjectPtr, handler_)
};

class TransferableTypedDataLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TransferableTypedData);
  VISIT_NOTHING();
};

// VM type for capturing stacktraces when exceptions are thrown,
// Currently we don't have any interface that this object is supposed
// to implement so we just support the 'toString' method which
// converts the stack trace into a string.
class StackTraceLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(StackTrace);

  VISIT_FROM(ObjectPtr, async_link_)
  StackTracePtr async_link_;  // Link to parent async stack trace.
  ArrayPtr code_array_;       // Code object for each frame in the stack trace.
  ArrayPtr pc_offset_array_;  // Offset of PC for each frame.
  VISIT_TO(ObjectPtr, pc_offset_array_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // False for pre-allocated stack trace (used in OOM and Stack overflow).
  bool expand_inlined_;
  // Whether the link between the stack and the async-link represents a
  // synchronous start to an asynchronous function. In this case, we omit the
  // <asynchronous suspension> marker when concatenating the stacks.
  bool skip_sync_start_in_parent_stack;
};

// VM type for capturing JS regular expressions.
class RegExpLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(RegExp);

  VISIT_FROM(ObjectPtr, num_bracket_expressions_)
  SmiPtr num_bracket_expressions_;
  ArrayPtr capture_name_map_;
  StringPtr pattern_;  // Pattern to be used for matching.
  union {
    FunctionPtr function_;
    TypedDataPtr bytecode_;
  } one_byte_;
  union {
    FunctionPtr function_;
    TypedDataPtr bytecode_;
  } two_byte_;
  FunctionPtr external_one_byte_function_;
  FunctionPtr external_two_byte_function_;
  union {
    FunctionPtr function_;
    TypedDataPtr bytecode_;
  } one_byte_sticky_;
  union {
    FunctionPtr function_;
    TypedDataPtr bytecode_;
  } two_byte_sticky_;
  FunctionPtr external_one_byte_sticky_function_;
  FunctionPtr external_two_byte_sticky_function_;
  VISIT_TO(ObjectPtr, external_two_byte_sticky_function_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // The same pattern may use different amount of registers if compiled
  // for a one-byte target than a two-byte target. For example, we do not
  // need to allocate registers to check whether the current position is within
  // a surrogate pair when matching a Unicode pattern against a one-byte string.
  intptr_t num_one_byte_registers_;
  intptr_t num_two_byte_registers_;

  // A bitfield with two fields:
  // type: Uninitialized, simple or complex.
  // flags: Represents global/local, case insensitive, multiline, unicode,
  //        dotAll.
  int8_t type_flags_;
};

class WeakPropertyLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakProperty);

  VISIT_FROM(ObjectPtr, key_)
  ObjectPtr key_;
  ObjectPtr value_;
  VISIT_TO(ObjectPtr, value_)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Linked list is chaining all pending weak properties.
  // Untyped to make it clear that it is not to be visited by GC.
  uword next_;

  friend class GCMarker;
  template <bool>
  friend class MarkingVisitorBase;
  friend class Scavenger;
  template <bool>
  friend class ScavengerVisitorBase;
};

// MirrorReferences are used by mirrors to hold reflectees that are VM
// internal objects, such as libraries, classes, functions or types.
class MirrorReferenceLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MirrorReference);

  VISIT_FROM(ObjectPtr, referent_)
  ObjectPtr referent_;
  VISIT_TO(ObjectPtr, referent_)
};

// UserTag are used by the profiler to track Dart script state.
class UserTagLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UserTag);

  VISIT_FROM(ObjectPtr, label_)
  StringPtr label_;
  VISIT_TO(ObjectPtr, label_)

  // Isolate unique tag.
  uword tag_;

  friend class SnapshotReader;
  friend class Object;

 public:
  uword tag() const { return tag_; }
};

class FutureOrLayout : public InstanceLayout {
  RAW_HEAP_OBJECT_IMPLEMENTATION(FutureOr);

  VISIT_FROM(RawCompressed, type_arguments_)
  TypeArgumentsPtr type_arguments_;
  VISIT_TO(RawCompressed, type_arguments_)

  friend class SnapshotReader;
};

}  // namespace dart

#endif  // RUNTIME_VM_RAW_OBJECT_H_
