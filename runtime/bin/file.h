// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_FILE_H_
#define RUNTIME_BIN_FILE_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/namespace.h"
#include "bin/reference_counting.h"
#include "platform/syslog.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

// Forward declaration.
class FileHandle;

class MappedMemory {
 public:
  MappedMemory(void* address, intptr_t size, bool should_unmap = true)
      : should_unmap_(should_unmap), address_(address), size_(size) {}
  ~MappedMemory() {
    if (should_unmap_) Unmap();
  }

  void* address() const { return address_; }
  intptr_t size() const { return size_; }
  uword start() const { return reinterpret_cast<uword>(address()); }

 private:
  void Unmap();

  // False for mappings which reside inside another, and will be removed when
  // the outer mapping is removed.
  bool should_unmap_;

  void* address_;
  intptr_t size_;

  DISALLOW_COPY_AND_ASSIGN(MappedMemory);
};

class File : public ReferenceCounted<File> {
 public:
  enum FileOpenMode {
    kRead = 0,
    kWrite = 1,
    kTruncate = 1 << 2,
    kWriteOnly = 1 << 3,
    kWriteTruncate = kWrite | kTruncate,
    kWriteOnlyTruncate = kWriteOnly | kTruncate
  };

  // These values have to be kept in sync with the mode values of
  // FileMode.READ, FileMode.WRITE, FileMode.APPEND,
  // FileMode.WRITE_ONLY and FileMode.WRITE_ONLY_APPEND in file.dart.
  enum DartFileOpenMode {
    kDartRead = 0,
    kDartWrite = 1,
    kDartAppend = 2,
    kDartWriteOnly = 3,
    kDartWriteOnlyAppend = 4
  };

  enum Type { kIsFile = 0, kIsDirectory = 1, kIsLink = 2, kDoesNotExist = 3 };

  enum Identical { kIdentical = 0, kDifferent = 1, kError = 2 };

  enum StdioHandleType {
    // These match the constants in stdio.dart.
    kTerminal = 0,
    kPipe = 1,
    kFile = 2,
    kSocket = 3,
    kOther = 4,
    kTypeError = 5
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

  enum LockType {
    // These match the constants in FileStat in file_impl.dart.
    kLockMin = 0,
    kLockUnlock = 0,
    kLockShared = 1,
    kLockExclusive = 2,
    kLockBlockingShared = 3,
    kLockBlockingExclusive = 4,
    kLockMax = 4
  };

  intptr_t GetFD();

  enum MapType {
    kReadOnly = 0,
    kReadExecute = 1,
    kReadWrite = 2,
  };

  /// Maps or copies the file into memory.
  ///
  /// 'position' and 'length' should be page-aligned.
  ///
  /// If 'start' is zero, allocates virtual memory for the mapping. When the
  /// returned 'MappedMemory' is destroyed, the mapping is removed.
  ///
  /// If 'start' is non-zero, it must point within a suitably sized existing
  /// mapping. The returned 'MappedMemory' will not remove the mapping when it
  /// is destroyed; rather, the mapping will be removed when the enclosing
  /// mapping is removed. This mode is not supported on Fuchsia.
  ///
  /// If 'type' is 'kReadWrite', writes to the mapping are *not* copied back to
  /// the file.
  ///
  /// 'position' + 'length' may be larger than the file size. In this case, the
  /// extra memory is zero-filled.
  MappedMemory* Map(MapType type,
                    int64_t position,
                    int64_t length,
                    void* start = nullptr);

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
  bool WriteByte(uint8_t byte) { return WriteFully(&byte, 1); }

  bool Print(const char* format, ...) PRINTF_ATTRIBUTE(2, 3) {
    va_list args;
    va_start(args, format);
    bool result = VPrint(format, args);
    va_end(args);
    return result;
  }
  bool VPrint(const char* format, va_list args);

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

  // Lock range of a file.
  bool Lock(LockType lock, int64_t start, int64_t end);

  // Returns whether the file has been closed.
  bool IsClosed();

  // Calls the platform-specific functions to close the file.
  void Close();

  // Returns the finalizable handle for the File's Dart wrapper.
  Dart_FinalizableHandle FinalizableHandle() const {
    return finalizable_handle_;
  }

  // Set the finalizable handle for the File's Dart wrapper.
  void SetFinalizableHandle(Dart_FinalizableHandle handle) {
    ASSERT(finalizable_handle_ == NULL);
    finalizable_handle_ = handle;
  }

  // Deletes the finalizable handle for the File's Dart wrapper. Call
  // when the file is explicitly closed and the finalizer is no longer
  // needed.
  void DeleteFinalizableHandle(Dart_Isolate isolate, Dart_Handle strong_ref) {
    Dart_DeleteFinalizableHandle(finalizable_handle_, strong_ref);
    finalizable_handle_ = NULL;
  }

  // Open the file with the given path. The file is always opened for
  // reading. If mode contains kWrite the file is opened for both
  // reading and writing. If mode contains kWrite and the file does
  // not exist the file is created. The file is truncated to length 0 if
  // mode contains kTruncate.
  static File* Open(Namespace* namespc, const char* path, FileOpenMode mode);

  // Same as [File::Open], but attempts to convert uri to path before opening
  // the file. If conversion fails, uri is treated as a path.
  static File* OpenUri(Namespace* namespc, const char* uri, FileOpenMode mode);

  // Attempts to convert the given [uri] to a file path.
  static Utils::CStringUniquePtr UriToPath(const char* uri);

  // Create a file object for the specified stdio file descriptor
  // (stdin, stout or stderr).
  static File* OpenStdio(int fd);

#if defined(HOST_OS_FUCHSIA) || defined(HOST_OS_LINUX)
  static File* OpenFD(int fd);
#endif

  static bool Exists(Namespace* namespc, const char* path);
  static bool ExistsUri(Namespace* namespc, const char* uri);
  static bool Create(Namespace* namespc, const char* path);
  static bool CreateLink(Namespace* namespc,
                         const char* path,
                         const char* target);
  static bool Delete(Namespace* namespc, const char* path);
  static bool DeleteLink(Namespace* namespc, const char* path);
  static bool Rename(Namespace* namespc,
                     const char* old_path,
                     const char* new_path);
  static bool RenameLink(Namespace* namespc,
                         const char* old_path,
                         const char* new_path);
  static bool Copy(Namespace* namespc,
                   const char* old_path,
                   const char* new_path);
  static int64_t LengthFromPath(Namespace* namespc, const char* path);
  static void Stat(Namespace* namespc, const char* path, int64_t* data);
  static time_t LastModified(Namespace* namespc, const char* path);
  static bool SetLastModified(Namespace* namespc,
                              const char* path,
                              int64_t millis);
  static time_t LastAccessed(Namespace* namespc, const char* path);
  static bool SetLastAccessed(Namespace* namespc,
                              const char* path,
                              int64_t millis);
  static bool IsAbsolutePath(const char* path);
  static const char* PathSeparator();
  static const char* StringEscapedPathSeparator();
  static Type GetType(Namespace* namespc, const char* path, bool follow_links);
  static Identical AreIdentical(Namespace* namespc_1,
                                const char* file_1,
                                Namespace* namespc_2,
                                const char* file_2);
  static StdioHandleType GetStdioHandleType(int fd);

  // LinkTarget, GetCanonicalPath, and ReadLink may call Dart_ScopeAllocate.
  // If dest and its size are provided, Dart String will not be created.
  // The result will be populated into dest.
  static const char* LinkTarget(Namespace* namespc,
                                const char* pathname,
                                char* dest = nullptr,
                                int dest_size = 0);
  static const char* GetCanonicalPath(Namespace* namespc,
                                      const char* path,
                                      char* dest = nullptr,
                                      int dest_size = 0);
  // Link LinkTarget, but pathname must be absolute.
  static const char* ReadLink(const char* pathname);
  static intptr_t ReadLinkInto(const char* pathname,
                               char* result,
                               size_t result_size);

  // Cleans an input path, transforming it to out, according to the rules
  // defined by "Lexical File Names in Plan 9 or Getting Dot-Dot Right",
  // accessible at: https://9p.io/sys/doc/lexnames.html.
  // Returns -1 if out isn't big enough, and the length of out otherwise.
  static intptr_t CleanUnixPath(const char* in, char* out, intptr_t outlen);

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
  static CObject* SetLastModifiedRequest(const CObjectArray& request);
  static CObject* LastAccessedRequest(const CObjectArray& request);
  static CObject* SetLastAccessedRequest(const CObjectArray& request);
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
  static CObject* LockRequest(const CObjectArray& request);

 private:
  explicit File(FileHandle* handle)
      : ReferenceCounted(), handle_(handle), finalizable_handle_(NULL) {}

  ~File();

  static File* FileOpenW(const wchar_t* system_name, FileOpenMode mode);

  static const int kClosedFd = -1;

  // FileHandle is an OS specific class which stores data about the file.
  FileHandle* handle_;  // OS specific handle for the file.

  // We retain the finalizable handle because we can do cleanup eagerly when
  // Dart code calls closeSync(). In that case, we delete the finalizable
  // handle so that the finalizer doesn't run.
  Dart_FinalizableHandle finalizable_handle_;

  friend class ReferenceCounted<File>;
  DISALLOW_COPY_AND_ASSIGN(File);
};

class UriDecoder {
 public:
  explicit UriDecoder(const char* uri);
  ~UriDecoder();

  const char* decoded() const { return decoded_; }

 private:
  bool HexCharPairToByte(const char* pch, char* dest);

  char* decoded_;
  const char* uri_;

  DISALLOW_COPY_AND_ASSIGN(UriDecoder);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_FILE_H_
