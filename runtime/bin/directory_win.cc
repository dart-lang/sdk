// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/utils.h"

#include <errno.h>  // NOLINT
#include <sys/stat.h>  // NOLINT

#include "bin/log.h"

#undef DeleteFile

#define MAX_LONG_PATH 32767

namespace dart {
namespace bin {

PathBuffer::PathBuffer() : length_(0) {
  data_ = calloc(MAX_LONG_PATH + 1,  sizeof(wchar_t));  // NOLINT
}

char* PathBuffer::AsString() const {
  return StringUtils::WideToUtf8(AsStringW());
}

wchar_t* PathBuffer::AsStringW() const {
  return reinterpret_cast<wchar_t*>(data_);
}

bool PathBuffer::Add(const char* name) {
  const wchar_t* wide_name = StringUtils::Utf8ToWide(name);
  bool success = AddW(wide_name);
  free(const_cast<wchar_t*>(wide_name));
  return success;
}

bool PathBuffer::AddW(const wchar_t* name) {
  wchar_t* data = AsStringW();
  int written = _snwprintf(data + length_,
                           MAX_LONG_PATH - length_,
                           L"%s",
                           name);
  data[MAX_LONG_PATH] = L'\0';
  if (written <= MAX_LONG_PATH - length_ &&
      written >= 0 &&
      static_cast<size_t>(written) == wcsnlen(name, MAX_LONG_PATH + 1)) {
    length_ += written;
    return true;
  } else {
    SetLastError(ERROR_BUFFER_OVERFLOW);
    return false;
  }
}

void PathBuffer::Reset(int new_length) {
  length_ = new_length;
  AsStringW()[length_] = L'\0';
}

// If link_name points to a link, IsBrokenLink will return true if link_name
// points to an invalid target.
static bool IsBrokenLink(const wchar_t* link_name) {
  HANDLE handle = CreateFileW(
      link_name,
      0,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
      NULL,
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS,
      NULL);
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
                               WIN32_FIND_DATAW& find_file_data) {
  if (!listing->path_buffer().AddW(find_file_data.cFileName)) {
    return kListError;
  }
  DWORD attributes = find_file_data.dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (!listing->follow_links()) {
      return kListLink;
    }
    HANDLE handle = CreateFileW(
        listing->path_buffer().AsStringW(),
        0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS,
        NULL);
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
        if (previous->volume == current_link.volume &&
            previous->id_low == current_link.id_low &&
            previous->id_high == current_link.id_high) {
          // Report the looping link as a link, rather than following it.
          return kListLink;
        }
        previous = previous->next;
      }
      // Recurse into the directory, adding current link to the seen links list.
      if (wcscmp(find_file_data.cFileName, L".") == 0 ||
          wcscmp(find_file_data.cFileName, L"..") == 0) {
        return entry->Next(listing);
      }
      entry->set_link(new LinkList(current_link));
      return kListDirectory;
    }
  }
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    if (wcscmp(find_file_data.cFileName, L".") == 0 ||
        wcscmp(find_file_data.cFileName, L"..") == 0) {
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

    HANDLE find_handle = FindFirstFileW(listing->path_buffer().AsStringW(),
                                        &find_file_data);

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
  if (link_ != NULL && (parent_ == NULL || parent_->link_ != link_)) {
    delete link_;
    link_ = NULL;
  }
  if (parent_ != NULL) {
    link_ = parent_->link_;
  }
}


static bool DeleteFile(wchar_t* file_name, PathBuffer* path) {
  if (!path->AddW(file_name)) return false;

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
  if (wcscmp(dir_name, L".") == 0) return true;
  if (wcscmp(dir_name, L"..") == 0) return true;
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
  if ((attributes == INVALID_FILE_ATTRIBUTES)) {
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

  if (!path->AddW(L"\\*")) return false;

  WIN32_FIND_DATAW find_file_data;
  HANDLE find_handle = FindFirstFileW(path->AsStringW(), &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  int path_length = path->length() - 1;
  path->Reset(path_length);

  if (find_handle == INVALID_HANDLE_VALUE) {
    return false;
  }

  bool success = DeleteEntry(&find_file_data, path);

  while ((FindNextFileW(find_handle, &find_file_data) != 0) && success) {
    path->Reset(path_length);  // DeleteEntry adds to the path.
    success = success && DeleteEntry(&find_file_data, path);
  }

  path->Reset(path_length - 1);  // Drop the "\" from the end of the path.
  if ((GetLastError() != ERROR_NO_MORE_FILES) ||
      (FindClose(find_handle) == 0) ||
      (RemoveDirectoryW(path->AsStringW()) == 0)) {
    return false;
  }

  return success;
}


static Directory::ExistsResult ExistsHelper(const wchar_t* dir_name) {
  DWORD attributes = GetFileAttributesW(dir_name);
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    DWORD last_error = GetLastError();
    if (last_error == ERROR_FILE_NOT_FOUND ||
        last_error == ERROR_PATH_NOT_FOUND) {
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
  const wchar_t* system_name = StringUtils::Utf8ToWide(dir_name);
  Directory::ExistsResult result = ExistsHelper(system_name);
  free(const_cast<wchar_t*>(system_name));
  return result;
}


char* Directory::Current() {
  int length = GetCurrentDirectoryW(0, NULL);
  if (length == 0) return NULL;
  wchar_t* current = new wchar_t[length + 1];
  GetCurrentDirectoryW(length + 1, current);
  char* result = StringUtils::WideToUtf8(current);
  delete[] current;
  return result;
}


bool Directory::SetCurrent(const char* path) {
  const wchar_t* system_path = StringUtils::Utf8ToWide(path);
  bool result = SetCurrentDirectoryW(system_path) != 0;
  free(const_cast<wchar_t*>(system_path));
  return result;
}


bool Directory::Create(const char* dir_name) {
  const wchar_t* system_name = StringUtils::Utf8ToWide(dir_name);
  int create_status = CreateDirectoryW(system_name, NULL);
  // If the directory already existed, treat it as a success.
  if (create_status == 0 &&
      GetLastError() == ERROR_ALREADY_EXISTS &&
      ExistsHelper(system_name) == EXISTS) {
    free(const_cast<wchar_t*>(system_name));
    return true;
  }
  free(const_cast<wchar_t*>(system_name));
  return (create_status != 0);
}


char* Directory::SystemTemp() {
  PathBuffer path;
  // Remove \ at end.
  path.Reset(GetTempPathW(MAX_LONG_PATH, path.AsStringW()) - 1);
  return path.AsString();
}


char* Directory::CreateTemp(const char* prefix) {
  // Returns a new, unused directory name, adding characters to the
  // end of prefix.
  // Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value must be freed by the caller.
  PathBuffer path;
  const wchar_t* system_prefix = StringUtils::Utf8ToWide(prefix);
  path.AddW(system_prefix);
  free(const_cast<wchar_t*>(system_prefix));

  // Length of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 36.
  if (path.length() > MAX_LONG_PATH - 36) {
    return NULL;
  }

  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if (status != RPC_S_OK && status != RPC_S_UUID_LOCAL_ONLY) {
    return NULL;
  }
  RPC_WSTR uuid_string;
  status = UuidToStringW(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    return NULL;
  }

  // RPC_WSTR is an unsigned short*, so we cast to wchar_t*.
  path.AddW(reinterpret_cast<wchar_t*>(uuid_string));
  RpcStringFreeW(&uuid_string);
  if (!CreateDirectoryW(path.AsStringW(), NULL)) {
    return NULL;
  }
  char* result = path.AsString();
  return result;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  bool result = false;
  const wchar_t* system_dir_name = StringUtils::Utf8ToWide(dir_name);
  if (!recursive) {
    if (File::GetType(dir_name, true) == File::kIsDirectory) {
      result = (RemoveDirectoryW(system_dir_name) != 0);
    } else {
      SetLastError(ERROR_FILE_NOT_FOUND);
    }
  } else {
    PathBuffer path;
    if (path.AddW(system_dir_name)) {
      result = DeleteRecursively(&path);
    }
  }
  free(const_cast<wchar_t*>(system_dir_name));
  return result;
}


bool Directory::Rename(const char* path, const char* new_path) {
  const wchar_t* system_path = StringUtils::Utf8ToWide(path);
  const wchar_t* system_new_path = StringUtils::Utf8ToWide(new_path);
  ExistsResult exists = ExistsHelper(system_path);
  if (exists != EXISTS) return false;
  ExistsResult new_exists = ExistsHelper(system_new_path);
  // MoveFile does not allow replacing exising directories. Therefore,
  // if the new_path is currently a directory we need to delete it
  // first.
  if (new_exists == EXISTS) {
    bool success = Delete(new_path, true);
    if (!success) return false;
  }
  DWORD flags = MOVEFILE_WRITE_THROUGH;
  int move_status =
      MoveFileExW(system_path, system_new_path, flags);
  free(const_cast<wchar_t*>(system_path));
  free(const_cast<wchar_t*>(system_new_path));
  return (move_status != 0);
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
