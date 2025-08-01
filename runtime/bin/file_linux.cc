// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)

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
  if (!IsClosed() && (handle_->fd() != STDOUT_FILENO) &&
      (handle_->fd() != STDERR_FILENO)) {
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
    close(null_fd);
  } else {
    int err = close(handle_->fd());
    if (err != 0) {
      const int kBufferSize = 1024;
      char error_buf[kBufferSize];
      Syslog::PrintErr("%s\n", Utils::StrError(errno, error_buf, kBufferSize));
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
  void* hint = nullptr;
  int prot = PROT_NONE;
  int flags = MAP_PRIVATE;
  switch (type) {
    case kReadOnly:
      prot = PROT_READ;
      break;
    case kReadExecute:
      // Try to allocate near the VM's binary.
      hint = reinterpret_cast<void*>(&Dart_Initialize);
      prot = PROT_READ | PROT_EXEC;
      break;
    case kReadWrite:
      prot = PROT_READ | PROT_WRITE;
      break;
  }
  if (start != nullptr) {
    hint = start;
    flags |= MAP_FIXED;
  }
  void* addr = mmap(hint, length, prot, flags, handle_->fd(), position);

#if defined(DART_HOST_OS_LINUX)
  // On WSL 1 trying to allocate memory close to the binary by supplying a hint
  // fails with ENOMEM for unclear reason. Some reports suggest that this might
  // be related to the alignment of the hint but aligning it by 64Kb does not
  // make the issue go away in our experiments. Instead just retry without any
  // hint.
  if (addr == MAP_FAILED && hint != nullptr && start == nullptr &&
      Utils::IsWindowsSubsystemForLinux()) {
    addr = mmap(nullptr, length, prot, flags, handle_->fd(), position);
  }
#endif

  if (addr == MAP_FAILED) {
    return nullptr;
  }

  return new MappedMemory(addr, length, /*should_unmap=*/start == nullptr);
}

void MappedMemory::Unmap() {
  int result = munmap(address_, size_);
  ASSERT(result == 0);
  address_ = nullptr;
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
  intptr_t len = Utils::VSNPrint(nullptr, 0, format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  Utils::VSNPrint(buffer, len + 1, format, print_args);
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
  return TEMP_FAILURE_RETRY(ftruncate64(handle_->fd(), length) != -1);
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
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstat64(handle_->fd(), &st)) == 0) {
    return st.st_size;
  }
  return -1;
}

File* File::FileOpenW(const wchar_t* system_name, FileOpenMode mode) {
  UNREACHABLE();
  return nullptr;
}

File* File::OpenFD(int fd) {
  return new File(new FileHandle(fd));
}

File* File::Open(Namespace* namespc,
                 const char* name,
                 FileOpenMode mode,
                 bool executable) {
  NamespaceScope ns(namespc, name);
  // Report errors for non-regular files.
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &st, 0)) == 0) {
    // Only accept regular files, character devices, and pipes.
    if (!S_ISREG(st.st_mode) && !S_ISCHR(st.st_mode) && !S_ISFIFO(st.st_mode)) {
      errno = (S_ISDIR(st.st_mode)) ? EISDIR : ENOENT;
      return nullptr;
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
  const int fd = TEMP_FAILURE_RETRY(openat64(ns.fd(), ns.path(), flags, 0666));
  if (fd < 0) {
    return nullptr;
  }
  if ((((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) ||
      (((mode & kWriteOnly) != 0) && ((mode & kTruncate) == 0))) {
    int64_t position = NO_RETRY_EXPECTED(lseek64(fd, 0, SEEK_END));
    if (position < 0) {
      return nullptr;
    }
  }
  return OpenFD(fd);
}

CStringUniquePtr File::UriToPath(const char* uri) {
  const char* path =
      (strlen(uri) >= 8 && strncmp(uri, "file:///", 8) == 0) ? uri + 7 : uri;
  UriDecoder uri_decoder(path);
  if (uri_decoder.decoded() == nullptr) {
    errno = EINVAL;
    return CStringUniquePtr(nullptr);
  }
  return CStringUniquePtr(strdup(uri_decoder.decoded()));
}

File* File::OpenUri(Namespace* namespc,
                    const char* uri,
                    FileOpenMode mode,
                    bool executable) {
  auto path = UriToPath(uri);
  if (path == nullptr) {
    return nullptr;
  }
  return File::Open(namespc, path.get(), mode, executable);
}

File* File::OpenStdio(int fd) {
  return new File(new FileHandle(fd));
}

bool File::Exists(Namespace* namespc, const char* name) {
  NamespaceScope ns(namespc, name);
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &st, 0)) == 0) {
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

bool File::Create(Namespace* namespc, const char* name, bool exclusive) {
  NamespaceScope ns(namespc, name);
  int flags = O_RDONLY | O_CREAT | O_CLOEXEC;
  if (exclusive) {
    flags |= O_EXCL;
  }
  const int fd = TEMP_FAILURE_RETRY(openat64(ns.fd(), ns.path(), flags, 0666));
  if (fd < 0) {
    return false;
  }
  // File.create returns a File, so we shouldn't be giving the illusion that the
  // call has created a file or that a file already exists if there is already
  // an entity at the same path that is a directory or a link.
  bool is_file = true;
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstat64(fd, &st)) == 0) {
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
  NamespaceScope ns(namespc, name);
  return NO_RETRY_EXPECTED(symlinkat(target, ns.fd(), ns.path())) == 0;
}

bool File::CreatePipe(Namespace* namespc, File** readPipe, File** writePipe) {
  int pipe_fds[2];
  int status = NO_RETRY_EXPECTED(pipe(pipe_fds));
  if (status != 0) {
    return false;
  }
  *readPipe = OpenFD(pipe_fds[0]);
  *writePipe = OpenFD(pipe_fds[1]);
  return true;
}

File::Type File::GetType(Namespace* namespc,
                         const char* name,
                         bool follow_links) {
  NamespaceScope ns(namespc, name);
  struct stat64 entry_info;
  int stat_success;
  if (follow_links) {
    stat_success =
        TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &entry_info, 0));
  } else {
    stat_success = TEMP_FAILURE_RETRY(
        fstatat64(ns.fd(), ns.path(), &entry_info, AT_SYMLINK_NOFOLLOW));
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
  if (S_ISSOCK(entry_info.st_mode)) {
    return File::kIsSock;
  }
  if (S_ISFIFO(entry_info.st_mode)) {
    return File::kIsPipe;
  }
  return File::kDoesNotExist;
}

static void SetErrno(File::Type type) {
  switch (type) {
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
}

static bool CheckTypeAndSetErrno(Namespace* namespc,
                                 const char* name,
                                 File::Type expected,
                                 bool follow_links) {
  File::Type actual = File::GetType(namespc, name, follow_links);
  if (actual == expected) {
    return true;
  }
  SetErrno(actual);
  return false;
}

bool File::Delete(Namespace* namespc, const char* name) {
  File::Type type = File::GetType(namespc, name, true);
  if (type == kIsFile || type == kIsSock || type == kIsPipe) {
    NamespaceScope ns(namespc, name);
    return (NO_RETRY_EXPECTED(unlinkat(ns.fd(), ns.path(), 0)) == 0);
  }
  SetErrno(type);
  return false;
}

bool File::DeleteLink(Namespace* namespc, const char* name) {
  NamespaceScope ns(namespc, name);
  return CheckTypeAndSetErrno(namespc, name, kIsLink, false) &&
         (NO_RETRY_EXPECTED(unlinkat(ns.fd(), ns.path(), 0)) == 0);
}

bool File::Rename(Namespace* namespc,
                  const char* old_path,
                  const char* new_path) {
  File::Type type = File::GetType(namespc, old_path, true);
  if (type == kIsFile || type == kIsSock || type == kIsPipe) {
    NamespaceScope oldns(namespc, old_path);
    NamespaceScope newns(namespc, new_path);
    return (NO_RETRY_EXPECTED(renameat(oldns.fd(), oldns.path(), newns.fd(),
                                       newns.path())) == 0);
  }
  SetErrno(type);
  return false;
}

bool File::RenameLink(Namespace* namespc,
                      const char* old_path,
                      const char* new_path) {
  NamespaceScope oldns(namespc, old_path);
  NamespaceScope newns(namespc, new_path);
  return CheckTypeAndSetErrno(namespc, old_path, kIsLink, false) &&
         (NO_RETRY_EXPECTED(renameat(oldns.fd(), oldns.path(), newns.fd(),
                                     newns.path())) == 0);
}

bool File::Copy(Namespace* namespc,
                const char* old_path,
                const char* new_path) {
  File::Type type = File::GetType(namespc, old_path, true);
  if (type != kIsFile && type != kIsSock && type != kIsPipe) {
    SetErrno(type);
    return false;
  }
  NamespaceScope oldns(namespc, old_path);
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstatat64(oldns.fd(), oldns.path(), &st, 0)) != 0) {
    return false;
  }
  const int old_fd = TEMP_FAILURE_RETRY(
      openat64(oldns.fd(), oldns.path(), O_RDONLY | O_CLOEXEC));
  if (old_fd < 0) {
    return false;
  }
  NamespaceScope newns(namespc, new_path);
  const int new_fd = TEMP_FAILURE_RETRY(
      openat64(newns.fd(), newns.path(),
               O_WRONLY | O_TRUNC | O_CREAT | O_CLOEXEC, st.st_mode));
  if (new_fd < 0) {
    close(old_fd);
    return false;
  }
  int64_t offset = 0;
  intptr_t result = 1;
  while (result > 0) {
    // Loop to ensure we copy everything, and not only up to 2GB.
    result = NO_RETRY_EXPECTED(sendfile64(new_fd, old_fd, &offset, kMaxUint32));
  }
  // From sendfile man pages:
  //   Applications may wish to fall back to read(2)/write(2) in the case
  //   where sendfile() fails with EINVAL or ENOSYS.
  //
  // Also, fallback on ESPIPE (returned when the input file is not seekable).
  if ((result < 0) &&
      ((errno == EINVAL) || (errno == ENOSYS) || (errno == ESPIPE))) {
    const intptr_t kBufferSize = 8 * KB;
    uint8_t* buffer = reinterpret_cast<uint8_t*>(malloc(kBufferSize));
    while ((result = TEMP_FAILURE_RETRY(read(old_fd, buffer, kBufferSize))) >
           0) {
      int wrote = TEMP_FAILURE_RETRY(write(new_fd, buffer, result));
      if (wrote != result) {
        result = -1;
        break;
      }
    }
    free(buffer);
  }
  int e = errno;
  close(old_fd);
  close(new_fd);
  if (result < 0) {
    VOID_NO_RETRY_EXPECTED(unlinkat(newns.fd(), newns.path(), 0));
    errno = e;
    return false;
  }
  return true;
}

static bool StatHelper(Namespace* namespc,
                       const char* name,
                       struct stat64* st) {
  NamespaceScope ns(namespc, name);
  if (TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), st, 0)) != 0) {
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
  struct stat64 st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_size;
}

static int64_t TimespecToMilliseconds(const struct timespec& t) {
  return static_cast<int64_t>(t.tv_sec) * 1000L +
         static_cast<int64_t>(t.tv_nsec) / 1000000L;
}

static void MillisecondsToTimespec(int64_t millis, struct timespec* t) {
  ASSERT(t != nullptr);
  t->tv_sec = millis / kMillisecondsPerSecond;
  t->tv_nsec = (millis % kMillisecondsPerSecond) * 1000L;
}

void File::Stat(Namespace* namespc, const char* name, int64_t* data) {
  NamespaceScope ns(namespc, name);
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstatat64(ns.fd(), ns.path(), &st, 0)) == 0) {
    if (S_ISREG(st.st_mode)) {
      data[kType] = kIsFile;
    } else if (S_ISDIR(st.st_mode)) {
      data[kType] = kIsDirectory;
    } else if (S_ISLNK(st.st_mode)) {
      data[kType] = kIsLink;
    } else if (S_ISSOCK(st.st_mode)) {
      data[kType] = kIsSock;
    } else if (S_ISFIFO(st.st_mode)) {
      data[kType] = kIsPipe;
    } else {
      data[kType] = kDoesNotExist;
    }
    data[kCreatedTime] = TimespecToMilliseconds(st.st_ctim);
    data[kModifiedTime] = TimespecToMilliseconds(st.st_mtim);
    data[kAccessedTime] = TimespecToMilliseconds(st.st_atim);
    data[kMode] = st.st_mode;
    data[kSize] = st.st_size;
  } else {
    data[kType] = kDoesNotExist;
  }
}

time_t File::LastModified(Namespace* namespc, const char* name) {
  struct stat64 st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_mtime;
}

time_t File::LastAccessed(Namespace* namespc, const char* name) {
  struct stat64 st;
  if (!StatHelper(namespc, name, &st)) {
    return -1;
  }
  return st.st_atime;
}

bool File::SetLastAccessed(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct stat64 st;
  if (!StatHelper(namespc, name, &st)) {
    return false;
  }

  // Set the new time:
  NamespaceScope ns(namespc, name);
  struct timespec times[2];
  MillisecondsToTimespec(millis, &times[0]);
  times[1] = st.st_mtim;
  return utimensat(ns.fd(), ns.path(), times, 0) == 0;
}

bool File::SetLastModified(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct stat64 st;
  if (!StatHelper(namespc, name, &st)) {
    return false;
  }

  // Set the new time:
  NamespaceScope ns(namespc, name);
  struct timespec times[2];
  times[0] = st.st_atim;
  MillisecondsToTimespec(millis, &times[1]);
  return utimensat(ns.fd(), ns.path(), times, 0) == 0;
}

const char* File::LinkTarget(Namespace* namespc,
                             const char* name,
                             char* dest,
                             int dest_size) {
  NamespaceScope ns(namespc, name);
  struct stat64 link_stats;
  const int status = TEMP_FAILURE_RETRY(
      fstatat64(ns.fd(), ns.path(), &link_stats, AT_SYMLINK_NOFOLLOW));
  if (status != 0) {
    return nullptr;
  }
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return nullptr;
  }
  // Don't rely on the link_stats.st_size for the size of the link
  // target. For some filesystems, e.g. procfs, this value is always
  // 0. Also the link might have changed before the readlink call.
  const int kBufferSize = PATH_MAX + 1;
  char target[kBufferSize];
  const int target_size =
      TEMP_FAILURE_RETRY(readlinkat(ns.fd(), ns.path(), target, kBufferSize));
  if (target_size <= 0) {
    return nullptr;
  }
  if (dest == nullptr) {
    dest = DartUtils::ScopedCString(target_size + 1);
  } else {
    ASSERT(dest_size > 0);
    if (dest_size <= target_size) {
      return nullptr;
    }
  }
  memmove(dest, target, target_size);
  dest[target_size] = '\0';
  return dest;
}

bool File::IsAbsolutePath(const char* pathname) {
  return (pathname != nullptr) && (pathname[0] == '/');
}

intptr_t File::ReadLinkInto(const char* pathname,
                            char* result,
                            size_t result_size) {
  ASSERT(pathname != nullptr);
  ASSERT(IsAbsolutePath(pathname));
  struct stat64 link_stats;
  if (TEMP_FAILURE_RETRY(lstat64(pathname, &link_stats)) != 0) {
    return -1;
  }
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return -1;
  }
  size_t target_size =
      TEMP_FAILURE_RETRY(readlink(pathname, result, result_size));
  if (target_size <= 0) {
    return -1;
  }
  // readlink returns non-zero terminated strings. Append.
  if (target_size < result_size) {
    result[target_size] = '\0';
    target_size++;
  }
  return target_size;
}

const char* File::ReadLink(const char* pathname) {
  // Don't rely on the link_stats.st_size for the size of the link
  // target. For some filesystems, e.g. procfs, this value is always
  // 0. Also the link might have changed before the readlink call.
  const int kBufferSize = PATH_MAX + 1;
  char target[kBufferSize];
  size_t target_size = ReadLinkInto(pathname, target, kBufferSize);
  if (target_size <= 0) {
    return nullptr;
  }
  char* target_name = DartUtils::ScopedCString(target_size);
  ASSERT(target_name != nullptr);
  memmove(target_name, target, target_size);
  return target_name;
}

const char* File::GetCanonicalPath(Namespace* namespc,
                                   const char* name,
                                   char* dest,
                                   int dest_size) {
  if (name == nullptr) {
    return nullptr;
  }
  if (!Namespace::IsDefault(namespc)) {
    // TODO(zra): There is no realpathat(). Also chasing a symlink might result
    // in a path to something outside of the namespace, so canonicalizing paths
    // would have to be done carefully. For now, don't do anything.
    return name;
  }
  char* abs_path;
  if (dest == nullptr) {
    dest = DartUtils::ScopedCString(PATH_MAX + 1);
  } else {
    ASSERT(dest_size >= PATH_MAX);
  }
  ASSERT(dest != nullptr);
  do {
    abs_path = realpath(name, dest);
  } while ((abs_path == nullptr) && (errno == EINTR));
  ASSERT(abs_path == nullptr || IsAbsolutePath(abs_path));
  ASSERT(abs_path == nullptr || (abs_path == dest));
  return abs_path;
}

const char* File::PathSeparator() {
  return "/";
}

const char* File::StringEscapedPathSeparator() {
  return "/";
}

File::StdioHandleType File::GetStdioHandleType(int fd) {
  struct stat64 buf;
  int result = TEMP_FAILURE_RETRY(fstat64(fd, &buf));
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
  struct stat64 file_1_info;
  struct stat64 file_2_info;
  int status;
  {
    NamespaceScope ns1(namespc_1, file_1);
    status = TEMP_FAILURE_RETRY(
        fstatat64(ns1.fd(), ns1.path(), &file_1_info, AT_SYMLINK_NOFOLLOW));
    if (status == -1) {
      return File::kError;
    }
  }
  {
    NamespaceScope ns2(namespc_2, file_2);
    status = TEMP_FAILURE_RETRY(
        fstatat64(ns2.fd(), ns2.path(), &file_2_info, AT_SYMLINK_NOFOLLOW));
    if (status == -1) {
      return File::kError;
    }
  }
  return ((file_1_info.st_ino == file_2_info.st_ino) &&
          (file_1_info.st_dev == file_2_info.st_dev))
             ? File::kIdentical
             : File::kDifferent;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
