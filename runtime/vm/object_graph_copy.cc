// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object_graph_copy.h"
#include "vm/dart_api_state.h"
#include "vm/flags.h"
#include "vm/heap/weak_table.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/snapshot.h"
#include "vm/symbols.h"

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
  V(Context)                                                                   \
  V(ContextScope)                                                              \
  V(DynamicLibrary)                                                            \
  V(Error)                                                                     \
  V(ExceptionHandlers)                                                         \
  V(FfiTrampolineData)                                                         \
  V(Field)                                                                     \
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
  V(RegExp)                                                                    \
  V(Script)                                                                    \
  V(Sentinel)                                                                  \
  V(SendPort)                                                                  \
  V(SingleTargetCache)                                                         \
  V(Smi)                                                                       \
  V(StackTrace)                                                                \
  V(SubtypeTestCache)                                                          \
  V(Type)                                                                      \
  V(TypeArguments)                                                             \
  V(TypeParameter)                                                             \
  V(TypeParameters)                                                            \
  V(TypeRef)                                                                   \
  V(TypedDataBase)                                                             \
  V(UnhandledException)                                                        \
  V(UnlinkedCall)                                                              \
  V(UnwindError)                                                               \
  V(UserTag)                                                                   \
  V(WeakProperty)                                                              \
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
static bool CanShareObject(uword tags) {
  if ((tags & UntaggedObject::CanonicalBit::mask_in_place()) != 0) {
    return true;
  }
  const auto cid = UntaggedObject::ClassIdTag::decode(tags);
  if (cid == kOneByteStringCid) return true;
  if (cid == kTwoByteStringCid) return true;
  if (cid == kExternalOneByteStringCid) return true;
  if (cid == kExternalTwoByteStringCid) return true;
  if (cid == kMintCid) return true;
  if (cid == kImmutableArrayCid) return true;
  if (cid == kNeverCid) return true;
  if (cid == kSentinelCid) return true;
#if defined(DART_PRECOMPILED_RUNTIME)
  // In JIT mode we have field guards enabled which means
  // double/float32x4/float64x2 boxes can be mutable and we therefore cannot
  // share them.
  if (cid == kDoubleCid || cid == kFloat32x4Cid || cid == kFloat64x2Cid) {
    return true;
  }
#endif
  if (cid == kInt32x4Cid) return true;  // No field guards here.
  if (cid == kSendPortCid) return true;
  if (cid == kCapabilityCid) return true;
  if (cid == kRegExpCid) return true;

  return false;
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
  if (cid == kImmutableArrayCid) return false;
  if (cid == kRegExpCid) return false;
  if (cid == kInt32x4Cid) return false;

  // We copy those (instead of sharing them) - see [CanShareObjct]. They rely
  // on the default hashCode implementation which uses identity hash codes
  // (instead of structural hash code).
  if (cid == kFloat32x4Cid || cid == kFloat64x2Cid) {
    return !kDartPrecompiledRuntime;
  }

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
#if defined(HASH_IN_OBJECT_HEADER)
  tags = UntaggedObject::HashTag::update(0, tags);
#endif
  to.untag()->tags_ = tags;
}

DART_FORCE_INLINE
ObjectPtr AllocateObject(intptr_t cid, intptr_t size) {
#if defined(DART_COMPRESSED_POINTERS)
  const bool compressed = true;
#else
  const bool compressed = false;
#endif
  return Object::Allocate(cid, size, Heap::kNew, compressed);
}

DART_FORCE_INLINE
void UpdateLengthField(intptr_t cid, ObjectPtr from, ObjectPtr to) {
  // We share these objects - never copy them.
  ASSERT(!IsStringClassId(cid));
  ASSERT(cid != kImmutableArrayCid);

  // We update any in-heap variable sized object with the length to keep the
  // length and the size in the object header in-sync for the GC.
  if (cid == kArrayCid) {
    static_cast<UntaggedArray*>(to.untag())->length_ =
        static_cast<UntaggedArray*>(from.untag())->length_;
  } else if (IsTypedDataClassId(cid)) {
    static_cast<UntaggedTypedDataBase*>(to.untag())->length_ =
        static_cast<UntaggedTypedDataBase*>(from.untag())->length_;
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

void InitializeTypedDataView(TypedDataViewPtr obj) {
  obj.untag()->typed_data_ = TypedDataBase::null();
  obj.untag()->offset_in_bytes_ = 0;
  obj.untag()->length_ = 0;
}

void FreeExternalTypedData(void* isolate_callback_data, void* buffer) {
  free(buffer);
}

void FreeTransferablePeer(void* isolate_callback_data, void* peer) {
  delete static_cast<TransferableTypedDataPeer*>(peer);
}

class ForwardMapBase {
 public:
  explicit ForwardMapBase(Thread* thread)
      : thread_(thread), zone_(thread->zone()), isolate_(thread->isolate()) {}

 protected:
  friend class ObjectGraphCopier;

  intptr_t GetObjectId(ObjectPtr object) {
    if (object->IsNewObject()) {
      return isolate_->forward_table_new()->GetValueExclusive(object);
    } else {
      return isolate_->forward_table_old()->GetValueExclusive(object);
    }
  }
  void SetObjectId(ObjectPtr object, intptr_t id) {
    if (object->IsNewObject()) {
      isolate_->forward_table_new()->SetValueExclusive(object, id);
    } else {
      isolate_->forward_table_old()->SetValueExclusive(object, id);
    }
  }

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
    tpeer->set_handle(FinalizablePersistentHandle::New(
        thread_->isolate_group(), to, tpeer, FreeTransferablePeer, length,
        /*auto_delete=*/true));
    fpeer->ClearData();
  }

  void FinalizeExternalTypedData(const ExternalTypedData& to) {
    to.AddFinalizer(to.DataAddr(0), &FreeExternalTypedData, to.LengthInBytes());
  }

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;

 private:
  DISALLOW_COPY_AND_ASSIGN(ForwardMapBase);
};

class FastForwardMap : public ForwardMapBase {
 public:
  explicit FastForwardMap(Thread* thread)
      : ForwardMapBase(thread),
        raw_from_to_(thread->zone(), 20),
        raw_transferables_from_to_(thread->zone(), 0),
        raw_objects_to_rehash_(thread->zone(), 0) {
    raw_from_to_.Resize(2);
    raw_from_to_[0] = Object::null();
    raw_from_to_[1] = Object::null();
    fill_cursor_ = 2;
  }

  ObjectPtr ForwardedObject(ObjectPtr object) {
    const intptr_t id = GetObjectId(object);
    if (id == 0) return Marker();
    return raw_from_to_[id + 1];
  }

  void Insert(ObjectPtr from, ObjectPtr to) {
    ASSERT(ForwardedObject(from) == Marker());
    ASSERT(raw_from_to_.length() == raw_from_to_.length());
    const auto id = raw_from_to_.length();
    SetObjectId(from, id);
    raw_from_to_.Resize(id + 2);
    raw_from_to_[id] = from;
    raw_from_to_[id + 1] = to;
  }

  void AddTransferable(TransferableTypedDataPtr from,
                       TransferableTypedDataPtr to) {
    raw_transferables_from_to_.Add(from);
    raw_transferables_from_to_.Add(to);
  }
  void AddExternalTypedData(ExternalTypedDataPtr to) {
    raw_external_typed_data_to_.Add(to);
  }

  void AddObjectToRehash(ObjectPtr to) { raw_objects_to_rehash_.Add(to); }

 private:
  friend class FastObjectCopy;
  friend class ObjectGraphCopier;

  GrowableArray<ObjectPtr> raw_from_to_;
  GrowableArray<TransferableTypedDataPtr> raw_transferables_from_to_;
  GrowableArray<ExternalTypedDataPtr> raw_external_typed_data_to_;
  GrowableArray<ObjectPtr> raw_objects_to_rehash_;
  intptr_t fill_cursor_ = 0;

  DISALLOW_COPY_AND_ASSIGN(FastForwardMap);
};

class SlowForwardMap : public ForwardMapBase {
 public:
  explicit SlowForwardMap(Thread* thread)
      : ForwardMapBase(thread),
        from_to_(thread->zone(), 20),
        transferables_from_to_(thread->zone(), 0) {
    from_to_.Resize(2);
    from_to_[0] = &Object::null_object();
    from_to_[1] = &Object::null_object();
    fill_cursor_ = 2;
  }

  ObjectPtr ForwardedObject(ObjectPtr object) {
    const intptr_t id = GetObjectId(object);
    if (id == 0) return Marker();
    return from_to_[id + 1]->ptr();
  }

  void Insert(ObjectPtr from, ObjectPtr to) {
    ASSERT(ForwardedObject(from) == Marker());
    const auto id = from_to_.length();
    SetObjectId(from, id);
    from_to_.Resize(id + 2);
    from_to_[id] = &Object::Handle(Z, from);
    from_to_[id + 1] = &Object::Handle(Z, to);
  }

  void AddTransferable(const TransferableTypedData& from,
                       const TransferableTypedData& to) {
    transferables_from_to_.Add(&TransferableTypedData::Handle(from.ptr()));
    transferables_from_to_.Add(&TransferableTypedData::Handle(to.ptr()));
  }

  void AddExternalTypedData(ExternalTypedDataPtr to) {
    external_typed_data_.Add(&ExternalTypedData::Handle(to));
  }

  void AddObjectToRehash(const Object& to) {
    objects_to_rehash_.Add(&Object::Handle(to.ptr()));
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
  friend class ObjectGraphCopier;

  GrowableArray<const Object*> from_to_;
  GrowableArray<const TransferableTypedData*> transferables_from_to_;
  GrowableArray<const ExternalTypedData*> external_typed_data_;
  GrowableArray<const Object*> objects_to_rehash_;
  intptr_t fill_cursor_ = 0;

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
        tmp_(Object::Handle(thread->zone())) {}
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
    if (cid > kNumPredefinedCids) {
      const bool has_native_fields =
          Class::NumNativeFieldsOf(class_table_->At(cid)) != 0;
      if (has_native_fields) {
        exception_msg_ =
            "Illegal argument in isolate message: (object has native fields)";
        return false;
      }
      return true;
    }
#define HANDLE_ILLEGAL_CASE(Type)                                              \
  case k##Type##Cid: {                                                         \
    exception_msg_ =                                                           \
        "Illegal argument in isolate message: "                                \
        "(object is a" #Type ")";                                              \
    return false;                                                              \
  }

    switch (cid) {
      HANDLE_ILLEGAL_CASE(MirrorReference)
      HANDLE_ILLEGAL_CASE(ReceivePort)
      HANDLE_ILLEGAL_CASE(StackTrace)
      HANDLE_ILLEGAL_CASE(UserTag)
      HANDLE_ILLEGAL_CASE(DynamicLibrary)
      HANDLE_ILLEGAL_CASE(Pointer)
      case kClosureCid: {
        if (!Function::IsImplicitStaticClosureFunction(
                Closure::FunctionOf(Closure::RawCast(object)))) {
          exception_msg_ =
              "Illegal argument in isolate message: (object is a closure)";
          return false;
        }
        ASSERT(Closure::ContextOf(Closure::RawCast(object)) == Object::null());
        return true;
      }
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

  const char* exception_msg_ = nullptr;
};

class FastObjectCopyBase : public ObjectCopyBase {
 public:
  using Types = PtrTypes;

  explicit FastObjectCopyBase(Thread* thread)
      : ObjectCopyBase(thread), fast_forward_map_(thread) {}

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

  DART_FORCE_INLINE
  void ForwardCompressedPointer(ObjectPtr src, ObjectPtr dst, intptr_t offset) {
    auto value = LoadCompressedPointer(src, offset);
    if (!value.IsHeapObject()) {
      StoreCompressedPointerNoBarrier(dst, offset, value);
      return;
    }
    auto value_decompressed = value.Decompress(heap_base_);
    const uword tags = TagsFromUntaggedObject(value_decompressed.untag());
    if (CanShareObject(tags)) {
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

    auto to = Forward(tags, value.Decompress(heap_base_));
    StoreCompressedPointerNoBarrier(dst, offset, to);
  }

  ObjectPtr Forward(uword tags, ObjectPtr from) {
    const intptr_t header_size = UntaggedObject::SizeTag::decode(tags);
    const auto cid = UntaggedObject::ClassIdTag::decode(tags);
    const uword size =
        header_size != 0 ? header_size : from.untag()->HeapSize();
    if (Heap::IsAllocatableInNewSpace(size)) {
      const uword alloc = new_space_->TryAllocate(thread_, size);
      if (alloc != 0) {
        ObjectPtr to(reinterpret_cast<UntaggedObject*>(alloc));
        fast_forward_map_.Insert(from, to);

        if (IsExternalTypedDataClassId(cid)) {
          SetNewSpaceTaggingWord(to, cid, header_size);
          InitializeExternalTypedData(cid, ExternalTypedData::RawCast(from),
                                      ExternalTypedData::RawCast(to));
          fast_forward_map_.AddExternalTypedData(
              ExternalTypedData::RawCast(to));
        } else if (IsTypedDataViewClassId(cid)) {
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
  void EnqueueObjectToRehash(ObjectPtr to) {
    fast_forward_map_.AddObjectToRehash(to);
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

  explicit SlowObjectCopyBase(Thread* thread)
      : ObjectCopyBase(thread), slow_forward_map_(thread) {}

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
      }
    } else {
      for (; offset < end_offset; offset += kCompressedWordSize) {
        ForwardCompressedPointer(src, dst, offset);
      }
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
    if (CanShareObject(tags)) {
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
    if (CanShareObject(tags)) {
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
    ObjectPtr to = AllocateObject(cid, size);
    slow_forward_map_.Insert(from.ptr(), to);
    UpdateLengthField(cid, from.ptr(), to);
    if (cid == kArrayCid && !Heap::IsAllocatableInNewSpace(size)) {
      to.untag()->SetCardRememberedBitUnsynchronized();
    }
    if (IsExternalTypedDataClassId(cid)) {
      InitializeExternalTypedData(cid, ExternalTypedData::RawCast(from.ptr()),
                                  ExternalTypedData::RawCast(to));
      slow_forward_map_.AddExternalTypedData(ExternalTypedData::RawCast(to));
    } else if (IsTypedDataViewClassId(cid)) {
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
  void EnqueueObjectToRehash(const Object& to) {
    slow_forward_map_.AddObjectToRehash(to);
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

  explicit ObjectCopy(Thread* thread) : Base(thread) {}

  void CopyPredefinedInstance(typename Types::Object from,
                              typename Types::Object to,
                              intptr_t cid) {
    if (IsImplicitFieldClassId(cid)) {
      CopyUserdefinedInstance(from, to);
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
      COPY_TO(LinkedHashMap)
      COPY_TO(LinkedHashSet)
#undef COPY_TO

#define COPY_TO(clazz) case kTypedData##clazz##Cid:

      CLASS_LIST_TYPED_DATA(COPY_TO) {
        typename Types::TypedData casted_from = Types::CastTypedData(from);
        typename Types::TypedData casted_to = Types::CastTypedData(to);
        CopyTypedData(casted_from, casted_to);
        return;
      }
#undef COPY_TO

      case kByteDataViewCid:
#define COPY_TO(clazz) case kTypedData##clazz##ViewCid:
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
    FATAL1("Unexpected object: %s\n", obj.ToCString());
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  void CopyUserdefinedInstanceAOT(typename Types::Object from,
                                  typename Types::Object to,
                                  UnboxedFieldBitmap bitmap) {
    const intptr_t instance_size = UntagObject(from)->HeapSize();
    Base::ForwardCompressedPointers(from, to, kWordSize, instance_size, bitmap);
  }
#endif

  void CopyUserdefinedInstance(typename Types::Object from,
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
        if (key->IsHeapObject()) {
          if (MightNeedReHashing(key)) {
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
      Base::EnqueueObjectToRehash(to);
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
    }
    Base::ForwardCompressedPointer(from, to,
                                   OFFSET_OF(UntaggedLinkedHashBase, data_));
    Base::StoreCompressedPointersNoBarrier(
        from, to, OFFSET_OF(UntaggedLinkedHashBase, used_data_),
        OFFSET_OF(UntaggedLinkedHashBase, used_data_));
    Base::StoreCompressedPointersNoBarrier(
        from, to, OFFSET_OF(UntaggedLinkedHashMap, deleted_keys_),
        OFFSET_OF(UntaggedLinkedHashMap, deleted_keys_));
  }

  void CopyLinkedHashMap(typename Types::LinkedHashMap from,
                         typename Types::LinkedHashMap to) {
    CopyLinkedHashBase<2, typename Types::LinkedHashMap>(
        from, to, UntagLinkedHashMap(from), UntagLinkedHashMap(to));
  }
  void CopyLinkedHashSet(typename Types::LinkedHashSet from,
                         typename Types::LinkedHashSet to) {
    CopyLinkedHashBase<1, typename Types::LinkedHashSet>(
        from, to, UntagLinkedHashSet(from), UntagLinkedHashSet(to));
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

  void CopyTypedData(typename Types::TypedData from,
                     typename Types::TypedData to) {
    auto raw_from = UntagTypedData(from);
    auto raw_to = UntagTypedData(to);
    const intptr_t cid = Types::GetTypedDataPtr(from)->GetClassId();
    raw_to->length_ = raw_from->length_;
    raw_to->RecomputeDataField();
    const intptr_t length =
        TypedData::ElementSizeInBytes(cid) * Smi::Value(raw_from->length_);
    memmove(raw_to->data_, raw_from->data_, length);
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

    if (raw_to->typed_data_.Decompress(Base::heap_base_) == Object::null()) {
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
      return;
    }
    Base::EnqueueTransferable(from, to);
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
  explicit FastObjectCopy(Thread* thread) : ObjectCopy(thread) {}
  ~FastObjectCopy() {}

  ObjectPtr TryCopyGraphFast(ObjectPtr root) {
    NoSafepointScope no_safepoint_scope;

    ObjectPtr root_copy = Forward(TagsFromUntaggedObject(root.untag()), root);
    if (root_copy == Marker()) {
      return root_copy;
    }
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
    }
    if (root_copy != Marker()) {
      TryBuildArrayOfObjectsToRehash();
    }
    return root_copy;
  }

  void TryBuildArrayOfObjectsToRehash() {
    const auto& objects_to_rehash = fast_forward_map_.raw_objects_to_rehash_;
    const intptr_t length = objects_to_rehash.length();
    if (length == 0) return;

    const intptr_t size = Array::InstanceSize(length);
    const uword array_addr = new_space_->TryAllocate(thread_, size);
    if (array_addr == 0) {
      exception_msg_ = kFastAllocationFailed;
      return;
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
    raw_objects_to_rehash_ = array;
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
                                  from.untag()->HeapSize() - kWordSize) = 0;
    SetNewSpaceTaggingWord(to, cid, size);

    // Fall back to virtual variant for predefined classes
    if (cid < kNumPredefinedCids && cid != kInstanceCid) {
      CopyPredefinedInstance(from, to, cid);
      return;
    }
#if defined(DART_PRECOMPILED_RUNTIME)
    const auto bitmap =
        class_table_->shared_class_table()->GetUnboxedFieldsMapAt(cid);
    CopyUserdefinedInstanceAOT(Instance::RawCast(from), Instance::RawCast(to),
                               bitmap);
#else
    CopyUserdefinedInstance(Instance::RawCast(from), Instance::RawCast(to));
#endif
  }

  ArrayPtr raw_objects_to_rehash_ = Array::null();
};

class SlowObjectCopy : public ObjectCopy<SlowObjectCopyBase> {
 public:
  explicit SlowObjectCopy(Thread* thread)
      : ObjectCopy(thread), objects_to_rehash_(Array::Handle(thread->zone())) {}
  ~SlowObjectCopy() {}

  ObjectPtr ContinueCopyGraphSlow(const Object& root,
                                  const Object& fast_root_copy) {
    auto& root_copy = Object::Handle(Z, fast_root_copy.ptr());
    if (root_copy.ptr() == Marker()) {
      root_copy = Forward(TagsFromUntaggedObject(root.ptr().untag()), root);
    }

    Object& from = Object::Handle(Z);
    Object& to = Object::Handle(Z);
    while (slow_forward_map_.fill_cursor_ <
           slow_forward_map_.from_to_.length()) {
      const intptr_t index = slow_forward_map_.fill_cursor_;
      from = slow_forward_map_.from_to_[index]->ptr();
      to = slow_forward_map_.from_to_[index + 1]->ptr();
      CopyObject(from, to);
      slow_forward_map_.fill_cursor_ += 2;
      if (exception_msg_ != nullptr) {
        return Marker();
      }
    }
    BuildArrayOfObjectsToRehash();
    return root_copy.ptr();
  }

  void BuildArrayOfObjectsToRehash() {
    const auto& objects_to_rehash = slow_forward_map_.objects_to_rehash_;
    const intptr_t length = objects_to_rehash.length();
    if (length == 0) return;

    objects_to_rehash_ = Array::New(length);
    for (intptr_t i = 0; i < length; ++i) {
      objects_to_rehash_.SetAt(i, *objects_to_rehash[i]);
    }
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
#if defined(DART_PRECOMPILED_RUNTIME)
    const auto bitmap =
        class_table_->shared_class_table()->GetUnboxedFieldsMapAt(cid);
    CopyUserdefinedInstanceAOT(from, to, bitmap);
#else
    CopyUserdefinedInstance(from, to);
#endif
  }

  Array& objects_to_rehash_;
};

class ObjectGraphCopier {
 public:
  explicit ObjectGraphCopier(Thread* thread)
      : thread_(thread),
        zone_(thread->zone()),
        fast_object_copy_(thread_),
        slow_object_copy_(thread_) {
    thread_->isolate()->set_forward_table_new(new WeakTable());
    thread_->isolate()->set_forward_table_old(new WeakTable());
  }
  ~ObjectGraphCopier() {
    thread_->isolate()->set_forward_table_new(nullptr);
    thread_->isolate()->set_forward_table_old(nullptr);
  }

  // Result will be [<msg>, <objects-in-msg-to-rehash>]
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
    if (result.ptr() == Marker()) {
      ASSERT(exception_msg != nullptr);
      ThrowException(exception_msg);
      UNREACHABLE();
    }

    // The copy was successful, then detach transferable data from the sender
    // and attach to the copied graph.
    slow_object_copy_.slow_forward_map_.FinalizeTransferables();
    return result.ptr();
  }

 private:
  ObjectPtr CopyObjectGraphInternal(const Object& root,
                                    const char* volatile* exception_msg) {
    const auto& result_array = Array::Handle(zone_, Array::New(2));
    if (!root.ptr()->IsHeapObject()) {
      result_array.SetAt(0, root);
      return result_array.ptr();
    }
    const uword tags = TagsFromUntaggedObject(root.ptr().untag());
    if (CanShareObject(tags)) {
      result_array.SetAt(0, root);
      return result_array.ptr();
    }
    if (!fast_object_copy_.CanCopyObject(tags, root.ptr())) {
      ASSERT(fast_object_copy_.exception_msg_ != nullptr);
      *exception_msg = fast_object_copy_.exception_msg_;
      return Marker();
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
            HandlifyExternalTypedData();
            HandlifyTransferables();
            return result_array.ptr();
          }

          // There are left-over uninitialized objects we'll have to make GC
          // visible.
          SwitchToSlowFowardingList();
        }
      }

      if (FLAG_gc_on_foc_slow_path) {
        // We use kLowMemory to force the GC to compact, which is more likely to
        // discover untracked pointers (and other issues, like incorrect class
        // table).
        thread_->heap()->CollectAllGarbage(Heap::kLowMemory);
      }

      // Fast copy failed due to
      //   - either failure to allocate into new space
      //   - or failure to copy object which we cannot copy
      ASSERT(fast_object_copy_.exception_msg_ != nullptr);
      if (fast_object_copy_.exception_msg_ != kFastAllocationFailed) {
        *exception_msg = fast_object_copy_.exception_msg_;
        return Marker();
      }
      ASSERT(fast_object_copy_.exception_msg_ == kFastAllocationFailed);
    }

    // Use the slow copy approach.
    result = slow_object_copy_.ContinueCopyGraphSlow(root, result);
    ASSERT((result.ptr() == Marker()) ==
           (slow_object_copy_.exception_msg_ != nullptr));
    if (result.ptr() == Marker()) {
      *exception_msg = slow_object_copy_.exception_msg_;
      return Marker();
    }

    result_array.SetAt(0, result);
    result_array.SetAt(1, slow_object_copy_.objects_to_rehash_);
    return result_array.ptr();
  }

  void SwitchToSlowFowardingList() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    auto& slow_forward_map = slow_object_copy_.slow_forward_map_;

    MakeUninitializedNewSpaceObjectsGCSafe();
    HandlifyTransferables();
    HandlifyExternalTypedData();
    HandlifyObjectsToReHash();
    HandlifyFromToObjects();
    slow_forward_map.fill_cursor_ = fast_forward_map.fill_cursor_;
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
      const intptr_t size = UntaggedObject::SizeTag::decode(tags);
      // External typed data is already initialized.
      if (!IsExternalTypedDataClassId(cid) && !IsTypedDataViewClassId(cid)) {
        memset(reinterpret_cast<void*>(to.untag()), 0,
               from.untag()->HeapSize());
        SetNewSpaceTaggingWord(to, cid, size);
        UpdateLengthField(cid, from, to);
      }
    }
  }
  void HandlifyTransferables() {
    auto& raw_transferables =
        fast_object_copy_.fast_forward_map_.raw_transferables_from_to_;
    const auto length = raw_transferables.length();
    if (length > 0) {
      auto& transferables =
          slow_object_copy_.slow_forward_map_.transferables_from_to_;
      transferables.Resize(length);
      for (intptr_t i = 0; i < length; i++) {
        transferables[i] =
            &TransferableTypedData::Handle(Z, raw_transferables[i]);
      }
      raw_transferables.Clear();
    }
  }
  void HandlifyExternalTypedData() {
    auto& raw_external_typed_data =
        fast_object_copy_.fast_forward_map_.raw_external_typed_data_to_;
    const auto length = raw_external_typed_data.length();
    if (length > 0) {
      auto& external_typed_data =
          slow_object_copy_.slow_forward_map_.external_typed_data_;
      external_typed_data.Resize(length);
      for (intptr_t i = 0; i < length; i++) {
        external_typed_data[i] =
            &ExternalTypedData::Handle(Z, raw_external_typed_data[i]);
      }
      raw_external_typed_data.Clear();
    }
  }
  void HandlifyObjectsToReHash() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    auto& slow_forward_map = slow_object_copy_.slow_forward_map_;
    const auto length = fast_forward_map.raw_transferables_from_to_.length();
    if (length > 0) {
      slow_forward_map.objects_to_rehash_.Resize(length);
      for (intptr_t i = 0; i < length; i++) {
        slow_forward_map.objects_to_rehash_[i] =
            &Object::Handle(Z, fast_forward_map.raw_objects_to_rehash_[i]);
      }
      fast_forward_map.raw_objects_to_rehash_.Clear();
    }
  }
  void HandlifyFromToObjects() {
    auto& fast_forward_map = fast_object_copy_.fast_forward_map_;
    auto& slow_forward_map = slow_object_copy_.slow_forward_map_;

    const intptr_t cursor = fast_forward_map.fill_cursor_;
    const intptr_t length = fast_forward_map.raw_from_to_.length();

    slow_forward_map.from_to_.Resize(length);
    for (intptr_t i = 2; i < length; i += 2) {
      slow_forward_map.from_to_[i] =
          i < cursor ? nullptr
                     : &Object::Handle(Z, fast_forward_map.raw_from_to_[i]);
      slow_forward_map.from_to_[i + 1] =
          &Object::Handle(Z, fast_forward_map.raw_from_to_[i + 1]);
    }
    fast_forward_map.raw_from_to_.Clear();
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
  FastObjectCopy fast_object_copy_;
  SlowObjectCopy slow_object_copy_;
};

ObjectPtr CopyMutableObjectGraph(const Object& object) {
  auto thread = Thread::Current();
  ObjectGraphCopier copier(thread);
  return copier.CopyObjectGraph(object);
}

}  // namespace dart
