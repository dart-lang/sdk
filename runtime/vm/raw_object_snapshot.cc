// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dart_api_state.h"
#include "vm/message.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/type_testing_stubs.h"
#include "vm/visitor.h"

namespace dart {

// TODO(dartbug.com/34796): enable or remove this optimization.
DEFINE_FLAG(
    uint64_t,
    externalize_typed_data_threshold,
    kMaxUint64,
    "Convert TypedData to ExternalTypedData when sending through a message"
    " port after it exceeds certain size in bytes.");

#define OFFSET_OF_FROM(obj)                                                    \
  obj.raw()->from() - reinterpret_cast<ObjectPtr*>(obj.raw()->ptr())

// TODO(18854): Need to assert No GC can happen here, even though
// allocations may happen.
#define READ_OBJECT_FIELDS(object, from, to, as_reference)                     \
  intptr_t num_flds = (to) - (from);                                           \
  for (intptr_t i = 0; i <= num_flds; i++) {                                   \
    (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(as_reference);   \
    object.StorePointer(((from) + i), reader->PassiveObjectHandle()->raw());   \
  }

ClassPtr Class::ReadFrom(SnapshotReader* reader,
                         intptr_t object_id,
                         intptr_t tags,
                         Snapshot::Kind kind,
                         bool as_reference) {
  ASSERT(reader != NULL);

  Class& cls = Class::ZoneHandle(reader->zone(), Class::null());
  cls = reader->ReadClassId(object_id);
  return cls.raw();
}

void ClassLayout::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind,
                          bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kClassCid);
  writer->WriteTags(writer->GetObjectTags(this));

  if (writer->can_send_any_object() ||
      writer->AllowObjectsInDartLibrary(library())) {
    writer->WriteClassId(this);
  } else {
    // We do not allow regular dart instances in isolate messages.
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (object is a regular Dart Instance)");
  }
}

TypePtr Type::ReadFrom(SnapshotReader* reader,
                       intptr_t object_id,
                       intptr_t tags,
                       Snapshot::Kind kind,
                       bool as_reference) {
  ASSERT(reader != NULL);

  // Determine if the type class of this type is in the full snapshot.
  reader->Read<bool>();

  // Allocate type object.
  Type& type = Type::ZoneHandle(reader->zone(), Type::New());
  bool is_canonical = ObjectLayout::IsCanonical(tags);
  reader->AddBackRef(object_id, &type, kIsDeserialized);

  // Set all non object fields.
  type.set_token_pos(TokenPosition::Deserialize(reader->Read<int32_t>()));
  const uint8_t combined = reader->Read<uint8_t>();
  type.set_type_state(combined >> 4);
  type.set_nullability(static_cast<Nullability>(combined & 0xf));

  // Read the code object for the type testing stub and set its entrypoint.
  reader->EnqueueTypePostprocessing(type);

  // Set all the object fields.
  READ_OBJECT_FIELDS(type, type.raw()->ptr()->from(), type.raw()->ptr()->to(),
                     as_reference);

  // Read in the type class.
  (*reader->ClassHandle()) =
      Class::RawCast(reader->ReadObjectImpl(as_reference));
  type.set_type_class(*reader->ClassHandle());

  // Fill in the type testing stub.
  Code& code = *reader->CodeHandle();
  code = TypeTestingStubGenerator::DefaultCodeForType(type);
  type.SetTypeTestingStub(code);

  if (is_canonical) {
    type ^= type.Canonicalize(Thread::Current(), nullptr);
  }

  return type.raw();
}

void TypeLayout::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind,
                         bool as_reference) {
  ASSERT(writer != NULL);

  if (signature() != Function::null()) {
    writer->SetWriteException(Exceptions::kArgument,
                              "Illegal argument in isolate message"
                              " : (function types are not supported yet)");
    UNREACHABLE();
  }

  // Only resolved and finalized types should be written to a snapshot.
  ASSERT((type_state_ == TypeLayout::kFinalizedInstantiated) ||
         (type_state_ == TypeLayout::kFinalizedUninstantiated));
  ASSERT(type_class_id() != Object::null());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeCid);
  writer->WriteTags(writer->GetObjectTags(this));

  if (type_class_id()->IsHeapObject()) {
    // Type class is still an unresolved class.
    UNREACHABLE();
  }

  // Lookup the type class.
  SmiPtr raw_type_class_id = Smi::RawCast(type_class_id());
  ClassPtr type_class =
      writer->isolate()->class_table()->At(Smi::Value(raw_type_class_id));

  // Write out typeclass_is_in_fullsnapshot first as this will
  // help the reader decide on how to canonicalize the type object.
  intptr_t tags = writer->GetObjectTags(type_class);
  bool typeclass_is_in_fullsnapshot =
      (ClassIdTag::decode(tags) == kClassCid) &&
      Class::IsInFullSnapshot(static_cast<ClassPtr>(type_class));
  writer->Write<bool>(typeclass_is_in_fullsnapshot);

  // Write out all the non object pointer fields.
  writer->Write<int32_t>(token_pos_.Serialize());
  const uint8_t combined = (type_state_ << 4) | nullability_;
  ASSERT(type_state_ == (combined >> 4));
  ASSERT(nullability_ == (combined & 0xf));
  writer->Write<uint8_t>(combined);

  // Write out all the object pointer fields.
  ASSERT(type_class_id() != Object::null());
  SnapshotWriterVisitor visitor(writer, as_reference);
  visitor.VisitPointers(from(), to());

  // Write out the type class.
  writer->WriteObjectImpl(type_class, as_reference);
}

TypeRefPtr TypeRef::ReadFrom(SnapshotReader* reader,
                             intptr_t object_id,
                             intptr_t tags,
                             Snapshot::Kind kind,
                             bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate type ref object.
  TypeRef& type_ref = TypeRef::ZoneHandle(reader->zone(), TypeRef::New());
  reader->AddBackRef(object_id, &type_ref, kIsDeserialized);

  // Read the code object for the type testing stub and set its entrypoint.
  reader->EnqueueTypePostprocessing(type_ref);

  // Set all the object fields.
  READ_OBJECT_FIELDS(type_ref, type_ref.raw()->ptr()->from(),
                     type_ref.raw()->ptr()->to(), kAsReference);

  // Fill in the type testing stub.
  Code& code = *reader->CodeHandle();
  code = TypeTestingStubGenerator::DefaultCodeForType(type_ref);
  type_ref.SetTypeTestingStub(code);

  return type_ref.raw();
}

void TypeRefLayout::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind,
                            bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeRefCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());
}

TypeParameterPtr TypeParameter::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate type parameter object.
  TypeParameter& type_parameter =
      TypeParameter::ZoneHandle(reader->zone(), TypeParameter::New());
  bool is_canonical = ObjectLayout::IsCanonical(tags);
  reader->AddBackRef(object_id, &type_parameter, kIsDeserialized);

  // Set all non object fields.
  type_parameter.set_token_pos(
      TokenPosition::Deserialize(reader->Read<int32_t>()));
  type_parameter.set_index(reader->Read<int16_t>());
  const uint8_t combined = reader->Read<uint8_t>();
  type_parameter.set_flags(combined >> 4);
  type_parameter.set_nullability(static_cast<Nullability>(combined & 0xf));

  // Read the code object for the type testing stub and set its entrypoint.
  reader->EnqueueTypePostprocessing(type_parameter);

  // Set all the object fields.
  READ_OBJECT_FIELDS(type_parameter, type_parameter.raw()->ptr()->from(),
                     type_parameter.raw()->ptr()->to(), kAsReference);

  if (type_parameter.parameterized_function() == Function::null()) {
    // Read in the parameterized class.
    (*reader->ClassHandle()) =
        Class::RawCast(reader->ReadObjectImpl(kAsReference));
  } else {
    (*reader->ClassHandle()) = Class::null();
  }
  type_parameter.set_parameterized_class(*reader->ClassHandle());

  // Fill in the type testing stub.
  Code& code = *reader->CodeHandle();
  code = TypeTestingStubGenerator::DefaultCodeForType(type_parameter);
  type_parameter.SetTypeTestingStub(code);

  if (is_canonical) {
    type_parameter ^= type_parameter.Canonicalize(Thread::Current(), nullptr);
  }

  return type_parameter.raw();
}

void TypeParameterLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  ASSERT(writer != NULL);

  // Only finalized type parameters should be written to a snapshot.
  ASSERT(FinalizedBit::decode(flags_));

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kTypeParameterCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object pointer fields.
  writer->Write<int32_t>(token_pos_.Serialize());
  writer->Write<int16_t>(index_);
  const uint8_t combined = (flags_ << 4) | nullability_;
  ASSERT(flags_ == (combined >> 4));
  ASSERT(nullability_ == (combined & 0xf));
  writer->Write<uint8_t>(combined);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());

  if (parameterized_class_id_ != kFunctionCid) {
    ASSERT(parameterized_function() == Function::null());
    // Write out the parameterized class.
    ClassPtr param_class =
        writer->isolate()->class_table()->At(parameterized_class_id_);
    writer->WriteObjectImpl(param_class, kAsReference);
  } else {
    ASSERT(parameterized_function() != Function::null());
  }
}

TypeArgumentsPtr TypeArguments::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();

  TypeArguments& type_arguments =
      TypeArguments::ZoneHandle(reader->zone(), TypeArguments::New(len));
  bool is_canonical = ObjectLayout::IsCanonical(tags);
  reader->AddBackRef(object_id, &type_arguments, kIsDeserialized);

  // Set the instantiations field, which is only read from a full snapshot.
  type_arguments.set_instantiations(Object::zero_array());

  // Now set all the type fields.
  for (intptr_t i = 0; i < len; i++) {
    *reader->TypeHandle() ^= reader->ReadObjectImpl(as_reference);
    type_arguments.SetTypeAt(i, *reader->TypeHandle());
  }

  // Set the canonical bit.
  if (is_canonical) {
    type_arguments = type_arguments.Canonicalize(Thread::Current(), nullptr);
  }

  return type_arguments.raw();
}

void TypeArgumentsLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kTypeArgumentsCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the length field.
  writer->Write<ObjectPtr>(length());

  // Write out the individual types.
  intptr_t len = Smi::Value(length());
  for (intptr_t i = 0; i < len; i++) {
    // The Dart VM reuses type argument lists across instances in order
    // to reduce memory footprint, this can sometimes lead to a type from
    // such a shared type argument list being sent over to another isolate.
    // In such scenarios where it is not appropriate to send the types
    // across (isolates spawned using spawnURI) we send them as dynamic.
    if (!writer->can_send_any_object()) {
      // Lookup the type class.
      TypePtr raw_type = Type::RawCast(types()[i]);
      SmiPtr raw_type_class_id = Smi::RawCast(raw_type->ptr()->type_class_id());
      ClassPtr type_class =
          writer->isolate()->class_table()->At(Smi::Value(raw_type_class_id));
      if (!writer->AllowObjectsInDartLibrary(type_class->ptr()->library())) {
        writer->WriteVMIsolateObject(kDynamicType);
      } else {
        writer->WriteObjectImpl(types()[i], as_reference);
      }
    } else {
      writer->WriteObjectImpl(types()[i], as_reference);
    }
  }
}

ClosurePtr Closure::ReadFrom(SnapshotReader* reader,
                             intptr_t object_id,
                             intptr_t tags,
                             Snapshot::Kind kind,
                             bool as_reference) {
  UNREACHABLE();
  return Closure::null();
}

void ClosureLayout::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind,
                            bool as_reference) {
  ASSERT(writer != NULL);
  ASSERT(kind == Snapshot::kMessage);

  // Check if closure is serializable, throw an exception otherwise.
  FunctionPtr func = writer->IsSerializableClosure(ClosurePtr(this));
  if (func != Function::null()) {
    writer->WriteStaticImplicitClosure(
        object_id, func, writer->GetObjectTags(this), delayed_type_arguments());
    return;
  }

  UNREACHABLE();
}

ContextPtr Context::ReadFrom(SnapshotReader* reader,
                             intptr_t object_id,
                             intptr_t tags,
                             Snapshot::Kind kind,
                             bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate context object.
  int32_t num_vars = reader->Read<int32_t>();
  Context& context = Context::ZoneHandle(reader->zone());
  reader->AddBackRef(object_id, &context, kIsDeserialized);
  if (num_vars != 0) {
    context = Context::New(num_vars);

    // Set all the object fields.
    // TODO(5411462): Need to assert No GC can happen here, even though
    // allocations may happen.
    intptr_t num_flds =
        (context.raw()->ptr()->to(num_vars) - context.raw()->ptr()->from());
    for (intptr_t i = 0; i <= num_flds; i++) {
      (*reader->PassiveObjectHandle()) = reader->ReadObjectImpl(kAsReference);
      context.StorePointer((context.raw()->ptr()->from() + i),
                           reader->PassiveObjectHandle()->raw());
    }
  }
  return context.raw();
}

void ContextLayout::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind,
                            bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kContextCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out num of variables in the context.
  const int32_t num_variables = num_variables_;
  writer->Write<int32_t>(num_variables);
  if (num_variables != 0) {
    // Write out all the object pointer fields.
    SnapshotWriterVisitor visitor(writer, kAsReference);
    visitor.VisitPointers(from(), to(num_variables));
  }
}

ContextScopePtr ContextScope::ReadFrom(SnapshotReader* reader,
                                       intptr_t object_id,
                                       intptr_t tags,
                                       Snapshot::Kind kind,
                                       bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate context object.
  bool is_implicit = reader->Read<bool>();
  if (is_implicit) {
    ContextScope& context_scope = ContextScope::ZoneHandle(reader->zone());
    context_scope = ContextScope::New(1, true);
    reader->AddBackRef(object_id, &context_scope, kIsDeserialized);

    *reader->TypeHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);

    // Create a descriptor for 'this' variable.
    context_scope.SetTokenIndexAt(0, TokenPosition::kMinSource);
    context_scope.SetDeclarationTokenIndexAt(0, TokenPosition::kMinSource);
    context_scope.SetNameAt(0, Symbols::This());
    context_scope.SetIsFinalAt(0, true);
    context_scope.SetIsConstAt(0, false);
    context_scope.SetTypeAt(0, *reader->TypeHandle());
    context_scope.SetContextIndexAt(0, 0);
    context_scope.SetContextLevelAt(0, 0);
    return context_scope.raw();
  }
  UNREACHABLE();
  return NULL;
}

void ContextScopeLayout::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind,
                                 bool as_reference) {
  ASSERT(writer != NULL);

  if (is_implicit_) {
    ASSERT(num_variables_ == 1);
    const VariableDesc* var = VariableDescAddr(0);

    // Write out the serialization header value for this object.
    writer->WriteInlinedObjectHeader(object_id);

    // Write out the class and tags information.
    writer->WriteVMIsolateObject(kContextScopeCid);
    writer->WriteTags(writer->GetObjectTags(this));

    // Write out is_implicit flag for the context scope.
    writer->Write<bool>(true);

    // Write out the type of 'this' the variable.
    writer->WriteObjectImpl(var->type, kAsInlinedObject);

    return;
  }
  UNREACHABLE();
}

#define MESSAGE_SNAPSHOT_UNREACHABLE(type)                                     \
  type##Ptr type::ReadFrom(SnapshotReader* reader, intptr_t object_id,         \
                           intptr_t tags, Snapshot::Kind kind,                 \
                           bool as_reference) {                                \
    UNREACHABLE();                                                             \
    return type::null();                                                       \
  }                                                                            \
  void type##Layout::WriteTo(SnapshotWriter* writer, intptr_t object_id,       \
                             Snapshot::Kind kind, bool as_reference) {         \
    UNREACHABLE();                                                             \
  }

#define MESSAGE_SNAPSHOT_ILLEGAL(type)                                         \
  type##Ptr type::ReadFrom(SnapshotReader* reader, intptr_t object_id,         \
                           intptr_t tags, Snapshot::Kind kind,                 \
                           bool as_reference) {                                \
    UNREACHABLE();                                                             \
    return type::null();                                                       \
  }                                                                            \
  void type##Layout::WriteTo(SnapshotWriter* writer, intptr_t object_id,       \
                             Snapshot::Kind kind, bool as_reference) {         \
    writer->SetWriteException(Exceptions::kArgument,                           \
                              "Illegal argument in isolate message"            \
                              " : (object is a " #type ")");                   \
  }

MESSAGE_SNAPSHOT_UNREACHABLE(AbstractType);
MESSAGE_SNAPSHOT_UNREACHABLE(Bool);
MESSAGE_SNAPSHOT_UNREACHABLE(ClosureData);
MESSAGE_SNAPSHOT_UNREACHABLE(Code);
MESSAGE_SNAPSHOT_UNREACHABLE(CodeSourceMap);
MESSAGE_SNAPSHOT_UNREACHABLE(CompressedStackMaps);
MESSAGE_SNAPSHOT_UNREACHABLE(Error);
MESSAGE_SNAPSHOT_UNREACHABLE(ExceptionHandlers);
MESSAGE_SNAPSHOT_UNREACHABLE(FfiTrampolineData);
MESSAGE_SNAPSHOT_UNREACHABLE(Field);
MESSAGE_SNAPSHOT_UNREACHABLE(Function);
MESSAGE_SNAPSHOT_UNREACHABLE(CallSiteData);
MESSAGE_SNAPSHOT_UNREACHABLE(ICData);
MESSAGE_SNAPSHOT_UNREACHABLE(Instructions);
MESSAGE_SNAPSHOT_UNREACHABLE(InstructionsSection);
MESSAGE_SNAPSHOT_UNREACHABLE(KernelProgramInfo);
MESSAGE_SNAPSHOT_UNREACHABLE(Library);
MESSAGE_SNAPSHOT_UNREACHABLE(LibraryPrefix);
MESSAGE_SNAPSHOT_UNREACHABLE(LocalVarDescriptors);
MESSAGE_SNAPSHOT_UNREACHABLE(MegamorphicCache);
MESSAGE_SNAPSHOT_UNREACHABLE(Namespace);
MESSAGE_SNAPSHOT_UNREACHABLE(ObjectPool);
MESSAGE_SNAPSHOT_UNREACHABLE(PatchClass);
MESSAGE_SNAPSHOT_UNREACHABLE(PcDescriptors);
MESSAGE_SNAPSHOT_UNREACHABLE(Script);
MESSAGE_SNAPSHOT_UNREACHABLE(SignatureData);
MESSAGE_SNAPSHOT_UNREACHABLE(SingleTargetCache);
MESSAGE_SNAPSHOT_UNREACHABLE(String);
MESSAGE_SNAPSHOT_UNREACHABLE(SubtypeTestCache);
MESSAGE_SNAPSHOT_UNREACHABLE(LoadingUnit);
MESSAGE_SNAPSHOT_UNREACHABLE(TypedDataBase);
MESSAGE_SNAPSHOT_UNREACHABLE(UnlinkedCall);
MESSAGE_SNAPSHOT_UNREACHABLE(MonomorphicSmiableCall);
MESSAGE_SNAPSHOT_UNREACHABLE(UnwindError);
MESSAGE_SNAPSHOT_UNREACHABLE(FutureOr);
MESSAGE_SNAPSHOT_UNREACHABLE(WeakSerializationReference);

MESSAGE_SNAPSHOT_ILLEGAL(DynamicLibrary);
MESSAGE_SNAPSHOT_ILLEGAL(MirrorReference);
MESSAGE_SNAPSHOT_ILLEGAL(Pointer);
MESSAGE_SNAPSHOT_ILLEGAL(ReceivePort);
MESSAGE_SNAPSHOT_ILLEGAL(StackTrace);
MESSAGE_SNAPSHOT_ILLEGAL(UserTag);

ApiErrorPtr ApiError::ReadFrom(SnapshotReader* reader,
                               intptr_t object_id,
                               intptr_t tags,
                               Snapshot::Kind kind,
                               bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate ApiError object.
  ApiError& api_error = ApiError::ZoneHandle(reader->zone(), ApiError::New());
  reader->AddBackRef(object_id, &api_error, kIsDeserialized);

  // Set all the object fields.
  READ_OBJECT_FIELDS(api_error, api_error.raw()->ptr()->from(),
                     api_error.raw()->ptr()->to(), kAsReference);

  return api_error.raw();
}

void ApiErrorLayout::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind,
                             bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kApiErrorCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());
}

LanguageErrorPtr LanguageError::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate LanguageError object.
  LanguageError& language_error =
      LanguageError::ZoneHandle(reader->zone(), LanguageError::New());
  reader->AddBackRef(object_id, &language_error, kIsDeserialized);

  // Set all non object fields.
  language_error.set_token_pos(
      TokenPosition::Deserialize(reader->Read<int32_t>()));
  language_error.set_report_after_token(reader->Read<bool>());
  language_error.set_kind(reader->Read<uint8_t>());

  // Set all the object fields.
  READ_OBJECT_FIELDS(language_error, language_error.raw()->ptr()->from(),
                     language_error.raw()->ptr()->to(), kAsReference);

  return language_error.raw();
}

void LanguageErrorLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kLanguageErrorCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the non object fields.
  writer->Write<int32_t>(token_pos_.Serialize());
  writer->Write<bool>(report_after_token_);
  writer->Write<uint8_t>(kind_);

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());
}

UnhandledExceptionPtr UnhandledException::ReadFrom(SnapshotReader* reader,
                                                   intptr_t object_id,
                                                   intptr_t tags,
                                                   Snapshot::Kind kind,
                                                   bool as_reference) {
  UnhandledException& result =
      UnhandledException::ZoneHandle(reader->zone(), UnhandledException::New());
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  // Set all the object fields.
  READ_OBJECT_FIELDS(result, result.raw()->ptr()->from(),
                     result.raw()->ptr()->to(), kAsReference);

  return result.raw();
}

void UnhandledExceptionLayout::WriteTo(SnapshotWriter* writer,
                                       intptr_t object_id,
                                       Snapshot::Kind kind,
                                       bool as_reference) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteVMIsolateObject(kUnhandledExceptionCid);
  writer->WriteTags(writer->GetObjectTags(this));
  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());
}

InstancePtr Instance::ReadFrom(SnapshotReader* reader,
                               intptr_t object_id,
                               intptr_t tags,
                               Snapshot::Kind kind,
                               bool as_reference) {
  ASSERT(reader != NULL);

  // Create an Instance object or get canonical one if it is a canonical
  // constant.
  Instance& obj = Instance::ZoneHandle(reader->zone(), Instance::null());
  obj ^= Object::Allocate(kInstanceCid, Instance::InstanceSize(), Heap::kNew);
  if (ObjectLayout::IsCanonical(tags)) {
    obj = obj.Canonicalize(reader->thread());
  }
  reader->AddBackRef(object_id, &obj, kIsDeserialized);

  return obj.raw();
}

void InstanceLayout::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind,
                             bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kInstanceCid);
  writer->WriteTags(writer->GetObjectTags(this));
}

IntegerPtr Mint::ReadFrom(SnapshotReader* reader,
                          intptr_t object_id,
                          intptr_t tags,
                          Snapshot::Kind kind,
                          bool as_reference) {
  ASSERT(reader != NULL);

  // Read the 64 bit value for the object.
  int64_t value = reader->Read<int64_t>();

  // Check if the value could potentially fit in a Smi in our current
  // architecture, if so return the object as a Smi.
  if (Smi::IsValid(value)) {
    Smi& smi =
        Smi::ZoneHandle(reader->zone(), Smi::New(static_cast<intptr_t>(value)));
    reader->AddBackRef(object_id, &smi, kIsDeserialized);
    return smi.raw();
  }

  // Create a Mint object or get canonical one if it is a canonical constant.
  Mint& mint = Mint::ZoneHandle(reader->zone(), Mint::null());
  // When reading a script snapshot we need to canonicalize only those object
  // references that are objects from the core library (loaded from a
  // full snapshot). Objects that are only in the script need not be
  // canonicalized as they are already canonical.
  // When reading a message snapshot we always have to canonicalize.
  if (ObjectLayout::IsCanonical(tags)) {
    mint = Mint::NewCanonical(value);
    ASSERT(mint.IsCanonical());
  } else {
    mint = Mint::New(value);
  }
  reader->AddBackRef(object_id, &mint, kIsDeserialized);
  return mint.raw();
}

void MintLayout::WriteTo(SnapshotWriter* writer,
                         intptr_t object_id,
                         Snapshot::Kind kind,
                         bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kMintCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the 64 bit value.
  writer->Write<int64_t>(value_);
}

DoublePtr Double::ReadFrom(SnapshotReader* reader,
                           intptr_t object_id,
                           intptr_t tags,
                           Snapshot::Kind kind,
                           bool as_reference) {
  ASSERT(reader != NULL);
  ASSERT(kind != Snapshot::kMessage);
  // Read the double value for the object.
  double value = reader->ReadDouble();

  // Create a Double object or get canonical one if it is a canonical constant.
  Double& dbl = Double::ZoneHandle(reader->zone(), Double::null());
  // When reading a script snapshot we need to canonicalize only those object
  // references that are objects from the core library (loaded from a
  // full snapshot). Objects that are only in the script need not be
  // canonicalized as they are already canonical.
  if (ObjectLayout::IsCanonical(tags)) {
    dbl = Double::NewCanonical(value);
    ASSERT(dbl.IsCanonical());
  } else {
    dbl = Double::New(value);
  }
  reader->AddBackRef(object_id, &dbl, kIsDeserialized);
  return dbl.raw();
}

void DoubleLayout::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind,
                           bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kDoubleCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the double value.
  writer->WriteDouble(value_);
}

template <typename StringType, typename CharacterType, typename CallbackType>
void String::ReadFromImpl(SnapshotReader* reader,
                          String* str_obj,
                          intptr_t len,
                          intptr_t tags,
                          CallbackType new_symbol,
                          Snapshot::Kind kind) {
  ASSERT(reader != NULL);
  if (ObjectLayout::IsCanonical(tags)) {
    // Set up canonical string object.
    ASSERT(reader != NULL);
    CharacterType* ptr = reader->zone()->Alloc<CharacterType>(len);
    for (intptr_t i = 0; i < len; i++) {
      ptr[i] = reader->Read<CharacterType>();
    }
    *str_obj = (*new_symbol)(reader->thread(), ptr, len);
  } else {
    // Set up the string object.
    *str_obj = StringType::New(len, Heap::kNew);
    str_obj->SetHash(0);  // Will get computed when needed.
    if (len == 0) {
      return;
    }
    NoSafepointScope no_safepoint;
    CharacterType* str_addr = StringType::DataStart(*str_obj);
    for (intptr_t i = 0; i < len; i++) {
      *str_addr = reader->Read<CharacterType>();
      str_addr++;
    }
  }
}

OneByteStringPtr OneByteString::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  // Read the length so that we can determine instance size to allocate.
  ASSERT(reader != NULL);
  intptr_t len = reader->ReadSmiValue();
  String& str_obj = String::ZoneHandle(reader->zone(), String::null());

  String::ReadFromImpl<OneByteString, uint8_t>(reader, &str_obj, len, tags,
                                               Symbols::FromLatin1, kind);
  reader->AddBackRef(object_id, &str_obj, kIsDeserialized);
  return raw(str_obj);
}

TwoByteStringPtr TwoByteString::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  // Read the length so that we can determine instance size to allocate.
  ASSERT(reader != NULL);
  intptr_t len = reader->ReadSmiValue();
  String& str_obj = String::ZoneHandle(reader->zone(), String::null());

  String::ReadFromImpl<TwoByteString, uint16_t>(reader, &str_obj, len, tags,
                                                Symbols::FromUTF16, kind);
  reader->AddBackRef(object_id, &str_obj, kIsDeserialized);
  return raw(str_obj);
}

template <typename T>
static void StringWriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind,
                          intptr_t class_id,
                          intptr_t tags,
                          SmiPtr length,
                          T* data) {
  ASSERT(writer != NULL);
  intptr_t len = Smi::Value(length);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(class_id);
  writer->WriteTags(tags);

  // Write out the length field.
  writer->Write<ObjectPtr>(length);

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

void OneByteStringLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  StringWriteTo(writer, object_id, kind, kOneByteStringCid,
                writer->GetObjectTags(this), length(), data());
}

void TwoByteStringLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  StringWriteTo(writer, object_id, kind, kTwoByteStringCid,
                writer->GetObjectTags(this), length(), data());
}

ExternalOneByteStringPtr ExternalOneByteString::ReadFrom(SnapshotReader* reader,
                                                         intptr_t object_id,
                                                         intptr_t tags,
                                                         Snapshot::Kind kind,
                                                         bool as_reference) {
  UNREACHABLE();
  return ExternalOneByteString::null();
}

ExternalTwoByteStringPtr ExternalTwoByteString::ReadFrom(SnapshotReader* reader,
                                                         intptr_t object_id,
                                                         intptr_t tags,
                                                         Snapshot::Kind kind,
                                                         bool as_reference) {
  UNREACHABLE();
  return ExternalTwoByteString::null();
}

void ExternalOneByteStringLayout::WriteTo(SnapshotWriter* writer,
                                          intptr_t object_id,
                                          Snapshot::Kind kind,
                                          bool as_reference) {
  // Serialize as a non-external one byte string.
  StringWriteTo(writer, object_id, kind, kOneByteStringCid,
                writer->GetObjectTags(this), length(), external_data_);
}

void ExternalTwoByteStringLayout::WriteTo(SnapshotWriter* writer,
                                          intptr_t object_id,
                                          Snapshot::Kind kind,
                                          bool as_reference) {
  // Serialize as a non-external two byte string.
  StringWriteTo(writer, object_id, kind, kTwoByteStringCid,
                writer->GetObjectTags(this), length(), external_data_);
}

ArrayPtr Array::ReadFrom(SnapshotReader* reader,
                         intptr_t object_id,
                         intptr_t tags,
                         Snapshot::Kind kind,
                         bool as_reference) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();
  Array* array = NULL;
  DeserializeState state;
  if (!as_reference) {
    array = reinterpret_cast<Array*>(reader->GetBackRef(object_id));
    state = kIsDeserialized;
  } else {
    state = kIsNotDeserialized;
  }
  if (array == NULL) {
    array = &(Array::ZoneHandle(reader->zone(), Array::New(len)));
    reader->AddBackRef(object_id, array, state);
  }
  if (!as_reference) {
    // Read all the individual elements for inlined objects.
    ASSERT(!ObjectLayout::IsCanonical(tags));
    reader->ArrayReadFrom(object_id, *array, len, tags);
  }
  return array->raw();
}

ImmutableArrayPtr ImmutableArray::ReadFrom(SnapshotReader* reader,
                                           intptr_t object_id,
                                           intptr_t tags,
                                           Snapshot::Kind kind,
                                           bool as_reference) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  intptr_t len = reader->ReadSmiValue();
  Array* array = NULL;
  DeserializeState state;
  if (!as_reference) {
    array = reinterpret_cast<Array*>(reader->GetBackRef(object_id));
    state = kIsDeserialized;
  } else {
    state = kIsNotDeserialized;
  }
  if (array == NULL) {
    array = &(Array::ZoneHandle(reader->zone(), ImmutableArray::New(len)));
    reader->AddBackRef(object_id, array, state);
  }
  if (!as_reference) {
    // Read all the individual elements for inlined objects.
    reader->ArrayReadFrom(object_id, *array, len, tags);
    if (ObjectLayout::IsCanonical(tags)) {
      *array ^= array->Canonicalize(reader->thread());
    }
  }
  return raw(*array);
}

void ArrayLayout::WriteTo(SnapshotWriter* writer,
                          intptr_t object_id,
                          Snapshot::Kind kind,
                          bool as_reference) {
  ASSERT(!this->IsCanonical());
  writer->ArrayWriteTo(object_id, kArrayCid, writer->GetObjectTags(this),
                       length(), type_arguments(), data(), as_reference);
}

void ImmutableArrayLayout::WriteTo(SnapshotWriter* writer,
                                   intptr_t object_id,
                                   Snapshot::Kind kind,
                                   bool as_reference) {
  writer->ArrayWriteTo(object_id, kImmutableArrayCid,
                       writer->GetObjectTags(this), length_, type_arguments_,
                       data(), as_reference);
}

GrowableObjectArrayPtr GrowableObjectArray::ReadFrom(SnapshotReader* reader,
                                                     intptr_t object_id,
                                                     intptr_t tags,
                                                     Snapshot::Kind kind,
                                                     bool as_reference) {
  ASSERT(reader != NULL);

  // Read the length so that we can determine instance size to allocate.
  GrowableObjectArray& array = GrowableObjectArray::ZoneHandle(
      reader->zone(), GrowableObjectArray::null());
  array = GrowableObjectArray::New(0);
  reader->AddBackRef(object_id, &array, kIsDeserialized);

  // Read type arguments of growable array object.
  *reader->TypeArgumentsHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
  array.StorePointer(&array.raw_ptr()->type_arguments_,
                     reader->TypeArgumentsHandle()->raw());

  // Read length of growable array object.
  array.SetLength(reader->ReadSmiValue());

  // Read the backing array of growable array object.
  *(reader->ArrayHandle()) ^= reader->ReadObjectImpl(kAsReference);
  array.SetData(*(reader->ArrayHandle()));

  return array.raw();
}

void GrowableObjectArrayLayout::WriteTo(SnapshotWriter* writer,
                                        intptr_t object_id,
                                        Snapshot::Kind kind,
                                        bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kGrowableObjectArrayCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the type arguments field.
  writer->WriteObjectImpl(type_arguments_, kAsInlinedObject);

  // Write out the used length field.
  writer->Write<ObjectPtr>(length_);

  // Write out the Array object.
  writer->WriteObjectImpl(data_, kAsReference);
}

LinkedHashMapPtr LinkedHashMap::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  ASSERT(reader != NULL);

  LinkedHashMap& map =
      LinkedHashMap::ZoneHandle(reader->zone(), LinkedHashMap::null());
  // Since the map might contain itself as a key or value, allocate first.
  map = LinkedHashMap::NewUninitialized();
  reader->AddBackRef(object_id, &map, kIsDeserialized);

  // Read the type arguments.
  *reader->TypeArgumentsHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
  map.SetTypeArguments(*reader->TypeArgumentsHandle());

  // Read the number of key/value pairs.
  intptr_t len = reader->ReadSmiValue();
  intptr_t used_data = (len << 1);
  map.SetUsedData(used_data);

  // Allocate the data array.
  intptr_t data_size =
      Utils::Maximum(Utils::RoundUpToPowerOfTwo(used_data),
                     static_cast<uintptr_t>(LinkedHashMap::kInitialIndexSize));
  Array& data = Array::ZoneHandle(reader->zone(), Array::New(data_size));
  map.SetData(data);
  map.SetDeletedKeys(0);

  // The index and hashMask is regenerated by the maps themselves on demand.
  // Thus, the index will probably be allocated in new space (unless it's huge).
  // TODO(koda): Eagerly rehash here when no keys have user-defined '==', and
  // in particular, if/when (const) maps are needed in the VM isolate snapshot.
  ASSERT(reader->isolate() != Dart::vm_isolate());
  map.SetHashMask(0);  // Prefer sentinel 0 over null for better type feedback.

  reader->EnqueueRehashingOfMap(map);

  // Read the keys and values.
  bool read_as_reference = ObjectLayout::IsCanonical(tags) ? false : true;
  for (intptr_t i = 0; i < used_data; i++) {
    *reader->PassiveObjectHandle() = reader->ReadObjectImpl(read_as_reference);
    data.SetAt(i, *reader->PassiveObjectHandle());
  }
  return map.raw();
}

void LinkedHashMapLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kLinkedHashMapCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the type arguments.
  writer->WriteObjectImpl(type_arguments_, kAsInlinedObject);

  const intptr_t used_data = Smi::Value(used_data_);
  ASSERT((used_data & 1) == 0);  // Keys + values, so must be even.
  const intptr_t deleted_keys = Smi::Value(deleted_keys_);

  // Write out the number of (not deleted) key/value pairs that will follow.
  writer->Write<ObjectPtr>(Smi::New((used_data >> 1) - deleted_keys));

  // Write out the keys and values.
  const bool write_as_reference = this->IsCanonical() ? false : true;
  ArrayPtr data_array = data_;
  ObjectPtr* data_elements = data_array->ptr()->data();
  ASSERT(used_data <= Smi::Value(data_array->ptr()->length_));
#if defined(DEBUG)
  intptr_t deleted_keys_found = 0;
#endif  // DEBUG
  for (intptr_t i = 0; i < used_data; i += 2) {
    ObjectPtr key = data_elements[i];
    if (key == data_array) {
#if defined(DEBUG)
      ++deleted_keys_found;
#endif  // DEBUG
      continue;
    }
    ObjectPtr value = data_elements[i + 1];
    writer->WriteObjectImpl(key, write_as_reference);
    writer->WriteObjectImpl(value, write_as_reference);
  }
  DEBUG_ASSERT(deleted_keys_found == deleted_keys);
}

Float32x4Ptr Float32x4::ReadFrom(SnapshotReader* reader,
                                 intptr_t object_id,
                                 intptr_t tags,
                                 Snapshot::Kind kind,
                                 bool as_reference) {
  ASSERT(reader != NULL);
  // Read the values.
  float value0 = reader->Read<float>();
  float value1 = reader->Read<float>();
  float value2 = reader->Read<float>();
  float value3 = reader->Read<float>();

  // Create a Float32x4 object.
  Float32x4& simd = Float32x4::ZoneHandle(reader->zone(), Float32x4::null());
  simd = Float32x4::New(value0, value1, value2, value3);
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}

void Float32x4Layout::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind,
                              bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kFloat32x4Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the float values.
  writer->Write<float>(value_[0]);
  writer->Write<float>(value_[1]);
  writer->Write<float>(value_[2]);
  writer->Write<float>(value_[3]);
}

Int32x4Ptr Int32x4::ReadFrom(SnapshotReader* reader,
                             intptr_t object_id,
                             intptr_t tags,
                             Snapshot::Kind kind,
                             bool as_reference) {
  ASSERT(reader != NULL);
  // Read the values.
  uint32_t value0 = reader->Read<uint32_t>();
  uint32_t value1 = reader->Read<uint32_t>();
  uint32_t value2 = reader->Read<uint32_t>();
  uint32_t value3 = reader->Read<uint32_t>();

  // Create a Float32x4 object.
  Int32x4& simd = Int32x4::ZoneHandle(reader->zone(), Int32x4::null());
  simd = Int32x4::New(value0, value1, value2, value3);
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}

void Int32x4Layout::WriteTo(SnapshotWriter* writer,
                            intptr_t object_id,
                            Snapshot::Kind kind,
                            bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kInt32x4Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the mask values.
  writer->Write<uint32_t>(value_[0]);
  writer->Write<uint32_t>(value_[1]);
  writer->Write<uint32_t>(value_[2]);
  writer->Write<uint32_t>(value_[3]);
}

Float64x2Ptr Float64x2::ReadFrom(SnapshotReader* reader,
                                 intptr_t object_id,
                                 intptr_t tags,
                                 Snapshot::Kind kind,
                                 bool as_reference) {
  ASSERT(reader != NULL);
  // Read the values.
  double value0 = reader->Read<double>();
  double value1 = reader->Read<double>();

  // Create a Float64x2 object.
  Float64x2& simd = Float64x2::ZoneHandle(reader->zone(), Float64x2::null());
  simd = Float64x2::New(value0, value1);
  reader->AddBackRef(object_id, &simd, kIsDeserialized);
  return simd.raw();
}

void Float64x2Layout::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind,
                              bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kFloat64x2Cid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out the float values.
  writer->Write<double>(value_[0]);
  writer->Write<double>(value_[1]);
}

TypedDataPtr TypedData::ReadFrom(SnapshotReader* reader,
                                 intptr_t object_id,
                                 intptr_t tags,
                                 Snapshot::Kind kind,
                                 bool as_reference) {
  ASSERT(reader != NULL);

  intptr_t cid = ObjectLayout::ClassIdTag::decode(tags);
  intptr_t len = reader->ReadSmiValue();
  TypedData& result =
      TypedData::ZoneHandle(reader->zone(), TypedData::New(cid, len));
  reader->AddBackRef(object_id, &result, kIsDeserialized);

  // Setup the array elements.
  intptr_t element_size = ElementSizeInBytes(cid);
  intptr_t length_in_bytes = len * element_size;
  NoSafepointScope no_safepoint;
  uint8_t* data = reinterpret_cast<uint8_t*>(result.DataAddr(0));
  reader->Align(Zone::kAlignment);
  reader->ReadBytes(data, length_in_bytes);

  // If it is a canonical constant make it one.
  // When reading a full snapshot we don't need to canonicalize the object
  // as it would already be a canonical object.
  // When reading a script snapshot or a message snapshot we always have
  // to canonicalize the object.
  if (ObjectLayout::IsCanonical(tags)) {
    result ^= result.Canonicalize(reader->thread());
    ASSERT(!result.IsNull());
    ASSERT(result.IsCanonical());
  }
  return result.raw();
}

ExternalTypedDataPtr ExternalTypedData::ReadFrom(SnapshotReader* reader,
                                                 intptr_t object_id,
                                                 intptr_t tags,
                                                 Snapshot::Kind kind,
                                                 bool as_reference) {
  ASSERT(!Snapshot::IsFull(kind));
  intptr_t cid = ObjectLayout::ClassIdTag::decode(tags);
  intptr_t length = reader->ReadSmiValue();

  FinalizableData finalizable_data =
      static_cast<MessageSnapshotReader*>(reader)->finalizable_data()->Take();
  uint8_t* data = reinterpret_cast<uint8_t*>(finalizable_data.data);
  ExternalTypedData& obj =
      ExternalTypedData::ZoneHandle(ExternalTypedData::New(cid, data, length));
  reader->AddBackRef(object_id, &obj, kIsDeserialized);
  intptr_t external_size = obj.LengthInBytes();
  obj.AddFinalizer(finalizable_data.peer, finalizable_data.callback,
                   external_size);
  return obj.raw();
}

// This function's name can appear in Observatory.
static void IsolateMessageTypedDataFinalizer(void* isolate_callback_data,
                                             void* buffer) {
  free(buffer);
}

void TypedDataLayout::WriteTo(SnapshotWriter* writer,
                              intptr_t object_id,
                              Snapshot::Kind kind,
                              bool as_reference) {
  ASSERT(writer != NULL);
  intptr_t cid = this->GetClassId();
  intptr_t length = Smi::Value(length_);  // In elements.
  intptr_t external_cid;
  intptr_t bytes;
  switch (cid) {
    case kTypedDataInt8ArrayCid:
      external_cid = kExternalTypedDataInt8ArrayCid;
      bytes = length * sizeof(int8_t);
      break;
    case kTypedDataUint8ArrayCid:
      external_cid = kExternalTypedDataUint8ArrayCid;
      bytes = length * sizeof(uint8_t);
      break;
    case kTypedDataUint8ClampedArrayCid:
      external_cid = kExternalTypedDataUint8ClampedArrayCid;
      bytes = length * sizeof(uint8_t);
      break;
    case kTypedDataInt16ArrayCid:
      external_cid = kExternalTypedDataInt16ArrayCid;
      bytes = length * sizeof(int16_t);
      break;
    case kTypedDataUint16ArrayCid:
      external_cid = kExternalTypedDataUint16ArrayCid;
      bytes = length * sizeof(uint16_t);
      break;
    case kTypedDataInt32ArrayCid:
      external_cid = kExternalTypedDataInt32ArrayCid;
      bytes = length * sizeof(int32_t);
      break;
    case kTypedDataUint32ArrayCid:
      external_cid = kExternalTypedDataUint32ArrayCid;
      bytes = length * sizeof(uint32_t);
      break;
    case kTypedDataInt64ArrayCid:
      external_cid = kExternalTypedDataInt64ArrayCid;
      bytes = length * sizeof(int64_t);
      break;
    case kTypedDataUint64ArrayCid:
      external_cid = kExternalTypedDataUint64ArrayCid;
      bytes = length * sizeof(uint64_t);
      break;
    case kTypedDataFloat32ArrayCid:
      external_cid = kExternalTypedDataFloat32ArrayCid;
      bytes = length * sizeof(float);
      break;
    case kTypedDataFloat64ArrayCid:
      external_cid = kExternalTypedDataFloat64ArrayCid;
      bytes = length * sizeof(double);
      break;
    case kTypedDataInt32x4ArrayCid:
      external_cid = kExternalTypedDataInt32x4ArrayCid;
      bytes = length * sizeof(int32_t) * 4;
      break;
    case kTypedDataFloat32x4ArrayCid:
      external_cid = kExternalTypedDataFloat32x4ArrayCid;
      bytes = length * sizeof(float) * 4;
      break;
    case kTypedDataFloat64x2ArrayCid:
      external_cid = kExternalTypedDataFloat64x2ArrayCid;
      bytes = length * sizeof(double) * 2;
      break;
    default:
      external_cid = kIllegalCid;
      bytes = 0;
      UNREACHABLE();
  }

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  if ((kind == Snapshot::kMessage) &&
      (static_cast<uint64_t>(bytes) >= FLAG_externalize_typed_data_threshold)) {
    // Write as external.
    writer->WriteIndexedObject(external_cid);
    writer->WriteTags(writer->GetObjectTags(this));
    writer->Write<ObjectPtr>(length_);
    uint8_t* data = reinterpret_cast<uint8_t*>(this->data());
    void* passed_data = malloc(bytes);
    memmove(passed_data, data, bytes);
    static_cast<MessageWriter*>(writer)->finalizable_data()->Put(
        bytes,
        passed_data,  // data
        passed_data,  // peer,
        IsolateMessageTypedDataFinalizer);
  } else {
    // Write as internal.
    writer->WriteIndexedObject(cid);
    writer->WriteTags(writer->GetObjectTags(this));
    writer->Write<ObjectPtr>(length_);
    uint8_t* data = reinterpret_cast<uint8_t*>(this->data());
    writer->Align(Zone::kAlignment);
    writer->WriteBytes(data, bytes);
  }
}

void ExternalTypedDataLayout::WriteTo(SnapshotWriter* writer,
                                      intptr_t object_id,
                                      Snapshot::Kind kind,
                                      bool as_reference) {
  ASSERT(writer != NULL);
  intptr_t cid = this->GetClassId();
  intptr_t length = Smi::Value(length_);  // In elements.
  intptr_t bytes;
  switch (cid) {
    case kExternalTypedDataInt8ArrayCid:
      bytes = length * sizeof(int8_t);
      break;
    case kExternalTypedDataUint8ArrayCid:
      bytes = length * sizeof(uint8_t);
      break;
    case kExternalTypedDataUint8ClampedArrayCid:
      bytes = length * sizeof(uint8_t);
      break;
    case kExternalTypedDataInt16ArrayCid:
      bytes = length * sizeof(int16_t);
      break;
    case kExternalTypedDataUint16ArrayCid:
      bytes = length * sizeof(uint16_t);
      break;
    case kExternalTypedDataInt32ArrayCid:
      bytes = length * sizeof(int32_t);
      break;
    case kExternalTypedDataUint32ArrayCid:
      bytes = length * sizeof(uint32_t);
      break;
    case kExternalTypedDataInt64ArrayCid:
      bytes = length * sizeof(int64_t);
      break;
    case kExternalTypedDataUint64ArrayCid:
      bytes = length * sizeof(uint64_t);
      break;
    case kExternalTypedDataFloat32ArrayCid:
      bytes = length * sizeof(float);  // NOLINT.
      break;
    case kExternalTypedDataFloat64ArrayCid:
      bytes = length * sizeof(double);  // NOLINT.
      break;
    case kExternalTypedDataInt32x4ArrayCid:
      bytes = length * sizeof(int32_t) * 4;
      break;
    case kExternalTypedDataFloat32x4ArrayCid:
      bytes = length * sizeof(float) * 4;
      break;
    case kExternalTypedDataFloat64x2ArrayCid:
      bytes = length * sizeof(double) * 2;
      break;
    default:
      bytes = 0;
      UNREACHABLE();
  }

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write as external.
  writer->WriteIndexedObject(cid);
  writer->WriteTags(writer->GetObjectTags(this));
  writer->Write<ObjectPtr>(length_);
  uint8_t* data = reinterpret_cast<uint8_t*>(data_);
  void* passed_data = malloc(bytes);
  memmove(passed_data, data, bytes);
  static_cast<MessageWriter*>(writer)->finalizable_data()->Put(
      bytes,
      passed_data,  // data
      passed_data,  // peer,
      IsolateMessageTypedDataFinalizer);
}

void TypedDataViewLayout::WriteTo(SnapshotWriter* writer,
                                  intptr_t object_id,
                                  Snapshot::Kind kind,
                                  bool as_reference) {
  // Views have always a backing store.
  ASSERT(typed_data_ != Object::null());

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(GetClassId());
  writer->WriteTags(writer->GetObjectTags(this));

  // Write members.
  writer->Write<ObjectPtr>(offset_in_bytes_);
  writer->Write<ObjectPtr>(length_);
  writer->WriteObjectImpl(typed_data_, as_reference);
}

TypedDataViewPtr TypedDataView::ReadFrom(SnapshotReader* reader,
                                         intptr_t object_id,
                                         intptr_t tags,
                                         Snapshot::Kind kind,
                                         bool as_reference) {
  auto& typed_data = *reader->TypedDataBaseHandle();
  const classid_t cid = ObjectLayout::ClassIdTag::decode(tags);

  auto& view = *reader->TypedDataViewHandle();
  view = TypedDataView::New(cid);
  reader->AddBackRef(object_id, &view, kIsDeserialized);

  const intptr_t offset_in_bytes = reader->ReadSmiValue();
  const intptr_t length = reader->ReadSmiValue();
  typed_data ^= reader->ReadObjectImpl(as_reference);
  view.InitializeWith(typed_data, offset_in_bytes, length);

  return view.raw();
}

CapabilityPtr Capability::ReadFrom(SnapshotReader* reader,
                                   intptr_t object_id,
                                   intptr_t tags,
                                   Snapshot::Kind kind,
                                   bool as_reference) {
  uint64_t id = reader->Read<uint64_t>();

  Capability& result =
      Capability::ZoneHandle(reader->zone(), Capability::New(id));
  reader->AddBackRef(object_id, &result, kIsDeserialized);
  return result.raw();
}

void CapabilityLayout::WriteTo(SnapshotWriter* writer,
                               intptr_t object_id,
                               Snapshot::Kind kind,
                               bool as_reference) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kCapabilityCid);
  writer->WriteTags(writer->GetObjectTags(this));

  writer->Write<uint64_t>(id_);
}

SendPortPtr SendPort::ReadFrom(SnapshotReader* reader,
                               intptr_t object_id,
                               intptr_t tags,
                               Snapshot::Kind kind,
                               bool as_reference) {
  ASSERT(kind == Snapshot::kMessage);

  uint64_t id = reader->Read<uint64_t>();
  uint64_t origin_id = reader->Read<uint64_t>();

  SendPort& result =
      SendPort::ZoneHandle(reader->zone(), SendPort::New(id, origin_id));
  reader->AddBackRef(object_id, &result, kIsDeserialized);
  return result.raw();
}

void SendPortLayout::WriteTo(SnapshotWriter* writer,
                             intptr_t object_id,
                             Snapshot::Kind kind,
                             bool as_reference) {
  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kSendPortCid);
  writer->WriteTags(writer->GetObjectTags(this));

  writer->Write<uint64_t>(id_);
  writer->Write<uint64_t>(origin_id_);
}

TransferableTypedDataPtr TransferableTypedData::ReadFrom(SnapshotReader* reader,
                                                         intptr_t object_id,
                                                         intptr_t tags,
                                                         Snapshot::Kind kind,
                                                         bool as_reference) {
  ASSERT(reader != nullptr);

  ASSERT(!Snapshot::IsFull(kind));
  const intptr_t length = reader->Read<int32_t>();

  const FinalizableData finalizable_data =
      static_cast<MessageSnapshotReader*>(reader)->finalizable_data()->Take();
  uint8_t* data = reinterpret_cast<uint8_t*>(finalizable_data.data);
  auto& transferableTypedData = TransferableTypedData::ZoneHandle(
      reader->zone(), TransferableTypedData::New(data, length));
  reader->AddBackRef(object_id, &transferableTypedData, kIsDeserialized);
  return transferableTypedData.raw();
}

void TransferableTypedDataLayout::WriteTo(SnapshotWriter* writer,
                                          intptr_t object_id,
                                          Snapshot::Kind kind,
                                          bool as_reference) {
  ASSERT(writer != nullptr);
  ASSERT(GetClassId() == kTransferableTypedDataCid);
  void* peer = writer->thread()->heap()->GetPeer(ObjectPtr(this));
  // Assume that object's Peer is only used to track transferrability state.
  ASSERT(peer != nullptr);
  TransferableTypedDataPeer* tpeer =
      reinterpret_cast<TransferableTypedDataPeer*>(peer);
  intptr_t length = tpeer->length();  // In bytes.
  void* data = tpeer->data();
  if (data == nullptr) {
    writer->SetWriteException(
        Exceptions::kArgument,
        "Illegal argument in isolate message"
        " : (TransferableTypedData has been transferred already)");
    return;
  }

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  writer->WriteIndexedObject(GetClassId());
  writer->WriteTags(writer->GetObjectTags(this));
  writer->Write<int32_t>(length);

  static_cast<MessageWriter*>(writer)->finalizable_data()->Put(
      length, data, tpeer,
      // Finalizer does nothing - in case of failure to serialize,
      // [data] remains wrapped in sender's [TransferableTypedData].
      [](void* data, void* peer) {},
      // This is invoked on successful serialization of the message
      [](void* data, void* peer) {
        TransferableTypedDataPeer* tpeer =
            reinterpret_cast<TransferableTypedDataPeer*>(peer);
        tpeer->handle()->EnsureFreedExternal(IsolateGroup::Current());
        tpeer->ClearData();
      });
}

RegExpPtr RegExp::ReadFrom(SnapshotReader* reader,
                           intptr_t object_id,
                           intptr_t tags,
                           Snapshot::Kind kind,
                           bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate RegExp object.
  RegExp& regex = RegExp::ZoneHandle(reader->zone(), RegExp::New());
  reader->AddBackRef(object_id, &regex, kIsDeserialized);

  // Read and Set all the other fields.
  regex.StoreSmi(&regex.raw_ptr()->num_bracket_expressions_,
                 reader->ReadAsSmi());

  *reader->ArrayHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
  regex.set_capture_name_map(*reader->ArrayHandle());
  *reader->StringHandle() ^= reader->ReadObjectImpl(kAsInlinedObject);
  regex.set_pattern(*reader->StringHandle());

  regex.StoreNonPointer(&regex.raw_ptr()->num_one_byte_registers_,
                        reader->Read<int32_t>());
  regex.StoreNonPointer(&regex.raw_ptr()->num_two_byte_registers_,
                        reader->Read<int32_t>());
  regex.StoreNonPointer(&regex.raw_ptr()->type_flags_, reader->Read<int8_t>());

  const Function& no_function = Function::Handle(reader->zone());
  for (intptr_t cid = kOneByteStringCid; cid <= kExternalTwoByteStringCid;
       cid++) {
    regex.set_function(cid, /*sticky=*/false, no_function);
    regex.set_function(cid, /*sticky=*/true, no_function);
  }

  return regex.raw();
}

void RegExpLayout::WriteTo(SnapshotWriter* writer,
                           intptr_t object_id,
                           Snapshot::Kind kind,
                           bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kRegExpCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the other fields.
  writer->Write<ObjectPtr>(num_bracket_expressions_);
  writer->WriteObjectImpl(pattern_, kAsInlinedObject);
  writer->Write<int32_t>(num_one_byte_registers_);
  writer->Write<int32_t>(num_two_byte_registers_);
  writer->Write<int8_t>(type_flags_);
}

WeakPropertyPtr WeakProperty::ReadFrom(SnapshotReader* reader,
                                       intptr_t object_id,
                                       intptr_t tags,
                                       Snapshot::Kind kind,
                                       bool as_reference) {
  ASSERT(reader != NULL);

  // Allocate the weak property object.
  WeakProperty& weak_property =
      WeakProperty::ZoneHandle(reader->zone(), WeakProperty::New());
  reader->AddBackRef(object_id, &weak_property, kIsDeserialized);

  // Set all the object fields.
  READ_OBJECT_FIELDS(weak_property, weak_property.raw()->ptr()->from(),
                     weak_property.raw()->ptr()->to(), kAsReference);

  return weak_property.raw();
}

void WeakPropertyLayout::WriteTo(SnapshotWriter* writer,
                                 intptr_t object_id,
                                 Snapshot::Kind kind,
                                 bool as_reference) {
  ASSERT(writer != NULL);

  // Write out the serialization header value for this object.
  writer->WriteInlinedObjectHeader(object_id);

  // Write out the class and tags information.
  writer->WriteIndexedObject(kWeakPropertyCid);
  writer->WriteTags(writer->GetObjectTags(this));

  // Write out all the object pointer fields.
  SnapshotWriterVisitor visitor(writer, kAsReference);
  visitor.VisitPointers(from(), to());
}

}  // namespace dart
