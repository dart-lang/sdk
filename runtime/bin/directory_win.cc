// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/directory.h"

#include <errno.h>     // NOLINT
#include <sys/stat.h>  // NOLINT

#include "bin/crypto.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/file_win.h"
#include "bin/namespace.h"
#include "bin/utils.h"
#include "bin/utils_win.h"
#include "platform/syslog.h"
#include "platform/utils.h"

#undef DeleteFile

namespace dart {
namespace bin {

PathBuffer::PathBuffer() : length_(0) {
  data_ = calloc(MAX_LONG_PATH + 1, sizeof(wchar_t));  // NOLINT
}

PathBuffer::~PathBuffer() {
  free(data_);
}

char* PathBuffer::AsString() const {
  UNREACHABLE();
  return nullptr;
}

wchar_t* PathBuffer::AsStringW() const {
  return reinterpret_cast<wchar_t*>(data_);
}

const char* PathBuffer::AsScopedString() const {
  return StringUtilsWin::WideToUtf8(AsStringW());
}

bool PathBuffer::Add(const char* name) {
  const auto wide_name = Utf8ToWideChar(name);
  return AddW(wide_name.get());
}

bool PathBuffer::AddW(const wchar_t* name) {
  wchar_t* data = AsStringW();
  int written =
      _snwprintf(data + length_, MAX_LONG_PATH - length_, L"%s", name);
  data[MAX_LONG_PATH] = L'\0';
  if ((written <= MAX_LONG_PATH - length_) && (written >= 0) &&
      (static_cast<size_t>(written) == wcsnlen(name, MAX_LONG_PATH + 1))) {
    length_ += written;
    return true;
  } else {
    SetLastError(ERROR_BUFFER_OVERFLOW);
    return false;
  }
}

void PathBuffer::Reset(intptr_t new_length) {
  length_ = new_length;
  AsStringW()[length_] = L'\0';
}

// If link_name points to a link, IsBrokenLink will return true if link_name
// points to an invalid target.
static bool IsBrokenLink(const wchar_t* link_name) {
  HANDLE handle = CreateFileW(
      link_name, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
      nullptr, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
  if (handle == INVALID_HANDLE_VALUE) {
    return true;
  } else {
    CloseHandle(handle);
    return false;
  }
}

// A linked list structure holding a link target's unique file system ID.
// Used to detect loops in the file system when listing recursively.
struct LinkList {
  DWORD volume;
  DWORD id_low;
  DWORD id_high;
  LinkList* next;
};

// Forward declarations.
static bool DeleteRecursively(PathBuffer* path);

static ListType HandleFindFile(DirectoryListing* listing,
                               DirectoryListingEntry* entry,
                               const WIN32_FIND_DATAW& find_file_data) {
  if (!listing->path_buffer().AddW(find_file_data.cFileName)) {
    return kListError;
  }
  DWORD attributes = find_file_data.dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (!listing->follow_links()) {
      return kListLink;
    }
    HANDLE handle = CreateFileW(
        listing->path_buffer().AsStringW(), 0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, nullptr);
    if (handle == INVALID_HANDLE_VALUE) {
      // Report as (broken) link.
      return kListLink;
    }
    if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      // Check the seen link targets to see if we are in a file system loop.
      LinkList current_link;
      BY_HANDLE_FILE_INFORMATION info;
      // Get info
      if (!GetFileInformationByHandle(handle, &info)) {
        DWORD error = GetLastError();
        CloseHandle(handle);
        SetLastError(error);
        return kListError;
      }
      CloseHandle(handle);
      current_link.volume = info.dwVolumeSerialNumber;
      current_link.id_low = info.nFileIndexLow;
      current_link.id_high = info.nFileIndexHigh;
      current_link.next = entry->link();
      LinkList* previous = entry->link();
      while (previous != nullptr) {
        if ((previous->volume == current_link.volume) &&
            (previous->id_low == current_link.id_low) &&
            (previous->id_high == current_link.id_high)) {
          // Report the looping link as a link, rather than following it.
          return kListLink;
        }
        previous = previous->next;
      }
      // Recurse into the directory, adding current link to the seen links list.
      if ((wcscmp(find_file_data.cFileName, L".") == 0) ||
          (wcscmp(find_file_data.cFileName, L"..") == 0)) {
        return entry->Next(listing);
      }
      entry->set_link(new LinkList(current_link));
      return kListDirectory;
    }
  }
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    if ((wcscmp(find_file_data.cFileName, L".") == 0) ||
        (wcscmp(find_file_data.cFileName, L"..") == 0)) {
      return entry->Next(listing);
    }
    return kListDirectory;
  } else {
    return kListFile;
  }
}

ListType DirectoryListingEntry::Next(DirectoryListing* listing) {
  if (done_) {
    return kListDone;
  }

  WIN32_FIND_DATAW find_file_data;

  if (lister_ == 0) {
    const wchar_t* tail = parent_ == nullptr ? L"*" : L"\\*";
    if (!listing->path_buffer().AddW(tail)) {
      done_ = true;
      return kListError;
    }

    path_length_ = listing->path_buffer().length() - 1;

    HANDLE find_handle =
        FindFirstFileW(listing->path_buffer().AsStringW(), &find_file_data);

    if (find_handle == INVALID_HANDLE_VALUE) {
      done_ = true;
      return kListError;
    }

    lister_ = reinterpret_cast<intptr_t>(find_handle);

    listing->path_buffer().Reset(path_length_);

    return HandleFindFile(listing, this, find_file_data);
  }

  // Reset.
  listing->path_buffer().Reset(path_length_);
  ResetLink();

  if (FindNextFileW(reinterpret_cast<HANDLE>(lister_), &find_file_data) != 0) {
    return HandleFindFile(listing, this, find_file_data);
  }

  done_ = true;

  if (GetLastError() != ERROR_NO_MORE_FILES) {
    return kListError;
  }

  return kListDone;
}

DirectoryListingEntry::~DirectoryListingEntry() {
  ResetLink();
  if (lister_ != 0) {
    FindClose(reinterpret_cast<HANDLE>(lister_));
  }
}

void DirectoryListingEntry::ResetLink() {
  if ((link_ != nullptr) &&
      ((parent_ == nullptr) || (parent_->link_ != link_))) {
    delete link_;
    link_ = nullptr;
  }
  if (parent_ != nullptr) {
    link_ = parent_->link_;
  }
}

namespace {
class RecursiveDeleter {
 public:
  RecursiveDeleter() : path_() {}

  // Delete the given directory recursively. Expects an absolute long prefixed
  // path - which allows deletion to proceed without checking if path needs to
  // be prefixed while recursing.
  bool DeleteRecursively(const std::unique_ptr<wchar_t[]>& path) {
    ASSERT(wcsncmp(path.get(), L"\\\\?\\", 4) == 0);
    path_.Reset(0);
    if (path == nullptr || !path_.AddW(path.get()) || path_.length() == 0) {
      return false;
    }

    if (path_.AsStringW()[path_.length() - 1] == '\\') {
      // Strip trailing slash otherwise FindFirstFileW will fail.
      path_.Reset(path_.length() - 1);
    }

    return DeleteDirectory();
  }

 private:
  const wchar_t* path() const { return path_.AsStringW(); }

  bool DeleteDirectory() {
    DWORD attributes = GetFileAttributesW(path());
    if (attributes == INVALID_FILE_ATTRIBUTES) {
      return false;
    }

    // If the directory is a junction, it's pointing to some other place in the
    // filesystem that we do not want to recurse into.
    if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
      // Just delete the junction itself.
      return RemoveDirectoryW(path()) != 0;
    }

    // If it's a file, remove it directly.
    if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
      return DeleteFile();
    }

    if (!path_.AddW(L"\\*")) {
      return false;
    }

    WIN32_FIND_DATAW find_file_data;
    HANDLE find_handle = FindFirstFileW(path(), &find_file_data);

    if (find_handle == INVALID_HANDLE_VALUE) {
      return false;
    }

    // Adjust the path by removing the '*' used for the search.
    const int path_length = path_.length() - 1;
    path_.Reset(path_length);

    do {
      if (!DeleteEntry(&find_file_data)) {
        break;
      }
      path_.Reset(path_length);  // DeleteEntry adds to the path.
    } while (FindNextFileW(find_handle, &find_file_data) != 0);

    DWORD last_error = GetLastError();
    // Always close handle.
    FindClose(find_handle);
    if (last_error != ERROR_NO_MORE_FILES) {
      // Unexpected error, set and return.
      SetLastError(last_error);
      return false;
    }
    // All content deleted successfully, try to delete directory.
    // Drop the "\" from the end of the path.
    path_.Reset(path_length - 1);
    return RemoveDirectoryW(path()) != 0;
  }

  bool DeleteEntry(LPWIN32_FIND_DATAW find_file_data) {
    wchar_t* entry_name = find_file_data->cFileName;
    if ((wcscmp(entry_name, L".") == 0) || (wcscmp(entry_name, L"..") == 0)) {
      return true;
    }

    if (!path_.AddW(entry_name)) {
      return false;
    }

    DWORD attributes = find_file_data->dwFileAttributes;
    if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      return DeleteDirectory();
    } else {
      return DeleteFile();
    }
  }

  bool DeleteFile() {
    if (DeleteFileW(path()) != 0) {
      return true;
    }

    // If we failed because the file is read-only, make it writeable and try
    // again. This mirrors Linux/Mac where a directory containing read-only
    // files can still be recursively deleted.
    if (GetLastError() == ERROR_ACCESS_DENIED) {
      DWORD attributes = GetFileAttributesW(path());
      if (attributes == INVALID_FILE_ATTRIBUTES) {
        return false;
      }

      if ((attributes & FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY) {
        attributes &= ~FILE_ATTRIBUTE_READONLY;

        if (SetFileAttributesW(path(), attributes) == 0) {
          return false;
        }

        return DeleteFileW(path()) != 0;
      }
    }

    return false;
  }

  PathBuffer path_;
};
}  // namespace

Directory::ExistsResult Directory::Exists(const wchar_t* dir_name) {
  DWORD attributes = GetFileAttributesW(dir_name);
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    DWORD last_error = GetLastError();
    if ((last_error == ERROR_FILE_NOT_FOUND) ||
        (last_error == ERROR_PATH_NOT_FOUND)) {
      return Directory::DOES_NOT_EXIST;
    } else {
      // We might not be able to get the file attributes for other
      // reasons such as lack of permissions. In that case we do
      // not know if the directory exists.
      return Directory::UNKNOWN;
    }
  }
  bool exists = (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  exists = exists && !IsBrokenLink(dir_name);
  return exists ? Directory::EXISTS : Directory::DOES_NOT_EXIST;
}

Directory::ExistsResult Directory::Exists(Namespace* namespc,
                                          const char* dir_name) {
  const auto path = ToWinAPIPath(dir_name);
  return Exists(path.get());
}

char* Directory::CurrentNoScope() {
  int length = GetCurrentDirectoryW(0, nullptr);
  if (length == 0) {
    return nullptr;
  }
  wchar_t* current = new wchar_t[length + 1];
  GetCurrentDirectoryW(length + 1, current);
  int utf8_len = WideCharToMultiByte(CP_UTF8, 0, current, -1, nullptr, 0,
                                     nullptr, nullptr);
  char* result = reinterpret_cast<char*>(malloc(utf8_len));
  WideCharToMultiByte(CP_UTF8, 0, current, -1, result, utf8_len, nullptr,
                      nullptr);
  delete[] current;
  return result;
}

bool Directory::Create(Namespace* namespc, const char* dir_name) {
  const auto path = ToWinAPIPath(dir_name);
  int create_status = CreateDirectoryW(path.get(), nullptr);
  // If the directory already existed, treat it as a success.
  if ((create_status == 0) && (GetLastError() == ERROR_ALREADY_EXISTS) &&
      (Exists(path.get()) == EXISTS)) {
    return true;
  }
  return (create_status != 0);
}

const char* Directory::SystemTemp(Namespace* namespc) {
  PathBuffer path;
  // Remove \ at end.
  path.Reset(GetTempPathW(MAX_LONG_PATH, path.AsStringW()) - 1);
  return path.AsScopedString();
}

// Creates a new temporary directory with a UUID as suffix.
static const char* CreateTempFromUUID(const char* prefix) {
  PathBuffer path;
  const auto system_prefix = Utf8ToWideChar(prefix);
  if (!path.AddW(system_prefix.get())) {
    return nullptr;
  }

  // Length of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 36.
  if (path.length() > MAX_LONG_PATH - 36) {
    return nullptr;
  }

  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if ((status != RPC_S_OK) && (status != RPC_S_UUID_LOCAL_ONLY)) {
    return nullptr;
  }
  wchar_t* uuid_string;
  status = UuidToStringW(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    return nullptr;
  }

  // RPC_WSTR is an unsigned short*, so we cast to wchar_t*.
  if (!path.AddW(uuid_string)) {
    return nullptr;
  }
  RpcStringFreeW(&uuid_string);
  if (!CreateDirectoryW(path.AsStringW(), nullptr)) {
    return nullptr;
  }
  return path.AsScopedString();
}

// Creates a new, unused directory, adding characters to the end of prefix, and
// returns the directory's name.
//
// Creates this directory, with a default security descriptor inherited from its
// parent directory. The return value is Dart_ScopeAllocated.
//
// First, attempts appending a suffix created from a random uint32_t. If that
// name is already taken, falls back on using a UUID for the suffix.
//
// Note: More attempts at finding an available short suffix would more reliably
// avoid a uuid suffix. We choose one attempt here because it is simpler, and
// to have a small bound on the number of calls to CreateDirectoryW().
const char* Directory::CreateTemp(Namespace* namespc, const char* prefix) {
  PathBuffer path;
  const auto system_prefix = Utf8ToWideChar(prefix);
  if (!path.AddW(system_prefix.get())) {
    return nullptr;
  }

  // Adding 8 hex digits.
  if (path.length() > MAX_LONG_PATH - 8) {
    // No fallback, there won't be enough room for the UUID, either.
    return nullptr;
  }

  // First try a short suffix using the rng, then if that fails fall back on
  // a uuid.
  uint32_t suffix_bytes = 0;
  const int kSuffixSize = sizeof(suffix_bytes);
  if (!Crypto::GetRandomBytes(kSuffixSize,
                              reinterpret_cast<uint8_t*>(&suffix_bytes))) {
    // Getting random bytes failed, maybe the UUID will work?
    return CreateTempFromUUID(prefix);
  }

  // Two digits per byte plus null.
  char suffix[kSuffixSize * 2 + 1];
  Utils::SNPrint(suffix, sizeof(suffix), "%x", suffix_bytes);
  if (!path.Add(suffix)) {
    // Adding to the path failed, maybe because of low-memory. Don't fall back.
    return nullptr;
  }

  if (!CreateDirectoryW(path.AsStringW(), nullptr)) {
    // Creation failed, possibly because an entry with the name already exists.
    // Fall back to using the UUID suffix.
    return CreateTempFromUUID(prefix);
  }
  return path.AsScopedString();
}

bool Directory::Delete(Namespace* namespc,
                       const char* dir_name,
                       bool recursive) {
  const auto path = ToWinAPIPath(dir_name);
  bool result = false;
  if (!recursive) {
    if (File::GetType(path.get(), /*follow_links=*/true) ==
        File::kIsDirectory) {
      result = (RemoveDirectoryW(path.get()) != 0);
    } else {
      SetLastError(ERROR_FILE_NOT_FOUND);
    }
  } else {
    RecursiveDeleter deleter;
    result = deleter.DeleteRecursively(path);
  }
  return result;
}

bool Directory::Rename(Namespace* namespc,
                       const char* old_name,
                       const char* new_name) {
  const auto old_path = ToWinAPIPath(old_name);
  ExistsResult exists = Exists(old_path.get());
  if (exists != EXISTS) {
    SetLastError(ERROR_FILE_NOT_FOUND);
    return false;
  }
  const auto new_path = ToWinAPIPath(new_name);
  DWORD flags = MOVEFILE_WRITE_THROUGH;
  int move_status = MoveFileExW(old_path.get(), new_path.get(), flags);
  return (move_status != 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
