// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/exceptions.h"
#include "vm/heap/heap.h"
#include "vm/longjump.h"
#include "vm/message.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot_ids.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/type_testing_stubs.h"
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

static bool IsBootstrapedClassId(intptr_t class_id) {
  // Check if this is a class which is created during bootstrapping.
  return (class_id == kObjectCid ||
          (class_id >= kInstanceCid && class_id <= kUserTagCid) ||
          class_id == kArrayCid || class_id == kImmutableArrayCid ||
          IsStringClassId(class_id) || IsTypedDataClassId(class_id) ||
          IsExternalTypedDataClassId(class_id) ||
          IsTypedDataViewClassId(class_id) || class_id == kNullCid ||
          class_id == kNeverCid || class_id == kTransferableTypedDataCid);
}

static bool IsObjectStoreTypeId(intptr_t index) {
  // Check if this is a type which is stored in the object store.
  static_assert(kFirstTypeArgumentsSnapshotId == kLastTypeSnapshotId + 1,
                "Type and type arguments snapshot ids should be adjacent");
  return index >= kFirstTypeSnapshotId && index <= kLastTypeArgumentsSnapshotId;
}

static bool IsSplitClassId(intptr_t class_id) {
  // Return whether this class is serialized in two steps: first a reference,
  // with sufficient information to allocate a correctly sized object, and then
  // later inline with complete contents.
  return class_id >= kNumPredefinedCids || class_id == kArrayCid ||
         class_id == kImmutableArrayCid || class_id == kObjectPoolCid ||
         IsImplicitFieldClassId(class_id);
}

static intptr_t ClassIdFromObjectId(intptr_t object_id) {
  ASSERT(object_id > kClassIdsOffset);
  intptr_t class_id = (object_id - kClassIdsOffset);
  return class_id;
}

static intptr_t ObjectIdFromClassId(intptr_t class_id) {
  ASSERT((class_id > kIllegalCid) && (class_id < kNumPredefinedCids));
  return (class_id + kClassIdsOffset);
}

static ObjectPtr GetType(ObjectStore* object_store, intptr_t index) {
  switch (index) {
    case kLegacyObjectType:
      return object_store->legacy_object_type();
    case kNullableObjectType:
      return object_store->nullable_object_type();
    case kNullType:
      return object_store->null_type();
    case kNeverType:
      return object_store->never_type();
    case kLegacyFunctionType:
      return object_store->legacy_function_type();
    case kLegacyNumberType:
      return object_store->legacy_number_type();
    case kLegacySmiType:
      return object_store->legacy_smi_type();
    case kLegacyMintType:
      return object_store->legacy_mint_type();
    case kLegacyDoubleType:
      return object_store->legacy_double_type();
    case kLegacyIntType:
      return object_store->legacy_int_type();
    case kLegacyBoolType:
      return object_store->legacy_bool_type();
    case kLegacyStringType:
      return object_store->legacy_string_type();
    case kLegacyArrayType:
      return object_store->legacy_array_type();
    case kLegacyIntTypeArguments:
      return object_store->type_argument_legacy_int();
    case kLegacyDoubleTypeArguments:
      return object_store->type_argument_legacy_double();
    case kLegacyStringTypeArguments:
      return object_store->type_argument_legacy_string();
    case kLegacyStringDynamicTypeArguments:
      return object_store->type_argument_legacy_string_dynamic();
    case kLegacyStringLegacyStringTypeArguments:
      return object_store->type_argument_legacy_string_legacy_string();
    case kNonNullableObjectType:
      return object_store->non_nullable_object_type();
    case kNonNullableFunctionType:
      return object_store->non_nullable_function_type();
    case kNonNullableNumberType:
      return object_store->non_nullable_number_type();
    case kNonNullableSmiType:
      return object_store->non_nullable_smi_type();
    case kNonNullableMintType:
      return object_store->non_nullable_mint_type();
    case kNonNullableDoubleType:
      return object_store->non_nullable_double_type();
    case kNonNullableIntType:
      return object_store->non_nullable_int_type();
    case kNonNullableBoolType:
      return object_store->non_nullable_bool_type();
    case kNonNullableStringType:
      return object_store->non_nullable_string_type();
    case kNonNullableArrayType:
      return object_store->non_nullable_array_type();
    case kNonNullableIntTypeArguments:
      return object_store->type_argument_non_nullable_int();
    case kNonNullableDoubleTypeArguments:
      return object_store->type_argument_non_nullable_double();
    case kNonNullableStringTypeArguments:
      return object_store->type_argument_non_nullable_string();
    case kNonNullableStringDynamicTypeArguments:
      return object_store->type_argument_non_nullable_string_dynamic();
    case kNonNullableStringNonNullableStringTypeArguments:
      return object_store
          ->type_argument_non_nullable_string_non_nullable_string();
    default:
      break;
  }
  UNREACHABLE();
  return Type::null();
}

static intptr_t GetTypeIndex(ObjectStore* object_store,
                             const ObjectPtr raw_type) {
  if (raw_type == object_store->legacy_object_type()) {
    return kLegacyObjectType;
  } else if (raw_type == object_store->null_type()) {
    return kNullType;
  } else if (raw_type == object_store->never_type()) {
    return kNeverType;
  } else if (raw_type == object_store->legacy_function_type()) {
    return kLegacyFunctionType;
  } else if (raw_type == object_store->legacy_number_type()) {
    return kLegacyNumberType;
  } else if (raw_type == object_store->legacy_smi_type()) {
    return kLegacySmiType;
  } else if (raw_type == object_store->legacy_mint_type()) {
    return kLegacyMintType;
  } else if (raw_type == object_store->legacy_double_type()) {
    return kLegacyDoubleType;
  } else if (raw_type == object_store->legacy_int_type()) {
    return kLegacyIntType;
  } else if (raw_type == object_store->legacy_bool_type()) {
    return kLegacyBoolType;
  } else if (raw_type == object_store->legacy_string_type()) {
    return kLegacyStringType;
  } else if (raw_type == object_store->legacy_array_type()) {
    return kLegacyArrayType;
  } else if (raw_type == object_store->type_argument_legacy_int()) {
    return kLegacyIntTypeArguments;
  } else if (raw_type == object_store->type_argument_legacy_double()) {
    return kLegacyDoubleTypeArguments;
  } else if (raw_type == object_store->type_argument_legacy_string()) {
    return kLegacyStringTypeArguments;
  } else if (raw_type == object_store->type_argument_legacy_string_dynamic()) {
    return kLegacyStringDynamicTypeArguments;
  } else if (raw_type ==
             object_store->type_argument_legacy_string_legacy_string()) {
    return kLegacyStringLegacyStringTypeArguments;
  } else if (raw_type == object_store->non_nullable_object_type()) {
    return kNonNullableObjectType;
  } else if (raw_type == object_store->non_nullable_function_type()) {
    return kNonNullableFunctionType;
  } else if (raw_type == object_store->non_nullable_number_type()) {
    return kNonNullableNumberType;
  } else if (raw_type == object_store->non_nullable_smi_type()) {
    return kNonNullableSmiType;
  } else if (raw_type == object_store->non_nullable_mint_type()) {
    return kNonNullableMintType;
  } else if (raw_type == object_store->non_nullable_double_type()) {
    return kNonNullableDoubleType;
  } else if (raw_type == object_store->non_nullable_int_type()) {
    return kNonNullableIntType;
  } else if (raw_type == object_store->non_nullable_bool_type()) {
    return kNonNullableBoolType;
  } else if (raw_type == object_store->non_nullable_string_type()) {
    return kNonNullableStringType;
  } else if (raw_type == object_store->non_nullable_array_type()) {
    return kNonNullableArrayType;
  } else if (raw_type == object_store->type_argument_non_nullable_int()) {
    return kNonNullableIntTypeArguments;
  } else if (raw_type == object_store->type_argument_non_nullable_double()) {
    return kNonNullableDoubleTypeArguments;
  } else if (raw_type == object_store->type_argument_non_nullable_string()) {
    return kNonNullableStringTypeArguments;
  } else if (raw_type ==
             object_store->type_argument_non_nullable_string_dynamic()) {
    return kNonNullableStringDynamicTypeArguments;
  } else if (raw_type ==
             object_store
                 ->type_argument_non_nullable_string_non_nullable_string()) {
    return kNonNullableStringNonNullableStringTypeArguments;
  }
  return kInvalidIndex;
}

const char* Snapshot::KindToCString(Kind kind) {
  switch (kind) {
    case kFull:
      return "full";
    case kFullCore:
      return "full-core";
    case kFullJIT:
      return "full-jit";
    case kFullAOT:
      return "full-aot";
    case kMessage:
      return "message";
    case kNone:
      return "none";
    case kInvalid:
    default:
      return "invalid";
  }
}

const Snapshot* Snapshot::SetupFromBuffer(const void* raw_memory) {
  ASSERT(raw_memory != NULL);
  const Snapshot* snapshot = reinterpret_cast<const Snapshot*>(raw_memory);
  if (!snapshot->check_magic()) {
    return NULL;
  }
  // If the raw length is negative or greater than what the local machine can
  // handle, then signal an error.
  int64_t length = snapshot->large_length();
  if ((length < 0) || (length > kIntptrMax)) {
    return NULL;
  }
  return snapshot;
}

SmiPtr BaseReader::ReadAsSmi() {
  SmiPtr value = static_cast<SmiPtr>(Read<intptr_t>());
  ASSERT((static_cast<uword>(value) & kSmiTagMask) == kSmiTag);
  return value;
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
      code_(Code::Handle(zone_)),
      instance_(Instance::Handle(zone_)),
      instructions_(Instructions::Handle(zone_)),
      obj_(Object::Handle(zone_)),
      pobj_(PassiveObject::Handle(zone_)),
      array_(Array::Handle(zone_)),
      field_(Field::Handle(zone_)),
      str_(String::Handle(zone_)),
      library_(Library::Handle(zone_)),
      type_(AbstractType::Handle(zone_)),
      type_arguments_(TypeArguments::Handle(zone_)),
      tokens_(GrowableObjectArray::Handle(zone_)),
      data_(ExternalTypedData::Handle(zone_)),
      typed_data_base_(TypedDataBase::Handle(zone_)),
      typed_data_(TypedData::Handle(zone_)),
      typed_data_view_(TypedDataView::Handle(zone_)),
      function_(Function::Handle(zone_)),
      error_(UnhandledException::Handle(zone_)),
      set_class_(Class::ZoneHandle(
          zone_,
          thread_->isolate()->object_store()->linked_hash_set_class())),
      max_vm_isolate_object_id_(
          (Snapshot::IsFull(kind))
              ? Object::vm_isolate_snapshot_object_table().Length()
              : 0),
      backward_references_(backward_refs),
      types_to_postprocess_(GrowableObjectArray::Handle(zone_)),
      objects_to_rehash_(GrowableObjectArray::Handle(zone_)) {}

ObjectPtr SnapshotReader::ReadObject() {
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
    Object& result = Object::Handle(zone_);
    if (backward_references_->length() > 0) {
      result = (*backward_references_)[0].reference()->raw();
    } else {
      result = obj.raw();
    }
    RunDelayedTypePostprocessing();
    const Object& ok = Object::Handle(zone_, RunDelayedRehashingOfMaps());
    objects_to_rehash_ = GrowableObjectArray::null();
    if (!ok.IsNull()) {
      return ok.raw();
    }
    return result.raw();
  } else {
    // An error occurred while reading, return the error object.
    return Thread::Current()->StealStickyError();
  }
}

void SnapshotReader::EnqueueTypePostprocessing(const AbstractType& type) {
  if (types_to_postprocess_.IsNull()) {
    types_to_postprocess_ = GrowableObjectArray::New();
  }
  types_to_postprocess_.Add(type);
}

void SnapshotReader::RunDelayedTypePostprocessing() {
  if (types_to_postprocess_.IsNull()) {
    return;
  }

  AbstractType& type = AbstractType::Handle();
  Code& code = Code::Handle();
  for (intptr_t i = 0; i < types_to_postprocess_.Length(); ++i) {
    type ^= types_to_postprocess_.At(i);
    code = TypeTestingStubGenerator::DefaultCodeForType(type);
    type.SetTypeTestingStub(code);
  }
}

void SnapshotReader::EnqueueRehashingOfMap(const LinkedHashMap& map) {
  if (objects_to_rehash_.IsNull()) {
    objects_to_rehash_ = GrowableObjectArray::New();
  }
  objects_to_rehash_.Add(map);
}

ObjectPtr SnapshotReader::RunDelayedRehashingOfMaps() {
  if (!objects_to_rehash_.IsNull()) {
    const Library& collections_lib =
        Library::Handle(zone_, Library::CollectionLibrary());
    const Function& rehashing_function = Function::Handle(
        zone_,
        collections_lib.LookupFunctionAllowPrivate(Symbols::_rehashObjects()));
    ASSERT(!rehashing_function.IsNull());

    const Array& arguments = Array::Handle(zone_, Array::New(1));
    arguments.SetAt(0, objects_to_rehash_);

    return DartEntry::InvokeFunction(rehashing_function, arguments);
  }
  return Object::null();
}

ClassPtr SnapshotReader::ReadClassId(intptr_t object_id) {
  ASSERT(!Snapshot::IsFull(kind_));
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<int32_t>();
  ASSERT((class_header & kSmiTagMask) != kSmiTag);
  ASSERT(!IsVMIsolateObject(class_header) ||
         !IsSingletonClassId(GetVMIsolateObjectId(class_header)));
  ASSERT((SerializedHeaderTag::decode(class_header) != kObjectId) ||
         !IsBootstrapedClassId(SerializedHeaderData::decode(class_header)));
  Class& cls = Class::ZoneHandle(zone(), Class::null());
  AddBackRef(object_id, &cls, kIsDeserialized);
  // Read the library/class information and lookup the class.
  str_ ^= ReadObjectImpl(class_header, kAsInlinedObject);
  library_ = Library::LookupLibrary(thread(), str_);
  if (library_.IsNull() || !library_.Loaded()) {
    SetReadException(
        "Invalid object found in message: library is not found or loaded.");
  }
  str_ ^= ReadObjectImpl(kAsInlinedObject);
  if (str_.raw() == Symbols::TopLevel().raw()) {
    cls = library_.toplevel_class();
  } else {
    str_ = String::New(String::ScrubName(str_));
    cls = library_.LookupClassAllowPrivate(str_);
  }
  if (cls.IsNull()) {
    SetReadException("Invalid object found in message: class not found");
  }
  cls.EnsureIsFinalized(thread());
  return cls.raw();
}

ObjectPtr SnapshotReader::ReadStaticImplicitClosure(intptr_t object_id,
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
    str_ = String::New(String::ScrubName(str_));
    func = library_.LookupFunctionAllowPrivate(str_);
  } else {
    str_ = String::New(String::ScrubName(str_));
    cls_ = library_.LookupClassAllowPrivate(str_);
    if (cls_.IsNull()) {
      OS::PrintErr("Name of class not found %s\n", str_.ToCString());
      SetReadException("Invalid Class object found in message.");
    }
    cls_.EnsureIsFinalized(thread());
    str_ ^= ReadObjectImpl(kAsInlinedObject);
    str_ = String::New(String::ScrubName(str_));
    func = cls_.LookupFunctionAllowPrivate(str_);
  }
  if (func.IsNull()) {
    SetReadException("Invalid function object found in message.");
  }
  TypeArguments& delayed_type_arguments = TypeArguments::Handle(zone());
  delayed_type_arguments ^= ReadObjectImpl(kAsInlinedObject);

  func = func.ImplicitClosureFunction();
  ASSERT(!func.IsNull());

  // If delayedtype arguments were provided, create and return new closure with
  // those, otherwise return associated implicit static closure.
  // Note that static closures can't have instantiator or function types since
  // statics can't refer to class type arguments, don't have outer functions.
  if (!delayed_type_arguments.IsNull()) {
    const Context& context = Context::Handle(zone());
    obj = Closure::New(
        /*instantiator_type_arguments=*/Object::null_type_arguments(),
        /*function_type_arguments=*/Object::null_type_arguments(),
        delayed_type_arguments, func, context, Heap::kOld);
  } else {
    obj = func.ImplicitStaticClosure();
  }
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

ObjectPtr SnapshotReader::VmIsolateSnapshotObject(intptr_t index) const {
  return Object::vm_isolate_snapshot_object_table().At(index);
}

bool SnapshotReader::is_vm_isolate() const {
  return isolate() == Dart::vm_isolate();
}

ObjectPtr SnapshotReader::ReadObjectImpl(bool as_reference) {
  int64_t header_value = Read<int64_t>();
  if ((header_value & kSmiTagMask) == kSmiTag) {
    return NewInteger(header_value);
  }
  ASSERT((header_value <= kIntptrMax) && (header_value >= kIntptrMin));
  return ReadObjectImpl(static_cast<intptr_t>(header_value), as_reference);
}

ObjectPtr SnapshotReader::ReadObjectImpl(intptr_t header_value,
                                         bool as_reference) {
  if (IsVMIsolateObject(header_value)) {
    return ReadVMIsolateObject(header_value);
  }
  if (SerializedHeaderTag::decode(header_value) == kObjectId) {
    return ReadIndexedObject(SerializedHeaderData::decode(header_value));
  }
  ASSERT(SerializedHeaderTag::decode(header_value) == kInlined);
  intptr_t object_id = SerializedHeaderData::decode(header_value);
  if (object_id == kOmittedObjectId) {
    object_id = NextAvailableObjectId();
  }

  // Read the class header information.
  intptr_t class_header = Read<int32_t>();
  intptr_t tags = ReadTags();
  bool read_as_reference = as_reference && !ObjectLayout::IsCanonical(tags);
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
      tags = ObjectLayout::ClassIdTag::update(class_id, tags);
      pobj_ =
          TypedData::ReadFrom(this, object_id, tags, kind_, read_as_reference);
      break;
    }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz) case kExternalTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
      tags = ObjectLayout::ClassIdTag::update(class_id, tags);
      pobj_ = ExternalTypedData::ReadFrom(this, object_id, tags, kind_, true);
      break;
    }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz) case kTypedData##clazz##ViewCid:

    case kByteDataViewCid:
      CLASS_LIST_TYPED_DATA(SNAPSHOT_READ) {
        tags = ObjectLayout::ClassIdTag::update(class_id, tags);
        pobj_ = TypedDataView::ReadFrom(this, object_id, tags, kind_, true);
        break;
      }
#undef SNAPSHOT_READ
#define SNAPSHOT_READ(clazz) case kFfi##clazz##Cid:

    CLASS_LIST_FFI(SNAPSHOT_READ) { UNREACHABLE(); }
#undef SNAPSHOT_READ
    default:
      UNREACHABLE();
      break;
  }
  return pobj_.raw();
}

void SnapshotReader::EnqueueRehashingOfSet(const Object& set) {
  if (objects_to_rehash_.IsNull()) {
    objects_to_rehash_ = GrowableObjectArray::New();
  }
  objects_to_rehash_.Add(set);
}

ObjectPtr SnapshotReader::ReadInstance(intptr_t object_id,
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
    instance_size = cls_.host_instance_size();
    ASSERT(instance_size > 0);
    // Allocate the instance and read in all the fields for the object.
    *result ^= Object::Allocate(cls_.id(), instance_size, Heap::kNew);
  } else {
    cls_ ^= ReadObjectImpl(kAsInlinedObject);
    ASSERT(!cls_.IsNull());
    instance_size = cls_.host_instance_size();
  }
  if (cls_.id() == set_class_.id()) {
    EnqueueRehashingOfSet(*result);
  }
  if (!as_reference) {
    // Read all the individual fields for inlined objects.
    intptr_t next_field_offset = cls_.host_next_field_offset();

    intptr_t type_argument_field_offset =
        cls_.host_type_arguments_field_offset();
    ASSERT(next_field_offset > 0);
    // Instance::NextFieldOffset() returns the offset of the first field in
    // a Dart object.
    bool read_as_reference = ObjectLayout::IsCanonical(tags) ? false : true;
    intptr_t offset = Instance::NextFieldOffset();
    intptr_t result_cid = result->GetClassId();

    const auto unboxed_fields =
        isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
            result_cid);

    while (offset < next_field_offset) {
      if (unboxed_fields.Get(offset / kWordSize)) {
        uword* p = reinterpret_cast<uword*>(result->raw_value() -
                                            kHeapObjectTag + offset);
        // Reads 32 bits of the unboxed value at a time
        *p = ReadWordWith32BitReads();
      } else {
        pobj_ = ReadObjectImpl(read_as_reference);
        result->SetFieldAtOffset(offset, pobj_);
        if ((offset != type_argument_field_offset) &&
            (kind_ == Snapshot::kMessage) && isolate()->use_field_guards() &&
            (pobj_.raw() != Object::sentinel().raw())) {
          // TODO(fschneider): Consider hoisting these lookups out of the loop.
          // This would involve creating a handle, since cls_ can't be reused
          // across the call to ReadObjectImpl.
          cls_ = isolate()->class_table()->At(result_cid);
          array_ = cls_.OffsetToFieldMap();
          field_ ^= array_.At(offset >> kWordSizeLog2);
          ASSERT(!field_.IsNull());
          ASSERT(field_.HostOffset() == offset);
          obj_ = pobj_.raw();
          field_.RecordStore(obj_);
        }
        // TODO(fschneider): Verify the guarded cid and length for other kinds
        // of snapshot (kFull, kScript) with asserts.
      }
      offset += kWordSize;
    }
    if (ObjectLayout::IsCanonical(tags)) {
      *result = result->Canonicalize(thread());
      ASSERT(!result->IsNull());
    }
  }
  return result->raw();
}

void SnapshotReader::AddBackRef(intptr_t id,
                                Object* obj,
                                DeserializeState state) {
  intptr_t index = (id - kMaxPredefinedObjectIds);
  ASSERT(index >= max_vm_isolate_object_id_);
  index -= max_vm_isolate_object_id_;
  ASSERT(index == backward_references_->length());
  BackRefNode node(obj, state);
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

ApiErrorPtr SnapshotReader::VerifyVersionAndFeatures(Isolate* isolate) {
  // If the version string doesn't match, return an error.
  // Note: New things are allocated only if we're going to return an error.

  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  if (PendingBytes() < version_len) {
    const intptr_t kMessageBufferSize = 128;
    char message_buffer[kMessageBufferSize];
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "No full snapshot version found, expected '%s'",
                   expected_version);
    // This can also fail while bringing up the VM isolate, so make sure to
    // allocate the error message in old space.
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }

  const char* version = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(version != NULL);
  if (strncmp(version, expected_version, version_len) != 0) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_version = Utils::StrNDup(version, version_len);
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "Wrong %s snapshot version, expected '%s' found '%s'",
                   (Snapshot::IsFull(kind_)) ? "full" : "script",
                   expected_version, actual_version);
    free(actual_version);
    // This can also fail while bringing up the VM isolate, so make sure to
    // allocate the error message in old space.
    const String& msg = String::Handle(String::New(message_buffer, Heap::kOld));
    return ApiError::New(msg, Heap::kOld);
  }
  Advance(version_len);

  const char* expected_features = Dart::FeaturesString(isolate, false, kind_);
  ASSERT(expected_features != NULL);
  const intptr_t expected_len = strlen(expected_features);

  const char* features = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(features != NULL);
  intptr_t buffer_len = Utils::StrNLen(features, PendingBytes());
  if ((buffer_len != expected_len) ||
      (strncmp(features, expected_features, expected_len) != 0)) {
    const intptr_t kMessageBufferSize = 256;
    char message_buffer[kMessageBufferSize];
    char* actual_features =
        Utils::StrNDup(features, buffer_len < 128 ? buffer_len : 128);
    Utils::SNPrint(message_buffer, kMessageBufferSize,
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

ObjectPtr SnapshotReader::NewInteger(int64_t value) {
  ASSERT((value & kSmiTagMask) == kSmiTag);
  value = value >> kSmiTagShift;
  if (Smi::IsValid(value)) {
    return Smi::New(static_cast<intptr_t>(value));
  }
  return Mint::NewCanonical(value);
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
  ASSERT(IsBootstrapedClassId(class_id) || IsSingletonClassId(class_id));
  return class_id;
}

#define READ_VM_SINGLETON_OBJ(id, obj)                                         \
  if (object_id == id) {                                                       \
    return obj;                                                                \
  }

ObjectPtr SnapshotReader::ReadVMIsolateObject(intptr_t header_value) {
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
  READ_VM_SINGLETON_OBJ(kEmptyTypeArguments,
                        Object::empty_type_arguments().raw());
  READ_VM_SINGLETON_OBJ(kTrueValue, Bool::True().raw());
  READ_VM_SINGLETON_OBJ(kFalseValue, Bool::False().raw());
  READ_VM_SINGLETON_OBJ(kExtractorParameterTypes,
                        Object::extractor_parameter_types().raw());
  READ_VM_SINGLETON_OBJ(kExtractorParameterNames,
                        Object::extractor_parameter_names().raw());
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

ObjectPtr SnapshotReader::ReadIndexedObject(intptr_t object_id) {
  intptr_t class_id = ClassIdFromObjectId(object_id);
  if (IsBootstrapedClassId(class_id)) {
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
  return GetBackRef(object_id)->raw();
}

void SnapshotReader::ArrayReadFrom(intptr_t object_id,
                                   const Array& result,
                                   intptr_t len,
                                   intptr_t tags) {
  // Setup the object fields.
  *TypeArgumentsHandle() ^= ReadObjectImpl(kAsInlinedObject);
  result.SetTypeArguments(*TypeArgumentsHandle());

  bool as_reference = ObjectLayout::IsCanonical(tags) ? false : true;
  for (intptr_t i = 0; i < len; i++) {
    *PassiveObjectHandle() = ReadObjectImpl(as_reference);
    result.SetAt(i, *PassiveObjectHandle());
  }
}

MessageSnapshotReader::MessageSnapshotReader(Message* message, Thread* thread)
    : SnapshotReader(message->snapshot(),
                     message->snapshot_length(),
                     Snapshot::kMessage,
                     new ZoneGrowableArray<BackRefNode>(kNumInitialReferences),
                     thread),
      finalizable_data_(message->finalizable_data()) {}

MessageSnapshotReader::~MessageSnapshotReader() {
  ResetBackwardReferenceTable();
}

SnapshotWriter::SnapshotWriter(Thread* thread,
                               Snapshot::Kind kind,
                               intptr_t initial_size,
                               ForwardList* forward_list,
                               bool can_send_any_object)
    : BaseWriter(initial_size),
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

void SnapshotWriter::WriteObject(ObjectPtr rawobj) {
  WriteObjectImpl(rawobj, kAsInlinedObject);
  WriteForwardedObjects();
}

uint32_t SnapshotWriter::GetObjectTags(ObjectPtr raw) {
  uword tags = raw->ptr()->tags_;
#if defined(HASH_IN_OBJECT_HEADER)
  // Clear hash to make the narrowing cast safe / appease UBSAN.
  tags = ObjectLayout::HashTag::update(0, tags);
#endif
  return tags;
}

uint32_t SnapshotWriter::GetObjectTags(ObjectLayout* raw) {
  uword tags = raw->tags_;
#if defined(HASH_IN_OBJECT_HEADER)
  // Clear hash to make the narrowing cast safe / appease UBSAN.
  tags = ObjectLayout::HashTag::update(0, tags);
#endif
  return tags;
}

uword SnapshotWriter::GetObjectTagsAndHash(ObjectPtr raw) {
  return raw->ptr()->tags_;
}

#define VM_OBJECT_CLASS_LIST(V)                                                \
  V(OneByteString)                                                             \
  V(TwoByteString)                                                             \
  V(Mint)                                                                      \
  V(Double)                                                                    \
  V(ImmutableArray)

#define VM_OBJECT_WRITE(clazz)                                                 \
  case clazz::kClassId: {                                                      \
    object_id = forward_list_->AddObject(zone(), rawobj, kIsSerialized);       \
    clazz##Ptr raw_obj = static_cast<clazz##Ptr>(rawobj);                      \
    raw_obj->ptr()->WriteTo(this, object_id, kind(), false);                   \
    return true;                                                               \
  }

#define WRITE_VM_SINGLETON_OBJ(obj, id)                                        \
  if (rawobj == obj) {                                                         \
    WriteVMIsolateObject(id);                                                  \
    return true;                                                               \
  }

bool SnapshotWriter::HandleVMIsolateObject(ObjectPtr rawobj) {
  // Check if it is one of the singleton VM objects.
  WRITE_VM_SINGLETON_OBJ(Object::null(), kNullObject);
  WRITE_VM_SINGLETON_OBJ(Object::sentinel().raw(), kSentinelObject);
  WRITE_VM_SINGLETON_OBJ(Object::transition_sentinel().raw(),
                         kTransitionSentinelObject);
  WRITE_VM_SINGLETON_OBJ(Object::empty_array().raw(), kEmptyArrayObject);
  WRITE_VM_SINGLETON_OBJ(Object::zero_array().raw(), kZeroArrayObject);
  WRITE_VM_SINGLETON_OBJ(Object::dynamic_type().raw(), kDynamicType);
  WRITE_VM_SINGLETON_OBJ(Object::void_type().raw(), kVoidType);
  WRITE_VM_SINGLETON_OBJ(Object::empty_type_arguments().raw(),
                         kEmptyTypeArguments);
  WRITE_VM_SINGLETON_OBJ(Bool::True().raw(), kTrueValue);
  WRITE_VM_SINGLETON_OBJ(Bool::False().raw(), kFalseValue);
  WRITE_VM_SINGLETON_OBJ(Object::extractor_parameter_types().raw(),
                         kExtractorParameterTypes);
  WRITE_VM_SINGLETON_OBJ(Object::extractor_parameter_names().raw(),
                         kExtractorParameterNames);
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
    ClassPtr raw_class = static_cast<ClassPtr>(rawobj);
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
    // We do this check down here, because it's quite expensive.
    if (!rawobj->ptr()->InVMIsolateHeap()) {
      return false;
    }

    switch (id) {
      VM_OBJECT_CLASS_LIST(VM_OBJECT_WRITE)
      case kTypedDataUint32ArrayCid: {
        object_id = forward_list_->AddObject(zone(), rawobj, kIsSerialized);
        TypedDataPtr raw_obj = static_cast<TypedDataPtr>(rawobj);
        raw_obj->ptr()->WriteTo(this, object_id, kind(), false);
        return true;
      }
      default:
        OS::PrintErr("class id = %" Pd "\n", id);
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
  isolate()->set_forward_table_new(new WeakTable());
  isolate()->set_forward_table_old(new WeakTable());
}

ForwardList::~ForwardList() {
  isolate()->set_forward_table_new(nullptr);
  isolate()->set_forward_table_old(nullptr);
}

intptr_t ForwardList::AddObject(Zone* zone,
                                ObjectPtr raw,
                                SerializeState state) {
  NoSafepointScope no_safepoint;
  intptr_t object_id = next_object_id();
  ASSERT(object_id > 0 && object_id <= kMaxObjectId);
  const Object& obj = Object::ZoneHandle(zone, raw);
  Node* node = new Node(&obj, state);
  ASSERT(node != NULL);
  nodes_.Add(node);
  ASSERT(object_id != 0);
  SetObjectId(raw, object_id);
  return object_id;
}

intptr_t ForwardList::FindObject(ObjectPtr raw) {
  NoSafepointScope no_safepoint;
  intptr_t id = GetObjectId(raw);
  ASSERT(id == 0 || NodeForObjectId(id)->obj()->raw() == raw);
  return (id == 0) ? static_cast<intptr_t>(kInvalidIndex) : id;
}

void ForwardList::SetObjectId(ObjectPtr object, intptr_t id) {
  if (object->IsNewObject()) {
    isolate()->forward_table_new()->SetValueExclusive(object, id);
  } else {
    isolate()->forward_table_old()->SetValueExclusive(object, id);
  }
}

intptr_t ForwardList::GetObjectId(ObjectPtr object) {
  if (object->IsNewObject()) {
    return isolate()->forward_table_new()->GetValueExclusive(object);
  } else {
    return isolate()->forward_table_old()->GetValueExclusive(object);
  }
}

bool SnapshotWriter::CheckAndWritePredefinedObject(ObjectPtr rawobj) {
  // Check if object can be written in one of the following ways:
  // - Smi: the Smi value is written as is (last bit is not tagged).
  // - VM internal class (from VM isolate): (index of class in vm isolate | 0x3)
  // - Object that has already been written: (negative id in stream | 0x3)

  NoSafepointScope no_safepoint;

  // First check if it is a Smi (i.e not a heap object).
  if (!rawobj->IsHeapObject()) {
    Write<int64_t>(static_cast<intptr_t>(rawobj));
    return true;
  }

  intptr_t cid = rawobj->GetClassId();

  if ((kind_ == Snapshot::kMessage) && (cid == kDoubleCid)) {
    WriteVMIsolateObject(kDoubleObject);
    DoublePtr rd = static_cast<DoublePtr>(rawobj);
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

  // Check if it is a code object in that case just write a Null object
  // as we do not want code objects in the snapshot.
  if (cid == kCodeCid) {
    WriteVMIsolateObject(kNullObject);
    return true;
  }

  // Now check if it is an object from the VM isolate. These objects are shared
  // by all isolates.
  if (HandleVMIsolateObject(rawobj)) {
    return true;
  }

  // Check if classes are not being serialized and it is preinitialized type
  // or a predefined internal VM class in the object store.
  // Check if it is an internal VM class which is in the object store.
  if (cid == kClassCid) {
    ClassPtr raw_class = static_cast<ClassPtr>(rawobj);
    intptr_t class_id = raw_class->ptr()->id_;
    if (IsBootstrapedClassId(class_id)) {
      intptr_t object_id = ObjectIdFromClassId(class_id);
      WriteIndexedObject(object_id);
      return true;
    }
  }

  // Now check it is a preinitialized type object.
  intptr_t index = GetTypeIndex(object_store(), rawobj);
  if (index != kInvalidIndex) {
    WriteIndexedObject(index);
    return true;
  }

  return false;
}

void SnapshotWriter::WriteObjectImpl(ObjectPtr raw, bool as_reference) {
  // First check if object can be written as a simple predefined type.
  if (CheckAndWritePredefinedObject(raw)) {
    return;
  }

  // When we know that we are dealing with leaf or shallow objects we write
  // these objects inline even when 'as_reference' is true.
  const bool write_as_reference = as_reference && !raw->ptr()->IsCanonical();
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

void SnapshotWriter::WriteMarkedObjectImpl(ObjectPtr raw,
                                           intptr_t tags,
                                           intptr_t object_id,
                                           bool as_reference) {
  NoSafepointScope no_safepoint;
  ClassPtr cls = class_table_->At(ObjectLayout::ClassIdTag::decode(tags));
  intptr_t class_id = cls->ptr()->id_;
  ASSERT(class_id == ObjectLayout::ClassIdTag::decode(tags));
  if (class_id >= kNumPredefinedCids || IsImplicitFieldClassId(class_id)) {
    WriteInstance(raw, cls, tags, object_id, as_reference);
    return;
  }
  switch (class_id) {
#define SNAPSHOT_WRITE(clazz)                                                  \
  case clazz::kClassId: {                                                      \
    clazz##Ptr raw_obj = static_cast<clazz##Ptr>(raw);                         \
    raw_obj->ptr()->WriteTo(this, object_id, kind_, as_reference);             \
    return;                                                                    \
  }

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz) case kTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      TypedDataPtr raw_obj = static_cast<TypedDataPtr>(raw);
      raw_obj->ptr()->WriteTo(this, object_id, kind_, as_reference);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz) case kExternalTypedData##clazz##Cid:

    CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
      ExternalTypedDataPtr raw_obj = static_cast<ExternalTypedDataPtr>(raw);
      raw_obj->ptr()->WriteTo(this, object_id, kind_, as_reference);
      return;
    }
#undef SNAPSHOT_WRITE
#define SNAPSHOT_WRITE(clazz) case kTypedData##clazz##ViewCid:

    case kByteDataViewCid:
      CLASS_LIST_TYPED_DATA(SNAPSHOT_WRITE) {
        auto raw_obj = static_cast<TypedDataViewPtr>(raw);
        raw_obj->ptr()->WriteTo(this, object_id, kind_, as_reference);
        return;
      }
#undef SNAPSHOT_WRITE

#define SNAPSHOT_WRITE(clazz) case kFfi##clazz##Cid:

      CLASS_LIST_FFI(SNAPSHOT_WRITE) {
        SetWriteException(Exceptions::kArgument,
                          "Native objects (from dart:ffi) such as Pointers and "
                          "Structs cannot be passed between isolates.");
        UNREACHABLE();
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

  virtual void VisitObject(ObjectPtr obj) {
    intptr_t object_id = writer_->forward_list_->FindObject(obj);
    ASSERT(object_id != kInvalidIndex);
    intptr_t tags = MessageWriter::GetObjectTagsAndHash(ObjectPtr(obj));
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
      ObjectPtr raw = NodeForObjectId(id)->obj()->raw();
      writer->VisitObject(raw);

      // Mark object as serialized.
      NodeForObjectId(id)->set_state(kIsSerialized);
    }
  }
  first_unprocessed_object_id_ = next_object_id();
}

void SnapshotWriter::WriteClassId(ClassLayout* cls) {
  ASSERT(!Snapshot::IsFull(kind_));
  int class_id = cls->id_;
  ASSERT(!IsSingletonClassId(class_id) && !IsBootstrapedClassId(class_id));

  // Write out the library url and class name.
  LibraryPtr library = cls->library();
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url_, kAsInlinedObject);
  WriteObjectImpl(cls->name(), kAsInlinedObject);
}

void SnapshotWriter::WriteStaticImplicitClosure(
    intptr_t object_id,
    FunctionPtr func,
    intptr_t tags,
    TypeArgumentsPtr delayed_type_arguments) {
  // Write out the serialization header value for this object.
  WriteInlinedObjectHeader(object_id);

  // Indicate this is a static implicit closure object.
  Write<int32_t>(SerializedHeaderData::encode(kStaticImplicitClosureObjectId));

  // Write out the tags.
  WriteTags(tags);

  // Write out the library url, class name and signature function name.
  ClassPtr cls = GetFunctionOwner(func);
  ASSERT(cls != Class::null());
  LibraryPtr library = cls->ptr()->library();
  ASSERT(library != Library::null());
  WriteObjectImpl(library->ptr()->url(), kAsInlinedObject);
  WriteObjectImpl(cls->ptr()->name(), kAsInlinedObject);
  WriteObjectImpl(func->ptr()->name(), kAsInlinedObject);
  WriteObjectImpl(delayed_type_arguments, kAsInlinedObject);
}

void SnapshotWriter::ArrayWriteTo(intptr_t object_id,
                                  intptr_t array_kind,
                                  intptr_t tags,
                                  SmiPtr length,
                                  TypeArgumentsPtr type_arguments,
                                  ObjectPtr data[],
                                  bool as_reference) {
  if (as_reference) {
    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(kOmittedObjectId);

    // Write out the class information.
    WriteIndexedObject(array_kind);
    WriteTags(tags);

    // Write out the length field.
    Write<ObjectPtr>(length);
  } else {
    intptr_t len = Smi::Value(length);

    // Write out the serialization header value for this object.
    WriteInlinedObjectHeader(object_id);

    // Write out the class and tags information.
    WriteIndexedObject(array_kind);
    WriteTags(tags);

    // Write out the length field.
    Write<ObjectPtr>(length);

    // Write out the type arguments.
    WriteObjectImpl(type_arguments, kAsInlinedObject);

    // Write out the individual object ids.
    bool write_as_reference = ObjectLayout::IsCanonical(tags) ? false : true;
    for (intptr_t i = 0; i < len; i++) {
      WriteObjectImpl(data[i], write_as_reference);
    }
  }
}

FunctionPtr SnapshotWriter::IsSerializableClosure(ClosurePtr closure) {
  // Extract the function object to check if this closure
  // can be sent in an isolate message.
  FunctionPtr func = closure->ptr()->function();
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

ClassPtr SnapshotWriter::GetFunctionOwner(FunctionPtr func) {
  ObjectPtr owner = func->ptr()->owner();
  uword tags = GetObjectTags(owner);
  intptr_t class_id = ObjectLayout::ClassIdTag::decode(tags);
  if (class_id == kClassCid) {
    return static_cast<ClassPtr>(owner);
  }
  ASSERT(class_id == kPatchClassCid);
  return static_cast<PatchClassPtr>(owner)->ptr()->patched_class_;
}

void SnapshotWriter::CheckForNativeFields(ClassPtr cls) {
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

void SnapshotWriter::WriteInstance(ObjectPtr raw,
                                   ClassPtr cls,
                                   intptr_t tags,
                                   intptr_t object_id,
                                   bool as_reference) {
  // Closure instances are handled by ClosureLayout::WriteTo().
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
    intptr_t next_field_offset = Class::host_next_field_offset_in_words(cls)
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

    const auto unboxed_fields =
        isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
            cls->ptr()->id_);

    // Write out all the fields for the object.
    // Instance::NextFieldOffset() returns the offset of the first field in
    // a Dart object.
    bool write_as_reference = ObjectLayout::IsCanonical(tags) ? false : true;

    intptr_t offset = Instance::NextFieldOffset();
    while (offset < next_field_offset) {
      if (unboxed_fields.Get(offset / kWordSize)) {
        // Writes 32 bits of the unboxed value at a time
        const uword value = *reinterpret_cast<uword*>(
            reinterpret_cast<uword>(raw->ptr()) + offset);
        WriteWordWith32BitWrites(value);
      } else {
        ObjectPtr raw_obj = *reinterpret_cast<ObjectPtr*>(
            reinterpret_cast<uword>(raw->ptr()) + offset);
        WriteObjectImpl(raw_obj, write_as_reference);
      }
      offset += kWordSize;
    }
  }
  return;
}

bool SnapshotWriter::AllowObjectsInDartLibrary(LibraryPtr library) {
  return (library == object_store()->collection_library() ||
          library == object_store()->core_library() ||
          library == object_store()->typed_data_library());
}

intptr_t SnapshotWriter::FindVmSnapshotObject(ObjectPtr rawobj) {
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
  {
    NoSafepointScope no_safepoint;
    ErrorPtr error = thread()->StealStickyError();
    ASSERT(error == Object::snapshot_writer_error().raw());
  }

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
      Dart::FeaturesString(Isolate::Current(), false, kind_);
  ASSERT(expected_features != NULL);
  const intptr_t features_len = strlen(expected_features);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_features),
             features_len + 1);
  free(const_cast<char*>(expected_features));
}

void SnapshotWriterVisitor::VisitPointers(ObjectPtr* first, ObjectPtr* last) {
  ASSERT(Utils::IsAligned(first, sizeof(*first)));
  ASSERT(Utils::IsAligned(last, sizeof(*last)));
  for (ObjectPtr* current = first; current <= last; current++) {
    ObjectPtr raw_obj = *current;
    writer_->WriteObjectImpl(raw_obj, as_references_);
  }
}

MessageWriter::MessageWriter(bool can_send_any_object)
    : SnapshotWriter(Thread::Current(),
                     Snapshot::kMessage,
                     kInitialSize,
                     &forward_list_,
                     can_send_any_object),
      forward_list_(thread(), kMaxPredefinedObjectIds),
      finalizable_data_(new MessageFinalizableData()) {}

MessageWriter::~MessageWriter() {
  delete finalizable_data_;
}

std::unique_ptr<Message> MessageWriter::WriteMessage(
    const Object& obj,
    Dart_Port dest_port,
    Message::Priority priority) {
  ASSERT(kind() == Snapshot::kMessage);
  ASSERT(isolate() != NULL);

  // Setup for long jump in case there is an exception while writing
  // the message.
  volatile bool has_exception = false;
  {
    LongJumpScope jump;
    if (setjmp(*jump.Set()) == 0) {
      NoSafepointScope no_safepoint;
      WriteObject(obj.raw());
    } else {
      FreeBuffer();
      has_exception = true;
    }
  }
  if (has_exception) {
    ThrowException(exception_type(), exception_msg());
  } else {
    finalizable_data_->SerializationSucceeded();
  }

  MessageFinalizableData* finalizable_data = finalizable_data_;
  finalizable_data_ = nullptr;
  intptr_t size;
  uint8_t* buffer = Steal(&size);
  return Message::New(dest_port, buffer, size, finalizable_data, priority);
}

}  // namespace dart
