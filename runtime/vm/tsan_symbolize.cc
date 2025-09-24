// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/tsan_symbolize.h"

#include "platform/atomic.h"
#include "platform/thread_sanitizer.h"
#include "vm/code_descriptors.h"
#include "vm/object.h"

namespace dart {

#if defined(USING_THREAD_SANITIZER) && !defined(DART_PRECOMPILED_RUNTIME)

struct TsanLineNumberProgram {
  TsanLineNumberProgram* next;
  uintptr_t pc;
  uint32_t size;
  uint8_t stream[];
};
static std::atomic<TsanLineNumberProgram*> head = nullptr;

enum : uint8_t {
  OP_STOP = 0,
  OP_PUSH_FUNCTION,
  OP_POP_FUNCTION,
  OP_ADVANCE_PC,
  OP_CHANGE_POSITION,
};

static void WriteString(GrowableArray<uint8_t>& out, const char* str) {
  for (intptr_t i = 0, len = strlen(str); i <= len; i++) {
    out.Add(str[i]);
  }
}

void RegisterTsanSymbolize(const Code& code) {
  if (!code.IsFunctionCode()) {
    // TODO(rmacnak): Do something for stubs?
    return;
  }

  const CodeSourceMap& map = CodeSourceMap::Handle(code.code_source_map());
  RELEASE_ASSERT(!map.IsNull());
  const Array& functions = Array::Handle(code.inlined_id_to_function());
  Function& function = Function::Handle(code.function());
  Script& script = Script::Handle(function.script());
  String& url = String::Handle(script.url());
  GrowableArray<Function*> function_stack(8);
  GrowableArray<TokenPosition> token_positions(8);
  function_stack.Add(&Function::Handle(function.ptr()));
  token_positions.Add(CodeSourceMapBuilder::kInitialPosition);

  GrowableArray<uint8_t> out(256);
  out.Add(OP_PUSH_FUNCTION);
  WriteString(out, function.QualifiedUserVisibleNameCString());
  WriteString(out, url.ToCString());

  ReadStream stream(map.Data(), map.Length());
  while (stream.PendingBytes() > 0) {
    int32_t arg;
    switch (CodeSourceMapOps::Read(&stream, &arg)) {
      case CodeSourceMapOps::kChangePosition: {
        const TokenPosition& old_token = token_positions.Last();
        token_positions.Last() = TokenPosition::Deserialize(
            Utils::AddWithWrapAround(arg, old_token.Serialize()));

        TokenPosition pos = token_positions.Last();
        if (pos.IsNoSource()) {
          pos = function_stack.Last()->token_pos();
        }

        intptr_t line = -1;
        intptr_t column = -1;
        script = function_stack.Last()->script();
        script.GetTokenLocation(pos, &line, &column);

        out.Add(OP_CHANGE_POSITION);
        out.Add((line >> 0) & 0xFF);
        out.Add((line >> 8) & 0xFF);
        out.Add((column >> 0) & 0xFF);
        out.Add((column >> 8) & 0xFF);
        break;
      }
      case CodeSourceMapOps::kAdvancePC: {
        out.Add(OP_ADVANCE_PC);
        out.Add((arg >> 0) & 0xFF);
        out.Add((arg >> 8) & 0xFF);
        out.Add((arg >> 16) & 0xFF);
        out.Add((arg >> 24) & 0xFF);
        break;
      }
      case CodeSourceMapOps::kPushFunction: {
        function ^= functions.At(arg);
        function_stack.Add(&Function::Handle(function.ptr()));
        token_positions.Add(CodeSourceMapBuilder::kInitialPosition);

        out.Add(OP_PUSH_FUNCTION);
        WriteString(out, function.QualifiedUserVisibleNameCString());
        script = function_stack.Last()->script();
        url = script.url();
        WriteString(out, url.ToCString());
        break;
      }
      case CodeSourceMapOps::kPopFunction: {
        function_stack.RemoveLast();
        token_positions.RemoveLast();
        out.Add(OP_POP_FUNCTION);
        break;
      }
      case CodeSourceMapOps::kNullCheck: {
        break;
      }
      default:
        UNREACHABLE();
    }
  }
  out.Add(OP_STOP);

  TsanLineNumberProgram* lnp = reinterpret_cast<TsanLineNumberProgram*>(
      malloc(sizeof(TsanLineNumberProgram) + out.length()));
  lnp->next = nullptr;
  lnp->pc = code.PayloadStart();
  lnp->size = code.Size();
  memcpy(&lnp->stream, out.data(), out.length());  // NOLINT

  TsanLineNumberProgram* old_head = head.load(std::memory_order_acquire);
  do {
    lnp->next = old_head;
  } while (
      !head.compare_exchange_weak(old_head, lnp, std::memory_order_acq_rel));
}

typedef void (*AddFrame)(void* ctxt,
                         const char* function_name,
                         const char* file,
                         int line,
                         int column);

// It would be nice to implement this by a heap walk to find the Code object and
// then symbolize using our normal PC descriptors, etc, but this function must
// not call any function that has been instrumented by TSAN or it might deadlock
// during __tsan_func_entry.
extern "C" __attribute__((disable_sanitizer_instrumentation)) void
__tsan_symbolize_external_ex(uintptr_t pc, AddFrame add_frame, void* ctxt) {
  constexpr uintptr_t kExternalPCBit = 1ULL << 60;
  const uword lookup_pc = pc & ~kExternalPCBit;

  for (TsanLineNumberProgram* lnp = head.load(std::memory_order_acquire);
       lnp != nullptr; lnp = lnp->next) {
    if ((lookup_pc >= lnp->pc) && ((lookup_pc - lnp->pc) < lnp->size)) {
      // Greater than the default value of --inlining_depth_threshold.
      constexpr intptr_t kMaxDepth = 32;
      const char* names[kMaxDepth];
      const char* files[kMaxDepth];
      int32_t lines[kMaxDepth];
      int32_t columns[kMaxDepth];
      intptr_t depth = 0;
      uword lnp_pc = lnp->pc;

      uint8_t* cursor = &lnp->stream[0];
      for (;;) {
        switch (*cursor++) {
          case OP_PUSH_FUNCTION: {
            const char* name = reinterpret_cast<const char*>(cursor);
            while (*cursor++ != 0) {
            }
            const char* file = reinterpret_cast<const char*>(cursor);
            while (*cursor++ != 0) {
            }

            names[depth] = name;
            files[depth] = file;
            lines[depth] = -1;
            columns[depth] = -1;

            depth++;
            if (depth >= kMaxDepth) {
              FATAL("LNP overflow");
            }
            break;
          }
          case OP_POP_FUNCTION: {
            depth--;
            break;
          }
          case OP_CHANGE_POSITION: {
            uint8_t a = *cursor++;
            uint8_t b = *cursor++;
            uint8_t c = *cursor++;
            uint8_t d = *cursor++;
            lines[depth - 1] = a | (b << 8);
            columns[depth - 1] = c | (d << 8);
            break;
          }
          case OP_ADVANCE_PC: {
            uint8_t a = *cursor++;
            uint8_t b = *cursor++;
            uint8_t c = *cursor++;
            uint8_t d = *cursor++;
            uint32_t disp = a | (b << 8) | (c << 16) | (d << 24);
            lnp_pc += disp;
            if (lookup_pc <= lnp_pc) {
#if 0
              char s[17];
              s[16] = 0;
              for (intptr_t k = 0; k < 16; k++) {
                s[k] = "0123456789abcdef"[lookup_pc >> ((15 - k) << 2)) & 0xFF];
              }
              add_frame(ctxt, "lookup_pc", s, 0, 0);
              for (intptr_t k = 0; k < 16; k++) {
                s[k] = "0123456789abcdef"[lnp_pc >> ((15 - k) << 2)) & 0xFF];
              }
              add_frame(ctxt, "lnp_pc", s, 0, 0);
#endif

              for (intptr_t i = depth - 1; i >= 0; i--) {
                add_frame(ctxt, names[i], files[i], lines[i], columns[i]);
              }
              return;
            }
            break;
          }
          case OP_STOP: {
            FATAL("pc in function but outside LNP");
          }
          default:
            UNREACHABLE();
        }
      }
      UNREACHABLE();
    }
  }
  add_frame(ctxt, "dart-code-lookup-failed", nullptr, 0, 0);
}
#else
void RegisterTsanSymbolize(const Code& code) {}
#endif

}  // namespace dart
