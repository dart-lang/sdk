// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/file_system_watcher.h"

#include <WinIoCtl.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/log.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

bool FileSystemWatcher::IsSupported() {
  return true;
}

intptr_t FileSystemWatcher::Init() {
  return 0;
}

void FileSystemWatcher::Close(intptr_t id) {
  USE(id);
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  USE(id);
  Utf8ToWideScope name(path);
  HANDLE dir = CreateFileW(
      name.wide(), FILE_LIST_DIRECTORY,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, NULL);

  if (dir == INVALID_HANDLE_VALUE) {
    return -1;
  }

  int list_events = 0;
  if ((events & (kCreate | kMove | kDelete)) != 0) {
    list_events |= FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME;
  }
  if ((events & kModifyContent) != 0) {
    list_events |= FILE_NOTIFY_CHANGE_LAST_WRITE;
  }

  DirectoryWatchHandle* handle =
      new DirectoryWatchHandle(dir, list_events, recursive);
  // Issue a read directly, to be sure events are tracked from now on. This is
  // okay, since in Dart, we create the socket and start reading immidiately.
  handle->EnsureInitialized(EventHandler::delegate());
  handle->IssueRead();
  return reinterpret_cast<intptr_t>(handle);
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  USE(id);
  DirectoryWatchHandle* handle =
      reinterpret_cast<DirectoryWatchHandle*>(path_id);
  handle->Stop();
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  USE(id);
  return path_id;
}

Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  USE(id);
  const intptr_t kEventSize = sizeof(FILE_NOTIFY_INFORMATION);
  DirectoryWatchHandle* dir = reinterpret_cast<DirectoryWatchHandle*>(path_id);
  intptr_t available = dir->Available();
  intptr_t max_count = available / kEventSize + 1;
  Dart_Handle events = Dart_NewList(max_count);
  uint8_t* buffer = Dart_ScopeAllocate(available);
  intptr_t bytes = dir->Read(buffer, available);
  intptr_t offset = 0;
  intptr_t i = 0;
  while (offset < bytes) {
    FILE_NOTIFY_INFORMATION* e =
        reinterpret_cast<FILE_NOTIFY_INFORMATION*>(buffer + offset);

    Dart_Handle event = Dart_NewList(5);
    int mask = 0;
    if (e->Action == FILE_ACTION_ADDED) {
      mask |= kCreate;
    }
    if (e->Action == FILE_ACTION_REMOVED) {
      mask |= kDelete;
    }
    if (e->Action == FILE_ACTION_MODIFIED) {
      mask |= kModifyContent;
    }
    if (e->Action == FILE_ACTION_RENAMED_OLD_NAME) {
      mask |= kMove;
    }
    if (e->Action == FILE_ACTION_RENAMED_NEW_NAME) {
      mask |= kMove;
    }
    Dart_ListSetAt(event, 0, Dart_NewInteger(mask));
    // Move events come in pairs. Just 'enable' by default.
    Dart_ListSetAt(event, 1, Dart_NewInteger(1));
    Dart_ListSetAt(
        event, 2,
        Dart_NewStringFromUTF16(reinterpret_cast<uint16_t*>(e->FileName),
                                e->FileNameLength / 2));
    Dart_ListSetAt(event, 3, Dart_NewBoolean(true));
    Dart_ListSetAt(event, 4, Dart_NewInteger(path_id));
    Dart_ListSetAt(events, i, event);
    i++;
    if (e->NextEntryOffset == 0) {
      break;
    }
    offset += e->NextEntryOffset;
  }
  return events;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
