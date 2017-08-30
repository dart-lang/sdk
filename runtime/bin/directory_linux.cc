// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "bin/directory.h"

#include <dirent.h>     // NOLINT
#include <errno.h>      // NOLINT
#include <fcntl.h>      // NOLINT
#include <stdlib.h>     // NOLINT
#include <string.h>     // NOLINT
#include <sys/param.h>  // NOLINT
#include <sys/stat.h>   // NOLINT
#include <unistd.h>     // NOLINT

#include "bin/crypto.h"
#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/namespace.h"
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
  char* data = AsString();
  int written = snprintf(data + length_, PATH_MAX - length_, "%s", name);
  data[PATH_MAX] = '\0';
  if ((written <= PATH_MAX - length_) && (written >= 0) &&
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

  if (fd_ == -1) {
    ASSERT(lister_ == 0);
    NamespaceScope ns(listing->namespc(), listing->path_buffer().AsString());
    const int listingfd =
        TEMP_FAILURE_RETRY(openat64(ns.fd(), ns.path(), O_DIRECTORY));
    if (listingfd < 0) {
      done_ = true;
      return kListError;
    }
    fd_ = listingfd;
  }

  if (lister_ == 0) {
    do {
      lister_ = reinterpret_cast<intptr_t>(fdopendir(fd_));
    } while ((lister_ == 0) && (errno == EINTR));
    if (lister_ == 0) {
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
    switch (entry->d_type) {
      case DT_DIR:
        if ((strcmp(entry->d_name, ".") == 0) ||
            (strcmp(entry->d_name, "..") == 0)) {
          return Next(listing);
        }
        return kListDirectory;
      case DT_BLK:
      case DT_CHR:
      case DT_FIFO:
      case DT_SOCK:
      case DT_REG:
        return kListFile;
      case DT_LNK:
        if (!listing->follow_links()) {
          return kListLink;
        }
      // Else fall through to next case.
      // Fall through.
      case DT_UNKNOWN: {
        // On some file systems the entry type is not determined by
        // readdir. For those and for links we use stat to determine
        // the actual entry type. Notice that stat returns the type of
        // the file pointed to.
        NamespaceScope ns(listing->namespc(),
                          listing->path_buffer().AsString());
        struct stat64 entry_info;
        int stat_success;
        stat_success = TEMP_FAILURE_RETRY(
            fstatat64(ns.fd(), ns.path(), &entry_info, AT_SYMLINK_NOFOLLOW));
        if (stat_success == -1) {
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
          stat_success =
              TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &entry_info, 0));
          if (stat_success == -1) {
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
                   S_ISBLK(entry_info.st_mode) ||
                   S_ISFIFO(entry_info.st_mode) ||
                   S_ISSOCK(entry_info.st_mode)) {
          return kListFile;
        } else if (S_ISLNK(entry_info.st_mode)) {
          return kListLink;
        } else {
          FATAL1("Unexpected st_mode: %d\n", entry_info.st_mode);
          return kListError;
        }
      }

      default:
        // We should have covered all the bases. If not, let's get an error.
        FATAL1("Unexpected d_type: %d\n", entry->d_type);
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
    // This also closes fd_.
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

static bool DeleteRecursively(int dirfd, PathBuffer* path);

static bool DeleteFile(int dirfd, char* file_name, PathBuffer* path) {
  return path->Add(file_name) &&
         (NO_RETRY_EXPECTED(unlinkat(dirfd, path->AsString(), 0)) == 0);
}

static bool DeleteDir(int dirfd, char* dir_name, PathBuffer* path) {
  if ((strcmp(dir_name, ".") == 0) || (strcmp(dir_name, "..") == 0)) {
    return true;
  }
  return path->Add(dir_name) && DeleteRecursively(dirfd, path);
}

static bool DeleteRecursively(int dirfd, PathBuffer* path) {
  // Do not recurse into links for deletion. Instead delete the link.
  // If it's a file, delete it.
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(
          fstatat64(dirfd, path->AsString(), &st, AT_SYMLINK_NOFOLLOW)) == -1) {
    return false;
  } else if (!S_ISDIR(st.st_mode)) {
    return (NO_RETRY_EXPECTED(unlinkat(dirfd, path->AsString(), 0)) == 0);
  }

  if (!path->Add(File::PathSeparator())) {
    return false;
  }

  // Not a link. Attempt to open as a directory and recurse into the
  // directory.
  const int fd =
      TEMP_FAILURE_RETRY(openat64(dirfd, path->AsString(), O_DIRECTORY));
  if (fd < 0) {
    return false;
  }
  DIR* dir_pointer;
  do {
    dir_pointer = fdopendir(fd);
  } while ((dir_pointer == NULL) && (errno == EINTR));
  if (dir_pointer == NULL) {
    FDUtils::SaveErrorAndClose(fd);
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
      int status = NO_RETRY_EXPECTED(closedir(dir_pointer));
      FDUtils::SaveErrorAndClose(fd);
      if (status != 0) {
        return false;
      }
      status =
          NO_RETRY_EXPECTED(unlinkat(dirfd, path->AsString(), AT_REMOVEDIR));
      return status == 0;
    }
    bool ok = false;
    switch (entry->d_type) {
      case DT_DIR:
        ok = DeleteDir(dirfd, entry->d_name, path);
        break;
      case DT_BLK:
      case DT_CHR:
      case DT_FIFO:
      case DT_SOCK:
      case DT_REG:
      case DT_LNK:
        // Treat all links as files. This will delete the link which
        // is what we want no matter if the link target is a file or a
        // directory.
        ok = DeleteFile(dirfd, entry->d_name, path);
        break;
      case DT_UNKNOWN: {
        if (!path->Add(entry->d_name)) {
          break;
        }
        // On some file systems the entry type is not determined by
        // readdir. For those we use lstat to determine the entry
        // type.
        struct stat64 entry_info;
        if (TEMP_FAILURE_RETRY(fstatat64(dirfd, path->AsString(), &entry_info,
                                         AT_SYMLINK_NOFOLLOW)) == -1) {
          break;
        }
        path->Reset(path_length);
        if (S_ISDIR(entry_info.st_mode)) {
          ok = DeleteDir(dirfd, entry->d_name, path);
        } else {
          // Treat links as files. This will delete the link which is
          // what we want no matter if the link target is a file or a
          // directory.
          ok = DeleteFile(dirfd, entry->d_name, path);
        }
        break;
      }
      default:
        // We should have covered all the bases. If not, let's get an error.
        FATAL1("Unexpected d_type: %d\n", entry->d_type);
        break;
    }
    if (!ok) {
      break;
    }
    path->Reset(path_length);
  }
  // Only happens if an error.
  ASSERT(errno != 0);
  int err = errno;
  VOID_NO_RETRY_EXPECTED(closedir(dir_pointer));
  FDUtils::SaveErrorAndClose(fd);
  errno = err;
  return false;
}

Directory::ExistsResult Directory::Exists(Namespace* namespc,
                                          const char* dir_name) {
  NamespaceScope ns(namespc, dir_name);
  struct stat64 entry_info;
  int success =
      TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &entry_info, 0));
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

bool Directory::Create(Namespace* namespc, const char* dir_name) {
  NamespaceScope ns(namespc, dir_name);
  // Create the directory with the permissions specified by the
  // process umask.
  const int result = NO_RETRY_EXPECTED(mkdirat(ns.fd(), ns.path(), 0777));
  // If the directory already exists, treat it as a success.
  if ((result == -1) && (errno == EEXIST)) {
    return (Exists(namespc, dir_name) == EXISTS);
  }
  return (result == 0);
}

const char* Directory::SystemTemp(Namespace* namespc) {
  PathBuffer path;
  const char* temp_dir = getenv("TMPDIR");
  if (temp_dir == NULL) {
    temp_dir = getenv("TMP");
  }
  if (temp_dir == NULL) {
    temp_dir = "/tmp";
  }
  NamespaceScope ns(namespc, temp_dir);
  if (!path.Add(ns.path())) {
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

// Returns a new, unused directory name, adding characters to the end
// of prefix.  Creates the directory with the permissions specified
// by the process umask.
// The return value is Dart_ScopeAllocated.
const char* Directory::CreateTemp(Namespace* namespc, const char* prefix) {
  PathBuffer path;
  const int firstchar = 'A';
  const int numchars = 'Z' - 'A' + 1;
  uint8_t random_bytes[7];

  // mkdtemp doesn't have an "at" variant, so we have to simulate it.
  if (!path.Add(prefix)) {
    return NULL;
  }
  intptr_t prefix_length = path.length();
  while (true) {
    Crypto::GetRandomBytes(6, random_bytes);
    for (intptr_t i = 0; i < 6; i++) {
      random_bytes[i] = (random_bytes[i] % numchars) + firstchar;
    }
    random_bytes[6] = '\0';
    if (!path.Add(reinterpret_cast<char*>(random_bytes))) {
      return NULL;
    }
    NamespaceScope ns(namespc, path.AsString());
    const int result = NO_RETRY_EXPECTED(mkdirat(ns.fd(), ns.path(), 0777));
    if (result == 0) {
      return path.AsScopedString();
    } else if (errno == EEXIST) {
      path.Reset(prefix_length);
    } else {
      return NULL;
    }
  }
}

bool Directory::Delete(Namespace* namespc,
                       const char* dir_name,
                       bool recursive) {
  NamespaceScope ns(namespc, dir_name);
  if (!recursive) {
    if ((File::GetType(namespc, dir_name, false) == File::kIsLink) &&
        (File::GetType(namespc, dir_name, true) == File::kIsDirectory)) {
      return NO_RETRY_EXPECTED(unlinkat(ns.fd(), ns.path(), 0)) == 0;
    }
    return NO_RETRY_EXPECTED(unlinkat(ns.fd(), ns.path(), AT_REMOVEDIR)) == 0;
  } else {
    PathBuffer path;
    if (!path.Add(ns.path())) {
      return false;
    }
    return DeleteRecursively(ns.fd(), &path);
  }
}

bool Directory::Rename(Namespace* namespc,
                       const char* old_path,
                       const char* new_path) {
  ExistsResult exists = Exists(namespc, old_path);
  if (exists != EXISTS) {
    return false;
  }
  NamespaceScope oldns(namespc, old_path);
  NamespaceScope newns(namespc, new_path);
  return (NO_RETRY_EXPECTED(renameat(oldns.fd(), oldns.path(), newns.fd(),
                                     newns.path())) == 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
