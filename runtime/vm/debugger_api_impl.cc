// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"

#include "vm/class_finalizer.h"
#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/debugger.h"
#include "vm/isolate.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

namespace dart {

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


DART_EXPORT intptr_t Dart_CacheObject(Dart_Handle object_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Object& obj = Object::Handle(Api::UnwrapHandle(object_in));
  if (obj.IsApiError()) {
    return -1;
  }
  return isolate->debugger()->CacheObject(obj);
}


DART_EXPORT Dart_Handle Dart_GetCachedObject(intptr_t obj_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (!isolate->debugger()->IsValidObjectId(obj_id)) {
    return Api::NewError("%s: object id %" Pd " is invalid",
                         CURRENT_FUNC, obj_id);
  }
  return Api::NewHandle(isolate, isolate->debugger()->GetCachedObject(obj_id));
}


DART_EXPORT Dart_Handle Dart_StackTraceLength(
                            Dart_StackTrace trace,
                            intptr_t* length) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(length);
  CHECK_AND_CAST(DebuggerStackTrace, stack_trace, trace);
  *length = stack_trace->Length();
  return Api::Success();
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
       stack_trace->FrameAt(frame_index));
  return Api::Success();
}

static Dart_PausedEventHandler* paused_event_handler = NULL;
static Dart_BreakpointResolvedHandler* bp_resolved_handler = NULL;
static Dart_ExceptionThrownHandler* exc_thrown_handler = NULL;
static Dart_IsolateEventHandler* isolate_event_handler = NULL;

static Dart_BreakpointHandler* legacy_bp_handler = NULL;


static void DebuggerEventHandler(DebuggerEvent* event) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  ASSERT(isolate->debugger() != NULL);
  Dart_EnterScope();
  Dart_IsolateId isolate_id = isolate->debugger()->GetIsolateId();
  if (event->type() == DebuggerEvent::kBreakpointReached) {
    if (legacy_bp_handler != NULL) {
      Dart_StackTrace stack_trace =
          reinterpret_cast<Dart_StackTrace>(isolate->debugger()->StackTrace());
      (*legacy_bp_handler)(isolate_id, NULL, stack_trace);
    } else if (paused_event_handler != NULL) {
      Dart_CodeLocation location;
      ActivationFrame* top_frame = event->top_frame();
      location.script_url = Api::NewHandle(isolate, top_frame->SourceUrl());
      const Library& lib = Library::Handle(top_frame->Library());
      location.library_id = lib.index();
      location.token_pos = top_frame->TokenPos();
      intptr_t bp_id = 0;
      if (event->breakpoint() != NULL) {
        ASSERT(event->breakpoint()->id() != ILLEGAL_BREAKPOINT_ID);
        bp_id = event->breakpoint()->id();
      }
      (*paused_event_handler)(isolate_id, bp_id, location);
    }
  } else if (event->type() == DebuggerEvent::kBreakpointResolved) {
    if (bp_resolved_handler != NULL) {
      SourceBreakpoint* bpt = event->breakpoint();
      ASSERT(bpt != NULL);
      Dart_CodeLocation location;
      Library& library = Library::Handle(isolate);
      Script& script = Script::Handle(isolate);
      intptr_t token_pos;
      bpt->GetCodeLocation(&library, &script, &token_pos);
      location.script_url = Api::NewHandle(isolate, script.url());
      location.library_id = library.index();
      location.token_pos = token_pos;
      (*bp_resolved_handler)(isolate_id, bpt->id(), location);
    }
  } else if (event->type() == DebuggerEvent::kExceptionThrown) {
    if (exc_thrown_handler != NULL) {
      Dart_Handle exception =
          Api::NewHandle(isolate, event->exception()->raw());
      Dart_StackTrace trace =
      reinterpret_cast<Dart_StackTrace>(isolate->debugger()->StackTrace());
      (*exc_thrown_handler)(isolate_id, exception, trace);
    }
  } else if (event->type() == DebuggerEvent::kIsolateCreated) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kCreated);
    }
  } else if (event->type() == DebuggerEvent::kIsolateInterrupted) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kInterrupted);
    }
  } else if (event->type() == DebuggerEvent::kIsolateShutdown) {
    if (isolate_event_handler != NULL) {
      (*isolate_event_handler)(event->isolate_id(), kShutdown);
    }
  } else {
    UNIMPLEMENTED();
  }
  Dart_ExitScope();
}


DART_EXPORT void Dart_SetBreakpointHandler(Dart_BreakpointHandler bp_handler) {
  legacy_bp_handler = bp_handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT void Dart_SetPausedEventHandler(Dart_PausedEventHandler handler) {
  paused_event_handler = handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT void Dart_SetBreakpointResolvedHandler(
                            Dart_BreakpointResolvedHandler handler) {
  bp_resolved_handler = handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT void Dart_SetExceptionThrownHandler(
                            Dart_ExceptionThrownHandler handler) {
  exc_thrown_handler = handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT void Dart_SetIsolateEventHandler(Dart_IsolateEventHandler handler) {
  isolate_event_handler = handler;
  Debugger::SetEventHandler(DebuggerEventHandler);
}


DART_EXPORT Dart_Handle Dart_SetExceptionPauseInfo(
                            Dart_ExceptionPauseInfo pause_info) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetExceptionPauseInfo(pause_info);
  return Api::Success();
}


DART_EXPORT Dart_ExceptionPauseInfo Dart_GetExceptionPauseInfo() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  return isolate->debugger()->GetExceptionPauseInfo();
}


DART_EXPORT Dart_Handle Dart_GetStackTrace(Dart_StackTrace* trace) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(trace);
  *trace = reinterpret_cast<Dart_StackTrace>(
      isolate->debugger()->CurrentStackTrace());
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetStackTraceFromError(Dart_Handle handle,
                                                    Dart_StackTrace* trace) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(trace);
  const Object& obj = Object::Handle(isolate, Api::UnwrapHandle(handle));
  if (obj.IsUnhandledException()) {
    const UnhandledException& error = UnhandledException::Cast(obj);
    Stacktrace& dart_stacktrace = Stacktrace::Handle(isolate);
    dart_stacktrace ^= error.stacktrace();
    if (dart_stacktrace.IsNull()) {
      *trace = NULL;
    } else {
      *trace = reinterpret_cast<Dart_StackTrace>(
        isolate->debugger()->StackTraceFrom(dart_stacktrace));
    }
    return Api::Success();
  } else {
    return Api::NewError("Can only get stacktraces from error handles or "
                         "instances of Error.");
  }
}


DART_EXPORT Dart_Handle Dart_ActivationFrameInfo(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle* function_name,
                            Dart_Handle* script_url,
                            intptr_t* line_number,
                            intptr_t* column_number) {
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
  if (column_number != NULL) {
    *column_number = frame->ColumnNumber();
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_ActivationFrameGetLocation(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle* function_name,
                            Dart_Handle* function,
                            Dart_CodeLocation* location) {
  // TODO(hausner): Implement a way to recognize when there
  // is no source code for the code in the frame.
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);
  if (function_name != NULL) {
    *function_name = Api::NewHandle(isolate, frame->QualifiedFunctionName());
  }
  if (function != NULL) {
    *function = Api::NewHandle(isolate, frame->function().raw());
  }

  if (location != NULL) {
    location->script_url = Api::NewHandle(isolate, frame->SourceUrl());
    const Library& lib = Library::Handle(frame->Library());
    location->library_id = lib.index();
    location->token_pos = frame->TokenPos();
  }
  return Api::Success();
}

DART_EXPORT Dart_Handle Dart_ActivationFrameGetFramePointer(
                            Dart_ActivationFrame activation_frame,
                            uintptr_t* frame_pointer) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);

  if (frame_pointer != NULL) {
    *frame_pointer = static_cast<uintptr_t>(frame->fp());
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetFunctionOrigin(Dart_Handle function_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Function, function, function_in);

  const Class& cls = Class::Handle(function.origin());
  if (!cls.IsTopLevel()) {
    return Dart_NewInteger(cls.id());
  }
  return Api::Null();
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
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);

  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);
  SourceBreakpoint* bpt =
      debugger->SetBreakpointAtLine(script_url, line_number);
  if (bpt == NULL) {
    return Api::NewError("%s: could not set breakpoint at line %" Pd " in '%s'",
                         CURRENT_FUNC, line_number, script_url.ToCString());
  }
  return Dart_NewInteger(bpt->id());
}


DART_EXPORT Dart_Handle Dart_GetBreakpointURL(intptr_t bp_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);

  SourceBreakpoint* bpt = debugger->GetBreakpointById(bp_id);
  if (bpt == NULL) {
    return Api::NewError("%s: breakpoint with id %" Pd " does not exist",
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
    return Api::NewError("%s: breakpoint with id %" Pd " does not exist",
                         CURRENT_FUNC, bp_id);
  }
  return Dart_NewInteger(bpt->LineNumber());
}


DART_EXPORT Dart_Handle Dart_SetBreakpointAtEntry(
                            Dart_Handle library_in,
                            Dart_Handle class_name_in,
                            Dart_Handle function_name_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Library, library, library_in);
  UNWRAP_AND_CHECK_PARAM(String, class_name, class_name_in);
  UNWRAP_AND_CHECK_PARAM(String, function_name, function_name_in);

  // Ensure that the library is loaded.
  if (!library.Loaded()) {
    return Api::NewError(
        "%s expects library argument 'library_in' to be loaded.",
        CURRENT_FUNC);
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

  SourceBreakpoint* bpt = debugger->SetBreakpointAtEntry(bp_target);
  if (bpt == NULL) {
    const char* target_name = Debugger::QualifiedFunctionName(bp_target);
    return Api::NewError("%s: no breakpoint location found in '%s'",
                         CURRENT_FUNC, target_name);
  }
  return Dart_NewInteger(bpt->id());
}


DART_EXPORT Dart_Handle Dart_OneTimeBreakAtEntry(
                            Dart_Handle library_in,
                            Dart_Handle class_name_in,
                            Dart_Handle function_name_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Library, library, library_in);
  UNWRAP_AND_CHECK_PARAM(String, class_name, class_name_in);
  UNWRAP_AND_CHECK_PARAM(String, function_name, function_name_in);

  // Ensure that the library is loaded.
  if (!library.Loaded()) {
    return Api::NewError(
        "%s expects library argument 'library_in' to be loaded.",
        CURRENT_FUNC);
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

  const Error& error =
      Error::Handle(isolate, debugger->OneTimeBreakAtEntry(bp_target));
  if (!error.IsNull()) {
    return Api::NewHandle(isolate, error.raw());
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_RemoveBreakpoint(intptr_t bp_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  Debugger* debugger = isolate->debugger();
  ASSERT(debugger != NULL);

  isolate->debugger()->RemoveBreakpoint(bp_id);
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetStepOver() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetStepOver();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetStepInto() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetSingleStep();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetStepOut() {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  isolate->debugger()->SetStepOut();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetInstanceFields(Dart_Handle object_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Instance, obj, object_in);
  return Api::NewHandle(isolate, isolate->debugger()->GetInstanceFields(obj));
}


DART_EXPORT Dart_Handle Dart_GetStaticFields(Dart_Handle target) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Type& type_obj = Api::UnwrapTypeHandle(isolate, target);
  if (type_obj.IsNull()) {
    return Api::NewError("%s expects argument 'target' to be a type",
                         CURRENT_FUNC);
  }
  const Class& cls = Class::Handle(isolate, type_obj.type_class());
  return Api::NewHandle(isolate, isolate->debugger()->GetStaticFields(cls));
}


DART_EXPORT Dart_Handle Dart_GetLibraryFields(intptr_t library_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib =
      Library::Handle(isolate, Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  return Api::NewHandle(isolate, isolate->debugger()->GetLibraryFields(lib));
}


DART_EXPORT Dart_Handle Dart_GetGlobalVariables(intptr_t library_id) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  return Api::NewHandle(isolate, isolate->debugger()->GetGlobalFields(lib));
}


DART_EXPORT Dart_Handle Dart_ActivationFrameEvaluate(
                            Dart_ActivationFrame activation_frame,
                            Dart_Handle expr_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  CHECK_AND_CAST(ActivationFrame, frame, activation_frame);
  UNWRAP_AND_CHECK_PARAM(String, expr, expr_in);
  return Api::NewHandle(isolate, frame->Evaluate(expr));
}


DART_EXPORT Dart_Handle Dart_EvaluateExpr(Dart_Handle target_in,
                                          Dart_Handle expr_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  const Object& target = Object::Handle(isolate, Api::UnwrapHandle(target_in));
  if (target.IsError()) return target_in;
  if (target.IsNull()) {
    return Api::NewError("%s expects argument 'target' to be non-null",
                         CURRENT_FUNC);
  }
  UNWRAP_AND_CHECK_PARAM(String, expr, expr_in);
  // Type extends Instance, must check first.
  if (target.IsType()) {
    const Class& cls = Class::Handle(isolate, Type::Cast(target).type_class());
    return Api::NewHandle(isolate, cls.Evaluate(expr,
                                                Array::empty_array(),
                                                Array::empty_array()));
  } else if (target.IsInstance()) {
    const Instance& inst = Instance::Cast(target);
    return Api::NewHandle(isolate, inst.Evaluate(expr,
                                                 Array::empty_array(),
                                                 Array::empty_array()));
  } else if (target.IsLibrary()) {
    const Library& lib = Library::Cast(target);
    return Api::NewHandle(isolate, lib.Evaluate(expr,
                                                Array::empty_array(),
                                                Array::empty_array()));
  } else if (target.IsClass()) {
    const Class& cls = Class::Cast(target);
    return Api::NewHandle(isolate, cls.Evaluate(expr,
                                                Array::empty_array(),
                                                Array::empty_array()));
  }
  return Api::NewError("%s: unsupported target type", CURRENT_FUNC);
}


DART_EXPORT Dart_Handle Dart_GetObjClass(Dart_Handle object_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Instance, obj, object_in);
  return Api::NewHandle(isolate, obj.GetType());
}


DART_EXPORT Dart_Handle Dart_GetObjClassId(Dart_Handle object_in,
                                           intptr_t* class_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Instance, obj, object_in);
  CHECK_NOT_NULL(class_id);
  *class_id = obj.GetClassId();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetClassFromId(intptr_t class_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (!isolate->class_table()->IsValidIndex(class_id)) {
    return Api::NewError("%s: %" Pd " is not a valid class id",
                         CURRENT_FUNC, class_id);
  }
  return Api::NewHandle(isolate, isolate->class_table()->At(class_id));
}


DART_EXPORT Dart_Handle Dart_GetSupertype(Dart_Handle type_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);

  UNWRAP_AND_CHECK_PARAM(Type, type, type_in);
  if (!type.IsFinalized()) {
    return Api::NewError("%s: type in 'type_in' is not a finalized type",
                         CURRENT_FUNC);
  }
  if (!type.IsInstantiated()) {
    return Api::NewError("%s: type in 'type_in' is not an instantiated type",
                         CURRENT_FUNC);
  }
  const Class& cls= Class::Handle(type.type_class());
  if (cls.NumTypeParameters() == 0) {
    // The super type has no type parameters or it is already instantiated
    // just return it.
    const AbstractType& type = AbstractType::Handle(cls.super_type());
    if (type.IsNull()) {
      return Dart_Null();
    }
    return Api::NewHandle(isolate, type.Canonicalize());
  }
  // Set up the type arguments array for the super class type.
  const Class& super_cls = Class::Handle(cls.SuperClass());
  intptr_t num_expected_type_arguments = super_cls.NumTypeArguments();
  TypeArguments& super_type_args_array = TypeArguments::Handle();
  const TypeArguments& type_args_array =
      TypeArguments::Handle(type.arguments());
  if (!type_args_array.IsNull() && (num_expected_type_arguments > 0)) {
    super_type_args_array = TypeArguments::New(num_expected_type_arguments);
    AbstractType& type_arg = AbstractType::Handle();
    for (intptr_t i = 0; i < num_expected_type_arguments; i++) {
      type_arg ^= type_args_array.TypeAt(i);
      super_type_args_array.SetTypeAt(i, type_arg);
    }
  }

  // Construct the super type object, canonicalize it and return.
  Type& instantiated_type = Type::Handle(
      Type::New(super_cls, super_type_args_array, Scanner::kNoSourcePos));
  ASSERT(!instantiated_type.IsNull());
  instantiated_type.SetIsFinalized();
  return Api::NewHandle(isolate, instantiated_type.Canonicalize());
}


DART_EXPORT Dart_Handle Dart_GetClosureInfo(
                            Dart_Handle closure,
                            Dart_Handle* name,
                            Dart_Handle* signature,
                            Dart_CodeLocation* location) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(Instance, instance, closure);
  CHECK_NOT_NULL(location);

  if (!instance.IsClosure()) {
    return Api::NewError("%s: parameter 0 is not a closure", CURRENT_FUNC);
  }
  const Function& func = Function::Handle(Closure::function(instance));
  ASSERT(!func.IsNull());
  if (name != NULL) {
    *name = Api::NewHandle(isolate, func.QualifiedUserVisibleName());
  }
  if (signature != NULL) {
    *signature = Api::NewHandle(isolate, func.UserVisibleSignature());
  }

  if (location != NULL) {
    if (func.token_pos() >= 0) {
      const Class& cls = Class::Handle(func.origin());
      ASSERT(!cls.IsNull());
      const Library& lib = Library::Handle(isolate, cls.library());
      ASSERT(!lib.IsNull());
      // Note func.script() is not the same as cls.script() for eval functions.
      const Script& script = Script::Handle(func.script());
      ASSERT(!script.IsNull());
      location->script_url = Api::NewHandle(isolate, script.url());
      location->library_id = lib.index();
      location->token_pos = func.token_pos();
    } else {
      location->script_url = Api::NewHandle(isolate, String::null());
      location->library_id = -1;
      location->token_pos = -1;
    }
  }
  return Api::True();
}


DART_EXPORT Dart_Handle Dart_GetClassInfo(
                            intptr_t cls_id,
                            Dart_Handle* class_name,
                            intptr_t* library_id,
                            intptr_t* super_class_id,
                            Dart_Handle* static_fields) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  if (!isolate->class_table()->IsValidIndex(cls_id)) {
    return Api::NewError("%s: %" Pd " is not a valid class id",
                         CURRENT_FUNC, cls_id);
  }
  Class& cls = Class::Handle(isolate, isolate->class_table()->At(cls_id));
  if (class_name != NULL) {
    *class_name = Api::NewHandle(isolate, cls.Name());
  }
  if (library_id != NULL) {
    const Library& lib = Library::Handle(isolate, cls.library());
    *library_id = lib.index();
  }
  if (super_class_id != NULL) {
    *super_class_id = 0;
    Class& super_cls = Class::Handle(isolate, cls.SuperClass());
    if (!super_cls.IsNull()) {
      *super_class_id = super_cls.id();
    }
  }
  if (static_fields != NULL) {
    *static_fields =
        Api::NewHandle(isolate, isolate->debugger()->GetStaticFields(cls));
  }
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_ScriptGetSource(
                            intptr_t library_id,
                            Dart_Handle script_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);
  const Script& script = Script::Handle(lib.LookupScript(script_url));
  if (script.IsNull()) {
    return Api::NewError("%s: script '%s' not found in library '%s'",
                         CURRENT_FUNC, script_url.ToCString(),
                         String::Handle(lib.url()).ToCString());
  }
  return Api::NewHandle(isolate, script.Source());
}


DART_EXPORT Dart_Handle Dart_ScriptGetTokenInfo(
                            intptr_t library_id,
                            Dart_Handle script_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  UNWRAP_AND_CHECK_PARAM(String, script_url, script_url_in);
  const Script& script = Script::Handle(lib.LookupScript(script_url));
  if (script.IsNull()) {
    return Api::NewError("%s: script '%s' not found in library '%s'",
                         CURRENT_FUNC, script_url.ToCString(),
                         String::Handle(lib.url()).ToCString());
  }

  const GrowableObjectArray& info =
      GrowableObjectArray::Handle(script.GenerateLineNumberArray());
  return Api::NewHandle(isolate, Array::MakeArray(info));
}


DART_EXPORT Dart_Handle Dart_GenerateScriptSource(Dart_Handle library_url_in,
                                                  Dart_Handle script_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  UNWRAP_AND_CHECK_PARAM(String, library_url, library_url_in);
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

  return Api::NewHandle(isolate, script.GenerateSource());
}


DART_EXPORT Dart_Handle Dart_GetScriptURLs(Dart_Handle library_url_in) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
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


DART_EXPORT Dart_Handle Dart_GetLibraryIds() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);

  const GrowableObjectArray& libs =
      GrowableObjectArray::Handle(isolate->object_store()->libraries());
  int num_libs = libs.Length();

  // Create new list and populate with the url of loaded libraries.
  Library &lib = Library::Handle();
  const Array& library_id_list = Array::Handle(Array::New(num_libs));
  for (int i = 0; i < num_libs; i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    ASSERT(Smi::IsValid(lib.index()));
    library_id_list.SetAt(i, Smi::Handle(Smi::New(lib.index())));
  }
  return Api::NewHandle(isolate, library_id_list.raw());
}


DART_EXPORT Dart_Handle Dart_GetLibraryFromId(intptr_t library_id) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  return Api::NewHandle(isolate, lib.raw());
}


DART_EXPORT Dart_Handle Dart_LibraryId(Dart_Handle library,
                                       intptr_t* library_id) {
  Isolate* isolate = Isolate::Current();
  DARTSCOPE(isolate);
  const Library& lib = Api::UnwrapLibraryHandle(isolate, library);
  if (lib.IsNull()) {
    RETURN_TYPE_ERROR(isolate, library, Library);
  }
  if (library_id == NULL) {
    RETURN_NULL_ERROR(library_id);
  }
  *library_id = lib.index();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_GetLibraryImports(intptr_t library_id) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  const GrowableObjectArray& import_list =
      GrowableObjectArray::Handle(GrowableObjectArray::New(8));

  String& prefix_name = String::Handle(isolate);
  Library& imported = Library::Handle(isolate);
  intptr_t num_imports = lib.num_imports();
  for (int i = 0; i < num_imports; i++) {
    import_list.Add(prefix_name);  // Null prefix name means no prefix.
    imported = lib.ImportLibraryAt(i);
    ASSERT(!imported.IsNull());
    ASSERT(Smi::IsValid(imported.index()));
    import_list.Add(Smi::Handle(Smi::New(imported.index())));
  }
  LibraryPrefixIterator it(lib);
  LibraryPrefix& prefix = LibraryPrefix::Handle(isolate);
  while (it.HasNext()) {
    prefix = it.GetNext();
    prefix_name = prefix.name();
    ASSERT(!prefix_name.IsNull());
    prefix_name = String::Concat(prefix_name, Symbols::Dot());
    for (int32_t i = 0; i < prefix.num_imports(); i++) {
      imported = prefix.GetLibrary(i);
      import_list.Add(prefix_name);
      import_list.Add(Smi::Handle(Smi::New(imported.index())));
    }
  }
  return Api::NewHandle(isolate, Array::MakeArray(import_list));
}


DART_EXPORT Dart_Handle Dart_GetLibraryURL(intptr_t library_id) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  return Api::NewHandle(isolate, lib.url());
}


DART_EXPORT Dart_Handle Dart_GetLibraryDebuggable(intptr_t library_id,
                                                  bool* is_debuggable) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  CHECK_NOT_NULL(is_debuggable);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  *is_debuggable = lib.IsDebuggable();
  return Api::Success();
}


DART_EXPORT Dart_Handle Dart_SetLibraryDebuggable(intptr_t library_id,
                                                  bool is_debuggable) {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  DARTSCOPE(isolate);
  const Library& lib = Library::Handle(Library::GetLibrary(library_id));
  if (lib.IsNull()) {
    return Api::NewError("%s: %" Pd " is not a valid library id",
                         CURRENT_FUNC, library_id);
  }
  lib.set_debuggable(is_debuggable);
  return Api::Success();
}


DART_EXPORT Dart_Isolate Dart_GetIsolate(Dart_IsolateId isolate_id) {
  Isolate* isolate = PortMap::GetIsolate(isolate_id);
  return Api::CastIsolate(isolate);
}


DART_EXPORT Dart_IsolateId Dart_GetIsolateId(Dart_Isolate dart_isolate) {
  Isolate* isolate = reinterpret_cast<Isolate*>(dart_isolate);
  return isolate->debugger()->GetIsolateId();
}

}  // namespace dart
