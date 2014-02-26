// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/file_system_watcher.h"

#include <errno.h>  // NOLINT
#include <sys/inotify.h>  // NOLINT

#include "bin/fdutils.h"
#include "bin/socket.h"


namespace dart {
namespace bin {

bool FileSystemWatcher::IsSupported() {
  return true;
}


intptr_t FileSystemWatcher::Init() {
  int id = TEMP_FAILURE_RETRY(inotify_init1(IN_CLOEXEC));
  if (id < 0) return -1;
  // Some systems dosn't support setting this as non-blocking. Since watching
  // internals are kept away from the user, we know it's possible to continue,
  // even if setting non-blocking fails.
  FDUtils::SetNonBlocking(id);
  return id;
}


void FileSystemWatcher::Close(intptr_t id) {
  USE(id);
}


intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  int list_events = IN_DELETE_SELF | IN_MOVE_SELF;
  if (events & kCreate) list_events |= IN_CREATE;
  if (events & kModifyContent) list_events |= IN_CLOSE_WRITE | IN_ATTRIB;
  if (events & kDelete) list_events |= IN_DELETE;
  if (events & kMove) list_events |= IN_MOVE;
  int path_id = TEMP_FAILURE_RETRY(inotify_add_watch(id, path, list_events));
  if (path_id < 0) {
    return -1;
  }
  return path_id;
}


void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  VOID_TEMP_FAILURE_RETRY(inotify_rm_watch(id, path_id));
}


intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  USE(path_id);
  return id;
}


Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  USE(path_id);
  const intptr_t kEventSize = sizeof(struct inotify_event);
  const intptr_t kBufferSize = kEventSize + NAME_MAX + 1;
  uint8_t buffer[kBufferSize];
  intptr_t bytes = Socket::Read(id, buffer, kBufferSize);
  if (bytes < 0) {
    return DartUtils::NewDartOSError();
  }
  const intptr_t kMaxCount = bytes / kEventSize;
  Dart_Handle events = Dart_NewList(kMaxCount);
  intptr_t offset = 0;
  intptr_t i = 0;
  while (offset < bytes) {
    struct inotify_event* e =
        reinterpret_cast<struct inotify_event*>(buffer + offset);
    if ((e->mask & IN_IGNORED) == 0) {;
      Dart_Handle event = Dart_NewList(5);
      int mask = 0;
      if (e->mask & IN_CLOSE_WRITE) mask |= kModifyContent;
      if (e->mask & IN_ATTRIB) mask |= kModefyAttribute;
      if (e->mask & IN_CREATE) mask |= kCreate;
      if (e->mask & IN_MOVE) mask |= kMove;
      if (e->mask & IN_DELETE) mask |= kDelete;
      if (e->mask & (IN_DELETE_SELF | IN_MOVE_SELF)) mask |= kDeleteSelf;
      if (e->mask & IN_ISDIR) mask |= kIsDir;
      Dart_ListSetAt(event, 0, Dart_NewInteger(mask));
      Dart_ListSetAt(event, 1, Dart_NewInteger(e->cookie));
      if (e->len > 0) {
        Dart_ListSetAt(event, 2, Dart_NewStringFromUTF8(
            reinterpret_cast<uint8_t*>(e->name), strlen(e->name)));
      } else {
        Dart_ListSetAt(event, 2, Dart_Null());
      }
      Dart_ListSetAt(event, 3, Dart_NewBoolean(e->mask & IN_MOVED_TO));
      Dart_ListSetAt(event, 4, Dart_NewInteger(e->wd));
      Dart_ListSetAt(events, i, event);
      i++;
    }
    offset += kEventSize + e->len;
  }
  ASSERT(offset == bytes);
  return events;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)

