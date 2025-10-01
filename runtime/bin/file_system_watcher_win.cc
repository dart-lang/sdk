// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/file_system_watcher.h"

#include <winioctl.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/eventhandler.h"
#include "bin/utils.h"
#include "bin/utils_win.h"
#include "platform/syslog.h"

namespace dart {
namespace bin {

void FileSystemWatcher::InitOnce() {}

void FileSystemWatcher::Cleanup() {}

bool FileSystemWatcher::IsSupported() {
  return true;
}

intptr_t FileSystemWatcher::Init() {
  return 0;
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  USE(id);
  const auto name = Utf8ToWideChar(path);
  HANDLE dir =
      CreateFileW(name.get(), FILE_LIST_DIRECTORY,
                  FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                  nullptr, OPEN_EXISTING,
                  FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, nullptr);

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
  handle->Start();
  handle->Retain();
  return reinterpret_cast<intptr_t>(handle);
}

void FileSystemWatcher::DestroyWatch(intptr_t path_id) {
  FileSystemWatcher::UnwatchPath(0, path_id);
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  USE(id);
  DirectoryWatchHandle* handle =
      reinterpret_cast<DirectoryWatchHandle*>(path_id);
  handle->Stop();
  handle->Release();
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
  if (available <= 0) {
    return Dart_NewList(0);
  }
  intptr_t max_count = available / kEventSize + 1;
  Dart_Handle events = Dart_NewList(max_count);
  uint8_t* buffer = Dart_ScopeAllocate(available);
  intptr_t bytes = dir->Read(buffer, available);
  intptr_t offset = 0;
  intptr_t i = 0;
  while (offset < bytes) {
    FILE_NOTIFY_INFORMATION* e =
        reinterpret_cast<FILE_NOTIFY_INFORMATION*>(buffer + offset);

    Dart_Handle event = Dart_NewList(kEventNumElements);
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
      mask |= kMove | kMovedTo;
    }
    Dart_ListSetAt(event, kEventFlagsIndex, Dart_NewInteger(mask));
    // Move events come in pairs. Just 'enable' by default.
    Dart_ListSetAt(event, kEventCookieIndex, Dart_NewInteger(1));
    Dart_ListSetAt(
        event, kEventPathIndex,
        Dart_NewStringFromUTF16(reinterpret_cast<uint16_t*>(e->FileName),
                                e->FileNameLength / 2));
    Dart_ListSetAt(event, kEventPathIdIndex, Dart_NewInteger(path_id));
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

#endif  // defined(DART_HOST_OS_WINDOWS)
