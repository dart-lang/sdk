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
    fprintf(stderr, "%s\n", strerror(errno));
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
  int fd = open(name, flags, 0666);
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
  if (stat(name, &st) == 0) {
    return ((st.st_mode & S_IFMT) == S_IFREG);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  int fd = open(name, O_RDONLY | O_CREAT, 0666);
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}


bool File::Delete(const char* name) {
  int status = remove(name);
  if (status == -1) {
    return false;
  }
  return true;
}


off_t File::LengthFromName(const char* name) {
  struct stat st;
  if (stat(name, &st) == 0) {
    return st.st_size;
  }
  return -1;
}


time_t File::LastModified(const char* name) {
  struct stat st;
  if (stat(name, &st) == 0) {
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
  if (stat(pathname, &st) != 0) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return NULL;
  }
  int required_size = GetFullPathName(pathname, 0, NULL, NULL);
  char* path = static_cast<char*>(malloc(required_size));
  int written = GetFullPathName(pathname, required_size, path, NULL);
  ASSERT(written == (required_size - 1));
  return path;
}


char* File::GetContainingDirectory(char* pathname) {
  struct stat st;
  if (stat(pathname, &st) == 0) {
    if ((st.st_mode & S_IFMT) != S_IFREG) {
      SetLastError(ERROR_FILE_NOT_FOUND);
      return NULL;
    }
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return NULL;
  }
  int required_size = GetFullPathName(pathname, 0, NULL, NULL);
  char* path = static_cast<char*>(malloc(required_size));
  char* file_part = NULL;
  int written = GetFullPathName(pathname, required_size, path, &file_part);
  ASSERT(written == (required_size - 1));
  ASSERT(file_part != NULL);
  ASSERT(file_part > path);
  ASSERT(file_part[-1] == '\\');
  file_part[-1] = '\0';
  return path;
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
