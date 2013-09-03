// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/file_system_watcher.h"

#include <errno.h>  // NOLINT
#include <sys/inotify.h>  // NOLINT


namespace dart {
namespace bin {

bool FileSystemWatcher::IsSupported() {
  return true;
}


intptr_t FileSystemWatcher::WatchPath(const char* path,
                                      int events,
                                      bool recursive) {
  int fd = TEMP_FAILURE_RETRY(inotify_init1(IN_NONBLOCK | IN_CLOEXEC));
  if (fd < 0) return -1;
  int list_events = 0;
  if (events & kCreate) list_events |= IN_CREATE;
  if (events & kModifyContent) list_events |= IN_MODIFY | IN_ATTRIB;
  if (events & kDelete) list_events |= IN_DELETE;
  if (events & kMove) list_events |= IN_MOVE;
  int path_fd = TEMP_FAILURE_RETRY(inotify_add_watch(fd, path, list_events));
  if (path_fd < 0) {
    close(fd);
    return -1;
  }
  return fd;
}


void FileSystemWatcher::UnwatchPath(intptr_t id) {
  // Nothing to do.
}


intptr_t FileSystemWatcher::GetSocketId(intptr_t id) {
  return id;
}


Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id) {
  const intptr_t kEventSize = sizeof(struct inotify_event);
  const intptr_t kBufferSize = kEventSize + NAME_MAX + 1;
  uint8_t buffer[kBufferSize];
  intptr_t bytes = TEMP_FAILURE_RETRY(read(id, buffer, kBufferSize));
  if (bytes < 0) {
    return DartUtils::NewDartOSError();
  }
  const intptr_t kMaxCount = kBufferSize / kEventSize + 1;
  Dart_Handle events = Dart_NewList(kMaxCount);
  intptr_t offset = 0;
  intptr_t i = 0;
  while (offset < bytes) {
    struct inotify_event* e =
        reinterpret_cast<struct inotify_event*>(buffer + offset);
    Dart_Handle event = Dart_NewList(3);
    int mask = 0;
    if (e->mask & IN_MODIFY) mask |= kModifyContent;
    if (e->mask & IN_ATTRIB) mask |= kModefyAttribute;
    if (e->mask & IN_CREATE) mask |= kCreate;
    if (e->mask & IN_MOVE) mask |= kMove;
    if (e->mask & IN_DELETE) mask |= kDelete;
    Dart_ListSetAt(event, 0, Dart_NewInteger(mask));
    Dart_ListSetAt(event, 1, Dart_NewInteger(e->cookie));
    if (e->len > 0) {
      Dart_ListSetAt(event, 2, Dart_NewStringFromUTF8(
          reinterpret_cast<uint8_t*>(e->name), strlen(e->name)));
    } else {
      Dart_ListSetAt(event, 2, Dart_Null());
    }
    Dart_ListSetAt(events, i, event);
    i++;
    offset += kEventSize + e->len;
  }
  ASSERT(offset == bytes);
  return events;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)

