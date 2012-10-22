// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <fcntl.h>

#include "bin/fdutils.h"
#include "bin/crypto.h"


bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  intptr_t fd = TEMP_FAILURE_RETRY(open("/dev/urandom", O_RDONLY));
  if (fd < 0) return false;
  intptr_t bytes_read = read(fd, buffer, count);
  close(fd);
  return bytes_read == count;
}
