// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/namespace.h"

#include <errno.h>
#include <fcntl.h>

#include "bin/fdutils.h"
#include "bin/file.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

Namespace* Namespace::Create(const char* path) {
  const intptr_t fd = TEMP_FAILURE_RETRY(open(path, O_RDONLY));
  if (fd < 0) {
    return NULL;
  }
  return new Namespace(fd);
}

Namespace::~Namespace() {
  if (namespc_ != kNone) {
    VOID_TEMP_FAILURE_RETRY(close(namespc_));
  }
}

intptr_t Namespace::Default() {
  return kNone;
}

const char* Namespace::GetCurrent(Namespace* namespc) {
  if ((namespc == NULL) || (namespc->namespc() == kNone)) {
    // TODO(zra): When there are isolate-specific namespaces, extract it from
    // the namespace instead of calling getcwd.
    char buffer[PATH_MAX];
    if (getcwd(buffer, PATH_MAX) == NULL) {
      return NULL;
    }
    return DartUtils::ScopedCopyCString(buffer);
  }

  // TODO(zra): Allow changing the current working directory when there is
  // a non-default namespace.
  return DartUtils::ScopedCopyCString("/");
}

bool Namespace::SetCurrent(Namespace* namespc, const char* path) {
  if ((namespc == NULL) || (namespc->namespc() == kNone)) {
    return (NO_RETRY_EXPECTED(chdir(path)) == 0);
  }

  // TODO(zra): If a non-default namespace is set up, changing the current
  // working directoy is disallowed. We should relax this restriction when
  // isolate-specific cwds are implemented.
  errno = ENOSYS;
  return false;
}

bool Namespace::ResolvePath(Namespace* namespc,
                            const char* path,
                            intptr_t* dirfd,
                            const char** resolved_path) {
  ASSERT(dirfd != NULL);
  ASSERT(resolved_path != NULL);
  if ((namespc == NULL) || (namespc->namespc() == kNone)) {
    *dirfd = AT_FDCWD;
    *resolved_path = path;
    return false;
  }
  *dirfd = namespc->namespc();
  if (File::IsAbsolutePath(path)) {
    if (strcmp(path, File::PathSeparator()) == 0) {
      *resolved_path = ".";
    } else {
      *resolved_path = &path[1];
    }
  } else {
    *resolved_path = path;
  }
  return false;
}

NamespaceScope::NamespaceScope(Namespace* namespc, const char* path) {
  owns_fd_ = Namespace::ResolvePath(namespc, path, &fd_, &path_);
}

NamespaceScope::~NamespaceScope() {
  if (owns_fd_) {
    FDUtils::SaveErrorAndClose(fd_);
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)
