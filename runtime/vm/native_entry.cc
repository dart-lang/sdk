// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry.h"

#include "include/dart_api.h"

#include "vm/bootstrap.h"
#include "vm/code_patcher.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/object_store.h"
#include "vm/reusable_handles.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"


namespace dart {

DEFINE_FLAG(bool, trace_natives, false,
            "Trace invocation of natives (debug mode only)");


static ExternalLabel native_call_label(
    reinterpret_cast<uword>(&NativeEntry::NativeCallWrapper));


static ExternalLabel link_native_call_label(
    reinterpret_cast<uword>(&NativeEntry::LinkNativeCall));


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


const uint8_t* NativeEntry::ResolveSymbolInLibrary(const Library& library,
                                                   uword pc) {
  Dart_NativeEntrySymbol symbol_resolver =
      library.native_entry_symbol_resolver();
  if (symbol_resolver == 0) {
    // Cannot reverse lookup native entries.
    return NULL;
  }
  return symbol_resolver(reinterpret_cast<Dart_NativeFunction>(pc));
}


const uint8_t* NativeEntry::ResolveSymbol(uword pc) {
  Isolate* isolate = Isolate::Current();
  REUSABLE_GROWABLE_OBJECT_ARRAY_HANDLESCOPE(isolate);
  GrowableObjectArray& libs = reused_growable_object_array_handle.Handle();
  libs ^= isolate->object_store()->libraries();
  ASSERT(!libs.IsNull());
  intptr_t num_libs = libs.Length();
  for (intptr_t i = 0; i < num_libs; i++) {
    REUSABLE_LIBRARY_HANDLESCOPE(isolate);
    Library& lib = reused_library_handle.Handle();
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    const uint8_t* r = ResolveSymbolInLibrary(lib, pc);
    if (r != NULL) {
      return r;
    }
  }
  return NULL;
}


const ExternalLabel& NativeEntry::NativeCallWrapperLabel() {
  return native_call_label;
}


void NativeEntry::NativeCallWrapper(Dart_NativeArguments args,
                                    Dart_NativeFunction func) {
  CHECK_STACK_ALIGNMENT;
  VERIFY_ON_TRANSITION;
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  /* Tell MemorySanitizer 'arguments' is initialized by generated code. */
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  Thread* thread = arguments->thread();
  Isolate* isolate = thread->isolate();

  ApiState* state = isolate->api_state();
  ASSERT(state != NULL);
  ApiLocalScope* current_top_scope = state->top_scope();
  ApiLocalScope* scope = state->reusable_scope();
  TRACE_NATIVE_CALL("0x%" Px "", reinterpret_cast<uintptr_t>(func));
  if (scope == NULL) {
    scope = new ApiLocalScope(current_top_scope,
                              thread->top_exit_frame_info());
    ASSERT(scope != NULL);
  } else {
    scope->Reinit(thread,
                  current_top_scope,
                  thread->top_exit_frame_info());
    state->set_reusable_scope(NULL);
  }
  state->set_top_scope(scope);  // New scope is now the top scope.

  func(args);

  ASSERT(current_top_scope == scope->previous());
  state->set_top_scope(current_top_scope);  // Reset top scope to previous.
  if (state->reusable_scope() == NULL) {
    scope->Reset(thread);  // Reset the old scope which we just exited.
    state->set_reusable_scope(scope);
  } else {
    ASSERT(state->reusable_scope() != scope);
    delete scope;
  }
  DEOPTIMIZE_ALOT;
  VERIFY_ON_TRANSITION;
}


static bool IsNativeKeyword(const TokenStream::Iterator& it) {
  return Token::IsIdentifier(it.CurrentTokenKind()) &&
      (it.CurrentLiteral() == Symbols::Native().raw());
}


static NativeFunction ResolveNativeFunction(Isolate *isolate,
                                            const Function& func,
                                            bool* is_bootstrap_native) {
  const Script& script = Script::Handle(isolate, func.script());
  const Class& cls = Class::Handle(isolate, func.Owner());
  const Library& library = Library::Handle(isolate, cls.library());

  *is_bootstrap_native =
      Bootstrap::IsBootstapResolver(library.native_entry_resolver());

  TokenStream::Iterator it(TokenStream::Handle(isolate, script.tokens()),
                           func.token_pos());

  const intptr_t end_pos = func.end_token_pos();
  while (!IsNativeKeyword(it) && it.CurrentPosition() <= end_pos) {
    it.Advance();
  }
  ASSERT(IsNativeKeyword(it));
  it.Advance();
  ASSERT(it.CurrentTokenKind() == Token::kSTRING);
  const String& native_name = String::Handle(it.CurrentLiteral());

  const int num_params = NativeArguments::ParameterCountForResolution(func);
  bool auto_setup_scope = true;
  return NativeEntry::ResolveNative(
      library, native_name, num_params, &auto_setup_scope);
}


const ExternalLabel& NativeEntry::LinkNativeCallLabel() {
  return link_native_call_label;
}


void NativeEntry::LinkNativeCall(Dart_NativeArguments args) {
  CHECK_STACK_ALIGNMENT;
  VERIFY_ON_TRANSITION;
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  /* Tell MemorySanitizer 'arguments' is initialized by generated code. */
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  TRACE_NATIVE_CALL("%s", "LinkNative");

  NativeFunction target_function = NULL;
  bool call_through_wrapper = false;
#ifdef USING_SIMULATOR
  bool is_native_auto_setup_scope = false;
  intptr_t num_parameters = -1;
#endif

  {
    StackZone zone(arguments->thread());

    DartFrameIterator iterator;
    StackFrame* caller_frame = iterator.NextFrame();

    const Code& code = Code::Handle(caller_frame->LookupDartCode());
    const Function& func = Function::Handle(code.function());
#ifdef USING_SIMULATOR
    is_native_auto_setup_scope = func.IsNativeAutoSetupScope();
    num_parameters = func.NumParameters();
#endif

    if (FLAG_trace_natives) {
      OS::Print("Resolving native target for %s\n", func.ToCString());
    }

    bool is_bootstrap_native = false;
    target_function = ResolveNativeFunction(
        arguments->thread()->isolate(), func, &is_bootstrap_native);
    ASSERT(target_function != NULL);

#if defined(DEBUG)
    {
      NativeFunction current_function = NULL;
      uword current_trampoline =
          CodePatcher::GetNativeCallAt(caller_frame->pc(),
                                       code,
                                       &current_function);
#if !defined(USING_SIMULATOR)
      ASSERT(current_function ==
             reinterpret_cast<NativeFunction>(LinkNativeCall));
#else
      ASSERT(current_function ==
             reinterpret_cast<NativeFunction>(
                 Simulator::RedirectExternalReference(
                     reinterpret_cast<uword>(LinkNativeCall),
                     Simulator::kBootstrapNativeCall,
                     func.NumParameters())));
#endif
      ASSERT(current_trampoline ==
             StubCode::CallBootstrapCFunction_entry()->EntryPoint());
    }
#endif

    const intptr_t argc_tag = NativeArguments::ComputeArgcTag(func);
    const bool is_leaf_call =
      (argc_tag & NativeArguments::AutoSetupScopeMask()) == 0;

    call_through_wrapper = !is_bootstrap_native && !is_leaf_call;

    const Code& trampoline = Code::Handle(call_through_wrapper ?
        StubCode::CallNativeCFunction_entry()->code() :
        StubCode::CallBootstrapCFunction_entry()->code());

    NativeFunction patch_target_function = target_function;
#if defined(USING_SIMULATOR)
    if (!call_through_wrapper || !is_native_auto_setup_scope) {
      patch_target_function = reinterpret_cast<NativeFunction>(
          Simulator::RedirectExternalReference(
              reinterpret_cast<uword>(patch_target_function),
              Simulator::kBootstrapNativeCall, num_parameters));
    }
#endif

    CodePatcher::PatchNativeCallAt(
        caller_frame->pc(), code, patch_target_function, trampoline);

    if (FLAG_trace_natives) {
      OS::Print("    -> %p (%s, %s)\n",
                target_function,
                is_bootstrap_native ? "bootstrap" : "non-bootstrap",
                is_leaf_call ? "leaf" : "non-leaf");
    }
  }
  VERIFY_ON_TRANSITION;

  // Tail-call resolved target.
  if (call_through_wrapper) {
    NativeEntry::NativeCallWrapper(
        args, reinterpret_cast<Dart_NativeFunction>(target_function));
  } else {
    target_function(arguments);
  }
}


}  // namespace dart
