// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "include/dart_api_dl.h"
#include "include/dart_native_api.h"
#include "include/dart_version.h"
#include "include/internal/dart_api_dl_impl.h"
#include "platform/globals.h"
#include "vm/bootstrap_natives.h"
#include "vm/class_finalizer.h"
#include "vm/class_id.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/dart_api_impl.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/log.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/symbols.h"

#if !defined(DART_PRECOMPILED_RUNTIME)
#include "vm/compiler/assembler/assembler.h"
#include "vm/compiler/ffi/call.h"
#include "vm/compiler/ffi/callback.h"
#include "vm/compiler/ffi/marshaller.h"
#include "vm/compiler/jit/compiler.h"
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

// The remainder of this file implements the dart:ffi native methods.

DEFINE_NATIVE_ENTRY(Ffi_fromAddress, 1, 1) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Ffi_address, 0, 1) {
  UNREACHABLE();
}

#define DEFINE_NATIVE_ENTRY_LOAD(type)                                         \
  DEFINE_NATIVE_ENTRY(Ffi_load##type, 0, 2) { UNREACHABLE(); }
CLASS_LIST_FFI_NUMERIC_FIXED_SIZE(DEFINE_NATIVE_ENTRY_LOAD)
#undef DEFINE_NATIVE_ENTRY_LOAD

DEFINE_NATIVE_ENTRY(Ffi_loadPointer, 1, 2) {
  UNREACHABLE();
}

DEFINE_NATIVE_ENTRY(Ffi_loadStruct, 0, 2) {
  UNREACHABLE();
}

#define DEFINE_NATIVE_ENTRY_STORE(type)                                        \
  DEFINE_NATIVE_ENTRY(Ffi_store##type, 0, 3) { UNREACHABLE(); }
CLASS_LIST_FFI_NUMERIC_FIXED_SIZE(DEFINE_NATIVE_ENTRY_STORE)
#undef DEFINE_NATIVE_ENTRY_STORE

DEFINE_NATIVE_ENTRY(Ffi_storePointer, 0, 3) {
  UNREACHABLE();
}

// Static invocations to this method are translated directly in streaming FGB.
DEFINE_NATIVE_ENTRY(Ffi_asFunctionInternal, 2, 2) {
  UNREACHABLE();
}

#define DEFINE_NATIVE_ENTRY_AS_EXTERNAL_TYPED_DATA(type)                       \
  DEFINE_NATIVE_ENTRY(Ffi_asExternalTypedData##type, 0, 2) { UNREACHABLE(); }
CLASS_LIST_FFI_NUMERIC_FIXED_SIZE(DEFINE_NATIVE_ENTRY_AS_EXTERNAL_TYPED_DATA)
#undef DEFINE_NATIVE_ENTRY_AS_EXTERNAL_TYPED_DATA

DEFINE_NATIVE_ENTRY(Ffi_nativeCallbackFunction, 1, 2) {
#if defined(DART_PRECOMPILED_RUNTIME) || defined(DART_PRECOMPILER)
  // Calls to this function are removed by the flow-graph builder in AOT.
  // See StreamingFlowGraphBuilder::BuildFfiNativeCallbackFunction().
  UNREACHABLE();
#else
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Closure, closure, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, exceptional_return,
                               arguments->NativeArgAt(1));

  ASSERT(type_arg.IsInstantiated() && type_arg.IsFunctionType());
  const FunctionType& native_signature = FunctionType::Cast(type_arg);
  Function& func = Function::Handle(zone, closure.function());

  // The FE verifies that the target of a 'fromFunction' is a static method, so
  // the value we see here must be a static tearoff. See ffi_use_sites.dart for
  // details.
  //
  // TODO(36748): Define hot-reload semantics of native callbacks. We may need
  // to look up the target by name.
  ASSERT(func.IsImplicitClosureFunction());
  func = func.parent_function();
  ASSERT(func.is_static());

  // AbiSpecificTypes can have an incomplete mapping.
  const char* error = nullptr;
  compiler::ffi::NativeFunctionTypeFromFunctionType(zone, native_signature,
                                                    &error);
  if (error != nullptr) {
    Exceptions::ThrowCompileTimeError(LanguageError::Handle(
        zone, LanguageError::New(String::Handle(zone, String::New(error)))));
  }

  // We are returning an object which is not an Instance here. This is only OK
  // because we know that the result will be passed directly to
  // _pointerFromFunction and will not leak out into user code.
  arguments->SetReturn(
      Function::Handle(zone, compiler::ffi::NativeCallbackFunction(
                                 native_signature, func, exceptional_return)));

  // Because we have already set the return value.
  return Object::sentinel().ptr();
#endif
}

DEFINE_NATIVE_ENTRY(Ffi_pointerFromFunction, 1, 1) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  const Function& function =
      Function::CheckedHandle(zone, arguments->NativeArg0());

  Code& code = Code::Handle(zone);

#if defined(DART_PRECOMPILED_RUNTIME)
  code = function.CurrentCode();
#else
  // We compile the callback immediately because we need to return a pointer to
  // the entry-point. Native calls do not use patching like Dart calls, so we
  // cannot compile it lazily.
  const Object& result = Object::Handle(
      zone, Compiler::CompileOptimizedFunction(thread, function));
  if (result.IsError()) {
    Exceptions::PropagateError(Error::Cast(result));
  }
  ASSERT(result.IsCode());
  code ^= result.ptr();
#endif

  ASSERT(!code.IsNull());
  thread->SetFfiCallbackCode(function.FfiCallbackId(), code);

#ifdef TARGET_ARCH_IA32
  // On ia32, store the stack delta that we need to use when returning.
  const intptr_t stack_return_delta =
      function.FfiCSignatureReturnsStruct() && CallingConventions::kUsesRet4
          ? compiler::target::kWordSize
          : 0;
  thread->SetFfiCallbackStackReturn(function.FfiCallbackId(),
                                    stack_return_delta);
#endif

  uword entry_point = code.EntryPoint();
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (NativeCallbackTrampolines::Enabled()) {
    entry_point = isolate->native_callback_trampolines()->TrampolineForId(
        function.FfiCallbackId());
  }
#endif

  return Pointer::New(type_arg, entry_point);
}

DEFINE_NATIVE_ENTRY(DartNativeApiFunctionPointer, 0, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, name_dart, arguments->NativeArgAt(0));
  const char* name = name_dart.ToCString();

#define RETURN_FUNCTION_ADDRESS(function_name, R, A)                           \
  if (strcmp(name, #function_name) == 0) {                                     \
    return Integer::New(reinterpret_cast<intptr_t>(function_name));            \
  }
  DART_NATIVE_API_DL_SYMBOLS(RETURN_FUNCTION_ADDRESS)
#undef RETURN_FUNCTION_ADDRESS

  const String& error = String::Handle(
      String::NewFormatted("Unknown dart_native_api.h symbol: %s.", name));
  Exceptions::ThrowArgumentError(error);
}

DEFINE_NATIVE_ENTRY(DartApiDLMajorVersion, 0, 0) {
  return Integer::New(DART_API_DL_MAJOR_VERSION);
}

DEFINE_NATIVE_ENTRY(DartApiDLMinorVersion, 0, 0) {
  return Integer::New(DART_API_DL_MINOR_VERSION);
}

static const DartApiEntry dart_api_entries[] = {
#define ENTRY(name, R, A)                                                      \
  DartApiEntry{#name, reinterpret_cast<void (*)()>(name)},
    DART_API_ALL_DL_SYMBOLS(ENTRY)
#undef ENTRY
        DartApiEntry{nullptr, nullptr}};

static const DartApi dart_api_data = {
    DART_API_DL_MAJOR_VERSION, DART_API_DL_MINOR_VERSION, dart_api_entries};

DEFINE_NATIVE_ENTRY(DartApiDLInitializeData, 0, 0) {
  return Integer::New(reinterpret_cast<intptr_t>(&dart_api_data));
}

// FFI native C function pointer resolver.
static intptr_t FfiResolve(Dart_Handle lib_url,
                           Dart_Handle name,
                           uintptr_t args_n) {
  DARTSCOPE(Thread::Current());

  const String& lib_url_str = Api::UnwrapStringHandle(T->zone(), lib_url);
  const String& function_name = Api::UnwrapStringHandle(T->zone(), name);

  // Find the corresponding library's native function resolver (if set).
  const Library& lib = Library::Handle(Library::LookupLibrary(T, lib_url_str));
  if (lib.IsNull()) {
    const String& error = String::Handle(String::NewFormatted(
        "Unknown library: '%s'.", lib_url_str.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }
  auto resolver = lib.ffi_native_resolver();
  if (resolver == nullptr) {
    const String& error = String::Handle(String::NewFormatted(
        "Library has no handler: '%s'.", lib_url_str.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }

  auto* f = resolver(function_name.ToCString(), args_n);
  if (f == nullptr) {
    const String& error = String::Handle(String::NewFormatted(
        "Couldn't resolve function: '%s'.", function_name.ToCString()));
    Exceptions::ThrowArgumentError(error);
  }

  return reinterpret_cast<intptr_t>(f);
}

// Bootstrap to get the FFI Native resolver through a `native` call.
DEFINE_NATIVE_ENTRY(Ffi_GetFfiNativeResolver, 1, 0) {
  GET_NATIVE_TYPE_ARGUMENT(type_arg, arguments->NativeTypeArgAt(0));
  return Pointer::New(type_arg, reinterpret_cast<intptr_t>(FfiResolve));
}

}  // namespace dart
