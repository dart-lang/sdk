// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
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
class Dwarf;

// Translates the Dart Dwarf model into Microsoft CodeView records embedded in
// .debug$S (symbols + line numbers) and .debug$T (types).  The output is
// designed so that `link.exe /DEBUG` synthesizes a Microsoft .pdb compatible
// with WinDbg / Visual Studio.
//
// Owned by CoffWriter; appends bytes and relocations directly into the
// CoffWriter's .debug$S / .debug$T sections.
class CodeViewBuilder : public ZoneObject {
 public:
  CodeViewBuilder(Zone* zone, CoffWriter* writer);

  // Populate the .debug$S and .debug$T sections.  Caller (CoffWriter::Finalize)
  // must have created both sections before calling.
  void Build();

 private:
  // Per-function helpers (called from EmitSymbolsSubsection).
  struct FunctionInfo {
    const char* name;
    intptr_t
        text_offset;  // byte offset within .text where this function starts
    intptr_t size;
    intptr_t label;  // VM-internal label registered with both Dwarf and Coff
    uint32_t func_id_type;    // LF_FUNC_ID type index
    uint32_t string_id_type;  // LF_STRING_ID type index
    bool prefer_plain_name;   // claim the unsuffixed name before other dups
  };

  // .debug$T helpers.
  void EmitTypeRecords();

  // .debug$S helpers.
  void EmitObjectAndCompileSymbolsSubsection();
  void EmitFunctionSymbolsSubsection(const FunctionInfo& fn);
  void EmitLinesSubsection(const FunctionInfo& fn, const Code& code);
  void EmitFileChecksumsSubsection();
  void EmitStringTableSubsection();

  void GatherFunctions();
  void DisambiguateFunctionNames();
  void ComputeScriptTables();
  void EmitOneFunctionSymbol(const FunctionInfo& fn);

  // Returns a zone-owned, NUL-terminated path string for `script`, honoring
  // --resolve-dwarf-paths and the obfuscation trie.
  const char* ResolvedScriptUri(const Script& script);

  // Helpers for byte-stream construction.
  void Align4(ZoneGrowableArray<uint8_t>* buf);
  void AppendByte(ZoneGrowableArray<uint8_t>* buf, uint8_t v);
  void AppendU16(ZoneGrowableArray<uint8_t>* buf, uint16_t v);
  void AppendU32(ZoneGrowableArray<uint8_t>* buf, uint32_t v);
  void AppendBytes(ZoneGrowableArray<uint8_t>* buf, const void* p, intptr_t n);
  void AppendString(ZoneGrowableArray<uint8_t>* buf, const char* s);

  Zone* const zone_;
  CoffWriter* const writer_;

  ZoneGrowableArray<FunctionInfo>* functions_;

  // Cumulative byte buffer for .debug$S / .debug$T.  Flushed into the
  // CoffWriter sections at the end of Build().
  ZoneGrowableArray<uint8_t>* debugS_;
  ZoneGrowableArray<uint8_t>* debugT_;

  // Parallel arrays indexed by script index in dwarf_->scripts().  Computed
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
