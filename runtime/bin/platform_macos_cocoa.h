// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PLATFORM_MACOS_COCOA_H_
#define RUNTIME_BIN_PLATFORM_MACOS_COCOA_H_

// platform_macos_cocoa[.h,.mm] defines a new compilation unit, written
// in Objective-C++, that acts as a minimal bridge between platform_macos
// and the Cocoa (https://en.wikipedia.org/wiki/Cocoa_(API)) API.

#include "platform/globals.h"

#if !defined(DART_HOST_OS_MACOS)
#error Do not include platform_macos_cocoa.h on non-MacOS platforms.
#endif

#include <string>

namespace dart {
namespace bin {

// Return the operating system version string.
// See https://developer.apple.com/documentation/foundation/nsprocessinfo/1408730-operatingsystemversionstring.
std::string NSProcessInfoOperatingSystemVersionString();

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PLATFORM_MACOS_COCOA_H_
