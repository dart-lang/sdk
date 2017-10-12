// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/clustered_snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/class_finalizer.h"
#include "vm/dart.h"
#include "vm/dart_entry.h"
#include "vm/exceptions.h"
#include "vm/heap.h"
#include "vm/lockers.h"
#include "vm/longjump.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/stub_code.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/version.h"

namespace dart {

static RawObject* AllocateUninitialized(PageSpace* old_space, intptr_t size) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword address =
      old_space->TryAllocateDataBumpLocked(size, PageSpace::kForceGrowth);
  if (address == 0) {
    OUT_OF_MEMORY();
  }
  return reinterpret_cast<RawObject*>(address + kHeapObjectTag);
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
  raw->ptr()->tags_ = tags;
#if defined(HASH_IN_OBJECT_HEADER)
  raw->ptr()->hash_ = 0;
#endif
}

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClassSerializationCluster : public SerializationCluster {
 public:
  explicit ClassSerializationCluster(intptr_t num_cids)
      : predefined_(kNumPredefinedCids), objects_(num_cids) {}
  virtual ~ClassSerializationCluster() {}

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

    RawObject** from = cls->from();
    RawObject** to = cls->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClassCid);
    intptr_t count = predefined_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClass* cls = predefined_[i];
      intptr_t class_id = cls->ptr()->id_;
      s->WriteCid(class_id);
      s->AssignRef(cls);
    }
    count = objects_.length();
    s->Write<int32_t>(count);
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
    Snapshot::Kind kind = s->kind();
    RawObject** from = cls->from();
    RawObject** to = cls->to_snapshot(kind);
    for (RawObject** p = from; p <= to; p++) {
      s->WriteRef(*p);
    }
    intptr_t class_id = cls->ptr()->id_;
    if (class_id == kIllegalCid) {
      s->UnexpectedObject(cls, "Class with illegal cid");
    }
    s->WriteCid(class_id);
    s->Write<int32_t>(cls->ptr()->instance_size_in_words_);
    s->Write<int32_t>(cls->ptr()->next_field_offset_in_words_);
    s->Write<int32_t>(cls->ptr()->type_arguments_field_offset_in_words_);
    s->Write<uint16_t>(cls->ptr()->num_type_arguments_);
    s->Write<uint16_t>(cls->ptr()->num_own_type_arguments_);
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
  virtual ~ClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    predefined_start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
    count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Class::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    ClassTable* table = d->isolate()->class_table();

    for (intptr_t id = predefined_start_index_; id < predefined_stop_index_;
         id++) {
      RawClass* cls = reinterpret_cast<RawClass*>(d->Ref(id));
      RawObject** from = cls->from();
      RawObject** to_snapshot = cls->to_snapshot(kind);
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }

      intptr_t class_id = d->ReadCid();
      cls->ptr()->id_ = class_id;
      if (!RawObject::IsInternalVMdefinedClassId(class_id)) {
        cls->ptr()->instance_size_in_words_ = d->Read<int32_t>();
        cls->ptr()->next_field_offset_in_words_ = d->Read<int32_t>();
      } else {
        d->Read<int32_t>();  // Skip.
        d->Read<int32_t>();  // Skip.
      }
      cls->ptr()->type_arguments_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->num_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_own_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint16_t>();
    }

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawClass* cls = reinterpret_cast<RawClass*>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kClassCid, Class::InstanceSize(),
                                     is_vm_object);
      RawObject** from = cls->from();
      RawObject** to_snapshot = cls->to_snapshot(kind);
      RawObject** to = cls->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

      intptr_t class_id = d->ReadCid();

      ASSERT(class_id >= kNumPredefinedCids);
      Instance fake;
      cls->ptr()->handle_vtable_ = fake.vtable();

      cls->ptr()->id_ = class_id;
      cls->ptr()->instance_size_in_words_ = d->Read<int32_t>();
      cls->ptr()->next_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->type_arguments_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->num_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_own_type_arguments_ = d->Read<uint16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint16_t>();

      table->AllocateIndex(class_id);
      table->SetAt(class_id, cls);
    }
  }

  void PostLoad(const Array& refs, Snapshot::Kind kind, Zone* zone) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        Thread::Current(), Timeline::GetIsolateStream(), "PostLoadClass"));

    Class& cls = Class::Handle(zone);
    for (intptr_t i = predefined_start_index_; i < predefined_stop_index_;
         i++) {
      cls ^= refs.At(i);
      cls.RehashConstants(zone);
    }
    for (intptr_t i = start_index_; i < stop_index_; i++) {
      cls ^= refs.At(i);
      cls.RehashConstants(zone);
    }
  }

 private:
  intptr_t predefined_start_index_;
  intptr_t predefined_stop_index_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnresolvedClassSerializationCluster : public SerializationCluster {
 public:
  UnresolvedClassSerializationCluster() {}
  virtual ~UnresolvedClassSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawUnresolvedClass* cls = UnresolvedClass::RawCast(object);
    objects_.Add(cls);

    RawObject** from = cls->from();
    RawObject** to = cls->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnresolvedClassCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnresolvedClass* cls = objects_[i];
      s->AssignRef(cls);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnresolvedClass* cls = objects_[i];
      RawObject** from = cls->from();
      RawObject** to = cls->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      s->WriteTokenPosition(cls->ptr()->token_pos_);
    }
  }

 private:
  GrowableArray<RawUnresolvedClass*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnresolvedClassDeserializationCluster : public DeserializationCluster {
 public:
  UnresolvedClassDeserializationCluster() {}
  virtual ~UnresolvedClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, UnresolvedClass::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawUnresolvedClass* cls =
          reinterpret_cast<RawUnresolvedClass*>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kUnresolvedClassCid,
                                     UnresolvedClass::InstanceSize(),
                                     is_vm_object);
      RawObject** from = cls->from();
      RawObject** to = cls->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeArgumentsSerializationCluster : public SerializationCluster {
 public:
  TypeArgumentsSerializationCluster() {}
  virtual ~TypeArgumentsSerializationCluster() {}

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeArguments* type_args = objects_[i];
      intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->Write<int32_t>(length);
      s->AssignRef(type_args);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeArguments* type_args = objects_[i];
      intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->Write<int32_t>(length);
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
  virtual ~TypeArgumentsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
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
      intptr_t length = d->Read<int32_t>();
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
  PatchClassSerializationCluster() {}
  virtual ~PatchClassSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawPatchClass* cls = PatchClass::RawCast(object);
    objects_.Add(cls);

    RawObject** from = cls->from();
    RawObject** to = cls->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kPatchClassCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawPatchClass* cls = objects_[i];
      s->AssignRef(cls);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawPatchClass* cls = objects_[i];
      RawObject** from = cls->from();
      RawObject** to = cls->to_snapshot(s->kind());
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }

      s->Write<int32_t>(cls->ptr()->library_kernel_offset_);
    }
  }

 private:
  GrowableArray<RawPatchClass*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class PatchClassDeserializationCluster : public DeserializationCluster {
 public:
  PatchClassDeserializationCluster() {}
  virtual ~PatchClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = cls->from();
      RawObject** to_snapshot = cls->to_snapshot(d->kind());
      RawObject** to = cls->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

      cls->ptr()->library_kernel_offset_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FunctionSerializationCluster : public SerializationCluster {
 public:
  FunctionSerializationCluster() {}
  virtual ~FunctionSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawFunction* func = Function::RawCast(object);
    objects_.Add(func);

    RawObject** from = func->from();
    RawObject** to = func->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
    if (s->kind() == Snapshot::kFullAOT) {
      s->Push(func->ptr()->code_);
    } else if (s->kind() == Snapshot::kFullJIT) {
      NOT_IN_PRECOMPILED(s->Push(func->ptr()->unoptimized_code_));
      s->Push(func->ptr()->code_);
      s->Push(func->ptr()->ic_data_array_);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFunctionCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
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
      RawObject** from = func->from();
      RawObject** to = func->to_snapshot(s->kind());
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      if (kind == Snapshot::kFullAOT) {
        s->WriteRef(func->ptr()->code_);
      } else if (s->kind() == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(s->WriteRef(func->ptr()->unoptimized_code_));
        s->WriteRef(func->ptr()->code_);
        s->WriteRef(func->ptr()->ic_data_array_);
      }

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(func->ptr()->token_pos_);
        s->WriteTokenPosition(func->ptr()->end_token_pos_);
        s->Write<int32_t>(func->ptr()->kernel_offset_);
      }
#endif
      s->Write<int16_t>(func->ptr()->num_fixed_parameters_);
      s->Write<int16_t>(func->ptr()->num_optional_parameters_);
      s->Write<uint32_t>(func->ptr()->kind_tag_);
      if (kind == Snapshot::kFullAOT) {
        // Omit fields used to support de/reoptimization.
      } else if (!Snapshot::IncludesCode(kind)) {
#if !defined(DART_PRECOMPILED_RUNTIME)
        bool is_optimized = Code::IsOptimized(func->ptr()->code_);
        if (is_optimized) {
          s->Write<int32_t>(FLAG_optimization_counter_threshold);
        } else {
          s->Write<int32_t>(0);
        }
#endif
      }
    }
  }

 private:
  GrowableArray<RawFunction*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FunctionDeserializationCluster : public DeserializationCluster {
 public:
  FunctionDeserializationCluster() {}
  virtual ~FunctionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = func->from();
      RawObject** to_snapshot = func->to_snapshot(d->kind());
      RawObject** to = func->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }
      if (kind == Snapshot::kFullAOT) {
        func->ptr()->code_ = reinterpret_cast<RawCode*>(d->ReadRef());
      } else if (kind == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(func->ptr()->unoptimized_code_ =
                               reinterpret_cast<RawCode*>(d->ReadRef()));
        func->ptr()->code_ = reinterpret_cast<RawCode*>(d->ReadRef());
        func->ptr()->ic_data_array_ = reinterpret_cast<RawArray*>(d->ReadRef());
      }

#if defined(DEBUG)
      func->ptr()->entry_point_ = 0;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (kind != Snapshot::kFullAOT) {
        func->ptr()->token_pos_ = d->ReadTokenPosition();
        func->ptr()->end_token_pos_ = d->ReadTokenPosition();
        func->ptr()->kernel_offset_ = d->Read<int32_t>();
      }
#endif
      func->ptr()->num_fixed_parameters_ = d->Read<int16_t>();
      func->ptr()->num_optional_parameters_ = d->Read<int16_t>();
      func->ptr()->kind_tag_ = d->Read<uint32_t>();
      if (kind == Snapshot::kFullAOT) {
        // Omit fields used to support de/reoptimization.
      } else {
#if !defined(DART_PRECOMPILED_RUNTIME)
        if (Snapshot::IncludesCode(kind)) {
          func->ptr()->usage_counter_ = 0;
        } else {
          func->ptr()->usage_counter_ = d->Read<int32_t>();
        }
        func->ptr()->deoptimization_counter_ = 0;
        func->ptr()->optimized_instruction_count_ = 0;
        func->ptr()->optimized_call_site_count_ = 0;
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
      }
    } else if (kind == Snapshot::kFullJIT) {
      Function& func = Function::Handle(zone);
      Code& code = Code::Handle(zone);
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        code ^= func.CurrentCode();
        if (func.HasCode() && !code.IsDisabled()) {
          func.SetInstructions(code);
          func.SetWasCompiled(true);
        } else {
          func.ClearCode();
          func.SetWasCompiled(false);
        }
      }
    } else {
      Function& func = Function::Handle(zone);
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        func.ClearICDataArray();
        func.ClearCode();
        func.SetWasCompiled(false);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureDataSerializationCluster : public SerializationCluster {
 public:
  ClosureDataSerializationCluster() {}
  virtual ~ClosureDataSerializationCluster() {}

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClosureData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawClosureData* data = objects_[i];
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
  virtual ~ClosureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
  SignatureDataSerializationCluster() {}
  virtual ~SignatureDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawSignatureData* data = SignatureData::RawCast(object);
    objects_.Add(data);

    RawObject** from = data->from();
    RawObject** to = data->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSignatureDataCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawSignatureData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawSignatureData* data = objects_[i];
      RawObject** from = data->from();
      RawObject** to = data->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawSignatureData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SignatureDataDeserializationCluster : public DeserializationCluster {
 public:
  SignatureDataDeserializationCluster() {}
  virtual ~SignatureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = data->from();
      RawObject** to = data->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RedirectionDataSerializationCluster : public SerializationCluster {
 public:
  RedirectionDataSerializationCluster() {}
  virtual ~RedirectionDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawRedirectionData* data = RedirectionData::RawCast(object);
    objects_.Add(data);

    RawObject** from = data->from();
    RawObject** to = data->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kRedirectionDataCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawRedirectionData* data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawRedirectionData* data = objects_[i];
      RawObject** from = data->from();
      RawObject** to = data->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawRedirectionData*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RedirectionDataDeserializationCluster : public DeserializationCluster {
 public:
  RedirectionDataDeserializationCluster() {}
  virtual ~RedirectionDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = data->from();
      RawObject** to = data->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FieldSerializationCluster : public SerializationCluster {
 public:
  FieldSerializationCluster() {}
  virtual ~FieldSerializationCluster() {}

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
    s->Write<int32_t>(count);
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
#if !defined(DART_PRECOMPILED_RUNTIME)
        s->Write<int32_t>(field->ptr()->kernel_offset_);
#endif
      }
      s->Write<uint8_t>(field->ptr()->kind_bits_);
    }
  }

 private:
  GrowableArray<RawField*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FieldDeserializationCluster : public DeserializationCluster {
 public:
  FieldDeserializationCluster() {}
  virtual ~FieldDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = field->from();
      RawObject** to_snapshot = field->to_snapshot(kind);
      RawObject** to = field->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

      if (kind != Snapshot::kFullAOT) {
        field->ptr()->token_pos_ = d->ReadTokenPosition();
        field->ptr()->end_token_pos_ = d->ReadTokenPosition();
        field->ptr()->guarded_cid_ = d->ReadCid();
        field->ptr()->is_nullable_ = d->ReadCid();
#if !defined(DART_PRECOMPILED_RUNTIME)
        field->ptr()->kernel_offset_ = d->Read<int32_t>();
#endif
      }
      field->ptr()->kind_bits_ = d->Read<uint8_t>();
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
class LiteralTokenSerializationCluster : public SerializationCluster {
 public:
  LiteralTokenSerializationCluster() {}
  virtual ~LiteralTokenSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLiteralToken* token = LiteralToken::RawCast(object);
    objects_.Add(token);

    RawObject** from = token->from();
    RawObject** to = token->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLiteralTokenCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLiteralToken* token = objects_[i];
      s->AssignRef(token);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLiteralToken* token = objects_[i];
      RawObject** from = token->from();
      RawObject** to = token->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      s->Write<int32_t>(token->ptr()->kind_);
    }
  }

 private:
  GrowableArray<RawLiteralToken*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LiteralTokenDeserializationCluster : public DeserializationCluster {
 public:
  LiteralTokenDeserializationCluster() {}
  virtual ~LiteralTokenDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LiteralToken::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLiteralToken* token = reinterpret_cast<RawLiteralToken*>(d->Ref(id));
      Deserializer::InitializeHeader(
          token, kLiteralTokenCid, LiteralToken::InstanceSize(), is_vm_object);
      RawObject** from = token->from();
      RawObject** to = token->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      token->ptr()->kind_ = static_cast<Token::Kind>(d->Read<int32_t>());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TokenStreamSerializationCluster : public SerializationCluster {
 public:
  TokenStreamSerializationCluster() {}
  virtual ~TokenStreamSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTokenStream* stream = TokenStream::RawCast(object);
    objects_.Add(stream);

    RawObject** from = stream->from();
    RawObject** to = stream->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTokenStreamCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTokenStream* stream = objects_[i];
      s->AssignRef(stream);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTokenStream* stream = objects_[i];
      RawObject** from = stream->from();
      RawObject** to = stream->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawTokenStream*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TokenStreamDeserializationCluster : public DeserializationCluster {
 public:
  TokenStreamDeserializationCluster() {}
  virtual ~TokenStreamDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, TokenStream::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTokenStream* stream = reinterpret_cast<RawTokenStream*>(d->Ref(id));
      Deserializer::InitializeHeader(stream, kTokenStreamCid,
                                     TokenStream::InstanceSize(), is_vm_object);
      RawObject** from = stream->from();
      RawObject** to = stream->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ScriptSerializationCluster : public SerializationCluster {
 public:
  ScriptSerializationCluster() {}
  virtual ~ScriptSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawScript* script = Script::RawCast(object);
    objects_.Add(script);

    RawObject** from = script->from();
    RawObject** to = script->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kScriptCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawScript* script = objects_[i];
      s->AssignRef(script);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawScript* script = objects_[i];
      RawObject** from = script->from();
      RawObject** to = script->to_snapshot(kind);
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }

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
  virtual ~ScriptDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Script::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawScript* script = reinterpret_cast<RawScript*>(d->Ref(id));
      Deserializer::InitializeHeader(script, kScriptCid, Script::InstanceSize(),
                                     is_vm_object);
      RawObject** from = script->from();
      RawObject** to_snapshot = script->to_snapshot(kind);
      RawObject** to = script->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

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
  LibrarySerializationCluster() {}
  virtual ~LibrarySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLibrary* lib = Library::RawCast(object);
    objects_.Add(lib);

    RawObject** from = lib->from();
    RawObject** to = lib->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLibrary* lib = objects_[i];
      s->AssignRef(lib);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLibrary* lib = objects_[i];
      RawObject** from = lib->from();
      RawObject** to = lib->to_snapshot(s->kind());
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }

      s->Write<int32_t>(lib->ptr()->index_);
      s->Write<int32_t>(lib->ptr()->kernel_offset_);
      s->Write<uint16_t>(lib->ptr()->num_imports_);
      s->Write<int8_t>(lib->ptr()->load_state_);
      s->Write<bool>(lib->ptr()->corelib_imported_);
      s->Write<bool>(lib->ptr()->is_dart_scheme_);
      s->Write<bool>(lib->ptr()->debuggable_);
    }
  }

 private:
  GrowableArray<RawLibrary*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LibraryDeserializationCluster : public DeserializationCluster {
 public:
  LibraryDeserializationCluster() {}
  virtual ~LibraryDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = lib->from();
      RawObject** to_snapshot = lib->to_snapshot(d->kind());
      RawObject** to = lib->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

      lib->ptr()->native_entry_resolver_ = NULL;
      lib->ptr()->native_entry_symbol_resolver_ = NULL;
      lib->ptr()->index_ = d->Read<int32_t>();
      lib->ptr()->kernel_offset_ = d->Read<int32_t>();
      lib->ptr()->num_imports_ = d->Read<uint16_t>();
      lib->ptr()->load_state_ = d->Read<int8_t>();
      lib->ptr()->corelib_imported_ = d->Read<bool>();
      lib->ptr()->is_dart_scheme_ = d->Read<bool>();
      lib->ptr()->debuggable_ = d->Read<bool>();
      lib->ptr()->is_in_fullsnapshot_ = true;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class NamespaceSerializationCluster : public SerializationCluster {
 public:
  NamespaceSerializationCluster() {}
  virtual ~NamespaceSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawNamespace* ns = Namespace::RawCast(object);
    objects_.Add(ns);

    RawObject** from = ns->from();
    RawObject** to = ns->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kNamespaceCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawNamespace* ns = objects_[i];
      s->AssignRef(ns);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawNamespace* ns = objects_[i];
      RawObject** from = ns->from();
      RawObject** to = ns->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawNamespace*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class NamespaceDeserializationCluster : public DeserializationCluster {
 public:
  NamespaceDeserializationCluster() {}
  virtual ~NamespaceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = ns->from();
      RawObject** to = ns->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class CodeSerializationCluster : public SerializationCluster {
 public:
  CodeSerializationCluster() {}
  virtual ~CodeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawCode* code = Code::RawCast(object);
    objects_.Add(code);

    s->Push(code->ptr()->object_pool_);
    s->Push(code->ptr()->owner_);
    s->Push(code->ptr()->exception_handlers_);
    s->Push(code->ptr()->pc_descriptors_);
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
    s->Push(code->ptr()->catch_entry_.catch_entry_state_maps_);
#else
    s->Push(code->ptr()->catch_entry_.variables_);
#endif
    s->Push(code->ptr()->stackmaps_);
    if (!FLAG_dwarf_stack_traces) {
      s->Push(code->ptr()->inlined_id_to_function_);
      s->Push(code->ptr()->code_source_map_);
    }
    if (s->kind() != Snapshot::kFullAOT) {
      s->Push(code->ptr()->await_token_positions_);
    }

    if (s->kind() == Snapshot::kFullJIT) {
      s->Push(code->ptr()->deopt_info_array_);
      s->Push(code->ptr()->static_calls_target_table_);
      NOT_IN_PRODUCT(s->Push(code->ptr()->return_address_metadata_));
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kCodeCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
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

      RawInstructions* instr = code->ptr()->instructions_;
      int32_t text_offset = s->GetTextOffset(instr, code);
      s->Write<int32_t>(text_offset);
      if (s->kind() == Snapshot::kFullJIT) {
        // TODO(rmacnak): Fix references to disabled code before serializing.
        if (code->ptr()->active_instructions_ != code->ptr()->instructions_) {
          // For now, we write the FixCallersTarget or equivalent stub. This
          // will cause a fixup if this code is called.
          instr = code->ptr()->active_instructions_;
          text_offset = s->GetTextOffset(instr, code);
        }
        s->Write<int32_t>(text_offset);
      }

      s->WriteRef(code->ptr()->object_pool_);
      s->WriteRef(code->ptr()->owner_);
      s->WriteRef(code->ptr()->exception_handlers_);
      s->WriteRef(code->ptr()->pc_descriptors_);
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
      s->WriteRef(code->ptr()->catch_entry_.catch_entry_state_maps_);
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
      if (s->kind() != Snapshot::kFullAOT) {
        s->WriteRef(code->ptr()->await_token_positions_);
      }
      if (s->kind() == Snapshot::kFullJIT) {
        s->WriteRef(code->ptr()->deopt_info_array_);
        s->WriteRef(code->ptr()->static_calls_target_table_);
        NOT_IN_PRODUCT(s->WriteRef(code->ptr()->return_address_metadata_));
      }

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
  virtual ~CodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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

      int32_t text_offset = d->Read<int32_t>();
      RawInstructions* instr = d->GetInstructionsAt(text_offset);

      code->ptr()->entry_point_ = Instructions::UncheckedEntryPoint(instr);
      code->ptr()->checked_entry_point_ =
          Instructions::CheckedEntryPoint(instr);
      NOT_IN_PRECOMPILED(code->ptr()->active_instructions_ = instr);
      code->ptr()->instructions_ = instr;

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() == Snapshot::kFullJIT) {
        int32_t text_offset = d->Read<int32_t>();
        RawInstructions* instr = d->GetInstructionsAt(text_offset);
        code->ptr()->active_instructions_ = instr;
        code->ptr()->entry_point_ = Instructions::UncheckedEntryPoint(instr);
        code->ptr()->checked_entry_point_ =
            Instructions::CheckedEntryPoint(instr);
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
      code->ptr()->catch_entry_.catch_entry_state_maps_ =
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
      code->ptr()->await_token_positions_ =
          reinterpret_cast<RawArray*>(d->ReadRef());

      if (d->kind() == Snapshot::kFullJIT) {
        code->ptr()->deopt_info_array_ =
            reinterpret_cast<RawArray*>(d->ReadRef());
        code->ptr()->static_calls_target_table_ =
            reinterpret_cast<RawArray*>(d->ReadRef());
#if defined(PRODUCT)
        code->ptr()->return_address_metadata_ = Object::null();
#else
        code->ptr()->return_address_metadata_ = d->ReadRef();
#endif
      } else {
        code->ptr()->deopt_info_array_ = Array::null();
        code->ptr()->static_calls_target_table_ = Array::null();
        code->ptr()->return_address_metadata_ = Object::null();
      }

      code->ptr()->var_descriptors_ = LocalVarDescriptors::null();
      code->ptr()->comments_ = Array::null();

      code->ptr()->compile_timestamp_ = 0;
#endif  // !DART_PRECOMPILED_RUNTIME

      code->ptr()->state_bits_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ObjectPoolSerializationCluster : public SerializationCluster {
 public:
  ObjectPoolSerializationCluster() {}
  virtual ~ObjectPoolSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawObjectPool* pool = ObjectPool::RawCast(object);
    objects_.Add(pool);

    intptr_t length = pool->ptr()->length_;
    RawTypedData* info_array = pool->ptr()->info_array_;

    for (intptr_t i = 0; i < length; i++) {
      ObjectPool::EntryType entry_type =
          static_cast<ObjectPool::EntryType>(info_array->ptr()->data()[i]);
      if (entry_type == ObjectPool::kTaggedObject) {
        s->Push(pool->ptr()->data()[i].raw_obj_);
      }
    }

    // TODO(rmacnak): Allocate the object pool and its info array together.
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kObjectPoolCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawObjectPool* pool = objects_[i];
      intptr_t length = pool->ptr()->length_;
      s->Write<int32_t>(length);
      s->AssignRef(pool);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawObjectPool* pool = objects_[i];
      RawTypedData* info_array = pool->ptr()->info_array_;
      intptr_t length = pool->ptr()->length_;
      s->Write<int32_t>(length);
      for (intptr_t j = 0; j < length; j++) {
        ObjectPool::EntryType entry_type =
            static_cast<ObjectPool::EntryType>(info_array->ptr()->data()[j]);
        s->Write<int8_t>(entry_type);
        RawObjectPool::Entry& entry = pool->ptr()->data()[j];
        switch (entry_type) {
          case ObjectPool::kTaggedObject: {
#if !defined(TARGET_ARCH_DBC)
            if ((entry.raw_obj_ ==
                 StubCode::CallNoScopeNative_entry()->code()) ||
                (entry.raw_obj_ ==
                 StubCode::CallAutoScopeNative_entry()->code())) {
              // Natives can run while precompiling, becoming linked and
              // switching their stub. Reset to the initial stub used for
              // lazy-linking.
              s->WriteRef(StubCode::CallBootstrapNative_entry()->code());
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
          case ObjectPool::kNativeEntry: {
// Write nothing. Will initialize with the lazy link entry.
#if defined(TARGET_ARCH_DBC)
            UNREACHABLE();  // DBC does not support lazy native call linking.
#endif
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
  virtual ~ObjectPoolDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(
          AllocateUninitialized(old_space, ObjectPool::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();
    PageSpace* old_space = d->heap()->old_space();
    for (intptr_t id = start_index_; id < stop_index_; id += 1) {
      intptr_t length = d->Read<int32_t>();
      RawTypedData* info_array = reinterpret_cast<RawTypedData*>(
          AllocateUninitialized(old_space, TypedData::InstanceSize(length)));
      Deserializer::InitializeHeader(info_array, kTypedDataUint8ArrayCid,
                                     TypedData::InstanceSize(length),
                                     is_vm_object);
      info_array->ptr()->length_ = Smi::New(length);
      RawObjectPool* pool = reinterpret_cast<RawObjectPool*>(d->Ref(id + 0));
      Deserializer::InitializeHeader(
          pool, kObjectPoolCid, ObjectPool::InstanceSize(length), is_vm_object);
      pool->ptr()->length_ = length;
      pool->ptr()->info_array_ = info_array;
      for (intptr_t j = 0; j < length; j++) {
        ObjectPool::EntryType entry_type =
            static_cast<ObjectPool::EntryType>(d->Read<int8_t>());
        info_array->ptr()->data()[j] = entry_type;
        RawObjectPool::Entry& entry = pool->ptr()->data()[j];
        switch (entry_type) {
          case ObjectPool::kTaggedObject:
            entry.raw_obj_ = d->ReadRef();
            break;
          case ObjectPool::kImmediate:
            entry.raw_value_ = d->Read<intptr_t>();
            break;
          case ObjectPool::kNativeEntry: {
#if !defined(TARGET_ARCH_DBC)
            // Read nothing. Initialize with the lazy link entry.
            uword new_entry = NativeEntry::LinkNativeCallEntry();
            entry.raw_value_ = static_cast<intptr_t>(new_entry);
#else
            UNREACHABLE();  // DBC does not support lazy native call linking.
#endif
            break;
          }
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
  explicit RODataSerializationCluster(intptr_t cid) : cid_(cid) {}
  virtual ~RODataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    objects_.Add(object);

    // A string's hash must already be computed when we write it because it
    // will be loaded into read-only memory.
    if (cid_ == kOneByteStringCid) {
      RawOneByteString* str = static_cast<RawOneByteString*>(object);
      if (String::GetCachedHash(str) == 0) {
        intptr_t hash =
            String::Hash(str->ptr()->data(), Smi::Value(str->ptr()->length_));
        String::SetCachedHash(str, hash);
      }
      ASSERT(String::GetCachedHash(str) != 0);
    } else if (cid_ == kTwoByteStringCid) {
      RawTwoByteString* str = static_cast<RawTwoByteString*>(object);
      if (String::GetCachedHash(str) == 0) {
        intptr_t hash = String::Hash(str->ptr()->data(),
                                     Smi::Value(str->ptr()->length_) * 2);
        String::SetCachedHash(str, hash);
      }
      ASSERT(String::GetCachedHash(str) != 0);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawObject* object = objects_[i];
      int32_t rodata_offset = s->GetDataOffset(object);
      s->Write<int32_t>(rodata_offset);
      s->AssignRef(object);
    }
  }

  void WriteFill(Serializer* s) {
    // No-op.
  }

 private:
  const intptr_t cid_;
  GrowableArray<RawObject*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RODataDeserializationCluster : public DeserializationCluster {
 public:
  RODataDeserializationCluster() {}
  virtual ~RODataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      int32_t rodata_offset = d->Read<int32_t>();
      d->AssignRef(d->GetObjectAt(rodata_offset));
    }
  }

  void ReadFill(Deserializer* d) {
    // No-op.
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ExceptionHandlersSerializationCluster : public SerializationCluster {
 public:
  ExceptionHandlersSerializationCluster() {}
  virtual ~ExceptionHandlersSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawExceptionHandlers* handlers = ExceptionHandlers::RawCast(object);
    objects_.Add(handlers);

    s->Push(handlers->ptr()->handled_types_data_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kExceptionHandlersCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawExceptionHandlers* handlers = objects_[i];
      intptr_t length = handlers->ptr()->num_entries_;
      s->Write<int32_t>(length);
      s->AssignRef(handlers);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawExceptionHandlers* handlers = objects_[i];
      intptr_t length = handlers->ptr()->num_entries_;
      s->Write<int32_t>(length);
      s->WriteRef(handlers->ptr()->handled_types_data_);

      uint8_t* data = reinterpret_cast<uint8_t*>(handlers->ptr()->data());
      intptr_t length_in_bytes = length * sizeof(ExceptionHandlerInfo);
      s->WriteBytes(data, length_in_bytes);
    }
  }

 private:
  GrowableArray<RawExceptionHandlers*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExceptionHandlersDeserializationCluster : public DeserializationCluster {
 public:
  ExceptionHandlersDeserializationCluster() {}
  virtual ~ExceptionHandlersDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
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
      intptr_t length = d->Read<int32_t>();
      Deserializer::InitializeHeader(handlers, kExceptionHandlersCid,
                                     ExceptionHandlers::InstanceSize(length),
                                     is_vm_object);
      handlers->ptr()->num_entries_ = length;
      handlers->ptr()->handled_types_data_ =
          reinterpret_cast<RawArray*>(d->ReadRef());

      uint8_t* data = reinterpret_cast<uint8_t*>(handlers->ptr()->data());
      intptr_t length_in_bytes = length * sizeof(ExceptionHandlerInfo);
      d->ReadBytes(data, length_in_bytes);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ContextSerializationCluster : public SerializationCluster {
 public:
  ContextSerializationCluster() {}
  virtual ~ContextSerializationCluster() {}

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawContext* context = objects_[i];
      intptr_t length = context->ptr()->num_variables_;
      s->Write<int32_t>(length);
      s->AssignRef(context);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawContext* context = objects_[i];
      intptr_t length = context->ptr()->num_variables_;
      s->Write<int32_t>(length);
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
  virtual ~ContextDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(
          AllocateUninitialized(old_space, Context::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawContext* context = reinterpret_cast<RawContext*>(d->Ref(id));
      intptr_t length = d->Read<int32_t>();
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
  ContextScopeSerializationCluster() {}
  virtual ~ContextScopeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawContextScope* scope = ContextScope::RawCast(object);
    objects_.Add(scope);

    intptr_t length = scope->ptr()->num_variables_;
    RawObject** from = scope->from();
    RawObject** to = scope->to(length);
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kContextScopeCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawContextScope* scope = objects_[i];
      intptr_t length = scope->ptr()->num_variables_;
      s->Write<int32_t>(length);
      s->AssignRef(scope);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawContextScope* scope = objects_[i];
      intptr_t length = scope->ptr()->num_variables_;
      s->Write<int32_t>(length);
      s->Write<bool>(scope->ptr()->is_implicit_);
      RawObject** from = scope->from();
      RawObject** to = scope->to(length);
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawContextScope*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ContextScopeDeserializationCluster : public DeserializationCluster {
 public:
  ContextScopeDeserializationCluster() {}
  virtual ~ContextScopeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(
          AllocateUninitialized(old_space, ContextScope::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawContextScope* scope = reinterpret_cast<RawContextScope*>(d->Ref(id));
      intptr_t length = d->Read<int32_t>();
      Deserializer::InitializeHeader(scope, kContextScopeCid,
                                     ContextScope::InstanceSize(length),
                                     is_vm_object);
      scope->ptr()->num_variables_ = length;
      scope->ptr()->is_implicit_ = d->Read<bool>();
      RawObject** from = scope->from();
      RawObject** to = scope->to(length);
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnlinkedCallSerializationCluster : public SerializationCluster {
 public:
  UnlinkedCallSerializationCluster() {}
  virtual ~UnlinkedCallSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawUnlinkedCall* unlinked = UnlinkedCall::RawCast(object);
    objects_.Add(unlinked);

    RawObject** from = unlinked->from();
    RawObject** to = unlinked->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnlinkedCallCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnlinkedCall* unlinked = objects_[i];
      s->AssignRef(unlinked);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawUnlinkedCall* unlinked = objects_[i];
      RawObject** from = unlinked->from();
      RawObject** to = unlinked->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawUnlinkedCall*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnlinkedCallDeserializationCluster : public DeserializationCluster {
 public:
  UnlinkedCallDeserializationCluster() {}
  virtual ~UnlinkedCallDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = unlinked->from();
      RawObject** to = unlinked->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ICDataSerializationCluster : public SerializationCluster {
 public:
  ICDataSerializationCluster() {}
  virtual ~ICDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawICData* ic = ICData::RawCast(object);
    objects_.Add(ic);

    RawObject** from = ic->from();
    RawObject** to = ic->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kICDataCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
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
      RawObject** from = ic->from();
      RawObject** to = ic->to_snapshot(kind);
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      if (kind != Snapshot::kFullAOT) {
        NOT_IN_PRECOMPILED(s->Write<int32_t>(ic->ptr()->deopt_id_));
      }
      s->Write<uint32_t>(ic->ptr()->state_bits_);
#if defined(TAG_IC_DATA)
      s->Write<int32_t>(ic->ptr()->tag_);
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
  virtual ~ICDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, ICData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawICData* ic = reinterpret_cast<RawICData*>(d->Ref(id));
      Deserializer::InitializeHeader(ic, kICDataCid, ICData::InstanceSize(),
                                     is_vm_object);
      RawObject** from = ic->from();
      RawObject** to_snapshot = ic->to_snapshot(kind);
      RawObject** to = ic->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }
      NOT_IN_PRECOMPILED(ic->ptr()->deopt_id_ = d->Read<int32_t>());
      ic->ptr()->state_bits_ = d->Read<int32_t>();
#if defined(TAG_IC_DATA)
      ic->ptr()->tag_ = d->Read<int32_t>();
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MegamorphicCacheSerializationCluster : public SerializationCluster {
 public:
  MegamorphicCacheSerializationCluster() {}
  virtual ~MegamorphicCacheSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawMegamorphicCache* cache = MegamorphicCache::RawCast(object);
    objects_.Add(cache);

    RawObject** from = cache->from();
    RawObject** to = cache->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kMegamorphicCacheCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawMegamorphicCache* cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawMegamorphicCache* cache = objects_[i];
      RawObject** from = cache->from();
      RawObject** to = cache->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
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
  virtual ~MegamorphicCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = cache->from();
      RawObject** to = cache->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      cache->ptr()->filled_entry_count_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SubtypeTestCacheSerializationCluster : public SerializationCluster {
 public:
  SubtypeTestCacheSerializationCluster() {}
  virtual ~SubtypeTestCacheSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawSubtypeTestCache* cache = SubtypeTestCache::RawCast(object);
    objects_.Add(cache);
    s->Push(cache->ptr()->cache_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSubtypeTestCacheCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawSubtypeTestCache* cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawSubtypeTestCache* cache = objects_[i];
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
  virtual ~SubtypeTestCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
  LanguageErrorSerializationCluster() {}
  virtual ~LanguageErrorSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLanguageError* error = LanguageError::RawCast(object);
    objects_.Add(error);

    RawObject** from = error->from();
    RawObject** to = error->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLanguageErrorCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLanguageError* error = objects_[i];
      s->AssignRef(error);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLanguageError* error = objects_[i];
      RawObject** from = error->from();
      RawObject** to = error->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
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
  virtual ~LanguageErrorDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = error->from();
      RawObject** to = error->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      error->ptr()->token_pos_ = d->ReadTokenPosition();
      error->ptr()->report_after_token_ = d->Read<bool>();
      error->ptr()->kind_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnhandledExceptionSerializationCluster : public SerializationCluster {
 public:
  UnhandledExceptionSerializationCluster() {}
  virtual ~UnhandledExceptionSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawUnhandledException* exception = UnhandledException::RawCast(object);
    objects_.Add(exception);

    RawObject** from = exception->from();
    RawObject** to = exception->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnhandledExceptionCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawUnhandledException* exception = objects_[i];
      s->AssignRef(exception);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawUnhandledException* exception = objects_[i];
      RawObject** from = exception->from();
      RawObject** to = exception->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawUnhandledException*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnhandledExceptionDeserializationCluster : public DeserializationCluster {
 public:
  UnhandledExceptionDeserializationCluster() {}
  virtual ~UnhandledExceptionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = exception->from();
      RawObject** to = exception->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class InstanceSerializationCluster : public SerializationCluster {
 public:
  explicit InstanceSerializationCluster(intptr_t cid) : cid_(cid) {
    RawClass* cls = Isolate::Current()->class_table()->At(cid);
    next_field_offset_in_words_ = cls->ptr()->next_field_offset_in_words_;
    instance_size_in_words_ = cls->ptr()->instance_size_in_words_;
    ASSERT(next_field_offset_in_words_ > 0);
    ASSERT(instance_size_in_words_ > 0);
  }
  virtual ~InstanceSerializationCluster() {}

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
    s->Write<int32_t>(count);

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
  virtual ~InstanceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
  LibraryPrefixSerializationCluster() {}
  virtual ~LibraryPrefixSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawLibraryPrefix* prefix = LibraryPrefix::RawCast(object);
    objects_.Add(prefix);

    RawObject** from = prefix->from();
    RawObject** to = prefix->to_snapshot(s->kind());
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryPrefixCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLibraryPrefix* prefix = objects_[i];
      s->AssignRef(prefix);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLibraryPrefix* prefix = objects_[i];
      RawObject** from = prefix->from();
      RawObject** to = prefix->to_snapshot(kind);
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
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
  virtual ~LibraryPrefixDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LibraryPrefix::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    Snapshot::Kind kind = d->kind();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawLibraryPrefix* prefix =
          reinterpret_cast<RawLibraryPrefix*>(d->Ref(id));
      Deserializer::InitializeHeader(prefix, kLibraryPrefixCid,
                                     LibraryPrefix::InstanceSize(),
                                     is_vm_object);
      RawObject** from = prefix->from();
      RawObject** to_snapshot = prefix->to_snapshot(kind);
      RawObject** to = prefix->to();
      for (RawObject** p = from; p <= to_snapshot; p++) {
        *p = d->ReadRef();
      }
      for (RawObject** p = to_snapshot + 1; p <= to; p++) {
        *p = Object::null();
      }

      prefix->ptr()->num_imports_ = d->Read<uint16_t>();
      prefix->ptr()->is_deferred_load_ = d->Read<bool>();
      prefix->ptr()->is_loaded_ = !prefix->ptr()->is_deferred_load_;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeSerializationCluster : public SerializationCluster {
 public:
  TypeSerializationCluster() {}
  virtual ~TypeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawType* type = Type::RawCast(object);
    if (type->IsCanonical()) {
      canonical_objects_.Add(type);
    } else {
      objects_.Add(type);
    }

    RawObject** from = type->from();
    RawObject** to = type->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = canonical_objects_[i];
      s->AssignRef(type);
    }
    count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = canonical_objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = canonical_objects_[i];
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int8_t>(type->ptr()->type_state_);
    }
    count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawType* type = objects_[i];
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int8_t>(type->ptr()->type_state_);
    }
  }

 private:
  GrowableArray<RawType*> canonical_objects_;
  GrowableArray<RawType*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeDeserializationCluster : public DeserializationCluster {
 public:
  TypeDeserializationCluster() {}
  virtual ~TypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    canonical_start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Type::InstanceSize()));
    }
    canonical_stop_index_ = d->next_index();

    start_index_ = d->next_index();
    count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Type::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = canonical_start_index_; id < canonical_stop_index_;
         id++) {
      RawType* type = reinterpret_cast<RawType*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_vm_object, true);
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->type_state_ = d->Read<int8_t>();
    }

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawType* type = reinterpret_cast<RawType*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_vm_object);
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->type_state_ = d->Read<int8_t>();
    }
  }

 private:
  intptr_t canonical_start_index_;
  intptr_t canonical_stop_index_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeRefSerializationCluster : public SerializationCluster {
 public:
  TypeRefSerializationCluster() {}
  virtual ~TypeRefSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypeRef* type = TypeRef::RawCast(object);
    objects_.Add(type);

    RawObject** from = type->from();
    RawObject** to = type->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeRefCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeRef* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeRef* type = objects_[i];
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawTypeRef*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeRefDeserializationCluster : public DeserializationCluster {
 public:
  TypeRefDeserializationCluster() {}
  virtual ~TypeRefDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, TypeRef::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypeRef* type = reinterpret_cast<RawTypeRef*>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeRefCid, TypeRef::InstanceSize(),
                                     is_vm_object);
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeParameterSerializationCluster : public SerializationCluster {
 public:
  TypeParameterSerializationCluster() {}
  virtual ~TypeParameterSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypeParameter* type = TypeParameter::RawCast(object);
    objects_.Add(type);
    ASSERT(!type->IsCanonical());

    RawObject** from = type->from();
    RawObject** to = type->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeParameterCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypeParameter* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTypeParameter* type = objects_[i];
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
      s->Write<int32_t>(type->ptr()->parameterized_class_id_);
      s->WriteTokenPosition(type->ptr()->token_pos_);
      s->Write<int16_t>(type->ptr()->index_);
      s->Write<int8_t>(type->ptr()->type_state_);
    }
  }

 private:
  GrowableArray<RawTypeParameter*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeParameterDeserializationCluster : public DeserializationCluster {
 public:
  TypeParameterDeserializationCluster() {}
  virtual ~TypeParameterDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, TypeParameter::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTypeParameter* type = reinterpret_cast<RawTypeParameter*>(d->Ref(id));
      Deserializer::InitializeHeader(
          type, kTypeParameterCid, TypeParameter::InstanceSize(), is_vm_object);
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
      type->ptr()->parameterized_class_id_ = d->Read<int32_t>();
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->index_ = d->Read<int16_t>();
      type->ptr()->type_state_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class BoundedTypeSerializationCluster : public SerializationCluster {
 public:
  BoundedTypeSerializationCluster() {}
  virtual ~BoundedTypeSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawBoundedType* type = BoundedType::RawCast(object);
    objects_.Add(type);

    RawObject** from = type->from();
    RawObject** to = type->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kBoundedTypeCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawBoundedType* type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawBoundedType* type = objects_[i];
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawBoundedType*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class BoundedTypeDeserializationCluster : public DeserializationCluster {
 public:
  BoundedTypeDeserializationCluster() {}
  virtual ~BoundedTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = type->from();
      RawObject** to = type->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureSerializationCluster : public SerializationCluster {
 public:
  ClosureSerializationCluster() {}
  virtual ~ClosureSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawClosure* closure = Closure::RawCast(object);
    objects_.Add(closure);

    RawObject** from = closure->from();
    RawObject** to = closure->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClosureCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawClosure* closure = objects_[i];
      s->AssignRef(closure);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawClosure* closure = objects_[i];
      s->Write<bool>(closure->IsCanonical());
      RawObject** from = closure->from();
      RawObject** to = closure->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawClosure*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClosureDeserializationCluster : public DeserializationCluster {
 public:
  ClosureDeserializationCluster() {}
  virtual ~ClosureDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = closure->from();
      RawObject** to = closure->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MintSerializationCluster : public SerializationCluster {
 public:
  MintSerializationCluster() {}
  virtual ~MintSerializationCluster() {}

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

    s->Write<int32_t>(smis_.length() + mints_.length());
    for (intptr_t i = 0; i < smis_.length(); i++) {
      RawSmi* smi = smis_[i];
      s->Write<bool>(true);
      s->Write<int64_t>(Smi::Value(smi));
      s->AssignRef(smi);
    }
    for (intptr_t i = 0; i < mints_.length(); i++) {
      RawMint* mint = mints_[i];
      s->Write<bool>(mint->IsCanonical());
      s->Write<int64_t>(mint->ptr()->value_);
      s->AssignRef(mint);
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
  virtual ~MintDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    PageSpace* old_space = d->heap()->old_space();
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    start_index_ = d->next_index();
    intptr_t count = d->Read<int32_t>();
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

    const GrowableObjectArray& new_constants =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    Object& number = Object::Handle(zone);
    for (intptr_t i = start_index_; i < stop_index_; i++) {
      number = refs.At(i);
      if (number.IsMint() && number.IsCanonical()) {
        new_constants.Add(number);
      }
    }
    const Array& constants_array =
        Array::Handle(zone, Array::MakeFixedLength(new_constants));
    const Class& mint_cls =
        Class::Handle(zone, Isolate::Current()->object_store()->mint_class());
    mint_cls.set_constants(constants_array);
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class BigintSerializationCluster : public SerializationCluster {
 public:
  BigintSerializationCluster() {}
  virtual ~BigintSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawBigint* bigint = Bigint::RawCast(object);
    objects_.Add(bigint);

    RawObject** from = bigint->from();
    RawObject** to = bigint->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kBigintCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawBigint* bigint = objects_[i];
      s->AssignRef(bigint);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawBigint* bigint = objects_[i];
      s->Write<bool>(bigint->IsCanonical());
      RawObject** from = bigint->from();
      RawObject** to = bigint->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawBigint*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class BigintDeserializationCluster : public DeserializationCluster {
 public:
  BigintDeserializationCluster() {}
  virtual ~BigintDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Bigint::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawBigint* bigint = reinterpret_cast<RawBigint*>(d->Ref(id));
      bool is_canonical = d->Read<bool>();
      Deserializer::InitializeHeader(bigint, kBigintCid, Bigint::InstanceSize(),
                                     is_vm_object, is_canonical);
      RawObject** from = bigint->from();
      RawObject** to = bigint->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class DoubleSerializationCluster : public SerializationCluster {
 public:
  DoubleSerializationCluster() {}
  virtual ~DoubleSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawDouble* dbl = Double::RawCast(object);
    objects_.Add(dbl);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kDoubleCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawDouble* dbl = objects_[i];
      s->AssignRef(dbl);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawDouble* dbl = objects_[i];
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
  virtual ~DoubleDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
  GrowableObjectArraySerializationCluster() {}
  virtual ~GrowableObjectArraySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawGrowableObjectArray* array = GrowableObjectArray::RawCast(object);
    objects_.Add(array);

    RawObject** from = array->from();
    RawObject** to = array->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kGrowableObjectArrayCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawGrowableObjectArray* array = objects_[i];
      s->AssignRef(array);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawGrowableObjectArray* array = objects_[i];
      s->Write<bool>(array->IsCanonical());
      RawObject** from = array->from();
      RawObject** to = array->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
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
  virtual ~GrowableObjectArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = list->from();
      RawObject** to = list->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypedDataSerializationCluster : public SerializationCluster {
 public:
  explicit TypedDataSerializationCluster(intptr_t cid) : cid_(cid) {}
  virtual ~TypedDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTypedData* data = TypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTypedData* data = objects_[i];
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->Write<int32_t>(length);
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      RawTypedData* data = objects_[i];
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->Write<int32_t>(length);
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
  virtual ~TypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
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
      intptr_t length = d->Read<int32_t>();
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
  explicit ExternalTypedDataSerializationCluster(intptr_t cid) : cid_(cid) {}
  virtual ~ExternalTypedDataSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawExternalTypedData* data = ExternalTypedData::RawCast(object);
    objects_.Add(data);
    ASSERT(!data->IsCanonical());
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
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
      intptr_t length = Smi::Value(data->ptr()->length_);
      s->Write<int32_t>(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data_);
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
  virtual ~ExternalTypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      intptr_t length = d->Read<int32_t>();
      Deserializer::InitializeHeader(
          data, cid_, ExternalTypedData::InstanceSize(), is_vm_object);
      data->ptr()->length_ = Smi::New(length);
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
  StackTraceSerializationCluster() {}
  virtual ~StackTraceSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawStackTrace* trace = StackTrace::RawCast(object);
    objects_.Add(trace);

    RawObject** from = trace->from();
    RawObject** to = trace->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kStackTraceCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawStackTrace* trace = objects_[i];
      s->AssignRef(trace);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawStackTrace* trace = objects_[i];
      RawObject** from = trace->from();
      RawObject** to = trace->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawStackTrace*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class StackTraceDeserializationCluster : public DeserializationCluster {
 public:
  StackTraceDeserializationCluster() {}
  virtual ~StackTraceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = trace->from();
      RawObject** to = trace->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RegExpSerializationCluster : public SerializationCluster {
 public:
  RegExpSerializationCluster() {}
  virtual ~RegExpSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawRegExp* regexp = RegExp::RawCast(object);
    objects_.Add(regexp);

    RawObject** from = regexp->from();
    RawObject** to = regexp->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kRegExpCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawRegExp* regexp = objects_[i];
      s->AssignRef(regexp);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawRegExp* regexp = objects_[i];
      RawObject** from = regexp->from();
      RawObject** to = regexp->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }

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
  virtual ~RegExpDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = regexp->from();
      RawObject** to = regexp->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }

      regexp->ptr()->num_registers_ = d->Read<int32_t>();
      regexp->ptr()->type_flags_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class WeakPropertySerializationCluster : public SerializationCluster {
 public:
  WeakPropertySerializationCluster() {}
  virtual ~WeakPropertySerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawWeakProperty* property = WeakProperty::RawCast(object);
    objects_.Add(property);

    RawObject** from = property->from();
    RawObject** to = property->to();
    for (RawObject** p = from; p <= to; p++) {
      s->Push(*p);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kWeakPropertyCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawWeakProperty* property = objects_[i];
      s->AssignRef(property);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawWeakProperty* property = objects_[i];
      RawObject** from = property->from();
      RawObject** to = property->to();
      for (RawObject** p = from; p <= to; p++) {
        s->WriteRef(*p);
      }
    }
  }

 private:
  GrowableArray<RawWeakProperty*> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class WeakPropertyDeserializationCluster : public DeserializationCluster {
 public:
  WeakPropertyDeserializationCluster() {}
  virtual ~WeakPropertyDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
      RawObject** from = property->from();
      RawObject** to = property->to();
      for (RawObject** p = from; p <= to; p++) {
        *p = d->ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LinkedHashMapSerializationCluster : public SerializationCluster {
 public:
  LinkedHashMapSerializationCluster() {}
  virtual ~LinkedHashMapSerializationCluster() {}

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawLinkedHashMap* map = objects_[i];
      s->AssignRef(map);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawLinkedHashMap* map = objects_[i];
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
  virtual ~LinkedHashMapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
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
  explicit ArraySerializationCluster(intptr_t cid) : cid_(cid) {}
  virtual ~ArraySerializationCluster() {}

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
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawArray* array = objects_[i];
      intptr_t length = Smi::Value(array->ptr()->length_);
      s->Write<int32_t>(length);
      s->AssignRef(array);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawArray* array = objects_[i];
      intptr_t length = Smi::Value(array->ptr()->length_);
      s->Write<int32_t>(length);
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
  virtual ~ArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(
          AllocateUninitialized(old_space, Array::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawArray* array = reinterpret_cast<RawArray*>(d->Ref(id));
      intptr_t length = d->Read<int32_t>();
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
  OneByteStringSerializationCluster() {}
  virtual ~OneByteStringSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawOneByteString* str = reinterpret_cast<RawOneByteString*>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kOneByteStringCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawOneByteString* str = objects_[i];
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->Write<int32_t>(length);
      s->AssignRef(str);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawOneByteString* str = objects_[i];
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->Write<int32_t>(length);
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
  virtual ~OneByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(AllocateUninitialized(old_space,
                                         OneByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawOneByteString* str = reinterpret_cast<RawOneByteString*>(d->Ref(id));
      intptr_t length = d->Read<int32_t>();
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
  TwoByteStringSerializationCluster() {}
  virtual ~TwoByteStringSerializationCluster() {}

  void Trace(Serializer* s, RawObject* object) {
    RawTwoByteString* str = reinterpret_cast<RawTwoByteString*>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTwoByteStringCid);
    intptr_t count = objects_.length();
    s->Write<int32_t>(count);
    for (intptr_t i = 0; i < count; i++) {
      RawTwoByteString* str = objects_[i];
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->Write<int32_t>(length);
      s->AssignRef(str);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RawTwoByteString* str = objects_[i];
      intptr_t length = Smi::Value(str->ptr()->length_);
      s->Write<int32_t>(length);
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
  virtual ~TwoByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->Read<int32_t>();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t length = d->Read<int32_t>();
      d->AssignRef(AllocateUninitialized(old_space,
                                         TwoByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d) {
    bool is_vm_object = d->isolate() == Dart::vm_isolate();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RawTwoByteString* str = reinterpret_cast<RawTwoByteString*>(d->Ref(id));
      intptr_t length = d->Read<int32_t>();
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

Serializer::Serializer(Thread* thread,
                       Snapshot::Kind kind,
                       uint8_t** buffer,
                       ReAlloc alloc,
                       intptr_t initial_size,
                       ImageWriter* image_writer)
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
      next_ref_index_(1)
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
    case kUnresolvedClassCid:
      return new (Z) UnresolvedClassSerializationCluster();
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
    case kLiteralTokenCid:
      return new (Z) LiteralTokenSerializationCluster();
    case kTokenStreamCid:
      return new (Z) TokenStreamSerializationCluster();
    case kScriptCid:
      return new (Z) ScriptSerializationCluster();
    case kLibraryCid:
      return new (Z) LibrarySerializationCluster();
    case kNamespaceCid:
      return new (Z) NamespaceSerializationCluster();
    case kCodeCid:
      return new (Z) CodeSerializationCluster();
    case kObjectPoolCid:
      return new (Z) ObjectPoolSerializationCluster();
    case kPcDescriptorsCid:
      return new (Z) RODataSerializationCluster(kPcDescriptorsCid);
    case kCodeSourceMapCid:
      return new (Z) RODataSerializationCluster(kCodeSourceMapCid);
    case kStackMapCid:
      return new (Z) RODataSerializationCluster(kStackMapCid);
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
      return new (Z) TypeSerializationCluster();
    case kTypeRefCid:
      return new (Z) TypeRefSerializationCluster();
    case kTypeParameterCid:
      return new (Z) TypeParameterSerializationCluster();
    case kBoundedTypeCid:
      return new (Z) BoundedTypeSerializationCluster();
    case kClosureCid:
      return new (Z) ClosureSerializationCluster();
    case kMintCid:
      return new (Z) MintSerializationCluster();
    case kBigintCid:
      return new (Z) BigintSerializationCluster();
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
        return new (Z) RODataSerializationCluster(kOneByteStringCid);
      } else {
        return new (Z) OneByteStringSerializationCluster();
      }
    }
    case kTwoByteStringCid: {
      if (Snapshot::IncludesCode(kind_)) {
        return new (Z) RODataSerializationCluster(kTwoByteStringCid);
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

  if (object->IsSendPort()) {
    // TODO(rmacnak): Do a better job of resetting fields in precompilation
    // and assert this is unreachable.
    return;  // Do not trace, will write null.
  }

  intptr_t id = heap_->GetObjectId(object);
  if (id == 0) {
    heap_->SetObjectId(object, 1);
    ASSERT(heap_->GetObjectId(object) != 0);
    stack_.Add(object);
    num_written_objects_++;

#if defined(SNAPSHOT_BACKTRACE)
    parent_pairs_.Add(&Object::Handle(object));
    parent_pairs_.Add(&Object::Handle(current_parent_));
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

void Serializer::WriteVersionAndFeatures() {
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

#if defined(DEBUG)
static const int32_t kSectionMarker = 0xABAB;
#endif

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

  Write<int32_t>(num_base_objects_);
  Write<int32_t>(num_objects);
  Write<int32_t>(num_clusters);

  for (intptr_t cid = 1; cid < num_cids_; cid++) {
    SerializationCluster* cluster = clusters_by_cid_[cid];
    if (cluster != NULL) {
      cluster->WriteAlloc(this);
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
      cluster->WriteFill(this);
#if defined(DEBUG)
      Write<int32_t>(kSectionMarker);
#endif
    }
  }
}

void Serializer::AddVMIsolateBaseObjects() {
  // These objects are always allocated by Object::InitOnce, so they are not
  // written into the snapshot.

  AddBaseObject(Object::null());
  AddBaseObject(Object::sentinel().raw());
  AddBaseObject(Object::transition_sentinel().raw());
  AddBaseObject(Object::empty_array().raw());
  AddBaseObject(Object::zero_array().raw());
  AddBaseObject(Object::dynamic_type().raw());
  AddBaseObject(Object::void_type().raw());
  AddBaseObject(Bool::True().raw());
  AddBaseObject(Bool::False().raw());
  AddBaseObject(Object::extractor_parameter_types().raw());
  AddBaseObject(Object::extractor_parameter_names().raw());
  AddBaseObject(Object::empty_context().raw());
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
  for (intptr_t cid = kClassCid; cid < kInstanceCid; cid++) {
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
      AddBaseObject(StubCode::EntryAt(i)->code());
    }
  }
}

intptr_t Serializer::WriteVMSnapshot(const Array& symbols,
                                     ZoneGrowableArray<Object*>* seed_objects,
                                     ZoneGrowableArray<Code*>* seed_code) {
  NoSafepointScope no_safepoint;

  AddVMIsolateBaseObjects();

  // Push roots.
  Push(symbols.raw());
  if (Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      Push(StubCode::EntryAt(i)->code());
    }
  }
  if (seed_objects != NULL) {
    for (intptr_t i = 0; i < seed_objects->length(); i++) {
      Push((*seed_objects)[i]->raw());
    }
  }
  if (seed_code != NULL) {
    for (intptr_t i = 0; i < seed_code->length(); i++) {
      Code* code = (*seed_code)[i];
      GetTextOffset(code->instructions(), code->raw());
    }
  }

  Serialize();

  // Write roots.
  WriteRef(symbols.raw());
  if (Snapshot::IncludesCode(kind_)) {
    for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
      WriteRef(StubCode::EntryAt(i)->code());
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

// Collects Instructions from the VM isolate and adds them to object id table
// with offsets that will refer to the VM snapshot, causing them to be shared
// across isolates.
class SeedInstructionsVisitor : public ObjectVisitor {
 public:
  SeedInstructionsVisitor(uword text_base, Heap* heap)
      : text_base_(text_base), heap_(heap) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsInstructions()) {
      uword addr = reinterpret_cast<uword>(obj) - kHeapObjectTag;
      int32_t offset = addr - text_base_;
      heap_->SetObjectId(obj, -offset);
    }
  }

 private:
  uword text_base_;
  Heap* heap_;
};

void Serializer::WriteIsolateSnapshot(intptr_t num_base_objects,
                                      ObjectStore* object_store) {
  NoSafepointScope no_safepoint;

  if (num_base_objects == 0) {
    // Not writing a new vm isolate: use the one this VM was loaded from.
    const Array& base_objects = Object::vm_isolate_snapshot_object_table();
    for (intptr_t i = 1; i < base_objects.Length(); i++) {
      AddBaseObject(base_objects.At(i));
    }
    const uint8_t* text_base = Dart::vm_snapshot_instructions();
    if (text_base != NULL) {
      SeedInstructionsVisitor visitor(reinterpret_cast<uword>(text_base),
                                      heap_);
      Dart::vm_isolate()->heap()->VisitObjectsImagePages(&visitor);
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
    WriteRef(*p);
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
                           const uint8_t* instructions_buffer,
                           const uint8_t* data_buffer)
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
    image_reader_ = new (zone_) ImageReader(instructions_buffer, data_buffer);
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
    case kUnresolvedClassCid:
      return new (Z) UnresolvedClassDeserializationCluster();
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
    case kLiteralTokenCid:
      return new (Z) LiteralTokenDeserializationCluster();
    case kTokenStreamCid:
      return new (Z) TokenStreamDeserializationCluster();
    case kScriptCid:
      return new (Z) ScriptDeserializationCluster();
    case kLibraryCid:
      return new (Z) LibraryDeserializationCluster();
    case kNamespaceCid:
      return new (Z) NamespaceDeserializationCluster();
    case kCodeCid:
      return new (Z) CodeDeserializationCluster();
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
    case kBigintCid:
      return new (Z) BigintDeserializationCluster();
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
    const intptr_t kMessageBufferSize = 1024;
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

void Deserializer::Prepare() {
  num_base_objects_ = Read<int32_t>();
  num_objects_ = Read<int32_t>();
  num_clusters_ = Read<int32_t>();

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
  AddBaseObject(Bool::True().raw());
  AddBaseObject(Bool::False().raw());
  AddBaseObject(Object::extractor_parameter_types().raw());
  AddBaseObject(Object::extractor_parameter_names().raw());
  AddBaseObject(Object::empty_context().raw());
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
      AddBaseObject(StubCode::EntryAt(i)->code());
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
      Code& code = Code::Handle(zone_);
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        code ^= ReadRef();
        StubCode::EntryAtPut(i, new StubEntry(code));
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

  Symbols::InitOnceFromSnapshot(isolate());

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

#if defined(DEBUG)
  Isolate* isolate = thread()->isolate();
  isolate->ValidateClassTable();
  isolate->heap()->Verify();
#endif

  {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        thread(), Timeline::GetIsolateStream(), "PostLoad"));
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i]->PostLoad(refs, kind_, zone_);
    }
  }

  // Setup native resolver for bootstrap impl.
  Bootstrap::SetupNativeResolver();
}

// An object visitor which iterates the heap looking for objects to write into
// the VM isolate's snapshot, causing them to be shared across isolates.
class SeedVMIsolateVisitor : public ObjectVisitor {
 public:
  SeedVMIsolateVisitor(Zone* zone, bool include_code)
      : zone_(zone),
        include_code_(include_code),
        objects_(new (zone) ZoneGrowableArray<Object*>(4 * KB)),
        code_(new (zone) ZoneGrowableArray<Code*>(4 * KB)) {}

  void VisitObject(RawObject* obj) {
    if (obj->IsTokenStream()) {
      objects_->Add(&Object::Handle(zone_, obj));
    } else if (include_code_) {
      if (obj->IsStackMap() || obj->IsPcDescriptors() ||
          obj->IsCodeSourceMap()) {
        objects_->Add(&Object::Handle(zone_, obj));
      } else if (obj->IsCode()) {
        code_->Add(&Code::Handle(zone_, Code::RawCast(obj)));
      }
    }
  }

  ZoneGrowableArray<Object*>* objects() { return objects_; }
  ZoneGrowableArray<Code*>* code() { return code_; }

 private:
  Zone* zone_;
  bool include_code_;
  ZoneGrowableArray<Object*>* objects_;
  ZoneGrowableArray<Code*>* code_;
};

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
      seed_objects_(NULL),
      seed_code_(NULL),
      saved_symbol_table_(Array::Handle(zone())),
      new_vm_symbol_table_(Array::Handle(zone())),
      clustered_vm_size_(0),
      clustered_isolate_size_(0),
      mapped_data_size_(0),
      mapped_instructions_size_(0) {
  ASSERT(alloc_ != NULL);
  ASSERT(isolate() != NULL);
  ASSERT(ClassFinalizer::AllClassesFinalized());
  ASSERT(isolate() != NULL);
  ASSERT(heap() != NULL);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

#if defined(DEBUG)
  // Ensure the class table is valid.
  isolate()->ValidateClassTable();
#endif
  // Can't have any mutation happening while we're serializing.
  ASSERT(isolate()->background_compiler() == NULL);

  // TODO(rmacnak): The special case for AOT causes us to always generate the
  // same VM isolate snapshot for every app. AOT snapshots should be cleaned up
  // so the VM isolate snapshot is generated separately and each app is
  // generated from a VM that has loaded this snapshots, much like app-jit
  // snapshots.
  if ((vm_snapshot_data_buffer != NULL) && (kind != Snapshot::kFullAOT)) {
    NOT_IN_PRODUCT(TimelineDurationScope tds(
        thread(), Timeline::GetIsolateStream(), "PrepareNewVMIsolate"));

    HeapIterationScope iteration(thread());
    SeedVMIsolateVisitor visitor(thread()->zone(),
                                 Snapshot::IncludesCode(kind));
    iteration.IterateObjects(&visitor);
    iteration.IterateVMIsolateObjects(&visitor);
    seed_objects_ = visitor.objects();
    seed_code_ = visitor.code();

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
                        kInitialSize, vm_image_writer_);

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures();
  // VM snapshot roots are:
  // - the symbol table
  // - all the token streams
  // - the stub code (precompiled snapshots only)
  intptr_t num_objects = serializer.WriteVMSnapshot(new_vm_symbol_table_,
                                                    seed_objects_, seed_code_);
  serializer.FillHeader(serializer.kind());
  clustered_vm_size_ = serializer.bytes_written();

  if (Snapshot::IncludesCode(kind_)) {
    vm_image_writer_->Write(serializer.stream(), true);
    mapped_data_size_ += vm_image_writer_->data_size();
    mapped_instructions_size_ += vm_image_writer_->text_size();
    vm_image_writer_->ResetOffsets();
  }

  // The clustered part + the direct mapped data part.
  vm_isolate_snapshot_size_ = serializer.bytes_written();
  return num_objects;
}

void FullSnapshotWriter::WriteIsolateSnapshot(intptr_t num_base_objects) {
  NOT_IN_PRODUCT(TimelineDurationScope tds(
      thread(), Timeline::GetIsolateStream(), "WriteIsolateSnapshot"));

  Serializer serializer(thread(), kind_, isolate_snapshot_data_buffer_, alloc_,
                        kInitialSize, isolate_image_writer_);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures();
  // Isolate snapshot roots are:
  // - the object store
  serializer.WriteIsolateSnapshot(num_base_objects, object_store);
  serializer.FillHeader(serializer.kind());
  clustered_isolate_size_ = serializer.bytes_written();

  if (Snapshot::IncludesCode(kind_)) {
    isolate_image_writer_->Write(serializer.stream(), false);
    mapped_data_size_ += isolate_image_writer_->data_size();
    mapped_instructions_size_ += isolate_image_writer_->text_size();
    isolate_image_writer_->ResetOffsets();
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
    OS::Print("Instructions(CodeSize): %" Pd "\n", mapped_instructions_size_);
    OS::Print("Total(CodeSize): %" Pd "\n",
              clustered_vm_size_ + clustered_isolate_size_ + mapped_data_size_ +
                  mapped_instructions_size_);
  }
}

static const uint8_t* DataBuffer(const Snapshot* snapshot) {
  if (Snapshot::IncludesCode(snapshot->kind())) {
    uword offset =
        Utils::RoundUp(snapshot->length(), OS::kMaxPreferredCodeAlignment);
    return snapshot->Addr() + offset;
  }
  return NULL;
}

FullSnapshotReader::FullSnapshotReader(const Snapshot* snapshot,
                                       const uint8_t* instructions_buffer,
                                       Thread* thread)
    : kind_(snapshot->kind()),
      thread_(thread),
      buffer_(snapshot->content()),
      size_(snapshot->length()),
      instructions_buffer_(instructions_buffer),
      data_buffer_(DataBuffer(snapshot)) {
  thread->isolate()->set_compilation_allowed(kind_ != Snapshot::kFullAOT);
}

RawApiError* FullSnapshotReader::ReadVMSnapshot() {
  Deserializer deserializer(thread_, kind_, buffer_, size_,
                            instructions_buffer_, data_buffer_);

  RawApiError* error = deserializer.VerifyVersionAndFeatures(/*isolate=*/NULL);
  if (error != ApiError::null()) {
    return error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(instructions_buffer_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_buffer_,
                                       /* is_executable */ true);
    ASSERT(data_buffer_ != NULL);
    thread_->isolate()->SetupImagePage(data_buffer_,
                                       /* is_executable */ false);
    Dart::set_vm_snapshot_instructions(instructions_buffer_);
  }

  deserializer.ReadVMSnapshot();

  return ApiError::null();
}

RawApiError* FullSnapshotReader::ReadIsolateSnapshot() {
  Deserializer deserializer(thread_, kind_, buffer_, size_,
                            instructions_buffer_, data_buffer_);

  RawApiError* error =
      deserializer.VerifyVersionAndFeatures(thread_->isolate());
  if (error != ApiError::null()) {
    return error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(instructions_buffer_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_buffer_,
                                       /* is_executable */ true);
    ASSERT(data_buffer_ != NULL);
    thread_->isolate()->SetupImagePage(data_buffer_,
                                       /* is_executable */ false);
  }

  deserializer.ReadIsolateSnapshot(thread_->isolate()->object_store());

  return ApiError::null();
}

}  // namespace dart
