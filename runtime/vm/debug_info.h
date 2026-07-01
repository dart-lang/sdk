// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_DEBUG_INFO_H_
#define RUNTIME_VM_DEBUG_INFO_H_

#include "platform/globals.h"

#if defined(DART_PRECOMPILER)

#include <functional>

#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/growable_array.h"
#include "vm/object.h"
#include "vm/zone.h"

namespace dart {

template <typename T>
class Trie;

class DebugInfoPosition {
 public:
  DebugInfoPosition(int32_t line, int32_t column)
      : line_(line), column_(column) {
    // Should only have no line information if also no column information.
    ASSERT(line_ > kNoLine || column_ <= kNoColumn);
  }
  // CodeSourceMaps start the line and column registers at -1, not at 0, and
  // the arguments passed to ChangePosition are retrieved from CodeSourceMaps.
  explicit DebugInfoPosition(int32_t line) : DebugInfoPosition(line, -1) {}
  constexpr DebugInfoPosition() : line_(-1), column_(-1) {}

  // Debug formats use 0 to denote missing line or column information.
  static constexpr int32_t kNoLine = 0;
  static constexpr int32_t kNoColumn = 0;

  int32_t line() const { return line_ > kNoLine ? line_ : kNoLine; }
  int32_t column() const { return column_ > kNoColumn ? column_ : kNoColumn; }

  // Adjusts the contents given the arguments to a ChangePosition instruction
  // from CodeSourceMaps.
  void ChangePosition(int32_t line_delta, int32_t new_column) {
    line_ = Utils::AddWithWrapAround(line_, line_delta);
    column_ = new_column;
  }

 private:
  int32_t line_;
  int32_t column_;
};

static constexpr auto kNoDebugInfoPositionInfo = DebugInfoPosition();

class DebugInfoLineNumberProgramWriter : public ValueObject {
 public:
  explicit DebugInfoLineNumberProgramWriter(Zone* zone)
      : function_stack_(zone, 8), token_positions_(zone, 8) {}
  virtual ~DebugInfoLineNumberProgramWriter() {}

  virtual intptr_t LookupCodeLabel(const Code& code) = 0;
  virtual intptr_t LookupScript(const Script& script) = 0;
  virtual void EmitRow(intptr_t file,
                       intptr_t line,
                       intptr_t column,
                       intptr_t label,
                       intptr_t pc_offset) = 0;

 protected:
  GrowableArray<const Function*> function_stack_;
  GrowableArray<DebugInfoPosition> token_positions_;

 private:
  friend class DebugInfo;

  DISALLOW_COPY_AND_ASSIGN(DebugInfoLineNumberProgramWriter);
};

class DebugInfoWriteStream : public ValueObject {
 public:
  DebugInfoWriteStream() {}
  virtual ~DebugInfoWriteStream() {}

  virtual void sleb128(intptr_t value) = 0;
  virtual void uleb128(uintptr_t value) = 0;
  virtual void u1(uint8_t value) = 0;
  virtual void u2(uint16_t value) = 0;
  virtual void u4(uint32_t value) = 0;
  virtual void u8(uint64_t value) = 0;
  virtual void string(const char* cstr) = 0;  // NOLINT

  // Prefixes the content added by body with its length.
  //
  // symbol_prefix is used when a local symbol is created for the length.
  virtual void WritePrefixedLength(const char* symbol_prefix,
                                   std::function<void()> body) = 0;

  // Generates a relocated address from the given symbol label and offset.
  //
  // If no size is provided, the size of the relocated address in the stream
  // is the native word size.
  virtual void OffsetFromSymbol(intptr_t label,
                                intptr_t offset,
                                size_t size = kAddressSize) = 0;

  virtual void InitializeAbstractOrigins(intptr_t size) = 0;
  virtual void RegisterAbstractOrigin(intptr_t index) = 0;
  virtual void AbstractOrigin(intptr_t index) = 0;

 protected:
#if defined(TARGET_ARCH_IS_32_BIT)
  static constexpr size_t kAddressSize = kInt32Size;
#else
  static constexpr size_t kAddressSize = kInt64Size;
#endif

  DISALLOW_COPY_AND_ASSIGN(DebugInfoWriteStream);
};

class DebugInfo : public AllStatic {
 public:
  static const char* ConvertResolvedURI(const char* str);
  static const char* ResolveScriptUri(
      Zone* zone,
      const Script& script,
      const Trie<const char>* deobfuscation_trie);

  static void WriteLineNumberProgramForCode(
      Zone* zone,
      const Code& code,
      DebugInfoLineNumberProgramWriter* writer);

  static void WriteLineNumberProgramFromCodeSourceMaps(
      Zone* zone,
      const GrowableArray<const Code*>& codes,
      DebugInfoLineNumberProgramWriter* writer);
};

}  // namespace dart

#endif  // DART_PRECOMPILER

#endif  // RUNTIME_VM_DEBUG_INFO_H_
