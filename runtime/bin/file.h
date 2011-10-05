// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_FILE_H_
#define BIN_FILE_H_

#if defined(_WIN32)
typedef signed __int64 int64_t;
typedef unsigned __int8 uint8_t;
#else
#include <stdint.h>
#endif

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

// Forward declaration.
class FileHandle;

class File {
 public:
  ~File();

  // Read/Write attempt to transfer num_bytes to/from buffer. It returns
  // the number of bytes read/written.
  int64_t Read(void* buffer, int64_t num_bytes);
  int64_t Write(const void* buffer, int64_t num_bytes);

  // ReadFully and WriteFully do attempt to transfer num_bytes to/from
  // the buffer. In the event of short accesses they will loop internally until
  // the whole buffer has been transferred or an error occurs. If an error
  // occurred the result will be set to false.
  bool ReadFully(void* buffer, int64_t num_bytes);
  bool WriteFully(const void* buffer, int64_t num_bytes);
  bool WriteByte(uint8_t byte) {
    return WriteFully(&byte, 1);
  }

  // Get the length of the file. Returns a negative value if the length cannot
  // be determined (e.g. not seekable device).
  off_t Length();

  // Get the current position in the file.
  // Returns a negative value if position cannot be determined.
  off_t Position();

  // Flush contents of file.
  void Flush();

  const char* name() const { return name_; }

  static File* OpenFile(const char* name, bool writable);
  static bool FileExists(const char* name);
  static bool IsAbsolutePath(const char* pathname);
  static const char* PathSeparator();
  static const char* StringEscapedPathSeparator();

 private:
  File(const char* name, FileHandle* handle) : name_(name), handle_(handle) { }
  void Close();
  bool IsClosed();

  static const int kClosedFd = -1;

  const char* name_;
  // FileHandle is an OS specific class which stores data about the file.
  FileHandle* handle_;  // OS specific handle for the file.

  // DISALLOW_COPY_AND_ASSIGN(File).
  File(const File&);
  void operator=(const File&);
};

#endif  // BIN_FILE_H_
