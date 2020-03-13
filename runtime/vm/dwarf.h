// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DWARF_H_
#define RUNTIME_VM_DWARF_H_

#include "vm/allocation.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

#ifdef DART_PRECOMPILER

class Elf;
class InliningNode;
class AssemblyCodeNamer;

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

  static inline intptr_t Hashcode(Key key) { return key->token_pos().value(); }

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

struct CodeAddressPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Code* Key;
  typedef intptr_t Value;
  typedef CodeAddressPair Pair;

  static Key KeyOf(Pair kv) { return kv.code_; }

  static Value ValueOf(Pair kv) { return kv.address_; }

  static inline intptr_t Hashcode(Key key) {
    // Code objects are always allocated in old space, so they don't move.
    return key->PayloadStart();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.code_->raw() == key->raw();
  }

  CodeAddressPair(const Code* c, intptr_t address)
      : code_(c), address_(address) {
    ASSERT(!c->IsNull());
    ASSERT(c->IsNotTemporaryScopedHandle());
    ASSERT(address >= 0);
  }

  CodeAddressPair() : code_(NULL), address_(-1) {}

  void Print() const;

  const Code* code_;
  intptr_t address_;
};

typedef DirectChainedHashMap<CodeAddressPair> CodeAddressMap;

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

class Dwarf : public ZoneAllocated {
 public:
  Dwarf(Zone* zone, StreamingWriteStream* stream, Elf* elf);

  Elf* elf() const { return elf_; }

  // Stores the code object for later creating the line number program.
  //
  // Should only be called when the output is not ELF.
  //
  // Returns the stored index of the code object.
  intptr_t AddCode(const Code& code);

  // Stores the code object for later creating the line number program.
  //
  // [payload_offset] should be the offset of the payload within the text
  // section. [name] is used to create an ELF static symbol for the payload.
  //
  // Should only be called when the output is ELF.
  void AddCode(const Code& code, const char* name, intptr_t payload_offset);

  intptr_t AddFunction(const Function& function);
  intptr_t AddScript(const Script& script);
  intptr_t LookupFunction(const Function& function);
  intptr_t LookupScript(const Script& script);

  void Write() {
    WriteAbbreviations();
    WriteCompilationUnit();
    WriteLines();
  }

 private:
  // Implements shared functionality for the two AddCode calls. Assumes the
  // Code handle is appropriately zoned.
  intptr_t AddCodeHelper(const Code& code);

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

  static const intptr_t DW_LNE_end_sequence = 0x01;
  static const intptr_t DW_LNE_set_address = 0x02;

  enum {
    kCompilationUnit = 1,
    kAbstractFunction,
    kConcreteFunction,
    kInlinedFunction,
  };

  void Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3);

#if defined(TARGET_ARCH_IS_32_BIT)
#define FORM_ADDR ".4byte"
#elif defined(TARGET_ARCH_IS_64_BIT)
#define FORM_ADDR ".8byte"
#endif

  void PrintNamedAddress(const char* name) { Print(FORM_ADDR " %s\n", name); }
  void PrintNamedAddressWithOffset(const char* name, intptr_t offset) {
    Print(FORM_ADDR " %s + %" Pd "\n", name, offset);
  }

#undef FORM_ADDR

  void sleb128(intptr_t value) {
    if (asm_stream_ != nullptr) {
      Print(".sleb128 %" Pd "\n", value);
    }
    if (elf_ != nullptr) {
      bool is_last_part = false;
      while (!is_last_part) {
        uint8_t part = value & 0x7F;
        value >>= 7;
        if ((value == 0 && (part & 0x40) == 0) ||
            (value == static_cast<intptr_t>(-1) && (part & 0x40) != 0)) {
          is_last_part = true;
        } else {
          part |= 0x80;
        }
        bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&part),
                                sizeof(part));
      }
    }
  }
  void uleb128(uintptr_t value) {
    if (asm_stream_ != nullptr) {
      Print(".uleb128 %" Pd "\n", value);
    }
    if (elf_ != nullptr) {
      bool is_last_part = false;
      while (!is_last_part) {
        uint8_t part = value & 0x7F;
        value >>= 7;
        if (value == 0) {
          is_last_part = true;
        } else {
          part |= 0x80;
        }
        bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&part),
                                sizeof(part));
      }
    }
  }
  void u1(uint8_t value) {
    if (asm_stream_ != nullptr) {
      Print(".byte %u\n", value);
    }
    if (elf_ != nullptr) {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  void u2(uint16_t value) {
    if (asm_stream_ != nullptr) {
      Print(".2byte %u\n", value);
    }
    if (elf_ != nullptr) {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  intptr_t u4(uint32_t value) {
    if (asm_stream_ != nullptr) {
      Print(".4byte %" Pu32 "\n", value);
    }
    if (elf_ != nullptr) {
      intptr_t fixup = position();
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
      return fixup;
    }
    return -1;
  }
  void fixup_u4(intptr_t position, uint32_t value) {
    RELEASE_ASSERT(elf_ != nullptr);
    memmove(bin_stream_->buffer() + position, &value, sizeof(value));
  }
  void u8(uint64_t value) {
    if (asm_stream_ != nullptr) {
      Print(".8byte %" Pu64 "\n", value);
    }
    if (elf_ != nullptr) {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  void addr(uword value) {
    RELEASE_ASSERT(elf_ != nullptr);
#if defined(TARGET_ARCH_IS_32_BIT)
    u4(value);
#else
    u8(value);
#endif
  }
  void string(const char* cstr) {  // NOLINT
    if (asm_stream_ != nullptr) {
      Print(".string \"%s\"\n", cstr);  // NOLINT
    }
    if (elf_ != nullptr) {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(cstr),
                              strlen(cstr) + 1);
    }
  }
  intptr_t position() {
    RELEASE_ASSERT(elf_ != nullptr);
    return bin_stream_->Position();
  }

  void WriteAbbreviations();
  void WriteCompilationUnit();
  void WriteAbstractFunctions();
  void WriteConcreteFunctions();
  InliningNode* ExpandInliningTree(const Code& code);
  void WriteInliningNode(InliningNode* node,
                         intptr_t root_code_index,
                         intptr_t root_code_offset,
                         const Script& parent_script,
                         AssemblyCodeNamer* namer);
  void WriteLines();

  const char* Deobfuscate(const char* cstr);
  static Trie<const char>* CreateReverseObfuscationTrie(Zone* zone);

  Zone* const zone_;
  Elf* const elf_;
  Trie<const char>* const reverse_obfuscation_trie_;
  StreamingWriteStream* asm_stream_;
  WriteStream* bin_stream_;
  ZoneGrowableArray<const Code*> codes_;
  CodeAddressMap code_to_address_;
  ZoneGrowableArray<const Function*> functions_;
  FunctionIndexMap function_to_index_;
  ZoneGrowableArray<const Script*> scripts_;
  ScriptIndexMap script_to_index_;
  uint32_t* abstract_origins_;
  intptr_t temp_;
};

#endif  // DART_PRECOMPILER

}  // namespace dart

#endif  // RUNTIME_VM_DWARF_H_
