// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CODEVIEW_H_
#define RUNTIME_VM_CODEVIEW_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

#include "platform/coff.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/hash_map.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

class CoffWriter;
class DebugInfoStream;

// Translates the Dart debug metadata into Microsoft CodeView records embedded
// in .debug$S (symbols + line numbers) and .debug$T (types).  The output is
// designed so that `link.exe /DEBUG` synthesizes a Microsoft .pdb compatible
// with WinDbg / Visual Studio.
//
// Owned by CoffWriter; appends bytes and relocations directly into the
// CoffWriter's .debug$S / .debug$T sections.
class CodeViewBuilder : public ZoneObject {
 public:
  CodeViewBuilder(Zone* zone,
                  CoffWriter* writer,
                  DebugInfoStream* debug_s,
                  DebugInfoStream* debug_t);

  // Populate the .debug$S and .debug$T sections.  Caller (CoffWriter::Finalize)
  // must have created both sections before calling.
  void Build();

 private:
  // A row of a line table: the location of the code starting at pc_offset,
  // which is relative to the start of the function. The rows of a function,
  // or of a call to an inlined function, are in the script of that function.
  struct LineRow {
    uint32_t pc_offset;
    int32_t line;
    int32_t column;
  };

  // A call to an inlined function, which covers the code at
  // [start_pc_offset, end_pc_offset) of the function.
  struct InlineSite : public ZoneObject {
    InlineSite(Zone* zone, const Function& function, uint32_t start_pc_offset)
        : function(function),
          start_pc_offset(start_pc_offset),
          rows(new (zone) ZoneGrowableArray<LineRow>(zone, 4)),
          children(new (zone) ZoneGrowableArray<InlineSite*>(zone, 0)) {}

    const Function& function;
    const uint32_t start_pc_offset;
    uint32_t end_pc_offset = 0;
    // The locations in the inlined function.
    ZoneGrowableArray<LineRow>* const rows;
    // The calls to functions inlined into the inlined function.
    ZoneGrowableArray<InlineSite*>* const children;
  };

  // An LF_FUNC_ID type record. Functions with the same name share their
  // LF_FUNC_ID, as the linker would merge their identical records anyway.
  struct FuncId {
    const char* name;
    uint32_t type_index = 0;  // assigned by EmitTypeRecords
    // The debug function index of the first inlined function with this
    // LF_FUNC_ID, or -1 if no function with it is inlined. Its script and
    // start line are in the DEBUG_S_INLINEELINES entry of the LF_FUNC_ID.
    intptr_t inlined = -1;
    int32_t inlined_file_index = -1;
    int32_t inlined_start_line = 0;
  };

  // CodeView metadata of a function, indexed by debug function index.
  struct FunctionInfo {
    intptr_t func_id = -1;  // index into func_ids_
  };

  // CodeView metadata of a Code, indexed like CoffWriter::debug_codes().
  struct CodeInfo {
    const char* name = nullptr;
    // The VM-internal label registered with debug info/Coff.
    intptr_t label = 0;
    // The index of the LF_FUNC_ID in func_ids_.
    intptr_t func_id = -1;
    // Whether the function is visible in stack traces.
    bool is_visible = true;
    // The index of the script of the function, or -1 if there is none.
    int32_t file_index = -1;
    // The locations in the function itself.
    ZoneGrowableArray<LineRow>* rows = nullptr;
    // The calls to functions inlined into the function.
    ZoneGrowableArray<InlineSite*>* inline_sites = nullptr;
  };

  // .debug$T helpers.
  void EmitTypeRecords();
  uint32_t EmitFuncIdRecord(const char* name);

  // .debug$S helpers.
  void EmitObjectAndCompileSymbolsSubsection();
  void EmitFunctionSymbolsSubsection(const CodeInfo& info, const Code& code);
  void EmitLinesSubsection(const CodeInfo& info, const Code& code);
  void EmitInlineeLinesSubsection();
  void EmitFileChecksumsSubsection();
  void EmitStringTableSubsection();

  // Returns the index of the LF_FUNC_ID for [name] in func_ids_.
  intptr_t AddFuncId(const char* name);
  void GatherFunctions();
  void GatherCodes();
  void GatherLocations(CodeInfo* info, const Code& code);
  void ComputeScriptTables();
  void EmitOneFunctionSymbol(const CodeInfo& info, const Code& code);
  void EmitInlineSite(const InlineSite& site);

  // Returns the name of [function] to use in the debugging information.
  const char* FunctionName(const Function& function);
  // Returns the index of the script of [function] in the debug script table.
  int32_t ScriptIndex(const Function& function);
  // Returns the line on which [function] starts, or 0 if unknown.
  int32_t StartLine(const Function& function);

  // Returns a zone-owned, NUL-terminated path string for `script`, honoring
  // --resolve-dwarf-paths and the obfuscation trie.
  const char* ResolvedScriptUri(const Script& script);

  Zone* const zone_;
  // CodeViewBuilder is allocated and used synchronously by
  // CoffWriter::EmitCodeView() during CoffWriter::Finalize(). The CoffWriter
  // and the debug streams owned by its .debug$S/.debug$T Sections therefore
  // remain valid for the builder's lifetime, before the sections are laid out
  // and written.
  CoffWriter* const writer_;
  DebugInfoStream* const debugS_;
  DebugInfoStream* const debugT_;

  // The LF_FUNC_ID records, and their indices by name.
  ZoneGrowableArray<FuncId>* func_ids_;
  CStringIntMap func_id_indices_;

  // Parallel to CoffWriter::debug_functions().
  ZoneGrowableArray<FunctionInfo>* functions_;
  // Parallel to CoffWriter::debug_codes().
  ZoneGrowableArray<CodeInfo>* codes_;

  // Parallel arrays indexed by debug script index.  Computed
  // by ComputeScriptTables() so EmitLines can stamp checksum-offsets directly
  // into CV_LINE_BLOCK headers.
  ZoneGrowableArray<uint32_t>* script_string_offsets_;
  ZoneGrowableArray<uint32_t>* script_checksum_offsets_;

  // The next available LF_* type index (CodeView starts user types at 0x1000).
  uint32_t next_type_index_ = 0x1000;
  uint32_t arglist_type_ = 0;
  uint32_t procedure_type_ = 0;

  DISALLOW_COPY_AND_ASSIGN(CodeViewBuilder);
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_CODEVIEW_H_
