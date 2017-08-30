// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file_system_watcher.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/utils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

void FUNCTION_NAME(FileSystemWatcher_IsSupported)(Dart_NativeArguments args) {
  Dart_SetBooleanReturnValue(args, FileSystemWatcher::IsSupported());
}

void FUNCTION_NAME(FileSystemWatcher_InitWatcher)(Dart_NativeArguments args) {
  intptr_t id = FileSystemWatcher::Init();
  if (id >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(id));
  } else {
    OSError os_error;
    Dart_ThrowException(DartUtils::NewDartOSError(&os_error));
  }
}

void FUNCTION_NAME(FileSystemWatcher_CloseWatcher)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  FileSystemWatcher::Close(id);
}

void FUNCTION_NAME(FileSystemWatcher_WatchPath)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  Namespace* namespc = Namespace::GetNamespace(args, 1);
  const char* path = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 2));
  int events = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 3));
  bool recursive = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  intptr_t path_id =
      FileSystemWatcher::WatchPath(id, namespc, path, events, recursive);
  if (path_id == -1) {
    Dart_ThrowException(DartUtils::NewDartOSError());
  }
  Dart_SetIntegerReturnValue(args, path_id);
}

void FUNCTION_NAME(FileSystemWatcher_UnwatchPath)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  intptr_t path_id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  FileSystemWatcher::UnwatchPath(id, path_id);
}

void FUNCTION_NAME(FileSystemWatcher_ReadEvents)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  intptr_t path_id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  Dart_Handle handle = FileSystemWatcher::ReadEvents(id, path_id);
  ThrowIfError(handle);
  Dart_SetReturnValue(args, handle);
}

void FUNCTION_NAME(FileSystemWatcher_GetSocketId)(Dart_NativeArguments args) {
  intptr_t id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 0));
  intptr_t path_id = DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  int socket_id = FileSystemWatcher::GetSocketId(id, path_id);
  Dart_SetIntegerReturnValue(args, socket_id);
}

}  // namespace bin
}  // namespace dart
