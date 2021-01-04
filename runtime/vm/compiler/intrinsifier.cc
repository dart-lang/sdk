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

bool Intrinsifier::CanIntrinsify(const Function& function) {
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
  if (!function.is_intrinsic() && !CanIntrinsifyFieldAccessor(function)) {
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
      if (target::kBitsPerWord == 64 &&
          FlowGraphCompiler::SupportsUnboxedInt64()) {
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

bool Intrinsifier::CanIntrinsifyFieldAccessor(const Function& function) {
  const bool is_getter = function.IsImplicitGetterFunction();
  const bool is_setter = function.IsImplicitSetterFunction();
  if (!is_getter && !is_setter) return false;

  Field& field = Field::Handle(function.accessor_field());
  ASSERT(!field.IsNull());

  // The checks further down examine the field and its guard.
  //
  // In JIT mode we only intrinsify the field accessor if there is no active
  // guard, meaning the state transition has reached its final `kDynamicCid`
  // state (where it stays).
  //
  // If we intrinsify, the intrinsified code therefore does not depend on the
  // field guard and we do not add it to the guarded fields via
  // [ParsedFunction::AddToGuardedFields].
  if (CompilerState::Current().should_clone_fields()) {
    field = field.CloneFromOriginal();
  }

  // We only graph intrinsify implicit instance getters/setter for now.
  if (!field.is_instance()) return false;

  if (is_getter) {
    // We don't support complex getter cases.
    if (field.is_late() || field.needs_load_guard()) return false;

    if (FlowGraphCompiler::IsPotentialUnboxedField(field)) {
      if (function.HasUnboxedReturnValue()) {
        // In AOT mode: Unboxed fields contain the unboxed value and can be
        // returned in unboxed form.
        ASSERT(FLAG_precompiled_mode);
      } else {
        // In JIT mode: Unboxed fields contain a mutable box which we cannot
        // return.
        return false;
      }
    } else {
      // If the field is boxed, then we can either return the box directly or
      // unbox it and return unboxed representation.
      return true;
    }
  } else {
    ASSERT(is_setter);

    // We don't support complex setter cases.
    if (field.is_final()) {
      RELEASE_ASSERT(field.is_late());
      return false;
    }

    // We only support cases where there is no need to check for argument types.
    //
    // Normally we have to check the parameter type.
    ASSERT(function.NeedsArgumentTypeChecks());
    // Covariant parameter types have to be checked, which we don't support.
    if (field.is_covariant() || field.is_generic_covariant_impl()) return false;

    // If the incoming value is unboxed we only support real unboxed fields to
    // avoid the need for boxing (which we cannot do in the intrinsic).
    if (function.HasUnboxedParameters()) {
      ASSERT(FLAG_precompiled_mode);
      if (!FlowGraphCompiler::IsUnboxedField(field)) {
        return false;
      }
    }

    // We don't support field guards in graph intrinsic stores.
    if (!FLAG_precompiled_mode && field.guarded_cid() != kDynamicCid) {
      return false;
    }
  }

  return true;
}

struct IntrinsicDesc {
  const char* class_name;
  const char* function_name;
};

struct LibraryInstrinsicsDesc {
  Library& library;
  IntrinsicDesc* intrinsics;
};

#define DEFINE_INTRINSIC(class_name, function_name, destination, fp)           \
  {#class_name, #function_name},

// clang-format off
static IntrinsicDesc core_intrinsics[] = {
  CORE_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  CORE_INTEGER_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  GRAPH_CORE_INTRINSICS_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc math_intrinsics[] = {
  MATH_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  GRAPH_MATH_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc typed_data_intrinsics[] = {
  GRAPH_TYPED_DATA_INTRINSICS_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc developer_intrinsics[] = {
  DEVELOPER_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};

static IntrinsicDesc internal_intrinsics[] = {
  INTERNAL_LIB_INTRINSIC_LIST(DEFINE_INTRINSIC)
  {nullptr, nullptr},
};
// clang-format on

void Intrinsifier::InitializeState() {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  Library& lib = Library::Handle(zone);
  Class& cls = Class::Handle(zone);
  Function& func = Function::Handle(zone);
  String& str = String::Handle(zone);
  String& str2 = String::Handle(zone);
  Error& error = Error::Handle(zone);

  static const intptr_t kNumLibs = 5;
  LibraryInstrinsicsDesc intrinsics[kNumLibs] = {
      {Library::Handle(zone, Library::CoreLibrary()), core_intrinsics},
      {Library::Handle(zone, Library::MathLibrary()), math_intrinsics},
      {Library::Handle(zone, Library::TypedDataLibrary()),
       typed_data_intrinsics},
      {Library::Handle(zone, Library::DeveloperLibrary()),
       developer_intrinsics},
      {Library::Handle(zone, Library::InternalLibrary()), internal_intrinsics},
  };

  for (intptr_t i = 0; i < kNumLibs; i++) {
    lib = intrinsics[i].library.raw();
    for (IntrinsicDesc* intrinsic = intrinsics[i].intrinsics;
         intrinsic->class_name != nullptr; intrinsic++) {
      func = Function::null();
      if (strcmp(intrinsic->class_name, "::") == 0) {
        str = String::New(intrinsic->function_name);
        func = lib.LookupFunctionAllowPrivate(str);
      } else {
        str = String::New(intrinsic->class_name);
        cls = lib.LookupClassAllowPrivate(str);
        ASSERT(FLAG_precompiled_mode || !cls.IsNull());
        if (!cls.IsNull()) {
          error = cls.EnsureIsFinalized(thread);
          if (!error.IsNull()) {
            OS::PrintErr("%s\n", error.ToErrorCString());
          }
          ASSERT(error.IsNull());
          str = String::New(intrinsic->function_name);
          if (intrinsic->function_name[0] == '.') {
            str2 = String::New(intrinsic->class_name);
            str = String::Concat(str2, str);
          }
          func = cls.LookupFunctionAllowPrivate(str);
        }
      }
      if (!func.IsNull()) {
        func.set_is_intrinsic(true);
      } else if (!FLAG_precompiled_mode) {
        FATAL2("Intrinsifier failed to find method %s in class %s\n",
               intrinsic->function_name, intrinsic->class_name);
      }
    }
  }
#undef SETUP_FUNCTION
}

// Returns true if fall-through code can be omitted.
bool Intrinsifier::Intrinsify(const ParsedFunction& parsed_function,
                              FlowGraphCompiler* compiler) {
  const Function& function = parsed_function.function();
  if (!CanIntrinsify(function)) {
    return false;
  }

  if (GraphIntrinsifier::GraphIntrinsify(parsed_function, compiler)) {
    return compiler->intrinsic_slow_path_label()->IsUnused();
  }

#if !defined(HASH_IN_OBJECT_HEADER)
  // These two are more complicated on 32 bit platforms, where the
  // identity hash is not stored in the header of the object.  We
  // therefore don't intrinsify them, falling back on the native C++
  // implementations.
  if (function.recognized_kind() == MethodRecognizer::kObject_getHash ||
      function.recognized_kind() == MethodRecognizer::kObject_setHash) {
    return false;
  }
#endif

#if !defined(PRODUCT)
#define EMIT_BREAKPOINT() compiler->assembler()->Breakpoint()
#else
#define EMIT_BREAKPOINT()
#endif

#define EMIT_CASE(class_name, function_name, enum_name, fp)                    \
  case MethodRecognizer::k##enum_name: {                                       \
    compiler->assembler()->Comment("Intrinsic");                               \
    Label normal_ir_body;                                                      \
    const auto size_before = compiler->assembler()->CodeSize();                \
    AsmIntrinsifier::enum_name(compiler->assembler(), &normal_ir_body);        \
    const auto size_after = compiler->assembler()->CodeSize();                 \
    if (size_before == size_after) return false;                               \
    if (function.HasUnboxedParameters()) {                                     \
      FATAL1("Unsupported unboxed parameters in asm intrinsic %s",             \
             function.ToFullyQualifiedCString());                              \
    }                                                                          \
    if (function.HasUnboxedReturnValue()) {                                    \
      FATAL1("Unsupported unboxed return value in asm intrinsic %s",           \
             function.ToFullyQualifiedCString());                              \
    }                                                                          \
    if (!normal_ir_body.IsBound()) {                                           \
      EMIT_BREAKPOINT();                                                       \
      return true;                                                             \
    }                                                                          \
    return false;                                                              \
  }

  switch (function.recognized_kind()) {
    ALL_INTRINSICS_NO_INTEGER_LIB_LIST(EMIT_CASE);
    default:
      break;
  }
  switch (function.recognized_kind()) {
    CORE_INTEGER_LIB_INTRINSIC_LIST(EMIT_CASE)
    default:
      break;
  }

#undef EMIT_BREAKPOINT

#undef EMIT_INTRINSIC
  return false;
}

}  // namespace compiler
}  // namespace dart
