// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/exe_utils.h"

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/platform.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

char* EXEUtils::GetDirectoryPrefixFromExeName() {
  const char* name = nullptr;
  const int kTargetSize = 4096;
  char target[kTargetSize];
  intptr_t target_size =
      Platform::ResolveExecutablePathInto(target, kTargetSize);
  if (target_size > 0 && target_size < kTargetSize - 1) {
    target[target_size] = 0;
    name = target;
  }
  if (name == nullptr) {
    name = Platform::GetExecutableName();
    target_size = strlen(name);
  }
  Namespace* namespc = Namespace::Create(Namespace::Default());

  // We might run into symlinks of symlinks, so make sure we follow the
  // links all the way. See https://github.com/dart-lang/sdk/issues/41057 for
  // an example where this happens with brew on MacOS.
  bool followedSymlink = false;
  while (File::GetType(namespc, name, false) == File::kIsLink) {
    // Resolve the link without creating Dart scope String.
    name = File::LinkTarget(namespc, name, target, kTargetSize);
    if (name == NULL) {
      return strdup("");
    }
    followedSymlink = true;
  }
  if (followedSymlink) {
    target_size = strlen(name);
  }
  namespc->Release();
  const char* sep = File::PathSeparator();
  const intptr_t sep_length = strlen(sep);

  for (intptr_t i = target_size - 1; i >= 0; --i) {
    const char* str = name + i;
    if (strncmp(str, sep, sep_length) == 0
#if defined(HOST_OS_WINDOWS)
        // TODO(aam): GetExecutableName doesn't work reliably on Windows,
        // the code below is a workaround for that (we would be using
        // just single Platform::Separator instead of both slashes if it did).
        || *str == '/'
#endif
    ) {
      return Utils::StrNDup(name, i + 1);
    }
  }
  return strdup("");
}

}  // namespace bin
}  // namespace dart
