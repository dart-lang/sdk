// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <fcntl.h>
#include <io.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "bin/builtin.h"
#include "bin/file.h"

class FileHandle {
 public:
  explicit FileHandle(int fd) : fd_(fd) { }
  ~FileHandle() { }
  int fd() const { return fd_; }
  void set_fd(int fd) { fd_ = fd; }

 private:
  int fd_;

  // DISALLOW_COPY_AND_ASSIGN(FileHandle).
  FileHandle(const FileHandle&);
  void operator=(const FileHandle&);
};


File::~File() {
  // Close the file (unless it's a standard stream).
  if (handle_->fd() > 2) {
    Close();
  }
  delete handle_;
}


void File::Close() {
  assert(handle_->fd() >= 0);
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
  assert(handle_->fd() >= 0);
  return read(handle_->fd(), buffer, num_bytes);
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  assert(handle_->fd() >= 0);
  return write(handle_->fd(), buffer, num_bytes);
}


off_t File::Position() {
  assert(handle_->fd() >= 0);
  return lseek(handle_->fd(), 0, SEEK_CUR);
}


void File::Flush() {
  assert(handle_->fd());
  _commit(handle_->fd());
}


off_t File::Length() {
  assert(handle_->fd() >= 0);
  off_t position = lseek(handle_->fd(), 0, SEEK_CUR);
  if (position < 0) {
    // The file is not capable of seeking. Return an error.
    return -1;
  }
  off_t result = lseek(handle_->fd(), 0, SEEK_END);
  lseek(handle_->fd(), position, SEEK_SET);
  return result;
}


File* File::OpenFile(const char* name, bool writable) {
  int flags = O_RDONLY | O_BINARY;
  if (writable) {
    flags = (O_RDWR | O_CREAT | O_TRUNC | O_BINARY);
  }
  int fd = open(name, flags, 0666);
  if (fd < 0) {
    return NULL;
  }
  return new File(name, new FileHandle(fd));
}


bool File::FileExists(const char* name) {
  struct stat st;
  if (stat(name, &st) == 0) {
    return ((st.st_mode & S_IFMT) == S_IFREG);
  } else {
    return false;
  }
}


bool File::IsAbsolutePath(const char* pathname) {
  // Should we consider network paths?
  if (pathname == NULL) return false;
  return (strlen(pathname) > 2) &&
      (pathname[1] == ':') &&
      (pathname[2] == '\\');
}


const char* File::PathSeparator() {
  return "\\";
}


const char* File::StringEscapedPathSeparator() {
  return "\\\\";
}
