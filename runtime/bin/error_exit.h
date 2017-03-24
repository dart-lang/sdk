// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_ERROR_EXIT_H_
#define RUNTIME_BIN_ERROR_EXIT_H_

namespace dart {
namespace bin {

// Exit code indicating an internal Dart Frontend error.
static const int kDartFrontendErrorExitCode = 252;
// Exit code indicating an API error.
static const int kApiErrorExitCode = 253;
// Exit code indicating a compilation error.
static const int kCompilationErrorExitCode = 254;
// Exit code indicating an unhandled error that is not a compilation error.
static const int kErrorExitCode = 255;

void ErrorExit(int exit_code, const char* format, ...);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_ERROR_EXIT_H_
