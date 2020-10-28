// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_entry.h"

#include "include/dart_api.h"

#include "vm/bootstrap.h"
#include "vm/code_patcher.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_state.h"
#include "vm/heap/safepoint.h"
#include "vm/native_symbol.h"
#include "vm/object_store.h"
#include "vm/reusable_handles.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/tags.h"

namespace dart {

void DartNativeThrowTypeArgumentCountException(int num_type_args,
                                               int num_type_args_expected) {
  const String& error = String::Handle(String::NewFormatted(
      "Wrong number of type arguments (%i), expected %i type arguments",
      num_type_args, num_type_args_expected));
  Exceptions::ThrowArgumentError(error);
}

void DartNativeThrowArgumentException(const Instance& instance) {
  const Array& __args__ = Array::Handle(Array::New(1));
  __args__.SetAt(0, instance);
  Exceptions::ThrowByType(Exceptions::kArgument, __args__);
}

NativeFunction NativeEntry::ResolveNative(const Library& library,
                                          const String& function_name,
                                          int number_of_arguments,
                                          bool* auto_setup_scope) {
  // Now resolve the native function to the corresponding native entrypoint.
  if (library.native_entry_resolver() == NULL) {
    // Native methods are not allowed in the library to which this
    // class belongs in.
    return NULL;
  }
  Dart_NativeFunction native_function = NULL;
  {
    Thread* T = Thread::Current();
    Api::Scope api_scope(T);
    Dart_Handle api_function_name = Api::NewHandle(T, function_name.raw());
    {
      Dart_NativeEntryResolver resolver = library.native_entry_resolver();
      TransitionVMToNative transition(T);
      native_function =
          resolver(api_function_name, number_of_arguments, auto_setup_scope);
    }
  }
  return reinterpret_cast<NativeFunction>(native_function);
}

const uint8_t* NativeEntry::ResolveSymbolInLibrary(const Library& library,
                                                   uword pc) {
  Dart_NativeEntrySymbol symbol_resolver =
      library.native_entry_symbol_resolver();
  if (symbol_resolver == NULL) {
    // Cannot reverse lookup native entries.
    return NULL;
  }
  return symbol_resolver(reinterpret_cast<Dart_NativeFunction>(pc));
}

const uint8_t* NativeEntry::ResolveSymbol(uword pc) {
  Thread* thread = Thread::Current();
  REUSABLE_GROWABLE_OBJECT_ARRAY_HANDLESCOPE(thread);
  GrowableObjectArray& libs = reused_growable_object_array_handle.Handle();
  libs = thread->isolate()->object_store()->libraries();
  ASSERT(!libs.IsNull());
  intptr_t num_libs = libs.Length();
  for (intptr_t i = 0; i < num_libs; i++) {
    REUSABLE_LIBRARY_HANDLESCOPE(thread);
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

bool NativeEntry::ReturnValueIsError(NativeArguments* arguments) {
  ObjectPtr retval = arguments->ReturnValue();
  return (retval->IsHeapObject() && IsErrorClassId(retval->GetClassId()));
}

void NativeEntry::PropagateErrors(NativeArguments* arguments) {
  Thread* thread = arguments->thread();
  thread->UnwindScopes(thread->top_exit_frame_info());
  TransitionNativeToVM transition(thread);

  // The thread->zone() is different here than before we unwound.
  const Object& error =
      Object::Handle(thread->zone(), arguments->ReturnValue());
  Exceptions::PropagateError(Error::Cast(error));
  UNREACHABLE();
}

uword NativeEntry::BootstrapNativeCallWrapperEntry() {
  uword entry =
      reinterpret_cast<uword>(NativeEntry::BootstrapNativeCallWrapper);
#if defined(USING_SIMULATOR)
  entry = Simulator::RedirectExternalReference(
      entry, Simulator::kNativeCallWrapper,
      NativeEntry::kNumCallWrapperArguments);
#endif
  return entry;
}

void NativeEntry::BootstrapNativeCallWrapper(Dart_NativeArguments args,
                                             Dart_NativeFunction func) {
  CHECK_STACK_ALIGNMENT;
  if (func == LinkNativeCall) {
    func(args);
    return;
  }

  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  // Tell MemorySanitizer 'arguments' is initialized by generated code.
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  {
    Thread* thread = arguments->thread();
    ASSERT(thread == Thread::Current());
    TransitionGeneratedToVM transition(thread);
    StackZone zone(thread);
    // Be careful holding return_value_unsafe without a handle here.
    // A return of Object::sentinel means the return value has already
    // been set.
    ObjectPtr return_value_unsafe = reinterpret_cast<BootstrapNativeFunction>(
        func)(thread, zone.GetZone(), arguments);
    if (return_value_unsafe != Object::sentinel().raw()) {
      ASSERT(return_value_unsafe->IsDartInstance());
      arguments->SetReturnUnsafe(return_value_unsafe);
    }
    DEOPTIMIZE_ALOT;
  }
}

uword NativeEntry::NoScopeNativeCallWrapperEntry() {
  uword entry = reinterpret_cast<uword>(NativeEntry::NoScopeNativeCallWrapper);
#if defined(USING_SIMULATOR)
  entry = Simulator::RedirectExternalReference(
      entry, Simulator::kNativeCallWrapper,
      NativeEntry::kNumCallWrapperArguments);
#endif
  return entry;
}

void NativeEntry::NoScopeNativeCallWrapper(Dart_NativeArguments args,
                                           Dart_NativeFunction func) {
  CHECK_STACK_ALIGNMENT;
  NoScopeNativeCallWrapperNoStackCheck(args, func);
}

void NativeEntry::NoScopeNativeCallWrapperNoStackCheck(
    Dart_NativeArguments args,
    Dart_NativeFunction func) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  // Tell MemorySanitizer 'arguments' is initialized by generated code.
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  Thread* thread = arguments->thread();
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
  {
    TransitionGeneratedToNative transition(thread);
    func(args);
    if (ReturnValueIsError(arguments)) {
      PropagateErrors(arguments);
    }
  }
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
}

uword NativeEntry::AutoScopeNativeCallWrapperEntry() {
  uword entry =
      reinterpret_cast<uword>(NativeEntry::AutoScopeNativeCallWrapper);
#if defined(USING_SIMULATOR)
  entry = Simulator::RedirectExternalReference(
      entry, Simulator::kNativeCallWrapper,
      NativeEntry::kNumCallWrapperArguments);
#endif
  return entry;
}

void NativeEntry::AutoScopeNativeCallWrapper(Dart_NativeArguments args,
                                             Dart_NativeFunction func) {
  CHECK_STACK_ALIGNMENT;
  AutoScopeNativeCallWrapperNoStackCheck(args, func);
}

void NativeEntry::AutoScopeNativeCallWrapperNoStackCheck(
    Dart_NativeArguments args,
    Dart_NativeFunction func) {
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  // Tell MemorySanitizer 'arguments' is initialized by generated code.
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  Thread* thread = arguments->thread();
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
  {
    Isolate* isolate = thread->isolate();
    ApiState* state = isolate->group()->api_state();
    ASSERT(state != NULL);
    TRACE_NATIVE_CALL("0x%" Px "", reinterpret_cast<uintptr_t>(func));
    thread->EnterApiScope();
    {
      TransitionGeneratedToNative transition(thread);
      func(args);
      if (ReturnValueIsError(arguments)) {
        PropagateErrors(arguments);
      }
    }
    thread->ExitApiScope();
    DEOPTIMIZE_ALOT;
  }
  ASSERT(thread->execution_state() == Thread::kThreadInGenerated);
}

static NativeFunction ResolveNativeFunction(Zone* zone,
                                            const Function& func,
                                            bool* is_bootstrap_native,
                                            bool* is_auto_scope) {
  const Class& cls = Class::Handle(zone, func.Owner());
  const Library& library = Library::Handle(zone, cls.library());

  *is_bootstrap_native =
      Bootstrap::IsBootstrapResolver(library.native_entry_resolver());

  const String& native_name = String::Handle(zone, func.native_name());
  ASSERT(!native_name.IsNull());

  const int num_params = NativeArguments::ParameterCountForResolution(func);
  NativeFunction native_function = NativeEntry::ResolveNative(
      library, native_name, num_params, is_auto_scope);
  if (native_function == NULL) {
    FATAL2("Failed to resolve native function '%s' in '%s'\n",
           native_name.ToCString(), func.ToQualifiedCString());
  }
  return native_function;
}

uword NativeEntry::LinkNativeCallEntry() {
  uword entry = reinterpret_cast<uword>(NativeEntry::LinkNativeCall);
  return entry;
}

void NativeEntry::LinkNativeCall(Dart_NativeArguments args) {
  CHECK_STACK_ALIGNMENT;
  NativeArguments* arguments = reinterpret_cast<NativeArguments*>(args);
  // Tell MemorySanitizer 'arguments' is initialized by generated code.
  MSAN_UNPOISON(arguments, sizeof(*arguments));
  TRACE_NATIVE_CALL("%s", "LinkNative");

  NativeFunction target_function = NULL;
  bool is_bootstrap_native = false;
  bool is_auto_scope = true;

  {
    TransitionGeneratedToVM transition(arguments->thread());
    StackZone stack_zone(arguments->thread());
    Zone* zone = stack_zone.GetZone();

    DartFrameIterator iterator(arguments->thread(),
                               StackFrameIterator::kNoCrossThreadIteration);
    StackFrame* caller_frame = iterator.NextFrame();

    Code& code = Code::Handle(zone, caller_frame->LookupDartCode());
    Function& func = Function::Handle(zone, code.function());

    if (FLAG_trace_natives) {
      THR_Print("Resolving native target for %s\n", func.ToCString());
    }

    target_function =
        ResolveNativeFunction(arguments->thread()->zone(), func,
                              &is_bootstrap_native, &is_auto_scope);
    ASSERT(target_function != NULL);

#if defined(DEBUG)
    NativeFunction current_function = NULL;
    const Code& current_trampoline =
        Code::Handle(zone, CodePatcher::GetNativeCallAt(
                               caller_frame->pc(), code, &current_function));
    // Some other isolate(with code being shared in AOT) might have updated
    // target function/trampoline already.
    ASSERT(current_function ==
               reinterpret_cast<NativeFunction>(LinkNativeCall) ||
           current_function == target_function);
    ASSERT(current_trampoline.raw() == StubCode::CallBootstrapNative().raw() ||
           current_function == target_function);
#endif

    NativeFunction patch_target_function = target_function;
    Code& trampoline = Code::Handle(zone);
    if (is_bootstrap_native) {
      trampoline = StubCode::CallBootstrapNative().raw();
    } else if (is_auto_scope) {
      trampoline = StubCode::CallAutoScopeNative().raw();
    } else {
      trampoline = StubCode::CallNoScopeNative().raw();
    }
    CodePatcher::PatchNativeCallAt(caller_frame->pc(), code,
                                   patch_target_function, trampoline);

    if (FLAG_trace_natives) {
      THR_Print("    -> %p (%s)\n", target_function,
                is_bootstrap_native ? "bootstrap" : "non-bootstrap");
    }
  }

  // Tail-call resolved target.
  if (is_bootstrap_native) {
    NativeEntry::BootstrapNativeCallWrapper(
        args, reinterpret_cast<Dart_NativeFunction>(target_function));
  } else if (is_auto_scope) {
    // Because this call is within a compilation unit, Clang doesn't respect
    // the ABI alignment here.
    NativeEntry::AutoScopeNativeCallWrapperNoStackCheck(
        args, reinterpret_cast<Dart_NativeFunction>(target_function));
  } else {
    // Because this call is within a compilation unit, Clang doesn't respect
    // the ABI alignment here.
    NativeEntry::NoScopeNativeCallWrapperNoStackCheck(
        args, reinterpret_cast<Dart_NativeFunction>(target_function));
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)

// Note: not GC safe. Use with care.
NativeEntryData::Payload* NativeEntryData::FromTypedArray(TypedDataPtr data) {
  return reinterpret_cast<Payload*>(data->ptr()->data());
}

MethodRecognizer::Kind NativeEntryData::kind() const {
  return FromTypedArray(data_.raw())->kind;
}

void NativeEntryData::set_kind(MethodRecognizer::Kind value) const {
  FromTypedArray(data_.raw())->kind = value;
}

MethodRecognizer::Kind NativeEntryData::GetKind(TypedDataPtr data) {
  return FromTypedArray(data)->kind;
}

NativeFunctionWrapper NativeEntryData::trampoline() const {
  return FromTypedArray(data_.raw())->trampoline;
}

void NativeEntryData::set_trampoline(NativeFunctionWrapper value) const {
  FromTypedArray(data_.raw())->trampoline = value;
}

NativeFunctionWrapper NativeEntryData::GetTrampoline(TypedDataPtr data) {
  return FromTypedArray(data)->trampoline;
}

NativeFunction NativeEntryData::native_function() const {
  return FromTypedArray(data_.raw())->native_function;
}

void NativeEntryData::set_native_function(NativeFunction value) const {
  FromTypedArray(data_.raw())->native_function = value;
}

NativeFunction NativeEntryData::GetNativeFunction(TypedDataPtr data) {
  return FromTypedArray(data)->native_function;
}

intptr_t NativeEntryData::argc_tag() const {
  return FromTypedArray(data_.raw())->argc_tag;
}

void NativeEntryData::set_argc_tag(intptr_t value) const {
  FromTypedArray(data_.raw())->argc_tag = value;
}

intptr_t NativeEntryData::GetArgcTag(TypedDataPtr data) {
  return FromTypedArray(data)->argc_tag;
}

TypedDataPtr NativeEntryData::New(MethodRecognizer::Kind kind,
                                  NativeFunctionWrapper trampoline,
                                  NativeFunction native_function,
                                  intptr_t argc_tag) {
  const TypedData& data = TypedData::Handle(
      TypedData::New(kTypedDataUint8ArrayCid, sizeof(Payload), Heap::kOld));
  NativeEntryData native_entry(data);
  native_entry.set_kind(kind);
  native_entry.set_trampoline(trampoline);
  native_entry.set_native_function(native_function);
  native_entry.set_argc_tag(argc_tag);
  return data.raw();
}

#endif  // !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace dart
