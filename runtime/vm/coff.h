// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_COFF_H_
#define RUNTIME_VM_COFF_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

#include "platform/coff.h"
#include "vm/allocation.h"
#include "vm/datastream.h"
#include "vm/debug_info_stream.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/so_writer.h"
#include "vm/zone.h"

namespace dart {

class CodeViewBuilder;
template <typename T>
class Trie;

// Emits a PE/COFF .obj file consumed by MSVC link.exe to build a
// Windows DLL.  This is the third subclass of SharedObjectWriter, alongside
// ElfWriter and MachOWriter, and short-circuits the historical
// gen_snapshot -> .S -> llvm-mc -> .obj pipeline on Windows.
//
// Scope: x86-64 only, .obj output only.  The linker still produces the .dll
// and (with /DEBUG) the .pdb.
class CoffWriter : public SharedObjectWriter {
 public:
  CoffWriter(Zone* zone,
             BaseWriteStream* stream,
             Type type,
             Dwarf* dwarf = nullptr);

  static constexpr intptr_t kPageSize = 4096;
  intptr_t page_size() const override { return kPageSize; }
  Output output() const override { return Output::Coff; }

  void AddText(const char* name,
               intptr_t label,
               const uint8_t* bytes,
               intptr_t size,
               const SharedObjectWriter::RelocationArray* relocations,
               const SharedObjectWriter::SymbolDataArray* symbols) override;
  void AddROData(const char* name,
                 intptr_t label,
                 const uint8_t* bytes,
                 intptr_t size,
                 const SharedObjectWriter::RelocationArray* relocations,
                 const SharedObjectWriter::SymbolDataArray* symbols) override;

  void Finalize() override;

  const GrowableArray<const Code*>& debug_codes();
  const GrowableArray<const Script*>& debug_scripts();
  const Trie<const char>* debug_deobfuscation_trie();
  intptr_t LookupDebugCodeLabel(const Code& code);
  intptr_t LookupDebugScript(const Script& script);

  void AssertConsistency(const SharedObjectWriter* debug) const override {
    if (debug->AsCoffWriter() == nullptr) {
      FATAL("Expected both snapshot and debug to be COFF");
    }
  }

  const CoffWriter* AsCoffWriter() const override { return this; }

  // Sentinel `symbol_label` value used inside Reloc to mean "the section
  // symbol of the section this relocation lives in".  Resolved at write time
  // by looking up `section->section_symbol` directly, since the section that
  // owns the relocation isn't known until the symbol-table layout phase.
  // Negative enough to never collide with VM-internal labels (>0) or the
  // section-symbol labels below.
  static constexpr intptr_t kSelfSectionSymbolLabel = -1000;

  // Section index slots (0 means "not present").  Resolved during Finalize.
  enum SectionKind {
    kSecText = 0,
    kSecRData,
    kSecBss,
    kSecDrectve,
    kSecPdata,
    kSecXdata,
    kSecDebugS,
    kSecDebugT,
    kNumSections,
  };

 private:
  static constexpr int16_t kTextSectionNumber = -1;
  static constexpr int16_t kRDataSectionNumber = -2;
  static constexpr int16_t kBssSectionNumber = -3;

  static constexpr intptr_t kTextSectionSymbolLabel = -10;
  static constexpr intptr_t kXdataSectionSymbolLabel = -11;

  // ---------------------------------------------------------------------------
  // Internal data model
  // ---------------------------------------------------------------------------

  struct Reloc {
    uint32_t virtual_address;  // byte offset within section
    intptr_t symbol_label;     // resolved to symbol index at finalize
    uint16_t type;             // PE_REL_AMD64_*
  };

  struct Section : public ZoneObject {
    explicit Section(Zone* zone)
        : data_stream(zone, 1024), data(zone, &data_stream) {}

    char name[9] = {0};
    uint32_t characteristics = 0;
    intptr_t alignment_log2 = 0;  // 0 = 1, 1 = 2, ..., 4 = 16 byte
    bool is_bss = false;          // no PointerToRawData when true

    // Raw bytes for the section (unused for .bss).
    ZoneWriteStream data_stream;
    DebugInfoStream data;
    // BSS section size when is_bss=true.
    intptr_t bss_size = 0;

    // Relocations to emit in the section's reloc table.
    ZoneGrowableArray<Reloc>* relocs = nullptr;

    // Computed during finalize:
    intptr_t section_number = 0;  // 1-based
    intptr_t section_symbol = 0;  // 1-based symbol-table index of section sym
    intptr_t raw_data_offset = 0;
    intptr_t reloc_offset = 0;
  };

  // One PE_SYMBOL entry (plus optional auxiliary follow-up entries).
  struct CoffSym {
    const char* name = nullptr;  // may be > 8 chars; goes to string table
    int32_t value = 0;
    // PE section number. Before AssignSectionNumbersAndSymbols, this can hold
    // one of the k*SectionNumber sentinels above.
    int16_t section_number = coff::PE_SYM_UNDEFINED;
    uint16_t type = 0;
    uint8_t storage_class = 0;
    uint8_t num_aux = 0;  // count of aux entries that follow
    intptr_t label = 0;   // VM-internal label, 0 if none
    // Auxiliary entries that immediately follow this symbol.  Each is 18 bytes
    // (sizeof(PE_SYMBOL)).  Stored as raw byte arrays.
    ZoneGrowableArray<uint8_t>* aux = nullptr;
  };

  // ---------------------------------------------------------------------------
  // Section helpers
  // ---------------------------------------------------------------------------
  Section* GetOrCreateSection(SectionKind kind,
                              const char* name,
                              uint32_t characteristics,
                              intptr_t alignment_log2,
                              bool is_bss);

  // Pads the section out to the next `alignment`-byte boundary using
  // `pad_byte` (0xCC for .text so accidental fall-through traps, 0x00 for
  // data sections).
  void PadToAlignment(Section* section, intptr_t alignment, uint8_t pad_byte);

  // Adds bytes + relocations to the given section, returning the byte offset at
  // which the new content starts (which becomes the value of any symbol added).
  // `owning_label` is the headline label for this batch. Positive
  // `source_label` values in `relocs` that match it are treated as
  // self-relative, since they refer to the start of the bytes we just wrote.
  intptr_t AppendToSection(SectionKind kind,
                           const uint8_t* bytes,
                           intptr_t size,
                           const SharedObjectWriter::RelocationArray* relocs,
                           intptr_t owning_label = 0);

  // Translate one VM relocation into one COFF relocation entry, applying the
  // inline addend at `inline_offset` within `section_data`.
  void TranslateAndApply(Section* section,
                         const SharedObjectWriter::Relocation& vm_reloc);

  // ---------------------------------------------------------------------------
  // Symbol helpers
  // ---------------------------------------------------------------------------

  // Create the canonical section symbol (PE_SYM_CLASS_STATIC with an aux
  // section record) for `section`.
  void CreateSectionSymbol(Section* section);

  // Add an external symbol bound to a label.  Returns the assigned symbol
  // table index (1-based).
  intptr_t AddExternalSymbol(const char* name,
                             intptr_t label,
                             int16_t section_number,
                             int32_t value);

  // Add a static (file-local) symbol for a label or named offset.
  intptr_t AddStaticSymbol(const char* name,
                           intptr_t label,
                           int16_t section_number,
                           int32_t value);
  const char* DisambiguateStaticSymbolName(const char* name);

  // Look up the symbol-table index for `label`.  FATAL if not present.
  intptr_t SymbolIndexForLabel(intptr_t label) const;

  // Either look up the symbol index for `label`, or synthesize an undefined
  // external symbol if the label is unknown (used for build-id during stripped
  // builds).  Returns 0 to indicate "no relocation, treat as constant".
  intptr_t SymbolIndexForLabelOrZero(intptr_t label);

  // ---------------------------------------------------------------------------
  // Finalize sub-phases
  // ---------------------------------------------------------------------------
  void EmitBssSections();
  void EmitUnwindData();
  void EmitDrectve();
  void EmitCodeView();
  void AssignSectionNumbersAndSymbols();
  void ComputeLayoutAndWrite();

  // ---------------------------------------------------------------------------
  // String table helper.  Returns the (1-based, offset-from-start-of-table)
  // string offset.  Strings of <=8 bytes go inline in the symbol entry by the
  // caller instead.
  uint32_t InternString(const char* str);

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------
  ZoneGrowableArray<Section*> all_sections_;  // creation order
  Section* by_kind_[kNumSections] = {};

  ZoneGrowableArray<CoffSym>* symbols_ = nullptr;
  IntMap<intptr_t> label_to_symbol_index_;  // label -> 1-based index
  CStringIntMap static_symbol_usage_count_;

  // String table accumulator.  First 4 bytes are the size, leading byte cannot
  // be referenced (offsets start at 4).  We store the payload only; the size
  // is prepended at write time.
  ZoneGrowableArray<uint8_t>* string_table_ = nullptr;

  // Snapshot text section labels we discover via AddText, used to size the
  // .pdata block and emit unwind data.
  struct TextPortion {
    const char* symbol_name;
    intptr_t label;
    intptr_t offset_in_text;
    intptr_t size;
  };
  ZoneGrowableArray<TextPortion> text_portions_;

  // Tracks where each appended .text portion lives so the unwind data
  // generator can reference it by section-relative offset.  These are filled
  // in by AppendToSection for .text.
  CodeViewBuilder* codeview_ = nullptr;

  friend class CodeViewBuilder;

  DISALLOW_COPY_AND_ASSIGN(CoffWriter);
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_COFF_H_
