// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "bin/namespace.h"

#include <errno.h>
#include <fcntl.h>

#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

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
  char buffer[PATH_MAX];
  if (getcwd(buffer, PATH_MAX) == NULL) {
    return NULL;
  }
  return DartUtils::ScopedCopyCString(buffer);
}

bool Namespace::SetCurrent(Namespace* namespc, const char* path) {
  int result = NO_RETRY_EXPECTED(chdir(path));
  return (result == 0);
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

#endif  // defined(HOST_OS_MACOS)
