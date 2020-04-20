// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/file.h"

#include <WinIoCtl.h>  // NOLINT
#include <fcntl.h>     // NOLINT
#include <io.h>        // NOLINT
#include <Shlwapi.h>   // NOLINT
#include <stdio.h>     // NOLINT
#include <string.h>    // NOLINT
#include <sys/stat.h>  // NOLINT
#include <sys/utime.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/directory.h"
#include "bin/namespace.h"
#include "bin/utils.h"
#include "bin/utils_win.h"
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
  if (!IsClosed() && handle_->fd() != _fileno(stdout) &&
      handle_->fd() != _fileno(stderr)) {
    Close();
  }
  delete handle_;
}

void File::Close() {
  ASSERT(handle_->fd() >= 0);
  int closing_fd = handle_->fd();
  if ((closing_fd == _fileno(stdout)) || (closing_fd == _fileno(stderr))) {
    int fd = _open("NUL", _O_WRONLY);
    ASSERT(fd >= 0);
    _dup2(fd, closing_fd);
    close(fd);
  } else {
    int err = close(closing_fd);
    if (err != 0) {
      Syslog::PrintErr("%s\n", strerror(errno));
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

MappedMemory* File::Map(File::MapType type,
                        int64_t position,
                        int64_t length,
                        void* start) {
  DWORD prot_alloc;
  DWORD prot_final;
  switch (type) {
    case File::kReadOnly:
      prot_alloc = PAGE_READWRITE;
      prot_final = PAGE_READONLY;
      break;
    case File::kReadExecute:
      prot_alloc = PAGE_EXECUTE_READWRITE;
      prot_final = PAGE_EXECUTE_READ;
      break;
    case File::kReadWrite:
      prot_alloc = PAGE_READWRITE;
      prot_final = PAGE_READWRITE;
      break;
  }

  void* addr = start;
  if (addr == nullptr) {
    addr = VirtualAlloc(nullptr, length, MEM_COMMIT | MEM_RESERVE, prot_alloc);
    if (addr == nullptr) {
      Syslog::PrintErr("VirtualAlloc failed %d\n", GetLastError());
      return nullptr;
    }
  }

  const int64_t remaining_length = Length() - position;
  SetPosition(position);
  if (!ReadFully(addr, Utils::Minimum(length, remaining_length))) {
    Syslog::PrintErr("ReadFully failed %d\n", GetLastError());
    if (start == nullptr) {
      VirtualFree(addr, 0, MEM_RELEASE);
    }
    return nullptr;
  }

  // If the requested mapping is larger than the file size, we should fill the
  // extra memory with zeros.
  if (length > remaining_length) {
    memset(reinterpret_cast<uint8_t*>(addr) + remaining_length, 0,
           length - remaining_length);
  }

  DWORD old_prot;
  bool result = VirtualProtect(addr, length, prot_final, &old_prot);
  if (!result) {
    Syslog::PrintErr("VirtualProtect failed %d\n", GetLastError());
    if (start == nullptr) {
      VirtualFree(addr, 0, MEM_RELEASE);
    }
    return nullptr;
  }
  return new MappedMemory(addr, length, /*should_unmap=*/start == nullptr);
}

void MappedMemory::Unmap() {
  BOOL result = VirtualFree(address_, 0, MEM_RELEASE);
  ASSERT(result);
  address_ = 0;
  size_ = 0;
}

int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return read(handle_->fd(), buffer, num_bytes);
}

int64_t File::Write(const void* buffer, int64_t num_bytes) {
  int fd = handle_->fd();
  // Avoid narrowing conversion
  ASSERT(fd >= 0 && num_bytes <= MAXDWORD && num_bytes >= 0);
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(fd));
  DWORD written = 0;
  BOOL result = WriteFile(handle, buffer, num_bytes, &written, NULL);
  if (!result) {
    return -1;
  }
  DWORD mode;
  int64_t bytes_written = written;
  if (GetConsoleMode(handle, &mode)) {
    // If `handle` is for a console, then `written` may refer to the number of
    // characters printed to the screen rather than the number of bytes of the
    // buffer that were actually consumed. To compute the number of bytes that
    // were actually consumed, we convert the buffer to a wchar_t using the
    // console's current code page, filling as many characters as were
    // printed, and then convert that many characters back to the encoding for
    // the code page, which gives the number of bytes of `buffer` used to
    // generate the characters that were printed.
    wchar_t* wide = new wchar_t[written];
    int cp = GetConsoleOutputCP();
    MultiByteToWideChar(cp, 0, reinterpret_cast<const char*>(buffer), -1, wide,
                        written);
    int buffer_len =
        WideCharToMultiByte(cp, 0, wide, written, NULL, 0, NULL, NULL);
    delete[] wide;
    bytes_written = buffer_len;
  }
  return bytes_written;
}

bool File::VPrint(const char* format, va_list args) {
  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = _vscprintf(format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  _vsnprintf(buffer, len + 1, format, print_args);
  va_end(print_args);

  bool result = WriteFully(buffer, len);
  free(buffer);
  return result;
}

int64_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return _lseeki64(handle_->fd(), 0, SEEK_CUR);
}

bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  return _lseeki64(handle_->fd(), position, SEEK_SET) >= 0;
}

bool File::Truncate(int64_t length) {
  ASSERT(handle_->fd() >= 0);
  return _chsize_s(handle_->fd(), length) == 0;
}

bool File::Flush() {
  ASSERT(handle_->fd());
  return _commit(handle_->fd()) != -1;
}

bool File::Lock(File::LockType lock, int64_t start, int64_t end) {
  ASSERT(handle_->fd() >= 0);
  ASSERT((end == -1) || (end > start));
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(handle_->fd()));
  OVERLAPPED overlapped;
  ZeroMemory(&overlapped, sizeof(OVERLAPPED));

  overlapped.Offset = Utils::Low32Bits(start);
  overlapped.OffsetHigh = Utils::High32Bits(start);

  int64_t length = end == -1 ? 0 : end - start;
  if (length == 0) {
    length = kMaxInt64;
  }
  int32_t length_low = Utils::Low32Bits(length);
  int32_t length_high = Utils::High32Bits(length);

  BOOL rc;
  switch (lock) {
    case File::kLockUnlock:
      rc = UnlockFileEx(handle, 0, length_low, length_high, &overlapped);
      break;
    case File::kLockShared:
    case File::kLockExclusive:
    case File::kLockBlockingShared:
    case File::kLockBlockingExclusive: {
      DWORD flags = 0;
      if ((lock == File::kLockShared) || (lock == File::kLockExclusive)) {
        flags |= LOCKFILE_FAIL_IMMEDIATELY;
      }
      if ((lock == File::kLockExclusive) ||
          (lock == File::kLockBlockingExclusive)) {
        flags |= LOCKFILE_EXCLUSIVE_LOCK;
      }
      rc = LockFileEx(handle, flags, 0, length_low, length_high, &overlapped);
      break;
    }
    default:
      UNREACHABLE();
  }
  return rc;
}

int64_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct __stat64 st;
  if (_fstat64(handle_->fd(), &st) == 0) {
    return st.st_size;
  }
  return -1;
}

File* File::FileOpenW(const wchar_t* system_name, FileOpenMode mode) {
  int flags = O_RDONLY | O_BINARY | O_NOINHERIT;
  if ((mode & kWrite) != 0) {
    ASSERT((mode & kWriteOnly) == 0);
    flags = (O_RDWR | O_CREAT | O_BINARY | O_NOINHERIT);
  }
  if ((mode & kWriteOnly) != 0) {
    ASSERT((mode & kWrite) == 0);
    flags = (O_WRONLY | O_CREAT | O_BINARY | O_NOINHERIT);
  }
  if ((mode & kTruncate) != 0) {
    flags = flags | O_TRUNC;
  }
  int fd = _wopen(system_name, flags, 0666);
  if (fd < 0) {
    return NULL;
  }
  if ((((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) ||
      (((mode & kWriteOnly) != 0) && ((mode & kTruncate) == 0))) {
    int64_t position = _lseeki64(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}

File* File::Open(Namespace* namespc, const char* path, FileOpenMode mode) {
  Utf8ToWideScope system_name(path);
  File* file = FileOpenW(system_name.wide(), mode);
  return file;
}

File* File::OpenUri(Namespace* namespc, const char* uri, FileOpenMode mode) {
  UriDecoder uri_decoder(uri);
  if (uri_decoder.decoded() == NULL) {
    SetLastError(ERROR_INVALID_NAME);
    return NULL;
  }

  Utf8ToWideScope uri_w(uri_decoder.decoded());
  if (!UrlIsFileUrlW(uri_w.wide())) {
    return FileOpenW(uri_w.wide(), mode);
  }
  wchar_t filename_w[MAX_PATH];
  DWORD filename_len = MAX_PATH;
  HRESULT result = PathCreateFromUrlW(uri_w.wide(),
      filename_w, &filename_len, /* dwFlags= */ NULL);
  return (result == S_OK) ? FileOpenW(filename_w, mode) : NULL;
}

File* File::OpenStdio(int fd) {
  int stdio_fd = -1;
  switch (fd) {
    case 1:
      stdio_fd = _fileno(stdout);
      break;
    case 2:
      stdio_fd = _fileno(stderr);
      break;
    default:
      UNREACHABLE();
  }
  _setmode(stdio_fd, _O_BINARY);
  return new File(new FileHandle(stdio_fd));
}

static bool StatHelper(wchar_t* path, struct __stat64* st) {
  int stat_status = _wstat64(path, st);
  if (stat_status != 0) {
    return false;
  }
  if ((st->st_mode & S_IFMT) != S_IFREG) {
    SetLastError(ERROR_NOT_SUPPORTED);
    return false;
  }
  return true;
}

bool File::Exists(Namespace* namespc, const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  return StatHelper(system_name.wide(), &st);
}

bool File::ExistsUri(Namespace* namespc, const char* uri) {
  UriDecoder uri_decoder(uri);
  if (uri_decoder.decoded() == nullptr) {
    SetLastError(ERROR_INVALID_NAME);
    return false;
  }
  return File::Exists(namespc, uri_decoder.decoded());
}

bool File::Create(Namespace* namespc, const char* name) {
  Utf8ToWideScope system_name(name);
  int fd = _wopen(system_name.wide(), O_RDONLY | O_CREAT, 0666);
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}

// This structure is needed for creating and reading Junctions.
typedef struct _REPARSE_DATA_BUFFER {
  ULONG ReparseTag;
  USHORT ReparseDataLength;
  USHORT Reserved;

  union {
    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      ULONG Flags;
      WCHAR PathBuffer[1];
    } SymbolicLinkReparseBuffer;

    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      WCHAR PathBuffer[1];
    } MountPointReparseBuffer;

    struct {
      UCHAR DataBuffer[1];
    } GenericReparseBuffer;
  };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;

static const int kReparseDataHeaderSize = sizeof(ULONG) + 2 * sizeof(USHORT);
static const int kMountPointHeaderSize = 4 * sizeof(USHORT);

// Note: CreateLink used to create junctions on Windows instead of true
// symbolic links. All File::*Link methods now support handling links created
// as junctions and symbolic links.
bool File::CreateLink(Namespace* namespc,
                      const char* utf8_name,
                      const char* utf8_target) {
  Utf8ToWideScope name(utf8_name);
  Utf8ToWideScope target(utf8_target);
  DWORD flags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;

  File::Type type = File::GetType(namespc, utf8_target, true);
  if (type == kIsDirectory) {
    flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
  }

  int create_status = CreateSymbolicLinkW(name.wide(), target.wide(), flags);

  // If running on a Windows 10 build older than 14972, an invalid parameter
  // error will be returned when trying to use the
  // SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE flag. Retry without the flag.
  if ((create_status == 0) && (GetLastError() == ERROR_INVALID_PARAMETER)) {
    flags &= ~SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
    create_status = CreateSymbolicLinkW(name.wide(), target.wide(), flags);
  }

  return (create_status != 0);
}

bool File::Delete(Namespace* namespc, const char* name) {
  Utf8ToWideScope system_name(name);
  int status = _wremove(system_name.wide());
  return status != -1;
}

bool File::DeleteLink(Namespace* namespc, const char* name) {
  Utf8ToWideScope system_name(name);
  bool result = false;
  DWORD attributes = GetFileAttributesW(system_name.wide());
  if ((attributes == INVALID_FILE_ATTRIBUTES) ||
      ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0)) {
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
    return false;
  }
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    // It's a junction, which is a special type of directory, or a symbolic
    // link to a directory. Remove the directory.
    result = (RemoveDirectoryW(system_name.wide()) != 0);
  } else {
    // Symbolic link to a file. Remove the file.
    result = (DeleteFileW(system_name.wide()) != 0);
  }
  return result;
}

bool File::Rename(Namespace* namespc,
                  const char* old_path,
                  const char* new_path) {
  File::Type type = GetType(namespc, old_path, false);
  if (type != kIsFile) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }
  Utf8ToWideScope system_old_path(old_path);
  Utf8ToWideScope system_new_path(new_path);
  DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;
  int move_status =
      MoveFileExW(system_old_path.wide(), system_new_path.wide(), flags);
  return (move_status != 0);
}

bool File::RenameLink(Namespace* namespc,
                      const char* old_path,
                      const char* new_path) {
  File::Type type = GetType(namespc, old_path, false);
  if (type != kIsLink) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }
  Utf8ToWideScope system_old_path(old_path);
  Utf8ToWideScope system_new_path(new_path);
  DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;

  // Junction links on Windows appear as special directories. MoveFileExW's
  // MOVEFILE_REPLACE_EXISTING does not allow for replacement of directories,
  // so we need to remove it before renaming a link. This step is only
  // necessary for junctions created by the old Link.create implementation.
  if ((Directory::Exists(namespc, new_path) == Directory::EXISTS) &&
      (GetType(namespc, new_path, false) == kIsLink)) {
    // Bail out if the DeleteLink call fails.
    if (!DeleteLink(namespc, new_path)) {
      return false;
    }
  }
  int move_status =
      MoveFileExW(system_old_path.wide(), system_new_path.wide(), flags);
  return (move_status != 0);
}

bool File::Copy(Namespace* namespc,
                const char* old_path,
                const char* new_path) {
  File::Type type = GetType(namespc, old_path, false);
  if (type != kIsFile) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }
  Utf8ToWideScope system_old_path(old_path);
  Utf8ToWideScope system_new_path(new_path);
  bool success = CopyFileExW(system_old_path.wide(), system_new_path.wide(),
                             NULL, NULL, NULL, 0) != 0;
  return success;
}

int64_t File::LengthFromPath(Namespace* namespc, const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_size;
}

const char* File::LinkTarget(Namespace* namespc,
                             const char* pathname,
                             char* dest,
                             int dest_size) {
  const wchar_t* name = StringUtilsWin::Utf8ToWide(pathname);
  HANDLE dir_handle = CreateFileW(
      name, GENERIC_READ,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      NULL);
  if (dir_handle == INVALID_HANDLE_VALUE) {
    return NULL;
  }

  int buffer_size =
      sizeof(REPARSE_DATA_BUFFER) + 2 * (MAX_PATH + 1) * sizeof(WCHAR);
  REPARSE_DATA_BUFFER* buffer =
      reinterpret_cast<REPARSE_DATA_BUFFER*>(Dart_ScopeAllocate(buffer_size));
  DWORD received_bytes;  // Value is not used.
  int result = DeviceIoControl(dir_handle, FSCTL_GET_REPARSE_POINT, NULL, 0,
                               buffer, buffer_size, &received_bytes, NULL);
  if (result == 0) {
    DWORD error = GetLastError();
    CloseHandle(dir_handle);
    SetLastError(error);
    return NULL;
  }
  if (CloseHandle(dir_handle) == 0) {
    return NULL;
  }

  wchar_t* target;
  size_t target_offset;
  size_t target_length;
  if (buffer->ReparseTag == IO_REPARSE_TAG_MOUNT_POINT) {
    target = buffer->MountPointReparseBuffer.PathBuffer;
    target_offset = buffer->MountPointReparseBuffer.SubstituteNameOffset;
    target_length = buffer->MountPointReparseBuffer.SubstituteNameLength;
  } else if (buffer->ReparseTag == IO_REPARSE_TAG_SYMLINK) {
    target = buffer->SymbolicLinkReparseBuffer.PathBuffer;
    target_offset = buffer->SymbolicLinkReparseBuffer.SubstituteNameOffset;
    target_length = buffer->SymbolicLinkReparseBuffer.SubstituteNameLength;
  } else {  // Not a junction or a symbolic link.
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
    return NULL;
  }

  target_offset /= sizeof(wchar_t);  // Offset and length are in bytes.
  target_length /= sizeof(wchar_t);
  target += target_offset;
  // Remove "\??\" from beginning of target.
  if ((target_length > 4) && (wcsncmp(L"\\??\\", target, 4) == 0)) {
    target += 4;
    target_length -= 4;
  }
  int utf8_length = WideCharToMultiByte(CP_UTF8, 0, target, target_length, NULL,
                                        0, NULL, NULL);
  if (dest_size > 0 && dest_size <= utf8_length) {
    return NULL;
  }
  if (dest == NULL) {
    dest = DartUtils::ScopedCString(utf8_length + 1);
  }
  if (0 == WideCharToMultiByte(CP_UTF8, 0, target, target_length, dest,
                               utf8_length, NULL, NULL)) {
    return NULL;
  }
  dest[utf8_length] = '\0';
  return dest;
}

void File::Stat(Namespace* namespc, const char* name, int64_t* data) {
  File::Type type = GetType(namespc, name, false);
  data[kType] = type;
  if (type != kDoesNotExist) {
    struct _stat64 st;
    Utf8ToWideScope system_name(name);
    int stat_status = _wstat64(system_name.wide(), &st);
    if (stat_status == 0) {
      data[kCreatedTime] = st.st_ctime * 1000;
      data[kModifiedTime] = st.st_mtime * 1000;
      data[kAccessedTime] = st.st_atime * 1000;
      data[kMode] = st.st_mode;
      data[kSize] = st.st_size;
    } else {
      data[kType] = File::kDoesNotExist;
    }
  }
}

time_t File::LastAccessed(Namespace* namespc, const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_atime;
}

time_t File::LastModified(Namespace* namespc, const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_mtime;
}

bool File::SetLastAccessed(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return false;
  }

  // Set the new time:
  struct __utimbuf64 times;
  times.actime = millis / kMillisecondsPerSecond;
  times.modtime = st.st_mtime;
  return _wutime64(system_name.wide(), &times) == 0;
}

bool File::SetLastModified(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return false;
  }

  // Set the new time:
  struct __utimbuf64 times;
  times.actime = st.st_atime;
  times.modtime = millis / kMillisecondsPerSecond;
  return _wutime64(system_name.wide(), &times) == 0;
}

bool File::IsAbsolutePath(const char* pathname) {
  // Should we consider network paths?
  if (pathname == NULL) {
    return false;
  }
  return ((strlen(pathname) > 2) && (pathname[1] == ':') &&
          ((pathname[2] == '\\') || (pathname[2] == '/')));
}

const char* File::GetCanonicalPath(Namespace* namespc, const char* pathname) {
  Utf8ToWideScope system_name(pathname);
  HANDLE file_handle =
      CreateFileW(system_name.wide(), 0, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                  FILE_FLAG_BACKUP_SEMANTICS, NULL);
  if (file_handle == INVALID_HANDLE_VALUE) {
    return NULL;
  }
  wchar_t dummy_buffer[1];
  int required_size =
      GetFinalPathNameByHandle(file_handle, dummy_buffer, 0, VOLUME_NAME_DOS);
  if (required_size == 0) {
    DWORD error = GetLastError();
    CloseHandle(file_handle);
    SetLastError(error);
    return NULL;
  }
  wchar_t* path;
  path = reinterpret_cast<wchar_t*>(
      Dart_ScopeAllocate(required_size * sizeof(*path)));
  int result_size = GetFinalPathNameByHandle(file_handle, path, required_size,
                                             VOLUME_NAME_DOS);
  ASSERT(result_size <= required_size - 1);
  // Remove leading \\?\ if possible, unless input used it.
  char* result;
  if ((result_size < MAX_PATH - 1 + 4) && (result_size > 4) &&
      (wcsncmp(path, L"\\\\?\\", 4) == 0) &&
      (wcsncmp(system_name.wide(), L"\\\\?\\", 4) != 0)) {
    result = StringUtilsWin::WideToUtf8(path + 4);
  } else {
    result = StringUtilsWin::WideToUtf8(path);
  }
  CloseHandle(file_handle);
  return result;
}

const char* File::PathSeparator() {
  // This is already UTF-8 encoded.
  return "\\";
}

const char* File::StringEscapedPathSeparator() {
  // This is already UTF-8 encoded.
  return "\\\\";
}

File::StdioHandleType File::GetStdioHandleType(int fd) {
  // Treat all stdio handles as pipes. The Windows event handler and
  // socket code will handle the different handle types.
  return kPipe;
}

File::Type File::GetType(Namespace* namespc,
                         const char* pathname,
                         bool follow_links) {
  // Convert to wchar_t string.
  Utf8ToWideScope name(pathname);
  DWORD attributes = GetFileAttributesW(name.wide());
  File::Type result = kIsFile;
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    result = kDoesNotExist;
  } else if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (follow_links) {
      HANDLE dir_handle =
          CreateFileW(name.wide(), 0,
                      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                      NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
      if (dir_handle == INVALID_HANDLE_VALUE) {
        result = File::kIsLink;
      } else {
        CloseHandle(dir_handle);
        result = File::kIsDirectory;
      }
    } else {
      result = kIsLink;
    }
  } else if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    result = kIsDirectory;
  }
  return result;
}

File::Identical File::AreIdentical(Namespace* namespc_1,
                                   const char* file_1,
                                   Namespace* namespc_2,
                                   const char* file_2) {
  USE(namespc_1);
  USE(namespc_2);
  BY_HANDLE_FILE_INFORMATION file_info[2];
  const char* file_names[2] = {file_1, file_2};
  for (int i = 0; i < 2; ++i) {
    Utf8ToWideScope wide_name(file_names[i]);
    HANDLE file_handle = CreateFileW(
        wide_name.wide(), 0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT, NULL);
    if (file_handle == INVALID_HANDLE_VALUE) {
      return File::kError;
    }
    int result = GetFileInformationByHandle(file_handle, &file_info[i]);
    if (result == 0) {
      DWORD error = GetLastError();
      CloseHandle(file_handle);
      SetLastError(error);
      return File::kError;
    }
    if (CloseHandle(file_handle) == 0) {
      return File::kError;
    }
  }
  if ((file_info[0].dwVolumeSerialNumber ==
       file_info[1].dwVolumeSerialNumber) &&
      (file_info[0].nFileIndexHigh == file_info[1].nFileIndexHigh) &&
      (file_info[0].nFileIndexLow == file_info[1].nFileIndexLow)) {
    return kIdentical;
  } else {
    return kDifferent;
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
