// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph_copy.h"

#include <memory>

#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/heap/weak_table.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"
#include "vm/timeline.h"

#define Z zone_

// The list here contains two kinds of classes of objects
//   * objects that will be shared and we will therefore never need to copy
//   * objects that user object graphs should never reference
#define FOR_UNSUPPORTED_CLASSES(V)                                             \
  V(AbstractType)                                                              \
  V(ApiError)                                                                  \
  V(Bool)                                                                      \
  V(CallSiteData)                                                              \
  V(Capability)                                                                \
  V(Class)                                                                     \
  V(ClosureData)                                                               \
  V(Code)                                                                      \
  V(CodeSourceMap)                                                             \
  V(CompressedStackMaps)                                                       \
  V(ContextScope)                                                              \
  V(DynamicLibrary)                                                            \
  V(Error)                                                                     \
  V(ExceptionHandlers)                                                         \
  V(FfiTrampolineData)                                                         \
  V(Field)                                                                     \
  V(Finalizer)                                                                 \
  V(FinalizerBase)                                                             \
  V(FinalizerEntry)                                                            \
  V(NativeFinalizer)                                                           \
  V(Function)                                                                  \
  V(FunctionType)                                                              \
  V(FutureOr)                                                                  \
  V(ICData)                                                                    \
  V(Instance)                                                                  \
  V(Instructions)                                                              \
  V(InstructionsSection)                                                       \
  V(InstructionsTable)                                                         \
  V(Int32x4)                                                                   \
  V(Integer)                                                                   \
  V(KernelProgramInfo)                                                         \
  V(LanguageError)                                                             \
  V(Library)                                                                   \
  V(LibraryPrefix)                                                             \
  V(LoadingUnit)                                                               \
  V(LocalVarDescriptors)                                                       \
  V(MegamorphicCache)                                                          \
  V(Mint)                                                                      \
  V(MirrorReference)                                                           \
  V(MonomorphicSmiableCall)                                                    \
  V(Namespace)                                                                 \
  V(Number)                                                                    \
  V(ObjectPool)                                                                \
  V(PatchClass)                                                                \
  V(PcDescriptors)                                                             \
  V(Pointer)                                                                   \
  V(ReceivePort)                                                               \
  V(RecordType)                                                                \
  V(RegExp)                                                                    \
  V(Script)                                                                    \
  V(Sentinel)                                                                  \
  V(SendPort)                                                                  \
  V(SingleTargetCache)                                                         \
  V(Smi)                                                                       \
  V(StackTrace)                                                                \
  V(SubtypeTestCache)                                                          \
  V(SuspendState)                                                              \
  V(Type)                                                                      \
  V(TypeArguments)                                                             \
  V(TypeParameter)                                                             \
  V(TypeParameters)                                                            \
  V(TypedDataBase)                                                             \
  V(UnhandledException)                                                        \
  V(UnlinkedCall)                                                              \
  V(UnwindError)                                                               \
  V(UserTag)                                                                   \
  V(WeakArray)                                                                 \
  V(WeakSerializationReference)

namespace dart {

DEFINE_FLAG(bool,
            enable_fast_object_copy,
            true,
            "Enable fast path for fast object copy.");
DEFINE_FLAG(bool,
            gc_on_foc_slow_path,
            false,
            "Cause a GC when falling off the fast path for fast object copy.");

const char* kFastAllocationFailed = "fast allocation failed";

struct PtrTypes {
  using Object = ObjectPtr;
  static const dart::UntaggedObject* UntagObject(Object arg) {
    return arg.untag();
  }
  static const dart::ObjectPtr GetObjectPtr(Object arg) { return arg; }
  static const dart::Object& HandlifyObject(ObjectPtr arg) {
    return dart::Object::Handle(arg);
  }

#define DO(V)                                                                  \
  using V = V##Ptr;                                                            \
  static Untagged##V* Untag##V(V##Ptr arg) { return arg.untag(); }             \
  static V##Ptr Get##V##Ptr(V##Ptr arg) { return arg; }                        \
  static V##Ptr Cast##V(ObjectPtr arg) { return dart::V::RawCast(arg); }
  CLASS_LIST_FOR_HANDLES(DO)
#undef DO
};

struct HandleTypes {
  using Object = const dart::Object&;
  static const dart::UntaggedObject* UntagObject(Object arg) {
    return arg.ptr().untag();
  }
  static dart::ObjectPtr GetObjectPtr(Object arg) { return arg.ptr(); }
  static Object HandlifyObject(Object arg) { return arg; }

#define DO(V)                                                                  \
  using V = const dart::V&;                                                    \
  static Untagged##V* Untag##V(V arg) { return arg.ptr().untag(); }            \
  static V##Ptr Get##V##Ptr(V arg) { return arg.ptr(); }                       \
  static V Cast##V(const dart::Object& arg) { return dart::V::Cast(arg); }
  CLASS_LIST_FOR_HANDLES(DO)
#undef DO
};

DART_FORCE_INLINE
static ObjectPtr Marker() {
  return Object::unknown_constant().ptr();
}

DART_FORCE_INLINE
static bool CanShareObject(ObjectPtr obj, uword tags) {
  if ((tags & UntaggedObject::CanonicalBit::mask_in_place()) != 0) {
    return true;
  }
  const auto cid = UntaggedObject::ClassIdTag::decode(tags);
  if ((tags & UntaggedObject::ImmutableBit::mask_in_place()) != 0) {
    if (IsUnmodifiableTypedDataViewClassId(cid)) {
      // Unmodifiable typed data views may have mutable backing stores.
      return TypedDataView::RawCast(obj)
          ->untag()
          ->typed_data()
          ->untag()
          ->IsImmutable();
    }
    // All other objects that have immutability bit set are deeply immutable.
    return true;
  }

  if (cid == kClosureCid) {
    // We can share a closure iff it doesn't close over any state.
    return Closure::RawCast(obj)->untag()->context() == Object::null();
  }

  return false;
}

bool CanShareObjectAcrossIsolates(ObjectPtr obj) {
  if (!obj->IsHeapObject()) return true;
  const uword tags = TagsFromUntaggedObject(obj.untag());
  return CanShareObject(obj, tags);
}

// Whether executing `get:hashCode` (possibly in a different isolate) on an
// object with the given [tags] might return a different answer than the source
// object (if copying is needed) or on the same object (if the object is
// shared).
DART_FORCE_INLINE
static bool MightNeedReHashing(ObjectPtr object) {
  const uword tags = TagsFromUntaggedObject(object.untag());
  const auto cid = UntaggedObject::ClassIdTag::decode(tags);
  // These use structural hash codes and will therefore always result in the
  // same hash codes.
  if (cid == kOneByteStringCid) return false;
  if (cid == kTwoByteStringCid) return false;
  if (cid == kExternalOneByteStringCid) return false;
  if (cid == kExternalTwoByteStringCid) return false;
  if (cid == kMintCid) return false;
  if (cid == kDoubleCid) return false;
  if (cid == kBoolCid) return false;
  if (cid == kSendPortCid) return false;
  if (cid == kCapabilityCid) return false;
  if (cid == kNullCid) return false;

  // These are shared and use identity hash codes. If they are used as a key in
  // a map or a value in a set, they will already have the identity hash code
  // set.
  if (cid == kRegExpCid) return false;
  if (cid == kInt32x4Cid) return false;

  // If the [tags] indicates this is a canonical object we'll share it instead
  // of copying it. That would suggest we don't have to re-hash maps/sets
  // containing this object on the receiver side.
  //
  // Though the object can be a constant of a user-defined class with a
  // custom hash code that is misbehaving (e.g one that depends on global field
  // state, ...). To be on the safe side we'll force re-hashing if such objects
  // are encountered in maps/sets.
  //
  // => We might want to consider changing the implementation to avoid rehashing
  // in such cases in the future and disambiguate the documentation.
  return true;
}

DART_FORCE_INLINE
uword TagsFromUntaggedObject(UntaggedObject* obj) {
  return obj->tags_;
}

DART_FORCE_INLINE
void SetNewSpaceTaggingWord(ObjectPtr to, classid_t cid, uint32_t size) {
  uword tags = 0;

  tags = UntaggedObject::SizeTag::update(size, tags);
  tags = UntaggedObject::ClassIdTag::update(cid, tags);
  tags = UntaggedObject::OldBit::update(false, tags);
  tags = UntaggedObject::OldAndNotMarkedBit::update(false, tags);
  tags = UntaggedObject::OldAndNotRememberedBit::update(false, tags);
  tags = UntaggedObject::CanonicalBit::update(false, tags);
  tags = UntaggedObject::NewBit::update(true, tags);
  tags = UntaggedObject::ImmutableBit::update(
      IsUnmodifiableTypedDataViewClassId(cid), tags);
#if defined(HASH_IN_OBJECT_HEADER)
  tags = UntaggedObject::HashTag::update(0, tags);
#endif
  to.untag()->tags_ = tags;
}

DART_FORCE_INLINE
ObjectPtr AllocateObject(intptr_t cid,
                         intptr_t size,
                         intptr_t allocated_bytes) {
#if defined(DART_COMPRESSED_POINTERS)
  const bool compressed = true;
#else
  const bool compressed = false;
#endif
  const intptr_t kLargeMessageThreshold = 16 * MB;
  const Heap::Space space =
      allocated_bytes > kLargeMessageThreshold ? Heap::kOld : Heap::kNew;
  return Object::Allocate(cid, size, space, compressed);
}

DART_FORCE_INLINE
void UpdateLengthField(intptr_t cid, ObjectPtr from, ObjectPtr to) {
  // We share these objects - never copy them.
  ASSERT(!IsStringClassId(cid));

  // We update any in-heap variable sized object with the length to keep the
  // length and the size in the object header in-sync for the GC.
  if (cid == kArrayCid || cid == kImmutableArrayCid) {
    static_cast<UntaggedArray*>(to.untag())->length_ =
        static_cast<UntaggedArray*>(from.untag())->length_;
  } else if (cid == kContextCid) {
    static_cast<UntaggedContext*>(to.untag())->num_variables_ =
        static_cast<UntaggedContext*>(from.untag())->num_variables_;
  } else if (IsTypedDataClassId(cid)) {
    static_cast<UntaggedTypedDataBase*>(to.untag())->length_ =
        static_cast<UntaggedTypedDataBase*>(from.untag())->length_;
  } else if (cid == kRecordCid) {
    static_cast<UntaggedRecord*>(to.untag())->shape_ =
        static_cast<UntaggedRecord*>(from.untag())->shape_;
  }
}

void InitializeExternalTypedData(intptr_t cid,
                                 ExternalTypedDataPtr from,
                                 ExternalTypedDataPtr to) {
  auto raw_from = from.untag();
  auto raw_to = to.untag();
  const intptr_t length =
      TypedData::ElementSizeInBytes(cid) * Smi::Value(raw_from->length_);

  auto buffer = static_cast<uint8_t*>(malloc(length));
  memmove(buffer, raw_from->data_, length);
  raw_to->length_ = raw_from->length_;
  raw_to->data_ = buffer;
}

template <typename T>
void CopyTypedDataBaseWithSafepointChecks(Thread* thread,
                                          const T& from,
                                          const T& to,
                                          intptr_t length) {
  constexpr intptr_t kChunkSize = 100 * 1024;

  const intptr_t chunks = length / kChunkSize;
  const intptr_t remainder = length % kChunkSize;

  // Notice we re-load the data pointer, since T may be TypedData in which case
  // the interior pointer may change after checking into safepoints.
  for (intptr_t i = 0; i < chunks; ++i) {
    memmove(to.ptr().untag()->data_ + i * kChunkSize,
            from.ptr().untag()->data_ + i * kChunkSize, kChunkSize);

    thread->CheckForSafepoint();
  }
  if (remainder > 0) {
    memmove(to.ptr().untag()->data_ + chunks * kChunkSize,
            from.ptr().untag()->data_ + chunks * kChunkSize, remainder);
  }
}

void InitializeExternalTypedDataWithSafepointChecks(
    Thread* thread,
    intptr_t cid,
    const ExternalTypedData& from,
    const ExternalTypedData& to) {
  const intptr_t length_in_elements = from.Length();
  const intptr_t length_in_bytes =
      TypedData::ElementSizeInBytes(cid) * length_in_elements;

  uint8_t* to_data = static_cast<uint8_t*>(malloc(length_in_bytes));
  to.ptr().untag()->data_ = to_data;
  to.ptr().untag()->length_ = Smi::New(length_in_elements);

  CopyTypedDataBaseWithSafepointChecks(thread, from, to, length_in_bytes);
}

void InitializeTypedDataView(TypedDataViewPtr obj) {
  obj.untag()->typed_data_ = TypedDataBase::null();
  obj.untag()->offset_in_bytes_ = Smi::New(0);
  obj.untag()->length_ = Smi::New(0);
}

void FreeExternalTypedData(void* isolate_callback_data, void* buffer) {
  free(buffer);
}

void FreeTransferablePeer(void* isolate_callback_data, void* peer) {
  delete static_cast<TransferableTypedDataPeer*>(peer);
}

class SlowFromTo {
 public:
  explicit SlowFromTo(const GrowableObjectArray& storage) : storage_(storage) {}

  ObjectPtr At(intptr_t index) { return storage_.At(index); }
  void Add(const Object& key, const Object& value) {
    storage_.Add(key);
    storage_.Add(value);
  }
  intptr_t Length() { return storage_.Length(); }

 private:
  const GrowableObjectArray& storage_;
};

class FastFromTo {
 public:
  explicit FastFromTo(GrowableArray<ObjectPtr>& storage) : storage_(storage) {}

  ObjectPtr At(intptr_t index) { return storage_.At(index); }
  void Add(ObjectPtr key, ObjectPtr value) {
    intptr_t i = storage_.length();
    storage_.Resize(i + 2);
    storage_[i + 0] = key;
    storage_[i + 1] = value;
  }
  intptr_t Length() { return storage_.length(); }

 private:
  GrowableArray<ObjectPtr>& storage_;
};

static ObjectPtr Ptr(ObjectPtr obj) {
  return obj;
}
static ObjectPtr Ptr(const Object& obj) {
  return obj.ptr();
}

#if defined(HASH_IN_OBJECT_HEADER)
class IdentityMap {
 public:
  explicit IdentityMap(Thread* thread) : thread_(thread) {
    hash_table_used_ = 0;
    hash_table_capacity_ = 32;
    hash_table_ = reinterpret_cast<uint32_t*>(
        malloc(hash_table_capacity_ * sizeof(uint32_t)));
    memset(hash_table_, 0, hash_table_capacity_ * sizeof(uint32_t));
  }
  ~IdentityMap() { free(hash_table_); }

  template <typename S, typename T>
  DART_FORCE_INLINE ObjectPtr ForwardedObject(const S& object, T from_to) {
    intptr_t mask = hash_table_capacity_ - 1;
    intptr_t probe = GetHeaderHash(Ptr(object)) & mask;
    for (;;) {
      intptr_t index = hash_table_[probe];
      if (index == 0) {
        return Marker();
      }
      if (from_to.At(index) == Ptr(object)) {
        return from_to.At(index + 1);
      }
      probe = (probe + 1) & mask;
    }
  }

  template <typename S, typename T>
  DART_FORCE_INLINE void Insert(const S& from,
                                const S& to,
                                T from_to,
                                bool check_for_safepoint) {
    ASSERT(ForwardedObject(from, from_to) == Marker());
    const auto id = from_to.Length();
    from_to.Add(from, to);  // Must occur before rehashing.
    intptr_t mask = hash_table_capacity_ - 1;
    intptr_t probe = GetHeaderHash(Ptr(from)) & mask;
    for (;;) {
      intptr_t index = hash_table_[probe];
      if (index == 0) {
        hash_table_[probe] = id;
        break;
      }
      probe = (probe + 1) & mask;
    }
    hash_table_used_++;
    if (hash_table_used_ * 2 > hash_table_capacity_) {
      Rehash(hash_table_capacity_ * 2, from_to, check_for_safepoint);
    }
  }

 private:
  DART_FORCE_INLINE
  uint32_t GetHeaderHash(ObjectPtr object) {
    uint32_t hash = Object::GetCachedHash(object);
    if (hash == 0) {
      switch (object->GetClassId()) {
        case kMintCid:
          hash = Mint::Value(static_cast<MintPtr>(object));
          // Don't write back: doesn't agree with dart:core's identityHash.
          break;
        case kDoubleCid:
          hash =
              bit_cast<uint64_t>(Double::Value(static_cast<DoublePtr>(object)));
          // Don't write back: doesn't agree with dart:core's identityHash.
          break;
        case kOneByteStringCid:
        case kTwoByteStringCid:
        case kExternalOneByteStringCid:
        case kExternalTwoByteStringCid:
          hash = String::Hash(static_cast<StringPtr>(object));
          hash = Object::SetCachedHashIfNotSet(object, hash);
          break;
        default:
          do {
            hash = thread_->random()->NextUInt32();
          } while (hash == 0 || !Smi::IsValid(hash));
          hash = Object::SetCachedHashIfNotSet(object, hash);
          break;
      }
    }
    return hash;
  }

  template <typename T>
  void Rehash(intptr_t new_capacity, T from_to, bool check_for_safepoint) {
    hash_table_capacity_ = new_capacity;
    hash_table_used_ = 0;
    free(hash_table_);
    hash_table_ = reinterpret_cast<uint32_t*>(
        malloc(hash_table_capacity_ * sizeof(uint32_t)));
    for (intptr_t i = 0; i < hash_table_capacity_; i++) {
      hash_table_[i] = 0;
      if (check_for_safepoint && (((i + 1) % KB) == 0)) {
        thread_->CheckForSafepoint();
      }
    }
    for (intptr_t id = 2; id < from_to.Length(); id += 2) {
      ObjectPtr obj = from_to.At(id);
      intptr_t mask = hash_table_capacity_ - 1;
      intptr_t probe = GetHeaderHash(obj) & mask;
      for (;;) {
        if (hash_table_[probe] == 0) {
          hash_table_[probe] = id;
          hash_table_used_++;
          break;
        }
        probe = (probe + 1) & mask;
      }
      if (check_for_safepoint && (((id + 2) % KB) == 0)) {
        thread_->CheckForSafepoint();
      }
    }
  }

  Thread* thread_;
  uint32_t* hash_table_;
  uint32_t hash_table_capacity_;
  uint32_t hash_table_used_;
};
#else   // defined(HASH_IN_OBJECT_HEADER)
class IdentityMap {
 public:
  explicit IdentityMap(Thread* thread) : isolate_(thread->isolate()) {
    isolate_->set_forward_table_new(new WeakTable());
    isolate_->set_forward_table_old(new WeakTable());
  }
  ~IdentityMap() {
    isolate_->set_forward_table_new(nullptr);
    isolate_->set_forward_table_old(nullptr);
  }

  template <typename S, typename T>
  DART_FORCE_INLINE ObjectPtr ForwardedObject(const S& object, T from_to) {
    const intptr_t id = GetObjectId(Ptr(object));
    if (id == 0) return Marker();
    return from_to.At(id + 1);
  }

  template <typename S, typename T>
  DART_FORCE_INLINE void Insert(const S& from,
                                const S& to,
                                T from_to,
                                bool check_for_safepoint) {
    ASSERT(ForwardedObject(from, from_to) == Marker());
    const auto id = from_to.Length();
    // May take >100ms and cannot yield to safepoints.
    SetObjectId(Ptr(from), id);
    from_to.Add(from, to);
  }

 private:
  DART_FORCE_INLINE
  intptr_t GetObjectId(ObjectPtr object) {
    if (object->IsNewObject()) {
      return isolate_->forward_table_new()->GetValueExclusive(object);
    } else {
      return isolate_->forward_table_old()->GetValueExclusive(object);
    }
  }

  DART_FORCE_INLINE
  void SetObjectId(ObjectPtr object, intptr_t id) {
    if (object->IsNewObject()) {
      isolate_->forward_table_new()->SetValueExclusive(object, id);
    } else {
      isolate_->forward_table_old()->SetValueExclusive(object, id);
    }
  }

  Isolate* isolate_;
};
#endif  // defined(HASH_IN_OBJECT_HEADER)

class ForwardMapBase {
 public:
  explicit ForwardMapBase(Thread* thread)
      : thread_(thread), zone_(thread->zone()) {}

 protected:
  friend class ObjectGraphCopier;

  void FinalizeTransferable(const TransferableTypedData& from,
                            const TransferableTypedData& to) {
    // Get the old peer.
    auto fpeer = static_cast<TransferableTypedDataPeer*>(
        thread_->heap()->GetPeer(from.ptr()));
    ASSERT(fpeer != nullptr && fpeer->data() != nullptr);
    const intptr_t length = fpeer->length();

    // Allocate new peer object with (data, length).
    auto tpeer = new TransferableTypedDataPeer(fpeer->data(), length);
    thread_->heap()->SetPeer(to.ptr(), tpeer);

    // Move the handle itself to the new object.
    fpeer->handle()->EnsureFreedExternal(thread_->isolate_group());
    FinalizablePersistentHandle* finalizable_ref =
        FinalizablePersistentHandle::New(thread_->isolate_group(), to, tpeer,
                                         FreeTransferablePeer, length,
                                         /*auto_delete=*/true);
    ASSERT(finalizable_ref != nullptr);
    tpeer->set_handle(finalizable_ref);
    fpeer->ClearData();
  }

  void FinalizeExternalTypedData(const ExternalTypedData& to) {
    to.AddFinalizer(to.DataAddr(0), &FreeExternalTypedData, to.LengthInBytes());
  }

  Thread* thread_;
  Zone* zone_;

 private:
  DISALLOW_COPY_AND_ASSIGN(ForwardMapBase);
};

class FastForwardMap : public ForwardMapBase {
 public:
  explicit FastForwardMap(Thread* thread, IdentityMap* map)
      : ForwardMapBase(thread),
        map_(map),
        raw_from_to_(thread->zone(), 20),
        raw_transferables_from_to_(thread->zone(), 0),
        raw_objects_to_rehash_(thread->zone(), 0),
        raw_expandos_to_rehash_(thread->zone(), 0) {
    raw_from_to_.Resize(2);
    raw_from_to_[0] = Object::null();
    raw_from_to_[1] = Object::null();
    fill_cursor_ = 2;
  }

  ObjectPtr ForwardedObject(ObjectPtr object) {
    return map_->ForwardedObject(object, FastFromTo(raw_from_to_));
  }

  void Insert(ObjectPtr from, ObjectPtr to, intptr_t size) {
    map_->Insert(from, to, FastFromTo(raw_from_to_),
                 /*check_for_safepoint*/ false);
    allocated_bytes += size;
  }

  void AddTransferable(TransferableTypedDataPtr from,
                       TransferableTypedDataPtr to) {
    raw_transferables_from_to_.Add(from);
    raw_transferables_from_to_.Add(to);
  }
  void AddWeakProperty(WeakPropertyPtr from) { raw_weak_properties_.Add(from); }
  void AddWeakReference(WeakReferencePtr from) {
    raw_weak_references_.Add(from);
  }
  void AddExternalTypedData(ExternalTypedDataPtr to) {
    raw_external_typed_data_to_.Add(to);
  }

  void AddObjectToRehash(ObjectPtr to) { raw_objects_to_rehash_.Add(to); }
  void AddExpandoToRehash(ObjectPtr to) { raw_expandos_to_rehash_.Add(to); }

 private:
  friend class FastObjectCopy;
  friend class ObjectGraphCopier;

  IdentityMap* map_;
  GrowableArray<ObjectPtr> raw_from_to_;
  GrowableArray<TransferableTypedDataPtr> raw_transferables_from_to_;
  GrowableArray<ExternalTypedDataPtr> raw_external_typed_data_to_;
  GrowableArray<ObjectPtr> raw_objects_to_rehash_;
  GrowableArray<ObjectPtr> raw_expandos_to_rehash_;
  GrowableArray<WeakPropertyPtr> raw_weak_properties_;
  GrowableArray<WeakReferencePtr> raw_weak_references_;
  intptr_t fill_cursor_ = 0;
  intptr_t allocated_bytes = 0;

  DISALLOW_COPY_AND_ASSIGN(FastForwardMap);
};

class SlowForwardMap : public ForwardMapBase {
 public:
  explicit SlowForwardMap(Thread* thread, IdentityMap* map)
      : ForwardMapBase(thread),
        map_(map),
        from_to_transition_(thread->zone(), 2),
        from_to_(GrowableObjectArray::Handle(thread->zone(),
                                             GrowableObjectArray::New(2))),
        transferables_from_to_(thread->zone(), 0) {
    from_to_transition_.Resize(2);
    from_to_transition_[0] = &PassiveObject::Handle();
    from_to_transition_[1] = &PassiveObject::Handle();
    from_to_.Add(Object::null_object());
    from_to_.Add(Object::null_object());
    fill_cursor_ = 2;
  }

  ObjectPtr ForwardedObject(ObjectPtr object) {
    return map_->ForwardedObject(object, SlowFromTo(from_to_));
  }
  void Insert(const Object& from, const Object& to, intptr_t size) {
    map_->Insert(from, to, SlowFromTo(from_to_),
                 /* check_for_safepoint */ true);
    allocated_bytes += size;
  }

  void AddTransferable(const TransferableTypedData& from,
                       const TransferableTypedData& to) {
    transferables_from_to_.Add(&TransferableTypedData::Handle(from.ptr()));
    transferables_from_to_.Add(&TransferableTypedData::Handle(to.ptr()));
  }
  void AddWeakProperty(const WeakProperty& from) {
    weak_properties_.Add(&WeakProperty::Handle(from.ptr()));
  }
  void AddWeakReference(const WeakReference& from) {
    weak_references_.Add(&WeakReference::Handle(from.ptr()));
  }
  const ExternalTypedData& AddExternalTypedData(ExternalTypedDataPtr to) {
    auto to_handle = &ExternalTypedData::Handle(to);
    external_typed_data_.Add(to_handle);
    return *to_handle;
  }
  void AddObjectToRehash(const Object& to) {
    objects_to_rehash_.Add(&Object::Handle(to.ptr()));
  }
  void AddExpandoToRehash(const Object& to) {
    expandos_to_rehash_.Add(&Object::Handle(to.ptr()));
  }

  void FinalizeTransferables() {
    for (intptr_t i = 0; i < transferables_from_to_.length(); i += 2) {
      auto from = transferables_from_to_[i];
      auto to = transferables_from_to_[i + 1];
      FinalizeTransferable(*from, *to);
    }
  }

  void FinalizeExternalTypedData() {
    for (intptr_t i = 0; i < external_typed_data_.length(); i++) {
      auto to = external_typed_data_[i];
      ForwardMapBase::FinalizeExternalTypedData(*to);
    }
  }

 private:
  friend class SlowObjectCopy;
  friend class SlowObjectCopyBase;
  friend class ObjectGraphCopier;

  IdentityMap* map_;
  GrowableArray<const PassiveObject*> from_to_transition_;
  GrowableObjectArray& from_to_;
  GrowableArray<const TransferableTypedData*> transferables_from_to_;
  GrowableArray<const ExternalTypedData*> external_typed_data_;
  GrowableArray<const Object*> objects_to_rehash_;
  GrowableArray<const Object*> expandos_to_rehash_;
  GrowableArray<const WeakProperty*> weak_properties_;
  GrowableArray<const WeakReference*> weak_references_;
  intptr_t fill_cursor_ = 0;
  intptr_t allocated_bytes = 0;

  DISALLOW_COPY_AND_ASSIGN(SlowForwardMap);
};

class ObjectCopyBase {
 public:
  explicit ObjectCopyBase(Thread* thread)
      : thread_(thread),
        heap_base_(thread->heap_base()),
        zone_(thread->zone()),
        heap_(thread->isolate_group()->heap()),
        class_table_(thread->isolate_group()->class_table()),
        new_space_(heap_->new_space()),
        tmp_(Object::Handle(thread->zone())),
        to_(Object::Handle(thread->zone())),
        expando_cid_(Class::GetClassId(
            thread->isolate_group()->object_store()->expando_class())),
        exception_unexpected_object_(Object::Handle(thread->zone())) {}
  ~ObjectCopyBase() {}

 protected:
  static ObjectPtr LoadPointer(ObjectPtr src, intptr_t offset) {
    return src.untag()->LoadPointer(reinterpret_cast<ObjectPtr*>(
        reinterpret_cast<uint8_t*>(src.untag()) + offset));
  }
  static CompressedObjectPtr LoadCompressedPointer(ObjectPtr src,
                                                   intptr_t offset) {
    return src.untag()->LoadPointer(reinterpret_cast<CompressedObjectPtr*>(
        reinterpret_cast<uint8_t*>(src.untag()) + offset));
  }
  static compressed_uword LoadCompressedNonPointerWord(ObjectPtr src,
                                                       intptr_t offset) {
    return *reinterpret_cast<compressed_uword*>(
        reinterpret_cast<uint8_t*>(src.untag()) + offset);
  }
  static void StorePointerBarrier(ObjectPtr obj,
                                  intptr_t offset,
                                  ObjectPtr value) {
    obj.untag()->StorePointer(
        reinterpret_cast<ObjectPtr*>(reinterpret_cast<uint8_t*>(obj.untag()) +
                                     offset),
        value);
  }
  static void StoreCompressedPointerBarrier(ObjectPtr obj,
                                            intptr_t offset,
                                            ObjectPtr value) {
    obj.untag()->StoreCompressedPointer(
        reinterpret_cast<CompressedObjectPtr*>(
            reinterpret_cast<uint8_t*>(obj.untag()) + offset),
        value);
  }
  void StoreCompressedLargeArrayPointerBarrier(ObjectPtr obj,
                                               intptr_t offset,
                                               ObjectPtr value) {
    obj.untag()->StoreCompressedArrayPointer(
        reinterpret_cast<CompressedObjectPtr*>(
            reinterpret_cast<uint8_t*>(obj.untag()) + offset),
        value, thread_);
  }
  static void StorePointerNoBarrier(ObjectPtr obj,
                                    intptr_t offset,
                                    ObjectPtr value) {
    *reinterpret_cast<ObjectPtr*>(reinterpret_cast<uint8_t*>(obj.untag()) +
                                  offset) = value;
  }
  template <typename T = ObjectPtr>
  static void StoreCompressedPointerNoBarrier(ObjectPtr obj,
                                              intptr_t offset,
                                              T value) {
    *reinterpret_cast<CompressedObjectPtr*>(
        reinterpret_cast<uint8_t*>(obj.untag()) + offset) = value;
  }
  static void StoreCompressedNonPointerWord(ObjectPtr obj,
                                            intptr_t offset,
                                            compressed_uword value) {
    *reinterpret_cast<compressed_uword*>(
        reinterpret_cast<uint8_t*>(obj.untag()) + offset) = value;
  }

  DART_FORCE_INLINE
  bool CanCopyObject(uword tags, ObjectPtr object) {
    const auto cid = UntaggedObject::ClassIdTag::decode(tags);
    if (Class::IsIsolateUnsendable(class_table_->At(cid))) {
      exception_msg_ = OS::SCreate(
          zone_,
          "Illegal argument in isolate message: object is unsendable - %s ("
          "see restrictions listed at `SendPort.send()` documentation "
          "for more information)",
          Class::Handle(class_table_->At(cid)).ToCString());
      exception_unexpected_object_ = object;
      return false;
    }
    if (cid > kNumPredefinedCids) {
      return true;
    }
#define HANDLE_ILLEGAL_CASE(Type)                                              \
  case k##Type##Cid: {                                                         \
    exception_msg_ =                                                           \
        "Illegal argument in isolate message: "                                \
        "(object is a " #Type ")";                                             \
    exception_unexpected_object_ = object;                                     \
    return false;                                                              \
  }

    switch (cid) {
      // From "dart:ffi" we handle only Pointer/DynamicLibrary specially, since
      // those are the only non-abstract classes (so we avoid checking more cids
      // here that cannot happen in reality)
      HANDLE_ILLEGAL_CASE(DynamicLibrary)
      HANDLE_ILLEGAL_CASE(Finalizer)
      HANDLE_ILLEGAL_CASE(NativeFinalizer)
      HANDLE_ILLEGAL_CASE(MirrorReference)
      HANDLE_ILLEGAL_CASE(Pointer)
      HANDLE_ILLEGAL_CASE(ReceivePort)
      HANDLE_ILLEGAL_CASE(SuspendState)
      HANDLE_ILLEGAL_CASE(UserTag)
      default:
        return true;
    }
  }

  Thread* thread_;
  uword heap_base_;
  Zone* zone_;
  Heap* heap_;
  ClassTable* class_table_;
  Scavenger* new_space_;
  Object& tmp_;
  Object& to_;
  intptr_t expando_cid_;

  const char* exception_msg_ = nullptr;
  Object& exception_unexpected_object_;
};

class RetainingPath {
  class Visitor : public ObjectPointerVisitor {
   public:
    Visitor(IsolateGroup* isolate_group,
            RetainingPath* retaining_path,
            MallocGrowableArray<ObjectPtr>* const working_list,
            TraversalRules traversal_rules)
        : ObjectPointerVisitor(isolate_group),
          retaining_path_(retaining_path),
          working_list_(working_list),
          traversal_rules_(traversal_rules) {}

    void VisitObject(ObjectPtr obj) {
      if (!obj->IsHeapObject()) {
        return;
      }
      // Skip canonical objects when rules are for messages internal to
      // an isolate group. Otherwise, need to inspect canonical objects
      // as well.
      if (traversal_rules_ == TraversalRules::kInternalToIsolateGroup &&
          obj->untag()->IsCanonical()) {
        return;
      }
      if (retaining_path_->WasVisited(obj)) {
        return;
      }
      retaining_path_->MarkVisited(obj);
      working_list_->Add(obj);
    }

    void VisitPointers(ObjectPtr* from, ObjectPtr* to) override {
      for (ObjectPtr* ptr = from; ptr <= to; ptr++) {
        VisitObject(*ptr);
      }
    }

#if defined(DART_COMPRESSED_POINTERS)
    void VisitCompressedPointers(uword heap_base,
                                 CompressedObjectPtr* from,
                                 CompressedObjectPtr* to) override {
      for (CompressedObjectPtr* ptr = from; ptr <= to; ptr++) {
        VisitObject(ptr->Decompress(heap_base));
      }
    }
#endif

    RetainingPath* retaining_path_;
    MallocGrowableArray<ObjectPtr>* const working_list_;
    TraversalRules traversal_rules_;
  };

 public:
  RetainingPath(Zone* zone,
                Isolate* isolate,
                const Object& from,
                const Object& to,
                TraversalRules traversal_rules)
      : zone_(zone),
        isolate_(isolate),
        from_(from),
        to_(to),
        traversal_rules_(traversal_rules) {
    isolate_->set_forward_table_new(new WeakTable());
    isolate_->set_forward_table_old(new WeakTable());
  }

  ~RetainingPath() {
    isolate_->set_forward_table_new(nullptr);
    isolate_->set_forward_table_old(nullptr);
  }

  bool WasVisited(ObjectPtr object) {
    if (object->IsNewObject()) {
      return isolate_->forward_table_new()->GetValueExclusive(object) != 0;
    } else {
      return isolate_->forward_table_old()->GetValueExclusive(object) != 0;
    }
  }

  void MarkVisited(ObjectPtr object) {
    if (object->IsNewObject()) {
      isolate_->forward_table_new()->SetValueExclusive(object, 1);
    } else {
      isolate_->forward_table_old()->SetValueExclusive(object, 1);
    }
  }

  const char* FindPath() {
    MallocGrowableArray<ObjectPtr>* const working_list =
        isolate_->pointers_to_verify_at_exit();
    ASSERT(working_list->length() == 0);

    Visitor visitor(isolate_->group(), this, working_list, traversal_rules_);

    MarkVisited(from_.ptr());
    working_list->Add(from_.ptr());

    Thread* thread = Thread::Current();
    ClassTable* class_table = isolate_->group()->class_table();
    Closure& closure = Closure::Handle(zone_);
    Array& array = Array::Handle(zone_);
    Class& klass = Class::Handle(zone_);

    while (!working_list->is_empty()) {
      thread->CheckForSafepoint();

      // Keep node in the list, separated by null value so that
      // if we are to add children, children can find it in case
      // they are on retaining path.
      ObjectPtr raw = working_list->Last();
      if (raw == Object::null()) {
        // If all children of a node were processed, then skip the separator,
        working_list->RemoveLast();
        // then skip the parent since it has already been processed too.
        working_list->RemoveLast();
        continue;
      }

      if (raw == to_.ptr()) {
        return CollectPath(working_list);
      }

      // Separator null object indicates children goes next in the working_list
      working_list->Add(Object::null());
      int length = working_list->length();

      do {  // This loop is here so that we can skip children processing
        const intptr_t cid = raw->GetClassId();

        if (traversal_rules_ == TraversalRules::kInternalToIsolateGroup) {
          if (CanShareObjectAcrossIsolates(raw)) {
            break;
          }
          if (cid == kClosureCid) {
            closure ^= raw;
            // Only context has to be checked.
            working_list->Add(closure.context());
            break;
          }
          // These we are not expected to drill into as they can't be on
          // retaining path, they are illegal to send.
          klass = class_table->At(cid);
          if (klass.is_isolate_unsendable()) {
            break;
          }
        } else {
          ASSERT(traversal_rules_ ==
                 TraversalRules::kExternalBetweenIsolateGroups);
          // Skip classes that are illegal to send across isolate groups.
          // (keep the list in sync with message_snapshot.cc)
          bool skip = false;
          switch (cid) {
            case kClosureCid:
            case kFinalizerCid:
            case kFinalizerEntryCid:
            case kFunctionTypeCid:
            case kMirrorReferenceCid:
            case kNativeFinalizerCid:
            case kReceivePortCid:
            case kRecordCid:
            case kRecordTypeCid:
            case kRegExpCid:
            case kStackTraceCid:
            case kSuspendStateCid:
            case kUserTagCid:
            case kWeakPropertyCid:
            case kWeakReferenceCid:
            case kWeakArrayCid:
            case kDynamicLibraryCid:
            case kPointerCid:
            case kInstanceCid:
              skip = true;
              break;
            default:
              if (cid >= kNumPredefinedCids) {
                skip = true;
              }
          }
          if (skip) {
            break;
          }
        }
        if (cid == kArrayCid) {
          array ^= Array::RawCast(raw);
          visitor.VisitObject(array.GetTypeArguments());
          const intptr_t batch_size = (2 << 14) - 1;
          for (intptr_t i = 0; i < array.Length(); ++i) {
            ObjectPtr ptr = array.At(i);
            visitor.VisitObject(ptr);
            if ((i & batch_size) == batch_size) {
              thread->CheckForSafepoint();
            }
          }
          break;
        } else {
          raw->untag()->VisitPointers(&visitor);
        }
      } while (false);

      // If no children were added, remove null separator and the node.
      // If children were added, the node will be removed once last child
      // is processed, only separator null remains.
      if (working_list->length() == length) {
        RELEASE_ASSERT(working_list->RemoveLast() == Object::null());
        RELEASE_ASSERT(working_list->RemoveLast() == raw);
      }
    }
    // `to` was not found in the graph rooted in `from`, empty retaining path
    return "";
  }

 private:
  Zone* zone_;
  Isolate* isolate_;
  const Object& from_;
  const Object& to_;
  TraversalRules traversal_rules_;

  const char* CollectPath(MallocGrowableArray<ObjectPtr>* const working_list) {
    Object& object = Object::Handle(zone_);
    Class& klass = Class::Handle(zone_);
    Library& library = Library::Handle(zone_);
    String& library_url = String::Handle(zone_);
    const char* retaining_path = "";

    ObjectPtr raw = to_.ptr();
    // Skip all remaining children until null-separator, so we get the parent
    do {
      do {
        raw = working_list->RemoveLast();
      } while (raw != Object::null() && raw != from_.ptr());
      if (raw == Object::null()) {
        raw = working_list->RemoveLast();
        object = raw;
        klass = object.clazz();
        library = klass.library();
        if (library.IsNull()) {
          retaining_path = OS::SCreate(zone_, "%s <- %s\n", retaining_path,
                                       object.ToCString());
        } else {
          library_url = library.url();
          retaining_path =
              OS::SCreate(zone_, "%s <- %s (from %s)\n", retaining_path,
                          object.ToCString(), library_url.ToCString());
        }
      }
    } while (raw != from_.ptr());
    ASSERT(working_list->is_empty());
    return retaining_path;
  }
};

const char* FindRetainingPath(Zone* zone_,
                              Isolate* isolate,
                              const Object& from,
                              const Object& to,
                              TraversalRules traversal_rules) {
  RetainingPath rr(zone_, isolate, from, to, traversal_rules);
  return rr.FindPath();
}

class FastObjectCopyBase : public ObjectCopyBase {
 public:
  using Types = PtrTypes;

  FastObjectCopyBase(Thread* thread, IdentityMap* map)
      : ObjectCopyBase(thread), fast_forward_map_(thread, map) {}

 protected:
  DART_FORCE_INLINE
  void ForwardCompressedPointers(ObjectPtr src,
                                 ObjectPtr dst,
                                 intptr_t offset,
                                 intptr_t end_offset) {
    for (; offset < end_offset; offset += kCompressedWordSize) {
      ForwardCompressedPointer(src, dst, offset);
    }
  }

  DART_FORCE_INLINE
  void ForwardCompressedPointers(ObjectPtr src,
                                 ObjectPtr dst,
                                 intptr_t offset,
                                 intptr_t end_offset,
                                 UnboxedFieldBitmap bitmap) {
    if (bitmap.IsEmpty()) {
      ForwardCompressedPointers(src, dst, offset, end_offset);
      return;
    }
    intptr_t bit = offset >> kCompressedWordSizeLog2;
    for (; offset < end_offset; offset += kCompressedWordSize) {
      if (bitmap.Get(bit++)) {
        StoreCompressedNonPointerWord(
            dst, offset, LoadCompressedNonPointerWord(src, offset));
      } else {
        ForwardCompressedPointer(src, dst, offset);
      }
    }
  }

  void ForwardCompressedArrayPointers(intptr_t array_length,
                                      ObjectPtr src,
                                      ObjectPtr dst,
                                      intptr_t offset,
                                      intptr_t end_offset) {
    for (; offset < end_offset; offset += kCompressedWordSize) {
      ForwardCompressedPointer(src, dst, offset);
    }
  }

  void ForwardCompressedContextPointers(intptr_t context_length,
                                        ObjectPtr src,
                                        ObjectPtr dst,
                                        intptr_t offset,
                                        intptr_t end_offset) {
    for (; offset < end_offset; offset += kCompressedWordSize) {
      ForwardCompressedPointer(src, dst, offset);
    }
  }

  DART_FORCE_INLINE
  void ForwardCompressedPointer(ObjectPtr src, ObjectPtr dst, intptr_t offset) {
    auto value = LoadCompressedPointer(src, offset);
    if (!value.IsHeapObject()) {
      StoreCompressedPointerNoBarrier(dst, offset, value);
      return;
    }
    auto value_decompressed = value.Decompress(heap_base_);
    const uword tags = TagsFromUntaggedObject(value_decompressed.untag());
    if (CanShareObject(value_decompressed, tags)) {
      StoreCompressedPointerNoBarrier(dst, offset, value);
      return;
    }

    ObjectPtr existing_to =
        fast_forward_map_.ForwardedObject(value_decompressed);
    if (existing_to != Marker()) {
      StoreCompressedPointerNoBarrier(dst, offset, existing_to);
      return;
    }

    if (UNLIKELY(!CanCopyObject(tags, value_decompressed))) {
      ASSERT(exception_msg_ != nullptr);
      StoreCompressedPointerNoBarrier(dst, offset, Object::null());
      return;
    }

    auto to = Forward(tags, value_decompressed);
    StoreCompressedPointerNoBarrier(dst, offset, to);
  }

  ObjectPtr Forward(uword tags, ObjectPtr from) {
    const intptr_t header_size = UntaggedObject::SizeTag::decode(tags);
    const auto cid = UntaggedObject::ClassIdTag::decode(tags);
    const uword size =
        header_size != 0 ? header_size : from.untag()->HeapSize();
    if (Heap::IsAllocatableInNewSpace(size)) {
      const uword alloc = new_space_->TryAllocateNoSafepoint(thread_, size);
      if (alloc != 0) {
        ObjectPtr to(reinterpret_cast<UntaggedObject*>(alloc));
        fast_forward_map_.Insert(from, to, size);

        if (IsExternalTypedDataClassId(cid)) {
          SetNewSpaceTaggingWord(to, cid, header_size);
          InitializeExternalTypedData(cid, ExternalTypedData::RawCast(from),
                                      ExternalTypedData::RawCast(to));
          fast_forward_map_.AddExternalTypedData(
              ExternalTypedData::RawCast(to));
        } else if (IsTypedDataViewClassId(cid) ||
                   IsUnmodifiableTypedDataViewClassId(cid)) {
          // We set the views backing store to `null` to satisfy an assertion in
          // GCCompactor::VisitTypedDataViewPointers().
          SetNewSpaceTaggingWord(to, cid, header_size);
          InitializeTypedDataView(TypedDataView::RawCast(to));
        }
        return to;
      }
    }
    exception_msg_ = kFastAllocationFailed;
    return Marker();
  }

  void EnqueueTransferable(TransferableTypedDataPtr from,
                           TransferableTypedDataPtr to) {
    fast_forward_map_.AddTransferable(from, to);
  }
  void EnqueueWeakProperty(WeakPropertyPtr from) {
    fast_forward_map_.AddWeakProperty(from);
  }
  void EnqueueWeakReference(WeakReferencePtr from) {
    fast_forward_map_.AddWeakReference(from);
  }
  void EnqueueObjectToRehash(ObjectPtr to) {
    fast_forward_map_.AddObjectToRehash(to);
  }
  void EnqueueExpandoToRehash(ObjectPtr to) {
    fast_forward_map_.AddExpandoToRehash(to);
  }

  static void StoreCompressedArrayPointers(intptr_t array_length,
                                           ObjectPtr src,
                                           ObjectPtr dst,
                                           intptr_t offset,
                                           intptr_t end_offset) {
    StoreCompressedPointers(src, dst, offset, end_offset);
  }
  static void StoreCompressedPointers(ObjectPtr src,
                                      ObjectPtr dst,
                                      intptr_t offset,
                                      intptr_t end_offset) {
    StoreCompressedPointersNoBarrier(src, dst, offset, end_offset);
  }
  static void StoreCompressedPointersNoBarrier(ObjectPtr src,
                                               ObjectPtr dst,
                                               intptr_t offset,
                                               intptr_t end_offset) {
    for (; offset <= end_offset; offset += kCompressedWordSize) {
      StoreCompressedPointerNoBarrier(dst, offset,
                                      LoadCompressedPointer(src, offset));
    }
  }

 protected:
  friend class ObjectGraphCopier;

  FastForwardMap fast_forward_map_;
};

class SlowObjectCopyBase : public ObjectCopyBase {
 public:
  using Types = HandleTypes;

  explicit SlowObjectCopyBase(Thread* thread, IdentityMap* map)
      : ObjectCopyBase(thread), slow_forward_map_(thread, map) {}

 protected:
  DART_FORCE_INLINE
  void ForwardCompressedPointers(const Object& src,
                                 const Object& dst,
                                 intptr_t offset,
                                 intptr_t end_offset) {
    for (; offset < end_offset; offset += kCompressedWordSize) {
      ForwardCompressedPointer(src, dst, offset);
    }
  }

  DART_FORCE_INLINE
  void ForwardCompressedPointers(const Object& src,
                                 const Object& dst,
                                 intptr_t offset,
                                 intptr_t end_offset,
                                 UnboxedFieldBitmap bitmap) {
    intptr_t bit = offset >> kCompressedWordSizeLog2;
    for (; offset < end_offset; offset += kCompressedWordSize) {
      if (bitmap.Get(bit++)) {
        StoreCompressedNonPointerWord(
            dst.ptr(), offset, LoadCompressedNonPointerWord(src.ptr(), offset));
      } else {
        ForwardCompressedPointer(src, dst, offset);
      }
    }
  }

  void ForwardCompressedArrayPointers(intptr_t array_length,
                                      const Object& src,
                                      const Object& dst,
                                      intptr_t offset,
                                      intptr_t end_offset) {
    if (Array::UseCardMarkingForAllocation(array_length)) {
      for (; offset < end_offset; offset += kCompressedWordSize) {
        ForwardCompressedLargeArrayPointer(src, dst, offset);
        thread_->CheckForSafepoint();
      }
    } else {
      for (; offset < end_offset; offset += kCompressedWordSize) {
        ForwardCompressedPointer(src, dst, offset);
      }
    }
  }

  void ForwardCompressedContextPointers(intptr_t context_length,
                                        const Object& src,
                                        const Object& dst,
                                        intptr_t offset,
                                        intptr_t end_offset) {
    for (; offset < end_offset; offset += kCompressedWordSize) {
      ForwardCompressedPointer(src, dst, offset);
    }
  }

  DART_FORCE_INLINE
  void ForwardCompressedLargeArrayPointer(const Object& src,
                                          const Object& dst,
                                          intptr_t offset) {
    auto value = LoadCompressedPointer(src.ptr(), offset);
    if (!value.IsHeapObject()) {
      StoreCompressedPointerNoBarrier(dst.ptr(), offset, value);
      return;
    }

    auto value_decompressed = value.Decompress(heap_base_);
    const uword tags = TagsFromUntaggedObject(value_decompressed.untag());
    if (CanShareObject(value_decompressed, tags)) {
      StoreCompressedLargeArrayPointerBarrier(dst.ptr(), offset,
                                              value_decompressed);
      return;
    }

    ObjectPtr existing_to =
        slow_forward_map_.ForwardedObject(value_decompressed);
    if (existing_to != Marker()) {
      StoreCompressedLargeArrayPointerBarrier(dst.ptr(), offset, existing_to);
      return;
    }

    if (UNLIKELY(!CanCopyObject(tags, value_decompressed))) {
      ASSERT(exception_msg_ != nullptr);
      StoreCompressedLargeArrayPointerBarrier(dst.ptr(), offset,
                                              Object::null());
      return;
    }

    tmp_ = value_decompressed;
    tmp_ = Forward(tags, tmp_);  // Only this can cause allocation.
    StoreCompressedLargeArrayPointerBarrier(dst.ptr(), offset, tmp_.ptr());
  }
  DART_FORCE_INLINE
  void ForwardCompressedPointer(const Object& src,
                                const Object& dst,
                                intptr_t offset) {
    auto value = LoadCompressedPointer(src.ptr(), offset);
    if (!value.IsHeapObject()) {
      StoreCompressedPointerNoBarrier(dst.ptr(), offset, value);
      return;
    }
    auto value_decompressed = value.Decompress(heap_base_);
    const uword tags = TagsFromUntaggedObject(value_decompressed.untag());
    if (CanShareObject(value_decompressed, tags)) {
      StoreCompressedPointerBarrier(dst.ptr(), offset, value_decompressed);
      return;
    }

    ObjectPtr existing_to =
        slow_forward_map_.ForwardedObject(value_decompressed);
    if (existing_to != Marker()) {
      StoreCompressedPointerBarrier(dst.ptr(), offset, existing_to);
      return;
    }

    if (UNLIKELY(!CanCopyObject(tags, value_decompressed))) {
      ASSERT(exception_msg_ != nullptr);
      StoreCompressedPointerNoBarrier(dst.ptr(), offset, Object::null());
      return;
    }

    tmp_ = value_decompressed;
    tmp_ = Forward(tags, tmp_);  // Only this can cause allocation.
    StoreCompressedPointerBarrier(dst.ptr(), offset, tmp_.ptr());
  }

  ObjectPtr Forward(uword tags, const Object& from) {
    const intptr_t cid = UntaggedObject::ClassIdTag::decode(tags);
    intptr_t size = UntaggedObject::SizeTag::decode(tags);
    if (size == 0) {
      size = from.ptr().untag()->HeapSize();
    }
    to_ = AllocateObject(cid, size, slow_forward_map_.allocated_bytes);
    UpdateLengthField(cid, from.ptr(), to_.ptr());
    slow_forward_map_.Insert(from, to_, size);
    ObjectPtr to = to_.ptr();
    if ((cid == kArrayCid || cid == kImmutableArrayCid) &&
        !Heap::IsAllocatableInNewSpace(size)) {
      to.untag()->SetCardRememberedBitUnsynchronized();
    }
    if (IsExternalTypedDataClassId(cid)) {
      const auto& external_to = slow_forward_map_.AddExternalTypedData(
          ExternalTypedData::RawCast(to));
      InitializeExternalTypedDataWithSafepointChecks(
          thread_, cid, ExternalTypedData::Cast(from), external_to);
      return external_to.ptr();
    } else if (IsTypedDataViewClassId(cid) ||
               IsUnmodifiableTypedDataViewClassId(cid)) {
      // We set the views backing store to `null` to satisfy an assertion in
      // GCCompactor::VisitTypedDataViewPointers().
      InitializeTypedDataView(TypedDataView::RawCast(to));
    }
    return to;
  }
  void EnqueueTransferable(const TransferableTypedData& from,
                           const TransferableTypedData& to) {
    slow_forward_map_.AddTransferable(from, to);
  }
  void EnqueueWeakProperty(const WeakProperty& from) {
    slow_forward_map_.AddWeakProperty(from);
  }
  void EnqueueWeakReference(const WeakReference& from) {
    slow_forward_map_.AddWeakReference(from);
  }
  void EnqueueObjectToRehash(const Object& to) {
    slow_forward_map_.AddObjectToRehash(to);
  }
  void EnqueueExpandoToRehash(const Object& to) {
    slow_forward_map_.AddExpandoToRehash(to);
  }

  void StoreCompressedArrayPointers(intptr_t array_length,
                                    const Object& src,
                                    const Object& dst,
                                    intptr_t offset,
                                    intptr_t end_offset) {
    auto src_ptr = src.ptr();
    auto dst_ptr = dst.ptr();
    if (Array::UseCardMarkingForAllocation(array_length)) {
      for (; offset <= end_offset; offset += kCompressedWordSize) {
        StoreCompressedLargeArrayPointerBarrier(
            dst_ptr, offset,
            LoadCompressedPointer(src_ptr, offset).Decompress(heap_base_));
      }
    } else {
      for (; offset <= end_offset; offset += kCompressedWordSize) {
        StoreCompressedPointerBarrier(
            dst_ptr, offset,
            LoadCompressedPointer(src_ptr, offset).Decompress(heap_base_));
      }
    }
  }
  void StoreCompressedPointers(const Object& src,
                               const Object& dst,
                               intptr_t offset,
                               intptr_t end_offset) {
    auto src_ptr = src.ptr();
    auto dst_ptr = dst.ptr();
    for (; offset <= end_offset; offset += kCompressedWordSize) {
      StoreCompressedPointerBarrier(
          dst_ptr, offset,
          LoadCompressedPointer(src_ptr, offset).Decompress(heap_base_));
    }
  }
  static void StoreCompressedPointersNoBarrier(const Object& src,
                                               const Object& dst,
                                               intptr_t offset,
                                               intptr_t end_offset) {
    auto src_ptr = src.ptr();
    auto dst_ptr = dst.ptr();
    for (; offset <= end_offset; offset += kCompressedWordSize) {
      StoreCompressedPointerNoBarrier(dst_ptr, offset,
                                      LoadCompressedPointer(src_ptr, offset));
    }
  }

 protected:
  friend class ObjectGraphCopier;

  SlowForwardMap slow_forward_map_;
};

template <typename Base>
class ObjectCopy : public Base {
 public:
  using Types = typename Base::Types;

  ObjectCopy(Thread* thread, IdentityMap* map) : Base(thread, map) {}

  void CopyPredefinedInstance(typename Types::Object from,
                              typename Types::Object to,
                              intptr_t cid) {
    if (IsImplicitFieldClassId(cid)) {
      CopyUserdefinedInstanceWithoutUnboxedFields(from, to);
      return;
    }
    switch (cid) {
#define COPY_TO(clazz)                                                         \
  case clazz::kClassId: {                                                      \
    typename Types::clazz casted_from = Types::Cast##clazz(from);              \
    typename Types::clazz casted_to = Types::Cast##clazz(to);                  \
    Copy##clazz(casted_from, casted_to);                                       \
    return;                                                                    \
  }

      CLASS_LIST_NO_OBJECT_NOR_STRING_NOR_ARRAY_NOR_MAP(COPY_TO)
      COPY_TO(Array)
      COPY_TO(GrowableObjectArray)
      COPY_TO(Map)
      COPY_TO(Set)
#undef COPY_TO

      case ImmutableArray::kClassId: {
        typename Types::Array casted_from = Types::CastArray(from);
        typename Types::Array casted_to = Types::CastArray(to);
        CopyArray(casted_from, casted_to);
        return;
      }

#define COPY_TO(clazz) case kTypedData##clazz##Cid:

      CLASS_LIST_TYPED_DATA(COPY_TO) {
        typename Types::TypedData casted_from = Types::CastTypedData(from);
        typename Types::TypedData casted_to = Types::CastTypedData(to);
        CopyTypedData(casted_from, casted_to);
        return;
      }
#undef COPY_TO

      case kByteDataViewCid:
      case kUnmodifiableByteDataViewCid:
#define COPY_TO(clazz)                                                         \
  case kTypedData##clazz##ViewCid:                                             \
  case kUnmodifiableTypedData##clazz##ViewCid:
        CLASS_LIST_TYPED_DATA(COPY_TO) {
          typename Types::TypedDataView casted_from =
              Types::CastTypedDataView(from);
          typename Types::TypedDataView casted_to =
              Types::CastTypedDataView(to);
          CopyTypedDataView(casted_from, casted_to);
          return;
        }
#undef COPY_TO

#define COPY_TO(clazz) case kExternalTypedData##clazz##Cid:

        CLASS_LIST_TYPED_DATA(COPY_TO) {
          typename Types::ExternalTypedData casted_from =
              Types::CastExternalTypedData(from);
          typename Types::ExternalTypedData casted_to =
              Types::CastExternalTypedData(to);
          CopyExternalTypedData(casted_from, casted_to);
          return;
        }
#undef COPY_TO
      default:
        break;
    }

    const Object& obj = Types::HandlifyObject(from);
    FATAL("Unexpected object: %s\n", obj.ToCString());
  }

  void CopyUserdefinedInstance(typename Types::Object from,
                               typename Types::Object to,
                               UnboxedFieldBitmap bitmap) {
    const intptr_t instance_size = UntagObject(from)->HeapSize();
    Base::ForwardCompressedPointers(from, to, kWordSize, instance_size, bitmap);
  }

  void CopyUserdefinedInstanceWithoutUnboxedFields(typename Types::Object from,
                                                   typename Types::Object to) {
    const intptr_t instance_size = UntagObject(from)->HeapSize();
    Base::ForwardCompressedPointers(from, to, kWordSize, instance_size);
  }
  void CopyClosure(typename Types::Closure from, typename Types::Closure to) {
    Base::StoreCompressedPointers(
        from, to, OFFSET_OF(UntaggedClosure, instantiator_type_arguments_),
        OFFSET_OF(UntaggedClosure, function_));
    Base::ForwardCompressedPointer(from, to,
                                   OFFSET_OF(UntaggedClosure, context_));
    Base::StoreCompressedPointersNoBarrier(from, to,
                                           OFFSET_OF(UntaggedClosure, hash_),
                                           OFFSET_OF(UntaggedClosure, hash_));
    ONLY_IN_PRECOMPILED(UntagClosure(to)->entry_point_ =
                            UntagClosure(from)->entry_point_);
  }

  void CopyContext(typename Types::Context from, typename Types::Context to) {
    const intptr_t length = Context::NumVariables(Types::GetContextPtr(from));

    UntagContext(to)->num_variables_ = UntagContext(from)->num_variables_;

    Base::ForwardCompressedPointer(from, to,
                                   OFFSET_OF(UntaggedContext, parent_));
    Base::ForwardCompressedContextPointers(
        length, from, to, Context::variable_offset(0),
        Context::variable_offset(0) + Context::kBytesPerElement * length);
  }

  void CopyArray(typename Types::Array from, typename Types::Array to) {
    const intptr_t length = Smi::Value(UntagArray(from)->length());
    Base::StoreCompressedArrayPointers(
        length, from, to, OFFSET_OF(UntaggedArray, type_arguments_),
        OFFSET_OF(UntaggedArray, type_arguments_));
    Base::StoreCompressedPointersNoBarrier(from, to,
                                           OFFSET_OF(UntaggedArray, length_),
                                           OFFSET_OF(UntaggedArray, length_));
    Base::ForwardCompressedArrayPointers(
        length, from, to, Array::data_offset(),
        Array::data_offset() + kCompressedWordSize * length);
  }

  void CopyGrowableObjectArray(typename Types::GrowableObjectArray from,
                               typename Types::GrowableObjectArray to) {
    Base::StoreCompressedPointers(
        from, to, OFFSET_OF(UntaggedGrowableObjectArray, type_arguments_),
        OFFSET_OF(UntaggedGrowableObjectArray, type_arguments_));
    Base::StoreCompressedPointersNoBarrier(
        from, to, OFFSET_OF(UntaggedGrowableObjectArray, length_),
        OFFSET_OF(UntaggedGrowableObjectArray, length_));
    Base::ForwardCompressedPointer(
        from, to, OFFSET_OF(UntaggedGrowableObjectArray, data_));
  }

  void CopyRecord(typename Types::Record from, typename Types::Record to) {
    const intptr_t num_fields = Record::NumFields(Types::GetRecordPtr(from));
    Base::StoreCompressedPointersNoBarrier(from, to,
                                           OFFSET_OF(UntaggedRecord, shape_),
                                           OFFSET_OF(UntaggedRecord, shape_));
    Base::ForwardCompressedPointers(
        from, to, Record::field_offset(0),
        Record::field_offset(0) + Record::kBytesPerElement * num_fields);
  }

  template <intptr_t one_for_set_two_for_map, typename T>
  void CopyLinkedHashBase(T from,
                          T to,
                          UntaggedLinkedHashBase* from_untagged,
                          UntaggedLinkedHashBase* to_untagged) {
    // We have to find out whether the map needs re-hashing on the receiver side
    // due to keys being copied and the keys therefore possibly having different
    // hash codes (e.g. due to user-defined hashCode implementation or due to
    // new identity hash codes of the copied objects).
    bool needs_rehashing = false;
    ArrayPtr data = from_untagged->data_.Decompress(Base::heap_base_);
    if (data != Array::null()) {
      UntaggedArray* untagged_data = data.untag();
      const intptr_t length = Smi::Value(untagged_data->length_);
      auto key_value_pairs = untagged_data->data();
      for (intptr_t i = 0; i < length; i += one_for_set_two_for_map) {
        ObjectPtr key = key_value_pairs[i].Decompress(Base::heap_base_);
        const bool is_deleted_entry = key == data;
        if (key->IsHeapObject()) {
          if (!is_deleted_entry && MightNeedReHashing(key)) {
            needs_rehashing = true;
            break;
          }
        }
      }
    }

    Base::StoreCompressedPointers(
        from, to, OFFSET_OF(UntaggedLinkedHashBase, type_arguments_),
        OFFSET_OF(UntaggedLinkedHashBase, type_arguments_));

    // Compared with the snapshot-based (de)serializer we do preserve the same
    // backing store (i.e. used_data/deleted_keys/data) and therefore do not
    // magically shrink backing store based on usage.
    //
    // We do this to avoid making assumptions about the object graph and the
    // linked hash map (e.g. assuming there's no other references to the data,
    // assuming the linked hashmap is in a consistent state)
    if (needs_rehashing) {
      to_untagged->hash_mask_ = Smi::New(0);
      to_untagged->index_ = TypedData::RawCast(Object::null());
      to_untagged->deleted_keys_ = Smi::New(0);
    }

    // From this point on we shouldn't use the raw pointers, since GC might
    // happen when forwarding objects.
    from_untagged = nullptr;
    to_untagged = nullptr;

    if (!needs_rehashing) {
      Base::ForwardCompressedPointer(from, to,
                                     OFFSET_OF(UntaggedLinkedHashBase, index_));
      Base::StoreCompressedPointersNoBarrier(
          from, to, OFFSET_OF(UntaggedLinkedHashBase, hash_mask_),
          OFFSET_OF(UntaggedLinkedHashBase, hash_mask_));
      Base::StoreCompressedPointersNoBarrier(
          from, to, OFFSET_OF(UntaggedMap, deleted_keys_),
          OFFSET_OF(UntaggedMap, deleted_keys_));
    }
    Base::ForwardCompressedPointer(from, to,
                                   OFFSET_OF(UntaggedLinkedHashBase, data_));
    Base::StoreCompressedPointersNoBarrier(
        from, to, OFFSET_OF(UntaggedLinkedHashBase, used_data_),
        OFFSET_OF(UntaggedLinkedHashBase, used_data_));

    if (Base::exception_msg_ == nullptr && needs_rehashing) {
      Base::EnqueueObjectToRehash(to);
    }
  }

  void CopyMap(typename Types::Map from, typename Types::Map to) {
    CopyLinkedHashBase<2, typename Types::Map>(from, to, UntagMap(from),
                                               UntagMap(to));
  }

  void CopySet(typename Types::Set from, typename Types::Set to) {
    CopyLinkedHashBase<1, typename Types::Set>(from, to, UntagSet(from),
                                               UntagSet(to));
  }

  void CopyDouble(typename Types::Double from, typename Types::Double to) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    auto raw_from = UntagDouble(from);
    auto raw_to = UntagDouble(to);
    raw_to->value_ = raw_from->value_;
#else
    // Will be shared and not copied.
    UNREACHABLE();
#endif
  }

  void CopyFloat32x4(typename Types::Float32x4 from,
                     typename Types::Float32x4 to) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    auto raw_from = UntagFloat32x4(from);
    auto raw_to = UntagFloat32x4(to);
    raw_to->value_[0] = raw_from->value_[0];
    raw_to->value_[1] = raw_from->value_[1];
    raw_to->value_[2] = raw_from->value_[2];
    raw_to->value_[3] = raw_from->value_[3];
#else
    // Will be shared and not copied.
    UNREACHABLE();
#endif
  }

  void CopyFloat64x2(typename Types::Float64x2 from,
                     typename Types::Float64x2 to) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    auto raw_from = UntagFloat64x2(from);
    auto raw_to = UntagFloat64x2(to);
    raw_to->value_[0] = raw_from->value_[0];
    raw_to->value_[1] = raw_from->value_[1];
#else
    // Will be shared and not copied.
    UNREACHABLE();
#endif
  }

  void CopyTypedData(TypedDataPtr from, TypedDataPtr to) {
    auto raw_from = from.untag();
    auto raw_to = to.untag();
    const intptr_t cid = Types::GetTypedDataPtr(from)->GetClassId();
    raw_to->length_ = raw_from->length_;
    raw_to->RecomputeDataField();
    const intptr_t length =
        TypedData::ElementSizeInBytes(cid) * Smi::Value(raw_from->length_);
    memmove(raw_to->data_, raw_from->data_, length);
  }

  void CopyTypedData(const TypedData& from, const TypedData& to) {
    auto raw_from = from.ptr().untag();
    auto raw_to = to.ptr().untag();
    const intptr_t cid = Types::GetTypedDataPtr(from)->GetClassId();
    ASSERT(raw_to->length_ == raw_from->length_);
    raw_to->RecomputeDataField();
    const intptr_t length =
        TypedData::ElementSizeInBytes(cid) * Smi::Value(raw_from->length_);
    CopyTypedDataBaseWithSafepointChecks(Base::thread_, from, to, length);
  }

  void CopyTypedDataView(typename Types::TypedDataView from,
                         typename Types::TypedDataView to) {
    // This will forward & initialize the typed data.
    Base::ForwardCompressedPointer(
        from, to, OFFSET_OF(UntaggedTypedDataView, typed_data_));

    auto raw_from = UntagTypedDataView(from);
    auto raw_to = UntagTypedDataView(to);
    raw_to->length_ = raw_from->length_;
    raw_to->offset_in_bytes_ = raw_from->offset_in_bytes_;
    raw_to->data_ = nullptr;

    auto forwarded_backing_store =
        raw_to->typed_data_.Decompress(Base::heap_base_);
    if (forwarded_backing_store == Marker() ||
        forwarded_backing_store == Object::null()) {
      // Ensure the backing store is never "sentinel" - the scavenger doesn't
      // like it.
      Base::StoreCompressedPointerNoBarrier(
          Types::GetTypedDataViewPtr(to),
          OFFSET_OF(UntaggedTypedDataView, typed_data_), Object::null());
      raw_to->length_ = Smi::New(0);
      raw_to->offset_in_bytes_ = Smi::New(0);
      ASSERT(Base::exception_msg_ != nullptr);
      return;
    }

    const bool is_external =
        raw_from->data_ != raw_from->DataFieldForInternalTypedData();
    if (is_external) {
      // The raw_to is fully initialized at this point (see handling of external
      // typed data in [ForwardCompressedPointer])
      raw_to->RecomputeDataField();
    } else {
      // The raw_to isn't initialized yet, but it's address is valid, so we can
      // compute the data field it would use.
      raw_to->RecomputeDataFieldForInternalTypedData();
    }
    const bool is_external2 =
        raw_to->data_ != raw_to->DataFieldForInternalTypedData();
    ASSERT(is_external == is_external2);
  }

  void CopyExternalTypedData(typename Types::ExternalTypedData from,
                             typename Types::ExternalTypedData to) {
    // The external typed data is initialized on the forwarding pass (where
    // normally allocation but not initialization happens), so views on it
    // can be initialized immediately.
#if defined(DEBUG)
    auto raw_from = UntagExternalTypedData(from);
    auto raw_to = UntagExternalTypedData(to);
    ASSERT(raw_to->data_ != nullptr);
    ASSERT(raw_to->length_ == raw_from->length_);
#endif
  }

  void CopyTransferableTypedData(typename Types::TransferableTypedData from,
                                 typename Types::TransferableTypedData to) {
    // The [TransferableTypedData] is an empty object with an associated heap
    // peer object.
    // -> We'll validate that there's a peer and enqueue the transferable to be
    // transferred if the transitive copy is successful.
    auto fpeer = static_cast<TransferableTypedDataPeer*>(
        Base::heap_->GetPeer(Types::GetTransferableTypedDataPtr(from)));
    ASSERT(fpeer != nullptr);
    if (fpeer->data() == nullptr) {
      Base::exception_msg_ =
          "Illegal argument in isolate message"
          " : (TransferableTypedData has been transferred already)";
      Base::exception_unexpected_object_ =
          Types::GetTransferableTypedDataPtr(from);
      return;
    }
    Base::EnqueueTransferable(from, to);
  }

  void CopyWeakProperty(typename Types::WeakProperty from,
                        typename Types::WeakProperty to) {
    // We store `null`s as keys/values and let the main algorithm know that
    // we should check reachability of the key again after the fixpoint (if it
    // became reachable, forward the key/value).
    Base::StoreCompressedPointerNoBarrier(Types::GetWeakPropertyPtr(to),
                                          OFFSET_OF(UntaggedWeakProperty, key_),
                                          Object::null());
    Base::StoreCompressedPointerNoBarrier(
        Types::GetWeakPropertyPtr(to), OFFSET_OF(UntaggedWeakProperty, value_),
        Object::null());
    // To satisfy some ASSERT()s in GC we'll use Object:null() explicitly here.
    Base::StoreCompressedPointerNoBarrier(
        Types::GetWeakPropertyPtr(to),
        OFFSET_OF(UntaggedWeakProperty, next_seen_by_gc_), Object::null());
    Base::EnqueueWeakProperty(from);
  }

  void CopyWeakReference(typename Types::WeakReference from,
                         typename Types::WeakReference to) {
    // We store `null` as target and let the main algorithm know that
    // we should check reachability of the target again after the fixpoint (if
    // it became reachable, forward the target).
    Base::StoreCompressedPointerNoBarrier(
        Types::GetWeakReferencePtr(to),
        OFFSET_OF(UntaggedWeakReference, target_), Object::null());
    // Type argument should always be copied.
    Base::ForwardCompressedPointer(
        from, to, OFFSET_OF(UntaggedWeakReference, type_arguments_));
    // To satisfy some ASSERT()s in GC we'll use Object:null() explicitly here.
    Base::StoreCompressedPointerNoBarrier(
        Types::GetWeakReferencePtr(to),
        OFFSET_OF(UntaggedWeakReference, next_seen_by_gc_), Object::null());
    Base::EnqueueWeakReference(from);
  }

#define DEFINE_UNSUPPORTED(clazz)                                              \
  void Copy##clazz(typename Types::clazz from, typename Types::clazz to) {     \
    FATAL("Objects of type " #clazz " should not occur in object graphs");     \
  }

  FOR_UNSUPPORTED_CLASSES(DEFINE_UNSUPPORTED)

#undef DEFINE_UNSUPPORTED

  UntaggedObject* UntagObject(typename Types::Object obj) {
    return Types::GetObjectPtr(obj).Decompress(Base::heap_base_).untag();
  }

#define DO(V)                                                                  \
  DART_FORCE_INLINE                                                            \
  Untagged##V* Untag##V(typename Types::V obj) {                               \
    return Types::Get##V##Ptr(obj).Decompress(Base::heap_base_).untag();       \
  }
  CLASS_LIST_FOR_HANDLES(DO)
#undef DO
};

class FastObjectCopy : public ObjectCopy<FastObjectCopyBase> {
 public:
  FastObjectCopy(Thread* thread, IdentityMap* map) : ObjectCopy(thread, map) {}
  ~FastObjectCopy() {}

  ObjectPtr TryCopyGraphFast(ObjectPtr root) {
    NoSafepointScope no_safepoint_scope;

    ObjectPtr root_copy = Forward(TagsFromUntaggedObject(root.untag()), root);
    if (root_copy == Marker()) {
      return root_copy;
    }
    auto& from_weak_property = WeakProperty::Handle(zone_);
    auto& to_weak_property = WeakProperty::Handle(zone_);
    auto& weak_property_key = Object::Handle(zone_);
    while (true) {
      if (fast_forward_map_.fill_cursor_ ==
          fast_forward_map_.raw_from_to_.length()) {
        break;
      }

      // Run fixpoint to copy all objects.
      while (fast_forward_map_.fill_cursor_ <
             fast_forward_map_.raw_from_to_.length()) {
        const intptr_t index = fast_forward_map_.fill_cursor_;
        ObjectPtr from = fast_forward_map_.raw_from_to_[index];
        ObjectPtr to = fast_forward_map_.raw_from_to_[index + 1];
        FastCopyObject(from, to);
        if (exception_msg_ != nullptr) {
          return root_copy;
        }
        fast_forward_map_.fill_cursor_ += 2;

        // To maintain responsiveness we regularly check whether safepoints are
        // requested - if so, we bail to slow path which will then checkin.
        if (thread_->IsSafepointRequested()) {
          exception_msg_ = kFastAllocationFailed;
          return root_copy;
        }
      }

      // Possibly forward values of [WeakProperty]s if keys became reachable.
      intptr_t i = 0;
      auto& weak_properties = fast_forward_map_.raw_weak_properties_;
      while (i < weak_properties.length()) {
        from_weak_property = weak_properties[i];
        weak_property_key =
            fast_forward_map_.ForwardedObject(from_weak_property.key());
        if (weak_property_key.ptr() != Marker()) {
          to_weak_property ^=
              fast_forward_map_.ForwardedObject(from_weak_property.ptr());

          // The key became reachable so we'll change the forwarded
          // [WeakProperty]'s key to the new key (it is `null` at this point).
          to_weak_property.set_key(weak_property_key);

          // Since the key has become strongly reachable in the copied graph,
          // we'll also need to forward the value.
          ForwardCompressedPointer(from_weak_property.ptr(),
                                   to_weak_property.ptr(),
                                   OFFSET_OF(UntaggedWeakProperty, value_));

          // We don't need to process this [WeakProperty] again.
          const intptr_t last = weak_properties.length() - 1;
          if (i < last) {
            weak_properties[i] = weak_properties[last];
            weak_properties.SetLength(last);
            continue;
          }
        }
        i++;
      }
    }
    // After the fix point with [WeakProperty]s do [WeakReference]s.
    auto& from_weak_reference = WeakReference::Handle(zone_);
    auto& to_weak_reference = WeakReference::Handle(zone_);
    auto& weak_reference_target = Object::Handle(zone_);
    auto& weak_references = fast_forward_map_.raw_weak_references_;
    for (intptr_t i = 0; i < weak_references.length(); i++) {
      from_weak_reference = weak_references[i];
      weak_reference_target =
          fast_forward_map_.ForwardedObject(from_weak_reference.target());
      if (weak_reference_target.ptr() != Marker()) {
        to_weak_reference ^=
            fast_forward_map_.ForwardedObject(from_weak_reference.ptr());

        // The target became reachable so we'll change the forwarded
        // [WeakReference]'s target to the new target (it is `null` at this
        // point).
        to_weak_reference.set_target(weak_reference_target);
      }
    }
    if (root_copy != Marker()) {
      ObjectPtr array;
      array = TryBuildArrayOfObjectsToRehash(
          fast_forward_map_.raw_objects_to_rehash_);
      if (array == Marker()) return root_copy;
      raw_objects_to_rehash_ = Array::RawCast(array);

      array = TryBuildArrayOfObjectsToRehash(
          fast_forward_map_.raw_expandos_to_rehash_);
      if (array == Marker()) return root_copy;
      raw_expandos_to_rehash_ = Array::RawCast(array);
    }
    return root_copy;
  }

  ObjectPtr TryBuildArrayOfObjectsToRehash(
      const GrowableArray<ObjectPtr>& objects_to_rehash) {
    const intptr_t length = objects_to_rehash.length();
    if (length == 0) return Object::null();

    const intptr_t size = Array::InstanceSize(length);
    const uword array_addr = new_space_->TryAllocateNoSafepoint(thread_, size);
    if (array_addr == 0) {
      exception_msg_ = kFastAllocationFailed;
      return Marker();
    }

    const uword header_size =
        UntaggedObject::SizeTag::SizeFits(size) ? size : 0;
    ArrayPtr array(reinterpret_cast<UntaggedArray*>(array_addr));
    SetNewSpaceTaggingWord(array, kArrayCid, header_size);
    StoreCompressedPointerNoBarrier(array, OFFSET_OF(UntaggedArray, length_),
                                    Smi::New(length));
    StoreCompressedPointerNoBarrier(array,
                                    OFFSET_OF(UntaggedArray, type_arguments_),
                                    TypeArguments::null());
    auto array_data = array.untag()->data();
    for (intptr_t i = 0; i < length; ++i) {
      array_data[i] = objects_to_rehash[i];
    }
    return array;
  }

 private:
  friend class ObjectGraphCopier;

  void FastCopyObject(ObjectPtr from, ObjectPtr to) {
    const uword tags = TagsFromUntaggedObject(from.untag());
    const intptr_t cid = UntaggedObject::ClassIdTag::decode(tags);
    const intptr_t size = UntaggedObject::SizeTag::decode(tags);

    // Ensure the last word is GC-safe (our heap objects are 2-word aligned, the
    // object header stores the size in multiples of kObjectAlignment, the GC
    // uses the information from the header and therefore might visit one slot
    // more than the actual size of the instance).
    *reinterpret_cast<ObjectPtr*>(UntaggedObject::ToAddr(to) +
                                  from.untag()->HeapSize() - kWordSize) =
        nullptr;
    SetNewSpaceTaggingWord(to, cid, size);

    // Fall back to virtual variant for predefined classes
    if (cid < kNumPredefinedCids && cid != kInstanceCid) {
      CopyPredefinedInstance(from, to, cid);
      return;
    }
    const auto bitmap = class_table_->GetUnboxedFieldsMapAt(cid);
    CopyUserdefinedInstance(Instance::RawCast(from), Instance::RawCast(to),
                            bitmap);
    if (cid == expando_cid_) {
      EnqueueExpandoToRehash(to);
    }
  }

  ArrayPtr raw_objects_to_rehash_ = Array::null();
  ArrayPtr raw_expandos_to_rehash_ = Array::null();
};

class SlowObjectCopy : public ObjectCopy<SlowObjectCopyBase> {
 public:
  SlowObjectCopy(Thread* thread, IdentityMap* map)
      : ObjectCopy(thread, map),
        objects_to_rehash_(Array::Handle(thread->zone())),
        expandos_to_rehash_(Array::Handle(thread->zone())) {}
  ~SlowObjectCopy() {}

  ObjectPtr ContinueCopyGraphSlow(const Object& root,
                                  const Object& fast_root_copy) {
    auto& root_copy = Object::Handle(Z, fast_root_copy.ptr());
    if (root_copy.ptr() == Marker()) {
      root_copy = Forward(TagsFromUntaggedObject(root.ptr().untag()), root);
    }

    WeakProperty& weak_property = WeakProperty::Handle(Z);
    Object& from = Object::Handle(Z);
    Object& to = Object::Handle(Z);
    while (true) {
      if (slow_forward_map_.fill_cursor_ ==
          slow_forward_map_.from_to_.Length()) {
        break;
      }

      // Run fixpoint to copy all objects.
      while (slow_forward_map_.fill_cursor_ <
             slow_forward_map_.from_to_.Length()) {
        const intptr_t index = slow_forward_map_.fill_cursor_;
        from = slow_forward_map_.from_to_.At(index);
        to = slow_forward_map_.from_to_.At(index + 1);
        CopyObject(from, to);
        slow_forward_map_.fill_cursor_ += 2;
        if (exception_msg_ != nullptr) {
          return Marker();
        }
        // To maintain responsiveness we regularly check whether safepoints are
        // requested.
        thread_->CheckForSafepoint();
      }

      // Possibly forward values of [WeakProperty]s if keys became reachable.
      intptr_t i = 0;
      auto& weak_properties = slow_forward_map_.weak_properties_;
      while (i < weak_properties.length()) {
        const auto& from_weak_property = *weak_properties[i];
        to = slow_forward_map_.ForwardedObject(from_weak_property.key());
        if (to.ptr() != Marker()) {
          weak_property ^=
              slow_forward_map_.ForwardedObject(from_weak_property.ptr());

          // The key became reachable so we'll change the forwarded
          // [WeakProperty]'s key to the new key (it is `null` at this point).
          weak_property.set_key(to);

          // Since the key has become strongly reachable in the copied graph,
          // we'll also need to forward the value.
          ForwardCompressedPointer(from_weak_property, weak_property,
                                   OFFSET_OF(UntaggedWeakProperty, value_));

          // We don't need to process this [WeakProperty] again.
          const intptr_t last = weak_properties.length() - 1;
          if (i < last) {
            weak_properties[i] = weak_properties[last];
            weak_properties.SetLength(last);
            continue;
          }
        }
        i++;
      }
    }

    // After the fix point with [WeakProperty]s do [WeakReference]s.
    WeakReference& weak_reference = WeakReference::Handle(Z);
    auto& weak_references = slow_forward_map_.weak_references_;
    for (intptr_t i = 0; i < weak_references.length(); i++) {
      const auto& from_weak_reference = *weak_references[i];
      to = slow_forward_map_.ForwardedObject(from_weak_reference.target());
      if (to.ptr() != Marker()) {
        weak_reference ^=
            slow_forward_map_.ForwardedObject(from_weak_reference.ptr());

        // The target became reachable so we'll change the forwarded
        // [WeakReference]'s target to the new target (it is `null` at this
        // point).
        weak_reference.set_target(to);
      }
    }

    objects_to_rehash_ =
        BuildArrayOfObjectsToRehash(slow_forward_map_.objects_to_rehash_);
    expandos_to_rehash_ =
        BuildArrayOfObjectsToRehash(slow_forward_map_.expandos_to_rehash_);
    return root_copy.ptr();
  }

  ArrayPtr BuildArrayOfObjectsToRehash(
      const GrowableArray<const Object*>& objects_to_rehash) {
    const intptr_t length = objects_to_rehash.length();
    if (length == 0) return Array::null();

    const auto& array = Array::Handle(zone_, Array::New(length));
    for (intptr_t i = 0; i < length; ++i) {
      array.SetAt(i, *objects_to_rehash[i]);
    }
    return array.ptr();
  }

 private:
  friend class ObjectGraphCopier;

  void CopyObject(const Object& from, const Object& to) {
    const auto cid = from.GetClassId();

    // Fall back to virtual variant for predefined classes
    if (cid < kNumPredefinedCids && cid != kInstanceCid) {
      CopyPredefinedInstance(from, to, cid);
      return;
    }
    const auto bitmap = class_table_->GetUnboxedFieldsMapAt(cid);
    CopyUserdefinedInstance(from, to, bitmap);
    if (cid == expando_cid_) {
      EnqueueExpandoToRehash(to);
    }
  }

  Array& objects_to_rehash_;
  Array& expandos_to_rehash_;
};

class ObjectGraphCopier : public StackResource {
 public:
  explicit ObjectGraphCopier(Thread* thread)
      : StackResource(thread),
        thread_(thread),
        zone_(thread->zone()),
        map_(thread),
        fast_object_copy_(thread_, &map_),
        slow_object_copy_(thread_, &map_) {}

  // Result will be
  //   [
  //     <message>,
  //     <collection-lib-objects-to-rehash>,
  //     <core-lib-objects-to-rehash>,
  //   ]
  ObjectPtr CopyObjectGraph(const Object& root) {
    const char* volatile exception_msg = nullptr;
    auto& result = Object::Handle(zone_);

    {
      LongJumpScope jump;  // e.g. for OOMs.
      if (setjmp(*jump.Set()) == 0) {
        result = CopyObjectGraphInternal(root, &exception_msg);
        // Any allocated external typed data must have finalizers attached so
        // memory will get free()ed.
        slow_object_copy_.slow_forward_map_.FinalizeExternalTypedData();
      } else {
        // Any allocated external typed data must have finalizers attached so
        // memory will get free()ed.
        slow_object_copy_.slow_forward_map_.FinalizeExternalTypedData();

        // The copy failed due to non-application error (e.g. OOM error),
        // propagate this error.
        result = thread_->StealStickyError();
        RELEASE_ASSERT(result.IsError());
      }
    }

    if (result.IsError()) {
      Exceptions::PropagateError(Error::Cast(result));
      UNREACHABLE();
    }
    ASSERT(result.IsArray());
    auto& result_array = Array::Cast(result);
    if (result_array.At(0) == Marker()) {
      ASSERT(exception_msg != nullptr);
      auto& unexpected_object_ = Object::Handle(zone_, result_array.At(1));
      if (!unexpected_object_.IsNull()) {
        exception_msg =
            OS::SCreate(zone_, "%s\n%s", exception_msg,
                        FindRetainingPath(
                            zone_, thread_->isolate(), root, unexpected_object_,
                            TraversalRules::kInternalToIsolateGroup));
      }
      ThrowException(exception_msg);
      UNREACHABLE();
    }

    // The copy was successful, then detach transferable data from the sender
    // and attach to the copied graph.
    slow_object_copy_.slow_forward_map_.FinalizeTransferables();
    return result.ptr();
  }

  intptr_t allocated_bytes() { return allocated_bytes_; }

  intptr_t copied_objects() { return copied_objects_; }

 private:
  ObjectPtr CopyObjectGraphInternal(const Object& root,
                                    const char* volatile* exception_msg) {
    const auto& result_array = Array::Handle(zone_, Array::New(3));
    if (!root.ptr()->IsHeapObject()) {
      result_array.SetAt(0, root);
      return result_array.ptr();
    }
    const uword tags = TagsFromUntaggedObject(root.ptr().untag());
    if (CanShareObject(root.ptr(), tags)) {
      result_array.SetAt(0, root);
      return result_array.ptr();
    }
    if (!fast_object_copy_.CanCopyObject(tags, root.ptr())) {
      ASSERT(fast_object_copy_.exception_msg_ != nullptr);
      *exception_msg = fast_object_copy_.exception_msg_;
      result_array.SetAt(0, Object::Handle(zone_, Marker()));
      result_array.SetAt(1, fast_object_copy_.exception_unexpected_object_);
      return result_array.ptr();
    }

    // We try a fast new-space only copy first that will not use any barriers.
    auto& result = Object::Handle(Z, Marker());

    // All allocated but non-initialized heap objects have to be made GC-visible
    // at this point.
    if (FLAG_enable_fast_object_copy) {
      {
        NoSafepointScope no_safepoint_scope;

        result = fast_object_copy_.TryCopyGraphFast(root.ptr());
        if (result.ptr() != Marker()) {
          if (fast_object_copy_.exception_msg_ == nullptr) {
            result_array.SetAt(0, result);
            fast_object_copy_.tmp_ = fast_object_copy_.raw_objects_to_rehash_;
            result_array.SetAt(1, fast_object_copy_.tmp_);
            fast_object_copy_.tmp_ = fast_object_copy_.raw_expandos_to_rehash_;
            result_array.SetAt(2, fast_object_copy_.tmp_);
            HandlifyExternalTypedData();
            HandlifyTransferables();
            allocated_bytes_ =
                fast_object_copy_.fast_forward_map_.allocated_bytes;
            copied_objects_ =
                fast_object_copy_.fast_forward_map_.fill_cursor_ / 2 -
                /*null_entry=*/1;
            return result_array.ptr();
          }

          // There are left-over uninitialized objects we'll have to make GC
          // visible.
          SwitchToSlowForwardingList();
        }
      }

      if (FLAG_gc_on_foc_slow_path) {
        // We force the GC to compact, which is more likely to discover
        // untracked pointers (and other issues, like incorrect class table).
        thread_->heap()->CollectAllGarbage(GCReason::kDebugging,
                                           /*compact=*/true);
      }

      ObjectifyFromToObjects();

      // Fast copy failed due to
      //   - either failure to allocate into new space
      //   - or failure to copy object which we cannot copy
      ASSERT(fast_object_copy_.exception_msg_ != nullptr);
      if (fast_object_copy_.exception_msg_ != kFastAllocationFailed) {
        *exception_msg = fast_object_copy_.exception_msg_;
        result_array.SetAt(0, Object::Handle(zone_, Marker()));
        result_array.SetAt(1, fast_object_copy_.exception_unexpected_object_);
        return result_array.ptr();
      }
      ASSERT(fast_object_copy_.exception_msg_ == kFastAllocationFailed);
    }

    // Use the slow copy approach.
    result = slow_object_copy_.ContinueCopyGraphSlow(root, result);
    ASSERT((result.ptr() == Marker()) ==
           (slow_object_copy_.exception_msg_ != nullptr));
    if (result.ptr() == Marker()) {
      *exception_msg = slow_object_copy_.exception_msg_;
      result_array.SetAt(0, Object::Handle(zone_, Marker()));
      result_array.SetAt(1, slow_object_copy_.exception_unexpected_object_);
      return result_array.ptr();
    }

    result_array.SetAt(0, result);
    result_array.SetAt(1, slow_object_copy_.objects_to_rehash_);
    result_array.SetAt(2, slow_object_copy_.expandos_to_rehash_);
    allocated_bytes_ = slow_object_copy_.slow_forward_map_.allocated_bytes;
    copied_objects_ =
        slow_object_copy_.slow_forward_map_.fill_cursor_ / 2 - /*null_entry=*/1;
    return result_array.ptr();
  }

  void SwitchToSlowForwardingList() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    auto& slow_forward_map = slow_object_copy_.slow_forward_map_;

    MakeUninitializedNewSpaceObjectsGCSafe();
    HandlifyTransferables();
    HandlifyWeakProperties();
    HandlifyWeakReferences();
    HandlifyExternalTypedData();
    HandlifyObjectsToReHash();
    HandlifyExpandosToReHash();
    HandlifyFromToObjects();
    slow_forward_map.fill_cursor_ = fast_forward_map.fill_cursor_;
    slow_forward_map.allocated_bytes = fast_forward_map.allocated_bytes;
  }

  void MakeUninitializedNewSpaceObjectsGCSafe() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    const auto length = fast_forward_map.raw_from_to_.length();
    const auto cursor = fast_forward_map.fill_cursor_;
    for (intptr_t i = cursor; i < length; i += 2) {
      auto from = fast_forward_map.raw_from_to_[i];
      auto to = fast_forward_map.raw_from_to_[i + 1];
      const uword tags = TagsFromUntaggedObject(from.untag());
      const intptr_t cid = UntaggedObject::ClassIdTag::decode(tags);
      // External typed data is already initialized.
      if (!IsExternalTypedDataClassId(cid) && !IsTypedDataViewClassId(cid) &&
          !IsUnmodifiableTypedDataViewClassId(cid)) {
#if defined(DART_COMPRESSED_POINTERS)
        const bool compressed = true;
#else
        const bool compressed = false;
#endif
        Object::InitializeObject(reinterpret_cast<uword>(to.untag()), cid,
                                 from.untag()->HeapSize(), compressed);
        UpdateLengthField(cid, from, to);
      }
    }
  }
  void HandlifyTransferables() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_transferables_from_to_,
             &slow_object_copy_.slow_forward_map_.transferables_from_to_);
  }
  void HandlifyWeakProperties() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_weak_properties_,
             &slow_object_copy_.slow_forward_map_.weak_properties_);
  }
  void HandlifyWeakReferences() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_weak_references_,
             &slow_object_copy_.slow_forward_map_.weak_references_);
  }
  void HandlifyExternalTypedData() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_external_typed_data_to_,
             &slow_object_copy_.slow_forward_map_.external_typed_data_);
  }
  void HandlifyObjectsToReHash() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_objects_to_rehash_,
             &slow_object_copy_.slow_forward_map_.objects_to_rehash_);
  }
  void HandlifyExpandosToReHash() {
    Handlify(&fast_object_copy_.fast_forward_map_.raw_expandos_to_rehash_,
             &slow_object_copy_.slow_forward_map_.expandos_to_rehash_);
  }
  template <typename RawType, typename HandleType>
  void Handlify(GrowableArray<RawType>* from,
                GrowableArray<const HandleType*>* to) {
    const auto length = from->length();
    if (length > 0) {
      to->Resize(length);
      for (intptr_t i = 0; i < length; i++) {
        (*to)[i] = &HandleType::Handle(Z, (*from)[i]);
      }
      from->Clear();
    }
  }
  void HandlifyFromToObjects() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    auto& slow_forward_map = slow_object_copy_.slow_forward_map_;
    const intptr_t length = fast_forward_map.raw_from_to_.length();
    slow_forward_map.from_to_transition_.Resize(length);
    for (intptr_t i = 0; i < length; i++) {
      slow_forward_map.from_to_transition_[i] =
          &PassiveObject::Handle(Z, fast_forward_map.raw_from_to_[i]);
    }
    ASSERT(slow_forward_map.from_to_transition_.length() == length);
    fast_forward_map.raw_from_to_.Clear();
  }
  void ObjectifyFromToObjects() {
    auto& from_to_transition =
        slow_object_copy_.slow_forward_map_.from_to_transition_;
    auto& from_to = slow_object_copy_.slow_forward_map_.from_to_;
    intptr_t length = from_to_transition.length();
    from_to = GrowableObjectArray::New(length, Heap::kOld);
    for (intptr_t i = 0; i < length; i++) {
      from_to.Add(*from_to_transition[i]);
    }
    ASSERT(from_to.Length() == length);
    from_to_transition.Clear();
  }

  void ThrowException(const char* exception_msg) {
    const auto& msg_obj = String::Handle(Z, String::New(exception_msg));
    const auto& args = Array::Handle(Z, Array::New(1));
    args.SetAt(0, msg_obj);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
    UNREACHABLE();
  }

  Thread* thread_;
  Zone* zone_;
  IdentityMap map_;
  FastObjectCopy fast_object_copy_;
  SlowObjectCopy slow_object_copy_;
  intptr_t copied_objects_ = 0;
  intptr_t allocated_bytes_ = 0;
};

ObjectPtr CopyMutableObjectGraph(const Object& object) {
  auto thread = Thread::Current();
  TIMELINE_DURATION(thread, Isolate, "CopyMutableObjectGraph");
  ObjectGraphCopier copier(thread);
  ObjectPtr result = copier.CopyObjectGraph(object);
#if defined(SUPPORT_TIMELINE)
  if (tbes.enabled()) {
    tbes.SetNumArguments(2);
    tbes.FormatArgument(0, "CopiedObjects", "%" Pd, copier.copied_objects());
    tbes.FormatArgument(1, "AllocatedBytes", "%" Pd, copier.allocated_bytes());
  }
#endif
  return result;
}

}  // namespace dart
