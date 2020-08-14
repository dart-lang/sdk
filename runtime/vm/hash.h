// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_H_
#define RUNTIME_VM_HASH_H_

#include "platform/globals.h"

namespace dart {

inline uint32_t CombineHashes(uint32_t hash, uint32_t other_hash) {
  hash += other_hash;
  hash += hash << 10;
  hash ^= hash >> 6;  // Logical shift, unsigned hash.
  return hash;
}

inline uint32_t FinalizeHash(uint32_t hash, intptr_t hashbits) {
  hash += hash << 3;
  hash ^= hash >> 11;  // Logical shift, unsigned hash.
  hash += hash << 15;
  // FinalizeHash gets called with values for hashbits that are bigger than 31
  // (like kBitsPerWord - 1).  Therefore we are careful to use a type
  // (uintptr_t) big enough to avoid undefined behavior with the left shift.
  hash &= (static_cast<uintptr_t>(1) << hashbits) - 1;
  return (hash == 0) ? 1 : hash;
}

inline uint32_t HashBytes(const uint8_t* bytes, intptr_t size) {
  uint32_t hash = size;
  while (size > 0) {
    hash = CombineHashes(hash, *bytes);
    bytes++;
    size--;
  }
  return hash;
}

}  // namespace dart

#endif  // RUNTIME_VM_HASH_H_
