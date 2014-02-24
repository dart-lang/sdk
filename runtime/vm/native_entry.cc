// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry.h"

#include "include/dart_api.h"

#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"

namespace dart {

DEFINE_FLAG(bool, trace_natives, false,
            "Trace invocation of natives (debug mode only)");


static ExternalLabel native_call_label(
    "native_function_call",
    reinterpret_cast<uword>(&NativeEntry::NativeCallWrapper));


NativeFunction NativeEntry::ResolveNative(const Library& library,
                                          const String& function_name,
                                          int number_of_arguments,
                                          bool* auto_setup_scope) {
  // Now resolve the native function to the corresponding native entrypoint.
  if (library.native_entry_resolver() == 0) {
    // Native methods are not allowed in the library to which this
    // class belongs in.
    return NULL;
  }
  Dart_EnterScope();  // Enter a new Dart API scope as we invoke API entries.
  Dart_NativeEntryResolver resolver = library.native_entry_resolver();
  Dart_NativeFunction native_function =
      resolver(Api::NewHandle(Isolate::Current(), function_name.raw()),
               number_of_arguments, auto_setup_scope);
  Dart_ExitScope();  // Exit the Dart API scope.
  return reinterpret_cast<NativeFunction>(native_function);
}


const ExternalLabel& NativeEntry::NativeCallWrapperLabel() {
  return native_call_label;
}


void NativeEntry::NativeCallWrapper(Dart_NativeArguments args,
                                    Dart_NativeFunction func) {
  CHECK_STACK_ALIGNMENT;
  VERIFY_ON_TRANSITION;
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  Isolate* isolate = arguments->isolate();
  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* current_top_scope = state->top_scope();
  ApiLocalScope* scope = state->reusable_scope();
  TRACE_NATIVE_CALL("0x%" Px "", reinterpret_cast<uintptr_t>(func));
  if (scope == NULL) {
    scope = new ApiLocalScope(current_top_scope,
                              isolate->top_exit_frame_info());
    ASSERT(scope != NULL);
  } else {
    scope->Reinit(isolate,
                  current_top_scope,
                  isolate->top_exit_frame_info());
    state->set_reusable_scope(NULL);
  }
  state->set_top_scope(scope);  // New scope is now the top scope.

  func(args);

  ASSERT(current_top_scope == scope->previous());
  state->set_top_scope(current_top_scope);  // Reset top scope to previous.
  if (state->reusable_scope() == NULL) {
    scope->Reset(isolate);  // Reset the old scope which we just exited.
    state->set_reusable_scope(scope);
  } else {
    ASSERT(state->reusable_scope() != scope);
    delete scope;
  }
  DEOPTIMIZE_ALOT;
  VERIFY_ON_TRANSITION;
}

}  // namespace dart
