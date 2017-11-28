// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

static Dart_PausedEventHandler* paused_event_handler = NULL;
static Dart_BreakpointResolvedHandler* bp_resolved_handler = NULL;
static Dart_ExceptionThrownHandler* exc_thrown_handler = NULL;
static Dart_IsolateEventHandler* isolate_event_handler = NULL;

static void DebuggerEventHandler(ServiceEvent* event) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != NULL);
  Dart_EnterScope();
  Dart_IsolateId isolate_id = isolate->debugger()->GetIsolateId();
  if (event->kind() == ServiceEvent::kPauseBreakpoint) {
    if (paused_event_handler != NULL) {
      Dart_CodeLocation location;
      ActivationFrame* top_frame = event->top_frame();
      location.script_url = Api::NewHandle(thread, top_frame->SourceUrl());
      const Library& lib = Library::Handle(top_frame->Library());
      location.library_id = lib.index();
      location.token_pos = top_frame->TokenPos().Pos();
      intptr_t bp_id = 0;
      if (event->breakpoint() != NULL) {
        ASSERT(event->breakpoint()->id() != ILLEGAL_BREAKPOINT_ID);
        bp_id = event->breakpoint()->id();
      }
      (*paused_event_handler)(isolate_id, bp_id, location);
    }
  } else if (event->kind() == ServiceEvent::kBreakpointAdded ||
             event->kind() == ServiceEvent::kBreakpointResolved) {
    Breakpoint* bpt = event->breakpoint();
    ASSERT(bpt != NULL);
    if (bp_resolved_handler != NULL && bpt->bpt_location()->IsResolved() &&
        !bpt->IsSingleShot()) {
      Dart_CodeLocation location;
      Zone* zone = thread->zone();
      Library& library = Library::Handle(zone);
      Script& script = Script::Handle(zone);
      TokenPosition token_pos;
      bpt->bpt_location()->GetCodeLocation(&library, &script, &token_pos);
      location.script_url = Api::NewHandle(thread, script.url());
      location.library_id = library.index();
      location.token_pos = token_pos.Pos();
      (*bp_resolved_handler)(isolate_id, bpt->id(), location);
    }
  } else if (event->kind() == ServiceEvent::kBreakpointRemoved) {
    // Ignore.
  } else if (event->kind() == ServiceEvent::kPauseException) {
    if (exc_thrown_handler != NULL) {
      Dart_Handle exception = Api::NewHandle(thread, event->exception()->raw());
      Dart_StackTrace trace =
          reinterpret_cast<Dart_StackTrace>(isolate->debugger()->StackTrace());
      (*exc_thrown_handler)(isolate_id, exception, trace);
    }
  } else if (event->kind() == ServiceEvent::kIsolateStart) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kCreated);
    }
  } else if (event->kind() == ServiceEvent::kPauseInterrupted ||
             event->kind() == ServiceEvent::kPausePostRequest) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kInterrupted);
    }
  } else if (event->kind() == ServiceEvent::kIsolateExit) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kShutdown);
    }
  } else {
    UNIMPLEMENTED();
  }
  Dart_ExitScope();
}

DART_EXPORT void Dart_SetPausedEventHandler(Dart_PausedEventHandler handler) {
  paused_event_handler = handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
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
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();
  CHECK_DEBUGGER(I);
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);

  Debugger* debugger = I->debugger();
  Breakpoint* bpt = debugger->SetBreakpointAtLine(script_url, line_number);
  if (bpt == NULL) {
    return Api::NewError("%s: could not set breakpoint at line %" Pd " in '%s'",
                         CURRENT_FUNC, line_number, script_url.ToCString());
  }
  return Dart_NewInteger(bpt->id());
}

DART_EXPORT Dart_Handle Dart_EvaluateExpr(Dart_Handle target_in,
                                          Dart_Handle expr_in) {
  DARTSCOPE(Thread::Current());
  CHECK_DEBUGGER(T->isolate());

  const Object& target = Object::Handle(Z, Api::UnwrapHandle(target_in));
  if (target.IsError()) return target_in;
  if (target.IsNull()) {
    return Api::NewError("%s expects argument 'target' to be non-null",
                         CURRENT_FUNC);
  }
  UNWRAP_AND_CHECK_PARAM(String, expr, expr_in);
  // Type extends Instance, must check first.
  if (target.IsType()) {
    const Class& cls = Class::Handle(Z, Type::Cast(target).type_class());
    return Api::NewHandle(
        T, cls.Evaluate(expr, Array::empty_array(), Array::empty_array()));
  } else if (target.IsInstance()) {
    const Instance& inst = Instance::Cast(target);
    const Class& receiver_cls = Class::Handle(Z, inst.clazz());
    return Api::NewHandle(
        T, inst.Evaluate(receiver_cls, expr, Array::empty_array(),
                         Array::empty_array()));
  } else if (target.IsLibrary()) {
    const Library& lib = Library::Cast(target);
    return Api::NewHandle(
        T, lib.Evaluate(expr, Array::empty_array(), Array::empty_array()));
  } else if (target.IsClass()) {
    const Class& cls = Class::Cast(target);
    return Api::NewHandle(
        T, cls.Evaluate(expr, Array::empty_array(), Array::empty_array()));
  }
  return Api::NewError("%s: unsupported target type", CURRENT_FUNC);
}

DART_EXPORT Dart_Handle Dart_GetLibraryIds() {
  DARTSCOPE(Thread::Current());
  Isolate* I = T->isolate();

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(Z, I->object_store()->libraries());
  int num_libs = libs.Length();

  // Create new list and populate with the url of loaded libraries.
  Library& lib = Library::Handle();
  const Array& library_id_list = Array::Handle(Z, Array::New(num_libs));
  for (int i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    ASSERT(Smi::IsValid(lib.index()));
    library_id_list.SetAt(i, Smi::Handle(Smi::New(lib.index())));
  }
  return Api::NewHandle(T, library_id_list.raw());
}

DART_EXPORT Dart_Handle Dart_GetLibraryFromId(intptr_t library_id) {
  DARTSCOPE(Thread::Current());
  const Library& lib = Library::Handle(Z, Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id", CURRENT_FUNC,
                         library_id);
  }
  return Api::NewHandle(T, lib.raw());
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

#else

DART_EXPORT void Dart_SetPausedEventHandler(Dart_PausedEventHandler handler) {
  // NOOP.
}

#endif  // !PRODUCT

}  // namespace dart
