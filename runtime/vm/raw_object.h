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
#include "vm/class_id.h"
#include "vm/compiler/method_recognizer.h"
#include "vm/exceptions.h"
#include "vm/globals.h"
#include "vm/object_graph.h"
#include "vm/pointer_tagging.h"
#include "vm/snapshot.h"
#include "vm/token.h"
#include "vm/token_position.h"

namespace dart {

// For now there are no compressed pointers.
typedef RawObject* RawCompressed;

// Forward declarations.
class Isolate;
#define DEFINE_FORWARD_DECLARATION(clazz) class Raw##clazz;
CLASS_LIST(DEFINE_FORWARD_DECLARATION)
#undef DEFINE_FORWARD_DECLARATION
class CodeStatistics;

#define VISIT_FROM(type, first)                                                \
  type* from() { return reinterpret_cast<type*>(&ptr()->first); }

#define VISIT_TO(type, last)                                                   \
  type* to() { return reinterpret_cast<type*>(&ptr()->last); }

#define VISIT_TO_LENGTH(type, last)                                            \
  type* to(intptr_t length) { return reinterpret_cast<type*>(last); }

#define VISIT_NOTHING() int NothingToVisit();

#define ASSERT_UNCOMPRESSED(Type)                                              \
  ASSERT(SIZE_OF_DEREFERENCED_RETURNED_VALUE(Raw##Type, from) == kWordSize)

// For now there are no compressed pointers, so this assert is the same as
// the above.
#define ASSERT_COMPRESSED(Type)                                                \
  ASSERT(SIZE_OF_DEREFERENCED_RETURNED_VALUE(Raw##Type, from) == kWordSize)

#define ASSERT_NOTHING_TO_VISIT(Type)                                          \
  ASSERT(SIZE_OF_RETURNED_VALUE(Raw##Type, NothingToVisit) == sizeof(int))

enum TypedDataElementType {
#define V(name) k##name##Element,
  CLASS_LIST_TYPED_DATA(V)
#undef V
};

enum class MemoryOrder {
  kRelaxed,
  kRelease,
};

#define SNAPSHOT_WRITER_SUPPORT()                                              \
  void WriteTo(SnapshotWriter* writer, intptr_t object_id,                     \
               Snapshot::Kind kind, bool as_reference);                        \
  friend class SnapshotWriter;

#define VISITOR_SUPPORT(object)                                                \
  static intptr_t Visit##object##Pointers(Raw##object* raw_obj,                \
                                          ObjectPointerVisitor* visitor);

#define HEAP_PROFILER_SUPPORT() friend class HeapProfiler;

#define RAW_OBJECT_IMPLEMENTATION(object)                                      \
 private: /* NOLINT */                                                         \
  VISITOR_SUPPORT(object)                                                      \
  friend class object;                                                         \
  friend class RawObject;                                                      \
  friend class Heap;                                                           \
  friend class Interpreter;                                                    \
  friend class InterpreterHelpers;                                             \
  friend class Simulator;                                                      \
  friend class SimulatorHelpers;                                               \
  friend class OffsetsTable;                                                   \
  DISALLOW_ALLOCATION();                                                       \
  DISALLOW_IMPLICIT_CONSTRUCTORS(Raw##object)

// TODO(koda): Make ptr() return const*, like Object::raw_ptr().
#define RAW_HEAP_OBJECT_IMPLEMENTATION(object)                                 \
 private:                                                                      \
  RAW_OBJECT_IMPLEMENTATION(object);                                           \
  Raw##object* ptr() const {                                                   \
    ASSERT(IsHeapObject());                                                    \
    return reinterpret_cast<Raw##object*>(reinterpret_cast<uword>(this) -      \
                                          kHeapObjectTag);                     \
  }                                                                            \
  SNAPSHOT_WRITER_SUPPORT()                                                    \
  HEAP_PROFILER_SUPPORT()                                                      \
  friend class object##SerializationCluster;                                   \
  friend class object##DeserializationCluster;                                 \
  friend class Serializer;                                                     \
  friend class Deserializer;

// RawObject is the base class of all raw objects; even though it carries the
// tags_ field not all raw objects are allocated in the heap and thus cannot
// be dereferenced (e.g. RawSmi).
class RawObject {
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
    kVMHeapObjectBit = 6,
    kGraphMarkedBit = 7,  // ObjectGraph needs to mark through new space.

    kSizeTagPos = 8,
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

  COMPILE_ASSERT(kClassIdTagSize == (sizeof(classid_t) * kBitsPerByte));

  // Encodes the object size in the tag in units of object alignment.
  class SizeTag {
   public:
    static const intptr_t kMaxSizeTag = ((1 << RawObject::kSizeTagSize) - 1)
                                        << kObjectAlignmentLog2;

    static uword encode(intptr_t size) {
      return SizeBits::encode(SizeToTagValue(size));
    }

    static intptr_t decode(uword tag) {
      return TagValueToSize(SizeBits::decode(tag));
    }

    static uword update(intptr_t size, uword tag) {
      return SizeBits::update(SizeToTagValue(size), tag);
    }

   private:
    // The actual unscaled bit field used within the tag field.
    class SizeBits
        : public BitField<uint32_t, intptr_t, kSizeTagPos, kSizeTagSize> {};

    static intptr_t SizeToTagValue(intptr_t size) {
      ASSERT(Utils::IsAligned(size, kObjectAlignment));
      return (size > kMaxSizeTag) ? 0 : (size >> kObjectAlignmentLog2);
    }
    static intptr_t TagValueToSize(intptr_t value) {
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

  class CanonicalObjectTag : public BitField<uint32_t, bool, kCanonicalBit, 1> {
  };

  class GraphMarkedBit : public BitField<uint32_t, bool, kGraphMarkedBit, 1> {};

  class VMHeapObjectTag : public BitField<uint32_t, bool, kVMHeapObjectBit, 1> {
  };

  class OldBit : public BitField<uint32_t, bool, kOldBit, 1> {};

  class OldAndNotRememberedBit
      : public BitField<uint32_t, bool, kOldAndNotRememberedBit, 1> {};

  bool IsWellFormed() const {
    uword value = reinterpret_cast<uword>(this);
    return (value & kSmiTagMask) == 0 ||
           Utils::IsAligned(value - kHeapObjectTag, kWordSize);
  }
  bool IsHeapObject() const {
    ASSERT(IsWellFormed());
    uword value = reinterpret_cast<uword>(this);
    return (value & kSmiTagMask) == kHeapObjectTag;
  }
  // Assumes this is a heap object.
  bool IsNewObject() const {
    ASSERT(IsHeapObject());
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kNewObjectAlignmentOffset;
  }
  bool IsNewObjectMayBeSmi() const {
    static const uword kNewObjectBits =
        (kNewObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = reinterpret_cast<uword>(this);
    return (addr & kObjectAlignmentMask) == kNewObjectBits;
  }
  // Assumes this is a heap object.
  bool IsOldObject() const {
    ASSERT(IsHeapObject());
    uword addr = reinterpret_cast<uword>(this);
    return (addr & kNewObjectAlignmentOffset) == kOldObjectAlignmentOffset;
  }

  // Like !IsHeapObject() || IsOldObject(), but compiles to a single branch.
  bool IsSmiOrOldObject() const {
    ASSERT(IsWellFormed());
    static const uword kNewObjectBits =
        (kNewObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = reinterpret_cast<uword>(this);
    return (addr & kObjectAlignmentMask) != kNewObjectBits;
  }

  // Like !IsHeapObject() || IsNewObject(), but compiles to a single branch.
  bool IsSmiOrNewObject() const {
    ASSERT(IsWellFormed());
    static const uword kOldObjectBits =
        (kOldObjectAlignmentOffset | kHeapObjectTag);
    const uword addr = reinterpret_cast<uword>(this);
    return (addr & kObjectAlignmentMask) != kOldObjectBits;
  }

  // Support for GC marking bit.
  bool IsMarked() const {
    ASSERT(IsOldObject());
    return !OldAndNotMarkedBit::decode(ptr()->tags_);
  }
  void SetMarkBit() {
    ASSERT(IsOldObject());
    ASSERT(!IsMarked());
    UpdateTagBit<OldAndNotMarkedBit>(false);
  }
  void SetMarkBitUnsynchronized() {
    ASSERT(IsOldObject());
    ASSERT(!IsMarked());
    uint32_t tags = ptr()->tags_;
    ptr()->tags_ = OldAndNotMarkedBit::update(false, tags);
  }
  void ClearMarkBit() {
    ASSERT(IsOldObject());
    ASSERT(IsMarked());
    UpdateTagBit<OldAndNotMarkedBit>(true);
  }
  // Returns false if the bit was already set.
  DART_WARN_UNUSED_RESULT
  bool TryAcquireMarkBit() {
    ASSERT(IsOldObject());
    return TryClearTagBit<OldAndNotMarkedBit>();
  }

  // Support for object tags.
  bool IsCanonical() const { return CanonicalObjectTag::decode(ptr()->tags_); }
  void SetCanonical() { UpdateTagBit<CanonicalObjectTag>(true); }
  void ClearCanonical() { UpdateTagBit<CanonicalObjectTag>(false); }
  bool IsVMHeapObject() const { return VMHeapObjectTag::decode(ptr()->tags_); }
  void SetVMHeapObject() { UpdateTagBit<VMHeapObjectTag>(true); }

  // Support for ObjectGraph marking bit.
  bool IsGraphMarked() const {
    if (IsVMHeapObject()) return true;
    return GraphMarkedBit::decode(ptr()->tags_);
  }
  void SetGraphMarked() {
    ASSERT(!IsVMHeapObject());
    uint32_t tags = ptr()->tags_;
    ptr()->tags_ = GraphMarkedBit::update(true, tags);
  }
  void ClearGraphMarked() {
    ASSERT(!IsVMHeapObject());
    uint32_t tags = ptr()->tags_;
    ptr()->tags_ = GraphMarkedBit::update(false, tags);
  }

  // Support for GC remembered bit.
  bool IsRemembered() const {
    ASSERT(IsOldObject());
    return !OldAndNotRememberedBit::decode(ptr()->tags_);
  }
  void SetRememberedBit() {
    ASSERT(!IsRemembered());
    ASSERT(!IsCardRemembered());
    UpdateTagBit<OldAndNotRememberedBit>(false);
  }
  void ClearRememberedBit() {
    ASSERT(IsOldObject());
    UpdateTagBit<OldAndNotRememberedBit>(true);
  }

  bool IsCardRemembered() const {
    return CardRememberedBit::decode(ptr()->tags_);
  }
  void SetCardRememberedBitUnsynchronized() {
    ASSERT(!IsRemembered());
    ASSERT(!IsCardRemembered());
    uint32_t tags = ptr()->tags_;
    ptr()->tags_ = CardRememberedBit::update(true, tags);
  }

#define DEFINE_IS_CID(clazz)                                                   \
  bool Is##clazz() const { return ((GetClassId() == k##clazz##Cid)); }
  CLASS_LIST(DEFINE_IS_CID)
#undef DEFINE_IS_CID

#define DEFINE_IS_CID(clazz)                                                   \
  bool IsTypedData##clazz() const {                                            \
    return ((GetClassId() == kTypedData##clazz##Cid));                         \
  }                                                                            \
  bool IsTypedDataView##clazz() const {                                        \
    return ((GetClassId() == kTypedData##clazz##ViewCid));                     \
  }                                                                            \
  bool IsExternalTypedData##clazz() const {                                    \
    return ((GetClassId() == kExternalTypedData##clazz##Cid));                 \
  }
  CLASS_LIST_TYPED_DATA(DEFINE_IS_CID)
#undef DEFINE_IS_CID

  bool IsStringInstance() const { return IsStringClassId(GetClassId()); }
  bool IsRawNull() const { return GetClassId() == kNullCid; }
  bool IsDartInstance() const {
    return (!IsHeapObject() || (GetClassId() >= kInstanceCid));
  }
  bool IsFreeListElement() const {
    return ((GetClassId() == kFreeListElement));
  }
  bool IsForwardingCorpse() const {
    return ((GetClassId() == kForwardingCorpse));
  }
  bool IsPseudoObject() const {
    return IsFreeListElement() || IsForwardingCorpse();
  }

  intptr_t GetClassIdMayBeSmi() const {
    return IsHeapObject() ? GetClassId() : static_cast<intptr_t>(kSmiCid);
  }

  intptr_t Size() const {
    uint32_t tags = ptr()->tags_;
    intptr_t result = SizeTag::decode(tags);
    if (result != 0) {
#if defined(DEBUG)
      // TODO(22501) Array::MakeFixedLength has a race with this code: we might
      // have loaded tags field and then MakeFixedLength could have updated it
      // leading to inconsistency between SizeFromClass() and
      // SizeTag::decode(tags). We are working around it by reloading tags_ and
      // recomputing size from tags.
      const intptr_t size_from_class = SizeFromClass();
      if ((result > size_from_class) && (GetClassId() == kArrayCid) &&
          (ptr()->tags_ != tags)) {
        result = SizeTag::decode(ptr()->tags_);
      }
      ASSERT(result == size_from_class);
#endif
      return result;
    }
    result = SizeFromClass();
    ASSERT(result > SizeTag::kMaxSizeTag);
    return result;
  }

  bool Contains(uword addr) const {
    intptr_t this_size = Size();
    uword this_addr = RawObject::ToAddr(this);
    return (addr >= this_addr) && (addr < (this_addr + this_size));
  }

  void Validate(Isolate* isolate) const;
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
    intptr_t instance_size = Size();
    uword obj_addr = ToAddr(this);
    uword from = obj_addr + sizeof(RawObject);
    uword to = obj_addr + instance_size - kWordSize;

    // Call visitor function virtually
    visitor->VisitPointers(reinterpret_cast<RawObject**>(from),
                           reinterpret_cast<RawObject**>(to));

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
    intptr_t instance_size = Size();
    uword obj_addr = ToAddr(this);
    uword from = obj_addr + sizeof(RawObject);
    uword to = obj_addr + instance_size - kWordSize;

    // Call visitor function non-virtually
    visitor->V::VisitPointers(reinterpret_cast<RawObject**>(from),
                              reinterpret_cast<RawObject**>(to));

    return instance_size;
  }

  static RawObject* FromAddr(uword addr) {
    // We expect the untagged address here.
    ASSERT((addr & kSmiTagMask) != kHeapObjectTag);
    return reinterpret_cast<RawObject*>(addr + kHeapObjectTag);
  }

  static uword ToAddr(const RawObject* raw_obj) {
    return reinterpret_cast<uword>(raw_obj->ptr());
  }

  static bool IsVMHeapObject(intptr_t value) {
    return VMHeapObjectTag::decode(value);
  }

  static bool IsCanonical(intptr_t value) {
    return CanonicalObjectTag::decode(value);
  }

  // Class Id predicates.
  static bool IsErrorClassId(intptr_t index);
  static bool IsNumberClassId(intptr_t index);
  static bool IsIntegerClassId(intptr_t index);
  static bool IsStringClassId(intptr_t index);
  static bool IsOneByteStringClassId(intptr_t index);
  static bool IsTwoByteStringClassId(intptr_t index);
  static bool IsExternalStringClassId(intptr_t index);
  static bool IsBuiltinListClassId(intptr_t index);
  static bool IsTypedDataClassId(intptr_t index);
  static bool IsTypedDataViewClassId(intptr_t index);
  static bool IsExternalTypedDataClassId(intptr_t index);
  static bool IsInternalVMdefinedClassId(intptr_t index);
  static bool IsVariableSizeClassId(intptr_t index);
  static bool IsImplicitFieldClassId(intptr_t index);

  static intptr_t NumberOfTypedDataClasses();

 private:
  uint32_t tags_;  // Various object tags (bits).
#if defined(HASH_IN_OBJECT_HEADER)
  // On 64 bit there is a hash field in the header for the identity hash.
  uint32_t hash_;
#endif

  // TODO(koda): After handling tags_, return const*, like Object::raw_ptr().
  RawObject* ptr() const {
    ASSERT(IsHeapObject());
    return reinterpret_cast<RawObject*>(reinterpret_cast<uword>(this) -
                                        kHeapObjectTag);
  }

  intptr_t VisitPointersPredefined(ObjectPointerVisitor* visitor,
                                   intptr_t class_id);

  intptr_t SizeFromClass() const;

  intptr_t GetClassId() const {
    uint32_t tags = ptr()->tags_;
    return ClassIdTag::decode(tags);
  }

  void SetClassId(intptr_t new_cid) {
    uint32_t tags = ptr()->tags_;
    ptr()->tags_ = ClassIdTag::update(new_cid, tags);
  }

  template <class TagBitField>
  void UpdateTagBit(bool value) {
    if (value) {
      AtomicOperations::FetchOrRelaxedUint32(&ptr()->tags_,
                                             TagBitField::encode(true));
    } else {
      AtomicOperations::FetchAndRelaxedUint32(&ptr()->tags_,
                                              ~TagBitField::encode(true));
    }
  }

  template <class TagBitField>
  bool TryAcquireTagBit() {
    uint32_t old_tags = AtomicOperations::FetchOrRelaxedUint32(
        &ptr()->tags_, TagBitField::encode(true));
    return !TagBitField::decode(old_tags);
  }
  template <class TagBitField>
  bool TryClearTagBit() {
    uint32_t old_tags = AtomicOperations::FetchAndRelaxedUint32(
        &ptr()->tags_, ~TagBitField::encode(true));
    return TagBitField::decode(old_tags);
  }

  // All writes to heap objects should ultimately pass through one of the
  // methods below or their counterparts in Object, to ensure that the
  // write barrier is correctly applied.

  template <typename type, MemoryOrder order = MemoryOrder::kRelaxed>
  void StorePointer(type const* addr, type value) {
    if (order == MemoryOrder::kRelease) {
      AtomicOperations::StoreRelease(const_cast<type*>(addr), value);
    } else {
      ASSERT(order == MemoryOrder::kRelaxed);
      *const_cast<type*>(addr) = value;
    }
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

  DART_FORCE_INLINE
  void CheckHeapPointerStore(RawObject* value, Thread* thread) {
    uint32_t source_tags = this->ptr()->tags_;
    uint32_t target_tags = value->ptr()->tags_;
    if (((source_tags >> kBarrierOverlapShift) & target_tags &
         thread->write_barrier_mask()) != 0) {
      if (value->IsNewObject()) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        ASSERT(!this->IsRemembered());
        this->SetRememberedBit();
        thread->StoreBufferAddObject(this);
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
        if (value->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  template <typename type, MemoryOrder order = MemoryOrder::kRelaxed>
  void StoreArrayPointer(type const* addr, type value) {
    if (order == MemoryOrder::kRelease) {
      AtomicOperations::StoreRelease(const_cast<type*>(addr), value);
    } else {
      ASSERT(order == MemoryOrder::kRelaxed);
      *const_cast<type*>(addr) = value;
    }
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
                                                RawObject* value,
                                                Thread* thread) {
    uint32_t source_tags = this->ptr()->tags_;
    uint32_t target_tags = value->ptr()->tags_;
    if (((source_tags >> kBarrierOverlapShift) & target_tags &
         thread->write_barrier_mask()) != 0) {
      if (value->IsNewObject()) {
        // Generational barrier: record when a store creates an
        // old-and-not-remembered -> new reference.
        ASSERT(!this->IsRemembered());
        if (this->IsCardRemembered()) {
          RememberCard(reinterpret_cast<RawObject* const*>(addr));
        } else {
          this->SetRememberedBit();
          thread->StoreBufferAddObject(this);
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
        if (value->TryAcquireMarkBit()) {
          thread->MarkingStackAddObject(value);
        }
      }
    }
  }

  // Use for storing into an explicitly Smi-typed field of an object
  // (i.e., both the previous and new value are Smis).
  void StoreSmi(RawSmi* const* addr, RawSmi* value) {
    // Can't use Contains, as array length is initialized through this method.
    ASSERT(reinterpret_cast<uword>(addr) >= RawObject::ToAddr(this));
    *const_cast<RawSmi**>(addr) = value;
  }

 protected:
  friend class StoreBufferUpdateVisitor;  // RememberCard
  void RememberCard(RawObject* const* slot);

  friend class Api;
  friend class ApiMessageReader;  // GetClassId
  friend class Serializer;        // GetClassId
  friend class Array;
  friend class Become;  // GetClassId
  friend class CompactorTask;  // GetClassId
  friend class ByteBuffer;
  friend class CidRewriteVisitor;
  friend class Closure;
  friend class Code;
  friend class Double;
  friend class ForwardPointersVisitor;  // StorePointer
  friend class FreeListElement;
  friend class Function;
  friend class GCMarker;
  friend class ExternalTypedData;
  friend class ForwardList;
  friend class GrowableObjectArray;  // StorePointer
  friend class Heap;
  friend class HeapMapAsJSONVisitor;
  friend class ClassStatsVisitor;
  template <bool>
  friend class MarkingVisitorBase;
  friend class Mint;
  friend class Object;
  friend class OneByteString;  // StoreSmi
  friend class RawCode;
  friend class RawExternalTypedData;
  friend class RawInstructions;
  friend class RawInstance;
  friend class RawString;
  friend class RawTypedData;
  friend class Scavenger;
  friend class ScavengerVisitor;
  friend class SizeExcludingClassVisitor;  // GetClassId
  friend class InstanceAccumulator;        // GetClassId
  friend class RetainingPathVisitor;       // GetClassId
  friend class SkippedCodeFunctions;       // StorePointer
  friend class ImageReader;                // tags_ check
  friend class ImageWriter;
  friend class AssemblyImageWriter;
  friend class BlobImageWriter;
  friend class SnapshotReader;
  friend class Deserializer;
  friend class SnapshotWriter;
  friend class String;
  friend class Type;  // GetClassId
  friend class TypedData;
  friend class TypedDataView;
  friend class WeakProperty;            // StorePointer
  friend class Instance;                // StorePointer
  friend class StackFrame;              // GetCodeObject assertion.
  friend class CodeLookupTableBuilder;  // profiler
  friend class NativeEntry;             // GetClassId
  friend class WritePointerVisitor;     // GetClassId
  friend class Interpreter;
  friend class InterpreterHelpers;
  friend class Simulator;
  friend class SimulatorHelpers;
  friend class ObjectLocator;
  friend class InstanceMorpher;  // GetClassId
  friend class VerifyCanonicalVisitor;
  friend class ObjectGraph::Stack;  // GetClassId
  friend class Precompiler;         // GetClassId
  friend class ObjectOffsetTrait;   // GetClassId
  friend class WriteBarrierUpdateVisitor;  // CheckHeapPointerStore
  friend class OffsetsTable;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(RawObject);
};

class RawClass : public RawObject {
 public:
  enum ClassFinalizedState {
    kAllocated = 0,         // Initial state.
    kPreFinalized,          // VM classes: size precomputed, but no checks done.
    kFinalized,             // Class parsed, finalized and ready for use.
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Class);

  VISIT_FROM(RawObject*, name_);
  RawString* name_;
  RawString* user_name_;
  RawArray* functions_;
  RawArray* functions_hash_table_;
  RawArray* fields_;
  RawArray* offset_in_words_to_field_;
  RawArray* interfaces_;  // Array of AbstractType.
  RawScript* script_;
  RawLibrary* library_;
  RawTypeArguments* type_parameters_;  // Array of TypeParameter.
  RawAbstractType* super_type_;
  RawFunction* signature_function_;  // Associated function for typedef class.
  RawArray* constants_;      // Canonicalized const instances of this class.
  RawType* declaration_type_;              // Declaration type for this class.
  RawArray* invocation_dispatcher_cache_;  // Cache for dispatcher functions.
  RawCode* allocation_stub_;  // Stub code for allocation of instances.
  RawGrowableObjectArray* direct_implementors_;  // Array of Class.
  RawGrowableObjectArray* direct_subclasses_;  // Array of Class.
  RawArray* dependent_code_;                   // CHA optimized codes.
  VISIT_TO(RawObject*, dependent_code_);
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->allocation_stub_);
      case Snapshot::kFull:
        return reinterpret_cast<RawObject**>(&ptr()->direct_subclasses_);
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->dependent_code_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }

  cpp_vtable handle_vtable_;
  TokenPosition token_pos_;
  int32_t instance_size_in_words_;  // Size if fixed len or 0 if variable len.
  int32_t type_arguments_field_offset_in_words_;  // Offset of type args fld.
  int32_t next_field_offset_in_words_;  // Offset of the next instance field.
  classid_t id_;                // Class Id, also index in the class table.
  int16_t num_type_arguments_;  // Number of type arguments in flattened vector.

  // Bitfields with number of non-overlapping type arguments and 'has_pragma'
  // bit.
  uint16_t has_pragma_and_num_own_type_arguments_;

  uint16_t num_native_fields_;
  uint16_t state_bits_;
  NOT_IN_PRECOMPILED(intptr_t kernel_offset_);

  friend class Instance;
  friend class Isolate;
  friend class Object;
  friend class RawInstance;
  friend class RawInstructions;
  friend class RawTypeArguments;
  friend class SnapshotReader;
  friend class InstanceSerializationCluster;
  friend class CidRewriteVisitor;
};

class RawPatchClass : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(PatchClass);

  VISIT_FROM(RawObject*, patched_class_);
  RawClass* patched_class_;
  RawClass* origin_class_;
  RawScript* script_;
  RawExternalTypedData* library_kernel_data_;
  VISIT_TO(RawObject*, library_kernel_data_);

  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->script_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->library_kernel_data_);
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

class RawFunction : public RawObject {
 public:
  enum Kind {
    kRegularFunction,
    kClosureFunction,
    kImplicitClosureFunction,
    kSignatureFunction,  // represents a signature only without actual code.
    kGetterFunction,     // represents getter functions e.g: get foo() { .. }.
    kSetterFunction,     // represents setter functions e.g: set foo(..) { .. }.
    kConstructor,
    kImplicitGetter,             // represents an implicit getter for fields.
    kImplicitSetter,             // represents an implicit setter for fields.
    kImplicitStaticFinalGetter,  // represents an implicit getter for static
                                 // final fields (incl. static const fields).
    kMethodExtractor,  // converts method into implicit closure on the receiver.
    kNoSuchMethodDispatcher,  // invokes noSuchMethod.
    kInvokeFieldDispatcher,   // invokes a field as a closure.
    kIrregexpFunction,  // represents a generated irregexp matcher function.
    kDynamicInvocationForwarder,  // represents forwarder which performs type
                                  // checks for arguments of a dynamic
                                  // invocation.
  };

  enum AsyncModifier {
    kNoModifier = 0x0,
    kAsyncBit = 0x1,
    kGeneratorBit = 0x2,
    kAsync = kAsyncBit,
    kSyncGen = kGeneratorBit,
    kAsyncGen = kAsyncBit | kGeneratorBit,
  };

  static constexpr intptr_t kMaxFixedParametersBits = 15;
  static constexpr intptr_t kMaxOptionalParametersBits = 14;

 private:
  // So that the SkippedCodeFunctions::DetachCode can null out the code fields.
  friend class SkippedCodeFunctions;
  friend class Class;

  RAW_HEAP_OBJECT_IMPLEMENTATION(Function);

  static bool ShouldVisitCode(RawCode* raw_code);
  static bool CheckUsageCounter(RawFunction* raw_fun);

  uword entry_point_;  // Accessed from generated code.
  uword unchecked_entry_point_;  // Accessed from generated code.

  VISIT_FROM(RawObject*, name_);
  RawString* name_;
  RawObject* owner_;  // Class or patch class or mixin class
                      // where this function is defined.
  RawAbstractType* result_type_;
  RawArray* parameter_types_;
  RawArray* parameter_names_;
  RawTypeArguments* type_parameters_;  // Array of TypeParameter.
  RawObject* data_;  // Additional data specific to the function kind.
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->data_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  RawArray* ic_data_array_;  // ICData of unoptimized code.
  RawObject** to_no_code() {
    return reinterpret_cast<RawObject**>(&ptr()->ic_data_array_);
  }
  RawCode* code_;  // Currently active code. Accessed from generated code.
  NOT_IN_PRECOMPILED(RawBytecode* bytecode_);
  NOT_IN_PRECOMPILED(RawCode* unoptimized_code_);  // Unoptimized code, keep it
                                                   // after optimization.
#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(RawObject*, code_);
#else
  VISIT_TO(RawObject*, unoptimized_code_);
#endif

  NOT_IN_PRECOMPILED(TokenPosition token_pos_);
  NOT_IN_PRECOMPILED(TokenPosition end_token_pos_);
  uint32_t kind_tag_;                          // See Function::KindTagBits.
  uint32_t packed_fields_;

  typedef BitField<uint32_t, bool, 0, 1>
      PackedHasNamedOptionalParameters;
  typedef BitField<uint32_t,
                   bool,
                   PackedHasNamedOptionalParameters::kNextBit,
                   1>
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
                "RawFunction::packed_fields_ bitfields don't align.");

#define JIT_FUNCTION_COUNTERS(F)                                               \
  F(intptr_t, intptr_t, kernel_offset)                                         \
  F(intptr_t, int32_t, usage_counter)                                          \
  F(intptr_t, uint16_t, optimized_instruction_count)                           \
  F(intptr_t, uint16_t, optimized_call_site_count)                             \
  F(int8_t, int8_t, deoptimization_counter)                                    \
  F(intptr_t, int8_t, state_bits)                                              \
  F(int, int8_t, inlining_depth)

#if !defined(DART_PRECOMPILED_RUNTIME)
#define DECLARE(return_type, type, name) type name##_;

  JIT_FUNCTION_COUNTERS(DECLARE)

#undef DECLARE
#endif
};

class RawClosureData : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ClosureData);

  VISIT_FROM(RawObject*, context_scope_);
  RawContextScope* context_scope_;
  RawFunction* parent_function_;  // Enclosing function of this local function.
  RawType* signature_type_;
  RawInstance* closure_;  // Closure object for static implicit closures.
  VISIT_TO(RawObject*, closure_);

  friend class Function;
};

class RawSignatureData : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(SignatureData);

  VISIT_FROM(RawObject*, parent_function_);
  RawFunction* parent_function_;  // Enclosing function of this sig. function.
  RawType* signature_type_;
  VISIT_TO(RawObject*, signature_type_);
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class Function;
};

class RawRedirectionData : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(RedirectionData);

  VISIT_FROM(RawObject*, type_);
  RawType* type_;
  RawString* identifier_;
  RawFunction* target_;
  VISIT_TO(RawObject*, target_);
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawField : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Field);

  VISIT_FROM(RawObject*, name_);
  RawString* name_;
  RawObject* owner_;  // Class or patch class or mixin class
                      // where this field is defined or original field.
  RawAbstractType* type_;
  union {
    RawInstance* static_value_;  // Value for static fields.
    RawSmi* offset_;             // Offset in words for instance fields.
  } value_;
  union {
    // When precompiling we need to save the static initializer function here
    // so that code for it can be generated.
    RawFunction* precompiled_;  // Static initializer function - precompiling.
    // When generating script snapshots after running the application it is
    // necessary to save the initial value of static fields so that we can
    // restore the value back to the original initial value.
    RawInstance* saved_value_;  // Saved initial value - static fields.
  } initializer_;
  RawSmi* guarded_list_length_;
  RawArray* dependent_code_;
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
        return reinterpret_cast<RawObject**>(&ptr()->guarded_list_length_);
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->dependent_code_);
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->initializer_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(RawObject*, dependent_code_);
#else
  RawSubtypeTestCache* type_test_cache_;  // For type test in implicit setter.
  VISIT_TO(RawObject*, type_test_cache_);
#endif
  TokenPosition token_pos_;
  TokenPosition end_token_pos_;
  classid_t guarded_cid_;
  classid_t is_nullable_;  // kNullCid if field can contain null value and
                           // any other value otherwise.
  NOT_IN_PRECOMPILED(intptr_t kernel_offset_);
  // Offset to the guarded length field inside an instance of class matching
  // guarded_cid_. Stored corrected by -kHeapObjectTag to simplify code
  // generated on platforms with weak addressing modes (ARM).
  int8_t guarded_list_length_in_object_offset_;

  // Runtime tracking state of exactness of type annotation of this field.
  // See StaticTypeExactnessState for the meaning and possible values in this
  // field.
  int8_t static_type_exactness_state_;

  uint16_t kind_bits_;  // static, final, const, has initializer....

  friend class CidRewriteVisitor;
};

class RawScript : public RawObject {
 public:
  enum Kind {
    kScriptTag = 0,
    kLibraryTag,
    kSourceTag,
    kEvaluateTag,
    kKernelTag,
  };

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Script);

  VISIT_FROM(RawObject*, url_);
  RawString* url_;
  RawString* resolved_url_;
  RawArray* compile_time_constants_;
  RawTypedData* line_starts_;
  RawArray* debug_positions_;
  RawArray* yield_positions_;
  RawKernelProgramInfo* kernel_program_info_;
  RawString* source_;
  VISIT_TO(RawObject*, source_);
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->url_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->kernel_program_info_);
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
  int8_t kind_;  // Of type Kind.
  intptr_t kernel_script_index_;
  int64_t load_timestamp_;
};

class RawLibrary : public RawObject {
  enum LibraryState {
    kAllocated,       // Initial state.
    kLoadRequested,   // Compiler or script requested load of library.
    kLoadInProgress,  // Library is in the process of being loaded.
    kLoaded,          // Library is loaded.
    kLoadError,       // Error occurred during load of the Library.
  };

  RAW_HEAP_OBJECT_IMPLEMENTATION(Library);

  VISIT_FROM(RawObject*, name_);
  RawString* name_;
  RawString* url_;
  RawString* private_key_;
  RawArray* dictionary_;              // Top-level names in this library.
  RawGrowableObjectArray* metadata_;  // Metadata on classes, methods etc.
  RawClass* toplevel_class_;          // Class containing top-level elements.
  RawGrowableObjectArray* patch_classes_;
  RawArray* imports_;        // List of Namespaces imported without prefix.
  RawArray* exports_;        // List of re-exported Namespaces.
  RawInstance* load_error_;  // Error iff load_state_ == kLoadError.
  RawExternalTypedData* kernel_data_;
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->load_error_);
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->kernel_data_);
      case Snapshot::kMessage:
      case Snapshot::kNone:
      case Snapshot::kInvalid:
        break;
    }
    UNREACHABLE();
    return NULL;
  }
  RawArray* resolved_names_;  // Cache of resolved names in library scope.
  RawArray* exported_names_;  // Cache of exported names by library.
  RawArray* loaded_scripts_;  // Array of scripts loaded in this library.
  VISIT_TO(RawObject*, loaded_scripts_);

  Dart_NativeEntryResolver native_entry_resolver_;  // Resolves natives.
  Dart_NativeEntrySymbol native_entry_symbol_resolver_;
  classid_t index_;       // Library id number.
  uint16_t num_imports_;  // Number of entries in imports_.
  int8_t load_state_;     // Of type LibraryState.
  bool corelib_imported_;
  bool is_dart_scheme_;
  bool debuggable_;          // True if debugger can stop in library.
  bool is_in_fullsnapshot_;  // True if library is in a full snapshot.
  NOT_IN_PRECOMPILED(intptr_t kernel_offset_);  // Offset of this library's
                                                // kernel data in the overall
                                                // kernel program.

  friend class Class;
  friend class Isolate;
};

class RawNamespace : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Namespace);

  VISIT_FROM(RawObject*, library_);
  RawLibrary* library_;       // library with name dictionary.
  RawArray* show_names_;      // list of names that are exported.
  RawArray* hide_names_;      // blacklist of names that are not exported.
  RawField* metadata_field_;  // remembers the token pos of metadata if any,
                              // and the metadata values if computed.
  VISIT_TO(RawObject*, metadata_field_);
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawKernelProgramInfo : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(KernelProgramInfo);

  VISIT_FROM(RawObject*, string_offsets_);
  RawTypedData* string_offsets_;
  RawExternalTypedData* string_data_;
  RawTypedData* canonical_names_;
  RawExternalTypedData* metadata_payloads_;
  RawExternalTypedData* metadata_mappings_;
  RawArray* scripts_;
  RawArray* constants_;
  RawArray* bytecode_component_;
  RawGrowableObjectArray* potential_natives_;
  RawGrowableObjectArray* potential_pragma_functions_;
  RawExternalTypedData* constants_table_;
  RawArray* libraries_cache_;
  RawArray* classes_cache_;
  VISIT_TO(RawObject*, classes_cache_);

  RawObject** to_snapshot(Snapshot::Kind kind) {
    return reinterpret_cast<RawObject**>(&ptr()->potential_natives_);
  }
};

class RawCode : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Code);

  uword entry_point_;          // Accessed from generated code.

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
  uword unchecked_entry_point_;  // Accessed from generated code.
  uword monomorphic_unchecked_entry_point_;  // Accessed from generated code.

  VISIT_FROM(RawObject*, object_pool_);
  RawObjectPool* object_pool_;     // Accessed from generated code.
  RawInstructions* instructions_;  // Accessed from generated code.
  // If owner_ is Function::null() the owner is a regular stub.
  // If owner_ is a Class the owner is the allocation stub for that class.
  // Else, owner_ is a regular Dart Function.
  RawObject* owner_;  // Function, Null, or a Class.
  RawExceptionHandlers* exception_handlers_;
  RawPcDescriptors* pc_descriptors_;
  union {
    RawTypedData* catch_entry_moves_maps_;
    RawSmi* variables_;
  } catch_entry_;
  RawArray* stackmaps_;
  RawArray* inlined_id_to_function_;
  RawCodeSourceMap* code_source_map_;
  NOT_IN_PRECOMPILED(RawInstructions* active_instructions_);
  NOT_IN_PRECOMPILED(RawArray* deopt_info_array_);
  // (code-offset, function, code) triples.
  NOT_IN_PRECOMPILED(RawArray* static_calls_target_table_);
  NOT_IN_PRODUCT(RawArray* await_token_positions_);
  // If return_address_metadata_ is a Smi, it is the offset to the prologue.
  // Else, return_address_metadata_ is null.
  NOT_IN_PRODUCT(RawObject* return_address_metadata_);
  NOT_IN_PRODUCT(RawLocalVarDescriptors* var_descriptors_);
  NOT_IN_PRODUCT(RawArray* comments_);

#if !defined(PRODUCT)
  VISIT_TO(RawObject*, comments_);
#elif defined(DART_PRECOMPILED_RUNTIME)
  VISIT_TO(RawObject*, code_source_map_);
#else
  VISIT_TO(RawObject*, static_calls_target_table_);
#endif

  // Compilation timestamp.
  NOT_IN_PRODUCT(int64_t compile_timestamp_);

  // state_bits_ is a bitfield with three fields:
  // The optimized bit, the alive bit, and a count of the number of pointer
  // offsets.
  // Alive: If true, the embedded object pointers will be visited during GC.
  int32_t state_bits_;

  // Variable length data follows here.
  int32_t* data() { OPEN_ARRAY_START(int32_t, int32_t); }
  const int32_t* data() const { OPEN_ARRAY_START(int32_t, int32_t); }

  static bool ContainsPC(RawObject* raw_obj, uword pc);

  friend class Function;
  template <bool>
  friend class MarkingVisitorBase;
  friend class SkippedCodeFunctions;
  friend class StackFrame;
  friend class Profiler;
  friend class FunctionDeserializationCluster;
};

class RawBytecode : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bytecode);

  uword instructions_;
  intptr_t instructions_size_;

  VISIT_FROM(RawObject*, object_pool_);
  RawObjectPool* object_pool_;
  RawFunction* function_;
  RawExceptionHandlers* exception_handlers_;
  RawPcDescriptors* pc_descriptors_;
  VISIT_TO(RawObject*, pc_descriptors_);
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  int32_t instructions_binary_offset_;
  int32_t source_positions_binary_offset_;

  static bool ContainsPC(RawObject* raw_obj, uword pc);

  friend class Function;
  friend class StackFrame;
};

class RawObjectPool : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ObjectPool);

  intptr_t length_;

  struct Entry {
    union {
      RawObject* raw_obj_;
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
};

class RawInstructions : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instructions);
  VISIT_NOTHING();

  // Instructions size in bytes and flags.
  // Currently, only flag indicates 1 or 2 entry points.
  uint32_t size_and_flags_;
  uint32_t unchecked_entrypoint_pc_offset_;

#if defined(DART_PRECOMPILER)
  // There is a gap between size_and_flags_ and the entry point
  // because we align entry point by 4 words on all platforms.
  // This allows us to have a free field here without affecting
  // the aligned size of the Instructions object header.
  // This also means that entry point offset is the same
  // whether this field is included or excluded.
  CodeStatistics* stats_;
#endif

  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }

  // Private helper function used while visiting stack frames. The
  // code which iterates over dart frames is also called during GC and
  // is not allowed to create handles.
  static bool ContainsPC(RawInstructions* raw_instr, uword pc);

  friend class RawCode;
  friend class RawFunction;
  friend class Code;
  friend class StackFrame;
  template <bool>
  friend class MarkingVisitorBase;
  friend class SkippedCodeFunctions;
  friend class Function;
  friend class ImageReader;
  friend class ImageWriter;
};

class RawPcDescriptors : public RawObject {
 public:
  enum Kind {
    kDeopt = 1,                            // Deoptimization continuation point.
    kIcCall = kDeopt << 1,                 // IC call.
    kUnoptStaticCall = kIcCall << 1,       // Call to a known target via stub.
    kRuntimeCall = kUnoptStaticCall << 1,  // Runtime call.
    kOsrEntry = kRuntimeCall << 1,         // OSR entry point in unopt. code.
    kRewind = kOsrEntry << 1,              // Call rewind target address.
    kOther = kRewind << 1,
    kLastKind = kOther,
    kAnyKind = -1
  };

  class MergedKindTry {
   public:
    // Most of the time try_index will be small and merged field will fit into
    // one byte.
    static intptr_t Encode(intptr_t kind, intptr_t try_index) {
      intptr_t kind_shift = Utils::ShiftForPowerOfTwo(kind);
      ASSERT(Utils::IsUint(kKindShiftSize, kind_shift));
      ASSERT(Utils::IsInt(kTryIndexSize, try_index));
      return (try_index << kTryIndexPos) | (kind_shift << kKindShiftPos);
    }

    static intptr_t DecodeKind(intptr_t merged_kind_try) {
      const intptr_t kKindShiftMask = (1 << kKindShiftSize) - 1;
      return 1 << (merged_kind_try & kKindShiftMask);
    }

    static intptr_t DecodeTryIndex(intptr_t merged_kind_try) {
      // Arithmetic shift.
      return merged_kind_try >> kTryIndexPos;
    }

   private:
    static const intptr_t kKindShiftPos = 0;
    static const intptr_t kKindShiftSize = 3;
    // Is kKindShiftSize enough bits?
    COMPILE_ASSERT(kLastKind <= 1 << ((1 << kKindShiftSize) - 1));

    static const intptr_t kTryIndexPos = kKindShiftSize;
    static const intptr_t kTryIndexSize = kBitsPerWord - kKindShiftSize;
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
};

// CodeSourceMap encodes a mapping from code PC ranges to source token
// positions and the stack of inlined functions.
class RawCodeSourceMap : public RawObject {
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
};

// StackMap is an immutable representation of the layout of the stack at a
// PC. The stack map representation consists of a bit map which marks each
// live object index starting from the base of the frame.
//
// The bit map representation is optimized for dense and small bit maps, without
// any upper bound.
class RawStackMap : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(StackMap);
  VISIT_NOTHING();

  // Offset from code entry point corresponding to this stack map
  // representation.
  uint32_t pc_offset_;

  uint16_t length_;               // Length of payload, in bits.
  uint16_t slow_path_bit_count_;  // Slow path live values, included in length_.
  // ARM64 requires register_bit_count_ to be as large as 96.

  // Variable length data follows here (bitmap of the stack layout).
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }
};

class RawLocalVarDescriptors : public RawObject {
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

  VISIT_FROM(RawObject*, names()[0]);
  RawString** names() {
    // Array of [num_entries_] variable names.
    OPEN_ARRAY_START(RawString*, RawString*);
  }
  RawString** nameAddrAt(intptr_t i) { return &(ptr()->names()[i]); }
  VISIT_TO_LENGTH(RawObject*, nameAddrAt(length - 1));

  // Variable info with [num_entries_] entries.
  VarInfo* data() {
    return reinterpret_cast<VarInfo*>(nameAddrAt(ptr()->num_entries_));
  }

  friend class Object;
};

class RawExceptionHandlers : public RawObject {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExceptionHandlers);

  // Number of exception handler entries.
  int32_t num_entries_;

  // Array with [num_entries_] entries. Each entry is an array of all handled
  // exception types.
  VISIT_FROM(RawObject*, handled_types_data_)
  RawArray* handled_types_data_;
  VISIT_TO_LENGTH(RawObject*, &ptr()->handled_types_data_);

  // Exception handler info of length [num_entries_].
  const ExceptionHandlerInfo* data() const {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }
  ExceptionHandlerInfo* data() {
    OPEN_ARRAY_START(ExceptionHandlerInfo, intptr_t);
  }

  friend class Object;
};

class RawContext : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Context);

  int32_t num_variables_;

  VISIT_FROM(RawObject*, parent_);
  RawContext* parent_;

  // Variable length data follows here.
  RawObject** data() { OPEN_ARRAY_START(RawObject*, RawObject*); }
  RawObject* const* data() const { OPEN_ARRAY_START(RawObject*, RawObject*); }
  VISIT_TO_LENGTH(RawObject*, &ptr()->data()[length - 1]);

  friend class Object;
  friend class SnapshotReader;
};

class RawContextScope : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ContextScope);

  // TODO(iposva): Switch to conventional enum offset based structure to avoid
  // alignment mishaps.
  struct VariableDesc {
    RawSmi* declaration_token_pos;
    RawSmi* token_pos;
    RawString* name;
    RawBool* is_final;
    RawBool* is_const;
    union {
      RawAbstractType* type;
      RawInstance* value;  // iff is_const is true
    };
    RawSmi* context_index;
    RawSmi* context_level;
  };

  int32_t num_variables_;
  bool is_implicit_;  // true, if this context scope is for an implicit closure.

  RawObject** from() {
    VariableDesc* begin = const_cast<VariableDesc*>(ptr()->VariableDescAddr(0));
    return reinterpret_cast<RawObject**>(begin);
  }
  // Variable length data follows here.
  RawObject* const* data() const { OPEN_ARRAY_START(RawObject*, RawObject*); }
  const VariableDesc* VariableDescAddr(intptr_t index) const {
    ASSERT((index >= 0) && (index < num_variables_ + 1));
    // data() points to the first component of the first descriptor.
    return &(reinterpret_cast<const VariableDesc*>(data())[index]);
  }
  RawObject** to(intptr_t num_vars) {
    uword end = reinterpret_cast<uword>(ptr()->VariableDescAddr(num_vars));
    // 'end' is the address just beyond the last descriptor, so step back.
    return reinterpret_cast<RawObject**>(end - kWordSize);
  }
  RawObject** to_snapshot(Snapshot::Kind kind, intptr_t num_vars) {
    return to(num_vars);
  }

  friend class Object;
  friend class RawClosureData;
  friend class SnapshotReader;
};

class RawSingleTargetCache : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SingleTargetCache);
  VISIT_FROM(RawObject*, target_);
  RawCode* target_;
  VISIT_TO(RawObject*, target_);
  uword entry_point_;
  classid_t lower_limit_;
  classid_t upper_limit_;
};

class RawUnlinkedCall : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnlinkedCall);
  VISIT_FROM(RawObject*, target_name_);
  RawString* target_name_;
  RawArray* args_descriptor_;
  VISIT_TO(RawObject*, args_descriptor_);
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawICData : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ICData);

  VISIT_FROM(RawObject*, ic_data_);
  RawArray* ic_data_;          // Contains class-ids, target and count.
  RawString* target_name_;     // Name of target function.
  RawArray* args_descriptor_;  // Arguments descriptor.
  // Static type of the receiver. If it is set then we are performing
  // exactness profiling for the receiver type. See StaticTypeExactnessState
  // class for more information.
  NOT_IN_PRECOMPILED(RawAbstractType* static_receiver_type_);
  RawObject* owner_;  // Parent/calling function or original IC of cloned IC.
  VISIT_TO(RawObject*, owner_);
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->args_descriptor_);
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

class RawMegamorphicCache : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MegamorphicCache);

  VISIT_FROM(RawObject*, buckets_)
  RawArray* buckets_;
  RawSmi* mask_;
  RawString* target_name_;     // Name of target function.
  RawArray* args_descriptor_;  // Arguments descriptor.
  VISIT_TO(RawObject*, args_descriptor_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  int32_t filled_entry_count_;
};

class RawSubtypeTestCache : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SubtypeTestCache);
  VISIT_FROM(RawObject*, cache_);
  RawArray* cache_;
  VISIT_TO(RawObject*, cache_);
};

class RawError : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Error);
};

class RawApiError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ApiError);

  VISIT_FROM(RawObject*, message_)
  RawString* message_;
  VISIT_TO(RawObject*, message_)
};

class RawLanguageError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LanguageError);

  VISIT_FROM(RawObject*, previous_error_)
  RawError* previous_error_;  // May be null.
  RawScript* script_;
  RawString* message_;
  RawString* formatted_message_;  // Incl. previous error's formatted message.
  VISIT_TO(RawObject*, formatted_message_)
  TokenPosition token_pos_;  // Source position in script_.
  bool report_after_token_;  // Report message at or after the token.
  int8_t kind_;              // Of type Report::Kind.

  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawUnhandledException : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnhandledException);

  VISIT_FROM(RawObject*, exception_)
  RawInstance* exception_;
  RawInstance* stacktrace_;
  VISIT_TO(RawObject*, stacktrace_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawUnwindError : public RawError {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UnwindError);

  VISIT_FROM(RawObject*, message_)
  RawString* message_;
  VISIT_TO(RawObject*, message_)
  bool is_user_initiated_;
};

class RawInstance : public RawObject {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Instance);
};

class RawLibraryPrefix : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LibraryPrefix);

  VISIT_FROM(RawObject*, name_)
  RawString* name_;           // Library prefix name.
  RawLibrary* importer_;      // Library which declares this prefix.
  RawArray* imports_;         // Libraries imported with this prefix.
  RawArray* dependent_code_;  // Code that refers to deferred, unloaded
                              // library prefix.
  VISIT_TO(RawObject*, dependent_code_)
  RawObject** to_snapshot(Snapshot::Kind kind) {
    switch (kind) {
      case Snapshot::kFull:
      case Snapshot::kFullJIT:
        return reinterpret_cast<RawObject**>(&ptr()->imports_);
      case Snapshot::kFullAOT:
        return reinterpret_cast<RawObject**>(&ptr()->importer_);
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

class RawTypeArguments : public RawInstance {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeArguments);

  VISIT_FROM(RawObject*, instantiations_)
  // The instantiations_ array remains empty for instantiated type arguments.
  RawArray* instantiations_;  // Array of paired canonical vectors:
                              // Even index: instantiator.
                              // Odd index: instantiated (without bound error).
  // Instantiations leading to bound errors do not get cached.
  RawSmi* length_;
  RawSmi* hash_;

  // Variable length data follows here.
  RawAbstractType* const* types() const {
    OPEN_ARRAY_START(RawAbstractType*, RawAbstractType*);
  }
  RawAbstractType** types() {
    OPEN_ARRAY_START(RawAbstractType*, RawAbstractType*);
  }
  RawObject** to(intptr_t length) {
    return reinterpret_cast<RawObject**>(&ptr()->types()[length - 1]);
  }

  friend class Object;
  friend class SnapshotReader;
};

class RawAbstractType : public RawInstance {
 protected:
  enum TypeState {
    kAllocated,                // Initial state.
    kBeingFinalized,           // In the process of being finalized.
    kFinalizedInstantiated,    // Instantiated type ready for use.
    kFinalizedUninstantiated,  // Uninstantiated type ready for use.
  };

  uword type_test_stub_entry_point_;  // Accessed from generated code.
  RawCode* type_test_stub_;  // Must be the last field, since subclasses use it
                             // in their VISIT_FROM.

 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(AbstractType);

  friend class ObjectStore;
  friend class StubCode;
};

class RawType : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Type);

  VISIT_FROM(RawObject*, type_test_stub_)
  RawSmi* type_class_id_;
  RawTypeArguments* arguments_;
  RawSmi* hash_;
  // This type object represents a function type if its signature field is a
  // non-null function object.
  RawFunction* signature_;  // If not null, this type is a function type.
  VISIT_TO(RawObject*, signature_)
  TokenPosition token_pos_;
  int8_t type_state_;

  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class CidRewriteVisitor;
  friend class RawTypeArguments;
};

class RawTypeRef : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeRef);

  VISIT_FROM(RawObject*, type_test_stub_)
  RawAbstractType* type_;  // The referenced type.
  VISIT_TO(RawObject*, type_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }
};

class RawTypeParameter : public RawAbstractType {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypeParameter);

  VISIT_FROM(RawObject*, type_test_stub_)
  RawString* name_;
  RawSmi* hash_;
  RawAbstractType* bound_;  // ObjectType if no explicit bound specified.
  RawFunction* parameterized_function_;
  VISIT_TO(RawObject*, parameterized_function_)
  classid_t parameterized_class_id_;
  TokenPosition token_pos_;
  int16_t index_;
  int8_t type_state_;

  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class CidRewriteVisitor;
};

class RawClosure : public RawInstance {
 private:
  RAW_HEAP_OBJECT_IMPLEMENTATION(Closure);

  // No instance fields should be declared before the following fields whose
  // offsets must be identical in Dart and C++.

  // The following fields are also declared in the Dart source of class
  // _Closure.
  VISIT_FROM(RawCompressed, instantiator_type_arguments_)
  RawTypeArguments* instantiator_type_arguments_;
  RawTypeArguments* function_type_arguments_;
  RawTypeArguments* delayed_type_arguments_;
  RawFunction* function_;
  RawContext* context_;
  RawSmi* hash_;

  VISIT_TO(RawCompressed, hash_)

  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

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

class RawNumber : public RawInstance {
  RAW_OBJECT_IMPLEMENTATION(Number);
};

class RawInteger : public RawNumber {
  RAW_OBJECT_IMPLEMENTATION(Integer);
};

class RawSmi : public RawInteger {
  RAW_OBJECT_IMPLEMENTATION(Smi);
};

class RawMint : public RawInteger {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Mint);
  VISIT_NOTHING();

  ALIGN8 int64_t value_;

  friend class Api;
  friend class Integer;
  friend class SnapshotReader;
};
COMPILE_ASSERT(sizeof(RawMint) == 16);

class RawDouble : public RawNumber {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Double);
  VISIT_NOTHING();

  ALIGN8 double value_;

  friend class Api;
  friend class SnapshotReader;
};
COMPILE_ASSERT(sizeof(RawDouble) == 16);

class RawString : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(String);

 protected:
  VISIT_FROM(RawObject*, length_)
  RawSmi* length_;
#if !defined(HASH_IN_OBJECT_HEADER)
  RawSmi* hash_;
  VISIT_TO(RawObject*, hash_)
#else
  VISIT_TO(RawObject*, length_)
#endif

 private:
  friend class Library;
  friend class OneByteStringSerializationCluster;
  friend class TwoByteStringSerializationCluster;
  friend class OneByteStringDeserializationCluster;
  friend class TwoByteStringDeserializationCluster;
  friend class RODataSerializationCluster;
};

class RawOneByteString : public RawString {
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

class RawTwoByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TwoByteString);
  VISIT_NOTHING();

  // Variable length data follows here.
  uint16_t* data() { OPEN_ARRAY_START(uint16_t, uint16_t); }
  const uint16_t* data() const { OPEN_ARRAY_START(uint16_t, uint16_t); }

  friend class RODataSerializationCluster;
  friend class SnapshotReader;
  friend class String;
};

class RawExternalOneByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalOneByteString);

  const uint8_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class RawExternalTwoByteString : public RawString {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTwoByteString);

  const uint16_t* external_data_;
  void* peer_;
  friend class Api;
  friend class String;
};

class RawBool : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Bool);
  VISIT_NOTHING();

  bool value_;
};

class RawArray : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Array);

  VISIT_FROM(RawCompressed, type_arguments_)
  RawTypeArguments* type_arguments_;
  RawSmi* length_;
  // Variable length data follows here.
  RawObject** data() { OPEN_ARRAY_START(RawObject*, RawObject*); }
  RawObject* const* data() const { OPEN_ARRAY_START(RawObject*, RawObject*); }
  VISIT_TO_LENGTH(RawCompressed, &ptr()->data()[length - 1])

  friend class LinkedHashMapSerializationCluster;
  friend class LinkedHashMapDeserializationCluster;
  friend class CodeDeserializationCluster;
  friend class Deserializer;
  friend class RawCode;
  friend class RawImmutableArray;
  friend class SnapshotReader;
  friend class GrowableObjectArray;
  friend class LinkedHashMap;
  friend class RawLinkedHashMap;
  friend class Object;
  friend class ICData;            // For high performance access.
  friend class SubtypeTestCache;  // For high performance access.

  friend class HeapPage;
};

class RawImmutableArray : public RawArray {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ImmutableArray);

  friend class SnapshotReader;
};

class RawGrowableObjectArray : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(GrowableObjectArray);

  VISIT_FROM(RawCompressed, type_arguments_)
  RawTypeArguments* type_arguments_;
  RawSmi* length_;
  RawArray* data_;
  VISIT_TO(RawCompressed, data_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  friend class SnapshotReader;
};

class RawLinkedHashMap : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(LinkedHashMap);

  VISIT_FROM(RawCompressed, type_arguments_)
  RawTypeArguments* type_arguments_;
  RawTypedData* index_;
  RawSmi* hash_mask_;
  RawArray* data_;
  RawSmi* used_data_;
  RawSmi* deleted_keys_;
  VISIT_TO(RawCompressed, deleted_keys_)

  friend class SnapshotReader;
};

class RawFloat32x4 : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float32x4);
  VISIT_NOTHING();

  ALIGN8 float value_[4];

  friend class SnapshotReader;

 public:
  float x() const { return value_[0]; }
  float y() const { return value_[1]; }
  float z() const { return value_[2]; }
  float w() const { return value_[3]; }
};
COMPILE_ASSERT(sizeof(RawFloat32x4) == 24);

class RawInt32x4 : public RawInstance {
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
COMPILE_ASSERT(sizeof(RawInt32x4) == 24);

class RawFloat64x2 : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Float64x2);
  VISIT_NOTHING();

  ALIGN8 double value_[2];

  friend class SnapshotReader;

 public:
  double x() const { return value_[0]; }
  double y() const { return value_[1]; }
};
COMPILE_ASSERT(sizeof(RawFloat64x2) == 24);

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

class RawTypedData : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(TypedData);

 protected:
  VISIT_FROM(RawCompressed, length_)
  RawSmi* length_;
  VISIT_TO_LENGTH(RawCompressed, &ptr()->length_)
  // Variable length data follows here.
  uint8_t* data() { OPEN_ARRAY_START(uint8_t, uint8_t); }
  const uint8_t* data() const { OPEN_ARRAY_START(uint8_t, uint8_t); }

  friend class Api;
  friend class Instance;
  friend class NativeEntryData;
  friend class Object;
  friend class ObjectPool;
  friend class ObjectPoolDeserializationCluster;
  friend class ObjectPoolSerializationCluster;
  friend class RawObjectPool;
  friend class SnapshotReader;
};

class RawExternalTypedData : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ExternalTypedData);

 protected:
  VISIT_FROM(RawCompressed, length_)
  RawSmi* length_;
  VISIT_TO(RawCompressed, length_)

  uint8_t* data_;

  friend class RawBytecode;
};

// VM implementations of the basic types in the isolate.
class RawCapability : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(Capability);
  VISIT_NOTHING();
  uint64_t id_;
};

class RawSendPort : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(SendPort);
  VISIT_NOTHING();
  Dart_Port id_;
  Dart_Port origin_id_;

  friend class ReceivePort;
};

class RawReceivePort : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(ReceivePort);

  VISIT_FROM(RawObject*, send_port_)
  RawSendPort* send_port_;
  RawInstance* handler_;
  VISIT_TO(RawObject*, handler_)
};

// VM type for capturing stacktraces when exceptions are thrown,
// Currently we don't have any interface that this object is supposed
// to implement so we just support the 'toString' method which
// converts the stack trace into a string.
class RawStackTrace : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(StackTrace);

  VISIT_FROM(RawObject*, async_link_)
  RawStackTrace* async_link_;  // Link to parent async stack trace.
  RawArray* code_array_;       // Code object for each frame in the stack trace.
  RawArray* pc_offset_array_;  // Offset of PC for each frame.
  VISIT_TO(RawObject*, pc_offset_array_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  // False for pre-allocated stack trace (used in OOM and Stack overflow).
  bool expand_inlined_;
};

// VM type for capturing JS regular expressions.
class RawRegExp : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(RegExp);

  VISIT_FROM(RawObject*, num_bracket_expressions_)
  RawSmi* num_bracket_expressions_;
  RawString* pattern_;  // Pattern to be used for matching.
  union {
    RawFunction* function_;
    RawTypedData* bytecode_;
  } one_byte_;
  union {
    RawFunction* function_;
    RawTypedData* bytecode_;
  } two_byte_;
  RawFunction* external_one_byte_function_;
  RawFunction* external_two_byte_function_;
  union {
    RawFunction* function_;
    RawTypedData* bytecode_;
  } one_byte_sticky_;
  union {
    RawFunction* function_;
    RawTypedData* bytecode_;
  } two_byte_sticky_;
  RawFunction* external_one_byte_sticky_function_;
  RawFunction* external_two_byte_sticky_function_;
  VISIT_TO(RawObject*, external_two_byte_sticky_function_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  intptr_t num_registers_;

  // A bitfield with two fields:
  // type: Uninitialized, simple or complex.
  // flags: Represents global/local, case insensitive, multiline.
  int8_t type_flags_;
};

class RawWeakProperty : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(WeakProperty);

  VISIT_FROM(RawObject*, key_)
  RawObject* key_;
  RawObject* value_;
  VISIT_TO(RawObject*, value_)
  RawObject** to_snapshot(Snapshot::Kind kind) { return to(); }

  // Linked list is chaining all pending weak properties.
  // Untyped to make it clear that it is not to be visited by GC.
  uword next_;

  friend class GCMarker;
  template <bool>
  friend class MarkingVisitorBase;
  friend class Scavenger;
  friend class ScavengerVisitor;
};

// MirrorReferences are used by mirrors to hold reflectees that are VM
// internal objects, such as libraries, classes, functions or types.
class RawMirrorReference : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(MirrorReference);

  VISIT_FROM(RawObject*, referent_)
  RawObject* referent_;
  VISIT_TO(RawObject*, referent_)
};

// UserTag are used by the profiler to track Dart script state.
class RawUserTag : public RawInstance {
  RAW_HEAP_OBJECT_IMPLEMENTATION(UserTag);

  VISIT_FROM(RawObject*, label_)
  RawString* label_;
  VISIT_TO(RawObject*, label_)

  // Isolate unique tag.
  uword tag_;

  friend class SnapshotReader;
  friend class Object;

 public:
  uword tag() const { return tag_; }
};

// Class Id predicates.

inline bool RawObject::IsErrorClassId(intptr_t index) {
  // Make sure this function is updated when new Error types are added.
  COMPILE_ASSERT(
      kApiErrorCid == kErrorCid + 1 && kLanguageErrorCid == kErrorCid + 2 &&
      kUnhandledExceptionCid == kErrorCid + 3 &&
      kUnwindErrorCid == kErrorCid + 4 && kInstanceCid == kErrorCid + 5);
  return (index >= kErrorCid && index < kInstanceCid);
}

inline bool RawObject::IsNumberClassId(intptr_t index) {
  // Make sure this function is updated when new Number types are added.
  COMPILE_ASSERT(kIntegerCid == kNumberCid + 1 && kSmiCid == kNumberCid + 2 &&
                 kMintCid == kNumberCid + 3 && kDoubleCid == kNumberCid + 4);
  return (index >= kNumberCid && index <= kDoubleCid);
}

inline bool RawObject::IsIntegerClassId(intptr_t index) {
  // Make sure this function is updated when new Integer types are added.
  COMPILE_ASSERT(kSmiCid == kIntegerCid + 1 && kMintCid == kIntegerCid + 2);
  return (index >= kIntegerCid && index <= kMintCid);
}

inline bool RawObject::IsStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index >= kStringCid && index <= kExternalTwoByteStringCid);
}

inline bool RawObject::IsOneByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kOneByteStringCid || index == kExternalOneByteStringCid);
}

inline bool RawObject::IsTwoByteStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kTwoByteStringCid || index == kExternalTwoByteStringCid);
}

inline bool RawObject::IsExternalStringClassId(intptr_t index) {
  // Make sure this function is updated when new StringCid types are added.
  COMPILE_ASSERT(kOneByteStringCid == kStringCid + 1 &&
                 kTwoByteStringCid == kStringCid + 2 &&
                 kExternalOneByteStringCid == kStringCid + 3 &&
                 kExternalTwoByteStringCid == kStringCid + 4);
  return (index == kExternalOneByteStringCid ||
          index == kExternalTwoByteStringCid);
}

inline bool RawObject::IsBuiltinListClassId(intptr_t index) {
  // Make sure this function is updated when new builtin List types are added.
  COMPILE_ASSERT(kImmutableArrayCid == kArrayCid + 1);
  return ((index >= kArrayCid && index <= kImmutableArrayCid) ||
          (index == kGrowableObjectArrayCid) || IsTypedDataClassId(index) ||
          IsTypedDataViewClassId(index) || IsExternalTypedDataClassId(index) ||
          (index == kByteBufferCid));
}

inline bool RawObject::IsTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataUint8ArrayCid == kTypedDataInt8ArrayCid + 1 &&
                 kTypedDataUint8ClampedArrayCid == kTypedDataInt8ArrayCid + 2 &&
                 kTypedDataInt16ArrayCid == kTypedDataInt8ArrayCid + 3 &&
                 kTypedDataUint16ArrayCid == kTypedDataInt8ArrayCid + 4 &&
                 kTypedDataInt32ArrayCid == kTypedDataInt8ArrayCid + 5 &&
                 kTypedDataUint32ArrayCid == kTypedDataInt8ArrayCid + 6 &&
                 kTypedDataInt64ArrayCid == kTypedDataInt8ArrayCid + 7 &&
                 kTypedDataUint64ArrayCid == kTypedDataInt8ArrayCid + 8 &&
                 kTypedDataFloat32ArrayCid == kTypedDataInt8ArrayCid + 9 &&
                 kTypedDataFloat64ArrayCid == kTypedDataInt8ArrayCid + 10 &&
                 kTypedDataFloat32x4ArrayCid == kTypedDataInt8ArrayCid + 11 &&
                 kTypedDataInt32x4ArrayCid == kTypedDataInt8ArrayCid + 12 &&
                 kTypedDataFloat64x2ArrayCid == kTypedDataInt8ArrayCid + 13 &&
                 kTypedDataInt8ArrayViewCid == kTypedDataInt8ArrayCid + 14);
  return (index >= kTypedDataInt8ArrayCid &&
          index <= kTypedDataFloat64x2ArrayCid);
}

inline bool RawObject::IsTypedDataViewClassId(intptr_t index) {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(
      kTypedDataUint8ArrayViewCid == kTypedDataInt8ArrayViewCid + 1 &&
      kTypedDataUint8ClampedArrayViewCid == kTypedDataInt8ArrayViewCid + 2 &&
      kTypedDataInt16ArrayViewCid == kTypedDataInt8ArrayViewCid + 3 &&
      kTypedDataUint16ArrayViewCid == kTypedDataInt8ArrayViewCid + 4 &&
      kTypedDataInt32ArrayViewCid == kTypedDataInt8ArrayViewCid + 5 &&
      kTypedDataUint32ArrayViewCid == kTypedDataInt8ArrayViewCid + 6 &&
      kTypedDataInt64ArrayViewCid == kTypedDataInt8ArrayViewCid + 7 &&
      kTypedDataUint64ArrayViewCid == kTypedDataInt8ArrayViewCid + 8 &&
      kTypedDataFloat32ArrayViewCid == kTypedDataInt8ArrayViewCid + 9 &&
      kTypedDataFloat64ArrayViewCid == kTypedDataInt8ArrayViewCid + 10 &&
      kTypedDataFloat32x4ArrayViewCid == kTypedDataInt8ArrayViewCid + 11 &&
      kTypedDataInt32x4ArrayViewCid == kTypedDataInt8ArrayViewCid + 12 &&
      kTypedDataFloat64x2ArrayViewCid == kTypedDataInt8ArrayViewCid + 13 &&
      kByteDataViewCid == kTypedDataInt8ArrayViewCid + 14 &&
      kExternalTypedDataInt8ArrayCid == kTypedDataInt8ArrayViewCid + 15);
  return (index >= kTypedDataInt8ArrayViewCid && index <= kByteDataViewCid);
}

inline bool RawObject::IsExternalTypedDataClassId(intptr_t index) {
  // Make sure this is updated when new ExternalTypedData types are added.
  COMPILE_ASSERT(
      (kExternalTypedDataUint8ArrayCid == kExternalTypedDataInt8ArrayCid + 1) &&
      (kExternalTypedDataUint8ClampedArrayCid ==
       kExternalTypedDataInt8ArrayCid + 2) &&
      (kExternalTypedDataInt16ArrayCid == kExternalTypedDataInt8ArrayCid + 3) &&
      (kExternalTypedDataUint16ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 4) &&
      (kExternalTypedDataInt32ArrayCid == kExternalTypedDataInt8ArrayCid + 5) &&
      (kExternalTypedDataUint32ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 6) &&
      (kExternalTypedDataInt64ArrayCid == kExternalTypedDataInt8ArrayCid + 7) &&
      (kExternalTypedDataUint64ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 8) &&
      (kExternalTypedDataFloat32ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 9) &&
      (kExternalTypedDataFloat64ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 10) &&
      (kExternalTypedDataFloat32x4ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 11) &&
      (kExternalTypedDataInt32x4ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 12) &&
      (kExternalTypedDataFloat64x2ArrayCid ==
       kExternalTypedDataInt8ArrayCid + 13) &&
      (kByteBufferCid == kExternalTypedDataInt8ArrayCid + 14));
  return (index >= kExternalTypedDataInt8ArrayCid &&
          index <= kExternalTypedDataFloat64x2ArrayCid);
}

inline bool RawObject::IsInternalVMdefinedClassId(intptr_t index) {
  return ((index < kNumPredefinedCids) &&
          !RawObject::IsImplicitFieldClassId(index));
}

inline bool RawObject::IsVariableSizeClassId(intptr_t index) {
  return (index == kArrayCid) || (index == kImmutableArrayCid) ||
         RawObject::IsOneByteStringClassId(index) ||
         RawObject::IsTwoByteStringClassId(index) ||
         RawObject::IsTypedDataClassId(index) || (index == kContextCid) ||
         (index == kTypeArgumentsCid) || (index == kInstructionsCid) ||
         (index == kObjectPoolCid) || (index == kPcDescriptorsCid) ||
         (index == kCodeSourceMapCid) || (index == kStackMapCid) ||
         (index == kLocalVarDescriptorsCid) ||
         (index == kExceptionHandlersCid) || (index == kCodeCid) ||
         (index == kContextScopeCid) || (index == kInstanceCid) ||
         (index == kRegExpCid);
}

// This is a set of classes that are not Dart classes whose representation
// is defined by the VM but are used in the VM code by computing the
// implicit field offsets of the various fields in the dart object.
inline bool RawObject::IsImplicitFieldClassId(intptr_t index) {
  return (IsTypedDataViewClassId(index) || index == kByteBufferCid);
}

inline intptr_t RawObject::NumberOfTypedDataClasses() {
  // Make sure this is updated when new TypedData types are added.
  COMPILE_ASSERT(kTypedDataInt8ArrayViewCid == kTypedDataInt8ArrayCid + 14);
  COMPILE_ASSERT(kExternalTypedDataInt8ArrayCid ==
                 kTypedDataInt8ArrayViewCid + 15);
  COMPILE_ASSERT(kByteBufferCid == kExternalTypedDataInt8ArrayCid + 14);
  COMPILE_ASSERT(kNullCid == kByteBufferCid + 1);
  return (kNullCid - kTypedDataInt8ArrayCid);
}

}  // namespace dart

#endif  // RUNTIME_VM_RAW_OBJECT_H_
