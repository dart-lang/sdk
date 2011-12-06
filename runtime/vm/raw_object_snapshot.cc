// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bigint_operations.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/visitor.h"

namespace dart {

static RawSmi* GetSmi(intptr_t value) {
  ASSERT((value & kSmiTagMask) == 0);
  return reinterpret_cast<RawSmi*>(value);
}


static uword ZoneAllocator(intptr_t size) {
  Zone* zone = Isolate::Current()->current_zone();
  return zone->Allocate(size);
}


RawClass* Class::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  Class& cls = Class::ZoneHandle();
  if (kind == Snapshot::kFull) {
    // Read in the base information.
    ObjectKind kind = reader->Read<ObjectKind>();

    // Allocate class object of specified kind.
    cls = Class::GetClass(kind);
    reader->AddBackwardReference(object_id, &cls);

    // Set all non object fields.
    cls.set_instance_size(reader->Read<intptr_t>());
    cls.set_type_arguments_instance_field_offset(reader->Read<intptr_t>());
    cls.set_next_field_offset(reader->Read<intptr_t>());
    cls.set_num_native_fields(reader->Read<intptr_t>());
    cls.set_class_state(reader->Read<int8_t>());
    if (reader->Read<bool>()) {
      cls.set_is_const();
    }
    if (reader->Read<bool>()) {
      cls.set_is_interface();
    }

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds = (cls.raw()->to() - cls.raw()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      *(cls.raw()->from() + i) = reader->ReadObject();
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
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  if (kind == Snapshot::kFull) {
    // Write out the class information.
    writer->WriteObjectHeader(kObjectId, Object::kClassClass);

    // Write out all the non object pointer fields.
    // NOTE: cpp_vtable_ is not written.
    writer->Write<ObjectKind>(ptr()->instance_kind_);
    writer->Write<intptr_t>(ptr()->instance_size_);
    writer->Write<intptr_t>(ptr()->type_arguments_instance_field_offset_);
    writer->Write<intptr_t>(ptr()->next_field_offset_);
    writer->Write<intptr_t>(ptr()->num_native_fields_);
    writer->Write<int8_t>(ptr()->class_state_);
    writer->Write<bool>(ptr()->is_const_);
    writer->Write<bool>(ptr()->is_interface_);

    // Write out all the object pointer fields.
    visitor.VisitPointers(from(), to());
  } else {
    writer->WriteClassId(this);
  }
}


RawUnresolvedClass* UnresolvedClass::ReadFrom(SnapshotReader* reader,
                                              intptr_t object_id,
                                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate parameterized type object.
  UnresolvedClass& unresolved_class =
      UnresolvedClass::ZoneHandle(UnresolvedClass::New());
  reader->AddBackwardReference(object_id, &unresolved_class);

  // Set all non object fields.
  unresolved_class.set_token_index(reader->Read<intptr_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (unresolved_class.raw()->to() -
                       unresolved_class.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(unresolved_class.raw()->from() + i) = reader->ReadObject();
  }
  return unresolved_class.raw();
}


void RawUnresolvedClass::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kUnresolvedClassClass);

  // Write out all the non object pointer fields.
  writer->Write<intptr_t>(ptr()->token_index_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawAbstractType* AbstractType::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
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
                                                  Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate parameterized type object.
  Type& parameterized_type = Type::ZoneHandle(Type::New());
  reader->AddBackwardReference(object_id, &parameterized_type);

  // Set all non object fields.
  parameterized_type.set_type_state(reader->Read<int8_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (parameterized_type.raw()->to() -
                       parameterized_type.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(parameterized_type.raw()->from() + i) = reader->ReadObject();
  }
  return parameterized_type.raw();
}


void RawType::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kTypeClass);

  // Write out all the non object pointer fields.
  writer->Write<int8_t>(ptr()->type_state_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawTypeParameter* TypeParameter::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate type parameter object.
  TypeParameter& type_parameter =
      TypeParameter::ZoneHandle(TypeParameter::New());
  reader->AddBackwardReference(object_id, &type_parameter);

  // Set all non object fields.
  type_parameter.set_index(reader->Read<intptr_t>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (type_parameter.raw()->to() -
                       type_parameter.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(type_parameter.raw()->from() + i) = reader->ReadObject();
  }

  return type_parameter.raw();
}


void RawTypeParameter::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kTypeParameterClass);

  writer->Write<intptr_t>(ptr()->index_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawInstantiatedType* InstantiatedType::ReadFrom(SnapshotReader* reader,
                                                intptr_t object_id,
                                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate instantiated type object.
  InstantiatedType& instantiated_type =
      InstantiatedType::ZoneHandle(InstantiatedType::New());
  reader->AddBackwardReference(object_id, &instantiated_type);

  // Now set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (instantiated_type.raw()->to() -
                       instantiated_type.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(instantiated_type.raw()->from() + i) = reader->ReadObject();
  }
  return instantiated_type.raw();
}


void RawInstantiatedType::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kInstantiatedTypeClass);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawAbstractTypeArguments* AbstractTypeArguments::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
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
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  RawSmi* smi_len = GetSmi(reader->Read<intptr_t>());
  intptr_t len = Smi::Value(smi_len);

  TypeArguments& type_array = TypeArguments::Handle(TypeArguments::New(len));
  reader->AddBackwardReference(object_id, &type_array);
  AbstractType& type = AbstractType::Handle();
  for (intptr_t i = 0; i < len; i++) {
    type ^= reader->ReadObject();
    type_array.SetTypeAt(i, type);
  }
  return type_array.raw();
}


void RawTypeArguments::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kTypeArgumentsClass);

  // Write out the length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the individual types.
  intptr_t len = Smi::Value(ptr()->length_);
  for (intptr_t i = 0; i < len; i++) {
    writer->WriteObject(ptr()->types_[i]);
  }
}


RawInstantiatedTypeArguments* InstantiatedTypeArguments::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate instantiated types object.
  InstantiatedTypeArguments& instantiated_type_arguments =
      InstantiatedTypeArguments::ZoneHandle(InstantiatedTypeArguments::New());
  reader->AddBackwardReference(object_id, &instantiated_type_arguments);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (instantiated_type_arguments.raw()->to() -
                       instantiated_type_arguments.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(instantiated_type_arguments.raw()->from() + i) = reader->ReadObject();
  }
  return instantiated_type_arguments.raw();
}


void RawInstantiatedTypeArguments::WriteTo(SnapshotWriter* writer,
                                           intptr_t object_id,
                                           Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kInstantiatedTypeArgumentsClass);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawFunction* Function::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate function object.
  Function& func = Function::ZoneHandle(Function::New());
  reader->AddBackwardReference(object_id, &func);

  // Set all the non object fields.
  func.set_token_index(reader->Read<intptr_t>());
  func.set_num_fixed_parameters(reader->Read<intptr_t>());
  func.set_num_optional_parameters(reader->Read<intptr_t>());
  func.set_invocation_counter(reader->Read<intptr_t>());
  func.set_deoptimization_counter(reader->Read<intptr_t>());
  func.set_kind(static_cast<RawFunction::Kind >(reader->Read<intptr_t>()));
  func.set_is_static(reader->Read<bool>());
  func.set_is_const(reader->Read<bool>());
  func.set_is_optimizable(reader->Read<bool>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (func.raw()->to() - func.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(func.raw()->from() + i) = reader->ReadObject();
  }

  return func.raw();
}


void RawFunction::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kFunctionClass);

  // Write out all the non object fields.
  writer->Write<intptr_t>(ptr()->token_index_);
  writer->Write<intptr_t>(ptr()->num_fixed_parameters_);
  writer->Write<intptr_t>(ptr()->num_optional_parameters_);
  writer->Write<intptr_t>(ptr()->invocation_counter_);
  writer->Write<intptr_t>(ptr()->deoptimization_counter_);
  writer->Write<intptr_t>(ptr()->kind_);
  writer->Write<bool>(ptr()->is_static_);
  writer->Write<bool>(ptr()->is_const_);
  writer->Write<bool>(ptr()->is_optimizable_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawField* Field::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate field object.
  Field& field = Field::ZoneHandle(Field::New());
  reader->AddBackwardReference(object_id, &field);

  // Set all non object fields.
  field.set_token_index(reader->Read<intptr_t>());
  field.set_is_static(reader->Read<bool>());
  field.set_is_final(reader->Read<bool>());
  field.set_has_initializer(reader->Read<bool>());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (field.raw()->to() - field.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(field.raw()->from() + i) = reader->ReadObject();
  }

  return field.raw();
}


void RawField::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kFieldClass);

  writer->Write<intptr_t>(ptr()->token_index_);
  writer->Write<bool>(ptr()->is_static_);
  writer->Write<bool>(ptr()->is_final_);
  writer->Write<bool>(ptr()->has_initializer_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawTokenStream* TokenStream::ReadFrom(SnapshotReader* reader,
                                      intptr_t object_id,
                                      Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine number of tokens to read.
  RawSmi* smi_len = GetSmi(reader->Read<intptr_t>());
  intptr_t len = Smi::Value(smi_len);

  // Create the token stream object.
  TokenStream& token_stream = TokenStream::ZoneHandle(TokenStream::New(len));
  reader->AddBackwardReference(object_id, &token_stream);

  // Read the token stream into the TokenStream.
  String& literal = String::Handle();
  for (intptr_t i = 0; i < len; i++) {
    Token::Kind kind = static_cast<Token::Kind>(
        Smi::Value(GetSmi(reader->Read<intptr_t>())));
    literal ^= reader->ReadObject();
    token_stream.SetTokenAt(i, kind, literal);
  }
  return token_stream.raw();
}


void RawTokenStream::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kTokenStreamClass);

  // Write out the length field.
  writer->Write<RawObject*>(ptr()->length_);

  // Write out the token stream (token kind and literal).
  intptr_t len = Smi::Value(ptr()->length_);
  for (intptr_t i = 0; i < TokenStream::StreamLength(len); i++) {
    writer->WriteObject(ptr()->data_[i]);
  }
}


RawScript* Script::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate script object.
  Script& script = Script::ZoneHandle(Script::New());
  reader->AddBackwardReference(object_id, &script);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (script.raw()->to() - script.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(script.raw()->from() + i) = reader->ReadObject();
  }

  return script.raw();
}


void RawScript::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  ASSERT(tokens_ != TokenStream::null());
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kScriptClass);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawLibrary* Library::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate library object.
  Library& library = Library::ZoneHandle(Library::New());
  reader->AddBackwardReference(object_id, &library);

  // Set all non object fields.
  library.raw_ptr()->num_imports_ = reader->Read<intptr_t>();
  library.raw_ptr()->num_imported_into_ = reader->Read<intptr_t>();
  library.raw_ptr()->num_anonymous_ = reader->Read<intptr_t>();
  library.raw_ptr()->corelib_imported_ = reader->Read<bool>();
  library.raw_ptr()->load_state_ = reader->Read<int8_t>();
  // The native resolver is not serialized.
  Dart_NativeEntryResolver resolver = reader->Read<Dart_NativeEntryResolver>();
  ASSERT(resolver == NULL);
  library.set_native_entry_resolver(resolver);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (library.raw()->to() - library.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(library.raw()->from() + i) = reader->ReadObject();
  }

  return library.raw();
}


void RawLibrary::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kLibraryClass);

  writer->Write<intptr_t>(ptr()->num_imports_);
  writer->Write<intptr_t>(ptr()->num_imported_into_);
  writer->Write<intptr_t>(ptr()->num_anonymous_);
  writer->Write<bool>(ptr()->corelib_imported_);
  writer->Write<int8_t>(ptr()->load_state_);
  // We do not serialize the native resolver over, this needs to be explicitly
  // set after deserialization.
  writer->Write<Dart_NativeEntryResolver>(NULL);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawLibraryPrefix* LibraryPrefix::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate library prefix object.
  LibraryPrefix& prefix = LibraryPrefix::ZoneHandle(LibraryPrefix::New());
  reader->AddBackwardReference(object_id, &prefix);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (prefix.raw()->to() - prefix.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(prefix.raw()->from() + i) = reader->ReadObject();
  }

  return prefix.raw();
}


void RawLibraryPrefix::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kLibraryPrefixClass);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to());
}


RawCode* Code::ReadFrom(SnapshotReader* reader,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Create Code object.
  Code& code = Code::ZoneHandle(Code::New(0));
  reader->AddBackwardReference(object_id, &code);
  return code.raw();
}


void RawCode::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  // Currently we do not serialize any code and hence we write
  // out a null object for it.
  ASSERT(writer != NULL);

  writer->WriteObjectHeader(kObjectId, Object::kNullObject);
}


RawInstructions* Instructions::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
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
                                          Snapshot::Kind kind) {
  UNREACHABLE();
  return PcDescriptors::null();
}


void RawPcDescriptors::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  UNREACHABLE();
}


RawExceptionHandlers* ExceptionHandlers::ReadFrom(SnapshotReader* reader,
                                                  intptr_t object_id,
                                                  Snapshot::Kind kind) {
  UNREACHABLE();
  return ExceptionHandlers::null();
}


void RawExceptionHandlers::WriteTo(SnapshotWriter* writer,
                                   intptr_t object_id,
                                   Snapshot::Kind kind) {
  UNREACHABLE();
}


RawContext* Context::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate context object.
  intptr_t num_vars = reader->Read<intptr_t>();
  Context& context = Context::ZoneHandle(
      Context::New(num_vars,
                   (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  reader->AddBackwardReference(object_id, &context);

  // Set the isolate implicitly.
  context.set_isolate(Isolate::Current());

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (context.raw()->to(num_vars) - context.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(context.raw()->from() + i) = reader->ReadObject();
  }

  return context.raw();
}


void RawContext::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kContextClass);

  // Write out num of variables in the context.
  writer->Write<intptr_t>(ptr()->num_variables_);

  // Can't serialize the isolate pointer, we set it implicitly on read.

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to(ptr()->num_variables_));
}


RawContextScope* ContextScope::ReadFrom(SnapshotReader* reader,
                                        intptr_t object_id,
                                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Allocate context scope object.
  intptr_t num_vars = reader->Read<intptr_t>();
  ContextScope& scope = ContextScope::ZoneHandle(ContextScope::New(num_vars));
  reader->AddBackwardReference(object_id, &scope);

  // Set all the object fields.
  // TODO(5411462): Need to assert No GC can happen here, even though
  // allocations may happen.
  intptr_t num_flds = (scope.raw()->to(num_vars) - scope.raw()->from());
  for (intptr_t i = 0; i <= num_flds; i++) {
    *(scope.raw()->from() + i) = reader->ReadObject();
  }

  return scope.raw();
}


void RawContextScope::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  ASSERT(writer != NULL);
  SnapshotWriterVisitor visitor(writer);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, Object::kContextScopeClass);

  // Serialize number of variables.
  writer->Write<intptr_t>(ptr()->num_variables_);

  // Write out all the object pointer fields.
  visitor.VisitPointers(from(), to(ptr()->num_variables_));
}


RawUnhandledException* UnhandledException::ReadFrom(SnapshotReader* reader,
                                                    intptr_t object_id,
                                                    Snapshot::Kind kind) {
  UNIMPLEMENTED();
  return UnhandledException::null();
}


void RawUnhandledException::WriteTo(SnapshotWriter* writer,
                                    intptr_t object_id,
                                    Snapshot::Kind kind) {
  UNIMPLEMENTED();
}


RawApiError* ApiError::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    Snapshot::Kind kind) {
  UNIMPLEMENTED();
  return ApiError::null();
}


void RawApiError::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  UNIMPLEMENTED();
}


RawInstance* Instance::ReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
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
                        Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the 64 bit value for the object.
  int64_t value = reader->Read<int64_t>();

  // Create a Mint object.
  Mint& mint = Mint::ZoneHandle(
      Mint::New(value, (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  reader->AddBackwardReference(object_id, &mint);
  return mint.raw();
}


void RawMint::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, ObjectStore::kMintClass);

  // Write out the 64 bit value.
  writer->Write<int64_t>(ptr()->value_);
}


RawBigint* Bigint::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read in the HexCString representation of the bigint.
  intptr_t len = reader->Read<intptr_t>();
  char* str = reinterpret_cast<char*>(ZoneAllocator(len + 1));
  str[len] = '\0';
  for (intptr_t i = 0; i < len; i++) {
    str[i] = reader->Read<uint8_t>();
  }
  // Create a Bigint object from HexCString.
  Bigint& obj = Bigint::ZoneHandle(BigintOperations::FromHexCString(str));
  reader->AddBackwardReference(object_id, &obj);
  return obj.raw();
}


void RawBigint::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, ObjectStore::kBigintClass);

  // Write out the bigint value as a HEXCstring.
  ptr()->bn_.d = ptr()->data_;
  const char* str = BigintOperations::ToHexCString(&ptr()->bn_, &ZoneAllocator);
  intptr_t len = strlen(str);
  writer->Write<intptr_t>(len-2);
  for (intptr_t i = 2; i < len; i++) {
    writer->Write<uint8_t>(str[i]);
  }
}


RawDouble* Double::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the double value for the object.
  double value = reader->Read<double>();
  // Create a double object.
  Double& dbl = Double::ZoneHandle(
      Double::New(value, (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  reader->AddBackwardReference(object_id, &dbl);
  return dbl.raw();
}


void RawDouble::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, ObjectStore::kDoubleClass);

  // Write out the double value.
  writer->Write<double>(ptr()->value_);
}


RawString* String::ReadFrom(SnapshotReader* reader,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  UNREACHABLE();  // String is an abstract class.
  return String::null();
}


void RawString::WriteTo(SnapshotWriter* writer,
                        intptr_t object_id,
                        Snapshot::Kind kind) {
  UNREACHABLE();  // String is an abstract class.
}


template<typename HandleType, typename CharacterType>
RawString* String::ReadFromImpl(SnapshotReader* reader,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  // Read the length so that we can determine instance size to allocate.
  RawSmi* smi_len = GetSmi(reader->Read<intptr_t>());
  intptr_t len = Smi::Value(smi_len);
  RawSmi* smi_hash = GetSmi(reader->Read<intptr_t>());

  // Set up the string object.
  HandleType& str_obj = HandleType::ZoneHandle(HandleType::New(
      len, (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  for (intptr_t i = 0; i < len; i++) {
    *str_obj.CharAddr(i) = reader->Read<CharacterType>();
  }
  reader->AddBackwardReference(object_id, &str_obj);
  str_obj.SetHash(Smi::Value(smi_hash));
  return str_obj.raw();
}


RawOneByteString* OneByteString::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          Snapshot::Kind kind) {
  return static_cast<RawOneByteString*>(
      ReadFromImpl<OneByteString, uint8_t>(reader, object_id, kind));
}


RawTwoByteString* TwoByteString::ReadFrom(SnapshotReader* reader,
                                          intptr_t object_id,
                                          Snapshot::Kind kind) {
  return static_cast<RawTwoByteString*>(
      ReadFromImpl<TwoByteString, uint16_t>(reader, object_id, kind));
}


RawFourByteString* FourByteString::ReadFrom(SnapshotReader* reader,
                                            intptr_t object_id,
                                            Snapshot::Kind kind) {
  return static_cast<RawFourByteString*>(
      ReadFromImpl<FourByteString, uint32_t>(reader, object_id, kind));
}


template<typename T>
static void StringWriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          intptr_t class_id,
                          Snapshot::Kind kind,
                          RawSmi* length,
                          RawSmi* hash,
                          T* data) {
  ASSERT(writer != NULL);
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, class_id);

  // Write out the length field.
  writer->Write<RawObject*>(length);

  // Write out the hash field.
  writer->Write<RawObject*>(hash);

  // Write out the string.
  for (intptr_t i = 0; i < len; i++) {
    writer->Write(data[i]);
  }
}


void RawOneByteString::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  StringWriteTo(writer,
                object_id,
                ObjectStore::kOneByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->data_);
}


void RawTwoByteString::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind) {
  StringWriteTo(writer,
                object_id,
                ObjectStore::kTwoByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->data_);
}


void RawFourByteString::WriteTo(SnapshotWriter* writer,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  StringWriteTo(writer,
                object_id,
                ObjectStore::kFourByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->data_);
}


RawExternalOneByteString* ExternalOneByteString::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    Snapshot::Kind kind) {
  UNREACHABLE();
  return ExternalOneByteString::null();
}


RawExternalTwoByteString* ExternalTwoByteString::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    Snapshot::Kind kind) {
  UNREACHABLE();
  return ExternalTwoByteString::null();
}


RawExternalFourByteString* ExternalFourByteString::ReadFrom(
    SnapshotReader* reader,
    intptr_t object_id,
    Snapshot::Kind kind) {
  UNREACHABLE();
  return ExternalFourByteString::null();
}


void RawExternalOneByteString::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind) {
  // Serialize as a non-external one byte string.
  StringWriteTo(writer,
                object_id,
                ObjectStore::kOneByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->external_data_->data_);
}


void RawExternalTwoByteString::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind) {
  // Serialize as a non-external two byte string.
  StringWriteTo(writer,
                object_id,
                ObjectStore::kTwoByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->external_data_->data_);
}


void RawExternalFourByteString::WriteTo(SnapshotWriter* writer,
                                        intptr_t object_id,
                                        Snapshot::Kind kind) {
  // Serialize as a non-external four byte string.
  StringWriteTo(writer,
                object_id,
                ObjectStore::kFourByteStringClass,
                kind,
                ptr()->length_,
                ptr()->hash_,
                ptr()->external_data_->data_);
}


RawBool* Bool::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  UNREACHABLE();
  return Bool::null();
}


void RawBool::WriteTo(SnapshotWriter* writer,
                      intptr_t object_id,
                      Snapshot::Kind kind) {
  UNREACHABLE();
}


template <class T>
static RawObject* ArrayReadFrom(SnapshotReader* reader,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  RawSmi* smi_len = GetSmi(reader->Read<intptr_t>());
  intptr_t len = Smi::Value(smi_len);
  T& result = T::Handle(
      T::New(len, (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  reader->AddBackwardReference(object_id, &result);

  AbstractTypeArguments& type_arguments = AbstractTypeArguments::Handle();
  type_arguments ^= reader->ReadObject();
  result.SetTypeArguments(type_arguments);

  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < len; i++) {
    obj = reader->ReadObject();
    result.SetAt(i, obj);
  }
  return result.raw();
}


RawArray* Array::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          Snapshot::Kind kind) {
  return reinterpret_cast<RawArray*>(ArrayReadFrom<Array>(reader,
                                                          object_id,
                                                          kind));
}


RawImmutableArray* ImmutableArray::ReadFrom(SnapshotReader* reader,
                                            intptr_t object_id,
                                            Snapshot::Kind kind) {
  return reinterpret_cast<RawImmutableArray*>(
      ArrayReadFrom<ImmutableArray>(reader, object_id, kind));
}


static void ArrayWriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind,
                         intptr_t array_kind,
                         RawSmi* length,
                         RawAbstractTypeArguments* type_arguments,
                         RawObject* data[]) {
  ASSERT(writer != NULL);
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, array_kind);

  // Write out the length field.
  writer->Write<RawObject*>(length);

  // Write out the type arguments.
  writer->WriteObject(type_arguments);

  // Write out the individual objects.
  for (intptr_t i = 0; i < len; i++) {
    writer->WriteObject(data[i]);
  }
}


void RawArray::WriteTo(SnapshotWriter* writer,
                       intptr_t object_id,
                       Snapshot::Kind kind) {
  ArrayWriteTo(writer,
               object_id,
               kind,
               ObjectStore::kArrayClass,
               ptr()->length_,
               ptr()->type_arguments_,
               ptr()->data());
}


void RawImmutableArray::WriteTo(SnapshotWriter* writer,
                                intptr_t object_id,
                                Snapshot::Kind kind) {
  ArrayWriteTo(writer,
               object_id,
               kind,
               ObjectStore::kImmutableArrayClass,
               ptr()->length_,
               ptr()->type_arguments_,
               ptr()->data());
}


RawByteBuffer* ByteBuffer::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
                                    Snapshot::Kind kind) {
  UNIMPLEMENTED();
  return ByteBuffer::null();
}


void RawByteBuffer::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  UNIMPLEMENTED();
}


RawClosure* Closure::ReadFrom(SnapshotReader* reader,
                              intptr_t object_id,
                              Snapshot::Kind kind) {
  UNIMPLEMENTED();
  return Closure::null();
}


void RawClosure::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind) {
  UNIMPLEMENTED();
}


RawStacktrace* Stacktrace::ReadFrom(SnapshotReader* reader,
                                    intptr_t object_id,
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
                                Snapshot::Kind kind) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  RawSmi* smi_len = GetSmi(reader->Read<intptr_t>());
  intptr_t len = Smi::Value(smi_len);

  // Allocate JSRegExp object.
  JSRegExp& regex = JSRegExp::ZoneHandle(
      JSRegExp::New(len, (kind == Snapshot::kFull) ? Heap::kOld : Heap::kNew));
  reader->AddBackwardReference(object_id, &regex);

  // Read and Set all the other fields.
  regex.raw_ptr()->num_bracket_expressions_ = GetSmi(reader->Read<intptr_t>());
  String& pattern = String::Handle();
  pattern ^= reader->ReadObject();
  regex.raw_ptr()->pattern_ = pattern.raw();
  regex.raw_ptr()->type_ = reader->Read<intptr_t>();
  regex.raw_ptr()->flags_ = reader->Read<intptr_t>();

  // TODO(5411462): Need to implement a way of recompiling the regex.

  return regex.raw();
}


void RawJSRegExp::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteObjectHeader(kInlined, object_id);

  // Write out the class information.
  writer->WriteObjectHeader(kObjectId, ObjectStore::kJSRegExpClass);

  // Write out the data length field.
  writer->Write<RawObject*>(ptr()->data_length_);

  // Write out all the other fields.
  writer->Write<RawObject*>(ptr()->num_bracket_expressions_);
  writer->WriteObject(ptr()->pattern_);
  writer->Write<intptr_t>(ptr()->type_);
  writer->Write<intptr_t>(ptr()->flags_);

  // Do not write out the data part which is native.
}

}  // namespace dart
