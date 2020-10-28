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

class WorklistElement : public ZoneAllocated {
 public:
  WorklistElement(Zone* zone, const Object& object)
      : object_(Object::Handle(zone, object.raw())), next_(nullptr) {}

  ObjectPtr value() const { return object_.raw(); }

  void set_next(WorklistElement* elem) { next_ = elem; }
  WorklistElement* next() const { return next_; }

 private:
  const Object& object_;
  WorklistElement* next_;

  DISALLOW_COPY_AND_ASSIGN(WorklistElement);
};

// Implements a FIFO queue, using IsEmpty, Add, Remove operations.
class Worklist : public ValueObject {
 public:
  explicit Worklist(Zone* zone)
      : zone_(zone), first_(nullptr), last_(nullptr) {}

  bool IsEmpty() const { return first_ == nullptr; }

  void Add(const Object& value) {
    auto element = new (zone_) WorklistElement(zone_, value);
    if (first_ == nullptr) {
      first_ = element;
      ASSERT(last_ == nullptr);
    } else {
      ASSERT(last_ != nullptr);
      last_->set_next(element);
    }
    last_ = element;
    ASSERT(first_ != nullptr && last_ != nullptr);
  }

  ObjectPtr Remove() {
    ASSERT(first_ != nullptr);
    WorklistElement* result = first_;
    first_ = first_->next();
    if (first_ == nullptr) {
      last_ = nullptr;
    }
    return result->value();
  }

 private:
  Zone* const zone_;
  WorklistElement* first_;
  WorklistElement* last_;

  DISALLOW_COPY_AND_ASSIGN(Worklist);
};

// Walks through the classes, functions, and code for the current program.
//
// Uses the heap object ID table to determine whether or not a given object
// has been visited already.
class ProgramWalker : public ValueObject {
 public:
  ProgramWalker(Zone* zone, Heap* heap, ClassVisitor* visitor)
      : heap_(heap),
        visitor_(visitor),
        worklist_(zone),
        class_object_(Object::Handle(zone)),
        class_fields_(Array::Handle(zone)),
        class_field_(Field::Handle(zone)),
        class_functions_(Array::Handle(zone)),
        class_function_(Function::Handle(zone)),
        class_code_(Code::Handle(zone)),
        function_code_(Code::Handle(zone)),
        static_calls_array_(Array::Handle(zone)),
        static_calls_table_entry_(Object::Handle(zone)),
        worklist_entry_(Object::Handle(zone)) {}

  ~ProgramWalker() { heap_->ResetObjectIdTable(); }

  // Adds the given object to the worklist if it's an object type that the
  // visitor can visit.
  void AddToWorklist(const Object& object) {
    // We don't visit null, non-heap objects, or objects in the VM heap.
    if (object.IsNull() || object.IsSmi() || object.InVMIsolateHeap()) return;
    // Check and set visited, even if we don't end up adding this to the list.
    if (heap_->GetObjectId(object.raw()) != 0) return;
    heap_->SetObjectId(object.raw(), 1);
    if (object.IsClass() ||
        (object.IsFunction() && visitor_->IsFunctionVisitor()) ||
        (object.IsCode() && visitor_->IsCodeVisitor())) {
      worklist_.Add(object);
    }
  }

  void VisitWorklist() {
    while (!worklist_.IsEmpty()) {
      worklist_entry_ = worklist_.Remove();
      if (worklist_entry_.IsClass()) {
        VisitClass(Class::Cast(worklist_entry_));
      } else if (worklist_entry_.IsFunction()) {
        VisitFunction(Function::Cast(worklist_entry_));
      } else if (worklist_entry_.IsCode()) {
        VisitCode(Code::Cast(worklist_entry_));
      } else {
        FATAL1("Got unexpected object %s", worklist_entry_.ToCString());
      }
    }
  }

 private:
  void VisitClass(const Class& cls) {
    visitor_->VisitClass(cls);

    if (!visitor_->IsFunctionVisitor()) return;

    class_functions_ = cls.current_functions();
    for (intptr_t j = 0; j < class_functions_.Length(); j++) {
      class_function_ ^= class_functions_.At(j);
      AddToWorklist(class_function_);
      if (class_function_.HasImplicitClosureFunction()) {
        class_function_ = class_function_.ImplicitClosureFunction();
        AddToWorklist(class_function_);
      }
    }

    class_functions_ = cls.invocation_dispatcher_cache();
    for (intptr_t j = 0; j < class_functions_.Length(); j++) {
      class_object_ = class_functions_.At(j);
      if (class_object_.IsFunction()) {
        class_function_ ^= class_functions_.At(j);
        AddToWorklist(class_function_);
      }
    }

    class_fields_ = cls.fields();
    for (intptr_t j = 0; j < class_fields_.Length(); j++) {
      class_field_ ^= class_fields_.At(j);
      if (class_field_.HasInitializerFunction()) {
        class_function_ = class_field_.InitializerFunction();
        AddToWorklist(class_function_);
      }
    }

    if (!visitor_->IsCodeVisitor()) return;

    class_code_ = cls.allocation_stub();
    if (!class_code_.IsNull()) AddToWorklist(class_code_);
  }

  void VisitFunction(const Function& function) {
    ASSERT(visitor_->IsFunctionVisitor());
    visitor_->AsFunctionVisitor()->VisitFunction(function);
    if (!visitor_->IsCodeVisitor() || !function.HasCode()) return;
    function_code_ = function.CurrentCode();
    AddToWorklist(function_code_);
  }

  void VisitCode(const Code& code) {
    ASSERT(visitor_->IsCodeVisitor());
    visitor_->AsCodeVisitor()->VisitCode(code);

    // In the precompiler, some entries in the static calls table may need
    // to be visited as they may not be reachable from other sources.
    //
    // TODO(dartbug.com/41636): Figure out why walking the static calls table
    // in JIT mode with the DedupInstructions visitor fails, so we can remove
    // the check for AOT mode.
    static_calls_array_ = code.static_calls_target_table();
    if (FLAG_precompiled_mode && !static_calls_array_.IsNull()) {
      StaticCallsTable static_calls(static_calls_array_);
      for (auto& view : static_calls) {
        static_calls_table_entry_ =
            view.Get<Code::kSCallTableCodeOrTypeTarget>();
        if (static_calls_table_entry_.IsCode()) {
          AddToWorklist(Code::Cast(static_calls_table_entry_));
        }
      }
    }
  }

  Heap* const heap_;
  ClassVisitor* const visitor_;
  Worklist worklist_;
  Object& class_object_;
  Array& class_fields_;
  Field& class_field_;
  Array& class_functions_;
  Function& class_function_;
  Code& class_code_;
  Code& function_code_;
  Array& static_calls_array_;
  Object& static_calls_table_entry_;
  Object& worklist_entry_;
};

void ProgramVisitor::WalkProgram(Zone* zone,
                                 Isolate* isolate,
                                 ClassVisitor* visitor) {
  auto const object_store = isolate->object_store();
  auto const heap = isolate->heap();
  ProgramWalker walker(zone, heap, visitor);

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
      walker.AddToWorklist(cls);
    }
    patches = lib.used_scripts();
    for (intptr_t j = 0; j < patches.Length(); j++) {
      entry = patches.At(j);
      walker.AddToWorklist(entry);
    }
  }

  // If there's a global object pool, add any visitable objects.
  const auto& global_object_pool =
      ObjectPool::Handle(zone, object_store->global_object_pool());
  if (!global_object_pool.IsNull()) {
    auto& object = Object::Handle(zone);
    for (intptr_t i = 0; i < global_object_pool.Length(); i++) {
      auto const type = global_object_pool.TypeAt(i);
      if (type != ObjectPool::EntryType::kTaggedObject) continue;
      object = global_object_pool.ObjectAt(i);
      walker.AddToWorklist(object);
    }
  }

  if (visitor->IsFunctionVisitor()) {
    // Function objects not necessarily reachable from classes.
    auto& function = Function::Handle(zone);
    const auto& closures =
        GrowableObjectArray::Handle(zone, object_store->closure_functions());
    ASSERT(!closures.IsNull());
    for (intptr_t i = 0; i < closures.Length(); i++) {
      function ^= closures.At(i);
      walker.AddToWorklist(function);
      ASSERT(!function.HasImplicitClosureFunction());
    }
    // TODO(dartbug.com/43049): Use a more general solution and remove manual
    // tracking through object_store->ffi_callback_functions.
    const auto& ffi_callback_entries = GrowableObjectArray::Handle(
        zone, object_store->ffi_callback_functions());
    if (!ffi_callback_entries.IsNull()) {
      for (intptr_t i = 0; i < ffi_callback_entries.Length(); i++) {
        function ^= ffi_callback_entries.At(i);
        walker.AddToWorklist(function);
      }
    }
  }

  if (visitor->IsCodeVisitor()) {
    // Code objects not necessarily reachable from functions.
    auto& code = Code::Handle(zone);
    const auto& dispatch_table_entries =
        Array::Handle(zone, object_store->dispatch_table_code_entries());
    if (!dispatch_table_entries.IsNull()) {
      for (intptr_t i = 0; i < dispatch_table_entries.Length(); i++) {
        code ^= dispatch_table_entries.At(i);
        walker.AddToWorklist(code);
      }
    }
  }

  // Walk the program starting from any roots we added to the worklist.
  walker.VisitWorklist();
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

  typename T::ObjectPtrType Dedup(const T& obj) {
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
          ASSERT(kind == Code::kPcRelativeCall ||
                 kind == Code::kPcRelativeTailCall ||
                 kind == Code::kPcRelativeTTSCall);
          only_call_via_code = false;
          continue;
        }

        target_ = view.Get<Code::kSCallTableFunctionTarget>();
        if (target_.IsNull()) {
          target_ =
              Code::RawCast(view.Get<Code::kSCallTableCodeOrTypeTarget>());
          ASSERT(!target_.IsNull());  // Already bound.
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
        // all targets have been compiled, and so the binder replaces all static
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
        // Note: it is okay to drop the table fully even when generating
        // V8 snapshot profile because code objects are linked through the
        // pool.
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

DECLARE_FLAG(charp, trace_precompiler_to);
DECLARE_FLAG(charp, write_v8_snapshot_profile_to);

void ProgramVisitor::ShareMegamorphicBuckets(Zone* zone, Isolate* isolate) {
  const GrowableObjectArray& table = GrowableObjectArray::Handle(
      zone, isolate->object_store()->megamorphic_cache_table());
  if (table.IsNull()) return;
  MegamorphicCache& cache = MegamorphicCache::Handle(zone);

  const intptr_t capacity = 1;
  const Array& buckets = Array::Handle(
      zone, Array::New(MegamorphicCache::kEntryLength * capacity, Heap::kOld));
  const Function& handler = Function::Handle(zone);
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
  StackMapEntry(Zone* zone, const CompressedStackMaps::Iterator& it)
      : maps_(CompressedStackMaps::Handle(zone, it.maps_.raw())),
        bits_container_(
            CompressedStackMaps::Handle(zone, it.bits_container_.raw())),
        // If the map uses the global table, this accessor call ensures the
        // entry is fully loaded before we retrieve [it.current_bits_offset_].
        spill_slot_bit_count_(it.SpillSlotBitCount()),
        non_spill_slot_bit_count_(it.Length() - it.SpillSlotBitCount()),
        bits_offset_(it.current_bits_offset_) {
    ASSERT(!maps_.IsNull() && !maps_.IsGlobalTable());
    ASSERT(!bits_container_.IsNull());
    ASSERT(!maps_.UsesGlobalTable() || bits_container_.IsGlobalTable());
    ASSERT(it.current_spill_slot_bit_count_ >= 0);
  }

  static const intptr_t kHashBits = 30;

  intptr_t Hashcode() {
    if (hash_ != 0) return hash_;
    uint32_t hash = 0;
    hash = CombineHashes(hash, spill_slot_bit_count_);
    hash = CombineHashes(hash, non_spill_slot_bit_count_);
    {
      NoSafepointScope scope;
      auto const start = PayloadData();
      auto const end = start + PayloadLength();
      for (auto cursor = start; cursor < end; cursor++) {
        hash = CombineHashes(hash, *cursor);
      }
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
    NoSafepointScope scope;
    return memcmp(PayloadData(), other->PayloadData(), PayloadLength()) == 0;
  }

  // Encodes this StackMapEntry to the given array of bytes and returns the
  // initial offset of the entry in the array.
  intptr_t EncodeTo(NonStreamingWriteStream* stream) {
    auto const current_offset = stream->Position();
    stream->WriteLEB128(spill_slot_bit_count_);
    stream->WriteLEB128(non_spill_slot_bit_count_);
    {
      NoSafepointScope scope;
      stream->WriteBytes(PayloadData(), PayloadLength());
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
  const uint8_t* PayloadData() const {
    ASSERT(!Thread::Current()->IsAtSafepoint());
    return bits_container_.raw()->ptr()->data() + bits_offset_;
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
      CompressedStackMaps::Iterator it(compressed_stackmaps_,
                                       old_global_table_);
      while (it.MoveNext()) {
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
    CompressedStackMapsPtr CreateGlobalTable(
        StackMapEntryIntMap* entry_offsets) {
      ASSERT(entry_offsets->IsEmpty());
      if (collected_entries_.length() == 0) {
        return CompressedStackMaps::null();
      }
      // First, sort the entries from most used to least used. This way,
      // the most often used CSMs will have the lowest offsets, which means
      // they will be smaller when LEB128 encoded.
      collected_entries_.Sort(
          [](StackMapEntry* const* e1, StackMapEntry* const* e2) {
            return static_cast<int>((*e2)->UsageCount() - (*e1)->UsageCount());
          });
      MallocWriteStream stream(128);
      // Encode the entries and record their offset in the payload. Sorting the
      // entries may have changed their indices, so update those as well.
      for (intptr_t i = 0, n = collected_entries_.length(); i < n; i++) {
        auto const entry = collected_entries_.At(i);
        entry_indices_.Update({entry, i});
        entry_offsets->Insert({entry, entry->EncodeTo(&stream)});
      }
      const auto& data = CompressedStackMaps::Handle(
          zone_, CompressedStackMaps::NewGlobalTable(stream.buffer(),
                                                     stream.bytes_written()));
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
    CompressedStackMapsPtr NormalizeEntries(const CompressedStackMaps& maps) {
      if (maps.payload_size() == 0) {
        // No entries, so use the canonical empty map.
        return Object::empty_compressed_stackmaps().raw();
      }
      MallocWriteStream new_payload(maps.payload_size());
      CompressedStackMaps::Iterator it(maps, old_global_table_);
      intptr_t last_offset = 0;
      while (it.MoveNext()) {
        StackMapEntry entry(zone_, it);
        const intptr_t entry_offset = entry_offsets_.LookupValue(&entry);
        const intptr_t pc_delta = it.pc_offset() - last_offset;
        new_payload.WriteLEB128(pc_delta);
        new_payload.WriteLEB128(entry_offset);
        last_offset = it.pc_offset();
      }
      return CompressedStackMaps::NewUsingTable(new_payload.buffer(),
                                                new_payload.bytes_written());
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

   private:
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

  if (FLAG_precompiled_mode) return;
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
      FLAG_write_v8_snapshot_profile_to != nullptr ||
      FLAG_trace_precompiler_to != nullptr) {
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

    ArrayPtr PrepareParameterTypes(const Function& function) {
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

    ArrayPtr PrepareParameterNames(const Function& function) {
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

  static inline intptr_t Hashcode(Key key) { return key->Hash(); }

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
          code_(Code::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {
      if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
        // Prefer existing objects in the VM isolate.
        Dart::vm_isolate()->heap()->VisitObjectsImagePages(this);
      }
    }

    void VisitObject(ObjectPtr obj) {
      if (!obj->IsInstructions()) return;
      instructions_ = Instructions::RawCast(obj);
      AddCanonical(instructions_);
    }

    void VisitFunction(const Function& function) {
      if (!function.HasCode()) return;
      code_ = function.CurrentCode();
      // This causes the code to be visited once here and once directly in the
      // ProgramWalker, but as long as the deduplication process is idempotent,
      // the cached entry points won't change during the second visit.
      VisitCode(code_);
      function.SetInstructions(code_);  // Update cached entry point.
    }

    void VisitCode(const Code& code) {
      instructions_ = code.instructions();
      instructions_ = Dedup(instructions_);
      code.set_instructions(instructions_);
      if (code.IsDisabled()) {
        instructions_ = code.active_instructions();
        instructions_ = Dedup(instructions_);
      }
      code.SetActiveInstructions(instructions_,
                                 code.UncheckedEntryPointOffset());
    }

   private:
    Code& code_;
    Instructions& instructions_;
  };

#if defined(DART_PRECOMPILER)
  class DedupInstructionsWithSameMetadataVisitor
      : public CodeVisitor,
        public Dedupper<Code, CodeKeyValueTrait> {
   public:
    explicit DedupInstructionsWithSameMetadataVisitor(Zone* zone)
        : Dedupper(zone),
          canonical_(Code::Handle(zone)),
          code_(Code::Handle(zone)),
          instructions_(Instructions::Handle(zone)) {}

    void VisitFunction(const Function& function) {
      if (!function.HasCode()) return;
      code_ = function.CurrentCode();
      // This causes the code to be visited once here and once directly in the
      // ProgramWalker, but as long as the deduplication process is idempotent,
      // the cached entry points won't change during the second visit.
      VisitCode(code_);
      function.SetInstructions(code_);  // Update cached entry point.
    }

    void VisitCode(const Code& code) {
      if (code.IsDisabled()) return;
      canonical_ = Dedup(code);
      instructions_ = canonical_.instructions();
      code.SetActiveInstructions(instructions_,
                                 code.UncheckedEntryPointOffset());
      code.set_instructions(instructions_);
    }

   private:
    bool CanCanonicalize(const Code& code) const { return !code.IsDisabled(); }

    Code& canonical_;
    Code& code_;
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
  DedupDeoptEntries(zone, isolate);
#if defined(DART_PRECOMPILER)
  DedupCatchEntryMovesMaps(zone, isolate);
  DedupUnlinkedCalls(zone, isolate);
#endif
  DedupCodeSourceMaps(zone, isolate);
  DedupLists(zone, isolate);

  // Reduces binary size but obfuscates profiler results.
  if (FLAG_dedup_instructions) {
    // In non-bare mode (unused atm) dedupping instructions would cause us to
    // loose the ability to uniquely map a PC to a given UnlinkedCall object,
    // since two code objects might point to the same deduped instructions
    // object but might have two different UnlinkedCall objects in their pool.
    //
    // In bare mode this cannot happen because different UnlinkedCall objects
    // would get different indices into the (global) object pool, therefore
    // making the instructions different.
    //
    // (When transitioning the switchable call site we loose track of the args
    // descriptor. Since we need it for further transitions we currently save it
    // via a PC -> UnlinkedCall mapping).
    //
    // We therfore disable the instruction deduplication in product-non-bare
    // mode (which is unused atm).
#if defined(PRODUCT)
    if (FLAG_precompiled_mode && !FLAG_use_bare_instructions) return;
#endif

    DedupInstructions(zone, isolate);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
}

#if defined(DART_PRECOMPILER)
class AssignLoadingUnitsCodeVisitor : public CodeVisitor {
 public:
  explicit AssignLoadingUnitsCodeVisitor(Zone* zone)
      : heap_(Thread::Current()->heap()),
        func_(Function::Handle(zone)),
        cls_(Class::Handle(zone)),
        lib_(Library::Handle(zone)),
        unit_(LoadingUnit::Handle(zone)),
        obj_(Object::Handle(zone)) {}

  void VisitCode(const Code& code) {
    intptr_t id;
    if (code.IsFunctionCode()) {
      func_ ^= code.function();
      cls_ = func_.Owner();
      lib_ = cls_.library();
      unit_ = lib_.loading_unit();
      id = unit_.id();
    } else if (code.IsAllocationStubCode()) {
      cls_ ^= code.owner();
      lib_ = cls_.library();
      unit_ = lib_.loading_unit();
      id = unit_.id();
    } else if (code.IsStubCode()) {
      id = LoadingUnit::kRootId;
    } else {
      UNREACHABLE();
    }

    ASSERT(heap_->GetLoadingUnit(code.raw()) == WeakTable::kNoValue);
    heap_->SetLoadingUnit(code.raw(), id);

    obj_ = code.code_source_map();
    MergeAssignment(obj_, id);
    obj_ = code.compressed_stackmaps();
    MergeAssignment(obj_, id);
  }

  void MergeAssignment(const Object& obj, intptr_t id) {
    intptr_t old_id = heap_->GetLoadingUnit(obj_.raw());
    if (old_id == WeakTable::kNoValue) {
      heap_->SetLoadingUnit(obj_.raw(), id);
    } else if (old_id == id) {
      // Shared with another code in the same loading unit.
    } else {
      // Shared with another code in a different loading unit.
      // Could assign to dominating loading unit.
      heap_->SetLoadingUnit(obj_.raw(), LoadingUnit::kRootId);
    }
  }

 private:
  Heap* heap_;
  Function& func_;
  Class& cls_;
  Library& lib_;
  LoadingUnit& unit_;
  Object& obj_;
};

void ProgramVisitor::AssignUnits(Thread* thread) {
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);
  Zone* zone = thread->zone();

  // VM stubs.
  Instructions& inst = Instructions::Handle(zone);
  Code& code = Code::Handle(zone);
  for (intptr_t i = 0; i < StubCode::NumEntries(); i++) {
    inst = StubCode::EntryAt(i).instructions();
    thread->heap()->SetLoadingUnit(inst.raw(), LoadingUnit::kRootId);
  }

  // Isolate stubs.
  ObjectStore* object_store = thread->isolate()->object_store();
  ObjectPtr* from = object_store->from();
  ObjectPtr* to = object_store->to_snapshot(Snapshot::kFullAOT);
  for (ObjectPtr* p = from; p <= to; p++) {
    if ((*p)->IsCode()) {
      code ^= *p;
      inst = code.instructions();
      thread->heap()->SetLoadingUnit(inst.raw(), LoadingUnit::kRootId);
    }
  }

  // Function code / allocation stubs.
  AssignLoadingUnitsCodeVisitor visitor(zone);
  WalkProgram(zone, thread->isolate(), &visitor);
}

class ProgramHashVisitor : public CodeVisitor {
 public:
  explicit ProgramHashVisitor(Zone* zone)
      : str_(String::Handle(zone)),
        pool_(ObjectPool::Handle(zone)),
        obj_(Object::Handle(zone)),
        instr_(Instructions::Handle(zone)),
        hash_(0) {}

  void VisitClass(const Class& cls) {
    str_ = cls.Name();
    VisitInstance(str_);
  }

  void VisitFunction(const Function& function) {
    str_ = function.name();
    VisitInstance(str_);
  }

  void VisitCode(const Code& code) {
    pool_ = code.object_pool();
    VisitPool(pool_);

    instr_ = code.instructions();
    hash_ = CombineHashes(hash_, instr_.Hash());
  }

  void VisitPool(const ObjectPool& pool) {
    if (pool.IsNull()) return;

    for (intptr_t i = 0; i < pool.Length(); i++) {
      if (pool.TypeAt(i) == ObjectPool::EntryType::kTaggedObject) {
        obj_ = pool.ObjectAt(i);
        if (obj_.IsInstance()) {
          VisitInstance(Instance::Cast(obj_));
        }
      }
    }
  }

  void VisitInstance(const Instance& instance) {
    hash_ = CombineHashes(hash_, instance.CanonicalizeHash());
  }

  uint32_t hash() const { return FinalizeHash(hash_, String::kHashBits); }

 private:
  String& str_;
  ObjectPool& pool_;
  Object& obj_;
  Instructions& instr_;
  uint32_t hash_;
};

uint32_t ProgramVisitor::Hash(Thread* thread) {
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);
  Zone* zone = thread->zone();

  ProgramHashVisitor visitor(zone);
  WalkProgram(zone, thread->isolate(), &visitor);
  visitor.VisitPool(ObjectPool::Handle(
      zone, thread->isolate()->object_store()->global_object_pool()));
  return visitor.hash();
}

#endif  // defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
