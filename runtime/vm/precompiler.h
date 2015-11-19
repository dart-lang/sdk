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

class FunctionKeyValueTrait {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Function* Key;
  typedef const Function* Value;
  typedef const Function* Pair;

  static Key KeyOf(Pair kv) { return kv; }

  static Value ValueOf(Pair kv) { return kv; }

  static inline intptr_t Hashcode(Key key) {
    return key->token_pos();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair->raw() == key->raw();
  }
};

typedef DirectChainedHashMap<FunctionKeyValueTrait> FunctionSet;


class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll(
      Dart_QualifiedFunctionName embedder_entry_points[],
      bool reset_fields);

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
  void BindStaticCalls();
  void DedupStackmaps();
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

  const GrowableObjectArray& libraries_;
  const GrowableObjectArray& pending_functions_;
  SymbolSet sent_selectors_;
  FunctionSet enqueued_functions_;
  Error& error_;
};

}  // namespace dart

#endif  // VM_PRECOMPILER_H_
