// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "bin/namespace.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

static const int kNamespaceNativeFieldIndex = 0;

static void ReleaseNamespace(void* isolate_callback_data,
                             Dart_WeakPersistentHandle handle,
                             void* peer) {
  Namespace* namespc = reinterpret_cast<Namespace*>(peer);
  ASSERT(namespc != NULL);
  namespc->Release();
}

#if defined(DEBUG)
static bool IsNamespace(Dart_Handle namespc_obj) {
  Dart_Handle namespc_type =
      DartUtils::GetDartType("dart:io", "_NamespaceImpl");
  ASSERT(!Dart_IsError(namespc_type));
  bool isinstance = false;
  Dart_Handle result =
      Dart_ObjectIsType(namespc_obj, namespc_type, &isinstance);
  ASSERT(!Dart_IsError(result));
  return isinstance;
}
#endif

void FUNCTION_NAME(Namespace_Create)(Dart_NativeArguments args) {
  Dart_Handle namespc_obj = Dart_GetNativeArgument(args, 0);
  if (Dart_IsError(namespc_obj)) {
    Dart_PropagateError(namespc_obj);
  }
  DEBUG_ASSERT(IsNamespace(namespc_obj));

  // Allocate a native wrapper for the platform namespc bits.
  Namespace* namespc = NULL;
  Dart_Handle result;
  Dart_Handle native_namespc = Dart_GetNativeArgument(args, 1);
  if (Dart_IsInteger(native_namespc)) {
    int64_t namespc_val;
    result = Dart_IntegerToInt64(native_namespc, &namespc_val);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    namespc = Namespace::Create(namespc_val);
  } else if (Dart_IsString(native_namespc)) {
    const char* namespc_path;
    result = Dart_StringToCString(native_namespc, &namespc_path);
    if (Dart_IsError(result)) {
      Dart_PropagateError(result);
    }
    namespc = Namespace::Create(namespc_path);
  } else {
    // Propagate a type error.
    Dart_ThrowException(
        DartUtils::NewDartArgumentError("Argument must be an int or a String"));
  }

  // We were unable to create a native Namespace wrapper object due to some
  // OS-level error.
  if (namespc == NULL) {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }

  // Set the Dart objects native field to the native wrapper.
  result = Dart_SetNativeInstanceField(namespc_obj, kNamespaceNativeFieldIndex,
                                       reinterpret_cast<intptr_t>(namespc));
  if (Dart_IsError(result)) {
    namespc->Release();
    Dart_PropagateError(result);
  }

  // Set up a finalizer for the Dart object so that we can do any necessary
  // platform-specific cleanup for the namespc.
  Dart_NewWeakPersistentHandle(namespc_obj, reinterpret_cast<void*>(namespc),
                               sizeof(*namespc), ReleaseNamespace);
  Dart_SetReturnValue(args, namespc_obj);
}

void FUNCTION_NAME(Namespace_GetDefault)(Dart_NativeArguments args) {
  Dart_SetIntegerReturnValue(args, Namespace::Default());
}

void FUNCTION_NAME(Namespace_GetPointer)(Dart_NativeArguments args) {
  Namespace* namespc = Namespace::GetNamespace(args, 0);
  ASSERT(namespc != NULL);
  namespc->Retain();
  Dart_SetIntegerReturnValue(args, reinterpret_cast<intptr_t>(namespc));
}

Namespace* Namespace::GetNamespace(Dart_NativeArguments args, intptr_t index) {
  Namespace* namespc;
  Dart_Handle status =
      Namespace::GetNativeNamespaceArgument(args, index, &namespc);
  if (Dart_IsError(status)) {
    Dart_PropagateError(status);
  }
  return namespc;
}

bool Namespace::IsDefault(Namespace* namespc) {
  return (namespc == NULL) || (namespc->namespc() == NULL);
}

Dart_Handle Namespace::GetNativeNamespaceArgument(Dart_NativeArguments args,
                                                  intptr_t index,
                                                  Namespace** namespc) {
  Dart_Handle namespc_obj = Dart_GetNativeArgument(args, index);
  if (Dart_IsError(namespc_obj)) {
    Dart_PropagateError(namespc_obj);
  }
  DEBUG_ASSERT(IsNamespace(namespc_obj));

  Dart_Handle result =
      Dart_GetNativeInstanceField(namespc_obj, kNamespaceNativeFieldIndex,
                                  reinterpret_cast<intptr_t*>(namespc));
  if (Dart_IsError(result)) {
    return result;
  }
  return Dart_Null();
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED)
