// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include <errno.h>
#include <sys/stat.h>

#include "bin/platform.h"

// Forward declaration.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            Dart_Port dir_port,
                            Dart_Port file_port,
                            Dart_Port done_port,
                            Dart_Port error_port);


static bool HandleDir(char* dir_name,
                      char* path,
                      int path_length,
                      bool recursive,
                      Dart_Port dir_port,
                      Dart_Port file_port,
                      Dart_Port done_port,
                      Dart_Port error_port) {
  if (strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              dir_name);
    ASSERT(written == strlen(dir_name));
    if (dir_port != 0) {
      Dart_Handle name = Dart_NewString(path);
      Dart_Post(dir_port, name);
    }
    if (recursive) {
      return ListRecursively(path,
                             recursive,
                             dir_port,
                             file_port,
                             done_port,
                             error_port);
    }
  }
  return true;
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


static bool HandleEntry(LPWIN32_FIND_DATA find_file_data,
                        char* path,
                        int path_length,
                        bool recursive,
                        Dart_Port dir_port,
                        Dart_Port file_port,
                        Dart_Port done_port,
                        Dart_Port error_port) {
  DWORD attributes = find_file_data->dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return HandleDir(find_file_data->cFileName,
                     path,
                     path_length,
                     recursive,
                     dir_port,
                     file_port,
                     done_port,
                     error_port);
  } else {
    HandleFile(find_file_data->cFileName, path, path_length, file_port);
    return true;
  }
}


static void ComputeFullSearchPath(const char* dir_name,
                                  char* path,
                                  int* path_length) {
  // GetFullPathName only works in a multi-threaded environment if
  // SetCurrentDirectory is not used. We currently have no plan for
  // exposing SetCurrentDirectory.
  size_t written =
    GetFullPathName(dir_name, MAX_PATH - *path_length, path, NULL);
  *path_length += written;
  written = snprintf(path + *path_length,
                     MAX_PATH - *path_length,
                     "%s",
                     "\\*");
  ASSERT(written == 2);
  *path_length += written;
}

static void PostError(Dart_Port error_port,
                      const char* prefix,
                      const char* suffix) {
  if (error_port != 0) {
    char* error_str = Platform::StrError(GetLastError());
    int error_message_size =
        strlen(prefix) + strlen(suffix) + strlen(error_str) + 3;
    char* message = static_cast<char*>(malloc(error_message_size + 1));
    size_t written = snprintf(message,
                       error_message_size + 1,
                       "%s%s (%s)",
                       prefix,
                       suffix,
                       error_str);
    ASSERT(written == error_message_size);
    free(error_str);
    Dart_Post(error_port, Dart_NewString(message));
    free(message);
  }
}


static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            Dart_Port dir_port,
                            Dart_Port file_port,
                            Dart_Port done_port,
                            Dart_Port error_port) {
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length = 0;
  ComputeFullSearchPath(dir_name, path, &path_length);

  WIN32_FIND_DATA find_file_data;
  HANDLE find_handle = FindFirstFile(path, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  path_length -= 1;
  path[path_length] = '\0';

  if (find_handle == INVALID_HANDLE_VALUE) {
    PostError(error_port, "Directory listing failed for: ", path);
    free(path);
    return false;
  }

  bool listing_error = !HandleEntry(&find_file_data,
                                    path,
                                    path_length,
                                    recursive,
                                    dir_port,
                                    file_port,
                                    done_port,
                                    error_port);

  while ((FindNextFile(find_handle, &find_file_data) != 0) && !listing_error) {
    listing_error = listing_error || !HandleEntry(&find_file_data,
                                                  path,
                                                  path_length,
                                                  recursive,
                                                  dir_port,
                                                  file_port,
                                                  done_port,
                                                  error_port);
  }

  if (GetLastError() != ERROR_NO_MORE_FILES) {
    listing_error = true;
    PostError(error_port, "Directory listing failed", "");
  }

  if (FindClose(find_handle) == 0) {
    PostError(error_port, "Failed to close directory", "");
  }
  free(path);

  return !listing_error;
}


void Directory::List(const char* dir_name,
                     bool recursive,
                     Dart_Port dir_port,
                     Dart_Port file_port,
                     Dart_Port done_port,
                     Dart_Port error_port) {
  bool result = ListRecursively(dir_name,
                                recursive,
                                dir_port,
                                file_port,
                                done_port,
                                error_port);
  if (done_port != 0) {
    Dart_Handle value = Dart_NewBoolean(result);
    Dart_Post(done_port, value);
  }
}


Directory::ExistsResult Directory::Exists(const char* dir_name) {
  struct stat entry_info;
  int stat_success = stat(dir_name, &entry_info);
  if (stat_success == 0) {
    if ((entry_info.st_mode & S_IFMT) == S_IFDIR) {
      return EXISTS;
    } else {
      return DOES_NOT_EXIST;
    }
  } else {
    if (errno == EACCES ||
        errno == EBADF ||
        errno == EFAULT ||
        errno == ENOMEM) {
      // Search permissions denied for one of the directories in the
      // path or a low level error occured. We do not know if the
      // directory exists.
      return UNKNOWN;
    }
    ASSERT(errno == ENAMETOOLONG ||
           errno == ENOENT ||
           errno == ENOTDIR);
    return DOES_NOT_EXIST;
  }
}


bool Directory::Create(const char* dir_name) {
  return (CreateDirectory(dir_name, NULL) != 0);
}


char* Directory::CreateTemp(const char* const_template, int64_t number) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value must be freed by the caller.
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length;
  if (0 == strncmp(const_template, "", 1)) {
    path_length = GetTempPath(MAX_PATH, path);
  } else {
    snprintf(path, MAX_PATH, "%s", const_template);
    path_length = strlen(path);
  }
  if (path_length > MAX_PATH - 14) {
    path[0] = '\0';
    return path;
  }
  if (path[path_length - 1] == '\\') {
    // No base name for the directory - use "tempdir"
    snprintf(path + path_length, MAX_PATH - path_length, "tempdir");
    path_length = strlen(path);
  }

  int tries = 0;
  int numeric_part = number % 1000000;
  while (true) {
    snprintf(path + path_length, MAX_PATH - path_length, "%.6d", numeric_part);
    if (CreateDirectory(path, NULL)) break;
    numeric_part++;
    tries++;
    if (tries > 100) {
      path[0] = '\0';
      break;
    }
  }
  return path;
}


bool Directory::Delete(const char* dir_name) {
  return (RemoveDirectory(dir_name) != 0);
}
