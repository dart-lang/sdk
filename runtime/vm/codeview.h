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

class DebugInfoStream;
class Dwarf;

// Translates the Dart debug metadata into Microsoft CodeView records embedded
// in .debug$S (symbols + line numbers) and .debug$T (types).  The output is
// designed so that `link.exe /DEBUG` synthesizes a Microsoft .pdb compatible
// with WinDbg / Visual Studio.
//
// Used by CoffWriter for PE/COFF snapshots, and by AssemblyImageWriter for
// assembly snapshots for Windows, which write the records and the relocations
// of .debug$S to their output.
class CodeViewBuilder : public ZoneObject {
 public:
  // A field of .debug$S that the linker sets to the location of the symbol of
  // a Code.
  struct Relocation {
    enum class Kind {
      // The 32-bit offset of the symbol in its section (SECREL).
      kSectionOffset,
      // The 16-bit index of the section of the symbol (SECTION).
      kSectionIndex,
    };

    // The offset of the field in .debug$S.
    intptr_t offset;
    // The label of the Code.
    intptr_t label;
    Kind kind;
  };

  // Writes the records of the Codes in [dwarf] whose labels [code_symbols]
  // maps to the names of their symbols in the text section. Other labels in
  // [code_symbols] are ignored.
  CodeViewBuilder(Zone* zone,
                  Dwarf* dwarf,
                  const IntMap<const char*>& code_symbols,
                  DebugInfoStream* debug_s,
                  DebugInfoStream* debug_t);

  // Populate the .debug$S and .debug$T sections.
  void Build();

  // The relocations of .debug$S, in increasing order of offset.
  const GrowableArray<Relocation>& relocations() const { return relocations_; }

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

  // CodeView metadata of a Code, indexed like Dwarf::codes().
  struct CodeInfo {
    const char* name = nullptr;
    // The label of the Code.
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
  // Writes a field that the linker sets to the [kind] of location of the
  // symbol of the Code with [label].
  void WriteRelocatedField(intptr_t label, Relocation::Kind kind);
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
  Dwarf* const dwarf_;
  const IntMap<const char*>& code_symbols_;
  DebugInfoStream* const debugS_;
  DebugInfoStream* const debugT_;
  GrowableArray<Relocation> relocations_;

  // The LF_FUNC_ID records, and their indices by name.
  ZoneGrowableArray<FuncId>* func_ids_;
  CStringIntMap func_id_indices_;

  // Parallel to Dwarf::functions().
  ZoneGrowableArray<FunctionInfo>* functions_;
  // Parallel to Dwarf::codes().
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
