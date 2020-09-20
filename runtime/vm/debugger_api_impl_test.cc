// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <include/dart_api.h>
#include "include/dart_tools_api.h"

#include "vm/class_finalizer.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/debugger.h"
#include "vm/debugger_api_impl_test.h"
#include "vm/isolate.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

// Facilitate quick access to the current zone once we have the current thread.
#define Z (T->zone())

#ifndef PRODUCT

#define UNWRAP_AND_CHECK_PARAM(type, var, param)                               \
  type& var = type::Handle();                                                  \
  do {                                                                         \
    const Object& tmp = Object::Handle(Api::UnwrapHandle(param));              \
    if (tmp.IsNull()) {                                                        \
      return Api::NewError("%s expects argument '%s' to be non-null.",         \
                           CURRENT_FUNC, #param);                              \
    } else if (tmp.IsApiError()) {                                             \
      return param;                                                            \
    } else if (!tmp.Is##type()) {                                              \
      return Api::NewError("%s expects argument '%s' to be of type %s.",       \
                           CURRENT_FUNC, #param, #type);                       \
    }                                                                          \
    var ^= tmp.raw();                                                          \
  } while (0)

#define CHECK_AND_CAST(type, var, param)                                       \
  type* var = NULL;                                                            \
  do {                                                                         \
    if (param == NULL) {                                                       \
      return Api::NewError("%s expects argument '%s' to be non-null.",         \
                           CURRENT_FUNC, #param);                              \
    }                                                                          \
    var = reinterpret_cast<type*>(param);                                      \
  } while (0)

#define CHECK_NOT_NULL(param)                                                  \
  if (param == NULL) {                                                         \
    return Api::NewError("%s expects argument '%s' to be non-null.",           \
                         CURRENT_FUNC, #param);                                \
  }

#define CHECK_DEBUGGER(isolate)                                                \
  if (isolate->debugger() == NULL) {                                           \
    return Api::NewError("%s requires debugger support.", CURRENT_FUNC);       \
  }

DART_EXPORT Dart_Handle Dart_StackTraceLength(Dart_StackTrace trace,
                                              intptr_t* length) {
  DARTSCOPE(Thread::Current());
  CHECK_NOT_NULL(length);
  CHECK_AND_CAST(DebuggerStackTrace, stack_trace, trace);
  *length = stack_trace->Length();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetActivationFrame(Dart_StackTrace trace,
                                                int frame_index,
                                                Dart_ActivationFrame* frame) {
  DARTSCOPE(Thread::Current());
  CHECK_NOT_NULL(frame);
  CHECK_AND_CAST(DebuggerStackTrace, stack_trace, trace);
  if ((frame_index < 0) || (frame_index >= stack_trace->Length())) {
    return Api::NewError("argument 'frame_index' is out of range for %s",
                         CURRENT_FUNC);
  }
  *frame =
      reinterpret_cast<Dart_ActivationFrame>(stack_trace->FrameAt(frame_index));
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetStackTrace(Dart_StackTrace* trace) {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  CHECK_DEBUGGER(I);
  CHECK_NOT_NULL(trace);
  *trace =
      reinterpret_cast<Dart_StackTrace>(I->debugger()->CurrentStackTrace());
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetStackTraceFromError(Dart_Handle handle,
                                                    Dart_StackTrace* trace) {
  DARTSCOPE(Thread::Current());
  CHECK_DEBUGGER(T->isolate());
  CHECK_NOT_NULL(trace);
  const Object& obj = Object::Handle(Z, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    StackTrace& dart_stacktrace = StackTrace::Handle(Z);
    dart_stacktrace ^= error.stacktrace();
    if (dart_stacktrace.IsNull()) {
      *trace = NULL;
    } else {
      Isolate* I = T->isolate();
      *trace = reinterpret_cast<Dart_StackTrace>(
          I->debugger()->StackTraceFrom(dart_stacktrace));
    }
    return Api::Success();
  } else {
    return Api::NewError(
        "Can only get stacktraces from error handles or "
        "instances of Error.");
  }
}

DART_EXPORT Dart_Handle
Dart_ActivationFrameInfo(Dart_ActivationFrame activation_frame,
                         Dart_Handle* function_name,
                         Dart_Handle* script_url,
                         intptr_t* line_number,
                         intptr_t* column_number) {
  DARTSCOPE(Thread::Current());
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);
  if (function_name != NULL) {
    *function_name = Api::NewHandle(T, frame->QualifiedFunctionName());
  }
  if (script_url != NULL) {
    *script_url = Api::NewHandle(T, frame->SourceUrl());
  }
  if (line_number != NULL) {
    *line_number = frame->LineNumber();
  }
  if (column_number != NULL) {
    *column_number = frame->ColumnNumber();
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_SetBreakpoint(Dart_Handle script_url_in,
                                           intptr_t line_number) {
  Breakpoint* bpt;
  {
    DARTSCOPE(Thread::Current());
    Isolate* I = T->isolate();
    CHECK_DEBUGGER(I);
    UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);

    Debugger* debugger = I->debugger();
    bpt = debugger->SetBreakpointAtLine(script_url, line_number);
    if (bpt == NULL) {
      return Api::NewError("%s: could not set breakpoint at line %" Pd
                           " in '%s'",
                           CURRENT_FUNC, line_number, script_url.ToCString());
    }
  }
  return Dart_NewInteger(bpt->id());
}

DART_EXPORT Dart_Handle Dart_EvaluateStaticExpr(Dart_Handle lib_handle,
                                                Dart_Handle expr_in) {
  DARTSCOPE(Thread::Current());
  CHECK_DEBUGGER(T->isolate());

  const Object& target = Object::Handle(Z, Api::UnwrapHandle(lib_handle));
  if (target.IsError()) return lib_handle;
  if (target.IsNull()) {
    return Api::NewError("%s expects argument 'target' to be non-null",
                         CURRENT_FUNC);
  }
  const Library& lib = Library::Cast(target);
  UNWRAP_AND_CHECK_PARAM(String, expr, expr_in);

  if (!KernelIsolate::IsRunning()) {
    UNREACHABLE();
  } else {
    Dart_KernelCompilationResult compilation_result =
        KernelIsolate::CompileExpressionToKernel(
            /* platform_kernel= */ nullptr, /* platform_kernel_size= */ 0,
            expr.ToCString(),
            /* definitions= */ Array::empty_array(),
            /* type_defintions= */ Array::empty_array(),
            String::Handle(lib.url()).ToCString(),
            /* klass= */ nullptr,
            /* is_static= */ true);
    if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
      return Api::NewError("Failed to compile expression.");
    }

    const ExternalTypedData& kernel_buffer =
        ExternalTypedData::Handle(ExternalTypedData::NewFinalizeWithFree(
            const_cast<uint8_t*>(compilation_result.kernel),
            compilation_result.kernel_size));

    Dart_Handle result = Api::NewHandle(
        T,
        lib.EvaluateCompiledExpression(kernel_buffer,
                                       /* type_definitions= */
                                       Array::empty_array(),
                                       /* param_values= */
                                       Array::empty_array(),
                                       /* type_param_values= */
                                       TypeArguments::null_type_arguments()));
    return result;
  }
}

DART_EXPORT Dart_Handle Dart_LibraryId(Dart_Handle library,
                                       intptr_t* library_id) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Api::UnwrapLibraryHandle(Z, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(Z, library, Library);
  }
  if (library_id == NULL) {
    RETURN_NULL_ERROR(library_id);
  }
  *library_id = lib.index();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_GetLibraryDebuggable(intptr_t library_id,
                                                  bool* is_debuggable) {
  DARTSCOPE(Thread::Current());
  CHECK_NOT_NULL(is_debuggable);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id", CURRENT_FUNC,
                         library_id);
  }
  *is_debuggable = lib.IsDebuggable();
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_SetLibraryDebuggable(intptr_t library_id,
                                                  bool is_debuggable) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Library::Handle(Z, Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id", CURRENT_FUNC,
                         library_id);
  }
  lib.set_debuggable(is_debuggable);
  return Api::Success();
}

#endif  // !PRODUCT

}  // namespace dart
