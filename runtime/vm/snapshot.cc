// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/snapshot.h"

#include "vm/assert.h"
#include "vm/bootstrap.h"
#include "vm/heap.h"
#include "vm/object.h"
#include "vm/object_store.h"

namespace dart {

enum {
  kInstanceId = ObjectStore::kMaxId,
  kMaxPredefinedObjectIds,
};


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
  ASSERT((kSnapshotFlagIndex * sizeof(int32_t)) == full_snapshot_offset());
  ASSERT((kHeapObjectTag & kInlined));
  ASSERT((kHeapObjectTag & kObjectId));
  ASSERT((kObjectAlignmentMask & kObjectId) == kObjectId);
  const Snapshot* snapshot = reinterpret_cast<const Snapshot*>(raw_memory);
  return snapshot;
}


RawObject* SnapshotReader::ReadObject() {
  intptr_t header = Read<intptr_t>();
  if ((header & kSmiTagMask) == 0) {
    return reinterpret_cast<RawObject*>(header);
  }
  return ReadObjectImpl(header);
}


RawClass* SnapshotReader::ReadClassId(intptr_t object_id) {
  ASSERT(!classes_serialized_);
  // Read the class header information and lookup the class.
  intptr_t class_header = Read<intptr_t>();
  ASSERT((class_header & kSmiTagMask) != 0);
  Class& cls = Class::Handle();
  cls ^= LookupInternalClass(class_header);
  AddBackwardReference(object_id, &cls);
  if (cls.IsNull()) {
    // Read the library/class information and lookup the class.
    String& library_url = String::Handle();
    library_url ^= ReadObjectImpl(class_header);
    String& class_name = String::Handle();
    class_name ^= ReadObject();
    const Library& library =
        Library::Handle(Library::LookupLibrary(library_url));
    ASSERT(!library.IsNull());
    cls ^= library.LookupClass(class_name);
  }
  ASSERT(!cls.IsNull());
  return cls.raw();
}


void SnapshotReader::AddBackwardReference(intptr_t id, Object* obj) {
  ASSERT((id - kMaxPredefinedObjectIds) == backward_references_.length());
  backward_references_.Add(obj);
}


void SnapshotReader::ReadFullSnapshot() {
  ASSERT(classes_serialized_);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ObjectStore* object_store = isolate->object_store();
  ASSERT(object_store != NULL);

  // Read in all the objects stored in the object store.
  intptr_t num_flds = (object_store->to() - object_store->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(object_store->from() + i) = ReadObject();
  }

  // Setup native resolver for bootstrap impl.
  Bootstrap::SetupNativeResolver();
}


RawClass* SnapshotReader::LookupInternalClass(intptr_t class_header) {
  SerializedHeaderType header_type = SerializedHeaderTag::decode(class_header);
  intptr_t header_value = SerializedHeaderData::decode(class_header);

  // If the header is an object Id, lookup singleton VM classes or classes
  // stored in the object store.
  if (header_type == kObjectId) {
    if (IsSingletonClassId(header_value)) {
      return Object::GetSingletonClass(header_value);  // return the singleton.
    } else if (IsObjectStoreClassId(header_value)) {
      return object_store()->GetClass(header_value);
    }
  }
  return Class::null();
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
  } else if (!classes_serialized_) {
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
  intptr_t class_header = Read<intptr_t>();
  Class& cls = Class::Handle();
  if (SerializedHeaderData::decode(class_header) == kInstanceId) {
    // Object is regular dart instance.
    Instance& result = Instance::ZoneHandle();
    AddBackwardReference(object_id, &result);

    cls ^= ReadObject();
    ASSERT(!cls.IsNull());
    intptr_t instance_size = cls.instance_size();
    ASSERT(instance_size > 0);
    // Allocate the instance and read in all the fields for the object.
    RawObject* raw = Object::Allocate(cls, instance_size, Heap::kNew);
    result ^= raw;
    intptr_t offset = Object::InstanceSize();
    Object& obj = Object::Handle();
    while (offset < instance_size) {
      obj = ReadObject();
      result.SetFieldAtOffset(offset, obj);
      offset += kWordSize;
    }
    return result.raw();
  } else {
    ASSERT((class_header & kSmiTagMask) != 0);
    cls ^= LookupInternalClass(class_header);
    ASSERT(!cls.IsNull());
  }
  switch (cls.instance_kind()) {
#define SNAPSHOT_READ(clazz)                                                   \
    case clazz::kInstanceKind: {                                               \
      return clazz::ReadFrom(this, object_id, classes_serialized_);            \
    }
    CLASS_LIST_NO_OBJECT(SNAPSHOT_READ)
#undef SNAPSHOT_READ
    default: break;
  }
  UNREACHABLE();
  return Object::null();
}


void MessageWriter::WriteMessage(intptr_t field_count, intptr_t *data) {
  // Write out the serialization header value for this object.
  WriteObjectHeader(kInlined, kMaxPredefinedObjectIds);

  // Write out the class information.
  WriteObjectHeader(kObjectId, ObjectStore::kArrayClass);

  // Write out the length field.
  Write<RawObject*>(Smi::New(field_count));

  // Write out the type arguments.
  WriteObjectHeader(kObjectId, Object::kNullObject);

  // Write out the individual Smis.
  for (int i = 0; i < field_count; i++) {
    Write<RawObject*>(Integer::New(data[i]));
  }

  FinalizeBuffer();
}


void SnapshotWriter::WriteObject(RawObject* rawobj) {
  // An object is written in one of the following ways:
  // - Smi: the Smi value is written as is (last bit is not tagged).
  // - VM internal class (from VM isolate): (index of class in vm isolate | 0x3)
  // - Object that has already been written: (negative id in stream | 0x3)
  // - Object that is seen for the first time (inlined as follows):
  //    (object size in multiples of kObjectAlignment | 0x1)
  //    serialized fields of the object
  //    ......

  NoGCScope no_gc;
  // writing a snap shot.

  // First check if it is a Smi (i.e not a heap object).
  if (!rawobj->IsHeapObject()) {
    Write<RawObject*>(rawobj);
    return;
  }

  // Check if it is a singleton null object which is shared by all isolates.
  if (rawobj == Object::null()) {
    WriteObjectHeader(kObjectId, Object::kNullObject);
    return;
  }

  // Check if it is a singleton sentinel object which is shared by all isolates.
  if (rawobj == Object::sentinel()) {
    WriteObjectHeader(kObjectId, Object::kSentinelObject);
    return;
  }

  // Check if it is a singleton class object which is shared by
  // all isolates.
  RawClass* raw_class = reinterpret_cast<RawClass*>(rawobj);
  intptr_t index = Object::GetSingletonClassIndex(raw_class);
  if (index != Object::kInvalidIndex) {
    WriteObjectHeader(kObjectId, index);
    return;
  }

  // Check if it is a singleton boolean true value.
  if (rawobj == object_store()->true_value()) {
    WriteObjectHeader(kObjectId, ObjectStore::kTrueValue);
    return;
  }

  // Check if it is a singleton boolean false value.
  if (rawobj == object_store()->false_value()) {
    WriteObjectHeader(kObjectId, ObjectStore::kFalseValue);
    return;
  }

  // Check if classes are not being serialized and it is preinitialized type.
  if (!serialize_classes_) {
    RawType* raw_type = reinterpret_cast<RawType*>(rawobj);
    index = object_store()->GetTypeIndex(raw_type);
    if (index != ObjectStore::kInvalidIndex) {
      WriteObjectHeader(kObjectId, index);
      return;
    }
  }

  // Now write the object out inline in the stream.
  WriteInlinedObject(rawobj);
}


void SnapshotWriter::WriteObjectHeader(SerializedHeaderType type, intptr_t id) {
  uword value = 0;
  value = SerializedHeaderTag::update(type, value);
  value = SerializedHeaderData::update(id, value);
  Write<uword>(value);
}


void SnapshotWriter::UnmarkAll() {
  NoGCScope no_gc;
  for (intptr_t i = 0; i < forward_list_.length(); i++) {
    RawObject* raw = forward_list_[i]->raw();
    raw->ptr()->class_ = forward_list_[i]->cls();  // Restore original class.
  }
}


void SnapshotWriter::WriteFullSnapshot() {
  ASSERT(serialize_classes_);
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


intptr_t SnapshotWriter::MarkObject(RawObject* raw, RawClass* cls) {
  NoGCScope no_gc;
  intptr_t object_id = forward_list_.length() + kMaxPredefinedObjectIds;
  uword value = 0;
  value = SerializedHeaderTag::update(kObjectId, value);
  value = SerializedHeaderData::update(object_id, value);
  raw->ptr()->class_ = reinterpret_cast<RawClass*>(value);
  ForwardObjectNode* node = new ForwardObjectNode(raw, cls);
  ASSERT(node != NULL);
  forward_list_.Add(node);
  return object_id;
}


void SnapshotWriter::WriteInlinedObject(RawObject* raw) {
  NoGCScope no_gc;
  RawClass* cls = raw->ptr()->class_;

  // Check if object has already been serialized, in that
  // case just write the object id out.
  if (SerializedHeaderTag::decode(reinterpret_cast<uword>(cls)) == kObjectId) {
    intptr_t id = SerializedHeaderData::decode(reinterpret_cast<intptr_t>(cls));
    WriteObjectHeader(kObjectId, id);
    return;
  }

  // Object is being serialized, add it to the forward ref list and mark
  // it so that future references to this object in the snapshot will use
  // an object id, instead of trying to serialize it again.
  intptr_t object_id = MarkObject(raw, cls);

  ObjectKind kind = cls->ptr()->instance_kind_;
  if (kind == Instance::kInstanceKind) {
    // Object is regular dart instance.
    // TODO(5411462): figure out what we need to do if an object with native
    // fields is serialized (throw exception or serialize a null object).
    ASSERT(cls->ptr()->num_native_fields_ == 0);
    intptr_t instance_size = cls->ptr()->instance_size_;
    ASSERT(instance_size != 0);

    // Write out the serialization header value for this object.
    WriteObjectHeader(kInlined, object_id);

    // Indicate this is an instance object.
    Write<intptr_t>(SerializedHeaderData::encode(kInstanceId));

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
      raw_obj->WriteTo(this, object_id, serialize_classes_);                   \
      return;                                                                  \
    }                                                                          \

    CLASS_LIST_NO_OBJECT(SNAPSHOT_WRITE)
#undef SNAPSHOT_WRITE
    default: break;
  }
  UNREACHABLE();
}


void SnapshotWriter::WriteClassId(RawClass* cls) {
  ASSERT(!serialize_classes_);
  int id = object_store()->GetClassIndex(cls);
  if (IsSingletonClassId(id) || IsObjectStoreClassId(id)) {
    WriteObjectHeader(kObjectId, id);
  } else {
    // TODO(5411462): Should restrict this to only core-lib classes in this
    // case.
    // Write out the class information.
    WriteObjectHeader(kObjectId, Object::kClassClass);
    // Write out the library url and class name.
    RawLibrary* library = cls->ptr()->library_;
    ASSERT(library != Library::null());
    WriteObject(library->ptr()->url_);
    WriteObject(cls->ptr()->name_);
  }
}


void SnapshotWriterVisitor::VisitPointers(RawObject** first, RawObject** last) {
  for (RawObject** current = first; current <= last; current++) {
    RawObject* raw_obj = *current;
    writer_->WriteObject(raw_obj);
  }
}

}  // namespace dart
