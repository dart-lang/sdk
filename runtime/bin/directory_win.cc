// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include <errno.h>
#include <sys/stat.h>

#include "bin/log.h"

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
      Log::PrintErr("FormatMessage failed %d\n", GetLastError());
    }
    snprintf(os_error_message, os_error_message_len, "OS Error %d", error_code);
  }
  os_error_message[os_error_message_len - 1] = '\0';
  return error_code;
}


// Forward declaration.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            DirectoryListing* listing);
static bool DeleteRecursively(const char* dir_name);


static bool HandleDir(char* dir_name,
                      char* path,
                      int path_length,
                      bool recursive,
                      DirectoryListing* listing) {
  if (strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              MAX_PATH - path_length,
                              "%s",
                              dir_name);
    if (written != strlen(dir_name)) {
      return false;
    }
    char* utf8_path = StringUtils::SystemStringToUtf8(path);
    bool ok = listing->HandleDirectory(utf8_path);
    free(utf8_path);
    if (!ok) return ok;
    if (recursive) {
      return ListRecursively(path, recursive, listing);
    }
  }
  return true;
}


static bool HandleFile(char* file_name,
                       char* path,
                       int path_length,
                       DirectoryListing* listing) {
  size_t written = snprintf(path + path_length,
                            MAX_PATH - path_length,
                            "%s",
                            file_name);
  if (written != strlen(file_name)) {
    return false;
  };
  char* utf8_path = StringUtils::SystemStringToUtf8(path);
  bool ok = listing->HandleFile(utf8_path);
  free(utf8_path);
  return ok;
}


static bool HandleEntry(LPWIN32_FIND_DATA find_file_data,
                        char* path,
                        int path_length,
                        bool recursive,
                        DirectoryListing* listing) {
  DWORD attributes = find_file_data->dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return HandleDir(find_file_data->cFileName,
                     path,
                     path_length,
                     recursive,
                     listing);
  } else {
    return HandleFile(find_file_data->cFileName, path, path_length, listing);
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

static void PostError(DirectoryListing* listing,
                      const char* dir_name) {
  const char* utf8_path = StringUtils::SystemStringToUtf8(dir_name);
  listing->HandleError(utf8_path);
  free(const_cast<char*>(utf8_path));
}


static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            DirectoryListing* listing) {
  // Compute full path for the directory currently being listed.  The
  // path buffer will be used to construct the current path in the
  // recursive traversal. path_length does not always equal
  // strlen(path) but indicates the current prefix of path that is the
  // path of the current directory in the traversal.
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length = 0;
  bool valid = ComputeFullSearchPath(dir_name, path, &path_length);
  if (!valid) {
    PostError(listing, dir_name);
    free(path);
    return false;
  }

  WIN32_FIND_DATA find_file_data;
  HANDLE find_handle = FindFirstFile(path, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  path_length -= 1;
  path[path_length] = '\0';

  if (find_handle == INVALID_HANDLE_VALUE) {
    PostError(listing, path);
    free(path);
    return false;
  }

  bool success = HandleEntry(&find_file_data,
                             path,
                             path_length,
                             recursive,
                             listing);

  while ((FindNextFile(find_handle, &find_file_data) != 0)) {
    success = HandleEntry(&find_file_data,
                          path,
                          path_length,
                          recursive,
                          listing) && success;
  }

  if (GetLastError() != ERROR_NO_MORE_FILES) {
    success = false;
    PostError(listing, dir_name);
  }

  if (FindClose(find_handle) == 0) {
    success = false;
    PostError(listing, dir_name);
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

  if (DeleteFile(path) != 0) {
    return true;
  }

  // If we failed because the file is read-only, make it writeable and try
  // again. This mirrors Linux/Mac where a directory containing read-only files
  // can still be recursively deleted.
  if (GetLastError() == ERROR_ACCESS_DENIED) {
    DWORD attributes = GetFileAttributes(path);
    if (attributes == INVALID_FILE_ATTRIBUTES) {
      return false;
    }

    if ((attributes & FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY) {
      attributes &= ~FILE_ATTRIBUTE_READONLY;

      if (SetFileAttributes(path, attributes) == 0) {
        return false;
      }

      return DeleteFile(path) != 0;
    }
  }

  return false;
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
  // If the directory is a junction, it's pointing to some other place in the
  // filesystem that we do not want to recurse into.
  DWORD attributes = GetFileAttributes(dir_name);
  if ((attributes != INVALID_FILE_ATTRIBUTES) &&
      (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    // Just delete the junction itself.
    return RemoveDirectory(dir_name) != 0;
  }

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


bool Directory::List(const char* dir_name,
                     bool recursive,
                     DirectoryListing* listing) {
  const char* system_name = StringUtils::Utf8ToSystemString(dir_name);
  bool completed = ListRecursively(system_name, recursive, listing);
  free(const_cast<char*>(system_name));
  return completed;
}


static Directory::ExistsResult ExistsHelper(const char* dir_name) {
  DWORD attributes = GetFileAttributes(dir_name);
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    DWORD last_error = GetLastError();
    if (last_error == ERROR_FILE_NOT_FOUND ||
        last_error == ERROR_PATH_NOT_FOUND) {
      return Directory::DOES_NOT_EXIST;
    } else {
      // We might not be able to get the file attributes for other
      // reasons such as lack of permissions. In that case we do
      // not know if the directory exists.
      return Directory::UNKNOWN;
    }
  }
  bool exists = (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  return exists ? Directory::EXISTS : Directory::DOES_NOT_EXIST;
}


Directory::ExistsResult Directory::Exists(const char* dir_name) {
  const char* system_name = StringUtils::Utf8ToSystemString(dir_name);
  Directory::ExistsResult result = ExistsHelper(system_name);
  free(const_cast<char*>(system_name));
  return result;
}


char* Directory::Current() {
  int length = GetCurrentDirectory(0, NULL);
  char* current = reinterpret_cast<char*>(malloc(length + 1));
  GetCurrentDirectory(length + 1, current);
  char* result = StringUtils::SystemStringToUtf8(current);
  free(current);
  return result;
}


bool Directory::Create(const char* dir_name) {
  const char* system_name = StringUtils::Utf8ToSystemString(dir_name);
  // If the directory already exists and is a directory do not
  // attempt to create it again and treat it as a success.
  if (ExistsHelper(system_name) == EXISTS) {
    free(const_cast<char*>(system_name));
    return true;
  }
  int create_status = CreateDirectory(system_name, NULL);
  free(const_cast<char*>(system_name));
  return (create_status != 0);
}


char* Directory::CreateTemp(const char* const_template) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value must be freed by the caller.
  char* path = static_cast<char*>(malloc(MAX_PATH));
  int path_length;
  if (0 == strncmp(const_template, "", 1)) {
    path_length = GetTempPath(MAX_PATH, path);
    if (path_length == 0) {
      free(path);
      return NULL;
    }
  } else {
    const char* system_template =
        StringUtils::Utf8ToSystemString(const_template);
    snprintf(path, MAX_PATH, "%s", system_template);
    free(const_cast<char*>(system_template));
    path_length = strlen(path);
  }
  // Length of tempdir-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 44.
  if (path_length > MAX_PATH - 44) {
    free(path);
    return NULL;
  }
  if ((path)[path_length - 1] == '\\') {
    // No base name for the directory - use "tempdir".
    snprintf(path + path_length, MAX_PATH - path_length, "tempdir");
    path_length = strlen(path);
  }

  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if (status != RPC_S_OK && status != RPC_S_UUID_LOCAL_ONLY) {
    free(path);
    return NULL;
  }
  RPC_CSTR uuid_string;
  status = UuidToString(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    free(path);
    return NULL;
  }

  snprintf(path + path_length, MAX_PATH - path_length, "-%s", uuid_string);
  if (!CreateDirectory(path, NULL)) {
    free(path);
    return NULL;
  }
  char* result = StringUtils::SystemStringToUtf8(path);
  free(path);
  return result;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  bool result = false;
  const char* system_dir_name =
      StringUtils::Utf8ToSystemString(dir_name);
  if (!recursive) {
    result = (RemoveDirectory(system_dir_name) != 0);
  } else {
    result = DeleteRecursively(system_dir_name);
  }
  free(const_cast<char*>(system_dir_name));
  return result;
}


bool Directory::Rename(const char* path, const char* new_path) {
  const char* system_path = StringUtils::Utf8ToSystemString(path);
  const char* system_new_path =
      StringUtils::Utf8ToSystemString(new_path);
  ExistsResult exists = ExistsHelper(system_path);
  if (exists != EXISTS) return false;
  ExistsResult new_exists = ExistsHelper(system_new_path);
  // MoveFile does not allow replacing exising directories. Therefore,
  // if the new_path is currently a directory we need to delete it
  // first.
  if (new_exists == EXISTS) {
    bool success = DeleteRecursively(system_new_path);
    if (!success) return false;
  }
  DWORD flags = MOVEFILE_WRITE_THROUGH;
  int move_status =
      MoveFileEx(system_path, system_new_path, flags);
  free(const_cast<char*>(system_path));
  free(const_cast<char*>(system_new_path));
  return (move_status != 0);
}
