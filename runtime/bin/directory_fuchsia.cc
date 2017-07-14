// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/directory.h"

#include <dirent.h>     // NOLINT
#include <errno.h>      // NOLINT
#include <stdlib.h>     // NOLINT
#include <string.h>     // NOLINT
#include <sys/param.h>  // NOLINT
#include <sys/stat.h>   // NOLINT
#include <unistd.h>     // NOLINT

#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

PathBuffer::PathBuffer() : length_(0) {
  data_ = calloc(PATH_MAX + 1, sizeof(char));  // NOLINT
}

PathBuffer::~PathBuffer() {
  free(data_);
}

bool PathBuffer::AddW(const wchar_t* name) {
  UNREACHABLE();
  return false;
}

char* PathBuffer::AsString() const {
  return reinterpret_cast<char*>(data_);
}

wchar_t* PathBuffer::AsStringW() const {
  UNREACHABLE();
  return NULL;
}

const char* PathBuffer::AsScopedString() const {
  return DartUtils::ScopedCopyCString(AsString());
}

bool PathBuffer::Add(const char* name) {
  const intptr_t name_length = strnlen(name, PATH_MAX + 1);
  if (name_length == 0) {
    errno = EINVAL;
    return false;
  }
  char* data = AsString();
  int written = snprintf(data + length_, PATH_MAX - length_, "%s", name);
  data[PATH_MAX] = '\0';
  if ((written <= (PATH_MAX - length_)) && (written > 0) &&
      (static_cast<size_t>(written) == strnlen(name, PATH_MAX + 1))) {
    length_ += written;
    return true;
  } else {
    errno = ENAMETOOLONG;
    return false;
  }
}

void PathBuffer::Reset(intptr_t new_length) {
  length_ = new_length;
  AsString()[length_] = '\0';
}

// A linked list of symbolic links, with their unique file system identifiers.
// These are scanned to detect loops while doing a recursive directory listing.
struct LinkList {
  dev_t dev;
  ino64_t ino;
  LinkList* next;
};

ListType DirectoryListingEntry::Next(DirectoryListing* listing) {
  if (done_) {
    return kListDone;
  }

  if (lister_ == 0) {
    lister_ =
        reinterpret_cast<intptr_t>(opendir(listing->path_buffer().AsString()));
    if (lister_ == 0) {
      perror("opendir failed: ");
      done_ = true;
      return kListError;
    }
    if (parent_ != NULL) {
      if (!listing->path_buffer().Add(File::PathSeparator())) {
        return kListError;
      }
    }
    path_length_ = listing->path_buffer().length();
  }
  // Reset.
  listing->path_buffer().Reset(path_length_);
  ResetLink();

  // Iterate the directory and post the directories and files to the
  // ports.
  errno = 0;
  dirent* entry = readdir(reinterpret_cast<DIR*>(lister_));
  if (entry != NULL) {
    if (!listing->path_buffer().Add(entry->d_name)) {
      done_ = true;
      return kListError;
    }
    // TODO(MG-450): When entry->d_type is filled out correctly, we can avoid
    // this call to stat().
    struct stat64 entry_info;
    int stat_success;
    stat_success = NO_RETRY_EXPECTED(
        lstat64(listing->path_buffer().AsString(), &entry_info));
    if (stat_success == -1) {
      perror("lstat64 failed: ");
      return kListError;
    }
    if (listing->follow_links() && S_ISLNK(entry_info.st_mode)) {
      // Check to see if we are in a loop created by a symbolic link.
      LinkList current_link = {entry_info.st_dev, entry_info.st_ino, link_};
      LinkList* previous = link_;
      while (previous != NULL) {
        if ((previous->dev == current_link.dev) &&
            (previous->ino == current_link.ino)) {
          // Report the looping link as a link, rather than following it.
          return kListLink;
        }
        previous = previous->next;
      }
      stat_success = NO_RETRY_EXPECTED(
          stat64(listing->path_buffer().AsString(), &entry_info));
      if (stat_success == -1) {
        perror("lstat64 failed");
        // Report a broken link as a link, even if follow_links is true.
        return kListLink;
      }
      if (S_ISDIR(entry_info.st_mode)) {
        // Recurse into the subdirectory with current_link added to the
        // linked list of seen file system links.
        link_ = new LinkList(current_link);
        if ((strcmp(entry->d_name, ".") == 0) ||
            (strcmp(entry->d_name, "..") == 0)) {
          return Next(listing);
        }
        return kListDirectory;
      }
    }
    if (S_ISDIR(entry_info.st_mode)) {
      if ((strcmp(entry->d_name, ".") == 0) ||
          (strcmp(entry->d_name, "..") == 0)) {
        return Next(listing);
      }
      return kListDirectory;
    } else if (S_ISREG(entry_info.st_mode) || S_ISCHR(entry_info.st_mode) ||
               S_ISBLK(entry_info.st_mode) || S_ISFIFO(entry_info.st_mode) ||
               S_ISSOCK(entry_info.st_mode)) {
      return kListFile;
    } else if (S_ISLNK(entry_info.st_mode)) {
      return kListLink;
    } else {
      FATAL1("Unexpected st_mode: %d\n", entry_info.st_mode);
      return kListError;
    }
  }
  done_ = true;

  if (errno != 0) {
    return kListError;
  }

  return kListDone;
}

DirectoryListingEntry::~DirectoryListingEntry() {
  ResetLink();
  if (lister_ != 0) {
    VOID_NO_RETRY_EXPECTED(closedir(reinterpret_cast<DIR*>(lister_)));
  }
}

void DirectoryListingEntry::ResetLink() {
  if ((link_ != NULL) && ((parent_ == NULL) || (parent_->link_ != link_))) {
    delete link_;
    link_ = NULL;
  }
  if (parent_ != NULL) {
    link_ = parent_->link_;
  }
}

Directory::ExistsResult Directory::Exists(const char* dir_name) {
  struct stat entry_info;
  int success = NO_RETRY_EXPECTED(stat(dir_name, &entry_info));
  if (success == 0) {
    if (S_ISDIR(entry_info.st_mode)) {
      return EXISTS;
    } else {
      // An OSError may be constructed based on the return value of this
      // function, so set errno to something that makes sense.
      errno = ENOTDIR;
      return DOES_NOT_EXIST;
    }
  } else {
    if ((errno == EACCES) || (errno == EBADF) || (errno == EFAULT) ||
        (errno == ENOMEM) || (errno == EOVERFLOW)) {
      // Search permissions denied for one of the directories in the
      // path or a low level error occured. We do not know if the
      // directory exists.
      return UNKNOWN;
    }
    ASSERT((errno == ELOOP) || (errno == ENAMETOOLONG) || (errno == ENOENT) ||
           (errno == ENOTDIR));
    return DOES_NOT_EXIST;
  }
}

char* Directory::CurrentNoScope() {
  return getcwd(NULL, 0);
}

const char* Directory::Current() {
  char buffer[PATH_MAX];
  if (getcwd(buffer, PATH_MAX) == NULL) {
    return NULL;
  }
  return DartUtils::ScopedCopyCString(buffer);
}

bool Directory::SetCurrent(const char* path) {
  return (NO_RETRY_EXPECTED(chdir(path)) == 0);
}

bool Directory::Create(const char* dir_name) {
  // Create the directory with the permissions specified by the
  // process umask.
  int result = NO_RETRY_EXPECTED(mkdir(dir_name, 0777));
  // If the directory already exists, treat it as a success.
  if ((result == -1) && (errno == EEXIST)) {
    return (Exists(dir_name) == EXISTS);
  }
  return (result == 0);
}

const char* Directory::SystemTemp() {
  PathBuffer path;
  const char* temp_dir = getenv("TMPDIR");
  if (temp_dir == NULL) {
    temp_dir = getenv("TMP");
  }
  if (temp_dir == NULL) {
    temp_dir = "/tmp";
  }
  if (!path.Add(temp_dir)) {
    return NULL;
  }

  // Remove any trailing slash.
  char* result = path.AsString();
  int length = strlen(result);
  if ((length > 1) && (result[length - 1] == '/')) {
    result[length - 1] = '\0';
  }
  return path.AsScopedString();
}

const char* Directory::CreateTemp(const char* prefix) {
  // Returns a new, unused directory name, adding characters to the end
  // of prefix.  Creates the directory with the permissions specified
  // by the process umask.
  // The return value is Dart_ScopeAllocated.
  PathBuffer path;
  if (!path.Add(prefix)) {
    return NULL;
  }
  if (!path.Add("XXXXXX")) {
    // Pattern has overflowed.
    return NULL;
  }
  char* result = mkdtemp(path.AsString());
  if (result == NULL) {
    return NULL;
  }
  return path.AsScopedString();
}

static bool DeleteRecursively(PathBuffer* path);

static bool DeleteFile(char* file_name, PathBuffer* path) {
  return path->Add(file_name) &&
         (NO_RETRY_EXPECTED(unlink(path->AsString())) == 0);
}

static bool DeleteDir(char* dir_name, PathBuffer* path) {
  if ((strcmp(dir_name, ".") == 0) || (strcmp(dir_name, "..") == 0)) {
    return true;
  }
  return path->Add(dir_name) && DeleteRecursively(path);
}

static bool DeleteRecursively(PathBuffer* path) {
  // Do not recurse into links for deletion. Instead delete the link.
  // If it's a file, delete it.
  struct stat64 st;
  if (NO_RETRY_EXPECTED(lstat64(path->AsString(), &st)) == -1) {
    return false;
  } else if (!S_ISDIR(st.st_mode)) {
    return NO_RETRY_EXPECTED(unlink(path->AsString())) == 0;
  }

  if (!path->Add(File::PathSeparator())) {
    return false;
  }

  // Not a link. Attempt to open as a directory and recurse into the
  // directory.
  DIR* dir_pointer = opendir(path->AsString());
  if (dir_pointer == NULL) {
    return false;
  }

  // Iterate the directory and delete all files and directories.
  int path_length = path->length();
  while (true) {
    // In case `readdir()` returns `NULL` we distinguish between end-of-stream
    // and error by looking if `errno` was updated.
    errno = 0;
    // In glibc 2.24+, readdir_r is deprecated.
    // According to the man page for readdir:
    // "readdir(3) is not required to be thread-safe. However, in modern
    // implementations (including the glibc implementation), concurrent calls to
    // readdir(3) that specify different directory streams are thread-safe."
    dirent* entry = readdir(dir_pointer);
    if (entry == NULL) {
      // Failed to read next directory entry.
      if (errno != 0) {
        break;
      }
      // End of directory.
      return (NO_RETRY_EXPECTED(closedir(dir_pointer)) == 0) &&
             (NO_RETRY_EXPECTED(remove(path->AsString())) == 0);
    }
    bool ok = false;
    if (!path->Add(entry->d_name)) {
      break;
    }
    // TODO(MG-450): When entry->d_type is filled out correctly, we can avoid
    // this call to stat().
    struct stat64 entry_info;
    if (NO_RETRY_EXPECTED(lstat64(path->AsString(), &entry_info)) == -1) {
      break;
    }
    path->Reset(path_length);
    if (S_ISDIR(entry_info.st_mode)) {
      ok = DeleteDir(entry->d_name, path);
    } else {
      // Treat links as files. This will delete the link which is
      // what we want no matter if the link target is a file or a
      // directory.
      ok = DeleteFile(entry->d_name, path);
    }
    if (!ok) {
      break;
    }
    path->Reset(path_length);
  }
  // Only happens if there was an error.
  ASSERT(errno != 0);
  int err = errno;
  VOID_NO_RETRY_EXPECTED(closedir(dir_pointer));
  errno = err;
  return false;
}

bool Directory::Delete(const char* dir_name, bool recursive) {
  if (!recursive) {
    if ((File::GetType(dir_name, false) == File::kIsLink) &&
        (File::GetType(dir_name, true) == File::kIsDirectory)) {
      return NO_RETRY_EXPECTED(unlink(dir_name)) == 0;
    }
    return NO_RETRY_EXPECTED(rmdir(dir_name)) == 0;
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
  if (exists != EXISTS) {
    return false;
  }
  return (NO_RETRY_EXPECTED(rename(path, new_path)) == 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
