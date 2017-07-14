// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

#include <errno.h>     // NOLINT
#include <sys/stat.h>  // NOLINT

#include "bin/dartutils.h"
#include "bin/log.h"

#undef DeleteFile

#define MAX_LONG_PATH 32767

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
  return NULL;
}

wchar_t* PathBuffer::AsStringW() const {
  return reinterpret_cast<wchar_t*>(data_);
}

const char* PathBuffer::AsScopedString() const {
  return StringUtilsWin::WideToUtf8(AsStringW());
}

bool PathBuffer::Add(const char* name) {
  Utf8ToWideScope wide_name(name);
  return AddW(wide_name.wide());
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
      NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
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
    HANDLE handle =
        CreateFileW(listing->path_buffer().AsStringW(), 0,
                    FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                    NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
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
      while (previous != NULL) {
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
    const wchar_t* tail = parent_ == NULL ? L"*" : L"\\*";
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
  if ((link_ != NULL) && ((parent_ == NULL) || (parent_->link_ != link_))) {
    delete link_;
    link_ = NULL;
  }
  if (parent_ != NULL) {
    link_ = parent_->link_;
  }
}

static bool DeleteFile(wchar_t* file_name, PathBuffer* path) {
  if (!path->AddW(file_name)) {
    return false;
  }

  if (DeleteFileW(path->AsStringW()) != 0) {
    return true;
  }

  // If we failed because the file is read-only, make it writeable and try
  // again. This mirrors Linux/Mac where a directory containing read-only files
  // can still be recursively deleted.
  if (GetLastError() == ERROR_ACCESS_DENIED) {
    DWORD attributes = GetFileAttributesW(path->AsStringW());
    if (attributes == INVALID_FILE_ATTRIBUTES) {
      return false;
    }

    if ((attributes & FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY) {
      attributes &= ~FILE_ATTRIBUTE_READONLY;

      if (SetFileAttributesW(path->AsStringW(), attributes) == 0) {
        return false;
      }

      return DeleteFileW(path->AsStringW()) != 0;
    }
  }

  return false;
}

static bool DeleteDir(wchar_t* dir_name, PathBuffer* path) {
  if ((wcscmp(dir_name, L".") == 0) || (wcscmp(dir_name, L"..") == 0)) {
    return true;
  }
  return path->AddW(dir_name) && DeleteRecursively(path);
}

static bool DeleteEntry(LPWIN32_FIND_DATAW find_file_data, PathBuffer* path) {
  DWORD attributes = find_file_data->dwFileAttributes;

  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return DeleteDir(find_file_data->cFileName, path);
  } else {
    return DeleteFile(find_file_data->cFileName, path);
  }
}

static bool DeleteRecursively(PathBuffer* path) {
  DWORD attributes = GetFileAttributesW(path->AsStringW());
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    return false;
  }
  // If the directory is a junction, it's pointing to some other place in the
  // filesystem that we do not want to recurse into.
  if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    // Just delete the junction itself.
    return RemoveDirectoryW(path->AsStringW()) != 0;
  }
  // If it's a file, remove it directly.
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
    return DeleteFile(L"", path);
  }

  if (!path->AddW(L"\\*")) {
    return false;
  }

  WIN32_FIND_DATAW find_file_data;
  HANDLE find_handle = FindFirstFileW(path->AsStringW(), &find_file_data);

  if (find_handle == INVALID_HANDLE_VALUE) {
    return false;
  }

  // Adjust the path by removing the '*' used for the search.
  int path_length = path->length() - 1;
  path->Reset(path_length);

  do {
    if (!DeleteEntry(&find_file_data, path)) {
      break;
    }
    path->Reset(path_length);  // DeleteEntry adds to the path.
  } while (FindNextFileW(find_handle, &find_file_data) != 0);

  DWORD last_error = GetLastError();
  // Always close handle.
  FindClose(find_handle);
  if (last_error != ERROR_NO_MORE_FILES) {
    // Unexpected error, set and return.
    SetLastError(last_error);
    return false;
  }
  // All content deleted succesfully, try to delete directory.
  path->Reset(path_length - 1);  // Drop the "\" from the end of the path.
  return RemoveDirectoryW(path->AsStringW()) != 0;
}

static Directory::ExistsResult ExistsHelper(const wchar_t* dir_name) {
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

Directory::ExistsResult Directory::Exists(const char* dir_name) {
  Utf8ToWideScope system_name(dir_name);
  return ExistsHelper(system_name.wide());
}

char* Directory::CurrentNoScope() {
  int length = GetCurrentDirectoryW(0, NULL);
  if (length == 0) {
    return NULL;
  }
  wchar_t* current = new wchar_t[length + 1];
  GetCurrentDirectoryW(length + 1, current);
  int utf8_len =
      WideCharToMultiByte(CP_UTF8, 0, current, -1, NULL, 0, NULL, NULL);
  char* result = reinterpret_cast<char*>(malloc(utf8_len));
  WideCharToMultiByte(CP_UTF8, 0, current, -1, result, utf8_len, NULL, NULL);
  delete[] current;
  return result;
}

const char* Directory::Current() {
  int length = GetCurrentDirectoryW(0, NULL);
  if (length == 0) {
    return NULL;
  }
  wchar_t* current;
  current = reinterpret_cast<wchar_t*>(
      Dart_ScopeAllocate((length + 1) * sizeof(*current)));
  GetCurrentDirectoryW(length + 1, current);
  return StringUtilsWin::WideToUtf8(current);
}

bool Directory::SetCurrent(const char* path) {
  Utf8ToWideScope system_path(path);
  bool result = SetCurrentDirectoryW(system_path.wide()) != 0;
  return result;
}

bool Directory::Create(const char* dir_name) {
  Utf8ToWideScope system_name(dir_name);
  int create_status = CreateDirectoryW(system_name.wide(), NULL);
  // If the directory already existed, treat it as a success.
  if ((create_status == 0) && (GetLastError() == ERROR_ALREADY_EXISTS) &&
      (ExistsHelper(system_name.wide()) == EXISTS)) {
    return true;
  }
  return (create_status != 0);
}

const char* Directory::SystemTemp() {
  PathBuffer path;
  // Remove \ at end.
  path.Reset(GetTempPathW(MAX_LONG_PATH, path.AsStringW()) - 1);
  return path.AsScopedString();
}

const char* Directory::CreateTemp(const char* prefix) {
  // Returns a new, unused directory name, adding characters to the
  // end of prefix.
  // Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value is Dart_ScopeAllocated.
  PathBuffer path;
  Utf8ToWideScope system_prefix(prefix);
  if (!path.AddW(system_prefix.wide())) {
    return NULL;
  }

  // Length of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 36.
  if (path.length() > MAX_LONG_PATH - 36) {
    return NULL;
  }

  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if ((status != RPC_S_OK) && (status != RPC_S_UUID_LOCAL_ONLY)) {
    return NULL;
  }
  RPC_WSTR uuid_string;
  status = UuidToStringW(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    return NULL;
  }

  // RPC_WSTR is an unsigned short*, so we cast to wchar_t*.
  if (!path.AddW(reinterpret_cast<wchar_t*>(uuid_string))) {
    return NULL;
  }
  RpcStringFreeW(&uuid_string);
  if (!CreateDirectoryW(path.AsStringW(), NULL)) {
    return NULL;
  }
  return path.AsScopedString();
}

bool Directory::Delete(const char* dir_name, bool recursive) {
  bool result = false;
  Utf8ToWideScope system_dir_name(dir_name);
  if (!recursive) {
    if (File::GetType(dir_name, true) == File::kIsDirectory) {
      result = (RemoveDirectoryW(system_dir_name.wide()) != 0);
    } else {
      SetLastError(ERROR_FILE_NOT_FOUND);
    }
  } else {
    PathBuffer path;
    if (path.AddW(system_dir_name.wide())) {
      result = DeleteRecursively(&path);
    }
  }
  return result;
}

bool Directory::Rename(const char* path, const char* new_path) {
  Utf8ToWideScope system_path(path);
  Utf8ToWideScope system_new_path(new_path);
  ExistsResult exists = ExistsHelper(system_path.wide());
  if (exists != EXISTS) {
    return false;
  }
  ExistsResult new_exists = ExistsHelper(system_new_path.wide());
  // MoveFile does not allow replacing existing directories. Therefore,
  // if the new_path is currently a directory we need to delete it
  // first.
  if (new_exists == EXISTS) {
    bool success = Delete(new_path, true);
    if (!success) {
      return false;
    }
  }
  DWORD flags = MOVEFILE_WRITE_THROUGH;
  int move_status =
      MoveFileExW(system_path.wide(), system_new_path.wide(), flags);
  return (move_status != 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
