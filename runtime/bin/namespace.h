// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_NAMESPACE_H_
#define RUNTIME_BIN_NAMESPACE_H_

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/log.h"
#include "bin/reference_counting.h"

namespace dart {
namespace bin {

class NamespaceImpl;

class Namespace : public ReferenceCounted<Namespace> {
 public:
  // Assumes namespc is a value that can be directly used as namespc_.
  static Namespace* Create(intptr_t namespc);

  // Uses path to compute a value that can be used as namespc_.
  static Namespace* Create(const char* path);

  // Gives a safe default value for namespc_ for the standalone Dart VM.
  static intptr_t Default();

  // Tells whether the given namespace is the default namespace.
  static bool IsDefault(Namespace* namespc);

  // Returns the native namespace wrapper if the argument at the supplied index
  // is a _NamespaceImpl object. If it is not, calls Dart_PropagateError().
  static Namespace* GetNamespace(Dart_NativeArguments args, intptr_t index);

  // Get and set the current working directory through the namespace if there
  // is one.
  static const char* GetCurrent(Namespace* namespc);
  static bool SetCurrent(Namespace* namespc, const char* path);

  NamespaceImpl* namespc() const { return namespc_; }

 private:
  // When namespc_ has this value, it indicates that there is currently
  // no namespace for resolving absolute paths.
  static const intptr_t kNone = 0;

  explicit Namespace(NamespaceImpl* namespc)
      : ReferenceCounted(), namespc_(namespc) {}

  ~Namespace();

  // When the native argument at |index| is a _NamespaceImpl object,
  // write the valueof its native field into |namespc|.
  static Dart_Handle GetNativeNamespaceArgument(Dart_NativeArguments args,
                                                intptr_t index,
                                                Namespace** namespc);

  // Given a namespace and a path, computes the information needed to access the
  // path relative to the namespace. This can include massaging the path and
  // returning a platform specific value in dirfd that together are used to
  // access the path.
  static void ResolvePath(Namespace* namespc,
                          const char* path,
                          intptr_t* dirfd,
                          const char** resolved_path);

  NamespaceImpl* namespc_;
  // TODO(zra): When Isolate-specific cwds are added, we'll need some more
  // fields here to track them.

  friend class NamespaceScope;
  friend class ReferenceCounted<Namespace>;
  DISALLOW_COPY_AND_ASSIGN(Namespace);
};

class NamespaceScope {
 public:
  NamespaceScope(Namespace* namespc, const char* path);
  ~NamespaceScope();

  intptr_t fd() const { return fd_; }
  const char* path() const { return path_; }

 private:
  intptr_t fd_;
  const char* path_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(NamespaceScope);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_NAMESPACE_H_
