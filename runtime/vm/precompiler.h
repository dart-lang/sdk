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


class TypeRangeCache : public StackResource {
 public:
  TypeRangeCache(Thread* thread, intptr_t num_cids)
      : StackResource(thread),
        thread_(thread),
        lower_limits_(thread->zone()->Alloc<intptr_t>(num_cids)),
        upper_limits_(thread->zone()->Alloc<intptr_t>(num_cids)) {
    for (intptr_t i = 0; i < num_cids; i++) {
      lower_limits_[i] = kNotComputed;
      upper_limits_[i] = kNotComputed;
    }
    // We don't re-enter the precompiler.
    ASSERT(thread->type_range_cache() == NULL);
    thread->set_type_range_cache(this);
  }

  ~TypeRangeCache() {
    ASSERT(thread_->type_range_cache() == this);
    thread_->set_type_range_cache(NULL);
  }

  bool InstanceOfHasClassRange(const AbstractType& type,
                               intptr_t* lower_limit,
                               intptr_t* upper_limit);

 private:
  static const intptr_t kNotComputed = -1;
  static const intptr_t kNotContiguous = -2;

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

class StackmapKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Stackmap* Key;
  typedef const Stackmap* Value;
  typedef const Stackmap* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->PcOffset(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->Equals(*key);
  }
};

typedef DirectChainedHashMap<StackmapKeyValueTrait> StackmapSet;


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


class FunctionKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Function* Key;
  typedef const Function* Value;
  typedef const Function* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) { return key->token_pos().value(); }

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

  static inline intptr_t Hashcode(Key key) { return key->token_pos().value(); }

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


class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll(
      Dart_QualifiedFunctionName embedder_entry_points[],
      bool reset_fields);

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

 private:
  Precompiler(Thread* thread, bool reset_fields);

  void DoCompileAll(Dart_QualifiedFunctionName embedder_entry_points[]);
  void ClearAllCode();
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
  void DropClasses();
  void DropLibraries();

  void BindStaticCalls();
  void SwitchICCalls();
  void ShareMegamorphicBuckets();
  void DedupStackmaps();
  void DedupLists();
  void DedupInstructions();
  void ResetPrecompilerState();

  void CollectDynamicFunctionNames();

  void PrecompileStaticInitializers();
  void PrecompileConstructors();

  template <typename T>
  class Visitor : public ValueObject {
   public:
    virtual ~Visitor() {}
    virtual void Visit(const T& obj) = 0;
  };
  typedef Visitor<Function> FunctionVisitor;
  typedef Visitor<Class> ClassVisitor;

  void VisitFunctions(FunctionVisitor* visitor);
  void VisitClasses(ClassVisitor* visitor);

  void FinalizeAllClasses();
  void SortClasses();
  void RemapClassIds(intptr_t* old_to_new_cid);

  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }
  Isolate* isolate() const { return isolate_; }

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;

  const bool reset_fields_;

  bool changed_;
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
