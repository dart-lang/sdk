// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_FUCHSIA)

#include "bin/directory.h"

#include <errno.h>  // NOLINT
#include <stdlib.h>  // NOLINT
#include <string.h>  // NOLINT
#include <unistd.h>  // NOLINT

namespace dart {
namespace bin {

PathBuffer::PathBuffer() : length_(0) {
  data_ = calloc(PATH_MAX + 1, sizeof(char));  // NOLINT
}


PathBuffer::~PathBuffer() {
  free(data_);
}


bool PathBuffer::AddW(const wchar_t* name) {
  UNREACHABLE();
  return false;
}


char* PathBuffer::AsString() const {
  return reinterpret_cast<char*>(data_);
}


wchar_t* PathBuffer::AsStringW() const {
  UNREACHABLE();
  return NULL;
}


const char* PathBuffer::AsScopedString() const {
  return DartUtils::ScopedCopyCString(AsString());
}


bool PathBuffer::Add(const char* name) {
  const intptr_t name_length = strnlen(name, PATH_MAX + 1);
  if (name_length == 0) {
    errno = EINVAL;
    return false;
  }
  char* data = AsString();
  int written = snprintf(data + length_,
                         PATH_MAX - length_,
                         "%s",
                         name);
  data[PATH_MAX] = '\0';
  if ((written <= (PATH_MAX - length_)) &&
      (written > 0) &&
      (static_cast<size_t>(written) == strnlen(name, PATH_MAX + 1))) {
    length_ += written;
    return true;
  } else {
    errno = ENAMETOOLONG;
    return false;
  }
}


void PathBuffer::Reset(intptr_t new_length) {
  length_ = new_length;
  AsString()[length_] = '\0';
}


ListType DirectoryListingEntry::Next(DirectoryListing* listing) {
  UNIMPLEMENTED();
  return kListError;
}


DirectoryListingEntry::~DirectoryListingEntry() {
  UNIMPLEMENTED();
}


void DirectoryListingEntry::ResetLink() {
  UNIMPLEMENTED();
}


Directory::ExistsResult Directory::Exists(const char* dir_name) {
  UNIMPLEMENTED();
  return UNKNOWN;
}


char* Directory::CurrentNoScope() {
  return getcwd(NULL, 0);
}


const char* Directory::Current() {
  char buffer[PATH_MAX];
  if (getcwd(buffer, PATH_MAX) == NULL) {
    return NULL;
  }
  return DartUtils::ScopedCopyCString(buffer);
}


bool Directory::SetCurrent(const char* path) {
  UNIMPLEMENTED();
  return false;
}


bool Directory::Create(const char* dir_name) {
  UNIMPLEMENTED();
  return false;
}


const char* Directory::SystemTemp() {
  UNIMPLEMENTED();
  return NULL;
}


const char* Directory::CreateTemp(const char* prefix) {
  UNIMPLEMENTED();
  return NULL;
}


bool Directory::Delete(const char* dir_name, bool recursive) {
  UNIMPLEMENTED();
  return false;
}


bool Directory::Rename(const char* path, const char* new_path) {
  UNIMPLEMENTED();
  return false;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
