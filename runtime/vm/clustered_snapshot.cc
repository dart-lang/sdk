// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>

#include "vm/clustered_snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/bss_relocs.h"
#include "vm/canonical_tables.h"
#include "vm/class_id.h"
#include "vm/code_observers.h"
#include "vm/compiler/api/print_filter.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/dart.h"
#include "vm/dispatch_table.h"
#include "vm/flag_list.h"
#include "vm/growable_array.h"
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
#include "vm/zone_text_buffer.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/backend/code_statistics.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/relocation.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)
DEFINE_FLAG(bool,
            print_cluster_information,
            false,
            "Print information about clusters written to snapshot");
#endif

#if defined(DART_PRECOMPILER)
DEFINE_FLAG(charp,
            write_v8_snapshot_profile_to,
            NULL,
            "Write a snapshot profile in V8 format to a file.");
#endif  // defined(DART_PRECOMPILER)

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

static void RelocateCodeObjects(
    bool is_vm,
    GrowableArray<CodePtr>* code_objects,
    GrowableArray<ImageWriterCommand>* image_writer_commands) {
  auto thread = Thread::Current();
  auto isolate = is_vm ? Dart::vm_isolate() : thread->isolate();

  WritableCodePages writable_code_pages(thread, isolate);
  CodeRelocator::Relocate(thread, code_objects, image_writer_commands, is_vm);
}

class CodePtrKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const CodePtr Key;
  typedef const CodePtr Value;
  typedef CodePtr Pair;

  static Key KeyOf(Pair kv) { return kv; }
  static Value ValueOf(Pair kv) { return kv; }
  static inline intptr_t Hashcode(Key key) {
    return static_cast<intptr_t>(key);
  }

  static inline bool IsKeyEqual(Pair pair, Key key) { return pair == key; }
};

typedef DirectChainedHashMap<CodePtrKeyValueTrait> RawCodeSet;

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

static ObjectPtr AllocateUninitialized(PageSpace* old_space, intptr_t size) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword address = old_space->TryAllocateDataBumpLocked(size);
  if (address == 0) {
    OUT_OF_MEMORY();
  }
  return ObjectLayout::FromAddr(address);
}

void Deserializer::InitializeHeader(ObjectPtr raw,
                                    intptr_t class_id,
                                    intptr_t size,
                                    bool is_canonical) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword tags = 0;
  tags = ObjectLayout::ClassIdTag::update(class_id, tags);
  tags = ObjectLayout::SizeTag::update(size, tags);
  tags = ObjectLayout::CanonicalBit::update(is_canonical, tags);
  tags = ObjectLayout::OldBit::update(true, tags);
  tags = ObjectLayout::OldAndNotMarkedBit::update(true, tags);
  tags = ObjectLayout::OldAndNotRememberedBit::update(true, tags);
  tags = ObjectLayout::NewBit::update(false, tags);
  raw->ptr()->tags_ = tags;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void SerializationCluster::WriteAndMeasureAlloc(Serializer* serializer) {
  intptr_t start_size = serializer->bytes_written();
  intptr_t start_data = serializer->GetDataSize();
  intptr_t start_objects = serializer->next_ref_index();
  WriteAlloc(serializer);
  intptr_t stop_size = serializer->bytes_written();
  intptr_t stop_data = serializer->GetDataSize();
  intptr_t stop_objects = serializer->next_ref_index();
  if (FLAG_print_cluster_information) {
    OS::PrintErr("Snapshot 0x%" Pp " (%" Pd "), ", start_size,
                 stop_size - start_size);
    OS::PrintErr("Data 0x%" Pp " (%" Pd "): ", start_data,
                 stop_data - start_data);
    OS::PrintErr("Alloc %s (%" Pd ")\n", name(), stop_objects - start_objects);
  }
  size_ += (stop_size - start_size) + (stop_data - start_data);
  num_objects_ += (stop_objects - start_objects);
}

void SerializationCluster::WriteAndMeasureFill(Serializer* serializer) {
  intptr_t start = serializer->bytes_written();
  WriteFill(serializer);
  intptr_t stop = serializer->bytes_written();
  if (FLAG_print_cluster_information) {
    OS::PrintErr("Snapshot 0x%" Pp " (%" Pd "): Fill %s\n", start, stop - start,
                 name());
  }
  size_ += (stop - start);
}

static UnboxedFieldBitmap CalculateTargetUnboxedFieldsBitmap(
    Serializer* s,
    intptr_t class_id) {
  const auto unboxed_fields_bitmap_host =
      s->isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
          class_id);

  UnboxedFieldBitmap unboxed_fields_bitmap;
  if (unboxed_fields_bitmap_host.IsEmpty() ||
      kWordSize == compiler::target::kWordSize) {
    unboxed_fields_bitmap = unboxed_fields_bitmap_host;
  } else {
    ASSERT(kWordSize == 8 && compiler::target::kWordSize == 4);
    // A new bitmap is built if the word sizes in the target and
    // host are different
    unboxed_fields_bitmap.Reset();
    intptr_t target_i = 0, host_i = 0;

    while (host_i < UnboxedFieldBitmap::Length()) {
      // Each unboxed field has constant length, therefore the number of
      // words used by it should double when compiling from 64-bit to 32-bit.
      if (unboxed_fields_bitmap_host.Get(host_i++)) {
        unboxed_fields_bitmap.Set(target_i++);
        unboxed_fields_bitmap.Set(target_i++);
      } else {
        // For object pointers, the field is always one word length
        target_i++;
      }
    }
  }

  return unboxed_fields_bitmap;
}

class ClassSerializationCluster : public SerializationCluster {
 public:
  explicit ClassSerializationCluster(intptr_t num_cids)
      : SerializationCluster("Class"),
        predefined_(kNumPredefinedCids),
        objects_(num_cids) {}
  ~ClassSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ClassPtr cls = Class::RawCast(object);
    intptr_t class_id = cls->ptr()->id_;

    if (class_id == kIllegalCid) {
      // Classes expected to be dropped by the precompiler should not be traced.
      s->UnexpectedObject(cls, "Class with illegal cid");
    }
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
      ClassPtr cls = predefined_[i];
      s->AssignRef(cls);
      AutoTraceObject(cls);
      intptr_t class_id = cls->ptr()->id_;
      s->WriteCid(class_id);
    }
    count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ClassPtr cls = objects_[i];
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

 private:
  void WriteClass(Serializer* s, ClassPtr cls) {
    AutoTraceObjectName(cls, cls->ptr()->name_);
    WriteFromTo(cls);
    intptr_t class_id = cls->ptr()->id_;
    if (class_id == kIllegalCid) {
      s->UnexpectedObject(cls, "Class with illegal cid");
    }
    s->WriteCid(class_id);
    if (s->kind() == Snapshot::kFullCore &&
        RequireLegacyErasureOfConstants(cls)) {
      s->UnexpectedObject(cls, "Class with non mode agnostic constants");
    }
    if (s->kind() != Snapshot::kFullAOT) {
      s->Write<uint32_t>(cls->ptr()->kernel_offset_);
    }
    s->Write<int32_t>(Class::target_instance_size_in_words(cls));
    s->Write<int32_t>(Class::target_next_field_offset_in_words(cls));
    s->Write<int32_t>(Class::target_type_arguments_field_offset_in_words(cls));
    s->Write<int16_t>(cls->ptr()->num_type_arguments_);
    s->Write<uint16_t>(cls->ptr()->num_native_fields_);
    s->WriteTokenPosition(cls->ptr()->token_pos_);
    s->WriteTokenPosition(cls->ptr()->end_token_pos_);
    s->Write<uint32_t>(cls->ptr()->state_bits_);

    // In AOT, the bitmap of unboxed fields should also be serialized
    if (FLAG_precompiled_mode && !ClassTable::IsTopLevelCid(class_id)) {
      s->WriteUnsigned64(
          CalculateTargetUnboxedFieldsBitmap(s, class_id).Value());
    }
  }

  GrowableArray<ClassPtr> predefined_;
  GrowableArray<ClassPtr> objects_;

  bool RequireLegacyErasureOfConstants(ClassPtr cls) {
    // Do not generate a core snapshot containing constants that would require
    // a legacy erasure of their types if loaded in an isolate running in weak
    // mode.
    if (cls->ptr()->host_type_arguments_field_offset_in_words_ ==
            Class::kNoTypeArguments ||
        cls->ptr()->constants_ == Array::null()) {
      return false;
    }
    Zone* zone = Thread::Current()->zone();
    const Class& clazz = Class::Handle(zone, cls);
    return clazz.RequireLegacyErasureOfConstants(zone);
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClassDeserializationCluster : public DeserializationCluster {
 public:
  ClassDeserializationCluster() : DeserializationCluster("Class") {}
  ~ClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    predefined_start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    intptr_t count = d->ReadUnsigned();
    ClassTable* table = d->isolate()->class_table();
    for (intptr_t i = 0; i < count; i++) {
      intptr_t class_id = d->ReadCid();
      ASSERT(table->HasValidClassAt(class_id));
      ClassPtr cls = table->At(class_id);
      ASSERT(cls != nullptr);
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

  void ReadFill(Deserializer* d, bool is_canonical) {
    ClassTable* table = d->isolate()->class_table();

    for (intptr_t id = predefined_start_index_; id < predefined_stop_index_;
         id++) {
      ClassPtr cls = static_cast<ClassPtr>(d->Ref(id));
      ReadFromTo(cls);
      intptr_t class_id = d->ReadCid();
      cls->ptr()->id_ = class_id;
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        cls->ptr()->kernel_offset_ = d->Read<uint32_t>();
      }
#endif
      if (!IsInternalVMdefinedClassId(class_id)) {
        cls->ptr()->host_instance_size_in_words_ = d->Read<int32_t>();
        cls->ptr()->host_next_field_offset_in_words_ = d->Read<int32_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
        // Only one pair is serialized. The target field only exists when
        // DART_PRECOMPILED_RUNTIME is not defined
        cls->ptr()->target_instance_size_in_words_ =
            cls->ptr()->host_instance_size_in_words_;
        cls->ptr()->target_next_field_offset_in_words_ =
            cls->ptr()->host_next_field_offset_in_words_;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
      } else {
        d->Read<int32_t>();  // Skip.
        d->Read<int32_t>();  // Skip.
      }
      cls->ptr()->host_type_arguments_field_offset_in_words_ =
          d->Read<int32_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      cls->ptr()->target_type_arguments_field_offset_in_words_ =
          cls->ptr()->host_type_arguments_field_offset_in_words_;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
      cls->ptr()->num_type_arguments_ = d->Read<int16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->end_token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint32_t>();

      if (FLAG_precompiled_mode) {
        d->ReadUnsigned64();  // Skip unboxed fields bitmap.
      }
    }

    auto shared_class_table = d->isolate()->group()->shared_class_table();
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ClassPtr cls = static_cast<ClassPtr>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kClassCid, Class::InstanceSize());
      ReadFromTo(cls);

      intptr_t class_id = d->ReadCid();
      ASSERT(class_id >= kNumPredefinedCids);
      cls->ptr()->id_ = class_id;

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        cls->ptr()->kernel_offset_ = d->Read<uint32_t>();
      }
#endif
      cls->ptr()->host_instance_size_in_words_ = d->Read<int32_t>();
      cls->ptr()->host_next_field_offset_in_words_ = d->Read<int32_t>();
      cls->ptr()->host_type_arguments_field_offset_in_words_ =
          d->Read<int32_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      cls->ptr()->target_instance_size_in_words_ =
          cls->ptr()->host_instance_size_in_words_;
      cls->ptr()->target_next_field_offset_in_words_ =
          cls->ptr()->host_next_field_offset_in_words_;
      cls->ptr()->target_type_arguments_field_offset_in_words_ =
          cls->ptr()->host_type_arguments_field_offset_in_words_;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
      cls->ptr()->num_type_arguments_ = d->Read<int16_t>();
      cls->ptr()->num_native_fields_ = d->Read<uint16_t>();
      cls->ptr()->token_pos_ = d->ReadTokenPosition();
      cls->ptr()->end_token_pos_ = d->ReadTokenPosition();
      cls->ptr()->state_bits_ = d->Read<uint32_t>();

      table->AllocateIndex(class_id);
      table->SetAt(class_id, cls);

      if (FLAG_precompiled_mode && !ClassTable::IsTopLevelCid(class_id)) {
        const UnboxedFieldBitmap unboxed_fields_map(d->ReadUnsigned64());
        shared_class_table->SetUnboxedFieldsMapAt(class_id, unboxed_fields_map);
      }
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

  void Trace(Serializer* s, ObjectPtr object) {
    TypeArgumentsPtr type_args = TypeArguments::RawCast(object);
    objects_.Add(type_args);

    s->Push(type_args->ptr()->instantiations_);
    const intptr_t length = Smi::Value(type_args->ptr()->length_);
    for (intptr_t i = 0; i < length; i++) {
      s->Push(type_args->ptr()->types()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeArgumentsCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypeArgumentsPtr type_args = objects_[i];
      s->AssignRef(type_args);
      AutoTraceObject(type_args);
      const intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypeArgumentsPtr type_args = objects_[i];
      AutoTraceObject(type_args);
      const intptr_t length = Smi::Value(type_args->ptr()->length_);
      s->WriteUnsigned(length);
      intptr_t hash = Smi::Value(type_args->ptr()->hash_);
      s->Write<int32_t>(hash);
      const intptr_t nullability = Smi::Value(type_args->ptr()->nullability_);
      s->WriteUnsigned(nullability);
      WriteField(type_args, instantiations_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(type_args->ptr()->types()[j], j);
      }
    }
  }

 private:
  GrowableArray<TypeArgumentsPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeArgumentsDeserializationCluster : public DeserializationCluster {
 public:
  TypeArgumentsDeserializationCluster()
      : DeserializationCluster("TypeArguments") {}
  ~TypeArgumentsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         TypeArguments::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypeArgumentsPtr type_args = static_cast<TypeArgumentsPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(type_args, kTypeArgumentsCid,
                                     TypeArguments::InstanceSize(length),
                                     is_canonical);
      type_args->ptr()->length_ = Smi::New(length);
      type_args->ptr()->hash_ = Smi::New(d->Read<int32_t>());
      type_args->ptr()->nullability_ = Smi::New(d->ReadUnsigned());
      type_args->ptr()->instantiations_ = static_cast<ArrayPtr>(d->ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        type_args->ptr()->types()[j] =
            static_cast<AbstractTypePtr>(d->ReadRef());
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      CanonicalTypeArgumentsSet table(
          d->zone(), d->isolate()->object_store()->canonical_type_arguments());
      TypeArguments& type_arg = TypeArguments::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        type_arg ^= refs.At(i);
        ASSERT(type_arg.IsCanonical());
        bool present = table.Insert(type_arg);
        // Two recursive types with different topology (and hashes) may be
        // equal.
        ASSERT(!present || type_arg.IsRecursive());
      }
      d->isolate()->object_store()->set_canonical_type_arguments(
          table.Release());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class PatchClassSerializationCluster : public SerializationCluster {
 public:
  PatchClassSerializationCluster() : SerializationCluster("PatchClass") {}
  ~PatchClassSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    PatchClassPtr cls = PatchClass::RawCast(object);
    objects_.Add(cls);
    PushFromTo(cls);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kPatchClassCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      PatchClassPtr cls = objects_[i];
      s->AssignRef(cls);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      PatchClassPtr cls = objects_[i];
      AutoTraceObject(cls);
      WriteFromTo(cls);
      if (s->kind() != Snapshot::kFullAOT) {
        s->Write<int32_t>(cls->ptr()->library_kernel_offset_);
      }
    }
  }

 private:
  GrowableArray<PatchClassPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class PatchClassDeserializationCluster : public DeserializationCluster {
 public:
  PatchClassDeserializationCluster() : DeserializationCluster("PatchClass") {}
  ~PatchClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, PatchClass::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      PatchClassPtr cls = static_cast<PatchClassPtr>(d->Ref(id));
      Deserializer::InitializeHeader(cls, kPatchClassCid,
                                     PatchClass::InstanceSize());
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

  void Trace(Serializer* s, ObjectPtr object) {
    Snapshot::Kind kind = s->kind();
    FunctionPtr func = Function::RawCast(object);
    objects_.Add(func);

    PushFromTo(func);
    if (kind == Snapshot::kFullAOT) {
      s->Push(func->ptr()->code_);
    } else if (kind == Snapshot::kFullJIT) {
      NOT_IN_PRECOMPILED(s->Push(func->ptr()->unoptimized_code_));
      s->Push(func->ptr()->code_);
      s->Push(func->ptr()->ic_data_array_);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFunctionCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      FunctionPtr func = objects_[i];
      s->AssignRef(func);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      FunctionPtr func = objects_[i];
      AutoTraceObjectName(func, MakeDisambiguatedFunctionName(s, func));
      WriteFromTo(func);
      if (kind == Snapshot::kFullAOT) {
        WriteField(func, code_);
      } else if (s->kind() == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(WriteField(func, unoptimized_code_));
        WriteField(func, code_);
        WriteField(func, ic_data_array_);
      }

      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(func->ptr()->token_pos_);
        s->WriteTokenPosition(func->ptr()->end_token_pos_);
        s->Write<uint32_t>(func->ptr()->kernel_offset_);
      }

      s->Write<uint32_t>(func->ptr()->packed_fields_);
      s->Write<uint32_t>(func->ptr()->kind_tag_);
    }
  }

  static const char* MakeDisambiguatedFunctionName(Serializer* s,
                                                   FunctionPtr f) {
    if (s->profile_writer() == nullptr) {
      return nullptr;
    }

    REUSABLE_FUNCTION_HANDLESCOPE(s->thread());
    Function& fun = reused_function_handle.Handle();
    fun = f;
    ZoneTextBuffer printer(s->thread()->zone());
    fun.PrintName(NameFormattingParams::DisambiguatedUnqualified(
                      Object::NameVisibility::kInternalName),
                  &printer);
    return printer.buffer();
  }

 private:
  GrowableArray<FunctionPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FunctionDeserializationCluster : public DeserializationCluster {
 public:
  FunctionDeserializationCluster() : DeserializationCluster("Function") {}
  ~FunctionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Function::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    Snapshot::Kind kind = d->kind();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      FunctionPtr func = static_cast<FunctionPtr>(d->Ref(id));
      Deserializer::InitializeHeader(func, kFunctionCid,
                                     Function::InstanceSize());
      ReadFromTo(func);

      if (kind == Snapshot::kFullAOT) {
        func->ptr()->code_ = static_cast<CodePtr>(d->ReadRef());
      } else if (kind == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(func->ptr()->unoptimized_code_ =
                               static_cast<CodePtr>(d->ReadRef()));
        func->ptr()->code_ = static_cast<CodePtr>(d->ReadRef());
        func->ptr()->ic_data_array_ = static_cast<ArrayPtr>(d->ReadRef());
      }

#if defined(DEBUG)
      func->ptr()->entry_point_ = 0;
      func->ptr()->unchecked_entry_point_ = 0;
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
      if (kind != Snapshot::kFullAOT) {
        func->ptr()->token_pos_ = d->ReadTokenPosition();
        func->ptr()->end_token_pos_ = d->ReadTokenPosition();
        func->ptr()->kernel_offset_ = d->Read<uint32_t>();
      }
      func->ptr()->unboxed_parameters_info_.Reset();
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

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (d->kind() == Snapshot::kFullAOT) {
      Function& func = Function::Handle(d->zone());
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
    } else if (d->kind() == Snapshot::kFullJIT) {
      Function& func = Function::Handle(d->zone());
      Code& code = Code::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        func ^= refs.At(i);
        code = func.CurrentCode();
        if (func.HasCode() && !code.IsDisabled()) {
          func.SetInstructions(code);  // Set entrypoint.
          func.SetWasCompiled(true);
        } else {
          func.ClearCode();  // Set code and entrypoint to lazy compile stub.
        }
      }
    } else {
      Function& func = Function::Handle(d->zone());
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

  void Trace(Serializer* s, ObjectPtr object) {
    ClosureDataPtr data = ClosureData::RawCast(object);
    objects_.Add(data);

    if (s->kind() != Snapshot::kFullAOT) {
      s->Push(data->ptr()->context_scope_);
    }
    s->Push(data->ptr()->parent_function_);
    s->Push(data->ptr()->signature_type_);
    s->Push(data->ptr()->closure_);
    s->Push(data->ptr()->default_type_arguments_);
    s->Push(data->ptr()->default_type_arguments_info_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClosureDataCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ClosureDataPtr data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ClosureDataPtr data = objects_[i];
      AutoTraceObject(data);
      if (s->kind() != Snapshot::kFullAOT) {
        WriteField(data, context_scope_);
      }
      WriteField(data, parent_function_);
      WriteField(data, signature_type_);
      WriteField(data, closure_);
      WriteField(data, default_type_arguments_);
      WriteField(data, default_type_arguments_info_);
    }
  }

 private:
  GrowableArray<ClosureDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClosureDataDeserializationCluster : public DeserializationCluster {
 public:
  ClosureDataDeserializationCluster() : DeserializationCluster("ClosureData") {}
  ~ClosureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, ClosureData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ClosureDataPtr data = static_cast<ClosureDataPtr>(d->Ref(id));
      Deserializer::InitializeHeader(data, kClosureDataCid,
                                     ClosureData::InstanceSize());
      if (d->kind() == Snapshot::kFullAOT) {
        data->ptr()->context_scope_ = ContextScope::null();
      } else {
        data->ptr()->context_scope_ =
            static_cast<ContextScopePtr>(d->ReadRef());
      }
      data->ptr()->parent_function_ = static_cast<FunctionPtr>(d->ReadRef());
      data->ptr()->signature_type_ = static_cast<TypePtr>(d->ReadRef());
      data->ptr()->closure_ = static_cast<InstancePtr>(d->ReadRef());
      data->ptr()->default_type_arguments_ =
          static_cast<TypeArgumentsPtr>(d->ReadRef());
      data->ptr()->default_type_arguments_info_ =
          static_cast<SmiPtr>(d->ReadRef());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SignatureDataSerializationCluster : public SerializationCluster {
 public:
  SignatureDataSerializationCluster() : SerializationCluster("SignatureData") {}
  ~SignatureDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    SignatureDataPtr data = SignatureData::RawCast(object);
    objects_.Add(data);
    PushFromTo(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSignatureDataCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      SignatureDataPtr data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      SignatureDataPtr data = objects_[i];
      AutoTraceObject(data);
      WriteFromTo(data);
    }
  }

 private:
  GrowableArray<SignatureDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SignatureDataDeserializationCluster : public DeserializationCluster {
 public:
  SignatureDataDeserializationCluster()
      : DeserializationCluster("SignatureData") {}
  ~SignatureDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, SignatureData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      SignatureDataPtr data = static_cast<SignatureDataPtr>(d->Ref(id));
      Deserializer::InitializeHeader(data, kSignatureDataCid,
                                     SignatureData::InstanceSize());
      ReadFromTo(data);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FfiTrampolineDataSerializationCluster : public SerializationCluster {
 public:
  FfiTrampolineDataSerializationCluster()
      : SerializationCluster("FfiTrampolineData") {}
  ~FfiTrampolineDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    FfiTrampolineDataPtr data = FfiTrampolineData::RawCast(object);
    objects_.Add(data);
    PushFromTo(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFfiTrampolineDataCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      s->AssignRef(objects_[i]);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      FfiTrampolineDataPtr const data = objects_[i];
      AutoTraceObject(data);
      WriteFromTo(data);

      if (s->kind() == Snapshot::kFullAOT) {
        s->WriteUnsigned(data->ptr()->callback_id_);
      } else {
        // FFI callbacks can only be written to AOT snapshots.
        ASSERT(data->ptr()->callback_target_ == Object::null());
      }
    }
  }

 private:
  GrowableArray<FfiTrampolineDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FfiTrampolineDataDeserializationCluster : public DeserializationCluster {
 public:
  FfiTrampolineDataDeserializationCluster()
      : DeserializationCluster("FfiTrampolineData") {}
  ~FfiTrampolineDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, FfiTrampolineData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      FfiTrampolineDataPtr data = static_cast<FfiTrampolineDataPtr>(d->Ref(id));
      Deserializer::InitializeHeader(data, kFfiTrampolineDataCid,
                                     FfiTrampolineData::InstanceSize());
      ReadFromTo(data);
      data->ptr()->callback_id_ =
          d->kind() == Snapshot::kFullAOT ? d->ReadUnsigned() : 0;
    }
  }
};


#if !defined(DART_PRECOMPILED_RUNTIME)
class FieldSerializationCluster : public SerializationCluster {
 public:
  FieldSerializationCluster() : SerializationCluster("Field") {}
  ~FieldSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    FieldPtr field = Field::RawCast(object);
    objects_.Add(field);

    Snapshot::Kind kind = s->kind();

    s->Push(field->ptr()->name_);
    s->Push(field->ptr()->owner_);
    s->Push(field->ptr()->type_);
    // Write out the initializer function
    s->Push(field->ptr()->initializer_function_);

    if (kind != Snapshot::kFullAOT) {
      s->Push(field->ptr()->guarded_list_length_);
    }
    if (kind == Snapshot::kFullJIT) {
      s->Push(field->ptr()->dependent_code_);
    }
    // Write out either the initial static value or field offset.
    if (Field::StaticBit::decode(field->ptr()->kind_bits_)) {
      const intptr_t field_id =
          Smi::Value(field->ptr()->host_offset_or_field_id_);
      s->Push(s->initial_field_table()->At(field_id));
    } else {
      s->Push(Smi::New(Field::TargetOffsetOf(field)));
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kFieldCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      FieldPtr field = objects_[i];
      s->AssignRef(field);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      FieldPtr field = objects_[i];
      AutoTraceObjectName(field, field->ptr()->name_);

      WriteField(field, name_);
      WriteField(field, owner_);
      WriteField(field, type_);
      // Write out the initializer function and initial value if not in AOT.
      WriteField(field, initializer_function_);
      if (kind != Snapshot::kFullAOT) {
        WriteField(field, guarded_list_length_);
      }
      if (kind == Snapshot::kFullJIT) {
        WriteField(field, dependent_code_);
      }

      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(field->ptr()->token_pos_);
        s->WriteTokenPosition(field->ptr()->end_token_pos_);
        s->WriteCid(field->ptr()->guarded_cid_);
        s->WriteCid(field->ptr()->is_nullable_);
        s->Write<int8_t>(field->ptr()->static_type_exactness_state_);
        s->Write<uint32_t>(field->ptr()->kernel_offset_);
      }
      s->Write<uint16_t>(field->ptr()->kind_bits_);

      // Write out either the initial static value or field offset.
      if (Field::StaticBit::decode(field->ptr()->kind_bits_)) {
        const intptr_t field_id =
            Smi::Value(field->ptr()->host_offset_or_field_id_);
        WriteFieldValue("static value", s->initial_field_table()->At(field_id));
        s->WriteUnsigned(field_id);
      } else {
        WriteFieldValue("offset", Smi::New(Field::TargetOffsetOf(field)));
      }
    }
  }

 private:
  GrowableArray<FieldPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FieldDeserializationCluster : public DeserializationCluster {
 public:
  FieldDeserializationCluster() : DeserializationCluster("Field") {}
  ~FieldDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Field::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    Snapshot::Kind kind = d->kind();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      FieldPtr field = static_cast<FieldPtr>(d->Ref(id));
      Deserializer::InitializeHeader(field, kFieldCid, Field::InstanceSize());
      ReadFromTo(field);
      if (kind != Snapshot::kFullAOT) {
        field->ptr()->guarded_list_length_ = static_cast<SmiPtr>(d->ReadRef());
      }
      if (kind == Snapshot::kFullJIT) {
        field->ptr()->dependent_code_ = static_cast<ArrayPtr>(d->ReadRef());
      }
      if (kind != Snapshot::kFullAOT) {
        field->ptr()->token_pos_ = d->ReadTokenPosition();
        field->ptr()->end_token_pos_ = d->ReadTokenPosition();
        field->ptr()->guarded_cid_ = d->ReadCid();
        field->ptr()->is_nullable_ = d->ReadCid();
        field->ptr()->static_type_exactness_state_ = d->Read<int8_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
        field->ptr()->kernel_offset_ = d->Read<uint32_t>();
#endif
      }
      field->ptr()->kind_bits_ = d->Read<uint16_t>();

      ObjectPtr value_or_offset = d->ReadRef();
      if (Field::StaticBit::decode(field->ptr()->kind_bits_)) {
        const intptr_t field_id = d->ReadUnsigned();
        d->initial_field_table()->SetAt(
            field_id, static_cast<InstancePtr>(value_or_offset));
        field->ptr()->host_offset_or_field_id_ = Smi::New(field_id);
      } else {
        field->ptr()->host_offset_or_field_id_ = Smi::RawCast(value_or_offset);
#if !defined(DART_PRECOMPILED_RUNTIME)
        field->ptr()->target_offset_ =
            Smi::Value(field->ptr()->host_offset_or_field_id_);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    Field& field = Field::Handle(d->zone());
    if (!Isolate::Current()->use_field_guards()) {
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        field ^= refs.At(i);
        field.set_guarded_cid_unsafe(kDynamicCid);
        field.set_is_nullable_unsafe(true);
        field.set_guarded_list_length_unsafe(Field::kNoFixedLength);
        field.set_guarded_list_length_in_object_offset_unsafe(
            Field::kUnknownLengthOffset);
        field.set_static_type_exactness_state(
            StaticTypeExactnessState::NotTracking());
      }
    } else {
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        field ^= refs.At(i);
        field.InitializeGuardedListLengthInObjectOffset(/*unsafe=*/true);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ScriptSerializationCluster : public SerializationCluster {
 public:
  ScriptSerializationCluster() : SerializationCluster("Script") {}
  ~ScriptSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ScriptPtr script = Script::RawCast(object);
    objects_.Add(script);
    PushFromTo(script);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kScriptCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ScriptPtr script = objects_[i];
      s->AssignRef(script);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ScriptPtr script = objects_[i];
      AutoTraceObjectName(script, script->ptr()->url_);
      WriteFromTo(script);
      s->Write<int32_t>(script->ptr()->line_offset_);
      s->Write<int32_t>(script->ptr()->col_offset_);
      if (s->kind() != Snapshot::kFullAOT) {
        // Clear out the max position cache in snapshots to ensure no
        // differences in the snapshot due to triggering caching vs. not.
        int32_t written_flags = ScriptLayout::CachedMaxPositionBitField::update(
            0, script->ptr()->flags_and_max_position_);
        written_flags =
            ScriptLayout::HasCachedMaxPositionBit::update(false, written_flags);
        s->Write<int32_t>(written_flags);
      }
      s->Write<int32_t>(script->ptr()->kernel_script_index_);
    }
  }

 private:
  GrowableArray<ScriptPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ScriptDeserializationCluster : public DeserializationCluster {
 public:
  ScriptDeserializationCluster() : DeserializationCluster("Script") {}
  ~ScriptDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Script::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ScriptPtr script = static_cast<ScriptPtr>(d->Ref(id));
      Deserializer::InitializeHeader(script, kScriptCid,
                                     Script::InstanceSize());
      ReadFromTo(script);
      script->ptr()->line_offset_ = d->Read<int32_t>();
      script->ptr()->col_offset_ = d->Read<int32_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      script->ptr()->flags_and_max_position_ = d->Read<int32_t>();
#endif
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

  void Trace(Serializer* s, ObjectPtr object) {
    LibraryPtr lib = Library::RawCast(object);
    objects_.Add(lib);
    PushFromTo(lib);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      LibraryPtr lib = objects_[i];
      s->AssignRef(lib);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      LibraryPtr lib = objects_[i];
      AutoTraceObjectName(lib, lib->ptr()->url_);
      WriteFromTo(lib);
      s->Write<int32_t>(lib->ptr()->index_);
      s->Write<uint16_t>(lib->ptr()->num_imports_);
      s->Write<int8_t>(lib->ptr()->load_state_);
      s->Write<uint8_t>(lib->ptr()->flags_);
      if (s->kind() != Snapshot::kFullAOT) {
        s->Write<uint32_t>(lib->ptr()->kernel_offset_);
      }
    }
  }

 private:
  GrowableArray<LibraryPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LibraryDeserializationCluster : public DeserializationCluster {
 public:
  LibraryDeserializationCluster() : DeserializationCluster("Library") {}
  ~LibraryDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Library::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      LibraryPtr lib = static_cast<LibraryPtr>(d->Ref(id));
      Deserializer::InitializeHeader(lib, kLibraryCid, Library::InstanceSize());
      ReadFromTo(lib);
      lib->ptr()->native_entry_resolver_ = NULL;
      lib->ptr()->native_entry_symbol_resolver_ = NULL;
      lib->ptr()->index_ = d->Read<int32_t>();
      lib->ptr()->num_imports_ = d->Read<uint16_t>();
      lib->ptr()->load_state_ = d->Read<int8_t>();
      lib->ptr()->flags_ =
          LibraryLayout::InFullSnapshotBit::update(true, d->Read<uint8_t>());
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (d->kind() != Snapshot::kFullAOT) {
        lib->ptr()->kernel_offset_ = d->Read<uint32_t>();
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

  void Trace(Serializer* s, ObjectPtr object) {
    NamespacePtr ns = Namespace::RawCast(object);
    objects_.Add(ns);
    PushFromTo(ns);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kNamespaceCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      NamespacePtr ns = objects_[i];
      s->AssignRef(ns);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      NamespacePtr ns = objects_[i];
      AutoTraceObject(ns);
      WriteFromTo(ns);
    }
  }

 private:
  GrowableArray<NamespacePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class NamespaceDeserializationCluster : public DeserializationCluster {
 public:
  NamespaceDeserializationCluster() : DeserializationCluster("Namespace") {}
  ~NamespaceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Namespace::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      NamespacePtr ns = static_cast<NamespacePtr>(d->Ref(id));
      Deserializer::InitializeHeader(ns, kNamespaceCid,
                                     Namespace::InstanceSize());
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

  void Trace(Serializer* s, ObjectPtr object) {
    KernelProgramInfoPtr info = KernelProgramInfo::RawCast(object);
    objects_.Add(info);
    PushFromTo(info);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kKernelProgramInfoCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      KernelProgramInfoPtr info = objects_[i];
      s->AssignRef(info);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      KernelProgramInfoPtr info = objects_[i];
      AutoTraceObject(info);
      WriteFromTo(info);
      s->Write<uint32_t>(info->ptr()->kernel_binary_version_);
    }
  }

 private:
  GrowableArray<KernelProgramInfoPtr> objects_;
};

// Since KernelProgramInfo objects are not written into full AOT snapshots,
// one will never need to read them from a full AOT snapshot.
class KernelProgramInfoDeserializationCluster : public DeserializationCluster {
 public:
  KernelProgramInfoDeserializationCluster()
      : DeserializationCluster("KernelProgramInfo") {}
  ~KernelProgramInfoDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, KernelProgramInfo::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      KernelProgramInfoPtr info = static_cast<KernelProgramInfoPtr>(d->Ref(id));
      Deserializer::InitializeHeader(info, kKernelProgramInfoCid,
                                     KernelProgramInfo::InstanceSize());
      ReadFromTo(info);
      info->ptr()->kernel_binary_version_ = d->Read<uint32_t>();
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    Array& array = Array::Handle(d->zone());
    KernelProgramInfo& info = KernelProgramInfo::Handle(d->zone());
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      info ^= refs.At(id);
      array = HashTables::New<UnorderedHashMap<SmiTraits>>(16, Heap::kOld);
      info.set_libraries_cache(array);
      array = HashTables::New<UnorderedHashMap<SmiTraits>>(16, Heap::kOld);
      info.set_classes_cache(array);
    }
  }
};

class CodeSerializationCluster : public SerializationCluster {
 public:
  explicit CodeSerializationCluster(Heap* heap)
      : SerializationCluster("Code"), array_(Array::Handle()) {}
  ~CodeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    CodePtr code = Code::RawCast(object);

    if (s->InCurrentLoadingUnit(code, /*record*/ true)) {
      objects_.Add(code);
    }

    if (!(s->kind() == Snapshot::kFullAOT && FLAG_use_bare_instructions)) {
      s->Push(code->ptr()->object_pool_);
    }
    s->Push(code->ptr()->owner_);
    s->Push(code->ptr()->exception_handlers_);
    s->Push(code->ptr()->pc_descriptors_);
    s->Push(code->ptr()->catch_entry_);
    if (s->InCurrentLoadingUnit(code->ptr()->compressed_stackmaps_)) {
      s->Push(code->ptr()->compressed_stackmaps_);
    }
    if (!FLAG_precompiled_mode || !FLAG_dwarf_stack_traces_mode) {
      s->Push(code->ptr()->inlined_id_to_function_);
      if (s->InCurrentLoadingUnit(code->ptr()->code_source_map_)) {
        s->Push(code->ptr()->code_source_map_);
      }
    }
    if (s->kind() == Snapshot::kFullJIT) {
      s->Push(code->ptr()->deopt_info_array_);
      s->Push(code->ptr()->static_calls_target_table_);
    } else if (s->kind() == Snapshot::kFullAOT) {
#if defined(DART_PRECOMPILER)
      auto const calls_array = code->ptr()->static_calls_target_table_;
      if (calls_array != Array::null()) {
        // Some Code entries in the static calls target table may only be
        // accessible via here, so push the Code objects.
        array_ = calls_array;
        for (auto entry : StaticCallsTable(array_)) {
          auto kind = Code::KindField::decode(
              Smi::Value(entry.Get<Code::kSCallTableKindAndOffset>()));
          switch (kind) {
            case Code::kCallViaCode:
              // Code object in the pool.
              continue;
            case Code::kPcRelativeTTSCall:
              // TTS will be reachable through type object which itself is
              // in the pool.
              continue;
            case Code::kPcRelativeCall:
            case Code::kPcRelativeTailCall:
              auto destination = entry.Get<Code::kSCallTableCodeOrTypeTarget>();
              ASSERT(destination->IsHeapObject() && destination->IsCode());
              s->Push(destination);
          }
        }
      }
#else
      UNREACHABLE();
#endif
    }
#if !defined(PRODUCT)
    s->Push(code->ptr()->return_address_metadata_);
    if (FLAG_code_comments) {
      s->Push(code->ptr()->comments_);
    }
#endif
  }

  struct CodeOrderInfo {
    CodePtr code;
    intptr_t order;
  };

  static int CompareCodeOrderInfo(CodeOrderInfo const* a,
                                  CodeOrderInfo const* b) {
    if (a->order < b->order) return -1;
    if (a->order > b->order) return 1;
    return 0;
  }

  static void Insert(GrowableArray<CodeOrderInfo>* order_list,
                     IntMap<intptr_t>* order_map,
                     CodePtr code) {
    InstructionsPtr instr = code->ptr()->instructions_;
    intptr_t key = static_cast<intptr_t>(instr);
    intptr_t order;
    if (order_map->HasKey(key)) {
      order = order_map->Lookup(key);
    } else {
      order = order_list->length() + 1;
      order_map->Insert(key, order);
    }
    CodeOrderInfo info;
    info.code = code;
    info.order = order;
    order_list->Add(info);
  }

  static void Sort(GrowableArray<CodePtr>* codes) {
    GrowableArray<CodeOrderInfo> order_list;
    IntMap<intptr_t> order_map;
    for (intptr_t i = 0; i < codes->length(); i++) {
      Insert(&order_list, &order_map, (*codes)[i]);
    }
    order_list.Sort(CompareCodeOrderInfo);
    ASSERT(order_list.length() == codes->length());
    for (intptr_t i = 0; i < order_list.length(); i++) {
      (*codes)[i] = order_list[i].code;
    }
  }

  static void Sort(GrowableArray<Code*>* codes) {
    GrowableArray<CodeOrderInfo> order_list;
    IntMap<intptr_t> order_map;
    for (intptr_t i = 0; i < codes->length(); i++) {
      Insert(&order_list, &order_map, (*codes)[i]->raw());
    }
    order_list.Sort(CompareCodeOrderInfo);
    ASSERT(order_list.length() == codes->length());
    for (intptr_t i = 0; i < order_list.length(); i++) {
      *(*codes)[i] = order_list[i].code;
    }
  }

  void WriteAlloc(Serializer* s) {
    Sort(&objects_);
    auto loading_units = s->loading_units();
    if (loading_units != nullptr) {
      for (intptr_t i = LoadingUnit::kRootId + 1; i < loading_units->length();
           i++) {
        auto unit_objects = loading_units->At(i)->deferred_objects();
        Sort(unit_objects);
        for (intptr_t j = 0; j < unit_objects->length(); j++) {
          deferred_objects_.Add(unit_objects->At(j)->raw());
        }
      }
    }
    s->PrepareInstructions(&objects_);

    s->WriteCid(kCodeCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      CodePtr code = objects_[i];
      s->AssignRef(code);
    }
    const intptr_t deferred_count = deferred_objects_.length();
    s->WriteUnsigned(deferred_count);
    for (intptr_t i = 0; i < deferred_count; i++) {
      CodePtr code = deferred_objects_[i];
      s->AssignRef(code);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      CodePtr code = objects_[i];
      WriteFill(s, kind, code, false);
    }
    const intptr_t deferred_count = deferred_objects_.length();
    for (intptr_t i = 0; i < deferred_count; i++) {
      CodePtr code = deferred_objects_[i];
      WriteFill(s, kind, code, true);
    }
  }

  void WriteFill(Serializer* s,
                 Snapshot::Kind kind,
                 CodePtr code,
                 bool deferred) {
    AutoTraceObjectName(code, MakeDisambiguatedCodeName(s, code));

    intptr_t pointer_offsets_length =
        Code::PtrOffBits::decode(code->ptr()->state_bits_);
    if (pointer_offsets_length != 0) {
      FATAL("Cannot serialize code with embedded pointers");
    }
    if (kind == Snapshot::kFullAOT && Code::IsDisabled(code)) {
      // Disabled code is fatal in AOT since we cannot recompile.
      s->UnexpectedObject(code, "Disabled code");
    }

    s->WriteInstructions(code->ptr()->instructions_,
                         code->ptr()->unchecked_offset_, code, deferred);
    if (kind == Snapshot::kFullJIT) {
      // TODO(rmacnak): Fix references to disabled code before serializing.
      // For now, we may write the FixCallersTarget or equivalent stub. This
      // will cause a fixup if this code is called.
      const uint32_t active_unchecked_offset =
          code->ptr()->unchecked_entry_point_ - code->ptr()->entry_point_;
      s->WriteInstructions(code->ptr()->active_instructions_,
                           active_unchecked_offset, code, deferred);
    }

    // No need to write object pool out if we are producing full AOT
    // snapshot with bare instructions.
    if (!(kind == Snapshot::kFullAOT && FLAG_use_bare_instructions)) {
      WriteField(code, object_pool_);
#if defined(DART_PRECOMPILER)
    } else if (FLAG_write_v8_snapshot_profile_to != nullptr &&
               code->ptr()->object_pool_ != ObjectPool::null()) {
      // If we are writing V8 snapshot profile then attribute references
      // going through the object pool to the code object itself.
      ObjectPoolPtr pool = code->ptr()->object_pool_;

      for (intptr_t i = 0; i < pool->ptr()->length_; i++) {
        uint8_t bits = pool->ptr()->entry_bits()[i];
        if (ObjectPool::TypeBits::decode(bits) ==
            ObjectPool::EntryType::kTaggedObject) {
          s->AttributeElementRef(pool->ptr()->data()[i].raw_obj_, i);
        }
      }
#endif  // defined(DART_PRECOMPILER)
    }
    WriteField(code, owner_);
    WriteField(code, exception_handlers_);
    WriteField(code, pc_descriptors_);
    WriteField(code, catch_entry_);
    if (s->InCurrentLoadingUnit(code->ptr()->compressed_stackmaps_)) {
      WriteField(code, compressed_stackmaps_);
    } else {
      WriteFieldValue(compressed_stackmaps_, CompressedStackMaps::null());
    }
    if (FLAG_precompiled_mode && FLAG_dwarf_stack_traces_mode) {
      WriteFieldValue(inlined_id_to_function_, Array::null());
      WriteFieldValue(code_source_map_, CodeSourceMap::null());
    } else {
      WriteField(code, inlined_id_to_function_);
      if (s->InCurrentLoadingUnit(code->ptr()->code_source_map_)) {
        WriteField(code, code_source_map_);
      } else {
        WriteFieldValue(code_source_map_, CodeSourceMap::null());
      }
    }
    if (kind == Snapshot::kFullJIT) {
      WriteField(code, deopt_info_array_);
      WriteField(code, static_calls_target_table_);
    }

#if defined(DART_PRECOMPILER)
    if (FLAG_write_v8_snapshot_profile_to != nullptr &&
        code->ptr()->static_calls_target_table_ != Array::null()) {
      // If we are writing V8 snapshot profile then attribute references
      // going through static calls.
      array_ = code->ptr()->static_calls_target_table_;
      intptr_t index = code->ptr()->object_pool_ != ObjectPool::null()
                           ? code->ptr()->object_pool_->ptr()->length_
                           : 0;
      for (auto entry : StaticCallsTable(array_)) {
        auto kind = Code::KindField::decode(
            Smi::Value(entry.Get<Code::kSCallTableKindAndOffset>()));
        switch (kind) {
          case Code::kCallViaCode:
            // Code object in the pool.
            continue;
          case Code::kPcRelativeTTSCall:
            // TTS will be reachable through type object which itself is
            // in the pool.
            continue;
          case Code::kPcRelativeCall:
          case Code::kPcRelativeTailCall:
            auto destination = entry.Get<Code::kSCallTableCodeOrTypeTarget>();
            ASSERT(destination->IsHeapObject() && destination->IsCode());
            s->AttributeElementRef(destination, index++);
        }
      }
    }
#endif  // defined(DART_PRECOMPILER)

#if !defined(PRODUCT)
    WriteField(code, return_address_metadata_);
    if (FLAG_code_comments) {
      WriteField(code, comments_);
    }
#endif
    s->Write<int32_t>(code->ptr()->state_bits_);
  }

  GrowableArray<CodePtr>* discovered_objects() { return &objects_; }

  // Some code objects would have their owners dropped from the snapshot,
  // which makes it is impossible to recover program structure when
  // analysing snapshot profile. To facilitate analysis of snapshot profiles
  // we include artificial nodes into profile representing such dropped
  // owners.
  void WriteDroppedOwnersIntoProfile(Serializer* s) {
    ASSERT(s->profile_writer() != nullptr);

    for (auto code : objects_) {
      ObjectPtr owner = WeakSerializationReference::Unwrap(code->ptr()->owner_);
      if (s->CreateArtificalNodeIfNeeded(owner)) {
        AutoTraceObject(code);
        s->AttributePropertyRef(owner, ":owner_",
                                /*permit_artificial_ref=*/true);
      }
    }
  }

 private:
  static const char* MakeDisambiguatedCodeName(Serializer* s, CodePtr c) {
    if (s->profile_writer() == nullptr) {
      return nullptr;
    }

    REUSABLE_CODE_HANDLESCOPE(s->thread());
    Code& code = reused_code_handle.Handle();
    code = c;
    return code.QualifiedName(
        NameFormattingParams::DisambiguatedWithoutClassName(
            Object::NameVisibility::kInternalName));
  }

  GrowableArray<CodePtr> objects_;
  GrowableArray<CodePtr> deferred_objects_;
  Array& array_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class CodeDeserializationCluster : public DeserializationCluster {
 public:
  CodeDeserializationCluster() : DeserializationCluster("Code") {}
  ~CodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    PageSpace* old_space = d->heap()->old_space();
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      auto code = AllocateUninitialized(old_space, Code::InstanceSize(0));
      d->AssignRef(code);
    }
    stop_index_ = d->next_index();
    deferred_start_index_ = d->next_index();
    const intptr_t deferred_count = d->ReadUnsigned();
    for (intptr_t i = 0; i < deferred_count; i++) {
      auto code = AllocateUninitialized(old_space, Code::InstanceSize(0));
      d->AssignRef(code);
    }
    deferred_stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ReadFill(d, id, false);
    }
    for (intptr_t id = deferred_start_index_; id < deferred_stop_index_; id++) {
      ReadFill(d, id, true);
    }
  }

  void ReadFill(Deserializer* d, intptr_t id, bool deferred) {
    auto const code = static_cast<CodePtr>(d->Ref(id));
    Deserializer::InitializeHeader(code, kCodeCid, Code::InstanceSize(0));

    d->ReadInstructions(code, deferred);

    // There would be a single global pool if this is a full AOT snapshot
    // with bare instructions.
    if (!(d->kind() == Snapshot::kFullAOT && FLAG_use_bare_instructions)) {
      code->ptr()->object_pool_ = static_cast<ObjectPoolPtr>(d->ReadRef());
    } else {
      code->ptr()->object_pool_ = ObjectPool::null();
    }
    code->ptr()->owner_ = d->ReadRef();
    code->ptr()->exception_handlers_ =
        static_cast<ExceptionHandlersPtr>(d->ReadRef());
    code->ptr()->pc_descriptors_ = static_cast<PcDescriptorsPtr>(d->ReadRef());
    code->ptr()->catch_entry_ = d->ReadRef();
    code->ptr()->compressed_stackmaps_ =
        static_cast<CompressedStackMapsPtr>(d->ReadRef());
    code->ptr()->inlined_id_to_function_ = static_cast<ArrayPtr>(d->ReadRef());
    code->ptr()->code_source_map_ = static_cast<CodeSourceMapPtr>(d->ReadRef());

#if !defined(DART_PRECOMPILED_RUNTIME)
    if (d->kind() == Snapshot::kFullJIT) {
      code->ptr()->deopt_info_array_ = static_cast<ArrayPtr>(d->ReadRef());
      code->ptr()->static_calls_target_table_ =
          static_cast<ArrayPtr>(d->ReadRef());
    }
#endif  // !DART_PRECOMPILED_RUNTIME

#if !defined(PRODUCT)
    code->ptr()->return_address_metadata_ = d->ReadRef();
    code->ptr()->var_descriptors_ = LocalVarDescriptors::null();
    code->ptr()->comments_ = FLAG_code_comments
                                 ? static_cast<ArrayPtr>(d->ReadRef())
                                 : Array::null();
    code->ptr()->compile_timestamp_ = 0;
#endif

    code->ptr()->state_bits_ = d->Read<int32_t>();
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    d->EndInstructions(refs, start_index_, stop_index_);

#if !defined(PRODUCT)
    if (!CodeObservers::AreActive() && !FLAG_support_disassembler) return;
#endif
    Code& code = Code::Handle(d->zone());
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
    Object& owner = Object::Handle(d->zone());
#endif
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      code ^= refs.At(id);
#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT)
      if (CodeObservers::AreActive()) {
        Code::NotifyCodeObservers(code, code.is_optimized());
      }
#endif
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
      owner = code.owner();
      if (owner.IsFunction()) {
        if ((FLAG_disassemble ||
             (code.is_optimized() && FLAG_disassemble_optimized)) &&
            compiler::PrintFilter::ShouldPrint(Function::Cast(owner))) {
          Disassembler::DisassembleCode(Function::Cast(owner), code,
                                        code.is_optimized());
        }
      } else if (FLAG_disassemble_stubs) {
        Disassembler::DisassembleStub(code.Name(), code);
      }
#endif  // !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
    }
  }

 private:
  intptr_t deferred_start_index_;
  intptr_t deferred_stop_index_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ObjectPoolSerializationCluster : public SerializationCluster {
 public:
  ObjectPoolSerializationCluster() : SerializationCluster("ObjectPool") {}
  ~ObjectPoolSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ObjectPoolPtr pool = ObjectPool::RawCast(object);
    objects_.Add(pool);

    const intptr_t length = pool->ptr()->length_;
    uint8_t* entry_bits = pool->ptr()->entry_bits();
    for (intptr_t i = 0; i < length; i++) {
      auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
      if (entry_type == ObjectPool::EntryType::kTaggedObject) {
        s->Push(pool->ptr()->data()[i].raw_obj_);
      }
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kObjectPoolCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ObjectPoolPtr pool = objects_[i];
      s->AssignRef(pool);
      AutoTraceObject(pool);
      const intptr_t length = pool->ptr()->length_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ObjectPoolPtr pool = objects_[i];
      AutoTraceObject(pool);
      const intptr_t length = pool->ptr()->length_;
      s->WriteUnsigned(length);
      uint8_t* entry_bits = pool->ptr()->entry_bits();
      for (intptr_t j = 0; j < length; j++) {
        s->Write<uint8_t>(entry_bits[j]);
        ObjectPoolLayout::Entry& entry = pool->ptr()->data()[j];
        switch (ObjectPool::TypeBits::decode(entry_bits[j])) {
          case ObjectPool::EntryType::kTaggedObject: {
            if ((entry.raw_obj_ == StubCode::CallNoScopeNative().raw()) ||
                (entry.raw_obj_ == StubCode::CallAutoScopeNative().raw())) {
              // Natives can run while precompiling, becoming linked and
              // switching their stub. Reset to the initial stub used for
              // lazy-linking.
              s->WriteElementRef(StubCode::CallBootstrapNative().raw(), j);
              break;
            }
            s->WriteElementRef(entry.raw_obj_, j);
            break;
          }
          case ObjectPool::EntryType::kImmediate: {
            s->Write<intptr_t>(entry.raw_value_);
            break;
          }
          case ObjectPool::EntryType::kNativeFunction:
          case ObjectPool::EntryType::kNativeFunctionWrapper: {
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
  GrowableArray<ObjectPoolPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ObjectPoolDeserializationCluster : public DeserializationCluster {
 public:
  ObjectPoolDeserializationCluster() : DeserializationCluster("ObjectPool") {}
  ~ObjectPoolDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, ObjectPool::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id += 1) {
      const intptr_t length = d->ReadUnsigned();
      ObjectPoolPtr pool = static_cast<ObjectPoolPtr>(d->Ref(id + 0));
      Deserializer::InitializeHeader(pool, kObjectPoolCid,
                                     ObjectPool::InstanceSize(length));
      pool->ptr()->length_ = length;
      for (intptr_t j = 0; j < length; j++) {
        const uint8_t entry_bits = d->Read<uint8_t>();
        pool->ptr()->entry_bits()[j] = entry_bits;
        ObjectPoolLayout::Entry& entry = pool->ptr()->data()[j];
        switch (ObjectPool::TypeBits::decode(entry_bits)) {
          case ObjectPool::EntryType::kTaggedObject:
            entry.raw_obj_ = d->ReadRef();
            break;
          case ObjectPool::EntryType::kImmediate:
            entry.raw_value_ = d->Read<intptr_t>();
            break;
          case ObjectPool::EntryType::kNativeFunction: {
            // Read nothing. Initialize with the lazy link entry.
            uword new_entry = NativeEntry::LinkNativeCallEntry();
            entry.raw_value_ = static_cast<intptr_t>(new_entry);
            break;
          }
          default:
            UNREACHABLE();
        }
      }
    }
  }
};

#if defined(DART_PRECOMPILER)
class WeakSerializationReferenceSerializationCluster
    : public SerializationCluster {
 public:
  WeakSerializationReferenceSerializationCluster(Zone* zone, Heap* heap)
      : SerializationCluster("WeakSerializationReference"),
        heap_(ASSERT_NOTNULL(heap)),
        objects_(zone, 0),
        canonical_wsrs_(zone, 0),
        canonical_wsr_map_(zone) {}
  ~WeakSerializationReferenceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ASSERT(s->kind() == Snapshot::kFullAOT);
    // Make sure we don't trace again after choosing canonical WSRs.
    ASSERT(!have_canonicalized_wsrs_);

    auto const ref = WeakSerializationReference::RawCast(object);
    objects_.Add(ref);
    // We do _not_ push the target, since this is not a strong reference.
  }

  void WriteAlloc(Serializer* s) {
    ASSERT(s->kind() == Snapshot::kFullAOT);
    ASSERT(have_canonicalized_wsrs_);

    s->WriteCid(kWeakSerializationReferenceCid);
    s->WriteUnsigned(WrittenCount());

    // Set up references for those objects that will be written.
    for (auto const& ref : canonical_wsrs_) {
      s->AssignRef(ref);
    }

    // In precompiled mode, set the object ID of each non-canonical WSR to
    // its canonical counterpart's object ID. This ensures that any reference to
    // it is serialized as a reference to the canonicalized one.
    for (auto const& ref : objects_) {
      ASSERT(IsReachableReference(heap_->GetObjectId(ref)));
      if (ShouldDrop(ref)) {
        // For dropped references, reset their ID to be the unreachable
        // reference value, so RefId retrieves the target ID instead.
        heap_->SetObjectId(ref, kUnreachableReference);
        continue;
      }
      // Skip if we've already allocated a reference (this is a canonical WSR).
      if (IsAllocatedReference(heap_->GetObjectId(ref))) continue;
      auto const target_cid = WeakSerializationReference::TargetClassIdOf(ref);
      ASSERT(canonical_wsr_map_.HasKey(target_cid));
      auto const canonical_index = canonical_wsr_map_.Lookup(target_cid) - 1;
      auto const canonical_wsr = objects_[canonical_index];
      // Set the object ID of this non-canonical WSR to the same as its
      // canonical WSR entry, so we'll reference the canonical WSR when
      // serializing references to this object.
      auto const canonical_heap_id = heap_->GetObjectId(canonical_wsr);
      ASSERT(IsAllocatedReference(canonical_heap_id));
      heap_->SetObjectId(ref, canonical_heap_id);
    }
  }

  void WriteFill(Serializer* s) {
    ASSERT(s->kind() == Snapshot::kFullAOT);
    for (auto const& ref : canonical_wsrs_) {
      AutoTraceObject(ref);

      // In precompiled mode, we drop the reference to the target and only
      // keep the class ID.
      s->WriteCid(WeakSerializationReference::TargetClassIdOf(ref));
    }
  }

  // Picks a WSR for each target class ID to be canonical. Should only be run
  // after all objects have been traced.
  void CanonicalizeReferences() {
    ASSERT(!have_canonicalized_wsrs_);
    for (intptr_t i = 0; i < objects_.length(); i++) {
      auto const ref = objects_[i];
      if (ShouldDrop(ref)) continue;
      auto const target_cid = WeakSerializationReference::TargetClassIdOf(ref);
      if (canonical_wsr_map_.HasKey(target_cid)) continue;
      canonical_wsr_map_.Insert(target_cid, i + 1);
      canonical_wsrs_.Add(ref);
    }
    have_canonicalized_wsrs_ = true;
  }

  intptr_t WrittenCount() const {
    ASSERT(have_canonicalized_wsrs_);
    return canonical_wsrs_.length();
  }

  intptr_t DroppedCount() const { return TotalCount() - WrittenCount(); }

  intptr_t TotalCount() const { return objects_.length(); }

 private:
  // Returns whether a WSR should be dropped due to its target being reachable
  // via strong references. WSRs only wrap heap objects, so we can just retrieve
  // the object ID from the heap directly.
  bool ShouldDrop(WeakSerializationReferencePtr ref) const {
    auto const target = WeakSerializationReference::TargetOf(ref);
    return IsReachableReference(heap_->GetObjectId(target));
  }

  Heap* const heap_;
  GrowableArray<WeakSerializationReferencePtr> objects_;
  GrowableArray<WeakSerializationReferencePtr> canonical_wsrs_;
  IntMap<intptr_t> canonical_wsr_map_;
  bool have_canonicalized_wsrs_ = false;
};
#endif

#if defined(DART_PRECOMPILED_RUNTIME)
class WeakSerializationReferenceDeserializationCluster
    : public DeserializationCluster {
 public:
  WeakSerializationReferenceDeserializationCluster()
      : DeserializationCluster("WeakSerializationReference") {}
  ~WeakSerializationReferenceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();

    for (intptr_t i = 0; i < count; i++) {
      auto ref = AllocateUninitialized(
          old_space, WeakSerializationReference::InstanceSize());
      d->AssignRef(ref);
    }

    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      auto const ref = static_cast<WeakSerializationReferencePtr>(d->Ref(id));
      Deserializer::InitializeHeader(
          ref, kWeakSerializationReferenceCid,
          WeakSerializationReference::InstanceSize());
      ref->ptr()->cid_ = d->ReadCid();
    }
  }
};
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
class PcDescriptorsSerializationCluster : public SerializationCluster {
 public:
  PcDescriptorsSerializationCluster() : SerializationCluster("PcDescriptors") {}
  ~PcDescriptorsSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    PcDescriptorsPtr desc = PcDescriptors::RawCast(object);
    objects_.Add(desc);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kPcDescriptorsCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      PcDescriptorsPtr desc = objects_[i];
      s->AssignRef(desc);
      AutoTraceObject(desc);
      const intptr_t length = desc->ptr()->length_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      PcDescriptorsPtr desc = objects_[i];
      AutoTraceObject(desc);
      const intptr_t length = desc->ptr()->length_;
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(desc->ptr()->data());
      s->WriteBytes(cdata, length);
    }
  }

 private:
  GrowableArray<PcDescriptorsPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class PcDescriptorsDeserializationCluster : public DeserializationCluster {
 public:
  PcDescriptorsDeserializationCluster()
      : DeserializationCluster("PcDescriptors") {}
  ~PcDescriptorsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         PcDescriptors::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id += 1) {
      const intptr_t length = d->ReadUnsigned();
      PcDescriptorsPtr desc = static_cast<PcDescriptorsPtr>(d->Ref(id));
      Deserializer::InitializeHeader(desc, kPcDescriptorsCid,
                                     PcDescriptors::InstanceSize(length));
      desc->ptr()->length_ = length;
      uint8_t* cdata = reinterpret_cast<uint8_t*>(desc->ptr()->data());
      d->ReadBytes(cdata, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
// PcDescriptor, CompressedStackMaps, OneByteString, TwoByteString
class RODataSerializationCluster : public SerializationCluster {
 public:
  RODataSerializationCluster(Zone* zone, const char* type, intptr_t cid)
      : SerializationCluster(ImageWriter::TagObjectTypeAsReadOnly(zone, type)),
        cid_(cid),
        objects_(),
        type_(type) {}
  ~RODataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    // A string's hash must already be computed when we write it because it
    // will be loaded into read-only memory. Extra bytes due to allocation
    // rounding need to be deterministically set for reliable deduplication in
    // shared images.
    if (object->ptr()->InVMIsolateHeap() ||
        s->heap()->old_space()->IsObjectFromImagePages(object)) {
      // This object is already read-only.
    } else {
      Object::FinalizeReadOnlyObject(object);
    }

    objects_.Add(object);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);

    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      ObjectPtr object = objects_[i];
      s->AssignRef(object);
      if (cid_ == kOneByteStringCid || cid_ == kTwoByteStringCid) {
        s->TraceStartWritingObject(type_, object, String::RawCast(object));
      } else {
        s->TraceStartWritingObject(type_, object, nullptr);
      }
      uint32_t offset = s->GetDataOffset(object);
      s->TraceDataOffset(offset);
      ASSERT(Utils::IsAligned(
          offset, compiler::target::ObjectAlignment::kObjectAlignment));
      ASSERT(offset > running_offset);
      s->WriteUnsigned((offset - running_offset) >>
                       compiler::target::ObjectAlignment::kObjectAlignmentLog2);
      running_offset = offset;
      s->TraceEndWritingObject();
    }
  }

  void WriteFill(Serializer* s) {
    // No-op.
  }

 private:
  const intptr_t cid_;
  GrowableArray<ObjectPtr> objects_;
  const char* const type_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RODataDeserializationCluster : public DeserializationCluster {
 public:
  explicit RODataDeserializationCluster(intptr_t cid)
      : DeserializationCluster("ROData"), cid_(cid) {}
  ~RODataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    intptr_t count = d->ReadUnsigned();
    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      running_offset += d->ReadUnsigned() << kObjectAlignmentLog2;
      d->AssignRef(d->GetObjectAt(running_offset));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    // No-op.
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && IsStringClassId(cid_) &&
        (d->isolate() != Dart::vm_isolate())) {
      CanonicalStringSet table(d->zone(),
                               d->isolate()->object_store()->symbol_table());
      String& str = String::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        str ^= refs.At(i);
        ASSERT(str.IsCanonical());
        bool present = table.Insert(str);
        ASSERT(!present);
      }
      d->isolate()->object_store()->set_symbol_table(table.Release());
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ExceptionHandlersSerializationCluster : public SerializationCluster {
 public:
  ExceptionHandlersSerializationCluster()
      : SerializationCluster("ExceptionHandlers") {}
  ~ExceptionHandlersSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ExceptionHandlersPtr handlers = ExceptionHandlers::RawCast(object);
    objects_.Add(handlers);

    s->Push(handlers->ptr()->handled_types_data_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kExceptionHandlersCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ExceptionHandlersPtr handlers = objects_[i];
      s->AssignRef(handlers);
      AutoTraceObject(handlers);
      const intptr_t length = handlers->ptr()->num_entries_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ExceptionHandlersPtr handlers = objects_[i];
      AutoTraceObject(handlers);
      const intptr_t length = handlers->ptr()->num_entries_;
      s->WriteUnsigned(length);
      WriteField(handlers, handled_types_data_);
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
  GrowableArray<ExceptionHandlersPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExceptionHandlersDeserializationCluster : public DeserializationCluster {
 public:
  ExceptionHandlersDeserializationCluster()
      : DeserializationCluster("ExceptionHandlers") {}
  ~ExceptionHandlersDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(
          old_space, ExceptionHandlers::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ExceptionHandlersPtr handlers =
          static_cast<ExceptionHandlersPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(handlers, kExceptionHandlersCid,
                                     ExceptionHandlers::InstanceSize(length));
      handlers->ptr()->num_entries_ = length;
      handlers->ptr()->handled_types_data_ =
          static_cast<ArrayPtr>(d->ReadRef());
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

  void Trace(Serializer* s, ObjectPtr object) {
    ContextPtr context = Context::RawCast(object);
    objects_.Add(context);

    s->Push(context->ptr()->parent_);
    const intptr_t length = context->ptr()->num_variables_;
    for (intptr_t i = 0; i < length; i++) {
      s->Push(context->ptr()->data()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kContextCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ContextPtr context = objects_[i];
      s->AssignRef(context);
      AutoTraceObject(context);
      const intptr_t length = context->ptr()->num_variables_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ContextPtr context = objects_[i];
      AutoTraceObject(context);
      const intptr_t length = context->ptr()->num_variables_;
      s->WriteUnsigned(length);
      WriteField(context, parent_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(context->ptr()->data()[j], j);
      }
    }
  }

 private:
  GrowableArray<ContextPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ContextDeserializationCluster : public DeserializationCluster {
 public:
  ContextDeserializationCluster() : DeserializationCluster("Context") {}
  ~ContextDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, Context::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ContextPtr context = static_cast<ContextPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(context, kContextCid,
                                     Context::InstanceSize(length));
      context->ptr()->num_variables_ = length;
      context->ptr()->parent_ = static_cast<ContextPtr>(d->ReadRef());
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

  void Trace(Serializer* s, ObjectPtr object) {
    ContextScopePtr scope = ContextScope::RawCast(object);
    objects_.Add(scope);

    const intptr_t length = scope->ptr()->num_variables_;
    PushFromTo(scope, length);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kContextScopeCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ContextScopePtr scope = objects_[i];
      s->AssignRef(scope);
      AutoTraceObject(scope);
      const intptr_t length = scope->ptr()->num_variables_;
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ContextScopePtr scope = objects_[i];
      AutoTraceObject(scope);
      const intptr_t length = scope->ptr()->num_variables_;
      s->WriteUnsigned(length);
      s->Write<bool>(scope->ptr()->is_implicit_);
      WriteFromTo(scope, length);
    }
  }

 private:
  GrowableArray<ContextScopePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ContextScopeDeserializationCluster : public DeserializationCluster {
 public:
  ContextScopeDeserializationCluster()
      : DeserializationCluster("ContextScope") {}
  ~ContextScopeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, ContextScope::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ContextScopePtr scope = static_cast<ContextScopePtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(scope, kContextScopeCid,
                                     ContextScope::InstanceSize(length));
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

  void Trace(Serializer* s, ObjectPtr object) {
    UnlinkedCallPtr unlinked = UnlinkedCall::RawCast(object);
    objects_.Add(unlinked);
    PushFromTo(unlinked);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnlinkedCallCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      UnlinkedCallPtr unlinked = objects_[i];
      s->AssignRef(unlinked);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      UnlinkedCallPtr unlinked = objects_[i];
      AutoTraceObjectName(unlinked, unlinked->ptr()->target_name_);
      WriteFromTo(unlinked);
      s->Write<bool>(unlinked->ptr()->can_patch_to_monomorphic_);
    }
  }

 private:
  GrowableArray<UnlinkedCallPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnlinkedCallDeserializationCluster : public DeserializationCluster {
 public:
  UnlinkedCallDeserializationCluster()
      : DeserializationCluster("UnlinkedCall") {}
  ~UnlinkedCallDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, UnlinkedCall::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      UnlinkedCallPtr unlinked = static_cast<UnlinkedCallPtr>(d->Ref(id));
      Deserializer::InitializeHeader(unlinked, kUnlinkedCallCid,
                                     UnlinkedCall::InstanceSize());
      ReadFromTo(unlinked);
      unlinked->ptr()->can_patch_to_monomorphic_ = d->Read<bool>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ICDataSerializationCluster : public SerializationCluster {
 public:
  ICDataSerializationCluster() : SerializationCluster("ICData") {}
  ~ICDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ICDataPtr ic = ICData::RawCast(object);
    objects_.Add(ic);
    PushFromTo(ic);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kICDataCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ICDataPtr ic = objects_[i];
      s->AssignRef(ic);
    }
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ICDataPtr ic = objects_[i];
      AutoTraceObjectName(ic, ic->ptr()->target_name_);
      WriteFromTo(ic);
      if (kind != Snapshot::kFullAOT) {
        NOT_IN_PRECOMPILED(s->Write<int32_t>(ic->ptr()->deopt_id_));
      }
      s->Write<uint32_t>(ic->ptr()->state_bits_);
    }
  }

 private:
  GrowableArray<ICDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ICDataDeserializationCluster : public DeserializationCluster {
 public:
  ICDataDeserializationCluster() : DeserializationCluster("ICData") {}
  ~ICDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, ICData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ICDataPtr ic = static_cast<ICDataPtr>(d->Ref(id));
      Deserializer::InitializeHeader(ic, kICDataCid, ICData::InstanceSize());
      ReadFromTo(ic);
      NOT_IN_PRECOMPILED(ic->ptr()->deopt_id_ = d->Read<int32_t>());
      ic->ptr()->state_bits_ = d->Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MegamorphicCacheSerializationCluster : public SerializationCluster {
 public:
  MegamorphicCacheSerializationCluster()
      : SerializationCluster("MegamorphicCache") {}
  ~MegamorphicCacheSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    MegamorphicCachePtr cache = MegamorphicCache::RawCast(object);
    objects_.Add(cache);
    PushFromTo(cache);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kMegamorphicCacheCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      MegamorphicCachePtr cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      MegamorphicCachePtr cache = objects_[i];
      AutoTraceObjectName(cache, cache->ptr()->target_name_);
      WriteFromTo(cache);
      s->Write<int32_t>(cache->ptr()->filled_entry_count_);
    }
  }

 private:
  GrowableArray<MegamorphicCachePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MegamorphicCacheDeserializationCluster : public DeserializationCluster {
 public:
  MegamorphicCacheDeserializationCluster()
      : DeserializationCluster("MegamorphicCache") {}
  ~MegamorphicCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, MegamorphicCache::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      MegamorphicCachePtr cache = static_cast<MegamorphicCachePtr>(d->Ref(id));
      Deserializer::InitializeHeader(cache, kMegamorphicCacheCid,
                                     MegamorphicCache::InstanceSize());
      ReadFromTo(cache);
      cache->ptr()->filled_entry_count_ = d->Read<int32_t>();
    }
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (FLAG_use_bare_instructions) {
      // By default, every megamorphic call site will load the target
      // [Function] from the hash table and call indirectly via loading the
      // entrypoint from the function.
      //
      // In --use-bare-instruction we reduce the extra indirection via the
      // [Function] object by storing the entry point directly into the hashmap.
      //
      // Currently our AOT compiler will emit megamorphic calls in certain
      // situations (namely in slow-path code of CheckedSmi* instructions).
      //
      // TODO(compiler-team): Change the CheckedSmi* slow path code to use
      // normal switchable calls instead of megamorphic calls. (This is also a
      // memory balance beause [MegamorphicCache]s are per-selector while
      // [ICData] are per-callsite.)
      auto& cache = MegamorphicCache::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; ++i) {
        cache ^= refs.At(i);
        cache.SwitchToBareInstructions();
      }
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SubtypeTestCacheSerializationCluster : public SerializationCluster {
 public:
  SubtypeTestCacheSerializationCluster()
      : SerializationCluster("SubtypeTestCache") {}
  ~SubtypeTestCacheSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    SubtypeTestCachePtr cache = SubtypeTestCache::RawCast(object);
    objects_.Add(cache);
    s->Push(cache->ptr()->cache_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kSubtypeTestCacheCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      SubtypeTestCachePtr cache = objects_[i];
      s->AssignRef(cache);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      SubtypeTestCachePtr cache = objects_[i];
      AutoTraceObject(cache);
      WriteField(cache, cache_);
    }
  }

 private:
  GrowableArray<SubtypeTestCachePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SubtypeTestCacheDeserializationCluster : public DeserializationCluster {
 public:
  SubtypeTestCacheDeserializationCluster()
      : DeserializationCluster("SubtypeTestCache") {}
  ~SubtypeTestCacheDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, SubtypeTestCache::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      SubtypeTestCachePtr cache = static_cast<SubtypeTestCachePtr>(d->Ref(id));
      Deserializer::InitializeHeader(cache, kSubtypeTestCacheCid,
                                     SubtypeTestCache::InstanceSize());
      cache->ptr()->cache_ = static_cast<ArrayPtr>(d->ReadRef());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LoadingUnitSerializationCluster : public SerializationCluster {
 public:
  LoadingUnitSerializationCluster() : SerializationCluster("LoadingUnit") {}
  ~LoadingUnitSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LoadingUnitPtr unit = LoadingUnit::RawCast(object);
    objects_.Add(unit);
    s->Push(unit->ptr()->parent_);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLoadingUnitCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      LoadingUnitPtr unit = objects_[i];
      s->AssignRef(unit);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      LoadingUnitPtr unit = objects_[i];
      AutoTraceObject(unit);
      WriteField(unit, parent_);
      s->Write<int32_t>(unit->ptr()->id_);
    }
  }

 private:
  GrowableArray<LoadingUnitPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LoadingUnitDeserializationCluster : public DeserializationCluster {
 public:
  LoadingUnitDeserializationCluster() : DeserializationCluster("LoadingUnit") {}
  ~LoadingUnitDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LoadingUnit::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      LoadingUnitPtr unit = static_cast<LoadingUnitPtr>(d->Ref(id));
      Deserializer::InitializeHeader(unit, kLoadingUnitCid,
                                     LoadingUnit::InstanceSize());
      unit->ptr()->parent_ = static_cast<LoadingUnitPtr>(d->ReadRef());
      unit->ptr()->base_objects_ = Array::null();
      unit->ptr()->id_ = d->Read<int32_t>();
      unit->ptr()->loaded_ = false;
      unit->ptr()->load_outstanding_ = false;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LanguageErrorSerializationCluster : public SerializationCluster {
 public:
  LanguageErrorSerializationCluster() : SerializationCluster("LanguageError") {}
  ~LanguageErrorSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LanguageErrorPtr error = LanguageError::RawCast(object);
    objects_.Add(error);
    PushFromTo(error);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLanguageErrorCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      LanguageErrorPtr error = objects_[i];
      s->AssignRef(error);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      LanguageErrorPtr error = objects_[i];
      AutoTraceObject(error);
      WriteFromTo(error);
      s->WriteTokenPosition(error->ptr()->token_pos_);
      s->Write<bool>(error->ptr()->report_after_token_);
      s->Write<int8_t>(error->ptr()->kind_);
    }
  }

 private:
  GrowableArray<LanguageErrorPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LanguageErrorDeserializationCluster : public DeserializationCluster {
 public:
  LanguageErrorDeserializationCluster()
      : DeserializationCluster("LanguageError") {}
  ~LanguageErrorDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LanguageError::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      LanguageErrorPtr error = static_cast<LanguageErrorPtr>(d->Ref(id));
      Deserializer::InitializeHeader(error, kLanguageErrorCid,
                                     LanguageError::InstanceSize());
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

  void Trace(Serializer* s, ObjectPtr object) {
    UnhandledExceptionPtr exception = UnhandledException::RawCast(object);
    objects_.Add(exception);
    PushFromTo(exception);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kUnhandledExceptionCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      UnhandledExceptionPtr exception = objects_[i];
      s->AssignRef(exception);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      UnhandledExceptionPtr exception = objects_[i];
      AutoTraceObject(exception);
      WriteFromTo(exception);
    }
  }

 private:
  GrowableArray<UnhandledExceptionPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnhandledExceptionDeserializationCluster : public DeserializationCluster {
 public:
  UnhandledExceptionDeserializationCluster()
      : DeserializationCluster("UnhandledException") {}
  ~UnhandledExceptionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, UnhandledException::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      UnhandledExceptionPtr exception =
          static_cast<UnhandledExceptionPtr>(d->Ref(id));
      Deserializer::InitializeHeader(exception, kUnhandledExceptionCid,
                                     UnhandledException::InstanceSize());
      ReadFromTo(exception);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class InstanceSerializationCluster : public SerializationCluster {
 public:
  explicit InstanceSerializationCluster(intptr_t cid)
      : SerializationCluster("Instance"), cid_(cid) {
    ClassPtr cls = Isolate::Current()->class_table()->At(cid);
    host_next_field_offset_in_words_ =
        cls->ptr()->host_next_field_offset_in_words_;
    ASSERT(host_next_field_offset_in_words_ > 0);
#if !defined(DART_PRECOMPILED_RUNTIME)
    target_next_field_offset_in_words_ =
        cls->ptr()->target_next_field_offset_in_words_;
    target_instance_size_in_words_ = cls->ptr()->target_instance_size_in_words_;
    ASSERT(target_next_field_offset_in_words_ > 0);
    ASSERT(target_instance_size_in_words_ > 0);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }
  ~InstanceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    InstancePtr instance = Instance::RawCast(object);
    objects_.Add(instance);
    const intptr_t next_field_offset = host_next_field_offset_in_words_
                                       << kWordSizeLog2;
    const auto unboxed_fields_bitmap =
        s->isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
            cid_);
    intptr_t offset = Instance::NextFieldOffset();
    while (offset < next_field_offset) {
      // Skips unboxed fields
      if (!unboxed_fields_bitmap.Get(offset / kWordSize)) {
        ObjectPtr raw_obj = *reinterpret_cast<ObjectPtr*>(
            reinterpret_cast<uword>(instance->ptr()) + offset);
        s->Push(raw_obj);
      }
      offset += kWordSize;
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);

#if !defined(DART_PRECOMPILED_RUNTIME)
    s->Write<int32_t>(target_next_field_offset_in_words_);
    s->Write<int32_t>(target_instance_size_in_words_);
#else
    s->Write<int32_t>(host_next_field_offset_in_words_);
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)

    for (intptr_t i = 0; i < count; i++) {
      InstancePtr instance = objects_[i];
      s->AssignRef(instance);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t next_field_offset = host_next_field_offset_in_words_
                                 << kWordSizeLog2;
    const intptr_t count = objects_.length();
    s->WriteUnsigned64(CalculateTargetUnboxedFieldsBitmap(s, cid_).Value());
    const auto unboxed_fields_bitmap =
        s->isolate()->group()->shared_class_table()->GetUnboxedFieldsMapAt(
            cid_);

    for (intptr_t i = 0; i < count; i++) {
      InstancePtr instance = objects_[i];
      AutoTraceObject(instance);
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        if (unboxed_fields_bitmap.Get(offset / kWordSize)) {
          // Writes 32 bits of the unboxed value at a time
          const uword value = *reinterpret_cast<uword*>(
              reinterpret_cast<uword>(instance->ptr()) + offset);
          s->WriteWordWith32BitWrites(value);
        } else {
          ObjectPtr raw_obj = *reinterpret_cast<ObjectPtr*>(
              reinterpret_cast<uword>(instance->ptr()) + offset);
          s->WriteElementRef(raw_obj, offset);
        }
        offset += kWordSize;
      }
    }
  }

 private:
  const intptr_t cid_;
  intptr_t host_next_field_offset_in_words_;
#if !defined(DART_PRECOMPILED_RUNTIME)
  intptr_t target_next_field_offset_in_words_;
  intptr_t target_instance_size_in_words_;
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
  GrowableArray<InstancePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class InstanceDeserializationCluster : public DeserializationCluster {
 public:
  explicit InstanceDeserializationCluster(intptr_t cid)
      : DeserializationCluster("Instance"), cid_(cid) {}
  ~InstanceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    next_field_offset_in_words_ = d->Read<int32_t>();
    instance_size_in_words_ = d->Read<int32_t>();
    intptr_t instance_size =
        Object::RoundedAllocationSize(instance_size_in_words_ * kWordSize);
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, instance_size));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    intptr_t next_field_offset = next_field_offset_in_words_ << kWordSizeLog2;
    intptr_t instance_size =
        Object::RoundedAllocationSize(instance_size_in_words_ * kWordSize);
    const UnboxedFieldBitmap unboxed_fields_bitmap(d->ReadUnsigned64());

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      InstancePtr instance = static_cast<InstancePtr>(d->Ref(id));
      Deserializer::InitializeHeader(instance, cid_, instance_size,
                                     is_canonical);
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        if (unboxed_fields_bitmap.Get(offset / kWordSize)) {
          uword* p = reinterpret_cast<uword*>(
              reinterpret_cast<uword>(instance->ptr()) + offset);
          // Reads 32 bits of the unboxed value at a time
          *p = d->ReadWordWith32BitReads();
        } else {
          ObjectPtr* p = reinterpret_cast<ObjectPtr*>(
              reinterpret_cast<uword>(instance->ptr()) + offset);
          *p = d->ReadRef();
        }
        offset += kWordSize;
      }
      if (offset < instance_size) {
        ObjectPtr* p = reinterpret_cast<ObjectPtr*>(
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

  void Trace(Serializer* s, ObjectPtr object) {
    LibraryPrefixPtr prefix = LibraryPrefix::RawCast(object);
    objects_.Add(prefix);
    PushFromTo(prefix);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLibraryPrefixCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      LibraryPrefixPtr prefix = objects_[i];
      s->AssignRef(prefix);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      LibraryPrefixPtr prefix = objects_[i];
      AutoTraceObject(prefix);
      WriteFromTo(prefix);
      s->Write<uint16_t>(prefix->ptr()->num_imports_);
      s->Write<bool>(prefix->ptr()->is_deferred_load_);
    }
  }

 private:
  GrowableArray<LibraryPrefixPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LibraryPrefixDeserializationCluster : public DeserializationCluster {
 public:
  LibraryPrefixDeserializationCluster()
      : DeserializationCluster("LibraryPrefix") {}
  ~LibraryPrefixDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LibraryPrefix::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      LibraryPrefixPtr prefix = static_cast<LibraryPrefixPtr>(d->Ref(id));
      Deserializer::InitializeHeader(prefix, kLibraryPrefixCid,
                                     LibraryPrefix::InstanceSize());
      ReadFromTo(prefix);
      prefix->ptr()->num_imports_ = d->Read<uint16_t>();
      prefix->ptr()->is_deferred_load_ = d->Read<bool>();
      prefix->ptr()->is_loaded_ = !prefix->ptr()->is_deferred_load_;
    }
  }
};

// Used to pack nullability into other serialized values.
static constexpr intptr_t kNullabilityBitSize = 2;
static constexpr intptr_t kNullabilityBitMask = (1 << kNullabilityBitSize) - 1;

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeSerializationCluster : public SerializationCluster {
 public:
  TypeSerializationCluster() : SerializationCluster("Type") {}
  ~TypeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypePtr type = Type::RawCast(object);
    objects_.Add(type);

    PushFromTo(type);

    if (type->ptr()->type_class_id_->IsHeapObject()) {
      // Type class is still an unresolved class.
      UNREACHABLE();
    }

    SmiPtr raw_type_class_id = Smi::RawCast(type->ptr()->type_class_id_);
    ClassPtr type_class =
        s->isolate()->class_table()->At(Smi::Value(raw_type_class_id));
    s->Push(type_class);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypePtr type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteType(s, objects_[i]);
    }
  }

 private:
  void WriteType(Serializer* s, TypePtr type) {
    AutoTraceObject(type);
    WriteFromTo(type);
    s->WriteTokenPosition(type->ptr()->token_pos_);
    ASSERT(type->ptr()->type_state_ < (1 << TypeLayout::kTypeStateBitSize));
    ASSERT(type->ptr()->nullability_ < (1 << kNullabilityBitSize));
    static_assert(TypeLayout::kTypeStateBitSize + kNullabilityBitSize <=
                      kBitsPerByte * sizeof(uint8_t),
                  "Cannot pack type_state_ and nullability_ into a uint8_t");
    const uint8_t combined = (type->ptr()->type_state_ << kNullabilityBitSize) |
                             type->ptr()->nullability_;
    ASSERT_EQUAL(type->ptr()->type_state_, combined >> kNullabilityBitSize);
    ASSERT_EQUAL(type->ptr()->nullability_, combined & kNullabilityBitMask);
    s->Write<uint8_t>(combined);
  }

  GrowableArray<TypePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeDeserializationCluster : public DeserializationCluster {
 public:
  TypeDeserializationCluster() : DeserializationCluster("Type") {}
  ~TypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Type::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypePtr type = static_cast<TypePtr>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     is_canonical);
      ReadFromTo(type);
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      const uint8_t combined = d->Read<uint8_t>();
      type->ptr()->type_state_ = combined >> kNullabilityBitSize;
      type->ptr()->nullability_ = combined & kNullabilityBitMask;
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      CanonicalTypeSet table(d->zone(),
                             d->isolate()->object_store()->canonical_types());
      Type& type = Type::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        type ^= refs.At(i);
        ASSERT(type.IsCanonical());
        bool present = table.Insert(type);
        // Two recursive types with different topology (and hashes) may be
        // equal.
        ASSERT(!present || type.IsRecursive());
      }
      d->isolate()->object_store()->set_canonical_types(table.Release());
    }

    Type& type = Type::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type ^= refs.At(id);
        stub = type.type_test_stub();
        type.SetTypeTestingStub(stub);  // Update type_test_stub_entry_point_
      }
    } else {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type);
        type.SetTypeTestingStub(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeRefSerializationCluster : public SerializationCluster {
 public:
  TypeRefSerializationCluster() : SerializationCluster("TypeRef") {}
  ~TypeRefSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypeRefPtr type = TypeRef::RawCast(object);
    objects_.Add(type);
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeRefCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypeRefPtr type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypeRefPtr type = objects_[i];
      AutoTraceObject(type);
      WriteFromTo(type);
    }
  }

 private:
  GrowableArray<TypeRefPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeRefDeserializationCluster : public DeserializationCluster {
 public:
  TypeRefDeserializationCluster() : DeserializationCluster("TypeRef") {}
  ~TypeRefDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, TypeRef::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypeRefPtr type = static_cast<TypeRefPtr>(d->Ref(id));
      Deserializer::InitializeHeader(type, kTypeRefCid,
                                     TypeRef::InstanceSize());
      ReadFromTo(type);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    TypeRef& type_ref = TypeRef::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_ref ^= refs.At(id);
        stub = type_ref.type_test_stub();
        type_ref.SetTypeTestingStub(
            stub);  // Update type_test_stub_entry_point_
      }
    } else {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_ref ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type_ref);
        type_ref.SetTypeTestingStub(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeParameterSerializationCluster : public SerializationCluster {
 public:
  TypeParameterSerializationCluster() : SerializationCluster("TypeParameter") {}
  ~TypeParameterSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypeParameterPtr type = TypeParameter::RawCast(object);
    objects_.Add(type);

    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTypeParameterCid);
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypeParameterPtr type = objects_[i];
      s->AssignRef(type);
    }
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteTypeParameter(s, objects_[i]);
    }
  }

 private:
  void WriteTypeParameter(Serializer* s, TypeParameterPtr type) {
    AutoTraceObject(type);
    WriteFromTo(type);
    s->Write<int32_t>(type->ptr()->parameterized_class_id_);
    s->WriteTokenPosition(type->ptr()->token_pos_);
    s->Write<int16_t>(type->ptr()->index_);
    ASSERT(type->ptr()->flags_ < (1 << TypeParameterLayout::kFlagsBitSize));
    ASSERT(type->ptr()->nullability_ < (1 << kNullabilityBitSize));
    static_assert(TypeParameterLayout::kFlagsBitSize + kNullabilityBitSize <=
                      kBitsPerByte * sizeof(uint8_t),
                  "Cannot pack flags_ and nullability_ into a uint8_t");
    const uint8_t combined = (type->ptr()->flags_ << kNullabilityBitSize) |
                             type->ptr()->nullability_;
    ASSERT_EQUAL(type->ptr()->flags_, combined >> kNullabilityBitSize);
    ASSERT_EQUAL(type->ptr()->nullability_, combined & kNullabilityBitMask);
    s->Write<uint8_t>(combined);
  }

  GrowableArray<TypeParameterPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeParameterDeserializationCluster : public DeserializationCluster {
 public:
  TypeParameterDeserializationCluster()
      : DeserializationCluster("TypeParameter") {}
  ~TypeParameterDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, TypeParameter::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypeParameterPtr type = static_cast<TypeParameterPtr>(d->Ref(id));
      Deserializer::InitializeHeader(
          type, kTypeParameterCid, TypeParameter::InstanceSize(), is_canonical);
      ReadFromTo(type);
      type->ptr()->parameterized_class_id_ = d->Read<int32_t>();
      type->ptr()->token_pos_ = d->ReadTokenPosition();
      type->ptr()->index_ = d->Read<int16_t>();
      const uint8_t combined = d->Read<uint8_t>();
      type->ptr()->flags_ = combined >> kNullabilityBitSize;
      type->ptr()->nullability_ = combined & kNullabilityBitMask;
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      CanonicalTypeParameterSet table(
          d->zone(), d->isolate()->object_store()->canonical_type_parameters());
      TypeParameter& type_param = TypeParameter::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        type_param ^= refs.At(i);
        ASSERT(type_param.IsCanonical());
        if (!type_param.IsDeclaration()) {
          bool present = table.Insert(type_param);
          ASSERT(!present);
        }
      }
      d->isolate()->object_store()->set_canonical_type_parameters(
          table.Release());
    }

    TypeParameter& type_param = TypeParameter::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_param ^= refs.At(id);
        stub = type_param.type_test_stub();
        type_param.SetTypeTestingStub(
            stub);  // Update type_test_stub_entry_point_
      }
    } else {
      for (intptr_t id = start_index_; id < stop_index_; id++) {
        type_param ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type_param);
        type_param.SetTypeTestingStub(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureSerializationCluster : public SerializationCluster {
 public:
  ClosureSerializationCluster() : SerializationCluster("Closure") {}
  ~ClosureSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ClosurePtr closure = Closure::RawCast(object);
    objects_.Add(closure);
    PushFromTo(closure);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kClosureCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ClosurePtr closure = objects_[i];
      s->AssignRef(closure);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ClosurePtr closure = objects_[i];
      AutoTraceObject(closure);
      WriteFromTo(closure);
    }
  }

 private:
  GrowableArray<ClosurePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClosureDeserializationCluster : public DeserializationCluster {
 public:
  ClosureDeserializationCluster() : DeserializationCluster("Closure") {}
  ~ClosureDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Closure::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ClosurePtr closure = static_cast<ClosurePtr>(d->Ref(id));
      Deserializer::InitializeHeader(closure, kClosureCid,
                                     Closure::InstanceSize(), is_canonical);
      ReadFromTo(closure);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MintSerializationCluster : public SerializationCluster {
 public:
  MintSerializationCluster() : SerializationCluster("int") {}
  ~MintSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    if (!object->IsHeapObject()) {
      SmiPtr smi = Smi::RawCast(object);
      smis_.Add(smi);
    } else {
      MintPtr mint = Mint::RawCast(object);
      mints_.Add(mint);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kMintCid);

    s->WriteUnsigned(smis_.length() + mints_.length());
    for (intptr_t i = 0; i < smis_.length(); i++) {
      SmiPtr smi = smis_[i];
      s->AssignRef(smi);
      AutoTraceObject(smi);
      s->Write<int64_t>(Smi::Value(smi));
    }
    for (intptr_t i = 0; i < mints_.length(); i++) {
      MintPtr mint = mints_[i];
      s->AssignRef(mint);
      AutoTraceObject(mint);
      s->Write<int64_t>(mint->ptr()->value_);
    }
  }

  void WriteFill(Serializer* s) {}

 private:
  GrowableArray<SmiPtr> smis_;
  GrowableArray<MintPtr> mints_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MintDeserializationCluster : public DeserializationCluster {
 public:
  MintDeserializationCluster() : DeserializationCluster("int") {}
  ~MintDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    PageSpace* old_space = d->heap()->old_space();

    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      int64_t value = d->Read<int64_t>();
      if (Smi::IsValid(value)) {
        d->AssignRef(Smi::New(value));
      } else {
        MintPtr mint = static_cast<MintPtr>(
            AllocateUninitialized(old_space, Mint::InstanceSize()));
        Deserializer::InitializeHeader(mint, kMintCid, Mint::InstanceSize(),
                                       is_canonical);
        mint->ptr()->value_ = value;
        d->AssignRef(mint);
      }
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {}

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      const Class& mint_cls = Class::Handle(
          d->zone(), Isolate::Current()->object_store()->mint_class());
      mint_cls.set_constants(Object::null_array());
      Object& number = Object::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        number = refs.At(i);
        if (number.IsMint()) {
          ASSERT(number.IsCanonical());
          mint_cls.InsertCanonicalMint(d->zone(), Mint::Cast(number));
        }
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class DoubleSerializationCluster : public SerializationCluster {
 public:
  DoubleSerializationCluster() : SerializationCluster("double") {}
  ~DoubleSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    DoublePtr dbl = Double::RawCast(object);
    objects_.Add(dbl);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kDoubleCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      DoublePtr dbl = objects_[i];
      s->AssignRef(dbl);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      DoublePtr dbl = objects_[i];
      AutoTraceObject(dbl);
      s->Write<double>(dbl->ptr()->value_);
    }
  }

 private:
  GrowableArray<DoublePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class DoubleDeserializationCluster : public DeserializationCluster {
 public:
  DoubleDeserializationCluster() : DeserializationCluster("double") {}
  ~DoubleDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, Double::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      DoublePtr dbl = static_cast<DoublePtr>(d->Ref(id));
      Deserializer::InitializeHeader(dbl, kDoubleCid, Double::InstanceSize(),
                                     is_canonical);
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

  void Trace(Serializer* s, ObjectPtr object) {
    GrowableObjectArrayPtr array = GrowableObjectArray::RawCast(object);
    objects_.Add(array);
    PushFromTo(array);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kGrowableObjectArrayCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      GrowableObjectArrayPtr array = objects_[i];
      s->AssignRef(array);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      GrowableObjectArrayPtr array = objects_[i];
      AutoTraceObject(array);
      WriteFromTo(array);
    }
  }

 private:
  GrowableArray<GrowableObjectArrayPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class GrowableObjectArrayDeserializationCluster
    : public DeserializationCluster {
 public:
  GrowableObjectArrayDeserializationCluster()
      : DeserializationCluster("GrowableObjectArray") {}
  ~GrowableObjectArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space,
                                         GrowableObjectArray::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      GrowableObjectArrayPtr list =
          static_cast<GrowableObjectArrayPtr>(d->Ref(id));
      Deserializer::InitializeHeader(list, kGrowableObjectArrayCid,
                                     GrowableObjectArray::InstanceSize(),
                                     is_canonical);
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

  void Trace(Serializer* s, ObjectPtr object) {
    TypedDataPtr data = TypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataPtr data = objects_[i];
      s->AssignRef(data);
      AutoTraceObject(data);
      const intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataPtr data = objects_[i];
      AutoTraceObject(data);
      const intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data());
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  const intptr_t cid_;
  GrowableArray<TypedDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit TypedDataDeserializationCluster(intptr_t cid)
      : DeserializationCluster("TypedData"), cid_(cid) {}
  ~TypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(
          old_space, TypedData::InstanceSize(length * element_size)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypedDataPtr data = static_cast<TypedDataPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      const intptr_t length_in_bytes = length * element_size;
      Deserializer::InitializeHeader(
          data, cid_, TypedData::InstanceSize(length_in_bytes), is_canonical);
      data->ptr()->length_ = Smi::New(length);
      data->ptr()->RecomputeDataField();
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data());
      d->ReadBytes(cdata, length_in_bytes);
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypedDataViewSerializationCluster : public SerializationCluster {
 public:
  explicit TypedDataViewSerializationCluster(intptr_t cid)
      : SerializationCluster("TypedDataView"), cid_(cid) {}
  ~TypedDataViewSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypedDataViewPtr view = TypedDataView::RawCast(object);
    objects_.Add(view);

    PushFromTo(view);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteCid(cid_);
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataViewPtr view = objects_[i];
      s->AssignRef(view);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypedDataViewPtr view = objects_[i];
      AutoTraceObject(view);
      WriteFromTo(view);
    }
  }

 private:
  const intptr_t cid_;
  GrowableArray<TypedDataViewPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypedDataViewDeserializationCluster : public DeserializationCluster {
 public:
  explicit TypedDataViewDeserializationCluster(intptr_t cid)
      : DeserializationCluster("TypedDataView"), cid_(cid) {}
  ~TypedDataViewDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, TypedDataView::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TypedDataViewPtr view = static_cast<TypedDataViewPtr>(d->Ref(id));
      Deserializer::InitializeHeader(view, cid_, TypedDataView::InstanceSize(),
                                     is_canonical);
      ReadFromTo(view);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    auto& view = TypedDataView::Handle(d->zone());
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      view ^= refs.At(id);
      view.RecomputeDataField();
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

  void Trace(Serializer* s, ObjectPtr object) {
    ExternalTypedDataPtr data = ExternalTypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ExternalTypedDataPtr data = objects_[i];
      s->AssignRef(data);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      ExternalTypedDataPtr data = objects_[i];
      AutoTraceObject(data);
      const intptr_t length = Smi::Value(data->ptr()->length_);
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->ptr()->data_);
      s->Align(ExternalTypedData::kDataSerializationAlignment);
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  const intptr_t cid_;
  GrowableArray<ExternalTypedDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExternalTypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit ExternalTypedDataDeserializationCluster(intptr_t cid)
      : DeserializationCluster("ExternalTypedData"), cid_(cid) {}
  ~ExternalTypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, ExternalTypedData::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid_);

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ExternalTypedDataPtr data = static_cast<ExternalTypedDataPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(data, cid_,
                                     ExternalTypedData::InstanceSize());
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

  void Trace(Serializer* s, ObjectPtr object) {
    StackTracePtr trace = StackTrace::RawCast(object);
    objects_.Add(trace);
    PushFromTo(trace);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kStackTraceCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      StackTracePtr trace = objects_[i];
      s->AssignRef(trace);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      StackTracePtr trace = objects_[i];
      AutoTraceObject(trace);
      WriteFromTo(trace);
    }
  }

 private:
  GrowableArray<StackTracePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class StackTraceDeserializationCluster : public DeserializationCluster {
 public:
  StackTraceDeserializationCluster() : DeserializationCluster("StackTrace") {}
  ~StackTraceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, StackTrace::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      StackTracePtr trace = static_cast<StackTracePtr>(d->Ref(id));
      Deserializer::InitializeHeader(trace, kStackTraceCid,
                                     StackTrace::InstanceSize());
      ReadFromTo(trace);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RegExpSerializationCluster : public SerializationCluster {
 public:
  RegExpSerializationCluster() : SerializationCluster("RegExp") {}
  ~RegExpSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    RegExpPtr regexp = RegExp::RawCast(object);
    objects_.Add(regexp);
    PushFromTo(regexp);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kRegExpCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      RegExpPtr regexp = objects_[i];
      s->AssignRef(regexp);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      RegExpPtr regexp = objects_[i];
      AutoTraceObject(regexp);
      WriteFromTo(regexp);
      s->Write<int32_t>(regexp->ptr()->num_one_byte_registers_);
      s->Write<int32_t>(regexp->ptr()->num_two_byte_registers_);
      s->Write<int8_t>(regexp->ptr()->type_flags_);
    }
  }

 private:
  GrowableArray<RegExpPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RegExpDeserializationCluster : public DeserializationCluster {
 public:
  RegExpDeserializationCluster() : DeserializationCluster("RegExp") {}
  ~RegExpDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(AllocateUninitialized(old_space, RegExp::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      RegExpPtr regexp = static_cast<RegExpPtr>(d->Ref(id));
      Deserializer::InitializeHeader(regexp, kRegExpCid,
                                     RegExp::InstanceSize());
      ReadFromTo(regexp);
      regexp->ptr()->num_one_byte_registers_ = d->Read<int32_t>();
      regexp->ptr()->num_two_byte_registers_ = d->Read<int32_t>();
      regexp->ptr()->type_flags_ = d->Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class WeakPropertySerializationCluster : public SerializationCluster {
 public:
  WeakPropertySerializationCluster() : SerializationCluster("WeakProperty") {}
  ~WeakPropertySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    WeakPropertyPtr property = WeakProperty::RawCast(object);
    objects_.Add(property);
    PushFromTo(property);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kWeakPropertyCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      WeakPropertyPtr property = objects_[i];
      s->AssignRef(property);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WeakPropertyPtr property = objects_[i];
      AutoTraceObject(property);
      WriteFromTo(property);
    }
  }

 private:
  GrowableArray<WeakPropertyPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class WeakPropertyDeserializationCluster : public DeserializationCluster {
 public:
  WeakPropertyDeserializationCluster()
      : DeserializationCluster("WeakProperty") {}
  ~WeakPropertyDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, WeakProperty::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      WeakPropertyPtr property = static_cast<WeakPropertyPtr>(d->Ref(id));
      Deserializer::InitializeHeader(property, kWeakPropertyCid,
                                     WeakProperty::InstanceSize());
      ReadFromTo(property);
      property->ptr()->next_ = WeakProperty::null();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LinkedHashMapSerializationCluster : public SerializationCluster {
 public:
  LinkedHashMapSerializationCluster() : SerializationCluster("LinkedHashMap") {}
  ~LinkedHashMapSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LinkedHashMapPtr map = LinkedHashMap::RawCast(object);
    objects_.Add(map);

    s->Push(map->ptr()->type_arguments_);

    intptr_t used_data = Smi::Value(map->ptr()->used_data_);
    ArrayPtr data_array = map->ptr()->data_;
    ObjectPtr* data_elements = data_array->ptr()->data();
    for (intptr_t i = 0; i < used_data; i += 2) {
      ObjectPtr key = data_elements[i];
      if (key != data_array) {
        ObjectPtr value = data_elements[i + 1];
        s->Push(key);
        s->Push(value);
      }
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kLinkedHashMapCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      LinkedHashMapPtr map = objects_[i];
      s->AssignRef(map);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      LinkedHashMapPtr map = objects_[i];
      AutoTraceObject(map);

      WriteField(map, type_arguments_);

      const intptr_t used_data = Smi::Value(map->ptr()->used_data_);
      ASSERT((used_data & 1) == 0);  // Keys + values, so must be even.
      const intptr_t deleted_keys = Smi::Value(map->ptr()->deleted_keys_);

      // Write out the number of (not deleted) key/value pairs that will follow.
      s->Write<int32_t>((used_data >> 1) - deleted_keys);

      ArrayPtr data_array = map->ptr()->data_;
      ObjectPtr* data_elements = data_array->ptr()->data();
      for (intptr_t i = 0; i < used_data; i += 2) {
        ObjectPtr key = data_elements[i];
        if (key != data_array) {
          ObjectPtr value = data_elements[i + 1];
          s->WriteElementRef(key, i);
          s->WriteElementRef(value, i + 1);
        }
      }
    }
  }

 private:
  GrowableArray<LinkedHashMapPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class LinkedHashMapDeserializationCluster : public DeserializationCluster {
 public:
  LinkedHashMapDeserializationCluster()
      : DeserializationCluster("LinkedHashMap") {}
  ~LinkedHashMapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(
          AllocateUninitialized(old_space, LinkedHashMap::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    PageSpace* old_space = d->heap()->old_space();

    for (intptr_t id = start_index_; id < stop_index_; id++) {
      LinkedHashMapPtr map = static_cast<LinkedHashMapPtr>(d->Ref(id));
      Deserializer::InitializeHeader(
          map, kLinkedHashMapCid, LinkedHashMap::InstanceSize(), is_canonical);

      map->ptr()->type_arguments_ = static_cast<TypeArgumentsPtr>(d->ReadRef());

      // TODO(rmacnak): Reserve ref ids and co-allocate in ReadAlloc.
      intptr_t pairs = d->Read<int32_t>();
      intptr_t used_data = pairs << 1;
      intptr_t data_size = Utils::Maximum(
          Utils::RoundUpToPowerOfTwo(used_data),
          static_cast<uintptr_t>(LinkedHashMap::kInitialIndexSize));

      ArrayPtr data = static_cast<ArrayPtr>(
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

  void Trace(Serializer* s, ObjectPtr object) {
    ArrayPtr array = Array::RawCast(object);
    objects_.Add(array);

    s->Push(array->ptr()->type_arguments_);
    const intptr_t length = Smi::Value(array->ptr()->length_);
    for (intptr_t i = 0; i < length; i++) {
      s->Push(array->ptr()->data()[i]);
    }
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(cid_);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ArrayPtr array = objects_[i];
      s->AssignRef(array);
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ArrayPtr array = objects_[i];
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->ptr()->length_);
      s->WriteUnsigned(length);
      WriteField(array, type_arguments_);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(array->ptr()->data()[j], j);
      }
    }
  }

 private:
  intptr_t cid_;
  GrowableArray<ArrayPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ArrayDeserializationCluster : public DeserializationCluster {
 public:
  explicit ArrayDeserializationCluster(intptr_t cid)
      : DeserializationCluster("Array"), cid_(cid) {}
  ~ArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(
          AllocateUninitialized(old_space, Array::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      ArrayPtr array = static_cast<ArrayPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(array, cid_, Array::InstanceSize(length),
                                     is_canonical);
      array->ptr()->type_arguments_ =
          static_cast<TypeArgumentsPtr>(d->ReadRef());
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

  void Trace(Serializer* s, ObjectPtr object) {
    OneByteStringPtr str = static_cast<OneByteStringPtr>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kOneByteStringCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      OneByteStringPtr str = objects_[i];
      s->AssignRef(str);
      AutoTraceObject(str);
      const intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      OneByteStringPtr str = objects_[i];
      AutoTraceObject(str);
      const intptr_t length = Smi::Value(str->ptr()->length_);
      ASSERT(length <= compiler::target::kSmiMax);
      s->WriteUnsigned(length);
      s->WriteBytes(str->ptr()->data(), length);
    }
  }

 private:
  GrowableArray<OneByteStringPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class OneByteStringDeserializationCluster : public DeserializationCluster {
 public:
  OneByteStringDeserializationCluster()
      : DeserializationCluster("OneByteString") {}
  ~OneByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         OneByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      OneByteStringPtr str = static_cast<OneByteStringPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(str, kOneByteStringCid,
                                     OneByteString::InstanceSize(length),
                                     is_canonical);
      str->ptr()->length_ = Smi::New(length);
      StringHasher hasher;
      for (intptr_t j = 0; j < length; j++) {
        uint8_t code_unit = d->Read<uint8_t>();
        str->ptr()->data()[j] = code_unit;
        hasher.Add(code_unit);
      }
      String::SetCachedHash(str, hasher.Finalize());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      CanonicalStringSet table(d->zone(),
                               d->isolate()->object_store()->symbol_table());
      String& str = String::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        str ^= refs.At(i);
        ASSERT(str.IsCanonical());
        bool present = table.Insert(str);
        ASSERT(!present);
      }
      d->isolate()->object_store()->set_symbol_table(table.Release());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TwoByteStringSerializationCluster : public SerializationCluster {
 public:
  TwoByteStringSerializationCluster() : SerializationCluster("TwoByteString") {}
  ~TwoByteStringSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TwoByteStringPtr str = static_cast<TwoByteStringPtr>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    s->WriteCid(kTwoByteStringCid);
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TwoByteStringPtr str = objects_[i];
      s->AssignRef(str);
      AutoTraceObject(str);
      const intptr_t length = Smi::Value(str->ptr()->length_);
      s->WriteUnsigned(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TwoByteStringPtr str = objects_[i];
      AutoTraceObject(str);
      const intptr_t length = Smi::Value(str->ptr()->length_);
      ASSERT(length <= (compiler::target::kSmiMax / 2));
      s->WriteUnsigned(length);
      s->WriteBytes(reinterpret_cast<uint8_t*>(str->ptr()->data()), length * 2);
    }
  }

 private:
  GrowableArray<TwoByteStringPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TwoByteStringDeserializationCluster : public DeserializationCluster {
 public:
  TwoByteStringDeserializationCluster()
      : DeserializationCluster("TwoByteString") {}
  ~TwoByteStringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d, bool is_canonical) {
    start_index_ = d->next_index();
    PageSpace* old_space = d->heap()->old_space();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(AllocateUninitialized(old_space,
                                         TwoByteString::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d, bool is_canonical) {
    for (intptr_t id = start_index_; id < stop_index_; id++) {
      TwoByteStringPtr str = static_cast<TwoByteStringPtr>(d->Ref(id));
      const intptr_t length = d->ReadUnsigned();
      Deserializer::InitializeHeader(str, kTwoByteStringCid,
                                     TwoByteString::InstanceSize(length),
                                     is_canonical);
      str->ptr()->length_ = Smi::New(length);
      StringHasher hasher;
      for (intptr_t j = 0; j < length; j++) {
        uint16_t code_unit = d->Read<uint8_t>();
        code_unit = code_unit | (d->Read<uint8_t>() << 8);
        str->ptr()->data()[j] = code_unit;
        hasher.Add(code_unit);
      }
      String::SetCachedHash(str, hasher.Finalize());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool is_canonical) {
    if (is_canonical && (d->isolate() != Dart::vm_isolate())) {
      CanonicalStringSet table(d->zone(),
                               d->isolate()->object_store()->symbol_table());
      String& str = String::Handle(d->zone());
      for (intptr_t i = start_index_; i < stop_index_; i++) {
        str ^= refs.At(i);
        ASSERT(str.IsCanonical());
        bool present = table.Insert(str);
        ASSERT(!present);
      }
      d->isolate()->object_store()->set_symbol_table(table.Release());
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FakeSerializationCluster : public SerializationCluster {
 public:
  FakeSerializationCluster(const char* name,
                           intptr_t num_objects,
                           intptr_t size)
      : SerializationCluster(name) {
    num_objects_ = num_objects;
    size_ = size;
  }
  ~FakeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) { UNREACHABLE(); }
  void WriteAlloc(Serializer* s) { UNREACHABLE(); }
  void WriteFill(Serializer* s) { UNREACHABLE(); }
};
#endif  // !DART_PRECOMPILED_RUNTIME

#if !defined(DART_PRECOMPILED_RUNTIME)
class VMSerializationRoots : public SerializationRoots {
 public:
  explicit VMSerializationRoots(const Array& symbols)
      : symbols_(symbols), zone_(Thread::Current()->zone()) {}

  void AddBaseObjects(Serializer* s) {
    // These objects are always allocated by Object::InitOnce, so they are not
    // written into the snapshot.

    s->AddBaseObject(Object::null(), "Null", "null");
    s->AddBaseObject(Object::sentinel().raw(), "Null", "sentinel");
    s->AddBaseObject(Object::transition_sentinel().raw(), "Null",
                     "transition_sentinel");
    s->AddBaseObject(Object::empty_array().raw(), "Array", "<empty_array>");
    s->AddBaseObject(Object::zero_array().raw(), "Array", "<zero_array>");
    s->AddBaseObject(Object::dynamic_type().raw(), "Type", "<dynamic type>");
    s->AddBaseObject(Object::void_type().raw(), "Type", "<void type>");
    s->AddBaseObject(Object::empty_type_arguments().raw(), "TypeArguments",
                     "[]");
    s->AddBaseObject(Bool::True().raw(), "bool", "true");
    s->AddBaseObject(Bool::False().raw(), "bool", "false");
    ASSERT(Object::extractor_parameter_types().raw() != Object::null());
    s->AddBaseObject(Object::extractor_parameter_types().raw(), "Array",
                     "<extractor parameter types>");
    ASSERT(Object::extractor_parameter_names().raw() != Object::null());
    s->AddBaseObject(Object::extractor_parameter_names().raw(), "Array",
                     "<extractor parameter names>");
    s->AddBaseObject(Object::empty_context_scope().raw(), "ContextScope",
                     "<empty>");
    s->AddBaseObject(Object::empty_object_pool().raw(), "ObjectPool",
                     "<empty>");
    s->AddBaseObject(Object::empty_compressed_stackmaps().raw(),
                     "CompressedStackMaps", "<empty>");
    s->AddBaseObject(Object::empty_descriptors().raw(), "PcDescriptors",
                     "<empty>");
    s->AddBaseObject(Object::empty_var_descriptors().raw(),
                     "LocalVarDescriptors", "<empty>");
    s->AddBaseObject(Object::empty_exception_handlers().raw(),
                     "ExceptionHandlers", "<empty>");

    for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
      s->AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i],
                       "ArgumentsDescriptor", "<cached arguments descriptor>");
    }
    for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
      s->AddBaseObject(ICData::cached_icdata_arrays_[i], "Array",
                       "<empty icdata entries>");
    }
    s->AddBaseObject(SubtypeTestCache::cached_array_, "Array",
                     "<empty subtype entries>");

    ClassTable* table = s->isolate()->class_table();
    for (intptr_t cid = kClassCid; cid < kInstanceCid; cid++) {
      // Error, CallSiteData has no class object.
      if (cid != kErrorCid && cid != kCallSiteDataCid) {
        ASSERT(table->HasValidClassAt(cid));
        s->AddBaseObject(table->At(cid), "Class");
      }
    }
    s->AddBaseObject(table->At(kDynamicCid), "Class");
    s->AddBaseObject(table->At(kVoidCid), "Class");

    if (!Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->AddBaseObject(StubCode::EntryAt(i).raw(), "Code", "<stub code>");
      }
    }
  }

  void PushRoots(Serializer* s) {
    s->Push(symbols_.raw());
    if (Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->Push(StubCode::EntryAt(i).raw());
      }
    }
  }

  void WriteRoots(Serializer* s) {
    s->WriteRootRef(symbols_.raw(), "symbol-table");
    if (Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->WriteRootRef(StubCode::EntryAt(i).raw(),
                        zone_->PrintToString("Stub:%s", StubCode::NameAt(i)));
      }
    }
  }

 private:
  const Array& symbols_;
  Zone* zone_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class VMDeserializationRoots : public DeserializationRoots {
 public:
  VMDeserializationRoots() : symbol_table_(Array::Handle()) {}

  void AddBaseObjects(Deserializer* d) {
    // These objects are always allocated by Object::InitOnce, so they are not
    // written into the snapshot.

    d->AddBaseObject(Object::null());
    d->AddBaseObject(Object::sentinel().raw());
    d->AddBaseObject(Object::transition_sentinel().raw());
    d->AddBaseObject(Object::empty_array().raw());
    d->AddBaseObject(Object::zero_array().raw());
    d->AddBaseObject(Object::dynamic_type().raw());
    d->AddBaseObject(Object::void_type().raw());
    d->AddBaseObject(Object::empty_type_arguments().raw());
    d->AddBaseObject(Bool::True().raw());
    d->AddBaseObject(Bool::False().raw());
    ASSERT(Object::extractor_parameter_types().raw() != Object::null());
    d->AddBaseObject(Object::extractor_parameter_types().raw());
    ASSERT(Object::extractor_parameter_names().raw() != Object::null());
    d->AddBaseObject(Object::extractor_parameter_names().raw());
    d->AddBaseObject(Object::empty_context_scope().raw());
    d->AddBaseObject(Object::empty_object_pool().raw());
    d->AddBaseObject(Object::empty_compressed_stackmaps().raw());
    d->AddBaseObject(Object::empty_descriptors().raw());
    d->AddBaseObject(Object::empty_var_descriptors().raw());
    d->AddBaseObject(Object::empty_exception_handlers().raw());

    for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
      d->AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i]);
    }
    for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
      d->AddBaseObject(ICData::cached_icdata_arrays_[i]);
    }
    d->AddBaseObject(SubtypeTestCache::cached_array_);

    ClassTable* table = d->isolate()->class_table();
    for (intptr_t cid = kClassCid; cid <= kUnwindErrorCid; cid++) {
      // Error, CallSiteData has no class object.
      if (cid != kErrorCid && cid != kCallSiteDataCid) {
        ASSERT(table->HasValidClassAt(cid));
        d->AddBaseObject(table->At(cid));
      }
    }
    d->AddBaseObject(table->At(kDynamicCid));
    d->AddBaseObject(table->At(kVoidCid));

    if (!Snapshot::IncludesCode(d->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        d->AddBaseObject(StubCode::EntryAt(i).raw());
      }
    }
  }

  void ReadRoots(Deserializer* d) {
    symbol_table_ ^= d->ReadRef();
    d->isolate()->object_store()->set_symbol_table(symbol_table_);
    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        Code* code = Code::ReadOnlyHandle();
        *code ^= d->ReadRef();
        StubCode::EntryAtPut(i, code);
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    // Move remaining bump allocation space to the freelist so it used by C++
    // allocations (e.g., FinalizeVMIsolate) before allocating new pages.
    d->heap()->old_space()->AbandonBumpAllocation();

    Symbols::InitFromSnapshot(d->isolate());

    Object::set_vm_isolate_snapshot_object_table(refs);
  }

 private:
  Array& symbol_table_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
static const char* kObjectStoreFieldNames[] = {
#define DECLARE_OBJECT_STORE_FIELD(Type, Name) #Name,
    OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
};

class ProgramSerializationRoots : public SerializationRoots {
 public:
  ProgramSerializationRoots(ZoneGrowableArray<Object*>* base_objects,
                            ObjectStore* object_store)
      : base_objects_(base_objects),
        object_store_(object_store),
        saved_symbol_table_(Array::Handle()),
        saved_canonical_types_(Array::Handle()),
        saved_canonical_type_parameters_(Array::Handle()),
        saved_canonical_type_arguments_(Array::Handle()),
        dispatch_table_entries_(Array::Handle()) {
    saved_symbol_table_ = object_store->symbol_table();
    object_store->set_symbol_table(
        Array::Handle(HashTables::New<CanonicalStringSet>(4)));

    saved_canonical_types_ = object_store->canonical_types();
    object_store->set_canonical_types(
        Array::Handle(HashTables::New<CanonicalTypeSet>(4)));

    saved_canonical_type_parameters_ =
        object_store->canonical_type_parameters();
    object_store->set_canonical_type_parameters(
        Array::Handle(HashTables::New<CanonicalTypeParameterSet>(4)));

    saved_canonical_type_arguments_ = object_store->canonical_type_arguments();
    object_store->set_canonical_type_arguments(
        Array::Handle(HashTables::New<CanonicalTypeArgumentsSet>(4)));
  }
  ~ProgramSerializationRoots() {
    object_store_->set_symbol_table(saved_symbol_table_);
    object_store_->set_canonical_types(saved_canonical_types_);
    object_store_->set_canonical_type_parameters(
        saved_canonical_type_parameters_);
    object_store_->set_canonical_type_arguments(
        saved_canonical_type_arguments_);
  }

  void AddBaseObjects(Serializer* s) {
    if (base_objects_ == nullptr) {
      // Not writing a new vm isolate: use the one this VM was loaded from.
      const Array& base_objects = Object::vm_isolate_snapshot_object_table();
      for (intptr_t i = kFirstReference; i < base_objects.Length(); i++) {
        s->AddBaseObject(base_objects.At(i));
      }
    } else {
      // Base objects carried over from WriteVMSnapshot.
      for (intptr_t i = 0; i < base_objects_->length(); i++) {
        s->AddBaseObject((*base_objects_)[i]->raw());
      }
    }
  }

  void PushRoots(Serializer* s) {
    ObjectPtr* from = object_store_->from();
    ObjectPtr* to = object_store_->to_snapshot(s->kind());
    for (ObjectPtr* p = from; p <= to; p++) {
      s->Push(*p);
    }

    dispatch_table_entries_ = object_store_->dispatch_table_code_entries();
    // We should only have a dispatch table in precompiled mode.
    ASSERT(dispatch_table_entries_.IsNull() || s->kind() == Snapshot::kFullAOT);

#if defined(DART_PRECOMPILER)
    // We treat the dispatch table as a root object and trace the Code objects
    // it references. Otherwise, a non-empty entry could be invalid on
    // deserialization if the corresponding Code object was not reachable from
    // the existing snapshot roots.
    if (!dispatch_table_entries_.IsNull()) {
      for (intptr_t i = 0; i < dispatch_table_entries_.Length(); i++) {
        s->Push(dispatch_table_entries_.At(i));
      }
    }
#endif
  }

  void WriteRoots(Serializer* s) {
    ObjectPtr* from = object_store_->from();
    ObjectPtr* to = object_store_->to_snapshot(s->kind());
    for (ObjectPtr* p = from; p <= to; p++) {
      s->WriteRootRef(*p, kObjectStoreFieldNames[p - from]);
    }

    // The dispatch table is serialized only for precompiled snapshots.
    s->WriteDispatchTable(dispatch_table_entries_);
  }

 private:
  ZoneGrowableArray<Object*>* base_objects_;
  ObjectStore* object_store_;
  Array& saved_symbol_table_;
  Array& saved_canonical_types_;
  Array& saved_canonical_type_parameters_;
  Array& saved_canonical_type_arguments_;
  Array& dispatch_table_entries_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ProgramDeserializationRoots : public DeserializationRoots {
 public:
  explicit ProgramDeserializationRoots(ObjectStore* object_store)
      : object_store_(object_store) {}

  void AddBaseObjects(Deserializer* d) {
    // N.B.: Skipping index 0 because ref 0 is illegal.
    const Array& base_objects = Object::vm_isolate_snapshot_object_table();
    for (intptr_t i = kFirstReference; i < base_objects.Length(); i++) {
      d->AddBaseObject(base_objects.At(i));
    }
  }

  void ReadRoots(Deserializer* d) {
    // Read roots.
    ObjectPtr* from = object_store_->from();
    ObjectPtr* to = object_store_->to_snapshot(d->kind());
    for (ObjectPtr* p = from; p <= to; p++) {
      *p = d->ReadRef();
    }

    // Deserialize dispatch table (when applicable)
    d->ReadDispatchTable();
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    Isolate* isolate = d->thread()->isolate();
    isolate->class_table()->CopySizesFromClassObjects();
    d->heap()->old_space()->EvaluateAfterLoading();

    const Array& units =
        Array::Handle(isolate->object_store()->loading_units());
    if (!units.IsNull()) {
      LoadingUnit& unit = LoadingUnit::Handle();
      unit ^= units.At(LoadingUnit::kRootId);
      unit.set_base_objects(refs);
    }
    isolate->isolate_object_store()->PreallocateObjects();

    // Setup native resolver for bootstrap impl.
    Bootstrap::SetupNativeResolver();
  }

 private:
  ObjectStore* object_store_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnitSerializationRoots : public SerializationRoots {
 public:
  explicit UnitSerializationRoots(LoadingUnitSerializationData* unit)
      : unit_(unit) {}

  void AddBaseObjects(Serializer* s) {
    ZoneGrowableArray<Object*>* objects = unit_->parent()->objects();
    for (intptr_t i = 0; i < objects->length(); i++) {
      s->AddBaseObject(objects->At(i)->raw());
    }
  }

  void PushRoots(Serializer* s) {
    intptr_t num_deferred_objects = unit_->deferred_objects()->length();
    for (intptr_t i = 0; i < num_deferred_objects; i++) {
      const Object* deferred_object = (*unit_->deferred_objects())[i];
      ASSERT(deferred_object->IsCode());
      CodePtr code = static_cast<CodePtr>(deferred_object->raw());
      s->Push(code->ptr()->compressed_stackmaps_);
      s->Push(code->ptr()->code_source_map_);
    }
    {
      GrowableArray<CodePtr> raw_codes(num_deferred_objects);
      for (intptr_t i = 0; i < num_deferred_objects; i++) {
        raw_codes.Add((*unit_->deferred_objects())[i]->raw());
      }
      s->PrepareInstructions(&raw_codes);
    }
  }

  void WriteRoots(Serializer* s) {
#if defined(DART_PRECOMPILER)
    intptr_t start_index = 0;
    intptr_t num_deferred_objects = unit_->deferred_objects()->length();
    if (num_deferred_objects != 0) {
      start_index = s->RefId(unit_->deferred_objects()->At(0)->raw());
      ASSERT(start_index > 0);
    }
    s->WriteUnsigned(start_index);
    s->WriteUnsigned(num_deferred_objects);
    for (intptr_t i = 0; i < num_deferred_objects; i++) {
      const Object* deferred_object = (*unit_->deferred_objects())[i];
      ASSERT(deferred_object->IsCode());
      CodePtr code = static_cast<CodePtr>(deferred_object->raw());
      ASSERT(s->RefId(code) == (start_index + i));
      s->WriteInstructions(code->ptr()->instructions_,
                           code->ptr()->unchecked_offset_, code, false);
      s->WriteRootRef(code->ptr()->compressed_stackmaps_, "deferred-code");
      s->WriteRootRef(code->ptr()->code_source_map_, "deferred-code");
    }
#endif
  }

 private:
  LoadingUnitSerializationData* unit_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnitDeserializationRoots : public DeserializationRoots {
 public:
  explicit UnitDeserializationRoots(const LoadingUnit& unit) : unit_(unit) {}

  void AddBaseObjects(Deserializer* d) {
    const Array& base_objects =
        Array::Handle(LoadingUnit::Handle(unit_.parent()).base_objects());
    for (intptr_t i = kFirstReference; i < base_objects.Length(); i++) {
      d->AddBaseObject(base_objects.At(i));
    }
  }

  void ReadRoots(Deserializer* d) {
    deferred_start_index_ = d->ReadUnsigned();
    deferred_stop_index_ = deferred_start_index_ + d->ReadUnsigned();
    for (intptr_t id = deferred_start_index_; id < deferred_stop_index_; id++) {
      CodePtr code = static_cast<CodePtr>(d->Ref(id));
      d->ReadInstructions(code, false);
      if (code->ptr()->owner_->IsFunction()) {
        FunctionPtr func = static_cast<FunctionPtr>(code->ptr()->owner_);
        uword entry_point = code->ptr()->entry_point_;
        ASSERT(entry_point != 0);
        func->ptr()->entry_point_ = entry_point;
        uword unchecked_entry_point = code->ptr()->unchecked_entry_point_;
        ASSERT(unchecked_entry_point != 0);
        func->ptr()->unchecked_entry_point_ = unchecked_entry_point;
      }
      code->ptr()->compressed_stackmaps_ =
          static_cast<CompressedStackMapsPtr>(d->ReadRef());
      code->ptr()->code_source_map_ =
          static_cast<CodeSourceMapPtr>(d->ReadRef());
    }

    // Reinitialize the dispatch table by rereading the table's serialization
    // in the root snapshot.
    IsolateGroup* group = d->thread()->isolate()->group();
    if (group->dispatch_table_snapshot() != nullptr) {
      ReadStream stream(group->dispatch_table_snapshot(),
                        group->dispatch_table_snapshot_size());
      d->ReadDispatchTable(&stream);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    d->EndInstructions(refs, deferred_start_index_, deferred_stop_index_);
    unit_.set_base_objects(refs);
  }

 private:
  const LoadingUnit& unit_;
  intptr_t deferred_start_index_;
  intptr_t deferred_stop_index_;
};

#if defined(DEBUG)
static const int32_t kSectionMarker = 0xABAB;
#endif

Serializer::Serializer(Thread* thread,
                       Snapshot::Kind kind,
                       NonStreamingWriteStream* stream,
                       ImageWriter* image_writer,
                       bool vm,
                       V8SnapshotProfileWriter* profile_writer)
    : ThreadStackResource(thread),
      heap_(thread->isolate()->heap()),
      zone_(thread->zone()),
      kind_(kind),
      stream_(stream),
      image_writer_(image_writer),
      canonical_clusters_by_cid_(nullptr),
      clusters_by_cid_(nullptr),
      stack_(),
      num_cids_(0),
      num_tlc_cids_(0),
      num_base_objects_(0),
      num_written_objects_(0),
      next_ref_index_(kFirstReference),
      previous_text_offset_(0),
      initial_field_table_(thread->isolate_group()->initial_field_table()),
      vm_(vm),
      profile_writer_(profile_writer)
#if defined(SNAPSHOT_BACKTRACE)
      ,
      current_parent_(Object::null()),
      parent_pairs_()
#endif
#if defined(DART_PRECOMPILER)
      ,
      deduped_instructions_sources_(zone_)
#endif
{
  num_cids_ = thread->isolate()->class_table()->NumCids();
  num_tlc_cids_ = thread->isolate()->class_table()->NumTopLevelCids();
  canonical_clusters_by_cid_ = new SerializationCluster*[num_cids_];
  for (intptr_t i = 0; i < num_cids_; i++) {
    canonical_clusters_by_cid_[i] = nullptr;
  }
  clusters_by_cid_ = new SerializationCluster*[num_cids_];
  for (intptr_t i = 0; i < num_cids_; i++) {
    clusters_by_cid_[i] = nullptr;
  }
  if (profile_writer_ != nullptr) {
    offsets_table_ = new (zone_) OffsetsTable(zone_);
  }
}

Serializer::~Serializer() {
  delete[] canonical_clusters_by_cid_;
  delete[] clusters_by_cid_;
}

void Serializer::AddBaseObject(ObjectPtr base_object,
                               const char* type,
                               const char* name) {
  intptr_t ref = AssignRef(base_object);
  num_base_objects_++;

  if ((profile_writer_ != nullptr) && (type != nullptr)) {
    if (name == nullptr) {
      name = "<base object>";
    }
    profile_writer_->SetObjectTypeAndName(
        {V8SnapshotProfileWriter::kSnapshot, ref}, type, name);
    profile_writer_->AddRoot({V8SnapshotProfileWriter::kSnapshot, ref});
  }
}

intptr_t Serializer::AssignRef(ObjectPtr object) {
  ASSERT(IsAllocatedReference(next_ref_index_));

  // The object id weak table holds image offsets for Instructions instead
  // of ref indices.
  ASSERT(!object->IsHeapObject() || !object->IsInstructions());
  heap_->SetObjectId(object, next_ref_index_);
  ASSERT(heap_->GetObjectId(object) == next_ref_index_);

  objects_->Add(&Object::ZoneHandle(object));

  return next_ref_index_++;
}

intptr_t Serializer::AssignArtificialRef(ObjectPtr object) {
  ASSERT(object.IsHeapObject());
  const intptr_t ref = -(next_ref_index_++);
  ASSERT(IsArtificialReference(ref));
  heap_->SetObjectId(object, ref);
  ASSERT(heap_->GetObjectId(object) == ref);
  return ref;
}

void Serializer::FlushBytesWrittenToRoot() {
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    ASSERT(object_currently_writing_.id_ == 0);
    // All bytes between objects are attributed into root node.
    profile_writer_->AttributeBytesTo(
        V8SnapshotProfileWriter::ArtificialRootId(),
        stream_->Position() - object_currently_writing_.stream_start_);
    object_currently_writing_.stream_start_ = stream_->Position();
  }
#endif
}

void Serializer::TraceStartWritingObject(const char* type,
                                         ObjectPtr obj,
                                         StringPtr name) {
  if (profile_writer_ == nullptr) return;

  const char* name_str = nullptr;
  if (name != nullptr) {
    REUSABLE_STRING_HANDLESCOPE(thread());
    String& str = reused_string_handle.Handle();
    str = name;
    name_str = str.ToCString();
  }

  TraceStartWritingObject(type, obj, name_str);
}

void Serializer::TraceStartWritingObject(const char* type,
                                         ObjectPtr obj,
                                         const char* name) {
  if (profile_writer_ == nullptr) return;

  intptr_t id = heap_->GetObjectId(obj);
  intptr_t cid = obj->GetClassIdMayBeSmi();
  if (IsArtificialReference(id)) {
    id = -id;
  }
  ASSERT(IsAllocatedReference(id));

  FlushBytesWrittenToRoot();
  object_currently_writing_.object_ = obj;
  object_currently_writing_.id_ = id;
  object_currently_writing_.stream_start_ = stream_->Position();
  object_currently_writing_.cid_ = cid;
  profile_writer_->SetObjectTypeAndName(
      {V8SnapshotProfileWriter::kSnapshot, id}, type, name);
}

void Serializer::TraceEndWritingObject() {
  if (profile_writer_ != nullptr) {
    ASSERT(IsAllocatedReference(object_currently_writing_.id_));
    profile_writer_->AttributeBytesTo(
        {V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_},
        stream_->Position() - object_currently_writing_.stream_start_);
    object_currently_writing_ = ProfilingObject();
    object_currently_writing_.stream_start_ = stream_->Position();
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
bool Serializer::CreateArtificalNodeIfNeeded(ObjectPtr obj) {
  ASSERT(profile_writer() != nullptr);

  intptr_t id = heap_->GetObjectId(obj);
  if (IsAllocatedReference(id)) {
    return false;
  }
  if (IsArtificialReference(id)) {
    return true;
  }
  ASSERT_EQUAL(id, kUnreachableReference);
  id = AssignArtificialRef(obj);

  const char* type = nullptr;
  StringPtr name_string = nullptr;
  const char* name = nullptr;
  ObjectPtr owner = nullptr;
  const char* owner_ref_name = nullptr;
  switch (obj->GetClassId()) {
    case kFunctionCid: {
      FunctionPtr func = static_cast<FunctionPtr>(obj);
      type = "Function";
      name = FunctionSerializationCluster::MakeDisambiguatedFunctionName(this,
                                                                         func);
      owner_ref_name = "owner_";
      owner = func->ptr()->owner_;
      break;
    }
    case kClassCid: {
      ClassPtr cls = static_cast<ClassPtr>(obj);
      type = "Class";
      name_string = cls->ptr()->name_;
      owner_ref_name = "library_";
      owner = cls->ptr()->library_;
      break;
    }
    case kPatchClassCid: {
      PatchClassPtr patch_cls = static_cast<PatchClassPtr>(obj);
      type = "PatchClass";
      owner_ref_name = "patched_class_";
      owner = patch_cls->ptr()->patched_class_;
      break;
    }
    case kLibraryCid: {
      LibraryPtr lib = static_cast<LibraryPtr>(obj);
      type = "Library";
      name_string = lib->ptr()->url_;
      break;
    }
    default:
      UNREACHABLE();
  }

  if (name_string != nullptr) {
    REUSABLE_STRING_HANDLESCOPE(thread());
    String& str = reused_string_handle.Handle();
    str = name_string;
    name = str.ToCString();
  }

  // CreateArtificalNodeIfNeeded might call TraceStartWritingObject
  // and these calls don't nest, so we need to call this outside
  // of the tracing scope created below.
  if (owner != nullptr) {
    CreateArtificalNodeIfNeeded(owner);
  }

  TraceStartWritingObject(type, obj, name);
  if (owner != nullptr) {
    AttributePropertyRef(owner, owner_ref_name,
                         /*permit_artificial_ref=*/true);
  }
  TraceEndWritingObject();
  return true;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

const char* Serializer::ReadOnlyObjectType(intptr_t cid) {
  switch (cid) {
    case kPcDescriptorsCid:
      return "PcDescriptors";
    case kCodeSourceMapCid:
      return "CodeSourceMap";
    case kCompressedStackMapsCid:
      return "CompressedStackMaps";
    case kOneByteStringCid:
      return current_loading_unit_id_ <= LoadingUnit::kRootId
                 ? "OneByteStringCid"
                 : nullptr;
    case kTwoByteStringCid:
      return current_loading_unit_id_ <= LoadingUnit::kRootId
                 ? "TwoByteStringCid"
                 : nullptr;
    default:
      return nullptr;
  }
}

SerializationCluster* Serializer::NewClusterForClass(intptr_t cid) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return NULL;
#else
  Zone* Z = zone_;
  if (cid >= kNumPredefinedCids || cid == kInstanceCid) {
    Push(isolate()->class_table()->At(cid));
    return new (Z) InstanceSerializationCluster(cid);
  }
  if (IsTypedDataViewClassId(cid)) {
    return new (Z) TypedDataViewSerializationCluster(cid);
  }
  if (IsExternalTypedDataClassId(cid)) {
    return new (Z) ExternalTypedDataSerializationCluster(cid);
  }
  if (IsTypedDataClassId(cid)) {
    return new (Z) TypedDataSerializationCluster(cid);
  }

  if (Snapshot::IncludesCode(kind_)) {
    if (auto const type = ReadOnlyObjectType(cid)) {
      return new (Z) RODataSerializationCluster(Z, type, cid);
    }
  }

  switch (cid) {
    case kClassCid:
      return new (Z) ClassSerializationCluster(num_cids_ + num_tlc_cids_);
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
    case kFfiTrampolineDataCid:
      return new (Z) FfiTrampolineDataSerializationCluster();
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
      return new (Z) CodeSerializationCluster(heap_);
    case kObjectPoolCid:
      return new (Z) ObjectPoolSerializationCluster();
    case kPcDescriptorsCid:
      return new (Z) PcDescriptorsSerializationCluster();
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
    case kLoadingUnitCid:
      return new (Z) LoadingUnitSerializationCluster();
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
    case kOneByteStringCid:
      return new (Z) OneByteStringSerializationCluster();
    case kTwoByteStringCid:
      return new (Z) TwoByteStringSerializationCluster();
    case kWeakSerializationReferenceCid:
#if defined(DART_PRECOMPILER)
      ASSERT(kind_ == Snapshot::kFullAOT);
      return new (Z)
          WeakSerializationReferenceSerializationCluster(zone_, heap_);
#endif
    default:
      break;
  }

  // The caller will check for NULL and provide an error with more context than
  // is available here.
  return NULL;
#endif  // !DART_PRECOMPILED_RUNTIME
}

bool Serializer::InCurrentLoadingUnit(ObjectPtr obj, bool record) {
  if (loading_units_ == nullptr) return true;

  intptr_t unit_id = heap_->GetLoadingUnit(obj);
  if (unit_id == WeakTable::kNoValue) {
    // Not found in early assignment. Conservatively choose the root.
    // TODO(41974): Are these always type testing stubs?
    unit_id = LoadingUnit::kRootId;
  }
  if (unit_id != current_loading_unit_id_) {
    if (record) {
      (*loading_units_)[unit_id]->AddDeferredObject(static_cast<CodePtr>(obj));
    }
    return false;
  }
  return true;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void Serializer::PrepareInstructions(GrowableArray<CodePtr>* code_objects) {
#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
  if ((kind() == Snapshot::kFullAOT) && FLAG_use_bare_instructions) {
    GrowableArray<ImageWriterCommand> writer_commands;
    RelocateCodeObjects(vm_, code_objects, &writer_commands);
    image_writer_->PrepareForSerialization(&writer_commands);
  }
#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
}

void Serializer::WriteInstructions(InstructionsPtr instr,
                                   uint32_t unchecked_offset,
                                   CodePtr code,
                                   bool deferred) {
  ASSERT(code != Code::null());

  ASSERT(InCurrentLoadingUnit(code) != deferred);
  if (deferred) {
    return;
  }

  const intptr_t offset = image_writer_->GetTextOffsetFor(instr, code);
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    ASSERT(IsAllocatedReference(object_currently_writing_.id_));
    const auto offset_space = vm_ ? V8SnapshotProfileWriter::kVmText
                                  : V8SnapshotProfileWriter::kIsolateText;
    const V8SnapshotProfileWriter::ObjectId to_object(offset_space, offset);
    const V8SnapshotProfileWriter::ObjectId from_object(
        V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_);
    profile_writer_->AttributeReferenceTo(
        from_object, {to_object, V8SnapshotProfileWriter::Reference::kProperty,
                      profile_writer_->EnsureString("<instructions>")});
  }

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    ASSERT(offset != 0);
    RELEASE_ASSERT(offset >= previous_text_offset_);
    const uint32_t delta = offset - previous_text_offset_;
    WriteUnsigned(delta);
    const uint32_t payload_info =
        (unchecked_offset << 1) | (Code::HasMonomorphicEntry(code) ? 0x1 : 0x0);
    WriteUnsigned(payload_info);
    previous_text_offset_ = offset;
    return;
  }
#endif
  Write<uint32_t>(offset);
  WriteUnsigned(unchecked_offset);
}

void Serializer::TraceDataOffset(uint32_t offset) {
  if (profile_writer_ != nullptr) {
    // ROData cannot be roots.
    ASSERT(IsAllocatedReference(object_currently_writing_.id_));
    auto offset_space = vm_ ? V8SnapshotProfileWriter::kVmData
                            : V8SnapshotProfileWriter::kIsolateData;
    V8SnapshotProfileWriter::ObjectId from_object = {
        V8SnapshotProfileWriter::kSnapshot, object_currently_writing_.id_};
    V8SnapshotProfileWriter::ObjectId to_object = {offset_space, offset};
    // TODO(sjindel): Give this edge a more appropriate type than element
    // (internal, maybe?).
    profile_writer_->AttributeReferenceTo(
        from_object,
        {to_object, V8SnapshotProfileWriter::Reference::kElement, 0});
  }
}

uint32_t Serializer::GetDataOffset(ObjectPtr object) const {
  return image_writer_->GetDataOffsetFor(object);
}

intptr_t Serializer::GetDataSize() const {
  if (image_writer_ == NULL) {
    return 0;
  }
  return image_writer_->data_size();
}
#endif

void Serializer::Push(ObjectPtr object) {
  if (object->IsHeapObject() && object->IsCode() &&
      !Snapshot::IncludesCode(kind_)) {
    return;  // Do not trace, will write null.
  }

  intptr_t id = heap_->GetObjectId(object);
  if (id == kUnreachableReference) {
    // When discovering the transitive closure of objects reachable from the
    // roots we do not trace references, e.g. inside [RawCode], to
    // [RawInstructions], since [RawInstructions] doesn't contain any references
    // and the serialization code uses an [ImageWriter] for those.
    if (object->IsHeapObject() && object->IsInstructions()) {
      UnexpectedObject(object,
                       "Instructions should only be reachable from Code");
    }

    heap_->SetObjectId(object, kUnallocatedReference);
    ASSERT(IsReachableReference(heap_->GetObjectId(object)));
    stack_.Add(object);
    num_written_objects_++;
#if defined(SNAPSHOT_BACKTRACE)
    parent_pairs_.Add(&Object::Handle(zone_, object));
    parent_pairs_.Add(&Object::Handle(zone_, current_parent_));
#endif
  }
}

void Serializer::Trace(ObjectPtr object) {
  intptr_t cid;
  bool is_canonical;
  if (!object->IsHeapObject()) {
    // Smis are merged into the Mint cluster because Smis for the writer might
    // become Mints for the reader and vice versa.
    cid = kMintCid;
    is_canonical = true;
  } else {
    cid = object->GetClassId();
    is_canonical = object->ptr()->IsCanonical();
  }

  SerializationCluster** cluster_ref =
      is_canonical ? &canonical_clusters_by_cid_[cid] : &clusters_by_cid_[cid];
  if (*cluster_ref == nullptr) {
    *cluster_ref = NewClusterForClass(cid);
    if (*cluster_ref == nullptr) {
      UnexpectedObject(object, "No serialization cluster defined");
    }
  }
  SerializationCluster* cluster = *cluster_ref;
  ASSERT(cluster != nullptr);

#if defined(SNAPSHOT_BACKTRACE)
  current_parent_ = object;
#endif

  cluster->Trace(this, object);

#if defined(SNAPSHOT_BACKTRACE)
  current_parent_ = Object::null();
#endif
}

void Serializer::UnexpectedObject(ObjectPtr raw_object, const char* message) {
  // Exit the no safepoint scope so we can allocate while printing.
  while (thread()->no_safepoint_scope_depth() > 0) {
    thread()->DecrementNoSafepointScopeDepth();
  }
  Object& object = Object::Handle(raw_object);
  OS::PrintErr("Unexpected object (%s, %s): 0x%" Px " %s\n", message,
               Snapshot::KindToCString(kind_), static_cast<uword>(object.raw()),
               object.ToCString());
#if defined(SNAPSHOT_BACKTRACE)
  while (!object.IsNull()) {
    object = ParentOf(object);
    OS::PrintErr("referenced by 0x%" Px " %s\n",
                 static_cast<uword>(object.raw()), object.ToCString());
  }
#endif
  OS::Abort();
}

#if defined(SNAPSHOT_BACKTRACE)
ObjectPtr Serializer::ParentOf(const Object& object) {
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

ZoneGrowableArray<Object*>* Serializer::Serialize(SerializationRoots* roots) {
  roots->AddBaseObjects(this);

  NoSafepointScope no_safepoint;

  roots->PushRoots(this);

  while (stack_.length() > 0) {
    Trace(stack_.RemoveLast());
  }

  GrowableArray<SerializationCluster*> canonical_clusters;
  for (intptr_t cid = 0; cid < num_cids_; cid++) {
    if (canonical_clusters_by_cid_[cid] != nullptr) {
      canonical_clusters.Add(canonical_clusters_by_cid_[cid]);
    }
  }
  GrowableArray<SerializationCluster*> clusters;
  for (intptr_t cid = 0; cid < num_cids_; cid++) {
    if (clusters_by_cid_[cid] != nullptr) {
      clusters.Add(clusters_by_cid_[cid]);
    }
  }

#if defined(DART_PRECOMPILER)
  // Before we finalize the count of written objects, pick canonical versions
  // of WSR objects that will be serialized and then remove any non-serialized
  // or non-canonical WSR objects from that count.
  if (auto const cluster =
          reinterpret_cast<WeakSerializationReferenceSerializationCluster*>(
              clusters_by_cid_[kWeakSerializationReferenceCid])) {
    cluster->CanonicalizeReferences();
    auto const dropped_count = cluster->DroppedCount();
    ASSERT(dropped_count == 0 || kind() == Snapshot::kFullAOT);
    num_written_objects_ -= dropped_count;
  }
#endif

  intptr_t num_objects = num_base_objects_ + num_written_objects_;
#if defined(ARCH_IS_64_BIT)
  if (!Utils::IsInt(32, num_objects)) {
    FATAL("Ref overflow");
  }
#endif

  WriteUnsigned(num_base_objects_);
  WriteUnsigned(num_objects);
  WriteUnsigned(canonical_clusters.length());
  WriteUnsigned(clusters.length());
  // TODO(dartbug.com/36097): Not every snapshot carries the field table.
  if (current_loading_unit_id_ <= LoadingUnit::kRootId) {
    WriteUnsigned(initial_field_table_->NumFieldIds());
  } else {
    WriteUnsigned(0);
  }

  for (SerializationCluster* cluster : canonical_clusters) {
    cluster->WriteAndMeasureAlloc(this);
#if defined(DEBUG)
    Write<int32_t>(next_ref_index_);
#endif
  }
  for (SerializationCluster* cluster : clusters) {
    cluster->WriteAndMeasureAlloc(this);
#if defined(DEBUG)
    Write<int32_t>(next_ref_index_);
#endif
  }

  // We should have assigned a ref to every object we pushed.
  ASSERT((next_ref_index_ - 1) == num_objects);
  // And recorded them all in [objects_].
  ASSERT(objects_->length() == num_objects);

#if defined(DART_PRECOMPILER)
  // When writing snapshot profile, we want to retain some of the program
  // structure information (e.g. information about libraries, classes and
  // functions - even if it was dropped when writing snapshot itself).
  if (FLAG_write_v8_snapshot_profile_to != nullptr) {
    static_cast<CodeSerializationCluster*>(clusters_by_cid_[kCodeCid])
        ->WriteDroppedOwnersIntoProfile(this);
  }
#endif

  for (SerializationCluster* cluster : canonical_clusters) {
    cluster->WriteAndMeasureFill(this);
#if defined(DEBUG)
    Write<int32_t>(kSectionMarker);
#endif
  }
  for (SerializationCluster* cluster : clusters) {
    cluster->WriteAndMeasureFill(this);
#if defined(DEBUG)
    Write<int32_t>(kSectionMarker);
#endif
  }

  roots->WriteRoots(this);

#if defined(DEBUG)
  Write<int32_t>(kSectionMarker);
#endif

  FlushBytesWrittenToRoot();
  object_currently_writing_.stream_start_ = stream_->Position();

  PrintSnapshotSizes();

  heap()->ResetObjectIdTable();
  return objects_;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)
// The serialized format of the dispatch table is a sequence of variable-length
// integers (the built-in variable-length integer encoding/decoding of
// the stream). Each encoded integer e is interpreted thus:
// -kRecentCount .. -1   Pick value from the recent values buffer at index -1-e.
// 0                     Empty (unused) entry.
// 1 .. kMaxRepeat       Repeat previous entry e times.
// kIndexBase or higher  Pick entry point from the object at index e-kIndexBase
//                       in the snapshot code cluster. Also put it in the recent
//                       values buffer at the next round-robin index.

// Constants for serialization format. Chosen such that repeats and recent
// values are encoded as single bytes in SLEB128 encoding.
static constexpr intptr_t kDispatchTableSpecialEncodingBits = 6;
static constexpr intptr_t kDispatchTableRecentCount =
    1 << kDispatchTableSpecialEncodingBits;
static constexpr intptr_t kDispatchTableRecentMask =
    (1 << kDispatchTableSpecialEncodingBits) - 1;
static constexpr intptr_t kDispatchTableMaxRepeat =
    (1 << kDispatchTableSpecialEncodingBits) - 1;
static constexpr intptr_t kDispatchTableIndexBase = kDispatchTableMaxRepeat + 1;
#endif  // defined(DART_PRECOMPILER) || defined(DART_PRECOMPILED_RUNTIME)

void Serializer::WriteDispatchTable(const Array& entries) {
#if defined(DART_PRECOMPILER)
  if (kind() != Snapshot::kFullAOT) return;

  const intptr_t bytes_before = bytes_written();
  const intptr_t table_length = entries.IsNull() ? 0 : entries.Length();

  ASSERT(table_length <= compiler::target::kWordMax);
  WriteUnsigned(table_length);
  if (table_length == 0) {
    dispatch_table_size_ = bytes_written() - bytes_before;
    return;
  }

  auto const code_cluster =
      reinterpret_cast<CodeSerializationCluster*>(clusters_by_cid_[kCodeCid]);
  ASSERT(code_cluster != nullptr);
  // Reference IDs in a cluster are allocated sequentially, so we can use the
  // first code object's reference ID to calculate the cluster index.
  const intptr_t first_code_id =
      RefId(code_cluster->discovered_objects()->At(0));
  // The first object in the code cluster must have its reference ID allocated.
  ASSERT(IsAllocatedReference(first_code_id));

  // If instructions can be deduped, the code order table in the deserializer
  // may not contain all Code objects in the snapshot. Thus, we write the ID
  // for the first code object here so we can retrieve it during deserialization
  // and calculate the snapshot ID for Code objects from the cluster index.
  //
  // We could just use the snapshot reference ID of the Code object itself
  // instead of the cluster index and avoid this. However, since entries are
  // SLEB128 encoded, the size delta for serializing the first ID once is less
  // than the size delta of serializing the ID plus kIndexBase for each entry,
  // even when Code objects are allocated before all other non-base objects.
  //
  // We could also map Code objects to the first Code object in the cluster with
  // the same entry point and serialize that ID instead, but that loses
  // information about which Code object was originally referenced.
  ASSERT(first_code_id <= compiler::target::kWordMax);
  WriteUnsigned(first_code_id);

  CodePtr previous_code = nullptr;
  CodePtr recent[kDispatchTableRecentCount] = {nullptr};
  intptr_t recent_index = 0;
  intptr_t repeat_count = 0;
  for (intptr_t i = 0; i < table_length; i++) {
    auto const code = Code::RawCast(entries.At(i));
    // First, see if we're repeating the previous entry (invalid, recent, or
    // encoded).
    if (code == previous_code) {
      if (++repeat_count == kDispatchTableMaxRepeat) {
        Write(kDispatchTableMaxRepeat);
        repeat_count = 0;
      }
      continue;
    }
    // Emit any outsanding repeat count before handling the new code value.
    if (repeat_count > 0) {
      Write(repeat_count);
      repeat_count = 0;
    }
    previous_code = code;
    // The invalid entry can be repeated, but is never part of the recent list
    // since it already encodes to a single byte..
    if (code == Code::null()) {
      Write(0);
      continue;
    }
    // Check against the recent entries, and write an encoded reference to
    // the recent entry if found.
    intptr_t found_index = 0;
    for (; found_index < kDispatchTableRecentCount; found_index++) {
      if (recent[found_index] == code) break;
    }
    if (found_index < kDispatchTableRecentCount) {
      Write(~found_index);
      continue;
    }
    // We have a non-repeated, non-recent entry, so encode the reference ID of
    // the code object and emit that.
    auto const object_id = RefId(code);
    // Make sure that this code object has an allocated reference ID.
    ASSERT(IsAllocatedReference(object_id));
    // Use the index in the code cluster, not in the snapshot..
    auto const encoded = kDispatchTableIndexBase + (object_id - first_code_id);
    ASSERT(encoded <= compiler::target::kWordMax);
    Write(encoded);
    recent[recent_index] = code;
    recent_index = (recent_index + 1) & kDispatchTableRecentMask;
  }
  if (repeat_count > 0) {
    Write(repeat_count);
  }
  dispatch_table_size_ = bytes_written() - bytes_before;

  object_currently_writing_.stream_start_ = stream_->Position();
  // If any bytes were written for the dispatch table, add it to the profile.
  if (dispatch_table_size_ > 0 && profile_writer_ != nullptr) {
    // Grab an unused ref index for a unique object id for the dispatch table.
    const auto dispatch_table_id = next_ref_index_++;
    const V8SnapshotProfileWriter::ObjectId dispatch_table_snapshot_id(
        V8SnapshotProfileWriter::kSnapshot, dispatch_table_id);
    profile_writer_->AddRoot(dispatch_table_snapshot_id, "dispatch_table");
    profile_writer_->SetObjectTypeAndName(dispatch_table_snapshot_id,
                                          "DispatchTable", nullptr);
    profile_writer_->AttributeBytesTo(dispatch_table_snapshot_id,
                                      dispatch_table_size_);

    if (!entries.IsNull()) {
      for (intptr_t i = 0; i < entries.Length(); i++) {
        auto const code = Code::RawCast(entries.At(i));
        if (code == Code::null()) continue;
        const V8SnapshotProfileWriter::ObjectId code_id(
            V8SnapshotProfileWriter::kSnapshot, RefId(code));
        profile_writer_->AttributeReferenceTo(
            dispatch_table_snapshot_id,
            {code_id, V8SnapshotProfileWriter::Reference::kElement, i});
      }
    }
  }

#endif  // defined(DART_PRECOMPILER)
}

void Serializer::PrintSnapshotSizes() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_print_snapshot_sizes_verbose) {
    OS::PrintErr(
        "                  Cluster   Objs     Size Fraction Cumulative\n");
    GrowableArray<SerializationCluster*> clusters_by_size;
    for (intptr_t cid = 1; cid < num_cids_; cid++) {
      SerializationCluster* cluster = clusters_by_cid_[cid];
      if (cluster != NULL) {
        clusters_by_size.Add(cluster);
      }
    }
    intptr_t text_size = 0;
    if (image_writer_ != nullptr) {
      auto const text_object_count = image_writer_->GetTextObjectCount();
      text_size = image_writer_->text_size();
      intptr_t trampoline_count, trampoline_size;
      image_writer_->GetTrampolineInfo(&trampoline_count, &trampoline_size);
      auto const instructions_count = text_object_count - trampoline_count;
      auto const instructions_size = text_size - trampoline_size;
      clusters_by_size.Add(new (zone_) FakeSerializationCluster(
          ImageWriter::TagObjectTypeAsReadOnly(zone_, "Instructions"),
          instructions_count, instructions_size));
      if (trampoline_size > 0) {
        clusters_by_size.Add(new (zone_) FakeSerializationCluster(
            ImageWriter::TagObjectTypeAsReadOnly(zone_, "Trampoline"),
            trampoline_count, trampoline_size));
      }
    }
    // The dispatch_table_size_ will be 0 if the snapshot did not include a
    // dispatch table (i.e., the VM snapshot). For a precompiled isolate
    // snapshot, we always serialize at least _one_ byte for the DispatchTable.
    if (dispatch_table_size_ > 0) {
      const auto& dispatch_table_entries = Array::Handle(
          zone_, isolate()->object_store()->dispatch_table_code_entries());
      auto const entry_count =
          dispatch_table_entries.IsNull() ? 0 : dispatch_table_entries.Length();
      clusters_by_size.Add(new (zone_) FakeSerializationCluster(
          "DispatchTable", entry_count, dispatch_table_size_));
    }
    clusters_by_size.Sort(CompareClusters);
    double total_size =
        static_cast<double>(bytes_written() + GetDataSize() + text_size);
    double cumulative_fraction = 0.0;
    for (intptr_t i = 0; i < clusters_by_size.length(); i++) {
      SerializationCluster* cluster = clusters_by_size[i];
      double fraction = static_cast<double>(cluster->size()) / total_size;
      cumulative_fraction += fraction;
      OS::PrintErr("%25s %6" Pd " %8" Pd " %lf %lf\n", cluster->name(),
                   cluster->num_objects(), cluster->size(), fraction,
                   cumulative_fraction);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

Deserializer::Deserializer(Thread* thread,
                           Snapshot::Kind kind,
                           const uint8_t* buffer,
                           intptr_t size,
                           const uint8_t* data_buffer,
                           const uint8_t* instructions_buffer,
                           bool is_non_root_unit,
                           intptr_t offset)
    : ThreadStackResource(thread),
      heap_(thread->isolate()->heap()),
      zone_(thread->zone()),
      kind_(kind),
      stream_(buffer, size),
      image_reader_(nullptr),
      refs_(nullptr),
      next_ref_index_(kFirstReference),
      previous_text_offset_(0),
      canonical_clusters_(nullptr),
      clusters_(nullptr),
      initial_field_table_(thread->isolate_group()->initial_field_table()),
      is_non_root_unit_(is_non_root_unit) {
  if (Snapshot::IncludesCode(kind)) {
    ASSERT(instructions_buffer != nullptr);
    ASSERT(data_buffer != nullptr);
    image_reader_ = new (zone_) ImageReader(data_buffer, instructions_buffer);
  }
  stream_.SetPosition(offset);
}

Deserializer::~Deserializer() {
  delete[] canonical_clusters_;
  delete[] clusters_;
}

DeserializationCluster* Deserializer::ReadCluster() {
  intptr_t cid = ReadCid();
  Zone* Z = zone_;
  if (cid >= kNumPredefinedCids || cid == kInstanceCid) {
    return new (Z) InstanceDeserializationCluster(cid);
  }
  if (IsTypedDataViewClassId(cid)) {
    return new (Z) TypedDataViewDeserializationCluster(cid);
  }
  if (IsExternalTypedDataClassId(cid)) {
    return new (Z) ExternalTypedDataDeserializationCluster(cid);
  }
  if (IsTypedDataClassId(cid)) {
    return new (Z) TypedDataDeserializationCluster(cid);
  }

  if (Snapshot::IncludesCode(kind_)) {
    switch (cid) {
      case kPcDescriptorsCid:
      case kCodeSourceMapCid:
      case kCompressedStackMapsCid:
        return new (Z) RODataDeserializationCluster(cid);
      case kOneByteStringCid:
      case kTwoByteStringCid:
        if (!is_non_root_unit_) {
          return new (Z) RODataDeserializationCluster(cid);
        }
        break;
    }
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
    case kFfiTrampolineDataCid:
      return new (Z) FfiTrampolineDataDeserializationCluster();
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
    case kObjectPoolCid:
      return new (Z) ObjectPoolDeserializationCluster();
    case kPcDescriptorsCid:
      return new (Z) PcDescriptorsDeserializationCluster();
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
    case kLoadingUnitCid:
      return new (Z) LoadingUnitDeserializationCluster();
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
    case kOneByteStringCid:
      return new (Z) OneByteStringDeserializationCluster();
    case kTwoByteStringCid:
      return new (Z) TwoByteStringDeserializationCluster();
    case kWeakSerializationReferenceCid:
#if defined(DART_PRECOMPILED_RUNTIME)
      return new (Z) WeakSerializationReferenceDeserializationCluster();
#endif
    default:
      break;
  }
  FATAL1("No cluster defined for cid %" Pd, cid);
  return NULL;
}

void Deserializer::ReadDispatchTable(ReadStream* stream) {
#if defined(DART_PRECOMPILED_RUNTIME)
  const uint8_t* table_snapshot_start = stream->AddressOfCurrentPosition();
  const intptr_t length = stream->ReadUnsigned();
  if (length == 0) return;

  // Not all Code objects may be in the code_order_table when instructions can
  // be deduplicated. Thus, we serialize the reference ID of the first code
  // object, from which we can get the reference ID for any code object.
  const intptr_t first_code_id = stream->ReadUnsigned();

  auto const I = isolate();
  auto code = I->object_store()->dispatch_table_null_error_stub();
  ASSERT(code != Code::null());
  uword null_entry = Code::EntryPointOf(code);

  auto const table = new DispatchTable(length);
  auto const array = table->array();
  uword value = 0;
  uword recent[kDispatchTableRecentCount] = {0};
  intptr_t recent_index = 0;
  intptr_t repeat_count = 0;
  for (intptr_t i = 0; i < length; i++) {
    if (repeat_count > 0) {
      array[i] = value;
      repeat_count--;
      continue;
    }
    auto const encoded = stream->Read<intptr_t>();
    if (encoded == 0) {
      value = null_entry;
    } else if (encoded < 0) {
      intptr_t r = ~encoded;
      ASSERT(r < kDispatchTableRecentCount);
      value = recent[r];
    } else if (encoded <= kDispatchTableMaxRepeat) {
      repeat_count = encoded - 1;
    } else {
      intptr_t cluster_index = encoded - kDispatchTableIndexBase;
      code = Code::RawCast(Ref(first_code_id + cluster_index));
      value = Code::EntryPointOf(code);
      recent[recent_index] = value;
      recent_index = (recent_index + 1) & kDispatchTableRecentMask;
    }
    array[i] = value;
  }
  ASSERT(repeat_count == 0);

  I->group()->set_dispatch_table(table);
  intptr_t table_snapshot_size =
      stream->AddressOfCurrentPosition() - table_snapshot_start;
  I->group()->set_dispatch_table_snapshot(table_snapshot_start);
  I->group()->set_dispatch_table_snapshot_size(table_snapshot_size);
#endif
}

ApiErrorPtr Deserializer::VerifyImageAlignment() {
  if (image_reader_ != nullptr) {
    return image_reader_->VerifyAlignment();
  }
  return ApiError::null();
}

char* SnapshotHeaderReader::VerifyVersionAndFeatures(Isolate* isolate,
                                                     intptr_t* offset) {
  char* error = VerifyVersion();
  if (error == nullptr) {
    error = VerifyFeatures(isolate);
  }
  if (error == nullptr) {
    *offset = stream_.Position();
  }
  return error;
}

char* SnapshotHeaderReader::VerifyVersion() {
  // If the version string doesn't match, return an error.
  // Note: New things are allocated only if we're going to return an error.

  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != NULL);
  const intptr_t version_len = strlen(expected_version);
  if (stream_.PendingBytes() < version_len) {
    const intptr_t kMessageBufferSize = 128;
    char message_buffer[kMessageBufferSize];
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "No full snapshot version found, expected '%s'",
                   expected_version);
    return BuildError(message_buffer);
  }

  const char* version =
      reinterpret_cast<const char*>(stream_.AddressOfCurrentPosition());
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
    return BuildError(message_buffer);
  }
  stream_.Advance(version_len);

  return nullptr;
}

char* SnapshotHeaderReader::VerifyFeatures(Isolate* isolate) {
  const char* expected_features =
      Dart::FeaturesString(isolate, (isolate == NULL), kind_);
  ASSERT(expected_features != NULL);
  const intptr_t expected_len = strlen(expected_features);

  const char* features = nullptr;
  intptr_t features_length = 0;

  auto error = ReadFeatures(&features, &features_length);
  if (error != nullptr) {
    return error;
  }

  if (features_length != expected_len ||
      (strncmp(features, expected_features, expected_len) != 0)) {
    const intptr_t kMessageBufferSize = 1024;
    char message_buffer[kMessageBufferSize];
    char* actual_features = Utils::StrNDup(
        features, features_length < 1024 ? features_length : 1024);
    Utils::SNPrint(message_buffer, kMessageBufferSize,
                   "Snapshot not compatible with the current VM configuration: "
                   "the snapshot requires '%s' but the VM has '%s'",
                   actual_features, expected_features);
    free(const_cast<char*>(expected_features));
    free(actual_features);
    return BuildError(message_buffer);
  }
  free(const_cast<char*>(expected_features));
  return nullptr;
}

char* SnapshotHeaderReader::ReadFeatures(const char** features,
                                         intptr_t* features_length) {
  const char* cursor =
      reinterpret_cast<const char*>(stream_.AddressOfCurrentPosition());
  const intptr_t length = Utils::StrNLen(cursor, stream_.PendingBytes());
  if (length == stream_.PendingBytes()) {
    return BuildError(
        "The features string in the snapshot was not '\\0'-terminated.");
  }
  *features = cursor;
  *features_length = length;
  stream_.Advance(length + 1);
  return nullptr;
}

char* SnapshotHeaderReader::BuildError(const char* message) {
  return Utils::StrDup(message);
}

ApiErrorPtr FullSnapshotReader::ConvertToApiError(char* message) {
  // This can also fail while bringing up the VM isolate, so make sure to
  // allocate the error message in old space.
  const String& msg = String::Handle(String::New(message, Heap::kOld));

  // The [message] was constructed with [BuildError] and needs to be freed.
  free(message);

  return ApiError::New(msg, Heap::kOld);
}

void Deserializer::ReadInstructions(CodePtr code, bool deferred) {
  if (deferred) {
#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_use_bare_instructions) {
      uword entry_point = StubCode::NotLoaded().EntryPoint();
      code->ptr()->entry_point_ = entry_point;
      code->ptr()->unchecked_entry_point_ = entry_point;
      code->ptr()->monomorphic_entry_point_ = entry_point;
      code->ptr()->monomorphic_unchecked_entry_point_ = entry_point;
      code->ptr()->instructions_length_ = 0;
      return;
    }
#endif
    InstructionsPtr instr = StubCode::NotLoaded().instructions();
    uint32_t unchecked_offset = 0;
    code->ptr()->instructions_ = instr;
#if defined(DART_PRECOMPILED_RUNTIME)
    code->ptr()->instructions_length_ = Instructions::Size(instr);
#else
    code->ptr()->unchecked_offset_ = unchecked_offset;
#endif
    Code::InitializeCachedEntryPointsFrom(code, instr, unchecked_offset);
    return;
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_use_bare_instructions) {
    // There are no serialized RawInstructions objects in this mode.
    code->ptr()->instructions_ = Instructions::null();
    previous_text_offset_ += ReadUnsigned();
    const uword payload_start =
        image_reader_->GetBareInstructionsAt(previous_text_offset_);
    const uint32_t payload_info = ReadUnsigned();
    const uint32_t unchecked_offset = payload_info >> 1;
    const bool has_monomorphic_entrypoint = (payload_info & 0x1) == 0x1;

    const uword entry_offset = has_monomorphic_entrypoint
                                   ? Instructions::kPolymorphicEntryOffsetAOT
                                   : 0;
    const uword monomorphic_entry_offset =
        has_monomorphic_entrypoint ? Instructions::kMonomorphicEntryOffsetAOT
                                   : 0;

    const uword entry_point = payload_start + entry_offset;
    const uword monomorphic_entry_point =
        payload_start + monomorphic_entry_offset;

    code->ptr()->entry_point_ = entry_point;
    code->ptr()->unchecked_entry_point_ = entry_point + unchecked_offset;
    code->ptr()->monomorphic_entry_point_ = monomorphic_entry_point;
    code->ptr()->monomorphic_unchecked_entry_point_ =
        monomorphic_entry_point + unchecked_offset;
    return;
  }
#endif

  InstructionsPtr instr = image_reader_->GetInstructionsAt(Read<uint32_t>());
  uint32_t unchecked_offset = ReadUnsigned();
  code->ptr()->instructions_ = instr;
#if defined(DART_PRECOMPILED_RUNTIME)
  code->ptr()->instructions_length_ = Instructions::Size(instr);
#else
  code->ptr()->unchecked_offset_ = unchecked_offset;
  if (kind() == Snapshot::kFullJIT) {
    const uint32_t active_offset = Read<uint32_t>();
    instr = image_reader_->GetInstructionsAt(active_offset);
    unchecked_offset = ReadUnsigned();
  }
  code->ptr()->active_instructions_ = instr;
#endif
  Code::InitializeCachedEntryPointsFrom(code, instr, unchecked_offset);
}

void Deserializer::EndInstructions(const Array& refs,
                                   intptr_t start_index,
                                   intptr_t stop_index) {
#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_use_bare_instructions) {
    uword previous_end = image_reader_->GetBareInstructionsEnd();
    for (intptr_t id = stop_index - 1; id >= start_index; id--) {
      CodePtr code = static_cast<CodePtr>(refs.At(id));
      uword start = Code::PayloadStartOf(code);
      ASSERT(start <= previous_end);
      code->ptr()->instructions_length_ = previous_end - start;
      previous_end = start;
    }

    // Build an array of code objects representing the order in which the
    // [Code]'s instructions will be located in memory.
    const intptr_t count = stop_index - start_index;
    const Array& order_table =
        Array::Handle(zone_, Array::New(count, Heap::kOld));
    Object& code = Object::Handle(zone_);
    for (intptr_t i = 0; i < count; i++) {
      code = refs.At(start_index + i);
      order_table.SetAt(i, code);
    }
    ObjectStore* object_store = Isolate::Current()->object_store();
    GrowableObjectArray& order_tables =
        GrowableObjectArray::Handle(zone_, object_store->code_order_tables());
    if (order_tables.IsNull()) {
      order_tables = GrowableObjectArray::New(Heap::kOld);
      object_store->set_code_order_tables(order_tables);
    }
    order_tables.Add(order_table, Heap::kOld);
  }
#endif
}

ObjectPtr Deserializer::GetObjectAt(uint32_t offset) const {
  return image_reader_->GetObjectAt(offset);
}

class HeapLocker : public StackResource {
 public:
  HeapLocker(Thread* thread, PageSpace* page_space)
      : StackResource(thread),
        page_space_(page_space),
        freelist_(page_space->DataFreeList()) {
    page_space_->AcquireLock(freelist_);
  }
  ~HeapLocker() { page_space_->ReleaseLock(freelist_); }

 private:
  PageSpace* page_space_;
  FreeList* freelist_;
};

void Deserializer::Deserialize(DeserializationRoots* roots) {
  Array& refs = Array::Handle(zone_);
  num_base_objects_ = ReadUnsigned();
  num_objects_ = ReadUnsigned();
  num_canonical_clusters_ = ReadUnsigned();
  num_clusters_ = ReadUnsigned();
  const intptr_t initial_field_table_len = ReadUnsigned();

  canonical_clusters_ = new DeserializationCluster*[num_canonical_clusters_];
  clusters_ = new DeserializationCluster*[num_clusters_];
  refs_ = Array::New(num_objects_ + kFirstReference, Heap::kOld);
  if (initial_field_table_len > 0) {
    initial_field_table_->AllocateIndex(initial_field_table_len - 1);
    ASSERT_EQUAL(initial_field_table_->NumFieldIds(), initial_field_table_len);
  }

  {
    NoSafepointScope no_safepoint;
    HeapLocker hl(thread(), heap_->old_space());

    roots->AddBaseObjects(this);

    if (num_base_objects_ != (next_ref_index_ - kFirstReference)) {
      FATAL2("Snapshot expects %" Pd
             " base objects, but deserializer provided %" Pd,
             num_base_objects_, next_ref_index_ - kFirstReference);
    }

    {
      TIMELINE_DURATION(thread(), Isolate, "ReadAlloc");
      for (intptr_t i = 0; i < num_canonical_clusters_; i++) {
        canonical_clusters_[i] = ReadCluster();
        TIMELINE_DURATION(thread(), Isolate, canonical_clusters_[i]->name());
        canonical_clusters_[i]->ReadAlloc(this, /*is_canonical*/ true);
#if defined(DEBUG)
        intptr_t serializers_next_ref_index_ = Read<int32_t>();
        ASSERT_EQUAL(serializers_next_ref_index_, next_ref_index_);
#endif
      }
      for (intptr_t i = 0; i < num_clusters_; i++) {
        clusters_[i] = ReadCluster();
        TIMELINE_DURATION(thread(), Isolate, clusters_[i]->name());
        clusters_[i]->ReadAlloc(this, /*is_canonical*/ false);
#if defined(DEBUG)
        intptr_t serializers_next_ref_index_ = Read<int32_t>();
        ASSERT_EQUAL(serializers_next_ref_index_, next_ref_index_);
#endif
      }
    }

    // We should have completely filled the ref array.
    ASSERT_EQUAL(next_ref_index_ - kFirstReference, num_objects_);

    {
      TIMELINE_DURATION(thread(), Isolate, "ReadFill");
      for (intptr_t i = 0; i < num_canonical_clusters_; i++) {
        TIMELINE_DURATION(thread(), Isolate, canonical_clusters_[i]->name());
        canonical_clusters_[i]->ReadFill(this, /*is_canonical*/ true);
#if defined(DEBUG)
        int32_t section_marker = Read<int32_t>();
        ASSERT(section_marker == kSectionMarker);
#endif
      }
      for (intptr_t i = 0; i < num_clusters_; i++) {
        TIMELINE_DURATION(thread(), Isolate, clusters_[i]->name());
        clusters_[i]->ReadFill(this, /*is_canonical*/ false);
#if defined(DEBUG)
        int32_t section_marker = Read<int32_t>();
        ASSERT(section_marker == kSectionMarker);
#endif
      }
    }

    roots->ReadRoots(this);

#if defined(DEBUG)
    int32_t section_marker = Read<int32_t>();
    ASSERT(section_marker == kSectionMarker);
#endif

    refs = refs_;
    refs_ = NULL;
  }

  roots->PostLoad(this, refs);

#if defined(DEBUG)
  Isolate* isolate = thread()->isolate();
  isolate->ValidateClassTable();
  if (isolate != Dart::vm_isolate()) {
    isolate->heap()->Verify();
  }
#endif

  // TODO(rmacnak): When splitting literals, load clusters requiring
  // canonicalization first, canonicalize and update the ref array, the load
  // the remaining clusters to avoid a full heap walk to update references to
  // the losers of any canonicalization races.
  {
    TIMELINE_DURATION(thread(), Isolate, "PostLoad");
    for (intptr_t i = 0; i < num_canonical_clusters_; i++) {
      TIMELINE_DURATION(thread(), Isolate, canonical_clusters_[i]->name());
      canonical_clusters_[i]->PostLoad(this, refs, /*is_canonical*/ true);
    }
    for (intptr_t i = 0; i < num_clusters_; i++) {
      TIMELINE_DURATION(thread(), Isolate, clusters_[i]->name());
      clusters_[i]->PostLoad(this, refs, /*is_canonical*/ false);
    }
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
FullSnapshotWriter::FullSnapshotWriter(
    Snapshot::Kind kind,
    NonStreamingWriteStream* vm_snapshot_data,
    NonStreamingWriteStream* isolate_snapshot_data,
    ImageWriter* vm_image_writer,
    ImageWriter* isolate_image_writer)
    : thread_(Thread::Current()),
      kind_(kind),
      vm_snapshot_data_(vm_snapshot_data),
      isolate_snapshot_data_(isolate_snapshot_data),
      vm_isolate_snapshot_size_(0),
      isolate_snapshot_size_(0),
      vm_image_writer_(vm_image_writer),
      isolate_image_writer_(isolate_image_writer),
      clustered_vm_size_(0),
      clustered_isolate_size_(0),
      mapped_data_size_(0),
      mapped_text_size_(0) {
  ASSERT(isolate() != NULL);
  ASSERT(heap() != NULL);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

#if defined(DEBUG)
  isolate()->ValidateClassTable();
  isolate()->ValidateConstants();
#endif  // DEBUG

#if defined(DART_PRECOMPILER)
  if (FLAG_write_v8_snapshot_profile_to != nullptr) {
    profile_writer_ = new (zone()) V8SnapshotProfileWriter(zone());
  }
#endif
}

FullSnapshotWriter::~FullSnapshotWriter() {}

ZoneGrowableArray<Object*>* FullSnapshotWriter::WriteVMSnapshot() {
  TIMELINE_DURATION(thread(), Isolate, "WriteVMSnapshot");

  ASSERT(vm_snapshot_data_ != nullptr);
  Serializer serializer(thread(), kind_, vm_snapshot_data_, vm_image_writer_,
                        /*vm=*/true, profile_writer_);

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(true);
  VMSerializationRoots roots(
      Array::Handle(Dart::vm_isolate()->object_store()->symbol_table()));
  ZoneGrowableArray<Object*>* objects = serializer.Serialize(&roots);
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
  return objects;
}

void FullSnapshotWriter::WriteProgramSnapshot(
    ZoneGrowableArray<Object*>* objects,
    GrowableArray<LoadingUnitSerializationData*>* units) {
  TIMELINE_DURATION(thread(), Isolate, "WriteProgramSnapshot");

  ASSERT(isolate_snapshot_data_ != nullptr);
  Serializer serializer(thread(), kind_, isolate_snapshot_data_,
                        isolate_image_writer_, /*vm=*/false, profile_writer_);
  serializer.set_loading_units(units);
  serializer.set_current_loading_unit_id(LoadingUnit::kRootId);
  ObjectStore* object_store = isolate()->object_store();
  ASSERT(object_store != NULL);

  // These type arguments must always be retained.
  ASSERT(object_store->type_argument_int()->ptr()->IsCanonical());
  ASSERT(object_store->type_argument_double()->ptr()->IsCanonical());
  ASSERT(object_store->type_argument_string()->ptr()->IsCanonical());
  ASSERT(object_store->type_argument_string_dynamic()->ptr()->IsCanonical());
  ASSERT(object_store->type_argument_string_string()->ptr()->IsCanonical());

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(false);
  ProgramSerializationRoots roots(objects, object_store);
  objects = serializer.Serialize(&roots);
  if (units != nullptr) {
    (*units)[LoadingUnit::kRootId]->set_objects(objects);
  }
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

void FullSnapshotWriter::WriteUnitSnapshot(
    GrowableArray<LoadingUnitSerializationData*>* units,
    LoadingUnitSerializationData* unit,
    uint32_t program_hash) {
  TIMELINE_DURATION(thread(), Isolate, "WriteUnitSnapshot");

  Serializer serializer(thread(), kind_, isolate_snapshot_data_,
                        isolate_image_writer_, /*vm=*/false, profile_writer_);
  serializer.set_loading_units(units);
  serializer.set_current_loading_unit_id(unit->id());

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(false);
  serializer.Write(program_hash);

  UnitSerializationRoots roots(unit);
  unit->set_objects(serializer.Serialize(&roots));

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

void FullSnapshotWriter::WriteFullSnapshot(
    GrowableArray<LoadingUnitSerializationData*>* data) {
  ZoneGrowableArray<Object*>* objects;
  if (vm_snapshot_data_ != nullptr) {
    objects = WriteVMSnapshot();
  } else {
    objects = nullptr;
  }

  if (isolate_snapshot_data_ != nullptr) {
    WriteProgramSnapshot(objects, data);
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
#endif  // defined(DART_PRECOMPILED_RUNTIME)

FullSnapshotReader::FullSnapshotReader(const Snapshot* snapshot,
                                       const uint8_t* instructions_buffer,
                                       Thread* thread)
    : kind_(snapshot->kind()),
      thread_(thread),
      buffer_(snapshot->Addr()),
      size_(snapshot->length()),
      data_image_(snapshot->DataImage()),
      instructions_image_(instructions_buffer) {}

char* SnapshotHeaderReader::InitializeGlobalVMFlagsFromSnapshot(
    const Snapshot* snapshot) {
  SnapshotHeaderReader header_reader(snapshot);

  char* error = header_reader.VerifyVersion();
  if (error != nullptr) {
    return error;
  }

  const char* features = nullptr;
  intptr_t features_length = 0;
  error = header_reader.ReadFeatures(&features, &features_length);
  if (error != nullptr) {
    return error;
  }

  ASSERT(features[features_length] == '\0');
  const char* cursor = features;
  while (*cursor != '\0') {
    while (*cursor == ' ') {
      cursor++;
    }

    const char* end = strstr(cursor, " ");
    if (end == nullptr) {
      end = features + features_length;
    }

#define SET_FLAG(name)                                                         \
  if (strncmp(cursor, #name, end - cursor) == 0) {                             \
    FLAG_##name = true;                                                        \
    cursor = end;                                                              \
    continue;                                                                  \
  }                                                                            \
  if (strncmp(cursor, "no-" #name, end - cursor) == 0) {                       \
    FLAG_##name = false;                                                       \
    cursor = end;                                                              \
    continue;                                                                  \
  }

#define CHECK_FLAG(name, mode)                                                 \
  if (strncmp(cursor, #name, end - cursor) == 0) {                             \
    if (!FLAG_##name) {                                                        \
      return header_reader.BuildError("Flag " #name                            \
                                      " is true in snapshot, "                 \
                                      "but " #name                             \
                                      " is always false in " mode);            \
    }                                                                          \
    cursor = end;                                                              \
    continue;                                                                  \
  }                                                                            \
  if (strncmp(cursor, "no-" #name, end - cursor) == 0) {                       \
    if (FLAG_##name) {                                                         \
      return header_reader.BuildError("Flag " #name                            \
                                      " is false in snapshot, "                \
                                      "but " #name                             \
                                      " is always true in " mode);             \
    }                                                                          \
    cursor = end;                                                              \
    continue;                                                                  \
  }

#define SET_P(name, T, DV, C) SET_FLAG(name)

#if defined(PRODUCT)
#define SET_OR_CHECK_R(name, PV, T, DV, C) CHECK_FLAG(name, "product mode")
#else
#define SET_OR_CHECK_R(name, PV, T, DV, C) SET_FLAG(name)
#endif

#if defined(PRODUCT)
#define SET_OR_CHECK_C(name, PCV, PV, T, DV, C) CHECK_FLAG(name, "product mode")
#elif defined(DART_PRECOMPILED_RUNTIME)
#define SET_OR_CHECK_C(name, PCV, PV, T, DV, C)                                \
  CHECK_FLAG(name, "the precompiled runtime")
#else
#define SET_OR_CHECK_C(name, PV, T, DV, C) SET_FLAG(name)
#endif

#if !defined(DEBUG)
#define SET_OR_CHECK_D(name, T, DV, C) CHECK_FLAG(name, "non-debug mode")
#else
#define SET_OR_CHECK_D(name, T, DV, C) SET_FLAG(name)
#endif

    VM_GLOBAL_FLAG_LIST(SET_P, SET_OR_CHECK_R, SET_OR_CHECK_C, SET_OR_CHECK_D)

#undef SET_OR_CHECK_D
#undef SET_OR_CHECK_C
#undef SET_OR_CHECK_R
#undef SET_P
#undef CHECK_FLAG
#undef SET_FLAG

#if defined(DART_PRECOMPILED_RUNTIME)
    if (FLAG_sound_null_safety == kNullSafetyOptionUnspecified) {
      if (strncmp(cursor, "null-safety", end - cursor) == 0) {
        FLAG_sound_null_safety = kNullSafetyOptionStrong;
        cursor = end;
        continue;
      }
      if (strncmp(cursor, "no-null-safety", end - cursor) == 0) {
        FLAG_sound_null_safety = kNullSafetyOptionWeak;
        cursor = end;
        continue;
      }
    }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

    cursor = end;
  }

  return nullptr;
}

bool SnapshotHeaderReader::NullSafetyFromSnapshot(const Snapshot* snapshot) {
  bool null_safety = false;
  SnapshotHeaderReader header_reader(snapshot);
  const char* features = nullptr;
  intptr_t features_length = 0;

  char* error = header_reader.ReadFeatures(&features, &features_length);
  if (error != nullptr) {
    return false;
  }

  ASSERT(features[features_length] == '\0');
  const char* cursor = features;
  while (*cursor != '\0') {
    while (*cursor == ' ') {
      cursor++;
    }

    const char* end = strstr(cursor, " ");
    if (end == nullptr) {
      end = features + features_length;
    }

    if (strncmp(cursor, "null-safety", end - cursor) == 0) {
      cursor = end;
      null_safety = true;
      continue;
    }
    if (strncmp(cursor, "no-null-safety", end - cursor) == 0) {
      cursor = end;
      null_safety = false;
      continue;
    }

    cursor = end;
  }

  return null_safety;
}

ApiErrorPtr FullSnapshotReader::ReadVMSnapshot() {
  SnapshotHeaderReader header_reader(kind_, buffer_, size_);

  intptr_t offset = 0;
  char* error =
      header_reader.VerifyVersionAndFeatures(/*isolate=*/NULL, &offset);
  if (error != nullptr) {
    return ConvertToApiError(error);
  }

  Deserializer deserializer(thread_, kind_, buffer_, size_, data_image_,
                            instructions_image_, /*is_non_root_unit=*/false,
                            offset);
  ApiErrorPtr api_error = deserializer.VerifyImageAlignment();
  if (api_error != ApiError::null()) {
    return api_error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != NULL);
    thread_->isolate()->SetupImagePage(data_image_,
                                       /* is_executable */ false);
    ASSERT(instructions_image_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_image_,
                                       /* is_executable */ true);
  }

  VMDeserializationRoots roots;
  deserializer.Deserialize(&roots);

#if defined(DART_PRECOMPILED_RUNTIME)
  // Initialize entries in the VM portion of the BSS segment.
  ASSERT(Snapshot::IncludesCode(kind_));
  Image image(instructions_image_);
  if (auto const bss = image.bss()) {
    BSS::Initialize(thread_, bss, /*vm=*/true);
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  return ApiError::null();
}

ApiErrorPtr FullSnapshotReader::ReadProgramSnapshot() {
  SnapshotHeaderReader header_reader(kind_, buffer_, size_);
  intptr_t offset = 0;
  char* error =
      header_reader.VerifyVersionAndFeatures(thread_->isolate(), &offset);
  if (error != nullptr) {
    return ConvertToApiError(error);
  }

  Deserializer deserializer(thread_, kind_, buffer_, size_, data_image_,
                            instructions_image_, /*is_non_root_unit=*/false,
                            offset);
  ApiErrorPtr api_error = deserializer.VerifyImageAlignment();
  if (api_error != ApiError::null()) {
    return api_error;
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != NULL);
    thread_->isolate()->SetupImagePage(data_image_,
                                       /* is_executable */ false);
    ASSERT(instructions_image_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_image_,
                                       /* is_executable */ true);
  }

  ProgramDeserializationRoots roots(thread_->isolate()->object_store());
  deserializer.Deserialize(&roots);

  PatchGlobalObjectPool();
  InitializeBSS();

  return ApiError::null();
}

ApiErrorPtr FullSnapshotReader::ReadUnitSnapshot(const LoadingUnit& unit) {
  SnapshotHeaderReader header_reader(kind_, buffer_, size_);
  intptr_t offset = 0;
  char* error =
      header_reader.VerifyVersionAndFeatures(thread_->isolate(), &offset);
  if (error != nullptr) {
    return ConvertToApiError(error);
  }

  Deserializer deserializer(
      thread_, kind_, buffer_, size_, data_image_, instructions_image_,
      /*is_non_root_unit=*/unit.id() != LoadingUnit::kRootId, offset);
  ApiErrorPtr api_error = deserializer.VerifyImageAlignment();
  if (api_error != ApiError::null()) {
    return api_error;
  }
  {
    Array& units =
        Array::Handle(thread_->isolate()->object_store()->loading_units());
    uint32_t main_program_hash = Smi::Value(Smi::RawCast(units.At(0)));
    uint32_t unit_program_hash = deserializer.Read<uint32_t>();
    if (main_program_hash != unit_program_hash) {
      return ApiError::New(String::Handle(
          String::New("Deferred loading unit is from a different "
                      "program than the main loading unit")));
    }
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != NULL);
    thread_->isolate()->SetupImagePage(data_image_,
                                       /* is_executable */ false);
    ASSERT(instructions_image_ != NULL);
    thread_->isolate()->SetupImagePage(instructions_image_,
                                       /* is_executable */ true);
  }

  UnitDeserializationRoots roots(unit);
  deserializer.Deserialize(&roots);

  PatchGlobalObjectPool();
  InitializeBSS();

  return ApiError::null();
}

void FullSnapshotReader::PatchGlobalObjectPool() {
#if defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_use_bare_instructions) {
    // By default, every switchable call site will put (ic_data, code) into the
    // object pool.  The [code] is initialized (at AOT compile-time) to be a
    // [StubCode::SwitchableCallMiss].
    //
    // In --use-bare-instruction we reduce the extra indirection via the [code]
    // object and store instead (ic_data, entrypoint) in the object pool.
    //
    // Since the actual [entrypoint] is only known at AOT runtime we switch all
    // existing UnlinkedCall entries in the object pool to be it's entrypoint.
    auto zone = thread_->zone();
    const auto& pool = ObjectPool::Handle(
        zone, ObjectPool::RawCast(
                  thread_->isolate()->object_store()->global_object_pool()));
    auto& entry = Object::Handle(zone);
    auto& smi = Smi::Handle(zone);
    for (intptr_t i = 0; i < pool.Length(); i++) {
      if (pool.TypeAt(i) == ObjectPool::EntryType::kTaggedObject) {
        entry = pool.ObjectAt(i);
        if (entry.raw() == StubCode::SwitchableCallMiss().raw()) {
          smi = Smi::FromAlignedAddress(
              StubCode::SwitchableCallMiss().MonomorphicEntryPoint());
          pool.SetTypeAt(i, ObjectPool::EntryType::kImmediate,
                         ObjectPool::Patchability::kPatchable);
          pool.SetObjectAt(i, smi);
        } else if (entry.raw() == StubCode::MegamorphicCall().raw()) {
          smi = Smi::FromAlignedAddress(
              StubCode::MegamorphicCall().MonomorphicEntryPoint());
          pool.SetTypeAt(i, ObjectPool::EntryType::kImmediate,
                         ObjectPool::Patchability::kPatchable);
          pool.SetObjectAt(i, smi);
        }
      }
    }
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void FullSnapshotReader::InitializeBSS() {
#if defined(DART_PRECOMPILED_RUNTIME)
  // Initialize entries in the isolate portion of the BSS segment.
  ASSERT(Snapshot::IncludesCode(kind_));
  Image image(instructions_image_);
  if (auto const bss = image.bss()) {
    BSS::Initialize(thread_, bss, /*vm=*/false);
  }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
