// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/file.h"

#include <errno.h>         // NOLINT
#include <fcntl.h>         // NOLINT
#include <libgen.h>        // NOLINT
#include <sys/mman.h>      // NOLINT
#include <sys/sendfile.h>  // NOLINT
#include <sys/stat.h>      // NOLINT
#include <sys/types.h>     // NOLINT
#include <unistd.h>        // NOLINT
#include <utime.h>         // NOLINT

#include "bin/builtin.h"
#include "bin/fdutils.h"
#include "bin/log.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

class FileHandle {
 public:
  explicit FileHandle(int fd) : fd_(fd) {}
  ~FileHandle() {}
  int fd() const { return fd_; }
  void set_fd(int fd) { fd_ = fd; }

 private:
  int fd_;

  DISALLOW_COPY_AND_ASSIGN(FileHandle);
};


File::~File() {
  if (!IsClosed()) {
    Close();
  }
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  if (handle_->fd() == STDOUT_FILENO) {
    // If stdout, redirect fd to /dev/null.
    int null_fd = TEMP_FAILURE_RETRY(open("/dev/null", O_WRONLY));
    ASSERT(null_fd >= 0);
    VOID_TEMP_FAILURE_RETRY(dup2(null_fd, handle_->fd()));
    VOID_TEMP_FAILURE_RETRY(close(null_fd));
  } else {
    int err = TEMP_FAILURE_RETRY(close(handle_->fd()));
    if (err != 0) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      Utils::StrError(errno, error_message, kBufferSize);
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


MappedMemory* File::Map(MapType type, int64_t position, int64_t length) {
  ASSERT(handle_->fd() >= 0);
  ASSERT(length > 0);
  int prot = PROT_NONE;
  switch (type) {
    case kReadOnly:
      prot = PROT_READ;
      break;
    case kReadExecute:
      prot = PROT_READ | PROT_EXEC;
      break;
    default:
      return NULL;
  }
  void* addr = mmap(NULL, length, prot, MAP_PRIVATE, handle_->fd(), position);
  if (addr == MAP_FAILED) {
    return NULL;
  }
  return new MappedMemory(addr, length);
}


void MappedMemory::Unmap() {
  int result = munmap(address_, size_);
  ASSERT(result == 0);
  address_ = 0;
  size_ = 0;
}


int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(read(handle_->fd(), buffer, num_bytes));
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(write(handle_->fd(), buffer, num_bytes));
}


bool File::VPrint(const char* format, va_list args) {
  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = vsnprintf(NULL, 0, format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  vsnprintf(buffer, len + 1, format, print_args);
  va_end(print_args);

  bool result = WriteFully(buffer, len);
  free(buffer);
  return result;
}


int64_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return NO_RETRY_EXPECTED(lseek64(handle_->fd(), 0, SEEK_CUR));
}


bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  return NO_RETRY_EXPECTED(lseek64(handle_->fd(), position, SEEK_SET)) >= 0;
}


bool File::Truncate(int64_t length) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(ftruncate(handle_->fd(), length) != -1);
}


bool File::Flush() {
  ASSERT(handle_->fd() >= 0);
  return NO_RETRY_EXPECTED(fsync(handle_->fd()) != -1);
}


bool File::Lock(File::LockType lock, int64_t start, int64_t end) {
  ASSERT(handle_->fd() >= 0);
  ASSERT((end == -1) || (end > start));
  struct flock fl;
  switch (lock) {
    case File::kLockUnlock:
      fl.l_type = F_UNLCK;
      break;
    case File::kLockShared:
    case File::kLockBlockingShared:
      fl.l_type = F_RDLCK;
      break;
    case File::kLockExclusive:
    case File::kLockBlockingExclusive:
      fl.l_type = F_WRLCK;
      break;
    default:
      return false;
  }
  fl.l_whence = SEEK_SET;
  fl.l_start = start;
  fl.l_len = end == -1 ? 0 : end - start;
  int cmd = F_SETLK;
  if ((lock == File::kLockBlockingShared) ||
      (lock == File::kLockBlockingExclusive)) {
    cmd = F_SETLKW;
  }
  return TEMP_FAILURE_RETRY(fcntl(handle_->fd(), cmd, &fl)) != -1;
}


int64_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct stat st;
  if (NO_RETRY_EXPECTED(fstat(handle_->fd(), &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


File* File::FileOpenW(const wchar_t* system_name, FileOpenMode mode) {
  UNREACHABLE();
  return NULL;
}


File* File::Open(const char* name, FileOpenMode mode) {
  // Report errors for non-regular files.
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    if (!S_ISREG(st.st_mode)) {
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
  flags |= O_CLOEXEC;
  int fd = TEMP_FAILURE_RETRY(open(name, flags, 0666));
  if (fd < 0) {
    return NULL;
  }
  if ((((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) ||
      (((mode & kWriteOnly) != 0) && ((mode & kTruncate) == 0))) {
    int64_t position = lseek64(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}


File* File::OpenStdio(int fd) {
  return ((fd < 0) || (2 < fd)) ? NULL : new File(new FileHandle(fd));
}


bool File::Exists(const char* name) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    // Everything but a directory and a link is a file to Dart.
    return !S_ISDIR(st.st_mode) && !S_ISLNK(st.st_mode);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  int fd = TEMP_FAILURE_RETRY(open(name, O_RDONLY | O_CREAT | O_CLOEXEC, 0666));
  if (fd < 0) {
    return false;
  }
  // File.create returns a File, so we shouldn't be giving the illusion that the
  // call has created a file or that a file already exists if there is already
  // an entity at the same path that is a directory or a link.
  bool is_file = true;
  struct stat st;
  if (NO_RETRY_EXPECTED(fstat(fd, &st)) == 0) {
    if (S_ISDIR(st.st_mode)) {
      errno = EISDIR;
      is_file = false;
    } else if (S_ISLNK(st.st_mode)) {
      errno = ENOENT;
      is_file = false;
    }
  }
  FDUtils::SaveErrorAndClose(fd);
  return is_file;
}


bool File::CreateLink(const char* name, const char* target) {
  int status = NO_RETRY_EXPECTED(symlink(target, name));
  return (status == 0);
}


File::Type File::GetType(const char* pathname, bool follow_links) {
  struct stat entry_info;
  int stat_success;
  if (follow_links) {
    stat_success = NO_RETRY_EXPECTED(stat(pathname, &entry_info));
  } else {
    stat_success = NO_RETRY_EXPECTED(lstat(pathname, &entry_info));
  }
  if (stat_success == -1) {
    return File::kDoesNotExist;
  }
  if (S_ISDIR(entry_info.st_mode)) {
    return File::kIsDirectory;
  }
  if (S_ISREG(entry_info.st_mode)) {
    return File::kIsFile;
  }
  if (S_ISLNK(entry_info.st_mode)) {
    return File::kIsLink;
  }
  return File::kDoesNotExist;
}


static bool CheckTypeAndSetErrno(const char* name,
                                 File::Type expected,
                                 bool follow_links) {
  File::Type actual = File::GetType(name, follow_links);
  if (actual == expected) {
    return true;
  }
  switch (actual) {
    case File::kIsDirectory:
      errno = EISDIR;
      break;
    case File::kDoesNotExist:
      errno = ENOENT;
      break;
    default:
      errno = EINVAL;
      break;
  }
  return false;
}


bool File::Delete(const char* name) {
  return CheckTypeAndSetErrno(name, kIsFile, true) &&
         (NO_RETRY_EXPECTED(unlink(name)) == 0);
}


bool File::DeleteLink(const char* name) {
  return CheckTypeAndSetErrno(name, kIsLink, false) &&
         (NO_RETRY_EXPECTED(unlink(name)) == 0);
}


bool File::Rename(const char* old_path, const char* new_path) {
  return CheckTypeAndSetErrno(old_path, kIsFile, true) &&
         (NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0);
}


bool File::RenameLink(const char* old_path, const char* new_path) {
  return CheckTypeAndSetErrno(old_path, kIsLink, false) &&
         (NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0);
}


bool File::Copy(const char* old_path, const char* new_path) {
  if (!CheckTypeAndSetErrno(old_path, kIsFile, true)) {
    return false;
  }
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(old_path, &st)) != 0) {
    return false;
  }
  int old_fd = TEMP_FAILURE_RETRY(open(old_path, O_RDONLY | O_CLOEXEC));
  if (old_fd < 0) {
    return false;
  }
  int new_fd = TEMP_FAILURE_RETRY(
      open(new_path, O_WRONLY | O_TRUNC | O_CREAT | O_CLOEXEC, st.st_mode));
  if (new_fd < 0) {
    VOID_TEMP_FAILURE_RETRY(close(old_fd));
    return false;
  }
  off_t offset = 0;
  int result = 1;
  while (result > 0) {
    // Loop to ensure we copy everything, and not only up to 2GB.
    result = NO_RETRY_EXPECTED(sendfile(new_fd, old_fd, &offset, kMaxUint32));
  }
  // From sendfile man pages:
  //   Applications may wish to fall back to read(2)/write(2) in the case
  //   where sendfile() fails with EINVAL or ENOSYS.
  if ((result < 0) && ((errno == EINVAL) || (errno == ENOSYS))) {
    const intptr_t kBufferSize = 8 * KB;
    uint8_t buffer[kBufferSize];
    while ((result = TEMP_FAILURE_RETRY(read(old_fd, buffer, kBufferSize))) >
           0) {
      int wrote = TEMP_FAILURE_RETRY(write(new_fd, buffer, result));
      if (wrote != result) {
        result = -1;
        break;
      }
    }
  }
  int e = errno;
  VOID_TEMP_FAILURE_RETRY(close(old_fd));
  VOID_TEMP_FAILURE_RETRY(close(new_fd));
  if (result < 0) {
    VOID_NO_RETRY_EXPECTED(unlink(new_path));
    errno = e;
    return false;
  }
  return true;
}


static bool StatHelper(const char* name, struct stat* st) {
  if (NO_RETRY_EXPECTED(stat(name, st)) != 0) {
    return false;
  }
  // Signal an error if it's a directory.
  if (S_ISDIR(st->st_mode)) {
    errno = EISDIR;
    return false;
  }
  // Otherwise assume the caller knows what it's doing.
  return true;
}


int64_t File::LengthFromPath(const char* name) {
  struct stat st;
  if (!StatHelper(name, &st)) {
    return -1;
  }
  return st.st_size;
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
    data[kCreatedTime] = static_cast<int64_t>(st.st_ctime) * 1000;
    data[kModifiedTime] = static_cast<int64_t>(st.st_mtime) * 1000;
    data[kAccessedTime] = static_cast<int64_t>(st.st_atime) * 1000;
    data[kMode] = st.st_mode;
    data[kSize] = st.st_size;
  } else {
    data[kType] = kDoesNotExist;
  }
}


time_t File::LastModified(const char* name) {
  struct stat st;
  if (!StatHelper(name, &st)) {
    return -1;
  }
  return st.st_mtime;
}


time_t File::LastAccessed(const char* name) {
  struct stat st;
  if (!StatHelper(name, &st)) {
    return -1;
  }
  return st.st_atime;
}


bool File::SetLastAccessed(const char* name, int64_t millis) {
  // First get the current times.
  struct stat st;
  if (!StatHelper(name, &st)) {
    return false;
  }

  // Set the new time:
  struct utimbuf times;
  times.actime = millis / kMillisecondsPerSecond;
  times.modtime = st.st_mtime;
  return utime(name, &times) == 0;
}


bool File::SetLastModified(const char* name, int64_t millis) {
  // First get the current times.
  struct stat st;
  if (!StatHelper(name, &st)) {
    return false;
  }

  // Set the new time:
  struct utimbuf times;
  times.actime = st.st_atime;
  times.modtime = millis / kMillisecondsPerSecond;
  return utime(name, &times) == 0;
}


const char* File::LinkTarget(const char* pathname) {
  struct stat link_stats;
  if (lstat(pathname, &link_stats) != 0) {
    return NULL;
  }
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return NULL;
  }
  size_t target_size = link_stats.st_size;
  char* target_name = DartUtils::ScopedCString(target_size + 1);
  ASSERT(target_name != NULL);
  size_t read_size = readlink(pathname, target_name, target_size + 1);
  if (read_size != target_size) {
    return NULL;
  }
  target_name[target_size] = '\0';
  return target_name;
}


bool File::IsAbsolutePath(const char* pathname) {
  return ((pathname != NULL) && (pathname[0] == '/'));
}


const char* File::GetCanonicalPath(const char* pathname) {
  char* abs_path = NULL;
  if (pathname != NULL) {
    char* resolved_path = DartUtils::ScopedCString(PATH_MAX + 1);
    ASSERT(resolved_path != NULL);
    do {
      abs_path = realpath(pathname, resolved_path);
    } while ((abs_path == NULL) && (errno == EINTR));
    ASSERT((abs_path == NULL) || IsAbsolutePath(abs_path));
    ASSERT((abs_path == NULL) || (abs_path == resolved_path));
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
  ASSERT((0 <= fd) && (fd <= 2));
  struct stat buf;
  int result = fstat(fd, &buf);
  if (result == -1) {
    return kOther;
  }
  if (S_ISCHR(buf.st_mode)) {
    return kTerminal;
  }
  if (S_ISFIFO(buf.st_mode)) {
    return kPipe;
  }
  if (S_ISSOCK(buf.st_mode)) {
    return kSocket;
  }
  if (S_ISREG(buf.st_mode)) {
    return kFile;
  }
  return kOther;
}


File::Identical File::AreIdentical(const char* file_1, const char* file_2) {
  struct stat file_1_info;
  struct stat file_2_info;
  if ((NO_RETRY_EXPECTED(lstat(file_1, &file_1_info)) == -1) ||
      (NO_RETRY_EXPECTED(lstat(file_2, &file_2_info)) == -1)) {
    return File::kError;
  }
  return ((file_1_info.st_ino == file_2_info.st_ino) &&
          (file_1_info.st_dev == file_2_info.st_dev))
             ? File::kIdentical
             : File::kDifferent;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
