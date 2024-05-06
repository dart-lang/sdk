// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_FILE_WIN_H_
#define RUNTIME_BIN_FILE_WIN_H_

#include <memory>

#include "bin/file.h"

// The limit for a regular directory is 248.
// Reference: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#maximum-path-length-limitation
#define MAX_DIRECTORY_PATH (MAX_PATH - 12)

namespace dart {
namespace bin {

// Converts the given UTF8 path to wide char. If resulting path does not
// fit into MAX_DIRECTORY_PATH (or if |force_long_prefix| is true) then
// converts the path to the absolute `\\?\`-prefixed form.
//
// Note:
// 1. Some WinAPI functions (like SetCurrentDirectoryW) are always limited
//    to MAX_PATH long paths and converting to `\\?\`-prefixed form does not
//    remove this limitation. Always check Win API documentation.
// 2. This function might change relative path to an absolute path.
std::unique_ptr<wchar_t[]> ToWinAPIDirectoryPath(
    const char* path,
    bool force_long_prefix = false);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_FILE_WIN_H_
