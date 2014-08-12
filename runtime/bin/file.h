// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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


namespace dart {
namespace bin {

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

  enum Type {
    kIsFile = 0,
    kIsDirectory = 1,
    kIsLink = 2,
    kDoesNotExist = 3
  };

  enum Identical {
    kIdentical = 0,
    kDifferent = 1,
    kError = 2
  };

  enum StdioHandleType {
    kTerminal = 0,
    kPipe = 1,
    kFile = 2,
    kSocket = 3,
    kOther = 4
  };

  enum FileStat {
    // These match the constants in FileStat in file_system_entity.dart.
    kType = 0,
    kCreatedTime = 1,
    kModifiedTime = 2,
    kAccessedTime = 3,
    kMode = 4,
    kSize = 5,
    kStatSize = 6
  };

  ~File();

  intptr_t GetFD();

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
  int64_t Length();

  // Get the current position in the file.
  // Returns a negative value if position cannot be determined.
  int64_t Position();

  // Set the byte position in the file.
  bool SetPosition(int64_t position);

  // Truncate (or extend) the file to the given length in bytes.
  bool Truncate(int64_t length);

  // Flush contents of file.
  bool Flush();

  // Returns whether the file has been closed.
  bool IsClosed();

  // Open the file with the given path. The file is always opened for
  // reading. If mode contains kWrite the file is opened for both
  // reading and writing. If mode contains kWrite and the file does
  // not exist the file is created. The file is truncated to length 0 if
  // mode contains kTruncate.
  static File* Open(const char* path, FileOpenMode mode);

  // Create a file object for the specified stdio file descriptor
  // (stdin, stout or stderr).
  static File* OpenStdio(int fd);

  static bool Exists(const char* path);
  static bool Create(const char* path);
  static bool CreateLink(const char* path, const char* target);
  static bool Delete(const char* path);
  static bool DeleteLink(const char* path);
  static bool Rename(const char* old_path, const char* new_path);
  static bool RenameLink(const char* old_path, const char* new_path);
  static bool Copy(const char* old_path, const char* new_path);
  static int64_t LengthFromPath(const char* path);
  static void Stat(const char* path, int64_t* data);
  static time_t LastModified(const char* path);
  static char* LinkTarget(const char* pathname);
  static bool IsAbsolutePath(const char* path);
  static char* GetCanonicalPath(const char* path);
  static const char* PathSeparator();
  static const char* StringEscapedPathSeparator();
  static Type GetType(const char* path, bool follow_links);
  static Identical AreIdentical(const char* file_1, const char* file_2);
  static StdioHandleType GetStdioHandleType(int fd);

  static FileOpenMode DartModeToFileMode(DartFileOpenMode mode);

  static CObject* ExistsRequest(const CObjectArray& request);
  static CObject* CreateRequest(const CObjectArray& request);
  static CObject* DeleteRequest(const CObjectArray& request);
  static CObject* RenameRequest(const CObjectArray& request);
  static CObject* CopyRequest(const CObjectArray& request);
  static CObject* OpenRequest(const CObjectArray& request);
  static CObject* ResolveSymbolicLinksRequest(const CObjectArray& request);
  static CObject* CloseRequest(const CObjectArray& request);
  static CObject* PositionRequest(const CObjectArray& request);
  static CObject* SetPositionRequest(const CObjectArray& request);
  static CObject* TruncateRequest(const CObjectArray& request);
  static CObject* LengthRequest(const CObjectArray& request);
  static CObject* LengthFromPathRequest(const CObjectArray& request);
  static CObject* LastModifiedRequest(const CObjectArray& request);
  static CObject* FlushRequest(const CObjectArray& request);
  static CObject* ReadByteRequest(const CObjectArray& request);
  static CObject* WriteByteRequest(const CObjectArray& request);
  static CObject* ReadRequest(const CObjectArray& request);
  static CObject* ReadIntoRequest(const CObjectArray& request);
  static CObject* WriteFromRequest(const CObjectArray& request);
  static CObject* CreateLinkRequest(const CObjectArray& request);
  static CObject* DeleteLinkRequest(const CObjectArray& request);
  static CObject* RenameLinkRequest(const CObjectArray& request);
  static CObject* LinkTargetRequest(const CObjectArray& request);
  static CObject* TypeRequest(const CObjectArray& request);
  static CObject* IdenticalRequest(const CObjectArray& request);
  static CObject* StatRequest(const CObjectArray& request);

 private:
  explicit File(FileHandle* handle) : handle_(handle) { }
  void Close();

  static const int kClosedFd = -1;

  // FileHandle is an OS specific class which stores data about the file.
  FileHandle* handle_;  // OS specific handle for the file.

  DISALLOW_COPY_AND_ASSIGN(File);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_FILE_H_
