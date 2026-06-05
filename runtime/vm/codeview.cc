// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/codeview.h"

#if defined(DART_PRECOMPILER)

#include "vm/code_descriptors.h"
#include "vm/coff.h"
#include "vm/datastream.h"
#include "vm/dwarf.h"
#include "vm/flags.h"
#include "vm/hash_map.h"
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/version.h"

namespace dart {

DECLARE_FLAG(bool, resolve_dwarf_paths);

// URI prefix stripping copied (intentionally) from runtime/vm/dwarf.cc so the
// CodeView and DWARF emitters resolve script URIs identically when
// --resolve-dwarf-paths is set.  Keeping this here avoids exposing the helper
// as a public surface area on Dwarf.
static constexpr char kResolvedFileRoot[] = "file:///";
static constexpr intptr_t kResolvedFileRootLen = sizeof(kResolvedFileRoot) - 1;
static constexpr char kResolvedFlutterRoot[] = "org-dartlang-sdk:///flutter/";
static constexpr intptr_t kResolvedFlutterRootLen =
    sizeof(kResolvedFlutterRoot) - 1;
static constexpr char kResolvedSdkRoot[] = "org-dartlang-sdk:///";
static constexpr intptr_t kResolvedSdkRootLen = sizeof(kResolvedSdkRoot) - 1;
static constexpr char kResolvedGoogle3Root[] = "google3:///";
static constexpr intptr_t kResolvedGoogle3RootLen =
    sizeof(kResolvedGoogle3Root) - 1;

static const char* ConvertResolvedURI(const char* str) {
  const intptr_t len = strlen(str);
  if (len > kResolvedFileRootLen &&
      strncmp(str, kResolvedFileRoot, kResolvedFileRootLen) == 0) {
#if defined(DART_HOST_OS_WINDOWS)
    return str + kResolvedFileRootLen;
#else
    return str + kResolvedFileRootLen - 1;
#endif
  }
  if (len > kResolvedFlutterRootLen &&
      strncmp(str, kResolvedFlutterRoot, kResolvedFlutterRootLen) == 0) {
    return str + kResolvedFlutterRootLen;
  }
  if (len > kResolvedSdkRootLen &&
      strncmp(str, kResolvedSdkRoot, kResolvedSdkRootLen) == 0) {
    return str + kResolvedSdkRootLen;
  }
  if (len > kResolvedGoogle3RootLen &&
      strncmp(str, kResolvedGoogle3Root, kResolvedGoogle3RootLen) == 0) {
    return str + kResolvedGoogle3RootLen;
  }
  return nullptr;
}

CodeViewBuilder::CodeViewBuilder(Zone* zone, CoffWriter* writer)
    : zone_(zone),
      writer_(writer),
      functions_(new (zone) ZoneGrowableArray<FunctionInfo>(zone, 64)),
      debugS_(new (zone) ZoneGrowableArray<uint8_t>(zone, 4096)),
      debugT_(new (zone) ZoneGrowableArray<uint8_t>(zone, 1024)),
      script_string_offsets_(new (zone) ZoneGrowableArray<uint32_t>(zone, 16)),
      script_checksum_offsets_(new (zone)
                                   ZoneGrowableArray<uint32_t>(zone, 16)) {}

// ----------------------------------------------------------------------------
// Byte-stream helpers
// ----------------------------------------------------------------------------

void CodeViewBuilder::AppendByte(ZoneGrowableArray<uint8_t>* buf, uint8_t v) {
  buf->Add(v);
}

void CodeViewBuilder::AppendU16(ZoneGrowableArray<uint8_t>* buf, uint16_t v) {
  buf->Add(static_cast<uint8_t>(v & 0xff));
  buf->Add(static_cast<uint8_t>((v >> 8) & 0xff));
}

void CodeViewBuilder::AppendU32(ZoneGrowableArray<uint8_t>* buf, uint32_t v) {
  buf->Add(static_cast<uint8_t>(v & 0xff));
  buf->Add(static_cast<uint8_t>((v >> 8) & 0xff));
  buf->Add(static_cast<uint8_t>((v >> 16) & 0xff));
  buf->Add(static_cast<uint8_t>((v >> 24) & 0xff));
}

void CodeViewBuilder::AppendBytes(ZoneGrowableArray<uint8_t>* buf,
                                  const void* p,
                                  intptr_t n) {
  const uint8_t* bytes = static_cast<const uint8_t*>(p);
  for (intptr_t i = 0; i < n; i++)
    buf->Add(bytes[i]);
}

void CodeViewBuilder::AppendString(ZoneGrowableArray<uint8_t>* buf,
                                   const char* s) {
  intptr_t len = strlen(s);
  for (intptr_t i = 0; i < len; i++)
    buf->Add(static_cast<uint8_t>(s[i]));
  buf->Add(0);  // NUL terminator
}

void CodeViewBuilder::Align4(ZoneGrowableArray<uint8_t>* buf) {
  while ((buf->length() & 3) != 0)
    buf->Add(0);
}

// ----------------------------------------------------------------------------
// Script URI resolution
// ----------------------------------------------------------------------------

// Returns a zone-owned, NUL-terminated path string for `script`, applying the
// same prefix stripping as the DWARF writer when --resolve-dwarf-paths is set.
// Falls back to the raw URL when the conversion would otherwise fail, so
// CodeView never aborts gen_snapshot the way the DWARF path does.
const char* CodeViewBuilder::ResolvedScriptUri(const Script& script) {
  String& uri = String::Handle(zone_, String::null());
  if (FLAG_resolve_dwarf_paths) {
    uri = script.resolved_url();
    if (!uri.IsNull()) {
      const char* converted = ConvertResolvedURI(uri.ToCString());
      if (converted != nullptr) {
        return OS::SCreate(zone_, "%s", converted);
      }
    }
  }
  uri = script.url();
  if (uri.IsNull()) {
    return OS::SCreate(zone_, "<unknown>");
  }
  const Dwarf* dwarf = writer_->dwarf();
  const char* raw = uri.ToCString();
  const char* deobf = ImageWriter::Deobfuscate(
      zone_, dwarf == nullptr ? nullptr : dwarf->deobfuscation_trie(), raw);
  if (deobf == nullptr || deobf[0] == '\0') {
    return OS::SCreate(zone_, "<unknown>");
  }
  return OS::SCreate(zone_, "%s", deobf);
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
  uint32_t string_offset = 1;
  const Dwarf* dwarf = writer_->dwarf();
  ASSERT(dwarf != nullptr);
  const auto& scripts = dwarf->scripts();
  for (intptr_t i = 0; i < scripts.length(); i++) {
    const Script& script = *(scripts[i]);
    const char* uri = ResolvedScriptUri(script);
    script_string_offsets_->Add(string_offset);
    string_offset += static_cast<uint32_t>(strlen(uri)) + 1;  // include NUL
    script_checksum_offsets_->Add(static_cast<uint32_t>(i * 8));
  }
}

// ----------------------------------------------------------------------------
// Function gathering: one CodeView function per Dart Code.
// ----------------------------------------------------------------------------

void CodeViewBuilder::GatherFunctions() {
  const Dwarf* dwarf = writer_->dwarf();
  ASSERT(dwarf != nullptr);
  const auto& codes = dwarf->codes();

  Function& function = Function::Handle(zone_);
  String& name = String::Handle(zone_);
  Class& cls = Class::Handle(zone_);
  Library& lib = Library::Handle(zone_);
  const Library& root_library = Library::Handle(
      zone_, IsolateGroup::Current()->object_store()->root_library());

  for (intptr_t i = 0; i < codes.length(); i++) {
    const Code& code = *(codes[i]);
    const bool is_dart_function_code =
        code.IsFunctionCode() && !code.IsUnknownDartCode();
    const intptr_t label = dwarf->LookupCodeLabel(code);
    if (label <= 0) continue;

    // The per-Code symbol added by BlobImageWriter::AddCodeSymbol got handed to
    // CoffWriter::AddText, which inserted it as a static symbol with the
    // absolute offset within .text recorded in CoffSym::value.  Look that up
    // here -- this is the same offset the linker will use when resolving the
    // SECREL relocation against the .text section symbol.
    if (!writer_->label_to_symbol_index_.HasKey(label)) continue;
    const intptr_t sym_idx = writer_->label_to_symbol_index_.Lookup(label);
    if (sym_idx <= 0 || sym_idx > writer_->symbols_->length()) continue;
    const auto& sym = (*writer_->symbols_)[sym_idx - 1];
    // section_number is still the pre-assignment sentinel here (-1 == .text).
    if (sym.section_number != -1) continue;

    FunctionInfo fn;
    fn.label = label;
    fn.text_offset = sym.value;
    fn.size = code.Size();
    fn.string_id_type = 0;
    fn.func_id_type = 0;
    fn.prefer_plain_name = false;

    if (!is_dart_function_code) {
      // No Dart-level function (stubs etc.) -- use the COFF symbol name we
      // already chose for this Code so the .pdb at least shows that.
      fn.name = sym.name != nullptr ? OS::SCreate(zone_, "%s", sym.name)
                                    : OS::SCreate(zone_, "code_%" Pd, label);
    } else {
      function = code.function();
      if (function.IsNull()) continue;
      name = function.QualifiedUserVisibleName();
      const char* raw_name = name.ToCString();
      const char* deob_name = ImageWriter::Deobfuscate(
          zone_, dwarf->deobfuscation_trie(), raw_name);
      if (deob_name == nullptr || deob_name[0] == '\0') {
        deob_name = sym.name != nullptr ? sym.name : "<anonymous>";
      }
      fn.name = OS::SCreate(zone_, "%s", deob_name);

      cls = function.Owner();
      lib = cls.library();
      fn.prefer_plain_name = !root_library.IsNull() &&
                             (lib.ptr() == root_library.ptr()) &&
                             (strcmp(fn.name, "main") == 0);
    }
    functions_->Add(fn);
  }
}

void CodeViewBuilder::DisambiguateFunctionNames() {
  CStringIntMap usage_count(zone_);
  auto claim_name = [&](FunctionInfo& fn) {
    auto* const pair = usage_count.Lookup(fn.name);
    if (pair == nullptr) {
      usage_count.Insert({fn.name, 1});
      return;
    }
    fn.name = OS::SCreate(zone_, "%s (#%" Pd ")", fn.name, ++pair->value);
  };

  for (intptr_t i = 0; i < functions_->length(); i++) {
    FunctionInfo& fn = (*functions_)[i];
    if (fn.prefer_plain_name) {
      claim_name(fn);
    }
  }
  for (intptr_t i = 0; i < functions_->length(); i++) {
    FunctionInfo& fn = (*functions_)[i];
    if (!fn.prefer_plain_name) {
      claim_name(fn);
    }
  }
}

// ----------------------------------------------------------------------------
// .debug$T type records
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitTypeRecords() {
  // Leading signature.
  AppendU32(debugT_, coff::CV_SIGNATURE_C13);

  // LF_ARGLIST (empty).
  {
    const intptr_t start = debugT_->length();
    AppendU16(debugT_, 0);  // length placeholder
    AppendU16(debugT_, coff::LF_ARGLIST);
    AppendU32(debugT_, 0);  // count
    while (((debugT_->length() - start) & 3) != 0)
      AppendByte(debugT_, 0);
    const uint16_t len = static_cast<uint16_t>(debugT_->length() - start - 2);
    (*debugT_)[start] = static_cast<uint8_t>(len & 0xff);
    (*debugT_)[start + 1] = static_cast<uint8_t>((len >> 8) & 0xff);
    arglist_type_ = next_type_index_++;
  }

  // LF_PROCEDURE (rvtype=T_VOID, calltype=C_NEAR_C, parmcount=0, arglist).
  {
    const intptr_t start = debugT_->length();
    AppendU16(debugT_, 0);
    AppendU16(debugT_, coff::LF_PROCEDURE);
    AppendU32(debugT_, coff::T_VOID);
    AppendByte(debugT_, coff::CV_CALL_NEAR_C);
    AppendByte(debugT_, 0);  // func attrs
    AppendU16(debugT_, 0);   // param count
    AppendU32(debugT_, arglist_type_);
    while (((debugT_->length() - start) & 3) != 0)
      AppendByte(debugT_, 0);
    const uint16_t len = static_cast<uint16_t>(debugT_->length() - start - 2);
    (*debugT_)[start] = static_cast<uint8_t>(len & 0xff);
    (*debugT_)[start + 1] = static_cast<uint8_t>((len >> 8) & 0xff);
    procedure_type_ = next_type_index_++;
  }

  // For each function: LF_STRING_ID then LF_FUNC_ID.
  for (intptr_t i = 0; i < functions_->length(); i++) {
    FunctionInfo& fn = (*functions_)[i];
    // LF_STRING_ID with the function's name.
    {
      const intptr_t start = debugT_->length();
      AppendU16(debugT_, 0);
      AppendU16(debugT_, coff::LF_STRING_ID);
      AppendU32(debugT_, 0);  // substring
      AppendString(debugT_, fn.name);
      while (((debugT_->length() - start) & 3) != 0)
        AppendByte(debugT_, 0);
      const uint16_t len = static_cast<uint16_t>(debugT_->length() - start - 2);
      (*debugT_)[start] = static_cast<uint8_t>(len & 0xff);
      (*debugT_)[start + 1] = static_cast<uint8_t>((len >> 8) & 0xff);
      fn.string_id_type = next_type_index_++;
    }
    // LF_FUNC_ID.
    {
      const intptr_t start = debugT_->length();
      AppendU16(debugT_, 0);
      AppendU16(debugT_, coff::LF_FUNC_ID);
      AppendU32(debugT_, 0);  // parent scope
      AppendU32(debugT_, procedure_type_);
      AppendString(debugT_, fn.name);
      while (((debugT_->length() - start) & 3) != 0)
        AppendByte(debugT_, 0);
      const uint16_t len = static_cast<uint16_t>(debugT_->length() - start - 2);
      (*debugT_)[start] = static_cast<uint8_t>(len & 0xff);
      (*debugT_)[start + 1] = static_cast<uint8_t>((len >> 8) & 0xff);
      fn.func_id_type = next_type_index_++;
    }
  }
}

// ----------------------------------------------------------------------------
// .debug$S subsections
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitOneFunctionSymbol(const FunctionInfo& fn) {
  // S_GPROC32_ID.
  const intptr_t rec_start = debugS_->length();
  AppendU16(debugS_, 0);  // record length placeholder
  AppendU16(debugS_, coff::S_GPROC32_ID);
  AppendU32(debugS_, 0);  // Parent
  AppendU32(debugS_, 0);  // End (would patch with offset to S_PROC_ID_END)
  AppendU32(debugS_, 0);  // Next
  AppendU32(debugS_, static_cast<uint32_t>(fn.size));  // CodeSize
  AppendU32(debugS_, 0);                               // DebugStart
  AppendU32(debugS_, static_cast<uint32_t>(fn.size));  // DebugEnd
  AppendU32(debugS_, fn.func_id_type);  // FunctionType (LF_FUNC_ID index)
  // CodeOffset slot -- SECREL relocation against this function's COFF symbol.
  const intptr_t code_offset_pos = debugS_->length();
  AppendU32(debugS_, 0);  // inline addend
  // Segment slot -- SECTION relocation against this function's COFF symbol.
  const intptr_t segment_pos = debugS_->length();
  AppendU16(debugS_, 0);
  AppendByte(debugS_, 0);  // flags
  AppendString(debugS_, fn.name);
  // Align record to 4.
  while (((debugS_->length() - rec_start) & 3) != 0)
    AppendByte(debugS_, 0);
  // Patch length.
  const uint16_t rl = static_cast<uint16_t>(debugS_->length() - rec_start - 2);
  (*debugS_)[rec_start] = static_cast<uint8_t>(rl & 0xff);
  (*debugS_)[rec_start + 1] = static_cast<uint8_t>((rl >> 8) & 0xff);

  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(code_offset_pos), fn.label,
       coff::PE_REL_AMD64_SECREL});
  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(segment_pos), fn.label,
       coff::PE_REL_AMD64_SECTION});

  // S_FRAMEPROC.
  {
    const intptr_t fp_start = debugS_->length();
    AppendU16(debugS_, 0);
    AppendU16(debugS_, coff::S_FRAMEPROC);
    AppendU32(debugS_, 0);  // frame size
    AppendU32(debugS_, 0);  // padding size
    AppendU32(debugS_, 0);  // offset to padding
    AppendU32(debugS_, 0);  // bytes of callee-saved regs
    AppendU32(debugS_, 0);  // offset of exception handler
    AppendU16(debugS_, 0);  // section of exception handler
    // Flags: EncodedLocalBasePointer=rbp (bits 14-15 == 0b01).
    AppendU32(debugS_, (1u << 14));
    while (((debugS_->length() - fp_start) & 3) != 0)
      AppendByte(debugS_, 0);
    const uint16_t l = static_cast<uint16_t>(debugS_->length() - fp_start - 2);
    (*debugS_)[fp_start] = static_cast<uint8_t>(l & 0xff);
    (*debugS_)[fp_start + 1] = static_cast<uint8_t>((l >> 8) & 0xff);
  }

  // S_PROC_ID_END.
  {
    AppendU16(debugS_, 2);  // length = 2 (kind only)
    AppendU16(debugS_, coff::S_PROC_ID_END);
  }
}

void CodeViewBuilder::EmitObjectAndCompileSymbolsSubsection() {
  // Subsection header.
  AppendU32(debugS_, coff::DEBUG_S_SYMBOLS);
  const intptr_t length_pos = debugS_->length();
  AppendU32(debugS_, 0);  // length placeholder
  const intptr_t body_start = debugS_->length();

  // S_OBJNAME.
  {
    const intptr_t s = debugS_->length();
    AppendU16(debugS_, 0);
    AppendU16(debugS_, coff::S_OBJNAME);
    AppendU32(debugS_, 0);  // signature
    AppendString(debugS_, "snapshot.obj");
    while (((debugS_->length() - s) & 3) != 0)
      AppendByte(debugS_, 0);
    const uint16_t l = static_cast<uint16_t>(debugS_->length() - s - 2);
    (*debugS_)[s] = static_cast<uint8_t>(l & 0xff);
    (*debugS_)[s + 1] = static_cast<uint8_t>((l >> 8) & 0xff);
  }

  // S_COMPILE3.
  {
    const intptr_t s = debugS_->length();
    AppendU16(debugS_, 0);
    AppendU16(debugS_, coff::S_COMPILE3);
    AppendU32(debugS_, static_cast<uint32_t>(coff::CV_CFL_C));
    AppendU16(debugS_, coff::CV_CFL_X64);
    AppendU16(debugS_, 0);  // FE Major
    AppendU16(debugS_, 0);  // FE Minor
    AppendU16(debugS_, 0);  // FE Build
    AppendU16(debugS_, 0);  // FE QFE
    AppendU16(debugS_, 0);  // BE Major
    AppendU16(debugS_, 0);  // BE Minor
    AppendU16(debugS_, 0);  // BE Build
    AppendU16(debugS_, 0);  // BE QFE
    AppendString(debugS_, "Dart AOT");
    while (((debugS_->length() - s) & 3) != 0)
      AppendByte(debugS_, 0);
    const uint16_t l = static_cast<uint16_t>(debugS_->length() - s - 2);
    (*debugS_)[s] = static_cast<uint8_t>(l & 0xff);
    (*debugS_)[s + 1] = static_cast<uint8_t>((l >> 8) & 0xff);
  }

  // Patch subsection length.
  const uint32_t body_len =
      static_cast<uint32_t>(debugS_->length() - body_start);
  (*debugS_)[length_pos + 0] = static_cast<uint8_t>(body_len & 0xff);
  (*debugS_)[length_pos + 1] = static_cast<uint8_t>((body_len >> 8) & 0xff);
  (*debugS_)[length_pos + 2] = static_cast<uint8_t>((body_len >> 16) & 0xff);
  (*debugS_)[length_pos + 3] = static_cast<uint8_t>((body_len >> 24) & 0xff);

  Align4(debugS_);
}

void CodeViewBuilder::EmitFunctionSymbolsSubsection(const FunctionInfo& fn) {
  AppendU32(debugS_, coff::DEBUG_S_SYMBOLS);
  const intptr_t length_pos = debugS_->length();
  AppendU32(debugS_, 0);  // length placeholder
  const intptr_t body_start = debugS_->length();

  EmitOneFunctionSymbol(fn);

  const uint32_t body_len =
      static_cast<uint32_t>(debugS_->length() - body_start);
  (*debugS_)[length_pos + 0] = static_cast<uint8_t>(body_len & 0xff);
  (*debugS_)[length_pos + 1] = static_cast<uint8_t>((body_len >> 8) & 0xff);
  (*debugS_)[length_pos + 2] = static_cast<uint8_t>((body_len >> 16) & 0xff);
  (*debugS_)[length_pos + 3] = static_cast<uint8_t>((body_len >> 24) & 0xff);

  Align4(debugS_);
}

// ----------------------------------------------------------------------------
// Per-function line tables: walk each Code's CodeSourceMap to build a sequence
// of (pc_offset, file_index, line) rows, then emit one DEBUG_S_LINES subsection
// per Code with the rows grouped into CV_LINE_BLOCKs by file.
// ----------------------------------------------------------------------------

void CodeViewBuilder::EmitLinesSubsection(const FunctionInfo& fn,
                                          const Code& code) {
  Dwarf* dwarf = writer_->dwarf();
  ASSERT(dwarf != nullptr);

  Function& root_function = Function::Handle(zone_);
  Script& script = Script::Handle(zone_);
  CodeSourceMap& map = CodeSourceMap::Handle(zone_);
  Array& functions = Array::Handle(zone_);
  GrowableArray<const Function*> function_stack(zone_, 8);
  // Tracks (line, column) per function-stack entry.
  GrowableArray<int32_t> line_stack(zone_, 8);
  GrowableArray<int32_t> column_stack(zone_, 8);

  // One CV_LINE row.
  struct LineRow {
    uint32_t pc_offset;
    int32_t file_index;  // index into dwarf_->scripts()
    int32_t line;
  };
  GrowableArray<LineRow> rows(zone_, 64);

  if (!code.IsFunctionCode() || code.IsUnknownDartCode()) return;

  map = code.code_source_map();
  if (map.IsNull() || map.Length() == 0) {
    return;
  }
  root_function = code.function();
  if (root_function.IsNull()) return;
  functions = code.inlined_id_to_function();

  function_stack.Clear();
  line_stack.Clear();
  column_stack.Clear();
  function_stack.Add(&root_function);
  line_stack.Add(-1);
  column_stack.Add(-1);

  rows.Clear();
  bool function_entry_position_was_emitted = false;
  int32_t current_pc_offset = 0;

  {
    NoSafepointScope no_safepoint;
    ReadStream code_map_stream(map.Data(), map.Length());

    while (code_map_stream.PendingBytes() > 0) {
      int32_t arg1;
      int32_t arg2 = -1;
      const uint8_t opcode =
          CodeSourceMapOps::Read(&code_map_stream, &arg1, &arg2);
      switch (opcode) {
        case CodeSourceMapOps::kChangePosition: {
          // Mirror DwarfPosition::ChangePosition: line is a delta, column is
          // an absolute value.
          line_stack.Last() = Utils::AddWithWrapAround(line_stack.Last(), arg1);
          column_stack.Last() = arg2;
          break;
        }
        case CodeSourceMapOps::kAdvancePC: {
          bool row_was_emitted = false;
          const Function& f = *(function_stack.Last());
          if (!f.IsNull()) {
            script = f.script();
            // LookupScript returns the 1-based DWARF file number.  We use
            // 0-based indices for our parallel offset tables.
            const intptr_t file_one_based =
                script.IsNull() ? 0 : dwarf->LookupScript(script);
            const intptr_t file = file_one_based - 1;
            const int32_t raw_line = line_stack.Last();
            const int32_t line = raw_line > 0 ? raw_line : 0;
            intptr_t pc_offset_adjustment = 0;
            const bool has_source_position =
                line > 0 || column_stack.Last() > 0;
            bool should_emit = has_source_position;
            if (current_pc_offset == 0 && function_entry_position_was_emitted) {
              pc_offset_adjustment = 1;
              should_emit = !(line == 0 && column_stack.Last() <= 0);
            }
            if (should_emit && file >= 0 && file < dwarf->scripts().length()) {
              LineRow row;
              intptr_t row_pc_offset = current_pc_offset + pc_offset_adjustment;
              if (rows.is_empty() && has_source_position) {
                row_pc_offset = 0;
              }
              row.pc_offset = static_cast<uint32_t>(row_pc_offset);
              row.file_index = static_cast<int32_t>(file);
              row.line = line;
              // Suppress duplicate consecutive rows (same pc, same file,
              // same line) -- the linker rejects DEBUG_S_LINES blocks whose
              // entries don't strictly advance.
              if (rows.is_empty() || rows.Last().pc_offset != row.pc_offset ||
                  rows.Last().file_index != row.file_index ||
                  rows.Last().line != row.line) {
                rows.Add(row);
                row_was_emitted = true;
              }
            }
          }
          current_pc_offset += arg1;
          if (arg1 == 0 && row_was_emitted) {
            ASSERT(current_pc_offset == 0);
            ASSERT(!function_entry_position_was_emitted);
            function_entry_position_was_emitted = true;
          }
          break;
        }
        case CodeSourceMapOps::kPushFunction: {
          auto child_func =
              &Function::Handle(zone_, Function::RawCast(functions.At(arg1)));
          function_stack.Add(child_func);
          line_stack.Add(-1);
          column_stack.Add(-1);
          break;
        }
        case CodeSourceMapOps::kPopFunction: {
          ASSERT(function_stack.length() > 1);
          function_stack.RemoveLast();
          line_stack.RemoveLast();
          column_stack.RemoveLast();
          break;
        }
        case CodeSourceMapOps::kNullCheck: {
          break;
        }
        default:
          UNREACHABLE();
      }
    }
  }

  if (rows.is_empty()) return;

  // Drop trailing rows that walk off the end of the function -- the
  // CodeView spec says CV_LINE Offset must be < CodeSize.
  while (!rows.is_empty() &&
         rows.Last().pc_offset >= static_cast<uint32_t>(fn.size)) {
    rows.RemoveLast();
  }
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

  AppendU32(debugS_, coff::DEBUG_S_LINES);
  const intptr_t length_pos = debugS_->length();
  AppendU32(debugS_, 0);  // length placeholder
  const intptr_t body_start = debugS_->length();

  // DEBUG_S_LINES section header.
  const intptr_t code_offset_pos = debugS_->length();
  AppendU32(debugS_, 0);  // inline addend
  const intptr_t section_pos = debugS_->length();
  AppendU16(debugS_, 0);  // Section (SECTION reloc)
  AppendU16(debugS_, 0);  // Flags
  AppendU32(debugS_, static_cast<uint32_t>(fn.size));  // CodeSize

  for (intptr_t b = 0; b < blocks.length(); b++) {
    const Block& blk = blocks[b];
    const uint32_t chksm_offset = (*script_checksum_offsets_)[blk.file_index];
    AppendU32(debugS_, chksm_offset);  // NameIndex (file checksum offset)
    AppendU32(debugS_, static_cast<uint32_t>(blk.count));
    // BlockSize = sizeof(CvLineBlockHeader) + count * sizeof(CvLine)
    //          = 12 + 8 * count
    const uint32_t block_size = static_cast<uint32_t>(12 + 8 * blk.count);
    AppendU32(debugS_, block_size);

    for (intptr_t r = blk.start; r < blk.start + blk.count; r++) {
      AppendU32(debugS_, rows[r].pc_offset);
      const uint32_t line_field =
          (static_cast<uint32_t>(rows[r].line) & 0xffffffu) | (1u << 31);
      AppendU32(debugS_, line_field);
    }
  }

  const uint32_t body_len =
      static_cast<uint32_t>(debugS_->length() - body_start);
  (*debugS_)[length_pos + 0] = static_cast<uint8_t>(body_len & 0xff);
  (*debugS_)[length_pos + 1] = static_cast<uint8_t>((body_len >> 8) & 0xff);
  (*debugS_)[length_pos + 2] = static_cast<uint8_t>((body_len >> 16) & 0xff);
  (*debugS_)[length_pos + 3] = static_cast<uint8_t>((body_len >> 24) & 0xff);

  Align4(debugS_);

  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(code_offset_pos), fn.label,
       coff::PE_REL_AMD64_SECREL});
  writer_->by_kind_[CoffWriter::kSecDebugS]->relocs->Add(
      {static_cast<uint32_t>(section_pos), fn.label,
       coff::PE_REL_AMD64_SECTION});
}

void CodeViewBuilder::EmitFileChecksumsSubsection() {
  AppendU32(debugS_, coff::DEBUG_S_FILECHKSMS);
  const intptr_t length_pos = debugS_->length();
  AppendU32(debugS_, 0);  // length placeholder
  const intptr_t body_start = debugS_->length();

  const Dwarf* dwarf = writer_->dwarf();
  ASSERT(dwarf != nullptr);
  const auto& scripts = dwarf->scripts();
  for (intptr_t i = 0; i < scripts.length(); i++) {
    // Each entry is exactly 8 bytes (6 payload + 2 padding), matching the
    // layout assumed by ComputeScriptTables.
    AppendU32(debugS_, (*script_string_offsets_)[i]);  // NameOffset
    AppendByte(debugS_, 0);                            // ChecksumSize
    AppendByte(debugS_, coff::CHKSUM_TYPE_NONE);
    AppendByte(debugS_, 0);  // padding
    AppendByte(debugS_, 0);  // padding
  }

  const uint32_t body_len =
      static_cast<uint32_t>(debugS_->length() - body_start);
  (*debugS_)[length_pos + 0] = static_cast<uint8_t>(body_len & 0xff);
  (*debugS_)[length_pos + 1] = static_cast<uint8_t>((body_len >> 8) & 0xff);
  (*debugS_)[length_pos + 2] = static_cast<uint8_t>((body_len >> 16) & 0xff);
  (*debugS_)[length_pos + 3] = static_cast<uint8_t>((body_len >> 24) & 0xff);

  Align4(debugS_);
}

void CodeViewBuilder::EmitStringTableSubsection() {
  AppendU32(debugS_, coff::DEBUG_S_STRINGTABLE);
  const intptr_t length_pos = debugS_->length();
  AppendU32(debugS_, 0);  // length placeholder
  const intptr_t body_start = debugS_->length();

  // Leading mandatory empty string.
  AppendByte(debugS_, 0);

  const Dwarf* dwarf = writer_->dwarf();
  ASSERT(dwarf != nullptr);
  const auto& scripts = dwarf->scripts();
  for (intptr_t i = 0; i < scripts.length(); i++) {
    const Script& script = *(scripts[i]);
    const char* uri = ResolvedScriptUri(script);
    AppendString(debugS_, uri);
  }

  const uint32_t body_len =
      static_cast<uint32_t>(debugS_->length() - body_start);
  (*debugS_)[length_pos + 0] = static_cast<uint8_t>(body_len & 0xff);
  (*debugS_)[length_pos + 1] = static_cast<uint8_t>((body_len >> 8) & 0xff);
  (*debugS_)[length_pos + 2] = static_cast<uint8_t>((body_len >> 16) & 0xff);
  (*debugS_)[length_pos + 3] = static_cast<uint8_t>((body_len >> 24) & 0xff);

  Align4(debugS_);
}

// ----------------------------------------------------------------------------
// Build
// ----------------------------------------------------------------------------

void CodeViewBuilder::Build() {
  GatherFunctions();
  DisambiguateFunctionNames();
  ComputeScriptTables();

  EmitTypeRecords();

  AppendU32(debugS_, coff::CV_SIGNATURE_C13);
  EmitObjectAndCompileSymbolsSubsection();
  for (intptr_t i = 0; i < writer_->dwarf()->codes().length(); i++) {
    const Code& code = *(writer_->dwarf()->codes()[i]);
    const intptr_t label = writer_->dwarf()->LookupCodeLabel(code);
    if (label <= 0) continue;
    for (intptr_t f = 0; f < functions_->length(); f++) {
      const FunctionInfo& fn = (*functions_)[f];
      if (fn.label == label) {
        EmitFunctionSymbolsSubsection(fn);
        EmitLinesSubsection(fn, code);
        break;
      }
    }
  }
  EmitFileChecksumsSubsection();
  EmitStringTableSubsection();

  // Flush both buffers into the CoffWriter sections.
  auto* ds = writer_->by_kind_[CoffWriter::kSecDebugS];
  for (intptr_t i = 0; i < debugS_->length(); i++) {
    ds->data->Add((*debugS_)[i]);
  }
  auto* dt = writer_->by_kind_[CoffWriter::kSecDebugT];
  for (intptr_t i = 0; i < debugT_->length(); i++) {
    dt->data->Add((*debugT_)[i]);
  }
}

}  // namespace dart

#endif  // DART_PRECOMPILER
