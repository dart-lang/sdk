// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include <fcntl.h>
#include <io.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "bin/builtin.h"
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
  if (handle_->fd() > 2) {
    Close();
  }
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  int err = close(handle_->fd());
  if (err != 0) {
    Log::PrintErr("%s\n", strerror(errno));
  }
  handle_->set_fd(kClosedFd);
}


bool File::IsClosed() {
  return handle_->fd() == kClosedFd;
}


int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return read(handle_->fd(), buffer, num_bytes);
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return write(handle_->fd(), buffer, num_bytes);
}


off_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return lseek(handle_->fd(), 0, SEEK_CUR);
}


bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  return (lseek(handle_->fd(), position, SEEK_SET) != -1);
}


bool File::Truncate(int64_t length) {
  ASSERT(handle_->fd() >= 0);
  return (chsize(handle_->fd(), length) != -1);
}


bool File::Flush() {
  ASSERT(handle_->fd());
  return _commit(handle_->fd()) != -1;
}


off_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct stat st;
  if (fstat(handle_->fd(), &st) == 0) {
    return st.st_size;
  }
  return -1;
}


File* File::Open(const char* name, FileOpenMode mode) {
  int flags = O_RDONLY | O_BINARY | O_NOINHERIT;
  if ((mode & kWrite) != 0) {
    flags = (O_RDWR | O_CREAT | O_BINARY | O_NOINHERIT);
  }
  if ((mode & kTruncate) != 0) {
    flags = flags | O_TRUNC;
  }
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  int fd = open(system_name, flags, 0666);
  free(const_cast<char*>(system_name));
  if (fd < 0) {
    return NULL;
  }
  if (((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) {
    int position = lseek(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}


File* File::OpenStdio(int fd) {
  UNREACHABLE();
  return NULL;
}


bool File::Exists(const char* name) {
  struct stat st;
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  bool stat_status = stat(system_name, &st);
  free(const_cast<char*>(system_name));
  if (stat_status == 0) {
    return ((st.st_mode & S_IFMT) == S_IFREG);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  int fd = open(system_name, O_RDONLY | O_CREAT, 0666);
  free(const_cast<char*>(system_name));
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}


bool File::Delete(const char* name) {
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  int status = remove(system_name);
  free(const_cast<char*>(system_name));
  if (status == -1) {
    return false;
  }
  return true;
}


off_t File::LengthFromName(const char* name) {
  struct stat st;
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  int stat_status = stat(system_name, &st);
  free(const_cast<char*>(system_name));
  if (stat_status == 0) {
    return st.st_size;
  }
  return -1;
}


time_t File::LastModified(const char* name) {
  struct stat st;
  const char* system_name = StringUtils::Utf8ToSystemString(name);
  int stat_status = stat(system_name, &st);
  free(const_cast<char*>(system_name));
  if (stat_status == 0) {
    return st.st_mtime;
  }
  return -1;
}


bool File::IsAbsolutePath(const char* pathname) {
  // Should we consider network paths?
  if (pathname == NULL) return false;
  return (strlen(pathname) > 2) &&
      (pathname[1] == ':') &&
      (pathname[2] == '\\' || pathname[2] == '/');
}


char* File::GetCanonicalPath(const char* pathname) {
  struct stat st;
  const char* system_name = StringUtils::Utf8ToSystemString(pathname);
  int stat_status = stat(system_name, &st);
  if (stat_status != 0) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    free(const_cast<char*>(system_name));
    return NULL;
  }
  int required_size = GetFullPathName(system_name, 0, NULL, NULL);
  char* path = static_cast<char*>(malloc(required_size));
  int written = GetFullPathName(system_name, required_size, path, NULL);
  free(const_cast<char*>(system_name));
  ASSERT(written == (required_size - 1));
  char* result = StringUtils::SystemStringToUtf8(path);
  free(path);
  return result;
}


char* File::GetContainingDirectory(char* pathname) {
  struct stat st;
  char* system_name = StringUtils::Utf8ToSystemString(pathname);
  int stat_status = stat(system_name, &st);
  if (stat_status == 0) {
    if ((st.st_mode & S_IFMT) != S_IFREG) {
      SetLastError(ERROR_FILE_NOT_FOUND);
      free(system_name);
      return NULL;
    }
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
    free(system_name);
    return NULL;
  }
  int required_size = GetFullPathName(system_name, 0, NULL, NULL);
  char* path = static_cast<char*>(malloc(required_size));
  char* file_part = NULL;
  int written =
    GetFullPathName(system_name, required_size, path, &file_part);
  free(system_name);
  ASSERT(written == (required_size - 1));
  ASSERT(file_part != NULL);
  ASSERT(file_part > path);
  ASSERT(file_part[-1] == '\\');
  file_part[-1] = '\0';
  char* result = StringUtils::SystemStringToUtf8(path);
  free(path);
  return result;
}


const char* File::PathSeparator() {
  return "\\";
}


const char* File::StringEscapedPathSeparator() {
  return "\\\\";
}


File::StdioHandleType File::GetStdioHandleType(int fd) {
  // Treat all stdio handles as pipes. The Windows event handler and
  // socket code will handle the different handle types.
  return kPipe;
}
