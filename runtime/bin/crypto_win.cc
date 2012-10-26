// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#define _CRT_RAND_S
#include "bin/crypto.h"


bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  uint32_t num;
  intptr_t read = 0;
  while (read < count) {
    if (rand_s(&num) != 0) {
      return false;
    }
    for (int i = 0; i < 4 && read < count; i++) {
      buffer[read] = num >> (i * 8);
      read++;
    }
  }
  return true;
}
