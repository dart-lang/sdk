// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_OPENBSD)

#include "bin/file_system_watcher.h"

#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool FileSystemWatcher::IsSupported() {
  /* There is no inotify API on OpenBSD*/
  return false;
}


intptr_t FileSystemWatcher::Init() {
  UNIMPLEMENTED();
  return 0;
}


void FileSystemWatcher::Close(intptr_t id) {
  UNIMPLEMENTED();
}


intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  UNIMPLEMENTED();
  return 0;
}


void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
}


intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
  return id;
}


Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  UNIMPLEMENTED();
  Dart_Handle events = Dart_NewList(0);
  return events;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_OPENBSD)
