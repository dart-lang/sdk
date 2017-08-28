// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PRECOMPILER_H_
#define RUNTIME_VM_PRECOMPILER_H_

#include "vm/allocation.h"
#include "vm/hash_map.h"
#include "vm/hash_table.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class Class;
class Error;
class Field;
class Function;
class GrowableObjectArray;
class RawError;
class SequenceNode;
class String;
class ParsedJSONObject;
class ParsedJSONArray;
class Precompiler;
class FlowGraph;

class TypeRangeCache : public ValueObject {
 public:
  TypeRangeCache(Precompiler* precompiler, Thread* thread, intptr_t num_cids);
  ~TypeRangeCache();

  bool InstanceOfHasClassRange(const AbstractType& type,
                               intptr_t* lower_limit,
                               intptr_t* upper_limit);

 private:
  static const intptr_t kNotComputed = -1;
  static const intptr_t kNotContiguous = -2;

  Precompiler* precompiler_;
  Thread* thread_;
  intptr_t* lower_limits_;
  intptr_t* upper_limits_;
};

class SymbolKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const String* Key;
  typedef const String* Value;
  typedef const String* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Hash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<SymbolKeyValueTrait> SymbolSet;

class UnlinkedCallKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const UnlinkedCall* Key;
  typedef const UnlinkedCall* Value;
  typedef const UnlinkedCall* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    return String::Handle(key->target_name()).Hash();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return (pair->target_name() == key->target_name()) &&
           (pair->args_descriptor() == key->args_descriptor());
  }
};

typedef DirectChainedHashMap<UnlinkedCallKeyValueTrait> UnlinkedCallSet;

static inline intptr_t SimplePointerHash(void* ptr) {
  return reinterpret_cast<intptr_t>(ptr) * 2654435761UL;
}

class FunctionKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Function* Key;
  typedef const Function* Value;
  typedef const Function* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    // We are using pointer hash for objects originating from Kernel because
    // Fasta currently does not assign any position information to them.
    if (key->kernel_offset() > 0) {
      return key->kernel_offset();
    } else {
      return key->token_pos().value();
    }
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<FunctionKeyValueTrait> FunctionSet;

class FieldKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Field* Key;
  typedef const Field* Value;
  typedef const Field* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    // We are using pointer hash for objects originating from Kernel because
    // Fasta currently does not assign any position information to them.
    if (key->kernel_offset() > 0) {
      return key->kernel_offset();
    } else {
      return key->token_pos().value();
    }
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<FieldKeyValueTrait> FieldSet;

class ClassKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Class* Key;
  typedef const Class* Value;
  typedef const Class* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->token_pos().value(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<ClassKeyValueTrait> ClassSet;

class AbstractTypeKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const AbstractType* Key;
  typedef const AbstractType* Value;
  typedef const AbstractType* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Hash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<AbstractTypeKeyValueTrait> AbstractTypeSet;

class TypeArgumentsKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const TypeArguments* Key;
  typedef const TypeArguments* Value;
  typedef const TypeArguments* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->Hash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<TypeArgumentsKeyValueTrait> TypeArgumentsSet;

class InstanceKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Instance* Key;
  typedef const Instance* Value;
  typedef const Instance* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->GetClassId(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<InstanceKeyValueTrait> InstanceSet;

struct FieldTypePair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Field* Key;
  typedef intptr_t Value;
  typedef FieldTypePair Pair;

  static Key KeyOf(Pair kv) { return kv.field_; }

  static Value ValueOf(Pair kv) { return kv.cid_; }

  static inline intptr_t Hashcode(Key key) { return key->token_pos().value(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.field_->raw() == key->raw();
  }

  FieldTypePair(const Field* f, intptr_t cid) : field_(f), cid_(cid) {}

  FieldTypePair() : field_(NULL), cid_(-1) {}

  void Print() const;

  const Field* field_;
  intptr_t cid_;
};

typedef DirectChainedHashMap<FieldTypePair> FieldTypeMap;

struct IntptrPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef intptr_t Key;
  typedef intptr_t Value;
  typedef IntptrPair Pair;

  static Key KeyOf(Pair kv) { return kv.key_; }

  static Value ValueOf(Pair kv) { return kv.value_; }

  static inline intptr_t Hashcode(Key key) { return key; }

  static inline bool IsKeyEqual(Pair pair, Key key) { return pair.key_ == key; }

  IntptrPair(intptr_t key, intptr_t value) : key_(key), value_(value) {}

  IntptrPair() : key_(kIllegalCid), value_(kIllegalCid) {}

  Key key_;
  Value value_;
};

typedef DirectChainedHashMap<IntptrPair> CidMap;

struct FunctionFeedbackKey {
  FunctionFeedbackKey() : owner_cid_(kIllegalCid), token_(0), kind_(0) {}
  FunctionFeedbackKey(intptr_t owner_cid, intptr_t token, intptr_t kind)
      : owner_cid_(owner_cid), token_(token), kind_(kind) {}

  intptr_t owner_cid_;
  intptr_t token_;
  intptr_t kind_;
};

struct FunctionFeedbackPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef FunctionFeedbackKey Key;
  typedef ParsedJSONObject* Value;
  typedef FunctionFeedbackPair Pair;

  static Key KeyOf(Pair kv) { return kv.key_; }

  static Value ValueOf(Pair kv) { return kv.value_; }

  static inline intptr_t Hashcode(Key key) {
    return key.token_ ^ key.owner_cid_ ^ key.kind_;
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return (pair.key_.owner_cid_ == key.owner_cid_) &&
           (pair.key_.token_ == key.token_) && (pair.key_.kind_ == key.kind_);
  }

  FunctionFeedbackPair(Key key, Value value) : key_(key), value_(value) {}

  FunctionFeedbackPair() : key_(), value_(NULL) {}

  Key key_;
  Value value_;
};

typedef DirectChainedHashMap<FunctionFeedbackPair> FunctionFeedbackMap;

class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll(
      Dart_QualifiedFunctionName embedder_entry_points[],
      uint8_t* jit_feedback,
      intptr_t jit_feedback_length);

  static RawError* CompileFunction(Precompiler* precompiler,
                                   Thread* thread,
                                   Zone* zone,
                                   const Function& function,
                                   FieldTypeMap* field_type_map = NULL);

  static RawObject* EvaluateStaticInitializer(const Field& field);
  static RawObject* ExecuteOnce(SequenceNode* fragment);

  static RawFunction* CompileStaticInitializer(const Field& field,
                                               bool compute_type);

  // Returns true if get:runtimeType is not overloaded by any class.
  bool get_runtime_type_is_unique() const {
    return get_runtime_type_is_unique_;
  }

  FieldTypeMap* field_type_map() { return &field_type_map_; }
  TypeRangeCache* type_range_cache() { return type_range_cache_; }
  void set_type_range_cache(TypeRangeCache* value) {
    type_range_cache_ = value;
  }

  bool HasFeedback() const { return jit_feedback_ != NULL; }
  static void PopulateWithICData(const Function& func, FlowGraph* graph);
  void TryApplyFeedback(const Function& func, FlowGraph* graph);
  void TryApplyFeedback(ParsedJSONArray* js_icdatas, const ICData& ic);

 private:
  explicit Precompiler(Thread* thread);

  void LoadFeedback(uint8_t* jit_feedback, intptr_t jit_feedback_length);
  ParsedJSONObject* LookupFeedback(const Function& function);

  void DoCompileAll(Dart_QualifiedFunctionName embedder_entry_points[]);
  void AddRoots(Dart_QualifiedFunctionName embedder_entry_points[]);
  void AddEntryPoints(Dart_QualifiedFunctionName entry_points[]);
  void Iterate();

  void AddType(const AbstractType& type);
  void AddTypesOf(const Class& cls);
  void AddTypesOf(const Function& function);
  void AddTypeArguments(const TypeArguments& args);
  void AddCalleesOf(const Function& function);
  void AddConstObject(const Instance& instance);
  void AddClosureCall(const Array& arguments_descriptor);
  void AddField(const Field& field);
  void AddFunction(const Function& function);
  void AddInstantiatedClass(const Class& cls);
  void AddSelector(const String& selector);
  bool IsSent(const String& selector);

  void ProcessFunction(const Function& function);
  void CheckForNewDynamicFunctions();
  void TraceConstFunctions();
  void CollectCallbackFields();

  void TraceForRetainedFunctions();
  void DropFunctions();
  void DropFields();
  void TraceTypesFromRetainedClasses();
  void DropTypes();
  void DropTypeArguments();
  void DropScriptData();
  void DropMetadata();
  void DropLibraryEntries();
  void DropClasses();
  void DropLibraries();

  void BindStaticCalls();
  void SwitchICCalls();
  void ResetPrecompilerState();

  void Obfuscate();

  void CollectDynamicFunctionNames();

  void PrecompileStaticInitializers();
  void PrecompileConstructors();

  void FinalizeAllClasses();
  void VerifyJITFeedback();
  RawScript* LookupScript(const char* uri);
  intptr_t MapCid(intptr_t feedback_cid);

  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }
  Isolate* isolate() const { return isolate_; }

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;

  ParsedJSONObject* jit_feedback_;

  bool changed_;
  bool retain_root_library_caches_;
  intptr_t function_count_;
  intptr_t class_count_;
  intptr_t selector_count_;
  intptr_t dropped_function_count_;
  intptr_t dropped_field_count_;
  intptr_t dropped_class_count_;
  intptr_t dropped_typearg_count_;
  intptr_t dropped_type_count_;
  intptr_t dropped_library_count_;

  GrowableObjectArray& libraries_;
  const GrowableObjectArray& pending_functions_;
  SymbolSet sent_selectors_;
  FunctionSet enqueued_functions_;
  FieldSet fields_to_retain_;
  FunctionSet functions_to_retain_;
  ClassSet classes_to_retain_;
  TypeArgumentsSet typeargs_to_retain_;
  AbstractTypeSet types_to_retain_;
  InstanceSet consts_to_retain_;
  FieldTypeMap field_type_map_;
  TypeRangeCache* type_range_cache_;
  CidMap feedback_cid_map_;
  FunctionFeedbackMap function_feedback_map_;
  Error& error_;

  bool get_runtime_type_is_unique_;
};

class FunctionsTraits {
 public:
  static const char* Name() { return "FunctionsTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    Zone* zone = Thread::Current()->zone();
    String& a_s = String::Handle(zone);
    String& b_s = String::Handle(zone);
    a_s = a.IsFunction() ? Function::Cast(a).name() : String::Cast(a).raw();
    b_s = b.IsFunction() ? Function::Cast(b).name() : String::Cast(b).raw();
    ASSERT(a_s.IsSymbol() && b_s.IsSymbol());
    return a_s.raw() == b_s.raw();
  }
  static uword Hash(const Object& obj) {
    if (obj.IsFunction()) {
      return String::Handle(Function::Cast(obj).name()).Hash();
    } else {
      ASSERT(String::Cast(obj).IsSymbol());
      return String::Cast(obj).Hash();
    }
  }
  static RawObject* NewKey(const Function& function) { return function.raw(); }
};

typedef UnorderedHashSet<FunctionsTraits> UniqueFunctionsSet;

#if defined(DART_PRECOMPILER)
// ObfuscationMap maps Strings to Strings.
class ObfuscationMapTraits {
 public:
  static const char* Name() { return "ObfuscationMapTraits"; }
  static bool ReportStats() { return false; }

  // Only for non-descriptor lookup and table expansion.
  static bool IsMatch(const Object& a, const Object& b) {
    return a.raw() == b.raw();
  }

  static uword Hash(const Object& key) { return String::Cast(key).Hash(); }
};
typedef UnorderedHashMap<ObfuscationMapTraits> ObfuscationMap;

// Obfuscator is a helper class that is responsible for obfuscating
// identifiers when obfuscation is enabled via isolate flags.
//
class Obfuscator : public ValueObject {
 public:
  // Create Obfuscator for the given |thread|, with the given |private_key|.
  // This private key will be used when obfuscating private identifiers
  // (those starting with '_').
  //
  // If obfuscation is enabled constructor will restore obfuscation state
  // from ObjectStore::obfuscation_map()
  //
  // Note: only a single instance of obfuscator should exist at any given
  // moment on the stack because Obfuscator takes ownership of obfuscation
  // map. ObjectStore::obfuscation_map() will only be updated when
  // this Obfuscator is destroyed.
  Obfuscator(Thread* thread, const String& private_key);

  // If obfuscation is enabled - commit accumulated renames to ObjectStore.
  ~Obfuscator();

  // If obfuscation is enabled return a rename for the given |name|,
  // otherwise it is a no-op.
  //
  // Note: |name| *must* be a Symbol.
  //
  // By default renames are aware about mangling scheme used for private names:
  // '_ident@key' and '_ident' will be renamed consistently. If such
  // interpretation is undesirable e.g. it is known that name does not
  // contain a private key suffix or name is not a Dart identifier at all
  // then this function should be called with |atomic| set to true.
  //
  // Note: if obfuscator was created with private_key then all
  // renames *must* be atomic.
  //
  // This method is guaranteed to return the same value for the same
  // input and it always preserves leading '_' even for atomic renames.
  RawString* Rename(const String& name, bool atomic = false) {
    if (state_ == NULL) {
      return name.raw();
    }

    return state_->RenameImpl(name, atomic);
  }

  // Given a constant |instance| of dart:internal.Symbol rename it by updating
  // its |name| field.
  static void ObfuscateSymbolInstance(Thread* thread, const Instance& instance);

  // Given a sequence of obfuscated identifiers deobfuscate it.
  //
  // This method is only used by parser when resolving conditional imports
  // because it needs deobfuscated names to lookup in the environment.
  //
  // Note: this operation is not optimized because is very infrequent.
  static void Deobfuscate(Thread* thread, const GrowableObjectArray& pieces);

  // Serialize renaming map as a malloced array of strings.
  static const char** SerializeMap(Thread* thread);

 private:
  // Populate renaming map with names that should have identity renaming.
  // (or in other words: with those names that should not be renamed).
  void InitializeRenamingMap(Isolate* isolate);
  void PreventRenaming(Dart_QualifiedFunctionName* entry_points);
  void PreventRenaming(const char* name);
  void PreventRenaming(const String& name) { state_->PreventRenaming(name); }

  // ObjectStore::obfuscation_map() is an Array with two elements:
  // first element is the last used rename and the second element is
  // renaming map.
  static const intptr_t kSavedStateNameIndex = 0;
  static const intptr_t kSavedStateRenamesIndex = 1;
  static const intptr_t kSavedStateSize = 2;

  static RawArray* GetRenamesFromSavedState(const Array& saved_state) {
    Array& renames = Array::Handle();
    renames ^= saved_state.At(kSavedStateRenamesIndex);
    return renames.raw();
  }

  static RawString* GetNameFromSavedState(const Array& saved_state) {
    String& name = String::Handle();
    name ^= saved_state.At(kSavedStateNameIndex);
    return name.raw();
  }

  class ObfuscationState : public ZoneAllocated {
   public:
    ObfuscationState(Thread* thread,
                     const Array& saved_state,
                     const String& private_key)
        : thread_(thread),
          saved_state_(saved_state),
          renames_(GetRenamesFromSavedState(saved_state)),
          private_key_(private_key),
          string_(String::Handle(thread->zone())),
          renamed_(String::Handle(thread->zone())) {
      memset(name_, 0, sizeof(name_));

      // Restore last used rename.
      string_ = GetNameFromSavedState(saved_state);
      if (!string_.IsNull()) {
        string_.ToUTF8(reinterpret_cast<uint8_t*>(name_), sizeof(name_));
      }
    }

    void SaveState();

    // Return a rename for the given |name|.
    //
    // Note: |name| *must* be a Symbol.
    //
    // By default renames are aware about mangling scheme used for private
    // names: '_ident@key' and '_ident' will be renamed consistently. If such
    // interpretation is undesirable e.g. it is known that name does not
    // contain a private key suffix or name is not a Dart identifier at all
    // then this function should be called with |atomic| set to true.
    //
    // Note: if obfuscator was created with private_key then all
    // renames *must* be atomic.
    //
    // This method is guaranteed to return the same value for the same
    // input.
    RawString* RenameImpl(const String& name, bool atomic);

    // Register an identity (name -> name) mapping in the renaming map.
    //
    // This essentially prevents the given name from being renamed.
    void PreventRenaming(const String& name);
    void PreventRenaming(const char* name);

   private:
    // Build rename for the given |name|.
    //
    // For atomic renames BuildRename just returns the next
    // available rename generated by AtomicRename(...).
    //
    // For non-atomic renames BuildRename ensures that private mangled
    // identifiers (_ident@key) are renamed consistently with non-mangled
    // counterparts (_ident).
    RawString* BuildRename(const String& name, bool atomic);

    // Generate a new rename. If |should_be_private| is set to true
    // then we prefix returned identifier with '_'.
    RawString* NewAtomicRename(bool should_be_private);

    // Update next_ to generate the next free rename.
    void NextName();

    Thread* thread_;

    // Saved obfuscation state (ObjectStore::obfuscation_map())
    const Array& saved_state_;

    // Last used rename. Renames are only using a-zA-Z characters
    // and are generated in order: a, b, ..., z, A, ..., Z, aa, ba, ...
    char name_[100];

    ObfuscationMap renames_;

    const String& private_key_;

    // Temporary handles.
    String& string_;
    String& renamed_;
  };

  // Current obfucation state or NULL if obfuscation is not enabled.
  ObfuscationState* state_;
};
#else
// Minimal do-nothing implementation of an Obfuscator for non-precompiler
// builds.
class Obfuscator {
 public:
  Obfuscator(Thread* thread, const String& private_key) {}
  ~Obfuscator() {}

  RawString* Rename(const String& name, bool atomic = false) {
    return name.raw();
  }

  static void ObfuscateSymbolInstance(Thread* thread,
                                      const Instance& instance) {}

  static void Deobfuscate(Thread* thread, const GrowableObjectArray& pieces) {}
};
#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_PRECOMPILER_H_
