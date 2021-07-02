// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/namespace.h"
#include "bin/namespace_fuchsia.h"

#include <errno.h>
#include <fcntl.h>
#include <lib/fdio/namespace.h>
#include <zircon/status.h>

#include "bin/file.h"
#include "platform/signal_blocker.h"
#include "platform/text_buffer.h"

namespace dart {
namespace bin {

NamespaceImpl::NamespaceImpl(fdio_ns_t* fdio_ns)
      : fdio_ns_(fdio_ns),
        cwd_(strdup("/")) {
  rootfd_ = fdio_ns_opendir(fdio_ns);
  if (rootfd_ < 0) {
    FATAL2("Failed to open file descriptor for namespace: errno=%d: %s", errno,
           strerror(errno));
  }
  cwdfd_ = dup(rootfd_);
  if (cwdfd_ < 0) {
    FATAL2("Failed to dup() namespace file descriptor: errno=%d: %s", errno,
           strerror(errno));
  }
}

NamespaceImpl::NamespaceImpl(const char* path)
      : fdio_ns_(NULL),
        cwd_(strdup("/")) {
  rootfd_ = TEMP_FAILURE_RETRY(open(path, O_DIRECTORY));
  if (rootfd_ < 0) {
    FATAL2("Failed to open file descriptor for namespace: errno=%d: %s", errno,
           strerror(errno));
  }
  cwdfd_ = dup(rootfd_);
  if (cwdfd_ < 0) {
    FATAL2("Failed to dup() namespace file descriptor: errno=%d: %s", errno,
           strerror(errno));
  }
}

NamespaceImpl::~NamespaceImpl() {
  NO_RETRY_EXPECTED(close(rootfd_));
  free(cwd_);
  NO_RETRY_EXPECTED(close(cwdfd_));
  if (fdio_ns_ != NULL) {
    zx_status_t status = fdio_ns_destroy(fdio_ns_);
    if (status != ZX_OK) {
      Syslog::PrintErr("fdio_ns_destroy: %s\n", zx_status_get_string(status));
    }
  }
}

bool NamespaceImpl::SetCwd(Namespace* namespc, const char* new_path) {
  NamespaceScope ns(namespc, new_path);
  const intptr_t new_cwdfd =
      TEMP_FAILURE_RETRY(openat(ns.fd(), ns.path(), O_DIRECTORY));
  if (new_cwdfd < 0) {
    return false;
  }

  // Build the new cwd.
  TextBuffer tbuf(PATH_MAX);
  if (!File::IsAbsolutePath(new_path)) {
    tbuf.AddString(cwd_);
  }
  tbuf.AddString(File::PathSeparator());
  tbuf.AddString(ns.path());

  // Normalize it.
  char result[PATH_MAX];
  const intptr_t result_len =
      File::CleanUnixPath(tbuf.buffer(), result, PATH_MAX);
  if (result_len < 0) {
    errno = ENAMETOOLONG;
    return false;
  }

  free(cwd_);
  cwd_ = strdup(result);
  close(cwdfd_);
  cwdfd_ = new_cwdfd;
  return true;
}

Namespace* Namespace::Create(intptr_t namespc) {
  NamespaceImpl* namespc_impl = NULL;
  if (namespc != kNone) {
    namespc_impl = new NamespaceImpl(reinterpret_cast<fdio_ns_t*>(namespc));
  }
  return new Namespace(namespc_impl);
}

Namespace* Namespace::Create(const char* path) {
  return new Namespace(new NamespaceImpl(path));
}

Namespace::~Namespace() {
  delete namespc_;
}

intptr_t Namespace::Default() {
  return kNone;
}

const char* Namespace::GetCurrent(Namespace* namespc) {
  if (Namespace::IsDefault(namespc)) {
    char buffer[PATH_MAX];
    if (getcwd(buffer, PATH_MAX) == NULL) {
      return NULL;
    }
    return DartUtils::ScopedCopyCString(buffer);
  }
  return namespc->namespc()->cwd();
}

bool Namespace::SetCurrent(Namespace* namespc, const char* path) {
  if (Namespace::IsDefault(namespc)) {
    return (NO_RETRY_EXPECTED(chdir(path)) == 0);
  }
  return namespc->namespc()->SetCwd(namespc, path);
}

void Namespace::ResolvePath(Namespace* namespc,
                            const char* path,
                            intptr_t* dirfd,
                            const char** resolved_path) {
  ASSERT(dirfd != NULL);
  ASSERT(resolved_path != NULL);
  if (Namespace::IsDefault(namespc)) {
    *dirfd = AT_FDCWD;
    *resolved_path = path;
    return;
  }
  if (File::IsAbsolutePath(path)) {
    *dirfd = namespc->namespc()->rootfd();
    if (strcmp(path, File::PathSeparator()) == 0) {
      // Change "/" to ".".
      *resolved_path = ".";
    } else {
      // Otherwise strip off the leading "/".
      *resolved_path = &path[1];
    }
  } else {
    *dirfd = namespc->namespc()->cwdfd();
    *resolved_path = path;
  }
}

NamespaceScope::NamespaceScope(Namespace* namespc, const char* path) {
  Namespace::ResolvePath(namespc, path, &fd_, &path_);
}

NamespaceScope::~NamespaceScope() {}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
