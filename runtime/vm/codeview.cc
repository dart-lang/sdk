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
      func_ids_(new (zone) ZoneGrowableArray<FuncId>(zone, 64)),
      func_id_indices_(zone),
      functions_(new (zone) ZoneGrowableArray<FunctionInfo>(zone, 64)),
      codes_(new (zone) ZoneGrowableArray<CodeInfo>(zone, 64)),
      script_string_offsets_(new (zone) ZoneGrowableArray<uint32_t>(zone, 16)),
      script_checksum_offsets_(new (zone)
                                   ZoneGrowableArray<uint32_t>(zone, 16)) {}

// ----------------------------------------------------------------------------
// Binary annotations of S_INLINESITE records
// ----------------------------------------------------------------------------

// Appends [value] in the compressed integer format used by CodeView binary
// annotations.
static void WriteCompressedAnnotation(GrowableArray<uint8_t>* out,
                                      uint32_t value) {
  if (value < 0x80) {
    out->Add(static_cast<uint8_t>(value));
  } else if (value < 0x4000) {
    out->Add(static_cast<uint8_t>(0x80 | (value >> 8)));
    out->Add(static_cast<uint8_t>(value & 0xff));
  } else {
    RELEASE_ASSERT(value < 0x20000000);
    out->Add(static_cast<uint8_t>(0xc0 | (value >> 24)));
    out->Add(static_cast<uint8_t>((value >> 16) & 0xff));
    out->Add(static_cast<uint8_t>((value >> 8) & 0xff));
    out->Add(static_cast<uint8_t>(value & 0xff));
  }
}

// Encodes a signed annotation operand: the sign is stored in the lowest bit.
static uint32_t EncodeSignedAnnotation(int32_t value) {
  return value >= 0 ? static_cast<uint32_t>(value) << 1
                    : (static_cast<uint32_t>(-value) << 1) | 1;
}

// ----------------------------------------------------------------------------
// Function properties
// ----------------------------------------------------------------------------

const char* CodeViewBuilder::FunctionName(const Function& function) {
  const char* const raw_name = function.QualifiedUserVisibleNameCString();
  return ImageWriter::Deobfuscate(zone_, writer_->debug_deobfuscation_trie(),
                                  raw_name);
}

int32_t CodeViewBuilder::ScriptIndex(const Function& function) {
  const Script& script = Script::Handle(zone_, function.script());
  // Debug script indices are 1-based.
  return static_cast<int32_t>(writer_->LookupDebugScript(script) - 1);
}

int32_t CodeViewBuilder::StartLine(const Function& function) {
  // As with DW_AT_decl_line, this may be unavailable since scripts have lost
  // their token stream at this point.
  const Script& script = Script::Handle(zone_, function.script());
  intptr_t line = 0;
  intptr_t column = 0;
  script.GetTokenLocation(function.token_pos(), &line, &column);
  return static_cast<int32_t>(line);
}

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
// Function gathering: one CodeView function per Dart Code, and an LF_FUNC_ID
// per name of a function or Code.
// ----------------------------------------------------------------------------

intptr_t CodeViewBuilder::AddFuncId(const char* name) {
  if (auto* const pair = func_id_indices_.Lookup(name)) {
    return pair->value;
  }
  const intptr_t index = func_ids_->length();
  func_ids_->Add({name});
  func_id_indices_.Insert({name, index});
  return index;
}

void CodeViewBuilder::GatherFunctions() {
  const auto& functions = writer_->debug_functions();
  functions_->Clear();
  functions_->EnsureLength(functions.length(), FunctionInfo());
  for (intptr_t i = 0; i < functions.length(); i++) {
    (*functions_)[i].func_id = AddFuncId(FunctionName(*functions[i]));
  }
}

void CodeViewBuilder::GatherCodes() {
  const auto& codes = writer_->debug_codes();
  codes_->Clear();
  codes_->EnsureLength(codes.length(), CodeInfo());

  // The names of procedures don't need to be unique, so like in DWARF they are
  // the names of the functions, which is also what stack traces show.
  Function& function = Function::Handle(zone_);
  for (intptr_t i = 0; i < codes.length(); i++) {
    CodeInfo& info = (*codes_)[i];
    const Code& code = *(codes[i]);
    const intptr_t label = writer_->LookupDebugCodeLabel(code);
    if (label <= 0 || !writer_->label_to_symbol_index_.HasKey(label)) continue;

    const intptr_t sym_idx = writer_->label_to_symbol_index_.Lookup(label);
    ASSERT(sym_idx > 0 && sym_idx <= writer_->symbols_->length());
    const auto& sym = (*writer_->symbols_)[sym_idx - 1];
    ASSERT(sym.section_number == CoffWriter::kTextSectionNumber);

    info.label = label;
    if (code.IsFunctionCode() && !code.IsUnknownDartCode()) {
      function = code.function();
      ASSERT(!function.IsNull());
      info.func_id =
          (*functions_)[writer_->LookupDebugFunction(function)].func_id;
      info.name = (*func_ids_)[info.func_id].name;
      if (info.name[0] == '\0') {
        info.name = sym.name != nullptr ? sym.name : "<anonymous>";
        info.func_id = AddFuncId(info.name);
      }
      info.is_visible = function.is_visible();
      info.file_index = ScriptIndex(function);
    } else {
      // No Dart-level function (stubs etc.) -- use the COFF symbol name we
      // already chose for this Code so the .pdb at least shows that.
      info.name = sym.name != nullptr ? sym.name
                                      : OS::SCreate(zone_, "code_%" Pd, label);
      info.func_id = AddFuncId(info.name);
    }
  }
}

// ----------------------------------------------------------------------------
// Locations: walk each Code's CodeSourceMap to compute the line rows of the
// function itself and of each call to an inlined function.
// ----------------------------------------------------------------------------
//
// For each code offset, the CodeSourceMap gives the current position in each
// function on the inlining stack. Each of these functions gets its own rows:
// the rows of the function itself make up its line table, and the rows of an
// inlined function make up the binary annotations of the S_INLINESITE of the
// call. Thus, at code inlined into a function, the row of the function is the
// position of the call, which is what its stack frame shows.
//
// Calls to invisible inlined functions don't get an S_INLINESITE, so they
// don't appear in stack traces, and the calls to functions inlined into them
// are added to the closest visible caller instead.

void CodeViewBuilder::GatherLocations(CodeInfo* info, const Code& code) {
  info->rows = new (zone_) ZoneGrowableArray<LineRow>(zone_, 8);
  info->inline_sites = new (zone_) ZoneGrowableArray<InlineSite*>(zone_, 0);
  if (!code.IsFunctionCode() || code.IsUnknownDartCode()) return;
  // Functions without line information still get a row, which gives the
  // script of the function and distinguishes it from stubs, which have no line
  // table.
  const CodeSourceMap& map =
      CodeSourceMap::Handle(zone_, code.code_source_map());
  if (map.IsNull() || map.Length() == 0) {
    info->rows->Add(
        {0, DebugInfoPosition::kNoLine, DebugInfoPosition::kNoColumn});
    return;
  }
  const Array& inlined_functions =
      Array::Handle(zone_, code.inlined_id_to_function());

  // A function on the inlining stack.
  struct Frame {
    DebugInfoPosition position;
    // The rows of the function, or nullptr if it is an invisible inlined
    // function.
    ZoneGrowableArray<LineRow>* rows;
    // Where calls from the function to inlined functions are added.
    ZoneGrowableArray<InlineSite*>* inline_sites;
    // The call to the function, or nullptr if it is the root function or an
    // invisible inlined function.
    InlineSite* site;
  };
  GrowableArray<Frame> frames(zone_, 4);
  frames.Add({DebugInfoPosition(), info->rows, info->inline_sites, nullptr});

  // Like in DWARF, code without line information gets rows with line 0, so
  // that it isn't attributed to the previous line.
  const uint32_t code_size = static_cast<uint32_t>(code.Size());
  auto add_row = [code_size](const Frame& frame, uint32_t pc_offset) {
    // A row at the end of the code would have no instructions.
    if (pc_offset >= code_size) return;
    auto* const rows = frame.rows;
    const int32_t line = frame.position.line();
    const int32_t column = frame.position.column();
    if (!rows->is_empty()) {
      const LineRow& last = rows->Last();
      // A row can only be at the offset of the last one if the latter was
      // moved from the function entry (see below).
      ASSERT(pc_offset >= last.pc_offset);
      if (pc_offset == last.pc_offset) return;
      if (last.line == line && last.column == column) return;
    }
    rows->Add({pc_offset, line, column});
  };

  // The position at the function entry is handled as in
  // DebugInfo::WriteLineNumberProgramForCode.
  bool function_entry_position_was_emitted = false;
  uint32_t pc_offset = 0;

  NoSafepointScope no_safepoint;
  ReadStream stream(map.Data(), map.Length());
  while (stream.PendingBytes() > 0) {
    int32_t arg1;
    int32_t arg2 = -1;
    const uint8_t opcode = CodeSourceMapOps::Read(&stream, &arg1, &arg2);
    switch (opcode) {
      case CodeSourceMapOps::kChangePosition: {
        frames.Last().position.ChangePosition(arg1, arg2);
        break;
      }
      case CodeSourceMapOps::kAdvancePC: {
        const bool after_function_entry =
            pc_offset == 0 && function_entry_position_was_emitted;
        const uint32_t row_pc_offset = after_function_entry ? 1 : pc_offset;
        for (intptr_t i = 0; i < frames.length(); i++) {
          const Frame& frame = frames[i];
          if (frame.rows == nullptr) continue;
          // Ignore synthetic positions of the function itself after the
          // function entry, as the function entry position gives more
          // information anyway. Calls to inlined functions at the function
          // entry have no such position, so they keep their rows.
          if (after_function_entry && i == 0 &&
              frame.position.line() == DebugInfoPosition::kNoLine &&
              frame.position.column() == DebugInfoPosition::kNoColumn) {
            continue;
          }
          add_row(frame, row_pc_offset);
        }
        pc_offset += arg1;
        if (arg1 == 0) {
          ASSERT(pc_offset == 0);
          function_entry_position_was_emitted = true;
        }
        break;
      }
      case CodeSourceMapOps::kPushFunction: {
        const Function& function = Function::ZoneHandle(
            zone_, Function::RawCast(inlined_functions.At(arg1)));
        auto* const inline_sites = frames.Last().inline_sites;
        if (function.is_visible()) {
          const uint32_t start_pc_offset =
              pc_offset == 0 && function_entry_position_was_emitted ? 1
                                                                    : pc_offset;
          auto* const site =
              new (zone_) InlineSite(zone_, function, start_pc_offset);
          inline_sites->Add(site);
          frames.Add({DebugInfoPosition(), site->rows, site->children, site});
          const intptr_t function_index =
              writer_->LookupDebugFunction(function);
          FuncId& func_id = (*func_ids_)[(*functions_)[function_index].func_id];
          if (func_id.inlined == -1) {
            func_id.inlined = function_index;
            func_id.inlined_file_index = ScriptIndex(function);
            func_id.inlined_start_line = StartLine(function);
          }
        } else {
          frames.Add({DebugInfoPosition(), nullptr, inline_sites, nullptr});
        }
        break;
      }
      case CodeSourceMapOps::kPopFunction: {
        // We never pop the root function.
        ASSERT(frames.length() > 1);
        if (InlineSite* const site = frames.Last().site) {
          site->end_pc_offset = pc_offset;
        }
        frames.RemoveLast();
        break;
      }
      case CodeSourceMapOps::kNullCheck: {
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  while (frames.length() > 1) {
    if (InlineSite* const site = frames.Last().site) {
      site->end_pc_offset = pc_offset;
    }
    frames.RemoveLast();
  }
  if (info->rows->is_empty()) {
    info->rows->Add(
        {0, DebugInfoPosition::kNoLine, DebugInfoPosition::kNoColumn});
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

  // For each LF_FUNC_ID: LF_STRING_ID then LF_FUNC_ID.
  for (FuncId& func_id : *func_ids_) {
    // LF_STRING_ID with the function's name.
    debugT_->WritePrefixedLengthU16([&]() {
      debugT_->u2(coff::LF_STRING_ID);
      debugT_->u4(0);  // substring
      debugT_->string(func_id.name);
      debugT_->Align(4);
      next_type_index_++;
    });
    func_id.type_index = EmitFuncIdRecord(func_id.name);
  }
}

uint32_t CodeViewBuilder::EmitFuncIdRecord(const char* name) {
  debugT_->WritePrefixedLengthU16([&]() {
    debugT_->u2(coff::LF_FUNC_ID);
    debugT_->u4(0);  // parent scope
    debugT_->u4(procedure_type_);
    debugT_->string(name);
    debugT_->Align(4);
  });
  return next_type_index_++;
}

// ----------------------------------------------------------------------------
// .debug$S subsections
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitOneFunctionSymbol(const CodeInfo& info,
                                            const Code& code) {
  const uint32_t code_size = static_cast<uint32_t>(code.Size());
  auto* const relocs = writer_->by_kind_[CoffWriter::kSecDebugS]->relocs;

  // S_GPROC32_ID, or S_LPROC32_ID for functions that are invisible in stack
  // traces, so that symbolizers can hide them like DWARF-based ones hide
  // artificial subprograms.
  debugS_->WritePrefixedLengthU16([&]() {
    debugS_->u2(info.is_visible ? coff::S_GPROC32_ID : coff::S_LPROC32_ID);
    debugS_->u4(0);  // Parent
    debugS_->u4(0);  // End (would patch with offset to S_PROC_ID_END)
    debugS_->u4(0);  // Next
    debugS_->u4(code_size);
    debugS_->u4(0);          // DebugStart
    debugS_->u4(code_size);  // DebugEnd
    debugS_->u4((*func_ids_)[info.func_id].type_index);
    // CodeOffset slot -- SECREL relocation against this function's COFF
    // symbol.
    relocs->Add({static_cast<uint32_t>(debugS_->Position()), info.label,
                 coff::PE_REL_AMD64_SECREL});
    debugS_->u4(0);  // inline addend
    // Segment slot -- SECTION relocation against this function's COFF symbol.
    relocs->Add({static_cast<uint32_t>(debugS_->Position()), info.label,
                 coff::PE_REL_AMD64_SECTION});
    debugS_->u2(0);
    debugS_->u1(0);  // flags
    debugS_->string(info.name);
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

  for (const InlineSite* site : *info.inline_sites) {
    EmitInlineSite(*site);
  }

  // S_PROC_ID_END.
  debugS_->u2(2);  // length = 2 (kind only)
  debugS_->u2(coff::S_PROC_ID_END);
}

// The binary annotations describe the code of the call relative to the start
// of the function, and its file and lines relative to the ones in the
// DEBUG_S_INLINEELINES entry of its LF_FUNC_ID (see
// EmitInlineeLinesSubsection), which are the script and start line of the
// first inlined function with that LF_FUNC_ID. Each row sets the location of
// the code up to the next row, and the last row covers the rest of the call.
// The encoding matches the one of LLVM, which is understood by debuggers and
// symbolizers.
void CodeViewBuilder::EmitInlineSite(const InlineSite& site) {
  if (site.rows->is_empty() || site.end_pc_offset <= site.start_pc_offset) {
    return;
  }
  // Leaves room for the fixed part of the record and the last annotation, as
  // the record length is limited to 16 bits. Rows past the limit are dropped.
  static constexpr intptr_t kMaxAnnotationsLength = 0xf000;

  GrowableArray<uint8_t> annotations(zone_, 16);
  auto annotate = [&](uint32_t opcode, uint32_t operand) {
    WriteCompressedAnnotation(&annotations, opcode);
    WriteCompressedAnnotation(&annotations, operand);
  };
  const intptr_t function_index = writer_->LookupDebugFunction(site.function);
  const FuncId& func_id = (*func_ids_)[(*functions_)[function_index].func_id];
  ASSERT(func_id.inlined != -1);
  // The other functions with the LF_FUNC_ID can be in other scripts.
  const int32_t file_index = ScriptIndex(site.function);
  if (file_index != func_id.inlined_file_index) {
    annotate(coff::BA_OP_ChangeFile, (*script_checksum_offsets_)[file_index]);
  }
  uint32_t last_pc_offset = 0;
  int32_t last_line = func_id.inlined_start_line;
  int32_t last_column = DebugInfoPosition::kNoColumn;
  for (const LineRow& row : *site.rows) {
    if (annotations.length() > kMaxAnnotationsLength) break;
    ASSERT(row.pc_offset >= last_pc_offset);
    if (row.column != last_column) {
      annotate(coff::BA_OP_ChangeColumnStart, row.column);
    }
    const int32_t line_delta = row.line - last_line;
    const uint32_t encoded_line_delta = EncodeSignedAnnotation(line_delta);
    const uint32_t pc_delta = row.pc_offset - last_pc_offset;
    if (encoded_line_delta < 0x8 && pc_delta <= 0xf) {
      annotate(coff::BA_OP_ChangeCodeOffsetAndLineOffset,
               (encoded_line_delta << 4) | pc_delta);
    } else {
      if (line_delta != 0) {
        annotate(coff::BA_OP_ChangeLineOffset, encoded_line_delta);
      }
      annotate(coff::BA_OP_ChangeCodeOffset, pc_delta);
    }
    last_pc_offset = row.pc_offset;
    last_line = row.line;
    last_column = row.column;
  }
  annotate(coff::BA_OP_ChangeCodeLength, site.end_pc_offset - last_pc_offset);

  // S_INLINESITE.
  debugS_->WritePrefixedLengthU16([&]() {
    debugS_->u2(coff::S_INLINESITE);
    debugS_->u4(0);  // Parent, set by the linker.
    debugS_->u4(0);  // End, set by the linker.
    debugS_->u4(func_id.type_index);
    debugS_->bytes(annotations.data(), annotations.length());
    debugS_->Align(4);
  });

  for (const InlineSite* child : *site.children) {
    EmitInlineSite(*child);
  }

  // S_INLINESITE_END.
  debugS_->u2(2);  // length = 2 (kind only)
  debugS_->u2(coff::S_INLINESITE_END);
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

void CodeViewBuilder::EmitFunctionSymbolsSubsection(const CodeInfo& info,
                                                    const Code& code) {
  debugS_->u4(coff::DEBUG_S_SYMBOLS);
  debugS_->WritePrefixedLength([&]() { EmitOneFunctionSymbol(info, code); });
  debugS_->Align(4);
}

// ----------------------------------------------------------------------------
// Per-function line tables: emit one DEBUG_S_LINES subsection per Code with
// the rows of the function itself (see GatherLocations) in a CV_LINE_BLOCK
// for the script of the function.
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitLinesSubsection(const CodeInfo& info,
                                          const Code& code) {
  const auto& rows = *info.rows;
  if (rows.is_empty()) return;
  ASSERT(info.file_index >= 0);

  intptr_t code_offset_pos = 0;
  intptr_t section_pos = 0;
  debugS_->u4(coff::DEBUG_S_LINES);
  debugS_->WritePrefixedLength([&]() {
    // DEBUG_S_LINES section header.
    code_offset_pos = debugS_->Position();
    debugS_->u4(0);  // inline addend
    section_pos = debugS_->Position();
    debugS_->u2(0);  // Section (SECTION reloc)
    debugS_->u2(coff::CvLineSectionHeader::kHaveColumns);  // Flags
    debugS_->u4(static_cast<uint32_t>(code.Size()));

    // CV_LINE_BLOCK.
    debugS_->u4((*script_checksum_offsets_)[info.file_index]);  // NameIndex
    debugS_->u4(static_cast<uint32_t>(rows.length()));
    const uint32_t block_size = static_cast<uint32_t>(
        sizeof(coff::CvLineBlockHeader) +
        (sizeof(coff::CvLine) + sizeof(coff::CvColumn)) * rows.length());
    debugS_->u4(block_size);
    for (const LineRow& row : rows) {
      debugS_->u4(row.pc_offset);
      const uint32_t line_field =
          (static_cast<uint32_t>(row.line) & coff::CvLine::kLineMask) |
          coff::CvLine::kIsStatementBit;
      debugS_->u4(line_field);
    }
    for (const LineRow& row : rows) {
      debugS_->u2(static_cast<uint16_t>(
          Utils::Minimum<int32_t>(row.column, kMaxUint16)));
      debugS_->u2(0);  // EndColumn
    }
  });
  debugS_->Align(4);

  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(code_offset_pos), info.label,
       coff::PE_REL_AMD64_SECREL});
  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(section_pos), info.label,
       coff::PE_REL_AMD64_SECTION});
}

// For each LF_FUNC_ID of inlined functions, the script and start line of the
// first inlined function with it, which the binary annotations of the
// S_INLINESITEs with it are relative to.
void CodeViewBuilder::EmitInlineeLinesSubsection() {
  bool has_inlinees = false;
  for (const FuncId& func_id : *func_ids_) {
    has_inlinees = has_inlinees || func_id.inlined != -1;
  }
  if (!has_inlinees) return;
  debugS_->u4(coff::DEBUG_S_INLINEELINES);
  debugS_->WritePrefixedLength([&]() {
    debugS_->u4(coff::CV_INLINEE_SOURCE_LINE_SIGNATURE);
    for (const FuncId& func_id : *func_ids_) {
      if (func_id.inlined == -1) continue;
      debugS_->u4(func_id.type_index);  // Inlinee
      // FileID (file checksum offset)
      debugS_->u4((*script_checksum_offsets_)[func_id.inlined_file_index]);
      debugS_->u4(func_id.inlined_start_line);  // SourceLineNum
    }
  });
  debugS_->Align(4);
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
  GatherCodes();
  ComputeScriptTables();

  const auto& codes = writer_->debug_codes();
  ASSERT(codes_->length() == codes.length());
  for (intptr_t i = 0; i < codes.length(); i++) {
    CodeInfo& info = (*codes_)[i];
    if (info.name == nullptr) continue;
    GatherLocations(&info, *(codes[i]));
  }

  EmitTypeRecords();

  debugS_->u4(coff::CV_SIGNATURE_C13);
  EmitObjectAndCompileSymbolsSubsection();
  for (intptr_t i = 0; i < codes.length(); i++) {
    const CodeInfo& info = (*codes_)[i];
    if (info.name == nullptr) continue;
    const Code& code = *(codes[i]);
    EmitFunctionSymbolsSubsection(info, code);
    EmitLinesSubsection(info, code);
  }
  EmitInlineeLinesSubsection();
  EmitFileChecksumsSubsection();
  EmitStringTableSubsection();
}

}  // namespace dart

#endif  // DART_PRECOMPILER
