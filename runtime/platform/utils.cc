// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/utils.h"

namespace dart {

// Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
// figure 3-3, page 48, where the function is called clp2.
uintptr_t Utils::RoundUpToPowerOfTwo(uintptr_t x) {
  x = x - 1;
  x = x | (x >> 1);
  x = x | (x >> 2);
  x = x | (x >> 4);
  x = x | (x >> 8);
  x = x | (x >> 16);
#if defined(ARCH_IS_64_BIT)
  x = x | (x >> 32);
#endif  // defined(ARCH_IS_64_BIT)
  return x + 1;
}


// Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
// figure 5-2, page 66, where the function is called pop.
int Utils::CountOneBits(uint32_t x) {
  x = x - ((x >> 1) & 0x55555555);
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F;
  x = x + (x >> 8);
  x = x + (x >> 16);
  return static_cast<int>(x & 0x0000003F);
}


int Utils::HighestBit(int64_t v) {
  uint64_t x = static_cast<uint64_t>((v > 0) ? v : -v);
  uint64_t t;
  int r = 0;
  if ((t = x >> 32) != 0) { x = t; r += 32; }
  if ((t = x >> 16) != 0) { x = t; r += 16; }
  if ((t = x >> 8) != 0) { x = t; r += 8; }
  if ((t = x >> 4) != 0) { x = t; r += 4; }
  if ((t = x >> 2) != 0) { x = t; r += 2; }
  if (x > 1) r += 1;
  return r;
}


uint32_t Utils::StringHash(const char* data, int length) {
  // This implementation is based on the public domain MurmurHash
  // version 2.0. It assumes that the underlying CPU can read from
  // unaligned addresses. The constants M and R have been determined
  // to work well experimentally.
  // TODO(3158902): need to account for unaligned address access on ARM.
  const uint32_t M = 0x5bd1e995;
  const int R = 24;
  int size = length;
  uint32_t hash = size;

  // Mix four bytes at a time into the hash.
  const uint8_t* cursor = reinterpret_cast<const uint8_t*>(data);
  while (size >= 4) {
    uint32_t part = *reinterpret_cast<const uint32_t*>(cursor);
    part *= M;
    part ^= part >> R;
    part *= M;
    hash *= M;
    hash ^= part;
    cursor += 4;
    size -= 4;
  }

  // Handle the last few bytes of the string.
  switch (size) {
    case 3:
      hash ^= cursor[2] << 16;
    case 2:
      hash ^= cursor[1] << 8;
    case 1:
      hash ^= cursor[0];
      hash *= M;
  }

  // Do a few final mixes of the hash to ensure the last few bytes are
  // well-incorporated.
  hash ^= hash >> 13;
  hash *= M;
  hash ^= hash >> 15;
  return hash;
}


uint32_t Utils::WordHash(word key) {
  // TODO(iposva): Need to check hash spreading.
  // This example is from http://www.concentric.net/~Ttwang/tech/inthash.htm
  uword a = static_cast<uword>(key);
  a = (a + 0x7ed55d16) + (a << 12);
  a = (a ^ 0xc761c23c) ^ (a >> 19);
  a = (a + 0x165667b1) + (a << 5);
  a = (a + 0xd3a2646c) ^ (a << 9);
  a = (a + 0xfd7046c5) + (a << 3);
  a = (a ^ 0xb55a4f09) ^ (a >> 16);
  return static_cast<uint32_t>(a);
}


}  // namespace dart
