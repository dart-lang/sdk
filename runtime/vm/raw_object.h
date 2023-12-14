// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_RAW_OBJECT_H_
#define RUNTIME_VM_RAW_OBJECT_H_

#if defined(SHOULD_NOT_INCLUDE_RUNTIME)
#error "Should not include runtime"
#endif

#include "platform/assert.h"
#include "vm/class_id.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/compiler/runtime_api.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/pointer_tagging.h"
#include "vm/snapshot.h"
#include "vm/tagged_pointer.h"
#include "vm/thread.h"
#include "vm/token.h"
#include "vm/token_position.h"
#include "vm/visitor.h"

// Currently we have two different axes for offset generation:
//
//  * Target architecture
//  * DART_PRECOMPILED_RUNTIME (i.e, AOT vs. JIT)
//
// That is, fields in UntaggedObject and its subclasses should only be included
// or excluded conditionally based on these factors. Otherwise, the generated
// offsets can be wrong (which should be caught by offset checking in dart.cc).
//
// TODO(dartbug.com/43646): Add DART_PRECOMPILER as another axis.

namespace dart {

// Forward declarations.
class Isolate;
class IsolateGroup;
#define DEFINE_FORWARD_DECLARATION(clazz) class Untagged##clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class CodeStatistics;
class StackFrame;

#define DEFINE_CONTAINS_COMPRESSED(type)                                       \
  static constexpr bool kContainsCompressedPointers =                          \
      is_compressed_ptr<type>::value;

#define CHECK_CONTAIN_COMPRESSED(type)                                         \
  static_assert(                                                               \
      kContainsCompressedPointers || is_uncompressed_ptr<type>::value,         \
      "From declaration uses ObjectPtr");                                      \
  static_assert(                                                               \
      !kContainsCompressedPointers || is_compressed_ptr<type>::value,          \
      "From declaration uses CompressedObjectPtr");

#define VISIT_FROM(first)                                                      \
  DEFINE_CONTAINS_COMPRESSED(decltype(first##_))                               \
  static constexpr bool kContainsPointerFields = true;                         \
  base_ptr_type<decltype(first##_)>::type* from() {                            \
    return reinterpret_cast<base_ptr_type<decltype(first##_)>::type*>(         \
        &first##_);                                                            \
  }

#define VISIT_FROM_PAYLOAD_START(elem_type)                                    \
  static_assert(is_uncompressed_ptr<elem_type>::value ||                       \
                    is_compressed_ptr<elem_type>::value,                       \
                "Payload elements must be object pointers");                   \
  DEFINE_CONTAINS_COMPRESSED(elem_type)                                        \
  static constexpr bool kContainsPointerFields = true;                         \
  base_ptr_type<elem_type>::type* from() {                                     \
    const uword payload_start = reinterpret_cast<uword>(this) + sizeof(*this); \
    ASSERT(Utils::IsAligned(payload_start, sizeof(elem_type)));                \
    return reinterpret_cast<base_ptr_type<elem_type>::type*>(payload_start);   \
  }

#define VISIT_TO(last)                                                         \
  CHECK_CONTAIN_COMPRESSED(decltype(last##_));                                 \
  static_assert(kContainsPointerFields,                                        \
                "Must have a corresponding VISIT_FROM");                       \
  base_ptr_type<decltype(last##_)>::type* to(intptr_t length = 0) {            \
    return reinterpret_cast<base_ptr_type<decltype(last##_)>::type*>(          \
        &last##_);                                                             \
  }

#define VISIT_TO_PAYLOAD_END(elem_type)                                        \
  static_assert(is_uncompressed_ptr<elem_type>::value ||                       \
                    is_compressed_ptr<elem_type>::value,                       \
                "Payload elements must be object pointers");                   \
  static_assert(kContainsPointerFields,                                        \
                "Must have a corresponding VISIT_FROM");                       \
  CHECK_CONTAIN_COMPRESSED(elem_type);                                         \
  base_ptr_type<elem_type>::type* to(intptr_t length) {                        \
    const uword payload_start = reinterpret_cast<uword>(this) + sizeof(*this); \
    ASSERT(Utils::IsAligned(payload_start, sizeof(elem_type)));                \
    const uword payload_last =                                                 \
        payload_start + sizeof(elem_type) * (length - 1);                      \
    return reinterpret_cast<base_ptr_type<elem_type>::type*>(payload_last);    \
  }

#define VISIT_NOTHING() int NothingToVisit();

#if defined(DART_COMPRESSED_POINTERS)
#define ASSERT_UNCOMPRESSED(Type)                                              \
  static_assert(!Untagged##Type::kContainsCompressedPointers,                  \
                "Should contain compressed pointers");

#define ASSERT_COMPRESSED(Type)                                                \
  static_assert(Untagged##Type::kContainsCompressedPointers,                   \
                "Should not contain compressed pointers");
#else
// Do no checks if there are no compressed pointers.
#define ASSERT_UNCOMPRESSED(Type)
#define ASSERT_COMPRESSED(Type)
#endif

#define ASSERT_NOTHING_TO_VISIT(Type)                                          \
  ASSERT(SIZE_OF_RETURNED_VALUE(Untagged##Type, NothingToVisit) == sizeof(int))

enum TypedDataElementType {
#define V(name) k##name##Element,
  CLASS_LIST_TYPED_DATA(V)
#undef V
};

#define VISITOR_SUPPORT(object)                                                \
  static intptr_t Visit##object##Pointers(object##Ptr raw_obj,                 \
                                          ObjectPointerVisitor* visitor);

#define RAW_OBJECT_IMPLEMENTATION(object)                                      \
 private: /* NOLINT */                                                         \
  VISITOR_SUPPORT(object)                                                      \
  friend class object;                                                         \
  friend class UntaggedObject;                                                 \
  friend class OffsetsTable;                                                   \
  DISALLOW_ALLOCATION();                                                       \
  DISALLOW_IMPLICIT_CONSTRUCTORS(Untagged##object)

#define RAW_HEAP_OBJECT_IMPLEMENTATION(object)                                 \
 private:                                                                      \
  RAW_OBJECT_IMPLEMENTATION(object);                                           \
  friend class object##SerializationCluster;                                   \
  friend class object##DeserializationCluster;                                 \
  friend class object##MessageSerializationCluster;                            \
  friend class object##MessageDeserializationCluster;                          \
  friend class Serializer;                                                     \
  friend class Deserializer;                                                   \
  template <typename Base>                                                     \
  friend class ObjectCopy;                                                     \
  friend class Pass2Visitor;

// UntaggedObject is the base class of all raw objects; even though it carries
// the tags_ field not all raw objects are allocated in the heap and thus cannot
// be dereferenced (e.g. UntaggedSmi).
class UntaggedObject {
 public:
  // The tags field which is a part of the object header uses the following
  // bit fields for storing tags.
  enum TagBits {
    kCardRememberedBit = 0,
    kCanonicalBit = 1,
    kNotMarkedBit = 2,            // Incremental barrier target.
    kNewBit = 3,                  // Generational barrier target.
    kAlwaysSetBit = 4,            // Incremental barrier source.
    kOldAndNotRememberedBit = 5,  // Generational barrier source.
    kImmutableBit = 6,
    kReservedBit = 7,

    kSizeTagPos = kReservedBit + 1,  // = 8
    kSizeTagSize = 4,
    kClassIdTagPos = kSizeTagPos + kSizeTagSize,  // = 12
    kClassIdTagSize = 20,
    kHashTagPos = kClassIdTagPos + kClassIdTagSize,  // = 32
    kHashTagSize = 32,
  };

  static constexpr intptr_t kGenerationalBarrierMask = 1 << kNewBit;
  static constexpr intptr_t kIncrementalBarrierMask = 1 << kNotMarkedBit;
  static constexpr intptr_t kBarrierOverlapShift = 2;
  COMPILE_ASSERT(kNotMarkedBit + kBarrierOverlapShift == kAlwaysSetBit);
  COMPILE_ASSERT(kNewBit + kBarrierOverlapShift == kOldAndNotRememberedBit);

  // The bit in the Smi tag position must be something that can be set to 0
  // for a dead filler object of either generation.
  // See Object::MakeUnusedSpaceTraversable.
  COMPILE_ASSERT(kCardRememberedBit == 0);

  // Encodes the object size in the tag in units of object alignment.
  class SizeTag {
   public:
    typedef intptr_t Type;

    static constexpr intptr_t kMaxSizeTagInUnitsOfAlignment =
        ((1 << UntaggedObject::kSizeTagSize) - 1);
    static constexpr intptr_t kMaxSizeTag =
        kMaxSizeTagInUnitsOfAlignment * kObjectAlignment;

    static constexpr uword encode(intptr_t size) {
      return SizeBits::encode(SizeToTagValue(size));
    }

    static constexpr uword decode(uword tag) {
      return TagValueToSize(SizeBits::decode(tag));
    }

    static constexpr uword update(intptr_t size, uword tag) {
      return SizeBits::update(SizeToTagValue(size), tag);
    }

    static constexpr bool SizeFits(intptr_t size) {
      assert(Utils::IsAligned(size, kObjectAlignment));
      return (size <= kMaxSizeTag);
    }

   private:
    // The actual unscaled bit field used within the tag field.
    class SizeBits
        : public BitField<uword, intptr_t, kSizeTagPos, kSizeTagSize> {};

    static constexpr intptr_t SizeToTagValue(intptr_t size) {
      assert(Utils::IsAligned(size, kObjectAlignment));
      return !SizeFits(size) ? 0 : (size >> kObjectAlignmentLog2);
    }
    static constexpr intptr_t TagValueToSize(intptr_t value) {
      return value << kObjectAlignmentLog2;
    }
  };

  class ClassIdTag : public BitField<uword,
                                     ClassIdTagType,
                                     kClassIdTagPos,
                                     kClassIdTagSize> {};
  COMPILE_ASSERT(kBitsPerByte * sizeof(ClassIdTagType) >= kClassIdTagSize);
  COMPILE_ASSERT(kClassIdTagMax == (1 << kClassIdTagSize) - 1);

#if defined(HASH_IN_OBJECT_HEADER)
  class HashTag : public BitField<uword, uint32_t, kHashTagPos, kHashTagSize> {
  };
#endif

  class CardRememberedBit
      : public BitField<uword, bool, kCardRememberedBit, 1> {};

  class NotMarkedBit : public BitField<uword, bool, kNotMarkedBit, 1> {};

  class NewBit : public BitField<uword, bool, kNewBit, 1> {};

  class CanonicalBit : public BitField<uword, bool, kCanonicalBit, 1> {};

  class AlwaysSetBit : public BitField<uword, bool, kAlwaysSetBit, 1> {};

  class OldAndNotRememberedBit
      : public BitField<uword, bool, kOldAndNotRememberedBit, 1> {};

  // Will be set to 1 iff
  //   - is unmodifiable typed data view (backing store may be mutable)
  //   - is transitively immutable
  class ImmutableBit : public BitField<uword, bool, kImmutableBit, 1> {};

  class ReservedBit : public BitField<uword, intptr_t, kReservedBit, 1> {};

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

  uword tags() const { return tags_; }

  // Support for GC marking bit. Marked objects are either grey (not yet
  // visited) or black (already visited).
  static bool IsMarked(uword tags) { return !NotMarkedBit::decode(tags); }
  bool IsMarked() const { return !tags_.Read<NotMarkedBit>(); }
  bool IsMarkedIgnoreRace() const {
    return !tags_.ReadIgnoreRace<NotMarkedBit>();
  }
  void SetMarkBit() {
    ASSERT(!IsMarked());
    tags_.UpdateBool<NotMarkedBit>(false);
  }
  void SetMarkBitUnsynchronized() {
    ASSERT(!IsMarked());
    tags_.UpdateUnsynchronized<NotMarkedBit>(false);
  }
  void SetMarkBitRelease() {
    ASSERT(!IsMarked());
    tags_.UpdateBool<NotMarkedBit, std::memory_order_release>(false);
  }
  void ClearMarkBit() {
    ASSERT(IsMarked());
    tags_.UpdateBool<NotMarkedBit>(true);
  }
  void ClearMarkBitUnsynchronized() {
    ASSERT(IsMarked());
    tags_.UpdateUnsynchronized<NotMarkedBit>(true);
  }
  // Returns false if the bit was already set.
  DART_WARN_UNUSED_RESULT
  bool TryAcquireMarkBit() { return tags_.TryClear<NotMarkedBit>(); }

  // Canonical objects have the property that two canonical objects are
  // logically equal iff they are the same object (pointer equal).
  bool IsCanonical() const { return tags_.Read<CanonicalBit>(); }
  void SetCanonical() { tags_.UpdateBool<CanonicalBit>(true); }
  void ClearCanonical() { tags_.UpdateBool<CanonicalBit>(false); }

  bool IsImmutable() const { return tags_.Read<ImmutableBit>(); }
  void SetImmutable() { tags_.UpdateBool<ImmutableBit>(true); }
  void ClearImmutable() { tags_.UpdateBool<ImmutableBit>(false); }

  bool InVMIsolateHeap() const;

  // Support for GC remembered bit.
  bool IsRemembered() const {
    ASSERT(IsOldObject());
    return !tags_.Read<OldAndNotRememberedBit>();
  }
  bool TryAcquireRememberedBit() {
    ASSERT(!IsCardRemembered());
    return tags_.TryClear<OldAndNotRememberedBit>();
  }
  void ClearRememberedBit() {
    ASSERT(IsOldObject());
    tags_.UpdateBool<OldAndNotRememberedBit>(true);
  }
  void ClearRememberedBitUnsynchronized() {
    ASSERT(IsOldObject());
    tags_.UpdateUnsynchronized<OldAndNotRememberedBit>(true);
  }

  DART_FORCE_INLINE
  void EnsureInRememberedSet(Thread* thread) {
    if (TryAcquireRememberedBit()) {
      thread->StoreBufferAddObject(ObjectPtr(this));
    }
  }

  bool IsCardRemembered() const { return tags_.Read<CardRememberedBit>(); }
  void SetCardRememberedBitUnsynchronized() {
    ASSERT(!IsRemembered());
    ASSERT(!IsCardRemembered());
    tags_.UpdateUnsynchronized<CardRememberedBit>(true);
  }

  intptr_t GetClassId() const { return tags_.Read<ClassIdTag>(); }

#if defined(HASH_IN_OBJECT_HEADER)
  uint32_t GetHeaderHash() const { return tags_.Read<HashTag>(); }
  uint32_t SetHeaderHashIfNotSet(uint32_t h) {
    return tags_.UpdateConditional<HashTag>(h, /*conditional_old_value=*/0);
  }
#endif

  intptr_t HeapSize() const {
    uword tags = tags_;
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
  intptr_t HeapSize(uword tags) const {
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
    uword this_addr = UntaggedObject::ToAddr(this);
    return (addr >= this_addr) && (addr < (this_addr + this_size));
  }

  void Validate(IsolateGroup* isolate_group) const;

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
    uword from = obj_addr + sizeof(UntaggedObject);
    uword to = obj_addr + instance_size - kCompressedWordSize;
    const auto first = reinterpret_cast<CompressedObjectPtr*>(from);
    const auto last = reinterpret_cast<CompressedObjectPtr*>(to);

    const auto unboxed_fields_bitmap =
        visitor->class_table()->GetUnboxedFieldsMapAt(class_id);

    if (!unboxed_fields_bitmap.IsEmpty()) {
      intptr_t bit = sizeof(UntaggedObject) / kCompressedWordSize;
      for (CompressedObjectPtr* current = first; current <= last; current++) {
        if (!unboxed_fields_bitmap.Get(bit++)) {
          visitor->VisitCompressedPointers(heap_base(), current, current);
        }
      }
    } else {
      visitor->VisitCompressedPointers(heap_base(), first, last);
    }

    return instance_size;
  }

  template <class V>
  DART_FORCE_INLINE intptr_t VisitPointersNonvirtual(V* visitor) {
    // Fall back to virtual variant for predefined classes
    intptr_t class_id = GetClassId();
    if (class_id < kNumPredefinedCids) {
      return VisitPointersPredefined(visitor, class_id);
    }

    // Calculate the first and last raw object pointer fields.
    intptr_t instance_size = HeapSize();
    uword obj_addr = ToAddr(this);
    uword from = obj_addr + sizeof(UntaggedObject);
    uword to = obj_addr + instance_size - kCompressedWordSize;
    const auto first = reinterpret_cast<CompressedObjectPtr*>(from);
    const auto last = reinterpret_cast<CompressedObjectPtr*>(to);

    const auto unboxed_fields_bitmap =
        visitor->class_table()->GetUnboxedFieldsMapAt(class_id);

    if (!unboxed_fields_bitmap.IsEmpty()) {
      intptr_t bit = sizeof(UntaggedObject) / kCompressedWordSize;
      for (CompressedObjectPtr* current = first; current <= last; current++) {
        if (!unboxed_fields_bitmap.Get(bit++)) {
          visitor->V::VisitCompressedPointers(heap_base(), current, current);
        }
      }
    } else {
      visitor->V::VisitCompressedPointers(heap_base(), first, last);
    }

    return instance_size;
  }

  // This variant ensures that we do not visit the extra slot created from
  // rounding up instance sizes up to the allocation unit.
  void VisitPointersPrecise(ObjectPointerVisitor* visitor);

  static ObjectPtr FromAddr(uword addr) {
    // We expect the untagged address here.
    ASSERT((addr & kSmiTagMask) != kHeapObjectTag);
    return static_cast<ObjectPtr>(addr + kHeapObjectTag);
  }

  static uword ToAddr(const UntaggedObject* raw_obj) {
    return reinterpret_cast<uword>(raw_obj);
  }
  static uword ToAddr(const ObjectPtr raw_obj) {
    return static_cast<uword>(raw_obj) - kHeapObjectTag;
  }

  static bool IsCanonical(intptr_t value) {
    return CanonicalBit::decode(value);
  }

 private:
  AtomicBitFieldContainer<uword> tags_;  // Various object tags (bits).

  intptr_t VisitPointersPredefined(ObjectPointerVisitor* visitor,
                                   intptr_t class_id);

  intptr_t HeapSizeFromClass(uword tags) const;

  void SetClassId(intptr_t new_cid) { tags_.Update<ClassIdTag>(new_cid); }
  void SetClassIdUnsynchronized(intptr_t new_cid) {
    tags_.UpdateUnsynchronized<ClassIdTag>(new_cid);
  }

 protected:
  // Automatically inherited by subclasses unless overridden.
  static constexpr bool kContainsCompressedPointers = false;
  // Automatically inherited by subclasses unless overridden.
  static constexpr bool kContainsPointerFields = false;

  // The first offset in an allocated object of the given type that contains a
  // (possibly compressed) object pointer. Used to initialize object pointer
  // fields to Object::null() instead of 0.
  //
  // Always returns an offset after the object header tags.
  template <typename T>
  DART_FORCE_INLINE static uword from_offset();

  // The last offset in an allocated object of the given untagged type that
  // contains a (possibly compressed) object pointer. Used to initialize object
  // pointer fields to Object::null() instead of 0.
  //
  // Takes an optional argument that is the number of elements in the payload,
  // which is ignored if the object never contains a payload.
  //
  // If there are no pointer fields in the object, then
  // to_offset<T>() < from_offset<T>().
  template <typename T>
  DART_FORCE_INLINE static uword to_offset(intptr_t length = 0);

  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in Object, to ensure that the
  // write barrier is correctly applied.
  template <typename type, std::memory_order order = std::memory_order_relaxed>
  type LoadPointer(type const* addr) const {
    return reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->load(order);
  }
  template <typename type,
            typename compressed_type,
            std::memory_order order = std::memory_order_relaxed>
  type LoadCompressedPointer(compressed_type const* addr) const {
    compressed_type v = reinterpret_cast<std::atomic<compressed_type>*>(
                            const_cast<compressed_type*>(addr))
                            ->load(order);
    return static_cast<type>(v.Decompress(heap_base()));
  }

  uword heap_base() const {
    return reinterpret_cast<uword>(this) & kHeapBaseMask;
  }

  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StorePointer(type const* addr, type value) {
    reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->store(value, order);
    if (value.IsHeapObject()) {
      CheckHeapPointerStore(value, Thread::Current());
    }
  }

  template <typename type,
            typename compressed_type,
            std::memory_order order = std::memory_order_relaxed>
  void StoreCompressedPointer(compressed_type const* addr, type value) {
    reinterpret_cast<std::atomic<compressed_type>*>(
        const_cast<compressed_type*>(addr))
        ->store(static_cast<compressed_type>(value), order);
    if (value.IsHeapObject()) {
      CheckHeapPointerStore(value, Thread::Current());
    }
  }

  template <typename type>
  void StorePointer(type const* addr, type value, Thread* thread) {
    *const_cast<type*>(addr) = value;
    if (value.IsHeapObject()) {
      CheckHeapPointerStore(value, thread);
    }
  }

  template <typename type, typename compressed_type>
  void StoreCompressedPointer(compressed_type const* addr,
                              type value,
                              Thread* thread) {
    *const_cast<compressed_type*>(addr) = value;
    if (value.IsHeapObject()) {
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

  // Note: StoreArrayPointer won't work if value_type is a compressed pointer.
  template <typename type,
            std::memory_order order = std::memory_order_relaxed,
            typename value_type = type>
  void StoreArrayPointer(type const* addr, value_type value) {
    reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->store(type(value), order);
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, Thread::Current());
    }
  }

  template <typename type, typename value_type = type>
  void StoreArrayPointer(type const* addr, value_type value, Thread* thread) {
    *const_cast<type*>(addr) = value;
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, thread);
    }
  }

  template <typename type, typename compressed_type, std::memory_order order>
  void StoreCompressedArrayPointer(compressed_type const* addr, type value) {
    reinterpret_cast<std::atomic<compressed_type>*>(
        const_cast<compressed_type*>(addr))
        ->store(static_cast<compressed_type>(value), order);
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, Thread::Current());
    }
  }

  template <typename type, typename compressed_type, std::memory_order order>
  void StoreCompressedArrayPointer(compressed_type const* addr,
                                   type value,
                                   Thread* thread) {
    reinterpret_cast<std::atomic<compressed_type>*>(
        const_cast<compressed_type*>(addr))
        ->store(static_cast<compressed_type>(value), order);
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, thread);
    }
  }

  template <typename type, typename compressed_type>
  void StoreCompressedArrayPointer(compressed_type const* addr,
                                   type value,
                                   Thread* thread) {
    *const_cast<compressed_type*>(addr) = value;
    if (value->IsHeapObject()) {
      CheckArrayPointerStore(addr, value, thread);
    }
  }

  template <typename type,
            typename compressed_type,
            std::memory_order order = std::memory_order_relaxed>
  type ExchangeCompressedPointer(compressed_type const* addr, type value) {
    compressed_type previous_value =
        reinterpret_cast<std::atomic<compressed_type>*>(
            const_cast<compressed_type*>(addr))
            ->exchange(static_cast<compressed_type>(value), order);
    if (value.IsHeapObject()) {
      CheckHeapPointerStore(value, Thread::Current());
    }
    return static_cast<type>(previous_value.Decompress(heap_base()));
  }

  template <std::memory_order order = std::memory_order_relaxed>
  SmiPtr LoadSmi(SmiPtr const* addr) const {
    return reinterpret_cast<std::atomic<SmiPtr>*>(const_cast<SmiPtr*>(addr))
        ->load(order);
  }
  template <std::memory_order order = std::memory_order_relaxed>
  SmiPtr LoadCompressedSmi(CompressedSmiPtr const* addr) const {
    return static_cast<SmiPtr>(reinterpret_cast<std::atomic<CompressedSmiPtr>*>(
                                   const_cast<CompressedSmiPtr*>(addr))
                                   ->load(order)
                                   .DecompressSmi());
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  template <typename type, std::memory_order order = std::memory_order_relaxed>
  void StoreSmi(type const* addr, type value) {
    // Can't use Contains, as array length is initialized through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= UntaggedObject::ToAddr(this));
    reinterpret_cast<std::atomic<type>*>(const_cast<type*>(addr))
        ->store(value, order);
  }
  template <std::memory_order order = std::memory_order_relaxed>
  void StoreCompressedSmi(CompressedSmiPtr const* addr, SmiPtr value) {
    // Can't use Contains, as array length is initialized through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= UntaggedObject::ToAddr(this));
    reinterpret_cast<std::atomic<CompressedSmiPtr>*>(
        const_cast<CompressedSmiPtr*>(addr))
        ->store(static_cast<CompressedSmiPtr>(value), order);
  }

 private:
  DART_FORCE_INLINE
  void CheckHeapPointerStore(ObjectPtr value, Thread* thread) {
    uword source_tags = this->tags_;
    uword target_tags = value->untag()->tags_;
    uword overlap = (source_tags >> kBarrierOverlapShift) & target_tags &
                    thread->write_barrier_mask();
    if (overlap != 0) {
      if ((overlap & kGenerationalBarrierMask) != 0) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        EnsureInRememberedSet(thread);
      }
      if ((overlap & kIncrementalBarrierMask) != 0) {
        // Incremental barrier: record when a store creates an
        // any -> not-marked reference.
        if (ClassIdTag::decode(target_tags) == kInstructionsCid) {
          // Instruction pages may be non-writable. Defer marking.
          thread->DeferredMarkingStackAddObject(value);
          return;
        }
        if (value->untag()->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  template <typename type, typename value_type>
  DART_FORCE_INLINE void CheckArrayPointerStore(type const* addr,
                                                value_type value,
                                                Thread* thread) {
    uword source_tags = this->tags_;
    uword target_tags = value->untag()->tags_;
    uword overlap = (source_tags >> kBarrierOverlapShift) & target_tags &
                    thread->write_barrier_mask();
    if (overlap != 0) {
      if ((overlap & kGenerationalBarrierMask) != 0) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        if (this->IsCardRemembered()) {
          RememberCard(addr);
        } else if (this->TryAcquireRememberedBit()) {
          thread->StoreBufferAddObject(static_cast<ObjectPtr>(this));
        }
      }
      if ((overlap & kIncrementalBarrierMask) != 0) {
        // Incremental barrier: record when a store creates an
        // old -> old-and-not-marked reference.
        if (ClassIdTag::decode(target_tags) == kInstructionsCid) {
          // Instruction pages may be non-writable. Defer marking.
          thread->DeferredMarkingStackAddObject(value);
          return;
        }
        if (value->untag()->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  friend class StoreBufferUpdateVisitor;  // RememberCard
  void RememberCard(ObjectPtr const* slot);
#if defined(DART_COMPRESSED_POINTERS)
  void RememberCard(CompressedObjectPtr const* slot);
#endif

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
  friend class GCSweeper;
  friend class ExternalTypedData;
  friend class GrowableObjectArray;  // StorePointer
  template <bool>
  friend class MarkingVisitorBase;
  friend class Mint;
  friend class Object;
  friend class OneByteString;  // StoreSmi
  friend class UntaggedInstance;
  friend class Scavenger;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class ImageReader;  // tags_ check
  friend class ImageWriter;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class Deserializer;
  friend class String;
  friend class WeakProperty;            // StorePointer
  friend class Instance;                // StorePointer
  friend class StackFrame;              // GetCodeObject assertion.
  friend class CodeLookupTableBuilder;  // profiler
  friend class ObjectLocator;
  friend class WriteBarrierUpdateVisitor;  // CheckHeapPointerStore
  friend class OffsetsTable;
  friend class Object;
  friend uword TagsFromUntaggedObject(UntaggedObject*);                // tags_
  friend void SetNewSpaceTaggingWord(ObjectPtr, classid_t, uint32_t);  // tags_
  friend class ObjectCopyBase;  // LoadPointer/StorePointer
  friend void ReportImpossibleNullError(intptr_t cid,
                                        StackFrame* caller_frame,
                                        Thread* thread);

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(UntaggedObject);
};

// Note that the below templates for from_offset and to_offset for objects
// with pointer fields assume that the range from from() and to() cover all
// pointer fields. If this is not the case (e.g., the next_seen_by_gc_ field
// in WeakArray/WeakProperty/WeakReference), then specialize the definitions.

template <typename T>
DART_FORCE_INLINE uword UntaggedObject::from_offset() {
  if constexpr (T::kContainsPointerFields) {
    return reinterpret_cast<uword>(reinterpret_cast<T*>(kOffsetOfPtr)->from()) -
           kOffsetOfPtr;
  } else {
    // Non-zero to ensure to_offset() < from_offset() in this case, as
    // to_offset() is the offset to the last pointer field, not past it.
    return sizeof(UntaggedObject);
  }
}

template <typename T>
DART_FORCE_INLINE uword UntaggedObject::to_offset(intptr_t length) {
  if constexpr (T::kContainsPointerFields) {
    return reinterpret_cast<uword>(
               reinterpret_cast<T*>(kOffsetOfPtr)->to(length)) -
           kOffsetOfPtr;
  } else {
    USE(length);
    // Zero to ensure to_offset() < from_offset() in this case, as
    // from_offset() is guaranteed to return an offset after the header tags.
    return 0;
  }
}

inline intptr_t ObjectPtr::GetClassId() const {
  return untag()->GetClassId();
}

#define POINTER_FIELD(type, name)                                              \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    return LoadPointer<type, order>(&name##_);                                 \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    StorePointer<type, order>(&name##_, value);                                \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  type name##_;

#define COMPRESSED_POINTER_FIELD(type, name)                                   \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    return LoadCompressedPointer<type, Compressed##type, order>(&name##_);     \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    StoreCompressedPointer<type, Compressed##type, order>(&name##_, value);    \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  Compressed##type name##_;

#define ARRAY_POINTER_FIELD(type, name)                                        \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    return LoadPointer<type, order>(&name##_);                                 \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    StoreArrayPointer<type, order>(&name##_, value);                           \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  type name##_;

#define COMPRESSED_ARRAY_POINTER_FIELD(type, name)                             \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    return LoadPointer<Compressed##type, order>(&name##_).Decompress(          \
        heap_base());                                                          \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    StoreCompressedArrayPointer<type, Compressed##type, order>(&name##_,       \
                                                               value);         \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  Compressed##type name##_;

#define VARIABLE_POINTER_FIELDS(type, accessor_name, array_name)               \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type accessor_name(intptr_t index) const {                                   \
    return LoadPointer<type, order>(&array_name()[index]);                     \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##accessor_name(intptr_t index, type value) {                       \
    StoreArrayPointer<type, order>(&array_name()[index], value);               \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##accessor_name(intptr_t index, type value, Thread* thread) {       \
    StoreArrayPointer<type, order>(&array_name()[index], value, thread);       \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  type* array_name() { OPEN_ARRAY_START(type, type); }                         \
  type const* array_name() const { OPEN_ARRAY_START(type, type); }             \
  VISIT_TO_PAYLOAD_END(type)

#define COMPRESSED_VARIABLE_POINTER_FIELDS(type, accessor_name, array_name)    \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type accessor_name(intptr_t index) const {                                   \
    return LoadCompressedPointer<type, Compressed##type, order>(               \
        &array_name()[index]);                                                 \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##accessor_name(intptr_t index, type value) {                       \
    StoreCompressedArrayPointer<type, Compressed##type, order>(                \
        &array_name()[index], value);                                          \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##accessor_name(intptr_t index, type value, Thread* thread) {       \
    StoreCompressedArrayPointer<type, Compressed##type, order>(                \
        &array_name()[index], value, thread);                                  \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  Compressed##type* array_name() {                                             \
    OPEN_ARRAY_START(Compressed##type, Compressed##type);                      \
  }                                                                            \
  Compressed##type const* array_name() const {                                 \
    OPEN_ARRAY_START(Compressed##type, Compressed##type);                      \
  }                                                                            \
  VISIT_TO_PAYLOAD_END(Compressed##type)

#define SMI_FIELD(type, name)                                                  \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    type result = LoadSmi<order>(&name##_);                                    \
    ASSERT(!result.IsHeapObject());                                            \
    return result;                                                             \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    ASSERT(!value.IsHeapObject());                                             \
    StoreSmi<type, order>(&name##_, value);                                    \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  type name##_;

#define COMPRESSED_SMI_FIELD(type, name)                                       \
 public:                                                                       \
  template <std::memory_order order = std::memory_order_relaxed>               \
  type name() const {                                                          \
    type result = LoadCompressedSmi<order>(&name##_);                          \
    ASSERT(!result.IsHeapObject());                                            \
    return result;                                                             \
  }                                                                            \
  template <std::memory_order order = std::memory_order_relaxed>               \
  void set_##name(type value) {                                                \
    ASSERT(!value.IsHeapObject());                                             \
    StoreCompressedSmi(&name##_, value);                                       \
  }                                                                            \
                                                                               \
 protected:                                                                    \
  Compressed##type name##_;

// Used to define untagged object fields that can have values wrapped in
// WeakSerializationReferences. Since WeakSerializationReferences are only used
// during precompilation, these fields have type CompressedObjectPtr in the
// precompiler and the normally expected type otherwise.
//
// Fields that are defined with WSR_COMPRESSED_POINTER_FIELD should have
// getters and setters that are declared in object.h with
// PRECOMPILER_WSR_FIELD_DECLARATION and defined in object.cc with
// PRECOMPILER_WSR_FIELD_DEFINITION.
#if defined(DART_PRECOMPILER)
#define WSR_COMPRESSED_POINTER_FIELD(Type, Name)                               \
  COMPRESSED_POINTER_FIELD(ObjectPtr, Name)
#else
#define WSR_COMPRESSED_POINTER_FIELD(Type, Name)                               \
  COMPRESSED_POINTER_FIELD(Type, Name)
#endif

class UntaggedClass : public UntaggedObject {
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

  classid_t id() const { return id_; }

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Class);

  COMPRESSED_POINTER_FIELD(StringPtr, name)
  VISIT_FROM(name)
  NOT_IN_PRODUCT(COMPRESSED_POINTER_FIELD(StringPtr, user_name))
  COMPRESSED_POINTER_FIELD(ArrayPtr, functions)
  COMPRESSED_POINTER_FIELD(ArrayPtr, functions_hash_table)
  COMPRESSED_POINTER_FIELD(ArrayPtr, fields)
  COMPRESSED_POINTER_FIELD(ArrayPtr, offset_in_words_to_field)
  COMPRESSED_POINTER_FIELD(ArrayPtr, interfaces)  // Array of AbstractType.
  COMPRESSED_POINTER_FIELD(ScriptPtr, script)
  COMPRESSED_POINTER_FIELD(LibraryPtr, library)
  COMPRESSED_POINTER_FIELD(TypeParametersPtr, type_parameters)
  COMPRESSED_POINTER_FIELD(TypePtr, super_type)
  // Canonicalized const instances of this class.
  COMPRESSED_POINTER_FIELD(ArrayPtr, constants)
  // Declaration type for this class.
  COMPRESSED_POINTER_FIELD(TypePtr, declaration_type)
  // Cache for dispatcher functions.
  COMPRESSED_POINTER_FIELD(ArrayPtr, invocation_dispatcher_cache)

#if !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)
  // Array of Class.
  COMPRESSED_POINTER_FIELD(GrowableObjectArrayPtr, direct_implementors)
  // Array of Class.
  COMPRESSED_POINTER_FIELD(GrowableObjectArrayPtr, direct_subclasses)
#endif  // !defined(PRODUCT) || !defined(DART_PRECOMPILED_RUNTIME)

  // Cached declaration instance type arguments for this class.
  // Not preserved in AOT snapshots.
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr,
                           declaration_instance_type_arguments)
#if !defined(DART_PRECOMPILED_RUNTIME)
  // Stub code for allocation of instances.
  COMPRESSED_POINTER_FIELD(CodePtr, allocation_stub)
  // CHA optimized codes.
  COMPRESSED_POINTER_FIELD(WeakArrayPtr, dependent_code)
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(declaration_instance_type_arguments)
#else
  VISIT_TO(dependent_code)
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
#if defined(PRODUCT)
        return reinterpret_cast<CompressedObjectPtr*>(
            &invocation_dispatcher_cache_);
#else
        return reinterpret_cast<CompressedObjectPtr*>(&direct_subclasses_);
#endif  // defined(PRODUCT)
      case Snapshot::kFull:
      case Snapshot::kFullCore:
#if !defined(DART_PRECOMPILED_RUNTIME)
        return reinterpret_cast<CompressedObjectPtr*>(&allocation_stub_);
#endif
      case Snapshot::kFullJIT:
#if !defined(DART_PRECOMPILED_RUNTIME)
        return reinterpret_cast<CompressedObjectPtr*>(&dependent_code_);
#endif
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }

  NOT_IN_PRECOMPILED(TokenPosition token_pos_);
  NOT_IN_PRECOMPILED(TokenPosition end_token_pos_);
  NOT_IN_PRECOMPILED(classid_t implementor_cid_);

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

#if defined(DART_PRECOMPILER)
  // Size if fixed len or 0 if variable len (target).
  int32_t target_instance_size_in_words_;

  // Offset of type args fld.
  int32_t target_type_arguments_field_offset_in_words_;

  // Offset of the next instance field (target).
  int32_t target_next_field_offset_in_words_;
#endif  // defined(DART_PRECOMPILER)

#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t kernel_offset_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  friend class Instance;
  friend class IsolateGroup;
  friend class Object;
  friend class UntaggedInstance;
  friend class UntaggedInstructions;
  friend class UntaggedTypeArguments;
  friend class MessageSerializer;
  friend class InstanceSerializationCluster;
  friend class TypeSerializationCluster;
  friend class CidRewriteVisitor;
  friend class FinalizeVMIsolateVisitor;
  friend class Api;
};

class UntaggedPatchClass : public UntaggedObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PatchClass);

  COMPRESSED_POINTER_FIELD(ClassPtr, wrapped_class)
  VISIT_FROM(wrapped_class)
  COMPRESSED_POINTER_FIELD(ScriptPtr, script)
#if !defined(DART_PRECOMPILED_RUNTIME)
  COMPRESSED_POINTER_FIELD(KernelProgramInfoPtr, kernel_program_info)
  VISIT_TO(kernel_program_info)
#else
  VISIT_TO(script)
#endif

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<CompressedObjectPtr*>(&script_);
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
#if !defined(DART_PRECOMPILED_RUNTIME)
        return reinterpret_cast<CompressedObjectPtr*>(&kernel_program_info_);
#else
        UNREACHABLE();
        return nullptr;
#endif
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }

  NOT_IN_PRECOMPILED(intptr_t kernel_library_index_);

  friend class Function;
};

class UntaggedFunction : public UntaggedObject {
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
  /* A `dart:ffi` call or callback trampoline. */                              \
  V(FfiTrampoline)                                                             \
  /* getter for a record field */                                              \
  V(RecordFieldGetter)

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
  // return value. Two bits are used for each of them to denote if it is boxed,
  // unboxed integer, unboxed double or unboxed record.
  // It includes the two bits for the receiver, even though currently we
  // do not have information from TFA that allows the receiver to be unboxed.
  class alignas(8) UnboxedParameterBitmap {
   public:
    enum UnboxedState {
      kBoxed,
      kUnboxedInt,
      kUnboxedDouble,
      kUnboxedRecord,
    };
    static constexpr intptr_t kBitsPerElement = 2;
    static constexpr uint64_t kElementBitmask = (1 << kBitsPerElement) - 1;
    static constexpr intptr_t kCapacity =
        (kBitsPerByte * sizeof(uint64_t)) / kBitsPerElement;

    UnboxedParameterBitmap() : bitmap_(0) {}
    explicit UnboxedParameterBitmap(uint64_t bitmap) : bitmap_(bitmap) {}
    UnboxedParameterBitmap(const UnboxedParameterBitmap&) = default;
    UnboxedParameterBitmap& operator=(const UnboxedParameterBitmap&) = default;

    DART_FORCE_INLINE bool IsUnboxed(intptr_t position) const {
      return At(position) != kBoxed;
    }
    DART_FORCE_INLINE bool IsUnboxedInteger(intptr_t position) const {
      return At(position) == kUnboxedInt;
    }
    DART_FORCE_INLINE bool IsUnboxedDouble(intptr_t position) const {
      return At(position) == kUnboxedDouble;
    }
    DART_FORCE_INLINE bool IsUnboxedRecord(intptr_t position) const {
      return At(position) == kUnboxedRecord;
    }
    DART_FORCE_INLINE void SetUnboxedInteger(intptr_t position) {
      SetAt(position, kUnboxedInt);
    }
    DART_FORCE_INLINE void SetUnboxedDouble(intptr_t position) {
      SetAt(position, kUnboxedDouble);
    }
    DART_FORCE_INLINE void SetUnboxedRecord(intptr_t position) {
      SetAt(position, kUnboxedRecord);
    }
    DART_FORCE_INLINE uint64_t Value() const { return bitmap_; }
    DART_FORCE_INLINE bool IsEmpty() const { return bitmap_ == 0; }
    DART_FORCE_INLINE void Reset() { bitmap_ = 0; }
    DART_FORCE_INLINE bool HasUnboxedParameters() const {
      return (bitmap_ >> kBitsPerElement) != 0;
    }

   private:
    DART_FORCE_INLINE UnboxedState At(intptr_t position) const {
      if (position >= kCapacity) {
        return kBoxed;
      }
      return static_cast<UnboxedState>(
          (bitmap_ >> (kBitsPerElement * position)) & kElementBitmask);
    }
    DART_FORCE_INLINE void SetAt(intptr_t position, UnboxedState state) {
      ASSERT(position < kCapacity);
      const intptr_t shift = kBitsPerElement * position;
      bitmap_ = (bitmap_ & ~(kElementBitmask << shift)) |
                (static_cast<decltype(bitmap_)>(state) << shift);
    }

    uint64_t bitmap_;
  };

 private:
  friend class Class;
  friend class UnitDeserializationRoots;

  RAW_HEAP_OBJECT_IMPLEMENTATION(Function);

  uword entry_point_;            // Accessed from generated code.
  uword unchecked_entry_point_;  // Accessed from generated code.

  COMPRESSED_POINTER_FIELD(StringPtr, name)
  VISIT_FROM(name)
  // Class or patch class or mixin class where this function is defined.
  COMPRESSED_POINTER_FIELD(ObjectPtr, owner)
  WSR_COMPRESSED_POINTER_FIELD(FunctionTypePtr, signature)
  // Additional data specific to the function kind. See Function::set_data()
  // for details.
  COMPRESSED_POINTER_FIELD(ObjectPtr, data)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
        return reinterpret_cast<CompressedObjectPtr*>(&data_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  // ICData of unoptimized code.
  COMPRESSED_POINTER_FIELD(ArrayPtr, ic_data_array);
  // Currently active code. Accessed from generated code.
  COMPRESSED_POINTER_FIELD(CodePtr, code);
#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(code);
#else
  // Positional parameter names are not needed in the AOT runtime.
  COMPRESSED_POINTER_FIELD(ArrayPtr, positional_parameter_names);
  // Unoptimized code, keep it after optimization.
  COMPRESSED_POINTER_FIELD(CodePtr, unoptimized_code);
  VISIT_TO(unoptimized_code);

  UnboxedParameterBitmap unboxed_parameters_info_;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME) ||                                      \
    (defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT))
  TokenPosition token_pos_;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  TokenPosition end_token_pos_;
#endif

  AtomicBitFieldContainer<uint32_t> kind_tag_;  // See Function::KindTagBits.

#define JIT_FUNCTION_COUNTERS(F)                                               \
  F(intptr_t, int32_t, usage_counter)                                          \
  F(intptr_t, uint16_t, optimized_instruction_count)                           \
  F(intptr_t, uint16_t, optimized_call_site_count)                             \
  F(int8_t, int8_t, deoptimization_counter)                                    \
  F(intptr_t, int8_t, state_bits)                                              \
  F(int, int8_t, inlining_depth)

#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t kernel_offset_;

#define DECLARE(return_type, type, name) type name##_;
  JIT_FUNCTION_COUNTERS(DECLARE)
#undef DECLARE

  AtomicBitFieldContainer<uint8_t> packed_fields_;

  static constexpr intptr_t kMaxOptimizableBits = 1;

  using PackedOptimizable =
      BitField<decltype(packed_fields_), bool, 0, kMaxOptimizableBits>;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
};

class UntaggedClosureData : public UntaggedObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ClosureData);

  COMPRESSED_POINTER_FIELD(ContextScopePtr, context_scope)
  VISIT_FROM(context_scope)
  // Enclosing function of this local function.
  WSR_COMPRESSED_POINTER_FIELD(FunctionPtr, parent_function)
  // Closure object for static implicit closures.
  COMPRESSED_POINTER_FIELD(ClosurePtr, closure)
  VISIT_TO(closure)

  enum class DefaultTypeArgumentsKind : uint8_t {
    // Only here to make sure it's explicitly set appropriately.
    kInvalid = 0,
    // Must instantiate the default type arguments before use.
    kNeedsInstantiation,
    // The default type arguments are already instantiated.
    kIsInstantiated,
    // Use the instantiator type arguments that would be used to instantiate
    // the default type arguments, as instantiating produces the same result.
    kSharesInstantiatorTypeArguments,
    // Use the function type arguments that would be used to instantiate
    // the default type arguments, as instantiating produces the same result.
    kSharesFunctionTypeArguments,
  };

  // kernel_to_il.cc assumes we can load the untagged value and box it in a Smi.
  static_assert(sizeof(DefaultTypeArgumentsKind) * kBitsPerByte <=
                    compiler::target::kSmiBits,
                "Default type arguments kind must fit in a Smi");

  static constexpr uint8_t kNoAwaiterLinkDepth = 0xFF;

  AtomicBitFieldContainer<uint32_t> packed_fields_;

  using PackedDefaultTypeArgumentsKind =
      BitField<decltype(packed_fields_), DefaultTypeArgumentsKind, 0, 8>;
  using PackedAwaiterLinkDepth =
      BitField<decltype(packed_fields_),
               uint8_t,
               PackedDefaultTypeArgumentsKind::kNextBit,
               8>;
  using PackedAwaiterLinkIndex = BitField<decltype(packed_fields_),
                                          uint8_t,
                                          PackedAwaiterLinkDepth::kNextBit,
                                          8>;

  friend class Function;
  friend class UnitDeserializationRoots;
};

class UntaggedFfiTrampolineData : public UntaggedObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(FfiTrampolineData);

  COMPRESSED_POINTER_FIELD(TypePtr, signature_type)
  VISIT_FROM(signature_type)

  COMPRESSED_POINTER_FIELD(FunctionTypePtr, c_signature)

  // Target Dart method for callbacks, otherwise null.
  COMPRESSED_POINTER_FIELD(FunctionPtr, callback_target)

  // For callbacks, value to return if Dart target throws an exception.
  COMPRESSED_POINTER_FIELD(InstancePtr, callback_exceptional_return)
  VISIT_TO(callback_exceptional_return)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Callback id for callbacks.
  //
  // The callbacks ids are used so that native callbacks can lookup their own
  // code objects, since native code doesn't pass code objects into function
  // calls. The callback id is also used to for verifying that callbacks are
  // called on the correct isolate. See DLRT_VerifyCallbackIsolate for details.
  //
  // Callback id is -1 for non-callbacks or when id is not allocated yet.
  // Check 'callback_target_' to determine if this is a callback or not.
  int32_t callback_id_;

  // Whether this is a leaf call - i.e. one that doesn't call back into Dart.
  bool is_leaf_;

  // The kind of trampoline this is. See FfiFunctionKind.
  uint8_t ffi_function_kind_;
};

class UntaggedField : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Field);

  COMPRESSED_POINTER_FIELD(StringPtr, name)
  VISIT_FROM(name)
  // Class or patch class or mixin class where this field is defined or original
  // field.
  COMPRESSED_POINTER_FIELD(ObjectPtr, owner)
  COMPRESSED_POINTER_FIELD(AbstractTypePtr, type)
  // Static initializer function.
  COMPRESSED_POINTER_FIELD(FunctionPtr, initializer_function)
  // - for instance fields: offset in words to the value in the class instance.
  // - for static fields: index into field_table.
  COMPRESSED_POINTER_FIELD(SmiPtr, host_offset_or_field_id)
  COMPRESSED_POINTER_FIELD(SmiPtr, guarded_list_length)
  COMPRESSED_POINTER_FIELD(WeakArrayPtr, dependent_code)
  VISIT_TO(dependent_code);
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
      case Snapshot::kFullAOT:
        return reinterpret_cast<CompressedObjectPtr*>(&initializer_function_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  TokenPosition token_pos_;
  TokenPosition end_token_pos_;
  ClassIdTagType guarded_cid_;
  ClassIdTagType is_nullable_;  // kNullCid if field can contain null value and
                                // kIllegalCid otherwise.

#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t kernel_offset_;
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
  friend class StoreFieldInstr;          // For sizeof(guarded_cid_/...)
};

class alignas(8) UntaggedScript : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Script);

  COMPRESSED_POINTER_FIELD(StringPtr, url)
  VISIT_FROM(url)
  COMPRESSED_POINTER_FIELD(StringPtr, resolved_url)
  COMPRESSED_POINTER_FIELD(TypedDataPtr, line_starts)
#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  COMPRESSED_POINTER_FIELD(TypedDataViewPtr, constant_coverage)
#endif  // !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  COMPRESSED_POINTER_FIELD(ArrayPtr, debug_positions)
  COMPRESSED_POINTER_FIELD(KernelProgramInfoPtr, kernel_program_info)
  COMPRESSED_POINTER_FIELD(StringPtr, source)
  VISIT_TO(source)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
#if defined(PRODUCT)
        return reinterpret_cast<CompressedObjectPtr*>(&url_);
#else
        return reinterpret_cast<CompressedObjectPtr*>(&resolved_url_);
#endif
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
        return reinterpret_cast<CompressedObjectPtr*>(&kernel_program_info_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  int64_t load_timestamp_;
  int32_t kernel_script_index_;
#else
  int32_t kernel_script_index_;
  int64_t load_timestamp_;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
  int32_t flags_and_max_position_;

 public:
  using LazyLookupSourceAndLineStartsBit =
      BitField<decltype(flags_and_max_position_), bool, 0, 1>;
  using HasCachedMaxPositionBit =
      BitField<decltype(flags_and_max_position_),
               bool,
               LazyLookupSourceAndLineStartsBit::kNextBit,
               1>;
  using CachedMaxPositionBitField = BitField<decltype(flags_and_max_position_),
                                             intptr_t,
                                             HasCachedMaxPositionBit::kNextBit>;

 private:
#endif
};

class UntaggedLibrary : public UntaggedObject {
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

  COMPRESSED_POINTER_FIELD(StringPtr, name)
  VISIT_FROM(name)
  COMPRESSED_POINTER_FIELD(StringPtr, url)
  COMPRESSED_POINTER_FIELD(StringPtr, private_key)
  // Top-level names in this library.
  COMPRESSED_POINTER_FIELD(ArrayPtr, dictionary)
  // Metadata on classes, methods etc.
  COMPRESSED_POINTER_FIELD(ArrayPtr, metadata)
  // Class containing top-level elements.
  COMPRESSED_POINTER_FIELD(ClassPtr, toplevel_class)
  COMPRESSED_POINTER_FIELD(GrowableObjectArrayPtr, used_scripts)
  COMPRESSED_POINTER_FIELD(LoadingUnitPtr, loading_unit)
  // List of Namespaces imported without prefix.
  COMPRESSED_POINTER_FIELD(ArrayPtr, imports)
  // List of re-exported Namespaces.
  COMPRESSED_POINTER_FIELD(ArrayPtr, exports)
  COMPRESSED_POINTER_FIELD(ArrayPtr, dependencies)
#if !defined(DART_PRECOMPILED_RUNTIME)
  COMPRESSED_POINTER_FIELD(KernelProgramInfoPtr, kernel_program_info)
#endif
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<CompressedObjectPtr*>(&exports_);
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
#if !defined(DART_PRECOMPILED_RUNTIME)
        return reinterpret_cast<CompressedObjectPtr*>(&kernel_program_info_);
#else
        UNREACHABLE();
        return nullptr;
#endif
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  // Array of scripts loaded in this library.
  COMPRESSED_POINTER_FIELD(ArrayPtr, loaded_scripts);
  VISIT_TO(loaded_scripts);

  Dart_NativeEntryResolver native_entry_resolver_;  // Resolves natives.
  Dart_NativeEntrySymbol native_entry_symbol_resolver_;
  Dart_FfiNativeResolver ffi_native_resolver_;

  classid_t index_;       // Library id number.
  uint16_t num_imports_;  // Number of entries in imports_.
  int8_t load_state_;     // Of type LibraryState.
  uint8_t flags_;         // BitField for LibraryFlags.

#if !defined(DART_PRECOMPILED_RUNTIME)
  uint32_t kernel_library_index_;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  friend class Class;
  friend class Isolate;
};

class UntaggedNamespace : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Namespace);

  // library with name dictionary.
  COMPRESSED_POINTER_FIELD(LibraryPtr, target)
  VISIT_FROM(target)
  // list of names that are exported.
  COMPRESSED_POINTER_FIELD(ArrayPtr, show_names)
  // list of names that are hidden.
  COMPRESSED_POINTER_FIELD(ArrayPtr, hide_names)
  COMPRESSED_POINTER_FIELD(LibraryPtr, owner)
  VISIT_TO(owner)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<CompressedObjectPtr*>(&target_);
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
        return reinterpret_cast<CompressedObjectPtr*>(&owner_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
};

// Contains information about a kernel [Component].
//
// Used to access string tables, canonical name tables, constants, metadata, ...
class UntaggedKernelProgramInfo : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(KernelProgramInfo);

  COMPRESSED_POINTER_FIELD(TypedDataBasePtr, kernel_component)
  VISIT_FROM(kernel_component)
  COMPRESSED_POINTER_FIELD(TypedDataPtr, string_offsets)
  COMPRESSED_POINTER_FIELD(TypedDataViewPtr, string_data)
  COMPRESSED_POINTER_FIELD(TypedDataPtr, canonical_names)
  COMPRESSED_POINTER_FIELD(TypedDataViewPtr, metadata_payloads)
  COMPRESSED_POINTER_FIELD(TypedDataViewPtr, metadata_mappings)
  COMPRESSED_POINTER_FIELD(ArrayPtr, scripts)
  COMPRESSED_POINTER_FIELD(ArrayPtr, constants)
  COMPRESSED_POINTER_FIELD(TypedDataViewPtr, constants_table)
  COMPRESSED_POINTER_FIELD(ArrayPtr, libraries_cache)
  COMPRESSED_POINTER_FIELD(ArrayPtr, classes_cache)
  VISIT_TO(classes_cache)

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    return reinterpret_cast<CompressedObjectPtr*>(&constants_table_);
  }
};

class UntaggedWeakSerializationReference : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakSerializationReference);

  COMPRESSED_POINTER_FIELD(ObjectPtr, target)
  VISIT_FROM(target)
  COMPRESSED_POINTER_FIELD(ObjectPtr, replacement)
  VISIT_TO(replacement)
};

class UntaggedWeakArray : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakArray);

  COMPRESSED_POINTER_FIELD(WeakArrayPtr, next_seen_by_gc)

  COMPRESSED_SMI_FIELD(SmiPtr, length)
  VISIT_FROM(length)
  // Variable length data follows here.
  COMPRESSED_VARIABLE_POINTER_FIELDS(ObjectPtr, element, data)

  template <typename Table, bool kAllCanonicalObjectsAreIncludedIntoSet>
  friend class CanonicalSetDeserializationCluster;
  template <typename Type, typename PtrType>
  friend class GCLinkedList;
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class Scavenger;
};

// WeakArray is special in that it has a pointer field which is not
// traversed by pointer visitors, and thus not in the range [from(),to()]:
// next_seen_by_gc, which is before the other fields.
template <>
DART_FORCE_INLINE uword UntaggedObject::from_offset<UntaggedWeakArray>() {
  return OFFSET_OF(UntaggedWeakArray, next_seen_by_gc_);
}

class UntaggedCode : public UntaggedObject {
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

  POINTER_FIELD(ObjectPoolPtr, object_pool)  // Accessed from generated code.
  VISIT_FROM(object_pool)
  POINTER_FIELD(InstructionsPtr,
                instructions)  // Accessed from generated code.
  // If owner_ is Function::null() the owner is a regular stub.
  // If owner_ is a Class the owner is the allocation stub for that class.
  // Else, owner_ is a regular Dart Function.
  POINTER_FIELD(ObjectPtr, owner)  // Function, Null, or a Class.
  POINTER_FIELD(ExceptionHandlersPtr, exception_handlers)
  POINTER_FIELD(PcDescriptorsPtr, pc_descriptors)
  // If FLAG_precompiled_mode, then this field contains
  //   TypedDataPtr catch_entry_moves_maps
  // Otherwise, it is
  //   SmiPtr num_variables
  POINTER_FIELD(ObjectPtr, catch_entry)
  POINTER_FIELD(CompressedStackMapsPtr, compressed_stackmaps)
  POINTER_FIELD(ArrayPtr, inlined_id_to_function)
  POINTER_FIELD(CodeSourceMapPtr, code_source_map)
  NOT_IN_PRECOMPILED(POINTER_FIELD(InstructionsPtr, active_instructions))
  NOT_IN_PRECOMPILED(POINTER_FIELD(ArrayPtr, deopt_info_array))
  // (code-offset, function, code) triples.
  NOT_IN_PRECOMPILED(POINTER_FIELD(ArrayPtr, static_calls_target_table))
  // If return_address_metadata_ is a Smi, it is the offset to the prologue.
  // Else, return_address_metadata_ is null.
  NOT_IN_PRODUCT(POINTER_FIELD(ObjectPtr, return_address_metadata))
  NOT_IN_PRODUCT(POINTER_FIELD(LocalVarDescriptorsPtr, var_descriptors))
  NOT_IN_PRODUCT(POINTER_FIELD(ArrayPtr, comments))

#if !defined(PRODUCT)
  VISIT_TO(comments);
#elif defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(code_source_map);
#else
  VISIT_TO(static_calls_target_table);
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
  friend class UnitSerializationRoots;
  friend class UnitDeserializationRoots;
  friend class CallSiteResetter;
};

class UntaggedObjectPool : public UntaggedObject {
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
  DEFINE_CONTAINS_COMPRESSED(decltype(Entry::raw_obj_));

  // The entry bits are located after the last entry. They are encoded versions
  // of `ObjectPool::TypeBits() | ObjectPool::PatchabilityBit()`.
  uint8_t* entry_bits() { return reinterpret_cast<uint8_t*>(&data()[length_]); }
  uint8_t const* entry_bits() const {
    return reinterpret_cast<uint8_t const*>(&data()[length_]);
  }

  friend class Object;
  friend class CodeSerializationCluster;
  friend class UnitSerializationRoots;
  friend class UnitDeserializationRoots;
};

class UntaggedInstructions : public UntaggedObject {
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

  friend class UntaggedCode;
  friend class UntaggedFunction;
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

// Used to carry extra information to the VM without changing the embedder
// interface, to provide memory accounting for the bare instruction payloads
// we serialize, since they are no longer part of RawInstructions objects,
// and to avoid special casing bare instructions payload Images in the GC.
class UntaggedInstructionsSection : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(InstructionsSection);
  VISIT_NOTHING();

  // Instructions section payload length in bytes.
  uword payload_length_;
  // The offset of the corresponding BSS section from this text section.
  word bss_offset_;
  // The relocated address of this text section in the shared object. Properly
  // filled for ELF snapshots, always 0 in assembly snapshots. (For the latter,
  // we instead get the value during BSS initialization and store it there.)
  uword instructions_relocated_address_;
  // The offset of the GNU build ID note section from this text section.
  word build_id_offset_;

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class Image;
};

class UntaggedPcDescriptors : public UntaggedObject {
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

  // Used to represent the absence of a yield index in PcDescriptors.
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
    static constexpr intptr_t kKindShiftSize = 3;
    static constexpr intptr_t kTryIndexSize = 10;
    static constexpr intptr_t kYieldIndexSize =
        32 - kKindShiftSize - kTryIndexSize;

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
class UntaggedCodeSourceMap : public UntaggedObject {
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
class UntaggedCompressedStackMaps : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(CompressedStackMaps);
  VISIT_NOTHING();

 public:
  // Note: AOT snapshots pack these structures without any padding in between
  // so payload structure should not have any alignment requirements.
  // alignas(1) is here to trigger a compiler error if we violate this.
  struct alignas(1) Payload {
    using FlagsAndSizeHeader = uint32_t;

    // The most significant bits are the length of the encoded payload, in
    // bytes (excluding the header itself). The low bits determine the
    // expected payload contents, as described below.
    DART_FORCE_INLINE FlagsAndSizeHeader flags_and_size() const {
      // Note: |this| does not necessarily satisfy alignment requirements
      // of uint32_t so we should use bit_cast.
      return bit_copy<FlagsAndSizeHeader, Payload>(*this);
    }

    DART_FORCE_INLINE void set_flags_and_size(FlagsAndSizeHeader value) {
      // Note: |this| does not necessarily satisfy alignment requirements
      // of uint32_t hence the byte copy below.
      memcpy(reinterpret_cast<void*>(this), &value, sizeof(value));  // NOLINT
    }

    // Variable length data follows here. The contents of the payload depend on
    // the type of CompressedStackMaps (CSM) being represented. There are three
    // major types of CSM:
    //
    // 1) GlobalTableBit = false, UsesTableBit = false: CSMs that include all
    //    information about the stack maps. The payload for these contain
    //    tightly packed entries with the following information:
    //
    //   * A header containing the following three pieces of information:
    //     * An unsigned integer representing the PC offset as a delta from the
    //       PC offset of the previous entry (from 0 for the first entry).
    //     * An unsigned integer representing the number of bits used for
    //       spill slot entries.
    //     * An unsigned integer representing the number of bits used for other
    //       entries.
    //   * The body containing the bits for the stack map. The length of
    //     the body in bits is the sum of the spill slot and non-spill slot
    //     bit counts.
    //
    // 2) GlobalTableBit = false, UsesTableBit = true: CSMs where the majority
    //    of the stack map information has been offloaded and canonicalized into
    //    a global table. The payload contains tightly packed entries with the
    //    following information:
    //
    //   * A header containing just an unsigned integer representing the PC
    //     offset delta as described above.
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
    //   * The body containing the bits for the stack map. The length of the
    //     body in bits is the sum of the spill slot and non-spill slot bit
    //     counts.
    //
    // In all types of CSM, each unsigned integer is LEB128 encoded, as
    // generally they tend to fit in a single byte or two. Thus, entry headers
    // are not a fixed length, and currently there is no random access of
    // entries.  In addition, PC offsets are currently encoded as deltas, which
    // also inhibits random access without accessing previous entries. That
    // means to find an entry for a given PC offset, a linear search must be
    // done where the payload is decoded up to the entry whose PC offset
    // is greater or equal to the given PC.

    uint8_t* data() {
      return reinterpret_cast<uint8_t*>(this) + sizeof(FlagsAndSizeHeader);
    }

    const uint8_t* data() const {
      return reinterpret_cast<const uint8_t*>(this) +
             sizeof(FlagsAndSizeHeader);
    }
  };

 private:
  // We are using OPEN_ARRAY_START rather than embedding Payload directly into
  // the UntaggedCompressedStackMaps as a field because that would introduce a
  // padding at the end of UntaggedCompressedStackMaps - so we would not be
  // able to use sizeof(UntaggedCompressedStackMaps) as the size of the header
  // anyway.
  Payload* payload() { OPEN_ARRAY_START(Payload, uint8_t); }
  const Payload* payload() const { OPEN_ARRAY_START(Payload, uint8_t); }

  class GlobalTableBit
      : public BitField<Payload::FlagsAndSizeHeader, bool, 0, 1> {};
  class UsesTableBit : public BitField<Payload::FlagsAndSizeHeader,
                                       bool,
                                       GlobalTableBit::kNextBit,
                                       1> {};
  class SizeField
      : public BitField<Payload::FlagsAndSizeHeader,
                        Payload::FlagsAndSizeHeader,
                        UsesTableBit::kNextBit,
                        sizeof(Payload::FlagsAndSizeHeader) * kBitsPerByte -
                            UsesTableBit::kNextBit> {};

  friend class Object;
  friend class ImageWriter;
  friend class StackMapEntry;
};

class UntaggedInstructionsTable : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(InstructionsTable);

  POINTER_FIELD(ArrayPtr, code_objects)
  VISIT_FROM(code_objects)
  VISIT_TO(code_objects)

  struct DataEntry {
    uint32_t pc_offset;
    uint32_t stack_map_offset;
  };
  static_assert(sizeof(DataEntry) == sizeof(uint32_t) * 2);

  struct Data {
    uint32_t canonical_stack_map_entries_offset;
    uint32_t length;
    uint32_t first_entry_with_code;
    uint32_t padding;

    const DataEntry* entries() const { OPEN_ARRAY_START(DataEntry, uint32_t); }

    const UntaggedCompressedStackMaps::Payload* StackMapAt(
        intptr_t offset) const {
      return reinterpret_cast<UntaggedCompressedStackMaps::Payload*>(
          reinterpret_cast<uword>(this) + offset);
    }
  };
  static_assert(sizeof(Data) == sizeof(uint32_t) * 4);

  intptr_t length_;
  const Data* rodata_;
  uword start_pc_;
  uword end_pc_;

  friend class Deserializer;
};

class UntaggedLocalVarDescriptors : public UntaggedObject {
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
    int32_t index_kind = 0;  // Bitfield for slot index on stack or in context,
                             // and Entry kind of type VarInfoKind.
    TokenPosition declaration_pos =
        TokenPosition::kNoSource;  // Token position of declaration.
    TokenPosition begin_pos =
        TokenPosition::kNoSource;  // Token position of scope start.
    TokenPosition end_pos =
        TokenPosition::kNoSource;  // Token position of scope end.
    int16_t scope_id;              // Scope to which the variable belongs.

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

  VISIT_FROM_PAYLOAD_START(CompressedStringPtr)
  COMPRESSED_VARIABLE_POINTER_FIELDS(StringPtr, name, names)

  CompressedStringPtr* nameAddrAt(intptr_t i) { return &(names()[i]); }
  void set_name(intptr_t i, StringPtr value) {
    StoreCompressedPointer(nameAddrAt(i), value);
  }

  // Variable info with [num_entries_] entries.
  VarInfo* data() {
    return reinterpret_cast<VarInfo*>(nameAddrAt(num_entries_));
  }

  friend class Object;
};

class UntaggedExceptionHandlers : public UntaggedObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers);

  // Number of exception handler entries and
  // async handler.
  uint32_t packed_fields_;

  // Async handler is used in the async/async* functions.
  // It's an implicit exception handler (stub) which runs when
  // exception is not handled within the function.
  using AsyncHandlerBit = BitField<decltype(packed_fields_), bool, 0, 1>;
  using NumEntriesBits = BitField<decltype(packed_fields_),
                                  uint32_t,
                                  AsyncHandlerBit::kNextBit,
                                  31>;

  intptr_t num_entries() const {
    return NumEntriesBits::decode(packed_fields_);
  }

  // Array with [num_entries] entries. Each entry is an array of all handled
  // exception types.
  COMPRESSED_POINTER_FIELD(ArrayPtr, handled_types_data)
  VISIT_FROM(handled_types_data)
  VISIT_TO(handled_types_data)

  // Exception handler info of length [num_entries].
  const ExceptionHandlerInfo* data() const {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }
  ExceptionHandlerInfo* data() {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }

  friend class Object;
};

class UntaggedContext : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Context);

  int32_t num_variables_;

  COMPRESSED_POINTER_FIELD(ContextPtr, parent)
  VISIT_FROM(parent)
  // Variable length data follows here.
  COMPRESSED_VARIABLE_POINTER_FIELDS(ObjectPtr, element, data)

  friend class Object;
  friend void UpdateLengthField(intptr_t,
                                ObjectPtr,
                                ObjectPtr);  // num_variables_
};

#define CONTEXT_SCOPE_VARIABLE_DESC_FLAG_LIST(V)                               \
  V(Final)                                                                     \
  V(Late)                                                                      \
  V(Nullable)                                                                  \
  V(Invisible)                                                                 \
  V(AwaiterLink)

class UntaggedContextScope : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ContextScope);

  // TODO(iposva): Switch to conventional enum offset based structure to avoid
  // alignment mishaps.
  struct VariableDesc {
    CompressedSmiPtr declaration_token_pos;
    CompressedSmiPtr token_pos;
    CompressedStringPtr name;
    CompressedSmiPtr flags;
    enum FlagBits {
#define DECLARE_BIT(Name) kIs##Name,
      CONTEXT_SCOPE_VARIABLE_DESC_FLAG_LIST(DECLARE_BIT)
#undef DECLARE_BIT
    };
    CompressedSmiPtr late_init_offset;
    CompressedAbstractTypePtr type;
    CompressedSmiPtr cid;
    CompressedSmiPtr context_index;
    CompressedSmiPtr context_level;
    CompressedSmiPtr kernel_offset;
  };

  int32_t num_variables_;
  bool is_implicit_;  // true, if this context scope is for an implicit closure.

  // Just choose one of the fields in VariableDesc, since they should all be
  // compressed or not compressed.
  DEFINE_CONTAINS_COMPRESSED(decltype(VariableDesc::name));

  CompressedObjectPtr* from() {
    VariableDesc* begin = const_cast<VariableDesc*>(VariableDescAddr(0));
    return reinterpret_cast<CompressedObjectPtr*>(begin);
  }
  // Variable length data follows here.
  CompressedObjectPtr const* data() const {
    OPEN_ARRAY_START(CompressedObjectPtr, CompressedObjectPtr);
  }
  const VariableDesc* VariableDescAddr(intptr_t index) const {
    // data() points to the first component of the first descriptor.
    return reinterpret_cast<const VariableDesc*>(data()) + index;
  }

#define DEFINE_ACCESSOR(type, name)                                            \
  type name##_at(intptr_t index) {                                             \
    return LoadCompressedPointer<type>(&VariableDescAddr(index)->name);        \
  }                                                                            \
  void set_##name##_at(intptr_t index, type value) {                           \
    StoreCompressedPointer(&VariableDescAddr(index)->name, value);             \
  }
  DEFINE_ACCESSOR(SmiPtr, declaration_token_pos)
  DEFINE_ACCESSOR(SmiPtr, token_pos)
  DEFINE_ACCESSOR(StringPtr, name)
  DEFINE_ACCESSOR(SmiPtr, flags)
  DEFINE_ACCESSOR(SmiPtr, late_init_offset)
  DEFINE_ACCESSOR(AbstractTypePtr, type)
  DEFINE_ACCESSOR(SmiPtr, cid)
  DEFINE_ACCESSOR(SmiPtr, context_index)
  DEFINE_ACCESSOR(SmiPtr, context_level)
  DEFINE_ACCESSOR(SmiPtr, kernel_offset)
#undef DEFINE_ACCESSOR

  CompressedObjectPtr* to(intptr_t num_vars) {
    uword end = reinterpret_cast<uword>(VariableDescAddr(num_vars));
    // 'end' is the address just beyond the last descriptor, so step back.
    return reinterpret_cast<CompressedObjectPtr*>(end -
                                                  sizeof(CompressedObjectPtr));
  }
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind, intptr_t num_vars) {
    return to(num_vars);
  }

  friend class Object;
  friend class UntaggedClosureData;
};

class UntaggedSentinel : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Sentinel);
  VISIT_NOTHING();
};

class UntaggedSingleTargetCache : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache);
  POINTER_FIELD(CodePtr, target)
  VISIT_FROM(target)
  VISIT_TO(target)
  uword entry_point_;
  ClassIdTagType lower_limit_;
  ClassIdTagType upper_limit_;
};

class UntaggedMonomorphicSmiableCall : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MonomorphicSmiableCall);
  VISIT_NOTHING();

  uword expected_cid_;
  uword entrypoint_;
};

// Abstract base class for RawICData/RawMegamorphicCache
class UntaggedCallSiteData : public UntaggedObject {
 protected:
  POINTER_FIELD(StringPtr, target_name);  // Name of target function.
  VISIT_FROM(target_name)
  // arg_descriptor in RawICData and in RawMegamorphicCache should be
  // in the same position so that NoSuchMethod can access it.
  POINTER_FIELD(ArrayPtr, args_descriptor);  // Arguments descriptor.
  VISIT_TO(args_descriptor)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(CallSiteData)
};

class UntaggedUnlinkedCall : public UntaggedCallSiteData {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnlinkedCall);

  bool can_patch_to_monomorphic_;
};

class UntaggedICData : public UntaggedCallSiteData {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ICData);
  POINTER_FIELD(ArrayPtr, entries)  // Contains class-ids, target and count.
  // Static type of the receiver, if instance call and available.
  NOT_IN_PRECOMPILED(POINTER_FIELD(AbstractTypePtr, receivers_static_type))
  POINTER_FIELD(ObjectPtr,
                owner)  // Parent/calling function or original IC of cloned IC.
  VISIT_TO(owner)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<ObjectPtr*>(&entries_);
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
        return to();
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  NOT_IN_PRECOMPILED(int32_t deopt_id_);
  // Number of arguments tested in IC, deopt reasons.
  AtomicBitFieldContainer<uint32_t> state_bits_;
};

class UntaggedMegamorphicCache : public UntaggedCallSiteData {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache);

  POINTER_FIELD(ArrayPtr, buckets)
  SMI_FIELD(SmiPtr, mask)
  VISIT_TO(mask)
  ObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  int32_t filled_entry_count_;
};

class UntaggedSubtypeTestCache : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache);

  POINTER_FIELD(ArrayPtr, cache)
  VISIT_FROM(cache)
  VISIT_TO(cache)
  uint32_t num_inputs_;
  uint32_t num_occupied_;
};

class UntaggedLoadingUnit : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LoadingUnit);

  COMPRESSED_POINTER_FIELD(LoadingUnitPtr, parent)
  VISIT_FROM(parent)
  COMPRESSED_POINTER_FIELD(ArrayPtr, base_objects)
  VISIT_TO(base_objects)
  int32_t id_;
  bool load_outstanding_;
  bool loaded_;
};

class UntaggedError : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Error);
};

class UntaggedApiError : public UntaggedError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ApiError);

  COMPRESSED_POINTER_FIELD(StringPtr, message)
  VISIT_FROM(message)
  VISIT_TO(message)
};

class UntaggedLanguageError : public UntaggedError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LanguageError);

  COMPRESSED_POINTER_FIELD(ErrorPtr, previous_error)  // May be null.
  VISIT_FROM(previous_error)
  COMPRESSED_POINTER_FIELD(ScriptPtr, script)
  COMPRESSED_POINTER_FIELD(StringPtr, message)
  // Incl. previous error's formatted message.
  COMPRESSED_POINTER_FIELD(StringPtr, formatted_message)
  VISIT_TO(formatted_message)
  TokenPosition token_pos_;  // Source position in script_.
  bool report_after_token_;  // Report message at or after the token.
  int8_t kind_;              // Of type Report::Kind.

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class UntaggedUnhandledException : public UntaggedError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnhandledException);

  COMPRESSED_POINTER_FIELD(InstancePtr, exception)
  VISIT_FROM(exception)
  COMPRESSED_POINTER_FIELD(InstancePtr, stacktrace)
  VISIT_TO(stacktrace)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class UntaggedUnwindError : public UntaggedError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnwindError);

  COMPRESSED_POINTER_FIELD(StringPtr, message)
  VISIT_FROM(message)
  VISIT_TO(message)
  bool is_user_initiated_;
};

class UntaggedInstance : public UntaggedObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instance);
  friend class Object;

 public:
#if defined(DART_COMPRESSED_POINTERS)
  static constexpr bool kContainsCompressedPointers = true;
#else
  static constexpr bool kContainsCompressedPointers = false;
#endif
};

class UntaggedLibraryPrefix : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix);

  // Library prefix name.
  COMPRESSED_POINTER_FIELD(StringPtr, name)
  VISIT_FROM(name)
  // Libraries imported with this prefix.
  COMPRESSED_POINTER_FIELD(ArrayPtr, imports)
  // Library which declares this prefix.
  COMPRESSED_POINTER_FIELD(LibraryPtr, importer)
  VISIT_TO(importer)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<CompressedObjectPtr*>(&imports_);
      case Snapshot::kFull:
      case Snapshot::kFullCore:
      case Snapshot::kFullJIT:
        return reinterpret_cast<CompressedObjectPtr*>(&importer_);
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return nullptr;
  }
  uint16_t num_imports_;  // Number of library entries in libraries_.
  bool is_deferred_load_;
};

class UntaggedTypeArguments : public UntaggedInstance {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeArguments);

  // The instantiations_ array remains empty for instantiated type arguments.
  // Of 3-tuple: 2 instantiators, result.
  COMPRESSED_POINTER_FIELD(ArrayPtr, instantiations)
  VISIT_FROM(instantiations)
  COMPRESSED_SMI_FIELD(SmiPtr, length)
  COMPRESSED_SMI_FIELD(SmiPtr, hash)
  COMPRESSED_SMI_FIELD(SmiPtr, nullability)
  // Variable length data follows here.
  COMPRESSED_VARIABLE_POINTER_FIELDS(AbstractTypePtr, element, types)

  friend class Object;
};

class UntaggedTypeParameters : public UntaggedObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameters);

  // Length of names reflects the number of type parameters.
  COMPRESSED_POINTER_FIELD(ArrayPtr, names)
  VISIT_FROM(names)
  // flags: isGenericCovariantImpl and (todo) variance.
  COMPRESSED_POINTER_FIELD(ArrayPtr, flags)
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, bounds)
  // defaults is the instantiation to bounds (calculated by CFE).
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, defaults)
  VISIT_TO(defaults)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class Object;
};

class UntaggedAbstractType : public UntaggedInstance {
 protected:
  // Accessed from generated code.
  std::atomic<uword> type_test_stub_entry_point_;
  // Accessed from generated code.
  std::atomic<uint32_t> flags_;
#if defined(DART_COMPRESSED_POINTERS)
  uint32_t padding_;  // Makes Windows and Posix agree on layout.
#endif
  COMPRESSED_POINTER_FIELD(CodePtr, type_test_stub)
  COMPRESSED_POINTER_FIELD(SmiPtr, hash)
  VISIT_FROM(type_test_stub)

  uint32_t flags() const { return flags_.load(std::memory_order_relaxed); }
  void set_flags(uint32_t value) {
    flags_.store(value, std::memory_order_relaxed);
  }

 public:
  enum TypeState {
    kAllocated,                // Initial state.
    kFinalizedInstantiated,    // Instantiated type ready for use.
    kFinalizedUninstantiated,  // Uninstantiated type ready for use.
  };

  using NullabilityBits = BitField<uint32_t, uint8_t, 0, 2>;
  static constexpr intptr_t kNullabilityMask = NullabilityBits::mask();

  static constexpr intptr_t kTypeStateShift = NullabilityBits::kNextBit;
  static constexpr intptr_t kTypeStateBits = 2;
  using TypeStateBits =
      BitField<uint32_t, uint8_t, kTypeStateShift, kTypeStateBits>;

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(AbstractType);

  friend class ObjectStore;
  friend class StubCode;
};

class UntaggedType : public UntaggedAbstractType {
 public:
  static constexpr intptr_t kTypeClassIdShift = TypeStateBits::kNextBit;
  using TypeClassIdBits =
      BitField<uint32_t, ClassIdTagType, kTypeClassIdShift, kClassIdTagSize>;

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Type);

  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, arguments)
  VISIT_TO(arguments)

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  ClassIdTagType type_class_id() const {
    return TypeClassIdBits::decode(flags());
  }
  void set_type_class_id(ClassIdTagType value) {
    set_flags(TypeClassIdBits::update(value, flags()));
  }

  friend class compiler::target::UntaggedType;
  friend class CidRewriteVisitor;
  friend class UntaggedTypeArguments;
};

class UntaggedFunctionType : public UntaggedAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(FunctionType);

  COMPRESSED_POINTER_FIELD(TypeParametersPtr, type_parameters)
  COMPRESSED_POINTER_FIELD(AbstractTypePtr, result_type)
  COMPRESSED_POINTER_FIELD(ArrayPtr, parameter_types)
  COMPRESSED_POINTER_FIELD(ArrayPtr, named_parameter_names);
  VISIT_TO(named_parameter_names)
  AtomicBitFieldContainer<uint32_t> packed_parameter_counts_;
  AtomicBitFieldContainer<uint16_t> packed_type_parameter_counts_;

  // The bit fields are public for use in kernel_to_il.cc.
 public:
  // For packed_type_parameter_counts_.
  using PackedNumParentTypeArguments =
      BitField<decltype(packed_type_parameter_counts_), uint8_t, 0, 8>;
  using PackedNumTypeParameters =
      BitField<decltype(packed_type_parameter_counts_),
               uint8_t,
               PackedNumParentTypeArguments::kNextBit,
               8>;

  // For packed_parameter_counts_.
  using PackedNumImplicitParameters =
      BitField<decltype(packed_parameter_counts_), uint8_t, 0, 1>;
  using PackedHasNamedOptionalParameters =
      BitField<decltype(packed_parameter_counts_),
               bool,
               PackedNumImplicitParameters::kNextBit,
               1>;
  using PackedNumFixedParameters =
      BitField<decltype(packed_parameter_counts_),
               uint16_t,
               PackedHasNamedOptionalParameters::kNextBit,
               14>;
  using PackedNumOptionalParameters =
      BitField<decltype(packed_parameter_counts_),
               uint16_t,
               PackedNumFixedParameters::kNextBit,
               14>;
  static_assert(PackedNumOptionalParameters::kNextBit <=
                    compiler::target::kSmiBits,
                "In-place mask for number of optional parameters cannot fit in "
                "a Smi on the target architecture");

 private:
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class Function;
};

class UntaggedRecordType : public UntaggedAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(RecordType);

  COMPRESSED_SMI_FIELD(SmiPtr, shape)
  COMPRESSED_POINTER_FIELD(ArrayPtr, field_types)
  VISIT_TO(field_types)

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }
};

class UntaggedTypeParameter : public UntaggedAbstractType {
 public:
  static constexpr intptr_t kIsFunctionTypeParameterBit =
      TypeStateBits::kNextBit;
  using IsFunctionTypeParameter =
      BitField<uint32_t, bool, kIsFunctionTypeParameterBit, 1>;

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameter);

  // FunctionType or Smi (class id).
  COMPRESSED_POINTER_FIELD(ObjectPtr, owner)
  VISIT_TO(owner)
  uint16_t base_;   // Number of enclosing function type parameters.
  uint16_t index_;  // Keep size in sync with BuildTypeParameterTypeTestStub.

 private:
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class CidRewriteVisitor;
};

class UntaggedClosure : public UntaggedInstance {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Closure);

  // No instance fields should be declared before the following fields whose
  // offsets must be identical in Dart and C++.

  // The following fields are also declared in the Dart source of class
  // _Closure.
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, instantiator_type_arguments)
  VISIT_FROM(instantiator_type_arguments)
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, function_type_arguments)
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, delayed_type_arguments)
  COMPRESSED_POINTER_FIELD(FunctionPtr, function)
  COMPRESSED_POINTER_FIELD(ContextPtr, context)
  COMPRESSED_POINTER_FIELD(SmiPtr, hash)
  VISIT_TO(hash)

  // We have an extra word in the object due to alignment rounding, so use it in
  // bare instructions mode to cache the entry point from the closure function
  // to avoid an extra redirection on call. Closure functions only have
  // one entry point, as dynamic calls use dynamic closure call dispatchers.
  ONLY_IN_PRECOMPILED(uword entry_point_);

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

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

  friend class UnitDeserializationRoots;
};

class UntaggedNumber : public UntaggedInstance {
  RAW_OBJECT_IMPLEMENTATION(Number);
};

class UntaggedInteger : public UntaggedNumber {
  RAW_OBJECT_IMPLEMENTATION(Integer);
};

class UntaggedSmi : public UntaggedInteger {
  RAW_OBJECT_IMPLEMENTATION(Smi);
};

class UntaggedMint : public UntaggedInteger {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Mint);
  VISIT_NOTHING();

  ALIGN8 int64_t value_;

  friend class Api;
  friend class Class;
  friend class Integer;
};
COMPILE_ASSERT(sizeof(UntaggedMint) == 16);

class UntaggedDouble : public UntaggedNumber {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Double);
  VISIT_NOTHING();

  ALIGN8 double value_;

  friend class Api;
  friend class Class;
};
COMPILE_ASSERT(sizeof(UntaggedDouble) == 16);

class UntaggedString : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(String);

 protected:
#if !defined(HASH_IN_OBJECT_HEADER)
  COMPRESSED_SMI_FIELD(SmiPtr, hash)
  VISIT_FROM(hash)
#endif
  COMPRESSED_SMI_FIELD(SmiPtr, length)
#if defined(HASH_IN_OBJECT_HEADER)
  VISIT_FROM(length)
#endif
  VISIT_TO(length)

 private:
  friend class Library;
  friend class RODataSerializationCluster;
  friend class ImageWriter;
};

class UntaggedOneByteString : public UntaggedString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(OneByteString);
  VISIT_NOTHING();

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class RODataSerializationCluster;
  friend class String;
  friend class StringDeserializationCluster;
  friend class StringSerializationCluster;
};

class UntaggedTwoByteString : public UntaggedString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TwoByteString);
  VISIT_NOTHING();

  // Variable length data follows here.
  uint16_t* data() { OPEN_ARRAY_START(uint16_t, uint16_t); }
  const uint16_t* data() const { OPEN_ARRAY_START(uint16_t, uint16_t); }

  friend class RODataSerializationCluster;
  friend class String;
  friend class StringDeserializationCluster;
  friend class StringSerializationCluster;
};

// Abstract base class for UntaggedTypedData/UntaggedExternalTypedData/
// UntaggedTypedDataView/Pointer.
//
// TypedData extends this with a length field, while Pointer extends this with
// TypeArguments field.
class UntaggedPointerBase : public UntaggedInstance {
 public:
  uint8_t* data() { return data_; }

 protected:
  // The contents of [data_] depends on what concrete subclass is used:
  //
  //  - UntaggedTypedData: Start of the payload.
  //  - UntaggedExternalTypedData: Start of the C-heap payload.
  //  - UntaggedTypedDataView: The [data_] field of the backing store for the
  //    view plus the [offset_in_bytes_] the view has.
  //  - UntaggedPointer: Pointer into C memory (no length specified).
  //
  // During allocation or snapshot reading the [data_] can be temporarily
  // nullptr (which is the case for views which just got created but haven't
  // gotten the backing store set).
  uint8_t* data_;

 private:
  template <typename T>
  friend void CopyTypedDataBaseWithSafepointChecks(
      Thread*,
      const T&,
      const T&,
      intptr_t);  // Access _data for memmove with safepoint checkins.

  RAW_HEAP_OBJECT_IMPLEMENTATION(PointerBase);
};

// Abstract base class for UntaggedTypedData/UntaggedExternalTypedData/
// UntaggedTypedDataView.
class UntaggedTypedDataBase : public UntaggedPointerBase {
 protected:
#if defined(DART_COMPRESSED_POINTERS)
  uint32_t padding_;  // Makes Windows and Posix agree on layout.
#endif
  // The length of the view in element sizes (obtainable via
  // [TypedDataBase::ElementSizeInBytes]).
  COMPRESSED_SMI_FIELD(SmiPtr, length);
  VISIT_FROM(length)
  VISIT_TO(length)

 private:
  friend class UntaggedTypedDataView;
  friend void UpdateLengthField(intptr_t, ObjectPtr, ObjectPtr);  // length_
  friend void InitializeExternalTypedData(
      intptr_t,
      ExternalTypedDataPtr,
      ExternalTypedDataPtr);  // initialize fields.
  friend void InitializeExternalTypedDataWithSafepointChecks(
      Thread*,
      intptr_t,
      const ExternalTypedData&,
      const ExternalTypedData&);  // initialize fields.

  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedDataBase);
};

class UntaggedTypedData : public UntaggedTypedDataBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedData);

 public:
  static intptr_t payload_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedTypedData, internal_data);
  }

  // Recompute [data_] pointer to internal data.
  void RecomputeDataField() { data_ = internal_data(); }

 protected:
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
  friend class DeltaEncodedTypedDataDeserializationCluster;
  friend class NativeEntryData;
  friend class Object;
  friend class ObjectPool;
  friend class ObjectPoolDeserializationCluster;
  friend class ObjectPoolSerializationCluster;
  friend class UntaggedObjectPool;
};

// All _*ArrayView/_ByteDataView classes share the same layout.
class UntaggedTypedDataView : public UntaggedTypedDataBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedDataView);

 public:
  // Recompute [data_] based on internal/external [typed_data_].
  void RecomputeDataField() {
    const intptr_t offset_in_bytes = RawSmiValue(this->offset_in_bytes());
    uint8_t* payload = typed_data()->untag()->data_;
    data_ = payload + offset_in_bytes;
  }

  // Recompute [data_] based on internal [typed_data_] - needs to be called by
  // GC whenever the backing store moved.
  //
  // NOTICE: This method assumes [this] is the forwarded object and the
  // [typed_data_] pointer points to the new backing store. The backing store's
  // fields don't need to be valid - only it's address.
  void RecomputeDataFieldForInternalTypedData() {
    data_ = DataFieldForInternalTypedData();
  }

  uint8_t* DataFieldForInternalTypedData() const {
    const intptr_t offset_in_bytes = RawSmiValue(this->offset_in_bytes());
    uint8_t* payload =
        reinterpret_cast<uint8_t*>(UntaggedObject::ToAddr(typed_data()) +
                                   UntaggedTypedData::payload_offset());
    return payload + offset_in_bytes;
  }

  void ValidateInnerPointer() {
    if (typed_data()->untag()->GetClassId() == kNullCid) {
      // The view object must have gotten just initialized.
      if (data_ != nullptr || RawSmiValue(offset_in_bytes()) != 0 ||
          RawSmiValue(length()) != 0) {
        FATAL("TypedDataView has invalid inner pointer.");
      }
    } else {
      const intptr_t offset_in_bytes = RawSmiValue(this->offset_in_bytes());
      uint8_t* payload = typed_data()->untag()->data_;
      if ((payload + offset_in_bytes) != data_) {
        FATAL("TypedDataView has invalid inner pointer.");
      }
    }
  }

 protected:
  COMPRESSED_POINTER_FIELD(TypedDataBasePtr, typed_data)
  COMPRESSED_SMI_FIELD(SmiPtr, offset_in_bytes)
  VISIT_TO(offset_in_bytes)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend void InitializeTypedDataView(TypedDataViewPtr);
  friend class Api;
  friend class Object;
  friend class ObjectPoolDeserializationCluster;
  friend class ObjectPoolSerializationCluster;
  friend class UntaggedObjectPool;
  friend class GCCompactor;
  template <bool>
  friend class ScavengerVisitorBase;
};

class UntaggedExternalOneByteString : public UntaggedString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalOneByteString);

  const uint8_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class UntaggedExternalTwoByteString : public UntaggedString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTwoByteString);

  const uint16_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class UntaggedBool : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bool);
  VISIT_NOTHING();

  bool value_;

  friend class Object;
};

class UntaggedArray : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Array);

  COMPRESSED_ARRAY_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_FROM(type_arguments)
  COMPRESSED_SMI_FIELD(SmiPtr, length)
  // Variable length data follows here.
  COMPRESSED_VARIABLE_POINTER_FIELDS(ObjectPtr, element, data)

  friend class MapSerializationCluster;
  friend class MapDeserializationCluster;
  friend class SetSerializationCluster;
  friend class SetDeserializationCluster;
  friend class CodeSerializationCluster;
  friend class CodeDeserializationCluster;
  friend class Deserializer;
  friend class UntaggedCode;
  friend class UntaggedImmutableArray;
  friend class GrowableObjectArray;
  friend class Map;
  friend class UntaggedMap;
  friend class UntaggedConstMap;
  friend class Object;
  friend class ICData;            // For high performance access.
  friend class SubtypeTestCache;  // For high performance access.
  friend class ReversePc;
  template <typename Table, bool kAllCanonicalObjectsAreIncludedIntoSet>
  friend class CanonicalSetDeserializationCluster;
  friend class Page;
  friend class FastObjectCopy;  // For initializing fields.
  friend void UpdateLengthField(intptr_t, ObjectPtr, ObjectPtr);  // length_
};

class UntaggedImmutableArray : public UntaggedArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ImmutableArray);
};

class UntaggedGrowableObjectArray : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray);

  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_FROM(type_arguments)
  COMPRESSED_SMI_FIELD(SmiPtr, length)
  COMPRESSED_POINTER_FIELD(ArrayPtr, data)
  VISIT_TO(data)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class ReversePc;
};

class UntaggedLinkedHashBase : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LinkedHashBase);

  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_FROM(type_arguments)
  COMPRESSED_POINTER_FIELD(SmiPtr, hash_mask)
  COMPRESSED_POINTER_FIELD(ArrayPtr, data)
  COMPRESSED_POINTER_FIELD(SmiPtr, used_data)
  COMPRESSED_POINTER_FIELD(SmiPtr, deleted_keys)
  COMPRESSED_POINTER_FIELD(TypedDataPtr, index)
  VISIT_TO(index)

  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) {
    // Do not serialize index.
    return reinterpret_cast<CompressedObjectPtr*>(&deleted_keys_);
  }
};

class UntaggedMap : public UntaggedLinkedHashBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Map);

  friend class UntaggedConstMap;
};

class UntaggedConstMap : public UntaggedMap {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ConstMap);
};

class UntaggedSet : public UntaggedLinkedHashBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Set);

  friend class UntaggedConstSet;
};

class UntaggedConstSet : public UntaggedSet {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ConstSet);
};

class UntaggedFloat32x4 : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float32x4);
  VISIT_NOTHING();

  ALIGN8 float value_[4];

  friend class Class;

 public:
  float x() const { return value_[0]; }
  float y() const { return value_[1]; }
  float z() const { return value_[2]; }
  float w() const { return value_[3]; }
};
COMPILE_ASSERT(sizeof(UntaggedFloat32x4) == 24);

class UntaggedInt32x4 : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Int32x4);
  VISIT_NOTHING();

  ALIGN8 int32_t value_[4];

  friend class Simd128MessageSerializationCluster;
  friend class Simd128MessageDeserializationCluster;

 public:
  int32_t x() const { return value_[0]; }
  int32_t y() const { return value_[1]; }
  int32_t z() const { return value_[2]; }
  int32_t w() const { return value_[3]; }
};
COMPILE_ASSERT(sizeof(UntaggedInt32x4) == 24);

class UntaggedFloat64x2 : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float64x2);
  VISIT_NOTHING();

  ALIGN8 double value_[2];

  friend class Class;

 public:
  double x() const { return value_[0]; }
  double y() const { return value_[1]; }
};
COMPILE_ASSERT(sizeof(UntaggedFloat64x2) == 24);

class UntaggedRecord : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Record);

#if defined(DART_COMPRESSED_POINTERS)
  // This explicit padding avoids implicit padding between [shape] and [data].
  // Record allocation doesn't initialize the implicit padding but GC scans
  // everything between 'from' (shape) and 'to' (end of data),
  // so it would see garbage if implicit padding is inserted.
  uint32_t padding_;
#endif
  COMPRESSED_SMI_FIELD(SmiPtr, shape)
  VISIT_FROM(shape)
  // Variable length data follows here.
  COMPRESSED_VARIABLE_POINTER_FIELDS(ObjectPtr, field, data)

  friend void UpdateLengthField(intptr_t, ObjectPtr,
                                ObjectPtr);  // shape_
};

// Define an aliases for intptr_t.
#if defined(ARCH_IS_32_BIT)
#define kIntPtrCid kTypedDataInt32ArrayCid
#define GetIntPtr GetInt32
#define SetIntPtr SetInt32
#define kUintPtrCid kTypedDataUint32ArrayCid
#define GetUintPtr GetUint32
#define SetUintPtr SetUint32
#elif defined(ARCH_IS_64_BIT)
#define kIntPtrCid kTypedDataInt64ArrayCid
#define GetIntPtr GetInt64
#define SetIntPtr SetInt64
#define kUintPtrCid kTypedDataUint64ArrayCid
#define GetUintPtr GetUint64
#define SetUintPtr SetUint64
#else
#error Architecture is not 32-bit or 64-bit.
#endif  // ARCH_IS_32_BIT

class UntaggedExternalTypedData : public UntaggedTypedDataBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData);
};

class UntaggedPointer : public UntaggedPointerBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Pointer);

  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_FROM(type_arguments)
  VISIT_TO(type_arguments)

  friend class Pointer;
};

class UntaggedDynamicLibrary : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(DynamicLibrary);
  VISIT_NOTHING();
  void* handle_;
  bool isClosed_;
  bool canBeClosed_;

  friend class DynamicLibrary;
};

// VM implementations of the basic types in the isolate.
class alignas(8) UntaggedCapability : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Capability);
  VISIT_NOTHING();
  uint64_t id_;
};

class alignas(8) UntaggedSendPort : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SendPort);
  VISIT_NOTHING();
  Dart_Port id_;
  Dart_Port origin_id_;

  friend class ReceivePort;
};

class UntaggedReceivePort : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ReceivePort);

  COMPRESSED_POINTER_FIELD(SendPortPtr, send_port)
  VISIT_FROM(send_port)
  COMPRESSED_POINTER_FIELD(SmiPtr, bitfield)
  COMPRESSED_POINTER_FIELD(InstancePtr, handler)
#if defined(PRODUCT)
  VISIT_TO(handler)
#else
  COMPRESSED_POINTER_FIELD(StringPtr, debug_name)
  COMPRESSED_POINTER_FIELD(StackTracePtr, allocation_location)
  VISIT_TO(allocation_location)
#endif  // !defined(PRODUCT)
};

class UntaggedTransferableTypedData : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TransferableTypedData);
  VISIT_NOTHING();
};

// VM type for capturing stacktraces when exceptions are thrown,
// Currently we don't have any interface that this object is supposed
// to implement so we just support the 'toString' method which
// converts the stack trace into a string.
class UntaggedStackTrace : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(StackTrace);

  // Link to parent async stack trace.
  COMPRESSED_POINTER_FIELD(StackTracePtr, async_link);
  VISIT_FROM(async_link)
  // Code object for each frame in the stack trace.
  COMPRESSED_POINTER_FIELD(ArrayPtr, code_array);
  // Offset of PC for each frame.
  COMPRESSED_POINTER_FIELD(TypedDataPtr, pc_offset_array);

  VISIT_TO(pc_offset_array)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // False for pre-allocated stack trace (used in OOM and Stack overflow).
  bool expand_inlined_;
  // Whether the link between the stack and the async-link represents a
  // synchronous start to an asynchronous function. In this case, we omit the
  // <asynchronous suspension> marker when concatenating the stacks.
  bool skip_sync_start_in_parent_stack;
};

class UntaggedSuspendState : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SuspendState);

  NOT_IN_PRECOMPILED(intptr_t frame_capacity_);
  intptr_t frame_size_;
  uword pc_;

  // Holds function-specific object which is returned from
  // SuspendState.init* method.
  // For async functions: _Future instance.
  // For async* functions: _AsyncStarStreamController instance.
  COMPRESSED_POINTER_FIELD(InstancePtr, function_data)

  COMPRESSED_POINTER_FIELD(ClosurePtr, then_callback)
  COMPRESSED_POINTER_FIELD(ClosurePtr, error_callback)
  VISIT_FROM(function_data)
  VISIT_TO(error_callback)

 public:
  uword pc() const { return pc_; }

  intptr_t frame_capacity() const {
#if defined(DART_PRECOMPILED_RUNTIME)
    return frame_size_;
#else
    return frame_capacity_;
#endif
  }

  static intptr_t payload_offset() {
    return OFFSET_OF_RETURNED_VALUE(UntaggedSuspendState, payload);
  }

  // Variable length payload follows here.
  uint8_t* payload() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* payload() const { OPEN_ARRAY_START(uint8_t, uint8_t); }
};

// VM type for capturing JS regular expressions.
class UntaggedRegExp : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(RegExp);

  COMPRESSED_POINTER_FIELD(ArrayPtr, capture_name_map)
  VISIT_FROM(capture_name_map)
  // Pattern to be used for matching.
  COMPRESSED_POINTER_FIELD(StringPtr, pattern)
  COMPRESSED_POINTER_FIELD(ObjectPtr, one_byte)  // FunctionPtr or TypedDataPtr
  COMPRESSED_POINTER_FIELD(ObjectPtr, two_byte)
  COMPRESSED_POINTER_FIELD(ObjectPtr, external_one_byte)
  COMPRESSED_POINTER_FIELD(ObjectPtr, external_two_byte)
  COMPRESSED_POINTER_FIELD(ObjectPtr, one_byte_sticky)
  COMPRESSED_POINTER_FIELD(ObjectPtr, two_byte_sticky)
  COMPRESSED_POINTER_FIELD(ObjectPtr, external_one_byte_sticky)
  COMPRESSED_POINTER_FIELD(ObjectPtr, external_two_byte_sticky)
  VISIT_TO(external_two_byte_sticky)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  std::atomic<intptr_t> num_bracket_expressions_;
  intptr_t num_bracket_expressions() {
    return num_bracket_expressions_.load(std::memory_order_relaxed);
  }
  void set_num_bracket_expressions(intptr_t value) {
    num_bracket_expressions_.store(value, std::memory_order_relaxed);
  }

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
  // It is possible multiple compilers race to update the flags concurrently.
  // That should be safe since all updates update to the same values..
  AtomicBitFieldContainer<int8_t> type_flags_;
};

class UntaggedWeakProperty : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakProperty);

  COMPRESSED_POINTER_FIELD(ObjectPtr, key)  // Weak reference.
  VISIT_FROM(key)
  COMPRESSED_POINTER_FIELD(ObjectPtr, value)
  VISIT_TO(value)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Linked list is chaining all pending weak properties. Not visited by
  // pointer visitors.
  COMPRESSED_POINTER_FIELD(WeakPropertyPtr, next_seen_by_gc)

  template <typename Type, typename PtrType>
  friend class GCLinkedList;
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class Scavenger;
  friend class FastObjectCopy;  // For OFFSET_OF
  friend class SlowObjectCopy;  // For OFFSET_OF
};

// WeakProperty is special in that it has a pointer field which is not
// traversed by pointer visitors, and thus not in the range [from(),to()]:
// next_seen_by_gc, which is after the other fields.
template <>
DART_FORCE_INLINE uword
UntaggedObject::to_offset<UntaggedWeakProperty>(intptr_t length) {
  return OFFSET_OF(UntaggedWeakProperty, next_seen_by_gc_);
}

class UntaggedWeakReference : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakReference);

  COMPRESSED_POINTER_FIELD(ObjectPtr, target)  // Weak reference.
  VISIT_FROM(target)
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_TO(type_arguments)
  CompressedObjectPtr* to_snapshot(Snapshot::Kind kind) { return to(); }

  // Linked list is chaining all pending weak properties. Not visited by
  // pointer visitors.
  COMPRESSED_POINTER_FIELD(WeakReferencePtr, next_seen_by_gc)

  template <typename Type, typename PtrType>
  friend class GCLinkedList;
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class Scavenger;
  friend class ObjectGraph;
  friend class FastObjectCopy;  // For OFFSET_OF
  friend class SlowObjectCopy;  // For OFFSET_OF
};

// WeakReference is special in that it has a pointer field which is not
// traversed by pointer visitors, and thus not in the range [from(),to()]:
// next_seen_by_gc, which is after the other fields.
template <>
DART_FORCE_INLINE uword
UntaggedObject::to_offset<UntaggedWeakReference>(intptr_t length) {
  return OFFSET_OF(UntaggedWeakReference, next_seen_by_gc_);
}

class UntaggedFinalizerBase : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(FinalizerBase);

  // The isolate this finalizer belongs to. Updated on sent and exit and set
  // to null on isolate shutdown. See Isolate::finalizers_.
  Isolate* isolate_;

// With compressed pointers, the first field in a subclass is at offset 28.
// If the fields would be public, the first field in a subclass is at offset 32.
// On Windows, it is always at offset 32, no matter public/private.
// This makes it 32 for all OSes.
// We can't use ALIGN8 on the first fields of the subclasses because they use
// the COMPRESSED_POINTER_FIELD macro to define it.
// Placed before the first fields so it is not included between from() and to().
#ifdef DART_COMPRESSED_POINTERS
  uint32_t align_first_field_in_subclass;
#endif

  COMPRESSED_POINTER_FIELD(ObjectPtr, detachments)
  VISIT_FROM(detachments)
  COMPRESSED_POINTER_FIELD(SetPtr, all_entries)
  COMPRESSED_POINTER_FIELD(FinalizerEntryPtr, entries_collected)

  template <typename GCVisitorType>
  friend void MournFinalizerEntry(GCVisitorType*, FinalizerEntryPtr);
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class ObjectGraph;
};

class UntaggedFinalizer : public UntaggedFinalizerBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Finalizer);

  COMPRESSED_POINTER_FIELD(ClosurePtr, callback)
  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_TO(type_arguments)

  template <std::memory_order order = std::memory_order_relaxed>
  FinalizerEntryPtr exchange_entries_collected(FinalizerEntryPtr value) {
    return ExchangeCompressedPointer<FinalizerEntryPtr,
                                     CompressedFinalizerEntryPtr, order>(
        &entries_collected_, value);
  }

  template <typename GCVisitorType>
  friend void MournFinalizerEntry(GCVisitorType*, FinalizerEntryPtr);
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
};

class UntaggedNativeFinalizer : public UntaggedFinalizerBase {
  RAW_HEAP_OBJECT_IMPLEMENTATION(NativeFinalizer);

  COMPRESSED_POINTER_FIELD(PointerPtr, callback)
  VISIT_TO(callback)

  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
};

class UntaggedFinalizerEntry : public UntaggedInstance {
 public:
  intptr_t external_size() { return external_size_; }
  void set_external_size(intptr_t value) { external_size_ = value; }

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(FinalizerEntry);

  COMPRESSED_POINTER_FIELD(ObjectPtr, value)  // Weak reference.
  VISIT_FROM(value)
  COMPRESSED_POINTER_FIELD(ObjectPtr, detach)  // Weak reference.
  COMPRESSED_POINTER_FIELD(ObjectPtr, token)
  COMPRESSED_POINTER_FIELD(FinalizerBasePtr, finalizer)  // Weak reference.
  // Used for the linked list in Finalizer::entries_collected_. That cannot be
  // an ordinary list because we need to add elements during a GC so we cannot
  // modify the heap.
  COMPRESSED_POINTER_FIELD(FinalizerEntryPtr, next)
  VISIT_TO(next)

  // Linked list is chaining all pending. Not visited by pointer visitors.
  // Only populated during the GC, otherwise null.
  COMPRESSED_POINTER_FIELD(FinalizerEntryPtr, next_seen_by_gc)

  intptr_t external_size_;

  template <typename Type, typename PtrType>
  friend class GCLinkedList;
  template <typename GCVisitorType>
  friend void MournFinalizerEntry(GCVisitorType*, FinalizerEntryPtr);
  template <bool>
  friend class MarkingVisitorBase;
  template <bool>
  friend class ScavengerVisitorBase;
  friend class Scavenger;
  friend class ObjectGraph;
};

// FinalizerEntry is special in that it has a pointer field which is not
// traversed by pointer visitors, and thus not in the range [from(),to()]:
// next_seen_by_gc, which is after the other fields.
template <>
DART_FORCE_INLINE uword
UntaggedObject::to_offset<UntaggedFinalizerEntry>(intptr_t length) {
  return OFFSET_OF(UntaggedFinalizerEntry, next_seen_by_gc_);
}

// MirrorReferences are used by mirrors to hold reflectees that are VM
// internal objects, such as libraries, classes, functions or types.
class UntaggedMirrorReference : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MirrorReference);

  COMPRESSED_POINTER_FIELD(ObjectPtr, referent)
  VISIT_FROM(referent)
  VISIT_TO(referent)
};

// UserTag are used by the profiler to track Dart script state.
class UntaggedUserTag : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UserTag);

  COMPRESSED_POINTER_FIELD(StringPtr, label)
  VISIT_FROM(label)
  VISIT_TO(label)

  // Isolate unique tag.
  uword tag_;

  // Should CPU samples with this tag be streamed?
  bool streamable_;

  friend class Object;

 public:
  uword tag() const { return tag_; }
  bool streamable() const { return streamable_; }
};

class UntaggedFutureOr : public UntaggedInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(FutureOr);

  COMPRESSED_POINTER_FIELD(TypeArgumentsPtr, type_arguments)
  VISIT_FROM(type_arguments)
  VISIT_TO(type_arguments)
};

#undef WSR_COMPRESSED_POINTER_FIELD

}  // namespace dart

#endif  // RUNTIME_VM_RAW_OBJECT_H_
