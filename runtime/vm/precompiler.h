// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PRECOMPILER_H_
#define VM_PRECOMPILER_H_

#include "vm/allocation.h"
#include "vm/hash_map.h"
#include "vm/object.h"

namespace dart {

// Forward declarations.
class Class;
class Error;
class Field;
class Function;
class GrowableObjectArray;
class RawError;
class String;

class SymbolKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const String* Key;
  typedef const String* Value;
  typedef const String* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    return key->Hash();
  }

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

  static inline intptr_t Hashcode(Key key) {
    return key->PcOffset();
  }

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

  static inline intptr_t Hashcode(Key key) {
    return key->Length();
  }

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


class FunctionKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Function* Key;
  typedef const Function* Value;
  typedef const Function* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    return key->token_pos().value();
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
    return key->token_pos().value();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<FieldKeyValueTrait> FieldSet;


class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll(
      Dart_QualifiedFunctionName embedder_entry_points[],
      bool reset_fields);

  // Returns named function that is a unique dynamic target, i.e.,
  // - the target is identified by its name alone, since it occurs only once.
  // - target's class has no subclasses, and neither is subclassed, i.e.,
  //   the receiver type can be only the function's class.
  // Returns Function::null() if there is no unique dynamic target for
  // given 'fname'. 'fname' must be a symbol.
  static void GetUniqueDynamicTarget(Isolate* isolate,
                                     const String& fname,
                                     Object* function);

 private:
  Precompiler(Thread* thread, bool reset_fields);

  void DoCompileAll(Dart_QualifiedFunctionName embedder_entry_points[]);
  void ClearAllCode();
  void AddRoots(Dart_QualifiedFunctionName embedder_entry_points[]);
  void AddEntryPoints(Dart_QualifiedFunctionName entry_points[]);
  void Iterate();

  void AddCalleesOf(const Function& function);
  void AddConstObject(const Instance& instance);
  void AddClosureCall(const ICData& call_site);
  void AddField(const Field& field);
  void AddFunction(const Function& function);
  void AddInstantiatedClass(const Class& cls);
  void AddSelector(const String& selector);
  bool IsSent(const String& selector);

  void ProcessFunction(const Function& function);
  void CheckForNewDynamicFunctions();

  void DropUncompiledFunctions();
  void DropFields();
  void CollectDynamicFunctionNames();
  void BindStaticCalls();
  void DedupStackmaps();
  void DedupStackmapLists();
  void ResetPrecompilerState();

  class FunctionVisitor : public ValueObject {
   public:
    virtual ~FunctionVisitor() {}
    virtual void VisitFunction(const Function& function) = 0;
  };

  void VisitFunctions(FunctionVisitor* visitor);

  void FinalizeAllClasses();

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

  const GrowableObjectArray& libraries_;
  const GrowableObjectArray& pending_functions_;
  SymbolSet sent_selectors_;
  FunctionSet enqueued_functions_;
  FieldSet fields_to_retain_;
  Error& error_;
};

}  // namespace dart

#endif  // VM_PRECOMPILER_H_
