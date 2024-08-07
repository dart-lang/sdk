// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Class for intrinsifying functions.

#include "vm/compiler/intrinsifier.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/backend/flow_graph.h"
#include "vm/compiler/backend/flow_graph_compiler.h"
#include "vm/compiler/backend/il_printer.h"
#include "vm/compiler/backend/linearscan.h"
#include "vm/compiler/frontend/flow_graph_builder.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/flags.h"
#include "vm/object.h"
#include "vm/parser.h"
#include "vm/symbols.h"

namespace dart {

DEFINE_FLAG(bool, intrinsify, true, "Instrinsify when possible");
DEFINE_FLAG(bool, trace_intrinsifier, false, "Trace intrinsifier");

namespace compiler {

bool Intrinsifier::CanIntrinsify(const ParsedFunction& parsed_function) {
  const Function& function = parsed_function.function();

  if (FLAG_trace_intrinsifier) {
    THR_Print("CanIntrinsify %s ->", function.ToQualifiedCString());
  }
  if (!FLAG_intrinsify) return false;
  // TODO(regis): We do not need to explicitly filter generic functions here,
  // unless there are errors we don't detect at link time. Revisit if necessary.
  if (function.IsClosureFunction()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, closure function.\n");
    }
    return false;
  }
  // Can occur because of compile-all flag.
  if (function.is_external()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, external function.\n");
    }
    return false;
  }
  if (!function.is_intrinsic()) {
    if (FLAG_trace_intrinsifier) {
      THR_Print("No, not intrinsic function.\n");
    }
    return false;
  }
  switch (function.recognized_kind()) {
    case MethodRecognizer::kInt64ArrayGetIndexed:
    case MethodRecognizer::kInt64ArraySetIndexed:
    case MethodRecognizer::kUint64ArrayGetIndexed:
    case MethodRecognizer::kUint64ArraySetIndexed:
      // TODO(ajcbik): consider 32-bit as well.
      if (target::kBitsPerWord == 64) {
        break;
      }
      if (FLAG_trace_intrinsifier) {
        THR_Print("No, 64-bit int intrinsic on 32-bit platform.\n");
      }
      return false;
    default:
      break;
  }
  if (FLAG_trace_intrinsifier) {
    THR_Print("Yes.\n");
  }
  return true;
}

// Returns true if fall-through code can be omitted.
bool Intrinsifier::Intrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler) {
  if (!CanIntrinsify(parsed_function)) {
    return false;
  }

  if (GraphIntrinsifier::GraphIntrinsify(parsed_function, compiler)) {
    return compiler->intrinsic_slow_path_label()->IsUnused();
  }

  const Function& function = parsed_function.function();
#if !defined(HASH_IN_OBJECT_HEADER)
  // These two are more complicated on 32 bit platforms, where the
  // identity hash is not stored in the header of the object.  We
  // therefore don't intrinsify them, falling back on the native C++
  // implementations.
  if (function.recognized_kind() == MethodRecognizer::kObject_getHash) {
    return false;
  }
#endif

#if !defined(PRODUCT)
#define EMIT_BREAKPOINT() compiler->assembler()->Breakpoint()
#else
#define EMIT_BREAKPOINT()
#endif

#define EMIT_CASE(library, class_name, function_name, enum_name, fp)           \
  case MethodRecognizer::k##enum_name: {                                       \
    compiler->assembler()->Comment("Intrinsic");                               \
    Label normal_ir_body;                                                      \
    const auto size_before = compiler->assembler()->CodeSize();                \
    AsmIntrinsifier::enum_name(compiler->assembler(), &normal_ir_body);        \
    const auto size_after = compiler->assembler()->CodeSize();                 \
    if (size_before == size_after) return false;                               \
    if (function.HasUnboxedParameters()) {                                     \
      FATAL("Unsupported unboxed parameters in asm intrinsic %s",              \
            function.ToFullyQualifiedCString());                               \
    }                                                                          \
    if (function.HasUnboxedReturnValue()) {                                    \
      FATAL("Unsupported unboxed return value in asm intrinsic %s",            \
            function.ToFullyQualifiedCString());                               \
    }                                                                          \
    if (!normal_ir_body.IsBound()) {                                           \
      EMIT_BREAKPOINT();                                                       \
      return true;                                                             \
    }                                                                          \
    return false;                                                              \
  }

  switch (function.recognized_kind()) {
    ASM_INTRINSICS_LIST(EMIT_CASE);
    default:
      break;
  }

#undef EMIT_BREAKPOINT

#undef EMIT_INTRINSIC
  return false;
}

}  // namespace compiler
}  // namespace dart
