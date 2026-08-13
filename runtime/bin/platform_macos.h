// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PLATFORM_MACOS_H_
#define RUNTIME_BIN_PLATFORM_MACOS_H_

#if !defined(RUNTIME_BIN_PLATFORM_H_)
#error Do not include platform_macos.h directly;
#error use platform.h instead.
#endif

namespace dart {
namespace bin {

// This function extracts OSVersion from SystemVersion.plist.
// The format of input should be:
//   <key>ProductVersion</key>
//   <string>10.15.4</string>
// Returns the string representation of OSVersion. For example, "10.15.4" will
// be returned in the previous example.
char* ExtractsOSVersionFromString(char* str);

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PLATFORM_MACOS_H_
