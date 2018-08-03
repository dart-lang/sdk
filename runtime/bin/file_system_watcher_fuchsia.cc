// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/file_system_watcher.h"

namespace dart {
namespace bin {

Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
  return DartUtils::NewDartOSError();
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
  return -1;
}

bool FileSystemWatcher::IsSupported() {
  return false;
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
}

intptr_t FileSystemWatcher::Init() {
  return 0;
}

void FileSystemWatcher::Close(intptr_t id) {
  UNIMPLEMENTED();
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  UNIMPLEMENTED();
  return -1;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
