// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/exceptions.h"
#include "vm/heap.h"
#include "vm/lockers.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot_ids.h"
#include "vm/symbols.h"
#include "vm/verified_memory.h"
#include "vm/version.h"

namespace dart {

static const int kNumInitialReferencesInFullSnapshot = 160 * KB;
static const int kNumInitialReferences = 64;


static bool IsSingletonClassId(intptr_t class_id) {
  // Check if this is a singleton object class which is shared by all isolates.
  return ((class_id >= kClassCid && class_id <= kUnwindErrorCid) ||
          (class_id >= kNullCid && class_id <= kVoidCid));
}


static bool IsObjectStoreClassId(intptr_t class_id) {
  // Check if this is a class which is stored in the object store.
  return (class_id == kObjectCid ||
          (class_id >= kInstanceCid && class_id <= kUserTagCid) ||
          class_id == kArrayCid || class_id == kImmutableArrayCid ||
          RawObject::IsStringClassId(class_id) ||
          RawObject::IsTypedDataClassId(class_id) ||
          RawObject::IsExternalTypedDataClassId(class_id) ||
          class_id == kNullCid);
}


static bool IsObjectStoreTypeId(intptr_t index) {
  // Check if this is a type which is stored in the object store.
  return (index >= kObjectType && index <= kArrayType);
}


static bool IsSplitClassId(intptr_t class_id) {
  // Return whether this class is serialized in two steps: first a reference,
  // with sufficient information to allocate a correctly sized object, and then
  // later inline with complete contents.
  return class_id >= kNumPredefinedCids ||
         class_id == kArrayCid ||
         class_id == kImmutableArrayCid ||
         RawObject::IsImplicitFieldClassId(class_id);
}


static intptr_t ClassIdFromObjectId(intptr_t object_id) {
  ASSERT(object_id > kClassIdsOffset);
  intptr_t class_id = (object_id - kClassIdsOffset);
  return class_id;
}


static intptr_t ObjectIdFromClassId(intptr_t class_id) {
  ASSERT((class_id > kIllegalCid) && (class_id < kNumPredefinedCids));
  ASSERT(!(RawObject::IsImplicitFieldClassId(class_id)));
  return (class_id + kClassIdsOffset);
}


static RawType* GetType(ObjectStore* object_store, intptr_t index) {
  switch (index) {
    case kObjectType: return object_store->object_type();
    case kNullType: return object_store->null_type();
    case kFunctionType: return object_store->function_type();
    case kNumberType: return object_store->number_type();
    case kSmiType: return object_store->smi_type();
    case kMintType: return object_store->mint_type();
    case kDoubleType: return object_store->double_type();
    case kIntType: return object_store->int_type();
    case kBoolType: return object_store->bool_type();
    case kStringType: return object_store->string_type();
    case kArrayType: return object_store->array_type();
    default: break;
  }
  UNREACHABLE();
  return Type::null();
}


static intptr_t GetTypeIndex(
    ObjectStore* object_store, const RawType* raw_type) {
  ASSERT(raw_type->IsHeapObject());
  if (raw_type == object_store->object_type()) {
    return kObjectType;
  } else if (raw_type == object_store->null_type()) {
    return kNullType;
  } else if (raw_type == object_store->function_type()) {
    return kFunctionType;
  } else if (raw_type == object_store->number_type()) {
    return kNumberType;
  } else if (raw_type == object_store->smi_type()) {
    return kSmiType;
  } else if (raw_type == object_store->mint_type()) {
    return kMintType;
  } else if (raw_type == object_store->double_type()) {
    return kDoubleType;
  } else if (raw_type == object_store->int_type()) {
    return kIntType;
  } else if (raw_type == object_store->bool_type()) {
    return kBoolType;
  } else if (raw_type == object_store->string_type()) {
    return kStringType;
  } else if (raw_type == object_store->array_type()) {
    return kArrayType;
  }
  return kInvalidIndex;
}


// TODO(5411462): Temporary setup of snapshot for testing purposes,
// the actual creation of a snapshot maybe done differently.
const Snapshot* Snapshot::SetupFromBuffer(const void* raw_memory) {
  ASSERT(raw_memory != NULL);
  ASSERT(kHeaderSize == sizeof(Snapshot));
  ASSERT(kLengthIndex == length_offset());
  ASSERT((kSnapshotFlagIndex * sizeof(int64_t)) == kind_offset());
  ASSERT((kHeapObjectTag & kInlined));
  // The kWatchedBit and kMarkBit are only set during GC operations. This
  // allows the two low bits in the header to be used for snapshotting.
  ASSERT(kObjectId ==
         ((1 << RawObject::kWatchedBit) | (1 << RawObject::kMarkBit)));
  ASSERT((kObjectAlignmentMask & kObjectId) == kObjectId);
  const Snapshot* snapshot = reinterpret_cast<const Snapshot*>(raw_memory);
  // If the raw length is negative or greater than what the local machine can
  // handle, then signal an error.
  int64_t snapshot_length = ReadUnaligned(&snapshot->unaligned_length_);
  if ((snapshot_length < 0) || (snapshot_length > kIntptrMax)) {
    return NULL;
  }
  return snapshot;
}


RawSmi* BaseReader::ReadAsSmi() {
  intptr_t value = Read<int32_t>();
  ASSERT((value & kSmiTagMask) == kSmiTag);
  return reinterpret_cast<RawSmi*>(value);
}


intptr_t BaseReader::ReadSmiValue() {
  return Smi::Value(ReadAsSmi());
}


SnapshotReader::SnapshotReader(const uint8_t* buffer,
                               intptr_t size,
                               Snapshot::Kind kind,
                               Isolate* isolate)
    : BaseReader(buffer, size),
      kind_(kind),
      isolate_(isolate),
      heap_(isolate->heap()),
      old_space_(isolate->heap()->old_space()),
      cls_(Class::Handle(isolate)),
      obj_(Object::Handle(isolate)),
      pobj_(PassiveObject::Handle(isolate)),
      array_(Array::Handle(isolate)),
      field_(Field::Handle(isolate)),
      str_(String::Handle(isolate)),
      library_(Library::Handle(isolate)),
      type_(AbstractType::Handle(isolate)),
      type_arguments_(TypeArguments::Handle(isolate)),
      tokens_(Array::Handle(isolate)),
      stream_(TokenStream::Handle(isolate)),
      data_(ExternalTypedData::Handle(isolate)),
      error_(UnhandledException::Handle(isolate)),
      backward_references_((kind == Snapshot::kFull) ?
                           kNumInitialReferencesInFullSnapshot :
                           kNumInitialReferences) {
}


RawObject* SnapshotReader::ReadObject() {
  // Setup for long jump in case there is an exception while reading.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    PassiveObject& obj = PassiveObject::Handle(isolate(), ReadObjectImpl());
    for (intptr_t i = 0; i < backward_references_.length(); i++) {
      if (!backward_references_[i].is_deserialized()) {
        ReadObjectImpl();
        backward_references_[i].set_state(kIsDeserialized);
      }
    }
    return obj.raw();
  } else {
    // An error occurred while reading, return the error object.
    const Error& err = Error::Handle(isolate()->object_store()->sticky_error());
    isolate()->object_store()->clear_sticky_error();
    return err.raw();
  }
}


RawClass* SnapshotReader::ReadClassId(intptr_t object_id) {
  ASSERT(kind_ != Snapshot::kFull);
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();
  ASSERT((class_header & kSmiTagMask) != kSmiTag);
  ASSERT(!IsVMIsolateObject(class_header) ||
         !IsSingletonClassId(GetVMIsolateObjectId(class_header)));
  ASSERT((SerializedHeaderTag::decode(class_header) != kObjectId) ||
         !IsObjectStoreClassId(SerializedHeaderData::decode(class_header)));
  Class& cls = Class::ZoneHandle(isolate(), Class::null());
  AddBackRef(object_id, &cls, kIsDeserialized);
  // Read the library/class information and lookup the class.
  str_ ^= ReadObjectImpl(class_header);
  library_ = Library::LookupLibrary(str_);
  ASSERT(!library_.IsNull());
  str_ ^= ReadObjectImpl();
  cls = library_.LookupClass(str_);
  cls.EnsureIsFinalized(isolate());
  ASSERT(!cls.IsNull());
  return cls.raw();
}


RawObject* SnapshotReader::ReadObjectImpl() {
  int64_t value = Read<int64_t>();
  if ((value & kSmiTagMask) == kSmiTag) {
    return NewInteger(value);
  }
  ASSERT((value <= kIntptrMax) && (value >= kIntptrMin));
  return ReadObjectImpl(static_cast<intptr_t>(value));
}


intptr_t SnapshotReader::NextAvailableObjectId() const {
  return backward_references_.length() + kMaxPredefinedObjectIds;
}


RawObject* SnapshotReader::ReadObjectImpl(intptr_t header_value) {
  if (IsVMIsolateObject(header_value)) {
    return ReadVMIsolateObject(header_value);
  } else {
    if (SerializedHeaderTag::decode(header_value) == kObjectId) {
      return ReadIndexedObject(SerializedHeaderData::decode(header_value));
    }
    ASSERT(SerializedHeaderTag::decode(header_value) == kInlined);
    intptr_t object_id = SerializedHeaderData::decode(header_value);
    if (object_id == kOmittedObjectId) {
      object_id = NextAvailableObjectId();
    }
    return ReadInlinedObject(object_id);
  }
}


RawObject* SnapshotReader::ReadObjectRef() {
  int64_t header_value = Read<int64_t>();
  if ((header_value & kSmiTagMask) == kSmiTag) {
    return NewInteger(header_value);
  }
  ASSERT((header_value <= kIntptrMax) && (header_value >= kIntptrMin));
  intptr_t value = static_cast<intptr_t>(header_value);
  if (IsVMIsolateObject(value)) {
    return ReadVMIsolateObject(value);
  } else if (SerializedHeaderTag::decode(value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(value));
  }
  ASSERT(SerializedHeaderTag::decode(value) == kInlined);
  intptr_t object_id = SerializedHeaderData::decode(value);
  if (object_id == kOmittedObjectId) {
    object_id = NextAvailableObjectId();
  }
  ASSERT(GetBackRef(object_id) == NULL);

  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();

  // Since we are only reading an object reference, If it is an instance kind
  // then we only need to figure out the class of the object and allocate an
  // instance of it. The individual fields will be read later.
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    Instance& result = Instance::ZoneHandle(isolate(), Instance::null());
    AddBackRef(object_id, &result, kIsNotDeserialized);

    cls_ ^= ReadObjectImpl();  // Read class information.
    ASSERT(!cls_.IsNull());
    intptr_t instance_size = cls_.instance_size();
    ASSERT(instance_size > 0);
    if (kind_ == Snapshot::kFull) {
      result ^= AllocateUninitialized(cls_.id(), instance_size);
    } else {
      result ^= Object::Allocate(cls_.id(), instance_size, HEAP_SPACE(kind_));
    }
    return result.raw();
  }
  ASSERT((class_header & kSmiTagMask) != kSmiTag);

  // Similarly Array and ImmutableArray objects are also similarly only
  // allocated here, the individual array elements are read later.
  intptr_t class_id = LookupInternalClass(class_header);
  if (class_id == kArrayCid) {
    // Read the length and allocate an object based on the len.
    intptr_t len = ReadSmiValue();
    Array& array = Array::ZoneHandle(
        isolate(),
        ((kind_ == Snapshot::kFull) ?
         NewArray(len) : Array::New(len, HEAP_SPACE(kind_))));
    AddBackRef(object_id, &array, kIsNotDeserialized);

    return array.raw();
  }
  if (class_id == kImmutableArrayCid) {
    // Read the length and allocate an object based on the len.
    intptr_t len = ReadSmiValue();
    Array& array = Array::ZoneHandle(
        isolate(),
        (kind_ == Snapshot::kFull) ?
        NewImmutableArray(len) : ImmutableArray::New(len, HEAP_SPACE(kind_)));
    AddBackRef(object_id, &array, kIsNotDeserialized);

    return array.raw();
  }

  // For all other internal VM classes we read the object inline.
  intptr_t tags = ReadTags();
  switch (class_id) {
#define SNAPSHOT_READ(clazz)                                                   \
    case clazz::kClassId: {                                                    \
      pobj_ = clazz::ReadFrom(this, object_id, tags, kind_);                   \
      break;                                                                   \
    }
    CLASS_LIST_NO_OBJECT(SNAPSHOT_READ)
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz)                                                   \
    case kTypedData##clazz##Cid:                                               \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ = TypedData::ReadFrom(this, object_id, tags, kind_);
      break;
    }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz)                                                   \
    case kExternalTypedData##clazz##Cid:                                       \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ = ExternalTypedData::ReadFrom(this, object_id, tags, kind_);
      break;
    }
#undef SNAPSHOT_READ
    default: UNREACHABLE(); break;
  }
  if (kind_ == Snapshot::kFull) {
    pobj_.SetCreatedFromSnapshot();
  }
  return pobj_.raw();
}


void SnapshotReader::AddBackRef(intptr_t id,
                                Object* obj,
                                DeserializeState state) {
  intptr_t index = (id - kMaxPredefinedObjectIds);
  ASSERT(index == backward_references_.length());
  BackRefNode node(obj, state);
  backward_references_.Add(node);
}


Object* SnapshotReader::GetBackRef(intptr_t id) {
  ASSERT(id >= kMaxPredefinedObjectIds);
  intptr_t index = (id - kMaxPredefinedObjectIds);
  if (index < backward_references_.length()) {
    return backward_references_[index].reference();
  }
  return NULL;
}


class HeapLocker : public StackResource {
 public:
  HeapLocker(Isolate* isolate, PageSpace* page_space)
      : StackResource(isolate), page_space_(page_space) {
        page_space_->AcquireDataLock();
  }
  ~HeapLocker() {
    page_space_->ReleaseDataLock();
  }

 private:
  PageSpace* page_space_;
};


RawApiError* SnapshotReader::ReadFullSnapshot() {
  ASSERT(kind_ == Snapshot::kFull);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ObjectStore* object_store = isolate->object_store();
  ASSERT(object_store != NULL);

  // First read the version string, and check that it matches.
  RawApiError* error = VerifyVersion();
  if (error != ApiError::null()) {
    return error;
  }

  // The version string matches. Read the rest of the snapshot.

  // TODO(asiva): Add a check here to ensure we have the right heap
  // size for the full snapshot being read.
  {
    NoGCScope no_gc;
    HeapLocker hl(isolate, old_space());

    // Read in all the objects stored in the object store.
    intptr_t num_flds = (object_store->to() - object_store->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      *(object_store->from() + i) = ReadObjectImpl();
    }
    for (intptr_t i = 0; i < backward_references_.length(); i++) {
      if (!backward_references_[i].is_deserialized()) {
        ReadObjectImpl();
        backward_references_[i].set_state(kIsDeserialized);
      }
    }

    // Validate the class table.
#if defined(DEBUG)
    isolate->ValidateClassTable();
#endif

    // Setup native resolver for bootstrap impl.
    Bootstrap::SetupNativeResolver();
    return ApiError::null();
  }
}


RawObject* SnapshotReader::ReadScriptSnapshot() {
  ASSERT(kind_ == Snapshot::kScript);

  // First read the version string, and check that it matches.
  RawApiError* error = VerifyVersion();
  if (error != ApiError::null()) {
    return error;
  }

  // The version string matches. Read the rest of the snapshot.
  obj_ = ReadObject();
  if (!obj_.IsLibrary()) {
    if (!obj_.IsError()) {
      const intptr_t kMessageBufferSize = 128;
      char message_buffer[kMessageBufferSize];
      OS::SNPrint(message_buffer,
                  kMessageBufferSize,
                  "Invalid object %s found in script snapshot",
                  obj_.ToCString());
      const String& msg = String::Handle(String::New(message_buffer));
      obj_ = ApiError::New(msg);
    }
  }
  return obj_.raw();
}


RawApiError* SnapshotReader::VerifyVersion() {
  // If the version string doesn't match, return an error.
  // Note: New things are allocated only if we're going to return an error.

  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  if (PendingBytes() < version_len) {
    const intptr_t kMessageBufferSize = 128;
    char message_buffer[kMessageBufferSize];
    OS::SNPrint(message_buffer,
                kMessageBufferSize,
                "No full snapshot version found, expected '%s'",
                Version::SnapshotString());
    const String& msg = String::Handle(String::New(message_buffer));
    return ApiError::New(msg);
  }

  const char* version = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(version != NULL);
  if (strncmp(version, expected_version, version_len)) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_version = OS::StrNDup(version, version_len);
    OS::SNPrint(message_buffer,
                kMessageBufferSize,
                "Wrong %s snapshot version, expected '%s' found '%s'",
                (kind_ == Snapshot::kFull) ? "full" : "script",
                Version::SnapshotString(),
                actual_version);
    free(actual_version);
    const String& msg = String::Handle(String::New(message_buffer));
    return ApiError::New(msg);
  }
  Advance(version_len);
  return ApiError::null();
}


#define ALLOC_NEW_OBJECT_WITH_LEN(type, length)                                \
  ASSERT(kind_ == Snapshot::kFull);                                            \
  ASSERT(isolate()->no_gc_scope_depth() != 0);                                 \
  Raw##type* obj = reinterpret_cast<Raw##type*>(                               \
      AllocateUninitialized(k##type##Cid, type::InstanceSize(length)));        \
  obj->StoreSmi(&(obj->ptr()->length_), Smi::New(length));                     \
  return obj;                                                                  \


RawArray* SnapshotReader::NewArray(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(Array, len);
}


RawImmutableArray* SnapshotReader::NewImmutableArray(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(ImmutableArray, len);
}


RawOneByteString* SnapshotReader::NewOneByteString(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(OneByteString, len);
}


RawTwoByteString* SnapshotReader::NewTwoByteString(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(TwoByteString, len);
}


RawTypeArguments* SnapshotReader::NewTypeArguments(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(TypeArguments, len);
}


RawTokenStream* SnapshotReader::NewTokenStream(intptr_t len) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  stream_ = reinterpret_cast<RawTokenStream*>(
      AllocateUninitialized(kTokenStreamCid, TokenStream::InstanceSize()));
  uint8_t* array = const_cast<uint8_t*>(CurrentBufferAddress());
  ASSERT(array != NULL);
  Advance(len);
  data_ = reinterpret_cast<RawExternalTypedData*>(
      AllocateUninitialized(kExternalTypedDataUint8ArrayCid,
                            ExternalTypedData::InstanceSize()));
  data_.SetData(array);
  data_.SetLength(len);
  stream_.SetStream(data_);
  return stream_.raw();
}


RawContext* SnapshotReader::NewContext(intptr_t num_variables) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawContext* obj = reinterpret_cast<RawContext*>(
      AllocateUninitialized(kContextCid, Context::InstanceSize(num_variables)));
  obj->ptr()->num_variables_ = num_variables;
  return obj;
}


RawClass* SnapshotReader::NewClass(intptr_t class_id) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  if (class_id < kNumPredefinedCids) {
    ASSERT((class_id >= kInstanceCid) &&
           (class_id <= kNullCid));
    return isolate()->class_table()->At(class_id);
  }
  RawClass* obj = reinterpret_cast<RawClass*>(
      AllocateUninitialized(kClassCid, Class::InstanceSize()));
  Instance fake;
  obj->ptr()->handle_vtable_ = fake.vtable();
  cls_ = obj;
  cls_.set_id(class_id);
  isolate()->RegisterClassAt(class_id, cls_);
  return cls_.raw();
}


RawInstance* SnapshotReader::NewInstance() {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawInstance* obj = reinterpret_cast<RawInstance*>(
      AllocateUninitialized(kObjectCid, Instance::InstanceSize()));
  return obj;
}


RawMint* SnapshotReader::NewMint(int64_t value) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawMint* obj = reinterpret_cast<RawMint*>(
      AllocateUninitialized(kMintCid, Mint::InstanceSize()));
  obj->ptr()->value_ = value;
  return obj;
}


RawDouble* SnapshotReader::NewDouble(double value) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawDouble* obj = reinterpret_cast<RawDouble*>(
      AllocateUninitialized(kDoubleCid, Double::InstanceSize()));
  obj->ptr()->value_ = value;
  return obj;
}


RawTypedData* SnapshotReader::NewTypedData(intptr_t class_id, intptr_t len) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  const intptr_t lengthInBytes = len * TypedData::ElementSizeInBytes(class_id);
  RawTypedData* obj = reinterpret_cast<RawTypedData*>(
      AllocateUninitialized(class_id, TypedData::InstanceSize(lengthInBytes)));
  obj->StoreSmi(&(obj->ptr()->length_), Smi::New(len));
  return obj;
}


#define ALLOC_NEW_OBJECT(type)                                                 \
  ASSERT(kind_ == Snapshot::kFull);                                            \
  ASSERT(isolate()->no_gc_scope_depth() != 0);                                 \
  return reinterpret_cast<Raw##type*>(                                         \
      AllocateUninitialized(k##type##Cid, type::InstanceSize()));              \


RawBigint* SnapshotReader::NewBigint() {
  ALLOC_NEW_OBJECT(Bigint);
}


RawUnresolvedClass* SnapshotReader::NewUnresolvedClass() {
  ALLOC_NEW_OBJECT(UnresolvedClass);
}


RawType* SnapshotReader::NewType() {
  ALLOC_NEW_OBJECT(Type);
}


RawTypeRef* SnapshotReader::NewTypeRef() {
  ALLOC_NEW_OBJECT(TypeRef);
}


RawTypeParameter* SnapshotReader::NewTypeParameter() {
  ALLOC_NEW_OBJECT(TypeParameter);
}


RawBoundedType* SnapshotReader::NewBoundedType() {
  ALLOC_NEW_OBJECT(BoundedType);
}


RawMixinAppType* SnapshotReader::NewMixinAppType() {
  ALLOC_NEW_OBJECT(MixinAppType);
}


RawPatchClass* SnapshotReader::NewPatchClass() {
  ALLOC_NEW_OBJECT(PatchClass);
}


RawClosureData* SnapshotReader::NewClosureData() {
  ALLOC_NEW_OBJECT(ClosureData);
}


RawRedirectionData* SnapshotReader::NewRedirectionData() {
  ALLOC_NEW_OBJECT(RedirectionData);
}


RawFunction* SnapshotReader::NewFunction() {
  ALLOC_NEW_OBJECT(Function);
}


RawField* SnapshotReader::NewField() {
  ALLOC_NEW_OBJECT(Field);
}


RawLibrary* SnapshotReader::NewLibrary() {
  ALLOC_NEW_OBJECT(Library);
}


RawLibraryPrefix* SnapshotReader::NewLibraryPrefix() {
  ALLOC_NEW_OBJECT(LibraryPrefix);
}


RawNamespace* SnapshotReader::NewNamespace() {
  ALLOC_NEW_OBJECT(Namespace);
}


RawScript* SnapshotReader::NewScript() {
  ALLOC_NEW_OBJECT(Script);
}


RawLiteralToken* SnapshotReader::NewLiteralToken() {
  ALLOC_NEW_OBJECT(LiteralToken);
}


RawGrowableObjectArray* SnapshotReader::NewGrowableObjectArray() {
  ALLOC_NEW_OBJECT(GrowableObjectArray);
}


RawFloat32x4* SnapshotReader::NewFloat32x4(float v0, float v1, float v2,
                                           float v3) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawFloat32x4* obj = reinterpret_cast<RawFloat32x4*>(
      AllocateUninitialized(kFloat32x4Cid, Float32x4::InstanceSize()));
  obj->ptr()->value_[0] = v0;
  obj->ptr()->value_[1] = v1;
  obj->ptr()->value_[2] = v2;
  obj->ptr()->value_[3] = v3;
  return obj;
}


RawInt32x4* SnapshotReader::NewInt32x4(uint32_t v0, uint32_t v1, uint32_t v2,
                                       uint32_t v3) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawInt32x4* obj = reinterpret_cast<RawInt32x4*>(
      AllocateUninitialized(kInt32x4Cid, Int32x4::InstanceSize()));
  obj->ptr()->value_[0] = v0;
  obj->ptr()->value_[1] = v1;
  obj->ptr()->value_[2] = v2;
  obj->ptr()->value_[3] = v3;
  return obj;
}


RawFloat64x2* SnapshotReader::NewFloat64x2(double v0, double v1) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  RawFloat64x2* obj = reinterpret_cast<RawFloat64x2*>(
      AllocateUninitialized(kFloat64x2Cid, Float64x2::InstanceSize()));
  obj->ptr()->value_[0] = v0;
  obj->ptr()->value_[1] = v1;
  return obj;
}


RawApiError* SnapshotReader::NewApiError() {
  ALLOC_NEW_OBJECT(ApiError);
}


RawLanguageError* SnapshotReader::NewLanguageError() {
  ALLOC_NEW_OBJECT(LanguageError);
}


RawUnhandledException* SnapshotReader::NewUnhandledException() {
  ALLOC_NEW_OBJECT(UnhandledException);
}


RawObject* SnapshotReader::NewInteger(int64_t value) {
  ASSERT((value & kSmiTagMask) == kSmiTag);
  value = value >> kSmiTagShift;
  if (Smi::IsValid(value)) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  if (kind_ == Snapshot::kFull) {
    return NewMint(value);
  }
  return Mint::NewCanonical(value);
}


RawStacktrace* SnapshotReader::NewStacktrace() {
  ALLOC_NEW_OBJECT(Stacktrace);
}


intptr_t SnapshotReader::LookupInternalClass(intptr_t class_header) {
  // If the header is an object Id, lookup singleton VM classes or classes
  // stored in the object store.
  if (IsVMIsolateObject(class_header)) {
    intptr_t class_id = GetVMIsolateObjectId(class_header);
    ASSERT(IsSingletonClassId(class_id));
    return class_id;
  }
  ASSERT(SerializedHeaderTag::decode(class_header) == kObjectId);
  intptr_t class_id = SerializedHeaderData::decode(class_header);
  ASSERT(IsObjectStoreClassId(class_id));
  return class_id;
}


RawObject* SnapshotReader::AllocateUninitialized(intptr_t class_id,
                                                 intptr_t size) {
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));

  uword address =
      old_space()->TryAllocateDataBumpLocked(size, PageSpace::kForceGrowth);
  if (address == 0) {
    // Use the preallocated out of memory exception to avoid calling
    // into dart code or allocating any code.
    // We do a longjmp at this point to unwind out of the entire
    // read part and return the error object back.
    const UnhandledException& error = UnhandledException::Handle(
        object_store()->preallocated_unhandled_exception());
    Isolate::Current()->long_jump_base()->Jump(1, error);
  }
#if defined(DEBUG)
  // Zap the uninitialized memory area.
  uword current = address;
  uword end = address + size;
  while (current < end) {
    *reinterpret_cast<intptr_t*>(current) = kZapUninitializedWord;
    current += kWordSize;
  }
#endif  // defined(DBEUG)
  // Make sure to initialize the last word, as this can be left untouched in
  // case the object deserialized has an alignment tail.
  *reinterpret_cast<RawObject**>(address + size - kWordSize) = Object::null();
  VerifiedMemory::Accept(address, size);

  RawObject* raw_obj = reinterpret_cast<RawObject*>(address + kHeapObjectTag);
  uword tags = 0;
  ASSERT(class_id != kIllegalCid);
  tags = RawObject::ClassIdTag::update(class_id, tags);
  tags = RawObject::SizeTag::update(size, tags);
  raw_obj->ptr()->tags_ = tags;
  return raw_obj;
}


RawObject* SnapshotReader::ReadVMIsolateObject(intptr_t header_value) {
  intptr_t object_id = GetVMIsolateObjectId(header_value);
  if (object_id == kNullObject) {
    // This is a singleton null object, return it.
    return Object::null();
  }
  if (object_id == kSentinelObject) {
    return Object::sentinel().raw();
  }
  if (object_id == kEmptyArrayObject) {
    return Object::empty_array().raw();
  }
  if (object_id == kZeroArrayObject) {
    return Object::zero_array().raw();
  }
  if (object_id == kDynamicType) {
    return Object::dynamic_type();
  }
  if (object_id == kVoidType) {
    return Object::void_type();
  }
  if (object_id == kTrueValue) {
    return Bool::True().raw();
  }
  if (object_id == kFalseValue) {
    return Bool::False().raw();
  }
  if (object_id == kDoubleObject) {
    ASSERT(kind_ == Snapshot::kMessage);
    return Double::New(ReadDouble());
  }
  intptr_t class_id = ClassIdFromObjectId(object_id);
  if (IsSingletonClassId(class_id)) {
    return isolate()->class_table()->At(class_id);  // get singleton class.
  } else {
    ASSERT(Symbols::IsVMSymbolId(object_id));
    return Symbols::GetVMSymbol(object_id);  // return VM symbol.
  }
  UNREACHABLE();
  return Object::null();
}


RawObject* SnapshotReader::ReadIndexedObject(intptr_t object_id) {
  intptr_t class_id = ClassIdFromObjectId(object_id);
  if (IsObjectStoreClassId(class_id)) {
    return isolate()->class_table()->At(class_id);  // get singleton class.
  }
  if (kind_ != Snapshot::kFull) {
    if (IsObjectStoreTypeId(object_id)) {
      return GetType(object_store(), object_id);  // return type obj.
    }
  }
  Object* object = GetBackRef(object_id);
  return object->raw();
}


RawObject* SnapshotReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();
  intptr_t tags = ReadTags();
  if (SerializedHeaderData::decode(class_header) == kInstanceObjectId) {
    // Object is regular dart instance.
    Instance* result = reinterpret_cast<Instance*>(GetBackRef(object_id));
    intptr_t instance_size = 0;
    if (result == NULL) {
      result = &(Instance::ZoneHandle(isolate(), Instance::null()));
      AddBackRef(object_id, result, kIsDeserialized);
      cls_ ^= ReadObjectImpl();
      ASSERT(!cls_.IsNull());
      instance_size = cls_.instance_size();
      ASSERT(instance_size > 0);
      // Allocate the instance and read in all the fields for the object.
      if (kind_ == Snapshot::kFull) {
        *result ^= AllocateUninitialized(cls_.id(), instance_size);
      } else {
        *result ^= Object::Allocate(cls_.id(),
                                    instance_size,
                                    HEAP_SPACE(kind_));
      }
    } else {
      cls_ ^= ReadObjectImpl();
      ASSERT(!cls_.IsNull());
      instance_size = cls_.instance_size();
    }
    intptr_t next_field_offset = cls_.next_field_offset();
    intptr_t type_argument_field_offset = cls_.type_arguments_field_offset();
    ASSERT(next_field_offset > 0);
    // Instance::NextFieldOffset() returns the offset of the first field in
    // a Dart object.
    intptr_t offset = Instance::NextFieldOffset();
    intptr_t result_cid = result->GetClassId();
    while (offset < next_field_offset) {
      pobj_ = ReadObjectRef();
      result->SetFieldAtOffset(offset, pobj_);
      if ((offset != type_argument_field_offset) &&
          (kind_ == Snapshot::kMessage)) {
        // TODO(fschneider): Consider hoisting these lookups out of the loop.
        // This would involve creating a handle, since cls_ can't be reused
        // across the call to ReadObjectRef.
        cls_ = isolate()->class_table()->At(result_cid);
        array_ = cls_.OffsetToFieldMap();
        field_ ^= array_.At(offset >> kWordSizeLog2);
        ASSERT(!field_.IsNull());
        ASSERT(field_.Offset() == offset);
        obj_ = pobj_.raw();
        field_.RecordStore(obj_);
      }
      // TODO(fschneider): Verify the guarded cid and length for other kinds of
      // snapshot (kFull, kScript) with asserts.
      offset += kWordSize;
    }
    if (kind_ == Snapshot::kFull) {
      // We create an uninitialized object in the case of full snapshots, so
      // we need to initialize any remaining padding area with the Null object.
      while (offset < instance_size) {
        result->SetFieldAtOffset(offset, Object::null_object());
        offset += kWordSize;
      }
      result->SetCreatedFromSnapshot();
    } else if (false && RawObject::IsCanonical(tags)) {
      *result = result->CheckAndCanonicalize(NULL);
      ASSERT(!result->IsNull());
    }
    return result->raw();
  }
  ASSERT((class_header & kSmiTagMask) != kSmiTag);
  intptr_t class_id = LookupInternalClass(class_header);
  switch (class_id) {
#define SNAPSHOT_READ(clazz)                                                   \
    case clazz::kClassId: {                                                    \
      pobj_ = clazz::ReadFrom(this, object_id, tags, kind_);                   \
      break;                                                                   \
    }
    CLASS_LIST_NO_OBJECT(SNAPSHOT_READ)
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz)                                                   \
    case kTypedData##clazz##Cid:                                               \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ = TypedData::ReadFrom(this, object_id, tags, kind_);
      break;
    }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz)                                                   \
    case kExternalTypedData##clazz##Cid:                                       \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ = ExternalTypedData::ReadFrom(this, object_id, tags, kind_);
      break;
    }
#undef SNAPSHOT_READ
    default: UNREACHABLE(); break;
  }
  if (kind_ == Snapshot::kFull) {
    pobj_.SetCreatedFromSnapshot();
  }
  return pobj_.raw();
}


void SnapshotReader::ArrayReadFrom(const Array& result,
                                   intptr_t len,
                                   intptr_t tags) {
  // Set the object tags.
  result.set_tags(tags);

  // Setup the object fields.
  *TypeArgumentsHandle() ^= ReadObjectImpl();
  result.SetTypeArguments(*TypeArgumentsHandle());

  for (intptr_t i = 0; i < len; i++) {
    *PassiveObjectHandle() = ReadObjectRef();
    result.SetAt(i, *PassiveObjectHandle());
  }
}


SnapshotWriter::SnapshotWriter(Snapshot::Kind kind,
                               uint8_t** buffer,
                               ReAlloc alloc,
                               intptr_t initial_size)
    : BaseWriter(buffer, alloc, initial_size),
      kind_(kind),
      isolate_(Isolate::Current()),
      object_store_(isolate_->object_store()),
      class_table_(isolate_->class_table()),
      forward_list_(kMaxPredefinedObjectIds),
      exception_type_(Exceptions::kNone),
      exception_msg_(NULL) {
}


void SnapshotWriter::WriteObject(RawObject* rawobj) {
  WriteObjectImpl(rawobj);
  WriteForwardedObjects();
}


void SnapshotWriter::HandleVMIsolateObject(RawObject* rawobj) {
  // Check if it is a singleton null object.
  if (rawobj == Object::null()) {
    WriteVMIsolateObject(kNullObject);
    return;
  }

  // Check if it is a singleton sentinel object.
  if (rawobj == Object::sentinel().raw()) {
    WriteVMIsolateObject(kSentinelObject);
    return;
  }

  // Check if it is a singleton empty array object.
  if (rawobj == Object::empty_array().raw()) {
    WriteVMIsolateObject(kEmptyArrayObject);
    return;
  }

  // Check if it is a singleton zero array object.
  if (rawobj == Object::zero_array().raw()) {
    WriteVMIsolateObject(kZeroArrayObject);
    return;
  }

  // Check if it is a singleton dyanmic Type object.
  if (rawobj == Object::dynamic_type()) {
    WriteVMIsolateObject(kDynamicType);
    return;
  }

  // Check if it is a singleton void Type object.
  if (rawobj == Object::void_type()) {
    WriteVMIsolateObject(kVoidType);
    return;
  }

  // Check if it is a singleton boolean true object.
  if (rawobj == Bool::True().raw()) {
    WriteVMIsolateObject(kTrueValue);
    return;
  }

  // Check if it is a singleton boolean false object.
  if (rawobj == Bool::False().raw()) {
    WriteVMIsolateObject(kFalseValue);
    return;
  }

  // Check if it is a singleton class object which is shared by
  // all isolates.
  intptr_t id = rawobj->GetClassId();
  if (id == kClassCid) {
    RawClass* raw_class = reinterpret_cast<RawClass*>(rawobj);
    intptr_t class_id = raw_class->ptr()->id_;
    if (IsSingletonClassId(class_id)) {
      intptr_t object_id = ObjectIdFromClassId(class_id);
      WriteVMIsolateObject(object_id);
      return;
    }
  }


  // Check it is a predefined symbol in the VM isolate.
  id = Symbols::LookupVMSymbol(rawobj);
  if (id != kInvalidIndex) {
    WriteVMIsolateObject(id);
    return;
  }

  UNREACHABLE();
}


void SnapshotWriter::WriteObjectRef(RawObject* raw) {
  // First check if object can be written as a simple predefined type.
  if (CheckAndWritePredefinedObject(raw)) {
    return;
  }

  NoGCScope no_gc;
  RawClass* cls = class_table_->At(raw->GetClassId());
  intptr_t class_id = cls->ptr()->id_;
  ASSERT(class_id == raw->GetClassId());
  if (class_id >= kNumPredefinedCids) {
    WriteInstanceRef(raw, cls);
    return;
  }
  if (class_id == kArrayCid) {
    // Object is being referenced, add it to the forward ref list and mark
    // it so that future references to this object in the snapshot will use
    // this object id. Mark it as not having been serialized yet so that we
    // will serialize the object when we go through the forward list.
    forward_list_.MarkAndAddObject(raw, kIsNotSerialized);

    RawArray* rawarray = reinterpret_cast<RawArray*>(raw);

    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(kOmittedObjectId);

    // Write out the class information.
    WriteIndexedObject(kArrayCid);

    // Write out the length field.
    Write<RawObject*>(rawarray->ptr()->length_);

    return;
  }
  if (class_id == kImmutableArrayCid) {
    // Object is being referenced, add it to the forward ref list and mark
    // it so that future references to this object in the snapshot will use
    // this object id. Mark it as not having been serialized yet so that we
    // will serialize the object when we go through the forward list.
    forward_list_.MarkAndAddObject(raw, kIsNotSerialized);

    RawArray* rawarray = reinterpret_cast<RawArray*>(raw);

    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(kOmittedObjectId);

    // Write out the class information.
    WriteIndexedObject(kImmutableArrayCid);

    // Write out the length field.
    Write<RawObject*>(rawarray->ptr()->length_);

    return;
  }
  if (RawObject::IsImplicitFieldClassId(class_id)) {
    WriteInstanceRef(raw, cls);
    return;
  }
  // Object is being referenced, add it to the forward ref list and mark
  // it so that future references to this object in the snapshot will use
  // this object id. Mark it as not having been serialized yet so that we
  // will serialize the object when we go through the forward list.
  forward_list_.MarkAndAddObject(raw, kIsSerialized);
  switch (class_id) {
#define SNAPSHOT_WRITE(clazz)                                                  \
    case clazz::kClassId: {                                                    \
      Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(raw);                \
      raw_obj->WriteTo(this, kOmittedObjectId, kind_);                         \
      return;                                                                  \
    }                                                                          \

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz)                                                  \
    case kTypedData##clazz##Cid:                                               \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawTypedData* raw_obj = reinterpret_cast<RawTypedData*>(raw);
      raw_obj->WriteTo(this, kOmittedObjectId, kind_);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz)                                                  \
    case kExternalTypedData##clazz##Cid:                                       \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawExternalTypedData* raw_obj =
        reinterpret_cast<RawExternalTypedData*>(raw);
      raw_obj->WriteTo(this, kOmittedObjectId, kind_);
      return;
    }
#undef SNAPSHOT_WRITE
    default: break;
  }
  UNREACHABLE();
}


void FullSnapshotWriter::WriteFullSnapshot() {
  ASSERT(isolate() != NULL);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Ensure the class table is valid.
#if defined(DEBUG)
  isolate()->ValidateClassTable();
#endif

  // Setup for long jump in case there is an exception while writing
  // the snapshot.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Reserve space in the output buffer for a snapshot header.
    ReserveHeader();

    // Write out the version string.
    WriteVersion();

    // Write out the full snapshot.
    {
      NoGCScope no_gc;

      // Write out all the objects in the object store of the isolate which
      // is the root set for all dart allocated objects at this point.
      SnapshotWriterVisitor visitor(this, false);
      object_store->VisitObjectPointers(&visitor);

      // Write out all forwarded objects.
      WriteForwardedObjects();

      FillHeader(kind());
      UnmarkAll();
    }
  } else {
    ThrowException(exception_type(), exception_msg());
  }
}


uword SnapshotWriter::GetObjectTags(RawObject* raw) {
  uword tags = raw->ptr()->tags_;
  if (SerializedHeaderTag::decode(tags) == kObjectId) {
    intptr_t id = SerializedHeaderData::decode(tags);
    return forward_list_.NodeForObjectId(id)->tags();
  } else {
    return tags;
  }
}


ForwardList::ForwardList(intptr_t first_object_id)
    : first_object_id_(first_object_id),
      nodes_(),
      first_unprocessed_object_id_(first_object_id) {
  // The ForwardList encodes information in the header tag word. There cannot
  // be any concurrent GC tasks while it is in use.
  PageSpace* page_space = Isolate::Current()->heap()->old_space();
  MonitorLocker ml(page_space->tasks_lock());
  while (page_space->tasks() > 0) {
    ml.Wait();
  }
  page_space->set_tasks(1);
}


ForwardList::~ForwardList() {
  PageSpace* page_space = Isolate::Current()->heap()->old_space();
  MonitorLocker ml(page_space->tasks_lock());
  ASSERT(page_space->tasks() == 1);
  page_space->set_tasks(0);
  ml.Notify();
}


intptr_t ForwardList::MarkAndAddObject(RawObject* raw, SerializeState state) {
  NoGCScope no_gc;
  intptr_t object_id = next_object_id();
  ASSERT(object_id <= kMaxObjectId);
  uword value = 0;
  value = SerializedHeaderTag::update(kObjectId, value);
  value = SerializedHeaderData::update(object_id, value);
  uword tags = raw->ptr()->tags_;
  ASSERT(SerializedHeaderTag::decode(tags) != kObjectId);
  raw->ptr()->tags_ = value;
  Node* node = new Node(raw, tags, state);
  ASSERT(node != NULL);
  nodes_.Add(node);
  return object_id;
}


void ForwardList::UnmarkAll() const {
  NoGCScope no_gc;
  for (intptr_t id = first_object_id(); id < next_object_id(); ++id) {
    const Node* node = NodeForObjectId(id);
    RawObject* raw = node->raw();
    raw->ptr()->tags_ = node->tags();  // Restore original tags.
  }
}


bool SnapshotWriter::CheckAndWritePredefinedObject(RawObject* rawobj) {
  // Check if object can be written in one of the following ways:
  // - Smi: the Smi value is written as is (last bit is not tagged).
  // - VM internal class (from VM isolate): (index of class in vm isolate | 0x3)
  // - Object that has already been written: (negative id in stream | 0x3)

  NoGCScope no_gc;

  // First check if it is a Smi (i.e not a heap object).
  if (!rawobj->IsHeapObject()) {
    Write<int64_t>(reinterpret_cast<intptr_t>(rawobj));
    return true;
  }

  intptr_t cid = rawobj->GetClassId();

  if ((kind_ == Snapshot::kMessage) && (cid == kDoubleCid)) {
    WriteVMIsolateObject(kDoubleObject);
    RawDouble* rd = reinterpret_cast<RawDouble*>(rawobj);
    WriteDouble(rd->ptr()->value_);
    return true;
  }

  // Check if object has already been serialized, in that case just write
  // the object id out.
  uword tags = rawobj->ptr()->tags_;
  if (SerializedHeaderTag::decode(tags) == kObjectId) {
    intptr_t id = SerializedHeaderData::decode(tags);
    WriteIndexedObject(id);
    return true;
  }

  // Now check if it is an object from the VM isolate (NOTE: premarked objects
  // are considered to be objects in the VM isolate). These objects are shared
  // by all isolates.
  if (rawobj->IsVMHeapObject()) {
    HandleVMIsolateObject(rawobj);
    return true;
  }

  // Check if the object is a Mint and could potentially be a Smi
  // on other architectures (64 bit), if so write it out as int64_t value.
  if (cid == kMintCid) {
    int64_t value = reinterpret_cast<RawMint*>(rawobj)->ptr()->value_;
    const intptr_t kSmi64Bits = 62;
    const int64_t kSmi64Max = (static_cast<int64_t>(1) << kSmi64Bits) - 1;
    const int64_t kSmi64Min = -(static_cast<int64_t>(1) << kSmi64Bits);
    if (value <= kSmi64Max && value >= kSmi64Min) {
      Write<int64_t>((value << kSmiTagShift) | kSmiTag);
      return true;
    }
  }

  // Check if it is a code object in that case just write a Null object
  // as we do not want code objects in the snapshot.
  if (cid == kCodeCid) {
    WriteVMIsolateObject(kNullObject);
    return true;
  }

  // Check if classes are not being serialized and it is preinitialized type
  // or a predefined internal VM class in the object store.
  if (kind_ != Snapshot::kFull) {
    // Check if it is an internal VM class which is in the object store.
    if (cid == kClassCid) {
      RawClass* raw_class = reinterpret_cast<RawClass*>(rawobj);
      intptr_t class_id = raw_class->ptr()->id_;
      if (IsObjectStoreClassId(class_id)) {
        intptr_t object_id = ObjectIdFromClassId(class_id);
        WriteIndexedObject(object_id);
        return true;
      }
    }

    // Now check it is a preinitialized type object.
    RawType* raw_type = reinterpret_cast<RawType*>(rawobj);
    intptr_t index = GetTypeIndex(object_store(), raw_type);
    if (index != kInvalidIndex) {
      WriteIndexedObject(index);
      return true;
    }
  }

  return false;
}


void SnapshotWriter::WriteObjectImpl(RawObject* raw) {
  // First check if object can be written as a simple predefined type.
  if (CheckAndWritePredefinedObject(raw)) {
    return;
  }

  // Object is being serialized, add it to the forward ref list and mark
  // it so that future references to this object in the snapshot will use
  // an object id, instead of trying to serialize it again.
  forward_list_.MarkAndAddObject(raw, kIsSerialized);

  WriteInlinedObject(raw);
}


void SnapshotWriter::WriteInlinedObject(RawObject* raw) {
  // Now write the object out inline in the stream as follows:
  // - Object is seen for the first time (inlined as follows):
  //    (object size in multiples of kObjectAlignment | 0x1)
  //    serialized fields of the object
  //    ......
  NoGCScope no_gc;
  uword tags = raw->ptr()->tags_;
  ASSERT(SerializedHeaderTag::decode(tags) == kObjectId);
  intptr_t object_id = SerializedHeaderData::decode(tags);
  tags = forward_list_.NodeForObjectId(object_id)->tags();
  RawClass* cls = class_table_->At(RawObject::ClassIdTag::decode(tags));
  intptr_t class_id = cls->ptr()->id_;

  if (!IsSplitClassId(class_id)) {
    object_id = kOmittedObjectId;
  }

  if (class_id >= kNumPredefinedCids) {
    WriteInstance(object_id, raw, cls, tags);
    return;
  }
  switch (class_id) {
#define SNAPSHOT_WRITE(clazz)                                                  \
    case clazz::kClassId: {                                                    \
      Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(raw);                \
      raw_obj->WriteTo(this, object_id, kind_);                                \
      return;                                                                  \
    }                                                                          \

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz)                                                  \
    case kTypedData##clazz##Cid:                                               \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawTypedData* raw_obj = reinterpret_cast<RawTypedData*>(raw);
      raw_obj->WriteTo(this, object_id, kind_);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz)                                                  \
    case kExternalTypedData##clazz##Cid:                                       \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawExternalTypedData* raw_obj =
        reinterpret_cast<RawExternalTypedData*>(raw);
      raw_obj->WriteTo(this, object_id, kind_);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz)                                                  \
    case kTypedData##clazz##ViewCid:                                           \

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE)
    case kByteDataViewCid: {
      WriteInstance(object_id, raw, cls, tags);
      return;
    }
#undef SNAPSHOT_WRITE
    default: break;
  }
  UNREACHABLE();
}


class WriteInlinedObjectVisitor : public ObjectVisitor {
 public:
  explicit WriteInlinedObjectVisitor(SnapshotWriter* writer)
      : ObjectVisitor(Isolate::Current()), writer_(writer) {}

  virtual void VisitObject(RawObject* obj) {
    writer_->WriteInlinedObject(obj);
  }

 private:
  SnapshotWriter* writer_;
};


void SnapshotWriter::WriteForwardedObjects() {
  WriteInlinedObjectVisitor visitor(this);
  forward_list_.SerializeAll(&visitor);
}


void ForwardList::SerializeAll(ObjectVisitor* writer) {
  // Write out all objects that were added to the forward list and have
  // not been serialized yet. These would typically be fields of instance
  // objects, arrays or immutable arrays (this is done in order to avoid
  // deep recursive calls to WriteObjectImpl).
  // NOTE: The forward list might grow as we process the list.
#ifdef DEBUG
  for (intptr_t i = first_object_id(); i < first_unprocessed_object_id_; ++i) {
    ASSERT(NodeForObjectId(i)->is_serialized());
  }
#endif  // DEBUG
  for (intptr_t id = first_unprocessed_object_id_;
       id < next_object_id();
       ++id) {
    if (!NodeForObjectId(id)->is_serialized()) {
      // Write the object out in the stream.
      RawObject* raw = NodeForObjectId(id)->raw();
      writer->VisitObject(raw);

      // Mark object as serialized.
      NodeForObjectId(id)->set_state(kIsSerialized);
    }
  }
  first_unprocessed_object_id_ = next_object_id();
}


void SnapshotWriter::WriteClassId(RawClass* cls) {
  ASSERT(kind_ != Snapshot::kFull);
  int class_id = cls->ptr()->id_;
  ASSERT(!IsSingletonClassId(class_id) && !IsObjectStoreClassId(class_id));
  // TODO(5411462): Should restrict this to only core-lib classes in this
  // case.
  // Write out the class and tags information.
  WriteVMIsolateObject(kClassCid);
  WriteTags(GetObjectTags(cls));

  // Write out the library url and class name.
  RawLibrary* library = cls->ptr()->library_;
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url_);
  WriteObjectImpl(cls->ptr()->name_);
}


void SnapshotWriter::ArrayWriteTo(intptr_t object_id,
                                  intptr_t array_kind,
                                  intptr_t tags,
                                  RawSmi* length,
                                  RawTypeArguments* type_arguments,
                                  RawObject* data[]) {
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  WriteIndexedObject(array_kind);
  WriteTags(tags);

  // Write out the length field.
  Write<RawObject*>(length);

  // Write out the type arguments.
  WriteObjectImpl(type_arguments);

  // Write out the individual object ids.
  for (intptr_t i = 0; i < len; i++) {
    WriteObjectRef(data[i]);
  }
}


void SnapshotWriter::CheckIfSerializable(RawClass* cls) {
  if (Class::IsSignatureClass(cls)) {
    // We do not allow closure objects in an isolate message.
    SetWriteException(Exceptions::kArgument,
                      "Illegal argument in isolate message"
                      " : (object is a closure)");
  }
  if (cls->ptr()->num_native_fields_ != 0) {
    // We do not allow objects with native fields in an isolate message.
    SetWriteException(Exceptions::kArgument,
                      "Illegal argument in isolate message"
                      " : (object extends NativeWrapper)");
  }
}


void SnapshotWriter::SetWriteException(Exceptions::ExceptionType type,
                                       const char* msg) {
  set_exception_type(type);
  set_exception_msg(msg);
  // The more specific error is set up in SnapshotWriter::ThrowException().
  isolate()->long_jump_base()->
      Jump(1, Object::snapshot_writer_error());
}


void SnapshotWriter::WriteInstance(intptr_t object_id,
                                   RawObject* raw,
                                   RawClass* cls,
                                   intptr_t tags) {
  // First check if object is a closure or has native fields.
  CheckIfSerializable(cls);

  // Object is regular dart instance.
  intptr_t next_field_offset =
      cls->ptr()->next_field_offset_in_words_ << kWordSizeLog2;
  ASSERT(next_field_offset > 0);

  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(object_id);

  // Indicate this is an instance object.
  Write<int32_t>(SerializedHeaderData::encode(kInstanceObjectId));

  // Write out the tags.
  WriteTags(tags);

  // Write out the class information for this object.
  WriteObjectImpl(cls);

  // Write out all the fields for the object.
  // Instance::NextFieldOffset() returns the offset of the first field in
  // a Dart object.
  intptr_t offset = Instance::NextFieldOffset();
  while (offset < next_field_offset) {
    WriteObjectRef(*reinterpret_cast<RawObject**>(
        reinterpret_cast<uword>(raw->ptr()) + offset));
    offset += kWordSize;
  }
  return;
}


void SnapshotWriter::WriteInstanceRef(RawObject* raw, RawClass* cls) {
  // First check if object is a closure or has native fields.
  CheckIfSerializable(cls);

  // Object is being referenced, add it to the forward ref list and mark
  // it so that future references to this object in the snapshot will use
  // this object id. Mark it as not having been serialized yet so that we
  // will serialize the object when we go through the forward list.
  forward_list_.MarkAndAddObject(raw, kIsNotSerialized);

  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(kOmittedObjectId);

  // Indicate this is an instance object.
  Write<int32_t>(SerializedHeaderData::encode(kInstanceObjectId));

  // Write out the class information for this object.
  WriteObjectImpl(cls);
}


void SnapshotWriter::ThrowException(Exceptions::ExceptionType type,
                                    const char* msg) {
  isolate()->object_store()->clear_sticky_error();
  UnmarkAll();
  if (msg != NULL) {
    const String& msg_obj = String::Handle(String::New(msg));
    const Array& args = Array::Handle(Array::New(1));
    args.SetAt(0, msg_obj);
    Exceptions::ThrowByType(type, args);
  } else {
    Exceptions::ThrowByType(type, Object::empty_array());
  }
  UNREACHABLE();
}


void SnapshotWriter::WriteVersion() {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_version), version_len);
}


void ScriptSnapshotWriter::WriteScriptSnapshot(const Library& lib) {
  ASSERT(kind() == Snapshot::kScript);
  ASSERT(isolate() != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());

  // Setup for long jump in case there is an exception while writing
  // the snapshot.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    // Reserve space in the output buffer for a snapshot header.
    ReserveHeader();

    // Write out the version string.
    WriteVersion();

    // Write out the library object.
    {
      NoGCScope no_gc;

      // Write out the library object.
      WriteObject(lib.raw());

      FillHeader(kind());
      UnmarkAll();
    }
  } else {
    ThrowException(exception_type(), exception_msg());
  }
}


void SnapshotWriterVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    if (as_references_) {
      writer_->WriteObjectRef(raw_obj);
    } else {
      writer_->WriteObjectImpl(raw_obj);
    }
  }
}


void MessageWriter::WriteMessage(const Object& obj) {
  ASSERT(kind() == Snapshot::kMessage);
  ASSERT(isolate() != NULL);

  // Setup for long jump in case there is an exception while writing
  // the message.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    NoGCScope no_gc;
    WriteObject(obj.raw());
    UnmarkAll();
  } else {
    ThrowException(exception_type(), exception_msg());
  }
}


}  // namespace dart
