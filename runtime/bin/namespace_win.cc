// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include "bin/namespace.h"

#include <errno.h>
#include <sys/stat.h>

#include "bin/file.h"
#include "bin/file_win.h"
#include "bin/utils.h"
#include "bin/utils_win.h"

namespace dart {
namespace bin {

Namespace* Namespace::Create(intptr_t namespc) {
  return new Namespace(nullptr);
}

Namespace* Namespace::Create(const char* path) {
  UNIMPLEMENTED();
  return nullptr;
}

Namespace::~Namespace() {
  ASSERT(namespc_ == nullptr);
}

intptr_t Namespace::Default() {
  return kNone;
}

const char* Namespace::GetCurrent(Namespace* namespc) {
  int length = GetCurrentDirectoryW(0, nullptr);
  if (length == 0) {
    return nullptr;
  }
  wchar_t* current;
  current = reinterpret_cast<wchar_t*>(
      Dart_ScopeAllocate((length + 1) * sizeof(*current)));
  GetCurrentDirectoryW(length + 1, current);
  return StringUtilsWin::WideToUtf8(current);
}

bool Namespace::SetCurrent(Namespace* namespc, const char* path) {
  // SetCurrentDirectory does not actually support paths larger than MAX_PATH,
  // this limitation is due to the size of the internal buffer used for storing
  // current directory. In Windows 10, version 1607, changes have been made
  // to the OS to lift MAX_PATH limitations from file and directory management
  // APIs, but both application and OS need to opt-in into new behavior.
  // See https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry#enable-long-paths-in-windows-10-version-1607-and-later
  const auto system_path = Utf8ToWideChar(path);
  bool result = SetCurrentDirectoryW(system_path.get()) != 0;
  return result;
}

void Namespace::ResolvePath(Namespace* namespc,
                            const char* path,
                            intptr_t* dirfd,
                            const char** resolved_path) {
  UNIMPLEMENTED();
}

NamespaceScope::NamespaceScope(Namespace* namespc, const char* path) {
  UNIMPLEMENTED();
}

NamespaceScope::~NamespaceScope() {
  UNIMPLEMENTED();
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
