// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include "bin/directory.h"
#include "bin/file.h"

#include <errno.h>  // NOLINT
#include <sys/stat.h>  // NOLINT

#include "bin/log.h"

class PathBuffer {
 public:
  PathBuffer() : length(0) {
    data = new wchar_t[MAX_PATH + 1];
  }

  ~PathBuffer() {
    delete[] data;
  }

  wchar_t* data;
  int length;

  bool Add(const wchar_t* name) {
    int written = _snwprintf(data + length,
                             MAX_PATH - length,
                             L"%s",
                             name);
    data[MAX_PATH] = L'\0';
    if (written <= MAX_PATH - length &&
        written >= 0 &&
        static_cast<size_t>(written) == wcsnlen(name, MAX_PATH + 1)) {
      length += written;
      return true;
    } else {
      SetLastError(ERROR_BUFFER_OVERFLOW);
      return false;
    }
  }

  void Reset(int new_length) {
    length = new_length;
    data[length] = L'\0';
  }
};

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
static bool ListRecursively(PathBuffer* path,
                            bool recursive,
                            bool follow_links,
                            LinkList* seen,
                            DirectoryListing* listing);
static bool DeleteRecursively(PathBuffer* path);


static void PostError(DirectoryListing* listing,
                      const wchar_t* dir_name) {
  const char* utf8_path = StringUtils::WideToUtf8(dir_name);
  listing->HandleError(utf8_path);
  free(const_cast<char*>(utf8_path));
}


static bool HandleDir(wchar_t* dir_name,
                      PathBuffer* path,
                      bool recursive,
                      bool follow_links,
                      LinkList* seen,
                      DirectoryListing* listing) {
  if (wcscmp(dir_name, L".") == 0) return true;
  if (wcscmp(dir_name, L"..") == 0) return true;
  if (!path->Add(dir_name)) {
    PostError(listing, path->data);
    return false;
  }
  char* utf8_path = StringUtils::WideToUtf8(path->data);
  bool ok = listing->HandleDirectory(utf8_path);
  free(utf8_path);
  return ok &&
      (!recursive ||
       ListRecursively(path, recursive, follow_links, seen, listing));
}


static bool HandleFile(wchar_t* file_name,
                       PathBuffer* path,
                       DirectoryListing* listing) {
  if (!path->Add(file_name)) {
    PostError(listing, path->data);
    return false;
  }
  char* utf8_path = StringUtils::WideToUtf8(path->data);
  bool ok = listing->HandleFile(utf8_path);
  free(utf8_path);
  return ok;
}


static bool HandleLink(wchar_t* link_name,
                       PathBuffer* path,
                       DirectoryListing* listing) {
  if (!path->Add(link_name)) {
    PostError(listing, path->data);
    return false;
  }
  char* utf8_path = StringUtils::WideToUtf8(path->data);
  bool ok = listing->HandleLink(utf8_path);
  free(utf8_path);
  return ok;
}


static bool HandleEntry(LPWIN32_FIND_DATAW find_file_data,
                        PathBuffer* path,
                        bool recursive,
                        bool follow_links,
                        LinkList* seen,
                        DirectoryListing* listing) {
  DWORD attributes = find_file_data->dwFileAttributes;
  if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    if (!follow_links) {
      return HandleLink(find_file_data->cFileName, path, listing);
    }
    int path_length = path->length;
    if (!path->Add(find_file_data->cFileName)) return false;
    HANDLE handle = CreateFileW(
        path->data,
        0,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS,
        NULL);
    path->Reset(path_length);
    if (handle == INVALID_HANDLE_VALUE) {
      // Report as (broken) link.
      return HandleLink(find_file_data->cFileName, path, listing);
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
        PostError(listing, path->data);
        return false;
      }
      CloseHandle(handle);
      current_link.volume = info.dwVolumeSerialNumber;
      current_link.id_low = info.nFileIndexLow;
      current_link.id_high = info.nFileIndexHigh;
      current_link.next = seen;
      LinkList* previous = seen;
      while (previous != NULL) {
        if (previous->volume == current_link.volume &&
            previous->id_low == current_link.id_low &&
            previous->id_high == current_link.id_high) {
          // Report the looping link as a link, rather than following it.
          return HandleLink(find_file_data->cFileName, path, listing);
        }
        previous = previous->next;
      }
      // Recurse into the directory, adding current link to the seen links list.
      return HandleDir(find_file_data->cFileName,
                       path,
                       recursive,
                       follow_links,
                       &current_link,
                       listing);
    }
  }
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return HandleDir(find_file_data->cFileName,
                     path,
                     recursive,
                     follow_links,
                     seen,
                     listing);
  } else {
    return HandleFile(find_file_data->cFileName, path, listing);
  }
}


static bool ListRecursively(PathBuffer* path,
                            bool recursive,
                            bool follow_links,
                            LinkList* seen,
                            DirectoryListing* listing) {
  if (!path->Add(L"\\*")) {
    PostError(listing, path->data);
    return false;
  }

  WIN32_FIND_DATAW find_file_data;
  HANDLE find_handle = FindFirstFileW(path->data, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  path->Reset(path->length - 1);

  if (find_handle == INVALID_HANDLE_VALUE) {
    PostError(listing, path->data);
    return false;
  }

  int path_length = path->length;
  bool success = HandleEntry(&find_file_data,
                             path,
                             recursive,
                             follow_links,
                             seen,
                             listing);

  while ((FindNextFileW(find_handle, &find_file_data) != 0)) {
    path->Reset(path_length);  // HandleEntry adds the entry name to path.
    success = HandleEntry(&find_file_data,
                          path,
                          recursive,
                          follow_links,
                          seen,
                          listing) && success;
  }

  if (GetLastError() != ERROR_NO_MORE_FILES) {
    success = false;
    PostError(listing, path->data);
  }

  if (FindClose(find_handle) == 0) {
    success = false;
    PostError(listing, path->data);
  }

  return success;
}


static bool DeleteFile(wchar_t* file_name, PathBuffer* path) {
  if (!path->Add(file_name)) return false;

  if (DeleteFileW(path->data) != 0) {
    return true;
  }

  // If we failed because the file is read-only, make it writeable and try
  // again. This mirrors Linux/Mac where a directory containing read-only files
  // can still be recursively deleted.
  if (GetLastError() == ERROR_ACCESS_DENIED) {
    DWORD attributes = GetFileAttributesW(path->data);
    if (attributes == INVALID_FILE_ATTRIBUTES) {
      return false;
    }

    if ((attributes & FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY) {
      attributes &= ~FILE_ATTRIBUTE_READONLY;

      if (SetFileAttributesW(path->data, attributes) == 0) {
        return false;
      }

      return DeleteFileW(path->data) != 0;
    }
  }

  return false;
}


static bool DeleteDir(wchar_t* dir_name, PathBuffer* path) {
  if (wcscmp(dir_name, L".") == 0) return true;
  if (wcscmp(dir_name, L"..") == 0) return true;
  return path->Add(dir_name) && DeleteRecursively(path);
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
  DWORD attributes = GetFileAttributesW(path->data);
  if ((attributes == INVALID_FILE_ATTRIBUTES)) {
    return false;
  }
  // If the directory is a junction, it's pointing to some other place in the
  // filesystem that we do not want to recurse into.
  if ((attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
    // Just delete the junction itself.
    return RemoveDirectoryW(path->data) != 0;
  }
  // If it's a file, remove it directly.
  if ((attributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
    return DeleteFile(L"", path);
  }

  if (!path->Add(L"\\*")) return false;

  WIN32_FIND_DATAW find_file_data;
  HANDLE find_handle = FindFirstFileW(path->data, &find_file_data);

  // Adjust the path by removing the '*' used for the search.
  int path_length = path->length - 1;
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
      (RemoveDirectoryW(path->data) == 0)) {
    return false;
  }

  return success;
}


bool Directory::List(const char* dir_name,
                     bool recursive,
                     bool follow_links,
                     DirectoryListing* listing) {
  const wchar_t* system_name = StringUtils::Utf8ToWide(dir_name);
  PathBuffer path;
  if (!path.Add(system_name)) {
    PostError(listing, system_name);
    return false;
  }
  free(const_cast<wchar_t*>(system_name));
  return ListRecursively(&path, recursive, follow_links, NULL, listing);
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
  wchar_t* current = new wchar_t[length + 1];
  GetCurrentDirectoryW(length + 1, current);
  char* result = StringUtils::WideToUtf8(current);
  delete[] current;
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


char* Directory::CreateTemp(const char* const_template) {
  // Returns a new, unused directory name, modifying the contents of
  // dir_template.  Creates this directory, with a default security
  // descriptor inherited from its parent directory.
  // The return value must be freed by the caller.
  PathBuffer path;
  if (0 == strncmp(const_template, "", 1)) {
    path.length = GetTempPathW(MAX_PATH, path.data);
    if (path.length == 0) {
      return NULL;
    }
  } else {
    const wchar_t* system_template = StringUtils::Utf8ToWide(const_template);
    path.Add(system_template);
    free(const_cast<wchar_t*>(system_template));
  }
  // Length of tempdir-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx is 44.
  if (path.length > MAX_PATH - 44) {
    return NULL;
  }
  if ((path.data)[path.length - 1] == L'\\') {
    // No base name for the directory - use "tempdir".
    path.Add(L"tempdir");
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

  path.Add(L"-");
  // RPC_WSTR is an unsigned short*, so we cast to wchar_t*.
  path.Add(reinterpret_cast<wchar_t*>(uuid_string));
  RpcStringFreeW(&uuid_string);
  if (!CreateDirectoryW(path.data, NULL)) {
    return NULL;
  }
  char* result = StringUtils::WideToUtf8(path.data);
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
    if (path.Add(system_dir_name)) {
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

#endif  // defined(TARGET_OS_WINDOWS)
