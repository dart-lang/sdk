// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <dirent.h>
#include <libgen.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/directory.h"
#include "bin/file.h"


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


static void ComputeFullPath(const char* dir_name,
                            char* path,
                            int* path_length) {
  size_t written = 0;

  if (!File::IsAbsolutePath(dir_name)) {
    ASSERT(getcwd(path, PATH_MAX) != NULL);
    *path_length = strlen(path);
    written = snprintf(path + *path_length,
                       PATH_MAX - *path_length,
                       "%s",
                       File::PathSeparator());
    ASSERT(written == strlen(File::PathSeparator()));
    *path_length += written;
  }

  // Use dirname and basename to canonicalize the provided directory
  // name.
  char* dir_name_copy = strdup(dir_name);
  char* dir = dirname(dir_name_copy);
  if (strcmp(dir, ".") != 0) {
    written = snprintf(path + *path_length,
                       PATH_MAX - *path_length,
                       "%s%s",
                       dir,
                       File::PathSeparator());
    ASSERT(written == (strlen(dir) + strlen(File::PathSeparator())));
    *path_length += written;
  }
  char* base = basename(dir_name_copy);
  if (strcmp(base, ".") != 0) {
    written = snprintf(path + *path_length,
                       PATH_MAX - *path_length,
                       "%s%s",
                       base,
                       File::PathSeparator());
    ASSERT(written == (strlen(base) + strlen(File::PathSeparator())));
    *path_length += written;
  }
  free(dir_name_copy);
}


static void HandleDir(char* dir_name,
                      char* path,
                      int path_length,
                      Dart_Port dir_handler) {
  if (dir_handler != 0 &&
      strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              PATH_MAX - path_length,
                              "%s",
                              dir_name);
    ASSERT(written == strlen(dir_name));
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(dir_handler, name);
  }
}


static void HandleFile(char* file_name,
                       char* path,
                       int path_length,
                       Dart_Port file_handler) {
  if (file_handler != 0) {
    size_t written = snprintf(path + path_length,
                              PATH_MAX - path_length,
                              "%s",
                              file_name);
    ASSERT(written == strlen(file_name));
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(file_handler, name);
  }
}


void Directory::List(const char* dir_name,
                     intptr_t dir_handle,
                     bool recursive,
                     Dart_Port dir_handler,
                     Dart_Port file_handler,
                     Dart_Port done_handler,
                     Dart_Port dir_error_handler) {
  // Compute full path for the directory currently being listed.
  char path[PATH_MAX];
  int path_length = 0;
  ComputeFullPath(dir_name, path, &path_length);

  // Iterated the directory and post the directories and files to the
  // handlers.
  //
  // TODO(ager): Handle recursion and errors caused by recursion.
  DIR* dir_pointer = reinterpret_cast<DIR*>(dir_handle);
  int success = 0;
  bool lstat_error = false;
  dirent entry;
  dirent* result;
  while ((success = readdir_r(dir_pointer, &entry, &result)) == 0 &&
         result != NULL) {
    switch (entry.d_type) {
      case DT_DIR:
        HandleDir(entry.d_name, path, path_length, dir_handler);
        break;
      case DT_REG:
        HandleFile(entry.d_name, path, path_length, file_handler);
        break;
      case DT_UNKNOWN: {
        // On some file systems the entry type is not determined by
        // readdir_r. For those we use lstat to determine the entry
        // type.
        struct stat entry_info;
        size_t written = snprintf(path + path_length,
                                  PATH_MAX - path_length,
                                  "%s",
                                  entry.d_name);
        ASSERT(written == strlen(entry.d_name));
        int lstat_success = lstat(path, &entry_info);
        if (lstat_success != 0) {
          lstat_error = true;
          break;
        }
        if ((entry_info.st_mode & S_IFMT) == S_IFDIR) {
          HandleDir(entry.d_name, path, path_length, dir_handler);
        } else if ((entry_info.st_mode & S_IFMT) == S_IFREG) {
          HandleFile(entry.d_name, path, path_length, file_handler);
        }
        break;
      }
      default:
        break;
    }
  }
  if (done_handler != 0) {
    if (success != 0 || lstat_error) {
      Dart_Handle value = Dart_NewBoolean(false);
      Dart_Post(done_handler, value);
    } else {
      Dart_Handle value = Dart_NewBoolean(true);
      Dart_Post(done_handler, value);
    }
  }
}
