// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/codeview.h"

#if defined(DART_PRECOMPILER)

#include "vm/code_descriptors.h"
#include "vm/coff.h"
#include "vm/datastream.h"
#include "vm/debug_info.h"
#include "vm/debug_info_stream.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/os.h"
#include "vm/version.h"

namespace dart {

CodeViewBuilder::CodeViewBuilder(Zone* zone,
                                 CoffWriter* writer,
                                 DebugInfoStream* debug_s,
                                 DebugInfoStream* debug_t)
    : zone_(zone),
      writer_(writer),
      debugS_(ASSERT_NOTNULL(debug_s)),
      debugT_(ASSERT_NOTNULL(debug_t)),
      functions_(new (zone) ZoneGrowableArray<FunctionInfo>(zone, 64)),
      script_string_offsets_(new (zone) ZoneGrowableArray<uint32_t>(zone, 16)),
      script_checksum_offsets_(new (zone)
                                   ZoneGrowableArray<uint32_t>(zone, 16)) {}

struct CVLineRow {
  uint32_t pc_offset;
  int32_t file_index;  // index into the debug script table
  int32_t line;
};

class CVLineNumberProgramWriter : public DebugInfoLineNumberProgramWriter {
 public:
  CVLineNumberProgramWriter(Zone* zone,
                            CoffWriter* writer,
                            intptr_t script_count,
                            intptr_t code_size)
      : DebugInfoLineNumberProgramWriter(zone),
        rows_(zone, 64),
        writer_(ASSERT_NOTNULL(writer)),
        script_count_(script_count),
        code_size_(code_size) {}

  intptr_t LookupCodeLabel(const Code& code) override {
    return writer_->LookupDebugCodeLabel(code);
  }

  intptr_t LookupScript(const Script& script) override {
    return writer_->LookupDebugScript(script);
  }

  void EmitRow(intptr_t file,
               intptr_t line,
               intptr_t column,
               intptr_t label,
               intptr_t pc_offset) override {
    USE(label);
    ASSERT(file >= 1);
    ASSERT(line >= 0);
    ASSERT(column >= 0);

    if (file == file_ && line == line_ && column == column_) {
      return;
    }
    file_ = file;
    line_ = line;
    column_ = column;

    ASSERT(file <= script_count_);
    if (line == 0) {
      return;
    }
    ASSERT(pc_offset <= code_size_);
    if (pc_offset == code_size_) {
      // CodeView line rows describe instruction offsets inside the function
      // body. A trailing row exactly at code_size is the DWARF end-address
      // boundary and has no instruction to attach to in DEBUG_S_LINES.
      return;
    }

    CVLineRow row;
    row.pc_offset = static_cast<uint32_t>(pc_offset);
    row.file_index = static_cast<int32_t>(file - 1);
    row.line = static_cast<int32_t>(line);

    if (!rows_.is_empty()) {
      ASSERT(row.pc_offset > rows_.Last().pc_offset);
      if (row.pc_offset <= rows_.Last().pc_offset) {
        return;
      }
    }
    rows_.Add(row);
    return;
  }

  const GrowableArray<CVLineRow>& rows() const { return rows_; }

 private:
  GrowableArray<CVLineRow> rows_;
  CoffWriter* const writer_;
  const intptr_t script_count_;
  const intptr_t code_size_;

  intptr_t file_ = 0;
  intptr_t line_ = 1;
  intptr_t column_ = 0;
};

// ----------------------------------------------------------------------------
// Script URI resolution
// ----------------------------------------------------------------------------

const char* CodeViewBuilder::ResolvedScriptUri(const Script& script) {
  return DebugInfo::ResolveScriptUri(zone_, script,
                                     writer_->debug_deobfuscation_trie());
}

// ----------------------------------------------------------------------------
// Pre-compute string-table and file-checksum offsets per script.
// ----------------------------------------------------------------------------
//
// CV_LINE_BLOCK records reference a script by its byte-offset within the
// DEBUG_S_FILECHKSMS subsection body.  Each FILECHKSMS entry in turn references
// the script URI by its byte-offset within the DEBUG_S_STRINGTABLE subsection
// body.  We compute both offsets up-front so the EmitLines step can stamp them
// directly into the line-block headers without re-walking either subsection.
//
// FILECHKSMS entry layout when ChecksumKind=NONE and ChecksumSize=0:
//   u32 NameOffset
//   u8  ChecksumSize
//   u8  ChecksumKind
//   padding to 4-byte alignment
// = 6 bytes payload, padded to 8.  Each script slot is exactly 8 bytes.
void CodeViewBuilder::ComputeScriptTables() {
  script_string_offsets_->Clear();
  script_checksum_offsets_->Clear();

  // String table starts with a mandatory empty string at offset 0.
  static constexpr uint32_t kCheckSumEntrySize = 8;
  uint32_t string_offset = 1;
  const auto& scripts = writer_->debug_scripts();
  for (intptr_t i = 0; i < scripts.length(); i++) {
    const Script& script = *(scripts[i]);
    const char* uri = ResolvedScriptUri(script);
    script_string_offsets_->Add(string_offset);
    string_offset += static_cast<uint32_t>(strlen(uri)) + 1;  // include NUL
    // Actual entries are emitted in EmitFileChecksumsSubsection, see below.
    script_checksum_offsets_->Add(
        static_cast<uint32_t>(i * kCheckSumEntrySize));
  }
}

// ----------------------------------------------------------------------------
// Function gathering: one CodeView function per Dart Code.
// ----------------------------------------------------------------------------

void CodeViewBuilder::GatherFunctions() {
  const auto& codes = writer_->debug_codes();
  functions_->Clear();
  functions_->EnsureLength(codes.length(), FunctionInfo());

  Function& function = Function::Handle(zone_);
  CStringIntMap usage_count(zone_);
  auto mangle_name = [&](const char* name) -> const char* {
    auto* const pair = usage_count.Lookup(name);
    if (pair == nullptr) {
      usage_count.Insert({name, 1});
      return OS::SCreate(zone_, "%s", name);
    }
    return OS::SCreate(zone_, "%s (#%" Pd ")", name, ++pair->value);
  };

  for (intptr_t i = 0; i < codes.length(); i++) {
    FunctionInfo& fn = (*functions_)[i];
    const Code& code = *(codes[i]);
    const intptr_t label = writer_->LookupDebugCodeLabel(code);
    if (label <= 0 || !writer_->label_to_symbol_index_.HasKey(label)) continue;

    const intptr_t sym_idx = writer_->label_to_symbol_index_.Lookup(label);
    ASSERT(sym_idx > 0 && sym_idx <= writer_->symbols_->length());
    const auto& sym = (*writer_->symbols_)[sym_idx - 1];
    ASSERT(sym.section_number == CoffWriter::kTextSectionNumber);

    fn.label = label;
    if (code.IsFunctionCode() && !code.IsUnknownDartCode()) {
      function = code.function();
      ASSERT(!function.IsNull());
      const char* raw_name = function.QualifiedUserVisibleNameCString();
      const char* deob_name = ImageWriter::Deobfuscate(
          zone_, writer_->debug_deobfuscation_trie(), raw_name);
      if (deob_name == nullptr || deob_name[0] == '\0') {
        deob_name = sym.name != nullptr ? sym.name : "<anonymous>";
      }
      fn.name = mangle_name(deob_name);
    } else {
      // No Dart-level function (stubs etc.) -- use the COFF symbol name we
      // already chose for this Code so the .pdb at least shows that.
      fn.name = sym.name != nullptr ? mangle_name(sym.name)
                                    : OS::SCreate(zone_, "code_%" Pd, label);
    }
  }
}

// ----------------------------------------------------------------------------
// .debug$T type records
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitTypeRecords() {
  // Leading signature.
  debugT_->u4(coff::CV_SIGNATURE_C13);

  // LF_ARGLIST (empty).
  debugT_->WritePrefixedLengthU16([&]() {
    debugT_->u2(coff::LF_ARGLIST);
    debugT_->u4(0);  // count
    debugT_->Align(4);
    arglist_type_ = next_type_index_++;
  });

  // LF_PROCEDURE (rvtype=T_VOID, calltype=C_NEAR_C, parmcount=0, arglist).
  debugT_->WritePrefixedLengthU16([&]() {
    debugT_->u2(coff::LF_PROCEDURE);
    debugT_->u4(coff::T_VOID);
    debugT_->u1(coff::CV_CALL_NEAR_C);
    debugT_->u1(0);  // func attrs
    debugT_->u2(0);  // param count
    debugT_->u4(arglist_type_);
    debugT_->Align(4);
    procedure_type_ = next_type_index_++;
  });

  // For each function: LF_STRING_ID then LF_FUNC_ID.
  for (intptr_t i = 0; i < functions_->length(); i++) {
    FunctionInfo& fn = (*functions_)[i];
    if (fn.name == nullptr) continue;
    // LF_STRING_ID with the function's name.
    debugT_->WritePrefixedLengthU16([&]() {
      debugT_->u2(coff::LF_STRING_ID);
      debugT_->u4(0);  // substring
      debugT_->string(fn.name);
      debugT_->Align(4);
      next_type_index_++;
    });
    // LF_FUNC_ID.
    debugT_->WritePrefixedLengthU16([&]() {
      debugT_->u2(coff::LF_FUNC_ID);
      debugT_->u4(0);  // parent scope
      debugT_->u4(procedure_type_);
      debugT_->string(fn.name);
      debugT_->Align(4);
      fn.func_id_type = next_type_index_++;
    });
  }
}

// ----------------------------------------------------------------------------
// .debug$S subsections
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitOneFunctionSymbol(const FunctionInfo& fn,
                                            const Code& code) {
  const uint32_t code_size = static_cast<uint32_t>(code.Size());
  auto* const relocs = writer_->by_kind_[CoffWriter::kSecDebugS]->relocs;

  // S_GPROC32_ID.
  debugS_->WritePrefixedLengthU16([&]() {
    debugS_->u2(coff::S_GPROC32_ID);
    debugS_->u4(0);  // Parent
    debugS_->u4(0);  // End (would patch with offset to S_PROC_ID_END)
    debugS_->u4(0);  // Next
    debugS_->u4(code_size);
    debugS_->u4(0);          // DebugStart
    debugS_->u4(code_size);  // DebugEnd
    debugS_->u4(fn.func_id_type);
    // CodeOffset slot -- SECREL relocation against this function's COFF
    // symbol.
    relocs->Add({static_cast<uint32_t>(debugS_->Position()), fn.label,
                 coff::PE_REL_AMD64_SECREL});
    debugS_->u4(0);  // inline addend
    // Segment slot -- SECTION relocation against this function's COFF symbol.
    relocs->Add({static_cast<uint32_t>(debugS_->Position()), fn.label,
                 coff::PE_REL_AMD64_SECTION});
    debugS_->u2(0);
    debugS_->u1(0);  // flags
    debugS_->string(fn.name);
    debugS_->Align(4);
  });

  // S_FRAMEPROC.
  debugS_->WritePrefixedLengthU16([&]() {
    debugS_->u2(coff::S_FRAMEPROC);
    debugS_->u4(0);  // frame size
    debugS_->u4(0);  // padding size
    debugS_->u4(0);  // offset to padding
    debugS_->u4(0);  // bytes of callee-saved regs
    debugS_->u4(0);  // offset of exception handler
    debugS_->u2(0);  // section of exception handler
    // Flags: EncodedLocalBasePointer=rbp (bits 14-15 == 0b01).
    debugS_->u4(1u << 14);
    debugS_->Align(4);
  });

  // S_PROC_ID_END.
  debugS_->u2(2);  // length = 2 (kind only)
  debugS_->u2(coff::S_PROC_ID_END);
}

void CodeViewBuilder::EmitObjectAndCompileSymbolsSubsection() {
  debugS_->u4(coff::DEBUG_S_SYMBOLS);
  debugS_->WritePrefixedLength([&]() {
    // S_OBJNAME.
    debugS_->WritePrefixedLengthU16([&]() {
      debugS_->u2(coff::S_OBJNAME);
      debugS_->u4(0);  // signature
      debugS_->string("snapshot.obj");
      debugS_->Align(4);
    });

    // S_COMPILE3.
    debugS_->WritePrefixedLengthU16([&]() {
      debugS_->u2(coff::S_COMPILE3);
      debugS_->u4(static_cast<uint32_t>(coff::CV_CFL_C));
      debugS_->u2(coff::CV_CFL_X64);
      debugS_->u2(0);  // FE Major
      debugS_->u2(0);  // FE Minor
      debugS_->u2(0);  // FE Build
      debugS_->u2(0);  // FE QFE
      debugS_->u2(0);  // BE Major
      debugS_->u2(0);  // BE Minor
      debugS_->u2(0);  // BE Build
      debugS_->u2(0);  // BE QFE
      debugS_->string("Dart AOT");
      debugS_->Align(4);
    });
  });
  debugS_->Align(4);
}

void CodeViewBuilder::EmitFunctionSymbolsSubsection(const FunctionInfo& fn,
                                                    const Code& code) {
  debugS_->u4(coff::DEBUG_S_SYMBOLS);
  debugS_->WritePrefixedLength([&]() { EmitOneFunctionSymbol(fn, code); });
  debugS_->Align(4);
}

// ----------------------------------------------------------------------------
// Per-function line tables: walk each Code's CodeSourceMap to build a sequence
// of (pc_offset, file_index, line) rows, then emit one DEBUG_S_LINES subsection
// per Code with the rows grouped into CV_LINE_BLOCKs by file.
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitLinesSubsection(const FunctionInfo& fn,
                                          const Code& code) {
  if (!code.IsFunctionCode() || code.IsUnknownDartCode()) return;

  CodeSourceMap& map = CodeSourceMap::Handle(zone_, code.code_source_map());
  if (map.IsNull() || map.Length() == 0) {
    return;
  }
  Function& root_function = Function::Handle(zone_, code.function());
  ASSERT(!root_function.IsNull());
  CVLineNumberProgramWriter writer(
      zone_, writer_, writer_->debug_scripts().length(), code.Size());
  DebugInfo::WriteLineNumberProgramForCode(zone_, code, &writer);
  const auto& rows = writer.rows();
  if (rows.is_empty()) return;

  // Group consecutive rows by file_index into CV_LINE_BLOCK chunks.
  struct Block {
    int32_t file_index;
    intptr_t start;  // index into rows
    intptr_t count;
  };
  GrowableArray<Block> blocks(zone_, 4);
  for (intptr_t r = 0; r < rows.length(); r++) {
    if (blocks.is_empty() || blocks.Last().file_index != rows[r].file_index) {
      Block b = {rows[r].file_index, r, 1};
      blocks.Add(b);
    } else {
      blocks.Last().count++;
    }
  }
  if (blocks.is_empty()) return;

  intptr_t code_offset_pos = 0;
  intptr_t section_pos = 0;
  debugS_->u4(coff::DEBUG_S_LINES);
  debugS_->WritePrefixedLength([&]() {
    // DEBUG_S_LINES section header.
    code_offset_pos = debugS_->Position();
    debugS_->u4(0);  // inline addend
    section_pos = debugS_->Position();
    debugS_->u2(0);  // Section (SECTION reloc)
    debugS_->u2(0);  // Flags
    debugS_->u4(static_cast<uint32_t>(code.Size()));

    for (intptr_t b = 0; b < blocks.length(); b++) {
      const Block& blk = blocks[b];
      const uint32_t chksm_offset = (*script_checksum_offsets_)[blk.file_index];
      debugS_->u4(chksm_offset);  // NameIndex (file checksum offset)
      debugS_->u4(static_cast<uint32_t>(blk.count));
      const uint32_t block_size = static_cast<uint32_t>(
          sizeof(coff::CvLineBlockHeader) + sizeof(coff::CvLine) * blk.count);
      debugS_->u4(block_size);

      for (intptr_t r = blk.start; r < blk.start + blk.count; r++) {
        debugS_->u4(rows[r].pc_offset);
        const uint32_t line_field =
            (static_cast<uint32_t>(rows[r].line) & coff::CvLine::kLineMask) |
            coff::CvLine::kIsStatementBit;
        debugS_->u4(line_field);
      }
    }
  });
  debugS_->Align(4);

  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(code_offset_pos), fn.label,
       coff::PE_REL_AMD64_SECREL});
  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(section_pos), fn.label,
       coff::PE_REL_AMD64_SECTION});
}

void CodeViewBuilder::EmitFileChecksumsSubsection() {
  debugS_->u4(coff::DEBUG_S_FILECHKSMS);
  debugS_->WritePrefixedLength([&]() {
    const auto& scripts = writer_->debug_scripts();
    for (intptr_t i = 0; i < scripts.length(); i++) {
      // Each entry is exactly 8 bytes (6 payload + 2 padding), matching the
      // layout assumed by ComputeScriptTables.
      debugS_->u4((*script_string_offsets_)[i]);  // NameOffset
      debugS_->u1(0);                             // ChecksumSize
      debugS_->u1(coff::CHKSUM_TYPE_NONE);
      debugS_->u1(0);  // padding
      debugS_->u1(0);  // padding
    }
  });
  debugS_->Align(4);
}

void CodeViewBuilder::EmitStringTableSubsection() {
  debugS_->u4(coff::DEBUG_S_STRINGTABLE);
  debugS_->WritePrefixedLength([&]() {
    // Leading mandatory empty string.
    debugS_->u1(0);

    const auto& scripts = writer_->debug_scripts();
    for (intptr_t i = 0; i < scripts.length(); i++) {
      const Script& script = *(scripts[i]);
      const char* uri = ResolvedScriptUri(script);
      debugS_->string(uri);  // NOLINT(build/include_what_you_use)
    }
  });
  debugS_->Align(4);
}

// ----------------------------------------------------------------------------
// Build
// ----------------------------------------------------------------------------

void CodeViewBuilder::Build() {
  GatherFunctions();
  ComputeScriptTables();

  EmitTypeRecords();

  debugS_->u4(coff::CV_SIGNATURE_C13);
  EmitObjectAndCompileSymbolsSubsection();
  const auto& codes = writer_->debug_codes();
  ASSERT(functions_->length() == codes.length());
  for (intptr_t i = 0; i < codes.length(); i++) {
    const FunctionInfo& fn = (*functions_)[i];
    if (fn.name == nullptr) continue;
    const Code& code = *(codes[i]);
    EmitFunctionSymbolsSubsection(fn, code);
    EmitLinesSubsection(fn, code);
  }
  EmitFileChecksumsSubsection();
  EmitStringTableSubsection();
}

}  // namespace dart

#endif  // DART_PRECOMPILER
