// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/file.h"

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <copyfile.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <libgen.h>  // NOLINT
#include <limits.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/fdutils.h"
#include "bin/log.h"

#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

class FileHandle {
 public:
  explicit FileHandle(int fd) : fd_(fd) { }
  ~FileHandle() { }
  int fd() const { return fd_; }
  void set_fd(int fd) { fd_ = fd; }

 private:
  int fd_;

  DISALLOW_COPY_AND_ASSIGN(FileHandle);
};


File::~File() {
  Close();
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  if (handle_->fd() == STDOUT_FILENO) {
    // If stdout, redirect fd to /dev/null.
    intptr_t null_fd = TEMP_FAILURE_RETRY(open("/dev/null", O_WRONLY));
    ASSERT(null_fd >= 0);
    VOID_TEMP_FAILURE_RETRY(dup2(null_fd, handle_->fd()));
    VOID_TEMP_FAILURE_RETRY(close(null_fd));
  } else {
    intptr_t err = TEMP_FAILURE_RETRY(close(handle_->fd()));
    if (err != 0) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      strerror_r(errno, error_message, kBufferSize);
      Log::PrintErr("%s\n", error_message);
    }
  }
  handle_->set_fd(kClosedFd);
}


intptr_t File::GetFD() {
  return handle_->fd();
}


bool File::IsClosed() {
  return handle_->fd() == kClosedFd;
}


int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(read(handle_->fd(), buffer, num_bytes));
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(write(handle_->fd(), buffer, num_bytes));
}


int64_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return lseek(handle_->fd(), 0, SEEK_CUR);
}


bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  return lseek(handle_->fd(), position, SEEK_SET) >= 0;
}


bool File::Truncate(int64_t length) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(ftruncate(handle_->fd(), length)) != -1;
}


bool File::Flush() {
  ASSERT(handle_->fd() >= 0);
  return NO_RETRY_EXPECTED(fsync(handle_->fd())) != -1;
}


bool File::Lock(File::LockType lock, int64_t start, int64_t end) {
  ASSERT(handle_->fd() >= 0);
  ASSERT(end == -1 || end > start);
  struct flock fl;
  switch (lock) {
    case File::kLockUnlock:
      fl.l_type = F_UNLCK;
      break;
    case File::kLockShared:
      fl.l_type = F_RDLCK;
      break;
    case File::kLockExclusive:
      fl.l_type = F_WRLCK;
      break;
    default:
      return false;
  }
  fl.l_whence = SEEK_SET;
  fl.l_start = start;
  fl.l_len = end == -1 ? 0 : end - start;
  // fcntl does not block, but fails if the lock cannot be acquired.
  int rc = fcntl(handle_->fd(), F_SETLK, &fl);
  return rc != -1;
}


int64_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct stat st;
  if (NO_RETRY_EXPECTED(fstat(handle_->fd(), &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


File* File::Open(const char* name, FileOpenMode mode) {
  // Report errors for non-regular files.
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    // Only accept regular files and character devices.
    if (!S_ISREG(st.st_mode) && !S_ISCHR(st.st_mode)) {
      errno = (S_ISDIR(st.st_mode)) ? EISDIR : ENOENT;
      return NULL;
    }
  }
  int flags = O_RDONLY;
  if ((mode & kWrite) != 0) {
    ASSERT((mode & kWriteOnly) == 0);
    flags = (O_RDWR | O_CREAT);
  }
  if ((mode & kWriteOnly) != 0) {
    ASSERT((mode & kWrite) == 0);
    flags = (O_WRONLY | O_CREAT);
  }
  if ((mode & kTruncate) != 0) {
    flags = flags | O_TRUNC;
  }
  int fd = TEMP_FAILURE_RETRY(open(name, flags, 0666));
  if (fd < 0) {
    return NULL;
  }
  FDUtils::SetCloseOnExec(fd);
  if ((((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) ||
      (((mode & kWriteOnly) != 0) && ((mode & kTruncate) == 0))) {
    int64_t position = lseek(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}


File* File::OpenStdio(int fd) {
  if (fd < 0 || 2 < fd) return NULL;
  return new File(new FileHandle(fd));
}


bool File::Exists(const char* name) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    return S_ISREG(st.st_mode);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  int fd = TEMP_FAILURE_RETRY(open(name, O_RDONLY | O_CREAT, 0666));
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}


bool File::CreateLink(const char* name, const char* target) {
  int status = NO_RETRY_EXPECTED(symlink(target, name));
  return (status == 0);
}


bool File::Delete(const char* name) {
  File::Type type = File::GetType(name, true);
  if (type == kIsFile) {
    return NO_RETRY_EXPECTED(unlink(name)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


bool File::DeleteLink(const char* name) {
  File::Type type = File::GetType(name, false);
  if (type == kIsLink) {
    return NO_RETRY_EXPECTED(unlink(name)) == 0;
  }
  errno = EINVAL;
  return false;
}


bool File::Rename(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, true);
  if (type == kIsFile) {
    return NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


bool File::RenameLink(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, false);
  if (type == kIsLink) {
    return NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = EINVAL;
  }
  return false;
}


bool File::Copy(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, true);
  if (type == kIsFile) {
    return copyfile(old_path, new_path, NULL, COPYFILE_ALL) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


int64_t File::LengthFromPath(const char* name) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


static int64_t TimespecToMilliseconds(const struct timespec& t) {
  return static_cast<int64_t>(t.tv_sec) * 1000L +
      static_cast<int64_t>(t.tv_nsec) / 1000000L;
}


void File::Stat(const char* name, int64_t* data) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    if (S_ISREG(st.st_mode)) {
      data[kType] = kIsFile;
    } else if (S_ISDIR(st.st_mode)) {
      data[kType] = kIsDirectory;
    } else if (S_ISLNK(st.st_mode)) {
      data[kType] = kIsLink;
    } else {
      data[kType] = kDoesNotExist;
    }
    data[kCreatedTime] = st.st_ctime;
    data[kModifiedTime] = st.st_mtime;
    data[kAccessedTime] = st.st_atime;
    data[kCreatedTime] = TimespecToMilliseconds(st.st_ctimespec);
    data[kModifiedTime] = TimespecToMilliseconds(st.st_mtimespec);
    data[kAccessedTime] = TimespecToMilliseconds(st.st_atimespec);
    data[kMode] = st.st_mode;
    data[kSize] = st.st_size;
  } else {
    data[kType] = kDoesNotExist;
  }
}


time_t File::LastModified(const char* name) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    return st.st_mtime;
  }
  return -1;
}


char* File::LinkTarget(const char* pathname) {
  struct stat link_stats;
  if (lstat(pathname, &link_stats) != 0) return NULL;
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return NULL;
  }
  // Don't rely on the link_stats.st_size for the size of the link
  // target. The link might have changed before the readlink call.
  const int kBufferSize = 1024;
  char target[kBufferSize];
  size_t target_size = TEMP_FAILURE_RETRY(
      readlink(pathname, target, kBufferSize));
  if (target_size <= 0) {
    return NULL;
  }
  char* target_name = reinterpret_cast<char*>(malloc(target_size + 1));
  if (target_name == NULL) {
    return NULL;
  }
  memmove(target_name, target, target_size);
  target_name[target_size] = '\0';
  return target_name;
}


bool File::IsAbsolutePath(const char* pathname) {
  return (pathname != NULL && pathname[0] == '/');
}


char* File::GetCanonicalPath(const char* pathname) {
  char* abs_path = NULL;
  if (pathname != NULL) {
    // On some older MacOs versions the default behaviour of realpath allocating
    // space for the resolved_path when a NULL is passed in does not seem to
    // work, so we explicitly allocate space. The caller is responsible for
    // freeing this space as in a regular realpath call.
    char* resolved_path = reinterpret_cast<char*>(malloc(PATH_MAX + 1));
    ASSERT(resolved_path != NULL);
    do {
      abs_path = realpath(pathname, NULL);
    } while (abs_path == NULL && errno == EINTR);
    ASSERT(abs_path == NULL || IsAbsolutePath(abs_path));
  }
  return abs_path;
}


const char* File::PathSeparator() {
  return "/";
}


const char* File::StringEscapedPathSeparator() {
  return "/";
}


File::StdioHandleType File::GetStdioHandleType(int fd) {
  ASSERT(0 <= fd && fd <= 2);
  struct stat buf;
  int result = fstat(fd, &buf);
  if (result == -1) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    FATAL2("Failed stat on file descriptor %d: %s", fd, error_message);
  }
  if (S_ISCHR(buf.st_mode)) return kTerminal;
  if (S_ISFIFO(buf.st_mode)) return kPipe;
  if (S_ISSOCK(buf.st_mode)) return kSocket;
  if (S_ISREG(buf.st_mode)) return kFile;
  return kOther;
}


File::Type File::GetType(const char* pathname, bool follow_links) {
  struct stat entry_info;
  int stat_success;
  if (follow_links) {
    stat_success = NO_RETRY_EXPECTED(stat(pathname, &entry_info));
  } else {
    stat_success = NO_RETRY_EXPECTED(lstat(pathname, &entry_info));
  }
  if (stat_success == -1) return File::kDoesNotExist;
  if (S_ISDIR(entry_info.st_mode)) return File::kIsDirectory;
  if (S_ISREG(entry_info.st_mode)) return File::kIsFile;
  if (S_ISLNK(entry_info.st_mode)) return File::kIsLink;
  return File::kDoesNotExist;
}


File::Identical File::AreIdentical(const char* file_1, const char* file_2) {
  struct stat file_1_info;
  struct stat file_2_info;
  if (NO_RETRY_EXPECTED(lstat(file_1, &file_1_info)) == -1 ||
      NO_RETRY_EXPECTED(lstat(file_2, &file_2_info)) == -1) {
    return File::kError;
  }
  return (file_1_info.st_ino == file_2_info.st_ino &&
          file_1_info.st_dev == file_2_info.st_dev) ?
      File::kIdentical :
      File::kDifferent;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)
