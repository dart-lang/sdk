// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include <errno.h>
#include <fcntl.h>
#include <sys/random.h>

#include "bin/crypto.h"
#include "bin/fdutils.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  intptr_t bytes_read = 0;
  do {
    intptr_t chunk_size = count - bytes_read;
    if (chunk_size > 256) {
      chunk_size = 256;
    }
    int res = getentropy(buffer + bytes_read, chunk_size);
    if (res < 0) {
      return false;
    }
    bytes_read += chunk_size;
  } while (bytes_read < count);
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
