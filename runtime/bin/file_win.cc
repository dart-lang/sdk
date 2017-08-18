// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/file.h"

#include <WinIoCtl.h>  // NOLINT
#include <fcntl.h>     // NOLINT
#include <io.h>        // NOLINT
#include <stdio.h>     // NOLINT
#include <string.h>    // NOLINT
#include <sys/stat.h>  // NOLINT
#include <sys/utime.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/log.h"
#include "bin/utils.h"
#include "bin/utils_win.h"
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
      Log::PrintErr("%s\n", strerror(errno));
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

MappedMemory* File::Map(File::MapType type, int64_t position, int64_t length) {
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
    default:
      return NULL;
  }

  void* addr = VirtualAlloc(NULL, length, MEM_COMMIT | MEM_RESERVE, prot_alloc);
  if (addr == NULL) {
    Log::PrintErr("VirtualAlloc failed %d\n", GetLastError());
    return NULL;
  }

  SetPosition(position);
  if (!ReadFully(addr, length)) {
    Log::PrintErr("ReadFully failed %d\n", GetLastError());
    VirtualFree(addr, 0, MEM_RELEASE);
    return NULL;
  }

  DWORD old_prot;
  bool result = VirtualProtect(addr, length, prot_final, &old_prot);
  if (!result) {
    Log::PrintErr("VirtualProtect failed %d\n", GetLastError());
    VirtualFree(addr, 0, MEM_RELEASE);
    return NULL;
  }
  return new MappedMemory(addr, length);
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
  ASSERT(fd >= 0);
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
    delete wide;
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

File* File::Open(const char* path, FileOpenMode mode) {
  Utf8ToWideScope system_name(path);
  File* file = FileOpenW(system_name.wide(), mode);
  return file;
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

bool File::Exists(const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  return StatHelper(system_name.wide(), &st);
}

bool File::Create(const char* name) {
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

static const int kReparseDataHeaderSize = sizeof ULONG + 2 * sizeof USHORT;
static const int kMountPointHeaderSize = 4 * sizeof USHORT;

bool File::CreateLink(const char* utf8_name, const char* utf8_target) {
  Utf8ToWideScope name(utf8_name);
  int create_status = CreateDirectoryW(name.wide(), NULL);
  // If the directory already existed, treat it as a success.
  if ((create_status == 0) &&
      ((GetLastError() != ERROR_ALREADY_EXISTS) ||
       ((GetFileAttributesW(name.wide()) & FILE_ATTRIBUTE_DIRECTORY) != 0))) {
    return false;
  }

  HANDLE dir_handle = CreateFileW(
      name.wide(), GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      NULL);
  if (dir_handle == INVALID_HANDLE_VALUE) {
    return false;
  }

  Utf8ToWideScope target(utf8_target);
  int target_len = wcslen(target.wide());
  if (target_len > MAX_PATH - 1) {
    CloseHandle(dir_handle);
    return false;
  }

  int reparse_data_buffer_size =
      sizeof REPARSE_DATA_BUFFER + 2 * MAX_PATH * sizeof WCHAR;
  REPARSE_DATA_BUFFER* reparse_data_buffer =
      reinterpret_cast<REPARSE_DATA_BUFFER*>(malloc(reparse_data_buffer_size));
  reparse_data_buffer->ReparseTag = IO_REPARSE_TAG_MOUNT_POINT;
  wcscpy(reparse_data_buffer->MountPointReparseBuffer.PathBuffer,
         target.wide());
  wcscpy(
      reparse_data_buffer->MountPointReparseBuffer.PathBuffer + target_len + 1,
      target.wide());
  reparse_data_buffer->MountPointReparseBuffer.SubstituteNameOffset = 0;
  reparse_data_buffer->MountPointReparseBuffer.SubstituteNameLength =
      target_len * sizeof WCHAR;
  reparse_data_buffer->MountPointReparseBuffer.PrintNameOffset =
      (target_len + 1) * sizeof WCHAR;
  reparse_data_buffer->MountPointReparseBuffer.PrintNameLength =
      target_len * sizeof WCHAR;
  reparse_data_buffer->ReparseDataLength =
      (target_len + 1) * 2 * sizeof WCHAR + kMountPointHeaderSize;
  DWORD dummy_received_bytes;
  int result = DeviceIoControl(
      dir_handle, FSCTL_SET_REPARSE_POINT, reparse_data_buffer,
      reparse_data_buffer->ReparseDataLength + kReparseDataHeaderSize, NULL, 0,
      &dummy_received_bytes, NULL);
  free(reparse_data_buffer);
  if (CloseHandle(dir_handle) == 0) {
    return false;
  }
  return (result != 0);
}

bool File::Delete(const char* name) {
  Utf8ToWideScope system_name(name);
  int status = _wremove(system_name.wide());
  return status != -1;
}

bool File::DeleteLink(const char* name) {
  Utf8ToWideScope system_name(name);
  bool result = false;
  DWORD attributes = GetFileAttributesW(system_name.wide());
  if ((attributes != INVALID_FILE_ATTRIBUTES) &&
      (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    // It's a junction(link), delete it.
    result = (RemoveDirectoryW(system_name.wide()) != 0);
  } else {
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
  }
  return result;
}

bool File::Rename(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsFile) {
    Utf8ToWideScope system_old_path(old_path);
    Utf8ToWideScope system_new_path(new_path);
    DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;
    int move_status =
        MoveFileExW(system_old_path.wide(), system_new_path.wide(), flags);
    return (move_status != 0);
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}

bool File::RenameLink(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsLink) {
    Utf8ToWideScope system_old_path(old_path);
    Utf8ToWideScope system_new_path(new_path);
    DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;
    int move_status =
        MoveFileExW(system_old_path.wide(), system_new_path.wide(), flags);
    return (move_status != 0);
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}

bool File::Copy(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsFile) {
    Utf8ToWideScope system_old_path(old_path);
    Utf8ToWideScope system_new_path(new_path);
    bool success = CopyFileExW(system_old_path.wide(), system_new_path.wide(),
                               NULL, NULL, NULL, 0) != 0;
    return success;
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}

int64_t File::LengthFromPath(const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_size;
}

const char* File::LinkTarget(const char* pathname) {
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
      sizeof REPARSE_DATA_BUFFER + 2 * (MAX_PATH + 1) * sizeof WCHAR;
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
  char* utf8_target = DartUtils::ScopedCString(utf8_length + 1);
  if (0 == WideCharToMultiByte(CP_UTF8, 0, target, target_length, utf8_target,
                               utf8_length, NULL, NULL)) {
    return NULL;
  }
  utf8_target[utf8_length] = '\0';
  return utf8_target;
}

void File::Stat(const char* name, int64_t* data) {
  File::Type type = GetType(name, false);
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

time_t File::LastAccessed(const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_atime;
}

time_t File::LastModified(const char* name) {
  struct __stat64 st;
  Utf8ToWideScope system_name(name);
  if (!StatHelper(system_name.wide(), &st)) {
    return -1;
  }
  return st.st_mtime;
}

bool File::SetLastAccessed(const char* name, int64_t millis) {
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

bool File::SetLastModified(const char* name, int64_t millis) {
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

const char* File::GetCanonicalPath(const char* pathname) {
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

File::Type File::GetType(const char* pathname, bool follow_links) {
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

File::Identical File::AreIdentical(const char* file_1, const char* file_2) {
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
