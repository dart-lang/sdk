// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_NAMESPACE_FUCHSIA_H_
#define RUNTIME_BIN_NAMESPACE_FUCHSIA_H_

#include "platform/globals.h"
#if !defined(HOST_OS_FUCHSIA)
#error "This header file should only be included when targeting Fuchsia."
#endif

#include <lib/fdio/namespace.h>

namespace dart {
namespace bin {

class NamespaceImpl {
 public:
  explicit NamespaceImpl(fdio_ns_t* fdio_ns);
  explicit NamespaceImpl(const char* path);
  ~NamespaceImpl();

  intptr_t rootfd() const { return rootfd_; }
  char* cwd() const { return cwd_; }
  intptr_t cwdfd() const { return cwdfd_; }
  fdio_ns_t* fdio_ns() const { return fdio_ns_; }

  bool SetCwd(Namespace* namespc, const char* new_path);

 private:
  fdio_ns_t* fdio_ns_;  // native namespace object, if any.
  intptr_t rootfd_;     // dirfd for the namespace root.
  char* cwd_;           // cwd relative to the namespace.
  intptr_t cwdfd_;      // dirfd for the cwd.

  DISALLOW_COPY_AND_ASSIGN(NamespaceImpl);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_NAMESPACE_FUCHSIA_H_
