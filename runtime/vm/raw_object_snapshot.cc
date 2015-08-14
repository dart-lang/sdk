// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/visitor.h"

namespace dart {

#define NEW_OBJECT(type)                                                       \
  ((kind == Snapshot::kFull) ? reader->New##type() : type::New())

#define NEW_OBJECT_WITH_LEN(type, len)                                         \
  ((kind == Snapshot::kFull) ? reader->New##type(len) : type::New(len))

#define NEW_OBJECT_WITH_LEN_SPACE(type, len, kind)                             \
  ((kind == Snapshot::kFull) ?                                                 \
  reader->New##type(len) : type::New(len, HEAP_SPACE(kind)))

#define OFFSET_OF_FROM(obj)                                                    \
  obj.raw()->from() - reinterpret_cast<RawObject**>(obj.raw()->ptr())

RawClass* Class::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  Class& cls = Class::ZoneHandle(reader->zone(), Class::null());
  bool is_in_fullsnapshot = reader->Read<bool>();
  if ((kind == Snapshot::kFull) ||
      (kind == Snapshot::kScript && !is_in_fullsnapshot)) {
    // Read in the base information.
    classid_t class_id = reader->ReadClassIDValue();

    // Allocate class object of specified kind.
    if (kind == Snapshot::kFull) {
      cls = reader->NewClass(class_id);
    } else {
      if (class_id < kNumPredefinedCids) {
        ASSERT((class_id >= kInstanceCid) && (class_id <= kMirrorReferenceCid));
        cls = reader->isolate()->class_table()->At(class_id);
      } else {
        cls = New<Instance>(kIllegalCid);
      }
    }
    reader->AddBackRef(object_id, &cls, kIsDeserialized);

    // Set all non object fields.
    if (!RawObject::IsInternalVMdefinedClassId(class_id)) {
      // Instance size of a VM defined class is already set up.
      cls.set_instance_size_in_words(reader->Read<int32_t>());
      cls.set_next_field_offset_in_words(reader->Read<int32_t>());
    }
    cls.set_type_arguments_field_offset_in_words(reader->Read<int32_t>());
    cls.set_num_type_arguments(reader->Read<int16_t>());
    cls.set_num_own_type_arguments(reader->Read<int16_t>());
    cls.set_num_native_fields(reader->Read<uint16_t>());
    cls.set_token_pos(reader->Read<int32_t>());
    cls.set_state_bits(reader->Read<uint16_t>());

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (cls.raw()->to() - cls.raw()->from());
    intptr_t from_offset = OFFSET_OF_FROM(cls);
    for (intptr_t i = 0; i <= num_flds; i++) {
      (*reader->PassiveObjectHandle()) =
          reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
      cls.StorePointer((cls.raw()->from() + i),
                       reader->PassiveObjectHandle()->raw());
    }
    ASSERT(!cls.IsInFullSnapshot() || (kind == Snapshot::kFull));
  } else {
    cls ^= reader->ReadClassId(object_id);
    ASSERT((kind == Snapshot::kMessage) || cls.IsInFullSnapshot());
  }
  return cls.raw();
}


void RawClass::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  bool is_in_fullsnapshot = Class::IsInFullSnapshot(this);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kClassCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the boolean is_in_fullsnapshot first as this will
  // help the reader decide how the rest of the information needs
  // to be interpreted.
  writer->Write<bool>(is_in_fullsnapshot);

  if ((kind == Snapshot::kFull) ||
      (kind == Snapshot::kScript && !is_in_fullsnapshot)) {
    // Write out all the non object pointer fields.
    // NOTE: cpp_vtable_ is not written.
    classid_t class_id = ptr()->id_;
    writer->Write<classid_t>(class_id);
    if (!RawObject::IsInternalVMdefinedClassId(class_id)) {
      // We don't write the instance size of VM defined classes as they
      // are already setup during initialization as part of pre populating
      // the class table.
      writer->Write<int32_t>(ptr()->instance_size_in_words_);
      writer->Write<int32_t>(ptr()->next_field_offset_in_words_);
    }
    writer->Write<int32_t>(ptr()->type_arguments_field_offset_in_words_);
    writer->Write<uint16_t>(ptr()->num_type_arguments_);
    writer->Write<uint16_t>(ptr()->num_own_type_arguments_);
    writer->Write<uint16_t>(ptr()->num_native_fields_);
    writer->Write<int32_t>(ptr()->token_pos_);
    writer->Write<uint16_t>(ptr()->state_bits_);

    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer);
    visitor.VisitPointers(from(), to());
  } else {
    if (writer->can_send_any_object() ||
        writer->AllowObjectsInDartLibrary(ptr()->library_)) {
      writer->WriteClassId(this);
    } else {
      // We do not allow regular dart instances in isolate messages.
      writer->SetWriteException(Exceptions::kArgument,
                                "Illegal argument in isolate message"
                                " : (object is a regular Dart Instance)");
    }
  }
}


RawUnresolvedClass* UnresolvedClass::ReadFrom(SnapshotReader* reader,
                                              intptr_t object_id,
                                              intptr_t tags,
                                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate unresolved class object.
  UnresolvedClass& unresolved_class = UnresolvedClass::ZoneHandle(
      reader->zone(), NEW_OBJECT(UnresolvedClass));
  reader->AddBackRef(object_id, &unresolved_class, kIsDeserialized);

  // Set all non object fields.
  unresolved_class.set_token_pos(reader->Read<int32_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (unresolved_class.raw()->to() -
                       unresolved_class.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    unresolved_class.StorePointer((unresolved_class.raw()->from() + i),
                                  reader->PassiveObjectHandle()->raw());
  }
  return unresolved_class.raw();
}


void RawUnresolvedClass::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kUnresolvedClassCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->Write<int32_t>(ptr()->token_pos_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawAbstractType* AbstractType::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  UNREACHABLE();  // AbstractType is an abstract class.
  return NULL;
}


void RawAbstractType::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNREACHABLE();  // AbstractType is an abstract class.
}


RawType* Type::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
                        intptr_t tags,
                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Determine if the type class of this type is in the full snapshot.
  bool typeclass_is_in_fullsnapshot = reader->Read<bool>();

  // Allocate type object.
  Type& type = Type::ZoneHandle(reader->zone(), NEW_OBJECT(Type));
  bool is_canonical = RawObject::IsCanonical(tags);
  bool defer_canonicalization = is_canonical &&
      (kind != Snapshot::kFull && typeclass_is_in_fullsnapshot);
  reader->AddBackRef(object_id, &type, kIsDeserialized, defer_canonicalization);

  // Set all non object fields.
  type.set_token_pos(reader->Read<int32_t>());
  type.set_type_state(reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type.raw()->to() - type.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(type);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    type.StorePointer((type.raw()->from() + i),
                      reader->PassiveObjectHandle()->raw());
  }

  // Set the canonical bit.
  if (!defer_canonicalization && RawObject::IsCanonical(tags)) {
    type.SetCanonical();
  }

  return type.raw();
}


void RawType::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Only resolved and finalized types should be written to a snapshot.
  ASSERT((ptr()->type_state_ == RawType::kFinalizedInstantiated) ||
         (ptr()->type_state_ == RawType::kFinalizedUninstantiated));
  ASSERT(ptr()->type_class_ != Object::null());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out typeclass_is_in_fullsnapshot first as this will
  // help the reader decide on how to canonicalize the type object.
  intptr_t tags = writer->GetObjectTags(ptr()->type_class_);
  bool typeclass_is_in_fullsnapshot =
      (ClassIdTag::decode(tags) == kClassCid) &&
      Class::IsInFullSnapshot(reinterpret_cast<RawClass*>(ptr()->type_class_));
  writer->Write<bool>(typeclass_is_in_fullsnapshot);

  // Write out all the non object pointer fields.
  writer->Write<int32_t>(ptr()->token_pos_);
  writer->Write<int8_t>(ptr()->type_state_);

  // Write out all the object pointer fields. Since we will be canonicalizing
  // the type object when reading it back we should write out all the fields
  // inline and not as references.
  ASSERT(ptr()->type_class_ != Object::null());
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawTypeRef* TypeRef::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate type ref object.
  TypeRef& type_ref = TypeRef::ZoneHandle(
      reader->zone(), NEW_OBJECT(TypeRef));
  reader->AddBackRef(object_id, &type_ref, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type_ref.raw()->to() - type_ref.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(type_ref);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    type_ref.StorePointer((type_ref.raw()->from() + i),
                          reader->PassiveObjectHandle()->raw());
  }

  return type_ref.raw();
}


void RawTypeRef::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeRefCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawTypeParameter* TypeParameter::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate type parameter object.
  TypeParameter& type_parameter = TypeParameter::ZoneHandle(
      reader->zone(), NEW_OBJECT(TypeParameter));
  reader->AddBackRef(object_id, &type_parameter, kIsDeserialized);

  // Set all non object fields.
  type_parameter.set_token_pos(reader->Read<int32_t>());
  type_parameter.set_index(reader->Read<int16_t>());
  type_parameter.set_type_state(reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type_parameter.raw()->to() -
                       type_parameter.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(type_parameter);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    type_parameter.StorePointer((type_parameter.raw()->from() + i),
                                reader->PassiveObjectHandle()->raw());
  }

  return type_parameter.raw();
}


void RawTypeParameter::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Only finalized type parameters should be written to a snapshot.
  ASSERT(ptr()->type_state_ == RawTypeParameter::kFinalizedUninstantiated);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeParameterCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->Write<int32_t>(ptr()->token_pos_);
  writer->Write<int16_t>(ptr()->index_);
  writer->Write<int8_t>(ptr()->type_state_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawBoundedType* BoundedType::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate bounded type object.
  BoundedType& bounded_type = BoundedType::ZoneHandle(
      reader->zone(), NEW_OBJECT(BoundedType));
  reader->AddBackRef(object_id, &bounded_type, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (bounded_type.raw()->to() -
                       bounded_type.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(bounded_type);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    bounded_type.StorePointer((bounded_type.raw()->from() + i),
                              reader->PassiveObjectHandle()->raw());
  }

  return bounded_type.raw();
}


void RawBoundedType::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kBoundedTypeCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawMixinAppType* MixinAppType::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  UNREACHABLE();  // MixinAppType objects do not survive finalization.
  return MixinAppType::null();
}


void RawMixinAppType::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNREACHABLE();  // MixinAppType objects do not survive finalization.
}


RawTypeArguments* TypeArguments::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();

  TypeArguments& type_arguments = TypeArguments::ZoneHandle(
      reader->zone(), NEW_OBJECT_WITH_LEN_SPACE(TypeArguments, len, kind));
  bool is_canonical = RawObject::IsCanonical(tags);
  bool defer_canonicalization = is_canonical && (kind != Snapshot::kFull);
  reader->AddBackRef(object_id,
                     &type_arguments,
                     kIsDeserialized,
                     defer_canonicalization);

  // Set the instantiations field, which is only read from a full snapshot.
  if (kind == Snapshot::kFull) {
    *(reader->ArrayHandle()) ^= reader->ReadObjectImpl(kAsInlinedObject);
    type_arguments.set_instantiations(*(reader->ArrayHandle()));
  } else {
    type_arguments.set_instantiations(Object::zero_array());
  }

  // Now set all the type fields.
  intptr_t offset = type_arguments.TypeAddr(0) -
      reinterpret_cast<RawAbstractType**>(type_arguments.raw()->ptr());
  for (intptr_t i = 0; i < len; i++) {
    *reader->TypeHandle() ^=
        reader->ReadObjectImpl(kAsReference, object_id, (i + offset));
    type_arguments.SetTypeAt(i, *reader->TypeHandle());
  }

  // Set the canonical bit.
  if (!defer_canonicalization && RawObject::IsCanonical(tags)) {
    type_arguments.SetCanonical();
  }

  return type_arguments.raw();
}


void RawTypeArguments::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kTypeArgumentsCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the instantiations field, but only in a full snapshot.
  if (kind == Snapshot::kFull) {
    writer->WriteObjectImpl(ptr()->instantiations_, kAsInlinedObject);
  }

  // Write out the individual types.
  intptr_t len = Smi::Value(ptr()->length_);
  for (intptr_t i = 0; i < len; i++) {
    writer->WriteObjectImpl(ptr()->types()[i], kAsReference);
  }
}


RawPatchClass* PatchClass::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate function object.
  PatchClass& cls = PatchClass::ZoneHandle(reader->zone(),
                                            NEW_OBJECT(PatchClass));
  reader->AddBackRef(object_id, &cls, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (cls.raw()->to() - cls.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    cls.StorePointer((cls.raw()->from() + i),
                     reader->PassiveObjectHandle()->raw());
  }
  ASSERT(((kind == Snapshot::kScript) &&
          !Class::IsInFullSnapshot(cls.source_class())) ||
         (kind == Snapshot::kFull));

  return cls.raw();
}


void RawPatchClass::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kPatchClassCid);
  writer->WriteTags(writer->GetObjectTags(this));
  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawClosureData* ClosureData::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate closure data object.
  ClosureData& data = ClosureData::ZoneHandle(
      reader->zone(), NEW_OBJECT(ClosureData));
  reader->AddBackRef(object_id, &data, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (data.raw()->to() - data.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(data.raw()->from() + i) = reader->ReadObjectImpl(kAsReference);
  }

  return data.raw();
}


void RawClosureData::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kClosureDataCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Context scope.
  // We don't write the context scope in the snapshot.
  writer->WriteObjectImpl(Object::null(), kAsInlinedObject);

  // Parent function.
  writer->WriteObjectImpl(ptr()->parent_function_, kAsInlinedObject);

  // Signature class.
  writer->WriteObjectImpl(ptr()->signature_class_, kAsInlinedObject);

  // Static closure/Closure allocation stub.
  // We don't write the closure or allocation stub in the snapshot.
  writer->WriteObjectImpl(Object::null(), kAsInlinedObject);
}


RawRedirectionData* RedirectionData::ReadFrom(SnapshotReader* reader,
                                              intptr_t object_id,
                                              intptr_t tags,
                                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate redirection data object.
  RedirectionData& data = RedirectionData::ZoneHandle(
      reader->zone(), NEW_OBJECT(RedirectionData));
  reader->AddBackRef(object_id, &data, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (data.raw()->to() - data.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(data);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    data.StorePointer((data.raw()->from() + i),
                      reader->PassiveObjectHandle()->raw());
  }

  return data.raw();
}


void RawRedirectionData::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kRedirectionDataCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawFunction* Function::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate function object.
  Function& func = Function::ZoneHandle(
      reader->zone(), NEW_OBJECT(Function));
  reader->AddBackRef(object_id, &func, kIsDeserialized);

  // Set all the non object fields.
  func.set_token_pos(reader->Read<int32_t>());
  func.set_end_token_pos(reader->Read<int32_t>());
  func.set_usage_counter(reader->Read<int32_t>());
  func.set_num_fixed_parameters(reader->Read<int16_t>());
  func.set_num_optional_parameters(reader->Read<int16_t>());
  func.set_deoptimization_counter(reader->Read<int16_t>());
  func.set_kind_tag(reader->Read<uint32_t>());
  func.set_optimized_instruction_count(reader->Read<uint16_t>());
  func.set_optimized_call_site_count(reader->Read<uint16_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (func.raw()->to_snapshot() - func.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(func);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    func.StorePointer((func.raw()->from() + i),
                      reader->PassiveObjectHandle()->raw());
  }

  // Initialize all fields that are not part of the snapshot.
  func.ClearICDataArray();
  func.ClearCode();
  return func.raw();
}


void RawFunction::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kFunctionCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->Write<int32_t>(ptr()->token_pos_);
  writer->Write<int32_t>(ptr()->end_token_pos_);
  writer->Write<int32_t>(ptr()->usage_counter_);
  writer->Write<int16_t>(ptr()->num_fixed_parameters_);
  writer->Write<int16_t>(ptr()->num_optional_parameters_);
  writer->Write<int16_t>(ptr()->deoptimization_counter_);
  writer->Write<uint32_t>(ptr()->kind_tag_);
  writer->Write<uint16_t>(ptr()->optimized_instruction_count_);
  writer->Write<uint16_t>(ptr()->optimized_call_site_count_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to_snapshot());
}


RawField* Field::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate field object.
  Field& field = Field::ZoneHandle(reader->zone(), NEW_OBJECT(Field));
  reader->AddBackRef(object_id, &field, kIsDeserialized);

  // Set all non object fields.
  field.set_token_pos(reader->Read<int32_t>());
  field.set_guarded_cid(reader->Read<int32_t>());
  field.set_is_nullable(reader->Read<int32_t>());
  field.set_kind_bits(reader->Read<uint8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (field.raw()->to() - field.raw()->from());
  intptr_t from_offset = OFFSET_OF_FROM(field);
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) =
        reader->ReadObjectImpl(kAsReference, object_id, (i + from_offset));
    field.StorePointer((field.raw()->from() + i),
                       reader->PassiveObjectHandle()->raw());
  }

  field.InitializeGuardedListLengthInObjectOffset();

  return field.raw();
}


void RawField::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kFieldCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->Write<int32_t>(ptr()->token_pos_);
  writer->Write<int32_t>(ptr()->guarded_cid_);
  writer->Write<int32_t>(ptr()->is_nullable_);
  writer->Write<uint8_t>(ptr()->kind_bits_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawLiteralToken* LiteralToken::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind != Snapshot::kMessage);

  // Create the literal token object.
  LiteralToken& literal_token = LiteralToken::ZoneHandle(
      reader->zone(), NEW_OBJECT(LiteralToken));
  reader->AddBackRef(object_id, &literal_token, kIsDeserialized);

  // Read the token attributes.
  Token::Kind token_kind = static_cast<Token::Kind>(reader->Read<int32_t>());
  literal_token.set_kind(token_kind);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (literal_token.raw()->to() - literal_token.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    literal_token.StorePointer((literal_token.raw()->from() + i),
                               reader->PassiveObjectHandle()->raw());
  }

  return literal_token.raw();
}


void RawLiteralToken::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(kind != Snapshot::kMessage);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kLiteralTokenCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the kind field.
  writer->Write<int32_t>(ptr()->kind_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawTokenStream* TokenStream::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Read the length so that we can determine number of tokens to read.
  intptr_t len = reader->ReadSmiValue();

  // Create the token stream object.
  TokenStream& token_stream = TokenStream::ZoneHandle(
      reader->zone(), NEW_OBJECT_WITH_LEN(TokenStream, len));
  reader->AddBackRef(object_id, &token_stream, kIsDeserialized);

  // Read the stream of tokens into the TokenStream object for script
  // snapshots as we made a copy of token stream.
  if (kind == Snapshot::kScript) {
    NoSafepointScope no_safepoint;
    RawExternalTypedData* stream = token_stream.GetStream();
    reader->ReadBytes(stream->ptr()->data_, len);
  }

  // Read in the literal/identifier token array.
  *(reader->TokensHandle()) ^= reader->ReadObjectImpl(kAsInlinedObject);
  token_stream.SetTokenObjects(*(reader->TokensHandle()));
  // Read in the private key in use by the token stream.
  *(reader->StringHandle()) ^= reader->ReadObjectImpl(kAsInlinedObject);
  token_stream.SetPrivateKey(*(reader->StringHandle()));

  return token_stream.raw();
}


void RawTokenStream::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kTokenStreamCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the length field and the token stream.
  RawExternalTypedData* stream = ptr()->stream_;
  intptr_t len = Smi::Value(stream->ptr()->length_);
  writer->Write<RawObject*>(stream->ptr()->length_);
  writer->WriteBytes(stream->ptr()->data_, len);

  // Write out the literal/identifier token array.
  writer->WriteObjectImpl(ptr()->token_objects_, kAsInlinedObject);
  // Write out the private key in use by the token stream.
  writer->WriteObjectImpl(ptr()->private_key_, kAsInlinedObject);
}


RawScript* Script::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate script object.
  Script& script = Script::ZoneHandle(reader->zone(), NEW_OBJECT(Script));
  reader->AddBackRef(object_id, &script, kIsDeserialized);

  script.StoreNonPointer(&script.raw_ptr()->line_offset_,
                         reader->Read<int32_t>());
  script.StoreNonPointer(&script.raw_ptr()->col_offset_,
                         reader->Read<int32_t>());
  script.StoreNonPointer(&script.raw_ptr()->kind_,
                         reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (script.raw()->to_snapshot() - script.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    script.StorePointer((script.raw()->from() + i),
                        reader->PassiveObjectHandle()->raw());
  }
  // Script wasn't allocated with nulls?
  *reader->StringHandle() ^= String::null();
  script.set_source(*reader->StringHandle());

  return script.raw();
}


void RawScript::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(tokens_ != TokenStream::null());
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kScriptCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->Write<int32_t>(ptr()->line_offset_);
  writer->Write<int32_t>(ptr()->col_offset_);
  writer->Write<int8_t>(ptr()->kind_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to_snapshot());
}


RawLibrary* Library::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind != Snapshot::kMessage);

  Library& library = Library::ZoneHandle(reader->zone(), Library::null());
  reader->AddBackRef(object_id, &library, kIsDeserialized);

  bool is_in_fullsnapshot = reader->Read<bool>();
  if ((kind == Snapshot::kScript) && is_in_fullsnapshot) {
    // Lookup the object as it should already exist in the heap.
    *reader->StringHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
    library = Library::LookupLibrary(*reader->StringHandle());
    ASSERT(library.is_in_fullsnapshot());
  } else {
    // Allocate library object.
    library = NEW_OBJECT(Library);

    // Set all non object fields.
    library.StoreNonPointer(&library.raw_ptr()->index_,
                            reader->ReadClassIDValue());
    library.StoreNonPointer(&library.raw_ptr()->num_anonymous_,
                            reader->ReadClassIDValue());
    library.StoreNonPointer(&library.raw_ptr()->num_imports_,
                            reader->Read<uint16_t>());
    library.StoreNonPointer(&library.raw_ptr()->load_state_,
                            reader->Read<int8_t>());
    library.StoreNonPointer(&library.raw_ptr()->corelib_imported_,
                            reader->Read<bool>());
    library.StoreNonPointer(&library.raw_ptr()->is_dart_scheme_,
                            reader->Read<bool>());
    library.StoreNonPointer(&library.raw_ptr()->debuggable_,
                            reader->Read<bool>());
    if (kind == Snapshot::kFull) {
      is_in_fullsnapshot = true;
    }
    library.StoreNonPointer(&library.raw_ptr()->is_in_fullsnapshot_,
                            is_in_fullsnapshot);
    // The native resolver and symbolizer are not serialized.
    library.set_native_entry_resolver(NULL);
    library.set_native_entry_symbol_resolver(NULL);
    // The cache of loaded scripts is not serialized.
    library.StorePointer(&library.raw_ptr()->loaded_scripts_, Array::null());

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (library.raw()->to() - library.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
      library.StorePointer((library.raw()->from() + i),
                           reader->PassiveObjectHandle()->raw());
    }
    if (kind != Snapshot::kFull) {
      library.Register();
    }
  }
  return library.raw();
}


void RawLibrary::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(kind != Snapshot::kMessage);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kLibraryCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the boolean is_in_fullsnapshot_ first as this will
  // help the reader decide how the rest of the information needs
  // to be interpreted.
  writer->Write<bool>(ptr()->is_in_fullsnapshot_);

  if ((kind == Snapshot::kScript) && ptr()->is_in_fullsnapshot_) {
    // Write out library URL so that it can be looked up when reading.
    writer->WriteObjectImpl(ptr()->url_, kAsInlinedObject);
  } else {
    ASSERT((kind == Snapshot::kFull) || !ptr()->is_in_fullsnapshot_);
    // Write out all non object fields.
    writer->WriteClassIDValue(ptr()->index_);
    writer->WriteClassIDValue(ptr()->num_anonymous_);
    writer->Write<uint16_t>(ptr()->num_imports_);
    writer->Write<int8_t>(ptr()->load_state_);
    writer->Write<bool>(ptr()->corelib_imported_);
    writer->Write<bool>(ptr()->is_dart_scheme_);
    writer->Write<bool>(ptr()->debuggable_);
    // We do not serialize the native resolver or symbolizer. These need to be
    // explicitly set after deserialization.
    // We do not write the loaded_scripts_ cache to the snapshot. It gets
    // set to NULL when reading the library from the snapshot, and will
    // be rebuilt lazily.

    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer);
    visitor.VisitPointers(from(), to());
  }
}


RawLibraryPrefix* LibraryPrefix::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate library prefix object.
  LibraryPrefix& prefix = LibraryPrefix::ZoneHandle(
      reader->zone(), NEW_OBJECT(LibraryPrefix));
  reader->AddBackRef(object_id, &prefix, kIsDeserialized);

  // Set all non object fields.
  prefix.StoreNonPointer(&prefix.raw_ptr()->num_imports_,
                         reader->Read<int16_t>());
  prefix.StoreNonPointer(&prefix.raw_ptr()->is_deferred_load_,
                         reader->Read<bool>());
  prefix.StoreNonPointer(&prefix.raw_ptr()->is_loaded_, reader->Read<bool>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (prefix.raw()->to() - prefix.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    prefix.StorePointer((prefix.raw()->from() + i),
                         reader->PassiveObjectHandle()->raw());
  }

  return prefix.raw();
}


void RawLibraryPrefix::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kLibraryPrefixCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all non object fields.
  writer->Write<int16_t>(ptr()->num_imports_);
  writer->Write<bool>(ptr()->is_deferred_load_);
  writer->Write<bool>(ptr()->is_loaded_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawNamespace* Namespace::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Allocate Namespace object.
  Namespace& ns = Namespace::ZoneHandle(
      reader->zone(), NEW_OBJECT(Namespace));
  reader->AddBackRef(object_id, &ns, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (ns.raw()->to() - ns.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    ns.StorePointer((ns.raw()->from() + i),
                    reader->PassiveObjectHandle()->raw());
  }

  return ns.raw();
}


void RawNamespace::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind == Snapshot::kScript) || (kind == Snapshot::kFull));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kNamespaceCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawCode* Code::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
                        intptr_t tags,
                        Snapshot::Kind kind) {
  UNREACHABLE();
  return Code::null();
}


void RawCode::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  // We have already checked for this and written a NULL object, hence we
  // should not reach here.
  UNREACHABLE();
}


RawInstructions* Instructions::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  UNREACHABLE();
  return Instructions::null();
}


void RawInstructions::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNREACHABLE();
}


RawObjectPool* ObjectPool::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  UNREACHABLE();
  return ObjectPool::null();
}


void RawObjectPool::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  UNREACHABLE();
}


RawPcDescriptors* PcDescriptors::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader->allow_code());

  const int32_t length = reader->Read<int32_t>();
  PcDescriptors& result = PcDescriptors::ZoneHandle(reader->zone(),
                                                    PcDescriptors::New(length));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  if (result.Length() > 0) {
    NoSafepointScope no_safepoint;
    intptr_t len = result.Length();
    uint8_t* data = result.UnsafeMutableNonPointer(result.raw_ptr()->data());
    reader->ReadBytes(data, len);
  }

  return result.raw();
}


void RawPcDescriptors::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer->allow_code());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);
  writer->WriteIndexedObject(kPcDescriptorsCid);
  writer->WriteTags(writer->GetObjectTags(this));
  writer->Write<int32_t>(ptr()->length_);
  if (ptr()->length_ > 0) {
    intptr_t len = ptr()->length_;
    uint8_t* data = reinterpret_cast<uint8_t*>(ptr()->data());
    writer->WriteBytes(data, len);
  }
}


RawStackmap* Stackmap::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader->allow_code());

  const int32_t length = reader->Read<int32_t>();
  const int32_t register_bit_count = reader->Read<int32_t>();
  const uword pc_offset = reader->Read<uint32_t>();

  Stackmap& result =
      Stackmap::ZoneHandle(reader->zone(),
        Stackmap::New(length, register_bit_count, pc_offset));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  if (result.Length() > 0) {
    NoSafepointScope no_safepoint;
    intptr_t len = (result.Length() + 7) / 8;
    uint8_t* data = result.UnsafeMutableNonPointer(result.raw_ptr()->data());
    reader->ReadBytes(data, len);
  }

  return result.raw();
}


void RawStackmap::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer->allow_code());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);
  writer->WriteIndexedObject(kStackmapCid);
  writer->WriteTags(writer->GetObjectTags(this));
  writer->Write<int32_t>(ptr()->length_);
  writer->Write<int32_t>(ptr()->register_bit_count_);
  writer->Write<uint32_t>(ptr()->pc_offset_);
  if (ptr()->length_ > 0) {
    intptr_t len = (ptr()->length_ + 7) / 8;
    uint8_t* data = reinterpret_cast<uint8_t*>(ptr()->data());
    writer->WriteBytes(data, len);
  }
}


RawLocalVarDescriptors* LocalVarDescriptors::ReadFrom(SnapshotReader* reader,
                                                      intptr_t object_id,
                                                      intptr_t tags,
                                                      Snapshot::Kind kind) {
  ASSERT(reader->allow_code());

  const int32_t num_entries = reader->Read<int32_t>();

  LocalVarDescriptors& result =
      LocalVarDescriptors::ZoneHandle(reader->zone(),
        LocalVarDescriptors::New(num_entries));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  for (intptr_t i = 0; i < num_entries; i++) {
    (*reader->StringHandle()) ^= reader->ReadObjectImpl(kAsReference);
    result.StorePointer(result.raw()->nameAddrAt(i),
                        reader->StringHandle()->raw());
  }

  if (num_entries > 0) {
    NoSafepointScope no_safepoint;
    intptr_t len = num_entries * sizeof(RawLocalVarDescriptors::VarInfo);
    uint8_t* data = result.UnsafeMutableNonPointer(
        reinterpret_cast<const uint8_t*>(result.raw()->data()));
    reader->ReadBytes(data, len);
  }

  return result.raw();
}


void RawLocalVarDescriptors::WriteTo(SnapshotWriter* writer,
                                     intptr_t object_id,
                                     Snapshot::Kind kind) {
  ASSERT(writer->allow_code());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);
  writer->WriteIndexedObject(kLocalVarDescriptorsCid);
  writer->WriteTags(writer->GetObjectTags(this));
  writer->Write<int32_t>(ptr()->num_entries_);
  for (intptr_t i = 0; i < ptr()->num_entries_; i++) {
    writer->WriteObjectImpl(ptr()->names()[i], kAsInlinedObject);
  }
  if (ptr()->num_entries_ > 0) {
    intptr_t len = ptr()->num_entries_ * sizeof(VarInfo);
    uint8_t* data = reinterpret_cast<uint8_t*>(this->data());
    writer->WriteBytes(data, len);
  }
}


RawExceptionHandlers* ExceptionHandlers::ReadFrom(SnapshotReader* reader,
                                                  intptr_t object_id,
                                                  intptr_t tags,
                                                  Snapshot::Kind kind) {
  ASSERT(reader->allow_code());

  // handled_types_data.
  *(reader->ArrayHandle()) ^= reader->ReadObjectImpl(kAsInlinedObject);

  ExceptionHandlers& result =
      ExceptionHandlers::ZoneHandle(reader->zone(),
        ExceptionHandlers::New(*reader->ArrayHandle()));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  if (result.num_entries() > 0) {
    NoSafepointScope no_safepoint;
    const intptr_t len =
        result.num_entries() * sizeof(RawExceptionHandlers::HandlerInfo);
    uint8_t* data = result.UnsafeMutableNonPointer(
        reinterpret_cast<const uint8_t*>(result.raw_ptr()->data()));
    reader->ReadBytes(data, len);
  }

  return result.raw();
}


void RawExceptionHandlers::WriteTo(SnapshotWriter* writer,
                                   intptr_t object_id,
                                   Snapshot::Kind kind) {
  ASSERT(writer->allow_code());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);
  writer->WriteIndexedObject(kExceptionHandlersCid);
  writer->WriteTags(writer->GetObjectTags(this));
  writer->WriteObjectImpl(ptr()->handled_types_data_, kAsInlinedObject);

  if (ptr()->num_entries_ > 0) {
    intptr_t len = ptr()->num_entries_ * sizeof(HandlerInfo);
    uint8_t* data = reinterpret_cast<uint8_t*>(ptr()->data());
    writer->WriteBytes(data, len);
  }
}


RawContext* Context::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate context object.
  int32_t num_vars = reader->Read<int32_t>();
  Context& context = Context::ZoneHandle(reader->zone());
  reader->AddBackRef(object_id, &context, kIsDeserialized);
  if (num_vars == 0) {
    context ^= reader->object_store()->empty_context();
  } else {
    context ^= NEW_OBJECT_WITH_LEN(Context, num_vars);

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (context.raw()->to(num_vars) - context.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
      context.StorePointer((context.raw()->from() + i),
                           reader->PassiveObjectHandle()->raw());
    }
  }
  return context.raw();
}


void RawContext::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kContextCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out num of variables in the context.
  int32_t num_variables = ptr()->num_variables_;
  writer->Write<int32_t>(num_variables);
  if (num_variables != 0) {
    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer);
    visitor.VisitPointers(from(), to(num_variables));
  }
}


RawContextScope* ContextScope::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  UNREACHABLE();
  return NULL;
}


void RawContextScope::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNREACHABLE();
}


RawICData* ICData::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  UNREACHABLE();
  return NULL;
}


void RawICData::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  UNREACHABLE();
}


RawMegamorphicCache* MegamorphicCache::ReadFrom(SnapshotReader* reader,
                                                intptr_t object_id,
                                                intptr_t tags,
                                                Snapshot::Kind kind) {
  UNREACHABLE();
  return NULL;
}


void RawMegamorphicCache::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind) {
  UNREACHABLE();
}


RawSubtypeTestCache* SubtypeTestCache::ReadFrom(SnapshotReader* reader,
                                                intptr_t object_id,
                                                intptr_t tags,
                                                Snapshot::Kind kind) {
  UNREACHABLE();
  return NULL;
}


void RawSubtypeTestCache::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind) {
  UNREACHABLE();
}


RawError* Error::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  UNREACHABLE();
  return Error::null();  // Error is an abstract class.
}


void RawError::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  UNREACHABLE();  // Error is an abstract class.
}


RawApiError* ApiError::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate ApiError object.
  ApiError& api_error =
      ApiError::ZoneHandle(reader->zone(), NEW_OBJECT(ApiError));
  reader->AddBackRef(object_id, &api_error, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (api_error.raw()->to() - api_error.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    api_error.StorePointer((api_error.raw()->from() + i),
                           reader->PassiveObjectHandle()->raw());
  }

  return api_error.raw();
}


void RawApiError::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kApiErrorCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawLanguageError* LanguageError::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate LanguageError object.
  LanguageError& language_error =
      LanguageError::ZoneHandle(reader->zone(), NEW_OBJECT(LanguageError));
  reader->AddBackRef(object_id, &language_error, kIsDeserialized);

  // Set all non object fields.
  language_error.set_token_pos(reader->Read<int32_t>());
  language_error.set_kind(reader->Read<uint8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds =
      (language_error.raw()->to() - language_error.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    language_error.StorePointer((language_error.raw()->from() + i),
                                reader->PassiveObjectHandle()->raw());
  }

  return language_error.raw();
}


void RawLanguageError::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kLanguageErrorCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->Write<int32_t>(ptr()->token_pos_);
  writer->Write<uint8_t>(ptr()->kind_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawUnhandledException* UnhandledException::ReadFrom(SnapshotReader* reader,
                                                    intptr_t object_id,
                                                    intptr_t tags,
                                                    Snapshot::Kind kind) {
  UnhandledException& result = UnhandledException::ZoneHandle(
      reader->zone(), NEW_OBJECT(UnhandledException));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (result.raw()->to() - result.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    result.StorePointer((result.raw()->from() + i),
                         reader->PassiveObjectHandle()->raw());
  }

  return result.raw();
}


void RawUnhandledException::WriteTo(SnapshotWriter* writer,
                                    intptr_t object_id,
                                    Snapshot::Kind kind) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kUnhandledExceptionCid);
  writer->WriteTags(writer->GetObjectTags(this));
  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawUnwindError* UnwindError::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  UNREACHABLE();
  return UnwindError::null();
}


void RawUnwindError::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  UNREACHABLE();
}


RawInstance* Instance::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Create an Instance object or get canonical one if it is a canonical
  // constant.
  Instance& obj = Instance::ZoneHandle(reader->zone(), Instance::null());
  if (kind == Snapshot::kFull) {
    obj = reader->NewInstance();
    // Set the canonical bit.
    if (RawObject::IsCanonical(tags)) {
      obj.SetCanonical();
    }
  } else {
    obj ^= Object::Allocate(kInstanceCid,
                            Instance::InstanceSize(),
                            HEAP_SPACE(kind));
    if (RawObject::IsCanonical(tags)) {
      obj = obj.CheckAndCanonicalize(NULL);
    }
  }
  reader->AddBackRef(object_id, &obj, kIsDeserialized);

  return obj.raw();
}


void RawInstance::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kInstanceCid);
  writer->WriteTags(writer->GetObjectTags(this));
}


RawInteger* Mint::ReadFrom(SnapshotReader* reader,
                           intptr_t object_id,
                           intptr_t tags,
                           Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the 64 bit value for the object.
  int64_t value = reader->Read<int64_t>();

  // Check if the value could potentially fit in a Smi in our current
  // architecture, if so return the object as a Smi.
  if (Smi::IsValid(value)) {
    Smi& smi = Smi::ZoneHandle(reader->zone(),
                               Smi::New(static_cast<intptr_t>(value)));
    reader->AddBackRef(object_id, &smi, kIsDeserialized);
    return smi.raw();
  }

  // Create a Mint object or get canonical one if it is a canonical constant.
  Mint& mint = Mint::ZoneHandle(reader->zone(), Mint::null());
  if (kind == Snapshot::kFull) {
    mint = reader->NewMint(value);
    // Set the canonical bit.
    if (RawObject::IsCanonical(tags)) {
      mint.SetCanonical();
    }
  } else {
    // When reading a script snapshot we need to canonicalize only those object
    // references that are objects from the core library (loaded from a
    // full snapshot). Objects that are only in the script need not be
    // canonicalized as they are already canonical.
    // When reading a message snapshot we always have to canonicalize.
    if (RawObject::IsCanonical(tags)) {
      mint = Mint::NewCanonical(value);
      ASSERT(mint.IsCanonical());
    } else {
      mint = Mint::New(value, HEAP_SPACE(kind));
    }
  }
  reader->AddBackRef(object_id, &mint, kIsDeserialized);
  return mint.raw();
}


void RawMint::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kMintCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the 64 bit value.
  writer->Write<int64_t>(ptr()->value_);
}


RawBigint* Bigint::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate bigint object.
  Bigint& obj = Bigint::ZoneHandle(reader->zone(), NEW_OBJECT(Bigint));
  reader->AddBackRef(object_id, &obj, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (obj.raw()->to() - obj.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsInlinedObject);
    obj.StorePointer(obj.raw()->from() + i,
                     reader->PassiveObjectHandle()->raw());
  }

  // If it is a canonical constant make it one.
  // When reading a full snapshot we don't need to canonicalize the object
  // as it would already be a canonical object.
  // When reading a script snapshot or a message snapshot we always have
  // to canonicalize the object.
  if (RawObject::IsCanonical(tags)) {
    if (kind == Snapshot::kFull) {
      // Set the canonical bit.
      obj.SetCanonical();
    } else {
      obj ^= obj.CheckAndCanonicalize(NULL);
      ASSERT(!obj.IsNull());
      ASSERT(obj.IsCanonical());
    }
  }
  return obj.raw();
}


void RawBigint::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kBigintCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, false);
  visitor.VisitPointers(from(), to());
}


RawDouble* Double::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind != Snapshot::kMessage);
  // Read the double value for the object.
  double value = reader->ReadDouble();

  // Create a Double object or get canonical one if it is a canonical constant.
  Double& dbl = Double::ZoneHandle(reader->zone(), Double::null());
  if (kind == Snapshot::kFull) {
    dbl = reader->NewDouble(value);
    // Set the canonical bit.
    if (RawObject::IsCanonical(tags)) {
      dbl.SetCanonical();
    }
  } else {
    // When reading a script snapshot we need to canonicalize only those object
    // references that are objects from the core library (loaded from a
    // full snapshot). Objects that are only in the script need not be
    // canonicalized as they are already canonical.
    if (RawObject::IsCanonical(tags)) {
      dbl = Double::NewCanonical(value);
      ASSERT(dbl.IsCanonical());
    } else {
      dbl = Double::New(value, HEAP_SPACE(kind));
    }
  }
  reader->AddBackRef(object_id, &dbl, kIsDeserialized);
  return dbl.raw();
}


void RawDouble::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kDoubleCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the double value.
  writer->WriteDouble(ptr()->value_);
}


RawString* String::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  UNREACHABLE();  // String is an abstract class.
  return String::null();
}


void RawString::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  UNREACHABLE();  // String is an abstract class.
}


template<typename StringType, typename CharacterType, typename CallbackType>
void String::ReadFromImpl(SnapshotReader* reader,
                          String* str_obj,
                          intptr_t len,
                          intptr_t tags,
                          CallbackType new_symbol,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  if (RawObject::IsCanonical(tags)) {
    // Set up canonical string object.
    ASSERT(reader != NULL);
    CharacterType* ptr = reader->zone()->Alloc<CharacterType>(len);
    for (intptr_t i = 0; i < len; i++) {
      ptr[i] = reader->Read<CharacterType>();
    }
    *str_obj ^= (*new_symbol)(ptr, len);
  } else {
    // Set up the string object.
    *str_obj = StringType::New(len, HEAP_SPACE(kind));
    str_obj->SetHash(0);  // Will get computed when needed.
    if (len == 0) {
      return;
    }
    NoSafepointScope no_safepoint;
    CharacterType* str_addr = StringType::CharAddr(*str_obj, 0);
    for (intptr_t i = 0; i < len; i++) {
      *str_addr = reader->Read<CharacterType>();
      str_addr++;
    }
  }
}


RawOneByteString* OneByteString::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  // Read the length so that we can determine instance size to allocate.
  ASSERT(reader != NULL);
  intptr_t len = reader->ReadSmiValue();
  intptr_t hash = reader->ReadSmiValue();
  String& str_obj = String::Handle(reader->zone(), String::null());

  if (kind == Snapshot::kFull) {
    // We currently only expect the Dart mutator to read snapshots.
    reader->isolate()->AssertCurrentThreadIsMutator();
    ASSERT(Thread::Current()->no_safepoint_scope_depth() != 0);
    RawOneByteString* obj = reader->NewOneByteString(len);
    str_obj = obj;
    if (RawObject::IsCanonical(tags)) {
      str_obj.SetCanonical();
    }
    str_obj.SetHash(hash);
    if (len > 0) {
      uint8_t* raw_ptr = CharAddr(str_obj, 0);
      reader->ReadBytes(raw_ptr, len);
    }
    ASSERT((hash == 0) || (String::Hash(str_obj, 0, str_obj.Length()) == hash));
  } else {
    String::ReadFromImpl<OneByteString, uint8_t>(
        reader, &str_obj, len, tags, Symbols::FromLatin1, kind);
  }
  reader->AddBackRef(object_id, &str_obj, kIsDeserialized);
  return raw(str_obj);
}


RawTwoByteString* TwoByteString::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  // Read the length so that we can determine instance size to allocate.
  ASSERT(reader != NULL);
  intptr_t len = reader->ReadSmiValue();
  intptr_t hash = reader->ReadSmiValue();
  String& str_obj = String::Handle(reader->zone(), String::null());

  if (kind == Snapshot::kFull) {
    RawTwoByteString* obj = reader->NewTwoByteString(len);
    str_obj = obj;
    if (RawObject::IsCanonical(tags)) {
      str_obj.SetCanonical();
    }
    str_obj.SetHash(hash);
    NoSafepointScope no_safepoint;
    uint16_t* raw_ptr = (len > 0)? CharAddr(str_obj, 0) : NULL;
    for (intptr_t i = 0; i < len; i++) {
      ASSERT(CharAddr(str_obj, i) == raw_ptr);  // Will trigger assertions.
      *raw_ptr = reader->Read<uint16_t>();
      raw_ptr += 1;
    }
    ASSERT(String::Hash(str_obj, 0, str_obj.Length()) == hash);
  } else {
    String::ReadFromImpl<TwoByteString, uint16_t>(
        reader, &str_obj, len, tags, Symbols::FromUTF16, kind);
  }
  reader->AddBackRef(object_id, &str_obj, kIsDeserialized);
  return raw(str_obj);
}


template<typename T>
static void StringWriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind,
                          intptr_t class_id,
                          intptr_t tags,
                          RawSmi* length,
                          RawSmi* hash,
                          T* data) {
  ASSERT(writer != NULL);
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(class_id);
  writer->WriteTags(tags);

  // Write out the length field.
  writer->Write<RawObject*>(length);

  // Write out the hash field.
  writer->Write<RawObject*>(hash);

  // Write out the string.
  if (len > 0) {
    if (class_id == kOneByteStringCid) {
      writer->WriteBytes(reinterpret_cast<const uint8_t*>(data), len);
    } else {
      for (intptr_t i = 0; i < len; i++) {
        writer->Write(data[i]);
      }
    }
  }
}


void RawOneByteString::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  StringWriteTo(writer,
                object_id,
                kind,
                kOneByteStringCid,
                writer->GetObjectTags(this),
                ptr()->length_,
                ptr()->hash_,
                ptr()->data());
}


void RawTwoByteString::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  StringWriteTo(writer,
                object_id,
                kind,
                kTwoByteStringCid,
                writer->GetObjectTags(this),
                ptr()->length_,
                ptr()->hash_,
                ptr()->data());
}


RawExternalOneByteString* ExternalOneByteString::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    intptr_t tags,
    Snapshot::Kind kind) {
  UNREACHABLE();
  return ExternalOneByteString::null();
}


RawExternalTwoByteString* ExternalTwoByteString::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    intptr_t tags,
    Snapshot::Kind kind) {
  UNREACHABLE();
  return ExternalTwoByteString::null();
}


void RawExternalOneByteString::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind) {
  // Serialize as a non-external one byte string.
  StringWriteTo(writer,
                object_id,
                kind,
                kOneByteStringCid,
                writer->GetObjectTags(this),
                ptr()->length_,
                ptr()->hash_,
                ptr()->external_data_->data());
}


void RawExternalTwoByteString::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind) {
  // Serialize as a non-external two byte string.
  StringWriteTo(writer,
                object_id,
                kind,
                kTwoByteStringCid,
                writer->GetObjectTags(this),
                ptr()->length_,
                ptr()->hash_,
                ptr()->external_data_->data());
}


RawBool* Bool::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
                        intptr_t tags,
                        Snapshot::Kind kind) {
  UNREACHABLE();
  return Bool::null();
}


void RawBool::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  UNREACHABLE();
}


RawArray* Array::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();
  Array* array = reinterpret_cast<Array*>(
      reader->GetBackRef(object_id));
  if (array == NULL) {
    array = &(Array::ZoneHandle(reader->zone(),
                                NEW_OBJECT_WITH_LEN_SPACE(Array, len, kind)));
    reader->AddBackRef(object_id, array, kIsDeserialized);
  }
  ASSERT(!RawObject::IsCanonical(tags));
  reader->ArrayReadFrom(object_id, *array, len, tags);
  return array->raw();
}


RawImmutableArray* ImmutableArray::ReadFrom(SnapshotReader* reader,
                                            intptr_t object_id,
                                            intptr_t tags,
                                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();
  Array* array = reinterpret_cast<Array*>(reader->GetBackRef(object_id));
  if (array == NULL) {
    array = &(Array::ZoneHandle(
        reader->zone(),
        NEW_OBJECT_WITH_LEN_SPACE(ImmutableArray, len, kind)));
    reader->AddBackRef(object_id, array, kIsDeserialized);
  }
  reader->ArrayReadFrom(object_id, *array, len, tags);
  if (RawObject::IsCanonical(tags)) {
    if (kind == Snapshot::kFull) {
      array->SetCanonical();
    } else {
      *array ^= array->CheckAndCanonicalize(NULL);
    }
  }
  return raw(*array);
}


void RawArray::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(!RawObject::IsCanonical(writer->GetObjectTags(this)));
  writer->ArrayWriteTo(object_id,
                       kArrayCid,
                       writer->GetObjectTags(this),
                       ptr()->length_,
                       ptr()->type_arguments_,
                       ptr()->data());
}


void RawImmutableArray::WriteTo(SnapshotWriter* writer,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  writer->ArrayWriteTo(object_id,
                       kImmutableArrayCid,
                       writer->GetObjectTags(this),
                       ptr()->length_,
                       ptr()->type_arguments_,
                       ptr()->data());
}


RawGrowableObjectArray* GrowableObjectArray::ReadFrom(SnapshotReader* reader,
                                                      intptr_t object_id,
                                                      intptr_t tags,
                                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  GrowableObjectArray& array = GrowableObjectArray::ZoneHandle(
      reader->zone(), GrowableObjectArray::null());
  if (kind == Snapshot::kFull) {
    array = reader->NewGrowableObjectArray();
  } else {
    array = GrowableObjectArray::New(0, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &array, kIsDeserialized);

  // Read type arguments of growable array object.
  const intptr_t typeargs_offset =
      GrowableObjectArray::type_arguments_offset() / kWordSize;
  *reader->TypeArgumentsHandle() ^=
      reader->ReadObjectImpl(kAsInlinedObject, object_id, typeargs_offset);
  array.StorePointer(&array.raw_ptr()->type_arguments_,
                     reader->TypeArgumentsHandle()->raw());

  // Read length of growable array object.
  array.SetLength(reader->ReadSmiValue());

  // Read the backing array of growable array object.
  *(reader->ArrayHandle()) ^= reader->ReadObjectImpl(kAsInlinedObject);
  array.SetData(*(reader->ArrayHandle()));

  return array.raw();
}


void RawGrowableObjectArray::WriteTo(SnapshotWriter* writer,
                                     intptr_t object_id,
                                     Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kGrowableObjectArrayCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the type arguments field.
  writer->WriteObjectImpl(ptr()->type_arguments_, kAsInlinedObject);

  // Write out the used length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the Array object.
  writer->WriteObjectImpl(ptr()->data_, kAsInlinedObject);
}


RawLinkedHashMap* LinkedHashMap::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  LinkedHashMap& map = LinkedHashMap::ZoneHandle(
      reader->zone(), LinkedHashMap::null());
  if (kind == Snapshot::kFull || kind == Snapshot::kScript) {
    // The immutable maps that seed map literals are not yet VM-internal, so
    // we don't reach this.
    UNREACHABLE();
  } else {
    // Since the map might contain itself as a key or value, allocate first.
    map = LinkedHashMap::NewUninitialized(HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &map, kIsDeserialized);

  // Read the type arguments.
  const intptr_t typeargs_offset =
      GrowableObjectArray::type_arguments_offset() / kWordSize;
  *reader->TypeArgumentsHandle() ^=
      reader->ReadObjectImpl(kAsInlinedObject, object_id, typeargs_offset);
  map.SetTypeArguments(*reader->TypeArgumentsHandle());

  // Read the number of key/value pairs.
  intptr_t len = reader->ReadSmiValue();
  intptr_t used_data = (len << 1);
  map.SetUsedData(used_data);

  // Allocate the data array.
  intptr_t data_size = Utils::Maximum(
      Utils::RoundUpToPowerOfTwo(used_data),
      static_cast<uintptr_t>(LinkedHashMap::kInitialIndexSize));
  Array& data = Array::ZoneHandle(reader->zone(),
                                  Array::New(data_size, HEAP_SPACE(kind)));
  map.SetData(data);
  map.SetDeletedKeys(0);

  // The index and hashMask is regenerated by the maps themselves on demand.
  // Thus, the index will probably be allocated in new space (unless it's huge).
  // TODO(koda): Eagerly rehash here when no keys have user-defined '==', and
  // in particular, if/when (const) maps are needed in the VM isolate snapshot.
  ASSERT(reader->isolate() != Dart::vm_isolate());
  map.SetHashMask(0);  // Prefer sentinel 0 over null for better type feedback.

  // Read the keys and values.
  bool as_reference = RawObject::IsCanonical(tags) ? false : true;
  for (intptr_t i = 0; i < used_data; i++) {
    *reader->PassiveObjectHandle() = reader->ReadObjectImpl(as_reference);
    data.SetAt(i, *reader->PassiveObjectHandle());
  }
  return map.raw();
}


void RawLinkedHashMap::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  if (kind == Snapshot::kFull || kind == Snapshot::kScript) {
    // The immutable maps that seed map literals are not yet VM-internal, so
    // we don't reach this.
    UNREACHABLE();
  }
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kLinkedHashMapCid);
  const uword tags = writer->GetObjectTags(this);
  writer->WriteTags(tags);

  // Write out the type arguments.
  writer->WriteObjectImpl(ptr()->type_arguments_, kAsInlinedObject);

  const intptr_t used_data = Smi::Value(ptr()->used_data_);
  ASSERT((used_data & 1) == 0);  // Keys + values, so must be even.
  const intptr_t deleted_keys = Smi::Value(ptr()->deleted_keys_);

  // Write out the number of (not deleted) key/value pairs that will follow.
  writer->Write<RawObject*>(Smi::New((used_data >> 1) - deleted_keys));

  // Write out the keys and values.
  const bool as_reference = RawObject::IsCanonical(tags) ? false : true;
  RawArray* data_array = ptr()->data_;
  RawObject** data_elements = data_array->ptr()->data();
  ASSERT(used_data <= Smi::Value(data_array->ptr()->length_));
#if defined(DEBUG)
  intptr_t deleted_keys_found = 0;
#endif  // DEBUG
  for (intptr_t i = 0; i < used_data; i += 2) {
    RawObject* key = data_elements[i];
    if (key == data_array) {
#if defined(DEBUG)
      ++deleted_keys_found;
#endif  // DEBUG
      continue;
    }
    RawObject* value = data_elements[i + 1];
    writer->WriteObjectImpl(key, as_reference);
    writer->WriteObjectImpl(value, as_reference);
  }
  DEBUG_ASSERT(deleted_keys_found == deleted_keys);
}


RawFloat32x4* Float32x4::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the values.
  float value0 = reader->Read<float>();
  float value1 = reader->Read<float>();
  float value2 = reader->Read<float>();
  float value3 = reader->Read<float>();

  // Create a Float32x4 object.
  Float32x4& simd = Float32x4::ZoneHandle(reader->zone(),
                                          Float32x4::null());
  if (kind == Snapshot::kFull) {
    simd = reader->NewFloat32x4(value0, value1, value2, value3);
  } else {
    simd = Float32x4::New(value0, value1, value2, value3, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}


void RawFloat32x4::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kFloat32x4Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the float values.
  writer->Write<float>(ptr()->value_[0]);
  writer->Write<float>(ptr()->value_[1]);
  writer->Write<float>(ptr()->value_[2]);
  writer->Write<float>(ptr()->value_[3]);
}


RawInt32x4* Int32x4::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the values.
  uint32_t value0 = reader->Read<uint32_t>();
  uint32_t value1 = reader->Read<uint32_t>();
  uint32_t value2 = reader->Read<uint32_t>();
  uint32_t value3 = reader->Read<uint32_t>();

  // Create a Float32x4 object.
  Int32x4& simd = Int32x4::ZoneHandle(reader->zone(), Int32x4::null());

  if (kind == Snapshot::kFull) {
    simd = reader->NewInt32x4(value0, value1, value2, value3);
  } else {
    simd = Int32x4::New(value0, value1, value2, value3, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}


void RawInt32x4::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kInt32x4Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the mask values.
  writer->Write<uint32_t>(ptr()->value_[0]);
  writer->Write<uint32_t>(ptr()->value_[1]);
  writer->Write<uint32_t>(ptr()->value_[2]);
  writer->Write<uint32_t>(ptr()->value_[3]);
}


RawFloat64x2* Float64x2::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the values.
  double value0 = reader->Read<double>();
  double value1 = reader->Read<double>();

  // Create a Float64x2 object.
  Float64x2& simd = Float64x2::ZoneHandle(reader->zone(),
                                          Float64x2::null());
  if (kind == Snapshot::kFull) {
    simd = reader->NewFloat64x2(value0, value1);
  } else {
    simd = Float64x2::New(value0, value1, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}


void RawFloat64x2::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kFloat64x2Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the float values.
  writer->Write<double>(ptr()->value_[0]);
  writer->Write<double>(ptr()->value_[1]);
}


#define TYPED_DATA_READ(setter, type)                                          \
  for (intptr_t i = 0; i < length_in_bytes; i += element_size) {               \
    result.Set##setter(i, reader->Read<type>());                               \
  }                                                                            \


RawTypedData* TypedData::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  intptr_t cid = RawObject::ClassIdTag::decode(tags);
  intptr_t len = reader->ReadSmiValue();
  TypedData& result = TypedData::ZoneHandle(reader->zone(),
      (kind == Snapshot::kFull) ? reader->NewTypedData(cid, len)
                                : TypedData::New(cid, len, HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  // Setup the array elements.
  intptr_t element_size = ElementSizeInBytes(cid);
  intptr_t length_in_bytes = len * element_size;
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid: {
      NoSafepointScope no_safepoint;
      uint8_t* data = reinterpret_cast<uint8_t*>(result.DataAddr(0));
      reader->ReadBytes(data, length_in_bytes);
      break;
    }
    case kTypedDataInt16ArrayCid:
      TYPED_DATA_READ(Int16, int16_t);
      break;
    case kTypedDataUint16ArrayCid:
      TYPED_DATA_READ(Uint16, uint16_t);
      break;
    case kTypedDataInt32ArrayCid:
      TYPED_DATA_READ(Int32, int32_t);
      break;
    case kTypedDataUint32ArrayCid:
      TYPED_DATA_READ(Uint32, uint32_t);
      break;
    case kTypedDataInt64ArrayCid:
      TYPED_DATA_READ(Int64, int64_t);
      break;
    case kTypedDataUint64ArrayCid:
      TYPED_DATA_READ(Uint64, uint64_t);
      break;
    case kTypedDataFloat32ArrayCid:
      TYPED_DATA_READ(Float32, float);
      break;
    case kTypedDataFloat64ArrayCid:
      TYPED_DATA_READ(Float64, double);
      break;
    default:
      UNREACHABLE();
  }
  return result.raw();
}
#undef TYPED_DATA_READ


RawExternalTypedData* ExternalTypedData::ReadFrom(SnapshotReader* reader,
                                                  intptr_t object_id,
                                                  intptr_t tags,
                                                  Snapshot::Kind kind) {
  ASSERT(kind != Snapshot::kFull);
  intptr_t cid = RawObject::ClassIdTag::decode(tags);
  intptr_t length = reader->ReadSmiValue();
  uint8_t* data = reinterpret_cast<uint8_t*>(reader->ReadRawPointerValue());
  ExternalTypedData& obj = ExternalTypedData::Handle(
      ExternalTypedData::New(cid, data, length));
  reader->AddBackRef(object_id, &obj, kIsDeserialized);
  void* peer = reinterpret_cast<void*>(reader->ReadRawPointerValue());
  Dart_WeakPersistentHandleFinalizer callback =
      reinterpret_cast<Dart_WeakPersistentHandleFinalizer>(
          reader->ReadRawPointerValue());
  obj.AddFinalizer(peer, callback);
  return obj.raw();
}


#define TYPED_DATA_WRITE(type)                                                 \
  {                                                                            \
    type* data = reinterpret_cast<type*>(ptr()->data());                       \
    for (intptr_t i = 0; i < len; i++) {                                       \
      writer->Write(data[i]);                                                  \
    }                                                                          \
  }                                                                            \


void RawTypedData::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  intptr_t tags = writer->GetObjectTags(this);
  intptr_t cid = ClassIdTag::decode(tags);
  intptr_t len = Smi::Value(ptr()->length_);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(cid);
  writer->WriteTags(tags);

  // Write out the length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the array elements.
  switch (cid) {
    case kTypedDataInt8ArrayCid:
    case kTypedDataUint8ArrayCid:
    case kTypedDataUint8ClampedArrayCid: {
      uint8_t* data = reinterpret_cast<uint8_t*>(ptr()->data());
      writer->WriteBytes(data, len);
      break;
    }
    case kTypedDataInt16ArrayCid:
      TYPED_DATA_WRITE(int16_t);
      break;
    case kTypedDataUint16ArrayCid:
      TYPED_DATA_WRITE(uint16_t);
      break;
    case kTypedDataInt32ArrayCid:
      TYPED_DATA_WRITE(int32_t);
      break;
    case kTypedDataUint32ArrayCid:
      TYPED_DATA_WRITE(uint32_t);
      break;
    case kTypedDataInt64ArrayCid:
      TYPED_DATA_WRITE(int64_t);
      break;
    case kTypedDataUint64ArrayCid:
      TYPED_DATA_WRITE(uint64_t);
      break;
    case kTypedDataFloat32ArrayCid:
      TYPED_DATA_WRITE(float);  // NOLINT.
      break;
    case kTypedDataFloat64ArrayCid:
      TYPED_DATA_WRITE(double);  // NOLINT.
      break;
    default:
      UNREACHABLE();
  }
}


#define TYPED_EXT_DATA_WRITE(type)                                             \
  {                                                                            \
    type* data = reinterpret_cast<type*>(ptr()->data_);                        \
    for (intptr_t i = 0; i < len; i++) {                                       \
      writer->Write(data[i]);                                                  \
    }                                                                          \
  }                                                                            \


#define EXT_TYPED_DATA_WRITE(cid, type)                                        \
  writer->WriteIndexedObject(cid);                                             \
  writer->WriteTags(RawObject::ClassIdTag::update(cid, tags));                 \
  writer->Write<RawObject*>(ptr()->length_);                                   \
  TYPED_EXT_DATA_WRITE(type)                                                   \


void RawExternalTypedData::WriteTo(SnapshotWriter* writer,
                                   intptr_t object_id,
                                   Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  intptr_t tags = writer->GetObjectTags(this);
  intptr_t cid = ClassIdTag::decode(tags);
  intptr_t len = Smi::Value(ptr()->length_);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  switch (cid) {
    case kExternalTypedDataInt8ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataInt8ArrayCid, int8_t);
      break;
    case kExternalTypedDataUint8ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataUint8ArrayCid, uint8_t);
      break;
    case kExternalTypedDataUint8ClampedArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataUint8ClampedArrayCid, uint8_t);
      break;
    case kExternalTypedDataInt16ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataInt16ArrayCid, int16_t);
      break;
    case kExternalTypedDataUint16ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataUint16ArrayCid, uint16_t);
      break;
    case kExternalTypedDataInt32ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataInt32ArrayCid, int32_t);
      break;
    case kExternalTypedDataUint32ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataUint32ArrayCid, uint32_t);
      break;
    case kExternalTypedDataInt64ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataInt64ArrayCid, int64_t);
      break;
    case kExternalTypedDataUint64ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataUint64ArrayCid, uint64_t);
      break;
    case kExternalTypedDataFloat32ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataFloat32ArrayCid, float);  // NOLINT.
      break;
    case kExternalTypedDataFloat64ArrayCid:
      EXT_TYPED_DATA_WRITE(kTypedDataFloat64ArrayCid, double);  // NOLINT.
      break;
    default:
      UNREACHABLE();
  }
}
#undef TYPED_DATA_WRITE
#undef EXT_TYPED_DATA_WRITE


RawCapability* Capability::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  uint64_t id = reader->Read<uint64_t>();

  Capability& result = Capability::ZoneHandle(reader->zone(),
                                              Capability::New(id));
  reader->AddBackRef(object_id, &result, kIsDeserialized);
  return result.raw();
}


void RawCapability::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kCapabilityCid);
  writer->WriteTags(writer->GetObjectTags(this));

  writer->Write<uint64_t>(ptr()->id_);
}


RawReceivePort* ReceivePort::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  UNREACHABLE();
  return ReceivePort::null();
}


void RawReceivePort::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  if (kind == Snapshot::kMessage) {
    // We do not allow objects with native fields in an isolate message.
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (object is a RawReceivePort)");
  } else {
    UNREACHABLE();
  }
}


RawSendPort* SendPort::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  uint64_t id = reader->Read<uint64_t>();
  uint64_t origin_id = reader->Read<uint64_t>();

  SendPort& result = SendPort::ZoneHandle(reader->zone(),
                                          SendPort::New(id, origin_id));
  reader->AddBackRef(object_id, &result, kIsDeserialized);
  return result.raw();
}


void RawSendPort::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kSendPortCid);
  writer->WriteTags(writer->GetObjectTags(this));

  writer->Write<uint64_t>(ptr()->id_);
  writer->Write<uint64_t>(ptr()->origin_id_);
}


RawStacktrace* Stacktrace::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  if (kind == Snapshot::kFull) {
    Stacktrace& result = Stacktrace::ZoneHandle(reader->zone(),
                                                reader->NewStacktrace());
    reader->AddBackRef(object_id, &result, kIsDeserialized);

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (result.raw()->to() - result.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
      result.StorePointer((result.raw()->from() + i),
                          reader->PassiveObjectHandle()->raw());
    }

    bool expand_inlined = reader->Read<bool>();
    result.set_expand_inlined(expand_inlined);

    return result.raw();
  }
  UNREACHABLE();  // Stacktraces are not sent in a snapshot.
  return Stacktrace::null();
}


void RawStacktrace::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  if (kind == Snapshot::kFull) {
    ASSERT(writer != NULL);
    ASSERT(this == Isolate::Current()->object_store()->
           preallocated_stack_trace());

    // Write out the serialization header value for this object.
    writer->WriteInlinedObjectHeader(object_id);

    // Write out the class and tags information.
    writer->WriteIndexedObject(kStacktraceCid);
    writer->WriteTags(writer->GetObjectTags(this));

    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer);
    visitor.VisitPointers(from(), to());

    writer->Write(ptr()->expand_inlined_);
  } else {
    // Stacktraces are not allowed in other snapshot forms.
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (object is a stacktrace)");
  }
}


RawJSRegExp* JSRegExp::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Allocate JSRegExp object.
  JSRegExp& regex = JSRegExp::ZoneHandle(
      reader->zone(), JSRegExp::New(HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &regex, kIsDeserialized);

  // Read and Set all the other fields.
  regex.StoreSmi(&regex.raw_ptr()->num_bracket_expressions_,
                 reader->ReadAsSmi());
  *reader->StringHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
  regex.set_pattern(*reader->StringHandle());
  regex.StoreNonPointer(&regex.raw_ptr()->num_registers_,
                        reader->Read<int32_t>());
  regex.StoreNonPointer(&regex.raw_ptr()->type_flags_,
                        reader->Read<int8_t>());

  // TODO(18854): Need to implement a way of recreating the irrexp functions.
  return regex.raw();
}


void RawJSRegExp::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kJSRegExpCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the other fields.
  writer->Write<RawObject*>(ptr()->num_bracket_expressions_);
  writer->WriteObjectImpl(ptr()->pattern_, kAsInlinedObject);
  writer->Write<int32_t>(ptr()->num_registers_);
  writer->Write<int8_t>(ptr()->type_flags_);
}


RawWeakProperty* WeakProperty::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate the weak property object.
  WeakProperty& weak_property = WeakProperty::ZoneHandle(
      reader->zone(), WeakProperty::New(HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &weak_property, kIsDeserialized);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (weak_property.raw()->to() -
                       weak_property.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
    weak_property.StorePointer((weak_property.raw()->from() + i),
                               reader->PassiveObjectHandle()->raw());
  }

  return weak_property.raw();
}


void RawWeakProperty::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kWeakPropertyCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawMirrorReference* MirrorReference::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  UNREACHABLE();
  return MirrorReference::null();
}


void RawMirrorReference::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind) {
  if (kind == Snapshot::kMessage) {
    // We do not allow objects with native fields in an isolate message.
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (object is a MirrorReference)");
  } else {
    UNREACHABLE();
  }
}


RawUserTag* UserTag::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  UNREACHABLE();
  return UserTag::null();
}


void RawUserTag::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  if (kind == Snapshot::kMessage) {
    // We do not allow objects with native fields in an isolate message.
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (object is a UserTag)");
  } else {
    UNREACHABLE();
  }
}

}  // namespace dart
