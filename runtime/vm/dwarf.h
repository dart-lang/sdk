// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DWARF_H_
#define RUNTIME_VM_DWARF_H_

#include "vm/allocation.h"
#include "vm/hash.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

#ifdef DART_PRECOMPILER

class InliningNode;

struct ScriptIndexPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Script* Key;
  typedef intptr_t Value;
  typedef ScriptIndexPair Pair;

  static Key KeyOf(Pair kv) { return kv.script_; }

  static Value ValueOf(Pair kv) { return kv.index_; }

  static inline intptr_t Hashcode(Key key) {
    return String::Handle(key->url()).Hash();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.script_->raw() == key->raw();
  }

  ScriptIndexPair(const Script* s, intptr_t index) : script_(s), index_(index) {
    ASSERT(!s->IsNull());
    ASSERT(s->IsNotTemporaryScopedHandle());
  }

  ScriptIndexPair() : script_(NULL), index_(-1) {}

  void Print() const;

  const Script* script_;
  intptr_t index_;
};

typedef DirectChainedHashMap<ScriptIndexPair> ScriptIndexMap;

struct FunctionIndexPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Function* Key;
  typedef intptr_t Value;
  typedef FunctionIndexPair Pair;

  static Key KeyOf(Pair kv) { return kv.function_; }

  static Value ValueOf(Pair kv) { return kv.index_; }

  static inline intptr_t Hashcode(Key key) { return key->token_pos().Hash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.function_->raw() == key->raw();
  }

  FunctionIndexPair(const Function* f, intptr_t index)
      : function_(f), index_(index) {
    ASSERT(!f->IsNull());
    ASSERT(f->IsNotTemporaryScopedHandle());
  }

  FunctionIndexPair() : function_(NULL), index_(-1) {}

  void Print() const;

  const Function* function_;
  intptr_t index_;
};

typedef DirectChainedHashMap<FunctionIndexPair> FunctionIndexMap;

// Assumes T has a copy constructor and is CopyAssignable.
template <typename T>
struct DwarfCodeKeyValueTrait {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Code* Key;
  typedef T Value;

  struct Pair {
    Pair(const Code* c, const T v) : code(c), value(v) {
      ASSERT(c != nullptr);
      ASSERT(!c->IsNull());
      ASSERT(c->IsNotTemporaryScopedHandle());
    }
    Pair() : code(nullptr), value{} {}

    // Don't implcitly delete copy and copy assigment constructors.
    Pair(const Pair& other) = default;
    Pair& operator=(const Pair& other) = default;

    const Code* code;
    T value;
  };

  static Key KeyOf(Pair kv) { return kv.code; }

  static Value ValueOf(Pair kv) { return kv.value; }

  static inline intptr_t Hashcode(Key key) {
    // Instructions are always allocated in old space, so they don't move.
    return FinalizeHash(key->PayloadStart(), 32);
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    // Code objects are always allocated in old space, so they don't move.
    return pair.code->raw() == key->raw();
  }
};

template <typename T>
using DwarfCodeMap = DirectChainedHashMap<DwarfCodeKeyValueTrait<T>>;

template <typename T>
class Trie : public ZoneAllocated {
 public:
  // Returns whether [key] is a valid trie key (that is, a C string that
  // contains only characters for which charIndex returns a non-negative value).
  static bool IsValidKey(const char* key) {
    for (intptr_t i = 0; key[i] != '\0'; i++) {
      if (ChildIndex(key[i]) < 0) return false;
    }
    return true;
  }

  // Adds a binding of [key] to [value] in [trie]. Assumes that the string in
  // [key] is a valid trie key and does not already have a value in [trie].
  //
  // If [trie] is nullptr, then a new trie is created and a pointer to the new
  // trie is returned. Otherwise, [trie] will be returned.
  static Trie<T>* AddString(Zone* zone,
                            Trie<T>* trie,
                            const char* key,
                            const T* value);

  // Adds a binding of [key] to [value]. Assumes that the string in [key] is a
  // valid trie key and does not already have a value in this trie.
  void AddString(Zone* zone, const char* key, const T* value) {
    AddString(zone, this, key, value);
  }

  // Looks up the value stored for [key] in [trie]. If one is not found, then
  // nullptr is returned.
  //
  // If [end] is not nullptr, then the longest prefix of [key] that is a valid
  // trie key prefix will be used for the lookup and the value pointed to by
  // [end] is set to the index after that prefix. Otherwise, the whole [key]
  // is used.
  static const T* Lookup(const Trie<T>* trie,
                         const char* key,
                         intptr_t* end = nullptr);

  // Looks up the value stored for [key]. If one is not found, then nullptr is
  // returned.
  //
  // If [end] is not nullptr, then the longest prefix of [key] that is a valid
  // trie key prefix will be used for the lookup and the value pointed to by
  // [end] is set to the index after that prefix. Otherwise, the whole [key]
  // is used.
  const T* Lookup(const char* key, intptr_t* end = nullptr) const {
    return Lookup(this, key, end);
  }

 private:
  // Currently, only the following characters can appear in obfuscated names:
  // '_', '@', '0-9', 'a-z', 'A-Z'
  static const intptr_t kNumValidChars = 64;

  Trie() {
    for (intptr_t i = 0; i < kNumValidChars; i++) {
      children_[i] = nullptr;
    }
  }

  static intptr_t ChildIndex(char c) {
    if (c == '_') return 0;
    if (c == '@') return 1;
    if (c >= '0' && c <= '9') return ('9' - c) + 2;
    if (c >= 'a' && c <= 'z') return ('z' - c) + 12;
    if (c >= 'A' && c <= 'Z') return ('Z' - c) + 38;
    return -1;
  }

  const T* value_ = nullptr;
  Trie<T>* children_[kNumValidChars];
};

class DwarfWriteStream : public ValueObject {
 public:
  DwarfWriteStream() {}
  virtual ~DwarfWriteStream() {}

  virtual void sleb128(intptr_t value) = 0;
  virtual void uleb128(uintptr_t value) = 0;
  virtual void u1(uint8_t value) = 0;
  virtual void u2(uint16_t value) = 0;
  virtual void u4(uint32_t value) = 0;
  virtual void u8(uint64_t value) = 0;
  virtual void string(const char* cstr) = 0;  // NOLINT

  // Returns the position (if any) to fix up in SetSize().
  virtual intptr_t ReserveSize(const char* prefix, intptr_t* start) = 0;
  virtual void SetSize(intptr_t position,
                       const char* prefix,
                       intptr_t start) = 0;

  virtual void OffsetFromSymbol(const char* symbol, intptr_t offset) = 0;
  // Returns the difference between the relocated address at offset1 from
  // symbol1 and the relocated address at offset2 from symbol2.
  virtual void DistanceBetweenSymbolOffsets(const char* symbol1,
                                            intptr_t offset1,
                                            const char* symbol2,
                                            intptr_t offset2) = 0;

  virtual void InitializeAbstractOrigins(intptr_t size) = 0;
  virtual void RegisterAbstractOrigin(intptr_t index) = 0;
  virtual void AbstractOrigin(intptr_t index) = 0;

  DISALLOW_COPY_AND_ASSIGN(DwarfWriteStream);
};

class Dwarf : public ZoneAllocated {
 public:
  explicit Dwarf(Zone* zone);

  const ZoneGrowableArray<const Code*>& codes() const { return codes_; }

  // Stores the code object for later creating the line number program.
  void AddCode(const Code& code, const char* name);

  intptr_t AddFunction(const Function& function);
  intptr_t AddScript(const Script& script);
  intptr_t LookupFunction(const Function& function);
  intptr_t LookupScript(const Script& script);

  void WriteAbbreviations(DwarfWriteStream* stream);
  void WriteDebugInfo(DwarfWriteStream* stream);
  void WriteLineNumberProgram(DwarfWriteStream* stream);

 private:
  static const intptr_t DW_TAG_compile_unit = 0x11;
  static const intptr_t DW_TAG_inlined_subroutine = 0x1d;
  static const intptr_t DW_TAG_subprogram = 0x2e;

  static const intptr_t DW_CHILDREN_no = 0x0;
  static const intptr_t DW_CHILDREN_yes = 0x1;

  static const intptr_t DW_AT_sibling = 0x1;
  static const intptr_t DW_AT_name = 0x3;
  static const intptr_t DW_AT_stmt_list = 0x10;
  static const intptr_t DW_AT_low_pc = 0x11;
  static const intptr_t DW_AT_high_pc = 0x12;
  static const intptr_t DW_AT_comp_dir = 0x1b;
  static const intptr_t DW_AT_inline = 0x20;
  static const intptr_t DW_AT_producer = 0x25;
  static const intptr_t DW_AT_abstract_origin = 0x31;
  static const intptr_t DW_AT_decl_column = 0x39;
  static const intptr_t DW_AT_decl_file = 0x3a;
  static const intptr_t DW_AT_decl_line = 0x3b;
  static const intptr_t DW_AT_call_column = 0x57;
  static const intptr_t DW_AT_call_file = 0x58;
  static const intptr_t DW_AT_call_line = 0x59;

  static const intptr_t DW_FORM_addr = 0x01;
  static const intptr_t DW_FORM_string = 0x08;
  static const intptr_t DW_FORM_udata = 0x0f;
  static const intptr_t DW_FORM_ref4 = 0x13;
  static const intptr_t DW_FORM_ref_udata = 0x15;
  static const intptr_t DW_FORM_sec_offset = 0x17;

  static const intptr_t DW_INL_not_inlined = 0x0;
  static const intptr_t DW_INL_inlined = 0x1;

  static const intptr_t DW_LNS_copy = 0x1;
  static const intptr_t DW_LNS_advance_pc = 0x2;
  static const intptr_t DW_LNS_advance_line = 0x3;
  static const intptr_t DW_LNS_set_file = 0x4;
  static const intptr_t DW_LNS_set_column = 0x5;

  static const intptr_t DW_LNE_end_sequence = 0x01;
  static const intptr_t DW_LNE_set_address = 0x02;

  enum {
    kCompilationUnit = 1,
    kAbstractFunction,
    kConcreteFunction,
    kInlinedFunction,
  };

  void WriteAbstractFunctions(DwarfWriteStream* stream);
  void WriteConcreteFunctions(DwarfWriteStream* stream);
  InliningNode* ExpandInliningTree(const Code& code);
  void WriteInliningNode(DwarfWriteStream* stream,
                         InliningNode* node,
                         const char* root_code_name,
                         const Script& parent_script);

  const char* Deobfuscate(const char* cstr);
  static Trie<const char>* CreateReverseObfuscationTrie(Zone* zone);

  Zone* const zone_;
  Trie<const char>* const reverse_obfuscation_trie_;
  ZoneGrowableArray<const Code*> codes_;
  DwarfCodeMap<const char*> code_to_name_;
  ZoneGrowableArray<const Function*> functions_;
  FunctionIndexMap function_to_index_;
  ZoneGrowableArray<const Script*> scripts_;
  ScriptIndexMap script_to_index_;
  intptr_t temp_;
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_DWARF_H_
