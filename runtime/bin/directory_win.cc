// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

static void HandleDir(char* dir_name,
                      char* path,
                      int path_length,
                      Dart_Port dir_port) {
  if (dir_port != 0 &&
      strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              dir_name);
    ASSERT(written == strlen(dir_name));
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(dir_port, name);
  }
}


static void HandleFile(char* file_name,
                       char* path,
                       int path_length,
                       Dart_Port file_port) {
  if (file_port != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              file_name);
    ASSERT(written == strlen(file_name));
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(file_port, name);
  }
}


static void HandleEntry(LPWIN32_FIND_DATA find_file_data,
                        char* path,
                        int path_length,
                        Dart_Port file_port,
                        Dart_Port dir_port) {
  DWORD attributes = find_file_data->dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    HandleDir(find_file_data->cFileName, path, path_length, dir_port);
  } else {
    HandleFile(find_file_data->cFileName, path, path_length, file_port);
  }
}


static void ComputeFullSearchPath(const char* dir_name,
                                  char* path,
                                  int* path_length) {
  // GetFullPathName only works in a multi-threaded environment if
  // SetCurrentDirectory is not used. We currently have no plan for
  // exposing SetCurrentDirectory.
  int written =
    GetFullPathName(dir_name, MAX_PATH - *path_length, path, NULL);
  *path_length += written;
  written = snprintf(path + *path_length,
                     MAX_PATH - *path_length,
                     "%s",
                     "\\*");
  ASSERT(written == 2);
  *path_length += written;
}


void Directory::List(const char* dir_name,
                     bool recursive,
                     Dart_Port dir_port,
                     Dart_Port file_port,
                     Dart_Port done_port,
                     Dart_Port error_port) {
  // TODO(ager): Handle recursive listing.
  char path[MAX_PATH];
  int path_length = 0;
  ComputeFullSearchPath(dir_name, path, &path_length);

  WIN32_FIND_DATA find_file_data;
  HANDLE find_handle = FindFirstFile(path, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  path_length -= 1;
  path[path_length] = '\0';

  if (find_handle == INVALID_HANDLE_VALUE) {
    // TODO(ager): Post on error port.
    Dart_Handle value = Dart_NewBoolean(false);
    Dart_Post(done_port, value);
    return;
  }

  HandleEntry(&find_file_data, path, path_length, file_port, dir_port);
  while (FindNextFile(find_handle, &find_file_data) != 0) {
    HandleEntry(&find_file_data, path, path_length, file_port, dir_port);
  }

  bool result = GetLastError() == ERROR_NO_MORE_FILES;
  Dart_Handle value = Dart_NewBoolean(result);
  Dart_Post(done_port, value);

  // TODO(ager): Post on error port.
  FindClose(find_handle);
}
