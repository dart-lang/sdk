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

// Returns the directory portion of a given path.
//
// If dir is NULL, the result must be freed by the caller. Otherwise, the
// result is copied into dir.
static char* GetDirectoryFromPath(const char* path, char* dir) {
  const char* sep = File::PathSeparator();
  const intptr_t sep_length = strlen(sep);
  intptr_t path_len = strlen(path);

  for (intptr_t i = path_len - 1; i >= 0; --i) {
    const char* str = path + i;
    if (strncmp(str, sep, sep_length) == 0
#if defined(HOST_OS_WINDOWS)
        // TODO(aam): GetExecutableName doesn't work reliably on Windows,
        || *str == '/'
#endif
    ) {
      if (dir != nullptr) {
        strncpy(dir, path, i);
        dir[i] = '\0';
        return dir;
      } else {
        return Utils::StrNDup(path, i + 1);
      }
    }
  }
  return nullptr;
}

Utils::CStringUniquePtr EXEUtils::GetDirectoryPrefixFromExeName() {
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
    ASSERT(target_size < kTargetSize);
  }
  Namespace* namespc = Namespace::Create(Namespace::Default());
  if (File::GetType(namespc, name, false) == File::kIsLink) {
    char dir_path[kTargetSize];
    // cwd is currently wherever we launched from, so set the cwd to the
    // directory of the symlink while we try and resolve it. If we don't
    // do this, we won't be able to properly resolve relative paths.
    auto initial_dir_path =
        Utils::CreateCStringUniquePtr(Directory::CurrentNoScope());
    // We might run into symlinks of symlinks, so make sure we follow the
    // links all the way. See https://github.com/dart-lang/sdk/issues/41057 for
    // an example where this happens with brew on MacOS.
    do {
      Directory::SetCurrent(namespc, GetDirectoryFromPath(name, dir_path));
      // Resolve the link without creating Dart scope String.
      name = File::LinkTarget(namespc, name, target, kTargetSize);
      if (name == nullptr) {
        return Utils::CreateCStringUniquePtr(strdup(""));
      }
    } while (File::GetType(namespc, name, false) == File::kIsLink);
    target_size = strlen(name);

    // Reset cwd to the original value.
    Directory::SetCurrent(namespc, initial_dir_path.get());
  }
  namespc->Release();
  char* result = GetDirectoryFromPath(name, nullptr);
  return Utils::CreateCStringUniquePtr(result == nullptr ? strdup("") : result);
}

}  // namespace bin
}  // namespace dart
