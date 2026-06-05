// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/coff.h"

#if defined(DART_PRECOMPILER)

#include "include/dart_api.h"
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
  auto* const section = new (zone_) Section();
  ASSERT(strlen(name) <= 8);
  for (intptr_t i = 0; i < 8 && name[i] != '\0'; i++) {
    section->name[i] = name[i];
  }
  section->characteristics = characteristics;
  section->alignment_log2 = alignment_log2;
  section->is_bss = is_bss;
  if (!is_bss) {
    section->data = new (zone_) ZoneGrowableArray<uint8_t>(zone_, 1024);
  }
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
  const intptr_t cur = section->data->length();
  const intptr_t aligned = Utils::RoundUp(cur, alignment);
  for (intptr_t i = cur; i < aligned; i++) {
    section->data->Add(pad_byte);
  }
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
  const intptr_t start = section->data->length();
  for (intptr_t i = 0; i < size; i++) {
    section->data->Add(bytes[i]);
  }
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
      TranslateAndApply(section, translated.section_offset, translated);
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
    AddExternalSymbol(name, label, /*section_number=*/-1, /*value=*/offset);
  }

  if (symbols != nullptr) {
    for (const auto& s : *symbols) {
      AddStaticSymbol(s.name, s.label, /*section_number=*/-1,
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
    AddExternalSymbol(name, label, /*section_number=*/-2, /*value=*/offset);
  }
  if (symbols != nullptr) {
    for (const auto& s : *symbols) {
      AddStaticSymbol(s.name, s.label, /*section_number=*/-2,
                      /*value=*/offset + s.offset);
    }
  }
}

// -----------------------------------------------------------------------------
// Relocation translation
// -----------------------------------------------------------------------------

void CoffWriter::TranslateAndApply(
    Section* section,
    intptr_t inline_offset,
    const SharedObjectWriter::Relocation& reloc) {
  using R = SharedObjectWriter::Relocation;

  const intptr_t target_label = reloc.target_label;
  const intptr_t source_label = reloc.source_label;
  const intptr_t target_offset = reloc.target_offset;
  const intptr_t source_offset = reloc.source_offset;
  const size_t size_in_bytes = reloc.size_in_bytes;

  ASSERT(size_in_bytes == 4 || size_in_bytes == 8);

  auto write_inline = [&](int64_t value) {
    ASSERT(static_cast<intptr_t>(inline_offset) +
               static_cast<intptr_t>(size_in_bytes) <=
           section->data->length());
    uint8_t* dst = &(*section->data)[inline_offset];
    for (size_t i = 0; i < size_in_bytes; i++) {
      dst[i] = static_cast<uint8_t>(value & 0xff);
      value >>= 8;
    }
  };

  auto emit_reloc = [&](uint16_t type, intptr_t label) {
    Reloc r;
    r.virtual_address = static_cast<uint32_t>(inline_offset);
    r.symbol_label = label;
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

  // Snapshot-relative pointer to "here": to_write = reloc_addr + target_offset
  //   - source_offset.  source is anchored at snapshot-base 0, target at the
  //   current PC.  Express as ADDR64(section_symbol) + addend, where
  //   addend = inline_offset + target_offset - source_offset.  The linker
  //   resolves the section symbol to the section's final RVA, giving:
  //     final = section_RVA + inline_offset + target_offset - source_offset
  //           = reloc_addr + target_offset - source_offset.
  //   This form appears in BSS-back-pointer fields baked into the snapshot
  //   data (the InstructionsTable wrappers around stub regions).
  if (source_label == R::kSnapshotRelative &&
      target_label == R::kSelfRelative) {
    const int64_t addend = static_cast<int64_t>(inline_offset) +
                           static_cast<int64_t>(target_offset) -
                           static_cast<int64_t>(source_offset);
    write_inline(addend);
    if (size_in_bytes == 8) {
      emit_reloc(coff::PE_REL_AMD64_ADDR64, kSelfSectionSymbolLabel);
    } else {
      emit_reloc(coff::PE_REL_AMD64_ADDR32, kSelfSectionSymbolLabel);
    }
    return;
  }

  // Snapshot-absolute pointer to a label (the common ADDR64 case from .rdata).
  if (source_label == R::kSnapshotRelative && target_label > 0) {
    // Special-case kBuildIdLabel during stripped builds: emit the sentinel.
    // (Image::kNoRelocatedAddress is private to Image; its value is 0.)
    if (target_label == kBuildIdLabel &&
        !label_to_symbol_index_.HasKey(kBuildIdLabel)) {
      write_inline(0);
      return;
    }
    write_inline(static_cast<int64_t>(target_offset));
    if (size_in_bytes == 8) {
      emit_reloc(coff::PE_REL_AMD64_ADDR64, target_label);
    } else {
      // ADDR32 (rare in 64-bit Dart snapshots).
      emit_reloc(coff::PE_REL_AMD64_ADDR32, target_label);
    }
    return;
  }

  // PC-relative load/call to a label (the common REL32 case from .text).
  if (source_label == R::kSelfRelative && target_label > 0) {
    // Special-case kBuildIdLabel during stripped builds: the
    // InstructionsSection header's build_id field is emitted as
    //   Relocation(text_offset, instructions_label, kBuildIdLabel)
    // from image_snapshot.cc, and AppendToSection rewrites its
    // source_label (= instructions_label = owning_label) to kSelfRelative,
    // landing it here.  When the build is stripped, kBuildIdLabel has no
    // symbol; the assembly writer emits literal zero (see
    // AssemblyImageWriter::Relocation -> RelocationSymbol fallback) and the
    // runtime treats zero as "no build id".  Match that exactly instead of
    // emitting a REL32 against a non-existent symbol.
    if (target_label == kBuildIdLabel &&
        !label_to_symbol_index_.HasKey(kBuildIdLabel)) {
      write_inline(0);  // zeros all size_in_bytes bytes
      return;
    }
    // COFF REL32 computes:  inline + sym - (reloc_addr + 4)
    // Dart   semantics:     target_offset + sym - source_offset - reloc_addr
    // So:    inline = target_offset - source_offset + 4
    const int64_t addend =
        static_cast<int64_t>(target_offset - source_offset + 4);
    if (size_in_bytes == 4) {
      write_inline(addend);
      emit_reloc(coff::PE_REL_AMD64_REL32, target_label);
      return;
    }
    ASSERT(size_in_bytes == 8);
    // 8-byte (.quad) self-relative pointer.  COFF x64 has no 64-bit PC-
    // relative relocation, so mirror what llvm-mc does for `.quad sym - (.)`:
    // bake the 32-bit REL32 addend in the lower 4 bytes; sign-extend the
    // expected result into the upper 4 bytes.  The linker only patches the
    // lower 4 bytes; the upper 4 bytes are static.  Correct iff the runtime
    // 64-bit value fits in signed 32 bits, which holds for snapshot-internal
    // text->bss / text->build_id pointers (image size << 2^31).  Dart's
    // snapshot layout places .bss after .text, so the runtime diff is non-
    // negative; bake 0 in the upper bytes.
    uint8_t* dst = &(*section->data)[inline_offset];
    const uint32_t low32 = static_cast<uint32_t>(static_cast<int32_t>(addend));
    for (int i = 0; i < 4; i++)
      dst[i] = (low32 >> (8 * i)) & 0xff;
    for (int i = 4; i < 8; i++)
      dst[i] = 0;
    emit_reloc(coff::PE_REL_AMD64_REL32, target_label);
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
  // Capture the original section name for the inline ShortName field.
  // We store it in `name` and only inline if <= 8 chars.
  sym.name = Utils::StrDup(section->name);
  // Auxiliary record holds section data.
  sym.aux = new (zone_) ZoneGrowableArray<uint8_t>(zone_, 18);
  coff::ImageAuxSymbolSection aux = {};
  aux.Length = section->is_bss ? static_cast<uint32_t>(section->bss_size)
                               : static_cast<uint32_t>(section->data->length());
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
  // ElfWriter creates BSS based on the kSnapshotTextAsmSymbol portion in .text.
  // We do the same.
  bool need_section = false;
  for (const auto& p : text_portions_) {
    if (p.symbol_name == nullptr) continue;
    if (strcmp(p.symbol_name, kSnapshotTextAsmSymbol) == 0) {
      need_section = true;
      break;
    }
  }
  if (!need_section) return;

  Section* const bss = GetOrCreateSection(
      kSecBss, ".bss",
      coff::PE_SCN_CNT_UNINITIALIZED_DATA | coff::PE_SCN_MEM_READ |
          coff::PE_SCN_MEM_WRITE | coff::PE_SCN_ALIGN_16BYTES,
      /*alignment_log2=*/4, /*is_bss=*/true);

  intptr_t offset = 0;
  for (const auto& p : text_portions_) {
    if (p.symbol_name == nullptr) continue;
    const char* bss_symbol = nullptr;
    intptr_t bss_label = 0;
    intptr_t bss_size = 0;
    if (strcmp(p.symbol_name, kSnapshotTextAsmSymbol) == 0) {
      bss_symbol = kSnapshotBssAsmSymbol;
      bss_label = kIsolateBssLabel;
      bss_size = BSS::kIsolateGroupEntryCount * compiler::target::kWordSize;
    } else {
      continue;
    }
    AddStaticSymbol(bss_symbol, bss_label, /*section_number=*/-3, offset);
    offset += bss_size;
  }
  bss->bss_size = offset;
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

  constexpr intptr_t kTextSectionLabel = -10;
  constexpr intptr_t kXdataSectionLabel = -11;

  auto append_byte = [](ZoneGrowableArray<uint8_t>* out, uint8_t v) {
    out->Add(v);
  };
  auto append_u16 = [](ZoneGrowableArray<uint8_t>* out, uint16_t v) {
    out->Add(static_cast<uint8_t>(v & 0xff));
    out->Add(static_cast<uint8_t>((v >> 8) & 0xff));
  };
  auto append_u32 = [](ZoneGrowableArray<uint8_t>* out, uint32_t v) {
    out->Add(static_cast<uint8_t>(v & 0xff));
    out->Add(static_cast<uint8_t>((v >> 8) & 0xff));
    out->Add(static_cast<uint8_t>((v >> 16) & 0xff));
    out->Add(static_cast<uint8_t>((v >> 24) & 0xff));
  };
  auto patch_u32 = [](ZoneGrowableArray<uint8_t>* out, intptr_t offset,
                      uint32_t v) {
    (*out)[offset + 0] = static_cast<uint8_t>(v & 0xff);
    (*out)[offset + 1] = static_cast<uint8_t>((v >> 8) & 0xff);
    (*out)[offset + 2] = static_cast<uint8_t>((v >> 16) & 0xff);
    (*out)[offset + 3] = static_cast<uint8_t>((v >> 24) & 0xff);
  };
  auto read_u32 = [](const ZoneGrowableArray<uint8_t>* in,
                     intptr_t offset) -> uint32_t {
    return static_cast<uint32_t>((*in)[offset + 0]) |
           (static_cast<uint32_t>((*in)[offset + 1]) << 8) |
           (static_cast<uint32_t>((*in)[offset + 2]) << 16) |
           (static_cast<uint32_t>((*in)[offset + 3]) << 24);
  };

  auto parse_standard_prologue = [&](uint32_t begin,
                                     ParsedUnwindPrologue* prologue) -> bool {
    const intptr_t length = text->data->length();
    if (begin + 4 > static_cast<uint32_t>(length)) return false;
    if ((*text->data)[begin] != 0x55 ||  // push rbp
        (*text->data)[begin + 1] != 0x48 || (*text->data)[begin + 2] != 0x89 ||
        (*text->data)[begin + 3] != 0xe5) {  // mov rbp, rsp
      return false;
    }

    uint32_t cursor = begin + 4;
    uint32_t stack_size = 0;
    if (cursor + 4 <= static_cast<uint32_t>(length) &&
        (*text->data)[cursor] == 0x48 && (*text->data)[cursor + 1] == 0x83 &&
        (*text->data)[cursor + 2] == 0xec) {
      stack_size = (*text->data)[cursor + 3];
      cursor += 4;
    } else if (cursor + 7 <= static_cast<uint32_t>(length) &&
               (*text->data)[cursor] == 0x48 &&
               (*text->data)[cursor + 1] == 0x81 &&
               (*text->data)[cursor + 2] == 0xec) {
      stack_size = read_u32(text->data, cursor + 3);
      cursor += 7;
    }

    if ((stack_size % 8) != 0) return false;
    prologue->stack_size = stack_size;
    prologue->prologue_size = static_cast<uint8_t>(cursor - begin);
    return true;
  };

  auto has_standard_epilogue = [&](uint32_t begin, uint32_t end) -> bool {
    const uint32_t length = static_cast<uint32_t>(text->data->length());
    end = Utils::Minimum<uint32_t>(end, length);
    if (end <= begin) return false;

    for (uint32_t cursor = begin; cursor + 4 <= end; cursor++) {
      if ((*text->data)[cursor + 0] != 0x48 ||
          (*text->data)[cursor + 1] != 0x89 ||
          (*text->data)[cursor + 2] != 0xec ||
          (*text->data)[cursor + 3] != 0x5d) {
        continue;
      }
      if (cursor + 4 >= end) return false;
      switch ((*text->data)[cursor + 4]) {
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
    if (size == 0 || begin >= static_cast<uint32_t>(text->data->length())) {
      return;
    }
    FunctionUnwindRange range;
    range.begin = begin;
    range.end = Utils::Minimum<uint32_t>(
        begin + size, static_cast<uint32_t>(text->data->length()));
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
      if (sym_idx <= 0 || sym_idx > symbols_->length()) continue;
      const auto& sym = (*symbols_)[sym_idx - 1];
      if (sym.section_number != -1) continue;
      add_function(static_cast<uint32_t>(sym.value),
                   static_cast<uint32_t>(code.Size()));
    }
  }

  if (functions.length() == 0) return;
  functions.Sort(CompareFunctionUnwindRange);

  auto append_unwind_code = [&](uint8_t code_offset, uint8_t unwind_op,
                                uint8_t op_info) {
    append_byte(xdata->data, code_offset);
    append_byte(xdata->data,
                static_cast<uint8_t>((op_info << 4) | (unwind_op & 0x0f)));
  };

  auto emit_unwind_info =
      [&](const ParsedUnwindPrologue& prologue) -> uint32_t {
    const uint32_t xdata_offset = static_cast<uint32_t>(xdata->data->length());
    const intptr_t header_offset = xdata->data->length();
    append_byte(xdata->data, coff::kUnwindVersion);
    append_byte(xdata->data, prologue.prologue_size);
    append_byte(xdata->data, 0);              // CountOfCodes, patched below.
    append_byte(xdata->data, coff::kRegRbp);  // FrameRegister=RBP.

    uint8_t code_count = 0;
    if (prologue.stack_size > 0) {
      if (prologue.stack_size <= 128) {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_SMALL,
                           static_cast<uint8_t>((prologue.stack_size / 8) - 1));
        code_count += 1;
      } else if (prologue.stack_size <= 512 * 1024 - 8) {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_LARGE, 0);
        append_u16(xdata->data, static_cast<uint16_t>(prologue.stack_size / 8));
        code_count += 2;
      } else {
        append_unwind_code(prologue.prologue_size, coff::UWOP_ALLOC_LARGE, 1);
        append_u32(xdata->data, prologue.stack_size);
        code_count += 3;
      }
    }
    append_unwind_code(4, coff::UWOP_SET_FPREG, 0);
    code_count += 1;
    append_unwind_code(1, coff::UWOP_PUSH_NONVOL, coff::kRegRbp);
    code_count += 1;

    (*xdata->data)[header_offset + 2] = code_count;
    if ((code_count % 2) != 0) {
      append_u16(xdata->data, 0);
    }
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

  for (intptr_t i = 0; i < functions.length(); i++) {
    const FunctionUnwindRange& fn = functions[i];
    const uint32_t xdata_offset = unwind_info_for(fn.prologue);
    const intptr_t rf_offset = pdata->data->length();
    append_u32(pdata->data, fn.begin);
    append_u32(pdata->data, fn.end);
    append_u32(pdata->data, xdata_offset);

    pdata->relocs->Add({static_cast<uint32_t>(rf_offset + 0), kTextSectionLabel,
                        coff::PE_REL_AMD64_ADDR32NB});
    pdata->relocs->Add({static_cast<uint32_t>(rf_offset + 4), kTextSectionLabel,
                        coff::PE_REL_AMD64_ADDR32NB});
    pdata->relocs->Add({static_cast<uint32_t>(rf_offset + 8),
                        kXdataSectionLabel, coff::PE_REL_AMD64_ADDR32NB});

    patch_u32(pdata->data, rf_offset + 0, fn.begin);
    patch_u32(pdata->data, rf_offset + 4, fn.end);
    patch_u32(pdata->data, rf_offset + 8, xdata_offset);
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
  for (intptr_t i = 0; i < len; i++) {
    dr->data->Add(static_cast<uint8_t>(directives[i]));
  }
}

// -----------------------------------------------------------------------------
// CodeView (Phase 7)
// -----------------------------------------------------------------------------

void CoffWriter::EmitCodeView() {
  if (dwarf_ == nullptr) return;
  GetOrCreateSection(kSecDebugS, ".debug$S",
                     coff::PE_SCN_CNT_INITIALIZED_DATA | coff::PE_SCN_MEM_READ |
                         coff::PE_SCN_MEM_DISCARDABLE |
                         coff::PE_SCN_ALIGN_1BYTES,
                     /*alignment_log2=*/0, /*is_bss=*/false);
  GetOrCreateSection(kSecDebugT, ".debug$T",
                     coff::PE_SCN_CNT_INITIALIZED_DATA | coff::PE_SCN_MEM_READ |
                         coff::PE_SCN_MEM_DISCARDABLE |
                         coff::PE_SCN_ALIGN_1BYTES,
                     /*alignment_log2=*/0, /*is_bss=*/false);
  codeview_ = new (zone_) CodeViewBuilder(zone_, this);
  codeview_->Build();
}

// -----------------------------------------------------------------------------
// Section number / section symbol assignment
// -----------------------------------------------------------------------------

void CoffWriter::AssignSectionNumbersAndSymbols() {
  // Section numbers are 1-based.  Patch all symbols that referenced a section
  // via the negative-sentinel scheme:
  //   section_number == -1  ->  .text
  //   section_number == -2  ->  .rdata
  //   section_number == -3  ->  .bss
  for (intptr_t i = 0; i < all_sections_.length(); i++) {
    all_sections_[i]->section_number = i + 1;
  }
  Section* text = by_kind_[kSecText];
  Section* rdata = by_kind_[kSecRData];
  Section* bss = by_kind_[kSecBss];

  for (intptr_t i = 0; i < symbols_->length(); i++) {
    auto& s = (*symbols_)[i];
    if (s.section_number == -1 && text != nullptr) {
      s.section_number = static_cast<int16_t>(text->section_number);
    } else if (s.section_number == -2 && rdata != nullptr) {
      s.section_number = static_cast<int16_t>(rdata->section_number);
    } else if (s.section_number == -3 && bss != nullptr) {
      s.section_number = static_cast<int16_t>(bss->section_number);
    }
  }

  // Create section symbols and append them to the symbol table.
  for (intptr_t i = 0; i < all_sections_.length(); i++) {
    CreateSectionSymbol(all_sections_[i]);
  }

  // Resolve sentinel section labels used inside our own emitters
  // (kTextSectionLabel = -10, kXdataSectionLabel = -11) by inserting them
  // into the label map after section symbols are created.
  if (by_kind_[kSecText] != nullptr) {
    label_to_symbol_index_.Insert(-10, by_kind_[kSecText]->section_symbol);
  }
  if (by_kind_[kSecXdata] != nullptr) {
    label_to_symbol_index_.Insert(-11, by_kind_[kSecXdata]->section_symbol);
  }
  if (by_kind_[kSecText] != nullptr) {
    // CodeViewBuilder references the .text section symbol via label -12.
    label_to_symbol_index_.Insert(-12, by_kind_[kSecText]->section_symbol);
  }
}

// -----------------------------------------------------------------------------
// Layout + write
// -----------------------------------------------------------------------------

namespace {

// Helper: write a value of fixed size little-endian.
template <typename T>
void WriteLE(BaseWriteStream* s, T value) {
  for (size_t i = 0; i < sizeof(T); i++) {
    s->WriteByte(static_cast<uint8_t>(value & 0xff));
    value >>= 8;
  }
}

void WriteBytes(BaseWriteStream* s, const void* p, intptr_t n) {
  s->WriteBytes(p, n);
}

}  // namespace

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
      cursor += s->data->length();
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
  WriteBytes(unwrapped_stream_, &fh, sizeof(fh));

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
      sh.SizeOfRawData = static_cast<uint32_t>(s->data->length());
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
    WriteBytes(unwrapped_stream_, &sh, sizeof(sh));
  }

  // --- Write each section's body + reloc table ---
  intptr_t written = sizeof(coff::ImageFileHeader) +
                     num_sections * sizeof(coff::ImageSectionHeader);
  for (auto* s : all_sections_) {
    if (!s->is_bss) {
      // Align to 4.
      while ((written & 3) != 0) {
        unwrapped_stream_->WriteByte(0);
        written++;
      }
      ASSERT(written == s->raw_data_offset);
      WriteBytes(unwrapped_stream_, &(*s->data)[0], s->data->length());
      written += s->data->length();
    }
    if (s->relocs->length() > 0) {
      while ((written & 3) != 0) {
        unwrapped_stream_->WriteByte(0);
        written++;
      }
      ASSERT(written == s->reloc_offset);
      if (UsesRelocationCountOverflow(s->relocs->length())) {
        coff::ImageRelocation overflow = {};
        // The overflow count includes this synthetic relocation itself. COFF
        // readers skip it and expose VirtualAddress - 1 real relocations.
        ASSERT(s->relocs->length() <= static_cast<intptr_t>(kMaxUint32) - 1);
        overflow.VirtualAddress =
            static_cast<uint32_t>(s->relocs->length() + 1);
        WriteBytes(unwrapped_stream_, &overflow, sizeof(overflow));
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
        WriteBytes(unwrapped_stream_, &cr, sizeof(cr));
        written += sizeof(cr);
      }
    }
  }

  // Align before symbol table.
  while ((written & 3) != 0) {
    unwrapped_stream_->WriteByte(0);
    written++;
  }
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
    WriteBytes(unwrapped_stream_, &is, sizeof(is));
    written += sizeof(is);
    if (s.aux != nullptr) {
      ASSERT(s.aux->length() == 18 * s.num_aux);
      WriteBytes(unwrapped_stream_, &(*s.aux)[0], s.aux->length());
      written += s.aux->length();
    }
  }

  // --- Write string table ---
  uint32_t str_table_size = static_cast<uint32_t>(string_table_->length()) + 4;
  WriteLE<uint32_t>(unwrapped_stream_, str_table_size);
  if (string_table_->length() > 0) {
    WriteBytes(unwrapped_stream_, &(*string_table_)[0],
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
