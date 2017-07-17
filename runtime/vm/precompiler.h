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
  void DropLibraryEntries();
  void DropClasses();
  void DropLibraries();

  void BindStaticCalls();
  void SwitchICCalls();
  void ResetPrecompilerState();

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

}  // namespace dart

#endif  // RUNTIME_VM_PRECOMPILER_H_
