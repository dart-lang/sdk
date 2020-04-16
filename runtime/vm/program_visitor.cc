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

class ProgramWalker : public CodeVisitor {
 public:
  ProgramWalker(Zone* zone, ClassVisitor* visitor)
      : visitor_(visitor),
        object_(Object::Handle(zone)),
        fields_(Array::Handle(zone)),
        field_(Field::Handle(zone)),
        functions_(Array::Handle(zone)),
        function_(Function::Handle(zone)),
        code_(Code::Handle(zone)) {}

  void VisitClass(const Class& cls) {
    ASSERT(!cls.IsNull());
    if (cls.InVMIsolateHeap()) return;
    visitor_->VisitClass(cls);

    if (!visitor_->IsFunctionVisitor()) return;

    functions_ = cls.functions();
    for (intptr_t j = 0; j < functions_.Length(); j++) {
      function_ ^= functions_.At(j);
      VisitFunction(function_);
      if (function_.HasImplicitClosureFunction()) {
        function_ = function_.ImplicitClosureFunction();
        VisitFunction(function_);
      }
    }

    functions_ = cls.invocation_dispatcher_cache();
    for (intptr_t j = 0; j < functions_.Length(); j++) {
      object_ = functions_.At(j);
      if (object_.IsFunction()) {
        function_ ^= functions_.At(j);
        VisitFunction(function_);
      }
    }

    fields_ = cls.fields();
    for (intptr_t j = 0; j < fields_.Length(); j++) {
      field_ ^= fields_.At(j);
      if (field_.is_static() && field_.HasInitializerFunction()) {
        function_ = field_.InitializerFunction();
        VisitFunction(function_);
      }
    }

    if (!visitor_->IsCodeVisitor()) return;

    code_ = cls.allocation_stub();
    if (!code_.IsNull()) VisitCode(code_);
  }

  void VisitFunction(const Function& function) {
    ASSERT(visitor_->IsFunctionVisitor());
    ASSERT(!function.IsNull());
    if (function.InVMIsolateHeap()) return;
    visitor_->AsFunctionVisitor()->VisitFunction(function);
    if (!visitor_->IsCodeVisitor() || !function.HasCode()) return;
    code_ = function.CurrentCode();
    VisitCode(code_);
  }

  void VisitCode(const Code& code) {
    ASSERT(visitor_->IsCodeVisitor());
    ASSERT(!code.IsNull());
    if (code.InVMIsolateHeap()) return;
    visitor_->AsCodeVisitor()->VisitCode(code);
  }

  void VisitObject(const Object& object) {
    if (object.IsNull()) return;
    if (object.IsClass()) {
      VisitClass(Class::Cast(object));
    } else if (visitor_->IsFunctionVisitor() && object.IsFunction()) {
      VisitFunction(Function::Cast(object));
    } else if (visitor_->IsCodeVisitor() && object.IsCode()) {
      VisitCode(Code::Cast(object));
    }
  }

 private:
  ClassVisitor* const visitor_;
  Object& object_;
  Array& fields_;
  Field& field_;
  Array& functions_;
  Function& function_;
  Code& code_;
};

void ProgramVisitor::WalkProgram(Zone* zone,
                                 Isolate* isolate,
                                 ClassVisitor* visitor) {
  auto const object_store = isolate->object_store();
  ProgramWalker walker(zone, visitor);

  // Walk through the libraries and patches, looking for visitable objects.
  const auto& libraries =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  auto& lib = Library::Handle(zone);
  auto& cls = Class::Handle(zone);
  auto& entry = Object::Handle(zone);
  auto& patches = GrowableObjectArray::Handle(zone);

  for (intptr_t i = 0; i < libraries.Length(); i++) {
    lib ^= libraries.At(i);
    ClassDictionaryIterator it(lib, ClassDictionaryIterator::kIteratePrivate);
    while (it.HasNext()) {
      cls = it.GetNextClass();
      walker.VisitClass(cls);
    }
    patches = lib.used_scripts();
    for (intptr_t j = 0; j < patches.Length(); j++) {
      entry = patches.At(j);
      walker.VisitObject(entry);
    }
  }

  if (!visitor->IsFunctionVisitor()) return;

  // Function objects not necessarily reachable from classes.
  auto& function = Function::Handle(zone);
  const auto& closures =
      GrowableObjectArray::Handle(zone, object_store->closure_functions());
  ASSERT(!closures.IsNull());
  for (intptr_t i = 0; i < closures.Length(); i++) {
    function ^= closures.At(i);
    walker.VisitFunction(function);
    ASSERT(!function.HasImplicitClosureFunction());
  }

  // If there's a global object pool, check for functions like FfiTrampolines.
  const auto& global_object_pool =
      ObjectPool::Handle(zone, object_store->global_object_pool());
  if (!global_object_pool.IsNull()) {
    auto& object = Object::Handle(zone);
    for (intptr_t i = 0; i < global_object_pool.Length(); i++) {
      auto const type = global_object_pool.TypeAt(i);
      if (type != ObjectPool::EntryType::kTaggedObject) continue;
      object = global_object_pool.ObjectAt(i);
      if (object.IsFunction() && visitor->IsFunctionVisitor()) {
        walker.VisitFunction(Function::Cast(object));
      }
    }
  }

  if (!visitor->IsCodeVisitor()) return;

  // Code objects not necessarily reachable from functions.
  auto& code = Code::Handle(zone);
  const auto& dispatch_table_entries =
      Array::Handle(zone, object_store->dispatch_table_code_entries());
  if (!dispatch_table_entries.IsNull()) {
    for (intptr_t i = 0; i < dispatch_table_entries.Length(); i++) {
      code ^= dispatch_table_entries.At(i);
      if (code.IsNull()) continue;
      walker.VisitCode(code);
    }
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// A base class for deduplication of objects. T is the type of canonical objects
// being stored, whereas S is a trait appropriate for a DirectChainedHashMap
// based set containing those canonical objects.
template <typename T, typename S>
class Dedupper : public ValueObject {
 public:
  explicit Dedupper(Zone* zone) : zone_(zone), canonical_objects_(zone) {}
  virtual ~Dedupper() {}

 protected:
  // Predicate for objects of type T. Must be overridden for class hierarchies
  // like Instance and AbstractType, as it defaults to class ID comparison.
  virtual bool IsCorrectType(const Object& obj) const {
    return obj.GetClassId() == T::kClassId;
  }

  // Predicate for choosing Ts to canonicalize.
  virtual bool CanCanonicalize(const T& t) const { return true; }

  // Predicate for objects that are okay to add to the canonical hash set.
  // Override IsCorrectType and/or CanCanonicalize to change the behavior.
  bool ShouldAdd(const Object& obj) const {
    return !obj.IsNull() && IsCorrectType(obj) && CanCanonicalize(T::Cast(obj));
  }

  void AddCanonical(const T& obj) {
    if (!ShouldAdd(obj)) return;
    ASSERT(!canonical_objects_.HasKey(&obj));
    canonical_objects_.Insert(&T::ZoneHandle(zone_, obj.raw()));
  }

  void AddVMBaseObjects() {
    const auto& object_table = Object::vm_isolate_snapshot_object_table();
    auto& obj = Object::Handle(zone_);
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      obj = object_table.At(i);
      if (!ShouldAdd(obj)) continue;
      AddCanonical(T::Cast(obj));
    }
  }

  typename T::RawObjectType* Dedup(const T& obj) {
    if (ShouldAdd(obj)) {
      if (auto const canonical = canonical_objects_.LookupValue(&obj)) {
        return canonical->raw();
      }
      AddCanonical(obj);
    }
    return obj.raw();
  }

  Zone* const zone_;
  DirectChainedHashMap<S> canonical_objects_;
};

void ProgramVisitor::BindStaticCalls(Zone* zone, Isolate* isolate) {
  class BindStaticCallsVisitor : public CodeVisitor {
   public:
    explicit BindStaticCallsVisitor(Zone* zone)
        : table_(Array::Handle(zone)),
          kind_and_offset_(Smi::Handle(zone)),
          target_(Object::Handle(zone)),
          target_code_(Code::Handle(zone)) {}

    void VisitCode(const Code& code) {
      table_ = code.static_calls_target_table();
      if (table_.IsNull()) return;

      StaticCallsTable static_calls(table_);
      // We can only remove the target table in precompiled mode, since more
      // calls may be added later otherwise.
      bool only_call_via_code = FLAG_precompiled_mode;
      for (const auto& view : static_calls) {
        kind_and_offset_ = view.Get<Code::kSCallTableKindAndOffset>();
        auto const kind = Code::KindField::decode(kind_and_offset_.Value());
        if (kind != Code::kCallViaCode) {
          ASSERT(!FLAG_precompiled_mode || kind == Code::kPcRelativeCall ||
                 kind == Code::kPcRelativeTailCall);
          only_call_via_code = false;
          continue;
        }

        target_ = view.Get<Code::kSCallTableFunctionTarget>();
        if (target_.IsNull()) {
          target_ = view.Get<Code::kSCallTableCodeTarget>();
          ASSERT(!Code::Cast(target_).IsFunctionCode());
          // Allocation stub or AllocateContext or AllocateArray or ...
          continue;
        }

        auto const pc_offset =
            Code::OffsetField::decode(kind_and_offset_.Value());
        const uword pc = pc_offset + code.PayloadStart();

        // In JIT mode, static calls initially call the CallStaticFunction stub
        // because their target might not be compiled yet. If the target has
        // been compiled by this point, we patch the call to call the target
        // directly.
        //
        // In precompiled mode, the binder runs after tree shaking, during which
        // all targets have been compiled, and so the binder replace all static
        // calls with direct calls to the target.
        //
        // Cf. runtime entry PatchStaticCall called from CallStaticFunction
        // stub.
        const auto& fun = Function::Cast(target_);
        ASSERT(!FLAG_precompiled_mode || fun.HasCode());
        target_code_ = fun.HasCode() ? fun.CurrentCode()
                                     : StubCode::CallStaticFunction().raw();
        CodePatcher::PatchStaticCallAt(pc, code, target_code_);
      }

      if (only_call_via_code) {
        ASSERT(FLAG_precompiled_mode);
        // In precompiled mode, the Dart runtime won't patch static calls
        // anymore, so drop the static call table to save space.
        code.set_static_calls_target_table(Object::empty_array());
      }
    }

   private:
    Array& table_;
    Smi& kind_and_offset_;
    Object& target_;
    Code& target_code_;
  };

  BindStaticCallsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
}

DECLARE_FLAG(charp, write_v8_snapshot_profile_to);

void ProgramVisitor::ShareMegamorphicBuckets(Zone* zone, Isolate* isolate) {
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

void ProgramVisitor::NormalizeAndDedupCompressedStackMaps(Zone* zone,
                                                          Isolate* isolate) {
  // Walks all the CSMs in Code objects and collects their entry information
  // for consolidation.
  class CollectStackMapEntriesVisitor : public CodeVisitor {
   public:
    CollectStackMapEntriesVisitor(Zone* zone,
                                  const CompressedStackMaps& global_table)
        : zone_(zone),
          old_global_table_(global_table),
          compressed_stackmaps_(CompressedStackMaps::Handle(zone)),
          collected_entries_(zone, 2),
          entry_indices_(zone),
          entry_offset_(zone) {
      ASSERT(old_global_table_.IsNull() || old_global_table_.IsGlobalTable());
    }

    void VisitCode(const Code& code) {
      compressed_stackmaps_ = code.compressed_stackmaps();
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
  class NormalizeAndDedupCompressedStackMapsVisitor
      : public CodeVisitor,
        public Dedupper<CompressedStackMaps,
                        PointerKeyValueTrait<const CompressedStackMaps>> {
   public:
    NormalizeAndDedupCompressedStackMapsVisitor(Zone* zone, Isolate* isolate)
        : Dedupper(zone),
          old_global_table_(CompressedStackMaps::Handle(
              zone,
              isolate->object_store()->canonicalized_stack_map_entries())),
          entry_offsets_(zone),
          maps_(CompressedStackMaps::Handle(zone)) {
      ASSERT(old_global_table_.IsNull() || old_global_table_.IsGlobalTable());
      // The stack map normalization and deduplication happens in two phases:
      //
      // 1) Visit all CompressedStackMaps (CSM) objects and collect individual
      // entry info as canonicalized StackMapEntries (SMEs). Also record the
      // frequency the same entry info was seen across all CSMs in each SME.

      CollectStackMapEntriesVisitor collect_visitor(zone, old_global_table_);
      WalkProgram(zone, isolate, &collect_visitor);

      // The results of phase 1 are used to create a new global table with
      // entries sorted by decreasing frequency, so that entries that appear
      // more often in CSMs have smaller payload offsets (less bytes used in
      // the LEB128 encoding). The new global table is put into place
      // immediately, as we already have a handle on the old table.

      const auto& new_global_table = CompressedStackMaps::Handle(
          zone, collect_visitor.CreateGlobalTable(&entry_offsets_));
      isolate->object_store()->set_canonicalized_stack_map_entries(
          new_global_table);

      // 2) Visit all CSMs and replace each with a canonicalized normalized
      // version that uses the new global table for non-PC offset entry
      // information. This part is done in VisitCode.
    }

    void VisitCode(const Code& code) {
      maps_ = code.compressed_stackmaps();
      if (maps_.IsNull()) return;
      // First check is to make sure [maps] hasn't already been normalized,
      // since any normalized map already has a canonical entry in the set.
      if (auto const canonical = canonical_objects_.LookupValue(&maps_)) {
        maps_ = canonical->raw();
      } else {
        maps_ = NormalizeEntries(maps_);
        maps_ = Dedup(maps_);
      }
      code.set_compressed_stackmaps(maps_);
    }

   private:
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

    const CompressedStackMaps& old_global_table_;
    StackMapEntryIntMap entry_offsets_;
    CompressedStackMaps& maps_;
  };

  NormalizeAndDedupCompressedStackMapsVisitor dedup_visitor(zone, isolate);
  WalkProgram(zone, isolate, &dedup_visitor);
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

void ProgramVisitor::DedupPcDescriptors(Zone* zone, Isolate* isolate) {
  class DedupPcDescriptorsVisitor
      : public CodeVisitor,
        public Dedupper<PcDescriptors, PcDescriptorsKeyValueTrait> {
   public:
    explicit DedupPcDescriptorsVisitor(Zone* zone)
        : Dedupper(zone),
          bytecode_(Bytecode::Handle(zone)),
          pc_descriptor_(PcDescriptors::Handle(zone)) {
      if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
        // Prefer existing objects in the VM isolate.
        AddVMBaseObjects();
      }
    }

    void VisitCode(const Code& code) {
      pc_descriptor_ = code.pc_descriptors();
      pc_descriptor_ = Dedup(pc_descriptor_);
      code.set_pc_descriptors(pc_descriptor_);
    }

    void VisitFunction(const Function& function) {
      bytecode_ = function.bytecode();
      if (bytecode_.IsNull()) return;
      if (bytecode_.InVMIsolateHeap()) return;
      pc_descriptor_ = bytecode_.pc_descriptors();
      pc_descriptor_ = Dedup(pc_descriptor_);
      bytecode_.set_pc_descriptors(pc_descriptor_);
    }

   private:
    Bytecode& bytecode_;
    PcDescriptors& pc_descriptor_;
  };

  DedupPcDescriptorsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
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

class TypedDataDedupper : public Dedupper<TypedData, TypedDataKeyValueTrait> {
 public:
  explicit TypedDataDedupper(Zone* zone) : Dedupper(zone) {}

 private:
  bool IsCorrectType(const Object& obj) const { return obj.IsTypedData(); }
};

void ProgramVisitor::DedupDeoptEntries(Zone* zone, Isolate* isolate) {
  class DedupDeoptEntriesVisitor : public CodeVisitor,
                                   public TypedDataDedupper {
   public:
    explicit DedupDeoptEntriesVisitor(Zone* zone)
        : TypedDataDedupper(zone),
          deopt_table_(Array::Handle(zone)),
          deopt_entry_(TypedData::Handle(zone)),
          offset_(Smi::Handle(zone)),
          reason_and_flags_(Smi::Handle(zone)) {}

    void VisitCode(const Code& code) {
      deopt_table_ = code.deopt_info_array();
      if (deopt_table_.IsNull()) return;
      intptr_t length = DeoptTable::GetLength(deopt_table_);
      for (intptr_t i = 0; i < length; i++) {
        DeoptTable::GetEntry(deopt_table_, i, &offset_, &deopt_entry_,
                             &reason_and_flags_);
        ASSERT(!deopt_entry_.IsNull());
        deopt_entry_ = Dedup(deopt_entry_);
        ASSERT(!deopt_entry_.IsNull());
        DeoptTable::SetEntry(deopt_table_, i, offset_, deopt_entry_,
                             reason_and_flags_);
      }
    }

   private:
    Array& deopt_table_;
    TypedData& deopt_entry_;
    Smi& offset_;
    Smi& reason_and_flags_;
  };

  DedupDeoptEntriesVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
}

#if defined(DART_PRECOMPILER)
void ProgramVisitor::DedupCatchEntryMovesMaps(Zone* zone, Isolate* isolate) {
  class DedupCatchEntryMovesMapsVisitor : public CodeVisitor,
                                          public TypedDataDedupper {
   public:
    explicit DedupCatchEntryMovesMapsVisitor(Zone* zone)
        : TypedDataDedupper(zone),
          catch_entry_moves_maps_(TypedData::Handle(zone)) {}

    void VisitCode(const Code& code) {
      catch_entry_moves_maps_ = code.catch_entry_moves_maps();
      catch_entry_moves_maps_ = Dedup(catch_entry_moves_maps_);
      code.set_catch_entry_moves_maps(catch_entry_moves_maps_);
    }

   private:
    TypedData& catch_entry_moves_maps_;
  };

  if (!FLAG_precompiled_mode) return;
  DedupCatchEntryMovesMapsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
}

class UnlinkedCallKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const UnlinkedCall* Key;
  typedef const UnlinkedCall* Value;
  typedef const UnlinkedCall* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Hashcode(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

void ProgramVisitor::DedupUnlinkedCalls(Zone* zone, Isolate* isolate) {
  class DedupUnlinkedCallsVisitor
      : public CodeVisitor,
        public Dedupper<UnlinkedCall, UnlinkedCallKeyValueTrait> {
   public:
    explicit DedupUnlinkedCallsVisitor(Zone* zone, Isolate* isolate)
        : Dedupper(zone),
          entry_(Object::Handle(zone)),
          pool_(ObjectPool::Handle(zone)) {
      auto& gop = ObjectPool::Handle(
          zone, isolate->object_store()->global_object_pool());
      ASSERT_EQUAL(!gop.IsNull(), FLAG_use_bare_instructions);
      DedupPool(gop);
    }

    void DedupPool(const ObjectPool& pool) {
      if (pool.IsNull()) return;
      for (intptr_t i = 0; i < pool.Length(); i++) {
        if (pool.TypeAt(i) != ObjectPool::EntryType::kTaggedObject) {
          continue;
        }
        entry_ = pool.ObjectAt(i);
        if (!entry_.IsUnlinkedCall()) continue;
        entry_ = Dedup(UnlinkedCall::Cast(entry_));
        pool.SetObjectAt(i, entry_);
      }
    }

    void VisitCode(const Code& code) {
      pool_ = code.object_pool();
      DedupPool(pool_);
    }

   private:
    Object& entry_;
    ObjectPool& pool_;
  };

  if (!FLAG_precompiled_mode) return;

  DedupUnlinkedCallsVisitor deduper(zone, isolate);

  // Note: in bare instructions mode we can still have object pools attached
  // to code objects and these pools need to be deduplicated.
  // We use these pools to carry information about references between code
  // objects and other objects in the snapshots (these references are otherwise
  // implicit and go through global object pool). This information is needed
  // to produce more informative snapshot profile.
  if (!FLAG_use_bare_instructions ||
      FLAG_write_v8_snapshot_profile_to != nullptr) {
    WalkProgram(zone, isolate, &deduper);
  }
}
#endif  // defined(DART_PRECOMPILER)

class CodeSourceMapKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const CodeSourceMap* Key;
  typedef const CodeSourceMap* Value;
  typedef const CodeSourceMap* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    ASSERT(!key->IsNull());
    return key->Length();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    ASSERT(!pair->IsNull() && !key->IsNull());
    return pair->Equals(*key);
  }
};

void ProgramVisitor::DedupCodeSourceMaps(Zone* zone, Isolate* isolate) {
  class DedupCodeSourceMapsVisitor
      : public CodeVisitor,
        public Dedupper<CodeSourceMap, CodeSourceMapKeyValueTrait> {
   public:
    explicit DedupCodeSourceMapsVisitor(Zone* zone)
        : Dedupper(zone), code_source_map_(CodeSourceMap::Handle(zone)) {
      if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
        // Prefer existing objects in the VM isolate.
        AddVMBaseObjects();
      }
    }

    void VisitCode(const Code& code) {
      code_source_map_ = code.code_source_map();
      code_source_map_ = Dedup(code_source_map_);
      code.set_code_source_map(code_source_map_);
    }

   private:
    CodeSourceMap& code_source_map_;
  };

  DedupCodeSourceMapsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
}

class ArrayKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Array* Key;
  typedef const Array* Value;
  typedef const Array* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    ASSERT(!key->IsNull());
    return key->Length();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    ASSERT(!pair->IsNull() && !key->IsNull());
    if (pair->Length() != key->Length()) return false;
    for (intptr_t i = 0; i < pair->Length(); i++) {
      if (pair->At(i) != key->At(i)) return false;
    }
    return true;
  }
};

void ProgramVisitor::DedupLists(Zone* zone, Isolate* isolate) {
  class DedupListsVisitor : public CodeVisitor,
                            public Dedupper<Array, ArrayKeyValueTrait> {
   public:
    explicit DedupListsVisitor(Zone* zone)
        : Dedupper(zone),
          list_(Array::Handle(zone)),
          function_(Function::Handle(zone)) {}

    void VisitCode(const Code& code) {
      if (!code.IsFunctionCode()) return;

      list_ = code.inlined_id_to_function();
      list_ = Dedup(list_);
      code.set_inlined_id_to_function(list_);

      list_ = code.deopt_info_array();
      list_ = Dedup(list_);
      code.set_deopt_info_array(list_);

      list_ = code.static_calls_target_table();
      list_ = Dedup(list_);
      code.set_static_calls_target_table(list_);
    }

    void VisitFunction(const Function& function) {
      list_ = PrepareParameterTypes(function);
      list_ = Dedup(list_);
      function.set_parameter_types(list_);

      list_ = PrepareParameterNames(function);
      list_ = Dedup(list_);
      function.set_parameter_names(list_);
    }

   private:
    bool IsCorrectType(const Object& obj) const { return obj.IsArray(); }

    RawArray* PrepareParameterTypes(const Function& function) {
      list_ = function.parameter_types();
      // Preserve parameter types in the JIT. Needed in case of recompilation
      // in checked mode, or if available to mirrors, or for copied types to
      // lazily generated tear offs. Also avoid attempting to change read-only
      // VM objects for de-duplication.
      if (FLAG_precompiled_mode && !list_.IsNull() &&
          !list_.InVMIsolateHeap() && !function.IsSignatureFunction() &&
          !function.IsClosureFunction() && !function.IsFfiTrampoline() &&
          function.name() != Symbols::Call().raw()) {
        // Parameter types not needed for function type tests.
        for (intptr_t i = 0; i < list_.Length(); i++) {
          list_.SetAt(i, Object::dynamic_type());
        }
      }
      return list_.raw();
    }

    RawArray* PrepareParameterNames(const Function& function) {
      list_ = function.parameter_names();
      // Preserve parameter names in case of recompilation for the JIT. Also
      // avoid attempting to change read-only VM objects for de-duplication.
      if (FLAG_precompiled_mode && !list_.IsNull() &&
          !list_.InVMIsolateHeap() && !function.HasOptionalNamedParameters()) {
        // Parameter names not needed for resolution.
        ASSERT(list_.Length() == function.NumParameters());
        for (intptr_t i = 0; i < list_.Length(); i++) {
          list_.SetAt(i, Symbols::OptimizedOut());
        }
      }
      return list_.raw();
    }

    Array& list_;
    Function& function_;
  };

  DedupListsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
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
#endif

void ProgramVisitor::DedupInstructions(Zone* zone, Isolate* isolate) {
  class DedupInstructionsVisitor
      : public CodeVisitor,
        public Dedupper<Instructions, InstructionsKeyValueTrait>,
        public ObjectVisitor {
   public:
    explicit DedupInstructionsVisitor(Zone* zone)
        : Dedupper(zone),
          function_(Function::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {
      if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
        // Prefer existing objects in the VM isolate.
        Dart::vm_isolate()->heap()->VisitObjectsImagePages(this);
      }
    }

    void VisitObject(RawObject* obj) {
      if (!obj->IsInstructions()) return;
      instructions_ = Instructions::RawCast(obj);
      AddCanonical(instructions_);
    }

    void VisitCode(const Code& code) {
      instructions_ = code.instructions();
      instructions_ = Dedup(instructions_);
      code.SetActiveInstructions(instructions_,
                                 code.UncheckedEntryPointOffset());
      code.set_instructions(instructions_);
      if (!code.IsFunctionCode()) return;
      function_ = code.function();
      if (function_.IsNull()) return;
      function_.SetInstructions(code);  // Update cached entry point.
    }

   private:
    Function& function_;
    Instructions& instructions_;
  };

#if defined(DART_PRECOMPILER)
  class DedupInstructionsWithSameMetadataVisitor
      : public CodeVisitor,
        public Dedupper<Code, CodeKeyValueTrait>,
        public ObjectVisitor {
   public:
    explicit DedupInstructionsWithSameMetadataVisitor(Zone* zone)
        : Dedupper(zone),
          canonical_(Code::Handle(zone)),
          function_(Function::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {}

    void VisitObject(RawObject* obj) {
      if (!obj->IsCode()) return;
      canonical_ = Code::RawCast(obj);
      AddCanonical(canonical_);
    }

    void VisitCode(const Code& code) {
      if (code.IsDisabled()) return;
      canonical_ = Dedup(code);
      instructions_ = canonical_.instructions();
      code.SetActiveInstructions(instructions_,
                                 code.UncheckedEntryPointOffset());
      code.set_instructions(instructions_);
      if (!code.IsFunctionCode()) return;
      function_ = code.function();
      if (function_.IsNull()) return;
      function_.SetInstructions(code);  // Update cached entry point.
    }

   private:
    bool CanCanonicalize(const Code& code) const { return !code.IsDisabled(); }

    Code& canonical_;
    Function& function_;
    Instructions& instructions_;
  };

  if (FLAG_precompiled_mode && FLAG_use_bare_instructions) {
    DedupInstructionsWithSameMetadataVisitor visitor(zone);
    return WalkProgram(zone, isolate, &visitor);
  }
#endif  // defined(DART_PRECOMPILER)

  DedupInstructionsVisitor visitor(zone);
  WalkProgram(zone, isolate, &visitor);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void ProgramVisitor::Dedup(Thread* thread) {
#if !defined(DART_PRECOMPILED_RUNTIME)
  auto const isolate = thread->isolate();
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);
  auto const zone = thread->zone();

  BindStaticCalls(zone, isolate);
  ShareMegamorphicBuckets(zone, isolate);
  NormalizeAndDedupCompressedStackMaps(zone, isolate);
  DedupPcDescriptors(zone, isolate);
  NOT_IN_PRECOMPILED(DedupDeoptEntries(zone, isolate));
#if defined(DART_PRECOMPILER)
  DedupCatchEntryMovesMaps(zone, isolate);
  DedupUnlinkedCalls(zone, isolate);
#endif
  DedupCodeSourceMaps(zone, isolate);
  DedupLists(zone, isolate);

  // Reduces binary size but obfuscates profiler results.
  if (FLAG_dedup_instructions) {
    DedupInstructions(zone, isolate);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

}  // namespace dart
