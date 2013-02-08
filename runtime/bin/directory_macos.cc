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

class PathBuffer {
 public:
  PathBuffer() : length(0) { }



  char data[PATH_MAX + 1];
  int length;

  bool Add(const char* name) {
    size_t written = snprintf(data + length,
                              PATH_MAX - length,
                              "%s",
                              name);
    data[PATH_MAX] = '\0';
    if (written == strnlen(name, PATH_MAX + 1)) {
      length += written;
      return true;
    } else {
      errno = ENAMETOOLONG;
      return false;
    }
  }

  void Reset(int new_length) {
    length = new_length;
    data[length] = '\0';
  }
};



// Forward declarations.
static bool ListRecursively(const char* dir_name,
                            bool recursive,
                            DirectoryListing* listing);
static bool DeleteRecursively(const char* dir_name);


static void PostError(DirectoryListing *listing,
                      const char* dir_name) {
  listing->HandleError(dir_name);
}


static PathBuffer* ComputeFullPath(const char* dir_name) {
  PathBuffer* path = new PathBuffer();
  char* abs_path;
  do {
    abs_path = realpath(dir_name, path->data);
  } while (abs_path == NULL && errno == EINTR);
  if (abs_path == NULL) {
    delete path;
    return NULL;
  }
  path->length = strnlen(path->data, PATH_MAX);
  if (path->Add(File::PathSeparator())) {
    return path;
  } else {
    delete path;
    return NULL;
  }
}

static bool HandleDir(char* dir_name,
                      PathBuffer* path,
                      bool recursive,
                      DirectoryListing *listing) {
  if (strcmp(dir_name, ".") == 0) return true;
  if (strcmp(dir_name, "..") == 0) return true;
  if (!path->Add(dir_name)) {
    PostError(listing, path->data);
    return false;
  }
  return listing->HandleDirectory(path->data) &&
      (!recursive || ListRecursively(path->data, recursive, listing));
}

static bool HandleFile(char* file_name,
                       PathBuffer* path,
                       DirectoryListing *listing) {
  if (!path->Add(file_name)) {
    PostError(listing, path->data);
    return false;
  }
  return listing->HandleFile(path->data);
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
  PathBuffer* path = ComputeFullPath(dir_name);
  if (path == NULL) {
    PostError(listing, dir_name);
    return false;
  }
  // Iterate the directory and post the directories and files to the
  // ports.
  int path_length = path->length;
  int status = 0;
  bool success = true;
  dirent entry;
  dirent* result;
  while ((status = TEMP_FAILURE_RETRY(readdir_r(dir_pointer,
                                                &entry,
                                                &result))) == 0 &&
         result != NULL) {
    switch (entry.d_type) {
      case DT_DIR:
        success = HandleDir(entry.d_name,
                            path,
                            recursive,
                            listing) && success;
        break;
      case DT_REG:
        success = HandleFile(entry.d_name,
                             path,
                             listing) && success;
        break;
      case DT_LNK:
      case DT_UNKNOWN: {
        // On some file systems the entry type is not determined by
        // readdir_r. For those and for links we use stat to determine
        // the actual entry type. Notice that stat returns the type of
        // the file pointed to.
        struct stat entry_info;
        if (!path->Add(entry.d_name)) {
          success = false;
          break;
        }
        int stat_success = TEMP_FAILURE_RETRY(stat(path->data, &entry_info));
        if (stat_success == -1) {
          success = false;
          PostError(listing, path->data);
          break;
        }
        path->Reset(path_length);
        if (S_ISDIR(entry_info.st_mode)) {
          success = HandleDir(entry.d_name,
                              path,
                              recursive,
                              listing) && success;
        } else if (S_ISREG(entry_info.st_mode)) {
          success = HandleFile(entry.d_name,
                               path,
                               listing) && success;
        }
        ASSERT(!S_ISLNK(entry_info.st_mode));
        break;
      }
      default:
        break;
    }
    path->Reset(path_length);
  }

  if (status != 0) {
    errno = status;
    success = false;
    PostError(listing, dir_name);
  }

  if (closedir(dir_pointer) == -1) {
    success = false;
    PostError(listing, dir_name);
  }
  delete path;

  return success;
}


static bool DeleteFile(char* file_name,
                       PathBuffer* path) {
  return path->Add(file_name) && remove(path->data) == 0;
}


static bool DeleteDir(char* dir_name,
                      PathBuffer* path) {
  if (strcmp(dir_name, ".") == 0) return true;
  if (strcmp(dir_name, "..") == 0) return true;
  return path->Add(dir_name) && DeleteRecursively(path->data);
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
  // recursive traversal.
  PathBuffer* path = ComputeFullPath(dir_name);
  if (path == NULL) return false;

  // Iterate the directory and delete all files and directories.
  int path_length = path->length;
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
        success = success && DeleteDir(entry.d_name, path);
        break;
      case DT_REG:
      case DT_LNK:
        // Treat all links as files. This will delete the link which
        // is what we want no matter if the link target is a file or a
        // directory.
        success = success && DeleteFile(entry.d_name, path);
        break;
      case DT_UNKNOWN: {
        // On some file systems the entry type is not determined by
        // readdir_r. For those we use lstat to determine the entry
        // type.
        struct stat entry_info;
        if (!path->Add(entry.d_name)) {
          success = false;
          break;
        }
        int lstat_success = TEMP_FAILURE_RETRY(lstat(path->data, &entry_info));
        if (lstat_success == -1) {
          success = false;
          break;
        }
        path->Reset(path_length);
        if (S_ISDIR(entry_info.st_mode)) {
          success = success && DeleteDir(entry.d_name, path);
        } else if (S_ISREG(entry_info.st_mode) || S_ISLNK(entry_info.st_mode)) {
          // Treat links as files. This will delete the link which is
          // what we want no matter if the link target is a file or a
          // directory.
          success = success && DeleteFile(entry.d_name, path);
        }
        break;
      }
      default:
        break;
    }
    path->Reset(path_length);
  }
  delete path;

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
  return getcwd(NULL, 0);
}


bool Directory::Create(const char* dir_name) {
  // Create the directory with the permissions specified by the
  // process umask.
  int result = TEMP_FAILURE_RETRY(mkdir(dir_name, 0777));
  // If the directory already exists, treat it as a success.
  if (result == -1 && errno == EEXIST) {
    return (Exists(dir_name) == EXISTS);
  }
  return (result == 0);
}


char* Directory::CreateTemp(const char* const_template) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates the directory with the permissions specified
  // by the process umask.
  // The return value must be freed by the caller.
  PathBuffer* path = new PathBuffer();
  path->Add(const_template);
  if (path->length == 0) {
    path->Add("/tmp/temp_dir1_");
  } else if ((path->data)[path->length - 1] == '/') {
    path->Add("temp_dir_");
  }
  if (!path->Add("XXXXXX")) {
    // Pattern has overflowed.
    delete path;
    return NULL;
  }
  char* result;
  do {
    result = mkdtemp(path->data);
  } while (result == NULL && errno == EINTR);
  if (result == NULL) {
    delete path;
    return NULL;
  }
  int length = strnlen(path->data, PATH_MAX);
  result = static_cast<char*>(malloc(length + 1));
  strncpy(result, path->data, length);
  result[length] = '\0';
  delete path;
  return result;
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
