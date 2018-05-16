// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/program_visitor.h"

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
      if (cls.IsDynamicClass()) {
        continue;  // class 'dynamic' is in the read-only VM isolate.
      }
      visitor->Visit(cls);
    }
    patches = lib.patch_classes();
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
    if (cls.IsDynamicClass()) {
      return;  // class 'dynamic' is in the read-only VM isolate.
    }

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
      if (field_.is_static() && field_.HasPrecompiledInitializer()) {
        function_ ^= field_.PrecompiledInitializer();
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
  MegamorphicCache::SetEntry(buckets, 0, MegamorphicCache::smi_illegal_cid(),
                             handler);

  for (intptr_t i = 0; i < table.Length(); i++) {
    cache ^= table.At(i);
    cache.set_buckets(buckets);
    cache.set_mask(capacity - 1);
    cache.set_filled_entry_count(0);
  }
}

class StackMapKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const StackMap* Key;
  typedef const StackMap* Value;
  typedef const StackMap* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->PcOffset(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

typedef DirectChainedHashMap<StackMapKeyValueTrait> StackMapSet;

void ProgramVisitor::DedupStackMaps() {
  class DedupStackMapsVisitor : public FunctionVisitor {
   public:
    explicit DedupStackMapsVisitor(Zone* zone)
        : zone_(zone),
          canonical_stackmaps_(),
          code_(Code::Handle(zone)),
          stackmaps_(Array::Handle(zone)),
          stackmap_(StackMap::Handle(zone)) {}

    void AddStackMap(const StackMap& stackmap) {
      canonical_stackmaps_.Insert(&StackMap::ZoneHandle(zone_, stackmap.raw()));
    }

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      stackmaps_ = code_.stackmaps();
      if (stackmaps_.IsNull()) return;
      for (intptr_t i = 0; i < stackmaps_.Length(); i++) {
        stackmap_ ^= stackmaps_.At(i);
        stackmap_ = DedupStackMap(stackmap_);
        stackmaps_.SetAt(i, stackmap_);
      }
    }

    RawStackMap* DedupStackMap(const StackMap& stackmap) {
      const StackMap* canonical_stackmap =
          canonical_stackmaps_.LookupValue(&stackmap);
      if (canonical_stackmap == NULL) {
        AddStackMap(stackmap);
        return stackmap.raw();
      } else {
        return canonical_stackmap->raw();
      }
    }

   private:
    Zone* zone_;
    StackMapSet canonical_stackmaps_;
    Code& code_;
    Array& stackmaps_;
    StackMap& stackmap_;
  };

  DedupStackMapsVisitor visitor(Thread::Current()->zone());
  if (Snapshot::IncludesCode(Dart::vm_snapshot_kind())) {
    // Prefer existing objects in the VM isolate.
    const Array& object_table = Object::vm_isolate_snapshot_object_table();
    Object& object = Object::Handle();
    for (intptr_t i = 0; i < object_table.Length(); i++) {
      object = object_table.At(i);
      if (object.IsStackMap()) {
        visitor.AddStackMap(StackMap::Cast(object));
      }
    }
  }
  ProgramVisitor::VisitFunctions(&visitor);
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
          code_(Code::Handle(zone)),
          pc_descriptor_(PcDescriptors::Handle(zone)) {}

    void AddPcDescriptor(const PcDescriptors& pc_descriptor) {
      canonical_pc_descriptors_.Insert(
          &PcDescriptors::ZoneHandle(zone_, pc_descriptor.raw()));
    }

    void Visit(const Function& function) {
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

#if !defined(DART_PRECOMPILED_RUNTIME)
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

#if defined(DART_PRECOMPILER)
void ProgramVisitor::DedupCatchEntryStateMaps() {
  if (!FLAG_precompiled_mode) {
    return;
  }
  class DedupCatchEntryStateMapsVisitor : public FunctionVisitor {
   public:
    explicit DedupCatchEntryStateMapsVisitor(Zone* zone)
        : zone_(zone),
          canonical_catch_entry_state_maps_(),
          code_(Code::Handle(zone)),
          catch_entry_state_maps_(TypedData::Handle(zone)) {}

    void Visit(const Function& function) {
      if (!function.HasCode()) {
        return;
      }
      code_ = function.CurrentCode();
      catch_entry_state_maps_ = code_.catch_entry_state_maps();
      catch_entry_state_maps_ =
          DedupCatchEntryStateMaps(catch_entry_state_maps_);
      code_.set_catch_entry_state_maps(catch_entry_state_maps_);
    }

    RawTypedData* DedupCatchEntryStateMaps(
        const TypedData& catch_entry_state_maps) {
      const TypedData* canonical_catch_entry_state_maps =
          canonical_catch_entry_state_maps_.LookupValue(
              &catch_entry_state_maps);
      if (canonical_catch_entry_state_maps == NULL) {
        canonical_catch_entry_state_maps_.Insert(
            &TypedData::ZoneHandle(zone_, catch_entry_state_maps.raw()));
        return catch_entry_state_maps.raw();
      } else {
        return canonical_catch_entry_state_maps->raw();
      }
    }

   private:
    Zone* zone_;
    TypedDataSet canonical_catch_entry_state_maps_;
    Code& code_;
    TypedData& catch_entry_state_maps_;
  };

  DedupCatchEntryStateMapsVisitor visitor(Thread::Current()->zone());
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
        list_ = code_.stackmaps();
        if (!list_.IsNull()) {
          list_ = DedupList(list_);
          code_.set_stackmaps(list_);
        }
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
#ifndef PRODUCT
        list_ = code_.await_token_positions();
        if (!list_.IsNull()) {
          list_ = DedupList(list_);
          code_.set_await_token_positions(list_);
        }
#endif  // !PRODUCT
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
              (function.name() != Symbols::Call().raw()) && !list_.InVMHeap()) {
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
          if (!function.HasOptionalNamedParameters() && !list_.InVMHeap()) {
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
      if (list.InVMHeap()) {
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
      code_.SetActiveInstructions(instructions_);
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

void ProgramVisitor::Dedup() {
  Thread* thread = Thread::Current();
  StackZone stack_zone(thread);
  HANDLESCOPE(thread);

  // TODO(rmacnak): Bind static calls whose target has been compiled. Forward
  // references to disabled code.
  ShareMegamorphicBuckets();
  DedupStackMaps();
  DedupPcDescriptors();
  NOT_IN_PRECOMPILED(DedupDeoptEntries());
#if defined(DART_PRECOMPILER)
  DedupCatchEntryStateMaps();
#endif
  DedupCodeSourceMaps();
  DedupLists();

#if defined(PRODUCT)
  // Reduces binary size but obfuscates profiler results.
  DedupInstructions();
#endif
}

}  // namespace dart
