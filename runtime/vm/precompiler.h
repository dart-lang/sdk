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

class SymbolPair {
 public:
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const String* Key;
  typedef bool Value;
  typedef SymbolPair Pair;

  SymbolPair() : key_(NULL), value_(false) {}
  SymbolPair(Key key, Value value) : key_(key), value_(value) {
    ASSERT(key->IsNotTemporaryScopedHandle());
  }

  static Key KeyOf(Pair kv) { return kv.key_; }

  static Value ValueOf(Pair kv) { return kv.value_; }

  static inline intptr_t Hashcode(Key key) {
    return key->Hash();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.key_->raw() == key->raw();
  }

 private:
  Key key_;
  Value value_;
};


class SymbolSet : public ValueObject {
 public:
  explicit SymbolSet(Zone* zone) : zone_(zone), map_() {}

  void Add(const String& symbol) {
    ASSERT(symbol.IsSymbol());
    if (symbol.IsNotTemporaryScopedHandle()) {
      SymbolPair pair(&symbol, true);
      map_.Insert(pair);
    } else {
      SymbolPair pair(&String::ZoneHandle(zone_, symbol.raw()), true);
      map_.Insert(pair);
    }
  }

  bool Includes(const String& symbol) {
    ASSERT(symbol.IsSymbol());
    return map_.Lookup(&symbol);
  }

 private:
  Zone* zone_;
  DirectChainedHashMap<SymbolPair> map_;
};


class Precompiler : public ValueObject {
 public:
  static RawError* CompileAll();

 private:
  explicit Precompiler(Thread* thread);

  void DoCompileAll();
  void ClearAllCode();
  void AddRoots();
  void Iterate();
  void CleanUp();

  void AddCalleesOf(const Function& function);
  void AddField(const Field& field);
  void AddFunction(const Function& function);
  void AddClass(const Class& cls);
  void AddSelector(const String& selector);
  bool IsSent(const String& selector);

  void ProcessFunction(const Function& function);
  void CheckForNewDynamicFunctions();

  void DropUncompiledFunctions();

  Thread* thread() const { return thread_; }
  Zone* zone() const { return zone_; }
  Isolate* isolate() const { return isolate_; }

  Thread* thread_;
  Zone* zone_;
  Isolate* isolate_;

  bool changed_;
  intptr_t function_count_;
  intptr_t class_count_;
  intptr_t selector_count_;
  intptr_t dropped_function_count_;

  const GrowableObjectArray& libraries_;
  const GrowableObjectArray& pending_functions_;
  const GrowableObjectArray& collected_closures_;
  SymbolSet sent_selectors_;
  Error& error_;
};

}  // namespace dart

#endif  // VM_PRECOMPILER_H_
