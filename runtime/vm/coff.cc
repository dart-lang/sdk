// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coff.h"

#if defined(DART_PRECOMPILER)

#include "include/dart_api.h"
#include "platform/unaligned.h"
#include "platform/utils.h"
#include "vm/codeview.h"
#include "vm/dwarf.h"
#include "vm/image_snapshot.h"
#include "vm/os.h"

namespace dart {

namespace {

static constexpr intptr_t kCoffRelocationOverflowThreshold = 0xffff;
static constexpr uint16_t kCoffRelocationCountOverflowSentinel = 0xffff;

bool UsesRelocationCountOverflow(intptr_t relocation_count) {
  return relocation_count >= kCoffRelocationOverflowThreshold;
}

uint16_t EncodedRelocationCount(intptr_t relocation_count) {
  if (UsesRelocationCountOverflow(relocation_count)) {
    return kCoffRelocationCountOverflowSentinel;
  }
  return static_cast<uint16_t>(relocation_count);
}

intptr_t RelocationRecordCountOnDisk(intptr_t relocation_count) {
  return relocation_count +
         (UsesRelocationCountOverflow(relocation_count) ? 1 : 0);
}

struct ParsedUnwindPrologue {
  uint32_t stack_size = 0;
  uint8_t prologue_size = 0;
};

struct FunctionUnwindRange {
  uint32_t begin = 0;
  uint32_t end = 0;
  ParsedUnwindPrologue prologue;
};

struct SharedUnwindInfo {
  ParsedUnwindPrologue prologue;
  uint32_t xdata_offset = 0;
};

int CompareFunctionUnwindRange(const FunctionUnwindRange* a,
                               const FunctionUnwindRange* b) {
  if (a->begin < b->begin) return -1;
  if (a->begin > b->begin) return 1;
  if (a->end < b->end) return -1;
  if (a->end > b->end) return 1;
  return 0;
}

}  // namespace

// -----------------------------------------------------------------------------
// Construction
// -----------------------------------------------------------------------------

CoffWriter::CoffWriter(Zone* zone,
                       BaseWriteStream* stream,
                       Type type,
                       Dwarf* dwarf)
    : SharedObjectWriter(zone, stream, type, dwarf),
      all_sections_(zone, 8),
      label_to_symbol_index_(zone),
      static_symbol_usage_count_(zone),
      text_portions_(zone, 4) {
  symbols_ = new (zone) ZoneGrowableArray<CoffSym>(zone, 32);
  string_table_ = new (zone) ZoneGrowableArray<uint8_t>(zone, 128);
}

const GrowableArray<const Code*>& CoffWriter::debug_codes() {
  ASSERT(dwarf() != nullptr);
  return dwarf()->codes();
}

const GrowableArray<const Script*>& CoffWriter::debug_scripts() {
  ASSERT(dwarf() != nullptr);
  return dwarf()->scripts();
}

const Trie<const char>* CoffWriter::debug_deobfuscation_trie() {
  ASSERT(dwarf() != nullptr);
  return dwarf()->deobfuscation_trie();
}

intptr_t CoffWriter::LookupDebugCodeLabel(const Code& code) {
  ASSERT(dwarf() != nullptr);
  return dwarf()->LookupCodeLabel(code);
}

intptr_t CoffWriter::LookupDebugScript(const Script& script) {
  ASSERT(dwarf() != nullptr);
  return dwarf()->LookupScript(script);
}

// -----------------------------------------------------------------------------
// String table
// -----------------------------------------------------------------------------

uint32_t CoffWriter::InternString(const char* str) {
  // COFF string table starts at offset 4 (the first 4 bytes hold the size).
  const uint32_t offset = static_cast<uint32_t>(string_table_->length()) + 4;
  const intptr_t len = strlen(str);
  for (intptr_t i = 0; i <= len; i++) {  // include trailing NUL
    string_table_->Add(static_cast<uint8_t>(str[i]));
  }
  return offset;
}

// -----------------------------------------------------------------------------
// Section helpers
// -----------------------------------------------------------------------------

CoffWriter::Section* CoffWriter::GetOrCreateSection(SectionKind kind,
                                                    const char* name,
                                                    uint32_t characteristics,
                                                    intptr_t alignment_log2,
                                                    bool is_bss) {
  if (by_kind_[kind] != nullptr) {
    return by_kind_[kind];
  }
  auto* const section = new (zone_) Section(zone_);
  ASSERT(strlen(name) <= 8);
  for (intptr_t i = 0; i < 8 && name[i] != '\0'; i++) {
    section->name[i] = name[i];
  }
  section->characteristics = characteristics;
  section->alignment_log2 = alignment_log2;
  section->is_bss = is_bss;
  section->relocs = new (zone_) ZoneGrowableArray<Reloc>(zone_, 8);
  by_kind_[kind] = section;
  all_sections_.Add(section);
  return section;
}

void CoffWriter::PadToAlignment(Section* section,
                                intptr_t alignment,
                                uint8_t pad_byte) {
  ASSERT(section != nullptr);
  ASSERT(!section->is_bss);
  ASSERT(Utils::IsPowerOfTwo(alignment));
  section->data.Align(alignment, /*offset=*/0, pad_byte);
}

intptr_t CoffWriter::AppendToSection(
    SectionKind kind,
    const uint8_t* bytes,
    intptr_t size,
    const SharedObjectWriter::RelocationArray* relocations,
    intptr_t owning_label) {
  using R = SharedObjectWriter::Relocation;
  Section* const section = by_kind_[kind];
  ASSERT(section != nullptr);
  ASSERT(!section->is_bss);
  const intptr_t start = section->data.Position();
  section->data.bytes(bytes, size);
  if (relocations != nullptr) {
    for (const auto& vm_reloc : *relocations) {
      // Adjust section_offset to account for any data already in the section.
      SharedObjectWriter::Relocation translated = vm_reloc;
      translated.section_offset += start;
      // The Dart image writer expresses many text relocations as
      // `target_label - owning_label`, where `owning_label` is the headline
      // symbol for the current AddText portion (always at offset `start`
      // within the section).  COFF cannot express `sym1 - sym2` directly,
      // but this form is semantically a self-relative reloc once we shift
      // the reference point from `owning_label` to the relocation site.
      //
      // Rewrite: source_label_addr + source_offset == reloc_addr + new_offset
      //          new_offset = (start + source_offset) - reloc_addr
      // After this rewrite the standard kSelfRelative codepath handles it.
      if (owning_label > 0 && translated.source_label == owning_label) {
        translated.source_offset =
            start + translated.source_offset - translated.section_offset;
        translated.source_label = R::kSelfRelative;
      }
      // Same normalization for target_label == owning_label (rare: e.g.
      // `(.) - other_label` form).
      if (owning_label > 0 && translated.target_label == owning_label) {
        translated.target_offset =
            start + translated.target_offset - translated.section_offset;
        translated.target_label = R::kSelfRelative;
      }
      TranslateAndApply(section, translated);
    }
  }
  return start;
}

// -----------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------

void CoffWriter::AddText(const char* name,
                         intptr_t label,
                         const uint8_t* bytes,
                         intptr_t size,
                         const SharedObjectWriter::RelocationArray* relocations,
                         const SharedObjectWriter::SymbolDataArray* symbols) {
  // First text portion creates the section. 64-byte alignment matches
  // ImageWriter::kTextAlignment (= kObjectStartAlignment); the runtime's
  // VerifyAlignment refuses to load a snapshot whose instructions image is
  // not aligned to kObjectStartAlignment (64).
  GetOrCreateSection(kSecText, ".text",
                     coff::PE_SCN_CNT_CODE | coff::PE_SCN_MEM_EXECUTE |
                         coff::PE_SCN_MEM_READ | coff::PE_SCN_ALIGN_64BYTES,
                     /*alignment_log2=*/6, /*is_bss=*/false);

  // Pad to 64-byte alignment before each text portion so _kDartSnapshotText
  // lands on an object-start boundary. Use 0xCC (int3) as the padding byte so
  // any accidental jump into the gap fails fast.
  PadToAlignment(by_kind_[kSecText], kObjectStartAlignment, 0xCC);

  const intptr_t offset = AppendToSection(kSecText, bytes, size, relocations,
                                          /*owning_label=*/label);

  TextPortion portion;
  portion.symbol_name = name;
  portion.label = label;
  portion.offset_in_text = offset;
  portion.size = size;
  text_portions_.Add(portion);

  // The Code/Stub container symbol itself. This is the headline label
  // (_kDartSnapshotText) that other code resolves against, so it has to be in
  // the symbol table.
  if (name != nullptr) {
    AddExternalSymbol(name, label, kTextSectionNumber, /*value=*/offset);
  }

  if (symbols != nullptr) {
    for (const auto& s : *symbols) {
      AddStaticSymbol(s.name, s.label, kTextSectionNumber,
                      /*value=*/offset + s.offset);
    }
  }
}

void CoffWriter::AddROData(
    const char* name,
    intptr_t label,
    const uint8_t* bytes,
    intptr_t size,
    const SharedObjectWriter::RelocationArray* relocations,
    const SharedObjectWriter::SymbolDataArray* symbols) {
  GetOrCreateSection(kSecRData, ".rdata",
                     coff::PE_SCN_CNT_INITIALIZED_DATA | coff::PE_SCN_MEM_READ |
                         coff::PE_SCN_ALIGN_64BYTES,
                     /*alignment_log2=*/6, /*is_bss=*/false);

  // Match ImageWriter::kRODataAlignment (= kObjectStartAlignment = 64) so
  // each snapshot-data blob's headline symbol falls on an object-start
  // boundary, satisfying ImageReader::VerifyAlignment.
  PadToAlignment(by_kind_[kSecRData], kObjectStartAlignment, 0x00);

  const intptr_t offset = AppendToSection(kSecRData, bytes, size, relocations,
                                          /*owning_label=*/label);

  if (name != nullptr) {
    AddExternalSymbol(name, label, kRDataSectionNumber, /*value=*/offset);
  }
  if (symbols != nullptr) {
    for (const auto& s : *symbols) {
      AddStaticSymbol(s.name, s.label, kRDataSectionNumber,
                      /*value=*/offset + s.offset);
    }
  }
}

// -----------------------------------------------------------------------------
// Relocation translation
// -----------------------------------------------------------------------------

void CoffWriter::TranslateAndApply(
    Section* section,
    const SharedObjectWriter::Relocation& reloc) {
  using R = SharedObjectWriter::Relocation;

  intptr_t target_label = reloc.target_label;
  const intptr_t source_label = reloc.source_label;
  const intptr_t target_offset = reloc.target_offset;
  const intptr_t source_offset = reloc.source_offset;
  const size_t size_in_bytes = reloc.size_in_bytes;
  const intptr_t inline_offset = reloc.section_offset;

  ASSERT(size_in_bytes == 4 || size_in_bytes == 8);

  auto write_inline = [&](int64_t value) {
    const intptr_t end = section->data.Position();
    ASSERT(inline_offset + static_cast<intptr_t>(size_in_bytes) <= end);
    section->data.SetPosition(inline_offset);
    section->data.bytes(&value, size_in_bytes);
    section->data.SetPosition(end);
  };

  auto emit_reloc = [&](uint16_t type) {
    Reloc r;
    r.virtual_address = static_cast<uint32_t>(inline_offset);
    r.symbol_label = target_label;
    r.type = type;
    section->relocs->Add(r);
  };

  // Both sides are constants (snapshot-absolute). Just bake the difference.
  if (source_label == R::kSnapshotRelative &&
      target_label == R::kSnapshotRelative) {
    write_inline(static_cast<int64_t>(target_offset - source_offset));
    return;
  }

  // Self-relative both -- difference is independent of layout.
  if (source_label == R::kSelfRelative && target_label == R::kSelfRelative) {
    write_inline(static_cast<int64_t>(target_offset - source_offset));
    return;
  }

  if (target_label == kBuildIdLabel &&
      !label_to_symbol_index_.HasKey(kBuildIdLabel)) {
    write_inline(0);
    return;
  }

  // Relocation value is relocated address of the target plus an offset.
  if (source_label == R::kSnapshotRelative) {
    // Special-case kBuildIdLabel during stripped builds: emit the sentinel.
    // (Image::kNoRelocatedAddress is private to Image; its value is 0.)
    int64_t addend = static_cast<int64_t>(target_offset - source_offset);
    if (target_label == R::kSelfRelative) {
      target_label = kSelfSectionSymbolLabel;
      addend += inline_offset;
    }
    ASSERT(target_label > 0 || target_label == kSelfSectionSymbolLabel);
    write_inline(addend);
    if (size_in_bytes == 8) {
      emit_reloc(coff::PE_REL_AMD64_ADDR64);
    } else {
      emit_reloc(coff::PE_REL_AMD64_ADDR32);
    }
    return;
  }

  // Relocation value is a relative offset to the target from the current
  // address.
  if (source_label == R::kSelfRelative && target_label > 0) {
    // COFF REL32 computes:  inline + sym - (reloc_addr + 4)
    // Dart   semantics:     target_offset + sym - source_offset - reloc_addr
    // So:    inline = target_offset - source_offset + 4
    int64_t addend = static_cast<int64_t>(target_offset - source_offset + 4);
    if (size_in_bytes == 8) {
      // COFF x64 has no 64-bit PC-relative relocation. The linker patches the
      // low 32 bits, so the encoded addend must fit in signed 32 bits and the
      // upper 32 bits stay zero for snapshot-internal positive offsets.
      RELEASE_ASSERT(Utils::IsInt(32, addend));
      addend &= 0xffffffff;
    }
    write_inline(addend);
    emit_reloc(coff::PE_REL_AMD64_REL32);
    return;
  }

  // Less common: label - constant.  We can still resolve if the label is
  // self-relative (PC-relative) and target is a constant.  Bake target_offset
  // - source PC.  But we don't know PC at write time, so emit relocation form.
  if (source_label > 0 && target_label == R::kSnapshotRelative) {
    // ADDR64(-source).  COFF: inline + sym.  Dart: target_offset - sym -
    // source_offset.  So:  inline = target_offset - source_offset, then we
    // need to negate the symbol contribution -- which COFF cannot do.
    FATAL("CoffWriter: unsupported relocation form (label - snapshot)");
  }

  if (source_label > 0 && target_label > 0) {
    FATAL("CoffWriter: unsupported relocation form (label - label)");
  }

  FATAL("CoffWriter: unhandled relocation (src=%" Pd ", tgt=%" Pd ")",
        source_label, target_label);
}

// -----------------------------------------------------------------------------
// Symbol helpers
// -----------------------------------------------------------------------------

intptr_t CoffWriter::AddExternalSymbol(const char* name,
                                       intptr_t label,
                                       int16_t section_number,
                                       int32_t value) {
  CoffSym sym;
  sym.name = name;
  sym.value = value;
  sym.section_number = section_number;  // patched at AssignSectionNumbers
  sym.type = coff::PE_SYM_TYPE_NULL;
  sym.storage_class = coff::PE_SYM_CLASS_EXTERNAL;
  sym.label = label;
  symbols_->Add(sym);
  const intptr_t index = symbols_->length();  // 1-based when read at write time
  if (label != 0) {
    label_to_symbol_index_.Insert(label, index);
  }
  return index;
}

intptr_t CoffWriter::AddStaticSymbol(const char* name,
                                     intptr_t label,
                                     int16_t section_number,
                                     int32_t value) {
  CoffSym sym;
  sym.name = DisambiguateStaticSymbolName(name);
  sym.value = value;
  sym.section_number = section_number;
  sym.type = coff::PE_SYM_TYPE_NULL;
  sym.storage_class = coff::PE_SYM_CLASS_STATIC;
  sym.label = label;
  symbols_->Add(sym);
  const intptr_t index = symbols_->length();
  if (label != 0) {
    label_to_symbol_index_.Insert(label, index);
  }
  return index;
}

const char* CoffWriter::DisambiguateStaticSymbolName(const char* name) {
  if (name == nullptr) {
    return nullptr;
  }
  auto* const pair = static_symbol_usage_count_.Lookup(name);
  if (pair == nullptr) {
    static_symbol_usage_count_.Insert({name, 1});
    return name;
  }
  return OS::SCreate(zone_, "%s (#%" Pd ")", name, ++pair->value);
}

intptr_t CoffWriter::SymbolIndexForLabel(intptr_t label) const {
  ASSERT(label != 0);
  ASSERT(label_to_symbol_index_.HasKey(label));
  return label_to_symbol_index_.Lookup(label);
}

intptr_t CoffWriter::SymbolIndexForLabelOrZero(intptr_t label) {
  if (label_to_symbol_index_.HasKey(label)) {
    return label_to_symbol_index_.Lookup(label);
  }
  return 0;
}

void CoffWriter::CreateSectionSymbol(Section* section) {
  ASSERT(section->section_number != 0);
  CoffSym sym;
  sym.value = 0;
  sym.section_number = static_cast<int16_t>(section->section_number);
  sym.type = coff::PE_SYM_TYPE_NULL;
  sym.storage_class = coff::PE_SYM_CLASS_STATIC;
  sym.num_aux = 1;
  sym.name = OS::SCreate(zone_, "%s", section->name);
  // Auxiliary record holds section data.
  sym.aux = new (zone_) ZoneGrowableArray<uint8_t>(zone_, 18);
  coff::ImageAuxSymbolSection aux = {};
  aux.Length = section->is_bss
                   ? static_cast<uint32_t>(section->bss_size)
                   : static_cast<uint32_t>(section->data.bytes_written());
  aux.NumberOfRelocations = EncodedRelocationCount(section->relocs->length());
  aux.NumberOfLinenumbers = 0;
  aux.CheckSum = 0;
  aux.Number = static_cast<int16_t>(section->section_number);
  aux.Selection = 0;
  for (size_t i = 0; i < sizeof(aux); i++) {
    sym.aux->Add(reinterpret_cast<uint8_t*>(&aux)[i]);
  }
  symbols_->Add(sym);
  section->section_symbol = symbols_->length();
}

// -----------------------------------------------------------------------------
// BSS sections (mirror ElfWriter::CreateBSS)
// -----------------------------------------------------------------------------

void CoffWriter::EmitBssSections() {
  if (text_portions_.is_empty()) return;

  Section* const bss = GetOrCreateSection(
      kSecBss, ".bss",
      coff::PE_SCN_CNT_UNINITIALIZED_DATA | coff::PE_SCN_MEM_READ |
          coff::PE_SCN_MEM_WRITE | coff::PE_SCN_ALIGN_16BYTES,
      /*alignment_log2=*/4, /*is_bss=*/true);
  AddStaticSymbol(kSnapshotBssAsmSymbol, kIsolateBssLabel, kBssSectionNumber,
                  /*value=*/0);
  bss->bss_size = BSS::kIsolateGroupEntryCount * compiler::target::kWordSize;
}

// -----------------------------------------------------------------------------
// SEH .pdata / .xdata
// -----------------------------------------------------------------------------

void CoffWriter::EmitUnwindData() {
  Section* const text = by_kind_[kSecText];
  if (text == nullptr) return;

  Section* const pdata =
      GetOrCreateSection(kSecPdata, ".pdata",
                         coff::PE_SCN_CNT_INITIALIZED_DATA |
                             coff::PE_SCN_MEM_READ | coff::PE_SCN_ALIGN_4BYTES,
                         /*alignment_log2=*/2, /*is_bss=*/false);
  Section* const xdata =
      GetOrCreateSection(kSecXdata, ".xdata",
                         coff::PE_SCN_CNT_INITIALIZED_DATA |
                             coff::PE_SCN_MEM_READ | coff::PE_SCN_ALIGN_4BYTES,
                         /*alignment_log2=*/2, /*is_bss=*/false);

  auto read_u32 = [](const DebugInfoStream* in, intptr_t offset) -> uint32_t {
    return LoadUnaligned(
        reinterpret_cast<const uint32_t*>(in->buffer() + offset));
  };

  auto parse_standard_prologue = [&](uint32_t begin,
                                     ParsedUnwindPrologue* prologue) -> bool {
    const intptr_t length = text->data.Position();
    if (begin + 4 > static_cast<uint32_t>(length)) return false;
    if (text->data.LoadU1(begin) != 0x55 ||  // push rbp
        text->data.LoadU1(begin + 1) != 0x48 ||
        text->data.LoadU1(begin + 2) != 0x89 ||
        text->data.LoadU1(begin + 3) != 0xe5) {  // mov rbp, rsp
      return false;
    }

    uint32_t cursor = begin + 4;
    uint32_t stack_size = 0;
    if (cursor + 4 <= static_cast<uint32_t>(length) &&
        text->data.LoadU1(cursor) == 0x48 &&
        text->data.LoadU1(cursor + 1) == 0x83 &&
        text->data.LoadU1(cursor + 2) == 0xec) {
      stack_size = text->data.LoadU1(cursor + 3);
      cursor += 4;
    } else if (cursor + 7 <= static_cast<uint32_t>(length) &&
               text->data.LoadU1(cursor) == 0x48 &&
               text->data.LoadU1(cursor + 1) == 0x81 &&
               text->data.LoadU1(cursor + 2) == 0xec) {
      stack_size = read_u32(&text->data, cursor + 3);
      cursor += 7;
    }

    if ((stack_size % 8) != 0) return false;
    prologue->stack_size = stack_size;
    prologue->prologue_size = static_cast<uint8_t>(cursor - begin);
    return true;
  };

  auto has_standard_epilogue = [&](uint32_t begin, uint32_t end) -> bool {
    const uint32_t length = static_cast<uint32_t>(text->data.Position());
    end = Utils::Minimum<uint32_t>(end, length);
    if (end <= begin) return false;

    for (uint32_t cursor = begin; cursor + 4 <= end; cursor++) {
      if (text->data.LoadU1(cursor + 0) != 0x48 ||
          text->data.LoadU1(cursor + 1) != 0x89 ||
          text->data.LoadU1(cursor + 2) != 0xec ||
          text->data.LoadU1(cursor + 3) != 0x5d) {
        continue;
      }
      if (cursor + 4 >= end) return false;
      switch (text->data.LoadU1(cursor + 4)) {
        case 0xc3:  // ret
        case 0xe9:  // jmp rel32
        case 0xeb:  // jmp rel8
        case 0xff:  // jmp r/m64
          return true;
        default:
          break;
      }
    }
    return false;
  };

  ZoneGrowableArray<FunctionUnwindRange> functions(zone_, 128);
  auto add_function = [&](uint32_t begin, uint32_t size) {
    if (size == 0 || begin >= static_cast<uint32_t>(text->data.Position())) {
      return;
    }
    FunctionUnwindRange range;
    range.begin = begin;
    range.end = Utils::Minimum<uint32_t>(
        begin + size, static_cast<uint32_t>(text->data.Position()));
    if (range.end <= range.begin) return;
    if (!parse_standard_prologue(range.begin, &range.prologue)) return;
    if (!has_standard_epilogue(range.begin, range.end)) return;
    for (intptr_t i = 0; i < functions.length(); i++) {
      if (functions[i].begin == range.begin) return;
    }
    functions.Add(range);
  };

  if (dwarf() != nullptr && symbols_ != nullptr) {
    const auto& codes = dwarf()->codes();
    for (intptr_t i = 0; i < codes.length(); i++) {
      const Code& code = *(codes[i]);
      const intptr_t label = dwarf()->LookupCodeLabel(code);
      if (label <= 0 || !label_to_symbol_index_.HasKey(label)) continue;
      const intptr_t sym_idx = label_to_symbol_index_.Lookup(label);
      ASSERT(sym_idx > 0 && sym_idx <= symbols_->length());
      const auto& sym = (*symbols_)[sym_idx - 1];
      ASSERT(sym.section_number == kTextSectionNumber);
      add_function(static_cast<uint32_t>(sym.value),
                   static_cast<uint32_t>(code.Size()));
    }
  }

  if (functions.length() == 0) return;
  functions.Sort(CompareFunctionUnwindRange);

  auto append_unwind_code = [&](uint8_t code_offset, uint8_t unwind_op,
                                uint8_t op_info) {
    xdata->data.u1(code_offset);
    xdata->data.u1(static_cast<uint8_t>((op_info << 4) | (unwind_op & 0x0f)));
  };

  auto emit_unwind_info =
      [&](const ParsedUnwindPrologue& prologue) -> uint32_t {
    const uint32_t xdata_offset = static_cast<uint32_t>(xdata->data.Position());
    xdata->data.u1(coff::kUnwindVersion);
    xdata->data.u1(prologue.prologue_size);
    const intptr_t code_count_offset = xdata->data.Position();
    xdata->data.u1(0);              // CountOfCodes, patched below.
    xdata->data.u1(coff::kRegRbp);  // FrameRegister=RBP.

    uint8_t code_count = 0;
    if (prologue.stack_size > 0) {
      const uint32_t stack_size_words = prologue.stack_size / 8;
      if (Utils::IsUint(4, stack_size_words - 1)) {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_SMALL,
                           static_cast<uint8_t>(stack_size_words - 1));
        code_count += 1;
      } else if (Utils::IsUint(16, stack_size_words)) {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_LARGE, 0);
        xdata->data.u2(static_cast<uint16_t>(stack_size_words));
        code_count += 2;
      } else {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_LARGE, 1);
        xdata->data.u4(prologue.stack_size);
        code_count += 3;
      }
    }
    append_unwind_code(4, coff::UWOP_SET_FPREG, 0);
    code_count += 1;
    append_unwind_code(1, coff::UWOP_PUSH_NONVOL, coff::kRegRbp);
    code_count += 1;

    xdata->data.StoreU1(code_count_offset, code_count);
    xdata->data.Align(4);
    return xdata_offset;
  };

  ZoneGrowableArray<SharedUnwindInfo> shared_unwind_infos(zone_, 16);
  auto unwind_info_for = [&](const ParsedUnwindPrologue& prologue) -> uint32_t {
    for (intptr_t i = 0; i < shared_unwind_infos.length(); i++) {
      const SharedUnwindInfo& shared = shared_unwind_infos[i];
      if (shared.prologue.stack_size == prologue.stack_size &&
          shared.prologue.prologue_size == prologue.prologue_size) {
        return shared.xdata_offset;
      }
    }

    SharedUnwindInfo shared;
    shared.prologue = prologue;
    shared.xdata_offset = emit_unwind_info(prologue);
    shared_unwind_infos.Add(shared);
    return shared.xdata_offset;
  };

  auto u4_with_reloc = [](Section* section, intptr_t label, uint16_t type,
                          uint32_t value) {
    const intptr_t offset = section->data.Position();
    section->relocs->Add({static_cast<uint32_t>(offset), label, type});
    section->data.u4(value);
  };

  for (intptr_t i = 0; i < functions.length(); i++) {
    const FunctionUnwindRange& fn = functions[i];
    const uint32_t xdata_offset = unwind_info_for(fn.prologue);
    u4_with_reloc(pdata, kTextSectionSymbolLabel, coff::PE_REL_AMD64_ADDR32NB,
                  fn.begin);
    u4_with_reloc(pdata, kTextSectionSymbolLabel, coff::PE_REL_AMD64_ADDR32NB,
                  fn.end);
    u4_with_reloc(pdata, kXdataSectionSymbolLabel, coff::PE_REL_AMD64_ADDR32NB,
                  xdata_offset);
  }
}

// -----------------------------------------------------------------------------
// .drectve
// -----------------------------------------------------------------------------

void CoffWriter::EmitDrectve() {
  if (type_ != Type::Snapshot) return;
  Section* const dr =
      GetOrCreateSection(kSecDrectve, ".drectve",
                         coff::PE_SCN_LNK_INFO | coff::PE_SCN_LNK_REMOVE |
                             coff::PE_SCN_ALIGN_1BYTES,
                         /*alignment_log2=*/0, /*is_bss=*/false);

  // Export the snapshot data symbols directly. GetProcAddress can resolve data
  // exports, so no getter thunks are needed.
  const char* const directives = " /EXPORT:" kSnapshotDataCSymbol
                                 ",DATA"
                                 " /EXPORT:" kSnapshotTextCSymbol ",DATA";
  const intptr_t len = strlen(directives);
  dr->data.bytes(directives, len);
}

// -----------------------------------------------------------------------------
// CodeView (Phase 7)
// -----------------------------------------------------------------------------

void CoffWriter::EmitCodeView() {
  if (dwarf_ == nullptr) return;
  Section* const debug_s = GetOrCreateSection(
      kSecDebugS, ".debug$S",
      coff::PE_SCN_CNT_INITIALIZED_DATA | coff::PE_SCN_MEM_READ |
          coff::PE_SCN_MEM_DISCARDABLE | coff::PE_SCN_ALIGN_1BYTES,
      /*alignment_log2=*/0, /*is_bss=*/false);
  Section* const debug_t = GetOrCreateSection(
      kSecDebugT, ".debug$T",
      coff::PE_SCN_CNT_INITIALIZED_DATA | coff::PE_SCN_MEM_READ |
          coff::PE_SCN_MEM_DISCARDABLE | coff::PE_SCN_ALIGN_1BYTES,
      /*alignment_log2=*/0, /*is_bss=*/false);
  codeview_ =
      new (zone_) CodeViewBuilder(zone_, this, &debug_s->data, &debug_t->data);
  codeview_->Build();
}

// -----------------------------------------------------------------------------
// Section number / section symbol assignment
// -----------------------------------------------------------------------------

void CoffWriter::AssignSectionNumbersAndSymbols() {
  // Section numbers are 1-based.  Patch all symbols that referenced a section
  // via the negative-sentinel scheme.
  for (intptr_t i = 0; i < all_sections_.length(); i++) {
    all_sections_[i]->section_number = i + 1;
  }
  Section* text = by_kind_[kSecText];
  Section* rdata = by_kind_[kSecRData];
  Section* bss = by_kind_[kSecBss];

  for (intptr_t i = 0; i < symbols_->length(); i++) {
    auto& s = (*symbols_)[i];
    if (s.section_number == kTextSectionNumber && text != nullptr) {
      s.section_number = static_cast<int16_t>(text->section_number);
    } else if (s.section_number == kRDataSectionNumber && rdata != nullptr) {
      s.section_number = static_cast<int16_t>(rdata->section_number);
    } else if (s.section_number == kBssSectionNumber && bss != nullptr) {
      s.section_number = static_cast<int16_t>(bss->section_number);
    }
  }

  // Create section symbols and append them to the symbol table.
  for (intptr_t i = 0; i < all_sections_.length(); i++) {
    CreateSectionSymbol(all_sections_[i]);
  }

  // Resolve sentinel section labels used inside our own emitters by inserting
  // them into the label map after section symbols are created.
  if (by_kind_[kSecText] != nullptr) {
    label_to_symbol_index_.Insert(kTextSectionSymbolLabel,
                                  by_kind_[kSecText]->section_symbol);
  }
  if (by_kind_[kSecXdata] != nullptr) {
    label_to_symbol_index_.Insert(kXdataSectionSymbolLabel,
                                  by_kind_[kSecXdata]->section_symbol);
  }
}

// -----------------------------------------------------------------------------
// Layout + write
// -----------------------------------------------------------------------------

void CoffWriter::ComputeLayoutAndWrite() {
  // Compute file offsets:
  //  file_header
  //  section_headers[]
  //  per section: raw data (if !is_bss), then relocations
  //  symbol_table
  //  string_table
  const intptr_t num_sections = all_sections_.length();
  intptr_t cursor = sizeof(coff::ImageFileHeader) +
                    num_sections * sizeof(coff::ImageSectionHeader);

  for (auto* s : all_sections_) {
    if (!s->is_bss) {
      // Section raw data alignment within the file is 4 (LLVM convention).
      cursor = Utils::RoundUp(cursor, 4);
      s->raw_data_offset = cursor;
      cursor += s->data.bytes_written();
    } else {
      s->raw_data_offset = 0;
    }
    if (s->relocs->length() > 0) {
      cursor = Utils::RoundUp(cursor, 4);
      s->reloc_offset = cursor;
      cursor += RelocationRecordCountOnDisk(s->relocs->length()) *
                sizeof(coff::ImageRelocation);
    } else {
      s->reloc_offset = 0;
    }
  }

  cursor = Utils::RoundUp(cursor, 4);
  const intptr_t symtab_offset = cursor;
  // Each symbol entry (and each aux entry) is 18 bytes.
  intptr_t symbol_count = 0;
  // parent1_to_disk0[i] gives the 0-based on-disk symbol-table index for the
  // symbol stored at parent-only index i (0-based) in symbols_.  Values tracked
  // elsewhere (label_to_symbol_index_ entries, Section::section_symbol)
  // are 1-based parent-only indices; convert via parent1_to_disk0[v - 1] when
  // writing a SymbolTableIndex into a relocation.  The two diverge whenever a
  // symbol with num_aux>0 (i.e. our section symbols) precedes the lookup.
  ZoneGrowableArray<uint32_t> parent1_to_disk0(zone_, symbols_->length());
  for (intptr_t i = 0; i < symbols_->length(); i++) {
    parent1_to_disk0.Add(static_cast<uint32_t>(symbol_count));
    symbol_count += 1 + (*symbols_)[i].num_aux;
  }
  cursor += symbol_count * 18;
  auto disk_index_of = [&](intptr_t parent1) -> uint32_t {
    ASSERT(parent1 >= 1 && parent1 <= symbols_->length());
    return parent1_to_disk0[parent1 - 1];
  };
  // String table begins immediately after symbol table; size prefix is
  // included in the size word itself.

  // --- Write file header ---
  coff::ImageFileHeader fh = {};
  fh.Machine = coff::PE_FILE_MACHINE_AMD64;
  fh.NumberOfSections = static_cast<uint16_t>(num_sections);
  fh.TimeDateStamp = 0;
  fh.PointerToSymbolTable = static_cast<uint32_t>(symtab_offset);
  fh.NumberOfSymbols = static_cast<uint32_t>(symbol_count);
  fh.SizeOfOptionalHeader = 0;
  fh.Characteristics = coff::PE_FILE_LARGE_ADDRESS_AWARE;
  unwrapped_stream_->WriteBytes(&fh, sizeof(fh));

  // --- Write section headers ---
  for (auto* s : all_sections_) {
    coff::ImageSectionHeader sh = {};
    for (intptr_t i = 0; i < 8; i++) {
      sh.Name[i] = s->name[i];
    }
    sh.VirtualSize = 0;
    sh.VirtualAddress = 0;
    if (s->is_bss) {
      sh.SizeOfRawData = static_cast<uint32_t>(s->bss_size);
      sh.PointerToRawData = 0;
    } else {
      sh.SizeOfRawData = static_cast<uint32_t>(s->data.bytes_written());
      sh.PointerToRawData = static_cast<uint32_t>(s->raw_data_offset);
    }
    sh.PointerToRelocations = static_cast<uint32_t>(s->reloc_offset);
    sh.PointerToLinenumbers = 0;
    const bool has_relocation_overflow =
        UsesRelocationCountOverflow(s->relocs->length());
    sh.NumberOfRelocations = EncodedRelocationCount(s->relocs->length());
    sh.NumberOfLinenumbers = 0;
    sh.Characteristics = s->characteristics;
    if (has_relocation_overflow) {
      sh.Characteristics |= coff::PE_SCN_LNK_NRELOC_OVFL;
    }
    unwrapped_stream_->WriteBytes(&sh, sizeof(sh));
  }

  // --- Write each section's body + reloc table ---
  intptr_t written = unwrapped_stream_->Position();
  for (auto* s : all_sections_) {
    if (!s->is_bss) {
      unwrapped_stream_->Align(4);
      written = unwrapped_stream_->Position();
      ASSERT(written == s->raw_data_offset);
      unwrapped_stream_->WriteBytes(s->data.buffer(), s->data.bytes_written());
      written += s->data.bytes_written();
    }
    if (s->relocs->length() > 0) {
      unwrapped_stream_->Align(4);
      written = unwrapped_stream_->Position();
      ASSERT(written == s->reloc_offset);
      if (UsesRelocationCountOverflow(s->relocs->length())) {
        coff::ImageRelocation overflow = {};
        // The overflow count includes this synthetic relocation itself. COFF
        // readers skip it and expose VirtualAddress - 1 real relocations.
        ASSERT(s->relocs->length() <= static_cast<intptr_t>(kMaxUint32) - 1);
        overflow.VirtualAddress =
            static_cast<uint32_t>(s->relocs->length() + 1);
        unwrapped_stream_->WriteBytes(&overflow, sizeof(overflow));
        written += sizeof(overflow);
      }
      for (const auto& r : *s->relocs) {
        coff::ImageRelocation cr;
        cr.VirtualAddress = r.virtual_address;
        // Special sentinel: kSelfSectionSymbolLabel means "the section symbol
        // for the section this relocation lives in".  Used by snapshot-
        // relative-to-self relocs that need to reference their own section
        // without knowing its index at AppendToSection time.
        if (r.symbol_label == kSelfSectionSymbolLabel) {
          cr.SymbolTableIndex = disk_index_of(s->section_symbol);
        } else {
          cr.SymbolTableIndex =
              disk_index_of(SymbolIndexForLabel(r.symbol_label));
        }
        cr.Type = r.type;
        unwrapped_stream_->WriteBytes(&cr, sizeof(cr));
        written += sizeof(cr);
      }
    }
  }

  // Align before symbol table.
  unwrapped_stream_->Align(4);
  written = unwrapped_stream_->Position();
  ASSERT(written == symtab_offset);

  // --- Write symbol table ---
  for (const auto& s : *symbols_) {
    coff::ImageSymbol is = {};
    const char* name = s.name;
    if (name == nullptr || strlen(name) <= 8) {
      // Inline name in the 8-byte field.
      memset(is.N.ShortName, 0, 8);
      if (name != nullptr) {
        for (intptr_t i = 0; i < 8 && name[i] != '\0'; i++) {
          is.N.ShortName[i] = name[i];
        }
      }
    } else {
      is.N.LongName.Zeroes = 0;
      is.N.LongName.Offset = InternString(name);
    }
    is.Value = s.value;
    is.SectionNumber = s.section_number;
    is.Type = s.type;
    is.StorageClass = s.storage_class;
    is.NumberOfAuxSymbols = s.num_aux;
    unwrapped_stream_->WriteBytes(&is, sizeof(is));
    written += sizeof(is);
    if (s.aux != nullptr) {
      ASSERT(s.aux->length() == 18 * s.num_aux);
      unwrapped_stream_->WriteBytes(&(*s.aux)[0], s.aux->length());
      written += s.aux->length();
    }
  }

  // --- Write string table ---
  uint32_t str_table_size = static_cast<uint32_t>(string_table_->length()) + 4;
  unwrapped_stream_->WriteFixed(str_table_size);
  if (string_table_->length() > 0) {
    unwrapped_stream_->WriteBytes(&(*string_table_)[0],
                                  string_table_->length());
  }
}

// -----------------------------------------------------------------------------
// Finalize
// -----------------------------------------------------------------------------

void CoffWriter::Finalize() {
  EmitBssSections();
  EmitUnwindData();
  EmitDrectve();
  EmitCodeView();

  AssignSectionNumbersAndSymbols();

  // If CodeView builder accumulated relocations that needed the .text section
  // symbol, those got resolved when we inserted the section symbol into the
  // label map.  Nothing else to do here.

  ComputeLayoutAndWrite();
}

}  // namespace dart

#endif  // DART_PRECOMPILER
