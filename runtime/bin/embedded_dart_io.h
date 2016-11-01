// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_EMBEDDED_DART_IO_H_
#define RUNTIME_BIN_EMBEDDED_DART_IO_H_

namespace dart {
namespace bin {

// Bootstraps 'dart:io'.
void BootstrapDartIo();

// Lets dart:io know where the system temporary directory is located.
// Currently only wired up on Android.
void SetSystemTempDirectory(const char* system_temp);

// Tells the system whether to capture Stdout events.
void SetCaptureStdout(bool value);

// Tells the system whether to capture Stderr events.
void SetCaptureStderr(bool value);

// Should Stdout events be captured?
bool ShouldCaptureStdout();

// Should Stderr events be captured?
bool ShouldCaptureStderr();

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_EMBEDDED_DART_IO_H_
