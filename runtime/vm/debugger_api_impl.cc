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
      return Api::Error("%s expects argument '%s' to be non-null.",           \
                        CURRENT_FUNC, #param);                                \
    } else if (tmp.IsApiError()) {                                            \
      return param;                                                           \
    } else if (!tmp.Is##type()) {                                             \
      return Api::Error("%s expects argument '%s' to be of type %s.",         \
                        CURRENT_FUNC, #param, #type);                         \
    }                                                                         \
    var ^= tmp.raw();                                                         \
  } while (0);


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

  const char* msg = CheckIsolateState(isolate);
  if (msg != NULL) {
    return Api::Error(msg);
  }

  if (breakpoint != NULL) {
    *breakpoint = NULL;
  }

  // Resolve the breakpoint target function.
  Debugger* debugger = isolate->debugger();
  const Function& bp_target = Function::Handle(
      debugger->ResolveFunction(library, class_name, function_name));
  if (bp_target.IsNull()) {
    return Api::Error("Breakpoint target function does not exist");
  }

  LongJump* base = isolate->long_jump_base();
  LongJump jump;
  isolate->set_long_jump_base(&jump);
  Dart_Handle result = Api::True();
  if (setjmp(*jump.Set()) == 0) {
    Breakpoint* bpt = debugger->SetBreakpointAtEntry(bp_target);
    if (breakpoint != NULL) {
      *breakpoint = reinterpret_cast<Dart_Breakpoint>(bpt);
    }
  } else {
    SetupErrorResult(&result);
  }
  isolate->set_long_jump_base(base);
  return result;
}


}  // namespace dart
