// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/debugger.h"
#include "vm/isolate.h"
#include "vm/object_store.h"

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
  CHECK_AND_CAST(DebuggerStackTrace, stack_trace, trace);
  *length = stack_trace->Length();
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_GetActivationFrame(
                            Dart_StackTrace trace,
                            int frame_index,
                            Dart_ActivationFrame* frame) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(frame);
  CHECK_AND_CAST(DebuggerStackTrace, stack_trace, trace);
  if ((frame_index < 0) || (frame_index >= stack_trace->Length())) {
    return Api::NewError("argument 'frame_index' is out of range for %s",
                         CURRENT_FUNC);
  }
  *frame = reinterpret_cast<Dart_ActivationFrame>(
       stack_trace->ActivationFrameAt(frame_index));
  return Api::True(isolate);
}


DART_EXPORT void Dart_SetBreakpointHandler(
                     Dart_BreakpointHandler bp_handler) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  BreakpointHandler* handler =
      reinterpret_cast<BreakpointHandler*>(bp_handler);

  isolate->debugger()->SetBreakpointHandler(handler);
}


static Dart_BreakpointResolvedHandler* bp_resolved_handler = NULL;

static void DebuggerEventHandler(Debugger::DebuggerEvent* event) {
  printf("Debugger event %d\n", event->type);
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  if (event->type == Debugger::kBreakpointResolved) {
    if (bp_resolved_handler == NULL) {
      return;
    }
    SourceBreakpoint* bpt = event->breakpoint;
    ASSERT(bpt != NULL);
    Dart_Handle url = Api::NewHandle(isolate, bpt->SourceUrl());
    (*bp_resolved_handler)(bpt->id(), url, bpt->LineNumber());
  } else {
    UNIMPLEMENTED();
  }
}


DART_EXPORT void Dart_SetBreakpointResolvedHandler(
                            Dart_BreakpointResolvedHandler handler) {
  bp_resolved_handler = handler;
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT Dart_Handle Dart_GetStackTrace(Dart_StackTrace* trace) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(trace);
  *trace = reinterpret_cast<Dart_StackTrace>(isolate->debugger()->StackTrace());
  return Api::True(isolate);
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
    *function_name = Api::NewHandle(isolate, frame->QualifiedFunctionName());
  }
  if (script_url != NULL) {
    *script_url = Api::NewHandle(isolate, frame->SourceUrl());
  }
  if (line_number != NULL) {
    *line_number = frame->LineNumber();
  }
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_GetLocalVariables(
                            Dart_ActivationFrame activation_frame) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);
  return Api::NewHandle(isolate, frame->GetLocalVariables());
}


DART_EXPORT Dart_Handle Dart_SetBreakpoint(
                            Dart_Handle script_url_in,
                            intptr_t line_number) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  String& script_url = String::Handle();
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);

  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);
  SourceBreakpoint* bpt =
      debugger->SetBreakpointAtLine(script_url, line_number);
  if (bpt == NULL) {
    return Api::NewError("%s: could not set breakpoint at line %d in '%s'",
                         CURRENT_FUNC, line_number, script_url.ToCString());
  }
  return Dart_NewInteger(bpt->id());
}


// TODO(hausner): remove this function.
DART_EXPORT Dart_Handle Dart_SetBreakpointAtLine(
                            Dart_Handle script_url_in,
                            Dart_Handle line_number_in,
                            Dart_Breakpoint* breakpoint) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  String& script_url = String::Handle();
  Integer& line_number = Integer::Handle();
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);
  UNWRAP_AND_CHECK_PARAM(Integer, line_number, line_number_in);
  CHECK_NOT_NULL(breakpoint);

  if (!line_number.IsSmi()) {
    return Api::NewError("%s: line number out of range", CURRENT_FUNC);
  }
  intptr_t line = line_number.AsInt64Value();

  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::NewError(msg);
  }

  Dart_Handle result = Api::True(isolate);
  *breakpoint = NULL;
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);
  SourceBreakpoint* bpt =
      debugger->SetBreakpointAtLine(script_url, line);
  if (bpt == NULL) {
    result = Api::NewError("%s: could not set breakpoint at line %d of '%s'",
                             CURRENT_FUNC, line, script_url.ToCString());
  } else {
    *breakpoint = reinterpret_cast<Dart_Breakpoint>(bpt);
  }
  return result;
}


DART_EXPORT Dart_Handle Dart_GetBreakpointURL(intptr_t bp_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);

  SourceBreakpoint* bpt = debugger->GetBreakpointById(bp_id);
  if (bpt == NULL) {
    return Api::NewError("%s: breakpoint with id %d does not exist",
                           CURRENT_FUNC, bp_id);
  }
  return Api::NewHandle(isolate, bpt->SourceUrl());
}


DART_EXPORT Dart_Handle Dart_GetBreakpointLine(intptr_t bp_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);

  SourceBreakpoint* bpt = debugger->GetBreakpointById(bp_id);
  if (bpt == NULL) {
    return Api::NewError("%s: breakpoint with id %d does not exist",
                         CURRENT_FUNC, bp_id);
  }
  return Dart_NewInteger(bpt->LineNumber());
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

  Dart_Handle result = Api::True(isolate);
  *breakpoint = NULL;

  SourceBreakpoint* bpt = debugger->SetBreakpointAtEntry(bp_target);
  if (bpt == NULL) {
    const char* target_name = Debugger::QualifiedFunctionName(bp_target);
    result = Api::NewError("%s: no breakpoint location found in '%s'",
                             CURRENT_FUNC, target_name);
  } else {
    *breakpoint = reinterpret_cast<Dart_Breakpoint>(bpt);
  }
  return result;
}


DART_EXPORT Dart_Handle Dart_RemoveBreakpoint(intptr_t bp_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);

  isolate->debugger()->RemoveBreakpoint(bp_id);
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_DeleteBreakpoint(
                            Dart_Breakpoint breakpoint_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  CHECK_AND_CAST(SourceBreakpoint, breakpoint, breakpoint_in);
  isolate->debugger()->RemoveBreakpoint(breakpoint->id());
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_SetStepOver() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetStepOver();
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_SetStepInto() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetStepInto();
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_SetStepOut() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetStepOut();
  return Api::True(isolate);
}


DART_EXPORT Dart_Handle Dart_GetInstanceFields(Dart_Handle object_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Instance& obj = Instance::Handle();
  UNWRAP_AND_CHECK_PARAM(Instance, obj, object_in);
  return Api::NewHandle(isolate, isolate->debugger()->GetInstanceFields(obj));
}


DART_EXPORT Dart_Handle Dart_GetStaticFields(Dart_Handle cls_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Class& cls = Class::Handle();
  UNWRAP_AND_CHECK_PARAM(Class, cls, cls_in);
  return Api::NewHandle(isolate, isolate->debugger()->GetStaticFields(cls));
}


DART_EXPORT Dart_Handle Dart_GetObjClass(Dart_Handle object_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Instance& obj = Instance::Handle();
  UNWRAP_AND_CHECK_PARAM(Instance, obj, object_in);
  return Api::NewHandle(isolate, obj.clazz());
}


DART_EXPORT Dart_Handle Dart_GetSuperclass(Dart_Handle cls_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Class& cls = Class::Handle();
  UNWRAP_AND_CHECK_PARAM(Class, cls, cls_in);
  return Api::NewHandle(isolate, cls.SuperClass());
}


DART_EXPORT Dart_Handle Dart_GetScriptSource(
                            Dart_Handle library_url_in,
                            Dart_Handle script_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  String& library_url = String::Handle();
  UNWRAP_AND_CHECK_PARAM(String, library_url, library_url_in);
  String& script_url = String::Handle();
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);

  const Library& library = Library::Handle(Library::LookupLibrary(library_url));
  if (library.IsNull()) {
    return Api::NewError("%s: library '%s' not found",
                         CURRENT_FUNC, library_url.ToCString());
  }

  const Script& script = Script::Handle(library.LookupScript(script_url));
  if (script.IsNull()) {
    return Api::NewError("%s: script '%s' not found in library '%s'",
                         CURRENT_FUNC, script_url.ToCString(),
                         library_url.ToCString());
  }

  return Api::NewHandle(isolate, script.source());
}


DART_EXPORT Dart_Handle Dart_GetScriptURLs(Dart_Handle library_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  String& library_url = String::Handle();
  UNWRAP_AND_CHECK_PARAM(String, library_url, library_url_in);

  const Library& library = Library::Handle(Library::LookupLibrary(library_url));
  if (library.IsNull()) {
    return Api::NewError("%s: library '%s' not found",
                         CURRENT_FUNC, library_url.ToCString());
  }
  const Array& loaded_scripts = Array::Handle(library.LoadedScripts());
  ASSERT(!loaded_scripts.IsNull());
  intptr_t num_scripts = loaded_scripts.Length();
  const Array& script_list = Array::Handle(Array::New(num_scripts));
  Script& script = Script::Handle();
  String& url = String::Handle();
  for (int i = 0; i < num_scripts; i++) {
    script ^= loaded_scripts.At(i);
    url = script.url();
    script_list.SetAt(i, url);
  }
  return Api::NewHandle(isolate, script_list.raw());
}


DART_EXPORT Dart_Handle Dart_GetLibraryURLs() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);

  // Find out how many libraries are loaded in this isolate.
  int num_libs = 0;
  Library &lib = Library::Handle();
  lib = isolate->object_store()->registered_libraries();
  while (!lib.IsNull()) {
    num_libs++;
    lib = lib.next_registered();
  }

  // Create new list and populate with the url of loaded libraries.
  const Array& library_list = Array::Handle(Array::New(num_libs));
  lib = isolate->object_store()->registered_libraries();
  String& lib_url = String::Handle();
  for (int i = 0; i < num_libs; i++) {
    ASSERT(!lib.IsNull());
    lib_url = lib.url();
    library_list.SetAt(i, lib_url);
    lib = lib.next_registered();
  }
  return Api::NewHandle(isolate, library_list.raw());
}

}  // namespace dart
