// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/program_visitor.h"

#include "vm/code_patcher.h"
#include "vm/deopt_instructions.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

void ProgramVisitor::VisitClasses(ClassVisitor* visitor) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();
  GrowableObjectArray& libraries =
      GrowableObjectArray::Handle(zone, isolate->object_store()->libraries());
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  Object& entry = Object::Handle(zone);
  GrowableObjectArray& patches = GrowableObjectArray::Handle(zone);

  for (intptr_t i = 0; i < libraries.Length(); i++) {
    lib ^= libraries.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      visitor->Visit(cls);
    }
    patches = lib.used_scripts();
    for (intptr_t j = 0; j < patches.Length(); j++) {
      entry = patches.At(j);
      if (entry.IsClass()) {
        visitor->Visit(Class::Cast(entry));
      }
    }
  }
}

class ClassFunctionVisitor : public ClassVisitor {
 public:
  ClassFunctionVisitor(Zone* zone, FunctionVisitor* visitor)
      : visitor_(visitor),
        functions_(Array::Handle(zone)),
        function_(Function::Handle(zone)),
        object_(Object::Handle(zone)),
        fields_(Array::Handle(zone)),
        field_(Field::Handle(zone)) {}

  void Visit(const Class& cls) {
    functions_ = cls.functions();
    for (intptr_t j = 0; j < functions_.Length(); j++) {
      function_ ^= functions_.At(j);
      visitor_->Visit(function_);
      if (function_.HasImplicitClosureFunction()) {
        function_ = function_.ImplicitClosureFunction();
        visitor_->Visit(function_);
      }
    }

    functions_ = cls.invocation_dispatcher_cache();
    for (intptr_t j = 0; j < functions_.Length(); j++) {
      object_ = functions_.At(j);
      if (object_.IsFunction()) {
        function_ ^= functions_.At(j);
        visitor_->Visit(function_);
      }
    }

    fields_ = cls.fields();
    for (intptr_t j = 0; j < fields_.Length(); j++) {
      field_ ^= fields_.At(j);
      if (field_.is_static() && field_.HasInitializerFunction()) {
        function_ = field_.InitializerFunction();
        visitor_->Visit(function_);
      }
    }
  }

 private:
  FunctionVisitor* visitor_;
  Array& functions_;
  Function& function_;
  Object& object_;
  Array& fields_;
  Field& field_;
};

void ProgramVisitor::VisitFunctions(FunctionVisitor* visitor) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();

  ClassFunctionVisitor class_visitor(zone, visitor);
  VisitClasses(&class_visitor);

  Function& function = Function::Handle(zone);
  const GrowableObjectArray& closures = GrowableObjectArray::Handle(
      zone, isolate->object_store()->closure_functions());
  for (intptr_t i = 0; i < closures.Length(); i++) {
    function ^= closures.At(i);
    visitor->Visit(function);
    ASSERT(!function.HasImplicitClosureFunction());
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
void ProgramVisitor::BindStaticCalls() {
  if (FLAG_precompiled_mode) {
    return;
  }

  class BindJITStaticCallsVisitor : public FunctionVisitor {
   public:
    explicit BindJITStaticCallsVisitor(Zone* zone)
        : code_(Code::Handle(zone)),
          table_(Array::Handle(zone)),
          kind_and_offset_(Smi::Handle(zone)),
          target_(Object::Handle(zone)),
          target_code_(Code::Handle(zone)) {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      table_ = code_.static_calls_target_table();
      StaticCallsTable static_calls(table_);
      for (const auto& view : static_calls) {
        kind_and_offset_ = view.Get<Code::kSCallTableKindAndOffset>();
        Code::CallKind kind = Code::KindField::decode(kind_and_offset_.Value());
        if (kind != Code::kCallViaCode) {
          continue;
        }
        int32_t pc_offset = Code::OffsetField::decode(kind_and_offset_.Value());
        target_ = view.Get<Code::kSCallTableFunctionTarget>();
        if (target_.IsNull()) {
          target_ = view.Get<Code::kSCallTableCodeTarget>();
          ASSERT(!Code::Cast(target_).IsFunctionCode());
          // Allocation stub or AllocateContext or AllocateArray or ...
        } else {
          const Function& target_func = Function::Cast(target_);
          if (target_func.HasCode()) {
            target_code_ = target_func.CurrentCode();
          } else {
            target_code_ = StubCode::CallStaticFunction().raw();
          }
          uword pc = pc_offset + code_.PayloadStart();
          CodePatcher::PatchStaticCallAt(pc, code_, target_code_);
        }
      }
    }

   private:
    Code& code_;
    Array& table_;
    Smi& kind_and_offset_;
    Object& target_;
    Code& target_code_;
  };

  BindJITStaticCallsVisitor visitor(Thread::Current()->zone());
  ProgramVisitor::VisitFunctions(&visitor);
}

void ProgramVisitor::ShareMegamorphicBuckets() {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Zone* zone = thread->zone();

  const GrowableObjectArray& table = GrowableObjectArray::Handle(
      zone, isolate->object_store()->megamorphic_cache_table());
  if (table.IsNull()) return;
  MegamorphicCache& cache = MegamorphicCache::Handle(zone);

  const intptr_t capacity = 1;
  const Array& buckets = Array::Handle(
      zone, Array::New(MegamorphicCache::kEntryLength * capacity, Heap::kOld));
  const Function& handler =
      Function::Handle(zone, MegamorphicCacheTable::miss_handler(isolate));
  MegamorphicCache::SetEntry(buckets, 0, Object::smi_illegal_cid(), handler);

  for (intptr_t i = 0; i < table.Length(); i++) {
    cache ^= table.At(i);
    cache.set_buckets(buckets);
    cache.set_mask(capacity - 1);
    cache.set_filled_entry_count(0);
  }
}

class StackMapEntry : public ZoneAllocated {
 public:
  StackMapEntry(Zone* zone, const CompressedStackMapsIterator& it)
      : maps_(CompressedStackMaps::Handle(zone, it.maps_.raw())),
        bits_container_(
            CompressedStackMaps::Handle(zone, it.bits_container_.raw())),
        spill_slot_bit_count_(it.current_spill_slot_bit_count_),
        non_spill_slot_bit_count_(it.current_non_spill_slot_bit_count_),
        bits_offset_(it.current_bits_offset_) {
    ASSERT(!maps_.IsNull() && !maps_.IsGlobalTable());
    ASSERT(!bits_container_.IsNull());
    ASSERT(!maps_.UsesGlobalTable() || bits_container_.IsGlobalTable());
    // Check that the iterator was fully loaded when we ran the initializing
    // expressions above. By this point we enter the body of the constructor,
    // it's too late to run EnsureFullyLoadedEntry().
    ASSERT(it.HasLoadedEntry());
    ASSERT(it.current_spill_slot_bit_count_ >= 0);
  }

  static const intptr_t kHashBits = 30;

  intptr_t Hashcode() {
    if (hash_ != 0) return hash_;
    uint32_t hash = 0;
    hash = CombineHashes(hash, spill_slot_bit_count_);
    hash = CombineHashes(hash, non_spill_slot_bit_count_);
    for (intptr_t i = 0; i < PayloadLength(); i++) {
      hash = CombineHashes(hash, PayloadByte(i));
    }
    hash_ = FinalizeHash(hash, kHashBits);
    return hash_;
  }

  bool Equals(const StackMapEntry* other) const {
    if (spill_slot_bit_count_ != other->spill_slot_bit_count_ ||
        non_spill_slot_bit_count_ != other->non_spill_slot_bit_count_) {
      return false;
    }
    // Since we ensure that bits in the payload that are not part of the
    // actual stackmap data are cleared, we can just compare payloads by byte
    // instead of calling IsObject for each bit.
    for (intptr_t i = 0; i < PayloadLength(); i++) {
      if (PayloadByte(i) != other->PayloadByte(i)) return false;
    }
    return true;
  }

  // Encodes this StackMapEntry to the given array of bytes and returns the
  // initial offset of the entry in the array.
  intptr_t EncodeTo(GrowableArray<uint8_t>* array) {
    auto const current_offset = array->length();
    CompressedStackMapsBuilder::EncodeLEB128(array, spill_slot_bit_count_);
    CompressedStackMapsBuilder::EncodeLEB128(array, non_spill_slot_bit_count_);
    for (intptr_t i = 0; i < PayloadLength(); i++) {
      array->Add(PayloadByte(i));
    }
    return current_offset;
  }

  intptr_t UsageCount() const { return uses_; }
  void IncrementUsageCount() { uses_ += 1; }

 private:
  intptr_t Length() const {
    return spill_slot_bit_count_ + non_spill_slot_bit_count_;
  }
  intptr_t PayloadLength() const {
    return Utils::RoundUp(Length(), kBitsPerByte) >> kBitsPerByteLog2;
  }
  intptr_t PayloadByte(intptr_t offset) const {
    return bits_container_.PayloadByte(bits_offset_ + offset);
  }

  const CompressedStackMaps& maps_;
  const CompressedStackMaps& bits_container_;
  const intptr_t spill_slot_bit_count_;
  const intptr_t non_spill_slot_bit_count_;
  const intptr_t bits_offset_;

  intptr_t uses_ = 1;
  intptr_t hash_ = 0;
};

// Used for maps of indices and offsets. These are non-negative, and so the
// value for entries may be 0. Since 0 is kNoValue for
// RawPointerKeyValueTrait<const StackMapEntry, intptr_t>, we can't just use it.
class StackMapEntryKeyIntValueTrait {
 public:
  typedef StackMapEntry* Key;
  typedef intptr_t Value;

  struct Pair {
    Key key;
    Value value;
    Pair() : key(nullptr), value(-1) {}
    Pair(const Key key, const Value& value)
        : key(ASSERT_NOTNULL(key)), value(value) {}
    Pair(const Pair& other) : key(other.key), value(other.value) {}
    Pair& operator=(const Pair&) = default;
  };

  static Key KeyOf(Pair kv) { return kv.key; }
  static Value ValueOf(Pair kv) { return kv.value; }
  static intptr_t Hashcode(Key key) { return key->Hashcode(); }
  static bool IsKeyEqual(Pair kv, Key key) { return key->Equals(kv.key); }
};

typedef DirectChainedHashMap<StackMapEntryKeyIntValueTrait> StackMapEntryIntMap;

typedef DirectChainedHashMap<PointerKeyValueTrait<const CompressedStackMaps>>
    CompressedStackMapsSet;

void ProgramVisitor::NormalizeAndDedupCompressedStackMaps() {
  // Walks all the CSMs in Code objects and collects their entry information
  // for consolidation.
  class CollectStackMapEntriesVisitor : public FunctionVisitor {
   public:
    CollectStackMapEntriesVisitor(Zone* zone,
                                  const CompressedStackMaps& global_table)
        : zone_(zone),
          old_global_table_(global_table),
          code_(Code::Handle(zone)),
          compressed_stackmaps_(CompressedStackMaps::Handle(zone)),
          collected_entries_(zone, 2),
          entry_indices_(zone),
          entry_offset_(zone) {
      ASSERT(old_global_table_.IsNull() || old_global_table_.IsGlobalTable());
    }

    void Visit(const Function& function) {
      if (!function.HasCode()) return;
      code_ = function.CurrentCode();
      compressed_stackmaps_ = code_.compressed_stackmaps();
      CompressedStackMapsIterator it(compressed_stackmaps_, old_global_table_);
      while (it.MoveNext()) {
        it.EnsureFullyLoadedEntry();
        auto const entry = new (zone_) StackMapEntry(zone_, it);
        auto const index = entry_indices_.LookupValue(entry);
        if (index < 0) {
          auto new_index = collected_entries_.length();
          collected_entries_.Add(entry);
          entry_indices_.Insert({entry, new_index});
        } else {
          collected_entries_.At(index)->IncrementUsageCount();
        }
      }
    }

    // Creates a new global table of stack map information. Also adds the
    // offsets of encoded StackMapEntry objects to entry_offsets for use
    // when normalizing CompressedStackMaps.
    RawCompressedStackMaps* CreateGlobalTable(
        StackMapEntryIntMap* entry_offsets) {
      ASSERT(entry_offsets->IsEmpty());
      if (collected_entries_.length() == 0) return CompressedStackMaps::null();
      // First, sort the entries from most used to least used. This way,
      // the most often used CSMs will have the lowest offsets, which means
      // they will be smaller when LEB128 encoded.
      collected_entries_.Sort(
          [](StackMapEntry* const* e1, StackMapEntry* const* e2) {
            return static_cast<int>((*e2)->UsageCount() - (*e1)->UsageCount());
          });
      GrowableArray<uint8_t> bytes;
      // Encode the entries and record their offset in the payload. Sorting the
      // entries may have changed their indices, so update those as well.
      for (intptr_t i = 0, n = collected_entries_.length(); i < n; i++) {
        auto const entry = collected_entries_.At(i);
        entry_indices_.Update({entry, i});
        entry_offsets->Insert({entry, entry->EncodeTo(&bytes)});
      }
      const auto& data = CompressedStackMaps::Handle(
          zone_, CompressedStackMaps::NewGlobalTable(bytes));
      return data.raw();
    }

   private:
    Zone* const zone_;
    const CompressedStackMaps& old_global_table_;

    Code& code_;
    CompressedStackMaps& compressed_stackmaps_;
    GrowableArray<StackMapEntry*> collected_entries_;
    StackMapEntryIntMap entry_indices_;
    StackMapEntryIntMap entry_offset_;
  };

  // Walks all the CSMs in Code objects, normalizes them, and then dedups them.
  //
  // We use normalized to refer to CSMs whose entries are references to the
  // new global table created during stack map collection, and non-normalized
  // for CSMs that either have inlined entry information or whose entries are
  // references to the _old_ global table in the object store, if any.
  class NormalizeAndDedupCompressedStackMapsVisitor : public FunctionVisitor {
   public:
    NormalizeAndDedupCompressedStackMapsVisitor(
        Zone* zone,
        const CompressedStackMaps& global_table,
        const StackMapEntryIntMap& entry_offsets)
        : zone_(zone),
          old_global_table_(global_table),
          entry_offsets_(entry_offsets),
          canonical_compressed_stackmaps_set_(),
          code_(Code::Handle(zone)),
          compressed_stackmaps_(CompressedStackMaps::Handle(zone)),
          current_normalized_maps_(CompressedStackMaps::Handle(zone)) {
      ASSERT(old_global_table_.IsNull() || old_global_table_.IsGlobalTable());
    }

    // Creates a normalized CSM from the given non-normalized CSM.
    RawCompressedStackMaps* NormalizeEntries(const CompressedStackMaps& maps) {
      GrowableArray<uint8_t> new_payload;
      CompressedStackMapsIterator it(maps, old_global_table_);
      intptr_t last_offset = 0;
      while (it.MoveNext()) {
        it.EnsureFullyLoadedEntry();
        StackMapEntry entry(zone_, it);
        auto const entry_offset = entry_offsets_.LookupValue(&entry);
        auto const pc_delta = it.pc_offset() - last_offset;
        CompressedStackMapsBuilder::EncodeLEB128(&new_payload, pc_delta);
        CompressedStackMapsBuilder::EncodeLEB128(&new_payload, entry_offset);
        last_offset = it.pc_offset();
      }
      return CompressedStackMaps::NewUsingTable(new_payload);
    }

    RawCompressedStackMaps* NormalizeAndDedupCompressedStackMaps(
        const CompressedStackMaps& maps) {
      ASSERT(!maps.IsNull());
      // First check is to make sure [maps] hasn't already been normalized,
      // since any normalized map already has a canonical entry in the set.
      auto canonical_maps =
          canonical_compressed_stackmaps_set_.LookupValue(&maps);
      if (canonical_maps != nullptr) return canonical_maps->raw();
      current_normalized_maps_ = NormalizeEntries(compressed_stackmaps_);
      // Use the canonical entry for the newly normalized CSM, if one exists.
      canonical_maps = canonical_compressed_stackmaps_set_.LookupValue(
          &current_normalized_maps_);
      if (canonical_maps != nullptr) return canonical_maps->raw();
      canonical_compressed_stackmaps_set_.Insert(
          &CompressedStackMaps::ZoneHandle(zone_,
                                           current_normalized_maps_.raw()));
      return current_normalized_maps_.raw();
    }

    void Visit(const Function& function) {
      if (!function.HasCode()) return;
      code_ = function.CurrentCode();
      compressed_stackmaps_ = code_.compressed_stackmaps();
      // We represent empty CSMs as the null value, and thus those don't need to
      // be normalized or deduped.
      if (compressed_stackmaps_.IsNull()) return;
      compressed_stackmaps_ =
          NormalizeAndDedupCompressedStackMaps(compressed_stackmaps_);
      code_.set_compressed_stackmaps(compressed_stackmaps_);
    }

   private:
    Zone* const zone_;
    const CompressedStackMaps& old_global_table_;
    const StackMapEntryIntMap& entry_offsets_;
    CompressedStackMapsSet canonical_compressed_stackmaps_set_;
    Code& code_;
    CompressedStackMaps& compressed_stackmaps_;
    CompressedStackMaps& current_normalized_maps_;
  };

  // The stack map deduplication happens in two phases:
  // 1) Visit all CompressedStackMaps (CSM) objects and collect individual entry
  //    info as canonicalized StackMapEntries (SMEs). Also record the number of
  //    times the same entry info was seen across all CSMs in each SME.
  //
  // The results of phase 1 are used to create a new global table with entries
  // sorted by decreasing frequency, so that entries that appear more often in
  // CSMs have smaller payload offsets (less bytes used in the LEB128 encoding).
  //
  // 2) Visit all CSMs and replace each with a canonicalized normalized version
  //    that uses the new global table for non-PC offset entry information.
  Thread* const t = Thread::Current();
  StackZone temp_zone(t);
  HandleScope temp_handles(t);
  Zone* zone = temp_zone.GetZone();
  auto object_store = t->isolate()->object_store();
  const auto& old_global_table = CompressedStackMaps::Handle(
      zone, object_store->canonicalized_stack_map_entries());
  CollectStackMapEntriesVisitor collect_visitor(zone, old_global_table);
  ProgramVisitor::VisitFunctions(&collect_visitor);

  // We retrieve the new offsets for CSM entries by creating the new global
  // table now. We go ahead and put it in place, as we already have a handle
  // on the old table that we can pass to the normalizing visitor.
  StackMapEntryIntMap entry_offsets(zone);
  const auto& new_global_table = CompressedStackMaps::Handle(
      zone, collect_visitor.CreateGlobalTable(&entry_offsets));
  object_store->set_canonicalized_stack_map_entries(new_global_table);

  NormalizeAndDedupCompressedStackMapsVisitor dedup_visitor(
      zone, old_global_table, entry_offsets);
  ProgramVisitor::VisitFunctions(&dedup_visitor);
}

class PcDescriptorsKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const PcDescriptors* Key;
  typedef const PcDescriptors* Value;
  typedef const PcDescriptors* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Length(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

typedef DirectChainedHashMap<PcDescriptorsKeyValueTrait> PcDescriptorsSet;

void ProgramVisitor::DedupPcDescriptors() {
  class DedupPcDescriptorsVisitor : public FunctionVisitor {
   public:
    explicit DedupPcDescriptorsVisitor(Zone* zone)
        : zone_(zone),
          canonical_pc_descriptors_(),
          bytecode_(Bytecode::Handle(zone)),
          code_(Code::Handle(zone)),
          pc_descriptor_(PcDescriptors::Handle(zone)) {}

    void AddPcDescriptor(const PcDescriptors& pc_descriptor) {
      canonical_pc_descriptors_.Insert(
          &PcDescriptors::ZoneHandle(zone_, pc_descriptor.raw()));
    }

    void Visit(const Function& function) {
      bytecode_ = function.bytecode();
      if (!bytecode_.IsNull() && !bytecode_.InVMIsolateHeap()) {
        pc_descriptor_ = bytecode_.pc_descriptors();
        if (!pc_descriptor_.IsNull()) {
          pc_descriptor_ = DedupPcDescriptor(pc_descriptor_);
          bytecode_.set_pc_descriptors(pc_descriptor_);
        }
      }
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      pc_descriptor_ = code_.pc_descriptors();
      if (pc_descriptor_.IsNull()) return;
      pc_descriptor_ = DedupPcDescriptor(pc_descriptor_);
      code_.set_pc_descriptors(pc_descriptor_);
    }

    RawPcDescriptors* DedupPcDescriptor(const PcDescriptors& pc_descriptor) {
      const PcDescriptors* canonical_pc_descriptor =
          canonical_pc_descriptors_.LookupValue(&pc_descriptor);
      if (canonical_pc_descriptor == NULL) {
        AddPcDescriptor(pc_descriptor);
        return pc_descriptor.raw();
      } else {
        return canonical_pc_descriptor->raw();
      }
    }

   private:
    Zone* zone_;
    PcDescriptorsSet canonical_pc_descriptors_;
    Bytecode& bytecode_;
    Code& code_;
    PcDescriptors& pc_descriptor_;
  };

  DedupPcDescriptorsVisitor visitor(Thread::Current()->zone());
  if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
    // Prefer existing objects in the VM isolate.
    const Array& object_table = Object::vm_isolate_snapshot_object_table();
    Object& object = Object::Handle();
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      object = object_table.At(i);
      if (object.IsPcDescriptors()) {
        visitor.AddPcDescriptor(PcDescriptors::Cast(object));
      }
    }
  }
  ProgramVisitor::VisitFunctions(&visitor);
}

class TypedDataKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const TypedData* Key;
  typedef const TypedData* Value;
  typedef const TypedData* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->CanonicalizeHash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->CanonicalizeEquals(*key);
  }
};

typedef DirectChainedHashMap<TypedDataKeyValueTrait> TypedDataSet;

void ProgramVisitor::DedupDeoptEntries() {
  class DedupDeoptEntriesVisitor : public FunctionVisitor {
   public:
    explicit DedupDeoptEntriesVisitor(Zone* zone)
        : zone_(zone),
          canonical_deopt_entries_(),
          code_(Code::Handle(zone)),
          deopt_table_(Array::Handle(zone)),
          deopt_entry_(TypedData::Handle(zone)),
          offset_(Smi::Handle(zone)),
          reason_and_flags_(Smi::Handle(zone)) {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      deopt_table_ = code_.deopt_info_array();
      if (deopt_table_.IsNull()) return;
      intptr_t length = DeoptTable::GetLength(deopt_table_);
      for (intptr_t i = 0; i < length; i++) {
        DeoptTable::GetEntry(deopt_table_, i, &offset_, &deopt_entry_,
                             &reason_and_flags_);
        ASSERT(!deopt_entry_.IsNull());
        deopt_entry_ = DedupDeoptEntry(deopt_entry_);
        ASSERT(!deopt_entry_.IsNull());
        DeoptTable::SetEntry(deopt_table_, i, offset_, deopt_entry_,
                             reason_and_flags_);
      }
    }

    RawTypedData* DedupDeoptEntry(const TypedData& deopt_entry) {
      const TypedData* canonical_deopt_entry =
          canonical_deopt_entries_.LookupValue(&deopt_entry);
      if (canonical_deopt_entry == NULL) {
        canonical_deopt_entries_.Insert(
            &TypedData::ZoneHandle(zone_, deopt_entry.raw()));
        return deopt_entry.raw();
      } else {
        return canonical_deopt_entry->raw();
      }
    }

   private:
    Zone* zone_;
    TypedDataSet canonical_deopt_entries_;
    Code& code_;
    Array& deopt_table_;
    TypedData& deopt_entry_;
    Smi& offset_;
    Smi& reason_and_flags_;
  };

  DedupDeoptEntriesVisitor visitor(Thread::Current()->zone());
  ProgramVisitor::VisitFunctions(&visitor);
}

#if defined(DART_PRECOMPILER)
void ProgramVisitor::DedupCatchEntryMovesMaps() {
  if (!FLAG_precompiled_mode) {
    return;
  }
  class DedupCatchEntryMovesMapsVisitor : public FunctionVisitor {
   public:
    explicit DedupCatchEntryMovesMapsVisitor(Zone* zone)
        : zone_(zone),
          canonical_catch_entry_moves_maps_(),
          code_(Code::Handle(zone)),
          catch_entry_moves_maps_(TypedData::Handle(zone)) {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      catch_entry_moves_maps_ = code_.catch_entry_moves_maps();
      catch_entry_moves_maps_ =
          DedupCatchEntryMovesMaps(catch_entry_moves_maps_);
      code_.set_catch_entry_moves_maps(catch_entry_moves_maps_);
    }

    RawTypedData* DedupCatchEntryMovesMaps(
        const TypedData& catch_entry_moves_maps) {
      const TypedData* canonical_catch_entry_moves_maps =
          canonical_catch_entry_moves_maps_.LookupValue(
              &catch_entry_moves_maps);
      if (canonical_catch_entry_moves_maps == NULL) {
        canonical_catch_entry_moves_maps_.Insert(
            &TypedData::ZoneHandle(zone_, catch_entry_moves_maps.raw()));
        return catch_entry_moves_maps.raw();
      } else {
        return canonical_catch_entry_moves_maps->raw();
      }
    }

   private:
    Zone* zone_;
    TypedDataSet canonical_catch_entry_moves_maps_;
    Code& code_;
    TypedData& catch_entry_moves_maps_;
  };

  DedupCatchEntryMovesMapsVisitor visitor(Thread::Current()->zone());
  ProgramVisitor::VisitFunctions(&visitor);
}
#endif  // !defined(DART_PRECOMPILER)

class CodeSourceMapKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const CodeSourceMap* Key;
  typedef const CodeSourceMap* Value;
  typedef const CodeSourceMap* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Length(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

typedef DirectChainedHashMap<CodeSourceMapKeyValueTrait> CodeSourceMapSet;

void ProgramVisitor::DedupCodeSourceMaps() {
  class DedupCodeSourceMapsVisitor : public FunctionVisitor {
   public:
    explicit DedupCodeSourceMapsVisitor(Zone* zone)
        : zone_(zone),
          canonical_code_source_maps_(),
          code_(Code::Handle(zone)),
          code_source_map_(CodeSourceMap::Handle(zone)) {}

    void AddCodeSourceMap(const CodeSourceMap& code_source_map) {
      canonical_code_source_maps_.Insert(
          &CodeSourceMap::ZoneHandle(zone_, code_source_map.raw()));
    }

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      code_source_map_ = code_.code_source_map();
      ASSERT(!code_source_map_.IsNull());
      code_source_map_ = DedupCodeSourceMap(code_source_map_);
      code_.set_code_source_map(code_source_map_);
    }

    RawCodeSourceMap* DedupCodeSourceMap(const CodeSourceMap& code_source_map) {
      const CodeSourceMap* canonical_code_source_map =
          canonical_code_source_maps_.LookupValue(&code_source_map);
      if (canonical_code_source_map == NULL) {
        AddCodeSourceMap(code_source_map);
        return code_source_map.raw();
      } else {
        return canonical_code_source_map->raw();
      }
    }

   private:
    Zone* zone_;
    CodeSourceMapSet canonical_code_source_maps_;
    Code& code_;
    CodeSourceMap& code_source_map_;
  };

  DedupCodeSourceMapsVisitor visitor(Thread::Current()->zone());
  if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
    // Prefer existing objects in the VM isolate.
    const Array& object_table = Object::vm_isolate_snapshot_object_table();
    Object& object = Object::Handle();
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      object = object_table.At(i);
      if (object.IsCodeSourceMap()) {
        visitor.AddCodeSourceMap(CodeSourceMap::Cast(object));
      }
    }
  }
  ProgramVisitor::VisitFunctions(&visitor);
}

class ArrayKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Array* Key;
  typedef const Array* Value;
  typedef const Array* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Length(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    if (pair->Length() != key->Length()) {
      return false;
    }
    for (intptr_t i = 0; i < pair->Length(); i++) {
      if (pair->At(i) != key->At(i)) {
        return false;
      }
    }
    return true;
  }
};

typedef DirectChainedHashMap<ArrayKeyValueTrait> ArraySet;

void ProgramVisitor::DedupLists() {
  class DedupListsVisitor : public FunctionVisitor {
   public:
    explicit DedupListsVisitor(Zone* zone)
        : zone_(zone),
          canonical_lists_(),
          code_(Code::Handle(zone)),
          list_(Array::Handle(zone)) {}

    void Visit(const Function& function) {
      code_ = function.CurrentCode();
      if (!code_.IsNull()) {
        list_ = code_.inlined_id_to_function();
        if (!list_.IsNull()) {
          list_ = DedupList(list_);
          code_.set_inlined_id_to_function(list_);
        }
        list_ = code_.deopt_info_array();
        if (!list_.IsNull()) {
          list_ = DedupList(list_);
          code_.set_deopt_info_array(list_);
        }
        list_ = code_.static_calls_target_table();
        if (!list_.IsNull()) {
          list_ = DedupList(list_);
          code_.set_static_calls_target_table(list_);
        }
      }

      list_ = function.parameter_types();
      if (!list_.IsNull()) {
        // Preserve parameter types in the JIT. Needed in case of recompilation
        // in checked mode, or if available to mirrors, or for copied types to
        // lazily generated tear offs.
        if (FLAG_precompiled_mode) {
          if (!function.IsSignatureFunction() &&
              !function.IsClosureFunction() &&
              (function.name() != Symbols::Call().raw()) &&
              !list_.InVMIsolateHeap()) {
            // Parameter types not needed for function type tests.
            for (intptr_t i = 0; i < list_.Length(); i++) {
              list_.SetAt(i, Object::dynamic_type());
            }
          }
        }
        list_ = DedupList(list_);
        function.set_parameter_types(list_);
      }

      list_ = function.parameter_names();
      if (!list_.IsNull()) {
        // Preserve parameter names in case of recompilation for the JIT.
        if (FLAG_precompiled_mode) {
          if (!function.HasOptionalNamedParameters() &&
              !list_.InVMIsolateHeap()) {
            // Parameter names not needed for resolution.
            for (intptr_t i = 0; i < list_.Length(); i++) {
              list_.SetAt(i, Symbols::OptimizedOut());
            }
          }
        }
        list_ = DedupList(list_);
        function.set_parameter_names(list_);
      }
    }

    RawArray* DedupList(const Array& list) {
      if (list.InVMIsolateHeap()) {
        // Avoid using read-only VM objects for de-duplication.
        return list.raw();
      }
      const Array* canonical_list = canonical_lists_.LookupValue(&list);
      if (canonical_list == NULL) {
        canonical_lists_.Insert(&Array::ZoneHandle(zone_, list.raw()));
        return list.raw();
      } else {
        return canonical_list->raw();
      }
    }

   private:
    Zone* zone_;
    ArraySet canonical_lists_;
    Code& code_;
    Array& list_;
  };

  DedupListsVisitor visitor(Thread::Current()->zone());
  ProgramVisitor::VisitFunctions(&visitor);
}

// Traits for comparing two [Instructions] objects for equality, which is
// implemented as bit-wise equality.
//
// This considers two instruction objects to be equal even if they have
// different static call targets.  Since the static call targets are called via
// the object pool this is ok.
class InstructionsKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Instructions* Key;
  typedef const Instructions* Value;
  typedef const Instructions* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Size(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

typedef DirectChainedHashMap<InstructionsKeyValueTrait> InstructionsSet;

// Traits for comparing two [Code] objects for equality.
//
// The instruction deduplication naturally causes us to have a one-to-many
// relationship between Instructions and Code objects.
//
// In AOT bare instructions mode frames only have PCs. However, the runtime
// needs e.g. stack maps from the [Code] to scan such a frame. So we ensure that
// instructions of code objects are only deduplicated if the metadata in the
// code is the same. The runtime can then pick any code object corresponding to
// the PC in the frame and use the metadata.
//
// In AOT non-bare instructions mode frames are expanded, like in JIT, and
// contain the unique code object.
#if defined(DART_PRECOMPILER)
class CodeKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Code* Key;
  typedef const Code* Value;
  typedef const Code* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Size(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    // In AOT, disabled code objects should not be considered for deduplication.
    ASSERT(!pair->IsDisabled() && !key->IsDisabled());

    if (pair->raw() == key->raw()) return true;

    // Notice we assume that these entries have already been de-duped, so we
    // can use pointer equality.
    if (pair->static_calls_target_table() != key->static_calls_target_table()) {
      return false;
    }
    if (pair->pc_descriptors() != key->pc_descriptors()) {
      return false;
    }
    if (pair->compressed_stackmaps() != key->compressed_stackmaps()) {
      return false;
    }
    if (pair->catch_entry_moves_maps() != key->catch_entry_moves_maps()) {
      return false;
    }
    if (pair->exception_handlers() != key->exception_handlers()) {
      return false;
    }
    if (pair->UncheckedEntryPointOffset() != key->UncheckedEntryPointOffset()) {
      return false;
    }
    return Instructions::Equals(pair->instructions(), key->instructions());
  }
};

typedef DirectChainedHashMap<CodeKeyValueTrait> CodeSet;
#endif  // defined(DART_PRECOMPILER)

void ProgramVisitor::DedupInstructions() {
  class DedupInstructionsVisitor : public FunctionVisitor,
                                   public ObjectVisitor {
   public:
    explicit DedupInstructionsVisitor(Zone* zone)
        : zone_(zone),
          canonical_instructions_set_(),
          code_(Code::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {}

    void VisitObject(RawObject* obj) {
      if (obj->IsInstructions()) {
        canonical_instructions_set_.Insert(
            &Instructions::ZoneHandle(zone_, Instructions::RawCast(obj)));
      }
    }

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      instructions_ = code_.instructions();
      instructions_ = DedupOneInstructions(instructions_);
      code_.SetActiveInstructions(instructions_,
                                  code_.UncheckedEntryPointOffset());
      code_.set_instructions(instructions_);
      function.SetInstructions(code_);  // Update cached entry point.
    }

    RawInstructions* DedupOneInstructions(const Instructions& instructions) {
      const Instructions* canonical_instructions =
          canonical_instructions_set_.LookupValue(&instructions);
      if (canonical_instructions == NULL) {
        canonical_instructions_set_.Insert(
            &Instructions::ZoneHandle(zone_, instructions.raw()));
        return instructions.raw();
      } else {
        return canonical_instructions->raw();
      }
    }

   private:
    Zone* zone_;
    InstructionsSet canonical_instructions_set_;
    Code& code_;
    Instructions& instructions_;
  };

  DedupInstructionsVisitor visitor(Thread::Current()->zone());
  if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
    // Prefer existing objects in the VM isolate.
    Dart::vm_isolate()->heap()->VisitObjectsImagePages(&visitor);
  }
  ProgramVisitor::VisitFunctions(&visitor);
}

void ProgramVisitor::DedupInstructionsWithSameMetadata() {
#if defined(DART_PRECOMPILER)
  class DedupInstructionsWithSameMetadataVisitor : public FunctionVisitor,
                                                   public ObjectVisitor {
   public:
    explicit DedupInstructionsWithSameMetadataVisitor(Zone* zone)
        : zone_(zone),
          canonical_set_(),
          code_(Code::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {}

    void VisitObject(RawObject* obj) {
      if (obj->IsCode()) {
        const auto code = Code::RawCast(obj);
        if (Code::IsDisabled(code)) return;
        canonical_set_.Insert(&Code::ZoneHandle(zone_, code));
      }
    }

    void Visit(const Function& function) {
      if (!function.HasCode() || Code::IsDisabled(function.CurrentCode())) {
        return;
      }
      code_ = function.CurrentCode();
      instructions_ = DedupOneInstructions(function, code_);
      code_.SetActiveInstructions(instructions_,
                                  code_.UncheckedEntryPointOffset());
      code_.set_instructions(instructions_);
      function.SetInstructions(code_);  // Update cached entry point.
    }

    RawInstructions* DedupOneInstructions(const Function& function,
                                          const Code& code) {
      const Code* canonical = canonical_set_.LookupValue(&code);
      if (canonical == nullptr) {
        canonical_set_.Insert(&Code::ZoneHandle(zone_, code.raw()));
        return code.instructions();
      } else {
        return canonical->instructions();
      }
    }

   private:
    Zone* zone_;
    CodeSet canonical_set_;
    Code& code_;
    Instructions& instructions_;
  };

  DedupInstructionsWithSameMetadataVisitor visitor(Thread::Current()->zone());
  ProgramVisitor::VisitFunctions(&visitor);
#endif  // defined(DART_PRECOMPILER)
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ProgramVisitor::Dedup() {
#if !defined(DART_PRECOMPILED_RUNTIME)
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);

  BindStaticCalls();
  ShareMegamorphicBuckets();
  NormalizeAndDedupCompressedStackMaps();
  DedupPcDescriptors();
  NOT_IN_PRECOMPILED(DedupDeoptEntries());
#if defined(DART_PRECOMPILER)
  DedupCatchEntryMovesMaps();
#endif
  DedupCodeSourceMaps();
  DedupLists();

  // Reduces binary size but obfuscates profiler results.
  if (FLAG_dedup_instructions) {
    if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
      DedupInstructionsWithSameMetadata();
    } else {
      DedupInstructions();
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
