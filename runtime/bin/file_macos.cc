// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/file.h"

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <libgen.h>  // NOLINT
#include <limits.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/fdutils.h"
#include "bin/log.h"

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
  // Close the file (unless it's a standard stream).
  if (handle_->fd() > STDERR_FILENO) {
    Close();
  }
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  int err = TEMP_FAILURE_RETRY(close(handle_->fd()));
  if (err != 0) {
    const int kBufferSize = 1024;
    char error_message[kBufferSize];
    strerror_r(errno, error_message, kBufferSize);
    Log::PrintErr("%s\n", error_message);
  }
  handle_->set_fd(kClosedFd);
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


off_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(lseek(handle_->fd(), 0, SEEK_CUR));
}


bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(lseek(handle_->fd(), position, SEEK_SET) != -1);
}


bool File::Truncate(int64_t length) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(ftruncate(handle_->fd(), length) != -1);
}


bool File::Flush() {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(fsync(handle_->fd()) != -1);
}


off_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct stat st;
  if (TEMP_FAILURE_RETRY(fstat(handle_->fd(), &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


File* File::Open(const char* name, FileOpenMode mode) {
  // Report errors for non-regular files.
  struct stat st;
  if (TEMP_FAILURE_RETRY(stat(name, &st)) == 0) {
    // Only accept regular files and character devices.
    if (!S_ISREG(st.st_mode) && !S_ISCHR(st.st_mode)) {
      errno = (S_ISDIR(st.st_mode)) ? EISDIR : ENOENT;
      return NULL;
    }
  }
  int flags = O_RDONLY;
  if ((mode & kWrite) != 0) {
    flags = (O_RDWR | O_CREAT);
  }
  if ((mode & kTruncate) != 0) {
    flags = flags | O_TRUNC;
  }
  int fd = TEMP_FAILURE_RETRY(open(name, flags, 0666));
  if (fd < 0) {
    return NULL;
  }
  FDUtils::SetCloseOnExec(fd);
  if (((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) {
    int position = TEMP_FAILURE_RETRY(lseek(fd, 0, SEEK_END));
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
  if (TEMP_FAILURE_RETRY(stat(name, &st)) == 0) {
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
  int status = TEMP_FAILURE_RETRY(symlink(target, name));
  return (status == 0);
}


bool File::Delete(const char* name) {
  File::Type type = File::GetType(name, true);
  if (type == kIsFile) {
    return TEMP_FAILURE_RETRY(unlink(name)) == 0;
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
    return TEMP_FAILURE_RETRY(unlink(name)) == 0;
  }
  errno = EINVAL;
  return false;
}


off_t File::LengthFromPath(const char* name) {
  struct stat st;
  if (TEMP_FAILURE_RETRY(stat(name, &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


time_t File::LastModified(const char* name) {
  struct stat st;
  if (TEMP_FAILURE_RETRY(stat(name, &st)) == 0) {
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
  size_t target_size = link_stats.st_size;
  char* target_name = reinterpret_cast<char*>(malloc(target_size + 1));
  size_t read_size = readlink(pathname, target_name, target_size + 1);
  if (read_size != target_size) {
    free(target_name);
    return NULL;
  }
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


char* File::GetContainingDirectory(char* pathname) {
  // Report errors for non-regular files.
  struct stat st;
  if (TEMP_FAILURE_RETRY(stat(pathname, &st)) == 0) {
    if (!S_ISREG(st.st_mode)) {
      errno = (S_ISDIR(st.st_mode)) ? EISDIR : ENOENT;
      return NULL;
    }
  } else {
    return NULL;
  }
  char* path = NULL;
  do {
    path = dirname(pathname);
  } while (path == NULL && errno == EINTR);
  return GetCanonicalPath(path);
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
    FATAL2("Failed stat on file descriptor %d: %s", fd, strerror(errno));
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
    stat_success = TEMP_FAILURE_RETRY(stat(pathname, &entry_info));
  } else {
    stat_success = TEMP_FAILURE_RETRY(lstat(pathname, &entry_info));
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
  if (TEMP_FAILURE_RETRY(lstat(file_1, &file_1_info)) == -1 ||
      TEMP_FAILURE_RETRY(lstat(file_2, &file_2_info)) == -1) {
    return File::kError;
  }
  return (file_1_info.st_ino == file_2_info.st_ino &&
          file_1_info.st_dev == file_2_info.st_dev) ?
      File::kIdentical :
      File::kDifferent;
}

#endif  // defined(TARGET_OS_MACOS)
