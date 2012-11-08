// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bigint_operations.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
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


static uword BigintAllocator(intptr_t size) {
  Zone* zone = Isolate::Current()->current_zone();
  return zone->AllocUnsafe(size);
}


RawClass* Class::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  Class& cls = Class::ZoneHandle(reader->isolate(), Class::null());
  if ((kind == Snapshot::kFull) ||
      (kind == Snapshot::kScript && !RawObject::IsCreatedFromSnapshot(tags))) {
    // Read in the base information.
    intptr_t class_id = reader->ReadIntptrValue();

    // Allocate class object of specified kind.
    if (kind == Snapshot::kFull) {
      cls = reader->NewClass(class_id);
    } else {
      if (class_id < kNumPredefinedCids) {
        ASSERT((class_id >= kInstanceCid) && (class_id <= kDartFunctionCid));
        cls = reader->isolate()->class_table()->At(class_id);
      } else {
        cls = New<Instance>(kIllegalCid);
      }
    }
    reader->AddBackRef(object_id, &cls, kIsDeserialized);

    // Set the object tags.
    cls.set_tags(tags);

    // Set all non object fields.
    cls.set_instance_size(reader->ReadIntptrValue());
    cls.set_type_arguments_instance_field_offset(reader->ReadIntptrValue());
    cls.set_next_field_offset(reader->ReadIntptrValue());
    cls.set_num_native_fields(reader->ReadIntptrValue());
    cls.set_token_pos(reader->ReadIntptrValue());
    cls.set_state_bits(reader->Read<uint8_t>());

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (cls.raw()->to() - cls.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      *(cls.raw()->from() + i) = reader->ReadObjectRef();
    }
  } else {
    cls ^= reader->ReadClassId(object_id);
  }
  return cls.raw();
}


void RawClass::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  if ((kind == Snapshot::kFull) ||
      (kind == Snapshot::kScript &&
       !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)))) {
    // Write out the class and tags information.
    writer->WriteVMIsolateObject(kClassCid);
    writer->WriteIntptrValue(writer->GetObjectTags(this));

    // Write out all the non object pointer fields.
    // NOTE: cpp_vtable_ is not written.
    writer->WriteIntptrValue(ptr()->id_);
    writer->WriteIntptrValue(ptr()->instance_size_);
    writer->WriteIntptrValue(ptr()->type_arguments_instance_field_offset_);
    writer->WriteIntptrValue(ptr()->next_field_offset_);
    writer->WriteIntptrValue(ptr()->num_native_fields_);
    writer->WriteIntptrValue(ptr()->token_pos_);
    writer->Write<uint8_t>(ptr()->state_bits_);

    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer);
    visitor.VisitPointers(from(), to());
  } else {
    writer->WriteClassId(this);
  }
}


RawUnresolvedClass* UnresolvedClass::ReadFrom(SnapshotReader* reader,
                                              intptr_t object_id,
                                              intptr_t tags,
                                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate parameterized type object.
  UnresolvedClass& unresolved_class = UnresolvedClass::ZoneHandle(
      reader->isolate(), NEW_OBJECT(UnresolvedClass));
  reader->AddBackRef(object_id, &unresolved_class, kIsDeserialized);

  // Set the object tags.
  unresolved_class.set_tags(tags);

  // Set all non object fields.
  unresolved_class.set_token_pos(reader->ReadIntptrValue());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (unresolved_class.raw()->to() -
                       unresolved_class.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    unresolved_class.StorePointer((unresolved_class.raw()->from() + i),
                                  reader->ReadObjectRef());
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->WriteIntptrValue(ptr()->token_pos_);

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

  // Allocate type object.
  Type& type = Type::ZoneHandle(reader->isolate(), NEW_OBJECT(Type));
  reader->AddBackRef(object_id, &type, kIsDeserialized);

  // Set all non object fields.
  type.set_token_pos(reader->ReadIntptrValue());
  type.set_type_state(reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type.raw()->to() - type.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    type.StorePointer((type.raw()->from() + i), reader->ReadObjectRef());
  }

  // If object needs to be a canonical object, Canonicalize it.
  if ((kind != Snapshot::kFull) && RawObject::IsCanonical(tags)) {
    type ^= type.Canonicalize();
  }

  // Set the object tags (This is done after 'Canonicalize', which
  // does not canonicalize a type already marked as canonical).
  type.set_tags(tags);

  return type.raw();
}


void RawType::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->WriteIntptrValue(ptr()->token_pos_);
  writer->Write<int8_t>(ptr()->type_state_);

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
          reader->isolate(), NEW_OBJECT(TypeParameter));
  reader->AddBackRef(object_id, &type_parameter, kIsDeserialized);

  // Set the object tags.
  type_parameter.set_tags(tags);

  // Set all non object fields.
  type_parameter.set_index(reader->ReadIntptrValue());
  type_parameter.set_token_pos(reader->ReadIntptrValue());
  type_parameter.set_type_state(reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type_parameter.raw()->to() -
                       type_parameter.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    type_parameter.StorePointer((type_parameter.raw()->from() + i),
                                reader->ReadObjectRef());
  }

  return type_parameter.raw();
}


void RawTypeParameter::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeParameterCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->WriteIntptrValue(ptr()->index_);
  writer->WriteIntptrValue(ptr()->token_pos_);
  writer->Write<int8_t>(ptr()->type_state_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawAbstractTypeArguments* AbstractTypeArguments::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    intptr_t tags,
    Snapshot::Kind kind) {
  UNREACHABLE();  // AbstractTypeArguments is an abstract class.
  return TypeArguments::null();
}


void RawAbstractTypeArguments::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind) {
  UNREACHABLE();  // AbstractTypeArguments is an abstract class.
}


RawTypeArguments* TypeArguments::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();

  TypeArguments& type_arguments = TypeArguments::ZoneHandle(
      reader->isolate(), NEW_OBJECT_WITH_LEN_SPACE(TypeArguments, len, kind));
  reader->AddBackRef(object_id, &type_arguments, kIsDeserialized);

  // Now set all the object fields.
  for (intptr_t i = 0; i < len; i++) {
    *reader->TypeHandle() ^= reader->ReadObjectImpl();
    type_arguments.SetTypeAt(i, *reader->TypeHandle());
  }

  // If object needs to be a canonical object, Canonicalize it.
  if ((kind != Snapshot::kFull) && RawObject::IsCanonical(tags)) {
    type_arguments ^= type_arguments.Canonicalize();
  }

  // Set the object tags (This is done after setting the object fields
  // because 'SetTypeAt' has an assertion to check if the object is not
  // already canonical. Also, this is done after 'Canonicalize', which
  // does not canonicalize a type already marked as canonical).
  type_arguments.set_tags(tags);

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the individual types.
  intptr_t len = Smi::Value(ptr()->length_);
  for (intptr_t i = 0; i < len; i++) {
    writer->WriteObjectImpl(ptr()->types_[i]);
  }
}


RawInstantiatedTypeArguments* InstantiatedTypeArguments::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    intptr_t tags,
    Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Allocate instantiated types object.
  InstantiatedTypeArguments& instantiated_type_arguments =
      InstantiatedTypeArguments::ZoneHandle(reader->isolate(),
                                            InstantiatedTypeArguments::New());
  reader->AddBackRef(object_id, &instantiated_type_arguments, kIsDeserialized);

  // Set the object tags.
  instantiated_type_arguments.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (instantiated_type_arguments.raw()->to() -
                       instantiated_type_arguments.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    instantiated_type_arguments.StorePointer(
        (instantiated_type_arguments.raw()->from() + i),
        reader->ReadObjectRef());
  }
  return instantiated_type_arguments.raw();
}


void RawInstantiatedTypeArguments::WriteTo(SnapshotWriter* writer,
                                           intptr_t object_id,
                                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kInstantiatedTypeArgumentsCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawPatchClass* PatchClass::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate function object.
  PatchClass& cls = PatchClass::ZoneHandle(reader->isolate(),
                                            NEW_OBJECT(PatchClass));
  reader->AddBackRef(object_id, &cls, kIsDeserialized);

  // Set the object tags.
  cls.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (cls.raw()->to() - cls.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(cls.raw()->from() + i) = reader->ReadObjectRef();
  }

  return cls.raw();
}


void RawPatchClass::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kPatchClassCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));
  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawClosureData* ClosureData::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate closure data object.
  ClosureData& data = ClosureData::ZoneHandle(
      reader->isolate(), NEW_OBJECT(ClosureData));
  reader->AddBackRef(object_id, &data, kIsDeserialized);

  // Set the object tags.
  data.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (data.raw()->to() - data.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(data.raw()->from() + i) = reader->ReadObjectRef();
  }

  return data.raw();
}


void RawClosureData::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kClosureDataCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawRedirectionData* RedirectionData::ReadFrom(SnapshotReader* reader,
                                              intptr_t object_id,
                                              intptr_t tags,
                                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate redirection data object.
  RedirectionData& data = RedirectionData::ZoneHandle(
      reader->isolate(), NEW_OBJECT(RedirectionData));
  reader->AddBackRef(object_id, &data, kIsDeserialized);

  // Set the object tags.
  data.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (data.raw()->to() - data.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(data.raw()->from() + i) = reader->ReadObjectRef();
  }

  return data.raw();
}


void RawRedirectionData::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kRedirectionDataCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawFunction* Function::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate function object.
  Function& func = Function::ZoneHandle(
      reader->isolate(), NEW_OBJECT(Function));
  reader->AddBackRef(object_id, &func, kIsDeserialized);

  // Set the object tags.
  func.set_tags(tags);

  // Set all the non object fields.
  func.set_token_pos(reader->ReadIntptrValue());
  func.set_end_token_pos(reader->ReadIntptrValue());
  func.set_usage_counter(reader->ReadIntptrValue());
  func.set_num_fixed_parameters(reader->ReadIntptrValue());
  func.set_num_optional_parameters(reader->ReadIntptrValue());
  func.set_deoptimization_counter(reader->ReadIntptrValue());
  func.set_kind_tag(reader->Read<uint16_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (func.raw()->to() - func.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(func.raw()->from() + i) = reader->ReadObjectRef();
  }

  return func.raw();
}


void RawFunction::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kFunctionCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->WriteIntptrValue(ptr()->token_pos_);
  writer->WriteIntptrValue(ptr()->end_token_pos_);
  writer->WriteIntptrValue(ptr()->usage_counter_);
  writer->WriteIntptrValue(ptr()->num_fixed_parameters_);
  writer->WriteIntptrValue(ptr()->num_optional_parameters_);
  writer->WriteIntptrValue(ptr()->deoptimization_counter_);
  writer->Write<uint16_t>(ptr()->kind_tag_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawField* Field::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate field object.
  Field& field = Field::ZoneHandle(reader->isolate(), NEW_OBJECT(Field));
  reader->AddBackRef(object_id, &field, kIsDeserialized);

  // Set the object tags.
  field.set_tags(tags);

  // Set all non object fields.
  field.set_token_pos(reader->ReadIntptrValue());
  field.set_kind_bits(reader->Read<uint8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (field.raw()->to() - field.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(field.raw()->from() + i) = reader->ReadObjectRef();
  }

  return field.raw();
}


void RawField::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kFieldCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->WriteIntptrValue(ptr()->token_pos_);
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
      reader->isolate(), NEW_OBJECT(LiteralToken));
  reader->AddBackRef(object_id, &literal_token, kIsDeserialized);

  // Set the object tags.
  literal_token.set_tags(tags);

  // Read the token attributes.
  Token::Kind token_kind = static_cast<Token::Kind>(reader->ReadIntptrValue());
  literal_token.set_kind(token_kind);
  *reader->StringHandle() ^= reader->ReadObjectImpl();
  literal_token.set_literal(*reader->StringHandle());
  *reader->ObjectHandle() = reader->ReadObjectImpl();
  literal_token.set_value(*reader->ObjectHandle());

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the kind field.
  writer->Write<intptr_t>(ptr()->kind_);

  // Write out literal and value fields.
  writer->WriteObjectImpl(ptr()->literal_);
  writer->WriteObjectImpl(ptr()->value_);
}


RawTokenStream* TokenStream::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      intptr_t tags,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage)
          && !RawObject::IsCreatedFromSnapshot(tags));

  // Read the length so that we can determine number of tokens to read.
  intptr_t len = reader->ReadSmiValue();

  // Create the token stream object.
  TokenStream& token_stream = TokenStream::ZoneHandle(
      reader->isolate(), NEW_OBJECT_WITH_LEN(TokenStream, len));
  reader->AddBackRef(object_id, &token_stream, kIsDeserialized);

  // Set the object tags.
  token_stream.set_tags(tags);

  // Read the stream of tokens into the TokenStream object for script
  // snapshots as we made a copy of token stream.
  if (kind == Snapshot::kScript) {
    NoGCScope no_gc;
    RawExternalUint8Array* stream = token_stream.GetStream();
    reader->ReadBytes(stream->ptr()->external_data_->data(), len);
  }

  // Read in the literal/identifier token array.
  *(reader->TokensHandle()) ^= reader->ReadObjectImpl();
  token_stream.SetTokenObjects(*(reader->TokensHandle()));
  // Read in the private key in use by the token stream.
  *(reader->StringHandle()) ^= reader->ReadObjectImpl();
  token_stream.SetPrivateKey(*(reader->StringHandle()));

  return token_stream.raw();
}


void RawTokenStream::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kTokenStreamCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the length field and the token stream.
  RawExternalUint8Array* stream = ptr()->stream_;
  intptr_t len = Smi::Value(stream->ptr()->length_);
  writer->Write<RawObject*>(stream->ptr()->length_);
  writer->WriteBytes(stream->ptr()->external_data_->data(), len);

  // Write out the literal/identifier token array.
  writer->WriteObjectImpl(ptr()->token_objects_);
  // Write out the private key in use by the token stream.
  writer->WriteObjectImpl(ptr()->private_key_);
}


RawScript* Script::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate script object.
  Script& script = Script::ZoneHandle(reader->isolate(), NEW_OBJECT(Script));
  reader->AddBackRef(object_id, &script, kIsDeserialized);

  // Set the object tags.
  script.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  *reader->StringHandle() ^= reader->ReadObjectImpl();
  script.set_url(*reader->StringHandle());
  *reader->StringHandle() ^= String::null();
  script.set_source(*reader->StringHandle());
  TokenStream& stream = TokenStream::Handle();
  stream ^= reader->ReadObjectImpl();
  script.set_tokens(stream);

  return script.raw();
}


void RawScript::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(tokens_ != TokenStream::null());
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kScriptCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  writer->WriteObjectImpl(ptr()->url_);
  writer->WriteObjectImpl(ptr()->tokens_);
}


RawLibrary* Library::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind != Snapshot::kMessage);

  Library& library = Library::ZoneHandle(reader->isolate(), Library::null());
  reader->AddBackRef(object_id, &library, kIsDeserialized);

  if (RawObject::IsCreatedFromSnapshot(tags)) {
    ASSERT(kind != Snapshot::kFull);
    // Lookup the object as it should already exist in the heap.
    *reader->StringHandle() ^= reader->ReadObjectImpl();
    library = Library::LookupLibrary(*reader->StringHandle());
  } else {
    // Allocate library object.
    library = NEW_OBJECT(Library);

    // Set the object tags.
    library.set_tags(tags);

    // Set all non object fields.
    library.raw_ptr()->index_ = reader->ReadIntptrValue();
    library.raw_ptr()->num_imports_ = reader->ReadIntptrValue();
    library.raw_ptr()->num_anonymous_ = reader->ReadIntptrValue();
    library.raw_ptr()->corelib_imported_ = reader->Read<bool>();
    library.raw_ptr()->debuggable_ = reader->Read<bool>();
    library.raw_ptr()->load_state_ = reader->Read<int8_t>();
    // The native resolver is not serialized.
    Dart_NativeEntryResolver resolver =
        reader->Read<Dart_NativeEntryResolver>();
    ASSERT(resolver == NULL);
    library.set_native_entry_resolver(resolver);
    // The cache of loaded scripts is not serialized.
    library.raw_ptr()->loaded_scripts_ = Array::null();

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (library.raw()->to() - library.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      *(library.raw()->from() + i) = reader->ReadObjectRef();
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  if (RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this))) {
    ASSERT(kind != Snapshot::kFull);
    // Write out library URL so that it can be looked up when reading.
    writer->WriteObjectImpl(ptr()->url_);
  } else {
    // Write out all non object fields.
    writer->WriteIntptrValue(ptr()->index_);
    writer->WriteIntptrValue(ptr()->num_imports_);
    writer->WriteIntptrValue(ptr()->num_anonymous_);
    writer->Write<bool>(ptr()->corelib_imported_);
    writer->Write<bool>(ptr()->debuggable_);
    writer->Write<int8_t>(ptr()->load_state_);
    // We do not serialize the native resolver over, this needs to be explicitly
    // set after deserialization.
    writer->Write<Dart_NativeEntryResolver>(NULL);
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
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate library prefix object.
  LibraryPrefix& prefix = LibraryPrefix::ZoneHandle(
      reader->isolate(), NEW_OBJECT(LibraryPrefix));
  reader->AddBackRef(object_id, &prefix, kIsDeserialized);

  // Set the object tags.
  prefix.set_tags(tags);

  // Set all non object fields.
  prefix.raw_ptr()->num_imports_ = reader->ReadIntptrValue();

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (prefix.raw()->to() - prefix.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(prefix.raw()->from() + i) = reader->ReadObjectRef();
  }

  return prefix.raw();
}


void RawLibraryPrefix::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kLibraryPrefixCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all non object fields.
  writer->WriteIntptrValue(ptr()->num_imports_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawNamespace* Namespace::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(tags));

  // Allocate Namespace object.
  Namespace& ns = Namespace::ZoneHandle(
      reader->isolate(), NEW_OBJECT(Namespace));
  reader->AddBackRef(object_id, &ns, kIsDeserialized);

  // Set the object tags.
  ns.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (ns.raw()->to() - ns.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(ns.raw()->from() + i) = reader->ReadObjectRef();
  }

  return ns.raw();
}


void RawNamespace::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT((kind != Snapshot::kMessage) &&
         !RawObject::IsCreatedFromSnapshot(writer->GetObjectTags(this)));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kNamespaceCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

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


RawPcDescriptors* PcDescriptors::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          intptr_t tags,
                                          Snapshot::Kind kind) {
  UNREACHABLE();
  return PcDescriptors::null();
}


void RawPcDescriptors::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  UNREACHABLE();
}


RawStackmap* Stackmap::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  UNREACHABLE();
  return Stackmap::null();
}


void RawStackmap::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  UNREACHABLE();
}


RawLocalVarDescriptors* LocalVarDescriptors::ReadFrom(SnapshotReader* reader,
                                                      intptr_t object_id,
                                                      intptr_t tags,
                                                      Snapshot::Kind kind) {
  UNREACHABLE();
  return LocalVarDescriptors::null();
}


void RawLocalVarDescriptors::WriteTo(SnapshotWriter* writer,
                                     intptr_t object_id,
                                     Snapshot::Kind kind) {
  UNREACHABLE();
}


RawExceptionHandlers* ExceptionHandlers::ReadFrom(SnapshotReader* reader,
                                                  intptr_t object_id,
                                                  intptr_t tags,
                                                  Snapshot::Kind kind) {
  UNREACHABLE();
  return ExceptionHandlers::null();
}


void RawExceptionHandlers::WriteTo(SnapshotWriter* writer,
                                   intptr_t object_id,
                                   Snapshot::Kind kind) {
  UNREACHABLE();
}


RawDeoptInfo* DeoptInfo::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  UNREACHABLE();
  return DeoptInfo::null();
}


void RawDeoptInfo::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  UNREACHABLE();
}


RawContext* Context::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate context object.
  intptr_t num_vars = reader->ReadIntptrValue();
  Context& context = Context::ZoneHandle(reader->isolate(), Context::null());
  if (kind == Snapshot::kFull) {
    context = reader->NewContext(num_vars);
  } else {
    context = Context::New(num_vars, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &context, kIsDeserialized);

  // Set the object tags.
  context.set_tags(tags);

  // Set the isolate implicitly.
  context.set_isolate(Isolate::Current());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (context.raw()->to(num_vars) - context.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    context.StorePointer((context.raw()->from() + i), reader->ReadObjectRef());
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out num of variables in the context.
  writer->WriteIntptrValue(ptr()->num_variables_);

  // Can't serialize the isolate pointer, we set it implicitly on read.

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to(ptr()->num_variables_));
}


RawContextScope* ContextScope::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Allocate context scope object.
  intptr_t num_vars = reader->ReadIntptrValue();
  ContextScope& scope = ContextScope::ZoneHandle(reader->isolate(),
                                                 ContextScope::New(num_vars));
  reader->AddBackRef(object_id, &scope, kIsDeserialized);

  // Set the object tags.
  scope.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (scope.raw()->to(num_vars) - scope.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    scope.StorePointer((scope.raw()->from() + i), reader->ReadObjectRef());
  }

  return scope.raw();
}


void RawContextScope::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kContextScopeCid);
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Serialize number of variables.
  writer->WriteIntptrValue(ptr()->num_variables_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to(ptr()->num_variables_));
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
      ApiError::ZoneHandle(reader->isolate(), NEW_OBJECT(ApiError));
  reader->AddBackRef(object_id, &api_error, kIsDeserialized);

  // Set the object tags.
  api_error.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (api_error.raw()->to() - api_error.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    api_error.StorePointer((api_error.raw()->from() + i),
                           reader->ReadObjectRef());
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

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
      LanguageError::ZoneHandle(reader->isolate(), NEW_OBJECT(LanguageError));
  reader->AddBackRef(object_id, &language_error, kIsDeserialized);

  // Set the object tags.
  language_error.set_tags(tags);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds =
      (language_error.raw()->to() - language_error.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    language_error.StorePointer((language_error.raw()->from() + i),
                                reader->ReadObjectRef());
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer);
  visitor.VisitPointers(from(), to());
}


RawUnhandledException* UnhandledException::ReadFrom(SnapshotReader* reader,
                                                    intptr_t object_id,
                                                    intptr_t tags,
                                                    Snapshot::Kind kind) {
  UNREACHABLE();
  return UnhandledException::null();
}


void RawUnhandledException::WriteTo(SnapshotWriter* writer,
                                    intptr_t object_id,
                                    Snapshot::Kind kind) {
  UNREACHABLE();
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
  UNREACHABLE();
  return Instance::null();
}


void RawInstance::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  UNREACHABLE();
}


RawMint* Mint::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
                        intptr_t tags,
                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the 64 bit value for the object.
  int64_t value = reader->Read<int64_t>();

  // Create a Mint object or get canonical one if it is a canonical constant.
  Mint& mint = Mint::ZoneHandle(reader->isolate(), Mint::null());
  if (kind == Snapshot::kFull) {
    mint = reader->NewMint(value);
  } else {
    if (RawObject::IsCanonical(tags)) {
      mint = Mint::NewCanonical(value);
    } else {
      mint = Mint::New(value, HEAP_SPACE(kind));
    }
  }
  reader->AddBackRef(object_id, &mint, kIsDeserialized);

  // Set the object tags.
  mint.set_tags(tags);

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the 64 bit value.
  writer->Write<int64_t>(ptr()->value_);
}


RawBigint* Bigint::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read in the HexCString representation of the bigint.
  intptr_t len = reader->ReadIntptrValue();
  char* str = Isolate::Current()->current_zone()->Alloc<char>(len + 1);
  str[len] = '\0';
  reader->ReadBytes(reinterpret_cast<uint8_t*>(str), len);

  // Create a Bigint object from HexCString.
  Bigint& obj = Bigint::ZoneHandle(
      reader->isolate(),
      ((kind == Snapshot::kFull) ? reader->NewBigint(str) :
       BigintOperations::FromHexCString(str, HEAP_SPACE(kind))));

  // If it is a canonical constant make it one.
  if ((kind != Snapshot::kFull) && RawObject::IsCanonical(tags)) {
    obj ^= obj.Canonicalize();
  }
  reader->AddBackRef(object_id, &obj, kIsDeserialized);

  // Set the object tags.
  obj.set_tags(tags);

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the bigint value as a HEXCstring.
  intptr_t length = ptr()->signed_length_;
  bool is_negative = false;
  if (length <= 0) {
    length = -length;
    is_negative = true;
  }
  uword data_start = reinterpret_cast<uword>(ptr()) + sizeof(RawBigint);
  const char* str = BigintOperations::ToHexCString(
      length,
      is_negative,
      reinterpret_cast<void*>(data_start),
      &BigintAllocator);
  bool neg = false;
  if (*str == '-') {
    neg = true;
    str++;
  }
  intptr_t len = strlen(str);
  ASSERT(len > 2 && str[0] == '0' && str[1] == 'x');
  if (neg) {
    writer->WriteIntptrValue(len - 1);  // Include '-' in length.
    writer->Write<uint8_t>('-');
  } else {
    writer->WriteIntptrValue(len - 2);
  }
  writer->WriteBytes(reinterpret_cast<const uint8_t*>(&(str[2])), (len - 2));
}


RawDouble* Double::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            intptr_t tags,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the double value for the object.
  double value = reader->Read<double>();

  // Create a Double object or get canonical one if it is a canonical constant.
  Double& dbl = Double::ZoneHandle(reader->isolate(), Double::null());
  if (kind == Snapshot::kFull) {
    dbl = reader->NewDouble(value);
  } else {
    if (RawObject::IsCanonical(tags)) {
      dbl = Double::NewCanonical(value);
    } else {
      dbl = Double::New(value, HEAP_SPACE(kind));
    }
  }
  reader->AddBackRef(object_id, &dbl, kIsDeserialized);

  // Set the object tags.
  dbl.set_tags(tags);

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the double value.
  writer->Write<double>(ptr()->value_);
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


template<typename StringType, typename CharacterType>
void String::ReadFromImpl(SnapshotReader* reader,
                          String* str_obj,
                          intptr_t len,
                          intptr_t tags,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  if (RawObject::IsCanonical(tags)) {
    // Set up canonical string object.
    ASSERT(reader != NULL);
    CharacterType* ptr =
        Isolate::Current()->current_zone()->Alloc<CharacterType>(len);
    for (intptr_t i = 0; i < len; i++) {
      ptr[i] = reader->Read<CharacterType>();
    }
    *str_obj ^= Symbols::New(ptr, len);
  } else {
    // Set up the string object.
    *str_obj = StringType::New(len, HEAP_SPACE(kind));
    str_obj->set_tags(tags);
    str_obj->SetHash(0);  // Will get computed when needed.
    for (intptr_t i = 0; i < len; i++) {
      *StringType::CharAddr(*str_obj, i) = reader->Read<CharacterType>();
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
  String& str_obj = String::Handle(reader->isolate(), String::null());

  if (kind == Snapshot::kFull) {
    ASSERT(reader->isolate()->no_gc_scope_depth() != 0);
    RawOneByteString* obj = reader->NewOneByteString(len);
    str_obj = obj;
    str_obj.set_tags(tags);
    obj->ptr()->hash_ = Smi::New(hash);
    if (len > 0) {
      uint8_t* raw_ptr = CharAddr(str_obj, 0);
      reader->ReadBytes(raw_ptr, len);
    }
    ASSERT((hash == 0) || (String::Hash(str_obj, 0, str_obj.Length()) == hash));
  } else {
    String::ReadFromImpl<OneByteString, uint8_t>(
        reader, &str_obj, len, tags, kind);
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
  String& str_obj = String::Handle(reader->isolate(), String::null());

  if (kind == Snapshot::kFull) {
    RawTwoByteString* obj = reader->NewTwoByteString(len);
    str_obj = obj;
    str_obj.set_tags(tags);
    obj->ptr()->hash_ = Smi::New(hash);
    uint16_t* raw_ptr = (len > 0)? CharAddr(str_obj, 0) : NULL;
    for (intptr_t i = 0; i < len; i++) {
      ASSERT(CharAddr(str_obj, i) == raw_ptr);  // Will trigger assertions.
      *raw_ptr = reader->Read<uint16_t>();
      raw_ptr += 1;
    }
    ASSERT(String::Hash(str_obj, 0, str_obj.Length()) == hash);
  } else {
    String::ReadFromImpl<TwoByteString, uint16_t>(
        reader, &str_obj, len, tags, kind);
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
  writer->WriteIntptrValue(tags);

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
                ptr()->data_);
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
                ptr()->data_);
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
    array = &(Array::ZoneHandle(reader->isolate(),
                                NEW_OBJECT_WITH_LEN_SPACE(Array, len, kind)));
    reader->AddBackRef(object_id, array, kIsDeserialized);
  }
  reader->ArrayReadFrom(*array, len, tags);
  return array->raw();
}


RawImmutableArray* ImmutableArray::ReadFrom(SnapshotReader* reader,
                                            intptr_t object_id,
                                            intptr_t tags,
                                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();
  ImmutableArray* array = reinterpret_cast<ImmutableArray*>(
      reader->GetBackRef(object_id));
  if (array == NULL) {
    array = &(ImmutableArray::ZoneHandle(
        reader->isolate(),
        NEW_OBJECT_WITH_LEN_SPACE(ImmutableArray, len, kind)));
    reader->AddBackRef(object_id, array, kIsDeserialized);
  }
  reader->ArrayReadFrom(*array, len, tags);
  return array->raw();
}


void RawArray::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
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
      reader->isolate(), GrowableObjectArray::null());
  if (kind == Snapshot::kFull) {
    array = reader->NewGrowableObjectArray();
  } else {
    array = GrowableObjectArray::New(0, HEAP_SPACE(kind));
  }
  reader->AddBackRef(object_id, &array, kIsDeserialized);
  intptr_t length = reader->ReadSmiValue();
  array.SetLength(length);
  Array& contents = Array::Handle();
  contents ^= reader->ReadObjectImpl();
  array.SetData(contents);
  const AbstractTypeArguments& type_arguments =
      AbstractTypeArguments::Handle(contents.GetTypeArguments());
  array.SetTypeArguments(type_arguments);
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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the used length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the Array object.
  writer->WriteObjectImpl(ptr()->data_);
}


RawByteArray* ByteArray::ReadFrom(SnapshotReader* reader,
                                  intptr_t object_id,
                                  intptr_t tags,
                                  Snapshot::Kind kind) {
  UNREACHABLE();  // ByteArray is an abstract class.
  return ByteArray::null();
}


template<typename HandleT, typename RawT, typename ElementT>
RawT* ByteArray::ReadFromImpl(SnapshotReader* reader,
                              intptr_t object_id,
                              intptr_t tags,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  intptr_t len = reader->ReadSmiValue();
  HandleT& result = HandleT::ZoneHandle(
      reader->isolate(), HandleT::New(len, HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  // Set the object tags.
  result.set_tags(tags);

  // Setup the array elements.
  for (intptr_t i = 0; i < len; ++i) {
    result.SetAt(i, reader->Read<ElementT>());
  }
  return result.raw();
}


#define BYTEARRAY_TYPE_LIST(V)                                                 \
  V(Int8, int8, int8_t)                                                        \
  V(Uint8, uint8, uint8_t)                                                     \
  V(Int16, int16, int16_t)                                                     \
  V(Uint16, uint16, uint16_t)                                                  \
  V(Int32, int32, int32_t)                                                     \
  V(Uint32, uint32, uint32_t)                                                  \
  V(Int64, int64, int64_t)                                                     \
  V(Uint64, uint64, uint64_t)                                                  \
  V(Float32, float32, float)                                                   \
  V(Float64, float64, double)                                                  \


#define BYTEARRAY_READ_FROM(name, lname, type)                                 \
Raw##name##Array* name##Array::ReadFrom(SnapshotReader* reader,                \
                                          intptr_t object_id,                  \
                                          intptr_t tags,                       \
                                          Snapshot::Kind kind) {               \
  return ReadFromImpl<name##Array, Raw##name##Array, type>(reader,             \
                                                           object_id,          \
                                                           tags,               \
                                                           kind);              \
}                                                                              \


BYTEARRAY_TYPE_LIST(BYTEARRAY_READ_FROM)
#undef BYTEARRAY_READ_FROM


#define EXTERNALARRAY_READ_FROM(name, lname, type)                             \
RawExternal##name##Array* External##name##Array::ReadFrom(                     \
    SnapshotReader* reader,                                                    \
    intptr_t object_id,                                                        \
    intptr_t tags,                                                             \
    Snapshot::Kind kind) {                                                     \
  ASSERT(kind != Snapshot::kFull);                                             \
  intptr_t length = reader->ReadSmiValue();                                    \
  type* data = reinterpret_cast<type*>(reader->ReadIntptrValue());             \
  void* peer = reinterpret_cast<void*>(reader->ReadIntptrValue());             \
  Dart_PeerFinalizer callback =                                                \
      reinterpret_cast<Dart_PeerFinalizer>(reader->ReadIntptrValue());         \
  return New(data, length, peer, callback, HEAP_SPACE(kind));                  \
}                                                                              \


BYTEARRAY_TYPE_LIST(EXTERNALARRAY_READ_FROM)
#undef EXTERNALARRAY_READ_FROM


template<typename ElementT>
static void ByteArrayWriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind,
                             intptr_t byte_array_kind,
                             intptr_t tags,
                             RawSmi* length,
                             ElementT* data) {
  ASSERT(writer != NULL);
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(byte_array_kind);
  writer->WriteIntptrValue(tags);

  // Write out the length field.
  writer->Write<RawObject*>(length);

  // Write out the array elements.
  for (intptr_t i = 0; i < len; i++) {
    writer->Write(data[i]);
  }
}


void RawByteArray::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind) {
  UNREACHABLE();  // ByteArray is an abstract class
}


#define BYTEARRAY_WRITE_TO(name, lname, type)                                  \
void Raw##name##Array::WriteTo(SnapshotWriter* writer,                         \
                               intptr_t object_id,                             \
                               Snapshot::Kind kind) {                          \
  ByteArrayWriteTo(writer,                                                     \
                   object_id,                                                  \
                   kind,                                                       \
                   k##name##ArrayCid,                                          \
                   writer->GetObjectTags(this),                                \
                   ptr()->length_,                                             \
                   ptr()->data_);                                              \
}                                                                              \


BYTEARRAY_TYPE_LIST(BYTEARRAY_WRITE_TO)
#undef BYTEARRAY_WRITE_TO


#define EXTERNALARRAY_WRITE_TO(name, lname, type)                              \
void RawExternal##name##Array::WriteTo(SnapshotWriter* writer,                 \
                                       intptr_t object_id,                     \
                                       Snapshot::Kind kind) {                  \
  ByteArrayWriteTo(writer,                                                     \
                   object_id,                                                  \
                   kind,                                                       \
                   k##name##ArrayCid,                                          \
                   writer->GetObjectTags(this),                                \
                   ptr()->length_,                                             \
                   ptr()->external_data_->data());                             \
}                                                                              \


BYTEARRAY_TYPE_LIST(EXTERNALARRAY_WRITE_TO)
#undef BYTEARRAY_WRITE_TO
#undef BYTEARRAY_TYPE_LIST


RawDartFunction* DartFunction::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  UNREACHABLE();  // DartFunction is an abstract class.
  return DartFunction::null();
}


void RawDartFunction::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNREACHABLE();  // DartFunction is an abstract class.
}


RawStacktrace* Stacktrace::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    intptr_t tags,
                                    Snapshot::Kind kind) {
  UNIMPLEMENTED();
  return Stacktrace::null();
}


void RawStacktrace::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  UNIMPLEMENTED();
}


RawJSRegExp* JSRegExp::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                intptr_t tags,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();

  // Allocate JSRegExp object.
  JSRegExp& regex = JSRegExp::ZoneHandle(
      reader->isolate(), JSRegExp::New(len, HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &regex, kIsDeserialized);

  // Set the object tags.
  regex.set_tags(tags);

  // Read and Set all the other fields.
  regex.raw_ptr()->num_bracket_expressions_ = reader->ReadAsSmi();
  *reader->StringHandle() ^= reader->ReadObjectImpl();
  regex.set_pattern(*reader->StringHandle());
  regex.raw_ptr()->type_ = reader->ReadIntptrValue();
  regex.raw_ptr()->flags_ = reader->ReadIntptrValue();

  // TODO(5411462): Need to implement a way of recompiling the regex.

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out the data length field.
  writer->Write<RawObject*>(ptr()->data_length_);

  // Write out all the other fields.
  writer->Write<RawObject*>(ptr()->num_bracket_expressions_);
  writer->WriteObjectImpl(ptr()->pattern_);
  writer->WriteIntptrValue(ptr()->type_);
  writer->WriteIntptrValue(ptr()->flags_);

  // Do not write out the data part which is native.
}


RawWeakProperty* WeakProperty::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        intptr_t tags,
                                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate the weak property object.
  WeakProperty& weak_property = WeakProperty::ZoneHandle(
      reader->isolate(), WeakProperty::New(HEAP_SPACE(kind)));
  reader->AddBackRef(object_id, &weak_property, kIsDeserialized);

  // Set the object tags.
  weak_property.set_tags(tags);

  // Set all the object fields.
  weak_property.raw_ptr()->key_ = reader->ReadObjectRef();
  weak_property.raw_ptr()->value_ = reader->ReadObjectRef();

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
  writer->WriteIntptrValue(writer->GetObjectTags(this));

  // Write out all the other fields.
  writer->Write<RawObject*>(ptr()->key_);
  writer->Write<RawObject*>(ptr()->value_);
}

}  // namespace dart
