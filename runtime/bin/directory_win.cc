// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include <errno.h>
#include <sys/stat.h>

#include "bin/platform.h"


static int SetOsErrorMessage(char* os_error_message,
                             int os_error_message_len) {
  int error_code = GetLastError();
  DWORD message_size =
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    error_code,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    os_error_message,
                    os_error_message_len,
                    NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      fprintf(stderr, "FormatMessage failed %d\n", GetLastError());
    }
    snprintf(os_error_message, os_error_message_len, "OS Error %d", error_code);
  }
  os_error_message[os_error_message_len - 1] = '\0';
  return error_code;
}


// Forward declaration.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            Dart_Port dir_port,
                            Dart_Port file_port,
                            Dart_Port done_port,
                            Dart_Port error_port);
static bool DeleteRecursively(const char* dir_name);


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
    if (written != strlen(dir_name)) {
      return false;
    }
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


static bool HandleFile(char* file_name,
                       char* path,
                       int path_length,
                       Dart_Port file_port) {
  if (file_port != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              file_name);
    if (written != strlen(file_name)) {
      return false;
    };
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(file_port, name);
  }
  return true;
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
    return HandleFile(find_file_data->cFileName, path, path_length, file_port);
  }
}


// ComputeFullSearchPath must be called with a path array of size at
// least MAX_PATH.
static bool ComputeFullSearchPath(const char* dir_name,
                                  char* path,
                                  int* path_length) {
  // GetFullPathName only works in a multi-threaded environment if
  // SetCurrentDirectory is not used. We currently have no plan for
  // exposing SetCurrentDirectory.
  size_t written = GetFullPathName(dir_name, MAX_PATH, path, NULL);
  // GetFullPathName only accepts input strings of size less than
  // MAX_PATH and returns 0 to indicate failure for paths longer than
  // that. Therefore the path buffer is always big enough.
  if (written == 0) {
    return false;
  }
  *path_length = written;
  written = snprintf(path + *path_length,
                     MAX_PATH - *path_length,
                     "%s",
                     "\\*");
  if (written != 2) {
    return false;
  }
  *path_length += written;
  return true;
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
  // Compute full path for the directory currently being listed.  The
  // path buffer will be used to construct the current path in the
  // recursive traversal. path_length does not always equal
  // strlen(path) but indicates the current prefix of path that is the
  // path of the current directory in the traversal.
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length = 0;
  bool valid = ComputeFullSearchPath(dir_name, path, &path_length);
  if (!valid) {
    PostError(error_port, "Directory listing failed for: ", dir_name);
    free(path);
    return false;
  }

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

  bool success = HandleEntry(&find_file_data,
                             path,
                             path_length,
                             recursive,
                             dir_port,
                             file_port,
                             done_port,
                             error_port);

  while ((FindNextFile(find_handle, &find_file_data) != 0) && success) {
    success = success && HandleEntry(&find_file_data,
                                     path,
                                     path_length,
                                     recursive,
                                     dir_port,
                                     file_port,
                                     done_port,
                                     error_port);
  }

  if (GetLastError() != ERROR_NO_MORE_FILES) {
    success = false;
    PostError(error_port, "Directory listing failed", "");
  }

  if (FindClose(find_handle) == 0) {
    PostError(error_port, "Failed to close directory", "");
  }
  free(path);

  return success;
}


static bool DeleteFile(char* file_name,
                       char* path,
                       int path_length) {
  size_t written = snprintf(path + path_length,
                            MAX_PATH - path_length,
                            "%s",
                            file_name);
  if (written != strlen(file_name)) {
    return false;
  }
  return (DeleteFile(path) != 0);
}


static bool DeleteDir(char* dir_name,
                      char* path,
                      int path_length) {
  if (strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              dir_name);
    if (written != strlen(dir_name)) {
      return false;
    }
    return DeleteRecursively(path);
  }
  return true;
}


static bool DeleteEntry(LPWIN32_FIND_DATA find_file_data,
                        char* path,
                        int path_length) {
  DWORD attributes = find_file_data->dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return DeleteDir(find_file_data->cFileName, path, path_length);
  } else {
    return DeleteFile(find_file_data->cFileName, path, path_length);
  }
}


static bool DeleteRecursively(const char* dir_name) {
  // Compute full path for the directory currently being deleted.  The
  // path buffer will be used to construct the current path in the
  // recursive traversal. path_length does not always equal
  // strlen(path) but indicates the current prefix of path that is the
  // path of the current directory in the traversal.
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length = 0;
  bool valid = ComputeFullSearchPath(dir_name, path, &path_length);
  if (!valid) {
    free(path);
    return false;
  }

  WIN32_FIND_DATA find_file_data;
  HANDLE find_handle = FindFirstFile(path, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  path_length -= 1;
  path[path_length] = '\0';

  if (find_handle == INVALID_HANDLE_VALUE) {
    free(path);
    return false;
  }

  bool success = DeleteEntry(&find_file_data, path, path_length);

  while ((FindNextFile(find_handle, &find_file_data) != 0) && success) {
    success = success && DeleteEntry(&find_file_data, path, path_length);
  }

  free(path);

  if ((GetLastError() != ERROR_NO_MORE_FILES) ||
      (FindClose(find_handle) == 0) ||
      (RemoveDirectory(dir_name) == 0)) {
    return false;
  }

  return success;
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


int Directory::CreateTemp(const char* const_template,
                          char** path,
                          char* os_error_message,
                          int os_error_message_len) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value must be freed by the caller.
  *path = static_cast<char*>(malloc(MAX_PATH));
  int path_length;
  if (0 == strncmp(const_template, "", 1)) {
    path_length = GetTempPath(MAX_PATH, *path);
    if (path_length == 0) {
      free(*path);
      *path = NULL;
      int error_code =
          SetOsErrorMessage(os_error_message, os_error_message_len);
      return error_code;
    }
  } else {
    snprintf(*path, MAX_PATH, "%s", const_template);
    path_length = strlen(*path);
  }
  // Length of tempdir-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 44.
  if (path_length > MAX_PATH - 44) {
    free(*path);
    *path = NULL;
    return -1;
  }
  if ((*path)[path_length - 1] == '\\') {
    // No base name for the directory - use "tempdir".
    snprintf(*path + path_length, MAX_PATH - path_length, "tempdir");
    path_length = strlen(*path);
  }

  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if (status != RPC_S_OK && status != RPC_S_UUID_LOCAL_ONLY) {
    free(*path);
    *path = NULL;
    int error_code =
        SetOsErrorMessage(os_error_message, os_error_message_len);
    return error_code;
  }
  RPC_CSTR uuid_string;
  status = UuidToString(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    free(*path);
    *path = NULL;
    int error_code =
        SetOsErrorMessage(os_error_message, os_error_message_len);
    return error_code;
  }

  snprintf(*path + path_length, MAX_PATH - path_length, "-%s", uuid_string);
  if (!CreateDirectory(*path, NULL)) {
    free(*path);
    *path = NULL;
    int error_code =
        SetOsErrorMessage(os_error_message, os_error_message_len);
    return error_code;
  }
  return 0;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  if (!recursive) {
    return (RemoveDirectory(dir_name) != 0);
  } else {
    return DeleteRecursively(dir_name);
  }
}
