// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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


static char* SafeStrNCpy(char* dest, const char* src, size_t n) {
  strncpy(dest, src, n);
  dest[n - 1] = '\0';
  return dest;
}


// Forward declarations.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            DirectoryListing* listing);
static bool DeleteRecursively(const char* dir_name);


static bool ComputeFullPath(const char* dir_name,
                            char* path,
                            int* path_length) {
  char* abs_path;
  do {
    abs_path = realpath(dir_name, path);
  } while (abs_path == NULL && errno == EINTR);
  if (abs_path == NULL) {
    return false;
  }
  *path_length = strlen(path);
  size_t written = snprintf(path + *path_length,
                            PATH_MAX - *path_length,
                            "%s",
                            File::PathSeparator());
  if (written != strlen(File::PathSeparator())) {
    return false;
  }
  *path_length += written;
  return true;
}


static bool HandleDir(char* dir_name,
                      char* path,
                      int path_length,
                      bool recursive,
                      DirectoryListing *listing) {
  if (strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              PATH_MAX - path_length,
                              "%s",
                              dir_name);
    if (written != strlen(dir_name)) {
      return false;
    }
    bool ok = listing->HandleDirectory(path);
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
                       DirectoryListing *listing) {
  // TODO(sgjesse): Pass flags to indicate whether file responses are
  // needed.
  size_t written = snprintf(path + path_length,
                            PATH_MAX - path_length,
                            "%s",
                            file_name);
  if (written != strlen(file_name)) {
    return false;
  }
  return listing->HandleFile(path);
}


static void PostError(DirectoryListing *listing,
                      const char* dir_name) {
  listing->HandleError(dir_name);
}


static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            DirectoryListing *listing) {
  DIR* dir_pointer;
  do {
    dir_pointer = opendir(dir_name);
  } while (dir_pointer == NULL && errno == EINTR);
  if (dir_pointer == NULL) {
    PostError(listing, dir_name);
    return false;
  }

  // Compute full path for the directory currently being listed.  The
  // path buffer will be used to construct the current path in the
  // recursive traversal. path_length does not always equal
  // strlen(path) but indicates the current prefix of path that is the
  // path of the current directory in the traversal.
  char *path = static_cast<char*>(malloc(PATH_MAX));
  ASSERT(path != NULL);
  int path_length = 0;
  bool valid = ComputeFullPath(dir_name, path, &path_length);
  if (!valid) {
    free(path);
    PostError(listing, dir_name);
    return false;
  }

  // Iterated the directory and post the directories and files to the
  // ports.
  int read = 0;
  bool success = true;
  dirent entry;
  dirent* result;
  while ((read = TEMP_FAILURE_RETRY(readdir_r(dir_pointer,
                                              &entry,
                                              &result))) == 0 &&
         result != NULL) {
    switch (entry.d_type) {
      case DT_DIR:
        success = HandleDir(entry.d_name,
                            path,
                            path_length,
                            recursive,
                            listing) && success;
        break;
      case DT_REG:
        success = HandleFile(entry.d_name,
                             path,
                             path_length,
                             listing) && success;
        break;
      case DT_LNK:
      case DT_UNKNOWN: {
        // On some file systems the entry type is not determined by
        // readdir_r. For those and for links we use stat to determine
        // the actual entry type. Notice that stat returns the type of
        // the file pointed to.
        struct stat entry_info;
        size_t written = snprintf(path + path_length,
                                  PATH_MAX - path_length,
                                  "%s",
                                  entry.d_name);
        if (written != strlen(entry.d_name)) {
          success = false;
          break;
        }
        int stat_success = TEMP_FAILURE_RETRY(stat(path, &entry_info));
        if (stat_success == -1) {
          success = false;
          PostError(listing, path);
          break;
        }
        if (S_ISDIR(entry_info.st_mode)) {
          success = HandleDir(entry.d_name,
                              path,
                              path_length,
                              recursive,
                              listing) && success;
        } else if (S_ISREG(entry_info.st_mode)) {
          success = HandleFile(entry.d_name,
                               path,
                               path_length,
                               listing) && success;
        }
        ASSERT(!S_ISLNK(entry_info.st_mode));
        break;
      }
      default:
        break;
    }
  }

  if (read != 0) {
    errno = read;
    success = false;
    PostError(listing, dir_name);
  }

  if (closedir(dir_pointer) == -1) {
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
                            PATH_MAX - path_length,
                            "%s",
                            file_name);
  if (written != strlen(file_name)) {
    return false;
  }
  return (remove(path) == 0);
}


static bool DeleteDir(char* dir_name,
                      char* path,
                      int path_length) {
  if (strcmp(dir_name, ".") != 0 &&
      strcmp(dir_name, "..") != 0) {
    size_t written = snprintf(path + path_length,
                              PATH_MAX - path_length,
                              "%s",
                              dir_name);
    if (written != strlen(dir_name)) {
      return false;
    }
    return DeleteRecursively(path);
  }
  return true;
}


static bool DeleteRecursively(const char* dir_name) {
  // Do not recurse into links for deletion. Instead delete the link.
  struct stat st;
  if (TEMP_FAILURE_RETRY(lstat(dir_name, &st)) == -1) {
    return false;
  } else if (S_ISLNK(st.st_mode)) {
    return (remove(dir_name) == 0);
  }

  // Not a link. Attempt to open as a directory and recurse into the
  // directory.
  DIR* dir_pointer;
  do {
    dir_pointer = opendir(dir_name);
  } while (dir_pointer == NULL && errno == EINTR);

  if (dir_pointer == NULL) {
    return false;
  }

  // Compute full path for the directory currently being deleted.  The
  // path buffer will be used to construct the current path in the
  // recursive traversal. path_length does not always equal
  // strlen(path) but indicates the current prefix of path that is the
  // path of the current directory in the traversal.
  char *path = static_cast<char*>(malloc(PATH_MAX));
  ASSERT(path != NULL);
  int path_length = 0;
  bool valid = ComputeFullPath(dir_name, path, &path_length);
  if (!valid) {
    free(path);
    return false;
  }

  // Iterate the directory and delete all files and directories.
  int read = 0;
  bool success = true;
  dirent entry;
  dirent* result;
  while ((read = TEMP_FAILURE_RETRY(readdir_r(dir_pointer,
                                              &entry,
                                              &result))) == 0 &&
         result != NULL &&
         success) {
    switch (entry.d_type) {
      case DT_DIR:
        success = success && DeleteDir(entry.d_name, path, path_length);
        break;
      case DT_REG:
      case DT_LNK:
        // Treat all links as files. This will delete the link which
        // is what we want no matter if the link target is a file or a
        // directory.
        success = success && DeleteFile(entry.d_name, path, path_length);
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
        if (written != strlen(entry.d_name)) {
          success = false;
          break;
        }
        int lstat_success = TEMP_FAILURE_RETRY(lstat(path, &entry_info));
        if (lstat_success == -1) {
          success = false;
          break;
        }
        if (S_ISDIR(entry_info.st_mode)) {
          success = success && DeleteDir(entry.d_name, path, path_length);
        } else if (S_ISREG(entry_info.st_mode) || S_ISLNK(entry_info.st_mode)) {
          // Treat links as files. This will delete the link which is
          // what we want no matter if the link target is a file or a
          // directory.
          success = success && DeleteFile(entry.d_name, path, path_length);
        }
        break;
      }
      default:
        break;
    }
  }

  free(path);

  if ((read != 0) ||
      (closedir(dir_pointer) == -1) ||
      (remove(dir_name) == -1)) {
    return false;
  }

  return success;
}


bool Directory::List(const char* dir_name,
                     bool recursive,
                     DirectoryListing *listing) {
  bool completed = ListRecursively(dir_name, recursive, listing);
  return completed;
}


Directory::ExistsResult Directory::Exists(const char* dir_name) {
  struct stat entry_info;
  int success = TEMP_FAILURE_RETRY(stat(dir_name, &entry_info));
  if (success == 0) {
    if (S_ISDIR(entry_info.st_mode)) {
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


char* Directory::Current() {
  // Android's getcwd adheres closely to the POSIX standard. It won't
  // allocate memory. We need to make our own copy.

  char buffer[PATH_MAX];
  if (NULL == getcwd(buffer, PATH_MAX)) {
    return NULL;
  }

  return strdup(buffer);
}


bool Directory::Create(const char* dir_name) {
  // Create the directory with the permissions specified by the
  // process umask.
  return (TEMP_FAILURE_RETRY(mkdir(dir_name, 0777)) == 0);
}


// Android doesn't currently provide mkdtemp.  Once Android provied mkdtemp,
// remove this function in favor of calling mkdtemp directly.
static char* MakeTempDirectory(char* path_template) {
  if (mktemp(path_template) == NULL) {
    return NULL;
  }
  if (mkdir(path_template, 0700) != 0) {
    return NULL;
  }
  return path_template;
}


char* Directory::CreateTemp(const char* const_template) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates the directory with the permissions specified
  // by the process umask.
  // The return value must be freed by the caller.
  char* path = static_cast<char*>(malloc(PATH_MAX + 1));
  SafeStrNCpy(path, const_template, PATH_MAX + 1);
  int path_length = strlen(path);
  if (path_length > 0) {
    if ((path)[path_length - 1] == '/') {
      snprintf(path + path_length, PATH_MAX - path_length, "temp_dir_XXXXXX");
    } else {
      snprintf(path + path_length, PATH_MAX - path_length, "XXXXXX");
    }
  } else {
    // Android does not have a /tmp directory. A partial substitute,
    // suitable for bring-up work and tests, is to create a tmp
    // directory in /data/local/tmp.
    //
    // TODO(4413): In the long run, when running in an application we should
    // probably use android.content.Context.getCacheDir().
    #define ANDROID_TEMP_DIR "/data/local/tmp"
    struct stat st;
    if (stat(ANDROID_TEMP_DIR, &st) != 0) {
      mkdir(ANDROID_TEMP_DIR, 0777);
    }
    snprintf(path, PATH_MAX, ANDROID_TEMP_DIR "/temp_dir1_XXXXXX");
  }
  char* result;
  do {
    result = MakeTempDirectory(path);
  } while (result == NULL && errno == EINTR);
  if (result == NULL) {
    free(path);
    return NULL;
  }
  return path;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  if (!recursive) {
    return (TEMP_FAILURE_RETRY(remove(dir_name)) == 0);
  } else {
    return DeleteRecursively(dir_name);
  }
}


bool Directory::Rename(const char* path, const char* new_path) {
  ExistsResult exists = Exists(path);
  if (exists != EXISTS) return false;
  return (TEMP_FAILURE_RETRY(rename(path, new_path)) == 0);
}
