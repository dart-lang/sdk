// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/file.h"

#include <copyfile.h>  // NOLINT
#include <errno.h>     // NOLINT
#include <fcntl.h>     // NOLINT
#include <libgen.h>    // NOLINT
#include <limits.h>    // NOLINT
#include <sys/mman.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>    // NOLINT
#include <utime.h>     // NOLINT

#include "bin/builtin.h"
#include "bin/fdutils.h"
#include "bin/namespace.h"
#include "platform/signal_blocker.h"
#include "platform/syslog.h"
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
  if (!IsClosed() && handle_->fd() != STDOUT_FILENO &&
      handle_->fd() != STDERR_FILENO) {
    Close();
  }
  delete handle_;
}

void File::Close() {
  ASSERT(handle_->fd() >= 0);
  if (handle_->fd() == STDOUT_FILENO) {
    // If stdout, redirect fd to /dev/null.
    intptr_t null_fd = TEMP_FAILURE_RETRY(open("/dev/null", O_WRONLY));
    ASSERT(null_fd >= 0);
    VOID_TEMP_FAILURE_RETRY(dup2(null_fd, handle_->fd()));
    close(null_fd);
  } else {
    intptr_t err = close(handle_->fd());
    if (err != 0) {
      const int kBufferSize = 1024;
      char error_message[kBufferSize];
      Utils::StrError(errno, error_message, kBufferSize);
      Syslog::PrintErr("%s\n", error_message);
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

MappedMemory* File::Map(MapType type,
                        int64_t position,
                        int64_t length,
                        void* start) {
  ASSERT(handle_->fd() >= 0);
  ASSERT(length > 0);
  int prot = PROT_NONE;
  int map_flags = MAP_PRIVATE;
  switch (type) {
    case kReadOnly:
      prot = PROT_READ;
      break;
    case kReadExecute:
      prot = PROT_READ | PROT_EXEC;
      if (IsAtLeastOS10_14()) {
        map_flags |= (MAP_JIT | MAP_ANONYMOUS);
      }
      break;
    case kReadWrite:
      prot = PROT_READ | PROT_WRITE;
      break;
  }
  if (start != nullptr) {
    map_flags |= MAP_FIXED;
  }
  void* addr = start;
  if ((type == kReadExecute) && IsAtLeastOS10_14()) {
    // Due to codesigning restrictions, we cannot map the file as executable
    // directly. We must first copy it into an anonymous mapping and then mark
    // the mapping as executable.
    if (addr == nullptr) {
      addr = mmap(nullptr, length, (PROT_READ | PROT_WRITE), map_flags, -1, 0);
      if (addr == MAP_FAILED) {
        Syslog::PrintErr("mmap failed %s\n", strerror(errno));
        return nullptr;
      }
    }

    const int64_t remaining_length = Length() - position;
    SetPosition(position);
    if (!ReadFully(addr, Utils::Minimum(length, remaining_length))) {
      Syslog::PrintErr("ReadFully failed\n");
      if (start == nullptr) {
        munmap(addr, length);
      }
      return nullptr;
    }

    // If the requested mapping is larger than the file size, we should fill the
    // extra memory with zeros.
    if (length > remaining_length) {
      memset(reinterpret_cast<uint8_t*>(addr) + remaining_length, 0,
             length - remaining_length);
    }

    if (mprotect(addr, length, prot) != 0) {
      Syslog::PrintErr("mprotect failed %s\n", strerror(errno));
      if (start == nullptr) {
        munmap(addr, length);
      }
      return nullptr;
    }
  } else {
    addr = mmap(addr, length, prot, map_flags, handle_->fd(), position);
    if (addr == MAP_FAILED) {
      Syslog::PrintErr("mmap failed %s\n", strerror(errno));
      return nullptr;
    }
  }
  return new MappedMemory(addr, length, /*should_unmap=*/start == nullptr);
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
  // Invalid argument error will pop if num_bytes exceeds the limit.
  ASSERT(handle_->fd() >= 0 && num_bytes <= kMaxInt32);
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

File* File::Open(Namespace* namespc, const char* name, FileOpenMode mode) {
  // Report errors for non-regular files.
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    // Only accept regular files, character devices, and pipes.
    if (!S_ISREG(st.st_mode) && !S_ISCHR(st.st_mode) && !S_ISFIFO(st.st_mode)) {
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

Utils::CStringUniquePtr File::UriToPath(const char* uri) {
  const char* path = (strlen(uri) >= 8 && strncmp(uri, "file:///", 8) == 0)
      ? uri + 7 : uri;
  UriDecoder uri_decoder(path);
  if (uri_decoder.decoded() == nullptr) {
    errno = EINVAL;
    return Utils::CreateCStringUniquePtr(nullptr);
  }
  return Utils::CreateCStringUniquePtr(strdup(uri_decoder.decoded()));
}

File* File::OpenUri(Namespace* namespc, const char* uri, FileOpenMode mode) {
  auto path = UriToPath(uri);
  if (path == nullptr) {
    return nullptr;
  }
  return File::Open(namespc, path.get(), mode);
}

File* File::OpenStdio(int fd) {
  return new File(new FileHandle(fd));
}

bool File::Exists(Namespace* namespc, const char* name) {
  struct stat st;
  if (NO_RETRY_EXPECTED(stat(name, &st)) == 0) {
    // Everything but a directory and a link is a file to Dart.
    return !S_ISDIR(st.st_mode) && !S_ISLNK(st.st_mode);
  } else {
    return false;
  }
}

bool File::ExistsUri(Namespace* namespc, const char* uri) {
  auto path = UriToPath(uri);
  if (path == nullptr) {
    return false;
  }
  return File::Exists(namespc, path.get());
}

bool File::Create(Namespace* namespc, const char* name) {
  int fd = TEMP_FAILURE_RETRY(open(name, O_RDONLY | O_CREAT, 0666));
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

bool File::CreateLink(Namespace* namespc,
                      const char* name,
                      const char* target) {
  int status = NO_RETRY_EXPECTED(symlink(target, name));
  return (status == 0);
}

File::Type File::GetType(Namespace* namespc,
                         const char* pathname,
                         bool follow_links) {
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

static bool CheckTypeAndSetErrno(Namespace* namespc,
                                 const char* name,
                                 File::Type expected,
                                 bool follow_links) {
  File::Type actual = File::GetType(namespc, name, follow_links);
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

bool File::Delete(Namespace* namespc, const char* name) {
  return CheckTypeAndSetErrno(namespc, name, kIsFile, true) &&
         (NO_RETRY_EXPECTED(unlink(name)) == 0);
}

bool File::DeleteLink(Namespace* namespc, const char* name) {
  return CheckTypeAndSetErrno(namespc, name, kIsLink, false) &&
         (NO_RETRY_EXPECTED(unlink(name)) == 0);
}

bool File::Rename(Namespace* namespc,
                  const char* old_path,
                  const char* new_path) {
  return CheckTypeAndSetErrno(namespc, old_path, kIsFile, true) &&
         (NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0);
}

bool File::RenameLink(Namespace* namespc,
                      const char* old_path,
                      const char* new_path) {
  return CheckTypeAndSetErrno(namespc, old_path, kIsLink, false) &&
         (NO_RETRY_EXPECTED(rename(old_path, new_path)) == 0);
}

bool File::Copy(Namespace* namespc,
                const char* old_path,
                const char* new_path) {
  return CheckTypeAndSetErrno(namespc, old_path, kIsFile, true) &&
         (copyfile(old_path, new_path, NULL, COPYFILE_ALL) == 0);
}

static bool StatHelper(Namespace* namespc, const char* name, struct stat* st) {
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

int64_t File::LengthFromPath(Namespace* namespc, const char* name) {
  struct stat st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_size;
}

static int64_t TimespecToMilliseconds(const struct timespec& t) {
  return static_cast<int64_t>(t.tv_sec) * 1000L +
         static_cast<int64_t>(t.tv_nsec) / 1000000L;
}

void File::Stat(Namespace* namespc, const char* name, int64_t* data) {
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

time_t File::LastModified(Namespace* namespc, const char* name) {
  struct stat st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_mtime;
}

time_t File::LastAccessed(Namespace* namespc, const char* name) {
  struct stat st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_atime;
}

bool File::SetLastAccessed(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct stat st;
  if (!StatHelper(namespc, name, &st)) {
    return false;
  }

  // Set the new time:
  struct utimbuf times;
  times.actime = millis / kMillisecondsPerSecond;
  times.modtime = st.st_mtime;
  return utime(name, &times) == 0;
}

bool File::SetLastModified(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct stat st;
  if (!StatHelper(namespc, name, &st)) {
    return false;
  }

  // Set the new time:
  struct utimbuf times;
  times.actime = st.st_atime;
  times.modtime = millis / kMillisecondsPerSecond;
  return utime(name, &times) == 0;
}

const char* File::LinkTarget(Namespace* namespc,
                             const char* pathname,
                             char* dest,
                             int dest_size) {
  struct stat link_stats;
  if (lstat(pathname, &link_stats) != 0) {
    return NULL;
  }
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return NULL;
  }
  // Don't rely on the link_stats.st_size for the size of the link
  // target. The link might have changed before the readlink call.
  const int kBufferSize = 1024;
  char target[kBufferSize];
  size_t target_size =
      TEMP_FAILURE_RETRY(readlink(pathname, target, kBufferSize));
  if (target_size <= 0) {
    return NULL;
  }
  if (dest == NULL) {
    dest = DartUtils::ScopedCString(target_size + 1);
  } else {
    ASSERT(dest_size > 0);
    if ((size_t)dest_size <= target_size) {
      return NULL;
    }
  }
  memmove(dest, target, target_size);
  dest[target_size] = '\0';
  return dest;
}

bool File::IsAbsolutePath(const char* pathname) {
  return (pathname != NULL && pathname[0] == '/');
}

const char* File::GetCanonicalPath(Namespace* namespc,
                                   const char* pathname,
                                   char* dest,
                                   int dest_size) {
  char* abs_path = NULL;
  if (pathname != NULL) {
    // On some older MacOs versions the default behaviour of realpath allocating
    // space for the dest when a NULL is passed in does not seem to work, so we
    // explicitly allocate space.
    if (dest == NULL) {
      dest = DartUtils::ScopedCString(PATH_MAX + 1);
    } else {
      ASSERT(dest_size >= PATH_MAX);
    }
    do {
      abs_path = realpath(pathname, dest);
    } while ((abs_path == NULL) && (errno == EINTR));
    ASSERT((abs_path == NULL) || IsAbsolutePath(abs_path));
    ASSERT((abs_path == NULL) || (abs_path == dest));
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
  struct stat buf;
  int result = fstat(fd, &buf);
  if (result == -1) {
    return kTypeError;
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

File::Identical File::AreIdentical(Namespace* namespc_1,
                                   const char* file_1,
                                   Namespace* namespc_2,
                                   const char* file_2) {
  USE(namespc_1);
  USE(namespc_2);
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

#endif  // defined(HOST_OS_MACOS)
