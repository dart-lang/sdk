// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file_system_watcher.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"

#include "include/dart_api.h"

namespace dart {
namespace bin {

static const int kWatcherNativeField = 0;


void SetWatcherIdNativeField(Dart_Handle watcher, intptr_t id) {
  ThrowIfError(Dart_SetNativeInstanceField(watcher, kWatcherNativeField, id));
}


void GetWatcherIdNativeField(Dart_Handle watcher, intptr_t* id) {
  ThrowIfError(Dart_GetNativeInstanceField(watcher, kWatcherNativeField, id));
}

void FUNCTION_NAME(FileSystemWatcher_IsSupported)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewBoolean(FileSystemWatcher::IsSupported()));
}

void FUNCTION_NAME(FileSystemWatcher_WatchPath)(Dart_NativeArguments args) {
  Dart_Handle watcher = Dart_GetNativeArgument(args, 0);
  const char* path = DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  int events = DartUtils::GetIntegerValue(Dart_GetNativeArgument(args, 2));
  bool recursive = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  intptr_t id = FileSystemWatcher::WatchPath(path, events, recursive);
  if (id == -1) {
    Dart_PropagateError(DartUtils::NewDartOSError());
  } else {
    SetWatcherIdNativeField(watcher, id);
  }
  intptr_t socket_id = FileSystemWatcher::GetSocketId(id);
  Dart_SetReturnValue(args, Dart_NewInteger(socket_id));
}


void FUNCTION_NAME(FileSystemWatcher_UnwatchPath)(Dart_NativeArguments args) {
  Dart_Handle watcher = Dart_GetNativeArgument(args, 0);
  intptr_t id;
  GetWatcherIdNativeField(watcher, &id);
  FileSystemWatcher::UnwatchPath(id);
}


void FUNCTION_NAME(FileSystemWatcher_ReadEvents)(Dart_NativeArguments args) {
  Dart_Handle watcher = Dart_GetNativeArgument(args, 0);
  intptr_t id;
  GetWatcherIdNativeField(watcher, &id);
  Dart_Handle handle = FileSystemWatcher::ReadEvents(id);
  ThrowIfError(handle);
  Dart_SetReturnValue(args, handle);
}

}  // namespace bin
}  // namespace dart
