// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_FILE_H_
#define BIN_FILE_H_

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "platform/globals.h"
#include "platform/thread.h"

// Forward declaration.
class FileHandle;

class File {
 public:
  enum FileOpenMode {
    kRead = 0,
    kWrite = 1,
    kTruncate = 1 << 2,
    kWriteTruncate = kWrite | kTruncate
  };

  // These values have to be kept in sync with the mode values of
  // FileMode.READ, FileMode.WRITE and FileMode.APPEND in file.dart.
  enum DartFileOpenMode {
    kDartRead = 0,
    kDartWrite = 1,
    kDartAppend = 2
  };

  enum StdioHandleType {
    kTerminal = 0,
    kPipe = 1,
    kFile = 2,
    kSocket = 3,
    kOther = -1
  };

  enum FileRequest {
    kExistsRequest = 0,
    kCreateRequest = 1,
    kDeleteRequest = 2,
    kOpenRequest = 3,
    kFullPathRequest = 4,
    kDirectoryRequest = 5,
    kCloseRequest = 6,
    kPositionRequest = 7,
    kSetPositionRequest = 8,
    kTruncateRequest = 9,
    kLengthRequest = 10,
    kLengthFromNameRequest = 11,
    kLastModifiedRequest = 12,
    kFlushRequest = 13,
    kReadByteRequest = 14,
    kWriteByteRequest = 15,
    kReadRequest = 16,
    kReadListRequest = 17,
    kWriteListRequest = 18
  };

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

  // Set the byte position in the file.
  bool SetPosition(int64_t position);

  // Truncate (or extend) the file to the given length in bytes.
  bool Truncate(int64_t length);

  // Flush contents of file.
  bool Flush();

  // Returns whether the file has been closed.
  bool IsClosed();

  // Open the file with the given name. The file is always opened for
  // reading. If mode contains kWrite the file is opened for both
  // reading and writing. If mode contains kWrite and the file does
  // not exist the file is created. The file is truncated to length 0 if
  // mode contains kTruncate.
  static File* Open(const char* name, FileOpenMode mode);

  // Create a file object for the specified stdio file descriptor
  // (stdin, stout or stderr).
  static File* OpenStdio(int fd);

  static bool Exists(const char* name);
  static bool Create(const char* name);
  static bool Delete(const char* name);
  static off_t LengthFromName(const char* name);
  static time_t LastModified(const char* name);
  static bool IsAbsolutePath(const char* pathname);
  static char* GetCanonicalPath(const char* name);
  static char* GetContainingDirectory(char* name);
  static const char* PathSeparator();
  static const char* StringEscapedPathSeparator();
  static StdioHandleType GetStdioHandleType(int fd);

  static FileOpenMode DartModeToFileMode(DartFileOpenMode mode);

  static Dart_Port GetServicePort();

 private:
  explicit File(FileHandle* handle) : handle_(handle) { }
  void Close();

  static const int kClosedFd = -1;

  // FileHandle is an OS specific class which stores data about the file.
  FileHandle* handle_;  // OS specific handle for the file.

  static dart::Mutex mutex_;
  static int service_ports_size_;
  static Dart_Port* service_ports_;
  static int service_ports_index_;

  DISALLOW_COPY_AND_ASSIGN(File);
};

#endif  // BIN_FILE_H_
