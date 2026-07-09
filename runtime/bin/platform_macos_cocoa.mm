// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"

#if !defined(DART_HOST_OS_MACOS)
#error Do not build platform_macos_cocoa.mm on non-MacOS platforms.
#endif

#include "bin/platform_macos_cocoa.h"

#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>

namespace dart {
namespace bin {

std::string NSProcessInfoOperatingSystemVersionString() {
  @autoreleasepool {
    // `operatingSystemVersionString` has been available since iOS 2.0+ and macOS 10.2+.
    NSString* version =
        [[NSProcessInfo processInfo] operatingSystemVersionString];
    return std::string([version UTF8String]);
  }
}

}  // namespace bin
}  // namespace dart
