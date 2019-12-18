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

struct CodeIndexPair {
  // Typedefs needed for the DirectChainedHashMap template.
  typedef const Code* Key;
  typedef intptr_t Value;
  typedef CodeIndexPair Pair;

  static Key KeyOf(Pair kv) { return kv.code_; }

  static Value ValueOf(Pair kv) { return kv.index_; }

  static inline intptr_t Hashcode(Key key) {
    // Code objects are always allocated in old space, so they don't move.
    return key->PayloadStart();
  }

  static inline bool IsKeyEqual(Pair pair, Key key) {
    return pair.code_->raw() == key->raw();
  }

  CodeIndexPair(const Code* c, intptr_t index) : code_(c), index_(index) {
    ASSERT(!c->IsNull());
    ASSERT(c->IsNotTemporaryScopedHandle());
  }

  CodeIndexPair() : code_(NULL), index_(-1) {}

  void Print() const;

  const Code* code_;
  intptr_t index_;
};

typedef DirectChainedHashMap<CodeIndexPair> CodeIndexMap;

class Dwarf : public ZoneAllocated {
 public:
  Dwarf(Zone* zone, StreamingWriteStream* stream, Elf* elf);

  void AddCode(const Code& code, intptr_t offset);
  intptr_t AddCode(const Code& code);
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
  void sleb128(intptr_t value) {
    if (asm_stream_) {
      Print(".sleb128 %" Pd "\n", value);
    } else {
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
    if (asm_stream_) {
      Print(".uleb128 %" Pd "\n", value);
    } else {
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
    if (asm_stream_) {
      Print(".byte %d\n", value);
    } else {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  void u2(uint16_t value) {
    if (asm_stream_) {
      Print(".2byte %d\n", value);
    } else {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  intptr_t u4(uint32_t value) {
    if (asm_stream_) {
      Print(".4byte %d\n", value);
      return -1;
    } else {
      intptr_t fixup = position();
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
      return fixup;
    }
  }
  void fixup_u4(intptr_t position, uint32_t value) {
    if (asm_stream_) {
      UNREACHABLE();
    } else {
      memmove(bin_stream_->buffer() + position, &value, sizeof(value));
    }
  }
  void addr(uword value) {
    if (asm_stream_) {
      UNREACHABLE();
    } else {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(&value),
                              sizeof(value));
    }
  }
  void string(const char* cstr) {  // NOLINT
    if (asm_stream_) {
      Print(".string \"%s\"\n", cstr);  // NOLINT
    } else {
      bin_stream_->WriteBytes(reinterpret_cast<const uint8_t*>(cstr),
                              strlen(cstr) + 1);
    }
  }
  intptr_t position() {
    if (asm_stream_) {
      UNREACHABLE();
    } else {
      return bin_stream_->Position();
    }
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

  Zone* const zone_;
  Elf* const elf_;
  StreamingWriteStream* asm_stream_;
  WriteStream* bin_stream_;
  ZoneGrowableArray<const Code*> codes_;
  CodeIndexMap code_to_index_;
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
