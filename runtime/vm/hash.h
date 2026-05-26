// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_HASH_H_
#define RUNTIME_VM_HASH_H_

#include "platform/globals.h"

namespace dart {

inline uint32_t CombineHashes(uint32_t hash, uint32_t other_hash) {
  // Keep in sync with AssemblerBase::CombineHashes.
  hash += other_hash;
  hash += hash << 10;
  hash ^= hash >> 6;  // Logical shift, unsigned hash.
  return hash;
}

inline uint32_t FinalizeHash(uint32_t hash, intptr_t hashbits = kBitsPerInt32) {
  // Keep in sync with AssemblerBase::FinalizeHash.
  hash += hash << 3;
  hash ^= hash >> 11;  // Logical shift, unsigned hash.
  hash += hash << 15;
  if (hashbits < kBitsPerInt32) {
    hash &= (static_cast<uint32_t>(1) << hashbits) - 1;
  }
  return (hash == 0) ? 1 : hash;
}

inline uint32_t HashBytes(const void* bytes,
                          intptr_t len,
                          intptr_t hashbits = kBitsPerInt32) {
  if (len == 0) {
    return 1;
  }
  uint32_t hash = len;
  const intptr_t chunks = len / kInt32Size;
  for (intptr_t i = 0; i < chunks; i++) {
    hash = CombineHashes(hash, reinterpret_cast<const uint32_t*>(bytes)[i]);
  }
  for (intptr_t i = chunks * kInt32Size; i < len; i++) {
    hash = CombineHashes(hash, reinterpret_cast<const uint8_t*>(bytes)[i]);
  }
  return FinalizeHash(hash, hashbits);
}

}  // namespace dart

#endif  // RUNTIME_VM_HASH_H_
