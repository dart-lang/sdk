// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>

#include "vm/app_snapshot.h"

#include "platform/assert.h"
#include "vm/bootstrap.h"
#include "vm/bss_relocs.h"
#include "vm/canonical_tables.h"
#include "vm/class_id.h"
#include "vm/code_observers.h"
#include "vm/compiler/api/print_filter.h"
#include "vm/compiler/assembler/disassembler.h"
#include "vm/dart.h"
#include "vm/dart_entry.h"
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
#include "vm/v8_snapshot_writer.h"
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
            nullptr,
            "Write a snapshot profile in V8 format to a file.");
DEFINE_FLAG(bool,
            print_array_optimization_candidates,
            false,
            "Print information about how many array are candidates for Smi and "
            "ROData optimizations.");
#endif  // defined(DART_PRECOMPILER)

namespace {

// Serialized clusters are identified by their CID. So to insert custom clusters
// we need to assign them a CID that is otherwise never serialized.
static constexpr intptr_t kDeltaEncodedTypedDataCid = kNativePointer;

// StorageTrait for HashTable which allows to create hash tables backed by
// zone memory. Used to compute cluster order for canonical clusters.
struct GrowableArrayStorageTraits {
  class Array : public ZoneAllocated {
   public:
    explicit Array(Zone* zone, intptr_t length)
        : length_(length), array_(zone->Alloc<ObjectPtr>(length)) {}

    intptr_t Length() const { return length_; }
    void SetAt(intptr_t index, const Object& value) const {
      array_[index] = value.ptr();
    }
    ObjectPtr At(intptr_t index) const { return array_[index]; }

   private:
    intptr_t length_ = 0;
    ObjectPtr* array_ = nullptr;
    DISALLOW_COPY_AND_ASSIGN(Array);
  };

  using ArrayPtr = Array*;
  class ArrayHandle : public ZoneAllocated {
   public:
    explicit ArrayHandle(ArrayPtr ptr) : ptr_(ptr) {}
    ArrayHandle() {}

    void SetFrom(const ArrayHandle& other) { ptr_ = other.ptr_; }
    void Clear() { ptr_ = nullptr; }
    bool IsNull() const { return ptr_ == nullptr; }
    ArrayPtr ptr() { return ptr_; }

    intptr_t Length() const { return ptr_->Length(); }
    void SetAt(intptr_t index, const Object& value) const {
      ptr_->SetAt(index, value);
    }
    ObjectPtr At(intptr_t index) const { return ptr_->At(index); }

   private:
    ArrayPtr ptr_ = nullptr;
    DISALLOW_COPY_AND_ASSIGN(ArrayHandle);
  };

  static ArrayHandle& PtrToHandle(ArrayPtr ptr) {
    return *new ArrayHandle(ptr);
  }

  static void SetHandle(ArrayHandle& dst, const ArrayHandle& src) {  // NOLINT
    dst.SetFrom(src);
  }

  static void ClearHandle(ArrayHandle& dst) {  // NOLINT
    dst.Clear();
  }

  static ArrayPtr New(Zone* zone, intptr_t length, Heap::Space space) {
    return new (zone) Array(zone, length);
  }

  static bool IsImmutable(const ArrayHandle& handle) { return false; }

  static ObjectPtr At(ArrayHandle* array, intptr_t index) {
    return array->At(index);
  }

  static void SetAt(ArrayHandle* array, intptr_t index, const Object& value) {
    array->SetAt(index, value);
  }
};
}  // namespace

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

static void RelocateCodeObjects(
    bool is_vm,
    GrowableArray<CodePtr>* code_objects,
    GrowableArray<ImageWriterCommand>* image_writer_commands) {
  auto thread = Thread::Current();
  auto isolate_group =
      is_vm ? Dart::vm_isolate()->group() : thread->isolate_group();

  WritableCodePages writable_code_pages(thread, isolate_group);
  CodeRelocator::Relocate(thread, code_objects, image_writer_commands, is_vm);
}

#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)

DART_FORCE_INLINE
ObjectPtr Deserializer::Allocate(intptr_t size) {
  return UntaggedObject::FromAddr(
      old_space_->AllocateSnapshotLocked(freelist_, size));
}

void Deserializer::InitializeHeader(ObjectPtr raw,
                                    intptr_t class_id,
                                    intptr_t size,
                                    bool is_canonical) {
  ASSERT(Utils::IsAligned(size, kObjectAlignment));
  uword tags = 0;
  tags = UntaggedObject::ClassIdTag::update(class_id, tags);
  tags = UntaggedObject::SizeTag::update(size, tags);
  tags = UntaggedObject::CanonicalBit::update(is_canonical, tags);
  tags = UntaggedObject::OldBit::update(true, tags);
  tags = UntaggedObject::OldAndNotMarkedBit::update(true, tags);
  tags = UntaggedObject::OldAndNotRememberedBit::update(true, tags);
  tags = UntaggedObject::NewBit::update(false, tags);
  raw->untag()->tags_ = tags;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void SerializationCluster::WriteAndMeasureAlloc(Serializer* serializer) {
  intptr_t start_size = serializer->bytes_written();
  intptr_t start_data = serializer->GetDataSize();
  intptr_t start_objects = serializer->next_ref_index();
  uint64_t cid_and_canonical =
      (static_cast<uint64_t>(cid_) << 1) | (is_canonical() ? 0x1 : 0x0);
  serializer->Write<uint64_t>(cid_and_canonical);
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
  if (target_instance_size_ != kSizeVaries) {
    target_memory_size_ += num_objects_ * target_instance_size_;
  }
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
#endif  // !DART_PRECOMPILED_RUNTIME

DART_NOINLINE
void DeserializationCluster::ReadAllocFixedSize(Deserializer* d,
                                                intptr_t instance_size) {
  start_index_ = d->next_index();
  intptr_t count = d->ReadUnsigned();
  for (intptr_t i = 0; i < count; i++) {
    d->AssignRef(d->Allocate(instance_size));
  }
  stop_index_ = d->next_index();
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static UnboxedFieldBitmap CalculateTargetUnboxedFieldsBitmap(
    Serializer* s,
    intptr_t class_id) {
  const auto unboxed_fields_bitmap_host =
      s->isolate_group()->class_table()->GetUnboxedFieldsMapAt(class_id);

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
      : SerializationCluster("Class",
                             kClassCid,
                             compiler::target::Class::InstanceSize()),
        predefined_(kNumPredefinedCids),
        objects_(num_cids) {}
  ~ClassSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ClassPtr cls = Class::RawCast(object);
    intptr_t class_id = cls->untag()->id_;

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
    intptr_t count = predefined_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ClassPtr cls = predefined_[i];
      s->AssignRef(cls);
      AutoTraceObject(cls);
      intptr_t class_id = cls->untag()->id_;
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
    AutoTraceObjectName(cls, cls->untag()->name());
    WriteFromTo(cls);
    intptr_t class_id = cls->untag()->id_;
    if (class_id == kIllegalCid) {
      s->UnexpectedObject(cls, "Class with illegal cid");
    }
    s->WriteCid(class_id);
    if (s->kind() == Snapshot::kFullCore &&
        RequireCanonicalTypeErasureOfConstants(cls)) {
      s->UnexpectedObject(cls, "Class with non mode agnostic constants");
    }
    if (s->kind() != Snapshot::kFullAOT) {
      s->Write<uint32_t>(cls->untag()->kernel_offset_);
    }
    s->Write<int32_t>(Class::target_instance_size_in_words(cls));
    s->Write<int32_t>(Class::target_next_field_offset_in_words(cls));
    s->Write<int32_t>(Class::target_type_arguments_field_offset_in_words(cls));
    s->Write<int16_t>(cls->untag()->num_type_arguments_);
    s->Write<uint16_t>(cls->untag()->num_native_fields_);
    if (s->kind() != Snapshot::kFullAOT) {
      s->WriteTokenPosition(cls->untag()->token_pos_);
      s->WriteTokenPosition(cls->untag()->end_token_pos_);
      s->WriteCid(cls->untag()->implementor_cid_);
    }
    s->Write<uint32_t>(cls->untag()->state_bits_);

    if (!ClassTable::IsTopLevelCid(class_id)) {
      const auto unboxed_fields_map =
          CalculateTargetUnboxedFieldsBitmap(s, class_id);
      s->WriteUnsigned64(unboxed_fields_map.Value());
    }
  }

  GrowableArray<ClassPtr> predefined_;
  GrowableArray<ClassPtr> objects_;

  bool RequireCanonicalTypeErasureOfConstants(ClassPtr cls) {
    // Do not generate a core snapshot containing constants that would require
    // a canonical erasure of their types if loaded in an isolate running in
    // unsound nullability mode.
    if (cls->untag()->host_type_arguments_field_offset_in_words_ ==
            Class::kNoTypeArguments ||
        cls->untag()->constants() == Array::null()) {
      return false;
    }
    Zone* zone = Thread::Current()->zone();
    const Class& clazz = Class::Handle(zone, cls);
    return clazz.RequireCanonicalTypeErasureOfConstants(zone);
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ClassDeserializationCluster : public DeserializationCluster {
 public:
  ClassDeserializationCluster() : DeserializationCluster("Class") {}
  ~ClassDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    predefined_start_index_ = d->next_index();
    intptr_t count = d->ReadUnsigned();
    ClassTable* table = d->isolate_group()->class_table();
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
      d->AssignRef(d->Allocate(Class::InstanceSize()));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = predefined_start_index_; id < predefined_stop_index_;
         id++) {
      ClassPtr cls = static_cast<ClassPtr>(d.Ref(id));
      d.ReadFromTo(cls);
      intptr_t class_id = d.ReadCid();
      cls->untag()->id_ = class_id;
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      cls->untag()->kernel_offset_ = d.Read<uint32_t>();
#endif
      if (!IsInternalVMdefinedClassId(class_id)) {
        cls->untag()->host_instance_size_in_words_ = d.Read<int32_t>();
        cls->untag()->host_next_field_offset_in_words_ = d.Read<int32_t>();
#if defined(DART_PRECOMPILER)
        // Only one pair is serialized. The target field only exists when
        // DART_PRECOMPILER is defined
        cls->untag()->target_instance_size_in_words_ =
            cls->untag()->host_instance_size_in_words_;
        cls->untag()->target_next_field_offset_in_words_ =
            cls->untag()->host_next_field_offset_in_words_;
#endif  // defined(DART_PRECOMPILER)
      } else {
        d.Read<int32_t>();  // Skip.
        d.Read<int32_t>();  // Skip.
      }
      cls->untag()->host_type_arguments_field_offset_in_words_ =
          d.Read<int32_t>();
#if defined(DART_PRECOMPILER)
      cls->untag()->target_type_arguments_field_offset_in_words_ =
          cls->untag()->host_type_arguments_field_offset_in_words_;
#endif  // defined(DART_PRECOMPILER)
      cls->untag()->num_type_arguments_ = d.Read<int16_t>();
      cls->untag()->num_native_fields_ = d.Read<uint16_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      cls->untag()->token_pos_ = d.ReadTokenPosition();
      cls->untag()->end_token_pos_ = d.ReadTokenPosition();
      cls->untag()->implementor_cid_ = d.ReadCid();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
      cls->untag()->state_bits_ = d.Read<uint32_t>();
      d.ReadUnsigned64();  // Skip unboxed fields bitmap.
    }

    ClassTable* table = d_->isolate_group()->class_table();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ClassPtr cls = static_cast<ClassPtr>(d.Ref(id));
      Deserializer::InitializeHeader(cls, kClassCid, Class::InstanceSize());
      d.ReadFromTo(cls);

      intptr_t class_id = d.ReadCid();
      ASSERT(class_id >= kNumPredefinedCids);
      cls->untag()->id_ = class_id;

#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      cls->untag()->kernel_offset_ = d.Read<uint32_t>();
#endif
      cls->untag()->host_instance_size_in_words_ = d.Read<int32_t>();
      cls->untag()->host_next_field_offset_in_words_ = d.Read<int32_t>();
      cls->untag()->host_type_arguments_field_offset_in_words_ =
          d.Read<int32_t>();
#if defined(DART_PRECOMPILER)
      cls->untag()->target_instance_size_in_words_ =
          cls->untag()->host_instance_size_in_words_;
      cls->untag()->target_next_field_offset_in_words_ =
          cls->untag()->host_next_field_offset_in_words_;
      cls->untag()->target_type_arguments_field_offset_in_words_ =
          cls->untag()->host_type_arguments_field_offset_in_words_;
#endif  // defined(DART_PRECOMPILER)
      cls->untag()->num_type_arguments_ = d.Read<int16_t>();
      cls->untag()->num_native_fields_ = d.Read<uint16_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      cls->untag()->token_pos_ = d.ReadTokenPosition();
      cls->untag()->end_token_pos_ = d.ReadTokenPosition();
      cls->untag()->implementor_cid_ = d.ReadCid();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
      cls->untag()->state_bits_ = d.Read<uint32_t>();

      table->AllocateIndex(class_id);
      table->SetAt(class_id, cls);

      if (!ClassTable::IsTopLevelCid(class_id)) {
        const UnboxedFieldBitmap unboxed_fields_map(d.ReadUnsigned64());
        table->SetUnboxedFieldsMapAt(class_id, unboxed_fields_map);
      }
    }
  }

 private:
  intptr_t predefined_start_index_;
  intptr_t predefined_stop_index_;
};

// Super classes for writing out clusters which contain objects grouped into
// a canonical set (e.g. String, Type, TypeArguments, etc).
// To save space in the snapshot we avoid writing such canonical sets
// explicitly as Array objects into the snapshot and instead utilize a different
// encoding: objects in a cluster representing a canonical set are sorted
// to appear in the same order they appear in the Array representing the set,
// and we additionally write out array of values describing gaps between
// objects.
//
// In some situations not all canonical objects of the some type need to
// be added to the resulting canonical set because they are cached in some
// special way (see Type::Canonicalize as an example, which caches declaration
// types in a special way). In this case subclass can set
// kAllCanonicalObjectsAreIncludedIntoSet to |false| and override
// IsInCanonicalSet filter.
#if !defined(DART_PRECOMPILED_RUNTIME)
template <typename SetType,
          typename HandleType,
          typename PointerType,
          bool kAllCanonicalObjectsAreIncludedIntoSet = true>
class CanonicalSetSerializationCluster : public SerializationCluster {
 protected:
  CanonicalSetSerializationCluster(intptr_t cid,
                                   bool is_canonical,
                                   bool represents_canonical_set,
                                   const char* name,
                                   intptr_t target_instance_size = 0)
      : SerializationCluster(name, cid, target_instance_size, is_canonical),
        represents_canonical_set_(represents_canonical_set) {}

  virtual bool IsInCanonicalSet(Serializer* s, PointerType ptr) {
    // Must override this function if kAllCanonicalObjectsAreIncludedIntoSet
    // is set to |false|.
    ASSERT(kAllCanonicalObjectsAreIncludedIntoSet);
    return true;
  }

  void ReorderObjects(Serializer* s) {
    if (!represents_canonical_set_) {
      return;
    }

    // Sort objects before writing them out so that they appear in the same
    // order as they would appear in a CanonicalStringSet.
    using ZoneCanonicalSet =
        HashTable<typename SetType::Traits, 0, 0, GrowableArrayStorageTraits>;

    // Compute required capacity for the hashtable (to avoid overallocating).
    intptr_t required_capacity = 0;
    for (auto ptr : objects_) {
      if (kAllCanonicalObjectsAreIncludedIntoSet || IsInCanonicalSet(s, ptr)) {
        required_capacity++;
      }
    }
    // Over-allocate capacity so a few inserts can happen at startup without
    // causing a rehash.
    const intptr_t kSpareCapacity = 32;
    required_capacity = static_cast<intptr_t>(
        static_cast<double>(required_capacity + kSpareCapacity) /
        HashTables::kMaxLoadFactor);

    intptr_t num_occupied = 0;

    // Build canonical set out of objects that should belong to it.
    // Objects that don't belong to it are copied to the prefix of objects_.
    ZoneCanonicalSet table(
        s->zone(), HashTables::New<ZoneCanonicalSet>(required_capacity));
    HandleType& element = HandleType::Handle(s->zone());
    for (auto ptr : objects_) {
      if (kAllCanonicalObjectsAreIncludedIntoSet || IsInCanonicalSet(s, ptr)) {
        element ^= ptr;
        intptr_t entry = -1;
        const bool present = table.FindKeyOrDeletedOrUnused(element, &entry);
        ASSERT(!present);
        table.InsertKey(entry, element);
      } else {
        objects_[num_occupied++] = ptr;
      }
    }

    const auto prefix_length = num_occupied;

    // Compute objects_ order and gaps based on canonical set layout.
    auto& arr = table.Release();
    intptr_t last_occupied = ZoneCanonicalSet::kFirstKeyIndex - 1;
    for (intptr_t i = ZoneCanonicalSet::kFirstKeyIndex, length = arr.Length();
         i < length; i++) {
      ObjectPtr v = arr.At(i);
      ASSERT(v != ZoneCanonicalSet::DeletedMarker().ptr());
      if (v != ZoneCanonicalSet::UnusedMarker().ptr()) {
        const intptr_t unused_run_length = (i - 1) - last_occupied;
        gaps_.Add(unused_run_length);
        objects_[num_occupied++] = static_cast<PointerType>(v);
        last_occupied = i;
      }
    }
    ASSERT(num_occupied == objects_.length());
    ASSERT(prefix_length == (objects_.length() - gaps_.length()));
    table_length_ = arr.Length();
  }

  void WriteCanonicalSetLayout(Serializer* s) {
    if (represents_canonical_set_) {
      s->WriteUnsigned(table_length_);
      s->WriteUnsigned(objects_.length() - gaps_.length());
      for (auto gap : gaps_) {
        s->WriteUnsigned(gap);
      }
      target_memory_size_ +=
          compiler::target::Array::InstanceSize(table_length_);
    }
  }

  GrowableArray<PointerType> objects_;

 private:
  const bool represents_canonical_set_;
  GrowableArray<intptr_t> gaps_;
  intptr_t table_length_ = 0;
};
#endif

template <typename SetType, bool kAllCanonicalObjectsAreIncludedIntoSet = true>
class CanonicalSetDeserializationCluster : public DeserializationCluster {
 public:
  CanonicalSetDeserializationCluster(bool is_canonical,
                                     bool is_root_unit,
                                     const char* name)
      : DeserializationCluster(name, is_canonical),
        is_root_unit_(is_root_unit),
        table_(SetType::ArrayHandle::Handle()) {}

  void BuildCanonicalSetFromLayout(Deserializer* d) {
    if (!is_root_unit_ || !is_canonical()) {
      return;
    }

    const auto table_length = d->ReadUnsigned();
    first_element_ = d->ReadUnsigned();
    const intptr_t count = stop_index_ - (start_index_ + first_element_);
    auto table = StartDeserialization(d, table_length, count);
    for (intptr_t i = start_index_ + first_element_; i < stop_index_; i++) {
      table.FillGap(d->ReadUnsigned());
      table.WriteElement(d, d->Ref(i));
    }
    table_ = table.Finish();
  }

 protected:
  const bool is_root_unit_;
  intptr_t first_element_;
  typename SetType::ArrayHandle& table_;

  void VerifyCanonicalSet(Deserializer* d,
                          const Array& refs,
                          const typename SetType::ArrayHandle& current_table) {
#if defined(DEBUG)
    // First check that we are not overwriting a table and loosing information.
    if (!current_table.IsNull()) {
      SetType current_set(d->zone(), current_table.ptr());
      ASSERT(current_set.NumOccupied() == 0);
      current_set.Release();
    }

    // Now check that manually created table behaves correctly as a canonical
    // set.
    SetType canonical_set(d->zone(), table_.ptr());
    Object& key = Object::Handle();
    for (intptr_t i = start_index_ + first_element_; i < stop_index_; i++) {
      key = refs.At(i);
      ASSERT(canonical_set.GetOrNull(key) != Object::null());
    }
    canonical_set.Release();
#endif  // defined(DEBUG)
  }

 private:
  struct DeserializationFinger {
    typename SetType::ArrayPtr table;
    intptr_t current_index;
    ObjectPtr gap_element;

    void FillGap(int length) {
      for (intptr_t j = 0; j < length; j++) {
        table->untag()->data()[current_index + j] = gap_element;
      }
      current_index += length;
    }

    void WriteElement(Deserializer* d, ObjectPtr object) {
      table->untag()->data()[current_index++] = object;
    }

    typename SetType::ArrayPtr Finish() {
      if (table != SetType::ArrayHandle::null()) {
        FillGap(Smi::Value(table->untag()->length()) - current_index);
      }
      auto result = table;
      table = SetType::ArrayHandle::null();
      return result;
    }
  };

  static DeserializationFinger StartDeserialization(Deserializer* d,
                                                    intptr_t length,
                                                    intptr_t count) {
    const intptr_t instance_size = SetType::ArrayHandle::InstanceSize(length);
    typename SetType::ArrayPtr table =
        static_cast<typename SetType::ArrayPtr>(d->Allocate(instance_size));
    Deserializer::InitializeHeader(table, SetType::Storage::ArrayCid,
                                   instance_size);
    InitTypeArgsOrNext(table);
    table->untag()->length_ = Smi::New(length);
    for (intptr_t i = 0; i < SetType::kFirstKeyIndex; i++) {
      table->untag()->data()[i] = Smi::New(0);
    }
    table->untag()->data()[SetType::kOccupiedEntriesIndex] = Smi::New(count);
    return {table, SetType::kFirstKeyIndex, SetType::UnusedMarker().ptr()};
  }

  static void InitTypeArgsOrNext(ArrayPtr table) {
    table->untag()->type_arguments_ = TypeArguments::null();
  }
  static void InitTypeArgsOrNext(WeakArrayPtr table) {
    table->untag()->next_seen_by_gc_ = WeakArray::null();
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeParametersSerializationCluster : public SerializationCluster {
 public:
  TypeParametersSerializationCluster()
      : SerializationCluster("TypeParameters",
                             kTypeParametersCid,
                             compiler::target::TypeParameters::InstanceSize()) {
  }
  ~TypeParametersSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypeParametersPtr type_params = TypeParameters::RawCast(object);
    objects_.Add(type_params);
    PushFromTo(type_params);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      TypeParametersPtr type_params = objects_[i];
      s->AssignRef(type_params);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypeParametersPtr type_params = objects_[i];
      AutoTraceObject(type_params);
      WriteFromTo(type_params);
    }
  }

 private:
  GrowableArray<TypeParametersPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeParametersDeserializationCluster : public DeserializationCluster {
 public:
  TypeParametersDeserializationCluster()
      : DeserializationCluster("TypeParameters") {}
  ~TypeParametersDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, TypeParameters::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypeParametersPtr type_params = static_cast<TypeParametersPtr>(d.Ref(id));
      Deserializer::InitializeHeader(type_params, kTypeParametersCid,
                                     TypeParameters::InstanceSize());
      d.ReadFromTo(type_params);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeArgumentsSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalTypeArgumentsSet,
                                              TypeArguments,
                                              TypeArgumentsPtr> {
 public:
  TypeArgumentsSerializationCluster(bool is_canonical,
                                    bool represents_canonical_set)
      : CanonicalSetSerializationCluster(kTypeArgumentsCid,
                                         is_canonical,
                                         represents_canonical_set,
                                         "TypeArguments") {}
  ~TypeArgumentsSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypeArgumentsPtr type_args = TypeArguments::RawCast(object);
    objects_.Add(type_args);

    s->Push(type_args->untag()->instantiations());
    const intptr_t length = Smi::Value(type_args->untag()->length());
    for (intptr_t i = 0; i < length; i++) {
      s->Push(type_args->untag()->element(i));
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);
    for (intptr_t i = 0; i < count; i++) {
      TypeArgumentsPtr type_args = objects_[i];
      s->AssignRef(type_args);
      AutoTraceObject(type_args);
      const intptr_t length = Smi::Value(type_args->untag()->length());
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::TypeArguments::InstanceSize(length);
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      TypeArgumentsPtr type_args = objects_[i];
      AutoTraceObject(type_args);
      const intptr_t length = Smi::Value(type_args->untag()->length());
      s->WriteUnsigned(length);
      intptr_t hash = Smi::Value(type_args->untag()->hash());
      s->Write<int32_t>(hash);
      const intptr_t nullability =
          Smi::Value(type_args->untag()->nullability());
      s->WriteUnsigned(nullability);
      WriteField(type_args, instantiations());
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(type_args->untag()->element(j), j);
      }
    }
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeArgumentsDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalTypeArgumentsSet> {
 public:
  explicit TypeArgumentsDeserializationCluster(bool is_canonical,
                                               bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "TypeArguments") {}
  ~TypeArgumentsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(TypeArguments::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypeArgumentsPtr type_args = static_cast<TypeArgumentsPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(type_args, kTypeArgumentsCid,
                                     TypeArguments::InstanceSize(length),
                                     mark_canonical);
      type_args->untag()->length_ = Smi::New(length);
      type_args->untag()->hash_ = Smi::New(d.Read<int32_t>());
      type_args->untag()->nullability_ = Smi::New(d.ReadUnsigned());
      type_args->untag()->instantiations_ = static_cast<ArrayPtr>(d.ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        type_args->untag()->types()[j] =
            static_cast<AbstractTypePtr>(d.ReadRef());
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(
          d, refs, Array::Handle(object_store->canonical_type_arguments()));
      object_store->set_canonical_type_arguments(table_);
    } else if (!primary && is_canonical()) {
      TypeArguments& type_arg = TypeArguments::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        type_arg ^= refs.At(i);
        type_arg = type_arg.Canonicalize(d->thread());
        refs.SetAt(i, type_arg);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class PatchClassSerializationCluster : public SerializationCluster {
 public:
  PatchClassSerializationCluster()
      : SerializationCluster("PatchClass",
                             kPatchClassCid,
                             compiler::target::PatchClass::InstanceSize()) {}
  ~PatchClassSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    PatchClassPtr cls = PatchClass::RawCast(object);
    objects_.Add(cls);
    PushFromTo(cls);
  }

  void WriteAlloc(Serializer* s) {
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
        s->Write<int32_t>(cls->untag()->kernel_library_index_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, PatchClass::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      PatchClassPtr cls = static_cast<PatchClassPtr>(d.Ref(id));
      Deserializer::InitializeHeader(cls, kPatchClassCid,
                                     PatchClass::InstanceSize());
      d.ReadFromTo(cls);
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      cls->untag()->kernel_library_index_ = d.Read<int32_t>();
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FunctionSerializationCluster : public SerializationCluster {
 public:
  FunctionSerializationCluster()
      : SerializationCluster("Function",
                             kFunctionCid,
                             compiler::target::Function::InstanceSize()) {}
  ~FunctionSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    Snapshot::Kind kind = s->kind();
    FunctionPtr func = Function::RawCast(object);
    objects_.Add(func);

    PushFromTo(func);
    if (kind == Snapshot::kFullAOT) {
      s->Push(func->untag()->code());
    } else if (kind == Snapshot::kFullJIT) {
      NOT_IN_PRECOMPILED(s->Push(func->untag()->unoptimized_code()));
      s->Push(func->untag()->code());
      s->Push(func->untag()->ic_data_array());
    }
    if (kind != Snapshot::kFullAOT) {
      NOT_IN_PRECOMPILED(s->Push(func->untag()->positional_parameter_names()));
    }
  }

  void WriteAlloc(Serializer* s) {
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
#if defined(DART_PRECOMPILER)
        CodePtr code = func->untag()->code();
        const auto code_index = s->GetCodeIndex(code);
        s->WriteUnsigned(code_index);
        s->AttributePropertyRef(code, "code_");
#else
        UNREACHABLE();
#endif
      } else if (s->kind() == Snapshot::kFullJIT) {
        NOT_IN_PRECOMPILED(WriteCompressedField(func, unoptimized_code));
        WriteCompressedField(func, code);
        WriteCompressedField(func, ic_data_array);
      }

      if (kind != Snapshot::kFullAOT) {
        NOT_IN_PRECOMPILED(
            WriteCompressedField(func, positional_parameter_names));
      }

#if defined(DART_PRECOMPILER) && !defined(PRODUCT)
      TokenPosition token_pos = func->untag()->token_pos_;
      if (kind == Snapshot::kFullAOT) {
        // We use then token_pos property to store the line number
        // in AOT snapshots.
        intptr_t line = -1;
        const Function& function = Function::Handle(func);
        const Script& script = Script::Handle(function.script());
        if (!script.IsNull()) {
          script.GetTokenLocation(token_pos, &line, nullptr);
        }
        token_pos = line == -1 ? TokenPosition::kNoSource
                               : TokenPosition::Deserialize(line);
      }
      s->WriteTokenPosition(token_pos);
#else
      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(func->untag()->token_pos_);
      }
#endif
      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(func->untag()->end_token_pos_);
        s->Write<uint32_t>(func->untag()->kernel_offset_);
        s->Write<uint32_t>(func->untag()->packed_fields_);
      }
      s->Write<uint32_t>(func->untag()->kind_tag_);
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

template <bool need_entry_point_for_non_discarded>
DART_FORCE_INLINE static CodePtr GetCodeAndEntryPointByIndex(
    const Deserializer* d,
    intptr_t code_index,
    uword* entry_point) {
  code_index -= 1;  // 0 is reserved for LazyCompile stub.

  // In root unit and VM isolate snapshot code_indices are self-contained
  // they point into instruction table and/or into the code cluster.
  // In non-root units we might also refer to code objects from the
  // parent unit which means code_index is biased by num_base_objects_
  const intptr_t base = d->is_non_root_unit() ? d->num_base_objects() : 0;
  if (code_index < base) {
    CodePtr code = static_cast<CodePtr>(d->Ref(code_index));
    if (need_entry_point_for_non_discarded) {
      *entry_point = Code::EntryPointOf(code);
    }
    return code;
  }
  code_index -= base;

  // At this point code_index is referring to a code object which is either
  // discarded or exists in the Code cluster. Non-discarded Code objects
  // are associated with the tail of the instruction table and have the
  // same order there and in the Code cluster. This means that
  // subtracting first_entry_with_code yields index into the Code cluster.
  // This also works for deferred code objects in root unit's snapshot
  // due to the choice of encoding (see Serializer::GetCodeIndex).
  const intptr_t first_entry_with_code =
      d->instructions_table().rodata()->first_entry_with_code;
  if (code_index < first_entry_with_code) {
    *entry_point = d->instructions_table().EntryPointAt(code_index);
    return StubCode::UnknownDartCode().ptr();
  } else {
    const intptr_t cluster_index = code_index - first_entry_with_code;
    CodePtr code =
        static_cast<CodePtr>(d->Ref(d->code_start_index() + cluster_index));
    if (need_entry_point_for_non_discarded) {
      *entry_point = Code::EntryPointOf(code);
    }
    return code;
  }
}

CodePtr Deserializer::GetCodeByIndex(intptr_t code_index,
                                     uword* entry_point) const {
  // See Serializer::GetCodeIndex for how code_index is encoded.
  if (code_index == 0) {
    return StubCode::LazyCompile().ptr();
  } else if (FLAG_precompiled_mode) {
    return GetCodeAndEntryPointByIndex<
        /*need_entry_point_for_non_discarded=*/false>(this, code_index,
                                                      entry_point);
  } else {
    // -1 below because 0 is reserved for LazyCompile stub.
    const intptr_t ref = code_start_index_ + code_index - 1;
    ASSERT(code_start_index_ <= ref && ref < code_stop_index_);
    return static_cast<CodePtr>(Ref(ref));
  }
}

intptr_t Deserializer::CodeIndexToClusterIndex(const InstructionsTable& table,
                                               intptr_t code_index) {
  // Note: code indices we are interpreting here originate from the root
  // loading unit which means base is equal to 0.
  // See comments which clarify the connection between code_index and
  // index into the Code cluster.
  ASSERT(FLAG_precompiled_mode);
  const intptr_t first_entry_with_code = table.rodata()->first_entry_with_code;
  return code_index - 1 - first_entry_with_code;
}

uword Deserializer::GetEntryPointByCodeIndex(intptr_t code_index) const {
  // See Deserializer::GetCodeByIndex which this code repeats.
  ASSERT(FLAG_precompiled_mode);
  uword entry_point = 0;
  GetCodeAndEntryPointByIndex</*need_entry_point_for_non_discarded=*/true>(
      this, code_index, &entry_point);
  return entry_point;
}

class FunctionDeserializationCluster : public DeserializationCluster {
 public:
  FunctionDeserializationCluster() : DeserializationCluster("Function") {}
  ~FunctionDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Function::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    Snapshot::Kind kind = d_->kind();

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      FunctionPtr func = static_cast<FunctionPtr>(d.Ref(id));
      Deserializer::InitializeHeader(func, kFunctionCid,
                                     Function::InstanceSize());
      d.ReadFromTo(func);

#if defined(DEBUG)
      func->untag()->entry_point_ = 0;
      func->untag()->unchecked_entry_point_ = 0;
#endif

#if defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(kind == Snapshot::kFullAOT);
      const intptr_t code_index = d.ReadUnsigned();
      uword entry_point = 0;
      CodePtr code = d_->GetCodeByIndex(code_index, &entry_point);
      func->untag()->code_ = code;
      if (entry_point != 0) {
        func->untag()->entry_point_ = entry_point;
        func->untag()->unchecked_entry_point_ = entry_point;
      }
#else
      ASSERT(kind != Snapshot::kFullAOT);
      if (kind == Snapshot::kFullJIT) {
        func->untag()->unoptimized_code_ = static_cast<CodePtr>(d.ReadRef());
        func->untag()->code_ = static_cast<CodePtr>(d.ReadRef());
        func->untag()->ic_data_array_ = static_cast<ArrayPtr>(d.ReadRef());
      }
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(kind != Snapshot::kFullAOT);
      func->untag()->positional_parameter_names_ =
          static_cast<ArrayPtr>(d.ReadRef());
#endif
#if !defined(DART_PRECOMPILED_RUNTIME) ||                                      \
    (defined(DART_PRECOMPILED_RUNTIME) && !defined(PRODUCT))
      func->untag()->token_pos_ = d.ReadTokenPosition();
#endif
#if !defined(DART_PRECOMPILED_RUNTIME)
      func->untag()->end_token_pos_ = d.ReadTokenPosition();
      func->untag()->kernel_offset_ = d.Read<uint32_t>();
      func->untag()->unboxed_parameters_info_.Reset();
      func->untag()->packed_fields_ = d.Read<uint32_t>();
#endif

      func->untag()->kind_tag_ = d.Read<uint32_t>();
#if !defined(DART_PRECOMPILED_RUNTIME)
      func->untag()->usage_counter_ = 0;
      func->untag()->optimized_instruction_count_ = 0;
      func->untag()->optimized_call_site_count_ = 0;
      func->untag()->deoptimization_counter_ = 0;
      func->untag()->state_bits_ = 0;
      func->untag()->inlining_depth_ = 0;
#endif
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (d->kind() == Snapshot::kFullAOT) {
      Function& func = Function::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        func ^= refs.At(i);
        auto const code = func.ptr()->untag()->code();
        ASSERT(code->IsCode());
        if (!Code::IsUnknownDartCode(code)) {
          uword entry_point = code->untag()->entry_point_;
          ASSERT(entry_point != 0);
          func.ptr()->untag()->entry_point_ = entry_point;
          uword unchecked_entry_point = code->untag()->unchecked_entry_point_;
          ASSERT(unchecked_entry_point != 0);
          func.ptr()->untag()->unchecked_entry_point_ = unchecked_entry_point;
        }
      }
    } else if (d->kind() == Snapshot::kFullJIT) {
      Function& func = Function::Handle(d->zone());
      Code& code = Code::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        func ^= refs.At(i);
        code = func.CurrentCode();
        if (func.HasCode() && !code.IsDisabled()) {
          func.SetInstructionsSafe(code);  // Set entrypoint.
          func.SetWasCompiled(true);
        } else {
          func.ClearCodeSafe();  // Set code and entrypoint to lazy compile stub
        }
      }
    } else {
      Function& func = Function::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        func ^= refs.At(i);
        func.ClearCodeSafe();  // Set code and entrypoint to lazy compile stub.
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureDataSerializationCluster : public SerializationCluster {
 public:
  ClosureDataSerializationCluster()
      : SerializationCluster("ClosureData",
                             kClosureDataCid,
                             compiler::target::ClosureData::InstanceSize()) {}
  ~ClosureDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ClosureDataPtr data = ClosureData::RawCast(object);
    objects_.Add(data);

    if (s->kind() != Snapshot::kFullAOT) {
      s->Push(data->untag()->context_scope());
    }
    s->Push(data->untag()->parent_function());
    s->Push(data->untag()->closure());
  }

  void WriteAlloc(Serializer* s) {
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
        WriteCompressedField(data, context_scope);
      }
      WriteCompressedField(data, parent_function);
      WriteCompressedField(data, closure);
      s->WriteUnsigned(static_cast<uint32_t>(data->untag()->packed_fields_));
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, ClosureData::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ClosureDataPtr data = static_cast<ClosureDataPtr>(d.Ref(id));
      Deserializer::InitializeHeader(data, kClosureDataCid,
                                     ClosureData::InstanceSize());
      if (d_->kind() == Snapshot::kFullAOT) {
        data->untag()->context_scope_ = ContextScope::null();
      } else {
        data->untag()->context_scope_ =
            static_cast<ContextScopePtr>(d.ReadRef());
      }
      data->untag()->parent_function_ = static_cast<FunctionPtr>(d.ReadRef());
      data->untag()->closure_ = static_cast<ClosurePtr>(d.ReadRef());
      data->untag()->packed_fields_ = d.ReadUnsigned<uint32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FfiTrampolineDataSerializationCluster : public SerializationCluster {
 public:
  FfiTrampolineDataSerializationCluster()
      : SerializationCluster(
            "FfiTrampolineData",
            kFfiTrampolineDataCid,
            compiler::target::FfiTrampolineData::InstanceSize()) {}
  ~FfiTrampolineDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    FfiTrampolineDataPtr data = FfiTrampolineData::RawCast(object);
    objects_.Add(data);
    PushFromTo(data);
  }

  void WriteAlloc(Serializer* s) {
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
      s->Write<int32_t>(data->untag()->callback_id_);
      s->Write<uint8_t>(data->untag()->callback_kind_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, FfiTrampolineData::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      FfiTrampolineDataPtr data = static_cast<FfiTrampolineDataPtr>(d.Ref(id));
      Deserializer::InitializeHeader(data, kFfiTrampolineDataCid,
                                     FfiTrampolineData::InstanceSize());
      d.ReadFromTo(data);
      data->untag()->callback_id_ = d.Read<int32_t>();
      data->untag()->callback_kind_ = d.Read<uint8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FieldSerializationCluster : public SerializationCluster {
 public:
  FieldSerializationCluster()
      : SerializationCluster("Field",
                             kFieldCid,
                             compiler::target::Field::InstanceSize()) {}
  ~FieldSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    FieldPtr field = Field::RawCast(object);
    objects_.Add(field);

    Snapshot::Kind kind = s->kind();

    s->Push(field->untag()->name());
    s->Push(field->untag()->owner());
    s->Push(field->untag()->type());
    // Write out the initializer function
    s->Push(field->untag()->initializer_function());

    if (kind != Snapshot::kFullAOT) {
      s->Push(field->untag()->guarded_list_length());
    }
    if (kind == Snapshot::kFullJIT) {
      s->Push(field->untag()->dependent_code());
    }
    // Write out either the initial static value or field offset.
    if (Field::StaticBit::decode(field->untag()->kind_bits_)) {
      s->Push(field->untag()->host_offset_or_field_id());
    } else {
      s->Push(Smi::New(Field::TargetOffsetOf(field)));
    }
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(field, field->untag()->name());

      WriteCompressedField(field, name);
      WriteCompressedField(field, owner);
      WriteCompressedField(field, type);
      // Write out the initializer function and initial value if not in AOT.
      WriteCompressedField(field, initializer_function);
      if (kind != Snapshot::kFullAOT) {
        WriteCompressedField(field, guarded_list_length);
      }
      if (kind == Snapshot::kFullJIT) {
        WriteCompressedField(field, dependent_code);
      }

      if (kind != Snapshot::kFullAOT) {
        s->WriteTokenPosition(field->untag()->token_pos_);
        s->WriteTokenPosition(field->untag()->end_token_pos_);
        s->WriteCid(field->untag()->guarded_cid_);
        s->WriteCid(field->untag()->is_nullable_);
        s->Write<int8_t>(field->untag()->static_type_exactness_state_);
        s->Write<uint32_t>(field->untag()->kernel_offset_);
      }
      s->Write<uint16_t>(field->untag()->kind_bits_);

      // Write out either the initial static value or field offset.
      if (Field::StaticBit::decode(field->untag()->kind_bits_)) {
        WriteFieldValue("id", field->untag()->host_offset_or_field_id());
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Field::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
#if !defined(DART_PRECOMPILED_RUNTIME)
    Snapshot::Kind kind = d_->kind();
#endif
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      FieldPtr field = static_cast<FieldPtr>(d.Ref(id));
      Deserializer::InitializeHeader(field, kFieldCid, Field::InstanceSize());
      d.ReadFromTo(field);
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      field->untag()->guarded_list_length_ = static_cast<SmiPtr>(d.ReadRef());
      if (kind == Snapshot::kFullJIT) {
        field->untag()->dependent_code_ =
            static_cast<WeakArrayPtr>(d.ReadRef());
      }
      field->untag()->token_pos_ = d.ReadTokenPosition();
      field->untag()->end_token_pos_ = d.ReadTokenPosition();
      field->untag()->guarded_cid_ = d.ReadCid();
      field->untag()->is_nullable_ = d.ReadCid();
      const int8_t static_type_exactness_state = d.Read<int8_t>();
#if defined(TARGET_ARCH_X64)
      field->untag()->static_type_exactness_state_ =
          static_type_exactness_state;
#else
      // We might produce core snapshots using X64 VM and then consume
      // them in IA32 or ARM VM. In which case we need to simply ignore
      // static type exactness state written into snapshot because non-X64
      // builds don't have this feature enabled.
      // TODO(dartbug.com/34170) Support other architectures.
      USE(static_type_exactness_state);
      field->untag()->static_type_exactness_state_ =
          StaticTypeExactnessState::NotTracking().Encode();
#endif  // defined(TARGET_ARCH_X64)
      field->untag()->kernel_offset_ = d.Read<uint32_t>();
#endif
      field->untag()->kind_bits_ = d.Read<uint16_t>();

      field->untag()->host_offset_or_field_id_ =
          static_cast<SmiPtr>(d.ReadRef());
#if !defined(DART_PRECOMPILED_RUNTIME)
      field->untag()->target_offset_ =
          Smi::Value(field->untag()->host_offset_or_field_id());
#endif  //  !defined(DART_PRECOMPILED_RUNTIME)
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    Field& field = Field::Handle(d->zone());
    if (!IsolateGroup::Current()->use_field_guards()) {
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        field ^= refs.At(i);
        field.set_guarded_cid_unsafe(kDynamicCid);
        field.set_is_nullable_unsafe(true);
        field.set_guarded_list_length_unsafe(Field::kNoFixedLength);
        field.set_guarded_list_length_in_object_offset_unsafe(
            Field::kUnknownLengthOffset);
        field.set_static_type_exactness_state_unsafe(
            StaticTypeExactnessState::NotTracking());
      }
    } else {
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        field ^= refs.At(i);
        field.InitializeGuardedListLengthInObjectOffset(/*unsafe=*/true);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ScriptSerializationCluster : public SerializationCluster {
 public:
  ScriptSerializationCluster()
      : SerializationCluster("Script",
                             kScriptCid,
                             compiler::target::Script::InstanceSize()) {}
  ~ScriptSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ScriptPtr script = Script::RawCast(object);
    objects_.Add(script);
    auto* from = script->untag()->from();
    auto* to = script->untag()->to_snapshot(s->kind());
    for (auto* p = from; p <= to; p++) {
      const intptr_t offset =
          reinterpret_cast<uword>(p) - reinterpret_cast<uword>(script->untag());
      const ObjectPtr obj = p->Decompress(script->heap_base());
      if (offset == Script::line_starts_offset()) {
        // Line starts are delta encoded.
        s->Push(obj, kDeltaEncodedTypedDataCid);
      } else {
        s->Push(obj);
      }
    }
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(script, script->untag()->url());
      WriteFromTo(script);
      if (s->kind() != Snapshot::kFullAOT) {
        // Clear out the max position cache in snapshots to ensure no
        // differences in the snapshot due to triggering caching vs. not.
        int32_t written_flags =
            UntaggedScript::CachedMaxPositionBitField::update(
                0, script->untag()->flags_and_max_position_);
        written_flags = UntaggedScript::HasCachedMaxPositionBit::update(
            false, written_flags);
        s->Write<int32_t>(written_flags);
      }
      s->Write<int32_t>(script->untag()->kernel_script_index_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Script::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ScriptPtr script = static_cast<ScriptPtr>(d.Ref(id));
      Deserializer::InitializeHeader(script, kScriptCid,
                                     Script::InstanceSize());
      d.ReadFromTo(script);
#if !defined(DART_PRECOMPILED_RUNTIME)
      script->untag()->flags_and_max_position_ = d.Read<int32_t>();
#endif
      script->untag()->kernel_script_index_ = d.Read<int32_t>();
      script->untag()->load_timestamp_ = 0;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LibrarySerializationCluster : public SerializationCluster {
 public:
  LibrarySerializationCluster()
      : SerializationCluster("Library",
                             kLibraryCid,
                             compiler::target::Library::InstanceSize()) {}
  ~LibrarySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LibraryPtr lib = Library::RawCast(object);
    objects_.Add(lib);
    PushFromTo(lib);
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(lib, lib->untag()->url());
      WriteFromTo(lib);
      s->Write<int32_t>(lib->untag()->index_);
      s->Write<uint16_t>(lib->untag()->num_imports_);
      s->Write<int8_t>(lib->untag()->load_state_);
      s->Write<uint8_t>(lib->untag()->flags_);
      if (s->kind() != Snapshot::kFullAOT) {
        s->Write<uint32_t>(lib->untag()->kernel_library_index_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Library::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      LibraryPtr lib = static_cast<LibraryPtr>(d.Ref(id));
      Deserializer::InitializeHeader(lib, kLibraryCid, Library::InstanceSize());
      d.ReadFromTo(lib);
      lib->untag()->native_entry_resolver_ = nullptr;
      lib->untag()->native_entry_symbol_resolver_ = nullptr;
      lib->untag()->index_ = d.Read<int32_t>();
      lib->untag()->num_imports_ = d.Read<uint16_t>();
      lib->untag()->load_state_ = d.Read<int8_t>();
      lib->untag()->flags_ =
          UntaggedLibrary::InFullSnapshotBit::update(true, d.Read<uint8_t>());
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d_->kind() != Snapshot::kFullAOT);
      lib->untag()->kernel_library_index_ = d.Read<uint32_t>();
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class NamespaceSerializationCluster : public SerializationCluster {
 public:
  NamespaceSerializationCluster()
      : SerializationCluster("Namespace",
                             kNamespaceCid,
                             compiler::target::Namespace::InstanceSize()) {}
  ~NamespaceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    NamespacePtr ns = Namespace::RawCast(object);
    objects_.Add(ns);
    PushFromTo(ns);
  }

  void WriteAlloc(Serializer* s) {
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Namespace::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      NamespacePtr ns = static_cast<NamespacePtr>(d.Ref(id));
      Deserializer::InitializeHeader(ns, kNamespaceCid,
                                     Namespace::InstanceSize());
      d.ReadFromTo(ns);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
// KernelProgramInfo objects are not written into a full AOT snapshot.
class KernelProgramInfoSerializationCluster : public SerializationCluster {
 public:
  KernelProgramInfoSerializationCluster()
      : SerializationCluster(
            "KernelProgramInfo",
            kKernelProgramInfoCid,
            compiler::target::KernelProgramInfo::InstanceSize()) {}
  ~KernelProgramInfoSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    KernelProgramInfoPtr info = KernelProgramInfo::RawCast(object);
    objects_.Add(info);
    PushFromTo(info);
  }

  void WriteAlloc(Serializer* s) {
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, KernelProgramInfo::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      KernelProgramInfoPtr info = static_cast<KernelProgramInfoPtr>(d.Ref(id));
      Deserializer::InitializeHeader(info, kKernelProgramInfoCid,
                                     KernelProgramInfo::InstanceSize());
      d.ReadFromTo(info);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    Array& array = Array::Handle(d->zone());
    KernelProgramInfo& info = KernelProgramInfo::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
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
      : SerializationCluster("Code", kCodeCid), array_(Array::Handle()) {}
  ~CodeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    CodePtr code = Code::RawCast(object);

    const bool is_deferred = !s->InCurrentLoadingUnitOrRoot(code);
    if (is_deferred) {
      s->RecordDeferredCode(code);
    } else {
      objects_.Add(code);
    }

    // Even if this code object is itself deferred we still need to scan
    // the pool for references to other code objects (which might reside
    // in the current loading unit).
    ObjectPoolPtr pool = code->untag()->object_pool_;
    if (s->kind() == Snapshot::kFullAOT) {
      TracePool(s, pool, /*only_call_targets=*/is_deferred);
    } else {
      if (s->InCurrentLoadingUnitOrRoot(pool)) {
        s->Push(pool);
      } else {
        TracePool(s, pool, /*only_call_targets=*/true);
      }
    }

    if (s->kind() == Snapshot::kFullJIT) {
      s->Push(code->untag()->deopt_info_array_);
      s->Push(code->untag()->static_calls_target_table_);
      s->Push(code->untag()->compressed_stackmaps_);
    } else if (s->kind() == Snapshot::kFullAOT) {
      // Note: we don't trace compressed_stackmaps_ because we are going to emit
      // a separate mapping table into RO data which is not going to be a real
      // heap object.
#if defined(DART_PRECOMPILER)
      auto const calls_array = code->untag()->static_calls_target_table_;
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

    if (Code::IsDiscarded(code)) {
      ASSERT(s->kind() == Snapshot::kFullAOT && FLAG_dwarf_stack_traces_mode &&
             !FLAG_retain_code_objects);
      // Only object pool and static call table entries and the compressed
      // stack maps should be pushed.
      return;
    }

    s->Push(code->untag()->owner_);
    s->Push(code->untag()->exception_handlers_);
    s->Push(code->untag()->pc_descriptors_);
    s->Push(code->untag()->catch_entry_);
    if (!FLAG_precompiled_mode || !FLAG_dwarf_stack_traces_mode) {
      s->Push(code->untag()->inlined_id_to_function_);
      if (s->InCurrentLoadingUnitOrRoot(code->untag()->code_source_map_)) {
        s->Push(code->untag()->code_source_map_);
      }
    }
#if !defined(PRODUCT)
    s->Push(code->untag()->return_address_metadata_);
    if (FLAG_code_comments) {
      s->Push(code->untag()->comments_);
    }
#endif
  }

  void TracePool(Serializer* s, ObjectPoolPtr pool, bool only_call_targets) {
    if (pool == ObjectPool::null()) {
      return;
    }

    const intptr_t length = pool->untag()->length_;
    uint8_t* entry_bits = pool->untag()->entry_bits();
    for (intptr_t i = 0; i < length; i++) {
      auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
      if (entry_type == ObjectPool::EntryType::kTaggedObject) {
        const ObjectPtr target = pool->untag()->data()[i].raw_obj_;
        // A field is a call target because its initializer may be called
        // indirectly by passing the field to the runtime. A const closure
        // is a call target because its function may be called indirectly
        // via a closure call.
        intptr_t cid = target->GetClassIdMayBeSmi();
        if (!only_call_targets || (cid == kCodeCid) || (cid == kFunctionCid) ||
            (cid == kFieldCid) || (cid == kClosureCid)) {
          s->Push(target);
        } else if (cid >= kNumPredefinedCids) {
          s->Push(s->isolate_group()->class_table()->At(cid));
        }
      }
    }
  }

  struct CodeOrderInfo {
    CodePtr code;
    intptr_t not_discarded;  // 1 if this code was not discarded and
                             // 0 otherwise.
    intptr_t instructions_id;
  };

  // We sort code objects in such a way that code objects with the same
  // instructions are grouped together and ensure that all instructions
  // without associated code objects are grouped together at the beginning of
  // the code section. InstructionsTable encoding assumes that all
  // instructions with non-discarded Code objects are grouped at the end.
  //
  // Note that in AOT mode we expect that all Code objects pointing to
  // the same instructions are deduplicated, as in bare instructions mode
  // there is no way to identify which specific Code object (out of those
  // which point to the specific instructions range) actually corresponds
  // to a particular frame.
  static int CompareCodeOrderInfo(CodeOrderInfo const* a,
                                  CodeOrderInfo const* b) {
    if (a->not_discarded < b->not_discarded) return -1;
    if (a->not_discarded > b->not_discarded) return 1;
    if (a->instructions_id < b->instructions_id) return -1;
    if (a->instructions_id > b->instructions_id) return 1;
    return 0;
  }

  static void Insert(Serializer* s,
                     GrowableArray<CodeOrderInfo>* order_list,
                     IntMap<intptr_t>* order_map,
                     CodePtr code) {
    InstructionsPtr instr = code->untag()->instructions_;
    intptr_t key = static_cast<intptr_t>(instr);
    intptr_t instructions_id = 0;

    if (order_map->HasKey(key)) {
      // We are expected to merge code objects which point to the same
      // instructions in the precompiled mode.
      RELEASE_ASSERT(!FLAG_precompiled_mode);
      instructions_id = order_map->Lookup(key);
    } else {
      instructions_id = order_map->Length() + 1;
      order_map->Insert(key, instructions_id);
    }
    CodeOrderInfo info;
    info.code = code;
    info.instructions_id = instructions_id;
    info.not_discarded = Code::IsDiscarded(code) ? 0 : 1;
    order_list->Add(info);
  }

  static void Sort(Serializer* s, GrowableArray<CodePtr>* codes) {
    GrowableArray<CodeOrderInfo> order_list;
    IntMap<intptr_t> order_map;
    for (intptr_t i = 0; i < codes->length(); i++) {
      Insert(s, &order_list, &order_map, (*codes)[i]);
    }
    order_list.Sort(CompareCodeOrderInfo);
    ASSERT(order_list.length() == codes->length());
    for (intptr_t i = 0; i < order_list.length(); i++) {
      (*codes)[i] = order_list[i].code;
    }
  }

  static void Sort(Serializer* s, GrowableArray<Code*>* codes) {
    GrowableArray<CodeOrderInfo> order_list;
    IntMap<intptr_t> order_map;
    for (intptr_t i = 0; i < codes->length(); i++) {
      Insert(s, &order_list, &order_map, (*codes)[i]->ptr());
    }
    order_list.Sort(CompareCodeOrderInfo);
    ASSERT(order_list.length() == codes->length());
    for (intptr_t i = 0; i < order_list.length(); i++) {
      *(*codes)[i] = order_list[i].code;
    }
  }

  intptr_t NonDiscardedCodeCount() {
    intptr_t count = 0;
    for (auto code : objects_) {
      if (!Code::IsDiscarded(code)) {
        count++;
      }
    }
    return count;
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t non_discarded_count = NonDiscardedCodeCount();
    const intptr_t count = objects_.length();
    ASSERT(count == non_discarded_count || (s->kind() == Snapshot::kFullAOT));

    first_ref_ = s->next_ref_index();
    s->WriteUnsigned(non_discarded_count);
    for (auto code : objects_) {
      if (!Code::IsDiscarded(code)) {
        WriteAlloc(s, code);
      } else {
        // Mark discarded code unreachable, so that we could later
        // assign artificial references to it.
        s->heap()->SetObjectId(code, kUnreachableReference);
      }
    }

    s->WriteUnsigned(deferred_objects_.length());
    first_deferred_ref_ = s->next_ref_index();
    for (auto code : deferred_objects_) {
      ASSERT(!Code::IsDiscarded(code));
      WriteAlloc(s, code);
    }
    last_ref_ = s->next_ref_index() - 1;
  }

  void WriteAlloc(Serializer* s, CodePtr code) {
    ASSERT(!Code::IsDiscarded(code));
    s->AssignRef(code);
    AutoTraceObjectName(code, MakeDisambiguatedCodeName(s, code));
    const int32_t state_bits = code->untag()->state_bits_;
    s->Write<int32_t>(state_bits);
    target_memory_size_ += compiler::target::Code::InstanceSize(0);
  }

  void WriteFill(Serializer* s) {
    Snapshot::Kind kind = s->kind();
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      CodePtr code = objects_[i];
#if defined(DART_PRECOMPILER)
      if (FLAG_write_v8_snapshot_profile_to != nullptr &&
          Code::IsDiscarded(code)) {
        s->CreateArtificialNodeIfNeeded(code);
      }
#endif
      // Note: for discarded code this function will not write anything out
      // it is only called to produce information into snapshot profile.
      WriteFill(s, kind, code, /*deferred=*/false);
    }
    const intptr_t deferred_count = deferred_objects_.length();
    for (intptr_t i = 0; i < deferred_count; i++) {
      CodePtr code = deferred_objects_[i];
      WriteFill(s, kind, code, /*deferred=*/true);
    }
  }

  void WriteFill(Serializer* s,
                 Snapshot::Kind kind,
                 CodePtr code,
                 bool deferred) {
    const intptr_t bytes_written = s->bytes_written();
    AutoTraceObjectName(code, MakeDisambiguatedCodeName(s, code));

    intptr_t pointer_offsets_length =
        Code::PtrOffBits::decode(code->untag()->state_bits_);
    if (pointer_offsets_length != 0) {
      FATAL("Cannot serialize code with embedded pointers");
    }
    if (kind == Snapshot::kFullAOT && Code::IsDisabled(code)) {
      // Disabled code is fatal in AOT since we cannot recompile.
      s->UnexpectedObject(code, "Disabled code");
    }

    s->WriteInstructions(code->untag()->instructions_,
                         code->untag()->unchecked_offset_, code, deferred);
    if (kind == Snapshot::kFullJIT) {
      // TODO(rmacnak): Fix references to disabled code before serializing.
      // For now, we may write the FixCallersTarget or equivalent stub. This
      // will cause a fixup if this code is called.
      const uint32_t active_unchecked_offset =
          code->untag()->unchecked_entry_point_ - code->untag()->entry_point_;
      s->WriteInstructions(code->untag()->active_instructions_,
                           active_unchecked_offset, code, deferred);
    }

#if defined(DART_PRECOMPILER)
    if (FLAG_write_v8_snapshot_profile_to != nullptr) {
      // If we are writing V8 snapshot profile then attribute references going
      // through the object pool and static calls to the code object itself.
      if (kind == Snapshot::kFullAOT &&
          code->untag()->object_pool_ != ObjectPool::null()) {
        ObjectPoolPtr pool = code->untag()->object_pool_;
        // Non-empty per-code object pools should not be reachable in this mode.
        ASSERT(!s->HasRef(pool) || pool == Object::empty_object_pool().ptr());
        s->CreateArtificialNodeIfNeeded(pool);
        s->AttributePropertyRef(pool, "object_pool_");
      }
      if (kind != Snapshot::kFullJIT &&
          code->untag()->static_calls_target_table_ != Array::null()) {
        auto const table = code->untag()->static_calls_target_table_;
        // Non-empty static call target tables shouldn't be reachable in this
        // mode.
        ASSERT(!s->HasRef(table) || table == Object::empty_array().ptr());
        s->CreateArtificialNodeIfNeeded(table);
        s->AttributePropertyRef(table, "static_calls_target_table_");
      }
    }
#endif  // defined(DART_PRECOMPILER)

    if (Code::IsDiscarded(code)) {
      // No bytes should be written to represent this code.
      ASSERT(s->bytes_written() == bytes_written);
      // Only write instructions, compressed stackmaps and state bits
      // for the discarded Code objects.
      ASSERT(kind == Snapshot::kFullAOT && FLAG_dwarf_stack_traces_mode &&
             !FLAG_retain_code_objects);
#if defined(DART_PRECOMPILER)
      if (FLAG_write_v8_snapshot_profile_to != nullptr) {
        // Keep the owner as a (possibly artificial) node for snapshot analysis.
        const auto& owner = code->untag()->owner_;
        s->CreateArtificialNodeIfNeeded(owner);
        s->AttributePropertyRef(owner, "owner_");
      }
#endif
      return;
    }

    // No need to write object pool out if we are producing full AOT
    // snapshot with bare instructions.
    if (kind != Snapshot::kFullAOT) {
      if (s->InCurrentLoadingUnitOrRoot(code->untag()->object_pool_)) {
        WriteField(code, object_pool_);
      } else {
        WriteFieldValue(object_pool_, ObjectPool::null());
      }
    }
    WriteField(code, owner_);
    WriteField(code, exception_handlers_);
    WriteField(code, pc_descriptors_);
    WriteField(code, catch_entry_);
    if (s->kind() == Snapshot::kFullJIT) {
      WriteField(code, compressed_stackmaps_);
    }
    if (FLAG_precompiled_mode && FLAG_dwarf_stack_traces_mode) {
      WriteFieldValue(inlined_id_to_function_, Array::null());
      WriteFieldValue(code_source_map_, CodeSourceMap::null());
    } else {
      WriteField(code, inlined_id_to_function_);
      if (s->InCurrentLoadingUnitOrRoot(code->untag()->code_source_map_)) {
        WriteField(code, code_source_map_);
      } else {
        WriteFieldValue(code_source_map_, CodeSourceMap::null());
      }
    }
    if (kind == Snapshot::kFullJIT) {
      WriteField(code, deopt_info_array_);
      WriteField(code, static_calls_target_table_);
    }

#if !defined(PRODUCT)
    WriteField(code, return_address_metadata_);
    if (FLAG_code_comments) {
      WriteField(code, comments_);
    }
#endif
  }

  GrowableArray<CodePtr>* objects() { return &objects_; }
  GrowableArray<CodePtr>* deferred_objects() { return &deferred_objects_; }

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

  intptr_t first_ref() const { return first_ref_; }
  intptr_t first_deferred_ref() const { return first_deferred_ref_; }
  intptr_t last_ref() const { return last_ref_; }

 private:
  intptr_t first_ref_;
  intptr_t first_deferred_ref_;
  intptr_t last_ref_;
  GrowableArray<CodePtr> objects_;
  GrowableArray<CodePtr> deferred_objects_;
  Array& array_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class CodeDeserializationCluster : public DeserializationCluster {
 public:
  CodeDeserializationCluster() : DeserializationCluster("Code") {}
  ~CodeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    d->set_code_start_index(start_index_);
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      ReadAllocOneCode(d);
    }
    stop_index_ = d->next_index();
    d->set_code_stop_index(stop_index_);
    deferred_start_index_ = d->next_index();
    const intptr_t deferred_count = d->ReadUnsigned();
    for (intptr_t i = 0; i < deferred_count; i++) {
      ReadAllocOneCode(d);
    }
    deferred_stop_index_ = d->next_index();
  }

  void ReadAllocOneCode(Deserializer* d) {
    const int32_t state_bits = d->Read<int32_t>();
    ASSERT(!Code::DiscardedBit::decode(state_bits));
    auto code = static_cast<CodePtr>(d->Allocate(Code::InstanceSize(0)));
    d->AssignRef(code);
    code->untag()->state_bits_ = state_bits;
  }

  void ReadFill(Deserializer* d, bool primary) {
    ASSERT(!is_canonical());  // Never canonical.
    ReadFill(d, start_index_, stop_index_, false);
#if defined(DART_PRECOMPILED_RUNTIME)
    ReadFill(d, deferred_start_index_, deferred_stop_index_, true);
#else
    ASSERT(deferred_start_index_ == deferred_stop_index_);
#endif
  }

  void ReadFill(Deserializer* d,
                intptr_t start_index,
                intptr_t stop_index,
                bool deferred) {
    for (intptr_t id = start_index, n = stop_index; id < n; id++) {
      auto const code = static_cast<CodePtr>(d->Ref(id));

      ASSERT(!Code::IsUnknownDartCode(code));

      Deserializer::InitializeHeader(code, kCodeCid, Code::InstanceSize(0));
      ASSERT(!Code::IsDiscarded(code));

      d->ReadInstructions(code, deferred);

#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d->kind() == Snapshot::kFullJIT);
      code->untag()->object_pool_ = static_cast<ObjectPoolPtr>(d->ReadRef());
#else
      ASSERT(d->kind() == Snapshot::kFullAOT);
      // There is a single global pool.
      code->untag()->object_pool_ = ObjectPool::null();
#endif
      code->untag()->owner_ = d->ReadRef();
      code->untag()->exception_handlers_ =
          static_cast<ExceptionHandlersPtr>(d->ReadRef());
      code->untag()->pc_descriptors_ =
          static_cast<PcDescriptorsPtr>(d->ReadRef());
      code->untag()->catch_entry_ = d->ReadRef();
#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d->kind() == Snapshot::kFullJIT);
      code->untag()->compressed_stackmaps_ =
          static_cast<CompressedStackMapsPtr>(d->ReadRef());
#else
      ASSERT(d->kind() == Snapshot::kFullAOT);
      code->untag()->compressed_stackmaps_ = CompressedStackMaps::null();
#endif
      code->untag()->inlined_id_to_function_ =
          static_cast<ArrayPtr>(d->ReadRef());
      code->untag()->code_source_map_ =
          static_cast<CodeSourceMapPtr>(d->ReadRef());

#if !defined(DART_PRECOMPILED_RUNTIME)
      ASSERT(d->kind() == Snapshot::kFullJIT);
      code->untag()->deopt_info_array_ = static_cast<ArrayPtr>(d->ReadRef());
      code->untag()->static_calls_target_table_ =
          static_cast<ArrayPtr>(d->ReadRef());
#endif  // !DART_PRECOMPILED_RUNTIME

#if !defined(PRODUCT)
      code->untag()->return_address_metadata_ = d->ReadRef();
      code->untag()->var_descriptors_ = LocalVarDescriptors::null();
      code->untag()->comments_ = FLAG_code_comments
                                     ? static_cast<ArrayPtr>(d->ReadRef())
                                     : Array::null();
      code->untag()->compile_timestamp_ = 0;
#endif
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    d->EndInstructions();

#if !defined(PRODUCT)
    if (!CodeObservers::AreActive() && !FLAG_support_disassembler) return;
#endif
    Code& code = Code::Handle(d->zone());
#if !defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER)
    Object& owner = Object::Handle(d->zone());
#endif
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
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
  ObjectPoolSerializationCluster()
      : SerializationCluster("ObjectPool", kObjectPoolCid) {}
  ~ObjectPoolSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ObjectPoolPtr pool = ObjectPool::RawCast(object);
    objects_.Add(pool);

    if (s->kind() != Snapshot::kFullAOT) {
      const intptr_t length = pool->untag()->length_;
      uint8_t* entry_bits = pool->untag()->entry_bits();
      for (intptr_t i = 0; i < length; i++) {
        auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
        if (entry_type == ObjectPool::EntryType::kTaggedObject) {
          s->Push(pool->untag()->data()[i].raw_obj_);
        }
      }
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ObjectPoolPtr pool = objects_[i];
      s->AssignRef(pool);
      AutoTraceObject(pool);
      const intptr_t length = pool->untag()->length_;
      s->WriteUnsigned(length);
      target_memory_size_ += compiler::target::ObjectPool::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    bool weak = s->kind() == Snapshot::kFullAOT;

    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ObjectPoolPtr pool = objects_[i];
      AutoTraceObject(pool);
      const intptr_t length = pool->untag()->length_;
      s->WriteUnsigned(length);
      uint8_t* entry_bits = pool->untag()->entry_bits();
      for (intptr_t j = 0; j < length; j++) {
        UntaggedObjectPool::Entry& entry = pool->untag()->data()[j];
        uint8_t bits = entry_bits[j];
        ObjectPool::EntryType type = ObjectPool::TypeBits::decode(bits);
        if (weak && (type == ObjectPool::EntryType::kTaggedObject)) {
          // By default, every switchable call site will put (ic_data, code)
          // into the object pool. The [code] is initialized (at AOT
          // compile-time) to be [StubCode::SwitchableCallMiss] or
          // [StubCode::MegamorphicCall].
          //
          // In --use-bare-instruction we reduce the extra indirection via
          // the [code] object and store instead (ic_data, entrypoint) in
          // the object pool.
          //
          // Since the actual [entrypoint] is only known at AOT runtime we
          // switch all existing entries for these stubs to entrypoints
          // encoded as EntryType::kSwitchableCallMissEntryPoint and
          // EntryType::kMegamorphicCallEntryPoint.
          if (entry.raw_obj_ == StubCode::SwitchableCallMiss().ptr()) {
            type = ObjectPool::EntryType::kSwitchableCallMissEntryPoint;
            bits = ObjectPool::EncodeBits(type,
                                          ObjectPool::Patchability::kPatchable);
          } else if (entry.raw_obj_ == StubCode::MegamorphicCall().ptr()) {
            type = ObjectPool::EntryType::kMegamorphicCallEntryPoint;
            bits = ObjectPool::EncodeBits(type,
                                          ObjectPool::Patchability::kPatchable);
          }
        }
        s->Write<uint8_t>(bits);
        switch (type) {
          case ObjectPool::EntryType::kTaggedObject: {
            if ((entry.raw_obj_ == StubCode::CallNoScopeNative().ptr()) ||
                (entry.raw_obj_ == StubCode::CallAutoScopeNative().ptr())) {
              // Natives can run while precompiling, becoming linked and
              // switching their stub. Reset to the initial stub used for
              // lazy-linking.
              s->WriteElementRef(StubCode::CallBootstrapNative().ptr(), j);
              break;
            }
            if (weak && !s->HasRef(entry.raw_obj_)) {
              // Any value will do, but null has the shortest id.
              s->WriteElementRef(Object::null(), j);
            } else {
              s->WriteElementRef(entry.raw_obj_, j);
            }
            break;
          }
          case ObjectPool::EntryType::kImmediate: {
            s->Write<intptr_t>(entry.raw_value_);
            break;
          }
          case ObjectPool::EntryType::kNativeFunction: {
            // Write nothing. Will initialize with the lazy link entry.
            break;
          }
          case ObjectPool::EntryType::kSwitchableCallMissEntryPoint:
          case ObjectPool::EntryType::kMegamorphicCallEntryPoint:
            // Write nothing. Entry point is initialized during
            // snapshot deserialization.
            break;
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

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(ObjectPool::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    fill_position_ = d.Position();
#if defined(DART_PRECOMPILED_RUNTIME)
    const uint8_t immediate_bits =
        ObjectPool::EncodeBits(ObjectPool::EntryType::kImmediate,
                               ObjectPool::Patchability::kPatchable);
    uword switchable_call_miss_entry_point = 0;
    uword megamorphic_call_entry_point = 0;
    switchable_call_miss_entry_point =
        StubCode::SwitchableCallMiss().MonomorphicEntryPoint();
    megamorphic_call_entry_point =
        StubCode::MegamorphicCall().MonomorphicEntryPoint();
#endif  // defined(DART_PRECOMPILED_RUNTIME)

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      const intptr_t length = d.ReadUnsigned();
      ObjectPoolPtr pool = static_cast<ObjectPoolPtr>(d.Ref(id));
      Deserializer::InitializeHeader(pool, kObjectPoolCid,
                                     ObjectPool::InstanceSize(length));
      pool->untag()->length_ = length;
      for (intptr_t j = 0; j < length; j++) {
        const uint8_t entry_bits = d.Read<uint8_t>();
        pool->untag()->entry_bits()[j] = entry_bits;
        UntaggedObjectPool::Entry& entry = pool->untag()->data()[j];
        switch (ObjectPool::TypeBits::decode(entry_bits)) {
          case ObjectPool::EntryType::kTaggedObject:
            entry.raw_obj_ = d.ReadRef();
            break;
          case ObjectPool::EntryType::kImmediate:
            entry.raw_value_ = d.Read<intptr_t>();
            break;
          case ObjectPool::EntryType::kNativeFunction: {
            // Read nothing. Initialize with the lazy link entry.
            uword new_entry = NativeEntry::LinkNativeCallEntry();
            entry.raw_value_ = static_cast<intptr_t>(new_entry);
            break;
          }
#if defined(DART_PRECOMPILED_RUNTIME)
          case ObjectPool::EntryType::kSwitchableCallMissEntryPoint:
            pool->untag()->entry_bits()[j] = immediate_bits;
            entry.raw_value_ =
                static_cast<intptr_t>(switchable_call_miss_entry_point);
            break;
          case ObjectPool::EntryType::kMegamorphicCallEntryPoint:
            pool->untag()->entry_bits()[j] = immediate_bits;
            entry.raw_value_ =
                static_cast<intptr_t>(megamorphic_call_entry_point);
            break;
#endif  // defined(DART_PRECOMPILED_RUNTIME)
          default:
            UNREACHABLE();
        }
      }
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (d->is_non_root_unit()) {
      // If this is a non-root unit, some pool entries that should be canonical
      // may have been replaced be with other objects during canonicalization.

      intptr_t restore_position = d->position();
      d->set_position(fill_position_);

      auto Z = d->zone();
      ObjectPool& pool = ObjectPool::Handle(Z);
      Object& entry = Object::Handle(Z);
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        pool ^= refs.At(id);
        const intptr_t length = d->ReadUnsigned();
        for (intptr_t j = 0; j < length; j++) {
          const uint8_t entry_bits = d->Read<uint8_t>();
          switch (ObjectPool::TypeBits::decode(entry_bits)) {
            case ObjectPool::EntryType::kTaggedObject:
              entry = refs.At(d->ReadUnsigned());
              pool.SetObjectAt(j, entry);
              break;
            case ObjectPool::EntryType::kImmediate:
              d->Read<intptr_t>();
              break;
            case ObjectPool::EntryType::kNativeFunction: {
              // Read nothing.
              break;
            }
            default:
              UNREACHABLE();
          }
        }
      }

      d->set_position(restore_position);
    }

#if defined(DART_PRECOMPILED_RUNTIME) &&                                       \
    (!defined(PRODUCT) || defined(FORCE_INCLUDE_DISASSEMBLER))
    if (FLAG_disassemble) {
      ObjectPool& pool = ObjectPool::Handle(
          d->isolate_group()->object_store()->global_object_pool());
      THR_Print("Global object pool:\n");
      pool.DebugPrint();
    }
#endif
  }

 private:
  intptr_t fill_position_ = 0;
};

#if defined(DART_PRECOMPILER)
class WeakSerializationReferenceSerializationCluster
    : public SerializationCluster {
 public:
  WeakSerializationReferenceSerializationCluster()
      : SerializationCluster(
            "WeakSerializationReference",
            compiler::target::WeakSerializationReference::InstanceSize()) {}
  ~WeakSerializationReferenceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ASSERT(s->kind() == Snapshot::kFullAOT);
    objects_.Add(WeakSerializationReference::RawCast(object));
  }

  void RetraceEphemerons(Serializer* s) {
    for (intptr_t i = 0; i < objects_.length(); i++) {
      WeakSerializationReferencePtr weak = objects_[i];
      if (!s->IsReachable(weak->untag()->target())) {
        s->Push(weak->untag()->replacement());
      }
    }
  }

  intptr_t Count(Serializer* s) { return objects_.length(); }

  void CreateArtificialTargetNodesIfNeeded(Serializer* s) {
    for (intptr_t i = 0; i < objects_.length(); i++) {
      WeakSerializationReferencePtr weak = objects_[i];
      s->CreateArtificialNodeIfNeeded(weak->untag()->target());
    }
  }

  void WriteAlloc(Serializer* s) {
    UNREACHABLE();  // No WSRs are serialized, and so this cluster is not added.
  }

  void WriteFill(Serializer* s) {
    UNREACHABLE();  // No WSRs are serialized, and so this cluster is not added.
  }

 private:
  GrowableArray<WeakSerializationReferencePtr> objects_;
};
#endif

#if !defined(DART_PRECOMPILED_RUNTIME)
class PcDescriptorsSerializationCluster : public SerializationCluster {
 public:
  PcDescriptorsSerializationCluster()
      : SerializationCluster("PcDescriptors", kPcDescriptorsCid) {}
  ~PcDescriptorsSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    PcDescriptorsPtr desc = PcDescriptors::RawCast(object);
    objects_.Add(desc);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      PcDescriptorsPtr desc = objects_[i];
      s->AssignRef(desc);
      AutoTraceObject(desc);
      const intptr_t length = desc->untag()->length_;
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::PcDescriptors::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      PcDescriptorsPtr desc = objects_[i];
      AutoTraceObject(desc);
      const intptr_t length = desc->untag()->length_;
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(desc->untag()->data());
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

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(PcDescriptors::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      const intptr_t length = d.ReadUnsigned();
      PcDescriptorsPtr desc = static_cast<PcDescriptorsPtr>(d.Ref(id));
      Deserializer::InitializeHeader(desc, kPcDescriptorsCid,
                                     PcDescriptors::InstanceSize(length));
      desc->untag()->length_ = length;
      uint8_t* cdata = reinterpret_cast<uint8_t*>(desc->untag()->data());
      d.ReadBytes(cdata, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class CodeSourceMapSerializationCluster : public SerializationCluster {
 public:
  CodeSourceMapSerializationCluster()
      : SerializationCluster("CodeSourceMap", kCodeSourceMapCid) {}
  ~CodeSourceMapSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    CodeSourceMapPtr map = CodeSourceMap::RawCast(object);
    objects_.Add(map);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      CodeSourceMapPtr map = objects_[i];
      s->AssignRef(map);
      AutoTraceObject(map);
      const intptr_t length = map->untag()->length_;
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::PcDescriptors::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      CodeSourceMapPtr map = objects_[i];
      AutoTraceObject(map);
      const intptr_t length = map->untag()->length_;
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(map->untag()->data());
      s->WriteBytes(cdata, length);
    }
  }

 private:
  GrowableArray<CodeSourceMapPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class CodeSourceMapDeserializationCluster : public DeserializationCluster {
 public:
  CodeSourceMapDeserializationCluster()
      : DeserializationCluster("CodeSourceMap") {}
  ~CodeSourceMapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(CodeSourceMap::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      const intptr_t length = d.ReadUnsigned();
      CodeSourceMapPtr map = static_cast<CodeSourceMapPtr>(d.Ref(id));
      Deserializer::InitializeHeader(map, kPcDescriptorsCid,
                                     CodeSourceMap::InstanceSize(length));
      map->untag()->length_ = length;
      uint8_t* cdata = reinterpret_cast<uint8_t*>(map->untag()->data());
      d.ReadBytes(cdata, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class CompressedStackMapsSerializationCluster : public SerializationCluster {
 public:
  CompressedStackMapsSerializationCluster()
      : SerializationCluster("CompressedStackMaps", kCompressedStackMapsCid) {}
  ~CompressedStackMapsSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    CompressedStackMapsPtr desc = CompressedStackMaps::RawCast(object);
    objects_.Add(desc);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      CompressedStackMapsPtr map = objects_[i];
      s->AssignRef(map);
      AutoTraceObject(map);
      const intptr_t length = UntaggedCompressedStackMaps::SizeField::decode(
          map->untag()->payload()->flags_and_size());
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::CompressedStackMaps::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      CompressedStackMapsPtr map = objects_[i];
      AutoTraceObject(map);
      s->WriteUnsigned(map->untag()->payload()->flags_and_size());
      const intptr_t length = UntaggedCompressedStackMaps::SizeField::decode(
          map->untag()->payload()->flags_and_size());
      uint8_t* cdata =
          reinterpret_cast<uint8_t*>(map->untag()->payload()->data());
      s->WriteBytes(cdata, length);
    }
  }

 private:
  GrowableArray<CompressedStackMapsPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class CompressedStackMapsDeserializationCluster
    : public DeserializationCluster {
 public:
  CompressedStackMapsDeserializationCluster()
      : DeserializationCluster("CompressedStackMaps") {}
  ~CompressedStackMapsDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(CompressedStackMaps::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      const intptr_t flags_and_size = d.ReadUnsigned();
      const intptr_t length =
          UntaggedCompressedStackMaps::SizeField::decode(flags_and_size);
      CompressedStackMapsPtr map =
          static_cast<CompressedStackMapsPtr>(d.Ref(id));
      Deserializer::InitializeHeader(map, kCompressedStackMapsCid,
                                     CompressedStackMaps::InstanceSize(length));
      map->untag()->payload()->set_flags_and_size(flags_and_size);
      uint8_t* cdata =
          reinterpret_cast<uint8_t*>(map->untag()->payload()->data());
      d.ReadBytes(cdata, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME) && !defined(DART_COMPRESSED_POINTERS)
// PcDescriptor, CompressedStackMaps, OneByteString, TwoByteString
class RODataSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalStringSet,
                                              String,
                                              ObjectPtr> {
 public:
  RODataSerializationCluster(Zone* zone,
                             const char* type,
                             intptr_t cid,
                             bool is_canonical)
      : CanonicalSetSerializationCluster(
            cid,
            is_canonical,
            is_canonical && IsStringClassId(cid),
            ImageWriter::TagObjectTypeAsReadOnly(zone, type)),
        zone_(zone),
        cid_(cid),
        type_(type) {}
  ~RODataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    // A string's hash must already be computed when we write it because it
    // will be loaded into read-only memory. Extra bytes due to allocation
    // rounding need to be deterministically set for reliable deduplication in
    // shared images.
    if (object->untag()->InVMIsolateHeap() ||
        s->heap()->old_space()->IsObjectFromImagePages(object)) {
      // This object is already read-only.
    } else {
      Object::FinalizeReadOnlyObject(object);
    }

    objects_.Add(object);
  }

  void WriteAlloc(Serializer* s) {
    const bool is_string_cluster = IsStringClassId(cid_);

    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);

    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      ObjectPtr object = objects_[i];
      s->AssignRef(object);
      const StringPtr name =
          is_string_cluster ? String::RawCast(object) : nullptr;
      Serializer::WritingObjectScope scope(s, type_, object, name);
      uint32_t offset = s->GetDataOffset(object);
      s->TraceDataOffset(offset);
      ASSERT(Utils::IsAligned(
          offset, compiler::target::ObjectAlignment::kObjectAlignment));
      ASSERT(offset > running_offset);
      s->WriteUnsigned((offset - running_offset) >>
                       compiler::target::ObjectAlignment::kObjectAlignmentLog2);
      running_offset = offset;
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    // No-op.
  }

 private:
  Zone* zone_;
  const intptr_t cid_;
  const char* const type_;
};
#endif  // !DART_PRECOMPILED_RUNTIME && !DART_COMPRESSED_POINTERS

#if !defined(DART_COMPRESSED_POINTERS)
class RODataDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalStringSet> {
 public:
  explicit RODataDeserializationCluster(bool is_canonical,
                                        bool is_root_unit,
                                        intptr_t cid)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "ROData"),
        cid_(cid) {}
  ~RODataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    intptr_t count = d->ReadUnsigned();
    uint32_t running_offset = 0;
    for (intptr_t i = 0; i < count; i++) {
      running_offset += d->ReadUnsigned() << kObjectAlignmentLog2;
      ObjectPtr object = d->GetObjectAt(running_offset);
      d->AssignRef(object);
    }
    stop_index_ = d->next_index();
    if (cid_ == kStringCid) {
      BuildCanonicalSetFromLayout(d);
    }
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    // No-op.
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(d, refs,
                         WeakArray::Handle(object_store->symbol_table()));
      object_store->set_symbol_table(table_);
      if (d->isolate_group() == Dart::vm_isolate_group()) {
        Symbols::InitFromSnapshot(d->isolate_group());
      }
    } else if (!primary && is_canonical()) {
      FATAL("Cannot recanonicalize RO objects.");
    }
  }

 private:
  const intptr_t cid_;
};
#endif  // !DART_COMPRESSED_POINTERS

#if !defined(DART_PRECOMPILED_RUNTIME)
class ExceptionHandlersSerializationCluster : public SerializationCluster {
 public:
  ExceptionHandlersSerializationCluster()
      : SerializationCluster("ExceptionHandlers", kExceptionHandlersCid) {}
  ~ExceptionHandlersSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ExceptionHandlersPtr handlers = ExceptionHandlers::RawCast(object);
    objects_.Add(handlers);

    s->Push(handlers->untag()->handled_types_data());
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ExceptionHandlersPtr handlers = objects_[i];
      s->AssignRef(handlers);
      AutoTraceObject(handlers);
      const intptr_t length = handlers->untag()->num_entries();
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::ExceptionHandlers::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ExceptionHandlersPtr handlers = objects_[i];
      AutoTraceObject(handlers);
      const intptr_t packed_fields = handlers->untag()->packed_fields_;
      const intptr_t length =
          UntaggedExceptionHandlers::NumEntriesBits::decode(packed_fields);
      s->WriteUnsigned(packed_fields);
      WriteCompressedField(handlers, handled_types_data);
      for (intptr_t j = 0; j < length; j++) {
        const ExceptionHandlerInfo& info = handlers->untag()->data()[j];
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

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(ExceptionHandlers::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ExceptionHandlersPtr handlers =
          static_cast<ExceptionHandlersPtr>(d.Ref(id));
      const intptr_t packed_fields = d.ReadUnsigned();
      const intptr_t length =
          UntaggedExceptionHandlers::NumEntriesBits::decode(packed_fields);
      Deserializer::InitializeHeader(handlers, kExceptionHandlersCid,
                                     ExceptionHandlers::InstanceSize(length));
      handlers->untag()->packed_fields_ = packed_fields;
      handlers->untag()->handled_types_data_ =
          static_cast<ArrayPtr>(d.ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        ExceptionHandlerInfo& info = handlers->untag()->data()[j];
        info.handler_pc_offset = d.Read<uint32_t>();
        info.outer_try_index = d.Read<int16_t>();
        info.needs_stacktrace = d.Read<int8_t>();
        info.has_catch_all = d.Read<int8_t>();
        info.is_generated = d.Read<int8_t>();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ContextSerializationCluster : public SerializationCluster {
 public:
  ContextSerializationCluster()
      : SerializationCluster("Context", kContextCid) {}
  ~ContextSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ContextPtr context = Context::RawCast(object);
    objects_.Add(context);

    s->Push(context->untag()->parent());
    const intptr_t length = context->untag()->num_variables_;
    for (intptr_t i = 0; i < length; i++) {
      s->Push(context->untag()->element(i));
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ContextPtr context = objects_[i];
      s->AssignRef(context);
      AutoTraceObject(context);
      const intptr_t length = context->untag()->num_variables_;
      s->WriteUnsigned(length);
      target_memory_size_ += compiler::target::Context::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ContextPtr context = objects_[i];
      AutoTraceObject(context);
      const intptr_t length = context->untag()->num_variables_;
      s->WriteUnsigned(length);
      WriteField(context, parent());
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(context->untag()->element(j), j);
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

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(Context::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ContextPtr context = static_cast<ContextPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(context, kContextCid,
                                     Context::InstanceSize(length));
      context->untag()->num_variables_ = length;
      context->untag()->parent_ = static_cast<ContextPtr>(d.ReadRef());
      for (intptr_t j = 0; j < length; j++) {
        context->untag()->data()[j] = d.ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ContextScopeSerializationCluster : public SerializationCluster {
 public:
  ContextScopeSerializationCluster()
      : SerializationCluster("ContextScope", kContextScopeCid) {}
  ~ContextScopeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ContextScopePtr scope = ContextScope::RawCast(object);
    objects_.Add(scope);

    const intptr_t length = scope->untag()->num_variables_;
    PushFromTo(scope, length);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ContextScopePtr scope = objects_[i];
      s->AssignRef(scope);
      AutoTraceObject(scope);
      const intptr_t length = scope->untag()->num_variables_;
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::ContextScope::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ContextScopePtr scope = objects_[i];
      AutoTraceObject(scope);
      const intptr_t length = scope->untag()->num_variables_;
      s->WriteUnsigned(length);
      s->Write<bool>(scope->untag()->is_implicit_);
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

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(ContextScope::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ContextScopePtr scope = static_cast<ContextScopePtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(scope, kContextScopeCid,
                                     ContextScope::InstanceSize(length));
      scope->untag()->num_variables_ = length;
      scope->untag()->is_implicit_ = d.Read<bool>();
      d.ReadFromTo(scope, length);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnlinkedCallSerializationCluster : public SerializationCluster {
 public:
  UnlinkedCallSerializationCluster()
      : SerializationCluster("UnlinkedCall",
                             kUnlinkedCallCid,
                             compiler::target::UnlinkedCall::InstanceSize()) {}
  ~UnlinkedCallSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    UnlinkedCallPtr unlinked = UnlinkedCall::RawCast(object);
    objects_.Add(unlinked);
    PushFromTo(unlinked);
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(unlinked, unlinked->untag()->target_name_);
      WriteFromTo(unlinked);
      s->Write<bool>(unlinked->untag()->can_patch_to_monomorphic_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, UnlinkedCall::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      UnlinkedCallPtr unlinked = static_cast<UnlinkedCallPtr>(d.Ref(id));
      Deserializer::InitializeHeader(unlinked, kUnlinkedCallCid,
                                     UnlinkedCall::InstanceSize());
      d.ReadFromTo(unlinked);
      unlinked->untag()->can_patch_to_monomorphic_ = d.Read<bool>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ICDataSerializationCluster : public SerializationCluster {
 public:
  ICDataSerializationCluster()
      : SerializationCluster("ICData",
                             kICDataCid,
                             compiler::target::ICData::InstanceSize()) {}
  ~ICDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ICDataPtr ic = ICData::RawCast(object);
    objects_.Add(ic);
    PushFromTo(ic);
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(ic, ic->untag()->target_name_);
      WriteFromTo(ic);
      if (kind != Snapshot::kFullAOT) {
        NOT_IN_PRECOMPILED(s->Write<int32_t>(ic->untag()->deopt_id_));
      }
      s->Write<uint32_t>(ic->untag()->state_bits_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, ICData::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ICDataPtr ic = static_cast<ICDataPtr>(d.Ref(id));
      Deserializer::InitializeHeader(ic, kICDataCid, ICData::InstanceSize());
      d.ReadFromTo(ic);
      NOT_IN_PRECOMPILED(ic->untag()->deopt_id_ = d.Read<int32_t>());
      ic->untag()->state_bits_ = d.Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MegamorphicCacheSerializationCluster : public SerializationCluster {
 public:
  MegamorphicCacheSerializationCluster()
      : SerializationCluster(
            "MegamorphicCache",
            kMegamorphicCacheCid,
            compiler::target::MegamorphicCache::InstanceSize()) {}
  ~MegamorphicCacheSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    MegamorphicCachePtr cache = MegamorphicCache::RawCast(object);
    objects_.Add(cache);
    PushFromTo(cache);
  }

  void WriteAlloc(Serializer* s) {
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
      AutoTraceObjectName(cache, cache->untag()->target_name_);
      WriteFromTo(cache);
      s->Write<int32_t>(cache->untag()->filled_entry_count_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, MegamorphicCache::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      MegamorphicCachePtr cache = static_cast<MegamorphicCachePtr>(d.Ref(id));
      Deserializer::InitializeHeader(cache, kMegamorphicCacheCid,
                                     MegamorphicCache::InstanceSize());
      d.ReadFromTo(cache);
      cache->untag()->filled_entry_count_ = d.Read<int32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SubtypeTestCacheSerializationCluster : public SerializationCluster {
 public:
  SubtypeTestCacheSerializationCluster()
      : SerializationCluster(
            "SubtypeTestCache",
            kSubtypeTestCacheCid,
            compiler::target::SubtypeTestCache::InstanceSize()) {}
  ~SubtypeTestCacheSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    SubtypeTestCachePtr cache = SubtypeTestCache::RawCast(object);
    objects_.Add(cache);
    s->Push(cache->untag()->cache_);
  }

  void WriteAlloc(Serializer* s) {
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
      s->Write<uint32_t>(cache->untag()->num_inputs_);
      s->Write<uint32_t>(cache->untag()->num_occupied_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, SubtypeTestCache::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      SubtypeTestCachePtr cache = static_cast<SubtypeTestCachePtr>(d.Ref(id));
      Deserializer::InitializeHeader(cache, kSubtypeTestCacheCid,
                                     SubtypeTestCache::InstanceSize());
      cache->untag()->cache_ = static_cast<ArrayPtr>(d.ReadRef());
      cache->untag()->num_inputs_ = d.Read<uint32_t>();
      cache->untag()->num_occupied_ = d.Read<uint32_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LoadingUnitSerializationCluster : public SerializationCluster {
 public:
  LoadingUnitSerializationCluster()
      : SerializationCluster("LoadingUnit",
                             kLoadingUnitCid,
                             compiler::target::LoadingUnit::InstanceSize()) {}
  ~LoadingUnitSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LoadingUnitPtr unit = LoadingUnit::RawCast(object);
    objects_.Add(unit);
    s->Push(unit->untag()->parent());
  }

  void WriteAlloc(Serializer* s) {
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
      WriteCompressedField(unit, parent);
      s->Write<int32_t>(unit->untag()->id_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, LoadingUnit::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      LoadingUnitPtr unit = static_cast<LoadingUnitPtr>(d.Ref(id));
      Deserializer::InitializeHeader(unit, kLoadingUnitCid,
                                     LoadingUnit::InstanceSize());
      unit->untag()->parent_ = static_cast<LoadingUnitPtr>(d.ReadRef());
      unit->untag()->base_objects_ = Array::null();
      unit->untag()->id_ = d.Read<int32_t>();
      unit->untag()->loaded_ = false;
      unit->untag()->load_outstanding_ = false;
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class LanguageErrorSerializationCluster : public SerializationCluster {
 public:
  LanguageErrorSerializationCluster()
      : SerializationCluster("LanguageError",
                             kLanguageErrorCid,
                             compiler::target::LanguageError::InstanceSize()) {}
  ~LanguageErrorSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LanguageErrorPtr error = LanguageError::RawCast(object);
    objects_.Add(error);
    PushFromTo(error);
  }

  void WriteAlloc(Serializer* s) {
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
      s->WriteTokenPosition(error->untag()->token_pos_);
      s->Write<bool>(error->untag()->report_after_token_);
      s->Write<int8_t>(error->untag()->kind_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, LanguageError::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      LanguageErrorPtr error = static_cast<LanguageErrorPtr>(d.Ref(id));
      Deserializer::InitializeHeader(error, kLanguageErrorCid,
                                     LanguageError::InstanceSize());
      d.ReadFromTo(error);
      error->untag()->token_pos_ = d.ReadTokenPosition();
      error->untag()->report_after_token_ = d.Read<bool>();
      error->untag()->kind_ = d.Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class UnhandledExceptionSerializationCluster : public SerializationCluster {
 public:
  UnhandledExceptionSerializationCluster()
      : SerializationCluster(
            "UnhandledException",
            kUnhandledExceptionCid,
            compiler::target::UnhandledException::InstanceSize()) {}
  ~UnhandledExceptionSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    UnhandledExceptionPtr exception = UnhandledException::RawCast(object);
    objects_.Add(exception);
    PushFromTo(exception);
  }

  void WriteAlloc(Serializer* s) {
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, UnhandledException::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      UnhandledExceptionPtr exception =
          static_cast<UnhandledExceptionPtr>(d.Ref(id));
      Deserializer::InitializeHeader(exception, kUnhandledExceptionCid,
                                     UnhandledException::InstanceSize());
      d.ReadFromTo(exception);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class InstanceSerializationCluster : public SerializationCluster {
 public:
  InstanceSerializationCluster(bool is_canonical, intptr_t cid)
      : SerializationCluster("Instance", cid, kSizeVaries, is_canonical) {
    ClassPtr cls = IsolateGroup::Current()->class_table()->At(cid);
    host_next_field_offset_in_words_ =
        cls->untag()->host_next_field_offset_in_words_;
    ASSERT(host_next_field_offset_in_words_ > 0);
#if defined(DART_PRECOMPILER)
    target_next_field_offset_in_words_ =
        cls->untag()->target_next_field_offset_in_words_;
    target_instance_size_in_words_ =
        cls->untag()->target_instance_size_in_words_;
#else
    target_next_field_offset_in_words_ =
        cls->untag()->host_next_field_offset_in_words_;
    target_instance_size_in_words_ = cls->untag()->host_instance_size_in_words_;
#endif  // defined(DART_PRECOMPILER)
    ASSERT(target_next_field_offset_in_words_ > 0);
    ASSERT(target_instance_size_in_words_ > 0);
  }
  ~InstanceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    InstancePtr instance = Instance::RawCast(object);
    objects_.Add(instance);
    const intptr_t next_field_offset = host_next_field_offset_in_words_
                                       << kCompressedWordSizeLog2;
    const auto unboxed_fields_bitmap =
        s->isolate_group()->class_table()->GetUnboxedFieldsMapAt(cid_);
    intptr_t offset = Instance::NextFieldOffset();
    while (offset < next_field_offset) {
      // Skips unboxed fields
      if (!unboxed_fields_bitmap.Get(offset / kCompressedWordSize)) {
        ObjectPtr raw_obj =
            reinterpret_cast<CompressedObjectPtr*>(
                reinterpret_cast<uword>(instance->untag()) + offset)
                ->Decompress(instance->untag()->heap_base());
        s->Push(raw_obj);
      }
      offset += kCompressedWordSize;
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);

    s->Write<int32_t>(target_next_field_offset_in_words_);
    s->Write<int32_t>(target_instance_size_in_words_);

    for (intptr_t i = 0; i < count; i++) {
      InstancePtr instance = objects_[i];
      s->AssignRef(instance);
    }

    const intptr_t instance_size = compiler::target::RoundedAllocationSize(
        target_instance_size_in_words_ * compiler::target::kCompressedWordSize);
    target_memory_size_ += instance_size * count;
  }

  void WriteFill(Serializer* s) {
    intptr_t next_field_offset = host_next_field_offset_in_words_
                                 << kCompressedWordSizeLog2;
    const intptr_t count = objects_.length();
    s->WriteUnsigned64(CalculateTargetUnboxedFieldsBitmap(s, cid_).Value());
    const auto unboxed_fields_bitmap =
        s->isolate_group()->class_table()->GetUnboxedFieldsMapAt(cid_);

    for (intptr_t i = 0; i < count; i++) {
      InstancePtr instance = objects_[i];
      AutoTraceObject(instance);
#if defined(DART_PRECOMPILER)
      if (FLAG_write_v8_snapshot_profile_to != nullptr) {
        ClassPtr cls = s->isolate_group()->class_table()->At(cid_);
        s->AttributePropertyRef(cls, "<class>");
      }
#endif
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        if (unboxed_fields_bitmap.Get(offset / kCompressedWordSize)) {
          // Writes 32 bits of the unboxed value at a time.
          const compressed_uword value = *reinterpret_cast<compressed_uword*>(
              reinterpret_cast<uword>(instance->untag()) + offset);
          s->WriteWordWith32BitWrites(value);
        } else {
          ObjectPtr raw_obj =
              reinterpret_cast<CompressedObjectPtr*>(
                  reinterpret_cast<uword>(instance->untag()) + offset)
                  ->Decompress(instance->untag()->heap_base());
          s->WriteElementRef(raw_obj, offset);
        }
        offset += kCompressedWordSize;
      }
    }
  }

 private:
  intptr_t host_next_field_offset_in_words_;
  intptr_t target_next_field_offset_in_words_;
  intptr_t target_instance_size_in_words_;
  GrowableArray<InstancePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class AbstractInstanceDeserializationCluster : public DeserializationCluster {
 protected:
  explicit AbstractInstanceDeserializationCluster(const char* name,
                                                  bool is_canonical)
      : DeserializationCluster(name, is_canonical) {}

 public:
#if defined(DART_PRECOMPILED_RUNTIME)
  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!primary && is_canonical()) {
      SafepointMutexLocker ml(
          d->isolate_group()->constant_canonicalization_mutex());
      Instance& instance = Instance::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        instance ^= refs.At(i);
        instance = instance.CanonicalizeLocked(d->thread());
        refs.SetAt(i, instance);
      }
    }
  }
#endif
};

class InstanceDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit InstanceDeserializationCluster(intptr_t cid, bool is_canonical)
      : AbstractInstanceDeserializationCluster("Instance", is_canonical),
        cid_(cid) {}
  ~InstanceDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    next_field_offset_in_words_ = d->Read<int32_t>();
    instance_size_in_words_ = d->Read<int32_t>();
    intptr_t instance_size = Object::RoundedAllocationSize(
        instance_size_in_words_ * kCompressedWordSize);
    for (intptr_t i = 0; i < count; i++) {
      d->AssignRef(d->Allocate(instance_size));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const intptr_t cid = cid_;
    const bool mark_canonical = primary && is_canonical();
    intptr_t next_field_offset = next_field_offset_in_words_
                                 << kCompressedWordSizeLog2;
    intptr_t instance_size = Object::RoundedAllocationSize(
        instance_size_in_words_ * kCompressedWordSize);
    const UnboxedFieldBitmap unboxed_fields_bitmap(d.ReadUnsigned64());

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      InstancePtr instance = static_cast<InstancePtr>(d.Ref(id));
      Deserializer::InitializeHeader(instance, cid, instance_size,
                                     mark_canonical);
      intptr_t offset = Instance::NextFieldOffset();
      while (offset < next_field_offset) {
        if (unboxed_fields_bitmap.Get(offset / kCompressedWordSize)) {
          compressed_uword* p = reinterpret_cast<compressed_uword*>(
              reinterpret_cast<uword>(instance->untag()) + offset);
          // Reads 32 bits of the unboxed value at a time
          *p = d.ReadWordWith32BitReads();
        } else {
          CompressedObjectPtr* p = reinterpret_cast<CompressedObjectPtr*>(
              reinterpret_cast<uword>(instance->untag()) + offset);
          *p = d.ReadRef();
        }
        offset += kCompressedWordSize;
      }
      while (offset < instance_size) {
        CompressedObjectPtr* p = reinterpret_cast<CompressedObjectPtr*>(
            reinterpret_cast<uword>(instance->untag()) + offset);
        *p = Object::null();
        offset += kCompressedWordSize;
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
  LibraryPrefixSerializationCluster()
      : SerializationCluster("LibraryPrefix",
                             kLibraryPrefixCid,
                             compiler::target::LibraryPrefix::InstanceSize()) {}
  ~LibraryPrefixSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    LibraryPrefixPtr prefix = LibraryPrefix::RawCast(object);
    objects_.Add(prefix);
    PushFromTo(prefix);
  }

  void WriteAlloc(Serializer* s) {
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
      s->Write<uint16_t>(prefix->untag()->num_imports_);
      s->Write<bool>(prefix->untag()->is_deferred_load_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, LibraryPrefix::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      LibraryPrefixPtr prefix = static_cast<LibraryPrefixPtr>(d.Ref(id));
      Deserializer::InitializeHeader(prefix, kLibraryPrefixCid,
                                     LibraryPrefix::InstanceSize());
      d.ReadFromTo(prefix);
      prefix->untag()->num_imports_ = d.Read<uint16_t>();
      prefix->untag()->is_deferred_load_ = d.Read<bool>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeSerializationCluster
    : public CanonicalSetSerializationCluster<
          CanonicalTypeSet,
          Type,
          TypePtr,
          /*kAllCanonicalObjectsAreIncludedIntoSet=*/false> {
 public:
  TypeSerializationCluster(bool is_canonical, bool represents_canonical_set)
      : CanonicalSetSerializationCluster(
            kTypeCid,
            is_canonical,
            represents_canonical_set,
            "Type",
            compiler::target::Type::InstanceSize()) {}
  ~TypeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypePtr type = Type::RawCast(object);
    objects_.Add(type);

    PushFromTo(type);

    ASSERT(type->untag()->type_class_id() != kIllegalCid);
    ClassPtr type_class =
        s->isolate_group()->class_table()->At(type->untag()->type_class_id());
    s->Push(type_class);
  }

  void WriteAlloc(Serializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);
    for (intptr_t i = 0; i < count; i++) {
      TypePtr type = objects_[i];
      s->AssignRef(type);
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteType(s, objects_[i]);
    }
  }

 private:
  Type& type_ = Type::Handle();
  Class& cls_ = Class::Handle();

  // Type::Canonicalize does not actually put all canonical Type objects into
  // canonical_types set. Some of the canonical declaration types (but not all
  // of them) are simply cached in UntaggedClass::declaration_type_ and are not
  // inserted into the canonical_types set.
  // Keep in sync with Type::Canonicalize.
  virtual bool IsInCanonicalSet(Serializer* s, TypePtr type) {
    ClassPtr type_class =
        s->isolate_group()->class_table()->At(type->untag()->type_class_id());
    if (type_class->untag()->declaration_type() != type) {
      return true;
    }

    type_ = type;
    cls_ = type_class;
    return !type_.IsDeclarationTypeOf(cls_);
  }

  void WriteType(Serializer* s, TypePtr type) {
    AutoTraceObject(type);
#if defined(DART_PRECOMPILER)
    if (FLAG_write_v8_snapshot_profile_to != nullptr) {
      ClassPtr type_class =
          s->isolate_group()->class_table()->At(type->untag()->type_class_id());
      s->AttributePropertyRef(type_class, "<type_class>");
    }
#endif
    WriteFromTo(type);
    s->WriteUnsigned(type->untag()->flags());
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeDeserializationCluster
    : public CanonicalSetDeserializationCluster<
          CanonicalTypeSet,
          /*kAllCanonicalObjectsAreIncludedIntoSet=*/false> {
 public:
  explicit TypeDeserializationCluster(bool is_canonical, bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical, is_root_unit, "Type") {
  }
  ~TypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Type::InstanceSize());
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypePtr type = static_cast<TypePtr>(d.Ref(id));
      Deserializer::InitializeHeader(type, kTypeCid, Type::InstanceSize(),
                                     mark_canonical);
      d.ReadFromTo(type);
      type->untag()->set_flags(d.ReadUnsigned());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(d, refs,
                         Array::Handle(object_store->canonical_types()));
      object_store->set_canonical_types(table_);
    } else if (!primary && is_canonical()) {
      AbstractType& type = AbstractType::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        type ^= refs.At(i);
        type = type.Canonicalize(d->thread());
        refs.SetAt(i, type);
      }
    }

    Type& type = Type::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        type.UpdateTypeTestingStubEntryPoint();
      }
    } else {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type);
        type.InitializeTypeTestingStubNonAtomic(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FunctionTypeSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalFunctionTypeSet,
                                              FunctionType,
                                              FunctionTypePtr> {
 public:
  explicit FunctionTypeSerializationCluster(bool is_canonical,
                                            bool represents_canonical_set)
      : CanonicalSetSerializationCluster(
            kFunctionTypeCid,
            is_canonical,
            represents_canonical_set,
            "FunctionType",
            compiler::target::FunctionType::InstanceSize()) {}
  ~FunctionTypeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    FunctionTypePtr type = FunctionType::RawCast(object);
    objects_.Add(type);
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);

    for (intptr_t i = 0; i < count; i++) {
      FunctionTypePtr type = objects_[i];
      s->AssignRef(type);
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteFunctionType(s, objects_[i]);
    }
  }

 private:
  void WriteFunctionType(Serializer* s, FunctionTypePtr type) {
    AutoTraceObject(type);
    WriteFromTo(type);
    ASSERT(Utils::IsUint(8, type->untag()->flags()));
    s->Write<uint8_t>(type->untag()->flags());
    s->Write<uint32_t>(type->untag()->packed_parameter_counts_);
    s->Write<uint16_t>(type->untag()->packed_type_parameter_counts_);
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class FunctionTypeDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalFunctionTypeSet> {
 public:
  explicit FunctionTypeDeserializationCluster(bool is_canonical,
                                              bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "FunctionType") {}
  ~FunctionTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, FunctionType::InstanceSize());
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      FunctionTypePtr type = static_cast<FunctionTypePtr>(d.Ref(id));
      Deserializer::InitializeHeader(
          type, kFunctionTypeCid, FunctionType::InstanceSize(), mark_canonical);
      d.ReadFromTo(type);
      type->untag()->set_flags(d.Read<uint8_t>());
      type->untag()->packed_parameter_counts_ = d.Read<uint32_t>();
      type->untag()->packed_type_parameter_counts_ = d.Read<uint16_t>();
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(
          d, refs, Array::Handle(object_store->canonical_function_types()));
      object_store->set_canonical_function_types(table_);
    } else if (!primary && is_canonical()) {
      AbstractType& type = AbstractType::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        type ^= refs.At(i);
        type = type.Canonicalize(d->thread());
        refs.SetAt(i, type);
      }
    }

    FunctionType& type = FunctionType::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        type.UpdateTypeTestingStubEntryPoint();
      }
    } else {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type);
        type.InitializeTypeTestingStubNonAtomic(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RecordTypeSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalRecordTypeSet,
                                              RecordType,
                                              RecordTypePtr> {
 public:
  RecordTypeSerializationCluster(bool is_canonical,
                                 bool represents_canonical_set)
      : CanonicalSetSerializationCluster(
            kRecordTypeCid,
            is_canonical,
            represents_canonical_set,
            "RecordType",
            compiler::target::RecordType::InstanceSize()) {}
  ~RecordTypeSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    RecordTypePtr type = RecordType::RawCast(object);
    objects_.Add(type);
    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);

    for (intptr_t i = 0; i < count; i++) {
      RecordTypePtr type = objects_[i];
      s->AssignRef(type);
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WriteRecordType(s, objects_[i]);
    }
  }

 private:
  void WriteRecordType(Serializer* s, RecordTypePtr type) {
    AutoTraceObject(type);
    WriteFromTo(type);
    ASSERT(Utils::IsUint(8, type->untag()->flags()));
    s->Write<uint8_t>(type->untag()->flags());
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RecordTypeDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalRecordTypeSet> {
 public:
  RecordTypeDeserializationCluster(bool is_canonical, bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "RecordType") {}
  ~RecordTypeDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, RecordType::InstanceSize());
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      RecordTypePtr type = static_cast<RecordTypePtr>(d.Ref(id));
      Deserializer::InitializeHeader(
          type, kRecordTypeCid, RecordType::InstanceSize(), mark_canonical);
      d.ReadFromTo(type);
      type->untag()->set_flags(d.Read<uint8_t>());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(d, refs,
                         Array::Handle(object_store->canonical_record_types()));
      object_store->set_canonical_record_types(table_);
    } else if (!primary && is_canonical()) {
      AbstractType& type = AbstractType::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        type ^= refs.At(i);
        type = type.Canonicalize(d->thread());
        refs.SetAt(i, type);
      }
    }

    RecordType& type = RecordType::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        type.UpdateTypeTestingStubEntryPoint();
      }
    } else {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type);
        type.InitializeTypeTestingStubNonAtomic(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypeParameterSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalTypeParameterSet,
                                              TypeParameter,
                                              TypeParameterPtr> {
 public:
  TypeParameterSerializationCluster(bool is_canonical,
                                    bool cluster_represents_canonical_set)
      : CanonicalSetSerializationCluster(
            kTypeParameterCid,
            is_canonical,
            cluster_represents_canonical_set,
            "TypeParameter",
            compiler::target::TypeParameter::InstanceSize()) {}
  ~TypeParameterSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypeParameterPtr type = TypeParameter::RawCast(object);
    objects_.Add(type);

    PushFromTo(type);
  }

  void WriteAlloc(Serializer* s) {
    intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);
    for (intptr_t i = 0; i < count; i++) {
      TypeParameterPtr type = objects_[i];
      s->AssignRef(type);
    }
    WriteCanonicalSetLayout(s);
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
    s->Write<uint16_t>(type->untag()->base_);
    s->Write<uint16_t>(type->untag()->index_);
    ASSERT(Utils::IsUint(8, type->untag()->flags()));
    s->Write<uint8_t>(type->untag()->flags());
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypeParameterDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalTypeParameterSet> {
 public:
  explicit TypeParameterDeserializationCluster(bool is_canonical,
                                               bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "TypeParameter") {}
  ~TypeParameterDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, TypeParameter::InstanceSize());
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypeParameterPtr type = static_cast<TypeParameterPtr>(d.Ref(id));
      Deserializer::InitializeHeader(type, kTypeParameterCid,
                                     TypeParameter::InstanceSize(),
                                     mark_canonical);
      d.ReadFromTo(type);
      type->untag()->base_ = d.Read<uint16_t>();
      type->untag()->index_ = d.Read<uint16_t>();
      type->untag()->set_flags(d.Read<uint8_t>());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(
          d, refs, Array::Handle(object_store->canonical_type_parameters()));
      object_store->set_canonical_type_parameters(table_);
    } else if (!primary && is_canonical()) {
      TypeParameter& type_param = TypeParameter::Handle(d->zone());
      for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
        type_param ^= refs.At(i);
        type_param ^= type_param.Canonicalize(d->thread());
        refs.SetAt(i, type_param);
      }
    }

    TypeParameter& type_param = TypeParameter::Handle(d->zone());
    Code& stub = Code::Handle(d->zone());

    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type_param ^= refs.At(id);
        type_param.UpdateTypeTestingStubEntryPoint();
      }
    } else {
      for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
        type_param ^= refs.At(id);
        stub = TypeTestingStubGenerator::DefaultCodeForType(type_param);
        type_param.InitializeTypeTestingStubNonAtomic(stub);
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ClosureSerializationCluster : public SerializationCluster {
 public:
  explicit ClosureSerializationCluster(bool is_canonical)
      : SerializationCluster("Closure",
                             kClosureCid,
                             compiler::target::Closure::InstanceSize(),
                             is_canonical) {}
  ~ClosureSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ClosurePtr closure = Closure::RawCast(object);
    objects_.Add(closure);
    PushFromTo(closure);
  }

  void WriteAlloc(Serializer* s) {
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

class ClosureDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit ClosureDeserializationCluster(bool is_canonical)
      : AbstractInstanceDeserializationCluster("Closure", is_canonical) {}
  ~ClosureDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Closure::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ClosurePtr closure = static_cast<ClosurePtr>(d.Ref(id));
      Deserializer::InitializeHeader(closure, kClosureCid,
                                     Closure::InstanceSize(), mark_canonical);
      d.ReadFromTo(closure);
#if defined(DART_PRECOMPILED_RUNTIME)
      closure->untag()->entry_point_ = 0;
#endif
    }
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    // We only cache the entry point in bare instructions mode (as we need
    // to load the function anyway otherwise).
    ASSERT(d->kind() == Snapshot::kFullAOT);
    auto& closure = Closure::Handle(d->zone());
    auto& func = Function::Handle(d->zone());
    for (intptr_t i = start_index_, n = stop_index_; i < n; i++) {
      closure ^= refs.At(i);
      func = closure.function();
      uword entry_point = func.entry_point();
      ASSERT(entry_point != 0);
      closure.ptr()->untag()->entry_point_ = entry_point;
    }
  }
#endif
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MintSerializationCluster : public SerializationCluster {
 public:
  explicit MintSerializationCluster(bool is_canonical)
      : SerializationCluster("int", kMintCid, kSizeVaries, is_canonical) {}
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
    s->WriteUnsigned(smis_.length() + mints_.length());
    for (intptr_t i = 0; i < smis_.length(); i++) {
      SmiPtr smi = smis_[i];
      s->AssignRef(smi);
      AutoTraceObject(smi);
      const int64_t value = Smi::Value(smi);
      s->Write<int64_t>(value);
      if (!Smi::IsValid(value)) {
        // This Smi will become a Mint when loaded.
        target_memory_size_ += compiler::target::Mint::InstanceSize();
      }
    }
    for (intptr_t i = 0; i < mints_.length(); i++) {
      MintPtr mint = mints_[i];
      s->AssignRef(mint);
      AutoTraceObject(mint);
      s->Write<int64_t>(mint->untag()->value_);
      // All Mints on the host should be Mints on the target.
      ASSERT(!Smi::IsValid(mint->untag()->value_));
      target_memory_size_ += compiler::target::Mint::InstanceSize();
    }
  }

  void WriteFill(Serializer* s) {}

 private:
  GrowableArray<SmiPtr> smis_;
  GrowableArray<MintPtr> mints_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MintDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit MintDeserializationCluster(bool is_canonical)
      : AbstractInstanceDeserializationCluster("int", is_canonical) {}
  ~MintDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    const bool mark_canonical = is_canonical();
    for (intptr_t i = 0; i < count; i++) {
      int64_t value = d->Read<int64_t>();
      if (Smi::IsValid(value)) {
        d->AssignRef(Smi::New(value));
      } else {
        MintPtr mint = static_cast<MintPtr>(d->Allocate(Mint::InstanceSize()));
        Deserializer::InitializeHeader(mint, kMintCid, Mint::InstanceSize(),
                                       mark_canonical);
        mint->untag()->value_ = value;
        d->AssignRef(mint);
      }
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) { Deserializer::Local d(d_); }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class DoubleSerializationCluster : public SerializationCluster {
 public:
  explicit DoubleSerializationCluster(bool is_canonical)
      : SerializationCluster("double",
                             kDoubleCid,
                             compiler::target::Double::InstanceSize(),
                             is_canonical) {}
  ~DoubleSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    DoublePtr dbl = Double::RawCast(object);
    objects_.Add(dbl);
  }

  void WriteAlloc(Serializer* s) {
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
      s->Write<double>(dbl->untag()->value_);
    }
  }

 private:
  GrowableArray<DoublePtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class DoubleDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit DoubleDeserializationCluster(bool is_canonical)
      : AbstractInstanceDeserializationCluster("double", is_canonical) {}
  ~DoubleDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Double::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);
    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      DoublePtr dbl = static_cast<DoublePtr>(d.Ref(id));
      Deserializer::InitializeHeader(dbl, kDoubleCid, Double::InstanceSize(),
                                     mark_canonical);
      dbl->untag()->value_ = d.Read<double>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class GrowableObjectArraySerializationCluster : public SerializationCluster {
 public:
  GrowableObjectArraySerializationCluster()
      : SerializationCluster(
            "GrowableObjectArray",
            kGrowableObjectArrayCid,
            compiler::target::GrowableObjectArray::InstanceSize()) {}
  ~GrowableObjectArraySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    GrowableObjectArrayPtr array = GrowableObjectArray::RawCast(object);
    objects_.Add(array);
    PushFromTo(array);
  }

  void WriteAlloc(Serializer* s) {
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, GrowableObjectArray::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      GrowableObjectArrayPtr list =
          static_cast<GrowableObjectArrayPtr>(d.Ref(id));
      Deserializer::InitializeHeader(list, kGrowableObjectArrayCid,
                                     GrowableObjectArray::InstanceSize());
      d.ReadFromTo(list);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RecordSerializationCluster : public SerializationCluster {
 public:
  explicit RecordSerializationCluster(bool is_canonical)
      : SerializationCluster("Record", kRecordCid, kSizeVaries, is_canonical) {}
  ~RecordSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    RecordPtr record = Record::RawCast(object);
    objects_.Add(record);

    const intptr_t num_fields = Record::NumFields(record);
    for (intptr_t i = 0; i < num_fields; ++i) {
      s->Push(record->untag()->field(i));
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; ++i) {
      RecordPtr record = objects_[i];
      s->AssignRef(record);
      AutoTraceObject(record);
      const intptr_t num_fields = Record::NumFields(record);
      s->WriteUnsigned(num_fields);
      target_memory_size_ += compiler::target::Record::InstanceSize(num_fields);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; ++i) {
      RecordPtr record = objects_[i];
      AutoTraceObject(record);
      const RecordShape shape(record->untag()->shape());
      s->WriteUnsigned(shape.AsInt());
      const intptr_t num_fields = shape.num_fields();
      for (intptr_t j = 0; j < num_fields; ++j) {
        s->WriteElementRef(record->untag()->field(j), j);
      }
    }
  }

 private:
  GrowableArray<RecordPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class RecordDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit RecordDeserializationCluster(bool is_canonical)
      : AbstractInstanceDeserializationCluster("Record", is_canonical) {}
  ~RecordDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t num_fields = d->ReadUnsigned();
      d->AssignRef(d->Allocate(Record::InstanceSize(num_fields)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const bool stamp_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      RecordPtr record = static_cast<RecordPtr>(d.Ref(id));
      const intptr_t shape = d.ReadUnsigned();
      const intptr_t num_fields = RecordShape(shape).num_fields();
      Deserializer::InitializeHeader(record, kRecordCid,
                                     Record::InstanceSize(num_fields),
                                     stamp_canonical);
      record->untag()->shape_ = Smi::New(shape);
      for (intptr_t j = 0; j < num_fields; ++j) {
        record->untag()->data()[j] = d.ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypedDataSerializationCluster : public SerializationCluster {
 public:
  explicit TypedDataSerializationCluster(intptr_t cid)
      : SerializationCluster("TypedData", cid) {}
  ~TypedDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypedDataPtr data = TypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    const intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataPtr data = objects_[i];
      s->AssignRef(data);
      AutoTraceObject(data);
      const intptr_t length = Smi::Value(data->untag()->length());
      s->WriteUnsigned(length);
      target_memory_size_ +=
          compiler::target::TypedData::InstanceSize(length * element_size);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      TypedDataPtr data = objects_[i];
      AutoTraceObject(data);
      const intptr_t length = Smi::Value(data->untag()->length());
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->untag()->data());
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  GrowableArray<TypedDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit TypedDataDeserializationCluster(intptr_t cid)
      : DeserializationCluster("TypedData"), cid_(cid) {}
  ~TypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(TypedData::InstanceSize(length * element_size)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    intptr_t element_size = TypedData::ElementSizeInBytes(cid_);

    const intptr_t cid = cid_;
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypedDataPtr data = static_cast<TypedDataPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      const intptr_t length_in_bytes = length * element_size;
      Deserializer::InitializeHeader(data, cid,
                                     TypedData::InstanceSize(length_in_bytes));
      data->untag()->length_ = Smi::New(length);
      data->untag()->RecomputeDataField();
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->untag()->data());
      d.ReadBytes(cdata, length_in_bytes);
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class TypedDataViewSerializationCluster : public SerializationCluster {
 public:
  explicit TypedDataViewSerializationCluster(intptr_t cid)
      : SerializationCluster("TypedDataView",
                             cid,
                             compiler::target::TypedDataView::InstanceSize()) {}
  ~TypedDataViewSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypedDataViewPtr view = TypedDataView::RawCast(object);
    objects_.Add(view);

    PushFromTo(view);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
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
  GrowableArray<TypedDataViewPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class TypedDataViewDeserializationCluster : public DeserializationCluster {
 public:
  explicit TypedDataViewDeserializationCluster(intptr_t cid)
      : DeserializationCluster("TypedDataView"), cid_(cid) {}
  ~TypedDataViewDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, TypedDataView::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const intptr_t cid = cid_;
    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypedDataViewPtr view = static_cast<TypedDataViewPtr>(d.Ref(id));
      Deserializer::InitializeHeader(view, cid, TypedDataView::InstanceSize());
      d.ReadFromTo(view);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    ASSERT(primary || !is_canonical());
    auto& view = TypedDataView::Handle(d->zone());
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
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
      : SerializationCluster(
            "ExternalTypedData",
            cid,
            compiler::target::ExternalTypedData::InstanceSize()) {}
  ~ExternalTypedDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ExternalTypedDataPtr data = ExternalTypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
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
      const intptr_t length = Smi::Value(data->untag()->length());
      s->WriteUnsigned(length);
      uint8_t* cdata = reinterpret_cast<uint8_t*>(data->untag()->data_);
      s->Align(ExternalTypedData::kDataSerializationAlignment);
      s->WriteBytes(cdata, length * element_size);
    }
  }

 private:
  GrowableArray<ExternalTypedDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ExternalTypedDataDeserializationCluster : public DeserializationCluster {
 public:
  explicit ExternalTypedDataDeserializationCluster(intptr_t cid)
      : DeserializationCluster("ExternalTypedData"), cid_(cid) {}
  ~ExternalTypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, ExternalTypedData::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    const intptr_t cid = cid_;
    intptr_t element_size = ExternalTypedData::ElementSizeInBytes(cid);
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ExternalTypedDataPtr data = static_cast<ExternalTypedDataPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(data, cid,
                                     ExternalTypedData::InstanceSize());
      data->untag()->length_ = Smi::New(length);
      d.Align(ExternalTypedData::kDataSerializationAlignment);
      data->untag()->data_ = const_cast<uint8_t*>(d.AddressOfCurrentPosition());
      d.Advance(length * element_size);
      // No finalizer / external size 0.
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class DeltaEncodedTypedDataSerializationCluster : public SerializationCluster {
 public:
  DeltaEncodedTypedDataSerializationCluster()
      : SerializationCluster("DeltaEncodedTypedData",
                             kDeltaEncodedTypedDataCid) {}
  ~DeltaEncodedTypedDataSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    TypedDataPtr data = TypedData::RawCast(object);
    objects_.Add(data);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      const TypedDataPtr data = objects_[i];
      const intptr_t element_size =
          TypedData::ElementSizeInBytes(data->GetClassId());
      s->AssignRef(data);
      AutoTraceObject(data);
      const intptr_t length_in_bytes =
          Smi::Value(data->untag()->length()) * element_size;
      s->WriteUnsigned(length_in_bytes);
      target_memory_size_ +=
          compiler::target::TypedData::InstanceSize(length_in_bytes);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    TypedData& typed_data = TypedData::Handle(s->zone());
    for (intptr_t i = 0; i < count; i++) {
      const TypedDataPtr data = objects_[i];
      AutoTraceObject(data);
      const intptr_t cid = data->GetClassId();
      // Only Uint16 and Uint32 typed data is supported at the moment. So encode
      // which this is in the low bit of the length. Uint16 is 0, Uint32 is 1.
      ASSERT(cid == kTypedDataUint16ArrayCid ||
             cid == kTypedDataUint32ArrayCid);
      const intptr_t cid_flag = cid == kTypedDataUint16ArrayCid ? 0 : 1;
      const intptr_t length = Smi::Value(data->untag()->length());
      const intptr_t encoded_length = (length << 1) | cid_flag;
      s->WriteUnsigned(encoded_length);
      intptr_t prev = 0;
      typed_data = data;
      for (intptr_t j = 0; j < length; ++j) {
        const intptr_t value = (cid == kTypedDataUint16ArrayCid)
                                   ? typed_data.GetUint16(j << 1)
                                   : typed_data.GetUint32(j << 2);
        ASSERT(value >= prev);
        s->WriteUnsigned(value - prev);
        prev = value;
      }
    }
  }

 private:
  GrowableArray<TypedDataPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class DeltaEncodedTypedDataDeserializationCluster
    : public DeserializationCluster {
 public:
  DeltaEncodedTypedDataDeserializationCluster()
      : DeserializationCluster("DeltaEncodedTypedData") {}
  ~DeltaEncodedTypedDataDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length_in_bytes = d->ReadUnsigned();
      d->AssignRef(d->Allocate(TypedData::InstanceSize(length_in_bytes)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);
    TypedData& typed_data = TypedData::Handle(d_->zone());

    ASSERT(!is_canonical());  // Never canonical.

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      TypedDataPtr data = static_cast<TypedDataPtr>(d.Ref(id));
      const intptr_t encoded_length = d.ReadUnsigned();
      const intptr_t length = encoded_length >> 1;
      const intptr_t cid = (encoded_length & 0x1) == 0
                               ? kTypedDataUint16ArrayCid
                               : kTypedDataUint32ArrayCid;
      const intptr_t element_size = TypedData::ElementSizeInBytes(cid);
      const intptr_t length_in_bytes = length * element_size;
      Deserializer::InitializeHeader(data, cid,
                                     TypedData::InstanceSize(length_in_bytes));
      data->untag()->length_ = Smi::New(length);
      data->untag()->RecomputeDataField();
      intptr_t value = 0;
      typed_data = data;
      for (intptr_t j = 0; j < length; ++j) {
        value += d.ReadUnsigned();
        if (cid == kTypedDataUint16ArrayCid) {
          typed_data.SetUint16(j << 1, static_cast<uint16_t>(value));
        } else {
          typed_data.SetUint32(j << 2, value);
        }
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class StackTraceSerializationCluster : public SerializationCluster {
 public:
  StackTraceSerializationCluster()
      : SerializationCluster("StackTrace",
                             kStackTraceCid,
                             compiler::target::StackTrace::InstanceSize()) {}
  ~StackTraceSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    StackTracePtr trace = StackTrace::RawCast(object);
    objects_.Add(trace);
    PushFromTo(trace);
  }

  void WriteAlloc(Serializer* s) {
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, StackTrace::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      StackTracePtr trace = static_cast<StackTracePtr>(d.Ref(id));
      Deserializer::InitializeHeader(trace, kStackTraceCid,
                                     StackTrace::InstanceSize());
      d.ReadFromTo(trace);
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class RegExpSerializationCluster : public SerializationCluster {
 public:
  RegExpSerializationCluster()
      : SerializationCluster("RegExp",
                             kRegExpCid,
                             compiler::target::RegExp::InstanceSize()) {}
  ~RegExpSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    RegExpPtr regexp = RegExp::RawCast(object);
    objects_.Add(regexp);
    PushFromTo(regexp);
  }

  void WriteAlloc(Serializer* s) {
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
      s->Write<int32_t>(regexp->untag()->num_one_byte_registers_);
      s->Write<int32_t>(regexp->untag()->num_two_byte_registers_);
      s->Write<int8_t>(regexp->untag()->type_flags_);
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, RegExp::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      RegExpPtr regexp = static_cast<RegExpPtr>(d.Ref(id));
      Deserializer::InitializeHeader(regexp, kRegExpCid,
                                     RegExp::InstanceSize());
      d.ReadFromTo(regexp);
      regexp->untag()->num_one_byte_registers_ = d.Read<int32_t>();
      regexp->untag()->num_two_byte_registers_ = d.Read<int32_t>();
      regexp->untag()->type_flags_ = d.Read<int8_t>();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class WeakPropertySerializationCluster : public SerializationCluster {
 public:
  WeakPropertySerializationCluster()
      : SerializationCluster("WeakProperty",
                             kWeakPropertyCid,
                             compiler::target::WeakProperty::InstanceSize()) {}
  ~WeakPropertySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    WeakPropertyPtr property = WeakProperty::RawCast(object);
    objects_.Add(property);

    s->PushWeak(property->untag()->key());
  }

  void RetraceEphemerons(Serializer* s) {
    for (intptr_t i = 0; i < objects_.length(); i++) {
      WeakPropertyPtr property = objects_[i];
      if (s->IsReachable(property->untag()->key())) {
        s->Push(property->untag()->value());
      }
    }
  }

  void WriteAlloc(Serializer* s) {
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
      if (s->HasRef(property->untag()->key())) {
        s->WriteOffsetRef(property->untag()->key(), WeakProperty::key_offset());
        s->WriteOffsetRef(property->untag()->value(),
                          WeakProperty::value_offset());
      } else {
        s->WriteOffsetRef(Object::null(), WeakProperty::key_offset());
        s->WriteOffsetRef(Object::null(), WeakProperty::value_offset());
      }
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

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, WeakProperty::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    ASSERT(!is_canonical());  // Never canonical.
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      WeakPropertyPtr property = static_cast<WeakPropertyPtr>(d.Ref(id));
      Deserializer::InitializeHeader(property, kWeakPropertyCid,
                                     WeakProperty::InstanceSize());
      d.ReadFromTo(property);
      property->untag()->next_seen_by_gc_ = WeakProperty::null();
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class MapSerializationCluster : public SerializationCluster {
 public:
  MapSerializationCluster(bool is_canonical, intptr_t cid)
      : SerializationCluster("Map",
                             cid,
                             compiler::target::Map::InstanceSize(),
                             is_canonical) {}
  ~MapSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    MapPtr map = Map::RawCast(object);
    // We never have mutable hashmaps in snapshots.
    ASSERT(map->untag()->IsCanonical());
    ASSERT_EQUAL(map.GetClassId(), kConstMapCid);
    objects_.Add(map);
    PushFromTo(map);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      MapPtr map = objects_[i];
      s->AssignRef(map);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      MapPtr map = objects_[i];
      AutoTraceObject(map);
      WriteFromTo(map);
    }
  }

 private:
  GrowableArray<MapPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class MapDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit MapDeserializationCluster(bool is_canonical, intptr_t cid)
      : AbstractInstanceDeserializationCluster("Map", is_canonical),
        cid_(cid) {}
  ~MapDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Map::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const intptr_t cid = cid_;
    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      MapPtr map = static_cast<MapPtr>(d.Ref(id));
      Deserializer::InitializeHeader(map, cid, Map::InstanceSize(),
                                     mark_canonical);
      d.ReadFromTo(map);
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class SetSerializationCluster : public SerializationCluster {
 public:
  SetSerializationCluster(bool is_canonical, intptr_t cid)
      : SerializationCluster("Set",
                             cid,
                             compiler::target::Set::InstanceSize(),
                             is_canonical) {}
  ~SetSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    SetPtr set = Set::RawCast(object);
    // We never have mutable hashsets in snapshots.
    ASSERT(set->untag()->IsCanonical());
    ASSERT_EQUAL(set.GetClassId(), kConstSetCid);
    objects_.Add(set);
    PushFromTo(set);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      SetPtr set = objects_[i];
      s->AssignRef(set);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      SetPtr set = objects_[i];
      AutoTraceObject(set);
      WriteFromTo(set);
    }
  }

 private:
  GrowableArray<SetPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class SetDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit SetDeserializationCluster(bool is_canonical, intptr_t cid)
      : AbstractInstanceDeserializationCluster("Set", is_canonical),
        cid_(cid) {}
  ~SetDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    ReadAllocFixedSize(d, Set::InstanceSize());
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const intptr_t cid = cid_;
    const bool mark_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      SetPtr set = static_cast<SetPtr>(d.Ref(id));
      Deserializer::InitializeHeader(set, cid, Set::InstanceSize(),
                                     mark_canonical);
      d.ReadFromTo(set);
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class ArraySerializationCluster : public SerializationCluster {
 public:
  ArraySerializationCluster(bool is_canonical, intptr_t cid)
      : SerializationCluster("Array", cid, kSizeVaries, is_canonical) {}
  ~ArraySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    ArrayPtr array = Array::RawCast(object);
    objects_.Add(array);

    s->Push(array->untag()->type_arguments());
    const intptr_t length = Smi::Value(array->untag()->length());
    for (intptr_t i = 0; i < length; i++) {
      s->Push(array->untag()->element(i));
    }
  }

#if defined(DART_PRECOMPILER)
  static bool IsReadOnlyCid(intptr_t cid) {
    switch (cid) {
      case kPcDescriptorsCid:
      case kCodeSourceMapCid:
      case kCompressedStackMapsCid:
      case kOneByteStringCid:
      case kTwoByteStringCid:
        return true;
      default:
        return false;
    }
  }
#endif  // defined(DART_PRECOMPILER)

  void WriteAlloc(Serializer* s) {
#if defined(DART_PRECOMPILER)
    if (FLAG_print_array_optimization_candidates) {
      intptr_t array_count = objects_.length();
      intptr_t array_count_allsmi = 0;
      intptr_t array_count_allro = 0;
      intptr_t array_count_empty = 0;
      intptr_t element_count = 0;
      intptr_t element_count_allsmi = 0;
      intptr_t element_count_allro = 0;
      for (intptr_t i = 0; i < array_count; i++) {
        ArrayPtr array = objects_[i];
        bool allsmi = true;
        bool allro = true;
        const intptr_t length = Smi::Value(array->untag()->length());
        for (intptr_t i = 0; i < length; i++) {
          ObjectPtr element = array->untag()->element(i);
          intptr_t cid = element->GetClassIdMayBeSmi();
          if (!IsReadOnlyCid(cid)) allro = false;
          if (cid != kSmiCid) allsmi = false;
        }
        element_count += length;
        if (length == 0) {
          array_count_empty++;
        } else if (allsmi) {
          array_count_allsmi++;
          element_count_allsmi += length;
        } else if (allro) {
          array_count_allro++;
          element_count_allro += length;
        }
      }
      OS::PrintErr("Arrays\n");
      OS::PrintErr("  total:  %" Pd ", % " Pd " elements\n", array_count,
                   element_count);
      OS::PrintErr("  smi-only:%" Pd ", % " Pd " elements\n",
                   array_count_allsmi, element_count_allsmi);
      OS::PrintErr("  ro-only:%" Pd " , % " Pd " elements\n", array_count_allro,
                   element_count_allro);
      OS::PrintErr("  empty:%" Pd "\n", array_count_empty);
    }
#endif  // defined(DART_PRECOMPILER)

    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      ArrayPtr array = objects_[i];
      s->AssignRef(array);
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->untag()->length());
      s->WriteUnsigned(length);
      target_memory_size_ += compiler::target::Array::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      ArrayPtr array = objects_[i];
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->untag()->length());
      s->WriteUnsigned(length);
      WriteCompressedField(array, type_arguments);
      for (intptr_t j = 0; j < length; j++) {
        s->WriteElementRef(array->untag()->element(j), j);
      }
    }
  }

 private:
  GrowableArray<ArrayPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ArrayDeserializationCluster
    : public AbstractInstanceDeserializationCluster {
 public:
  explicit ArrayDeserializationCluster(bool is_canonical, intptr_t cid)
      : AbstractInstanceDeserializationCluster("Array", is_canonical),
        cid_(cid) {}
  ~ArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(Array::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    const intptr_t cid = cid_;
    const bool stamp_canonical = primary && is_canonical();
    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      ArrayPtr array = static_cast<ArrayPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(array, cid, Array::InstanceSize(length),
                                     stamp_canonical);
      array->untag()->type_arguments_ =
          static_cast<TypeArgumentsPtr>(d.ReadRef());
      array->untag()->length_ = Smi::New(length);
      for (intptr_t j = 0; j < length; j++) {
        array->untag()->data()[j] = d.ReadRef();
      }
    }
  }

 private:
  const intptr_t cid_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class WeakArraySerializationCluster : public SerializationCluster {
 public:
  WeakArraySerializationCluster()
      : SerializationCluster("WeakArray", kWeakArrayCid, kSizeVaries) {}
  ~WeakArraySerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    WeakArrayPtr array = WeakArray::RawCast(object);
    objects_.Add(array);

    const intptr_t length = Smi::Value(array->untag()->length());
    for (intptr_t i = 0; i < length; i++) {
      s->PushWeak(array->untag()->element(i));
    }
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    for (intptr_t i = 0; i < count; i++) {
      WeakArrayPtr array = objects_[i];
      s->AssignRef(array);
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->untag()->length());
      s->WriteUnsigned(length);
      target_memory_size_ += compiler::target::WeakArray::InstanceSize(length);
    }
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      WeakArrayPtr array = objects_[i];
      AutoTraceObject(array);
      const intptr_t length = Smi::Value(array->untag()->length());
      s->WriteUnsigned(length);
      for (intptr_t j = 0; j < length; j++) {
        if (s->HasRef(array->untag()->element(j))) {
          s->WriteElementRef(array->untag()->element(j), j);
        } else {
          s->WriteElementRef(Object::null(), j);
        }
      }
    }
  }

 private:
  GrowableArray<WeakArrayPtr> objects_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class WeakArrayDeserializationCluster : public DeserializationCluster {
 public:
  WeakArrayDeserializationCluster() : DeserializationCluster("WeakArray") {}
  ~WeakArrayDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t length = d->ReadUnsigned();
      d->AssignRef(d->Allocate(WeakArray::InstanceSize(length)));
    }
    stop_index_ = d->next_index();
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      WeakArrayPtr array = static_cast<WeakArrayPtr>(d.Ref(id));
      const intptr_t length = d.ReadUnsigned();
      Deserializer::InitializeHeader(array, kWeakArrayCid,
                                     WeakArray::InstanceSize(length), false);
      array->untag()->next_seen_by_gc_ = WeakArray::null();
      array->untag()->length_ = Smi::New(length);
      for (intptr_t j = 0; j < length; j++) {
        array->untag()->data()[j] = d.ReadRef();
      }
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class StringSerializationCluster
    : public CanonicalSetSerializationCluster<CanonicalStringSet,
                                              String,
                                              StringPtr> {
 public:
  // To distinguish one and two byte strings, we put a bit in the length to
  // indicate which it is. The length is an unsigned SMI, so we actually have
  // two spare bits available. Keep in sync with DecodeLengthAndCid.
  static intptr_t EncodeLengthAndCid(intptr_t length, intptr_t cid) {
    ASSERT(cid == kOneByteStringCid || cid == kTwoByteStringCid);
    ASSERT(length <= compiler::target::kSmiMax);
    return (length << 1) | (cid == kTwoByteStringCid ? 0x1 : 0x0);
  }

  explicit StringSerializationCluster(bool is_canonical,
                                      bool represents_canonical_set)
      : CanonicalSetSerializationCluster(kStringCid,
                                         is_canonical,
                                         represents_canonical_set,
                                         "String",
                                         kSizeVaries) {}
  ~StringSerializationCluster() {}

  void Trace(Serializer* s, ObjectPtr object) {
    StringPtr str = static_cast<StringPtr>(object);
    objects_.Add(str);
  }

  void WriteAlloc(Serializer* s) {
    const intptr_t count = objects_.length();
    s->WriteUnsigned(count);
    ReorderObjects(s);
    for (intptr_t i = 0; i < count; i++) {
      StringPtr str = objects_[i];
      s->AssignRef(str);
      AutoTraceObject(str);
      const intptr_t cid = str->GetClassId();
      const intptr_t length = Smi::Value(str->untag()->length());
      const intptr_t encoded = EncodeLengthAndCid(length, cid);
      s->WriteUnsigned(encoded);
      target_memory_size_ +=
          cid == kOneByteStringCid
              ? compiler::target::OneByteString::InstanceSize(length)
              : compiler::target::TwoByteString::InstanceSize(length);
    }
    WriteCanonicalSetLayout(s);
  }

  void WriteFill(Serializer* s) {
    const intptr_t count = objects_.length();
    for (intptr_t i = 0; i < count; i++) {
      StringPtr str = objects_[i];
      AutoTraceObject(str);
      const intptr_t cid = str->GetClassId();
      const intptr_t length = Smi::Value(str->untag()->length());
      const intptr_t encoded = EncodeLengthAndCid(length, cid);
      s->WriteUnsigned(encoded);
      if (cid == kOneByteStringCid) {
        s->WriteBytes(static_cast<OneByteStringPtr>(str)->untag()->data(),
                      length);
      } else {
        s->WriteBytes(reinterpret_cast<uint8_t*>(
                          static_cast<TwoByteStringPtr>(str)->untag()->data()),
                      length * 2);
      }
    }
  }
};
#endif  // !DART_PRECOMPILED_RUNTIME

class StringDeserializationCluster
    : public CanonicalSetDeserializationCluster<CanonicalStringSet> {
 public:
  static intptr_t DecodeLengthAndCid(intptr_t encoded, intptr_t* out_cid) {
    *out_cid = (encoded & 0x1) != 0 ? kTwoByteStringCid : kOneByteStringCid;
    return encoded >> 1;
  }

  static intptr_t InstanceSize(intptr_t length, intptr_t cid) {
    return cid == kOneByteStringCid ? OneByteString::InstanceSize(length)
                                    : TwoByteString::InstanceSize(length);
  }

  explicit StringDeserializationCluster(bool is_canonical, bool is_root_unit)
      : CanonicalSetDeserializationCluster(is_canonical,
                                           is_root_unit,
                                           "String") {}
  ~StringDeserializationCluster() {}

  void ReadAlloc(Deserializer* d) {
    start_index_ = d->next_index();
    const intptr_t count = d->ReadUnsigned();
    for (intptr_t i = 0; i < count; i++) {
      const intptr_t encoded = d->ReadUnsigned();
      intptr_t cid = 0;
      const intptr_t length = DecodeLengthAndCid(encoded, &cid);
      d->AssignRef(d->Allocate(InstanceSize(length, cid)));
    }
    stop_index_ = d->next_index();
    BuildCanonicalSetFromLayout(d);
  }

  void ReadFill(Deserializer* d_, bool primary) {
    Deserializer::Local d(d_);

    for (intptr_t id = start_index_, n = stop_index_; id < n; id++) {
      StringPtr str = static_cast<StringPtr>(d.Ref(id));
      const intptr_t encoded = d.ReadUnsigned();
      intptr_t cid = 0;
      const intptr_t length = DecodeLengthAndCid(encoded, &cid);
      const intptr_t instance_size = InstanceSize(length, cid);
      // Clean up last two words of the string object to simplify future
      // string comparisons.
      // Objects are rounded up to two-word size boundary.
      *reinterpret_cast<word*>(reinterpret_cast<uint8_t*>(str->untag()) +
                               instance_size - 1 * kWordSize) = 0;
      *reinterpret_cast<word*>(reinterpret_cast<uint8_t*>(str->untag()) +
                               instance_size - 2 * kWordSize) = 0;
      Deserializer::InitializeHeader(str, cid, instance_size,
                                     primary && is_canonical());
#if DART_COMPRESSED_POINTERS
      // Gap caused by less-than-a-word length_ smi sitting before data_.
      const intptr_t length_offset =
          reinterpret_cast<intptr_t>(&str->untag()->length_);
      const intptr_t data_offset =
          cid == kOneByteStringCid
              ? reinterpret_cast<intptr_t>(
                    static_cast<OneByteStringPtr>(str)->untag()->data())
              : reinterpret_cast<intptr_t>(
                    static_cast<TwoByteStringPtr>(str)->untag()->data());
      const intptr_t length_with_gap = data_offset - length_offset;
      ASSERT(length_with_gap > kCompressedWordSize);
      ASSERT(length_with_gap == kWordSize);
      memset(reinterpret_cast<void*>(length_offset), 0, length_with_gap);
#endif
      str->untag()->length_ = Smi::New(length);

      StringHasher hasher;
      if (cid == kOneByteStringCid) {
        for (intptr_t j = 0; j < length; j++) {
          uint8_t code_unit = d.Read<uint8_t>();
          static_cast<OneByteStringPtr>(str)->untag()->data()[j] = code_unit;
          hasher.Add(code_unit);
        }

      } else {
        for (intptr_t j = 0; j < length; j++) {
          uint16_t code_unit = d.Read<uint8_t>();
          code_unit = code_unit | (d.Read<uint8_t>() << 8);
          static_cast<TwoByteStringPtr>(str)->untag()->data()[j] = code_unit;
          hasher.Add(code_unit);
        }
      }
      String::SetCachedHash(str, hasher.Finalize());
    }
  }

  void PostLoad(Deserializer* d, const Array& refs, bool primary) {
    if (!table_.IsNull()) {
      auto object_store = d->isolate_group()->object_store();
      VerifyCanonicalSet(d, refs,
                         WeakArray::Handle(object_store->symbol_table()));
      object_store->set_symbol_table(table_);
      if (d->isolate_group() == Dart::vm_isolate_group()) {
        Symbols::InitFromSnapshot(d->isolate_group());
      }
#if defined(DEBUG)
      Symbols::New(Thread::Current(), ":some:new:symbol:");
      ASSERT(object_store->symbol_table() == table_.ptr());  // Did not rehash.
#endif
    }
  }
};

#if !defined(DART_PRECOMPILED_RUNTIME)
class FakeSerializationCluster : public SerializationCluster {
 public:
  FakeSerializationCluster(const char* name,
                           intptr_t num_objects,
                           intptr_t size,
                           intptr_t target_memory_size = 0)
      : SerializationCluster(name, -1) {
    num_objects_ = num_objects;
    size_ = size;
    target_memory_size_ = target_memory_size;
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
  explicit VMSerializationRoots(const WeakArray& symbols,
                                bool should_write_symbols)
      : symbols_(symbols),
        should_write_symbols_(should_write_symbols),
        zone_(Thread::Current()->zone()) {}

  void AddBaseObjects(Serializer* s) {
    // These objects are always allocated by Object::InitOnce, so they are not
    // written into the snapshot.

    s->AddBaseObject(Object::null(), "Null", "null");
    s->AddBaseObject(Object::sentinel().ptr(), "Null", "sentinel");
    s->AddBaseObject(Object::transition_sentinel().ptr(), "Null",
                     "transition_sentinel");
    s->AddBaseObject(Object::optimized_out().ptr(), "Null", "<optimized out>");
    s->AddBaseObject(Object::empty_array().ptr(), "Array", "<empty_array>");
    s->AddBaseObject(Object::empty_instantiations_cache_array().ptr(), "Array",
                     "<empty_instantiations_cache_array>");
    s->AddBaseObject(Object::empty_subtype_test_cache_array().ptr(), "Array",
                     "<empty_subtype_test_cache_array>");
    s->AddBaseObject(Object::dynamic_type().ptr(), "Type", "<dynamic type>");
    s->AddBaseObject(Object::void_type().ptr(), "Type", "<void type>");
    s->AddBaseObject(Object::empty_type_arguments().ptr(), "TypeArguments",
                     "[]");
    s->AddBaseObject(Bool::True().ptr(), "bool", "true");
    s->AddBaseObject(Bool::False().ptr(), "bool", "false");
    ASSERT(Object::synthetic_getter_parameter_types().ptr() != Object::null());
    s->AddBaseObject(Object::synthetic_getter_parameter_types().ptr(), "Array",
                     "<synthetic getter parameter types>");
    ASSERT(Object::synthetic_getter_parameter_names().ptr() != Object::null());
    s->AddBaseObject(Object::synthetic_getter_parameter_names().ptr(), "Array",
                     "<synthetic getter parameter names>");
    s->AddBaseObject(Object::empty_context_scope().ptr(), "ContextScope",
                     "<empty>");
    s->AddBaseObject(Object::empty_object_pool().ptr(), "ObjectPool",
                     "<empty>");
    s->AddBaseObject(Object::empty_compressed_stackmaps().ptr(),
                     "CompressedStackMaps", "<empty>");
    s->AddBaseObject(Object::empty_descriptors().ptr(), "PcDescriptors",
                     "<empty>");
    s->AddBaseObject(Object::empty_var_descriptors().ptr(),
                     "LocalVarDescriptors", "<empty>");
    s->AddBaseObject(Object::empty_exception_handlers().ptr(),
                     "ExceptionHandlers", "<empty>");
    s->AddBaseObject(Object::empty_async_exception_handlers().ptr(),
                     "ExceptionHandlers", "<empty async>");

    for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
      s->AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i],
                       "ArgumentsDescriptor", "<cached arguments descriptor>");
    }
    for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
      s->AddBaseObject(ICData::cached_icdata_arrays_[i], "Array",
                       "<empty icdata entries>");
    }

    ClassTable* table = s->isolate_group()->class_table();
    for (intptr_t cid = kFirstInternalOnlyCid; cid <= kLastInternalOnlyCid;
         cid++) {
      // Error, CallSiteData has no class object.
      if (cid != kErrorCid && cid != kCallSiteDataCid) {
        ASSERT(table->HasValidClassAt(cid));
        s->AddBaseObject(
            table->At(cid), "Class",
            Class::Handle(table->At(cid))
                .NameCString(Object::NameVisibility::kInternalName));
      }
    }
    s->AddBaseObject(table->At(kDynamicCid), "Class", "dynamic");
    s->AddBaseObject(table->At(kVoidCid), "Class", "void");

    if (!Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->AddBaseObject(StubCode::EntryAt(i).ptr());
      }
    }
  }

  void PushRoots(Serializer* s) {
    if (should_write_symbols_) {
      s->Push(symbols_.ptr());
    } else {
      for (intptr_t i = 0; i < symbols_.Length(); i++) {
        s->Push(symbols_.At(i));
      }
    }
    if (Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->Push(StubCode::EntryAt(i).ptr());
      }
    }
  }

  void WriteRoots(Serializer* s) {
    s->WriteRootRef(should_write_symbols_ ? symbols_.ptr() : Object::null(),
                    "symbol-table");
    if (Snapshot::IncludesCode(s->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        s->WriteRootRef(StubCode::EntryAt(i).ptr(),
                        zone_->PrintToString("Stub:%s", StubCode::NameAt(i)));
      }
    }

    if (!should_write_symbols_ && s->profile_writer() != nullptr) {
      // If writing V8 snapshot profile create an artificial node representing
      // VM isolate symbol table.
      ASSERT(!s->IsReachable(symbols_.ptr()));
      s->AssignArtificialRef(symbols_.ptr());
      const auto& symbols_snapshot_id = s->GetProfileId(symbols_.ptr());
      s->profile_writer()->SetObjectTypeAndName(symbols_snapshot_id, "Symbols",
                                                "vm_symbols");
      s->profile_writer()->AddRoot(symbols_snapshot_id);
      for (intptr_t i = 0; i < symbols_.Length(); i++) {
        s->profile_writer()->AttributeReferenceTo(
            symbols_snapshot_id, V8SnapshotProfileWriter::Reference::Element(i),
            s->GetProfileId(symbols_.At(i)));
      }
    }
  }

 private:
  const WeakArray& symbols_;
  const bool should_write_symbols_;
  Zone* zone_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class VMDeserializationRoots : public DeserializationRoots {
 public:
  VMDeserializationRoots() : symbol_table_(WeakArray::Handle()) {}

  bool AddBaseObjects(Deserializer* d) {
    // These objects are always allocated by Object::InitOnce, so they are not
    // written into the snapshot.

    d->AddBaseObject(Object::null());
    d->AddBaseObject(Object::sentinel().ptr());
    d->AddBaseObject(Object::transition_sentinel().ptr());
    d->AddBaseObject(Object::optimized_out().ptr());
    d->AddBaseObject(Object::empty_array().ptr());
    d->AddBaseObject(Object::empty_instantiations_cache_array().ptr());
    d->AddBaseObject(Object::empty_subtype_test_cache_array().ptr());
    d->AddBaseObject(Object::dynamic_type().ptr());
    d->AddBaseObject(Object::void_type().ptr());
    d->AddBaseObject(Object::empty_type_arguments().ptr());
    d->AddBaseObject(Bool::True().ptr());
    d->AddBaseObject(Bool::False().ptr());
    ASSERT(Object::synthetic_getter_parameter_types().ptr() != Object::null());
    d->AddBaseObject(Object::synthetic_getter_parameter_types().ptr());
    ASSERT(Object::synthetic_getter_parameter_names().ptr() != Object::null());
    d->AddBaseObject(Object::synthetic_getter_parameter_names().ptr());
    d->AddBaseObject(Object::empty_context_scope().ptr());
    d->AddBaseObject(Object::empty_object_pool().ptr());
    d->AddBaseObject(Object::empty_compressed_stackmaps().ptr());
    d->AddBaseObject(Object::empty_descriptors().ptr());
    d->AddBaseObject(Object::empty_var_descriptors().ptr());
    d->AddBaseObject(Object::empty_exception_handlers().ptr());
    d->AddBaseObject(Object::empty_async_exception_handlers().ptr());

    for (intptr_t i = 0; i < ArgumentsDescriptor::kCachedDescriptorCount; i++) {
      d->AddBaseObject(ArgumentsDescriptor::cached_args_descriptors_[i]);
    }
    for (intptr_t i = 0; i < ICData::kCachedICDataArrayCount; i++) {
      d->AddBaseObject(ICData::cached_icdata_arrays_[i]);
    }

    ClassTable* table = d->isolate_group()->class_table();
    for (intptr_t cid = kFirstInternalOnlyCid; cid <= kLastInternalOnlyCid;
         cid++) {
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
        d->AddBaseObject(StubCode::EntryAt(i).ptr());
      }
    }

    return true;  // primary
  }

  void ReadRoots(Deserializer* d) {
    symbol_table_ ^= d->ReadRef();
    if (!symbol_table_.IsNull()) {
      d->isolate_group()->object_store()->set_symbol_table(symbol_table_);
    }
    if (Snapshot::IncludesCode(d->kind())) {
      for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
        Code* code = Code::ReadOnlyHandle();
        *code ^= d->ReadRef();
        StubCode::EntryAtPut(i, code);
      }
      StubCode::InitializationDone();
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    // Move remaining bump allocation space to the freelist so it used by C++
    // allocations (e.g., FinalizeVMIsolate) before allocating new pages.
    d->heap()->old_space()->AbandonBumpAllocation();

    if (!symbol_table_.IsNull()) {
      Symbols::InitFromSnapshot(d->isolate_group());
    }

    Object::set_vm_isolate_snapshot_object_table(refs);
  }

 private:
  WeakArray& symbol_table_;
};

#if !defined(DART_PRECOMPILED_RUNTIME)
static const char* const kObjectStoreFieldNames[] = {
#define DECLARE_OBJECT_STORE_FIELD(Type, Name) #Name,
    OBJECT_STORE_FIELD_LIST(DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD,
                            DECLARE_OBJECT_STORE_FIELD)
#undef DECLARE_OBJECT_STORE_FIELD
};

class ProgramSerializationRoots : public SerializationRoots {
 public:
#define RESET_ROOT_LIST(V)                                                     \
  V(symbol_table, WeakArray, HashTables::New<CanonicalStringSet>(4))           \
  V(canonical_types, Array, HashTables::New<CanonicalTypeSet>(4))              \
  V(canonical_function_types, Array,                                           \
    HashTables::New<CanonicalFunctionTypeSet>(4))                              \
  V(canonical_record_types, Array, HashTables::New<CanonicalRecordTypeSet>(4)) \
  V(canonical_type_arguments, Array,                                           \
    HashTables::New<CanonicalTypeArgumentsSet>(4))                             \
  V(canonical_type_parameters, Array,                                          \
    HashTables::New<CanonicalTypeParameterSet>(4))                             \
  ONLY_IN_PRODUCT(ONLY_IN_AOT(                                                 \
      V(closure_functions, GrowableObjectArray, GrowableObjectArray::null()))) \
  ONLY_IN_AOT(V(closure_functions_table, Array, Array::null()))                \
  ONLY_IN_AOT(V(canonicalized_stack_map_entries, CompressedStackMaps,          \
                CompressedStackMaps::null()))

  ProgramSerializationRoots(ZoneGrowableArray<Object*>* base_objects,
                            ObjectStore* object_store,
                            Snapshot::Kind snapshot_kind)
      : base_objects_(base_objects),
        object_store_(object_store),
        snapshot_kind_(snapshot_kind) {
#define ONLY_IN_AOT(code)                                                      \
  if (snapshot_kind_ == Snapshot::kFullAOT) {                                  \
    code                                                                       \
  }
#define SAVE_AND_RESET_ROOT(name, Type, init)                                  \
  do {                                                                         \
    saved_##name##_ = object_store->name();                                    \
    object_store->set_##name(Type::Handle(init));                              \
  } while (0);

    RESET_ROOT_LIST(SAVE_AND_RESET_ROOT)
#undef SAVE_AND_RESET_ROOT
#undef ONLY_IN_AOT
  }
  ~ProgramSerializationRoots() {
#define ONLY_IN_AOT(code)                                                      \
  if (snapshot_kind_ == Snapshot::kFullAOT) {                                  \
    code                                                                       \
  }
#define RESTORE_ROOT(name, Type, init)                                         \
  object_store_->set_##name(saved_##name##_);
    RESET_ROOT_LIST(RESTORE_ROOT)
#undef RESTORE_ROOT
#undef ONLY_IN_AOT
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
        s->AddBaseObject((*base_objects_)[i]->ptr());
      }
    }
  }

  void PushRoots(Serializer* s) {
    ObjectPtr* from = object_store_->from();
    ObjectPtr* to = object_store_->to_snapshot(s->kind());
    for (ObjectPtr* p = from; p <= to; p++) {
      s->Push(*p);
    }

    FieldTable* initial_field_table =
        s->thread()->isolate_group()->initial_field_table();
    for (intptr_t i = 0, n = initial_field_table->NumFieldIds(); i < n; i++) {
      s->Push(initial_field_table->At(i));
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

    FieldTable* initial_field_table =
        s->thread()->isolate_group()->initial_field_table();
    intptr_t n = initial_field_table->NumFieldIds();
    s->WriteUnsigned(n);
    for (intptr_t i = 0; i < n; i++) {
      s->WriteRootRef(initial_field_table->At(i), "some-static-field");
    }

    // The dispatch table is serialized only for precompiled snapshots.
    s->WriteDispatchTable(dispatch_table_entries_);
  }

  virtual const CompressedStackMaps& canonicalized_stack_map_entries() const {
    return saved_canonicalized_stack_map_entries_;
  }

 private:
  ZoneGrowableArray<Object*>* const base_objects_;
  ObjectStore* const object_store_;
  const Snapshot::Kind snapshot_kind_;
  Array& dispatch_table_entries_ = Array::Handle();

#define ONLY_IN_AOT(code) code
#define DECLARE_FIELD(name, Type, init) Type& saved_##name##_ = Type::Handle();
  RESET_ROOT_LIST(DECLARE_FIELD)
#undef DECLARE_FIELD
#undef ONLY_IN_AOT
};
#endif  // !DART_PRECOMPILED_RUNTIME

class ProgramDeserializationRoots : public DeserializationRoots {
 public:
  explicit ProgramDeserializationRoots(ObjectStore* object_store)
      : object_store_(object_store) {}

  bool AddBaseObjects(Deserializer* d) {
    // N.B.: Skipping index 0 because ref 0 is illegal.
    const Array& base_objects = Object::vm_isolate_snapshot_object_table();
    for (intptr_t i = kFirstReference; i < base_objects.Length(); i++) {
      d->AddBaseObject(base_objects.At(i));
    }
    return true;  // primary
  }

  void ReadRoots(Deserializer* d) {
    // Read roots.
    ObjectPtr* from = object_store_->from();
    ObjectPtr* to = object_store_->to_snapshot(d->kind());
    for (ObjectPtr* p = from; p <= to; p++) {
      *p = d->ReadRef();
    }

    FieldTable* initial_field_table =
        d->thread()->isolate_group()->initial_field_table();
    intptr_t n = d->ReadUnsigned();
    initial_field_table->AllocateIndex(n - 1);
    for (intptr_t i = 0; i < n; i++) {
      initial_field_table->SetAt(i, d->ReadRef());
    }

    // Deserialize dispatch table (when applicable)
    d->ReadDispatchTable();
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    auto isolate_group = d->isolate_group();
    {
      SafepointWriteRwLocker ml(d->thread(), isolate_group->program_lock());
      isolate_group->class_table()->CopySizesFromClassObjects();
    }
    d->heap()->old_space()->EvaluateAfterLoading();

    auto object_store = isolate_group->object_store();
    const Array& units = Array::Handle(object_store->loading_units());
    if (!units.IsNull()) {
      LoadingUnit& unit = LoadingUnit::Handle();
      unit ^= units.At(LoadingUnit::kRootId);
      unit.set_base_objects(refs);
    }

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
      s->AddBaseObject(objects->At(i)->ptr());
    }
  }

  void PushRoots(Serializer* s) {
    for (auto deferred_object : *unit_->deferred_objects()) {
      ASSERT(deferred_object->IsCode());
      CodePtr code = static_cast<CodePtr>(deferred_object->ptr());
      ObjectPoolPtr pool = code->untag()->object_pool_;
      if (pool != ObjectPool::null()) {
        const intptr_t length = pool->untag()->length_;
        uint8_t* entry_bits = pool->untag()->entry_bits();
        for (intptr_t i = 0; i < length; i++) {
          auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
          if (entry_type == ObjectPool::EntryType::kTaggedObject) {
            s->Push(pool->untag()->data()[i].raw_obj_);
          }
        }
      }
      s->Push(code->untag()->code_source_map_);
    }
  }

  void WriteRoots(Serializer* s) {
#if defined(DART_PRECOMPILER)
    intptr_t start_index = 0;
    intptr_t num_deferred_objects = unit_->deferred_objects()->length();
    if (num_deferred_objects != 0) {
      start_index = s->RefId(unit_->deferred_objects()->At(0)->ptr());
      ASSERT(start_index > 0);
    }
    s->WriteUnsigned(start_index);
    s->WriteUnsigned(num_deferred_objects);
    for (intptr_t i = 0; i < num_deferred_objects; i++) {
      const Object* deferred_object = (*unit_->deferred_objects())[i];
      ASSERT(deferred_object->IsCode());
      CodePtr code = static_cast<CodePtr>(deferred_object->ptr());
      ASSERT(s->RefId(code) == (start_index + i));
      ASSERT(!Code::IsDiscarded(code));
      s->WriteInstructions(code->untag()->instructions_,
                           code->untag()->unchecked_offset_, code, false);
      s->WriteRootRef(code->untag()->code_source_map_, "deferred-code");
    }

    ObjectPoolPtr pool =
        s->isolate_group()->object_store()->global_object_pool();
    const intptr_t length = pool->untag()->length_;
    uint8_t* entry_bits = pool->untag()->entry_bits();
    intptr_t last_write = 0;
    for (intptr_t i = 0; i < length; i++) {
      auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
      if (entry_type == ObjectPool::EntryType::kTaggedObject) {
        if (s->IsWritten(pool->untag()->data()[i].raw_obj_)) {
          intptr_t skip = i - last_write;
          s->WriteUnsigned(skip);
          s->WriteRootRef(pool->untag()->data()[i].raw_obj_,
                          "deferred-literal");
          last_write = i;
        }
      }
    }
    s->WriteUnsigned(length - last_write);
#endif
  }

 private:
  LoadingUnitSerializationData* unit_;
};
#endif  // !DART_PRECOMPILED_RUNTIME

class UnitDeserializationRoots : public DeserializationRoots {
 public:
  explicit UnitDeserializationRoots(const LoadingUnit& unit) : unit_(unit) {}

  bool AddBaseObjects(Deserializer* d) {
    const Array& base_objects =
        Array::Handle(LoadingUnit::Handle(unit_.parent()).base_objects());
    for (intptr_t i = kFirstReference; i < base_objects.Length(); i++) {
      d->AddBaseObject(base_objects.At(i));
    }
    return false;  // primary
  }

  void ReadRoots(Deserializer* d) {
    deferred_start_index_ = d->ReadUnsigned();
    deferred_stop_index_ = deferred_start_index_ + d->ReadUnsigned();
    for (intptr_t id = deferred_start_index_; id < deferred_stop_index_; id++) {
      CodePtr code = static_cast<CodePtr>(d->Ref(id));
      ASSERT(!Code::IsUnknownDartCode(code));
      d->ReadInstructions(code, /*deferred=*/false);
      if (code->untag()->owner_->IsHeapObject() &&
          code->untag()->owner_->IsFunction()) {
        FunctionPtr func = static_cast<FunctionPtr>(code->untag()->owner_);
        uword entry_point = code->untag()->entry_point_;
        ASSERT(entry_point != 0);
        func->untag()->entry_point_ = entry_point;
        uword unchecked_entry_point = code->untag()->unchecked_entry_point_;
        ASSERT(unchecked_entry_point != 0);
        func->untag()->unchecked_entry_point_ = unchecked_entry_point;
#if defined(DART_PRECOMPILED_RUNTIME)
        if (func->untag()->data()->IsHeapObject() &&
            func->untag()->data()->IsClosureData()) {
          // For closure functions in bare instructions mode, also update the
          // cache inside the static implicit closure object, if any.
          auto data = static_cast<ClosureDataPtr>(func->untag()->data());
          if (data->untag()->closure() != Closure::null()) {
            // Closure functions only have one entry point.
            ASSERT_EQUAL(entry_point, unchecked_entry_point);
            data->untag()->closure()->untag()->entry_point_ = entry_point;
          }
        }
#endif
      }
      code->untag()->code_source_map_ =
          static_cast<CodeSourceMapPtr>(d->ReadRef());
    }

    ObjectPoolPtr pool =
        d->isolate_group()->object_store()->global_object_pool();
    const intptr_t length = pool->untag()->length_;
    uint8_t* entry_bits = pool->untag()->entry_bits();
    for (intptr_t i = d->ReadUnsigned(); i < length; i += d->ReadUnsigned()) {
      auto entry_type = ObjectPool::TypeBits::decode(entry_bits[i]);
      ASSERT(entry_type == ObjectPool::EntryType::kTaggedObject);
      // The existing entry will usually be null, but it might also be an
      // equivalent object that was duplicated in another loading unit.
      pool->untag()->data()[i].raw_obj_ = d->ReadRef();
    }

    // Reinitialize the dispatch table by rereading the table's serialization
    // in the root snapshot.
    auto isolate_group = d->isolate_group();
    if (isolate_group->dispatch_table_snapshot() != nullptr) {
      ReadStream stream(isolate_group->dispatch_table_snapshot(),
                        isolate_group->dispatch_table_snapshot_size());
      const GrowableObjectArray& tables = GrowableObjectArray::Handle(
          isolate_group->object_store()->instructions_tables());
      InstructionsTable& root_table = InstructionsTable::Handle();
      root_table ^= tables.At(0);
      d->ReadDispatchTable(&stream, /*deferred=*/true, root_table,
                           deferred_start_index_, deferred_stop_index_);
    }
  }

  void PostLoad(Deserializer* d, const Array& refs) {
    d->EndInstructions();
    unit_.set_base_objects(refs);
  }

 private:
  const LoadingUnit& unit_;
  intptr_t deferred_start_index_;
  intptr_t deferred_stop_index_;
};

#if defined(DEBUG)
static constexpr int32_t kSectionMarker = 0xABAB;
#endif

Serializer::Serializer(Thread* thread,
                       Snapshot::Kind kind,
                       NonStreamingWriteStream* stream,
                       ImageWriter* image_writer,
                       bool vm,
                       V8SnapshotProfileWriter* profile_writer)
    : ThreadStackResource(thread),
      heap_(thread->isolate_group()->heap()),
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
  num_cids_ = thread->isolate_group()->class_table()->NumCids();
  num_tlc_cids_ = thread->isolate_group()->class_table()->NumTopLevelCids();
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
  // Don't assign references to the discarded code.
  const bool is_discarded_code = base_object->IsHeapObject() &&
                                 base_object->IsCode() &&
                                 Code::IsDiscarded(Code::RawCast(base_object));
  if (!is_discarded_code) {
    AssignRef(base_object);
  }
  num_base_objects_++;

  if ((profile_writer_ != nullptr) && (type != nullptr)) {
    const auto& profile_id = GetProfileId(base_object);
    profile_writer_->SetObjectTypeAndName(profile_id, type, name);
    profile_writer_->AddRoot(profile_id);
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
  const intptr_t ref = -(next_ref_index_++);
  ASSERT(IsArtificialReference(ref));
  if (object != nullptr) {
    ASSERT(!object.IsHeapObject() || !object.IsInstructions());
    ASSERT(heap_->GetObjectId(object) == kUnreachableReference);
    heap_->SetObjectId(object, ref);
    ASSERT(heap_->GetObjectId(object) == ref);
  }
  return ref;
}

void Serializer::FlushProfile() {
  if (profile_writer_ == nullptr) return;
  const intptr_t bytes =
      stream_->Position() - object_currently_writing_.last_stream_position_;
  profile_writer_->AttributeBytesTo(object_currently_writing_.id_, bytes);
  object_currently_writing_.last_stream_position_ = stream_->Position();
}

V8SnapshotProfileWriter::ObjectId Serializer::GetProfileId(
    ObjectPtr object) const {
  // Instructions are handled separately.
  ASSERT(!object->IsHeapObject() || !object->IsInstructions());
  return GetProfileId(UnsafeRefId(object));
}

V8SnapshotProfileWriter::ObjectId Serializer::GetProfileId(
    intptr_t heap_id) const {
  if (IsArtificialReference(heap_id)) {
    return {IdSpace::kArtificial, -heap_id};
  }
  ASSERT(IsAllocatedReference(heap_id));
  return {IdSpace::kSnapshot, heap_id};
}

void Serializer::AttributeReference(
    ObjectPtr object,
    const V8SnapshotProfileWriter::Reference& reference) {
  if (profile_writer_ == nullptr) return;
  const auto& object_id = GetProfileId(object);
#if defined(DART_PRECOMPILER)
  if (object->IsHeapObject() && object->IsWeakSerializationReference()) {
    auto const wsr = WeakSerializationReference::RawCast(object);
    auto const target = wsr->untag()->target();
    const auto& target_id = GetProfileId(target);
    if (object_id != target_id) {
      const auto& replacement_id = GetProfileId(wsr->untag()->replacement());
      ASSERT(object_id == replacement_id);
      // The target of the WSR will be replaced in the snapshot, so write
      // attributions for both the dropped target and for the replacement.
      profile_writer_->AttributeDroppedReferenceTo(
          object_currently_writing_.id_, reference, target_id, replacement_id);
      return;
    }
    // The replacement isn't used for this WSR in the snapshot, as either the
    // target is strongly referenced or the WSR itself is unreachable, so fall
    // through to attributing a reference to the WSR (which shares the profile
    // ID of the target).
  }
#endif
  profile_writer_->AttributeReferenceTo(object_currently_writing_.id_,
                                        reference, object_id);
}

Serializer::WritingObjectScope::WritingObjectScope(
    Serializer* serializer,
    const V8SnapshotProfileWriter::ObjectId& id,
    ObjectPtr object)
    : serializer_(serializer),
      old_object_(serializer->object_currently_writing_.object_),
      old_id_(serializer->object_currently_writing_.id_),
      old_cid_(serializer->object_currently_writing_.cid_) {
  if (serializer_->profile_writer_ == nullptr) return;
  // The ID should correspond to one already added appropriately to the
  // profile writer.
  ASSERT(serializer_->profile_writer_->HasId(id));
  serializer_->FlushProfile();
  serializer_->object_currently_writing_.object_ = object;
  serializer_->object_currently_writing_.id_ = id;
  serializer_->object_currently_writing_.cid_ =
      object == nullptr ? -1 : object->GetClassIdMayBeSmi();
}

Serializer::WritingObjectScope::~WritingObjectScope() {
  if (serializer_->profile_writer_ == nullptr) return;
  serializer_->FlushProfile();
  serializer_->object_currently_writing_.object_ = old_object_;
  serializer_->object_currently_writing_.id_ = old_id_;
  serializer_->object_currently_writing_.cid_ = old_cid_;
}

V8SnapshotProfileWriter::ObjectId Serializer::WritingObjectScope::ReserveId(
    Serializer* s,
    const char* type,
    ObjectPtr obj,
    const char* name) {
  if (s->profile_writer_ == nullptr) {
    return V8SnapshotProfileWriter::kArtificialRootId;
  }
  if (name == nullptr) {
    // Handle some cases where there are obvious names to assign.
    switch (obj->GetClassIdMayBeSmi()) {
      case kSmiCid: {
        name = OS::SCreate(s->zone(), "%" Pd "", Smi::Value(Smi::RawCast(obj)));
        break;
      }
      case kMintCid: {
        name = OS::SCreate(s->zone(), "%" Pd64 "",
                           Mint::RawCast(obj)->untag()->value_);
        break;
      }
      case kOneByteStringCid:
      case kTwoByteStringCid: {
        name = String::ToCString(s->thread(), String::RawCast(obj));
        break;
      }
    }
  }
  const auto& obj_id = s->GetProfileId(obj);
  s->profile_writer_->SetObjectTypeAndName(obj_id, type, name);
  return obj_id;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
bool Serializer::CreateArtificialNodeIfNeeded(ObjectPtr obj) {
  ASSERT(profile_writer() != nullptr);

  // UnsafeRefId will do lazy reference allocation for WSRs.
  intptr_t id = UnsafeRefId(obj);
  ASSERT(id != kUnallocatedReference);
  if (id != kUnreachableReference) {
    return IsArtificialReference(id);
  }
  if (obj->IsHeapObject() && obj->IsWeakSerializationReference()) {
    auto const target =
        WeakSerializationReference::RawCast(obj)->untag()->target();
    CreateArtificialNodeIfNeeded(target);
    // Since the WSR is unreachable, we can replace its id with whatever the
    // ID of the target is, whether real or artificial.
    id = heap_->GetObjectId(target);
    heap_->SetObjectId(obj, id);
    return IsArtificialReference(id);
  }

  const char* type = nullptr;
  const char* name = nullptr;
  GrowableArray<std::pair<ObjectPtr, V8SnapshotProfileWriter::Reference>> links;
  const classid_t cid = obj->GetClassIdMayBeSmi();
  switch (cid) {
    // For profiling static call target tables in AOT mode.
    case kSmiCid: {
      type = "Smi";
      break;
    }
    // For profiling per-code object pools in bare instructions mode.
    case kObjectPoolCid: {
      type = "ObjectPool";
      auto const pool = ObjectPool::RawCast(obj);
      for (intptr_t i = 0; i < pool->untag()->length_; i++) {
        uint8_t bits = pool->untag()->entry_bits()[i];
        if (ObjectPool::TypeBits::decode(bits) ==
            ObjectPool::EntryType::kTaggedObject) {
          auto const elem = pool->untag()->data()[i].raw_obj_;
          // Elements should be reachable from the global object pool.
          ASSERT(HasRef(elem));
          links.Add({elem, V8SnapshotProfileWriter::Reference::Element(i)});
        }
      }
      break;
    }
    // For profiling static call target tables and the dispatch table in AOT.
    case kImmutableArrayCid:
    case kArrayCid: {
      type = "Array";
      auto const array = Array::RawCast(obj);
      for (intptr_t i = 0, n = Smi::Value(array->untag()->length()); i < n;
           i++) {
        ObjectPtr elem = array->untag()->element(i);
        links.Add({elem, V8SnapshotProfileWriter::Reference::Element(i)});
      }
      break;
    }
    // For profiling the dispatch table.
    case kCodeCid: {
      type = "Code";
      auto const code = Code::RawCast(obj);
      name = CodeSerializationCluster::MakeDisambiguatedCodeName(this, code);
      links.Add({code->untag()->owner(),
                 V8SnapshotProfileWriter::Reference::Property("owner_")});
      break;
    }
    case kFunctionCid: {
      FunctionPtr func = static_cast<FunctionPtr>(obj);
      type = "Function";
      name = FunctionSerializationCluster::MakeDisambiguatedFunctionName(this,
                                                                         func);
      links.Add({func->untag()->owner(),
                 V8SnapshotProfileWriter::Reference::Property("owner_")});
      ObjectPtr data = func->untag()->data();
      if (data->GetClassId() == kClosureDataCid) {
        links.Add(
            {data, V8SnapshotProfileWriter::Reference::Property("data_")});
      }
      break;
    }
    case kClosureDataCid: {
      auto data = static_cast<ClosureDataPtr>(obj);
      type = "ClosureData";
      links.Add(
          {data->untag()->parent_function(),
           V8SnapshotProfileWriter::Reference::Property("parent_function_")});
      break;
    }
    case kClassCid: {
      ClassPtr cls = static_cast<ClassPtr>(obj);
      type = "Class";
      name = String::ToCString(thread(), cls->untag()->name());
      links.Add({cls->untag()->library(),
                 V8SnapshotProfileWriter::Reference::Property("library_")});
      break;
    }
    case kPatchClassCid: {
      PatchClassPtr patch_cls = static_cast<PatchClassPtr>(obj);
      type = "PatchClass";
      links.Add(
          {patch_cls->untag()->wrapped_class(),
           V8SnapshotProfileWriter::Reference::Property("wrapped_class_")});
      break;
    }
    case kLibraryCid: {
      LibraryPtr lib = static_cast<LibraryPtr>(obj);
      type = "Library";
      name = String::ToCString(thread(), lib->untag()->url());
      break;
    }
    case kFunctionTypeCid: {
      type = "FunctionType";
      break;
    };
    case kRecordTypeCid: {
      type = "RecordType";
      break;
    };
    default:
      FATAL("Request to create artificial node for object with cid %d", cid);
  }

  id = AssignArtificialRef(obj);
  Serializer::WritingObjectScope scope(this, type, obj, name);
  for (const auto& link : links) {
    CreateArtificialNodeIfNeeded(link.first);
    AttributeReference(link.first, link.second);
  }
  return true;
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

intptr_t Serializer::RefId(ObjectPtr object) const {
  auto const id = UnsafeRefId(object);
  if (IsAllocatedReference(id)) {
    return id;
  }
  ASSERT(id == kUnreachableReference || IsArtificialReference(id));
  REUSABLE_OBJECT_HANDLESCOPE(thread());
  auto& handle = thread()->ObjectHandle();
  handle = object;
  FATAL("Reference to unreachable object %s", handle.ToCString());
}

intptr_t Serializer::UnsafeRefId(ObjectPtr object) const {
  // The object id weak table holds image offsets for Instructions instead
  // of ref indices.
  ASSERT(!object->IsHeapObject() || !object->IsInstructions());
  if (!Snapshot::IncludesCode(kind_) &&
      object->GetClassIdMayBeSmi() == kCodeCid) {
    return RefId(Object::null());
  }
  auto id = heap_->GetObjectId(object);
  if (id != kUnallocatedReference) {
    return id;
  }
  // This is the only case where we may still see unallocated references after
  // WriteAlloc is finished.
  if (object->IsWeakSerializationReference()) {
    // Lazily set the object ID of the WSR to the object which will replace
    // it in the snapshot.
    auto const wsr = static_cast<WeakSerializationReferencePtr>(object);
    // Either the target or the replacement must be allocated, since the
    // WSR is reachable.
    id = HasRef(wsr->untag()->target()) ? RefId(wsr->untag()->target())
                                        : RefId(wsr->untag()->replacement());
    heap_->SetObjectId(wsr, id);
    return id;
  }
  REUSABLE_OBJECT_HANDLESCOPE(thread());
  auto& handle = thread()->ObjectHandle();
  handle = object;
  FATAL("Reference for object %s is unallocated", handle.ToCString());
}

const char* Serializer::ReadOnlyObjectType(intptr_t cid) {
  switch (cid) {
    case kPcDescriptorsCid:
      return "PcDescriptors";
    case kCodeSourceMapCid:
      return "CodeSourceMap";
    case kCompressedStackMapsCid:
      return "CompressedStackMaps";
    case kStringCid:
      return current_loading_unit_id_ <= LoadingUnit::kRootId
                 ? "CanonicalString"
                 : nullptr;
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

SerializationCluster* Serializer::NewClusterForClass(intptr_t cid,
                                                     bool is_canonical) {
#if defined(DART_PRECOMPILED_RUNTIME)
  UNREACHABLE();
  return nullptr;
#else
  Zone* Z = zone_;
  if (cid >= kNumPredefinedCids || cid == kInstanceCid) {
    Push(isolate_group()->class_table()->At(cid));
    return new (Z) InstanceSerializationCluster(is_canonical, cid);
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

#if !defined(DART_COMPRESSED_POINTERS)
  // Sometimes we write memory images for read-only objects that contain no
  // pointers. These can be mmapped directly, needing no relocation, and added
  // to the list of heap pages. This gives us lazy/demand paging from the OS.
  // We do not do this for snapshots without code to keep snapshots portable
  // between machines with different word sizes. We do not do this when we use
  // compressed pointers because we cannot always control the load address of
  // the memory image, and it might be outside the 4GB region addressable by
  // compressed pointers.
  if (Snapshot::IncludesCode(kind_)) {
    if (auto const type = ReadOnlyObjectType(cid)) {
      return new (Z) RODataSerializationCluster(Z, type, cid, is_canonical);
    }
  }
#endif

  const bool cluster_represents_canonical_set =
      current_loading_unit_id_ <= LoadingUnit::kRootId && is_canonical;

  switch (cid) {
    case kClassCid:
      return new (Z) ClassSerializationCluster(num_cids_ + num_tlc_cids_);
    case kTypeParametersCid:
      return new (Z) TypeParametersSerializationCluster();
    case kTypeArgumentsCid:
      return new (Z) TypeArgumentsSerializationCluster(
          is_canonical, cluster_represents_canonical_set);
    case kPatchClassCid:
      return new (Z) PatchClassSerializationCluster();
    case kFunctionCid:
      return new (Z) FunctionSerializationCluster();
    case kClosureDataCid:
      return new (Z) ClosureDataSerializationCluster();
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
    case kCodeSourceMapCid:
      return new (Z) CodeSourceMapSerializationCluster();
    case kCompressedStackMapsCid:
      return new (Z) CompressedStackMapsSerializationCluster();
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
      return new (Z) TypeSerializationCluster(is_canonical,
                                              cluster_represents_canonical_set);
    case kFunctionTypeCid:
      return new (Z) FunctionTypeSerializationCluster(
          is_canonical, cluster_represents_canonical_set);
    case kRecordTypeCid:
      return new (Z) RecordTypeSerializationCluster(
          is_canonical, cluster_represents_canonical_set);
    case kTypeParameterCid:
      return new (Z) TypeParameterSerializationCluster(
          is_canonical, cluster_represents_canonical_set);
    case kClosureCid:
      return new (Z) ClosureSerializationCluster(is_canonical);
    case kMintCid:
      return new (Z) MintSerializationCluster(is_canonical);
    case kDoubleCid:
      return new (Z) DoubleSerializationCluster(is_canonical);
    case kGrowableObjectArrayCid:
      return new (Z) GrowableObjectArraySerializationCluster();
    case kRecordCid:
      return new (Z) RecordSerializationCluster(is_canonical);
    case kStackTraceCid:
      return new (Z) StackTraceSerializationCluster();
    case kRegExpCid:
      return new (Z) RegExpSerializationCluster();
    case kWeakPropertyCid:
      return new (Z) WeakPropertySerializationCluster();
    case kMapCid:
      // We do not have mutable hash maps in snapshots.
      UNREACHABLE();
    case kConstMapCid:
      return new (Z) MapSerializationCluster(is_canonical, kConstMapCid);
    case kSetCid:
      // We do not have mutable hash sets in snapshots.
      UNREACHABLE();
    case kConstSetCid:
      return new (Z) SetSerializationCluster(is_canonical, kConstSetCid);
    case kArrayCid:
      return new (Z) ArraySerializationCluster(is_canonical, kArrayCid);
    case kImmutableArrayCid:
      return new (Z)
          ArraySerializationCluster(is_canonical, kImmutableArrayCid);
    case kWeakArrayCid:
      return new (Z) WeakArraySerializationCluster();
    case kStringCid:
      return new (Z) StringSerializationCluster(
          is_canonical, cluster_represents_canonical_set && !vm_);
#define CASE_FFI_CID(name) case kFfi##name##Cid:
      CLASS_LIST_FFI_TYPE_MARKER(CASE_FFI_CID)
#undef CASE_FFI_CID
      return new (Z) InstanceSerializationCluster(is_canonical, cid);
    case kDeltaEncodedTypedDataCid:
      return new (Z) DeltaEncodedTypedDataSerializationCluster();
    case kWeakSerializationReferenceCid:
#if defined(DART_PRECOMPILER)
      ASSERT(kind_ == Snapshot::kFullAOT);
      return new (Z) WeakSerializationReferenceSerializationCluster();
#endif
    default:
      break;
  }

  // The caller will check for nullptr and provide an error with more context
  // than is available here.
  return nullptr;
#endif  // !DART_PRECOMPILED_RUNTIME
}

bool Serializer::InCurrentLoadingUnitOrRoot(ObjectPtr obj) {
  if (loading_units_ == nullptr) return true;

  intptr_t unit_id = heap_->GetLoadingUnit(obj);
  if (unit_id == WeakTable::kNoValue) {
    FATAL("Missing loading unit assignment: %s\n",
          Object::Handle(obj).ToCString());
  }
  return unit_id == LoadingUnit::kRootId || unit_id == current_loading_unit_id_;
}

void Serializer::RecordDeferredCode(CodePtr code) {
  const intptr_t unit_id = heap_->GetLoadingUnit(code);
  ASSERT(unit_id != WeakTable::kNoValue && unit_id != LoadingUnit::kRootId);
  (*loading_units_)[unit_id]->AddDeferredObject(code);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
#if defined(DART_PRECOMPILER)
// We use the following encoding schemes when encoding references to Code
// objects.
//
// In AOT mode:
//
// 0        --  LazyCompile stub
// 1        -+
//           |  for non-root-unit/non-VM snapshots
// ...        > reference into parent snapshot objects
//           |  (base is num_base_objects_ in this case, 0 otherwise).
// base     -+
// base + 1 -+
//           |  for non-deferred Code objects (those with instructions)
//            > index in into the instructions table (code_index_).
//           |  (L is code_index_.Length()).
// base + L -+
// ...      -+
//           |  for deferred Code objects (those without instructions)
//            > index of this Code object in the deferred part of the
//           |  Code cluster.
//
// Note that this encoding has the following property: non-discarded
// non-deferred Code objects form the tail of the instruction table
// which makes indices assigned to non-discarded non-deferred Code objects
// and deferred Code objects continuous. This means when decoding
// code_index - (base + 1) - first_entry_with_code yields an index of the
// Code object in the Code cluster both for non-deferred and deferred
// Code objects.
//
// For JIT snapshots we do:
//
// 0        --  LazyCompile stub
// 1        -+
//           |
// ...        > index of the Code object in the Code cluster.
//           |
//
intptr_t Serializer::GetCodeIndex(CodePtr code) {
  // In the precompiled mode Code object is uniquely identified by its
  // instructions (because ProgramVisitor::DedupInstructions will dedup Code
  // objects with the same instructions).
  if (code == StubCode::LazyCompile().ptr() && !vm_) {
    return 0;
  } else if (FLAG_precompiled_mode) {
    const intptr_t ref = heap_->GetObjectId(code);
    ASSERT(!IsReachableReference(ref) == Code::IsDiscarded(code));

    const intptr_t base =
        (vm_ || current_loading_unit_id() == LoadingUnit::kRootId)
            ? 0
            : num_base_objects_;

    // Check if we are referring to the Code object which originates from the
    // parent loading unit. In this case we write out the reference of this
    // object.
    if (!Code::IsDiscarded(code) && ref < base) {
      RELEASE_ASSERT(current_loading_unit_id() != LoadingUnit::kRootId);
      return 1 + ref;
    }

    // Otherwise the code object must either be discarded or originate from
    // the Code cluster.
    ASSERT(Code::IsDiscarded(code) || (code_cluster_->first_ref() <= ref &&
                                       ref <= code_cluster_->last_ref()));

    // If Code object is non-deferred then simply write out the index of the
    // entry point, otherwise write out the index of the deferred code object.
    if (ref < code_cluster_->first_deferred_ref()) {
      const intptr_t key = static_cast<intptr_t>(code->untag()->instructions_);
      ASSERT(code_index_.HasKey(key));
      const intptr_t result = code_index_.Lookup(key);
      ASSERT(0 < result && result <= code_index_.Length());
      // Note: result already has + 1.
      return base + result;
    } else {
      // Note: only root snapshot can have deferred Code objects in the
      // cluster.
      const intptr_t cluster_index = ref - code_cluster_->first_deferred_ref();
      return 1 + base + code_index_.Length() + cluster_index;
    }
  } else {
    const intptr_t ref = heap_->GetObjectId(code);
    ASSERT(IsAllocatedReference(ref));
    ASSERT(code_cluster_->first_ref() <= ref &&
           ref <= code_cluster_->last_ref());
    return 1 + (ref - code_cluster_->first_ref());
  }
}
#endif  // defined(DART_PRECOMPILER)

void Serializer::PrepareInstructions(
    const CompressedStackMaps& canonical_stack_map_entries) {
  if (!Snapshot::IncludesCode(kind())) return;

  // Code objects that have identical/duplicate instructions must be adjacent in
  // the order that Code objects are written because the encoding of the
  // reference from the Code to the Instructions assumes monotonically
  // increasing offsets as part of a delta encoding. Also the code order table
  // that allows for mapping return addresses back to Code objects depends on
  // this sorting.
  if (code_cluster_ != nullptr) {
    CodeSerializationCluster::Sort(this, code_cluster_->objects());
  }
  if ((loading_units_ != nullptr) &&
      (current_loading_unit_id_ == LoadingUnit::kRootId)) {
    for (intptr_t i = LoadingUnit::kRootId + 1; i < loading_units_->length();
         i++) {
      auto unit_objects = loading_units_->At(i)->deferred_objects();
      CodeSerializationCluster::Sort(this, unit_objects);
      ASSERT(unit_objects->length() == 0 || code_cluster_ != nullptr);
      for (intptr_t j = 0; j < unit_objects->length(); j++) {
        code_cluster_->deferred_objects()->Add(unit_objects->At(j)->ptr());
      }
    }
  }

#if defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
  if (kind() == Snapshot::kFullAOT) {
    // Group the code objects whose instructions are not being deferred in this
    // snapshot unit in the order they will be written: first the code objects
    // encountered for this first time in this unit being written by the
    // CodeSerializationCluster, then code object previously deferred whose
    // instructions are now written by UnitSerializationRoots. This order needs
    // to be known to finalize bare-instructions-mode's PC-relative calls.
    GrowableArray<CodePtr> code_objects;
    if (code_cluster_ != nullptr) {
      auto in = code_cluster_->objects();
      for (intptr_t i = 0; i < in->length(); i++) {
        code_objects.Add(in->At(i));
      }
    }
    if (loading_units_ != nullptr) {
      auto in =
          loading_units_->At(current_loading_unit_id_)->deferred_objects();
      for (intptr_t i = 0; i < in->length(); i++) {
        code_objects.Add(in->At(i)->ptr());
      }
    }

    GrowableArray<ImageWriterCommand> writer_commands;
    RelocateCodeObjects(vm_, &code_objects, &writer_commands);
    image_writer_->PrepareForSerialization(&writer_commands);

    if (code_objects.length() == 0) {
      return;
    }

    // Build UntaggedInstructionsTable::Data object to be added to the
    // read-only data section of the snapshot. It contains:
    //
    //    - a binary search table mapping an Instructions entry point to its
    //      stack maps (by offset from the beginning of the Data object);
    //    - followed by stack maps bytes;
    //    - followed by canonical stack map entries.
    //
    struct StackMapInfo : public ZoneAllocated {
      CompressedStackMapsPtr map;
      intptr_t use_count;
      uint32_t offset;
    };

    GrowableArray<StackMapInfo*> stack_maps;
    IntMap<StackMapInfo*> stack_maps_info;

    // Build code_index_ (which maps Instructions object to the order in
    // which they appear in the code section in the end) and collect all
    // stack maps.
    // We also find the first Instructions object which is going to have
    // Code object associated with it. This will allow to reduce the binary
    // search space when searching specifically for the code object in runtime.
    uint32_t total = 0;
    intptr_t not_discarded_count = 0;
    uint32_t first_entry_with_code = 0;
    for (auto& cmd : writer_commands) {
      if (cmd.op == ImageWriterCommand::InsertInstructionOfCode) {
        RELEASE_ASSERT(code_objects[total] ==
                       cmd.insert_instruction_of_code.code);
        ASSERT(!Code::IsDiscarded(cmd.insert_instruction_of_code.code) ||
               (not_discarded_count == 0));
        if (!Code::IsDiscarded(cmd.insert_instruction_of_code.code)) {
          if (not_discarded_count == 0) {
            first_entry_with_code = total;
          }
          not_discarded_count++;
        }
        total++;

        // Update code_index_.
        {
          const intptr_t instr = static_cast<intptr_t>(
              cmd.insert_instruction_of_code.code->untag()->instructions_);
          ASSERT(!code_index_.HasKey(instr));
          code_index_.Insert(instr, total);
        }

        // Collect stack maps.
        CompressedStackMapsPtr stack_map =
            cmd.insert_instruction_of_code.code->untag()->compressed_stackmaps_;
        const intptr_t key = static_cast<intptr_t>(stack_map);

        if (stack_maps_info.HasKey(key)) {
          stack_maps_info.Lookup(key)->use_count++;
        } else {
          auto info = new StackMapInfo();
          info->map = stack_map;
          info->use_count = 1;
          stack_maps.Add(info);
          stack_maps_info.Insert(key, info);
        }
      }
    }
    ASSERT(static_cast<intptr_t>(total) == code_index_.Length());
    instructions_table_len_ = not_discarded_count;

    // Sort stack maps by usage so that most commonly used stack maps are
    // together at the start of the Data object.
    stack_maps.Sort([](StackMapInfo* const* a, StackMapInfo* const* b) {
      if ((*a)->use_count < (*b)->use_count) return 1;
      if ((*a)->use_count > (*b)->use_count) return -1;
      return 0;
    });

    // Build Data object.
    MallocWriteStream pc_mapping(4 * KB);

    // Write the header out.
    {
      UntaggedInstructionsTable::Data header;
      memset(&header, 0, sizeof(header));
      header.length = total;
      header.first_entry_with_code = first_entry_with_code;
      pc_mapping.WriteFixed<UntaggedInstructionsTable::Data>(header);
    }

    // Reserve space for the binary search table.
    for (auto& cmd : writer_commands) {
      if (cmd.op == ImageWriterCommand::InsertInstructionOfCode) {
        pc_mapping.WriteFixed<UntaggedInstructionsTable::DataEntry>({0, 0});
      }
    }

    // Now write collected stack maps after the binary search table.
    auto write_stack_map = [&](CompressedStackMapsPtr smap) {
      const auto flags_and_size = smap->untag()->payload()->flags_and_size();
      const auto payload_size =
          UntaggedCompressedStackMaps::SizeField::decode(flags_and_size);
      pc_mapping.WriteFixed<uint32_t>(flags_and_size);
      pc_mapping.WriteBytes(smap->untag()->payload()->data(), payload_size);
    };

    for (auto sm : stack_maps) {
      sm->offset = pc_mapping.bytes_written();
      write_stack_map(sm->map);
    }

    // Write canonical entries (if any).
    if (!canonical_stack_map_entries.IsNull()) {
      auto header = reinterpret_cast<UntaggedInstructionsTable::Data*>(
          pc_mapping.buffer());
      header->canonical_stack_map_entries_offset = pc_mapping.bytes_written();
      write_stack_map(canonical_stack_map_entries.ptr());
    }
    const auto total_bytes = pc_mapping.bytes_written();

    // Now that we have offsets to all stack maps we can write binary
    // search table.
    pc_mapping.SetPosition(
        sizeof(UntaggedInstructionsTable::Data));  // Skip the header.
    for (auto& cmd : writer_commands) {
      if (cmd.op == ImageWriterCommand::InsertInstructionOfCode) {
        CompressedStackMapsPtr smap =
            cmd.insert_instruction_of_code.code->untag()->compressed_stackmaps_;
        const auto offset =
            stack_maps_info.Lookup(static_cast<intptr_t>(smap))->offset;
        const auto entry = image_writer_->GetTextOffsetFor(
            Code::InstructionsOf(cmd.insert_instruction_of_code.code),
            cmd.insert_instruction_of_code.code);

        pc_mapping.WriteFixed<UntaggedInstructionsTable::DataEntry>(
            {static_cast<uint32_t>(entry), offset});
      }
    }
    // Restore position so that Steal does not truncate the buffer.
    pc_mapping.SetPosition(total_bytes);

    intptr_t length = 0;
    uint8_t* bytes = pc_mapping.Steal(&length);

    instructions_table_rodata_offset_ =
        image_writer_->AddBytesToData(bytes, length);
    // Attribute all bytes in this object to the root for simplicity.
    if (profile_writer_ != nullptr) {
      const auto offset_space = vm_ ? IdSpace::kVmData : IdSpace::kIsolateData;
      profile_writer_->AttributeReferenceTo(
          V8SnapshotProfileWriter::kArtificialRootId,
          V8SnapshotProfileWriter::Reference::Property(
              "<instructions-table-rodata>"),
          {offset_space, instructions_table_rodata_offset_});
    }
  }
#endif  // defined(DART_PRECOMPILER) && !defined(TARGET_ARCH_IA32)
}

void Serializer::WriteInstructions(InstructionsPtr instr,
                                   uint32_t unchecked_offset,
                                   CodePtr code,
                                   bool deferred) {
  ASSERT(code != Code::null());

  ASSERT(InCurrentLoadingUnitOrRoot(code) != deferred);
  if (deferred) {
    return;
  }

  const intptr_t offset = image_writer_->GetTextOffsetFor(instr, code);
#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr) {
    ASSERT(object_currently_writing_.id_ !=
           V8SnapshotProfileWriter::kArtificialRootId);
    const auto offset_space = vm_ ? IdSpace::kVmText : IdSpace::kIsolateText;
    profile_writer_->AttributeReferenceTo(
        object_currently_writing_.id_,
        V8SnapshotProfileWriter::Reference::Property("<instructions>"),
        {offset_space, offset});
  }

  if (Code::IsDiscarded(code)) {
    // Discarded Code objects are not supported in the vm isolate snapshot.
    ASSERT(!vm_);
    return;
  }

  if (FLAG_precompiled_mode) {
    const uint32_t payload_info =
        (unchecked_offset << 1) | (Code::HasMonomorphicEntry(code) ? 0x1 : 0x0);
    WriteUnsigned(payload_info);
    return;
  }
#endif
  Write<uint32_t>(offset);
  WriteUnsigned(unchecked_offset);
}

void Serializer::TraceDataOffset(uint32_t offset) {
  if (profile_writer_ == nullptr) return;
  // ROData cannot be roots.
  ASSERT(object_currently_writing_.id_ !=
         V8SnapshotProfileWriter::kArtificialRootId);
  auto offset_space = vm_ ? IdSpace::kVmData : IdSpace::kIsolateData;
  // TODO(sjindel): Give this edge a more appropriate type than element
  // (internal, maybe?).
  profile_writer_->AttributeReferenceTo(
      object_currently_writing_.id_,
      V8SnapshotProfileWriter::Reference::Element(0), {offset_space, offset});
}

uint32_t Serializer::GetDataOffset(ObjectPtr object) const {
#if defined(SNAPSHOT_BACKTRACE)
  return image_writer_->GetDataOffsetFor(object, ParentOf(object));
#else
  return image_writer_->GetDataOffsetFor(object);
#endif
}

intptr_t Serializer::GetDataSize() const {
  if (image_writer_ == nullptr) {
    return 0;
  }
  return image_writer_->data_size();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void Serializer::Push(ObjectPtr object, intptr_t cid_override) {
  const bool is_code = object->IsHeapObject() && object->IsCode();
  if (is_code && !Snapshot::IncludesCode(kind_)) {
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
    stack_.Add({object, cid_override});
    if (!(is_code && Code::IsDiscarded(Code::RawCast(object)))) {
      num_written_objects_++;
    }
#if defined(SNAPSHOT_BACKTRACE)
    parent_pairs_.Add(&Object::Handle(zone_, object));
    parent_pairs_.Add(&Object::Handle(zone_, current_parent_));
#endif
  }
}

void Serializer::PushWeak(ObjectPtr object) {
  // The GC considers immediate objects to always be alive. This doesn't happen
  // automatically in the serializer because the serializer does not have
  // immediate objects: it handles Smis as ref indices like all other objects.
  // This visit causes the serializer to reproduce the GC's semantics for
  // weakness, which in particular allows the templates in hash_table.h to work
  // with weak arrays because the metadata Smis always survive.
  if (!object->IsHeapObject() || vm_) {
    Push(object);
  }
}

void Serializer::Trace(ObjectPtr object, intptr_t cid_override) {
  intptr_t cid;
  bool is_canonical;
  if (!object->IsHeapObject()) {
    // Smis are merged into the Mint cluster because Smis for the writer might
    // become Mints for the reader and vice versa.
    cid = kMintCid;
    is_canonical = true;
  } else {
    cid = object->GetClassId();
    is_canonical = object->untag()->IsCanonical();
  }
  if (cid_override != kIllegalCid) {
    cid = cid_override;
  } else if (IsStringClassId(cid)) {
    cid = kStringCid;
  }

  SerializationCluster** cluster_ref =
      is_canonical ? &canonical_clusters_by_cid_[cid] : &clusters_by_cid_[cid];
  if (*cluster_ref == nullptr) {
    *cluster_ref = NewClusterForClass(cid, is_canonical);
    if (*cluster_ref == nullptr) {
      UnexpectedObject(object, "No serialization cluster defined");
    }
  }
  SerializationCluster* cluster = *cluster_ref;
  ASSERT(cluster != nullptr);
  if (cluster->is_canonical() != is_canonical) {
    FATAL("cluster for %s (cid %" Pd ") %s as canonical, but %s",
          cluster->name(), cid,
          cluster->is_canonical() ? "marked" : "not marked",
          is_canonical ? "should be" : "should not be");
  }

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
               Snapshot::KindToCString(kind_), static_cast<uword>(object.ptr()),
               object.ToCString());
#if defined(SNAPSHOT_BACKTRACE)
  while (!object.IsNull()) {
    object = ParentOf(object);
    OS::PrintErr("referenced by 0x%" Px " %s\n",
                 static_cast<uword>(object.ptr()), object.ToCString());
  }
#endif
  OS::Abort();
}

#if defined(SNAPSHOT_BACKTRACE)
ObjectPtr Serializer::ParentOf(ObjectPtr object) const {
  for (intptr_t i = 0; i < parent_pairs_.length(); i += 2) {
    if (parent_pairs_[i]->ptr() == object) {
      return parent_pairs_[i + 1]->ptr();
    }
  }
  return Object::null();
}

ObjectPtr Serializer::ParentOf(const Object& object) const {
  for (intptr_t i = 0; i < parent_pairs_.length(); i += 2) {
    if (parent_pairs_[i]->ptr() == object.ptr()) {
      return parent_pairs_[i + 1]->ptr();
    }
  }
  return Object::null();
}
#endif  // SNAPSHOT_BACKTRACE

void Serializer::WriteVersionAndFeatures(bool is_vm_snapshot) {
  const char* expected_version = Version::SnapshotString();
  ASSERT(expected_version != nullptr);
  const intptr_t version_len = strlen(expected_version);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_version), version_len);

  char* expected_features =
      Dart::FeaturesString(IsolateGroup::Current(), is_vm_snapshot, kind_);
  ASSERT(expected_features != nullptr);
  const intptr_t features_len = strlen(expected_features);
  WriteBytes(reinterpret_cast<const uint8_t*>(expected_features),
             features_len + 1);
  free(expected_features);
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

#define CID_CLUSTER(Type)                                                      \
  reinterpret_cast<Type##SerializationCluster*>(clusters_by_cid_[k##Type##Cid])

const CompressedStackMaps& SerializationRoots::canonicalized_stack_map_entries()
    const {
  return CompressedStackMaps::Handle();
}

ZoneGrowableArray<Object*>* Serializer::Serialize(SerializationRoots* roots) {
  // While object_currently_writing_ is initialized to the artificial root, we
  // set up a scope to ensure proper flushing to the profile.
  Serializer::WritingObjectScope scope(
      this, V8SnapshotProfileWriter::kArtificialRootId);
  roots->AddBaseObjects(this);

  NoSafepointScope no_safepoint;

  roots->PushRoots(this);

  // Resolving WeakSerializationReferences and WeakProperties may cause new
  // objects to be pushed on the stack, and handling the changes to the stack
  // may cause the targets of WeakSerializationReferences and keys of
  // WeakProperties to become reachable, so we do this as a fixed point
  // computation. Note that reachability is computed monotonically (an object
  // can change from not reachable to reachable, but never the reverse), which
  // is technically a conservative approximation for WSRs, but doing a strict
  // analysis that allows non-monotonic reachability may not halt.
  //
  // To see this, take a WSR whose replacement causes the target of another WSR
  // to become reachable, which then causes the target of the first WSR to
  // become reachable, but the only way to reach the target is through the
  // target of the second WSR, which was only reachable via the replacement
  // the first.
  //
  // In practice, this case doesn't come up as replacements tend to be either
  // null, smis, or singleton objects that do not contain WSRs currently.
  while (stack_.length() > 0) {
    // Strong references.
    while (stack_.length() > 0) {
      StackEntry entry = stack_.RemoveLast();
      Trace(entry.obj, entry.cid_override);
    }

    // Ephemeron references.
#if defined(DART_PRECOMPILER)
    if (auto const cluster = CID_CLUSTER(WeakSerializationReference)) {
      cluster->RetraceEphemerons(this);
    }
#endif
    if (auto const cluster = CID_CLUSTER(WeakProperty)) {
      cluster->RetraceEphemerons(this);
    }
  }

#if defined(DART_PRECOMPILER)
  auto const wsr_cluster = CID_CLUSTER(WeakSerializationReference);
  if (wsr_cluster != nullptr) {
    // Now that we have computed the reachability fixpoint, we remove the
    // count of now-reachable WSRs as they are not actually serialized.
    num_written_objects_ -= wsr_cluster->Count(this);
    // We don't need to write this cluster, so remove it from consideration.
    clusters_by_cid_[kWeakSerializationReferenceCid] = nullptr;
  }
  ASSERT(clusters_by_cid_[kWeakSerializationReferenceCid] == nullptr);
#endif

  code_cluster_ = CID_CLUSTER(Code);

  GrowableArray<SerializationCluster*> clusters;
  // The order that PostLoad runs matters for some classes because of
  // assumptions during canonicalization, read filling, or post-load filling of
  // some classes about what has already been read and/or canonicalized.
  // Explicitly add these clusters first, then add the rest ordered by class id.
#define ADD_CANONICAL_NEXT(cid)                                                \
  if (auto const cluster = canonical_clusters_by_cid_[cid]) {                  \
    clusters.Add(cluster);                                                     \
    canonical_clusters_by_cid_[cid] = nullptr;                                 \
  }
#define ADD_NON_CANONICAL_NEXT(cid)                                            \
  if (auto const cluster = clusters_by_cid_[cid]) {                            \
    clusters.Add(cluster);                                                     \
    clusters_by_cid_[cid] = nullptr;                                           \
  }
  ADD_CANONICAL_NEXT(kOneByteStringCid)
  ADD_CANONICAL_NEXT(kTwoByteStringCid)
  ADD_CANONICAL_NEXT(kStringCid)
  ADD_CANONICAL_NEXT(kMintCid)
  ADD_CANONICAL_NEXT(kDoubleCid)
  ADD_CANONICAL_NEXT(kTypeParameterCid)
  ADD_CANONICAL_NEXT(kTypeCid)
  ADD_CANONICAL_NEXT(kTypeArgumentsCid)
  // Code cluster should be deserialized before Function as
  // FunctionDeserializationCluster::ReadFill uses instructions table
  // which is filled in CodeDeserializationCluster::ReadFill.
  // Code cluster should also precede ObjectPool as its ReadFill uses
  // entry points of stubs.
  ADD_NON_CANONICAL_NEXT(kCodeCid)
  // The function cluster should be deserialized before any closures, as
  // PostLoad for closures caches the entry point found in the function.
  ADD_NON_CANONICAL_NEXT(kFunctionCid)
  ADD_CANONICAL_NEXT(kClosureCid)
#undef ADD_CANONICAL_NEXT
#undef ADD_NON_CANONICAL_NEXT
  const intptr_t out_of_order_clusters = clusters.length();
  for (intptr_t cid = 0; cid < num_cids_; cid++) {
    if (auto const cluster = canonical_clusters_by_cid_[cid]) {
      clusters.Add(cluster);
    }
  }
  for (intptr_t cid = 0; cid < num_cids_; cid++) {
    if (auto const cluster = clusters_by_cid_[cid]) {
      clusters.Add(clusters_by_cid_[cid]);
    }
  }
  // Put back any taken out temporarily to avoid re-adding them during the loop.
  for (intptr_t i = 0; i < out_of_order_clusters; i++) {
    const auto& cluster = clusters.At(i);
    const intptr_t cid = cluster->cid();
    auto const cid_clusters =
        cluster->is_canonical() ? canonical_clusters_by_cid_ : clusters_by_cid_;
    ASSERT(cid_clusters[cid] == nullptr);
    cid_clusters[cid] = cluster;
  }

  PrepareInstructions(roots->canonicalized_stack_map_entries());

  intptr_t num_objects = num_base_objects_ + num_written_objects_;
#if defined(ARCH_IS_64_BIT)
  if (!Utils::IsInt(32, num_objects)) {
    FATAL("Ref overflow");
  }
#endif

  WriteUnsigned(num_base_objects_);
  WriteUnsigned(num_objects);
  WriteUnsigned(clusters.length());
  ASSERT((instructions_table_len_ == 0) || FLAG_precompiled_mode);
  WriteUnsigned(instructions_table_len_);
  WriteUnsigned(instructions_table_rodata_offset_);

  for (SerializationCluster* cluster : clusters) {
    cluster->WriteAndMeasureAlloc(this);
    bytes_heap_allocated_ += cluster->target_memory_size();
#if defined(DEBUG)
    Write<int32_t>(next_ref_index_);
#endif
  }

  // We should have assigned a ref to every object we pushed.
  ASSERT((next_ref_index_ - 1) == num_objects);
  // And recorded them all in [objects_].
  ASSERT(objects_->length() == num_objects);

#if defined(DART_PRECOMPILER)
  if (profile_writer_ != nullptr && wsr_cluster != nullptr) {
    // Post-WriteAlloc, we eagerly create artificial nodes for any unreachable
    // targets in reachable WSRs if writing a v8 snapshot profile, since they
    // will be used in AttributeReference().
    //
    // Unreachable WSRs may also need artificial nodes, as they may be members
    // of other unreachable objects that have artificial nodes in the profile,
    // but they are instead lazily handled in CreateArtificialNodeIfNeeded().
    wsr_cluster->CreateArtificialTargetNodesIfNeeded(this);
  }
#endif

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

  // Create an artificial node to which the bytes should be attributed. We
  // don't attribute them to entries.ptr(), as we don't want to attribute the
  // bytes for printing out a length of 0 to Object::null() when the dispatch
  // table is empty.
  const intptr_t profile_ref = AssignArtificialRef();
  const auto& dispatch_table_profile_id = GetProfileId(profile_ref);
  if (profile_writer_ != nullptr) {
    profile_writer_->SetObjectTypeAndName(dispatch_table_profile_id,
                                          "DispatchTable", "dispatch_table");
    profile_writer_->AddRoot(dispatch_table_profile_id);
  }
  WritingObjectScope scope(this, dispatch_table_profile_id);
  if (profile_writer_ != nullptr) {
    // We'll write the Array object as a property of the artificial dispatch
    // table node, so Code objects otherwise unreferenced will have it as an
    // ancestor.
    CreateArtificialNodeIfNeeded(entries.ptr());
    AttributePropertyRef(entries.ptr(), "<code entries>");
  }

  const intptr_t bytes_before = bytes_written();
  const intptr_t table_length = entries.IsNull() ? 0 : entries.Length();

  ASSERT(table_length <= compiler::target::kWordMax);
  WriteUnsigned(table_length);
  if (table_length == 0) {
    dispatch_table_size_ = bytes_written() - bytes_before;
    return;
  }

  ASSERT(code_cluster_ != nullptr);
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
  WriteUnsigned(code_cluster_->first_ref());

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
    // Emit any outstanding repeat count before handling the new code value.
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
    auto const code_index = GetCodeIndex(code);
    // Use the index in the code cluster, not in the snapshot..
    auto const encoded = kDispatchTableIndexBase + code_index;
    ASSERT(encoded <= compiler::target::kWordMax);
    Write(encoded);
    recent[recent_index] = code;
    recent_index = (recent_index + 1) & kDispatchTableRecentMask;
  }
  if (repeat_count > 0) {
    Write(repeat_count);
  }
  dispatch_table_size_ = bytes_written() - bytes_before;
#endif  // defined(DART_PRECOMPILER)
}

void Serializer::PrintSnapshotSizes() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (FLAG_print_snapshot_sizes_verbose) {
    TextBuffer buffer(1024);
    // Header, using format sizes matching those below to ensure alignment.
    buffer.Printf("%25s", "Cluster");
    buffer.Printf(" %6s", "Objs");
    buffer.Printf(" %8s", "Size");
    buffer.Printf(" %8s", "Fraction");
    buffer.Printf(" %10s", "Cumulative");
    buffer.Printf(" %8s", "HeapSize");
    buffer.Printf(" %5s", "Cid");
    buffer.Printf(" %9s", "Canonical");
    buffer.AddString("\n");
    GrowableArray<SerializationCluster*> clusters_by_size;
    for (intptr_t cid = 1; cid < num_cids_; cid++) {
      if (auto const cluster = canonical_clusters_by_cid_[cid]) {
        clusters_by_size.Add(cluster);
      }
      if (auto const cluster = clusters_by_cid_[cid]) {
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
          zone_,
          isolate_group()->object_store()->dispatch_table_code_entries());
      auto const entry_count =
          dispatch_table_entries.IsNull() ? 0 : dispatch_table_entries.Length();
      clusters_by_size.Add(new (zone_) FakeSerializationCluster(
          "DispatchTable", entry_count, dispatch_table_size_));
    }
    if (instructions_table_len_ > 0) {
      const intptr_t memory_size =
          compiler::target::InstructionsTable::InstanceSize() +
          compiler::target::Array::InstanceSize(instructions_table_len_);
      clusters_by_size.Add(new (zone_) FakeSerializationCluster(
          "InstructionsTable", instructions_table_len_, 0, memory_size));
    }
    clusters_by_size.Sort(CompareClusters);
    double total_size =
        static_cast<double>(bytes_written() + GetDataSize() + text_size);
    double cumulative_fraction = 0.0;
    for (intptr_t i = 0; i < clusters_by_size.length(); i++) {
      SerializationCluster* cluster = clusters_by_size[i];
      double fraction = static_cast<double>(cluster->size()) / total_size;
      cumulative_fraction += fraction;
      buffer.Printf("%25s", cluster->name());
      buffer.Printf(" %6" Pd "", cluster->num_objects());
      buffer.Printf(" %8" Pd "", cluster->size());
      buffer.Printf(" %1.6lf", fraction);
      buffer.Printf(" %1.8lf", cumulative_fraction);
      buffer.Printf(" %8" Pd "", cluster->target_memory_size());
      if (cluster->cid() != -1) {
        buffer.Printf(" %5" Pd "", cluster->cid());
      } else {
        buffer.Printf(" %5s", "");
      }
      if (cluster->is_canonical()) {
        buffer.Printf(" %9s", "canonical");
      } else {
        buffer.Printf(" %9s", "");
      }
      buffer.AddString("\n");
    }
    OS::PrintErr("%s", buffer.buffer());
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
      heap_(thread->isolate_group()->heap()),
      old_space_(heap_->old_space()),
      freelist_(old_space_->DataFreeList()),
      zone_(thread->zone()),
      kind_(kind),
      stream_(buffer, size),
      image_reader_(nullptr),
      refs_(nullptr),
      next_ref_index_(kFirstReference),
      clusters_(nullptr),
      is_non_root_unit_(is_non_root_unit),
      instructions_table_(InstructionsTable::Handle(thread->zone())) {
  if (Snapshot::IncludesCode(kind)) {
    ASSERT(instructions_buffer != nullptr);
    ASSERT(data_buffer != nullptr);
    image_reader_ = new (zone_) ImageReader(data_buffer, instructions_buffer);
  }
  stream_.SetPosition(offset);
}

Deserializer::~Deserializer() {
  delete[] clusters_;
}

DeserializationCluster* Deserializer::ReadCluster() {
  const uint64_t cid_and_canonical = Read<uint64_t>();
  const intptr_t cid = (cid_and_canonical >> 1) & kMaxUint32;
  const bool is_canonical = (cid_and_canonical & 0x1) == 0x1;
  Zone* Z = zone_;
  if (cid >= kNumPredefinedCids || cid == kInstanceCid) {
    return new (Z) InstanceDeserializationCluster(cid, is_canonical);
  }
  if (IsTypedDataViewClassId(cid)) {
    ASSERT(!is_canonical);
    return new (Z) TypedDataViewDeserializationCluster(cid);
  }
  if (IsExternalTypedDataClassId(cid)) {
    ASSERT(!is_canonical);
    return new (Z) ExternalTypedDataDeserializationCluster(cid);
  }
  if (IsTypedDataClassId(cid)) {
    ASSERT(!is_canonical);
    return new (Z) TypedDataDeserializationCluster(cid);
  }

#if !defined(DART_COMPRESSED_POINTERS)
  if (Snapshot::IncludesCode(kind_)) {
    switch (cid) {
      case kPcDescriptorsCid:
      case kCodeSourceMapCid:
      case kCompressedStackMapsCid:
        return new (Z)
            RODataDeserializationCluster(is_canonical, !is_non_root_unit_, cid);
      case kOneByteStringCid:
      case kTwoByteStringCid:
      case kStringCid:
        if (!is_non_root_unit_) {
          return new (Z) RODataDeserializationCluster(is_canonical,
                                                      !is_non_root_unit_, cid);
        }
        break;
    }
  }
#endif

  switch (cid) {
    case kClassCid:
      ASSERT(!is_canonical);
      return new (Z) ClassDeserializationCluster();
    case kTypeParametersCid:
      return new (Z) TypeParametersDeserializationCluster();
    case kTypeArgumentsCid:
      return new (Z)
          TypeArgumentsDeserializationCluster(is_canonical, !is_non_root_unit_);
    case kPatchClassCid:
      ASSERT(!is_canonical);
      return new (Z) PatchClassDeserializationCluster();
    case kFunctionCid:
      ASSERT(!is_canonical);
      return new (Z) FunctionDeserializationCluster();
    case kClosureDataCid:
      ASSERT(!is_canonical);
      return new (Z) ClosureDataDeserializationCluster();
    case kFfiTrampolineDataCid:
      ASSERT(!is_canonical);
      return new (Z) FfiTrampolineDataDeserializationCluster();
    case kFieldCid:
      ASSERT(!is_canonical);
      return new (Z) FieldDeserializationCluster();
    case kScriptCid:
      ASSERT(!is_canonical);
      return new (Z) ScriptDeserializationCluster();
    case kLibraryCid:
      ASSERT(!is_canonical);
      return new (Z) LibraryDeserializationCluster();
    case kNamespaceCid:
      ASSERT(!is_canonical);
      return new (Z) NamespaceDeserializationCluster();
#if !defined(DART_PRECOMPILED_RUNTIME)
    case kKernelProgramInfoCid:
      ASSERT(!is_canonical);
      return new (Z) KernelProgramInfoDeserializationCluster();
#endif  // !DART_PRECOMPILED_RUNTIME
    case kCodeCid:
      ASSERT(!is_canonical);
      return new (Z) CodeDeserializationCluster();
    case kObjectPoolCid:
      ASSERT(!is_canonical);
      return new (Z) ObjectPoolDeserializationCluster();
    case kPcDescriptorsCid:
      ASSERT(!is_canonical);
      return new (Z) PcDescriptorsDeserializationCluster();
    case kCodeSourceMapCid:
      ASSERT(!is_canonical);
      return new (Z) CodeSourceMapDeserializationCluster();
    case kCompressedStackMapsCid:
      ASSERT(!is_canonical);
      return new (Z) CompressedStackMapsDeserializationCluster();
    case kExceptionHandlersCid:
      ASSERT(!is_canonical);
      return new (Z) ExceptionHandlersDeserializationCluster();
    case kContextCid:
      ASSERT(!is_canonical);
      return new (Z) ContextDeserializationCluster();
    case kContextScopeCid:
      ASSERT(!is_canonical);
      return new (Z) ContextScopeDeserializationCluster();
    case kUnlinkedCallCid:
      ASSERT(!is_canonical);
      return new (Z) UnlinkedCallDeserializationCluster();
    case kICDataCid:
      ASSERT(!is_canonical);
      return new (Z) ICDataDeserializationCluster();
    case kMegamorphicCacheCid:
      ASSERT(!is_canonical);
      return new (Z) MegamorphicCacheDeserializationCluster();
    case kSubtypeTestCacheCid:
      ASSERT(!is_canonical);
      return new (Z) SubtypeTestCacheDeserializationCluster();
    case kLoadingUnitCid:
      ASSERT(!is_canonical);
      return new (Z) LoadingUnitDeserializationCluster();
    case kLanguageErrorCid:
      ASSERT(!is_canonical);
      return new (Z) LanguageErrorDeserializationCluster();
    case kUnhandledExceptionCid:
      ASSERT(!is_canonical);
      return new (Z) UnhandledExceptionDeserializationCluster();
    case kLibraryPrefixCid:
      ASSERT(!is_canonical);
      return new (Z) LibraryPrefixDeserializationCluster();
    case kTypeCid:
      return new (Z)
          TypeDeserializationCluster(is_canonical, !is_non_root_unit_);
    case kFunctionTypeCid:
      return new (Z)
          FunctionTypeDeserializationCluster(is_canonical, !is_non_root_unit_);
    case kRecordTypeCid:
      return new (Z)
          RecordTypeDeserializationCluster(is_canonical, !is_non_root_unit_);
    case kTypeParameterCid:
      return new (Z)
          TypeParameterDeserializationCluster(is_canonical, !is_non_root_unit_);
    case kClosureCid:
      return new (Z) ClosureDeserializationCluster(is_canonical);
    case kMintCid:
      return new (Z) MintDeserializationCluster(is_canonical);
    case kDoubleCid:
      return new (Z) DoubleDeserializationCluster(is_canonical);
    case kGrowableObjectArrayCid:
      ASSERT(!is_canonical);
      return new (Z) GrowableObjectArrayDeserializationCluster();
    case kRecordCid:
      return new (Z) RecordDeserializationCluster(is_canonical);
    case kStackTraceCid:
      ASSERT(!is_canonical);
      return new (Z) StackTraceDeserializationCluster();
    case kRegExpCid:
      ASSERT(!is_canonical);
      return new (Z) RegExpDeserializationCluster();
    case kWeakPropertyCid:
      ASSERT(!is_canonical);
      return new (Z) WeakPropertyDeserializationCluster();
    case kMapCid:
      // We do not have mutable hash maps in snapshots.
      UNREACHABLE();
    case kConstMapCid:
      return new (Z) MapDeserializationCluster(is_canonical, kConstMapCid);
    case kSetCid:
      // We do not have mutable hash sets in snapshots.
      UNREACHABLE();
    case kConstSetCid:
      return new (Z) SetDeserializationCluster(is_canonical, kConstSetCid);
    case kArrayCid:
      return new (Z) ArrayDeserializationCluster(is_canonical, kArrayCid);
    case kImmutableArrayCid:
      return new (Z)
          ArrayDeserializationCluster(is_canonical, kImmutableArrayCid);
    case kWeakArrayCid:
      return new (Z) WeakArrayDeserializationCluster();
    case kStringCid:
      return new (Z) StringDeserializationCluster(
          is_canonical,
          !is_non_root_unit_ && isolate_group() != Dart::vm_isolate_group());
#define CASE_FFI_CID(name) case kFfi##name##Cid:
      CLASS_LIST_FFI_TYPE_MARKER(CASE_FFI_CID)
#undef CASE_FFI_CID
      return new (Z) InstanceDeserializationCluster(cid, is_canonical);
    case kDeltaEncodedTypedDataCid:
      return new (Z) DeltaEncodedTypedDataDeserializationCluster();
    default:
      break;
  }
  FATAL("No cluster defined for cid %" Pd, cid);
  return nullptr;
}

void Deserializer::ReadDispatchTable(
    ReadStream* stream,
    bool deferred,
    const InstructionsTable& root_instruction_table,
    intptr_t deferred_code_start_index,
    intptr_t deferred_code_end_index) {
#if defined(DART_PRECOMPILED_RUNTIME)
  const uint8_t* table_snapshot_start = stream->AddressOfCurrentPosition();
  const intptr_t length = stream->ReadUnsigned();
  if (length == 0) return;

  const intptr_t first_code_id = stream->ReadUnsigned();
  deferred_code_start_index -= first_code_id;
  deferred_code_end_index -= first_code_id;

  auto const IG = isolate_group();
  auto code = IG->object_store()->dispatch_table_null_error_stub();
  ASSERT(code != Code::null());
  uword null_entry = Code::EntryPointOf(code);

  DispatchTable* table;
  if (deferred) {
    table = IG->dispatch_table();
    ASSERT(table != nullptr && table->length() == length);
  } else {
    ASSERT(IG->dispatch_table() == nullptr);
    table = new DispatchTable(length);
  }
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
      const intptr_t code_index = encoded - kDispatchTableIndexBase;
      if (deferred) {
        const intptr_t code_id =
            CodeIndexToClusterIndex(root_instruction_table, code_index);
        if ((deferred_code_start_index <= code_id) &&
            (code_id < deferred_code_end_index)) {
          auto code = static_cast<CodePtr>(Ref(first_code_id + code_id));
          value = Code::EntryPointOf(code);
        } else {
          // Reuse old value from the dispatch table.
          value = array[i];
        }
      } else {
        value = GetEntryPointByCodeIndex(code_index);
      }
      recent[recent_index] = value;
      recent_index = (recent_index + 1) & kDispatchTableRecentMask;
    }
    array[i] = value;
  }
  ASSERT(repeat_count == 0);

  if (!deferred) {
    IG->set_dispatch_table(table);
    intptr_t table_snapshot_size =
        stream->AddressOfCurrentPosition() - table_snapshot_start;
    IG->set_dispatch_table_snapshot(table_snapshot_start);
    IG->set_dispatch_table_snapshot_size(table_snapshot_size);
  }
#endif
}

ApiErrorPtr Deserializer::VerifyImageAlignment() {
  if (image_reader_ != nullptr) {
    return image_reader_->VerifyAlignment();
  }
  return ApiError::null();
}

char* SnapshotHeaderReader::VerifyVersionAndFeatures(
    IsolateGroup* isolate_group,
    intptr_t* offset) {
  char* error = VerifyVersion();
  if (error == nullptr) {
    error = VerifyFeatures(isolate_group);
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
  ASSERT(expected_version != nullptr);
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
  ASSERT(version != nullptr);
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

char* SnapshotHeaderReader::VerifyFeatures(IsolateGroup* isolate_group) {
  const char* expected_features =
      Dart::FeaturesString(isolate_group, (isolate_group == nullptr), kind_);
  ASSERT(expected_features != nullptr);
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
#if defined(DART_PRECOMPILED_RUNTIME)
  if (deferred) {
    uword entry_point = StubCode::NotLoaded().EntryPoint();
    code->untag()->entry_point_ = entry_point;
    code->untag()->unchecked_entry_point_ = entry_point;
    code->untag()->monomorphic_entry_point_ = entry_point;
    code->untag()->monomorphic_unchecked_entry_point_ = entry_point;
    code->untag()->instructions_length_ = 0;
    return;
  }

  const uword payload_start = instructions_table_.EntryPointAt(
      instructions_table_.rodata()->first_entry_with_code +
      instructions_index_);
  const uint32_t payload_info = ReadUnsigned();
  const uint32_t unchecked_offset = payload_info >> 1;
  const bool has_monomorphic_entrypoint = (payload_info & 0x1) == 0x1;

  const uword entry_offset =
      has_monomorphic_entrypoint ? Instructions::kPolymorphicEntryOffsetAOT : 0;
  const uword monomorphic_entry_offset =
      has_monomorphic_entrypoint ? Instructions::kMonomorphicEntryOffsetAOT : 0;

  const uword entry_point = payload_start + entry_offset;
  const uword monomorphic_entry_point =
      payload_start + monomorphic_entry_offset;

  instructions_table_.SetCodeAt(instructions_index_++, code);

  // There are no serialized RawInstructions objects in this mode.
  code->untag()->instructions_ = Instructions::null();
  code->untag()->entry_point_ = entry_point;
  code->untag()->unchecked_entry_point_ = entry_point + unchecked_offset;
  code->untag()->monomorphic_entry_point_ = monomorphic_entry_point;
  code->untag()->monomorphic_unchecked_entry_point_ =
      monomorphic_entry_point + unchecked_offset;
#else
  ASSERT(!deferred);
  InstructionsPtr instr = image_reader_->GetInstructionsAt(Read<uint32_t>());
  uint32_t unchecked_offset = ReadUnsigned();
  code->untag()->instructions_ = instr;
  code->untag()->unchecked_offset_ = unchecked_offset;
  ASSERT(kind() == Snapshot::kFullJIT);
  const uint32_t active_offset = Read<uint32_t>();
  instr = image_reader_->GetInstructionsAt(active_offset);
  unchecked_offset = ReadUnsigned();
  code->untag()->active_instructions_ = instr;
  Code::InitializeCachedEntryPointsFrom(code, instr, unchecked_offset);
#endif  // defined(DART_PRECOMPILED_RUNTIME)
}

void Deserializer::EndInstructions() {
#if defined(DART_PRECOMPILED_RUNTIME)
  if (instructions_table_.IsNull()) {
    ASSERT(instructions_index_ == 0);
    return;
  }

  const auto& code_objects =
      Array::Handle(instructions_table_.ptr()->untag()->code_objects());
  ASSERT(code_objects.Length() == instructions_index_);

  uword previous_end = image_reader_->GetBareInstructionsEnd();
  for (intptr_t i = instructions_index_ - 1; i >= 0; --i) {
    CodePtr code = Code::RawCast(code_objects.At(i));
    uword start = Code::PayloadStartOf(code);
    ASSERT(start <= previous_end);
    code->untag()->instructions_length_ = previous_end - start;
    previous_end = start;
  }

  ObjectStore* object_store = IsolateGroup::Current()->object_store();
  GrowableObjectArray& tables =
      GrowableObjectArray::Handle(zone_, object_store->instructions_tables());
  if (tables.IsNull()) {
    tables = GrowableObjectArray::New(Heap::kOld);
    object_store->set_instructions_tables(tables);
  }
  if ((tables.Length() == 0) ||
      (tables.At(tables.Length() - 1) != instructions_table_.ptr())) {
    ASSERT((!is_non_root_unit_ && tables.Length() == 0) ||
           (is_non_root_unit_ && tables.Length() > 0));
    tables.Add(instructions_table_, Heap::kOld);
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
  const void* clustered_start = AddressOfCurrentPosition();

  Array& refs = Array::Handle(zone_);
  num_base_objects_ = ReadUnsigned();
  num_objects_ = ReadUnsigned();
  num_clusters_ = ReadUnsigned();
  const intptr_t instructions_table_len = ReadUnsigned();
  const uint32_t instruction_table_data_offset = ReadUnsigned();
  USE(instruction_table_data_offset);

  clusters_ = new DeserializationCluster*[num_clusters_];
  refs = Array::New(num_objects_ + kFirstReference, Heap::kOld);

#if defined(DART_PRECOMPILED_RUNTIME)
  if (instructions_table_len > 0) {
    ASSERT(FLAG_precompiled_mode);
    const uword start_pc = image_reader_->GetBareInstructionsAt(0);
    const uword end_pc = image_reader_->GetBareInstructionsEnd();
    uword instruction_table_data = 0;
    if (instruction_table_data_offset != 0) {
      // NoSafepointScope to satisfy assertion in DataStart. InstructionsTable
      // data resides in RO memory and is immovable and immortal making it
      // safe to use DataStart result outside of NoSafepointScope.
      NoSafepointScope no_safepoint;
      instruction_table_data = reinterpret_cast<uword>(
          OneByteString::DataStart(String::Handle(static_cast<StringPtr>(
              image_reader_->GetObjectAt(instruction_table_data_offset)))));
    }
    instructions_table_ = InstructionsTable::New(
        instructions_table_len, start_pc, end_pc, instruction_table_data);
  }
#else
  ASSERT(instructions_table_len == 0);
#endif  // defined(DART_PRECOMPILED_RUNTIME)

  bool primary;
  {
    // The deserializer initializes objects without using the write barrier,
    // partly for speed since we know all the deserialized objects will be
    // long-lived and partly because the target objects can be not yet
    // initialized at the time of the write. To make this safe, we must ensure
    // there are no other threads mutating this heap, and that incremental
    // marking is not in progress. This is normally the case anyway for the
    // main snapshot being deserialized at isolate load, but needs checks for
    // loading secondary snapshots are part of deferred loading.
    HeapIterationScope iter(thread());
    // For bump-pointer allocation in old-space.
    HeapLocker hl(thread(), heap_->old_space());
    // Must not perform any other type of allocation, which might trigger GC
    // while there are still uninitialized objects.
    NoSafepointScope no_safepoint;
    refs_ = refs.ptr();

    primary = roots->AddBaseObjects(this);

    if (num_base_objects_ != (next_ref_index_ - kFirstReference)) {
      FATAL("Snapshot expects %" Pd
            " base objects, but deserializer provided %" Pd,
            num_base_objects_, next_ref_index_ - kFirstReference);
    }

    {
      TIMELINE_DURATION(thread(), Isolate, "ReadAlloc");
      for (intptr_t i = 0; i < num_clusters_; i++) {
        clusters_[i] = ReadCluster();
        clusters_[i]->ReadAlloc(this);
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
      SafepointWriteRwLocker ml(thread(), isolate_group()->program_lock());
      for (intptr_t i = 0; i < num_clusters_; i++) {
        clusters_[i]->ReadFill(this, primary);
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

    refs_ = nullptr;
  }

  roots->PostLoad(this, refs);

  auto isolate_group = thread()->isolate_group();
#if defined(DEBUG)
  isolate_group->ValidateClassTable();
  if (isolate_group != Dart::vm_isolate()->group()) {
    isolate_group->heap()->Verify("Deserializer::Deserialize");
  }
#endif

  {
    TIMELINE_DURATION(thread(), Isolate, "PostLoad");
    for (intptr_t i = 0; i < num_clusters_; i++) {
      clusters_[i]->PostLoad(this, refs, primary);
    }
  }

  if (isolate_group->snapshot_is_dontneed_safe()) {
    size_t clustered_length =
        reinterpret_cast<uword>(AddressOfCurrentPosition()) -
        reinterpret_cast<uword>(clustered_start);
    VirtualMemory::DontNeed(const_cast<void*>(clustered_start),
                            clustered_length);
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
      isolate_image_writer_(isolate_image_writer) {
  ASSERT(isolate_group() != nullptr);
  ASSERT(heap() != nullptr);
  ObjectStore* object_store = isolate_group()->object_store();
  ASSERT(object_store != nullptr);

#if defined(DEBUG)
  isolate_group()->ValidateClassTable();
  isolate_group()->ValidateConstants();
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
      WeakArray::Handle(
          Dart::vm_isolate_group()->object_store()->symbol_table()),
      /*should_write_symbols=*/!Snapshot::IncludesStringsInROData(kind_));
  ZoneGrowableArray<Object*>* objects = serializer.Serialize(&roots);
  serializer.FillHeader(serializer.kind());
  clustered_vm_size_ = serializer.bytes_written();
  heap_vm_size_ = serializer.bytes_heap_allocated();

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
  ObjectStore* object_store = isolate_group()->object_store();
  ASSERT(object_store != nullptr);

  // These type arguments must always be retained.
  ASSERT(object_store->type_argument_int()->untag()->IsCanonical());
  ASSERT(object_store->type_argument_double()->untag()->IsCanonical());
  ASSERT(object_store->type_argument_string()->untag()->IsCanonical());
  ASSERT(object_store->type_argument_string_dynamic()->untag()->IsCanonical());
  ASSERT(object_store->type_argument_string_string()->untag()->IsCanonical());

  serializer.ReserveHeader();
  serializer.WriteVersionAndFeatures(false);
  ProgramSerializationRoots roots(objects, object_store, kind_);
  objects = serializer.Serialize(&roots);
  if (units != nullptr) {
    (*units)[LoadingUnit::kRootId]->set_objects(objects);
  }
  serializer.FillHeader(serializer.kind());
  clustered_isolate_size_ = serializer.bytes_written();
  heap_isolate_size_ = serializer.bytes_heap_allocated();

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
    OS::Print("VMIsolate(HeapSize): %" Pd "\n", heap_vm_size_);
    OS::Print("Isolate(HeapSize): %" Pd "\n", heap_isolate_size_);
    OS::Print("Total(HeapSize): %" Pd "\n", heap_vm_size_ + heap_isolate_size_);
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
    if (strncmp(cursor, "null-safety", end - cursor) == 0) {
      FLAG_sound_null_safety = true;
      cursor = end;
      continue;
    }
    if (strncmp(cursor, "no-null-safety", end - cursor) == 0) {
      FLAG_sound_null_safety = false;
      cursor = end;
      continue;
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
  char* error = header_reader.VerifyVersionAndFeatures(
      /*isolate_group=*/nullptr, &offset);
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
    ASSERT(data_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(data_image_,
                                             /* is_executable */ false);
    ASSERT(instructions_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(instructions_image_,
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
      header_reader.VerifyVersionAndFeatures(thread_->isolate_group(), &offset);
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
    ASSERT(data_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(data_image_,
                                             /* is_executable */ false);
    ASSERT(instructions_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(instructions_image_,
                                             /* is_executable */ true);
  }

  ProgramDeserializationRoots roots(thread_->isolate_group()->object_store());
  deserializer.Deserialize(&roots);

  InitializeBSS();

  return ApiError::null();
}

ApiErrorPtr FullSnapshotReader::ReadUnitSnapshot(const LoadingUnit& unit) {
  SnapshotHeaderReader header_reader(kind_, buffer_, size_);
  intptr_t offset = 0;
  char* error =
      header_reader.VerifyVersionAndFeatures(thread_->isolate_group(), &offset);
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
        Array::Handle(isolate_group()->object_store()->loading_units());
    uint32_t main_program_hash = Smi::Value(Smi::RawCast(units.At(0)));
    uint32_t unit_program_hash = deserializer.Read<uint32_t>();
    if (main_program_hash != unit_program_hash) {
      return ApiError::New(String::Handle(
          String::New("Deferred loading unit is from a different "
                      "program than the main loading unit")));
    }
  }

  if (Snapshot::IncludesCode(kind_)) {
    ASSERT(data_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(data_image_,
                                             /* is_executable */ false);
    ASSERT(instructions_image_ != nullptr);
    thread_->isolate_group()->SetupImagePage(instructions_image_,
                                             /* is_executable */ true);
  }

  UnitDeserializationRoots roots(unit);
  deserializer.Deserialize(&roots);

  InitializeBSS();

  return ApiError::null();
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
