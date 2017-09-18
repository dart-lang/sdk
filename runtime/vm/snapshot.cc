// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_entry.h"
#include "vm/dwarf.h"
#include "vm/exceptions.h"
#include "vm/heap.h"
#include "vm/lockers.h"
#include "vm/longjump.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot_ids.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/version.h"

// We currently only expect the Dart mutator to read snapshots.
#define ASSERT_NO_SAFEPOINT_SCOPE()                                            \
  isolate()->AssertCurrentThreadIsMutator();                                   \
  ASSERT(thread()->no_safepoint_scope_depth() != 0)

namespace dart {

static const int kNumInitialReferences = 32;

static bool IsSingletonClassId(intptr_t class_id) {
  // Check if this is a singleton object class which is shared by all isolates.
  return ((class_id >= kClassCid && class_id <= kUnwindErrorCid) ||
          (class_id == kTypeArgumentsCid) ||
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
  return class_id >= kNumPredefinedCids || class_id == kArrayCid ||
         class_id == kImmutableArrayCid || class_id == kObjectPoolCid ||
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
    case kObjectType:
      return object_store->object_type();
    case kNullType:
      return object_store->null_type();
    case kFunctionType:
      return object_store->function_type();
    case kNumberType:
      return object_store->number_type();
    case kSmiType:
      return object_store->smi_type();
    case kMintType:
      return object_store->mint_type();
    case kDoubleType:
      return object_store->double_type();
    case kIntType:
      return object_store->int_type();
    case kBoolType:
      return object_store->bool_type();
    case kStringType:
      return object_store->string_type();
    case kArrayType:
      return object_store->array_type();
    default:
      break;
  }
  UNREACHABLE();
  return Type::null();
}

static intptr_t GetTypeIndex(ObjectStore* object_store,
                             const RawType* raw_type) {
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

const char* Snapshot::KindToCString(Kind kind) {
  switch (kind) {
    case kFull:
      return "full";
    case kScript:
      return "script";
    case kMessage:
      return "message";
    case kFullJIT:
      return "full-jit";
    case kFullAOT:
      return "full-aot";
    case kNone:
      return "none";
    case kInvalid:
    default:
      return "invalid";
  }
}

// TODO(5411462): Temporary setup of snapshot for testing purposes,
// the actual creation of a snapshot maybe done differently.
const Snapshot* Snapshot::SetupFromBuffer(const void* raw_memory) {
  ASSERT(raw_memory != NULL);
  ASSERT(kHeaderSize == sizeof(Snapshot));
  ASSERT(kLengthIndex == length_offset());
  ASSERT((kSnapshotFlagIndex * sizeof(int64_t)) == kind_offset());
  ASSERT((kHeapObjectTag & kInlined));
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
                               ZoneGrowableArray<BackRefNode>* backward_refs,
                               Thread* thread)
    : BaseReader(buffer, size),
      kind_(kind),
      thread_(thread),
      zone_(thread->zone()),
      heap_(isolate()->heap()),
      old_space_(thread_->isolate()->heap()->old_space()),
      cls_(Class::Handle(zone_)),
      obj_(Object::Handle(zone_)),
      pobj_(PassiveObject::Handle(zone_)),
      array_(Array::Handle(zone_)),
      field_(Field::Handle(zone_)),
      str_(String::Handle(zone_)),
      library_(Library::Handle(zone_)),
      type_(AbstractType::Handle(zone_)),
      type_arguments_(TypeArguments::Handle(zone_)),
      tokens_(GrowableObjectArray::Handle(zone_)),
      stream_(TokenStream::Handle(zone_)),
      data_(ExternalTypedData::Handle(zone_)),
      typed_data_(TypedData::Handle(zone_)),
      function_(Function::Handle(zone_)),
      error_(UnhandledException::Handle(zone_)),
      max_vm_isolate_object_id_(
          (Snapshot::IsFull(kind))
              ? Object::vm_isolate_snapshot_object_table().Length()
              : 0),
      backward_references_(backward_refs) {}

RawObject* SnapshotReader::ReadObject() {
  // Setup for long jump in case there is an exception while reading.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    PassiveObject& obj =
        PassiveObject::Handle(zone(), ReadObjectImpl(kAsInlinedObject));
    for (intptr_t i = 0; i < backward_references_->length(); i++) {
      if (!(*backward_references_)[i].is_deserialized()) {
        ReadObjectImpl(kAsInlinedObject);
        (*backward_references_)[i].set_state(kIsDeserialized);
      }
    }
    if (backward_references_->length() > 0) {
      ProcessDeferredCanonicalizations();
      if (kind() == Snapshot::kScript) {
        FixSubclassesAndImplementors();
      }
      return (*backward_references_)[0].reference()->raw();
    } else {
      return obj.raw();
    }
  } else {
    // An error occurred while reading, return the error object.
    const Error& err = Error::Handle(thread()->sticky_error());
    thread()->clear_sticky_error();
    return err.raw();
  }
}

RawClass* SnapshotReader::ReadClassId(intptr_t object_id) {
  ASSERT(!Snapshot::IsFull(kind_));
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();
  ASSERT((class_header & kSmiTagMask) != kSmiTag);
  ASSERT(!IsVMIsolateObject(class_header) ||
         !IsSingletonClassId(GetVMIsolateObjectId(class_header)));
  ASSERT((SerializedHeaderTag::decode(class_header) != kObjectId) ||
         !IsObjectStoreClassId(SerializedHeaderData::decode(class_header)));
  Class& cls = Class::ZoneHandle(zone(), Class::null());
  AddBackRef(object_id, &cls, kIsDeserialized);
  // Read the library/class information and lookup the class.
  str_ ^= ReadObjectImpl(class_header, kAsInlinedObject, kInvalidPatchIndex, 0);
  library_ = Library::LookupLibrary(thread(), str_);
  if (library_.IsNull() || !library_.Loaded()) {
    SetReadException("Invalid object found in message.");
  }
  str_ ^= ReadObjectImpl(kAsInlinedObject);
  if (str_.raw() == Symbols::TopLevel().raw()) {
    cls = library_.toplevel_class();
  } else {
    cls = library_.LookupClassAllowPrivate(str_);
  }
  if (cls.IsNull()) {
    SetReadException("Invalid object found in message.");
  }
  cls.EnsureIsFinalized(thread());
  return cls.raw();
}

RawFunction* SnapshotReader::ReadFunctionId(intptr_t object_id) {
  ASSERT(kind_ == Snapshot::kScript);
  // Read the function header information and lookup the function.
  intptr_t func_header = Read<int32_t>();
  ASSERT((func_header & kSmiTagMask) != kSmiTag);
  ASSERT(!IsVMIsolateObject(func_header) ||
         !IsSingletonClassId(GetVMIsolateObjectId(func_header)));
  ASSERT((SerializedHeaderTag::decode(func_header) != kObjectId) ||
         !IsObjectStoreClassId(SerializedHeaderData::decode(func_header)));
  Function& func = Function::ZoneHandle(zone(), Function::null());
  AddBackRef(object_id, &func, kIsDeserialized);
  // Read the library/class/function information and lookup the function.
  str_ ^= ReadObjectImpl(func_header, kAsInlinedObject, kInvalidPatchIndex, 0);
  library_ = Library::LookupLibrary(thread(), str_);
  if (library_.IsNull() || !library_.Loaded()) {
    SetReadException("Expected a library name, but found an invalid name.");
  }
  str_ ^= ReadObjectImpl(kAsInlinedObject);
  if (str_.Equals(Symbols::TopLevel(), 0, Symbols::TopLevel().Length())) {
    str_ ^= ReadObjectImpl(kAsInlinedObject);
    func ^= library_.LookupLocalFunction(str_);
  } else {
    cls_ = library_.LookupClassAllowPrivate(str_);
    if (cls_.IsNull()) {
      SetReadException("Expected a class name, but found an invalid name.");
    }
    cls_.EnsureIsFinalized(thread());
    str_ ^= ReadObjectImpl(kAsInlinedObject);
    func ^= cls_.LookupFunctionAllowPrivate(str_);
  }
  if (func.IsNull()) {
    SetReadException("Expected a function name, but found an invalid name.");
  }
  return func.raw();
}

RawObject* SnapshotReader::ReadStaticImplicitClosure(intptr_t object_id,
                                                     intptr_t class_header) {
  ASSERT(!Snapshot::IsFull(kind_));

  // First create a function object and associate it with the specified
  // 'object_id'.
  Function& func = Function::Handle(zone(), Function::null());
  Instance& obj = Instance::ZoneHandle(zone(), Instance::null());
  AddBackRef(object_id, &obj, kIsDeserialized);

  // Read the library/class/function information and lookup the function.
  // Note: WriteStaticImplicitClosure is *not* scrubbing the names before
  // writing them into the snapshot, because scrubbing requires allocation.
  // This means that names we read here might be mangled with private
  // keys. These keys need to be scrubbed before performing lookups
  // otherwise lookups might fail.
  str_ ^= ReadObjectImpl(kAsInlinedObject);
  library_ = Library::LookupLibrary(thread(), str_);
  if (library_.IsNull() || !library_.Loaded()) {
    SetReadException("Invalid Library object found in message.");
  }
  str_ ^= ReadObjectImpl(kAsInlinedObject);
  if (str_.Equals(Symbols::TopLevel())) {
    str_ ^= ReadObjectImpl(kAsInlinedObject);
    str_ = String::ScrubName(str_);
    func = library_.LookupFunctionAllowPrivate(str_);
  } else {
    str_ = String::ScrubName(str_);
    cls_ = library_.LookupClassAllowPrivate(str_);
    if (cls_.IsNull()) {
      OS::Print("Name of class not found %s\n", str_.ToCString());
      SetReadException("Invalid Class object found in message.");
    }
    cls_.EnsureIsFinalized(thread());
    str_ ^= ReadObjectImpl(kAsInlinedObject);
    str_ = String::ScrubName(str_);
    func = cls_.LookupFunctionAllowPrivate(str_);
  }
  if (func.IsNull()) {
    SetReadException("Invalid function object found in message.");
  }
  func = func.ImplicitClosureFunction();
  ASSERT(!func.IsNull());

  // Return the associated implicit static closure.
  obj = func.ImplicitStaticClosure();
  return obj.raw();
}

intptr_t SnapshotReader::NextAvailableObjectId() const {
  return backward_references_->length() + kMaxPredefinedObjectIds +
         max_vm_isolate_object_id_;
}

void SnapshotReader::SetReadException(const char* msg) {
  const String& error_str = String::Handle(zone(), String::New(msg));
  const Array& args = Array::Handle(zone(), Array::New(1));
  args.SetAt(0, error_str);
  Object& result = Object::Handle(zone());
  const Library& library = Library::Handle(zone(), Library::CoreLibrary());
  result = DartLibraryCalls::InstanceCreate(library, Symbols::ArgumentError(),
                                            Symbols::Dot(), args);
  const StackTrace& stacktrace = StackTrace::Handle(zone());
  const UnhandledException& error = UnhandledException::Handle(
      zone(), UnhandledException::New(Instance::Cast(result), stacktrace));
  thread()->long_jump_base()->Jump(1, error);
}

RawObject* SnapshotReader::VmIsolateSnapshotObject(intptr_t index) const {
  return Object::vm_isolate_snapshot_object_table().At(index);
}

bool SnapshotReader::is_vm_isolate() const {
  return isolate() == Dart::vm_isolate();
}

RawObject* SnapshotReader::ReadObjectImpl(bool as_reference,
                                          intptr_t patch_object_id,
                                          intptr_t patch_offset) {
  int64_t header_value = Read<int64_t>();
  if ((header_value & kSmiTagMask) == kSmiTag) {
    return NewInteger(header_value);
  }
  ASSERT((header_value <= kIntptrMax) && (header_value >= kIntptrMin));
  return ReadObjectImpl(static_cast<intptr_t>(header_value), as_reference,
                        patch_object_id, patch_offset);
}

RawObject* SnapshotReader::ReadObjectImpl(intptr_t header_value,
                                          bool as_reference,
                                          intptr_t patch_object_id,
                                          intptr_t patch_offset) {
  if (IsVMIsolateObject(header_value)) {
    return ReadVMIsolateObject(header_value);
  }
  if (SerializedHeaderTag::decode(header_value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(header_value),
                             patch_object_id, patch_offset);
  }
  ASSERT(SerializedHeaderTag::decode(header_value) == kInlined);
  intptr_t object_id = SerializedHeaderData::decode(header_value);
  if (object_id == kOmittedObjectId) {
    object_id = NextAvailableObjectId();
  }

  // Read the class header information.
  intptr_t class_header = Read<int32_t>();
  intptr_t tags = ReadTags();
  bool read_as_reference = as_reference && !RawObject::IsCanonical(tags);
  intptr_t header_id = SerializedHeaderData::decode(class_header);
  if (header_id == kInstanceObjectId) {
    return ReadInstance(object_id, tags, read_as_reference);
  } else if (header_id == kStaticImplicitClosureObjectId) {
    // We skip the tags that have been written as the implicit static
    // closure is going to be created in this isolate or the canonical
    // version already created in the isolate will be used.
    return ReadStaticImplicitClosure(object_id, class_header);
  }
  ASSERT((class_header & kSmiTagMask) != kSmiTag);

  intptr_t class_id = LookupInternalClass(class_header);
  switch (class_id) {
#define SNAPSHOT_READ(clazz)                                                   \
  case clazz::kClassId: {                                                      \
    pobj_ = clazz::ReadFrom(this, object_id, tags, kind_, read_as_reference);  \
    break;                                                                     \
  }
    CLASS_LIST_NO_OBJECT(SNAPSHOT_READ)
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz) case kTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ =
          TypedData::ReadFrom(this, object_id, tags, kind_, read_as_reference);
      break;
    }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz) case kExternalTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = RawObject::ClassIdTag::update(class_id, tags);
      pobj_ = ExternalTypedData::ReadFrom(this, object_id, tags, kind_, true);
      break;
    }
#undef SNAPSHOT_READ
    default:
      UNREACHABLE();
      break;
  }
  if (!read_as_reference) {
    AddPatchRecord(object_id, patch_object_id, patch_offset);
  }
  return pobj_.raw();
}

RawObject* SnapshotReader::ReadInstance(intptr_t object_id,
                                        intptr_t tags,
                                        bool as_reference) {
  // Object is regular dart instance.
  intptr_t instance_size = 0;
  Instance* result = NULL;
  DeserializeState state;
  if (!as_reference) {
    result = reinterpret_cast<Instance*>(GetBackRef(object_id));
    state = kIsDeserialized;
  } else {
    state = kIsNotDeserialized;
  }
  if (result == NULL) {
    result = &(Instance::ZoneHandle(zone(), Instance::null()));
    AddBackRef(object_id, result, state);
    cls_ ^= ReadObjectImpl(kAsInlinedObject);
    ASSERT(!cls_.IsNull());
    // Closure instances are handled by Closure::ReadFrom().
    ASSERT(!cls_.IsClosureClass());
    instance_size = cls_.instance_size();
    ASSERT(instance_size > 0);
    // Allocate the instance and read in all the fields for the object.
    *result ^= Object::Allocate(cls_.id(), instance_size, HEAP_SPACE(kind_));
  } else {
    cls_ ^= ReadObjectImpl(kAsInlinedObject);
    ASSERT(!cls_.IsNull());
    instance_size = cls_.instance_size();
  }
  if (!as_reference) {
    // Read all the individual fields for inlined objects.
    intptr_t next_field_offset = cls_.next_field_offset();

    intptr_t type_argument_field_offset = cls_.type_arguments_field_offset();
    ASSERT(next_field_offset > 0);
    // Instance::NextFieldOffset() returns the offset of the first field in
    // a Dart object.
    bool read_as_reference = RawObject::IsCanonical(tags) ? false : true;
    intptr_t offset = Instance::NextFieldOffset();
    intptr_t result_cid = result->GetClassId();
    while (offset < next_field_offset) {
      pobj_ =
          ReadObjectImpl(read_as_reference, object_id, (offset / kWordSize));
      result->SetFieldAtOffset(offset, pobj_);
      if ((offset != type_argument_field_offset) &&
          (kind_ == Snapshot::kMessage) && isolate()->use_field_guards()) {
        // TODO(fschneider): Consider hoisting these lookups out of the loop.
        // This would involve creating a handle, since cls_ can't be reused
        // across the call to ReadObjectImpl.
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
    if (RawObject::IsCanonical(tags)) {
      *result = result->CheckAndCanonicalize(thread(), NULL);
      ASSERT(!result->IsNull());
    }
  }
  return result->raw();
}

void SnapshotReader::AddBackRef(intptr_t id,
                                Object* obj,
                                DeserializeState state,
                                bool defer_canonicalization) {
  intptr_t index = (id - kMaxPredefinedObjectIds);
  ASSERT(index >= max_vm_isolate_object_id_);
  index -= max_vm_isolate_object_id_;
  ASSERT(index == backward_references_->length());
  BackRefNode node(obj, state, defer_canonicalization);
  backward_references_->Add(node);
}

Object* SnapshotReader::GetBackRef(intptr_t id) {
  ASSERT(id >= kMaxPredefinedObjectIds);
  intptr_t index = (id - kMaxPredefinedObjectIds);
  ASSERT(index >= max_vm_isolate_object_id_);
  index -= max_vm_isolate_object_id_;
  if (index < backward_references_->length()) {
    return (*backward_references_)[index].reference();
  }
  return NULL;
}

class HeapLocker : public StackResource {
 public:
  HeapLocker(Thread* thread, PageSpace* page_space)
      : StackResource(thread), page_space_(page_space) {
    page_space_->AcquireDataLock();
  }
  ~HeapLocker() { page_space_->ReleaseDataLock(); }

 private:
  PageSpace* page_space_;
};

RawObject* SnapshotReader::ReadScriptSnapshot() {
  ASSERT(kind_ == Snapshot::kScript);

  // First read the version string, and check that it matches.
  RawApiError* error = VerifyVersionAndFeatures(Isolate::Current());
  if (error != ApiError::null()) {
    return error;
  }

  // The version string matches. Read the rest of the snapshot.
  obj_ = ReadObject();
  if (!obj_.IsLibrary()) {
    if (!obj_.IsError()) {
      const intptr_t kMessageBufferSize = 128;
      char message_buffer[kMessageBufferSize];
      OS::SNPrint(message_buffer, kMessageBufferSize,
                  "Invalid object %s found in script snapshot",
                  obj_.ToCString());
      const String& msg = String::Handle(String::New(message_buffer));
      obj_ = ApiError::New(msg);
    }
  }
  return obj_.raw();
}

RawApiError* SnapshotReader::VerifyVersionAndFeatures(Isolate* isolate) {
  // If the version string doesn't match, return an error.
  // Note: New things are allocated only if we're going to return an error.

  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  if (PendingBytes() < version_len) {
    const intptr_t kMessageBufferSize = 128;
    char message_buffer[kMessageBufferSize];
    OS::SNPrint(message_buffer, kMessageBufferSize,
                "No full snapshot version found, expected '%s'",
                expected_version);
    // This can also fail while bringing up the VM isolate, so make sure to
    // allocate the error message in old space.
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }

  const char* version = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(version != NULL);
  if (strncmp(version, expected_version, version_len)) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_version = OS::StrNDup(version, version_len);
    OS::SNPrint(message_buffer, kMessageBufferSize,
                "Wrong %s snapshot version, expected '%s' found '%s'",
                (Snapshot::IsFull(kind_)) ? "full" : "script", expected_version,
                actual_version);
    free(actual_version);
    // This can also fail while bringing up the VM isolate, so make sure to
    // allocate the error message in old space.
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }
  Advance(version_len);

  const char* expected_features = Dart::FeaturesString(isolate, kind_);
  ASSERT(expected_features != NULL);
  const intptr_t expected_len = strlen(expected_features);

  const char* features = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(features != NULL);
  intptr_t buffer_len = OS::StrNLen(features, PendingBytes());
  if ((buffer_len != expected_len) ||
      strncmp(features, expected_features, expected_len)) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_features =
        OS::StrNDup(features, buffer_len < 128 ? buffer_len : 128);
    OS::SNPrint(message_buffer, kMessageBufferSize,
                "Snapshot not compatible with the current VM configuration: "
                "the snapshot requires '%s' but the VM has '%s'",
                actual_features, expected_features);
    free(const_cast<char*>(expected_features));
    free(actual_features);
    // This can also fail while bringing up the VM isolate, so make sure to
    // allocate the error message in old space.
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }
  free(const_cast<char*>(expected_features));
  Advance(expected_len + 1);
  return ApiError::null();
}

RawObject* SnapshotReader::NewInteger(int64_t value) {
  ASSERT((value & kSmiTagMask) == kSmiTag);
  value = value >> kSmiTagShift;
  if (Smi::IsValid(value)) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::NewCanonical(value);
}

int32_t ImageWriter::GetTextOffsetFor(RawInstructions* instructions,
                                      RawCode* code) {
  intptr_t heap_size = instructions->Size();
  intptr_t offset = next_offset_;
  next_offset_ += heap_size;
  instructions_.Add(InstructionsData(instructions, code, offset));
  return offset;
}

int32_t ImageWriter::GetDataOffsetFor(RawObject* raw_object) {
  intptr_t heap_size = raw_object->Size();
  intptr_t offset = next_object_offset_;
  next_object_offset_ += heap_size;
  objects_.Add(ObjectData(raw_object));
  return offset;
}

void ImageWriter::Write(WriteStream* clustered_stream, bool vm) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Heap* heap = thread->isolate()->heap();
  NOT_IN_PRODUCT(TimelineDurationScope tds(thread, Timeline::GetIsolateStream(),
                                           "WriteInstructions"));

  // Handlify collected raw pointers as building the names below
  // will allocate on the Dart heap.
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    InstructionsData& data = instructions_[i];
    data.insns_ = &Instructions::Handle(zone, data.raw_insns_);
    ASSERT(data.raw_code_ != NULL);
    data.code_ = &Code::Handle(zone, data.raw_code_);

    // Update object id table with offsets that will refer to the VM snapshot,
    // causing a subsequently written isolate snapshot to share instructions
    // with the VM snapshot.
    heap->SetObjectId(data.insns_->raw(), -data.offset_);
  }
  for (intptr_t i = 0; i < objects_.length(); i++) {
    ObjectData& data = objects_[i];
    data.obj_ = &Object::Handle(zone, data.raw_obj_);
  }

  // Append the direct-mapped RO data objects after the clustered snapshot.
  WriteROData(clustered_stream);

  WriteText(clustered_stream, vm);
}

void ImageWriter::WriteROData(WriteStream* stream) {
  stream->Align(OS::kMaxPreferredCodeAlignment);

  // Heap page starts here.

  stream->WriteWord(next_object_offset_);  // Data length.
  COMPILE_ASSERT(OS::kMaxPreferredCodeAlignment >= kObjectAlignment);
  stream->Align(OS::kMaxPreferredCodeAlignment);

  // Heap page objects start here.

  for (intptr_t i = 0; i < objects_.length(); i++) {
    const Object& obj = *objects_[i].obj_;

    NoSafepointScope no_safepoint;
    uword start = reinterpret_cast<uword>(obj.raw()) - kHeapObjectTag;
    uword end = start + obj.raw()->Size();

    // Write object header with the mark and VM heap bits set.
    uword marked_tags = obj.raw()->ptr()->tags_;
    marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
    marked_tags = RawObject::MarkBit::update(true, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    marked_tags |= static_cast<uword>(obj.raw()->ptr()->hash_) << 32;
#endif
    stream->WriteWord(marked_tags);
    start += sizeof(uword);
    for (uword* cursor = reinterpret_cast<uword*>(start);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      stream->WriteWord(*cursor);
    }
  }
}

AssemblyImageWriter::AssemblyImageWriter(uint8_t** assembly_buffer,
                                         ReAlloc alloc,
                                         intptr_t initial_size)
    : ImageWriter(),
      assembly_stream_(assembly_buffer, alloc, initial_size),
      text_size_(0),
      dwarf_(NULL) {
#if defined(DART_PRECOMPILER)
  Zone* zone = Thread::Current()->zone();
  dwarf_ = new (zone) Dwarf(zone, &assembly_stream_);
#endif
}

void AssemblyImageWriter::Finalize() {
#ifdef DART_PRECOMPILER
  dwarf_->Write();
#endif
}

static void EnsureIdentifier(char* label) {
  for (char c = *label; c != '\0'; c = *++label) {
    if (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) ||
        ((c >= '0') && (c <= '9'))) {
      continue;
    }
    *label = '_';
  }
}

void AssemblyImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  Zone* zone = Thread::Current()->zone();

  const char* instructions_symbol =
      vm ? "_kDartVmSnapshotInstructions" : "_kDartIsolateSnapshotInstructions";
  assembly_stream_.Print(".text\n");
  assembly_stream_.Print(".globl %s\n", instructions_symbol);

  // Start snapshot at page boundary.
  ASSERT(VirtualMemory::PageSize() >= OS::kMaxPreferredCodeAlignment);
  assembly_stream_.Print(".balign %" Pd ", 0\n", VirtualMemory::PageSize());
  assembly_stream_.Print("%s:\n", instructions_symbol);

  // This head also provides the gap to make the instructions snapshot
  // look like a HeapPage.
  intptr_t instructions_length = next_offset_;
  WriteWordLiteralText(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    WriteWordLiteralText(0);
  }

  FrameUnwindPrologue();

  Object& owner = Object::Handle(zone);
  String& str = String::Handle(zone);

  for (intptr_t i = 0; i < instructions_.length(); i++) {
    const Instructions& insns = *instructions_[i].insns_;
    const Code& code = *instructions_[i].code_;

    ASSERT(insns.raw()->Size() % sizeof(uint64_t) == 0);

    // 1. Write from the header to the entry point.
    {
      NoSafepointScope no_safepoint;

      uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
      uword entry = beginning + Instructions::HeaderSize();

      // Write Instructions with the mark and VM heap bits set.
      uword marked_tags = insns.raw_ptr()->tags_;
      marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
      marked_tags = RawObject::MarkBit::update(true, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
      // Can't use GetObjectTagsAndHash because the update methods discard the
      // high bits.
      marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

      WriteWordLiteralText(marked_tags);
      beginning += sizeof(uword);

      WriteByteSequence(beginning, entry);
    }

    // 2. Write a label at the entry point.
    // Linux's perf uses these labels.
    owner = code.owner();
    if (owner.IsNull()) {
      const char* name = StubCode::NameOfStub(insns.UncheckedEntryPoint());
      assembly_stream_.Print("Precompiled_Stub_%s:\n", name);
    } else if (owner.IsClass()) {
      str = Class::Cast(owner).Name();
      const char* name = str.ToCString();
      EnsureIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_AllocationStub_%s_%" Pd ":\n", name,
                             i);
    } else if (owner.IsFunction()) {
      const char* name = Function::Cast(owner).ToQualifiedCString();
      EnsureIdentifier(const_cast<char*>(name));
      assembly_stream_.Print("Precompiled_%s_%" Pd ":\n", name, i);
    } else {
      UNREACHABLE();
    }

#ifdef DART_PRECOMPILER
    // Create a label for use by DWARF.
    intptr_t dwarf_index = dwarf_->AddCode(code);
    assembly_stream_.Print(".Lcode%" Pd ":\n", dwarf_index);
#endif

    {
      // 3. Write from the entry point to the end.
      NoSafepointScope no_safepoint;
      uword beginning = reinterpret_cast<uword>(insns.raw()) - kHeapObjectTag;
      uword entry = beginning + Instructions::HeaderSize();
      uword payload_size = insns.Size();
      payload_size = Utils::RoundUp(payload_size, OS::PreferredCodeAlignment());
      uword end = entry + payload_size;

      ASSERT(Utils::IsAligned(beginning, sizeof(uword)));
      ASSERT(Utils::IsAligned(entry, sizeof(uword)));
      ASSERT(Utils::IsAligned(end, sizeof(uword)));

      WriteByteSequence(entry, end);
    }
  }

  FrameUnwindEpilogue();

#if defined(TARGET_OS_LINUX) || defined(TARGET_OS_ANDROID) ||                  \
    defined(TARGET_OS_FUCHSIA)
  assembly_stream_.Print(".section .rodata\n");
#elif defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  assembly_stream_.Print(".const\n");
#else
  UNIMPLEMENTED();
#endif

  const char* data_symbol =
      vm ? "_kDartVmSnapshotData" : "_kDartIsolateSnapshotData";
  assembly_stream_.Print(".globl %s\n", data_symbol);
  assembly_stream_.Print(".balign %" Pd ", 0\n",
                         OS::kMaxPreferredCodeAlignment);
  assembly_stream_.Print("%s:\n", data_symbol);
  uword buffer = reinterpret_cast<uword>(clustered_stream->buffer());
  intptr_t length = clustered_stream->bytes_written();
  WriteByteSequence(buffer, buffer + length);
}

void AssemblyImageWriter::FrameUnwindPrologue() {
  // Creates DWARF's .debug_frame
  // CFI = Call frame information
  // CFA = Canonical frame address
  assembly_stream_.Print(".cfi_startproc\n");

#if defined(TARGET_ARCH_X64)
  assembly_stream_.Print(".cfi_def_cfa rbp, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset rbp, 0\n");   // saved fp is *(CFA+0)
  assembly_stream_.Print(".cfi_offset rip, 8\n");   // saved pc is *(CFA+8)
  // saved sp is CFA+16
  // Should be ".cfi_value_offset rsp, 16", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (rsp)        7   (DWARF register number)
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend               16
  assembly_stream_.Print(".cfi_escape 0x10, 31, 2, 0x23, 16\n");

#elif defined(TARGET_ARCH_ARM64)
  COMPILE_ASSERT(FP == R29);
  COMPILE_ASSERT(LR == R30);
  assembly_stream_.Print(".cfi_def_cfa x29, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset x29, 0\n");   // saved fp is *(CFA+0)
  assembly_stream_.Print(".cfi_offset x30, 8\n");   // saved pc is *(CFA+8)
  // saved sp is CFA+16
  // Should be ".cfi_value_offset sp, 16", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (x31)       31
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend               16
  assembly_stream_.Print(".cfi_escape 0x10, 31, 2, 0x23, 16\n");

#elif defined(TARGET_ARCH_ARM)
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R7);
  assembly_stream_.Print(".cfi_def_cfa r7, 0\n");  // CFA is fp+j0
  assembly_stream_.Print(".cfi_offset r7, 0\n");   // saved fp is *(CFA+0)
#else
  COMPILE_ASSERT(FP == R11);
  assembly_stream_.Print(".cfi_def_cfa r11, 0\n");  // CFA is fp+0
  assembly_stream_.Print(".cfi_offset r11, 0\n");   // saved fp is *(CFA+0)
#endif
  assembly_stream_.Print(".cfi_offset lr, 4\n");   // saved pc is *(CFA+4)
  // saved sp is CFA+8
  // Should be ".cfi_value_offset sp, 8", but requires gcc newer than late
  // 2016 and not supported by Android's libunwind.
  // DW_CFA_expression          0x10
  // uleb128 register (sp)        13
  // uleb128 size of operation     2
  // DW_OP_plus_uconst          0x23
  // uleb128 addend                8
  assembly_stream_.Print(".cfi_escape 0x10, 13, 2, 0x23, 8\n");

// libunwind on ARM may use .ARM.exidx instead of .debug_frame
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
  COMPILE_ASSERT(FP == R7);
  assembly_stream_.Print(".fnstart\n");
  assembly_stream_.Print(".save {r7, lr}\n");
  assembly_stream_.Print(".setfp r7, sp, #0\n");
#else
  COMPILE_ASSERT(FP == R11);
  assembly_stream_.Print(".fnstart\n");
  assembly_stream_.Print(".save {r11, lr}\n");
  assembly_stream_.Print(".setfp r11, sp, #0\n");
#endif

#endif
}

void AssemblyImageWriter::FrameUnwindEpilogue() {
#if defined(TARGET_ARCH_ARM)
  assembly_stream_.Print(".fnend\n");
#endif
  assembly_stream_.Print(".cfi_endproc\n");
}

void AssemblyImageWriter::WriteByteSequence(uword start, uword end) {
  for (uword* cursor = reinterpret_cast<uword*>(start);
       cursor < reinterpret_cast<uword*>(end); cursor++) {
    WriteWordLiteralText(*cursor);
  }
}

void BlobImageWriter::WriteText(WriteStream* clustered_stream, bool vm) {
  // This header provides the gap to make the instructions snapshot look like a
  // HeapPage.
  intptr_t instructions_length = next_offset_;
  instructions_blob_stream_.WriteWord(instructions_length);
  intptr_t header_words = Image::kHeaderSize / sizeof(uword);
  for (intptr_t i = 1; i < header_words; i++) {
    instructions_blob_stream_.WriteWord(0);
  }

  NoSafepointScope no_safepoint;
  for (intptr_t i = 0; i < instructions_.length(); i++) {
    const Instructions& insns = *instructions_[i].insns_;

    uword beginning = reinterpret_cast<uword>(insns.raw_ptr());
    uword entry = beginning + Instructions::HeaderSize();
    uword payload_size = insns.Size();
    payload_size = Utils::RoundUp(payload_size, OS::PreferredCodeAlignment());
    uword end = entry + payload_size;

    ASSERT(Utils::IsAligned(beginning, sizeof(uword)));
    ASSERT(Utils::IsAligned(entry, sizeof(uword)));

    // Write Instructions with the mark and VM heap bits set.
    uword marked_tags = insns.raw_ptr()->tags_;
    marked_tags = RawObject::VMHeapObjectTag::update(true, marked_tags);
    marked_tags = RawObject::MarkBit::update(true, marked_tags);
#if defined(HASH_IN_OBJECT_HEADER)
    // Can't use GetObjectTagsAndHash because the update methods discard the
    // high bits.
    marked_tags |= static_cast<uword>(insns.raw_ptr()->hash_) << 32;
#endif

    instructions_blob_stream_.WriteWord(marked_tags);
    beginning += sizeof(uword);

    for (uword* cursor = reinterpret_cast<uword*>(beginning);
         cursor < reinterpret_cast<uword*>(end); cursor++) {
      instructions_blob_stream_.WriteWord(*cursor);
    }
  }
}

ImageReader::ImageReader(const uint8_t* instructions_buffer,
                         const uint8_t* data_buffer)
    : instructions_buffer_(instructions_buffer), data_buffer_(data_buffer) {
  ASSERT(instructions_buffer != NULL);
  ASSERT(data_buffer != NULL);
  ASSERT(Utils::IsAligned(reinterpret_cast<uword>(instructions_buffer),
                          OS::PreferredCodeAlignment()));
  vm_instructions_buffer_ = Dart::vm_snapshot_instructions();
}

RawInstructions* ImageReader::GetInstructionsAt(int32_t offset) {
  ASSERT(Utils::IsAligned(offset, OS::PreferredCodeAlignment()));

  RawInstructions* result;
  if (offset < 0) {
    result = reinterpret_cast<RawInstructions*>(
        reinterpret_cast<uword>(vm_instructions_buffer_) - offset +
        kHeapObjectTag);
  } else {
    result = reinterpret_cast<RawInstructions*>(
        reinterpret_cast<uword>(instructions_buffer_) + offset +
        kHeapObjectTag);
  }
  ASSERT(result->IsInstructions());
  ASSERT(result->IsMarked());

  return result;
}

RawObject* ImageReader::GetObjectAt(int32_t offset) {
  ASSERT(Utils::IsAligned(offset, kWordSize));

  RawObject* result = reinterpret_cast<RawObject*>(
      reinterpret_cast<uword>(data_buffer_) + offset + kHeapObjectTag);
  ASSERT(result->IsMarked());

  return result;
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
  ASSERT(IsObjectStoreClassId(class_id) || IsSingletonClassId(class_id));
  return class_id;
}

#define READ_VM_SINGLETON_OBJ(id, obj)                                         \
  if (object_id == id) {                                                       \
    return obj;                                                                \
  }

RawObject* SnapshotReader::ReadVMIsolateObject(intptr_t header_value) {
  intptr_t object_id = GetVMIsolateObjectId(header_value);

  // First check if it is one of the singleton objects.
  READ_VM_SINGLETON_OBJ(kNullObject, Object::null());
  READ_VM_SINGLETON_OBJ(kSentinelObject, Object::sentinel().raw());
  READ_VM_SINGLETON_OBJ(kTransitionSentinelObject,
                        Object::transition_sentinel().raw());
  READ_VM_SINGLETON_OBJ(kEmptyArrayObject, Object::empty_array().raw());
  READ_VM_SINGLETON_OBJ(kZeroArrayObject, Object::zero_array().raw());
  READ_VM_SINGLETON_OBJ(kDynamicType, Object::dynamic_type().raw());
  READ_VM_SINGLETON_OBJ(kVoidType, Object::void_type().raw());
  READ_VM_SINGLETON_OBJ(kTrueValue, Bool::True().raw());
  READ_VM_SINGLETON_OBJ(kFalseValue, Bool::False().raw());
  READ_VM_SINGLETON_OBJ(kExtractorParameterTypes,
                        Object::extractor_parameter_types().raw());
  READ_VM_SINGLETON_OBJ(kExtractorParameterNames,
                        Object::extractor_parameter_names().raw());
  READ_VM_SINGLETON_OBJ(kEmptyContextObject, Object::empty_context().raw());
  READ_VM_SINGLETON_OBJ(kEmptyContextScopeObject,
                        Object::empty_context_scope().raw());
  READ_VM_SINGLETON_OBJ(kEmptyObjectPool, Object::empty_object_pool().raw());
  READ_VM_SINGLETON_OBJ(kEmptyDescriptors, Object::empty_descriptors().raw());
  READ_VM_SINGLETON_OBJ(kEmptyVarDescriptors,
                        Object::empty_var_descriptors().raw());
  READ_VM_SINGLETON_OBJ(kEmptyExceptionHandlers,
                        Object::empty_exception_handlers().raw());

  // Check if it is a double.
  if (object_id == kDoubleObject) {
    ASSERT(kind_ == Snapshot::kMessage);
    return Double::New(ReadDouble());
  }

  // Check it is a singleton class object.
  intptr_t class_id = ClassIdFromObjectId(object_id);
  if (IsSingletonClassId(class_id)) {
    return isolate()->class_table()->At(class_id);  // get singleton class.
  }

  // Check if it is a singleton Argument descriptor object.
  for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
    if (object_id == (kCachedArgumentsDescriptor0 + i)) {
      return ArgumentsDescriptor::cached_args_descriptors_[i];
    }
  }

  // Check if it is a singleton ICData array object.
  for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
    if (object_id == (kCachedICDataArray0 + i)) {
      return ICData::cached_icdata_arrays_[i];
    }
  }

  ASSERT(Symbols::IsPredefinedSymbolId(object_id));
  return Symbols::GetPredefinedSymbol(object_id);  // return VM symbol.
}

RawObject* SnapshotReader::ReadIndexedObject(intptr_t object_id,
                                             intptr_t patch_object_id,
                                             intptr_t patch_offset) {
  intptr_t class_id = ClassIdFromObjectId(object_id);
  if (IsObjectStoreClassId(class_id)) {
    return isolate()->class_table()->At(class_id);  // get singleton class.
  }
  if (IsObjectStoreTypeId(object_id)) {
    return GetType(object_store(), object_id);  // return type obj.
  }
  ASSERT(object_id >= kMaxPredefinedObjectIds);
  intptr_t index = (object_id - kMaxPredefinedObjectIds);
  if (index < max_vm_isolate_object_id_) {
    return VmIsolateSnapshotObject(index);
  }
  AddPatchRecord(object_id, patch_object_id, patch_offset);
  return GetBackRef(object_id)->raw();
}

void SnapshotReader::AddPatchRecord(intptr_t object_id,
                                    intptr_t patch_object_id,
                                    intptr_t patch_offset) {
  if (patch_object_id != kInvalidPatchIndex) {
    ASSERT(object_id >= kMaxPredefinedObjectIds);
    intptr_t index = (object_id - kMaxPredefinedObjectIds);
    ASSERT(index >= max_vm_isolate_object_id_);
    index -= max_vm_isolate_object_id_;
    ASSERT(index < backward_references_->length());
    BackRefNode& ref = (*backward_references_)[index];
    ref.AddPatchRecord(patch_object_id, patch_offset);
  }
}

void SnapshotReader::ProcessDeferredCanonicalizations() {
  Type& typeobj = Type::Handle();
  TypeArguments& typeargs = TypeArguments::Handle();
  Object& newobj = Object::Handle();
  for (intptr_t i = 0; i < backward_references_->length(); i++) {
    BackRefNode& backref = (*backward_references_)[i];
    if (backref.defer_canonicalization()) {
      Object* objref = backref.reference();
      // Object should either be a type or a type argument.
      if (objref->IsType()) {
        typeobj ^= objref->raw();
        newobj = typeobj.Canonicalize();
      } else {
        ASSERT(objref->IsTypeArguments());
        typeargs ^= objref->raw();
        newobj = typeargs.Canonicalize();
      }
      if (newobj.raw() != objref->raw()) {
        ZoneGrowableArray<intptr_t>* patches = backref.patch_records();
        ASSERT(newobj.IsNull() || newobj.IsCanonical());
        // First we replace the back ref table with the canonical object.
        *objref = newobj.raw();
        if (patches != NULL) {
          // Now go over all the patch records and patch the canonical object.
          for (intptr_t j = 0; j < patches->length(); j += 2) {
            NoSafepointScope no_safepoint;
            intptr_t patch_object_id = (*patches)[j];
            intptr_t patch_offset = (*patches)[j + 1];
            Object* target = GetBackRef(patch_object_id);
            // We should not backpatch an object that is canonical.
            if (!target->IsCanonical()) {
              RawObject** rawptr =
                  reinterpret_cast<RawObject**>(target->raw()->ptr());
              target->StorePointer((rawptr + patch_offset), newobj.raw());
            }
          }
        }
      } else {
        ASSERT(objref->IsCanonical());
      }
    }
  }
}

void SnapshotReader::FixSubclassesAndImplementors() {
  Class& cls = Class::Handle(zone());
  Class& supercls = Class::Handle(zone());
  Array& interfaces = Array::Handle(zone());
  AbstractType& interface = AbstractType::Handle(zone());
  Class& interface_cls = Class::Handle(zone());
  for (intptr_t i = 0; i < backward_references_->length(); i++) {
    BackRefNode& backref = (*backward_references_)[i];
    Object* objref = backref.reference();
    if (objref->IsClass()) {
      cls ^= objref->raw();
      if (!cls.IsInFullSnapshot()) {
        supercls = cls.SuperClass();
        if (!supercls.IsNull() && !supercls.IsObjectClass() &&
            supercls.IsInFullSnapshot()) {
          supercls.AddDirectSubclass(cls);
          supercls.DisableCHAOptimizedCode(cls);
        }
        interfaces = cls.interfaces();
        for (intptr_t i = 0; i < interfaces.Length(); i++) {
          interface ^= interfaces.At(i);
          interface_cls = interface.type_class();
          interface_cls.set_is_implemented();
          interface_cls.DisableCHAOptimizedCode(cls);
        }
      }
    }
  }
}

void SnapshotReader::ArrayReadFrom(intptr_t object_id,
                                   const Array& result,
                                   intptr_t len,
                                   intptr_t tags) {
  // Setup the object fields.
  const intptr_t typeargs_offset =
      GrowableObjectArray::type_arguments_offset() / kWordSize;
  *TypeArgumentsHandle() ^=
      ReadObjectImpl(kAsInlinedObject, object_id, typeargs_offset);
  result.SetTypeArguments(*TypeArgumentsHandle());

  bool as_reference = RawObject::IsCanonical(tags) ? false : true;
  intptr_t offset = result.raw_ptr()->data() -
                    reinterpret_cast<RawObject**>(result.raw()->ptr());
  for (intptr_t i = 0; i < len; i++) {
    *PassiveObjectHandle() =
        ReadObjectImpl(as_reference, object_id, (i + offset));
    result.SetAt(i, *PassiveObjectHandle());
  }
}

ScriptSnapshotReader::ScriptSnapshotReader(const uint8_t* buffer,
                                           intptr_t size,
                                           Thread* thread)
    : SnapshotReader(buffer,
                     size,
                     Snapshot::kScript,
                     new ZoneGrowableArray<BackRefNode>(kNumInitialReferences),
                     thread) {}

ScriptSnapshotReader::~ScriptSnapshotReader() {
  ResetBackwardReferenceTable();
}

MessageSnapshotReader::MessageSnapshotReader(const uint8_t* buffer,
                                             intptr_t size,
                                             Thread* thread)
    : SnapshotReader(buffer,
                     size,
                     Snapshot::kMessage,
                     new ZoneGrowableArray<BackRefNode>(kNumInitialReferences),
                     thread) {}

MessageSnapshotReader::~MessageSnapshotReader() {
  ResetBackwardReferenceTable();
}

SnapshotWriter::SnapshotWriter(Thread* thread,
                               Snapshot::Kind kind,
                               uint8_t** buffer,
                               ReAlloc alloc,
                               DeAlloc dealloc,
                               intptr_t initial_size,
                               ForwardList* forward_list,
                               bool can_send_any_object)
    : BaseWriter(buffer, alloc, dealloc, initial_size),
      thread_(thread),
      kind_(kind),
      object_store_(isolate()->object_store()),
      class_table_(isolate()->class_table()),
      forward_list_(forward_list),
      exception_type_(Exceptions::kNone),
      exception_msg_(NULL),
      can_send_any_object_(can_send_any_object) {
  ASSERT(forward_list_ != NULL);
}

void SnapshotWriter::WriteObject(RawObject* rawobj) {
  WriteObjectImpl(rawobj, kAsInlinedObject);
  WriteForwardedObjects();
}

uint32_t SnapshotWriter::GetObjectTags(RawObject* raw) {
  return raw->ptr()->tags_;
}

uword SnapshotWriter::GetObjectTagsAndHash(RawObject* raw) {
  uword result = raw->ptr()->tags_;
#if defined(HASH_IN_OBJECT_HEADER)
  result |= static_cast<uword>(raw->ptr()->hash_) << 32;
#endif
  return result;
}

#define VM_OBJECT_CLASS_LIST(V)                                                \
  V(OneByteString)                                                             \
  V(TwoByteString)                                                             \
  V(Mint)                                                                      \
  V(Bigint)                                                                    \
  V(Double)                                                                    \
  V(ImmutableArray)

#define VM_OBJECT_WRITE(clazz)                                                 \
  case clazz::kClassId: {                                                      \
    object_id = forward_list_->AddObject(zone(), rawobj, kIsSerialized);       \
    Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(rawobj);               \
    raw_obj->WriteTo(this, object_id, kind(), false);                          \
    return true;                                                               \
  }

#define WRITE_VM_SINGLETON_OBJ(obj, id)                                        \
  if (rawobj == obj) {                                                         \
    WriteVMIsolateObject(id);                                                  \
    return true;                                                               \
  }

bool SnapshotWriter::HandleVMIsolateObject(RawObject* rawobj) {
  // Check if it is one of the singleton VM objects.
  WRITE_VM_SINGLETON_OBJ(Object::null(), kNullObject);
  WRITE_VM_SINGLETON_OBJ(Object::sentinel().raw(), kSentinelObject);
  WRITE_VM_SINGLETON_OBJ(Object::transition_sentinel().raw(),
                         kTransitionSentinelObject);
  WRITE_VM_SINGLETON_OBJ(Object::empty_array().raw(), kEmptyArrayObject);
  WRITE_VM_SINGLETON_OBJ(Object::zero_array().raw(), kZeroArrayObject);
  WRITE_VM_SINGLETON_OBJ(Object::dynamic_type().raw(), kDynamicType);
  WRITE_VM_SINGLETON_OBJ(Object::void_type().raw(), kVoidType);
  WRITE_VM_SINGLETON_OBJ(Bool::True().raw(), kTrueValue);
  WRITE_VM_SINGLETON_OBJ(Bool::False().raw(), kFalseValue);
  WRITE_VM_SINGLETON_OBJ(Object::extractor_parameter_types().raw(),
                         kExtractorParameterTypes);
  WRITE_VM_SINGLETON_OBJ(Object::extractor_parameter_names().raw(),
                         kExtractorParameterNames);
  WRITE_VM_SINGLETON_OBJ(Object::empty_context().raw(), kEmptyContextObject);
  WRITE_VM_SINGLETON_OBJ(Object::empty_context_scope().raw(),
                         kEmptyContextScopeObject);
  WRITE_VM_SINGLETON_OBJ(Object::empty_object_pool().raw(), kEmptyObjectPool);
  WRITE_VM_SINGLETON_OBJ(Object::empty_descriptors().raw(), kEmptyDescriptors);
  WRITE_VM_SINGLETON_OBJ(Object::empty_var_descriptors().raw(),
                         kEmptyVarDescriptors);
  WRITE_VM_SINGLETON_OBJ(Object::empty_exception_handlers().raw(),
                         kEmptyExceptionHandlers);

  // Check if it is a singleton class object which is shared by
  // all isolates.
  intptr_t id = rawobj->GetClassId();
  if (id == kClassCid) {
    RawClass* raw_class = reinterpret_cast<RawClass*>(rawobj);
    intptr_t class_id = raw_class->ptr()->id_;
    if (IsSingletonClassId(class_id)) {
      intptr_t object_id = ObjectIdFromClassId(class_id);
      WriteVMIsolateObject(object_id);
      return true;
    }
  }

  // Check if it is a singleton Argument descriptor object.
  for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
    if (rawobj == ArgumentsDescriptor::cached_args_descriptors_[i]) {
      WriteVMIsolateObject(kCachedArgumentsDescriptor0 + i);
      return true;
    }
  }

  // Check if it is a singleton ICData array object.
  for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
    if (rawobj == ICData::cached_icdata_arrays_[i]) {
      WriteVMIsolateObject(kCachedICDataArray0 + i);
      return true;
    }
  }

  // In the case of script snapshots or for messages we do not use
  // the index into the vm isolate snapshot object table, instead we
  // explicitly write the object out.
  intptr_t object_id = forward_list_->FindObject(rawobj);
  if (object_id != -1) {
    WriteIndexedObject(object_id);
    return true;
  } else {
    switch (id) {
      VM_OBJECT_CLASS_LIST(VM_OBJECT_WRITE)
      case kTypedDataUint32ArrayCid: {
        object_id = forward_list_->AddObject(zone(), rawobj, kIsSerialized);
        RawTypedData* raw_obj = reinterpret_cast<RawTypedData*>(rawobj);
        raw_obj->WriteTo(this, object_id, kind(), false);
        return true;
      }
      default:
        OS::Print("class id = %" Pd "\n", id);
        break;
    }
  }

  const Object& obj = Object::Handle(rawobj);
  FATAL1("Unexpected reference to object in VM isolate: %s\n", obj.ToCString());
  return false;
}

#undef VM_OBJECT_WRITE

ForwardList::ForwardList(Thread* thread, intptr_t first_object_id)
    : thread_(thread),
      first_object_id_(first_object_id),
      nodes_(),
      first_unprocessed_object_id_(first_object_id) {
  ASSERT(first_object_id > 0);
}

ForwardList::~ForwardList() {
  heap()->ResetObjectIdTable();
}

intptr_t ForwardList::AddObject(Zone* zone,
                                RawObject* raw,
                                SerializeState state) {
  NoSafepointScope no_safepoint;
  intptr_t object_id = next_object_id();
  ASSERT(object_id > 0 && object_id <= kMaxObjectId);
  const Object& obj = Object::ZoneHandle(zone, raw);
  Node* node = new Node(&obj, state);
  ASSERT(node != NULL);
  nodes_.Add(node);
  ASSERT(object_id != 0);
  heap()->SetObjectId(raw, object_id);
  return object_id;
}

intptr_t ForwardList::FindObject(RawObject* raw) {
  NoSafepointScope no_safepoint;
  intptr_t id = heap()->GetObjectId(raw);
  ASSERT(id == 0 || NodeForObjectId(id)->obj()->raw() == raw);
  return (id == 0) ? static_cast<intptr_t>(kInvalidIndex) : id;
}

bool SnapshotWriter::CheckAndWritePredefinedObject(RawObject* rawobj) {
  // Check if object can be written in one of the following ways:
  // - Smi: the Smi value is written as is (last bit is not tagged).
  // - VM internal class (from VM isolate): (index of class in vm isolate | 0x3)
  // - Object that has already been written: (negative id in stream | 0x3)

  NoSafepointScope no_safepoint;

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
  intptr_t object_id = forward_list_->FindObject(rawobj);
  if (object_id != kInvalidIndex) {
    WriteIndexedObject(object_id);
    return true;
  }

  // Now check if it is an object from the VM isolate. These objects are shared
  // by all isolates.
  if (rawobj->IsVMHeapObject() && HandleVMIsolateObject(rawobj)) {
    return true;
  }

  // Check if it is a code object in that case just write a Null object
  // as we do not want code objects in the snapshot.
  if (cid == kCodeCid) {
    WriteVMIsolateObject(kNullObject);
    return true;
  }

  // Check if classes are not being serialized and it is preinitialized type
  // or a predefined internal VM class in the object store.
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

  return false;
}

void SnapshotWriter::WriteObjectImpl(RawObject* raw, bool as_reference) {
  // First check if object can be written as a simple predefined type.
  if (CheckAndWritePredefinedObject(raw)) {
    return;
  }

  // When we know that we are dealing with leaf or shallow objects we write
  // these objects inline even when 'as_reference' is true.
  const bool write_as_reference = as_reference && !raw->IsCanonical();
  uintptr_t tags = GetObjectTagsAndHash(raw);

  // Add object to the forward ref list and mark it so that future references
  // to this object in the snapshot will use this object id. Mark the
  // serialization state so that we do the right thing when we go through
  // the forward list.
  intptr_t class_id = raw->GetClassId();
  intptr_t object_id;
  if (write_as_reference && IsSplitClassId(class_id)) {
    object_id = forward_list_->AddObject(zone(), raw, kIsNotSerialized);
  } else {
    object_id = forward_list_->AddObject(zone(), raw, kIsSerialized);
  }
  if (write_as_reference || !IsSplitClassId(class_id)) {
    object_id = kOmittedObjectId;
  }
  WriteMarkedObjectImpl(raw, tags, object_id, write_as_reference);
}

void SnapshotWriter::WriteMarkedObjectImpl(RawObject* raw,
                                           intptr_t tags,
                                           intptr_t object_id,
                                           bool as_reference) {
  NoSafepointScope no_safepoint;
  RawClass* cls = class_table_->At(RawObject::ClassIdTag::decode(tags));
  intptr_t class_id = cls->ptr()->id_;
  ASSERT(class_id == RawObject::ClassIdTag::decode(tags));
  if (class_id >= kNumPredefinedCids ||
      RawObject::IsImplicitFieldClassId(class_id)) {
    WriteInstance(raw, cls, tags, object_id, as_reference);
    return;
  }
  switch (class_id) {
#define SNAPSHOT_WRITE(clazz)                                                  \
  case clazz::kClassId: {                                                      \
    Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(raw);                  \
    raw_obj->WriteTo(this, object_id, kind_, as_reference);                    \
    return;                                                                    \
  }

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz) case kTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawTypedData* raw_obj = reinterpret_cast<RawTypedData*>(raw);
      raw_obj->WriteTo(this, object_id, kind_, as_reference);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz) case kExternalTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      RawExternalTypedData* raw_obj =
          reinterpret_cast<RawExternalTypedData*>(raw);
      raw_obj->WriteTo(this, object_id, kind_, as_reference);
      return;
    }
#undef SNAPSHOT_WRITE
    default:
      break;
  }

  const Object& obj = Object::Handle(raw);
  FATAL1("Unexpected object: %s\n", obj.ToCString());
}

class WriteInlinedObjectVisitor : public ObjectVisitor {
 public:
  explicit WriteInlinedObjectVisitor(SnapshotWriter* writer)
      : writer_(writer) {}

  virtual void VisitObject(RawObject* obj) {
    intptr_t object_id = writer_->forward_list_->FindObject(obj);
    ASSERT(object_id != kInvalidIndex);
    intptr_t tags = MessageWriter::GetObjectTagsAndHash(obj);
    writer_->WriteMarkedObjectImpl(obj, tags, object_id, kAsInlinedObject);
  }

 private:
  SnapshotWriter* writer_;
};

void SnapshotWriter::WriteForwardedObjects() {
  WriteInlinedObjectVisitor visitor(this);
  forward_list_->SerializeAll(&visitor);
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
  for (intptr_t id = first_unprocessed_object_id_; id < next_object_id();
       ++id) {
    if (!NodeForObjectId(id)->is_serialized()) {
      // Write the object out in the stream.
      RawObject* raw = NodeForObjectId(id)->obj()->raw();
      writer->VisitObject(raw);

      // Mark object as serialized.
      NodeForObjectId(id)->set_state(kIsSerialized);
    }
  }
  first_unprocessed_object_id_ = next_object_id();
}

void SnapshotWriter::WriteClassId(RawClass* cls) {
  ASSERT(!Snapshot::IsFull(kind_));
  int class_id = cls->ptr()->id_;
  ASSERT(!IsSingletonClassId(class_id) && !IsObjectStoreClassId(class_id));

  // Write out the library url and class name.
  RawLibrary* library = cls->ptr()->library_;
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url_, kAsInlinedObject);
  WriteObjectImpl(cls->ptr()->name_, kAsInlinedObject);
}

void SnapshotWriter::WriteFunctionId(RawFunction* func, bool owner_is_class) {
  ASSERT(kind_ == Snapshot::kScript);
  RawClass* cls = (owner_is_class)
                      ? reinterpret_cast<RawClass*>(func->ptr()->owner_)
                      : reinterpret_cast<RawPatchClass*>(func->ptr()->owner_)
                            ->ptr()
                            ->patched_class_;

  // Write out the library url and class name.
  RawLibrary* library = cls->ptr()->library_;
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url_, kAsInlinedObject);
  WriteObjectImpl(cls->ptr()->name_, kAsInlinedObject);
  WriteObjectImpl(func->ptr()->name_, kAsInlinedObject);
}

void SnapshotWriter::WriteStaticImplicitClosure(intptr_t object_id,
                                                RawFunction* func,
                                                intptr_t tags) {
  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(object_id);

  // Indicate this is a static implicit closure object.
  Write<int32_t>(SerializedHeaderData::encode(kStaticImplicitClosureObjectId));

  // Write out the tags.
  WriteTags(tags);

  // Write out the library url, class name and signature function name.
  RawClass* cls = GetFunctionOwner(func);
  ASSERT(cls != Class::null());
  RawLibrary* library = cls->ptr()->library_;
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url_, kAsInlinedObject);
  WriteObjectImpl(cls->ptr()->name_, kAsInlinedObject);
  WriteObjectImpl(func->ptr()->name_, kAsInlinedObject);
}

void SnapshotWriter::ArrayWriteTo(intptr_t object_id,
                                  intptr_t array_kind,
                                  intptr_t tags,
                                  RawSmi* length,
                                  RawTypeArguments* type_arguments,
                                  RawObject* data[],
                                  bool as_reference) {
  if (as_reference) {
    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(kOmittedObjectId);

    // Write out the class information.
    WriteIndexedObject(array_kind);
    WriteTags(tags);

    // Write out the length field.
    Write<RawObject*>(length);
  } else {
    intptr_t len = Smi::Value(length);

    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(object_id);

    // Write out the class and tags information.
    WriteIndexedObject(array_kind);
    WriteTags(tags);

    // Write out the length field.
    Write<RawObject*>(length);

    // Write out the type arguments.
    WriteObjectImpl(type_arguments, kAsInlinedObject);

    // Write out the individual object ids.
    bool write_as_reference = RawObject::IsCanonical(tags) ? false : true;
    for (intptr_t i = 0; i < len; i++) {
      WriteObjectImpl(data[i], write_as_reference);
    }
  }
}

RawFunction* SnapshotWriter::IsSerializableClosure(RawClosure* closure) {
  // Extract the function object to check if this closure
  // can be sent in an isolate message.
  RawFunction* func = closure->ptr()->function_;
  // We only allow closure of top level methods or static functions in a
  // class to be sent in isolate messages.
  if (can_send_any_object() &&
      Function::IsImplicitStaticClosureFunction(func)) {
    return func;
  }
  // Not a closure of a top level method or static function, throw an
  // exception as we do not allow these objects to be serialized.
  HANDLESCOPE(thread());

  const Function& errorFunc = Function::Handle(zone(), func);
  ASSERT(!errorFunc.IsNull());

  // All other closures are errors.
  char* chars = OS::SCreate(
      thread()->zone(),
      "Illegal argument in isolate message : (object is a closure - %s)",
      errorFunc.ToCString());
  SetWriteException(Exceptions::kArgument, chars);
  return Function::null();
}

RawClass* SnapshotWriter::GetFunctionOwner(RawFunction* func) {
  RawObject* owner = func->ptr()->owner_;
  uint32_t tags = GetObjectTags(owner);
  intptr_t class_id = RawObject::ClassIdTag::decode(tags);
  if (class_id == kClassCid) {
    return reinterpret_cast<RawClass*>(owner);
  }
  ASSERT(class_id == kPatchClassCid);
  return reinterpret_cast<RawPatchClass*>(owner)->ptr()->patched_class_;
}

void SnapshotWriter::CheckForNativeFields(RawClass* cls) {
  if (cls->ptr()->num_native_fields_ != 0) {
    // We do not allow objects with native fields in an isolate message.
    HANDLESCOPE(thread());
    const Class& clazz = Class::Handle(zone(), cls);
    char* chars = OS::SCreate(thread()->zone(),
                              "Illegal argument in isolate message"
                              " : (object extends NativeWrapper - %s)",
                              clazz.ToCString());
    SetWriteException(Exceptions::kArgument, chars);
  }
}

void SnapshotWriter::SetWriteException(Exceptions::ExceptionType type,
                                       const char* msg) {
  set_exception_type(type);
  set_exception_msg(msg);
  // The more specific error is set up in SnapshotWriter::ThrowException().
  thread()->long_jump_base()->Jump(1, Object::snapshot_writer_error());
}

void SnapshotWriter::WriteInstance(RawObject* raw,
                                   RawClass* cls,
                                   intptr_t tags,
                                   intptr_t object_id,
                                   bool as_reference) {
  // Closure instances are handled by RawClosure::WriteTo().
  ASSERT(!Class::IsClosureClass(cls));

  // Check if the instance has native fields and throw an exception if it does.
  CheckForNativeFields(cls);

  // Object is regular dart instance.
  if (as_reference) {
    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(kOmittedObjectId);

    // Indicate this is an instance object.
    Write<int32_t>(SerializedHeaderData::encode(kInstanceObjectId));
    WriteTags(tags);

    // Write out the class information for this object.
    WriteObjectImpl(cls, kAsInlinedObject);
  } else {
    intptr_t next_field_offset = cls->ptr()->next_field_offset_in_words_
                                 << kWordSizeLog2;
    ASSERT(next_field_offset > 0);

    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(object_id);

    // Indicate this is an instance object.
    Write<int32_t>(SerializedHeaderData::encode(kInstanceObjectId));

    // Write out the tags.
    WriteTags(tags);

    // Write out the class information for this object.
    WriteObjectImpl(cls, kAsInlinedObject);

    // Write out all the fields for the object.
    // Instance::NextFieldOffset() returns the offset of the first field in
    // a Dart object.
    bool write_as_reference = RawObject::IsCanonical(tags) ? false : true;
    intptr_t offset = Instance::NextFieldOffset();
    while (offset < next_field_offset) {
      RawObject* raw_obj = *reinterpret_cast<RawObject**>(
          reinterpret_cast<uword>(raw->ptr()) + offset);
      WriteObjectImpl(raw_obj, write_as_reference);
      offset += kWordSize;
    }
  }
  return;
}

bool SnapshotWriter::AllowObjectsInDartLibrary(RawLibrary* library) {
  return (library == object_store()->collection_library() ||
          library == object_store()->core_library() ||
          library == object_store()->typed_data_library());
}

intptr_t SnapshotWriter::FindVmSnapshotObject(RawObject* rawobj) {
  intptr_t length = Object::vm_isolate_snapshot_object_table().Length();
  for (intptr_t i = 0; i < length; i++) {
    if (Object::vm_isolate_snapshot_object_table().At(i) == rawobj) {
      return (i + kMaxPredefinedObjectIds);
    }
  }
  return kInvalidIndex;
}

void SnapshotWriter::ThrowException(Exceptions::ExceptionType type,
                                    const char* msg) {
  thread()->clear_sticky_error();
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

void SnapshotWriter::WriteVersionAndFeatures() {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_version), version_len);

  const char* expected_features =
      Dart::FeaturesString(Isolate::Current(), kind_);
  ASSERT(expected_features != NULL);
  const intptr_t features_len = strlen(expected_features);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_features),
             features_len + 1);
  free(const_cast<char*>(expected_features));
}

ScriptSnapshotWriter::ScriptSnapshotWriter(uint8_t** buffer, ReAlloc alloc)
    : SnapshotWriter(Thread::Current(),
                     Snapshot::kScript,
                     buffer,
                     alloc,
                     NULL,
                     kInitialSize,
                     &forward_list_,
                     true /* can_send_any_object */),
      forward_list_(thread(), kMaxPredefinedObjectIds) {
  ASSERT(buffer != NULL);
  ASSERT(alloc != NULL);
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
    WriteVersionAndFeatures();

    // Write out the library object.
    {
      NoSafepointScope no_safepoint;

      // Write out the library object.
      WriteObject(lib.raw());

      FillHeader(kind());
    }
  } else {
    ThrowException(exception_type(), exception_msg());
  }
}

void SnapshotWriterVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    writer_->WriteObjectImpl(raw_obj, as_references_);
  }
}

MessageWriter::MessageWriter(uint8_t** buffer,
                             ReAlloc alloc,
                             DeAlloc dealloc,
                             bool can_send_any_object,
                             intptr_t* buffer_len)
    : SnapshotWriter(Thread::Current(),
                     Snapshot::kMessage,
                     buffer,
                     alloc,
                     dealloc,
                     kInitialSize,
                     &forward_list_,
                     can_send_any_object),
      forward_list_(thread(), kMaxPredefinedObjectIds),
      buffer_len_(buffer_len) {
  ASSERT(buffer != NULL);
  ASSERT(alloc != NULL);
}

void MessageWriter::WriteMessage(const Object& obj) {
  ASSERT(kind() == Snapshot::kMessage);
  ASSERT(isolate() != NULL);

  // Setup for long jump in case there is an exception while writing
  // the message.
  LongJumpScope jump;
  if (setjmp(*jump.Set()) == 0) {
    NoSafepointScope no_safepoint;
    WriteObject(obj.raw());
    if (buffer_len_ != NULL) {
      *buffer_len_ = BytesWritten();
    }
  } else {
    FreeBuffer();
    ThrowException(exception_type(), exception_msg());
  }
}

}  // namespace dart
