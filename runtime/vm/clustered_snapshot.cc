// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/clustered_snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/compiler/backend/code_statistics.h"
#include "vm/dart.h"
#include "vm/heap/heap.h"
#include "vm/image_snapshot.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/program_visitor.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/version.h"

#define LOG_SECTION_BOUNDARIES false

namespace dart {

static RawObject* AllocateUninitialized(PageSpace* old_space, intptr_t size) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword address =
      old_space->TryAllocateDataBumpLocked(size, PageSpace::kForceGrowth);
  if (address == 0) {
    OUT_OF_MEMORY();
  }
  return RawObject::FromAddr(address);
}

static bool SnapshotContainsTypeTestingStubs(Snapshot::Kind kind) {
  return kind == Snapshot::kFullAOT || kind == Snapshot::kFullJIT;
}

void Deserializer::InitializeHeader(RawObject* raw,
                                    intptr_t class_id,
                                    intptr_t size,
                                    bool is_vm_isolate,
                                    bool is_canonical) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uint32_t tags = 0;
  tags = RawObject::ClassIdTag::update(class_id, tags);
  tags = RawObject::SizeTag::update(size, tags);
  tags = RawObject::VMHeapObjectTag::update(is_vm_isolate, tags);
  tags = RawObject::CanonicalObjectTag::update(is_canonical, tags);
  tags = RawObject::OldBit::update(true, tags);
  tags = RawObject::OldAndNotMarkedBit::update(true, tags);
  tags = RawObject::OldAndNotRememberedBit::update(true, tags);
  tags = RawObject::NewBit::update(false, tags);
  raw->ptr()->tags_ = tags;
#if defined(HASH_IN_OBJECT_HEADER)
  raw->ptr()->hash_ = 0;
#endif
}

void SerializationCluster::WriteAndMeasureAlloc(Serializer* serializer) {
  if (LOG_SECTION_BOUNDARIES) {
    OS::PrintErr("Data + %" Px ": Alloc %s\n", serializer->bytes_written(),
                 name_);
  }
  intptr_t start_size = serializer->bytes_written() + serializer->GetDataSize();
  intptr_t start_objects = serializer->next_ref_index();
  WriteAlloc(serializer);
  intptr_t stop_size = serializer->bytes_written() + serializer->GetDataSize();
  intptr_t stop_objects = serializer->next_ref_index();
  size_ += (stop_size - start_size);
  num_objects_ += (stop_objects - start_objects);
}

void SerializationCluster::WriteAndMeasureFill(Serializer* serializer) {
  if (LOG_SECTION_BOUNDARIES) {
    OS::PrintErr("Data + %" Px ": Fill %s\n", serializer->bytes_written(),
                 name_);
  }
  intptr_t start = serializer->bytes_written();
  WriteFill(serializer);
  intptr_t stop = serializer->bytes_written();
  size_ += (stop - start);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClassSerializationCluster : public SerializationCluster {
 public:
  explicit ClassSerializationCluster(intptr_t num_cids)
      : SerializationCluster("Class"),
        predefined_(kNumPredefinedCids),
        objects_(num_cids) {}
  ~ClassSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawClass* cls = Class::RawCast(object);
    intptr_t class_id = cls->ptr()->id_;

    if (class_id < kNumPredefinedCids) {
      // These classes are allocated by Object::Init or Object::InitOnce, so the
      // deserializer must find them in the class table instead of allocating
      // them.
      predefined_.Add(cls);
    } else {
      objects_.Add(cls);
    }

    PushFromTo(cls);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClassCid);
    intptr_t count = predefined_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClass* cls = predefined_[i];
      s->AssignRef(cls);
      AutoTraceObject(cls);
      intptr_t class_id = cls->ptr()->id_;
      s->WriteCid(class_id);
    }
    count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClass* cls = objects_[i];
      s->AssignRef(cls);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = predefined_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteClass(s, predefined_[i]);
    }
    count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteClass(s, objects_[i]);
    }
  }

  void WriteClass(Serializer* s, RawClass* cls) {
    AutoTraceObjectName(cls, cls->ptr()->name_);
    WriteFromTo(cls);
    intptr_t class_id = cls->ptr()->id_;
    if (class_id == kIllegalCid) {
      s->UnexpectedObject(cls, "Class with illegal cid");
    }
    s->WriteCid(class_id);
    if (s->kind() != Snapshot::kFullAOT) {
      s->Write<int32_t>(cls->ptr()->kernel_offset_);
    }
    s->Write<int32_t>(cls->ptr()->instance_size_in_words_);
    s->Write<int32_t>(cls->ptr()->next_field_offset_in_words_);
    s->Write<int32_t>(cls->ptr()->type_arguments_field_offset_in_words_);
    s->Write<uint16_t>(cls->ptr()->num_type_arguments_);
    s->Write<uint16_t>(cls->ptr()->has_pragma_and_num_own_type_arguments_);
    s->Write<uint16_t>(cls->ptr()->num_native_fields_);
    s->WriteTokenPosition(cls->ptr()->token_pos_);
    s->Write<uint16_t>(cls->ptr()->state_bits_);
  }

 private:
  GrowableArray<RawClass*> predefined_;
  GrowableArray<RawClass*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClassDeserializationCluster : public DeserializationCluster {
 public:
  ClassDeserializationCluster() {}
  ~ClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    predefined_start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    ClassTable* table = d->isolate()->class_table();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t class_id = d->ReadCid();
      ASSERT(table->HasValidClassAt(class_id));
      RawClass* cls = table->At(class_id);
      ASSERT(cls != NULL);
      d->AssignRef(cls);
    }
    predefined_stop_index_ = d->next_index();

    start_index_ = d->next_index();
    count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Class::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    ClassTable* table = d->isolate()->class_table();

    for (intptr_t id = predefined_start_index_; id < predefined_stop_index_;
         id++) {
      RawClass* cls = reinterpret_cast<RawClass*>(d->Ref(id));
      ReadFromTo(cls);
      intptr_t class_id = d->ReadCid();
      cls->ptr()->id_ = class_id;
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        cls->ptr()->kernel_offset_ = d->Read<int32_t>();
      }
#endif
      if (!RawObject::IsInternalVMdefinedClassId(class_id)) {
        cls->ptr()->instance_size_in_words_ = d->Read<int32_t>();
        cls->ptr()->next_field_offset_in_words_ = d->Read<int32_t>();
      } else {
        d->Read<int32_t>();  // Skip.
        d->Read<int32_t>();  // Skip.
      }
      cls->ptr()->type_arguments_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->num_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->has_pragma_and_num_own_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint16_t>();
    }

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawClass* cls = reinterpret_cast<RawClass*>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kClassCid, Class::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(cls);

      intptr_t class_id = d->ReadCid();

      ASSERT(class_id >= kNumPredefinedCids);
      Instance fake;
      cls->ptr()->handle_vtable_ = fake.vtable();

      cls->ptr()->id_ = class_id;
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        cls->ptr()->kernel_offset_ = d->Read<int32_t>();
      }
#endif
      cls->ptr()->instance_size_in_words_ = d->Read<int32_t>();
      cls->ptr()->next_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->type_arguments_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->num_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->has_pragma_and_num_own_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint16_t>();

      table->AllocateIndex(class_id);
      table->SetAt(class_id, cls);
    }
  }

 private:
  intptr_t predefined_start_index_;
  intptr_t predefined_stop_index_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeArgumentsSerializationCluster : public SerializationCluster {
 public:
  TypeArgumentsSerializationCluster() : SerializationCluster("TypeArguments") {}
  ~TypeArgumentsSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypeArguments* type_args = TypeArguments::RawCast(object);
    objects_.Add(type_args);

    s->Push(type_args->ptr()->instantiations_);
    intptr_t length = Smi::Value(type_args->ptr()->length_);
    for (intptr_t i = 0; i < length; i++) {
      s->Push(type_args->ptr()->types()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeArgumentsCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeArguments* type_args = objects_[i];
      s->AssignRef(type_args);
      AutoTraceObject(type_args);
      intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeArguments* type_args = objects_[i];
      AutoTraceObject(type_args);
      intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->WriteUnsigned(length);
      s->Write<bool>(type_args->IsCanonical());
      intptr_t hash = Smi::Value(type_args->ptr()->hash_);
      s->Write<int32_t>(hash);
      s->WriteRef(type_args->ptr()->instantiations_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(type_args->ptr()->types()[j]);
      }
    }
  }

 private:
  GrowableArray<RawTypeArguments*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeArgumentsDeserializationCluster : public DeserializationCluster {
 public:
  TypeArgumentsDeserializationCluster() {}
  ~TypeArgumentsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         TypeArguments::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypeArguments* type_args =
          reinterpret_cast<RawTypeArguments*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(type_args, kTypeArgumentsCid,
                                     TypeArguments::InstanceSize(length),
                                     is_vm_object, is_canonical);
      type_args->ptr()->length_ = Smi::New(length);
      type_args->ptr()->hash_ = Smi::New(d->Read<int32_t>());
      type_args->ptr()->instantiations_ =
          reinterpret_cast<RawArray*>(d->ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        type_args->ptr()->types()[j] =
            reinterpret_cast<RawAbstractType*>(d->ReadRef());
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class PatchClassSerializationCluster : public SerializationCluster {
 public:
  PatchClassSerializationCluster() : SerializationCluster("PatchClass") {}
  ~PatchClassSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawPatchClass* cls = PatchClass::RawCast(object);
    objects_.Add(cls);
    PushFromTo(cls);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kPatchClassCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawPatchClass* cls = objects_[i];
      s->AssignRef(cls);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawPatchClass* cls = objects_[i];
      AutoTraceObject(cls);
      WriteFromTo(cls);
      if (s->kind() != Snapshot::kFullAOT) {
        s->Write<int32_t>(cls->ptr()->library_kernel_offset_);
      }
    }
  }

 private:
  GrowableArray<RawPatchClass*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class PatchClassDeserializationCluster : public DeserializationCluster {
 public:
  PatchClassDeserializationCluster() {}
  ~PatchClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, PatchClass::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawPatchClass* cls = reinterpret_cast<RawPatchClass*>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kPatchClassCid,
                                     PatchClass::InstanceSize(), is_vm_object);
      ReadFromTo(cls);
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        cls->ptr()->library_kernel_offset_ = d->Read<int32_t>();
      }
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FunctionSerializationCluster : public SerializationCluster {
 public:
  FunctionSerializationCluster() : SerializationCluster("Function") {}
  ~FunctionSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    Snapshot::Kind kind = s->kind();
    RawFunction* func = Function::RawCast(object);
    objects_.Add(func);

    PushFromTo(func);
    if (kind == Snapshot::kFull) {
      NOT_IN_PRECOMPILED(s->Push(func->ptr()->bytecode_));
    } else if (kind == Snapshot::kFullAOT) {
      s->Push(func->ptr()->code_);
    } else if (kind == Snapshot::kFullJIT) {
      NOT_IN_PRECOMPILED(s->Push(func->ptr()->unoptimized_code_));
      NOT_IN_PRECOMPILED(s->Push(func->ptr()->bytecode_));
      s->Push(func->ptr()->code_);
      s->Push(func->ptr()->ic_data_array_);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFunctionCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawFunction* func = objects_[i];
      s->AssignRef(func);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawFunction* func = objects_[i];
      AutoTraceObjectName(func, func->ptr()->name_);
      WriteFromTo(func);
      if (kind == Snapshot::kFull) {
        NOT_IN_PRECOMPILED(WriteField(func, bytecode_));
      } else if (kind == Snapshot::kFullAOT) {
        WriteField(func, code_);
      } else if (s->kind() == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(WriteField(func, unoptimized_code_));
        NOT_IN_PRECOMPILED(WriteField(func, bytecode_));
        WriteField(func, code_);
        WriteField(func, ic_data_array_);
      }

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(func->ptr()->token_pos_);
        s->WriteTokenPosition(func->ptr()->end_token_pos_);
        s->Write<int32_t>(func->ptr()->kernel_offset_);
      }
#endif
      s->Write<uint32_t>(func->ptr()->packed_fields_);
      s->Write<uint32_t>(func->ptr()->kind_tag_);
    }
  }

 private:
  GrowableArray<RawFunction*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FunctionDeserializationCluster : public DeserializationCluster {
 public:
  FunctionDeserializationCluster() {}
  ~FunctionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Function::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawFunction* func = reinterpret_cast<RawFunction*>(d->Ref(id));
      Deserializer::InitializeHeader(func, kFunctionCid,
                                     Function::InstanceSize(), is_vm_object);
      ReadFromTo(func);

      if (kind == Snapshot::kFull) {
        NOT_IN_PRECOMPILED(func->ptr()->bytecode_ =
                               reinterpret_cast<RawBytecode*>(d->ReadRef()));
      } else if (kind == Snapshot::kFullAOT) {
        func->ptr()->code_ = reinterpret_cast<RawCode*>(d->ReadRef());
      } else if (kind == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(func->ptr()->unoptimized_code_ =
                               reinterpret_cast<RawCode*>(d->ReadRef()));
        NOT_IN_PRECOMPILED(func->ptr()->bytecode_ =
                               reinterpret_cast<RawBytecode*>(d->ReadRef()));
        func->ptr()->code_ = reinterpret_cast<RawCode*>(d->ReadRef());
        func->ptr()->ic_data_array_ = reinterpret_cast<RawArray*>(d->ReadRef());
      }

#if defined(DEBUG)
      func->ptr()->entry_point_ = 0;
      func->ptr()->unchecked_entry_point_ = 0;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (kind != Snapshot::kFullAOT) {
        func->ptr()->token_pos_ = d->ReadTokenPosition();
        func->ptr()->end_token_pos_ = d->ReadTokenPosition();
        func->ptr()->kernel_offset_ = d->Read<int32_t>();
      }
#endif
      func->ptr()->packed_fields_ = d->Read<uint32_t>();
      func->ptr()->kind_tag_ = d->Read<uint32_t>();
      if (kind == Snapshot::kFullAOT) {
        // Omit fields used to support de/reoptimization.
      } else {
#if !defined(DART_PRECOMPILED_RUNTIME)
        func->ptr()->usage_counter_ = 0;
        func->ptr()->optimized_instruction_count_ = 0;
        func->ptr()->optimized_call_site_count_ = 0;
        func->ptr()->deoptimization_counter_ = 0;
        func->ptr()->state_bits_ = 0;
        func->ptr()->inlining_depth_ = 0;
#endif
      }
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        Thread::Current(), Timeline::GetIsolateStream(), "PostLoadFunction"));

    if (kind == Snapshot::kFullAOT) {
      Function& func = Function::Handle(zone);
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        ASSERT(func.raw()->ptr()->code_->IsCode());
        uword entry_point = func.raw()->ptr()->code_->ptr()->entry_point_;
        ASSERT(entry_point != 0);
        func.raw()->ptr()->entry_point_ = entry_point;
        uword unchecked_entry_point =
            func.raw()->ptr()->code_->ptr()->unchecked_entry_point_;
        ASSERT(unchecked_entry_point != 0);
        func.raw()->ptr()->unchecked_entry_point_ = unchecked_entry_point;
      }
    } else if (kind == Snapshot::kFullJIT) {
      Function& func = Function::Handle(zone);
      Code& code = Code::Handle(zone);
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        code ^= func.CurrentCode();
        if (func.HasCode() && !code.IsDisabled()) {
          func.SetInstructions(code);  // Set entrypoint.
          func.SetWasCompiled(true);
#if !defined(DART_PRECOMPILED_RUNTIME)
        } else if (FLAG_enable_interpreter && func.HasBytecode()) {
          // Set the code entry_point to InterpretCall stub.
          func.SetInstructions(StubCode::InterpretCall());
        } else if (FLAG_use_bytecode_compiler && func.HasBytecode()) {
          func.SetInstructions(StubCode::LazyCompile());
#endif                                 // !defined(DART_PRECOMPILED_RUNTIME)
        } else {
          func.ClearCode();  // Set code and entrypoint to lazy compile stub.
        }
      }
    } else {
      Function& func = Function::Handle(zone);
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        func.ClearCode();  // Set code and entrypoint to lazy compile stub.
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureDataSerializationCluster : public SerializationCluster {
 public:
  ClosureDataSerializationCluster() : SerializationCluster("ClosureData") {}
  ~ClosureDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawClosureData* data = ClosureData::RawCast(object);
    objects_.Add(data);

    if (s->kind() != Snapshot::kFullAOT) {
      s->Push(data->ptr()->context_scope_);
    }
    s->Push(data->ptr()->parent_function_);
    s->Push(data->ptr()->signature_type_);
    s->Push(data->ptr()->closure_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClosureDataCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClosureData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawClosureData* data = objects_[i];
      AutoTraceObject(data);
      if (s->kind() != Snapshot::kFullAOT) {
        s->WriteRef(data->ptr()->context_scope_);
      }
      s->WriteRef(data->ptr()->parent_function_);
      s->WriteRef(data->ptr()->signature_type_);
      s->WriteRef(data->ptr()->closure_);
    }
  }

 private:
  GrowableArray<RawClosureData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClosureDataDeserializationCluster : public DeserializationCluster {
 public:
  ClosureDataDeserializationCluster() {}
  ~ClosureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, ClosureData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawClosureData* data = reinterpret_cast<RawClosureData*>(d->Ref(id));
      Deserializer::InitializeHeader(data, kClosureDataCid,
                                     ClosureData::InstanceSize(), is_vm_object);
      if (d->kind() == Snapshot::kFullAOT) {
        data->ptr()->context_scope_ = ContextScope::null();
      } else {
        data->ptr()->context_scope_ =
            static_cast<RawContextScope*>(d->ReadRef());
      }
      data->ptr()->parent_function_ = static_cast<RawFunction*>(d->ReadRef());
      data->ptr()->signature_type_ = static_cast<RawType*>(d->ReadRef());
      data->ptr()->closure_ = static_cast<RawInstance*>(d->ReadRef());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SignatureDataSerializationCluster : public SerializationCluster {
 public:
  SignatureDataSerializationCluster() : SerializationCluster("SignatureData") {}
  ~SignatureDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawSignatureData* data = SignatureData::RawCast(object);
    objects_.Add(data);
    PushFromTo(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSignatureDataCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawSignatureData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawSignatureData* data = objects_[i];
      AutoTraceObject(data);
      WriteFromTo(data);
    }
  }

 private:
  GrowableArray<RawSignatureData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SignatureDataDeserializationCluster : public DeserializationCluster {
 public:
  SignatureDataDeserializationCluster() {}
  ~SignatureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, SignatureData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawSignatureData* data = reinterpret_cast<RawSignatureData*>(d->Ref(id));
      Deserializer::InitializeHeader(
          data, kSignatureDataCid, SignatureData::InstanceSize(), is_vm_object);
      ReadFromTo(data);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RedirectionDataSerializationCluster : public SerializationCluster {
 public:
  RedirectionDataSerializationCluster()
      : SerializationCluster("RedirectionData") {}
  ~RedirectionDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawRedirectionData* data = RedirectionData::RawCast(object);
    objects_.Add(data);
    PushFromTo(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kRedirectionDataCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawRedirectionData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawRedirectionData* data = objects_[i];
      AutoTraceObject(data);
      WriteFromTo(data);
    }
  }

 private:
  GrowableArray<RawRedirectionData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RedirectionDataDeserializationCluster : public DeserializationCluster {
 public:
  RedirectionDataDeserializationCluster() {}
  ~RedirectionDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, RedirectionData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawRedirectionData* data =
          reinterpret_cast<RawRedirectionData*>(d->Ref(id));
      Deserializer::InitializeHeader(data, kRedirectionDataCid,
                                     RedirectionData::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(data);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FieldSerializationCluster : public SerializationCluster {
 public:
  FieldSerializationCluster() : SerializationCluster("Field") {}
  ~FieldSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawField* field = Field::RawCast(object);
    objects_.Add(field);

    Snapshot::Kind kind = s->kind();

    s->Push(field->ptr()->name_);
    s->Push(field->ptr()->owner_);
    s->Push(field->ptr()->type_);
    // Write out the initial static value or field offset.
    if (Field::StaticBit::decode(field->ptr()->kind_bits_)) {
      if (kind == Snapshot::kFullAOT) {
        // For precompiled static fields, the value was already reset and
        // initializer_ now contains a Function.
        s->Push(field->ptr()->value_.static_value_);
      } else if (Field::ConstBit::decode(field->ptr()->kind_bits_)) {
        // Do not reset const fields.
        s->Push(field->ptr()->value_.static_value_);
      } else {
        // Otherwise, for static fields we write out the initial static value.
        s->Push(field->ptr()->initializer_.saved_value_);
      }
    } else {
      s->Push(field->ptr()->value_.offset_);
    }
    // Write out the initializer function or saved initial value.
    if (kind == Snapshot::kFullAOT) {
      s->Push(field->ptr()->initializer_.precompiled_);
    } else {
      s->Push(field->ptr()->initializer_.saved_value_);
    }
    if (kind != Snapshot::kFullAOT) {
      // Write out the guarded list length.
      s->Push(field->ptr()->guarded_list_length_);
    }
    if (kind == Snapshot::kFullJIT) {
      s->Push(field->ptr()->dependent_code_);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFieldCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawField* field = objects_[i];
      s->AssignRef(field);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawField* field = objects_[i];
      AutoTraceObject(field);

      s->WriteRef(field->ptr()->name_);
      s->WriteRef(field->ptr()->owner_);
      s->WriteRef(field->ptr()->type_);
      // Write out the initial static value or field offset.
      if (Field::StaticBit::decode(field->ptr()->kind_bits_)) {
        if (kind == Snapshot::kFullAOT) {
          // For precompiled static fields, the value was already reset and
          // initializer_ now contains a Function.
          s->WriteRef(field->ptr()->value_.static_value_);
        } else if (Field::ConstBit::decode(field->ptr()->kind_bits_)) {
          // Do not reset const fields.
          s->WriteRef(field->ptr()->value_.static_value_);
        } else {
          // Otherwise, for static fields we write out the initial static value.
          s->WriteRef(field->ptr()->initializer_.saved_value_);
        }
      } else {
        s->WriteRef(field->ptr()->value_.offset_);
      }
      // Write out the initializer function or saved initial value.
      if (kind == Snapshot::kFullAOT) {
        s->WriteRef(field->ptr()->initializer_.precompiled_);
      } else {
        s->WriteRef(field->ptr()->initializer_.saved_value_);
      }
      if (kind != Snapshot::kFullAOT) {
        // Write out the guarded list length.
        s->WriteRef(field->ptr()->guarded_list_length_);
      }
      if (kind == Snapshot::kFullJIT) {
        s->WriteRef(field->ptr()->dependent_code_);
      }

      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(field->ptr()->token_pos_);
        s->WriteTokenPosition(field->ptr()->end_token_pos_);
        s->WriteCid(field->ptr()->guarded_cid_);
        s->WriteCid(field->ptr()->is_nullable_);
        s->Write<int8_t>(field->ptr()->static_type_exactness_state_);
#if !defined(DART_PRECOMPILED_RUNTIME)
        s->Write<int32_t>(field->ptr()->kernel_offset_);
#endif
      }
      s->Write<uint16_t>(field->ptr()->kind_bits_);
    }
  }

 private:
  GrowableArray<RawField*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FieldDeserializationCluster : public DeserializationCluster {
 public:
  FieldDeserializationCluster() {}
  ~FieldDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Field::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawField* field = reinterpret_cast<RawField*>(d->Ref(id));
      Deserializer::InitializeHeader(field, kFieldCid, Field::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(field);
      if (kind != Snapshot::kFullAOT) {
        field->ptr()->token_pos_ = d->ReadTokenPosition();
        field->ptr()->end_token_pos_ = d->ReadTokenPosition();
        field->ptr()->guarded_cid_ = d->ReadCid();
        field->ptr()->is_nullable_ = d->ReadCid();
        field->ptr()->static_type_exactness_state_ = d->Read<int8_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
        field->ptr()->kernel_offset_ = d->Read<int32_t>();
#endif
      }
      field->ptr()->kind_bits_ = d->Read<uint16_t>();
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        Thread::Current(), Timeline::GetIsolateStream(), "PostLoadField"));

    Field& field = Field::Handle(zone);
    if (!Isolate::Current()->use_field_guards()) {
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        field ^= refs.At(i);
        field.set_guarded_cid(kDynamicCid);
        field.set_is_nullable(true);
        field.set_guarded_list_length(Field::kNoFixedLength);
        field.set_guarded_list_length_in_object_offset(
            Field::kUnknownLengthOffset);
        field.set_static_type_exactness_state(
            StaticTypeExactnessState::NotTracking());
      }
    } else {
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        field ^= refs.At(i);
        field.InitializeGuardedListLengthInObjectOffset();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ScriptSerializationCluster : public SerializationCluster {
 public:
  ScriptSerializationCluster() : SerializationCluster("Script") {}
  ~ScriptSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawScript* script = Script::RawCast(object);
    objects_.Add(script);
    PushFromTo(script);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kScriptCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawScript* script = objects_[i];
      s->AssignRef(script);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawScript* script = objects_[i];
      AutoTraceObject(script);
      WriteFromTo(script);
      s->Write<int32_t>(script->ptr()->line_offset_);
      s->Write<int32_t>(script->ptr()->col_offset_);
      s->Write<int8_t>(script->ptr()->kind_);
      s->Write<int32_t>(script->ptr()->kernel_script_index_);
    }
  }

 private:
  GrowableArray<RawScript*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ScriptDeserializationCluster : public DeserializationCluster {
 public:
  ScriptDeserializationCluster() {}
  ~ScriptDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Script::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawScript* script = reinterpret_cast<RawScript*>(d->Ref(id));
      Deserializer::InitializeHeader(script, kScriptCid, Script::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(script);
      script->ptr()->line_offset_ = d->Read<int32_t>();
      script->ptr()->col_offset_ = d->Read<int32_t>();
      script->ptr()->kind_ = d->Read<int8_t>();
      script->ptr()->kernel_script_index_ = d->Read<int32_t>();
      script->ptr()->load_timestamp_ = 0;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LibrarySerializationCluster : public SerializationCluster {
 public:
  LibrarySerializationCluster() : SerializationCluster("Library") {}
  ~LibrarySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLibrary* lib = Library::RawCast(object);
    objects_.Add(lib);
    PushFromTo(lib);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLibrary* lib = objects_[i];
      s->AssignRef(lib);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLibrary* lib = objects_[i];
      AutoTraceObjectName(lib, lib->ptr()->url_);
      WriteFromTo(lib);
      s->Write<int32_t>(lib->ptr()->index_);
      s->Write<uint16_t>(lib->ptr()->num_imports_);
      s->Write<int8_t>(lib->ptr()->load_state_);
      s->Write<bool>(lib->ptr()->corelib_imported_);
      s->Write<bool>(lib->ptr()->is_dart_scheme_);
      s->Write<bool>(lib->ptr()->debuggable_);
      if (s->kind() != Snapshot::kFullAOT) {
        s->Write<int32_t>(lib->ptr()->kernel_offset_);
      }
    }
  }

 private:
  GrowableArray<RawLibrary*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LibraryDeserializationCluster : public DeserializationCluster {
 public:
  LibraryDeserializationCluster() {}
  ~LibraryDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Library::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLibrary* lib = reinterpret_cast<RawLibrary*>(d->Ref(id));
      Deserializer::InitializeHeader(lib, kLibraryCid, Library::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(lib);
      lib->ptr()->native_entry_resolver_ = NULL;
      lib->ptr()->native_entry_symbol_resolver_ = NULL;
      lib->ptr()->index_ = d->Read<int32_t>();
      lib->ptr()->num_imports_ = d->Read<uint16_t>();
      lib->ptr()->load_state_ = d->Read<int8_t>();
      lib->ptr()->corelib_imported_ = d->Read<bool>();
      lib->ptr()->is_dart_scheme_ = d->Read<bool>();
      lib->ptr()->debuggable_ = d->Read<bool>();
      lib->ptr()->is_in_fullsnapshot_ = true;
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        lib->ptr()->kernel_offset_ = d->Read<int32_t>();
      }
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class NamespaceSerializationCluster : public SerializationCluster {
 public:
  NamespaceSerializationCluster() : SerializationCluster("Namespace") {}
  ~NamespaceSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawNamespace* ns = Namespace::RawCast(object);
    objects_.Add(ns);
    PushFromTo(ns);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kNamespaceCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawNamespace* ns = objects_[i];
      s->AssignRef(ns);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawNamespace* ns = objects_[i];
      AutoTraceObject(ns);
      WriteFromTo(ns);
    }
  }

 private:
  GrowableArray<RawNamespace*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class NamespaceDeserializationCluster : public DeserializationCluster {
 public:
  NamespaceDeserializationCluster() {}
  ~NamespaceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Namespace::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawNamespace* ns = reinterpret_cast<RawNamespace*>(d->Ref(id));
      Deserializer::InitializeHeader(ns, kNamespaceCid,
                                     Namespace::InstanceSize(), is_vm_object);
      ReadFromTo(ns);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
// KernelProgramInfo objects are not written into a full AOT snapshot.
class KernelProgramInfoSerializationCluster : public SerializationCluster {
 public:
  KernelProgramInfoSerializationCluster()
      : SerializationCluster("KernelProgramInfo") {}
  ~KernelProgramInfoSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawKernelProgramInfo* info = KernelProgramInfo::RawCast(object);
    objects_.Add(info);
    PushFromTo(info);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kKernelProgramInfoCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawKernelProgramInfo* info = objects_[i];
      s->AssignRef(info);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawKernelProgramInfo* info = objects_[i];
      AutoTraceObject(info);
      WriteFromTo(info);
    }
  }

 private:
  GrowableArray<RawKernelProgramInfo*> objects_;
};

// Since KernelProgramInfo objects are not written into full AOT snapshots,
// one will never need to read them from a full AOT snapshot.
class KernelProgramInfoDeserializationCluster : public DeserializationCluster {
 public:
  KernelProgramInfoDeserializationCluster() {}
  ~KernelProgramInfoDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, KernelProgramInfo::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawKernelProgramInfo* info =
          reinterpret_cast<RawKernelProgramInfo*>(d->Ref(id));
      Deserializer::InitializeHeader(info, kKernelProgramInfoCid,
                                     KernelProgramInfo::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(info);
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    Array& array_ = Array::Handle(zone);
    KernelProgramInfo& info_ = KernelProgramInfo::Handle(zone);
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      info_ ^= refs.At(id);
      array_ = HashTables::New<UnorderedHashMap<SmiTraits>>(16, Heap::kOld);
      info_.set_libraries_cache(array_);
      array_ = HashTables::New<UnorderedHashMap<SmiTraits>>(16, Heap::kOld);
      info_.set_classes_cache(array_);
    }
  }
};

class CodeSerializationCluster : public SerializationCluster {
 public:
  CodeSerializationCluster() : SerializationCluster("Code") {}
  ~CodeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawCode* code = Code::RawCast(object);
    objects_.Add(code);

    s->Push(code->ptr()->object_pool_);
    s->Push(code->ptr()->owner_);
    s->Push(code->ptr()->exception_handlers_);
    s->Push(code->ptr()->pc_descriptors_);
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
    s->Push(code->ptr()->catch_entry_.catch_entry_moves_maps_);
#else
    s->Push(code->ptr()->catch_entry_.variables_);
#endif
    s->Push(code->ptr()->stackmaps_);
    if (!FLAG_dwarf_stack_traces) {
      s->Push(code->ptr()->inlined_id_to_function_);
      s->Push(code->ptr()->code_source_map_);
    }
    if (s->kind() == Snapshot::kFullJIT) {
      s->Push(code->ptr()->deopt_info_array_);
      s->Push(code->ptr()->static_calls_target_table_);
    }
    NOT_IN_PRODUCT(s->Push(code->ptr()->await_token_positions_));
    NOT_IN_PRODUCT(s->Push(code->ptr()->return_address_metadata_));
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kCodeCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawCode* code = objects_[i];
      s->AssignRef(code);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawCode* code = objects_[i];
      AutoTraceObject(code);

      intptr_t pointer_offsets_length =
          Code::PtrOffBits::decode(code->ptr()->state_bits_);
      if (pointer_offsets_length != 0) {
        FATAL("Cannot serialize code with embedded pointers");
      }
      if (kind == Snapshot::kFullAOT) {
        if (code->ptr()->instructions_ != code->ptr()->active_instructions_) {
          // Disabled code is fatal in AOT since we cannot recompile.
          s->UnexpectedObject(code, "Disabled code");
        }
      }

      s->WriteInstructions(code->ptr()->instructions_, code);
      if (kind == Snapshot::kFullJIT) {
        // TODO(rmacnak): Fix references to disabled code before serializing.
        // For now, we may write the FixCallersTarget or equivalent stub. This
        // will cause a fixup if this code is called.
        s->WriteInstructions(code->ptr()->active_instructions_, code);
      }

      s->WriteRef(code->ptr()->object_pool_);
      s->WriteRef(code->ptr()->owner_);
      s->WriteRef(code->ptr()->exception_handlers_);
      s->WriteRef(code->ptr()->pc_descriptors_);
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
      s->WriteRef(code->ptr()->catch_entry_.catch_entry_moves_maps_);
#else
      s->WriteRef(code->ptr()->catch_entry_.variables_);
#endif
      s->WriteRef(code->ptr()->stackmaps_);
      if (FLAG_dwarf_stack_traces) {
        s->WriteRef(Array::null());
        s->WriteRef(CodeSourceMap::null());
      } else {
        s->WriteRef(code->ptr()->inlined_id_to_function_);
        s->WriteRef(code->ptr()->code_source_map_);
      }
      if (kind == Snapshot::kFullJIT) {
        s->WriteRef(code->ptr()->deopt_info_array_);
        s->WriteRef(code->ptr()->static_calls_target_table_);
      }
      NOT_IN_PRODUCT(s->WriteRef(code->ptr()->await_token_positions_));
      NOT_IN_PRODUCT(s->WriteRef(code->ptr()->return_address_metadata_));

      s->Write<int32_t>(code->ptr()->state_bits_);
    }
  }

 private:
  GrowableArray<RawCode*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class CodeDeserializationCluster : public DeserializationCluster {
 public:
  CodeDeserializationCluster() {}
  ~CodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Code::InstanceSize(0)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawCode* code = reinterpret_cast<RawCode*>(d->Ref(id));
      Deserializer::InitializeHeader(code, kCodeCid, Code::InstanceSize(0),
                                     is_vm_object);

      RawInstructions* instr = d->ReadInstructions();

      code->ptr()->entry_point_ = Instructions::EntryPoint(instr);
      code->ptr()->monomorphic_entry_point_ =
          Instructions::MonomorphicEntryPoint(instr);
      NOT_IN_PRECOMPILED(code->ptr()->active_instructions_ = instr);
      code->ptr()->instructions_ = instr;
      code->ptr()->unchecked_entry_point_ =
          Instructions::UncheckedEntryPoint(instr);

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() == Snapshot::kFullJIT) {
        RawInstructions* instr = d->ReadInstructions();
        code->ptr()->active_instructions_ = instr;
        code->ptr()->entry_point_ = Instructions::EntryPoint(instr);
        code->ptr()->monomorphic_entry_point_ =
            Instructions::MonomorphicEntryPoint(instr);
        code->ptr()->unchecked_entry_point_ =
            Instructions::UncheckedEntryPoint(instr);
      }
#endif  // !DART_PRECOMPILED_RUNTIME

      code->ptr()->object_pool_ =
          reinterpret_cast<RawObjectPool*>(d->ReadRef());
      code->ptr()->owner_ = d->ReadRef();
      code->ptr()->exception_handlers_ =
          reinterpret_cast<RawExceptionHandlers*>(d->ReadRef());
      code->ptr()->pc_descriptors_ =
          reinterpret_cast<RawPcDescriptors*>(d->ReadRef());
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
      code->ptr()->catch_entry_.catch_entry_moves_maps_ =
          reinterpret_cast<RawTypedData*>(d->ReadRef());
#else
      code->ptr()->catch_entry_.variables_ =
          reinterpret_cast<RawSmi*>(d->ReadRef());
#endif
      code->ptr()->stackmaps_ = reinterpret_cast<RawArray*>(d->ReadRef());
      code->ptr()->inlined_id_to_function_ =
          reinterpret_cast<RawArray*>(d->ReadRef());
      code->ptr()->code_source_map_ =
          reinterpret_cast<RawCodeSourceMap*>(d->ReadRef());

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() == Snapshot::kFullJIT) {
        code->ptr()->deopt_info_array_ =
            reinterpret_cast<RawArray*>(d->ReadRef());
        code->ptr()->static_calls_target_table_ =
            reinterpret_cast<RawArray*>(d->ReadRef());
      }
#endif  // !DART_PRECOMPILED_RUNTIME

#if !defined(PRODUCT)
      code->ptr()->await_token_positions_ =
          reinterpret_cast<RawArray*>(d->ReadRef());
      code->ptr()->return_address_metadata_ = d->ReadRef();
      code->ptr()->var_descriptors_ = LocalVarDescriptors::null();
      code->ptr()->comments_ = Array::null();
      code->ptr()->compile_timestamp_ = 0;
#endif

      code->ptr()->state_bits_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class BytecodeSerializationCluster : public SerializationCluster {
 public:
  BytecodeSerializationCluster() : SerializationCluster("Bytecode") {}
  virtual ~BytecodeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawBytecode* bytecode = Bytecode::RawCast(object);
    objects_.Add(bytecode);
    PushFromTo(bytecode);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kBytecodeCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawBytecode* bytecode = objects_[i];
      s->AssignRef(bytecode);
    }
  }

  void WriteFill(Serializer* s) {
    ASSERT(s->kind() == Snapshot::kFullJIT);
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawBytecode* bytecode = objects_[i];
      WriteFromTo(bytecode);
      s->Write<int32_t>(bytecode->ptr()->source_positions_binary_offset_);
    }
  }

 private:
  GrowableArray<RawBytecode*> objects_;
};

class BytecodeDeserializationCluster : public DeserializationCluster {
 public:
  BytecodeDeserializationCluster() {}
  virtual ~BytecodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Bytecode::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    ASSERT(d->kind() == Snapshot::kFullJIT);
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawBytecode* bytecode = reinterpret_cast<RawBytecode*>(d->Ref(id));
      Deserializer::InitializeHeader(bytecode, kBytecodeCid,
                                     Bytecode::InstanceSize(), is_vm_object);
      ReadFromTo(bytecode);
      bytecode->ptr()->source_positions_binary_offset_ = d->Read<int32_t>();
    }
  }
};

class ObjectPoolSerializationCluster : public SerializationCluster {
 public:
  ObjectPoolSerializationCluster() : SerializationCluster("ObjectPool") {}
  ~ObjectPoolSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawObjectPool* pool = ObjectPool::RawCast(object);
    objects_.Add(pool);

    intptr_t length = pool->ptr()->length_;
    uint8_t* entry_bits = pool->ptr()->entry_bits();
    for (intptr_t i = 0; i < length; i++) {
      auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
      if ((entry_type == ObjectPool::kTaggedObject) ||
          (entry_type == ObjectPool::kNativeEntryData)) {
        s->Push(pool->ptr()->data()[i].raw_obj_);
      }
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kObjectPoolCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawObjectPool* pool = objects_[i];
      s->AssignRef(pool);
      AutoTraceObject(pool);
      intptr_t length = pool->ptr()->length_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawObjectPool* pool = objects_[i];
      AutoTraceObject(pool);
      intptr_t length = pool->ptr()->length_;
      s->WriteUnsigned(length);
      uint8_t* entry_bits = pool->ptr()->entry_bits();
      for (intptr_t j = 0; j < length; j++) {
        s->Write<uint8_t>(entry_bits[j]);
        RawObjectPool::Entry& entry = pool->ptr()->data()[j];
        switch (ObjectPool::TypeBits::decode(entry_bits[j])) {
          case ObjectPool::kTaggedObject: {
#if !defined(TARGET_ARCH_DBC)
            if ((entry.raw_obj_ == StubCode::CallNoScopeNative().raw()) ||
                (entry.raw_obj_ == StubCode::CallAutoScopeNative().raw())) {
              // Natives can run while precompiling, becoming linked and
              // switching their stub. Reset to the initial stub used for
              // lazy-linking.
              s->WriteRef(StubCode::CallBootstrapNative().raw());
              break;
            }
#endif
            s->WriteRef(entry.raw_obj_);
            break;
          }
          case ObjectPool::kImmediate: {
            s->Write<intptr_t>(entry.raw_value_);
            break;
          }
          case ObjectPool::kNativeEntryData: {
            RawObject* raw = entry.raw_obj_;
            RawTypedData* raw_data = reinterpret_cast<RawTypedData*>(raw);
            // kNativeEntryData object pool entries are for linking natives for
            // the interpreter. Before writing these entries into the snapshot,
            // we need to unlink them by nulling out the 'trampoline' and
            // 'native_function' fields.
            NativeEntryData::Payload* payload =
                NativeEntryData::FromTypedArray(raw_data);
            if (payload->kind == MethodRecognizer::kUnknown) {
              payload->trampoline = NULL;
              payload->native_function = NULL;
            }
            s->WriteRef(raw);
            break;
          }
          case ObjectPool::kNativeFunction:
          case ObjectPool::kNativeFunctionWrapper: {
            // Write nothing. Will initialize with the lazy link entry.
            break;
          }
          default:
            UNREACHABLE();
        }
      }
    }
  }

 private:
  GrowableArray<RawObjectPool*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ObjectPoolDeserializationCluster : public DeserializationCluster {
 public:
  ObjectPoolDeserializationCluster() {}
  ~ObjectPoolDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, ObjectPool::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    for (intptr_t id = start_index_; id < stop_index_; id += 1) {
      intptr_t length = d->ReadUnsigned();
      RawObjectPool* pool = reinterpret_cast<RawObjectPool*>(d->Ref(id + 0));
      Deserializer::InitializeHeader(
          pool, kObjectPoolCid, ObjectPool::InstanceSize(length), is_vm_object);
      pool->ptr()->length_ = length;
      for (intptr_t j = 0; j < length; j++) {
        const uint8_t entry_bits = d->Read<uint8_t>();
        pool->ptr()->entry_bits()[j] = entry_bits;
        RawObjectPool::Entry& entry = pool->ptr()->data()[j];
        switch (ObjectPool::TypeBits::decode(entry_bits)) {
          case ObjectPool::kNativeEntryData:
          case ObjectPool::kTaggedObject:
            entry.raw_obj_ = d->ReadRef();
            break;
          case ObjectPool::kImmediate:
            entry.raw_value_ = d->Read<intptr_t>();
            break;
          case ObjectPool::kNativeFunction: {
            // Read nothing. Initialize with the lazy link entry.
            uword new_entry = NativeEntry::LinkNativeCallEntry();
            entry.raw_value_ = static_cast<intptr_t>(new_entry);
            break;
          }
#if defined(TARGET_ARCH_DBC)
          case ObjectPool::kNativeFunctionWrapper: {
            // Read nothing. Initialize with the lazy link entry.
            uword new_entry = NativeEntry::BootstrapNativeCallWrapperEntry();
            entry.raw_value_ = static_cast<intptr_t>(new_entry);
            break;
          }
#endif
          default:
            UNREACHABLE();
        }
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
// PcDescriptor, StackMap, OneByteString, TwoByteString
class RODataSerializationCluster : public SerializationCluster {
 public:
  RODataSerializationCluster(const char* name, intptr_t cid)
      : SerializationCluster(name), cid_(cid) {}
  ~RODataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    // A string's hash must already be computed when we write it because it
    // will be loaded into read-only memory. Extra bytes due to allocation
    // rounding need to be deterministically set for reliable deduplication in
    // shared images.
    if (object->IsVMHeapObject()) {
      // This object is already read-only.
    } else {
      Object::FinalizeReadOnlyObject(object);
    }

    uint32_t ignored;
    if (s->GetSharedDataOffset(object, &ignored)) {
      shared_objects_.Add(object);
    } else {
      objects_.Add(object);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = shared_objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawObject* object = shared_objects_[i];
      s->AssignRef(object);
      AutoTraceObject(object);
      uint32_t offset;
      if (!s->GetSharedDataOffset(object, &offset)) {
        UNREACHABLE();
      }
      s->WriteUnsigned(offset);
    }

    count = objects_.length();
    s->WriteUnsigned(count);
    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      RawObject* object = objects_[i];
      s->AssignRef(object);
      AutoTraceObject(object);
      uint32_t offset = s->GetDataOffset(object);
      s->TraceDataOffset(offset);
      ASSERT(Utils::IsAligned(offset, kObjectAlignment));
      ASSERT(offset > running_offset);
      s->WriteUnsigned((offset - running_offset) >> kObjectAlignmentLog2);
      running_offset = offset;
    }
  }

  void WriteFill(Serializer* s) {
    // No-op.
  }

 private:
  const intptr_t cid_;
  GrowableArray<RawObject*> objects_;
  GrowableArray<RawObject*> shared_objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RODataDeserializationCluster : public DeserializationCluster {
 public:
  RODataDeserializationCluster() {}
  ~RODataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      uint32_t offset = d->ReadUnsigned();
      d->AssignRef(d->GetSharedObjectAt(offset));
    }

    count = d->ReadUnsigned();
    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      running_offset += d->ReadUnsigned() << kObjectAlignmentLog2;
      d->AssignRef(d->GetObjectAt(running_offset));
    }
  }

  void ReadFill(Deserializer* d) {
    // No-op.
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ExceptionHandlersSerializationCluster : public SerializationCluster {
 public:
  ExceptionHandlersSerializationCluster()
      : SerializationCluster("ExceptionHandlers") {}
  ~ExceptionHandlersSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawExceptionHandlers* handlers = ExceptionHandlers::RawCast(object);
    objects_.Add(handlers);

    s->Push(handlers->ptr()->handled_types_data_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kExceptionHandlersCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawExceptionHandlers* handlers = objects_[i];
      s->AssignRef(handlers);
      AutoTraceObject(handlers);
      intptr_t length = handlers->ptr()->num_entries_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawExceptionHandlers* handlers = objects_[i];
      AutoTraceObject(handlers);
      intptr_t length = handlers->ptr()->num_entries_;
      s->WriteUnsigned(length);
      s->WriteRef(handlers->ptr()->handled_types_data_);
      for (intptr_t j = 0; j < length; j++) {
        const ExceptionHandlerInfo& info = handlers->ptr()->data()[j];
        s->Write<uint32_t>(info.handler_pc_offset);
        s->Write<int16_t>(info.outer_try_index);
        s->Write<int8_t>(info.needs_stacktrace);
        s->Write<int8_t>(info.has_catch_all);
        s->Write<int8_t>(info.is_generated);
      }
    }
  }

 private:
  GrowableArray<RawExceptionHandlers*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExceptionHandlersDeserializationCluster : public DeserializationCluster {
 public:
  ExceptionHandlersDeserializationCluster() {}
  ~ExceptionHandlersDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(
          old_space, ExceptionHandlers::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawExceptionHandlers* handlers =
          reinterpret_cast<RawExceptionHandlers*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(handlers, kExceptionHandlersCid,
                                     ExceptionHandlers::InstanceSize(length),
                                     is_vm_object);
      handlers->ptr()->num_entries_ = length;
      handlers->ptr()->handled_types_data_ =
          reinterpret_cast<RawArray*>(d->ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        ExceptionHandlerInfo& info = handlers->ptr()->data()[j];
        info.handler_pc_offset = d->Read<uint32_t>();
        info.outer_try_index = d->Read<int16_t>();
        info.needs_stacktrace = d->Read<int8_t>();
        info.has_catch_all = d->Read<int8_t>();
        info.is_generated = d->Read<int8_t>();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ContextSerializationCluster : public SerializationCluster {
 public:
  ContextSerializationCluster() : SerializationCluster("Context") {}
  ~ContextSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawContext* context = Context::RawCast(object);
    objects_.Add(context);

    s->Push(context->ptr()->parent_);
    intptr_t length = context->ptr()->num_variables_;
    for (intptr_t i = 0; i < length; i++) {
      s->Push(context->ptr()->data()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kContextCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawContext* context = objects_[i];
      s->AssignRef(context);
      AutoTraceObject(context);
      intptr_t length = context->ptr()->num_variables_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawContext* context = objects_[i];
      AutoTraceObject(context);
      intptr_t length = context->ptr()->num_variables_;
      s->WriteUnsigned(length);
      s->WriteRef(context->ptr()->parent_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(context->ptr()->data()[j]);
      }
    }
  }

 private:
  GrowableArray<RawContext*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ContextDeserializationCluster : public DeserializationCluster {
 public:
  ContextDeserializationCluster() {}
  ~ContextDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, Context::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawContext* context = reinterpret_cast<RawContext*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(
          context, kContextCid, Context::InstanceSize(length), is_vm_object);
      context->ptr()->num_variables_ = length;
      context->ptr()->parent_ = reinterpret_cast<RawContext*>(d->ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        context->ptr()->data()[j] = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ContextScopeSerializationCluster : public SerializationCluster {
 public:
  ContextScopeSerializationCluster() : SerializationCluster("ContextScope") {}
  ~ContextScopeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawContextScope* scope = ContextScope::RawCast(object);
    objects_.Add(scope);

    intptr_t length = scope->ptr()->num_variables_;
    PushFromTo(scope, length);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kContextScopeCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawContextScope* scope = objects_[i];
      s->AssignRef(scope);
      AutoTraceObject(scope);
      intptr_t length = scope->ptr()->num_variables_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawContextScope* scope = objects_[i];
      AutoTraceObject(scope);
      intptr_t length = scope->ptr()->num_variables_;
      s->WriteUnsigned(length);
      s->Write<bool>(scope->ptr()->is_implicit_);
      WriteFromTo(scope, length);
    }
  }

 private:
  GrowableArray<RawContextScope*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ContextScopeDeserializationCluster : public DeserializationCluster {
 public:
  ContextScopeDeserializationCluster() {}
  ~ContextScopeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, ContextScope::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawContextScope* scope = reinterpret_cast<RawContextScope*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(scope, kContextScopeCid,
                                     ContextScope::InstanceSize(length),
                                     is_vm_object);
      scope->ptr()->num_variables_ = length;
      scope->ptr()->is_implicit_ = d->Read<bool>();
      ReadFromTo(scope, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnlinkedCallSerializationCluster : public SerializationCluster {
 public:
  UnlinkedCallSerializationCluster() : SerializationCluster("UnlinkedCall") {}
  ~UnlinkedCallSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawUnlinkedCall* unlinked = UnlinkedCall::RawCast(object);
    objects_.Add(unlinked);
    PushFromTo(unlinked);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnlinkedCallCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnlinkedCall* unlinked = objects_[i];
      s->AssignRef(unlinked);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawUnlinkedCall* unlinked = objects_[i];
      AutoTraceObject(unlinked);
      WriteFromTo(unlinked);
    }
  }

 private:
  GrowableArray<RawUnlinkedCall*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnlinkedCallDeserializationCluster : public DeserializationCluster {
 public:
  UnlinkedCallDeserializationCluster() {}
  ~UnlinkedCallDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, UnlinkedCall::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawUnlinkedCall* unlinked =
          reinterpret_cast<RawUnlinkedCall*>(d->Ref(id));
      Deserializer::InitializeHeader(unlinked, kUnlinkedCallCid,
                                     UnlinkedCall::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(unlinked);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ICDataSerializationCluster : public SerializationCluster {
 public:
  ICDataSerializationCluster() : SerializationCluster("ICData") {}
  ~ICDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawICData* ic = ICData::RawCast(object);
    objects_.Add(ic);
    PushFromTo(ic);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kICDataCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawICData* ic = objects_[i];
      s->AssignRef(ic);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawICData* ic = objects_[i];
      AutoTraceObject(ic);
      WriteFromTo(ic);
      if (kind != Snapshot::kFullAOT) {
        NOT_IN_PRECOMPILED(s->Write<int32_t>(ic->ptr()->deopt_id_));
      }
      s->Write<uint32_t>(ic->ptr()->state_bits_);
#if defined(TAG_IC_DATA)
      s->Write<int32_t>(static_cast<int32_t>(ic->ptr()->tag_));
#endif
    }
  }

 private:
  GrowableArray<RawICData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ICDataDeserializationCluster : public DeserializationCluster {
 public:
  ICDataDeserializationCluster() {}
  ~ICDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, ICData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawICData* ic = reinterpret_cast<RawICData*>(d->Ref(id));
      Deserializer::InitializeHeader(ic, kICDataCid, ICData::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(ic);
      NOT_IN_PRECOMPILED(ic->ptr()->deopt_id_ = d->Read<int32_t>());
      ic->ptr()->state_bits_ = d->Read<int32_t>();
#if defined(TAG_IC_DATA)
      ic->ptr()->tag_ = static_cast<ICData::Tag>(d->Read<int32_t>());
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MegamorphicCacheSerializationCluster : public SerializationCluster {
 public:
  MegamorphicCacheSerializationCluster()
      : SerializationCluster("MegamorphicCache") {}
  ~MegamorphicCacheSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawMegamorphicCache* cache = MegamorphicCache::RawCast(object);
    objects_.Add(cache);
    PushFromTo(cache);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kMegamorphicCacheCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawMegamorphicCache* cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawMegamorphicCache* cache = objects_[i];
      AutoTraceObject(cache);
      WriteFromTo(cache);
      s->Write<int32_t>(cache->ptr()->filled_entry_count_);
    }
  }

 private:
  GrowableArray<RawMegamorphicCache*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MegamorphicCacheDeserializationCluster : public DeserializationCluster {
 public:
  MegamorphicCacheDeserializationCluster() {}
  ~MegamorphicCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, MegamorphicCache::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawMegamorphicCache* cache =
          reinterpret_cast<RawMegamorphicCache*>(d->Ref(id));
      Deserializer::InitializeHeader(cache, kMegamorphicCacheCid,
                                     MegamorphicCache::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(cache);
      cache->ptr()->filled_entry_count_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SubtypeTestCacheSerializationCluster : public SerializationCluster {
 public:
  SubtypeTestCacheSerializationCluster()
      : SerializationCluster("SubtypeTestCache") {}
  ~SubtypeTestCacheSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawSubtypeTestCache* cache = SubtypeTestCache::RawCast(object);
    objects_.Add(cache);
    s->Push(cache->ptr()->cache_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSubtypeTestCacheCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawSubtypeTestCache* cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawSubtypeTestCache* cache = objects_[i];
      AutoTraceObject(cache);
      s->WriteRef(cache->ptr()->cache_);
    }
  }

 private:
  GrowableArray<RawSubtypeTestCache*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SubtypeTestCacheDeserializationCluster : public DeserializationCluster {
 public:
  SubtypeTestCacheDeserializationCluster() {}
  ~SubtypeTestCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, SubtypeTestCache::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawSubtypeTestCache* cache =
          reinterpret_cast<RawSubtypeTestCache*>(d->Ref(id));
      Deserializer::InitializeHeader(cache, kSubtypeTestCacheCid,
                                     SubtypeTestCache::InstanceSize(),
                                     is_vm_object);
      cache->ptr()->cache_ = reinterpret_cast<RawArray*>(d->ReadRef());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LanguageErrorSerializationCluster : public SerializationCluster {
 public:
  LanguageErrorSerializationCluster() : SerializationCluster("LanguageError") {}
  ~LanguageErrorSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLanguageError* error = LanguageError::RawCast(object);
    objects_.Add(error);
    PushFromTo(error);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLanguageErrorCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLanguageError* error = objects_[i];
      s->AssignRef(error);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLanguageError* error = objects_[i];
      AutoTraceObject(error);
      WriteFromTo(error);
      s->WriteTokenPosition(error->ptr()->token_pos_);
      s->Write<bool>(error->ptr()->report_after_token_);
      s->Write<int8_t>(error->ptr()->kind_);
    }
  }

 private:
  GrowableArray<RawLanguageError*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LanguageErrorDeserializationCluster : public DeserializationCluster {
 public:
  LanguageErrorDeserializationCluster() {}
  ~LanguageErrorDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LanguageError::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLanguageError* error = reinterpret_cast<RawLanguageError*>(d->Ref(id));
      Deserializer::InitializeHeader(error, kLanguageErrorCid,
                                     LanguageError::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(error);
      error->ptr()->token_pos_ = d->ReadTokenPosition();
      error->ptr()->report_after_token_ = d->Read<bool>();
      error->ptr()->kind_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnhandledExceptionSerializationCluster : public SerializationCluster {
 public:
  UnhandledExceptionSerializationCluster()
      : SerializationCluster("UnhandledException") {}
  ~UnhandledExceptionSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawUnhandledException* exception = UnhandledException::RawCast(object);
    objects_.Add(exception);
    PushFromTo(exception);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnhandledExceptionCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnhandledException* exception = objects_[i];
      s->AssignRef(exception);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawUnhandledException* exception = objects_[i];
      AutoTraceObject(exception);
      WriteFromTo(exception);
    }
  }

 private:
  GrowableArray<RawUnhandledException*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnhandledExceptionDeserializationCluster : public DeserializationCluster {
 public:
  UnhandledExceptionDeserializationCluster() {}
  ~UnhandledExceptionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, UnhandledException::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawUnhandledException* exception =
          reinterpret_cast<RawUnhandledException*>(d->Ref(id));
      Deserializer::InitializeHeader(exception, kUnhandledExceptionCid,
                                     UnhandledException::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(exception);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class InstanceSerializationCluster : public SerializationCluster {
 public:
  explicit InstanceSerializationCluster(intptr_t cid)
      : SerializationCluster("Instance"), cid_(cid) {
    RawClass* cls = Isolate::Current()->class_table()->At(cid);
    next_field_offset_in_words_ = cls->ptr()->next_field_offset_in_words_;
    instance_size_in_words_ = cls->ptr()->instance_size_in_words_;
    ASSERT(next_field_offset_in_words_ > 0);
    ASSERT(instance_size_in_words_ > 0);
  }
  ~InstanceSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawInstance* instance = Instance::RawCast(object);
    objects_.Add(instance);

    intptr_t next_field_offset = next_field_offset_in_words_ << kWordSizeLog2;
    intptr_t offset = Instance::NextFieldOffset();
    while (offset < next_field_offset) {
      RawObject* raw_obj = *reinterpret_cast<RawObject**>(
          reinterpret_cast<uword>(instance->ptr()) + offset);
      s->Push(raw_obj);
      offset += kWordSize;
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);

    s->Write<int32_t>(next_field_offset_in_words_);
    s->Write<int32_t>(instance_size_in_words_);

    for (intptr_t i = 0; i < count; i++) {
      RawInstance* instance = objects_[i];
      s->AssignRef(instance);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t next_field_offset = next_field_offset_in_words_ << kWordSizeLog2;
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawInstance* instance = objects_[i];
      AutoTraceObject(instance);
      s->Write<bool>(instance->IsCanonical());
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        RawObject* raw_obj = *reinterpret_cast<RawObject**>(
            reinterpret_cast<uword>(instance->ptr()) + offset);
        s->WriteRef(raw_obj);
        offset += kWordSize;
      }
    }
  }

 private:
  const intptr_t cid_;
  intptr_t next_field_offset_in_words_;
  intptr_t instance_size_in_words_;
  GrowableArray<RawInstance*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class InstanceDeserializationCluster : public DeserializationCluster {
 public:
  explicit InstanceDeserializationCluster(intptr_t cid) : cid_(cid) {}
  ~InstanceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    next_field_offset_in_words_ = d->Read<int32_t>();
    instance_size_in_words_ = d->Read<int32_t>();
    intptr_t instance_size =
        Object::RoundedAllocationSize(instance_size_in_words_ * kWordSize);
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, instance_size));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    intptr_t next_field_offset = next_field_offset_in_words_ << kWordSizeLog2;
    intptr_t instance_size =
        Object::RoundedAllocationSize(instance_size_in_words_ * kWordSize);
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawInstance* instance = reinterpret_cast<RawInstance*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(instance, cid_, instance_size,
                                     is_vm_object, is_canonical);
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        RawObject** p = reinterpret_cast<RawObject**>(
            reinterpret_cast<uword>(instance->ptr()) + offset);
        *p = d->ReadRef();
        offset += kWordSize;
      }
      if (offset < instance_size) {
        RawObject** p = reinterpret_cast<RawObject**>(
            reinterpret_cast<uword>(instance->ptr()) + offset);
        *p = Object::null();
        offset += kWordSize;
      }
      ASSERT(offset == instance_size);
    }
  }

 private:
  const intptr_t cid_;
  intptr_t next_field_offset_in_words_;
  intptr_t instance_size_in_words_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LibraryPrefixSerializationCluster : public SerializationCluster {
 public:
  LibraryPrefixSerializationCluster() : SerializationCluster("LibraryPrefix") {}
  ~LibraryPrefixSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLibraryPrefix* prefix = LibraryPrefix::RawCast(object);
    objects_.Add(prefix);
    PushFromTo(prefix);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryPrefixCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLibraryPrefix* prefix = objects_[i];
      s->AssignRef(prefix);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLibraryPrefix* prefix = objects_[i];
      AutoTraceObject(prefix);
      WriteFromTo(prefix);
      s->Write<uint16_t>(prefix->ptr()->num_imports_);
      s->Write<bool>(prefix->ptr()->is_deferred_load_);
    }
  }

 private:
  GrowableArray<RawLibraryPrefix*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LibraryPrefixDeserializationCluster : public DeserializationCluster {
 public:
  LibraryPrefixDeserializationCluster() {}
  ~LibraryPrefixDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LibraryPrefix::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLibraryPrefix* prefix =
          reinterpret_cast<RawLibraryPrefix*>(d->Ref(id));
      Deserializer::InitializeHeader(prefix, kLibraryPrefixCid,
                                     LibraryPrefix::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(prefix);
      prefix->ptr()->num_imports_ = d->Read<uint16_t>();
      prefix->ptr()->is_deferred_load_ = d->Read<bool>();
      prefix->ptr()->is_loaded_ = !prefix->ptr()->is_deferred_load_;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeSerializationCluster : public SerializationCluster {
 public:
  explicit TypeSerializationCluster(const TypeTestingStubFinder& ttsf)
      : SerializationCluster("Type"), type_testing_stubs_(ttsf) {}
  ~TypeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawType* type = Type::RawCast(object);
    if (type->IsCanonical()) {
      canonical_objects_.Add(type);
    } else {
      objects_.Add(type);
    }

    PushFromTo(type);

    if (type->ptr()->type_class_id_->IsHeapObject()) {
      // Type class is still an unresolved class.
      UNREACHABLE();
    }

    RawSmi* raw_type_class_id = Smi::RawCast(type->ptr()->type_class_id_);
    RawClass* type_class =
        s->isolate()->class_table()->At(Smi::Value(raw_type_class_id));
    s->Push(type_class);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeCid);
    intptr_t count = canonical_objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = canonical_objects_[i];
      s->AssignRef(type);
    }
    count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    const bool is_vm_isolate = s->isolate() == Dart::vm_isolate();
    const bool should_write_type_testing_stub =
        SnapshotContainsTypeTestingStubs(s->kind());

    intptr_t count = canonical_objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = canonical_objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int8_t>(type->ptr()->type_state_);
      if (should_write_type_testing_stub) {
        RawInstructions* instr = type_testing_stubs_.LookupByAddresss(
            type->ptr()->type_test_stub_entry_point_);
        s->WriteInstructions(instr, Code::null());
      }
    }
    count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int8_t>(type->ptr()->type_state_);
      if (should_write_type_testing_stub) {
        RawInstructions* instr = type_testing_stubs_.LookupByAddresss(
            type->ptr()->type_test_stub_entry_point_);
        s->WriteInstructions(instr, Code::null());
      }
    }

    // The dynamic/void objects are not serialized, so we manually send
    // the type testing stub for it.
    if (should_write_type_testing_stub && is_vm_isolate) {
      RawInstructions* dynamic_instr = type_testing_stubs_.LookupByAddresss(
          Type::dynamic_type().type_test_stub_entry_point());
      s->WriteInstructions(dynamic_instr, Code::null());

      RawInstructions* void_instr = type_testing_stubs_.LookupByAddresss(
          Type::void_type().type_test_stub_entry_point());
      s->WriteInstructions(void_instr, Code::null());
    }
  }

 private:
  GrowableArray<RawType*> canonical_objects_;
  GrowableArray<RawType*> objects_;
  const TypeTestingStubFinder& type_testing_stubs_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeDeserializationCluster : public DeserializationCluster {
 public:
  TypeDeserializationCluster()
      : type_(AbstractType::Handle()), instr_(Instructions::Handle()) {}
  ~TypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    canonical_start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Type::InstanceSize()));
    }
    canonical_stop_index_ = d->next_index();

    start_index_ = d->next_index();
    count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Type::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    const bool is_vm_isolate = d->isolate() == Dart::vm_isolate();
    const bool should_read_type_testing_stub =
        SnapshotContainsTypeTestingStubs(d->kind());

    for (intptr_t id = canonical_start_index_; id < canonical_stop_index_;
         id++) {
      RawType* type = reinterpret_cast<RawType*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_vm_isolate, true);
      ReadFromTo(type);
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->type_state_ = d->Read<int8_t>();
      if (should_read_type_testing_stub) {
        instr_ = d->ReadInstructions();
        type_ = type;
        type_.SetTypeTestingStub(instr_);
      }
    }

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawType* type = reinterpret_cast<RawType*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_vm_isolate);
      ReadFromTo(type);
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->type_state_ = d->Read<int8_t>();
      if (should_read_type_testing_stub) {
        instr_ = d->ReadInstructions();
        type_ = type;
        type_.SetTypeTestingStub(instr_);
      }
    }

    // The dynamic/void objects are not serialized, so we manually send
    // the type testing stub for it.
    if (should_read_type_testing_stub && is_vm_isolate) {
      instr_ = d->ReadInstructions();
      Type::dynamic_type().SetTypeTestingStub(instr_);
      instr_ = d->ReadInstructions();
      Type::void_type().SetTypeTestingStub(instr_);
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    if (!SnapshotContainsTypeTestingStubs(kind)) {
      for (intptr_t id = canonical_start_index_; id < canonical_stop_index_;
           id++) {
        type_ ^= refs.At(id);
        instr_ = TypeTestingStubGenerator::DefaultCodeForType(type_);
        type_.SetTypeTestingStub(instr_);
      }
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_ ^= refs.At(id);
        instr_ = TypeTestingStubGenerator::DefaultCodeForType(type_);
        type_.SetTypeTestingStub(instr_);
      }
    }
  }

 private:
  intptr_t canonical_start_index_;
  intptr_t canonical_stop_index_;
  AbstractType& type_;
  Instructions& instr_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeRefSerializationCluster : public SerializationCluster {
 public:
  explicit TypeRefSerializationCluster(const TypeTestingStubFinder& ttsf)
      : SerializationCluster("TypeRef"), type_testing_stubs_(ttsf) {}
  ~TypeRefSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypeRef* type = TypeRef::RawCast(object);
    objects_.Add(type);
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeRefCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeRef* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    const bool should_write_type_testing_stub =
        SnapshotContainsTypeTestingStubs(s->kind());

    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeRef* type = objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
      if (should_write_type_testing_stub) {
        RawInstructions* instr = type_testing_stubs_.LookupByAddresss(
            type->ptr()->type_test_stub_entry_point_);
        s->WriteInstructions(instr, Code::null());
      }
    }
  }

 private:
  GrowableArray<RawTypeRef*> objects_;
  const TypeTestingStubFinder& type_testing_stubs_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeRefDeserializationCluster : public DeserializationCluster {
 public:
  TypeRefDeserializationCluster()
      : type_(AbstractType::Handle()), instr_(Instructions::Handle()) {}
  ~TypeRefDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, TypeRef::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    const bool is_vm_object = d->isolate() == Dart::vm_isolate();
    const bool should_read_type_testing_stub =
        SnapshotContainsTypeTestingStubs(d->kind());

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypeRef* type = reinterpret_cast<RawTypeRef*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeRefCid, TypeRef::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(type);
      if (should_read_type_testing_stub) {
        instr_ = d->ReadInstructions();
        type_ = type;
        type_.SetTypeTestingStub(instr_);
      }
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    if (!SnapshotContainsTypeTestingStubs(kind)) {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_ ^= refs.At(id);
        instr_ = TypeTestingStubGenerator::DefaultCodeForType(type_);
        type_.SetTypeTestingStub(instr_);
      }
    }
  }

 private:
  AbstractType& type_;
  Instructions& instr_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeParameterSerializationCluster : public SerializationCluster {
 public:
  explicit TypeParameterSerializationCluster(const TypeTestingStubFinder& ttsf)
      : SerializationCluster("TypeParameter"), type_testing_stubs_(ttsf) {}

  ~TypeParameterSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypeParameter* type = TypeParameter::RawCast(object);
    objects_.Add(type);
    ASSERT(!type->IsCanonical());
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeParameterCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeParameter* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    const bool should_write_type_testing_stub =
        SnapshotContainsTypeTestingStubs(s->kind());

    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeParameter* type = objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
      s->Write<int32_t>(type->ptr()->parameterized_class_id_);
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int16_t>(type->ptr()->index_);
      s->Write<int8_t>(type->ptr()->type_state_);
      if (should_write_type_testing_stub) {
        RawInstructions* instr = type_testing_stubs_.LookupByAddresss(
            type->ptr()->type_test_stub_entry_point_);
        s->WriteInstructions(instr, Code::null());
      }
    }
  }

 private:
  GrowableArray<RawTypeParameter*> objects_;
  const TypeTestingStubFinder& type_testing_stubs_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeParameterDeserializationCluster : public DeserializationCluster {
 public:
  TypeParameterDeserializationCluster()
      : type_(AbstractType::Handle()), instr_(Instructions::Handle()) {}
  ~TypeParameterDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, TypeParameter::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    const bool should_read_type_testing_stub =
        SnapshotContainsTypeTestingStubs(d->kind());

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypeParameter* type = reinterpret_cast<RawTypeParameter*>(d->Ref(id));
      Deserializer::InitializeHeader(
          type, kTypeParameterCid, TypeParameter::InstanceSize(), is_vm_object);
      ReadFromTo(type);
      type->ptr()->parameterized_class_id_ = d->Read<int32_t>();
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->index_ = d->Read<int16_t>();
      type->ptr()->type_state_ = d->Read<int8_t>();
      if (should_read_type_testing_stub) {
        instr_ = d->ReadInstructions();
        type_ = type;
        type_.SetTypeTestingStub(instr_);
      }
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    if (!SnapshotContainsTypeTestingStubs(kind)) {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_ ^= refs.At(id);
        instr_ = TypeTestingStubGenerator::DefaultCodeForType(type_);
        type_.SetTypeTestingStub(instr_);
      }
    }
  }

 private:
  AbstractType& type_;
  Instructions& instr_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class BoundedTypeSerializationCluster : public SerializationCluster {
 public:
  BoundedTypeSerializationCluster() : SerializationCluster("BoundedType") {}
  ~BoundedTypeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawBoundedType* type = BoundedType::RawCast(object);
    objects_.Add(type);
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kBoundedTypeCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawBoundedType* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawBoundedType* type = objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
    }
  }

 private:
  GrowableArray<RawBoundedType*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class BoundedTypeDeserializationCluster : public DeserializationCluster {
 public:
  BoundedTypeDeserializationCluster() {}
  ~BoundedTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, BoundedType::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawBoundedType* type = reinterpret_cast<RawBoundedType*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kBoundedTypeCid,
                                     BoundedType::InstanceSize(), is_vm_object);
      ReadFromTo(type);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureSerializationCluster : public SerializationCluster {
 public:
  ClosureSerializationCluster() : SerializationCluster("Closure") {}
  ~ClosureSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawClosure* closure = Closure::RawCast(object);
    objects_.Add(closure);
    PushFromTo(closure);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClosureCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClosure* closure = objects_[i];
      s->AssignRef(closure);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawClosure* closure = objects_[i];
      AutoTraceObject(closure);
      s->Write<bool>(closure->IsCanonical());
      WriteFromTo(closure);
    }
  }

 private:
  GrowableArray<RawClosure*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClosureDeserializationCluster : public DeserializationCluster {
 public:
  ClosureDeserializationCluster() {}
  ~ClosureDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Closure::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawClosure* closure = reinterpret_cast<RawClosure*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(closure, kClosureCid,
                                     Closure::InstanceSize(), is_vm_object,
                                     is_canonical);
      ReadFromTo(closure);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MintSerializationCluster : public SerializationCluster {
 public:
  MintSerializationCluster() : SerializationCluster("Mint") {}
  ~MintSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    if (!object->IsHeapObject()) {
      RawSmi* smi = Smi::RawCast(object);
      smis_.Add(smi);
    } else {
      RawMint* mint = Mint::RawCast(object);
      mints_.Add(mint);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kMintCid);

    s->WriteUnsigned(smis_.length() + mints_.length());
    for (intptr_t i = 0; i < smis_.length(); i++) {
      RawSmi* smi = smis_[i];
      s->AssignRef(smi);
      AutoTraceObject(smi);
      s->Write<bool>(true);
      s->Write<int64_t>(Smi::Value(smi));
    }
    for (intptr_t i = 0; i < mints_.length(); i++) {
      RawMint* mint = mints_[i];
      s->AssignRef(mint);
      AutoTraceObject(mint);
      s->Write<bool>(mint->IsCanonical());
      s->Write<int64_t>(mint->ptr()->value_);
    }
  }

  void WriteFill(Serializer* s) {}

 private:
  GrowableArray<RawSmi*> smis_;
  GrowableArray<RawMint*> mints_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MintDeserializationCluster : public DeserializationCluster {
 public:
  MintDeserializationCluster() {}
  ~MintDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    PageSpace* old_space = d->heap()->old_space();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    start_index_ = d->next_index();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      bool is_canonical = d->Read<bool>();
      int64_t value = d->Read<int64_t>();
      if (Smi::IsValid(value)) {
        d->AssignRef(Smi::New(value));
      } else {
        RawMint* mint = static_cast<RawMint*>(
            AllocateUninitialized(old_space, Mint::InstanceSize()));
        Deserializer::InitializeHeader(mint, kMintCid, Mint::InstanceSize(),
                                       is_vm_object, is_canonical);
        mint->ptr()->value_ = value;
        d->AssignRef(mint);
      }
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {}

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        Thread::Current(), Timeline::GetIsolateStream(), "PostLoadMint"));

    const Class& mint_cls =
        Class::Handle(zone, Isolate::Current()->object_store()->mint_class());
    mint_cls.set_constants(Object::empty_array());
    Object& number = Object::Handle(zone);
    for (intptr_t i = start_index_; i < stop_index_; i++) {
      number = refs.At(i);
      if (number.IsMint() && number.IsCanonical()) {
        mint_cls.InsertCanonicalMint(zone, Mint::Cast(number));
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class DoubleSerializationCluster : public SerializationCluster {
 public:
  DoubleSerializationCluster() : SerializationCluster("Double") {}
  ~DoubleSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawDouble* dbl = Double::RawCast(object);
    objects_.Add(dbl);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kDoubleCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawDouble* dbl = objects_[i];
      s->AssignRef(dbl);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawDouble* dbl = objects_[i];
      AutoTraceObject(dbl);
      s->Write<bool>(dbl->IsCanonical());
      s->Write<double>(dbl->ptr()->value_);
    }
  }

 private:
  GrowableArray<RawDouble*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class DoubleDeserializationCluster : public DeserializationCluster {
 public:
  DoubleDeserializationCluster() {}
  ~DoubleDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Double::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawDouble* dbl = reinterpret_cast<RawDouble*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(dbl, kDoubleCid, Double::InstanceSize(),
                                     is_vm_object, is_canonical);
      dbl->ptr()->value_ = d->Read<double>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class GrowableObjectArraySerializationCluster : public SerializationCluster {
 public:
  GrowableObjectArraySerializationCluster()
      : SerializationCluster("GrowableObjectArray") {}
  ~GrowableObjectArraySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawGrowableObjectArray* array = GrowableObjectArray::RawCast(object);
    objects_.Add(array);
    PushFromTo(array);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kGrowableObjectArrayCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawGrowableObjectArray* array = objects_[i];
      s->AssignRef(array);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawGrowableObjectArray* array = objects_[i];
      AutoTraceObject(array);
      s->Write<bool>(array->IsCanonical());
      WriteFromTo(array);
    }
  }

 private:
  GrowableArray<RawGrowableObjectArray*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class GrowableObjectArrayDeserializationCluster
    : public DeserializationCluster {
 public:
  GrowableObjectArrayDeserializationCluster() {}
  ~GrowableObjectArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space,
                                         GrowableObjectArray::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawGrowableObjectArray* list =
          reinterpret_cast<RawGrowableObjectArray*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(list, kGrowableObjectArrayCid,
                                     GrowableObjectArray::InstanceSize(),
                                     is_vm_object, is_canonical);
      ReadFromTo(list);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypedDataSerializationCluster : public SerializationCluster {
 public:
  explicit TypedDataSerializationCluster(intptr_t cid)
      : SerializationCluster("TypedData"), cid_(cid) {}
  ~TypedDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypedData* data = TypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypedData* data = objects_[i];
      s->AssignRef(data);
      AutoTraceObject(data);
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      RawTypedData* data = objects_[i];
      AutoTraceObject(data);
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
      s->Write<bool>(data->IsCanonical());
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data());
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  const intptr_t cid_;
  GrowableArray<RawTypedData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit TypedDataDeserializationCluster(intptr_t cid) : cid_(cid) {}
  ~TypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(
          old_space, TypedData::InstanceSize(length * element_size)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypedData* data = reinterpret_cast<RawTypedData*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      bool is_canonical = d->Read<bool>();
      intptr_t length_in_bytes = length * element_size;
      Deserializer::InitializeHeader(data, cid_,
                                     TypedData::InstanceSize(length_in_bytes),
                                     is_vm_object, is_canonical);
      data->ptr()->length_ = Smi::New(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data());
      d->ReadBytes(cdata, length_in_bytes);
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ExternalTypedDataSerializationCluster : public SerializationCluster {
 public:
  explicit ExternalTypedDataSerializationCluster(intptr_t cid)
      : SerializationCluster("ExternalTypedData"), cid_(cid) {}
  ~ExternalTypedDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawExternalTypedData* data = ExternalTypedData::RawCast(object);
    objects_.Add(data);
    ASSERT(!data->IsCanonical());
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawExternalTypedData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      RawExternalTypedData* data = objects_[i];
      AutoTraceObject(data);
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data_);
      s->Align(ExternalTypedData::kDataSerializationAlignment);
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  const intptr_t cid_;
  GrowableArray<RawExternalTypedData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExternalTypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit ExternalTypedDataDeserializationCluster(intptr_t cid) : cid_(cid) {}
  ~ExternalTypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, ExternalTypedData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawExternalTypedData* data =
          reinterpret_cast<RawExternalTypedData*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(
          data, cid_, ExternalTypedData::InstanceSize(), is_vm_object);
      data->ptr()->length_ = Smi::New(length);
      d->Align(ExternalTypedData::kDataSerializationAlignment);
      data->ptr()->data_ = const_cast<uint8_t*>(d->CurrentBufferAddress());
      d->Advance(length * element_size);
      // No finalizer / external size 0.
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class StackTraceSerializationCluster : public SerializationCluster {
 public:
  StackTraceSerializationCluster() : SerializationCluster("StackTrace") {}
  ~StackTraceSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawStackTrace* trace = StackTrace::RawCast(object);
    objects_.Add(trace);
    PushFromTo(trace);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kStackTraceCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawStackTrace* trace = objects_[i];
      s->AssignRef(trace);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawStackTrace* trace = objects_[i];
      AutoTraceObject(trace);
      WriteFromTo(trace);
    }
  }

 private:
  GrowableArray<RawStackTrace*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class StackTraceDeserializationCluster : public DeserializationCluster {
 public:
  StackTraceDeserializationCluster() {}
  ~StackTraceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, StackTrace::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawStackTrace* trace = reinterpret_cast<RawStackTrace*>(d->Ref(id));
      Deserializer::InitializeHeader(trace, kStackTraceCid,
                                     StackTrace::InstanceSize(), is_vm_object);
      ReadFromTo(trace);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RegExpSerializationCluster : public SerializationCluster {
 public:
  RegExpSerializationCluster() : SerializationCluster("RegExp") {}
  ~RegExpSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawRegExp* regexp = RegExp::RawCast(object);
    objects_.Add(regexp);
    PushFromTo(regexp);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kRegExpCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawRegExp* regexp = objects_[i];
      s->AssignRef(regexp);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawRegExp* regexp = objects_[i];
      AutoTraceObject(regexp);
      WriteFromTo(regexp);
      s->Write<int32_t>(regexp->ptr()->num_registers_);
      s->Write<int8_t>(regexp->ptr()->type_flags_);
    }
  }

 private:
  GrowableArray<RawRegExp*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RegExpDeserializationCluster : public DeserializationCluster {
 public:
  RegExpDeserializationCluster() {}
  ~RegExpDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, RegExp::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawRegExp* regexp = reinterpret_cast<RawRegExp*>(d->Ref(id));
      Deserializer::InitializeHeader(regexp, kRegExpCid, RegExp::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(regexp);
      regexp->ptr()->num_registers_ = d->Read<int32_t>();
      regexp->ptr()->type_flags_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class WeakPropertySerializationCluster : public SerializationCluster {
 public:
  WeakPropertySerializationCluster() : SerializationCluster("WeakProperty") {}
  ~WeakPropertySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawWeakProperty* property = WeakProperty::RawCast(object);
    objects_.Add(property);
    PushFromTo(property);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kWeakPropertyCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawWeakProperty* property = objects_[i];
      s->AssignRef(property);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawWeakProperty* property = objects_[i];
      AutoTraceObject(property);
      WriteFromTo(property);
    }
  }

 private:
  GrowableArray<RawWeakProperty*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class WeakPropertyDeserializationCluster : public DeserializationCluster {
 public:
  WeakPropertyDeserializationCluster() {}
  ~WeakPropertyDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, WeakProperty::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawWeakProperty* property =
          reinterpret_cast<RawWeakProperty*>(d->Ref(id));
      Deserializer::InitializeHeader(property, kWeakPropertyCid,
                                     WeakProperty::InstanceSize(),
                                     is_vm_object);
      ReadFromTo(property);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LinkedHashMapSerializationCluster : public SerializationCluster {
 public:
  LinkedHashMapSerializationCluster() : SerializationCluster("LinkedHashMap") {}
  ~LinkedHashMapSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLinkedHashMap* map = LinkedHashMap::RawCast(object);
    objects_.Add(map);

    s->Push(map->ptr()->type_arguments_);

    intptr_t used_data = Smi::Value(map->ptr()->used_data_);
    RawArray* data_array = map->ptr()->data_;
    RawObject** data_elements = data_array->ptr()->data();
    for (intptr_t i = 0; i < used_data; i += 2) {
      RawObject* key = data_elements[i];
      if (key != data_array) {
        RawObject* value = data_elements[i + 1];
        s->Push(key);
        s->Push(value);
      }
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLinkedHashMapCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLinkedHashMap* map = objects_[i];
      s->AssignRef(map);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLinkedHashMap* map = objects_[i];
      AutoTraceObject(map);
      s->Write<bool>(map->IsCanonical());

      s->WriteRef(map->ptr()->type_arguments_);

      const intptr_t used_data = Smi::Value(map->ptr()->used_data_);
      ASSERT((used_data & 1) == 0);  // Keys + values, so must be even.
      const intptr_t deleted_keys = Smi::Value(map->ptr()->deleted_keys_);

      // Write out the number of (not deleted) key/value pairs that will follow.
      s->Write<int32_t>((used_data >> 1) - deleted_keys);

      RawArray* data_array = map->ptr()->data_;
      RawObject** data_elements = data_array->ptr()->data();
      for (intptr_t i = 0; i < used_data; i += 2) {
        RawObject* key = data_elements[i];
        if (key != data_array) {
          RawObject* value = data_elements[i + 1];
          s->WriteRef(key);
          s->WriteRef(value);
        }
      }
    }
  }

 private:
  GrowableArray<RawLinkedHashMap*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LinkedHashMapDeserializationCluster : public DeserializationCluster {
 public:
  LinkedHashMapDeserializationCluster() {}
  ~LinkedHashMapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LinkedHashMap::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    PageSpace* old_space = d->heap()->old_space();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLinkedHashMap* map = reinterpret_cast<RawLinkedHashMap*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(map, kLinkedHashMapCid,
                                     LinkedHashMap::InstanceSize(),
                                     is_vm_object, is_canonical);

      map->ptr()->type_arguments_ =
          reinterpret_cast<RawTypeArguments*>(d->ReadRef());

      // TODO(rmacnak): Reserve ref ids and co-allocate in ReadAlloc.
      intptr_t pairs = d->Read<int32_t>();
      intptr_t used_data = pairs << 1;
      intptr_t data_size = Utils::Maximum(
          Utils::RoundUpToPowerOfTwo(used_data),
          static_cast<uintptr_t>(LinkedHashMap::kInitialIndexSize));

      RawArray* data = reinterpret_cast<RawArray*>(
          AllocateUninitialized(old_space, Array::InstanceSize(data_size)));
      data->ptr()->type_arguments_ = TypeArguments::null();
      data->ptr()->length_ = Smi::New(data_size);
      intptr_t i;
      for (i = 0; i < used_data; i++) {
        data->ptr()->data()[i] = d->ReadRef();
      }
      for (; i < data_size; i++) {
        data->ptr()->data()[i] = Object::null();
      }

      map->ptr()->index_ = TypedData::null();
      map->ptr()->hash_mask_ = Smi::New(0);
      map->ptr()->data_ = data;
      map->ptr()->used_data_ = Smi::New(used_data);
      map->ptr()->deleted_keys_ = Smi::New(0);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ArraySerializationCluster : public SerializationCluster {
 public:
  explicit ArraySerializationCluster(intptr_t cid)
      : SerializationCluster("Array"), cid_(cid) {}
  ~ArraySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawArray* array = Array::RawCast(object);
    objects_.Add(array);

    s->Push(array->ptr()->type_arguments_);
    intptr_t length = Smi::Value(array->ptr()->length_);
    for (intptr_t i = 0; i < length; i++) {
      s->Push(array->ptr()->data()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawArray* array = objects_[i];
      s->AssignRef(array);
      AutoTraceObject(array);
      intptr_t length = Smi::Value(array->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawArray* array = objects_[i];
      AutoTraceObject(array);
      intptr_t length = Smi::Value(array->ptr()->length_);
      s->WriteUnsigned(length);
      s->Write<bool>(array->IsCanonical());
      s->WriteRef(array->ptr()->type_arguments_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteRef(array->ptr()->data()[j]);
      }
    }
  }

 private:
  intptr_t cid_;
  GrowableArray<RawArray*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ArrayDeserializationCluster : public DeserializationCluster {
 public:
  explicit ArrayDeserializationCluster(intptr_t cid) : cid_(cid) {}
  ~ArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, Array::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawArray* array = reinterpret_cast<RawArray*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(array, cid_, Array::InstanceSize(length),
                                     is_vm_object, is_canonical);
      array->ptr()->type_arguments_ =
          reinterpret_cast<RawTypeArguments*>(d->ReadRef());
      array->ptr()->length_ = Smi::New(length);
      for (intptr_t j = 0; j < length; j++) {
        array->ptr()->data()[j] = d->ReadRef();
      }
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class OneByteStringSerializationCluster : public SerializationCluster {
 public:
  OneByteStringSerializationCluster() : SerializationCluster("OneByteString") {}
  ~OneByteStringSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawOneByteString* str = reinterpret_cast<RawOneByteString*>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kOneByteStringCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawOneByteString* str = objects_[i];
      s->AssignRef(str);
      AutoTraceObject(str);
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawOneByteString* str = objects_[i];
      AutoTraceObject(str);
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
      s->Write<bool>(str->IsCanonical());
      intptr_t hash = String::GetCachedHash(str);
      s->Write<int32_t>(hash);
      s->WriteBytes(str->ptr()->data(), length);
    }
  }

 private:
  GrowableArray<RawOneByteString*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class OneByteStringDeserializationCluster : public DeserializationCluster {
 public:
  OneByteStringDeserializationCluster() {}
  ~OneByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         OneByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawOneByteString* str = reinterpret_cast<RawOneByteString*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(str, kOneByteStringCid,
                                     OneByteString::InstanceSize(length),
                                     is_vm_object, is_canonical);
      str->ptr()->length_ = Smi::New(length);
      String::SetCachedHash(str, d->Read<int32_t>());
      for (intptr_t j = 0; j < length; j++) {
        str->ptr()->data()[j] = d->Read<uint8_t>();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TwoByteStringSerializationCluster : public SerializationCluster {
 public:
  TwoByteStringSerializationCluster() : SerializationCluster("TwoByteString") {}
  ~TwoByteStringSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTwoByteString* str = reinterpret_cast<RawTwoByteString*>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTwoByteStringCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTwoByteString* str = objects_[i];
      s->AssignRef(str);
      AutoTraceObject(str);
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTwoByteString* str = objects_[i];
      AutoTraceObject(str);
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
      s->Write<bool>(str->IsCanonical());
      intptr_t hash = String::GetCachedHash(str);
      s->Write<int32_t>(hash);
      s->WriteBytes(reinterpret_cast<uint8_t*>(str->ptr()->data()), length * 2);
    }
  }

 private:
  GrowableArray<RawTwoByteString*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TwoByteStringDeserializationCluster : public DeserializationCluster {
 public:
  TwoByteStringDeserializationCluster() {}
  ~TwoByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         TwoByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTwoByteString* str = reinterpret_cast<RawTwoByteString*>(d->Ref(id));
      intptr_t length = d->ReadUnsigned();
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(str, kTwoByteStringCid,
                                     TwoByteString::InstanceSize(length),
                                     is_vm_object, is_canonical);
      str->ptr()->length_ = Smi::New(length);
      String::SetCachedHash(str, d->Read<int32_t>());
      uint8_t* cdata = reinterpret_cast<uint8_t*>(str->ptr()->data());
      d->ReadBytes(cdata, length * 2);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FakeSerializationCluster : public SerializationCluster {
 public:
  FakeSerializationCluster(const char* name, intptr_t size)
      : SerializationCluster(name) {
    size_ = size;
  }
  ~FakeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) { UNREACHABLE(); }
  void WriteAlloc(Serializer* s) { UNREACHABLE(); }
  void WriteFill(Serializer* s) { UNREACHABLE(); }
};
#endif  // !DART_PRECOMPILED_RUNTIME

Serializer::Serializer(Thread* thread,
                       Snapshot::Kind kind,
                       uint8_t** buffer,
                       ReAlloc alloc,
                       intptr_t initial_size,
                       ImageWriter* image_writer,
                       bool vm,
                       V8SnapshotProfileWriter* profile_writer)
    : StackResource(thread),
      heap_(thread->isolate()->heap()),
      zone_(thread->zone()),
      kind_(kind),
      stream_(buffer, alloc, initial_size),
      image_writer_(image_writer),
      clusters_by_cid_(NULL),
      stack_(),
      num_cids_(0),
      num_base_objects_(0),
      num_written_objects_(0),
      next_ref_index_(1),
      vm_(vm),
      profile_writer_(profile_writer)
#if defined(SNAPSHOT_BACKTRACE)
      ,
      current_parent_(Object::null()),
      parent_pairs_()
#endif
{
  num_cids_ = thread->isolate()->class_table()->NumCids();
  clusters_by_cid_ = new SerializationCluster*[num_cids_];
  for (intptr_t i = 0; i < num_cids_; i++) {
    clusters_by_cid_[i] = NULL;
  }
}

Serializer::~Serializer() {
  delete[] clusters_by_cid_;
}

void Serializer::TraceStartWritingObject(const char* type,
                                         RawObject* obj,
                                         RawString* name) {
  if (profile_writer_ == nullptr) return;

  intptr_t id = 0;
  if (obj->IsHeapObject()) {
    id = heap_->GetObjectId(obj);
  } else {
    id = smi_ids_.Lookup(Smi::RawCast(obj))->id_;
  }
  ASSERT(id != 0);

  const char* name_str = nullptr;
  if (name != nullptr) {
    String& str = thread()->StringHandle();
    str = name;
    name_str = str.ToCString();
  }

  object_currently_writing_id_ = id;
  profile_writer_->SetObjectTypeAndName(
      {V8SnapshotProfileWriter::kSnapshot, id}, type, name_str);
  object_currently_writing_start_ = stream_.Position();
}

void Serializer::TraceEndWritingObject() {
  if (profile_writer_ != nullptr) {
    ASSERT(object_currently_writing_id_ != 0);
    profile_writer_->AttributeBytesTo(
        {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_id_},
        stream_.Position() - object_currently_writing_start_);
    object_currently_writing_id_ = 0;
    object_currently_writing_start_ = 0;
  }
}

SerializationCluster* Serializer::NewClusterForClass(intptr_t cid) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return NULL;
#else
  Zone* Z = zone_;
  if ((cid >= kNumPredefinedCids) || (cid == kInstanceCid) ||
      RawObject::IsTypedDataViewClassId(cid)) {
    Push(isolate()->class_table()->At(cid));
    return new (Z) InstanceSerializationCluster(cid);
  }
  if (RawObject::IsExternalTypedDataClassId(cid)) {
    return new (Z) ExternalTypedDataSerializationCluster(cid);
  }
  if (RawObject::IsTypedDataClassId(cid)) {
    return new (Z) TypedDataSerializationCluster(cid);
  }

  switch (cid) {
    case kClassCid:
      return new (Z) ClassSerializationCluster(num_cids_);
    case kTypeArgumentsCid:
      return new (Z) TypeArgumentsSerializationCluster();
    case kPatchClassCid:
      return new (Z) PatchClassSerializationCluster();
    case kFunctionCid:
      return new (Z) FunctionSerializationCluster();
    case kClosureDataCid:
      return new (Z) ClosureDataSerializationCluster();
    case kSignatureDataCid:
      return new (Z) SignatureDataSerializationCluster();
    case kRedirectionDataCid:
      return new (Z) RedirectionDataSerializationCluster();
    case kFieldCid:
      return new (Z) FieldSerializationCluster();
    case kScriptCid:
      return new (Z) ScriptSerializationCluster();
    case kLibraryCid:
      return new (Z) LibrarySerializationCluster();
    case kNamespaceCid:
      return new (Z) NamespaceSerializationCluster();
    case kKernelProgramInfoCid:
      return new (Z) KernelProgramInfoSerializationCluster();
    case kCodeCid:
      return new (Z) CodeSerializationCluster();
#if !defined(DART_PRECOMPILED_RUNTIME)
    case kBytecodeCid:
      return new (Z) BytecodeSerializationCluster();
#endif  // !DART_PRECOMPILED_RUNTIME
    case kObjectPoolCid:
      return new (Z) ObjectPoolSerializationCluster();
    case kPcDescriptorsCid:
      return new (Z)
          RODataSerializationCluster("(RO)PcDescriptors", kPcDescriptorsCid);
    case kCodeSourceMapCid:
      return new (Z)
          RODataSerializationCluster("(RO)CodeSourceMap", kCodeSourceMapCid);
    case kStackMapCid:
      return new (Z) RODataSerializationCluster("(RO)StackMap", kStackMapCid);
    case kExceptionHandlersCid:
      return new (Z) ExceptionHandlersSerializationCluster();
    case kContextCid:
      return new (Z) ContextSerializationCluster();
    case kContextScopeCid:
      return new (Z) ContextScopeSerializationCluster();
    case kUnlinkedCallCid:
      return new (Z) UnlinkedCallSerializationCluster();
    case kICDataCid:
      return new (Z) ICDataSerializationCluster();
    case kMegamorphicCacheCid:
      return new (Z) MegamorphicCacheSerializationCluster();
    case kSubtypeTestCacheCid:
      return new (Z) SubtypeTestCacheSerializationCluster();
    case kLanguageErrorCid:
      return new (Z) LanguageErrorSerializationCluster();
    case kUnhandledExceptionCid:
      return new (Z) UnhandledExceptionSerializationCluster();
    case kLibraryPrefixCid:
      return new (Z) LibraryPrefixSerializationCluster();
    case kTypeCid:
      return new (Z) TypeSerializationCluster(type_testing_stubs_);
    case kTypeRefCid:
      return new (Z) TypeRefSerializationCluster(type_testing_stubs_);
    case kTypeParameterCid:
      return new (Z) TypeParameterSerializationCluster(type_testing_stubs_);
    case kBoundedTypeCid:
      return new (Z) BoundedTypeSerializationCluster();
    case kClosureCid:
      return new (Z) ClosureSerializationCluster();
    case kMintCid:
      return new (Z) MintSerializationCluster();
    case kDoubleCid:
      return new (Z) DoubleSerializationCluster();
    case kGrowableObjectArrayCid:
      return new (Z) GrowableObjectArraySerializationCluster();
    case kStackTraceCid:
      return new (Z) StackTraceSerializationCluster();
    case kRegExpCid:
      return new (Z) RegExpSerializationCluster();
    case kWeakPropertyCid:
      return new (Z) WeakPropertySerializationCluster();
    case kLinkedHashMapCid:
      return new (Z) LinkedHashMapSerializationCluster();
    case kArrayCid:
      return new (Z) ArraySerializationCluster(kArrayCid);
    case kImmutableArrayCid:
      return new (Z) ArraySerializationCluster(kImmutableArrayCid);
    case kOneByteStringCid: {
      if (Snapshot::IncludesCode(kind_)) {
        return new (Z)
            RODataSerializationCluster("(RO)OneByteString", kOneByteStringCid);
      } else {
        return new (Z) OneByteStringSerializationCluster();
      }
    }
    case kTwoByteStringCid: {
      if (Snapshot::IncludesCode(kind_)) {
        return new (Z)
            RODataSerializationCluster("(RO)TwoByteString", kTwoByteStringCid);
      } else {
        return new (Z) TwoByteStringSerializationCluster();
      }
    }
    default:
      break;
  }

  FATAL2("No cluster defined for cid %" Pd ", kind %s", cid,
         Snapshot::KindToCString(kind_));
  return NULL;
#endif  // !DART_PRECOMPILED_RUNTIME
}

void Serializer::WriteInstructions(RawInstructions* instr, RawCode* code) {
  const intptr_t offset = image_writer_->GetTextOffsetFor(instr, code);
  ASSERT(offset != 0);
  Write<int32_t>(offset);

  // If offset < 0, it's pointing to a shared instruction. We don't profile
  // references to shared text/data (since they don't consume any space). Of
  // course, the space taken for the reference is profiled.
  if (profile_writer_ != nullptr && offset >= 0) {
    // Instructions cannot be roots.
    ASSERT(object_currently_writing_id_ != 0);
    auto offset_space = vm_ ? V8SnapshotProfileWriter::kVmText
                            : V8SnapshotProfileWriter::kIsolateText;
    profile_writer_->AttributeReferenceTo(
        {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_id_},
        {offset_space, offset < 0 ? -offset : offset});
  }
}

void Serializer::TraceDataOffset(uint32_t offset) {
  if (profile_writer_ != nullptr) {
    // ROData cannot be roots.
    ASSERT(object_currently_writing_id_ != 0);
    auto offset_space = vm_ ? V8SnapshotProfileWriter::kVmData
                            : V8SnapshotProfileWriter::kIsolateData;
    profile_writer_->AttributeReferenceTo(
        {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_id_},
        {offset_space, offset});
  }
}

bool Serializer::GetSharedDataOffset(RawObject* object,
                                     uint32_t* offset) const {
  return image_writer_->GetSharedDataOffsetFor(object, offset);
}

uint32_t Serializer::GetDataOffset(RawObject* object) const {
  return image_writer_->GetDataOffsetFor(object);
}

intptr_t Serializer::GetDataSize() const {
  if (image_writer_ == NULL) {
    return 0;
  }
  return image_writer_->data_size();
}

intptr_t Serializer::GetTextSize() const {
  if (image_writer_ == NULL) {
    return 0;
  }
  return image_writer_->text_size();
}

void Serializer::Push(RawObject* object) {
  if (!object->IsHeapObject()) {
    RawSmi* smi = Smi::RawCast(object);
    if (smi_ids_.Lookup(smi) == NULL) {
      SmiObjectIdPair pair;
      pair.smi_ = smi;
      pair.id_ = 1;
      smi_ids_.Insert(pair);
      stack_.Add(object);
      num_written_objects_++;
    }
    return;
  }

  if (object->IsCode() && !Snapshot::IncludesCode(kind_)) {
    return;  // Do not trace, will write null.
  }
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (object->IsBytecode() && !Snapshot::IncludesBytecode(kind_)) {
    return;  // Do not trace, will write null.
  }
#endif  // !DART_PRECOMPILED_RUNTIME

  if (object->IsSendPort()) {
    // TODO(rmacnak): Do a better job of resetting fields in precompilation
    // and assert this is unreachable.
    return;  // Do not trace, will write null.
  }

  intptr_t id = heap_->GetObjectId(object);
  if (id == 0) {
    // When discovering the transitive closure of objects reachable from the
    // roots we do not trace references, e.g. inside [RawCode], to
    // [RawInstructions], since [RawInstructions] doesn't contain any references
    // and the serialization code uses an [ImageWriter] for those.
    ASSERT(object->GetClassId() != kInstructionsCid);

    heap_->SetObjectId(object, 1);
    ASSERT(heap_->GetObjectId(object) != 0);
    stack_.Add(object);
    num_written_objects_++;

#if defined(SNAPSHOT_BACKTRACE)
    parent_pairs_.Add(&Object::Handle(zone_, object));
    parent_pairs_.Add(&Object::Handle(zone_, current_parent_));
#endif
  }
}

void Serializer::Trace(RawObject* object) {
  intptr_t cid;
  if (!object->IsHeapObject()) {
    // Smis are merged into the Mint cluster because Smis for the writer might
    // become Mints for the reader and vice versa.
    cid = kMintCid;
  } else {
    cid = object->GetClassId();
  }

  SerializationCluster* cluster = clusters_by_cid_[cid];
  if (cluster == NULL) {
    cluster = NewClusterForClass(cid);
    clusters_by_cid_[cid] = cluster;
  }
  ASSERT(cluster != NULL);

#if defined(SNAPSHOT_BACKTRACE)
  current_parent_ = object;
#endif

  cluster->Trace(this, object);

#if defined(SNAPSHOT_BACKTRACE)
  current_parent_ = Object::null();
#endif
}

void Serializer::UnexpectedObject(RawObject* raw_object, const char* message) {
  // Exit the no safepoint scope so we can allocate while printing.
  while (thread()->no_safepoint_scope_depth() > 0) {
    thread()->DecrementNoSafepointScopeDepth();
  }
  Object& object = Object::Handle(raw_object);
  OS::PrintErr("Unexpected object (%s): 0x%" Px " %s\n", message,
               reinterpret_cast<uword>(object.raw()), object.ToCString());
#if defined(SNAPSHOT_BACKTRACE)
  while (!object.IsNull()) {
    object = ParentOf(object);
    OS::PrintErr("referenced by 0x%" Px " %s\n",
                 reinterpret_cast<uword>(object.raw()), object.ToCString());
  }
#endif
  OS::Abort();
}

#if defined(SNAPSHOT_BACKTRACE)
RawObject* Serializer::ParentOf(const Object& object) {
  for (intptr_t i = 0; i < parent_pairs_.length(); i += 2) {
    if (parent_pairs_[i]->raw() == object.raw()) {
      return parent_pairs_[i + 1]->raw();
    }
  }
  return Object::null();
}
#endif  // SNAPSHOT_BACKTRACE

void Serializer::WriteVersionAndFeatures(bool is_vm_snapshot) {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_version), version_len);

  const char* expected_features =
      Dart::FeaturesString(Isolate::Current(), is_vm_snapshot, kind_);
  ASSERT(expected_features != NULL);
  const intptr_t features_len = strlen(expected_features);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_features),
             features_len + 1);
  free(const_cast<char*>(expected_features));
}

#if defined(DEBUG)
static const int32_t kSectionMarker = 0xABAB;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
static int CompareClusters(SerializationCluster* const* a,
                           SerializationCluster* const* b) {
  if ((*a)->size() > (*b)->size()) {
    return -1;
  } else if ((*a)->size() < (*b)->size()) {
    return 1;
  } else {
    return 0;
  }
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void Serializer::Serialize() {
  while (stack_.length() > 0) {
    Trace(stack_.RemoveLast());
  }

  intptr_t num_clusters = 0;
  for (intptr_t cid = 1; cid < num_cids_; cid++) {
    SerializationCluster* cluster = clusters_by_cid_[cid];
    if (cluster != NULL) {
      num_clusters++;
    }
  }

  intptr_t num_objects = num_base_objects_ + num_written_objects_;
#if defined(ARCH_IS_64_BIT)
  if (!Utils::IsInt(32, num_objects)) {
    FATAL("Ref overflow");
  }
#endif

  WriteUnsigned(num_base_objects_);
  WriteUnsigned(num_objects);
  WriteUnsigned(num_clusters);

  for (intptr_t cid = 1; cid < num_cids_; cid++) {
    SerializationCluster* cluster = clusters_by_cid_[cid];
    if (cluster != NULL) {
      cluster->WriteAndMeasureAlloc(this);
#if defined(DEBUG)
      Write<int32_t>(next_ref_index_);
#endif
    }
  }

  // We should have assigned a ref to every object we pushed.
  ASSERT((next_ref_index_ - 1) == num_objects);

  for (intptr_t cid = 1; cid < num_cids_; cid++) {
    SerializationCluster* cluster = clusters_by_cid_[cid];
    if (cluster != NULL) {
      cluster->WriteAndMeasureFill(this);
#if defined(DEBUG)
      Write<int32_t>(kSectionMarker);
#endif
    }
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_print_snapshot_sizes_verbose) {
    OS::PrintErr("             Cluster   Objs     Size Fraction Cumulative\n");
    GrowableArray<SerializationCluster*> clusters_by_size;
    for (intptr_t cid = 1; cid < num_cids_; cid++) {
      SerializationCluster* cluster = clusters_by_cid_[cid];
      if (cluster != NULL) {
        clusters_by_size.Add(cluster);
      }
    }
    if (GetTextSize() != 0) {
      clusters_by_size.Add(new (zone_) FakeSerializationCluster(
          "(RO)Instructions", GetTextSize()));
    }
    clusters_by_size.Sort(CompareClusters);
    double total_size =
        static_cast<double>(bytes_written() + GetDataSize() + GetTextSize());
    double cumulative_fraction = 0.0;
    for (intptr_t i = 0; i < clusters_by_size.length(); i++) {
      SerializationCluster* cluster = clusters_by_size[i];
      double fraction = static_cast<double>(cluster->size()) / total_size;
      cumulative_fraction += fraction;
      OS::PrintErr("%20s %6" Pd " %8" Pd " %lf %lf\n", cluster->name(),
                   cluster->num_objects(), cluster->size(), fraction,
                   cumulative_fraction);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

void Serializer::AddVMIsolateBaseObjects() {
  // These objects are always allocated by Object::InitOnce, so they are not
  // written into the snapshot.

  AddBaseObject(Object::null(), "Null", "<null>");
  AddBaseObject(Object::sentinel().raw(), "Sentinel");
  AddBaseObject(Object::transition_sentinel().raw(), "Sentinel");
  AddBaseObject(Object::empty_array().raw(), "Array", "<empty_array>");
  AddBaseObject(Object::zero_array().raw(), "Array", "<zero_array>");
  AddBaseObject(Object::dynamic_type().raw(), "Type", "<dynamic type>");
  AddBaseObject(Object::void_type().raw(), "Type", "<void type>");
  AddBaseObject(Object::empty_type_arguments().raw(), "TypeArguments", "[]");
  AddBaseObject(Bool::True().raw(), "bool", "true");
  AddBaseObject(Bool::False().raw(), "bool", "false");
  ASSERT(Object::extractor_parameter_types().raw() != Object::null());
  AddBaseObject(Object::extractor_parameter_types().raw(), "Array",
                "<extractor parameter types>");
  ASSERT(Object::extractor_parameter_names().raw() != Object::null());
  AddBaseObject(Object::extractor_parameter_names().raw(), "Array",
                "<extractor parameter names>");
  AddBaseObject(Object::empty_context_scope().raw(), "ContextScope", "<empty>");
  AddBaseObject(Object::empty_descriptors().raw(), "PcDescriptors", "<empty>");
  AddBaseObject(Object::empty_var_descriptors().raw(), "LocalVarDescriptors",
                "<empty>");
  AddBaseObject(Object::empty_exception_handlers().raw(), "ExceptionHandlers",
                "<empty>");

  for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
    AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i],
                  "ArgumentsDescriptor", "<cached arguments descriptor>");
  }
  for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
    AddBaseObject(ICData::cached_icdata_arrays_[i], "ICData",
                  "<cached icdata>");
  }

  ClassTable* table = isolate()->class_table();
  for (intptr_t cid = kClassCid; cid < kInstanceCid; cid++) {
    // Error has no class object.
    if (cid != kErrorCid) {
      ASSERT(table->HasValidClassAt(cid));
      AddBaseObject(table->At(cid), "Class");
    }
  }
  AddBaseObject(table->At(kDynamicCid), "Class");
  AddBaseObject(table->At(kVoidCid), "Class");

  if (!Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      AddBaseObject(StubCode::EntryAt(i).raw(), "Code", "<stub code>");
    }
  }
}

intptr_t Serializer::WriteVMSnapshot(const Array& symbols,
                                     ZoneGrowableArray<Object*>* seeds) {
  NoSafepointScope no_safepoint;

  AddVMIsolateBaseObjects();

  // Push roots.
  Push(symbols.raw());
  if (Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      Push(StubCode::EntryAt(i).raw());
    }
  }
  if (seeds != NULL) {
    for (intptr_t i = 0; i < seeds->length(); i++) {
      Push((*seeds)[i]->raw());
    }
  }

  Serialize();

  // Write roots.
  WriteRootRef(symbols.raw());
  if (Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      WriteRootRef(StubCode::EntryAt(i).raw());
    }
  }

#if defined(DEBUG)
  Write<int32_t>(kSectionMarker);
#endif

  // Note we are not clearing the object id table. The full ref table
  // of the vm isolate snapshot serves as the base objects for the
  // regular isolate snapshot.

  // Return the number of objects, -1 accounts for unused ref 0.
  return next_ref_index_ - 1;
}

void Serializer::WriteIsolateSnapshot(intptr_t num_base_objects,
                                      ObjectStore* object_store) {
  NoSafepointScope no_safepoint;

  if (num_base_objects == 0) {
    // Not writing a new vm isolate: use the one this VM was loaded from.
    const Array& base_objects = Object::vm_isolate_snapshot_object_table();
    for (intptr_t i = 1; i < base_objects.Length(); i++) {
      AddBaseObject(base_objects.At(i));
    }
  } else {
    // Base objects carried over from WriteVMIsolateSnapshot.
    num_base_objects_ += num_base_objects;
    next_ref_index_ += num_base_objects;
  }

  // Push roots.
  RawObject** from = object_store->from();
  RawObject** to = object_store->to_snapshot(kind_);
  for (RawObject** p = from; p <= to; p++) {
    Push(*p);
  }

  Serialize();

  // Write roots.
  for (RawObject** p = from; p <= to; p++) {
    WriteRootRef(*p);
  }

#if defined(DEBUG)
  Write<int32_t>(kSectionMarker);
#endif

  heap_->ResetObjectIdTable();
}

Deserializer::Deserializer(Thread* thread,
                           Snapshot::Kind kind,
                           const uint8_t* buffer,
                           intptr_t size,
                           const uint8_t* data_buffer,
                           const uint8_t* instructions_buffer,
                           const uint8_t* shared_data_buffer,
                           const uint8_t* shared_instructions_buffer)
    : StackResource(thread),
      heap_(thread->isolate()->heap()),
      zone_(thread->zone()),
      kind_(kind),
      stream_(buffer, size),
      image_reader_(NULL),
      refs_(NULL),
      next_ref_index_(1),
      clusters_(NULL) {
  if (Snapshot::IncludesCode(kind)) {
    ASSERT(instructions_buffer != NULL);
    ASSERT(data_buffer != NULL);
    image_reader_ =
        new (zone_) ImageReader(data_buffer, instructions_buffer,
                                shared_data_buffer, shared_instructions_buffer);
  }
}

Deserializer::~Deserializer() {
  delete[] clusters_;
}

DeserializationCluster* Deserializer::ReadCluster() {
  intptr_t cid = ReadCid();

  Zone* Z = zone_;
  if ((cid >= kNumPredefinedCids) || (cid == kInstanceCid) ||
      RawObject::IsTypedDataViewClassId(cid)) {
    return new (Z) InstanceDeserializationCluster(cid);
  }
  if (RawObject::IsExternalTypedDataClassId(cid)) {
    return new (Z) ExternalTypedDataDeserializationCluster(cid);
  }
  if (RawObject::IsTypedDataClassId(cid)) {
    return new (Z) TypedDataDeserializationCluster(cid);
  }

  switch (cid) {
    case kClassCid:
      return new (Z) ClassDeserializationCluster();
    case kTypeArgumentsCid:
      return new (Z) TypeArgumentsDeserializationCluster();
    case kPatchClassCid:
      return new (Z) PatchClassDeserializationCluster();
    case kFunctionCid:
      return new (Z) FunctionDeserializationCluster();
    case kClosureDataCid:
      return new (Z) ClosureDataDeserializationCluster();
    case kSignatureDataCid:
      return new (Z) SignatureDataDeserializationCluster();
    case kRedirectionDataCid:
      return new (Z) RedirectionDataDeserializationCluster();
    case kFieldCid:
      return new (Z) FieldDeserializationCluster();
    case kScriptCid:
      return new (Z) ScriptDeserializationCluster();
    case kLibraryCid:
      return new (Z) LibraryDeserializationCluster();
    case kNamespaceCid:
      return new (Z) NamespaceDeserializationCluster();
#if !defined(DART_PRECOMPILED_RUNTIME)
    case kKernelProgramInfoCid:
      return new (Z) KernelProgramInfoDeserializationCluster();
#endif  // !DART_PRECOMPILED_RUNTIME
    case kCodeCid:
      return new (Z) CodeDeserializationCluster();
#if !defined(DART_PRECOMPILED_RUNTIME)
    case kBytecodeCid:
      return new (Z) BytecodeDeserializationCluster();
#endif  // !DART_PRECOMPILED_RUNTIME
    case kObjectPoolCid:
      return new (Z) ObjectPoolDeserializationCluster();
    case kPcDescriptorsCid:
    case kCodeSourceMapCid:
    case kStackMapCid:
      return new (Z) RODataDeserializationCluster();
    case kExceptionHandlersCid:
      return new (Z) ExceptionHandlersDeserializationCluster();
    case kContextCid:
      return new (Z) ContextDeserializationCluster();
    case kContextScopeCid:
      return new (Z) ContextScopeDeserializationCluster();
    case kUnlinkedCallCid:
      return new (Z) UnlinkedCallDeserializationCluster();
    case kICDataCid:
      return new (Z) ICDataDeserializationCluster();
    case kMegamorphicCacheCid:
      return new (Z) MegamorphicCacheDeserializationCluster();
    case kSubtypeTestCacheCid:
      return new (Z) SubtypeTestCacheDeserializationCluster();
    case kLanguageErrorCid:
      return new (Z) LanguageErrorDeserializationCluster();
    case kUnhandledExceptionCid:
      return new (Z) UnhandledExceptionDeserializationCluster();
    case kLibraryPrefixCid:
      return new (Z) LibraryPrefixDeserializationCluster();
    case kTypeCid:
      return new (Z) TypeDeserializationCluster();
    case kTypeRefCid:
      return new (Z) TypeRefDeserializationCluster();
    case kTypeParameterCid:
      return new (Z) TypeParameterDeserializationCluster();
    case kBoundedTypeCid:
      return new (Z) BoundedTypeDeserializationCluster();
    case kClosureCid:
      return new (Z) ClosureDeserializationCluster();
    case kMintCid:
      return new (Z) MintDeserializationCluster();
    case kDoubleCid:
      return new (Z) DoubleDeserializationCluster();
    case kGrowableObjectArrayCid:
      return new (Z) GrowableObjectArrayDeserializationCluster();
    case kStackTraceCid:
      return new (Z) StackTraceDeserializationCluster();
    case kRegExpCid:
      return new (Z) RegExpDeserializationCluster();
    case kWeakPropertyCid:
      return new (Z) WeakPropertyDeserializationCluster();
    case kLinkedHashMapCid:
      return new (Z) LinkedHashMapDeserializationCluster();
    case kArrayCid:
      return new (Z) ArrayDeserializationCluster(kArrayCid);
    case kImmutableArrayCid:
      return new (Z) ArrayDeserializationCluster(kImmutableArrayCid);
    case kOneByteStringCid: {
      if (Snapshot::IncludesCode(kind_)) {
        return new (Z) RODataDeserializationCluster();
      } else {
        return new (Z) OneByteStringDeserializationCluster();
      }
    }
    case kTwoByteStringCid: {
      if (Snapshot::IncludesCode(kind_)) {
        return new (Z) RODataDeserializationCluster();
      } else {
        return new (Z) TwoByteStringDeserializationCluster();
      }
    }
    default:
      break;
  }
  FATAL1("No cluster defined for cid %" Pd, cid);
  return NULL;
}

RawApiError* Deserializer::VerifyVersionAndFeatures(Isolate* isolate) {
  if (image_reader_ != NULL) {
    RawApiError* error = image_reader_->VerifyAlignment();
    if (error != ApiError::null()) {
      return error;
    }
  }

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
  if (strncmp(version, expected_version, version_len)) {
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

  const char* expected_features =
      Dart::FeaturesString(isolate, (isolate == NULL), kind_);
  ASSERT(expected_features != NULL);
  const intptr_t expected_len = strlen(expected_features);

  const char* features = reinterpret_cast<const char*>(CurrentBufferAddress());
  ASSERT(features != NULL);
  intptr_t buffer_len = Utils::StrNLen(features, PendingBytes());
  if ((buffer_len != expected_len) ||
      strncmp(features, expected_features, expected_len)) {
    const intptr_t kMessageBufferSize = 1024;
    char message_buffer[kMessageBufferSize];
    char* actual_features =
        Utils::StrNDup(features, buffer_len < 1024 ? buffer_len : 1024);
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

RawInstructions* Deserializer::ReadInstructions() {
  int32_t offset = Read<int32_t>();
  return image_reader_->GetInstructionsAt(offset);
}

RawObject* Deserializer::GetObjectAt(uint32_t offset) const {
  return image_reader_->GetObjectAt(offset);
}

RawObject* Deserializer::GetSharedObjectAt(uint32_t offset) const {
  return image_reader_->GetSharedObjectAt(offset);
}

void Deserializer::Prepare() {
  num_base_objects_ = ReadUnsigned();
  num_objects_ = ReadUnsigned();
  num_clusters_ = ReadUnsigned();

  clusters_ = new DeserializationCluster*[num_clusters_];
  refs_ = Array::New(num_objects_ + 1, Heap::kOld);
}

void Deserializer::Deserialize() {
  if (num_base_objects_ != (next_ref_index_ - 1)) {
    FATAL2("Snapshot expects %" Pd
           " base objects, but deserializer provided %" Pd,
           num_base_objects_, next_ref_index_ - 1);
  }

  {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        thread(), Timeline::GetIsolateStream(), "ReadAlloc"));
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i] = ReadCluster();
      clusters_[i]->ReadAlloc(this);
#if defined(DEBUG)
      intptr_t serializers_next_ref_index_ = Read<int32_t>();
      ASSERT(serializers_next_ref_index_ == next_ref_index_);
#endif
    }
  }

  // We should have completely filled the ref array.
  ASSERT((next_ref_index_ - 1) == num_objects_);

  {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        thread(), Timeline::GetIsolateStream(), "ReadFill"));
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i]->ReadFill(this);
#if defined(DEBUG)
      int32_t section_marker = Read<int32_t>();
      ASSERT(section_marker == kSectionMarker);
#endif
    }
  }
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

void Deserializer::AddVMIsolateBaseObjects() {
  // These objects are always allocated by Object::InitOnce, so they are not
  // written into the snapshot.

  AddBaseObject(Object::null());
  AddBaseObject(Object::sentinel().raw());
  AddBaseObject(Object::transition_sentinel().raw());
  AddBaseObject(Object::empty_array().raw());
  AddBaseObject(Object::zero_array().raw());
  AddBaseObject(Object::dynamic_type().raw());
  AddBaseObject(Object::void_type().raw());
  AddBaseObject(Object::empty_type_arguments().raw());
  AddBaseObject(Bool::True().raw());
  AddBaseObject(Bool::False().raw());
  ASSERT(Object::extractor_parameter_types().raw() != Object::null());
  AddBaseObject(Object::extractor_parameter_types().raw());
  ASSERT(Object::extractor_parameter_names().raw() != Object::null());
  AddBaseObject(Object::extractor_parameter_names().raw());
  AddBaseObject(Object::empty_context_scope().raw());
  AddBaseObject(Object::empty_descriptors().raw());
  AddBaseObject(Object::empty_var_descriptors().raw());
  AddBaseObject(Object::empty_exception_handlers().raw());

  for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
    AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i]);
  }
  for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
    AddBaseObject(ICData::cached_icdata_arrays_[i]);
  }

  ClassTable* table = isolate()->class_table();
  for (intptr_t cid = kClassCid; cid <= kUnwindErrorCid; cid++) {
    // Error has no class object.
    if (cid != kErrorCid) {
      ASSERT(table->HasValidClassAt(cid));
      AddBaseObject(table->At(cid));
    }
  }
  AddBaseObject(table->At(kDynamicCid));
  AddBaseObject(table->At(kVoidCid));

  if (!Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      AddBaseObject(StubCode::EntryAt(i).raw());
    }
  }
}

void Deserializer::ReadVMSnapshot() {
  Array& symbol_table = Array::Handle(zone_);
  Array& refs = Array::Handle(zone_);
  Prepare();

  {
    NoSafepointScope no_safepoint;
    HeapLocker hl(thread(), heap_->old_space());

    AddVMIsolateBaseObjects();

    Deserialize();

    // Read roots.
    symbol_table ^= ReadRef();
    isolate()->object_store()->set_symbol_table(symbol_table);
    if (Snapshot::IncludesCode(kind_)) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        Code* code = Code::ReadOnlyHandle();
        *code ^= ReadRef();
        StubCode::EntryAtPut(i, code);
      }
    }

#if defined(DEBUG)
    int32_t section_marker = Read<int32_t>();
    ASSERT(section_marker == kSectionMarker);
#endif

    refs = refs_;
    refs_ = NULL;
  }

  // Move remaining bump allocation space to the freelist so it used by C++
  // allocations (e.g., FinalizeVMIsolate) before allocating new pages.
  heap_->old_space()->AbandonBumpAllocation();

  Symbols::InitFromSnapshot(isolate());

  Object::set_vm_isolate_snapshot_object_table(refs);

#if defined(DEBUG)
  isolate()->ValidateClassTable();
#endif
}

void Deserializer::ReadIsolateSnapshot(ObjectStore* object_store) {
  Array& refs = Array::Handle();
  Prepare();

  {
    NoSafepointScope no_safepoint;
    HeapLocker hl(thread(), heap_->old_space());

    // N.B.: Skipping index 0 because ref 0 is illegal.
    const Array& base_objects = Object::vm_isolate_snapshot_object_table();
    for (intptr_t i = 1; i < base_objects.Length(); i++) {
      AddBaseObject(base_objects.At(i));
    }

    Deserialize();

    // Read roots.
    RawObject** from = object_store->from();
    RawObject** to = object_store->to_snapshot(kind_);
    for (RawObject** p = from; p <= to; p++) {
      *p = ReadRef();
    }

#if defined(DEBUG)
    int32_t section_marker = Read<int32_t>();
    ASSERT(section_marker == kSectionMarker);
#endif

    refs = refs_;
    refs_ = NULL;
  }

  thread()->isolate()->class_table()->CopySizesFromClassObjects();
  heap_->old_space()->EvaluateSnapshotLoad();

#if defined(DEBUG)
  Isolate* isolate = thread()->isolate();
  isolate->ValidateClassTable();
  isolate->heap()->Verify();
#endif

  for (intptr_t i = 0; i < num_clusters_; i++) {
    clusters_[i]->PostLoad(refs, kind_, zone_);
  }

  // Setup native resolver for bootstrap impl.
  Bootstrap::SetupNativeResolver();
}

// Iterates the program structure looking for objects to write into
// the VM isolate's snapshot, causing them to be shared across isolates.
// Duplicates will be removed by Serializer::Push.
class SeedVMIsolateVisitor : public ClassVisitor, public FunctionVisitor {
 public:
  SeedVMIsolateVisitor(Zone* zone, bool include_code)
      : zone_(zone),
        include_code_(include_code),
        seeds_(new (zone) ZoneGrowableArray<Object*>(4 * KB)),
        script_(Script::Handle(zone)),
        code_(Code::Handle(zone)),
        stack_maps_(Array::Handle(zone)),
        library_(Library::Handle(zone)),
        kernel_program_info_(KernelProgramInfo::Handle(zone)) {}

  void Visit(const Class& cls) {
    script_ = cls.script();
    if (!script_.IsNull()) {
      Visit(script_);
    }

    library_ = cls.library();
    AddSeed(library_.kernel_data());

    if (!include_code_) return;

    code_ = cls.allocation_stub();
    Visit(code_);
  }

  void Visit(const Function& function) {
    script_ = function.script();
    if (!script_.IsNull()) {
      Visit(script_);
    }

    if (!include_code_) return;

    code_ = function.CurrentCode();
    Visit(code_);
    code_ = function.unoptimized_code();
    Visit(code_);
  }

  void Visit(const Script& script) {
    kernel_program_info_ = script_.kernel_program_info();
    if (!kernel_program_info_.IsNull()) {
      AddSeed(kernel_program_info_.string_offsets());
      AddSeed(kernel_program_info_.string_data());
      AddSeed(kernel_program_info_.canonical_names());
      AddSeed(kernel_program_info_.metadata_payloads());
      AddSeed(kernel_program_info_.metadata_mappings());
      AddSeed(kernel_program_info_.constants());
    }
  }

  ZoneGrowableArray<Object*>* seeds() { return seeds_; }

 private:
  void Visit(const Code& code) {
    ASSERT(include_code_);
    if (code.IsNull()) return;

    AddSeed(code.pc_descriptors());
    AddSeed(code.code_source_map());

    stack_maps_ = code_.stackmaps();
    if (!stack_maps_.IsNull()) {
      for (intptr_t i = 0; i < stack_maps_.Length(); i++) {
        AddSeed(stack_maps_.At(i));
      }
    }
  }

  void AddSeed(RawObject* seed) { seeds_->Add(&Object::Handle(zone_, seed)); }

  Zone* zone_;
  bool include_code_;
  ZoneGrowableArray<Object*>* seeds_;
  Script& script_;
  Code& code_;
  Array& stack_maps_;
  Library& library_;
  KernelProgramInfo& kernel_program_info_;
};

#if defined(DART_PRECOMPILER)
DEFINE_FLAG(charp,
            write_v8_snapshot_profile_to,
            NULL,
            "Write a snapshot profile in V8 format to a file.");
#endif

FullSnapshotWriter::FullSnapshotWriter(Snapshot::Kind kind,
                                       uint8_t** vm_snapshot_data_buffer,
                                       uint8_t** isolate_snapshot_data_buffer,
                                       ReAlloc alloc,
                                       ImageWriter* vm_image_writer,
                                       ImageWriter* isolate_image_writer)
    : thread_(Thread::Current()),
      kind_(kind),
      vm_snapshot_data_buffer_(vm_snapshot_data_buffer),
      isolate_snapshot_data_buffer_(isolate_snapshot_data_buffer),
      alloc_(alloc),
      vm_isolate_snapshot_size_(0),
      isolate_snapshot_size_(0),
      vm_image_writer_(vm_image_writer),
      isolate_image_writer_(isolate_image_writer),
      seeds_(NULL),
      saved_symbol_table_(Array::Handle(zone())),
      new_vm_symbol_table_(Array::Handle(zone())),
      clustered_vm_size_(0),
      clustered_isolate_size_(0),
      mapped_data_size_(0),
      mapped_text_size_(0) {
  ASSERT(alloc_ != NULL);
  ASSERT(isolate() != NULL);
  ASSERT(heap() != NULL);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

#if defined(DEBUG)
  isolate()->ValidateClassTable();
  isolate()->ValidateConstants();
#endif  // DEBUG

  // TODO(rmacnak): The special case for AOT causes us to always generate the
  // same VM isolate snapshot for every app. AOT snapshots should be cleaned up
  // so the VM isolate snapshot is generated separately and each app is
  // generated from a VM that has loaded this snapshots, much like app-jit
  // snapshots.
  if ((vm_snapshot_data_buffer != NULL) && (kind != Snapshot::kFullAOT)) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        thread(), Timeline::GetIsolateStream(), "PrepareNewVMIsolate"));

    SeedVMIsolateVisitor visitor(thread()->zone(),
                                 Snapshot::IncludesCode(kind));
    ProgramVisitor::VisitClasses(&visitor);
    ProgramVisitor::VisitFunctions(&visitor);
    seeds_ = visitor.seeds();

    // Tuck away the current symbol table.
    saved_symbol_table_ = object_store->symbol_table();

    // Create a unified symbol table that will be written as the vm isolate's
    // symbol table.
    new_vm_symbol_table_ = Symbols::UnifiedSymbolTable();

    // Create an empty symbol table that will be written as the isolate's symbol
    // table.
    Symbols::SetupSymbolTable(isolate());
  } else {
    // Reuse the current vm isolate.
    saved_symbol_table_ = object_store->symbol_table();
    new_vm_symbol_table_ = Dart::vm_isolate()->object_store()->symbol_table();
  }

#if defined(DART_PRECOMPILER)
  if (FLAG_write_v8_snapshot_profile_to != nullptr) {
    profile_writer_ = new (zone()) V8SnapshotProfileWriter(zone());
  }
#endif
}

FullSnapshotWriter::~FullSnapshotWriter() {
  // We may run Dart code afterwards, restore the symbol table if needed.
  if (!saved_symbol_table_.IsNull()) {
    isolate()->object_store()->set_symbol_table(saved_symbol_table_);
    saved_symbol_table_ = Array::null();
  }
  new_vm_symbol_table_ = Array::null();
}

intptr_t FullSnapshotWriter::WriteVMSnapshot() {
  NOT_IN_PRODUCT(TimelineDurationScope tds(
      thread(), Timeline::GetIsolateStream(), "WriteVMSnapshot"));

  ASSERT(vm_snapshot_data_buffer_ != NULL);
  Serializer serializer(thread(), kind_, vm_snapshot_data_buffer_, alloc_,
                        kInitialSize, vm_image_writer_, /*vm=*/true,
                        profile_writer_);

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(true);
  // VM snapshot roots are:
  // - the symbol table
  // - all the token streams
  // - the stub code (App-AOT, App-JIT or Core-JIT)
  intptr_t num_objects =
      serializer.WriteVMSnapshot(new_vm_symbol_table_, seeds_);
  serializer.FillHeader(serializer.kind());
  clustered_vm_size_ = serializer.bytes_written();

  if (Snapshot::IncludesCode(kind_)) {
    vm_image_writer_->SetProfileWriter(profile_writer_);
    vm_image_writer_->Write(serializer.stream(), true);
    mapped_data_size_ += vm_image_writer_->data_size();
    mapped_text_size_ += vm_image_writer_->text_size();
    vm_image_writer_->ResetOffsets();
    vm_image_writer_->ClearProfileWriter();
  }

  // The clustered part + the direct mapped data part.
  vm_isolate_snapshot_size_ = serializer.bytes_written();
  return num_objects;
}

void FullSnapshotWriter::WriteIsolateSnapshot(intptr_t num_base_objects) {
  NOT_IN_PRODUCT(TimelineDurationScope tds(
      thread(), Timeline::GetIsolateStream(), "WriteIsolateSnapshot"));

  Serializer serializer(thread(), kind_, isolate_snapshot_data_buffer_, alloc_,
                        kInitialSize, isolate_image_writer_, /*vm=*/false,
                        profile_writer_);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(false);
  // Isolate snapshot roots are:
  // - the object store
  serializer.WriteIsolateSnapshot(num_base_objects, object_store);
  serializer.FillHeader(serializer.kind());
  clustered_isolate_size_ = serializer.bytes_written();

  if (Snapshot::IncludesCode(kind_)) {
    isolate_image_writer_->SetProfileWriter(profile_writer_);
    isolate_image_writer_->Write(serializer.stream(), false);
#if defined(DART_PRECOMPILER)
    isolate_image_writer_->DumpStatistics();
#endif

    mapped_data_size_ += isolate_image_writer_->data_size();
    mapped_text_size_ += isolate_image_writer_->text_size();
    isolate_image_writer_->ResetOffsets();
    isolate_image_writer_->ClearProfileWriter();
  }

  // The clustered part + the direct mapped data part.
  isolate_snapshot_size_ = serializer.bytes_written();
}

void FullSnapshotWriter::WriteFullSnapshot() {
  intptr_t num_base_objects;
  if (vm_snapshot_data_buffer() != NULL) {
    num_base_objects = WriteVMSnapshot();
    ASSERT(num_base_objects != 0);
  } else {
    num_base_objects = 0;
  }

  if (isolate_snapshot_data_buffer() != NULL) {
    WriteIsolateSnapshot(num_base_objects);
  }

  if (FLAG_print_snapshot_sizes) {
    OS::Print("VMIsolate(CodeSize): %" Pd "\n", clustered_vm_size_);
    OS::Print("Isolate(CodeSize): %" Pd "\n", clustered_isolate_size_);
    OS::Print("ReadOnlyData(CodeSize): %" Pd "\n", mapped_data_size_);
    OS::Print("Instructions(CodeSize): %" Pd "\n", mapped_text_size_);
    OS::Print("Total(CodeSize): %" Pd "\n",
              clustered_vm_size_ + clustered_isolate_size_ + mapped_data_size_ +
                  mapped_text_size_);
  }

#if defined(DART_PRECOMPILER)
  if (FLAG_write_v8_snapshot_profile_to != nullptr) {
    profile_writer_->Write(FLAG_write_v8_snapshot_profile_to);
  }
#endif
}

FullSnapshotReader::FullSnapshotReader(const Snapshot* snapshot,
                                       const uint8_t* instructions_buffer,
                                       const uint8_t* shared_data,
                                       const uint8_t* shared_instructions,
                                       Thread* thread)
    : kind_(snapshot->kind()),
      thread_(thread),
      buffer_(snapshot->Addr()),
      size_(snapshot->length()),
      data_image_(snapshot->DataImage()),
      instructions_image_(instructions_buffer) {
  thread->isolate()->set_compilation_allowed(kind_ != Snapshot::kFullAOT);

  if (shared_data == NULL) {
    shared_data_image_ = NULL;
  } else {
    shared_data_image_ = Snapshot::SetupFromBuffer(shared_data)->DataImage();
  }
  shared_instructions_image_ = shared_instructions;
}

RawApiError* FullSnapshotReader::ReadVMSnapshot() {
  Deserializer deserializer(thread_, kind_, buffer_, size_, data_image_,
                            instructions_image_, NULL, NULL);

  deserializer.SkipHeader();

  RawApiError* error = deserializer.VerifyVersionAndFeatures(/*isolate=*/NULL);
  if (error != ApiError::null()) {
    return error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != NULL);
    thread_->isolate()->SetupImagePage(data_image_,
                                       /* is_executable */ false);
    ASSERT(instructions_image_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_image_,
                                       /* is_executable */ true);
  }

  deserializer.ReadVMSnapshot();

  return ApiError::null();
}

RawApiError* FullSnapshotReader::ReadIsolateSnapshot() {
  Deserializer deserializer(thread_, kind_, buffer_, size_, data_image_,
                            instructions_image_, shared_data_image_,
                            shared_instructions_image_);

  deserializer.SkipHeader();

  RawApiError* error =
      deserializer.VerifyVersionAndFeatures(thread_->isolate());
  if (error != ApiError::null()) {
    return error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != NULL);
    thread_->isolate()->SetupImagePage(data_image_,
                                       /* is_executable */ false);
    ASSERT(instructions_image_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_image_,
                                       /* is_executable */ true);
    if (shared_data_image_ != NULL) {
      thread_->isolate()->SetupImagePage(shared_data_image_,
                                         /* is_executable */ false);
    }
    if (shared_instructions_image_ != NULL) {
      thread_->isolate()->SetupImagePage(shared_instructions_image_,
                                         /* is_executable */ true);
    }
  }

  deserializer.ReadIsolateSnapshot(thread_->isolate()->object_store());

  return ApiError::null();
}

}  // namespace dart
