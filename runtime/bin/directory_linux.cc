// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <string.h>
#include <sys/types.h>
#include <dirent.h>

#include "bin/directory.h"

bool Directory::Open(const char* path, intptr_t* dir) {
  DIR* dir_pointer = opendir(path);
  if (dir_pointer == NULL) {
    return false;
  }
  *dir = reinterpret_cast<intptr_t>(dir_pointer);
  return true;
}

bool Directory::Close(intptr_t dir) {
  DIR* dir_pointer = reinterpret_cast<DIR*>(dir);
  int result = closedir(dir_pointer);
  return result == 0;
}

void Directory::List(intptr_t dir,
                     bool recursive,
                     Dart_Port dir_handler,
                     Dart_Port file_handler,
                     Dart_Port done_handler,
                     Dart_Port dir_error_handler) {
  // TODO(ager): Handle recursion and errors caused by recursion.
  // TODO(ager): Make this async by using a thread to do this.
  DIR* dir_pointer = reinterpret_cast<DIR*>(dir);
  int success = 0;
  dirent entry;
  dirent* result;
  while ((success = readdir_r(dir_pointer, &entry, &result)) == 0 &&
         result != NULL) {
    switch (entry.d_type) {
      case DT_DIR:
        if (dir_handler != 0 &&
            strcmp(entry.d_name, ".") != 0 &&
            strcmp(entry.d_name, "..") != 0) {
          Dart_Handle name = Dart_NewString(entry.d_name);
          Dart_Post(dir_handler, name);
        }
        break;
      case DT_REG:
        if (file_handler != 0) {
          Dart_Handle name = Dart_NewString(entry.d_name);
          Dart_Post(file_handler, name);
        }
        break;
      case DT_UNKNOWN:
        UNIMPLEMENTED();
        // TODO(ager): Handle this correctly. Use lstat or something?
        break;
      default:
        // TODO(ager): Handle symbolic links?
        break;
    }
  }
  if (success != 0) {
    // TODO(ager): Error listing directory. There should probably be
    // a general error handler. Maybe collaps the dir_error_handler
    // to just be a general error handler.
  } else if (done_handler != 0) {
    Dart_Handle value = Dart_NewBoolean(true);
    Dart_Post(done_handler, value);
  }
}
