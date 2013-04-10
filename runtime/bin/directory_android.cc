// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_ANDROID)

#include "bin/directory.h"

#include <dirent.h>  // NOLINT
#include <errno.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/param.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "bin/file.h"
#include "bin/platform.h"

class PathBuffer {
 public:
  PathBuffer() : length(0) {
    data = new char[PATH_MAX + 1];
  }

  ~PathBuffer() {
    delete[] data;
  }

  char* data;
  int length;

  bool Add(const char* name) {
    int written = snprintf(data + length,
                           PATH_MAX - length,
                           "%s",
                           name);
    data[PATH_MAX] = '\0';
    if (written <= PATH_MAX - length &&
        written >= 0 &&
        static_cast<size_t>(written) == strnlen(name, PATH_MAX + 1)) {
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


// A linked list of symbolic links, with their unique file system identifiers.
// These are scanned to detect loops while doing a recursive directory listing.
struct LinkList {
  dev_t dev;
  ino_t ino;
  LinkList* next;
};


// Forward declarations.
static bool ListRecursively(PathBuffer* path,
                            bool recursive,
                            bool follow_links,
                            LinkList* seen,
                            DirectoryListing* listing);
static bool DeleteRecursively(PathBuffer* path);


static void PostError(DirectoryListing *listing,
                      const char* dir_name) {
  listing->HandleError(dir_name);
}


static bool HandleDir(char* dir_name,
                      PathBuffer* path,
                      bool recursive,
                      bool follow_links,
                      LinkList* seen,
                      DirectoryListing *listing) {
  if (strcmp(dir_name, ".") == 0) return true;
  if (strcmp(dir_name, "..") == 0) return true;
  if (!path->Add(dir_name)) {
    PostError(listing, path->data);
    return false;
  }
  return listing->HandleDirectory(path->data) &&
      (!recursive ||
       ListRecursively(path, recursive, follow_links, seen, listing));
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


static bool HandleLink(char* link_name,
                       PathBuffer* path,
                       DirectoryListing *listing) {
  if (!path->Add(link_name)) {
    PostError(listing, path->data);
    return false;
  }
  return listing->HandleLink(path->data);
}


static bool ListRecursively(PathBuffer* path,
                            bool recursive,
                            bool follow_links,
                            LinkList* seen,
                            DirectoryListing *listing) {
  if (!path->Add(File::PathSeparator())) {
    PostError(listing, path->data);
    return false;
  }
  DIR* dir_pointer;
  do {
    dir_pointer = opendir(path->data);
  } while (dir_pointer == NULL && errno == EINTR);
  if (dir_pointer == NULL) {
    PostError(listing, path->data);
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
                            follow_links,
                            seen,
                            listing) && success;
        break;
      case DT_REG:
        success = HandleFile(entry.d_name,
                             path,
                             listing) && success;
        break;
      case DT_LNK:
        if (!follow_links) {
          success = HandleLink(entry.d_name,
                               path,
                               listing) && success;
          break;
        }
        // Else fall through to next case.
        // Fall through.
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
        int stat_success;
        stat_success = TEMP_FAILURE_RETRY(lstat(path->data, &entry_info));
        if (stat_success == -1) {
          success = false;
          PostError(listing, path->data);
          break;
        }
        if (follow_links && S_ISLNK(entry_info.st_mode)) {
          // Check to see if we are in a loop created by a symbolic link.
          LinkList current_link = { entry_info.st_dev,
                                    entry_info.st_ino,
                                    seen };
          LinkList* previous = seen;
          bool looping_link = false;
          while (previous != NULL) {
            if (previous->dev == current_link.dev &&
                previous->ino == current_link.ino) {
              // Report the looping link as a link, rather than following it.
              path->Reset(path_length);
              success = HandleLink(entry.d_name,
                                   path,
                                   listing) && success;
              looping_link = true;
              break;
            }
            previous = previous->next;
          }
          if (looping_link) break;
          stat_success = TEMP_FAILURE_RETRY(stat(path->data, &entry_info));
          if (stat_success == -1) {
            // Report a broken link as a link, even if follow_links is true.
            path->Reset(path_length);
            success = HandleLink(entry.d_name,
                                 path,
                                 listing) && success;
            break;
          }
          if (S_ISDIR(entry_info.st_mode)) {
            // Recurse into the subdirectory with current_link added to the
            // linked list of seen file system links.
            path->Reset(path_length);
            success = HandleDir(entry.d_name,
                                path,
                                recursive,
                                follow_links,
                                seen,
                                &current_link,
                                listing) && success;
            break;
          }
        }
        path->Reset(path_length);
        if (S_ISDIR(entry_info.st_mode)) {
          success = HandleDir(entry.d_name,
                              path,
                              recursive,
                              follow_links,
                              seen,
                              listing) && success;
        } else if (S_ISREG(entry_info.st_mode)) {
          success = HandleFile(entry.d_name,
                               path,
                               listing) && success;
        } else if (S_ISLNK(entry_info.st_mode)) {
          success = HandleLink(entry.d_name,
                               path,
                               listing) && success;
        }
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
    PostError(listing, path->data);
  }

  if (closedir(dir_pointer) == -1) {
    success = false;
    PostError(listing, path->data);
  }

  return success;
}


static bool DeleteFile(char* file_name,
                       PathBuffer* path) {
  return path->Add(file_name) && unlink(path->data) == 0;
}


static bool DeleteDir(char* dir_name,
                      PathBuffer* path) {
  if (strcmp(dir_name, ".") == 0) return true;
  if (strcmp(dir_name, "..") == 0) return true;
  return path->Add(dir_name) && DeleteRecursively(path);
}


static bool DeleteRecursively(PathBuffer* path) {
  // Do not recurse into links for deletion. Instead delete the link.
  // If it's a file, delete it.
  struct stat st;
  if (TEMP_FAILURE_RETRY(lstat(path->data, &st)) == -1) {
    return false;
  } else if (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) {
    return (unlink(path->data) == 0);
  }

  if (!path->Add(File::PathSeparator())) return false;

  // Not a link. Attempt to open as a directory and recurse into the
  // directory.
  DIR* dir_pointer;
  do {
    dir_pointer = opendir(path->data);
  } while (dir_pointer == NULL && errno == EINTR);

  if (dir_pointer == NULL) {
    return false;
  }

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

  if ((read != 0) ||
      (closedir(dir_pointer) == -1) ||
      (remove(path->data) == -1)) {
    return false;
  }
  return success;
}


bool Directory::List(const char* dir_name,
                     bool recursive,
                     bool follow_links,
                     DirectoryListing *listing) {
  PathBuffer path;
  if (!path.Add(dir_name)) {
    PostError(listing, dir_name);
    return false;
  }
  return ListRecursively(&path, recursive, follow_links, NULL, listing);
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
  int result = TEMP_FAILURE_RETRY(mkdir(dir_name, 0777));
  // If the directory already exists, treat it as a success.
  if (result == -1 && errno == EEXIST) {
    return (Exists(dir_name) == EXISTS);
  }
  return (result == 0);
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
  PathBuffer path;
  path.Add(const_template);
  if (path.length == 0) {
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
    path->Add(ANDROID_TEMP_DIR "/tmp/temp_dir1_");
  } else if ((path.data)[path.length - 1] == '/') {
    path.Add("temp_dir_");
  }
  if (!path.Add("XXXXXX")) {
    // Pattern has overflowed.
    return NULL;
  }
  char* result;
  do {
    result = MakeTempDirectory(path->data);
  } while (result == NULL && errno == EINTR);
  if (result == NULL) {
    return NULL;
  }
  int length = strnlen(path.data, PATH_MAX);
  result = static_cast<char*>(malloc(length + 1));
  strncpy(result, path.data, length);
  result[length] = '\0';
  return result;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  if (!recursive) {
    if (File::GetType(dir_name, false) == File::kIsLink &&
        File::GetType(dir_name, true) == File::kIsDirectory) {
      return (TEMP_FAILURE_RETRY(unlink(dir_name)) == 0);
    }
    return (TEMP_FAILURE_RETRY(rmdir(dir_name)) == 0);
  } else {
    PathBuffer path;
    if (!path.Add(dir_name)) {
      return false;
    }
    return DeleteRecursively(&path);
  }
}


bool Directory::Rename(const char* path, const char* new_path) {
  ExistsResult exists = Exists(path);
  if (exists != EXISTS) return false;
  return (TEMP_FAILURE_RETRY(rename(path, new_path)) == 0);
}

#endif  // defined(TARGET_OS_ANDROID)
