// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DWARF_H_
#define RUNTIME_VM_DWARF_H_

#include "vm/allocation.h"
#include "vm/hash.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

#ifdef DART_PRECOMPILER

class InliningNode;
class LineNumberProgramWriter;

struct ScriptIndexPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Script* Key;
  typedef intptr_t Value;
  typedef ScriptIndexPair Pair;

  static Key KeyOf(Pair kv) { return kv.script_; }

  static Value ValueOf(Pair kv) { return kv.index_; }

  static inline uword Hash(Key key) {
    return String::Handle(key->url()).Hash();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.script_->ptr() == key->ptr();
  }

  ScriptIndexPair(const Script* s, intptr_t index) : script_(s), index_(index) {
    ASSERT(!s->IsNull());
    DEBUG_ASSERT(s->IsNotTemporaryScopedHandle());
  }

  ScriptIndexPair() : script_(nullptr), index_(-1) {}

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

  static inline uword Hash(Key key) { return key->token_pos().Hash(); }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.function_->ptr() == key->ptr();
  }

  FunctionIndexPair(const Function* f, intptr_t index)
      : function_(f), index_(index) {
    ASSERT(!f->IsNull());
    DEBUG_ASSERT(f->IsNotTemporaryScopedHandle());
  }

  FunctionIndexPair() : function_(nullptr), index_(-1) {}

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
      DEBUG_ASSERT(c->IsNotTemporaryScopedHandle());
    }
    Pair() : code(nullptr), value{} {}

    // Don't implicitly delete copy and copy assignment constructors.
    Pair(const Pair& other) = default;
    Pair& operator=(const Pair& other) = default;

    const Code* code;
    T value;
  };

  static Key KeyOf(Pair kv) { return kv.code; }

  static Value ValueOf(Pair kv) { return kv.value; }

  static inline uword Hash(Key key) {
    // Instructions are always allocated in old space, so they don't move.
    return Utils::WordHash(key->PayloadStart());
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    // Code objects are always allocated in old space, so they don't move.
    return pair.code->ptr() == key->ptr();
  }
};

template <typename T>
using DwarfCodeMap = DirectChainedHashMap<DwarfCodeKeyValueTrait<T>>;

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

  // Prefixes the content added by body with its length.
  //
  // symbol_prefix is used when a local symbol is created for the length.
  virtual void WritePrefixedLength(const char* symbol_prefix,
                                   std::function<void()> body) = 0;

  // Generates a relocated address from the given symbol label and offset.
  //
  // If no size is provided, the size of the relocated address in the stream
  // is the native word size.
  virtual void OffsetFromSymbol(intptr_t label,
                                intptr_t offset,
                                size_t size = kAddressSize) = 0;

  virtual void InitializeAbstractOrigins(intptr_t size) = 0;
  virtual void RegisterAbstractOrigin(intptr_t index) = 0;
  virtual void AbstractOrigin(intptr_t index) = 0;

 protected:
#if defined(TARGET_ARCH_IS_32_BIT)
  static constexpr size_t kAddressSize = kInt32Size;
#else
  static constexpr size_t kAddressSize = kInt64Size;
#endif

  DISALLOW_COPY_AND_ASSIGN(DwarfWriteStream);
};

class Dwarf : public ZoneObject {
 public:
  // The compilation unit name is used as the DW_AT_name for the
  // Dart program's compilation unit. If nullptr, then the name of
  // the root library is used instead.
  Dwarf(Zone* zone,
        const Trie<const char>* deobfuscation_trie,
        const char* compilation_unit_name = nullptr);

  const GrowableArray<const Code*>& codes() const { return codes_; }

  // Stores the code object for later creating the line number program.
  void AddCode(const Code& code, intptr_t label);

  intptr_t AddFunction(const Function& function);
  intptr_t AddScript(const Script& script);
  intptr_t LookupFunction(const Function& function);
  intptr_t LookupScript(const Script& script);

  void WriteAbbreviations(DwarfWriteStream* stream);
  void WriteDebugInfo(DwarfWriteStream* stream);
  void WriteLineNumberProgram(DwarfWriteStream* stream);

#if !defined(TARGET_ARCH_IA32)
  // A frame description entry (used in the call frame information records)
  // needs two pieces of information from the SharedObjectWriter:
  struct FrameDescriptionEntry {
    // * The starting address (here, represented by the label of the symbol
    //   corresponding to the starting address).
    intptr_t label;
    // * The size of the memory space to cover from the starting address.
    intptr_t size;
  };

  // Only used for non-assembly outputs; the AssemblyImageWriter inserts
  // approrpiate CFI directives directly into the generated assembly.
  static void WriteCallFrameInformationRecords(
      class DwarfSharedObjectStream* stream,
      const GrowableArray<FrameDescriptionEntry>& fdes);
#endif

 private:
  friend class LineNumberProgramWriter;

  static constexpr intptr_t DW_TAG_compile_unit = 0x11;
  static constexpr intptr_t DW_TAG_inlined_subroutine = 0x1d;
  static constexpr intptr_t DW_TAG_subprogram = 0x2e;

  static constexpr intptr_t DW_CHILDREN_no = 0x0;
  static constexpr intptr_t DW_CHILDREN_yes = 0x1;

  static constexpr intptr_t DW_AT_sibling = 0x1;
  static constexpr intptr_t DW_AT_name = 0x3;
  static constexpr intptr_t DW_AT_stmt_list = 0x10;
  static constexpr intptr_t DW_AT_low_pc = 0x11;
  static constexpr intptr_t DW_AT_high_pc = 0x12;
  static constexpr intptr_t DW_AT_comp_dir = 0x1b;
  static constexpr intptr_t DW_AT_inline = 0x20;
  static constexpr intptr_t DW_AT_producer = 0x25;
  static constexpr intptr_t DW_AT_abstract_origin = 0x31;
  static constexpr intptr_t DW_AT_artificial = 0x34;
  static constexpr intptr_t DW_AT_decl_column = 0x39;
  static constexpr intptr_t DW_AT_decl_file = 0x3a;
  static constexpr intptr_t DW_AT_decl_line = 0x3b;
  static constexpr intptr_t DW_AT_call_column = 0x57;
  static constexpr intptr_t DW_AT_call_file = 0x58;
  static constexpr intptr_t DW_AT_call_line = 0x59;

  static constexpr intptr_t DW_FORM_addr = 0x01;
  static constexpr intptr_t DW_FORM_string = 0x08;
  static constexpr intptr_t DW_FORM_flag = 0x0c;
  static constexpr intptr_t DW_FORM_udata = 0x0f;
  static constexpr intptr_t DW_FORM_ref4 = 0x13;
  static constexpr intptr_t DW_FORM_ref_udata = 0x15;
  static constexpr intptr_t DW_FORM_sec_offset = 0x17;

  static constexpr intptr_t DW_INL_not_inlined = 0x0;
  static constexpr intptr_t DW_INL_inlined = 0x1;

  static constexpr intptr_t DW_LNS_copy = 0x1;
  static constexpr intptr_t DW_LNS_advance_pc = 0x2;
  static constexpr intptr_t DW_LNS_advance_line = 0x3;
  static constexpr intptr_t DW_LNS_set_file = 0x4;
  static constexpr intptr_t DW_LNS_set_column = 0x5;

  static constexpr intptr_t DW_LNE_end_sequence = 0x01;
  static constexpr intptr_t DW_LNE_set_address = 0x02;

  static constexpr intptr_t DW_CFA_offset = 0x80;
  static constexpr intptr_t DW_CFA_val_offset = 0x14;
  static constexpr intptr_t DW_CFA_def_cfa = 0x0c;

  static constexpr uint8_t DW_EH_PE_pcrel = 0x10;
  static constexpr uint8_t DW_EH_PE_sdata4 = 0x0b;

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
                         intptr_t root_label,
                         const Script& parent_script);

  void WriteSyntheticLineNumberProgram(LineNumberProgramWriter* writer);
  void WriteLineNumberProgramFromCodeSourceMaps(
      LineNumberProgramWriter* writer);

  Zone* const zone_;
  const char* const compilation_unit_name_;
  const Trie<const char>* const deobfuscation_trie_;
  GrowableArray<const Code*> codes_;
  DwarfCodeMap<intptr_t> code_to_label_;
  GrowableArray<const Function*> functions_;
  FunctionIndexMap function_to_index_;
  GrowableArray<const Script*> scripts_;
  ScriptIndexMap script_to_index_;
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_DWARF_H_
