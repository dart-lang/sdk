// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/file.h"

#include <fcntl.h>  // NOLINT
#include <io.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <WinIoCtl.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/log.h"
#include "bin/utils.h"


namespace dart {
namespace bin {

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
  Close();
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  if (handle_->fd() == _fileno(stdout)) {
    int fd = _open("NUL", _O_WRONLY);
    ASSERT(fd >= 0);
    _dup2(fd, handle_->fd());
    close(fd);
  } else {
    int err = close(handle_->fd());
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


int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return read(handle_->fd(), buffer, num_bytes);
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return write(handle_->fd(), buffer, num_bytes);
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


int64_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct __stat64 st;
  if (_fstat64(handle_->fd(), &st) == 0) {
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
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  int fd = _wopen(system_name, flags, 0666);
  free(const_cast<wchar_t*>(system_name));
  if (fd < 0) {
    return NULL;
  }
  if (((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) {
    int64_t position = _lseeki64(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}


File* File::OpenStdio(int fd) {
  switch (fd) {
    case 1:
      fd = _fileno(stdout);
      break;
    case 2:
      fd = _fileno(stderr);
      break;
    default:
      UNREACHABLE();
  }
  return new File(new FileHandle(fd));
}


bool File::Exists(const char* name) {
  struct __stat64 st;
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  bool stat_status = _wstat64(system_name, &st);
  free(const_cast<wchar_t*>(system_name));
  if (stat_status == 0) {
    return ((st.st_mode & S_IFMT) == S_IFREG);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  int fd = _wopen(system_name, O_RDONLY | O_CREAT, 0666);
  free(const_cast<wchar_t*>(system_name));
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}


// This structure is needed for creating and reading Junctions.
typedef struct _REPARSE_DATA_BUFFER {
    ULONG  ReparseTag;
    USHORT ReparseDataLength;
    USHORT Reserved;

    union {
        struct {
            USHORT  SubstituteNameOffset;
            USHORT  SubstituteNameLength;
            USHORT  PrintNameOffset;
            USHORT  PrintNameLength;
            ULONG   Flags;
            WCHAR   PathBuffer[1];
        } SymbolicLinkReparseBuffer;

        struct {
            USHORT  SubstituteNameOffset;
            USHORT  SubstituteNameLength;
            USHORT  PrintNameOffset;
            USHORT  PrintNameLength;
            WCHAR   PathBuffer[1];
        } MountPointReparseBuffer;

        struct {
            UCHAR   DataBuffer[1];
        } GenericReparseBuffer;
    };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;


static const int kReparseDataHeaderSize = sizeof ULONG + 2 * sizeof USHORT;
static const int kMountPointHeaderSize = 4 * sizeof USHORT;


bool File::CreateLink(const char* utf8_name, const char* utf8_target) {
  const wchar_t* name = StringUtils::Utf8ToWide(utf8_name);
  int create_status = CreateDirectoryW(name, NULL);
  // If the directory already existed, treat it as a success.
  if (create_status == 0 &&
      (GetLastError() != ERROR_ALREADY_EXISTS ||
       (GetFileAttributesW(name) & FILE_ATTRIBUTE_DIRECTORY) != 0)) {
    free(const_cast<wchar_t*>(name));
    return false;
  }

  HANDLE dir_handle = CreateFileW(
      name,
      GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
      NULL,
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      NULL);
  free(const_cast<wchar_t*>(name));
  if (dir_handle == INVALID_HANDLE_VALUE) {
    return false;
  }

  const wchar_t* target = StringUtils::Utf8ToWide(utf8_target);
  int target_len = wcslen(target);
  if (target_len > MAX_PATH - 1) {
    free(const_cast<wchar_t*>(target));
    CloseHandle(dir_handle);
    return false;
  }

  int reparse_data_buffer_size =
      sizeof REPARSE_DATA_BUFFER + 2 * MAX_PATH * sizeof WCHAR;
  REPARSE_DATA_BUFFER* reparse_data_buffer =
      static_cast<REPARSE_DATA_BUFFER*>(calloc(reparse_data_buffer_size, 1));
  reparse_data_buffer->ReparseTag = IO_REPARSE_TAG_MOUNT_POINT;
  wcscpy(reparse_data_buffer->MountPointReparseBuffer.PathBuffer, target);
  wcscpy(
      reparse_data_buffer->MountPointReparseBuffer.PathBuffer + target_len + 1,
      target);
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
      dir_handle,
      FSCTL_SET_REPARSE_POINT,
      reparse_data_buffer,
      reparse_data_buffer->ReparseDataLength + kReparseDataHeaderSize,
      NULL,
      0,
      &dummy_received_bytes,
      NULL);
  if (CloseHandle(dir_handle) == 0) return false;
  free(const_cast<wchar_t*>(target));
  free(reparse_data_buffer);
  return (result != 0);
}


bool File::Delete(const char* name) {
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  int status = _wremove(system_name);
  free(const_cast<wchar_t*>(system_name));
  return status != -1;
}


bool File::DeleteLink(const char* name) {
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  bool result = false;
  DWORD attributes = GetFileAttributesW(system_name);
  if ((attributes != INVALID_FILE_ATTRIBUTES) &&
      (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    // It's a junction(link), delete it.
    result = (RemoveDirectoryW(system_name) != 0);
  } else {
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
  }
  free(const_cast<wchar_t*>(system_name));
  return result;
}


bool File::Rename(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsFile) {
    const wchar_t* system_old_path = StringUtils::Utf8ToWide(old_path);
    const wchar_t* system_new_path = StringUtils::Utf8ToWide(new_path);
    DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;
    int move_status =
        MoveFileExW(system_old_path, system_new_path, flags);
    free(const_cast<wchar_t*>(system_old_path));
    free(const_cast<wchar_t*>(system_new_path));
    return (move_status != 0);
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}


bool File::RenameLink(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsLink) {
    const wchar_t* system_old_path = StringUtils::Utf8ToWide(old_path);
    const wchar_t* system_new_path = StringUtils::Utf8ToWide(new_path);
    DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;
    int move_status =
        MoveFileExW(system_old_path, system_new_path, flags);
    free(const_cast<wchar_t*>(system_old_path));
    free(const_cast<wchar_t*>(system_new_path));
    return (move_status != 0);
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}


bool File::Copy(const char* old_path, const char* new_path) {
  File::Type type = GetType(old_path, false);
  if (type == kIsFile) {
    const wchar_t* system_old_path = StringUtils::Utf8ToWide(old_path);
    const wchar_t* system_new_path = StringUtils::Utf8ToWide(new_path);
    bool success = CopyFileExW(system_old_path,
                               system_new_path,
                               NULL,
                               NULL,
                               NULL,
                               0) != 0;
    free(const_cast<wchar_t*>(system_old_path));
    free(const_cast<wchar_t*>(system_new_path));
    return success;
  } else {
    SetLastError(ERROR_FILE_NOT_FOUND);
  }
  return false;
}


int64_t File::LengthFromPath(const char* name) {
  struct __stat64 st;
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  int stat_status = _wstat64(system_name, &st);
  free(const_cast<wchar_t*>(system_name));
  if (stat_status == 0) {
    return st.st_size;
  }
  return -1;
}


char* File::LinkTarget(const char* pathname) {
  const wchar_t* name = StringUtils::Utf8ToWide(pathname);
  HANDLE dir_handle = CreateFileW(
      name,
      GENERIC_READ,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
      NULL,
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      NULL);
  free(const_cast<wchar_t*>(name));
  if (dir_handle == INVALID_HANDLE_VALUE) {
    return NULL;
  }

  int buffer_size =
      sizeof REPARSE_DATA_BUFFER + 2 * (MAX_PATH + 1) * sizeof WCHAR;
  REPARSE_DATA_BUFFER* buffer =
      static_cast<REPARSE_DATA_BUFFER*>(calloc(buffer_size, 1));
  DWORD received_bytes;  // Value is not used.
  int result = DeviceIoControl(
      dir_handle,
      FSCTL_GET_REPARSE_POINT,
      NULL,
      0,
      buffer,
      buffer_size,
      &received_bytes,
      NULL);
  if (result == 0) {
    DWORD error = GetLastError();
    CloseHandle(dir_handle);
    SetLastError(error);
    free(buffer);
    return NULL;
  }
  if (CloseHandle(dir_handle) == 0) {
    free(buffer);
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
    free(buffer);
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
    return NULL;
  }

  target_offset /= sizeof(wchar_t);  // Offset and length are in bytes.
  target_length /= sizeof(wchar_t);
  target += target_offset;
  // Remove "\??\" from beginning of target.
  if (target_length > 4 && wcsncmp(L"\\??\\", target, 4) == 0) {
    target += 4;
    target_length -=4;
  }
  int utf8_length = WideCharToMultiByte(CP_UTF8,
                                        0,
                                        target,
                                        target_length,
                                        NULL,
                                        0,
                                        NULL,
                                        NULL);
  char* utf8_target = reinterpret_cast<char*>(malloc(utf8_length + 1));
  if (0 == WideCharToMultiByte(CP_UTF8,
                               0,
                               target,
                               target_length,
                               utf8_target,
                               utf8_length,
                               NULL,
                               NULL)) {
    free(buffer);
    free(utf8_target);
    return NULL;
  }
  utf8_target[utf8_length] = '\0';
  free(buffer);
  return utf8_target;
}


void File::Stat(const char* name, int64_t* data) {
  File::Type type = GetType(name, false);
  data[kType] = type;
  if (type != kDoesNotExist) {
    struct _stat64 st;
    const wchar_t* system_name = StringUtils::Utf8ToWide(name);
    int stat_status = _wstat64(system_name, &st);
    free(const_cast<wchar_t*>(system_name));
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


time_t File::LastModified(const char* name) {
  struct __stat64 st;
  const wchar_t* system_name = StringUtils::Utf8ToWide(name);
  int stat_status = _wstat64(system_name, &st);
  free(const_cast<wchar_t*>(system_name));
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
  const wchar_t* system_name = StringUtils::Utf8ToWide(pathname);
  HANDLE file_handle = CreateFileW(
        system_name,
        0,
        FILE_SHARE_READ,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS,
        NULL);
  if (file_handle == INVALID_HANDLE_VALUE) {
    free(const_cast<wchar_t*>(system_name));
    return NULL;
  }
  wchar_t dummy_buffer[1];
  int required_size = GetFinalPathNameByHandle(file_handle,
                                               dummy_buffer,
                                               0,
                                               VOLUME_NAME_DOS);
  if (required_size == 0) {
    free(const_cast<wchar_t*>(system_name));
    DWORD error = GetLastError();
    CloseHandle(file_handle);
    SetLastError(error);
    return NULL;
  }
  wchar_t* path =
      static_cast<wchar_t*>(malloc(required_size * sizeof(wchar_t)));
  int result_size = GetFinalPathNameByHandle(file_handle,
                                             path,
                                             required_size,
                                             VOLUME_NAME_DOS);
  ASSERT(result_size <= required_size - 1);
  // Remove leading \\?\ if possible, unless input used it.
  char* result;
  if (result_size < MAX_PATH - 1 + 4 &&
      result_size > 4 &&
      wcsncmp(path, L"\\\\?\\", 4) == 0 &&
      wcsncmp(system_name, L"\\\\?\\", 4) != 0) {
    result = StringUtils::WideToUtf8(path + 4);
  } else {
    result = StringUtils::WideToUtf8(path);
  }
  free(const_cast<wchar_t*>(system_name));
  free(path);
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
  const wchar_t* name = StringUtils::Utf8ToWide(pathname);
  DWORD attributes = GetFileAttributesW(name);
  File::Type result = kIsFile;
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    result = kDoesNotExist;
  } else if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (follow_links) {
      HANDLE dir_handle = CreateFileW(
          name,
          0,
          FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
          NULL,
          OPEN_EXISTING,
          FILE_FLAG_BACKUP_SEMANTICS,
          NULL);
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
  free(const_cast<wchar_t*>(name));
  return result;
}


File::Identical File::AreIdentical(const char* file_1, const char* file_2) {
  BY_HANDLE_FILE_INFORMATION file_info[2];
  const char* file_names[2] = { file_1, file_2 };
  for (int i = 0; i < 2; ++i) {
    const wchar_t* wide_name = StringUtils::Utf8ToWide(file_names[i]);
    HANDLE file_handle = CreateFileW(
        wide_name,
        0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
        NULL);
    if (file_handle == INVALID_HANDLE_VALUE) {
      free(const_cast<wchar_t*>(wide_name));
      return File::kError;
    }
    free(const_cast<wchar_t*>(wide_name));
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
  if (file_info[0].dwVolumeSerialNumber == file_info[1].dwVolumeSerialNumber &&
      file_info[0].nFileIndexHigh == file_info[1].nFileIndexHigh &&
      file_info[0].nFileIndexLow == file_info[1].nFileIndexLow) {
    return kIdentical;
  } else {
    return kDifferent;
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
