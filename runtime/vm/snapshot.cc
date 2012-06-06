// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "platform/assert.h"
#include "vm/bigint_operations.h"
#include "vm/bootstrap.h"
#include "vm/exceptions.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

enum {
  kInstanceId = ObjectStore::kMaxId,
  kMaxPredefinedObjectIds,
};
static const int kNumInitialReferencesInFullSnapshot = 160 * KB;
static const int kNumInitialReferences = 4;


static bool IsSingletonClassId(intptr_t index) {
  // Check if this is a singleton object class which is shared by all isolates.
  return (index >= Object::kClassClass && index < Object::kMaxId);
}


static bool IsObjectStoreClassId(intptr_t index) {
  // Check if this is a class which is stored in the object store.
  return (index >= ObjectStore::kObjectClass && index < ObjectStore::kMaxId);
}


static bool IsObjectStoreTypeId(intptr_t index) {
  // Check if this is a type which is stored in the object store.
  return (index >= ObjectStore::kObjectType &&
          index <= ObjectStore::kListInterface);
}


// TODO(5411462): Temporary setup of snapshot for testing purposes,
// the actual creation of a snapshot maybe done differently.
const Snapshot* Snapshot::SetupFromBuffer(const void* raw_memory) {
  ASSERT(raw_memory != NULL);
  ASSERT(kHeaderSize == sizeof(Snapshot));
  ASSERT(kLengthIndex == length_offset());
  ASSERT((kSnapshotFlagIndex * sizeof(int32_t)) == kind_offset());
  ASSERT((kHeapObjectTag & kInlined));
  // No object can have kFreeBit and kMarkBit set simultaneously. If kFreeBit
  // is set then the rest of tags is a pointer to the next FreeListElement which
  // is kObjectAlignment aligned and has at least 2 lower bits set to zero.
  ASSERT(kObjectId ==
         ((1 << RawObject::kFreeBit) | (1 << RawObject::kMarkBit)));
  ASSERT((kObjectAlignmentMask & kObjectId) == kObjectId);
  const Snapshot* snapshot = reinterpret_cast<const Snapshot*>(raw_memory);
  return snapshot;
}


RawSmi* BaseReader::ReadAsSmi() {
  intptr_t value = ReadIntptrValue();
  ASSERT((value & kSmiTagMask) == 0);
  return reinterpret_cast<RawSmi*>(value);
}


intptr_t BaseReader::ReadSmiValue() {
  return  Smi::Value(ReadAsSmi());
}


SnapshotReader::SnapshotReader(const Snapshot* snapshot, Isolate* isolate)
    : BaseReader(snapshot->content(), snapshot->length()),
      kind_(snapshot->kind()),
      isolate_(isolate),
      cls_(Class::Handle()),
      obj_(Object::Handle()),
      str_(String::Handle()),
      library_(Library::Handle()),
      type_(AbstractType::Handle()),
      type_arguments_(AbstractTypeArguments::Handle()),
      backward_references_((snapshot->kind() == Snapshot::kFull) ?
                           kNumInitialReferencesInFullSnapshot :
                           kNumInitialReferences) {
}


RawObject* SnapshotReader::ReadObject() {
  int64_t value = Read<int64_t>();
  if ((value & kSmiTagMask) == 0) {
    return Integer::New((value >> kSmiTagShift));
  }
  ASSERT((value <= kIntptrMax) && (value >= kIntptrMin));
  return ReadObjectImpl(value);
}


RawClass* SnapshotReader::ReadClassId(intptr_t object_id) {
  ASSERT(kind_ != Snapshot::kFull);
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();
  ASSERT((class_header & kSmiTagMask) != 0);
  Class& cls = Class::ZoneHandle(isolate(), Class::null());
  cls ^= LookupInternalClass(class_header);
  AddBackwardReference(object_id, &cls);
  if (cls.IsNull()) {
    // Read the library/class information and lookup the class.
    str_ ^= ReadObjectImpl(class_header);
    library_ = Library::LookupLibrary(str_);
    ASSERT(!library_.IsNull());
    str_ ^= ReadObject();
    cls ^= library_.LookupClass(str_);
  }
  ASSERT(!cls.IsNull());
  return cls.raw();
}


void SnapshotReader::AddBackwardReference(intptr_t id, Object* obj) {
  ASSERT((id - kMaxPredefinedObjectIds) == backward_references_.length());
  backward_references_.Add(obj);
}


void SnapshotReader::ReadFullSnapshot() {
  ASSERT(kind_ == Snapshot::kFull);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ObjectStore* object_store = isolate->object_store();
  ASSERT(object_store != NULL);
  NoGCScope no_gc;

  // TODO(asiva): Add a check here to ensure we have the right heap
  // size for the full snapshot being read.

  // Read in all the objects stored in the object store.
  intptr_t num_flds = (object_store->to() - object_store->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(object_store->from() + i) = ReadObject();
  }

  // Setup native resolver for bootstrap impl.
  Bootstrap::SetupNativeResolver();
}


#define ALLOC_NEW_OBJECT_WITH_LEN(type, class_obj, length)                     \
  ASSERT(kind_ == Snapshot::kFull);                                            \
  ASSERT(isolate()->no_gc_scope_depth() != 0);                                 \
  cls_ = class_obj;                                                            \
  Raw##type* obj = reinterpret_cast<Raw##type*>(                               \
      AllocateUninitialized(cls_, type::InstanceSize(length)));                \
  obj->ptr()->length_ = Smi::New(length);                                      \
  return obj;                                                                  \


RawArray* SnapshotReader::NewArray(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(Array, object_store()->array_class(), len);
}


RawImmutableArray* SnapshotReader::NewImmutableArray(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(ImmutableArray,
                            object_store()->immutable_array_class(),
                            len);
}


RawOneByteString* SnapshotReader::NewOneByteString(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(OneByteString,
                            object_store()->one_byte_string_class(),
                            len);
}


RawTwoByteString* SnapshotReader::NewTwoByteString(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(TwoByteString,
                            object_store()->two_byte_string_class(),
                            len);
}


RawFourByteString* SnapshotReader::NewFourByteString(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(FourByteString,
                            object_store()->four_byte_string_class(),
                            len);
}


RawTypeArguments* SnapshotReader::NewTypeArguments(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(TypeArguments,
                            Object::type_arguments_class(),
                            len);
}


RawTokenStream* SnapshotReader::NewTokenStream(intptr_t len) {
  ALLOC_NEW_OBJECT_WITH_LEN(TokenStream,
                            Object::token_stream_class(),
                            len);
}


RawContext* SnapshotReader::NewContext(intptr_t num_variables) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  cls_ = Object::context_class();
  RawContext* obj = reinterpret_cast<RawContext*>(
      AllocateUninitialized(cls_, Context::InstanceSize(num_variables)));
  obj->ptr()->num_variables_ = num_variables;
  return obj;
}


RawClass* SnapshotReader::NewClass(int value) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  ObjectKind object_kind = static_cast<ObjectKind>(value);
  if ((object_kind == kInstance || object_kind == kClosure)) {
    cls_ = Object::class_class();
    RawClass* obj = reinterpret_cast<RawClass*>(
        AllocateUninitialized(cls_, Class::InstanceSize()));
    if (object_kind == kInstance) {
      Instance fake;
      obj->ptr()->handle_vtable_ = fake.vtable();
    } else {
      Closure fake;
      obj->ptr()->handle_vtable_ = fake.vtable();
    }
    cls_ = obj;
    cls_.set_instance_kind(object_kind);
    cls_.set_id(kIllegalObjectKind);
    isolate()->class_table()->Register(cls_);
    return cls_.raw();
  }
  return Class::GetClass(object_kind);
}


RawMint* SnapshotReader::NewMint(int64_t value) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  cls_ = object_store()->mint_class();
  RawMint* obj = reinterpret_cast<RawMint*>(
      AllocateUninitialized(cls_, Mint::InstanceSize()));
  obj->ptr()->value_ = value;
  return obj;
}


RawBigint* SnapshotReader::NewBigint(const char* hex_string) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  cls_ = object_store()->bigint_class();
  intptr_t bigint_length = BigintOperations::ComputeChunkLength(hex_string);
  RawBigint* obj = reinterpret_cast<RawBigint*>(
      AllocateUninitialized(cls_, Bigint::InstanceSize(bigint_length)));
  obj->ptr()->allocated_length_ = bigint_length;
  obj->ptr()->signed_length_ = bigint_length;
  BigintOperations::FromHexCString(hex_string, Bigint::Handle(obj));
  return obj;
}


RawDouble* SnapshotReader::NewDouble(double value) {
  ASSERT(kind_ == Snapshot::kFull);
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  cls_ = object_store()->double_class();
  RawDouble* obj = reinterpret_cast<RawDouble*>(
      AllocateUninitialized(cls_, Double::InstanceSize()));
  obj->ptr()->value_ = value;
  return obj;
}


#define ALLOC_NEW_OBJECT(type, class_obj)                                      \
  ASSERT(kind_ == Snapshot::kFull);                                            \
  ASSERT(isolate()->no_gc_scope_depth() != 0);                                 \
  cls_ = class_obj;                                                            \
  return reinterpret_cast<Raw##type*>(                                         \
      AllocateUninitialized(cls_, type::InstanceSize()));                      \


RawUnresolvedClass* SnapshotReader::NewUnresolvedClass() {
  ALLOC_NEW_OBJECT(UnresolvedClass, Object::unresolved_class_class());
}


RawType* SnapshotReader::NewType() {
  ALLOC_NEW_OBJECT(Type, Object::type_class());
}


RawTypeParameter* SnapshotReader::NewTypeParameter() {
  ALLOC_NEW_OBJECT(TypeParameter, Object::type_parameter_class());
}


RawFunction* SnapshotReader::NewFunction() {
  ALLOC_NEW_OBJECT(Function, Object::function_class());
}


RawField* SnapshotReader::NewField() {
  ALLOC_NEW_OBJECT(Field, Object::field_class());
}


RawLibrary* SnapshotReader::NewLibrary() {
  ALLOC_NEW_OBJECT(Library, Object::library_class());
}


RawLibraryPrefix* SnapshotReader::NewLibraryPrefix() {
  ALLOC_NEW_OBJECT(LibraryPrefix, Object::library_prefix_class());
}


RawScript* SnapshotReader::NewScript() {
  ALLOC_NEW_OBJECT(Script, Object::script_class());
}


RawLiteralToken* SnapshotReader::NewLiteralToken() {
  ALLOC_NEW_OBJECT(LiteralToken, Object::literal_token_class());
}


RawGrowableObjectArray* SnapshotReader::NewGrowableObjectArray() {
  ALLOC_NEW_OBJECT(GrowableObjectArray,
                   object_store()->growable_object_array_class());
}


RawClass* SnapshotReader::LookupInternalClass(intptr_t class_header) {
  SerializedHeaderType header_type = SerializedHeaderTag::decode(class_header);

  // If the header is an object Id, lookup singleton VM classes or classes
  // stored in the object store.
  if (header_type == kObjectId) {
    intptr_t header_value = SerializedHeaderData::decode(class_header);
    if (IsObjectStoreClassId(header_value)) {
      return object_store()->GetClass(header_value);
    } else if (IsSingletonClassId(header_value)) {
      return Object::GetSingletonClass(header_value);  // return the singleton.
    }
  }
  return Class::null();
}


RawObject* SnapshotReader::AllocateUninitialized(const Class& cls,
                                                 intptr_t size) {
  ASSERT(isolate()->no_gc_scope_depth() != 0);
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  Heap* heap = isolate()->heap();

  uword address = heap->TryAllocate(size, Heap::kOld);
  if (address == 0) {
    // Use the preallocated out of memory exception to avoid calling
    // into dart code or allocating any code.
    const Instance& exception =
        Instance::Handle(object_store()->out_of_memory());
    Exceptions::Throw(exception);
    UNREACHABLE();
  }
  RawObject* raw_obj = reinterpret_cast<RawObject*>(address + kHeapObjectTag);
  uword tags = 0;
  intptr_t index = cls.id();
  ASSERT(index != kIllegalObjectKind);
  tags = RawObject::ClassIdTag::update(index, tags);
  tags = RawObject::SizeTag::update(size, tags);
  raw_obj->ptr()->tags_ = tags;
  return raw_obj;
}


RawObject* SnapshotReader::ReadObjectImpl(intptr_t header) {
  SerializedHeaderType header_type = SerializedHeaderTag::decode(header);
  intptr_t header_value = SerializedHeaderData::decode(header);

  if (header_type == kObjectId) {
    return ReadIndexedObject(header_value);
  }
  ASSERT(header_type == kInlined);
  return ReadInlinedObject(header_value);
}


RawObject* SnapshotReader::ReadIndexedObject(intptr_t object_id) {
  if (object_id == Object::kNullObject) {
    // This is a singleton null object, return it.
    return Object::null();
  }
  if (object_id == Object::kSentinelObject) {
    return Object::sentinel();
  }
  if (IsSingletonClassId(object_id)) {
    return Object::GetSingletonClass(object_id);  // return singleton object.
  } else if (IsObjectStoreClassId(object_id)) {
    return object_store()->GetClass(object_id);
  } else if (object_id == ObjectStore::kTrueValue) {
    return object_store()->true_value();
  } else if (object_id == ObjectStore::kFalseValue) {
    return object_store()->false_value();
  } else if (kind_ != Snapshot::kFull) {
    if (IsObjectStoreTypeId(object_id)) {
      return object_store()->GetType(object_id);  // return type object.
    }
  }

  ASSERT(object_id >= kMaxPredefinedObjectIds);
  intptr_t index = object_id - kMaxPredefinedObjectIds;
  ASSERT(index < backward_references_.length());
  return backward_references_[index]->raw();
}


RawObject* SnapshotReader::ReadInlinedObject(intptr_t object_id) {
  // Read the class header information and lookup the class.
  intptr_t class_header = ReadIntptrValue();
  intptr_t tags = ReadIntptrValue();
  if (SerializedHeaderData::decode(class_header) == kInstanceId) {
    // Object is regular dart instance.
    Instance& result = Instance::ZoneHandle(isolate(), Instance::null());
    AddBackwardReference(object_id, &result);

    cls_ ^= ReadObject();
    ASSERT(!cls_.IsNull());
    intptr_t instance_size = cls_.instance_size();
    ASSERT(instance_size > 0);
    // Allocate the instance and read in all the fields for the object.
    if (kind_ == Snapshot::kFull) {
      result ^= AllocateUninitialized(cls_, instance_size);
    } else {
      result ^= Object::Allocate(cls_, instance_size, Heap::kNew);
    }
    intptr_t offset = Object::InstanceSize();
    while (offset < instance_size) {
      obj_ = ReadObject();
      result.SetFieldAtOffset(offset, obj_);
      offset += kWordSize;
    }
    if (kind_ == Snapshot::kFull) {
      result.SetCreatedFromSnapshot();
    } else if (result.IsCanonical()) {
      result = result.Canonicalize();
    }
    return result.raw();
  } else {
    ASSERT((class_header & kSmiTagMask) != 0);
    cls_ ^= LookupInternalClass(class_header);
    ASSERT(!cls_.IsNull());
  }
  switch (cls_.instance_kind()) {
#define SNAPSHOT_READ(clazz)                                                   \
    case clazz::kInstanceKind: {                                               \
      obj_ = clazz::ReadFrom(this, object_id, tags, kind_);                    \
      break;                                                                   \
    }
    CLASS_LIST_NO_OBJECT(SNAPSHOT_READ)
#undef SNAPSHOT_READ
    default: UNREACHABLE(); break;
  }
  if (kind_ == Snapshot::kFull) {
    obj_.SetCreatedFromSnapshot();
  }
  return obj_.raw();
}


void SnapshotWriter::WriteObject(RawObject* rawobj) {
  // First check if object can be written as a simple predefined type.
  if (CheckAndWritePredefinedObject(rawobj)) {
    return;
  }
  // Now write the object out inline in the stream as follows:
  // - Object is seen for the first time (inlined as follows):
  //    (object size in multiples of kObjectAlignment | 0x1)
  //    serialized fields of the object
  //    ......
  WriteInlinedObject(rawobj);
}


void SnapshotWriter::UnmarkAll() {
  NoGCScope no_gc;
  for (intptr_t i = 0; i < forward_list_.length(); i++) {
    RawObject* raw = forward_list_[i]->raw();
    raw->ptr()->tags_ = forward_list_[i]->tags();  // Restore original tags.
  }
}


void SnapshotWriter::WriteFullSnapshot() {
  ASSERT(kind_ == Snapshot::kFull);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ObjectStore* object_store = isolate->object_store();
  ASSERT(object_store != NULL);

  // Write out all the objects in the object store of the isolate which
  // is the root set for all dart allocated objects at this point.
  SnapshotWriterVisitor visitor(this);
  object_store->VisitObjectPointers(&visitor);

  // Finalize the snapshot buffer.
  FinalizeBuffer();
}


uword SnapshotWriter::GetObjectTags(RawObject* raw) {
  uword tags = raw->ptr()->tags_;
  if (SerializedHeaderTag::decode(tags) == kObjectId) {
    intptr_t id = SerializedHeaderData::decode(tags);
    return forward_list_[id - kMaxPredefinedObjectIds]->tags();
  } else {
    return tags;
  }
}


intptr_t SnapshotWriter::MarkObject(RawObject* raw) {
  NoGCScope no_gc;
  intptr_t object_id = forward_list_.length() + kMaxPredefinedObjectIds;
  ASSERT(object_id <= kMaxObjectId);
  uword value = 0;
  value = SerializedHeaderTag::update(kObjectId, value);
  value = SerializedHeaderData::update(object_id, value);
  uword tags = raw->ptr()->tags_;
  raw->ptr()->tags_ = value;
  ForwardObjectNode* node = new ForwardObjectNode(raw, tags);
  ASSERT(node != NULL);
  forward_list_.Add(node);
  return object_id;
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

  // Check if it is a singleton null object which is shared by all isolates.
  if (rawobj == Object::null()) {
    WriteIndexedObject(Object::kNullObject);
    return true;
  }

  // Check if it is a singleton sentinel object which is shared by all isolates.
  if (rawobj == Object::sentinel()) {
    WriteIndexedObject(Object::kSentinelObject);
    return true;
  }

  // Check if it is a singleton class object which is shared by
  // all isolates.
  RawClass* raw_class = reinterpret_cast<RawClass*>(rawobj);
  intptr_t index = Object::GetSingletonClassIndex(raw_class);
  if (index != Object::kInvalidIndex) {
    WriteIndexedObject(index);
    return true;
  }

  // Check if it is a singleton boolean true value.
  if (rawobj == object_store()->true_value()) {
    WriteIndexedObject(ObjectStore::kTrueValue);
    return true;
  }

  // Check if it is a singleton boolean false value.
  if (rawobj == object_store()->false_value()) {
    WriteIndexedObject(ObjectStore::kFalseValue);
    return true;
  }

  // Check if it is a code object in that case just write a Null object
  // as we do not want code objects in the snapshot.
  if (RawObject::ClassIdTag::decode(GetObjectTags(rawobj)) == kCode) {
    WriteIndexedObject(Object::kNullObject);
    return true;
  }

  // Check if classes are not being serialized and it is preinitialized type.
  if (kind_ != Snapshot::kFull) {
    RawType* raw_type = reinterpret_cast<RawType*>(rawobj);
    index = object_store()->GetTypeIndex(raw_type);
    if (index != ObjectStore::kInvalidIndex) {
      WriteIndexedObject(index);
      return true;
    }
  }

  // Check if object has already been serialized, in that
  // case just write the object id out.
  uword tags = rawobj->ptr()->tags_;
  if (SerializedHeaderTag::decode(tags) == kObjectId) {
    intptr_t id = SerializedHeaderData::decode(tags);
    WriteIndexedObject(id);
    return true;
  }

  return false;
}


void SnapshotWriter::WriteInlinedObject(RawObject* raw) {
  NoGCScope no_gc;
  uword tags = raw->ptr()->tags_;
  RawClass* cls = class_table_->At(RawObject::ClassIdTag::decode(tags));

  // Object is being serialized, add it to the forward ref list and mark
  // it so that future references to this object in the snapshot will use
  // an object id, instead of trying to serialize it again.
  intptr_t object_id = MarkObject(raw);

  ObjectKind kind = cls->ptr()->instance_kind_;
  if (kind == Instance::kInstanceKind) {
    // Object is regular dart instance.
    // TODO(5411462): figure out what we need to do if an object with native
    // fields is serialized (throw exception or serialize a null object).
    ASSERT(cls->ptr()->num_native_fields_ == 0);
    intptr_t instance_size = cls->ptr()->instance_size_;
    ASSERT(instance_size != 0);

    // Write out the serialization header value for this object.
    WriteSerializationMarker(kInlined, object_id);

    // Indicate this is an instance object.
    WriteIntptrValue(SerializedHeaderData::encode(kInstanceId));

    // Write out the tags.
    WriteIntptrValue(tags);

    // Write out the class information for this object.
    WriteObject(cls);

    // Write out all the fields for the object.
    intptr_t offset = Object::InstanceSize();
    while (offset < instance_size) {
      WriteObject(*reinterpret_cast<RawObject**>(
          reinterpret_cast<uword>(raw->ptr()) + offset));
      offset += kWordSize;
    }
    return;
  }
  switch (kind) {
#define SNAPSHOT_WRITE(clazz)                                                  \
    case clazz::kInstanceKind: {                                               \
      Raw##clazz* raw_obj = reinterpret_cast<Raw##clazz*>(raw);                \
      raw_obj->WriteTo(this, object_id, kind_);                                \
      return;                                                                  \
    }                                                                          \

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
    default: break;
  }
  UNREACHABLE();
}


void SnapshotWriter::WriteClassId(RawClass* cls) {
  ASSERT(kind_ != Snapshot::kFull);
  int id = object_store()->GetClassIndex(cls);
  if (IsSingletonClassId(id) || IsObjectStoreClassId(id)) {
    WriteIndexedObject(id);
  } else {
    // TODO(5411462): Should restrict this to only core-lib classes in this
    // case.
    // Write out the class and tags information.
    WriteObjectHeader(Object::kClassClass, cls->ptr()->tags_);

    // Write out the library url and class name.
    RawLibrary* library = cls->ptr()->library_;
    ASSERT(library != Library::null());
    WriteObject(library->ptr()->url_);
    WriteObject(cls->ptr()->name_);
  }
}


void ScriptSnapshotWriter::WriteScriptSnapshot(const Library& lib) {
  ASSERT(kind() == Snapshot::kScript);

  // Write out the library object.
  WriteObject(lib.raw());

  // Finalize the snapshot buffer.
  FinalizeBuffer();
}


void SnapshotWriterVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    writer_->WriteObject(raw_obj);
  }
}

}  // namespace dart
