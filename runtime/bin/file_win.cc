// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include <functional>
#include <memory>
#include <utility>

// clang-format off
#include <Shlwapi.h>    // NOLINT
#include <fcntl.h>      // NOLINT
#include <io.h>         // NOLINT
#include <pathcch.h>    // NOLINT
#include <winioctl.h>   // NOLINT
#undef StrDup           // defined in Shlwapi.h as StrDupW
#include <stdio.h>      // NOLINT
#include <string.h>     // NOLINT
#include <sys/stat.h>   // NOLINT
#include <sys/utime.h>  // NOLINT
// clang-format on

#include "bin/builtin.h"
#include "bin/crypto.h"
#include "bin/directory.h"
#include "bin/file.h"
#include "bin/file_win.h"
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
    Utils::Close(fd);
  } else {
    int err = Utils::Close(closing_fd);
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
  address_ = nullptr;
  size_ = 0;
}

int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return Utils::Read(handle_->fd(), buffer, num_bytes);
}

int64_t File::Write(const void* buffer, int64_t num_bytes) {
  int fd = handle_->fd();
  // Avoid narrowing conversion
  ASSERT(fd >= 0 && num_bytes <= MAXDWORD && num_bytes >= 0);
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(fd));
  DWORD written = 0;
  BOOL result = WriteFile(handle, buffer, num_bytes, &written, nullptr);
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
        WideCharToMultiByte(cp, 0, wide, written, nullptr, 0, nullptr, nullptr);
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
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(handle_->fd()));
  LARGE_INTEGER zero_offset;
  zero_offset.QuadPart = 0;
  LARGE_INTEGER position;
  if (!SetFilePointerEx(handle, zero_offset, &position, FILE_CURRENT)) {
    return -1L;
  }
  return position.QuadPart;
}

bool File::SetPosition(int64_t position) {
  ASSERT(handle_->fd() >= 0);
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(handle_->fd()));
  LARGE_INTEGER requested_position;
  requested_position.QuadPart = position;
  return SetFilePointerEx(handle, requested_position,
                          /*lpNewFilePointer=*/nullptr, FILE_BEGIN);
}

bool File::Truncate(int64_t length) {
  if (!SetPosition(length)) {
    return false;
  }
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(handle_->fd()));
  return SetEndOfFile(handle);
}

bool File::Flush() {
  ASSERT(handle_->fd());
  HANDLE handle = reinterpret_cast<HANDLE>(_get_osfhandle(handle_->fd()));
  return FlushFileBuffers(handle);
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
    return nullptr;
  }
  if ((((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) ||
      (((mode & kWriteOnly) != 0) && ((mode & kTruncate) == 0))) {
    int64_t position = _lseeki64(fd, 0, SEEK_END);
    if (position < 0) {
      return nullptr;
    }
  }
  return OpenFD(fd);
}

File* File::OpenFD(int fd) {
  return new File(new FileHandle(fd));
}

static std::unique_ptr<wchar_t[]> ConvertToAbsolutePath(
    const std::unique_ptr<wchar_t[]>& path) {
  // Initial buffer size is selected to avoid overallocating too much
  // memory.
  int buffer_size = 1024;
  do {
    auto buffer = std::make_unique<wchar_t[]>(buffer_size);
    int full_path_length =
        GetFullPathNameW(path.get(), buffer_size, buffer.get(),
                         /*lpFilePart=*/nullptr);
    if (full_path_length == 0) {
      return nullptr;
    }

    // Note: when sucessful full_path_length does *not* include terminating
    // NUL character, but on failure it *does* include it when returning
    // the size of buffer which we need. Hence comparison here is `<`, rather
    // than `<=`.
    if (full_path_length < buffer_size) {
      return buffer;
    }

    buffer_size = full_path_length;
  } while (true);
}

static bool IsAbsolutePath(const wchar_t* pathname) {
  if (pathname == nullptr) return false;
  char first = pathname[0];
  char second = pathname[1];
  if (first == L'\\' && second == L'\\') return true;
  if (second != L':') return false;
  first |= 0x20;
  char third = pathname[2];
  return (first >= L'a') && (first <= L'z') &&
         (third == L'\\' || third == L'/');
}

const wchar_t* kLongPathPrefix = L"\\\\?\\";
const int kLongPathPrefixLength = 4;

// `\\.\` is a device namespace prefix somewhat similar to `\\?\`.
// We should preserve it at the start of the file names.
const wchar_t* kDeviceNamespacePrefix = L"\\\\.\\";
const int kDeviceNamespacePrefixLength = 4;

static bool IsLongPathPrefixed(const std::unique_ptr<wchar_t[]>& path) {
  return wcsncmp(path.get(), kLongPathPrefix, kLongPathPrefixLength) == 0;
}

static bool IsDeviceNamespacePrefixed(const std::unique_ptr<wchar_t[]>& path) {
  return wcsncmp(path.get(), kDeviceNamespacePrefix,
                 kDeviceNamespacePrefixLength) == 0;
}

// Converts the given UTF8 path to wide char '\\?\'-prefix absolute path.
//
// Note that some WinAPI functions (like SetCurrentDirectoryW) are always
// limited to MAX_PATH long paths and converting to `\\?\`-prefixed form does
// not remove this limitation. Always check Win API documentation.
std::unique_ptr<wchar_t[]> ToWinAPIPath(const char* utf8_path) {
  auto path = Utf8ToWideChar(utf8_path);
  // Among other things ConvertToAbsolutePath replaces '/' with '\',
  // which PathAllocCanonicalize won't do.
  auto abs_path = ConvertToAbsolutePath(path);
  if (abs_path.get() == nullptr) {
    return std::unique_ptr<wchar_t[]>(nullptr);
  }

  PWSTR canonical_path;
  if (PathAllocCanonicalize(abs_path.get(),
                            PATHCCH_ENSURE_IS_EXTENDED_LENGTH_PATH,
                            &canonical_path) != S_OK) {
    return std::unique_ptr<wchar_t[]>(nullptr);
  }
  auto result = std::unique_ptr<wchar_t[]>(wcsdup(canonical_path));
  LocalFree(canonical_path);
  return result;
}

File* File::Open(Namespace* namespc, const char* name, FileOpenMode mode) {
  const auto path = ToWinAPIPath(name);
  File* file = FileOpenW(path.get(), mode);
  return file;
}

CStringUniquePtr File::UriToPath(const char* uri) {
  UriDecoder uri_decoder(uri);
  if (uri_decoder.decoded() == nullptr) {
    SetLastError(ERROR_INVALID_NAME);
    return CStringUniquePtr(nullptr);
  }

  const auto uri_w = Utf8ToWideChar(uri_decoder.decoded());
  if (!UrlIsFileUrlW(uri_w.get())) {
    return CStringUniquePtr(Utils::StrDup(uri_decoder.decoded()));
  }
  wchar_t filename_w[MAX_PATH];
  DWORD filename_len = MAX_PATH;
  HRESULT result = PathCreateFromUrlW(uri_w.get(), filename_w, &filename_len,
                                      /* dwFlags= */ 0);
  if (result != S_OK) {
    return CStringUniquePtr(nullptr);
  }

  WideToUtf8Scope utf8_path(filename_w);
  return utf8_path.release();
}

File* File::OpenUri(Namespace* namespc, const char* uri, FileOpenMode mode) {
  auto path = UriToPath(uri);
  if (path == nullptr) {
    return nullptr;
  }
  return Open(namespc, path.get(), mode);
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

static bool StatHelper(const wchar_t* path, struct __stat64* st) {
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

static bool FileExists(const wchar_t* path) {
  struct __stat64 st;
  return StatHelper(path, &st);
}

bool File::Exists(Namespace* namespc, const char* name) {
  const auto path = ToWinAPIPath(name);
  return FileExists(path.get());
}

bool File::ExistsUri(Namespace* namespc, const char* uri) {
  UriDecoder uri_decoder(uri);
  if (uri_decoder.decoded() == nullptr) {
    SetLastError(ERROR_INVALID_NAME);
    return false;
  }
  return File::Exists(namespc, uri_decoder.decoded());
}

bool File::Create(Namespace* namespc, const char* name, bool exclusive) {
  const auto path = ToWinAPIPath(name);
  int flags = O_RDONLY | O_CREAT;
  if (exclusive) {
    flags |= O_EXCL;
  }
  int fd = _wopen(path.get(), flags, 0666);
  if (fd < 0) {
    return false;
  }
  return (Utils::Close(fd) == 0);
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

bool File::CreateLink(Namespace* namespc,
                      const char* utf8_name,
                      const char* utf8_target) {
  const auto name = ToWinAPIPath(utf8_name);

  std::unique_ptr<wchar_t[]> target;
  bool target_is_directory;
  if (File::IsAbsolutePath(utf8_target)) {
    target = ToWinAPIPath(utf8_target);
    target_is_directory =
        File::GetType(target.get(), /*follow_links=*/true) == kIsDirectory;
  } else {
    // The path of `target` is relative to `name`.
    //
    // To determine if `target` is a file or directory, we need to calculate
    // either its absolute path or its path relative to the current working
    // directory.
    //
    // For example:
    //
    // name=           C:\A\B\Link      ..\..\Link      ..\..\Link
    // target=         MyFile           MyFile          ..\Dir\MyFile
    // --------------------------------------------------------------------
    // target_path=    C:\A\B\MyFile    ..\..\MyFile    ..\..\..\Dir\MyFile
    //
    // The transformation steps are:
    // 1. target_path := name                           ..\..\Link
    // 2. target_path := remove_file(target_path)       ..\..\
    // 3. target_path := combine(target_path, target)   ..\..\..\Dir\MyFile
    target = Utf8ToWideChar(utf8_target);

    // 1. target_path := name
    intptr_t target_path_max_length =
        wcslen(name.get()) + wcslen(target.get()) + 2;
    auto target_path = std::make_unique<wchar_t[]>(target_path_max_length);
    wcscpy_s(target_path.get(), target_path_max_length, name.get());

    // 2. target_path := remove_file(target_path)
    HRESULT remove_result =
        PathCchRemoveFileSpec(target_path.get(), target_path_max_length);
    if (remove_result == S_FALSE) {
      // If the file component could not be removed, then `name` is
      // top-level, like "C:\" or "/". Attempts to create files at those paths
      // will fail with ERROR_ACCESS_DENIED.
      SetLastError(ERROR_ACCESS_DENIED);
      return false;
    } else if (remove_result != S_OK) {
      SetLastError(remove_result);
      return false;
    }

    // 3. target_path := combine(target_path, target)
    HRESULT combine_result = PathCchCombineEx(
        target_path.get(), target_path_max_length, target_path.get(),
        target.get(), PATHCCH_ALLOW_LONG_PATHS);
    if (combine_result != S_OK) {
      SetLastError(combine_result);
      return false;
    }

    target_is_directory =
        File::GetType(target_path.get(), /*follow_links=*/true) == kIsDirectory;
  }

  DWORD flags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  if (target_is_directory) {
    flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
  }
  int create_status = CreateSymbolicLinkW(name.get(), target.get(), flags);

  // If running on a Windows 10 build older than 14972, an invalid parameter
  // error will be returned when trying to use the
  // SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE flag. Retry without the flag.
  if ((create_status == 0) && (GetLastError() == ERROR_INVALID_PARAMETER)) {
    flags &= ~SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
    create_status = CreateSymbolicLinkW(name.get(), target.get(), flags);
  }

  return (create_status != 0);
}

bool File::CreatePipe(Namespace* namespc, File** readPipe, File** writePipe) {
  int pipe_fds[2];
  int status = _pipe(pipe_fds, 4096, _O_BINARY);
  if (status != 0) {
    return false;
  }
  *readPipe = OpenFD(pipe_fds[0]);
  *writePipe = OpenFD(pipe_fds[1]);
  return true;
}

bool File::Delete(Namespace* namespc, const char* name) {
  const auto path = ToWinAPIPath(name);
  int status = _wremove(path.get());
  return status != -1;
}

static bool DeleteLinkHelper(const wchar_t* path) {
  bool result = false;
  DWORD attributes = GetFileAttributesW(path);
  if ((attributes == INVALID_FILE_ATTRIBUTES) ||
      ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0)) {
    SetLastError(ERROR_NOT_A_REPARSE_POINT);
    return false;
  }
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    // It's a junction, which is a special type of directory, or a symbolic
    // link to a directory. Remove the directory.
    result = (RemoveDirectoryW(path) != 0);
  } else {
    // Symbolic link to a file. Remove the file.
    result = (DeleteFileW(path) != 0);
  }
  return result;
}

bool File::DeleteLink(Namespace* namespc, const char* name) {
  const auto path = ToWinAPIPath(name);
  return DeleteLinkHelper(path.get());
}

static bool RenameHelper(File::Type expected,
                         const char* old_name,
                         const char* new_name) {
  const auto old_path = ToWinAPIPath(old_name);
  File::Type type = File::GetType(old_path.get(), /*follow_links=*/false);
  if (type != expected) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }
  const auto new_path = ToWinAPIPath(new_name);
  DWORD flags = MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING;

  // Symbolic links (e.g. produced by Link.create) to directories on Windows
  // appear as special directories. MoveFileExW's MOVEFILE_REPLACE_EXISTING
  // does not allow for replacement of directories, so we need to remove it
  // before renaming.
  if ((Directory::Exists(new_path.get()) == Directory::EXISTS) &&
      (File::GetType(new_path.get(), /*follow_links=*/false) ==
       File::kIsLink)) {
    // Bail out if the DeleteLink call fails.
    if (!DeleteLinkHelper(new_path.get())) {
      return false;
    }
  }
  int move_status = MoveFileExW(old_path.get(), new_path.get(), flags);
  return (move_status != 0);
}

bool File::Rename(Namespace* namespc,
                  const char* old_name,
                  const char* new_name) {
  return RenameHelper(File::kIsFile, old_name, new_name);
}

bool File::RenameLink(Namespace* namespc,
                      const char* old_name,
                      const char* new_name) {
  return RenameHelper(File::kIsLink, old_name, new_name);
}

static std::unique_ptr<wchar_t[]> GetDirectoryPath(
    const std::unique_ptr<wchar_t[]>& path) {
  for (intptr_t i = wcslen(path.get()) - 1; i >= 0; --i) {
    if (path.get()[i] == '\\' || path.get()[i] == '/') {
      // Note: we need to copy the trailing directory separator so we need to
      // copy i + 1 characters (plus trailing '\0').
      auto result = std::make_unique<wchar_t[]>(i + 2);
      wcsncpy(result.get(), path.get(), i + 1);
      return result;
    }
  }
  return nullptr;
}

static void FreeUUID(wchar_t* ptr) {
  RpcStringFreeW(&ptr);
}

static std::unique_ptr<wchar_t, decltype(FreeUUID)*> GenerateUUIDString() {
  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if ((status != RPC_S_OK) && (status != RPC_S_UUID_LOCAL_ONLY)) {
    return {nullptr, nullptr};
  }
  wchar_t* uuid_string;
  status = UuidToStringW(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    return {nullptr, nullptr};
  }

  return {uuid_string, &FreeUUID};
}

// This function will copy the |src| file to a temporary file in the
// directory where |dest| resides and returns the path of temp file.
static std::unique_ptr<wchar_t[]> CopyIntoTempFile(
    const std::unique_ptr<wchar_t[]>& src,
    const std::unique_ptr<wchar_t[]>& dest) {
  const auto dir = GetDirectoryPath(dest);
  if (dir == nullptr) {
    return nullptr;
  }

  uint32_t suffix_bytes = 0;
  const int kSuffixSize = sizeof(suffix_bytes);
  if (Crypto::GetRandomBytes(kSuffixSize,
                             reinterpret_cast<uint8_t*>(&suffix_bytes))) {
    const size_t file_path_buf_size = wcslen(dir.get()) + 8 + 1;
    auto file_path = std::make_unique<wchar_t[]>(file_path_buf_size);
    swprintf(file_path.get(), file_path_buf_size, L"%s%x", dir.get(),
             suffix_bytes);

    if (CopyFileExW(src.get(), file_path.get(), nullptr, nullptr, nullptr, 0) !=
        0) {
      return file_path;
    }

    // If CopyFileExW() fails to copy to a temp file with random hex, fall
    // back to copy to a uuid temp file.
  }

  const auto uuid_str = GenerateUUIDString();
  if (uuid_str == nullptr) {
    return nullptr;
  }

  const size_t file_path_buf_size =
      wcslen(dir.get()) + wcslen(uuid_str.get()) + 1;
  auto file_path = std::make_unique<wchar_t[]>(file_path_buf_size);
  swprintf(file_path.get(), file_path_buf_size, L"%s%s", dir.get(),
           uuid_str.get());

  if (CopyFileExW(src.get(), file_path.get(), nullptr, nullptr, nullptr, 0) !=
      0) {
    return file_path;
  }

  return nullptr;
}

bool File::Copy(Namespace* namespc,
                const char* old_name,
                const char* new_name) {
  // We are going to concatenate new path with temporary file names in
  // CopyIntoTempFile so we force long prefix no matter what.
  const auto old_path = ToWinAPIPath(old_name);
  const auto new_path = ToWinAPIPath(new_name);

  File::Type type = GetType(old_path.get(), /*follow_links=*/false);
  if (type != kIsFile) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }

  const auto temp_file = CopyIntoTempFile(old_path, new_path);
  if (temp_file == nullptr) {
    // If temp file creation fails, fall back on doing a direct copy.
    return CopyFileExW(old_path.get(), new_path.get(), nullptr, nullptr,
                       nullptr, 0) != 0;
  }

  // Remove the existing file. Otherwise, renaming will fail.
  if (FileExists(new_path.get())) {
    DeleteFileW(new_path.get());
  }

  if (!MoveFileW(temp_file.get(), new_path.get())) {
    DWORD error = GetLastError();
    DeleteFileW(temp_file.get());
    SetLastError(error);
    return false;
  }

  return true;
}

int64_t File::LengthFromPath(Namespace* namespc, const char* name) {
  struct __stat64 st;
  const auto path = ToWinAPIPath(name);
  if (!StatHelper(path.get(), &st)) {
    return -1;
  }
  return st.st_size;
}

const char* File::LinkTarget(Namespace* namespc,
                             const char* pathname,
                             char* dest,
                             int dest_size) {
  const auto path = ToWinAPIPath(pathname);
  HANDLE dir_handle = CreateFileW(
      path.get(), GENERIC_READ,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      nullptr);
  if (dir_handle == INVALID_HANDLE_VALUE) {
    return nullptr;
  }

  // Allocate a buffer for regular paths (smaller than MAX_PATH). If buffer is
  // too small for a long path, allocate a bigger buffer and try again.
  int buffer_size =
      sizeof(REPARSE_DATA_BUFFER) + (MAX_PATH + 1) * sizeof(WCHAR);
  REPARSE_DATA_BUFFER* buffer =
      reinterpret_cast<REPARSE_DATA_BUFFER*>(Dart_ScopeAllocate(buffer_size));
  DWORD received_bytes;  // Value is not used.
  int result = DeviceIoControl(dir_handle, FSCTL_GET_REPARSE_POINT, nullptr, 0,
                               buffer, buffer_size, &received_bytes, nullptr);
  if (result == 0) {
    DWORD error = GetLastError();
    // If ERROR_MORE_DATA is thrown, the target path exceeds the size limit. A
    // bigger buffer will be required.
    if (error == ERROR_MORE_DATA) {
      // Allocate a bigger buffer with MAX_LONG_PATH
      buffer_size =
          sizeof(REPARSE_DATA_BUFFER) + (MAX_LONG_PATH + 1) * sizeof(WCHAR);
      buffer = reinterpret_cast<REPARSE_DATA_BUFFER*>(
          Dart_ScopeAllocate(buffer_size));
      result = DeviceIoControl(dir_handle, FSCTL_GET_REPARSE_POINT, nullptr, 0,
                               buffer, buffer_size, &received_bytes, nullptr);
      if (result == 0) {
        // Overwrite the ERROR_MORE_DATA.
        error = GetLastError();
      }
    }
    if (result == 0) {
      CloseHandle(dir_handle);
      SetLastError(error);
      return nullptr;
    }
  }
  if (CloseHandle(dir_handle) == 0) {
    return nullptr;
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
    return nullptr;
  }

  target_offset /= sizeof(wchar_t);  // Offset and length are in bytes.
  target_length /= sizeof(wchar_t);
  target += target_offset;
  // Remove "\??\" from beginning of target.
  if ((target_length > 4) && (wcsncmp(L"\\??\\", target, 4) == 0)) {
    target += 4;
    target_length -= 4;
  }
  int utf8_length = WideCharToMultiByte(CP_UTF8, 0, target, target_length,
                                        nullptr, 0, nullptr, nullptr);
  if (dest_size > 0 && dest_size <= utf8_length) {
    return nullptr;
  }
  if (dest == nullptr) {
    dest = DartUtils::ScopedCString(utf8_length + 1);
  }
  if (0 == WideCharToMultiByte(CP_UTF8, 0, target, target_length, dest,
                               utf8_length, nullptr, nullptr)) {
    return nullptr;
  }
  dest[utf8_length] = '\0';
  return dest;
}

void File::Stat(Namespace* namespc, const char* name, int64_t* data) {
  const auto path = ToWinAPIPath(name);
  File::Type type = GetType(path.get(), /*follow_links=*/true);
  data[kType] = type;
  if (type != kDoesNotExist) {
    struct _stat64 st;
    int stat_status = _wstat64(path.get(), &st);
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
  const auto path = ToWinAPIPath(name);
  if (!StatHelper(path.get(), &st)) {
    return -1;
  }
  return st.st_atime;
}

time_t File::LastModified(Namespace* namespc, const char* name) {
  struct __stat64 st;
  const auto path = ToWinAPIPath(name);
  if (!StatHelper(path.get(), &st)) {
    return -1;
  }
  return st.st_mtime;
}

bool File::SetLastAccessed(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  struct __stat64 st;
  const auto path = ToWinAPIPath(name);
  if (!StatHelper(path.get(), &st)) {  // Checks that it is a file.
    return false;
  }

  // _utime and related functions set the access and modification times of the
  // affected file. Even if the specified modification time is not changed
  // from the current value, _utime will trigger a file modification event
  // (e.g. ReadDirectoryChangesW will report the file as modified).
  //
  // So set the file access time directly using SetFileTime.
  FILETIME at = GetFiletimeFromMillis(millis);
  HANDLE file_handle =
      CreateFileW(path.get(), FILE_WRITE_ATTRIBUTES,
                  FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                  nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
  if (file_handle == INVALID_HANDLE_VALUE) {
    return false;
  }
  bool result = SetFileTime(file_handle, nullptr, &at, nullptr);
  CloseHandle(file_handle);
  return result;
}

bool File::SetLastModified(Namespace* namespc,
                           const char* name,
                           int64_t millis) {
  // First get the current times.
  struct __stat64 st;
  const auto path = ToWinAPIPath(name);
  if (!StatHelper(path.get(), &st)) {
    return false;
  }

  // Set the new time:
  struct __utimbuf64 times;
  times.actime = st.st_atime;
  times.modtime = millis / kMillisecondsPerSecond;
  return _wutime64(path.get(), &times) == 0;
}

// Keep this function synchronized with the behavior
// of `FileSystemEntity.isAbsolute` in file_system_entity.dart.
bool File::IsAbsolutePath(const char* pathname) {
  if (pathname == nullptr) return false;
  char first = pathname[0];
  char second = pathname[1];
  if (first == '\\' && second == '\\') return true;
  if (second != ':') return false;
  first |= 0x20;
  char third = pathname[2];
  return (first >= 'a') && (first <= 'z') && (third == '\\' || third == '/');
}

const char* File::GetCanonicalPath(Namespace* namespc,
                                   const char* pathname,
                                   char* dest,
                                   int dest_size) {
  const auto path = ToWinAPIPath(pathname);
  HANDLE file_handle =
      CreateFileW(path.get(), 0, FILE_SHARE_READ, nullptr, OPEN_EXISTING,
                  FILE_FLAG_BACKUP_SEMANTICS, nullptr);
  if (file_handle == INVALID_HANDLE_VALUE) {
    return nullptr;
  }
  wchar_t dummy_buffer[1];
  int required_size =
      GetFinalPathNameByHandle(file_handle, dummy_buffer, 0, VOLUME_NAME_DOS);
  if (required_size == 0) {
    DWORD error = GetLastError();
    CloseHandle(file_handle);
    SetLastError(error);
    return nullptr;
  }

  const auto canonical_path = std::make_unique<wchar_t[]>(required_size);
  int result_size = GetFinalPathNameByHandle(file_handle, canonical_path.get(),
                                             required_size, VOLUME_NAME_DOS);
  ASSERT(result_size <= required_size - 1);
  CloseHandle(file_handle);

  // Remove leading \\?\ since it is only to overcome MAX_PATH limitation.
  // Leave it if input used it though.
  int offset = 0;
  if ((result_size > 4) &&
      (wcsncmp(canonical_path.get(), L"\\\\?\\", 4) == 0) &&
      (strncmp(pathname, "\\\\?\\", 4) != 0)) {
    if ((result_size > 8) &&
        (wcsncmp(canonical_path.get(), L"\\\\?\\UNC\\", 8) == 0)) {
      // Leave '\\?\UNC\' prefix intact - stripping it makes invalid UNC name.
    } else {
      offset = 4;
    }
  }
  int utf8_size = WideCharToMultiByte(CP_UTF8, 0, canonical_path.get() + offset,
                                      -1, nullptr, 0, nullptr, nullptr);
  if (dest == nullptr) {
    dest = DartUtils::ScopedCString(utf8_size);
    dest_size = utf8_size;
  }
  if (dest_size != 0) {
    ASSERT(utf8_size <= dest_size);
  }
  if (0 == WideCharToMultiByte(CP_UTF8, 0, canonical_path.get() + offset, -1,
                               dest, dest_size, nullptr, nullptr)) {
    return nullptr;
  }
  return dest;
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

File::Type File::GetType(const wchar_t* path, bool follow_links) {
  DWORD attributes = GetFileAttributesW(path);
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    return File::kDoesNotExist;
  } else if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (follow_links) {
      HANDLE target_handle = CreateFileW(
          path, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
          nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
      if (target_handle == INVALID_HANDLE_VALUE) {
        return File::kDoesNotExist;
      } else {
        BY_HANDLE_FILE_INFORMATION info;
        if (!GetFileInformationByHandle(target_handle, &info)) {
          CloseHandle(target_handle);
          return File::kDoesNotExist;
        }
        CloseHandle(target_handle);
        return ((info.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0)
                   ? File::kIsDirectory
                   : File::kIsFile;
      }
    } else {
      return File::kIsLink;
    }
  } else if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return File::kIsDirectory;
  }
  return File::kIsFile;
}

File::Type File::GetType(Namespace* namespc,
                         const char* name,
                         bool follow_links) {
  const auto path = ToWinAPIPath(name);
  return GetType(path.get(), follow_links);
}

File::Identical File::AreIdentical(Namespace* namespc_1,
                                   const char* file_1,
                                   Namespace* namespc_2,
                                   const char* file_2) {
  USE(namespc_1);
  USE(namespc_2);
  BY_HANDLE_FILE_INFORMATION file_info[2];
  const std::unique_ptr<wchar_t[]> file_names[2] = {ToWinAPIPath(file_1),
                                                    ToWinAPIPath(file_2)};
  for (int i = 0; i < 2; ++i) {
    HANDLE file_handle = CreateFileW(
        file_names[i].get(), 0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT, nullptr);
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

#endif  // defined(DART_HOST_OS_WINDOWS)
