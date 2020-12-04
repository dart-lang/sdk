// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

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
  return new Namespace(NULL);
}

Namespace* Namespace::Create(const char* path) {
  UNIMPLEMENTED();
  return NULL;
}

Namespace::~Namespace() {
  ASSERT(namespc_ == NULL);
}

intptr_t Namespace::Default() {
  return kNone;
}

const char* Namespace::GetCurrent(Namespace* namespc) {
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

bool Namespace::SetCurrent(Namespace* namespc, const char* path) {
  // TODO(zichangguo): "\\?\" prepended long path doesn't work.
  // https://github.com/dart-lang/sdk/issues/42416
  path = PrefixLongDirectoryPath(path);
  Utf8ToWideScope system_path(path);
  bool result = SetCurrentDirectoryW(system_path.wide()) != 0;
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

#endif  // defined(HOST_OS_WINDOWS)
