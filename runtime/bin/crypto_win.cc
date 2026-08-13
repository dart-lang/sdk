// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_WINDOWS)

#include <bcrypt.h>
#include "bin/crypto.h"

namespace dart {
namespace bin {

// see https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptgenrandom
#ifndef NT_SUCCESS
#define NT_SUCCESS(Status) ((NTSTATUS)(Status) >= 0)
#endif

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  if (count <= 0) {
    return true;
  }
  return NT_SUCCESS(BCryptGenRandom(/*hAlgorithm=*/nullptr, buffer,
                                    (ULONG)count,
                                    BCRYPT_USE_SYSTEM_PREFERRED_RNG));
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS)
