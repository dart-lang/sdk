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
  // Per-function CodeView metadata.
  struct FunctionInfo {
    const char* name = nullptr;
    intptr_t label = 0;  // VM-internal label registered with debug info/Coff
    uint32_t func_id_type = 0;  // LF_FUNC_ID type index
  };

  // .debug$T helpers.
  void EmitTypeRecords();

  // .debug$S helpers.
  void EmitObjectAndCompileSymbolsSubsection();
  void EmitFunctionSymbolsSubsection(const FunctionInfo& fn, const Code& code);
  void EmitLinesSubsection(const FunctionInfo& fn, const Code& code);
  void EmitFileChecksumsSubsection();
  void EmitStringTableSubsection();

  void GatherFunctions();
  void ComputeScriptTables();
  void EmitOneFunctionSymbol(const FunctionInfo& fn, const Code& code);

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

  ZoneGrowableArray<FunctionInfo>* functions_;

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
