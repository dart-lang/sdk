// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_FILE_SYSTEM_WATCHER_H_
#define RUNTIME_BIN_FILE_SYSTEM_WATCHER_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/namespace.h"

namespace dart {
namespace bin {

class FileSystemWatcher {
 public:
  enum EventType {
    kCreate = 1 << 0,
    kModifyContent = 1 << 1,
    kDelete = 1 << 2,
    kMove = 1 << 3,
    kModifyAttribute = 1 << 4,
    kDeleteSelf = 1 << 5,
    kIsDir = 1 << 6,
    kMovedTo = 1 << 7,
  };

  // ReadEvents returns array of arrays encoding individual events.
  // Each event has the following elements.
  //
  // Keep in sync with _EventConverter in file_patch.dart.
  enum {
    kEventFlagsIndex = 0,   // See EventType
    kEventCookieIndex = 1,  // Integer used to link move from and move to events
    kEventPathIndex = 2,    // String path
    kEventPathIdIndex = 3,  // Integer pathId
    kEventNumElements = 4,
  };

  static void InitOnce();
  static void Cleanup();

  static bool IsSupported();
  static intptr_t Init();
  static void Close(intptr_t id);
  static intptr_t WatchPath(intptr_t id,
                            Namespace* namespc,
                            const char* path,
                            int events,
                            bool recursive);
  static void UnwatchPath(intptr_t id, intptr_t path_id);
  static intptr_t GetSocketId(intptr_t id, intptr_t path_id);
  static Dart_Handle ReadEvents(intptr_t id, intptr_t path_id);

#if defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_WINDOWS)
  static void DestroyWatch(intptr_t path_id);
#endif

  static void set_delayed_filewatch_callback(bool value) {
    delayed_filewatch_callback_ = value;
  }
  static bool delayed_filewatch_callback() {
    return delayed_filewatch_callback_;
  }

 private:
  static bool delayed_filewatch_callback_;
  DISALLOW_COPY_AND_ASSIGN(FileSystemWatcher);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_FILE_SYSTEM_WATCHER_H_
