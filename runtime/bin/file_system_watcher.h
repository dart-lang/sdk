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

namespace dart {
namespace bin {

class FileSystemWatcher {
 public:
  enum EventType {
    kCreate = 1 << 0,
    kModifyContent = 1 << 1,
    kDelete = 1 << 2,
    kMove = 1 << 3,
    kModefyAttribute = 1 << 4,
    kDeleteSelf = 1 << 5,
    kIsDir = 1 << 6
  };

  struct Event {
    intptr_t path_id;
    int event;
    const char* filename;
    int link;
  };

  static bool IsSupported();
  static intptr_t Init();
  static void Close(intptr_t id);
  static intptr_t WatchPath(intptr_t id,
                            const char* path,
                            int events,
                            bool recursive);
  static void UnwatchPath(intptr_t id, intptr_t path_id);
  static intptr_t GetSocketId(intptr_t id, intptr_t path_id);
  static Dart_Handle ReadEvents(intptr_t id, intptr_t path_id);

 private:
  DISALLOW_COPY_AND_ASSIGN(FileSystemWatcher);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_FILE_SYSTEM_WATCHER_H_
