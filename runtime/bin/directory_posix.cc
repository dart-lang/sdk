// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include <dirent.h>
#include <errno.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <unistd.h>

#include "bin/file.h"
#include "bin/platform.h"

// Forward declaration.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            Dart_Port dir_port,
                            Dart_Port file_port,
                            Dart_Port done_port,
                            Dart_Port error_port);


static void ComputeFullPath(const char* dir_name,
                            char* path,
                            int* path_length) {
  char* abs_path = realpath(dir_name, path);
  ASSERT(abs_path != NULL);
  *path_length = strlen(path);
  size_t written = snprintf(path + *path_length,
                            PATH_MAX - *path_length,
                            "%s",
                            File::PathSeparator());
  ASSERT(written == strlen(File::PathSeparator()));
  *path_length += written;
}


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
                              PATH_MAX - path_length,
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
                              PATH_MAX - path_length,
                              "%s",
                              file_name);
    ASSERT(written == strlen(file_name));
    Dart_Handle name = Dart_NewString(path);
    Dart_Post(file_port, name);
  }
}


static void PostError(Dart_Port error_port,
                      const char* prefix,
                      const char* suffix,
                      int error_code) {
  if (error_port != 0) {
    char* error_str = Platform::StrError(error_code);
    int error_message_size =
        strlen(prefix) + strlen(suffix) + strlen(error_str) + 3;
    char* message = static_cast<char*>(malloc(error_message_size + 1));
    int written = snprintf(message,
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
  DIR* dir_pointer = opendir(dir_name);
  if (dir_pointer == NULL) {
    PostError(error_port, "Directory listing failed for: ", dir_name, errno);
    return false;
  }

  // Compute full path for the directory currently being listed.
  char *path = static_cast<char*>(malloc(PATH_MAX));
  ASSERT(path != NULL);
  int path_length = 0;
  ComputeFullPath(dir_name, path, &path_length);

  // Iterated the directory and post the directories and files to the
  // ports.
  int success = 0;
  bool listing_error = false;
  dirent entry;
  dirent* result;
  while ((success = readdir_r(dir_pointer, &entry, &result)) == 0 &&
         result != NULL &&
         !listing_error) {
    switch (entry.d_type) {
      case DT_DIR:
        listing_error = listing_error || !HandleDir(entry.d_name,
                                                    path,
                                                    path_length,
                                                    recursive,
                                                    dir_port,
                                                    file_port,
                                                    done_port,
                                                    error_port);
        break;
      case DT_REG:
        HandleFile(entry.d_name, path, path_length, file_port);
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
        if (lstat_success == -1) {
          listing_error = true;
          PostError(error_port, "Directory listing failed for: ", path, errno);
          break;
        }
        if ((entry_info.st_mode & S_IFMT) == S_IFDIR) {
          listing_error = listing_error || !HandleDir(entry.d_name,
                                                      path,
                                                      path_length,
                                                      recursive,
                                                      dir_port,
                                                      file_port,
                                                      done_port,
                                                      error_port);
        } else if ((entry_info.st_mode & S_IFMT) == S_IFREG) {
          HandleFile(entry.d_name, path, path_length, file_port);
        }
        break;
      }
      default:
        break;
    }
  }

  if (success != 0) {
    listing_error = true;
    PostError(error_port, "Directory listing failed", "", success);
  }

  if (closedir(dir_pointer) == -1) {
    PostError(error_port, "Failed to close directory", "", errno);
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
  bool completed = ListRecursively(dir_name,
                                   recursive,
                                   dir_port,
                                   file_port,
                                   done_port,
                                   error_port);
  if (done_port != 0) {
    Dart_Handle value = Dart_NewBoolean(completed);
    Dart_Post(done_port, value);
  }
}


Directory::ExistsResult Directory::Exists(const char* dir_name) {
  struct stat entry_info;
  int lstat_success = lstat(dir_name, &entry_info);
  if (lstat_success == 0) {
    if ((entry_info.st_mode & S_IFMT) == S_IFDIR) {
      return EXISTS;
    } else {
      return DOES_NOT_EXIST;
    }
  } else {
    if (errno == EACCES ||
        errno == EBADF ||
        errno == EFAULT ||
        errno == ENOMEM ||
        errno == EOVERFLOW) {
      // Search permissions denied for one of the directories in the
      // path or a low level error occured. We do not know if the
      // directory exists.
      return UNKNOWN;
    }
    ASSERT(errno == ELOOP ||
           errno == ENAMETOOLONG ||
           errno == ENOENT ||
           errno == ENOTDIR);
    return DOES_NOT_EXIST;
  }
}


bool Directory::Create(const char* dir_name) {
  // Create the directory with the permissions specified by the
  // process umask.
  return (mkdir(dir_name, 0777) == 0);
}


bool Directory::Delete(const char* dir_name) {
  return (rmdir(dir_name) == 0);
}
