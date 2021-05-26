// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include <bcrypt.h>
#include "bin/crypto.h"

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  return SUCCEEDED(BCryptGenRandom(NULL, buffer, (ULONG)count,
                                   BCRYPT_USE_SYSTEM_PREFERRED_RNG));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
