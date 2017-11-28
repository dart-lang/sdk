// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "bin/namespace.h"

#include <errno.h>
#include <fcntl.h>

#include "bin/file.h"
#include "platform/signal_blocker.h"
#include "platform/text_buffer.h"

namespace dart {
namespace bin {

class NamespaceImpl {
 public:
  explicit NamespaceImpl(intptr_t rootfd) : rootfd_(rootfd), cwd_(strdup("/")) {
    ASSERT(rootfd_ > 0);
    cwdfd_ = dup(rootfd_);
    ASSERT(cwdfd_ > 0);
  }

  explicit NamespaceImpl(const char* path)
      : rootfd_(TEMP_FAILURE_RETRY(open64(path, O_DIRECTORY))),
        cwd_(strdup("/")) {
    ASSERT(rootfd_ > 0);
    cwdfd_ = dup(rootfd_);
    ASSERT(cwdfd_ > 0);
  }

  ~NamespaceImpl() {
    NO_RETRY_EXPECTED(close(rootfd_));
    free(cwd_);
    NO_RETRY_EXPECTED(close(cwdfd_));
  }

  intptr_t rootfd() const { return rootfd_; }
  char* cwd() const { return cwd_; }
  intptr_t cwdfd() const { return cwdfd_; }

  bool SetCwd(Namespace* namespc, const char* new_path) {
    NamespaceScope ns(namespc, new_path);
    const intptr_t new_cwdfd =
        TEMP_FAILURE_RETRY(openat64(ns.fd(), ns.path(), O_DIRECTORY));
    if (new_cwdfd < 0) {
      return false;
    }

    TextBuffer tbuf(PATH_MAX);
    if (!File::IsAbsolutePath(new_path)) {
      tbuf.AddString(cwd_);
    }
    tbuf.AddString(File::PathSeparator());
    tbuf.AddString(ns.path());

    // Normalize it.
    char result[PATH_MAX];
    const intptr_t result_len =
        File::CleanUnixPath(tbuf.buf(), result, PATH_MAX);
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

 private:
  intptr_t rootfd_;  // dirfd for the namespace root.
  char* cwd_;        // cwd relative to the namespace.
  intptr_t cwdfd_;   // dirfd for the cwd.

  DISALLOW_COPY_AND_ASSIGN(NamespaceImpl);
};

Namespace* Namespace::Create(intptr_t namespc) {
  NamespaceImpl* namespc_impl = NULL;
  if (namespc != kNone) {
    namespc_impl = new NamespaceImpl(namespc);
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
  const char* cwd = namespc->namespc()->cwd();
  return cwd;
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

#endif  // defined(HOST_OS_LINUX)
