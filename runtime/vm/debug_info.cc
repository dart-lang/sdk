// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debug_info.h"

#if defined(DART_PRECOMPILER)

#include "vm/code_descriptors.h"
#include "vm/datastream.h"
#include "vm/flags.h"
#include "vm/image_snapshot.h"
#include "vm/object.h"
#include "vm/os.h"

namespace dart {

DECLARE_FLAG(bool, resolve_dwarf_paths);

namespace {

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

}  // namespace

const char* DebugInfo::ConvertResolvedURI(const char* str) {
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

const char* DebugInfo::ResolveScriptUri(
    Zone* zone,
    const Script& script,
    const Trie<const char>* deobfuscation_trie) {
  String& uri = String::Handle(zone, String::null());
  if (FLAG_resolve_dwarf_paths) {
    uri = script.resolved_url();
    if (uri.IsNull()) {
      FATAL("no resolved URI for Script %s available", script.ToCString());
    }
    const char* raw = uri.ToCString();
    const char* converted = ConvertResolvedURI(raw);
    if (converted == nullptr) {
      FATAL("cannot convert resolved URI %s", raw);
    }
    return OS::SCreate(zone, "%s", converted);
  }

  uri = script.url();
  ASSERT(!uri.IsNull());
  const char* deobfuscated =
      ImageWriter::Deobfuscate(zone, deobfuscation_trie, uri.ToCString());
  RELEASE_ASSERT(deobfuscated != nullptr && deobfuscated[0] != '\0');
  return OS::SCreate(zone, "%s", deobfuscated);
}

void DebugInfo::WriteLineNumberProgramForCode(
    Zone* zone,
    const Code& code,
    DebugInfoLineNumberProgramWriter* writer) {
  const intptr_t label = writer->LookupCodeLabel(code);
  ASSERT(label > 0);

  CodeSourceMap& map = CodeSourceMap::Handle(zone, code.code_source_map());
  if (map.IsNull()) {
    return;
  }

  Function& root_function = Function::Handle(zone, code.function());
  Script& script = Script::Handle(zone);
  Array& functions = Array::Handle(zone, code.inlined_id_to_function());
  auto& function_stack = writer->function_stack_;
  auto& token_positions = writer->token_positions_;

  NoSafepointScope no_safepoint;
  ReadStream code_map_stream(map.Data(), map.Length());

  // CodeSourceMap might start in the following way:
  //
  //   ChangePosition function.token_pos()
  //   AdvancePC 0
  //   ChangePosition x
  //   AdvancePC y
  //
  // This entry is emitted to ensure correct symbolization of function listener
  // frames produced by async unwinding.
  // (See EmitFunctionEntrySourcePositionDescriptorIfNeeded).
  // Directly interpreting this sequence would cause us to emit multiple rows
  // with the same pc into line number table and different position information.
  // To avoid this, if the function-entry position was actually emitted, the
  // second row at PC 0 is either dropped when synthetic or moved to PC 1 when
  // real. This would not affect symbolization (you can't have a call that is 1
  // byte long) but will avoid line number table entries with the same PC.
  bool function_entry_position_was_emitted = false;

  int32_t current_pc_offset = 0;
  function_stack.Clear();
  token_positions.Clear();
  function_stack.Add(&root_function);
  token_positions.Add(DebugInfoPosition());

  while (code_map_stream.PendingBytes() > 0) {
    int32_t arg1;
    int32_t arg2 = -1;
    const uint8_t opcode =
        CodeSourceMapOps::Read(&code_map_stream, &arg1, &arg2);
    switch (opcode) {
      case CodeSourceMapOps::kChangePosition: {
        DebugInfoPosition& pos = token_positions[token_positions.length() - 1];
        pos.ChangePosition(arg1, arg2);
        break;
      }
      case CodeSourceMapOps::kAdvancePC: {
        // Emit a row for the previous PC value if the source location changed
        // since the last row was emitted.
        const Function& function = *(function_stack.Last());
        script = function.script();
        const intptr_t file = writer->LookupScript(script);
        const intptr_t line = token_positions.Last().line();
        const intptr_t column = token_positions.Last().column();
        intptr_t pc_offset_adjustment = 0;
        bool should_emit = true;

        // If we are at the function entry and have already emitted a row
        // corresponding to the function entry (marked by AdvancePC 0). Then
        // adjust current_pc_offset to avoid duplicated entries. See the
        // comment above which explains why this code is here.
        if (current_pc_offset == 0 && function_entry_position_was_emitted) {
          pc_offset_adjustment = 1;
          // Ignore synthetic positions. Function entry position gives more
          // information anyway.
          should_emit = !(line == 0 && column == 0);
        }

        if (should_emit) {
          writer->EmitRow(file, line, column, label,
                          current_pc_offset + pc_offset_adjustment);
        }

        current_pc_offset += arg1;
        if (arg1 == 0) {  // Special case of AdvancePC 0.
          ASSERT(current_pc_offset == 0);
          ASSERT(!function_entry_position_was_emitted);
          function_entry_position_was_emitted = true;
        }
        break;
      }
      case CodeSourceMapOps::kPushFunction: {
        auto child_func =
            &Function::Handle(zone, Function::RawCast(functions.At(arg1)));
        function_stack.Add(child_func);
        token_positions.Add(DebugInfoPosition());
        break;
      }
      case CodeSourceMapOps::kPopFunction: {
        // We never pop the root function.
        ASSERT(function_stack.length() > 1);
        ASSERT(token_positions.length() > 1);
        function_stack.RemoveLast();
        token_positions.RemoveLast();
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

void DebugInfo::WriteLineNumberProgramFromCodeSourceMaps(
    Zone* zone,
    const GrowableArray<const Code*>& codes,
    DebugInfoLineNumberProgramWriter* writer) {
  for (intptr_t i = 0; i < codes.length(); i++) {
    const Code& code = *(codes[i]);
    WriteLineNumberProgramForCode(zone, code, writer);
  }
}

}  // namespace dart

#endif  // DART_PRECOMPILER
