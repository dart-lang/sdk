// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/path.h"

#include <stdio.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/log.h"
#include "include/dart_api.h"
#include "include/dart_tools_api.h"
#include "platform/globals.h"

namespace dart {
namespace bin {

static const int kPathNativeFieldIndex = 0;

#if defined(DEBUG)
static bool IsPath(Dart_Handle path_obj) {
  Dart_Handle path_type = DartUtils::GetDartType("dart:io", "_PathImpl");
  ASSERT(!Dart_IsError(path_type));
  bool isinstance = false;
  Dart_Handle result = Dart_ObjectIsType(path_obj, path_type, &isinstance);
  ASSERT(!Dart_IsError(result));
  return isinstance;
}
#endif

Path* Path::GetPath(Dart_Handle path_obj) {
  DEBUG_ASSERT(IsPath(path_obj));
  Path* path = NULL;
  Dart_Handle result = Dart_GetNativeInstanceField(
      path_obj, kPathNativeFieldIndex, reinterpret_cast<intptr_t*>(&path));
  if (Dart_IsError(result)) {
    Log::PrintErr("GetNativeInstanceField in Path::GetPath failed\n");
    Dart_PropagateError(result);
  }
  return path;
}

static void ReleasePath(void* isolate_callback_data,
                        Dart_WeakPersistentHandle handle,
                        void* peer) {
  Path* path = reinterpret_cast<Path*>(peer);
  delete path;
}

void FUNCTION_NAME(Path_SetRawPath)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  Dart_Handle raw_path_list = Dart_GetNativeArgument(args, 1);

  const char* raw_path = DartUtils::GetRawStringValue(raw_path_list);

  Path* path = new Path(raw_path, strlen(raw_path) + 1);
  Dart_NewWeakPersistentHandle(dart_this, reinterpret_cast<void*>(path),
                               sizeof(*path), ReleasePath);

  Dart_Handle result = Dart_SetNativeInstanceField(
      dart_this, kPathNativeFieldIndex, reinterpret_cast<intptr_t>(path));
  if (Dart_IsError(result)) {
    Log::PrintErr("SetNativeInstanceField in SetRawPath() failed\n");
    Dart_PropagateError(result);
  }
}

void FUNCTION_NAME(Path_GetRawPath)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));

  Path* path = Path::GetPath(dart_this);
  ASSERT(path != NULL);

  Dart_Handle list = Dart_NewExternalTypedData(
      Dart_TypedData_kUint8, const_cast<char*>(path->raw_path()),
      path->length());
  ASSERT(!Dart_IsError(list));
  Dart_SetReturnValue(args, list);
}

}  // namespace bin
}  // namespace dart
