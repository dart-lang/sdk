// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/debugger.h"
#include "vm/isolate.h"
#include "vm/longjump.h"

namespace dart {

#define UNWRAP_AND_CHECK_PARAM(type, var, param)                              \
  do {                                                                        \
    const Object& tmp = Object::Handle(Api::UnwrapHandle(param));             \
    if (tmp.IsNull()) {                                                       \
      return Api::NewError("%s expects argument '%s' to be non-null.",        \
                           CURRENT_FUNC, #param);                             \
    } else if (tmp.IsApiError()) {                                            \
      return param;                                                           \
    } else if (!tmp.Is##type()) {                                             \
      return Api::NewError("%s expects argument '%s' to be of type %s.",      \
                           CURRENT_FUNC, #param, #type);                      \
    }                                                                         \
    var ^= tmp.raw();                                                         \
  } while (0);


#define CHECK_AND_CAST(type, var, param)                                      \
  if (param == NULL) {                                                        \
    return Api::NewError("%s expects argument '%s' to be non-null.",          \
                         CURRENT_FUNC, #param);                               \
  }                                                                           \
  type* var = reinterpret_cast<type*>(param);


#define CHECK_NOT_NULL(param)                                                 \
  if (param == NULL) {                                                        \
    return Api::NewError("%s expects argument '%s' to be non-null.",          \
                         CURRENT_FUNC, #param);                               \
  }


DART_EXPORT Dart_Handle Dart_StackTraceLength(
                            Dart_StackTrace trace,
                            intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(length);
  CHECK_AND_CAST(StackTrace, stack_trace, trace);
  *length = stack_trace->Length();
  return Api::True();
}


DART_EXPORT Dart_Handle Dart_GetActivationFrame(
                            Dart_StackTrace trace,
                            int frame_index,
                            Dart_ActivationFrame* frame) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(frame);
  CHECK_AND_CAST(StackTrace, stack_trace, trace);
  if ((frame_index < 0) || (frame_index >= stack_trace->Length())) {
    return Api::NewError("argument 'frame_index' is out of range for %s",
                         CURRENT_FUNC);
  }
  *frame = reinterpret_cast<Dart_ActivationFrame>(
       stack_trace->ActivationFrameAt(frame_index));
  return Api::True();
}


DART_EXPORT void Dart_SetBreakpointHandler(
                     Dart_BreakpointHandler bp_handler) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  BreakpointHandler* handler =
      reinterpret_cast<BreakpointHandler*>(bp_handler);

  isolate->debugger()->SetBreakpointHandler(handler);
}


DART_EXPORT Dart_Handle Dart_ActivationFrameInfo(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle* function_name,
                            Dart_Handle* script_url,
                            intptr_t* line_number) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);
  if (function_name != NULL) {
    const String& name = String::Handle(frame->QualifiedFunctionName());
    *function_name = Api::NewLocalHandle(name);
  }
  if (script_url != NULL) {
    const String& url = String::Handle(frame->SourceUrl());
    *script_url = Api::NewLocalHandle(url);
  }
  if (line_number != NULL) {
    *line_number = frame->LineNumber();
  }
  return Api::True();
}


DART_EXPORT Dart_Handle Dart_SetBreakpointAtEntry(
                            Dart_Handle library_in,
                            Dart_Handle class_name_in,
                            Dart_Handle function_name_in,
                            Dart_Breakpoint* breakpoint) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  Library& library = Library::Handle();
  String& class_name = String::Handle();
  String& function_name = String::Handle();
  UNWRAP_AND_CHECK_PARAM(Library, library, library_in);
  UNWRAP_AND_CHECK_PARAM(String, class_name, class_name_in);
  UNWRAP_AND_CHECK_PARAM(String, function_name, function_name_in);
  CHECK_NOT_NULL(breakpoint);

  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }

  // Resolve the breakpoint target function.
  Debugger* debugger = isolate->debugger();
  const Function& bp_target = Function::Handle(
      debugger->ResolveFunction(library, class_name, function_name));
  if (bp_target.IsNull()) {
    const bool toplevel = class_name.Length() == 0;
    return Api::NewError("%s: could not find function '%s%s%s'",
                         CURRENT_FUNC,
                         toplevel ? "" : class_name.ToCString(),
                         toplevel ? "" : ".",
                         function_name.ToCString());
  }

  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  Dart_Handle result = Api::True();
  *breakpoint = NULL;
  if (setjmp(*jump.Set()) == 0) {
    Breakpoint* bpt = debugger->SetBreakpointAtEntry(bp_target);
    if (bpt == NULL) {
      const char* target_name = Debugger::QualifiedFunctionName(bp_target);
      result = Api::NewError("%s: no breakpoint location found in '%s'",
                             CURRENT_FUNC, target_name);
    } else {
      *breakpoint = reinterpret_cast<Dart_Breakpoint>(bpt);
    }
  } else {
    SetupErrorResult(&result);
  }
  isolate->set_long_jump_base(base);
  return result;
}


}  // namespace dart
