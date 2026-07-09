// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include <Security/Security.h>

#include "bin/crypto.h"

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  return SecRandomCopyBytes(kSecRandomDefault, count, buffer) == errSecSuccess;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
