// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/utils.h"

#include "platform/allocation.h"

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

int Utils::CountOneBits64(uint64_t x) {
  // Apparently there are x64 chips without popcount.
#if __GNUC__ && !defined(HOST_ARCH_IA32) && !defined(HOST_ARCH_X64)
  return __builtin_popcountll(x);
#else
  return CountOneBits32(static_cast<uint32_t>(x)) +
         CountOneBits32(static_cast<uint32_t>(x >> 32));
#endif
}

int Utils::CountOneBits32(uint32_t x) {
  // Apparently there are x64 chips without popcount.
#if __GNUC__ && !defined(HOST_ARCH_IA32) && !defined(HOST_ARCH_X64)
  return __builtin_popcount(x);
#else
  // Implementation is from "Hacker's Delight" by Henry S. Warren, Jr.,
  // figure 5-2, page 66, where the function is called pop.
  x = x - ((x >> 1) & 0x55555555);
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
  x = (x + (x >> 4)) & 0x0F0F0F0F;
  x = x + (x >> 8);
  x = x + (x >> 16);
  return static_cast<int>(x & 0x0000003F);
#endif
}

// TODO(koda): Compare to flsll call/intrinsic.
int Utils::HighestBit(int64_t v) {
  uint64_t x = static_cast<uint64_t>((v > 0) ? v : -v);
  uint64_t t;
  int r = 0;
  if ((t = x >> 32) != 0) {
    x = t;
    r += 32;
  }
  if ((t = x >> 16) != 0) {
    x = t;
    r += 16;
  }
  if ((t = x >> 8) != 0) {
    x = t;
    r += 8;
  }
  if ((t = x >> 4) != 0) {
    x = t;
    r += 4;
  }
  if ((t = x >> 2) != 0) {
    x = t;
    r += 2;
  }
  if (x > 1) r += 1;
  return r;
}

int Utils::CountLeadingZeros64(uint64_t x) {
#if defined(ARCH_IS_32_BIT)
  const uint32_t x_hi = static_cast<uint32_t>(x >> 32);
  if (x_hi != 0) {
    return CountLeadingZeros32(x_hi);
  }
  return 32 + CountLeadingZeros32(static_cast<uint32_t>(x));
#elif defined(HOST_OS_WINDOWS)
  unsigned long position;  // NOLINT
  return (_BitScanReverse64(&position, x) == 0)
             ? 64
             : 63 - static_cast<int>(position);
#else
  return x == 0 ? 64 : __builtin_clzll(x);
#endif
}

int Utils::CountLeadingZeros32(uint32_t x) {
#if defined(HOST_OS_WINDOWS)
  unsigned long position;  // NOLINT
  return (_BitScanReverse(&position, x) == 0) ? 32
                                              : 31 - static_cast<int>(position);
#else
  return x == 0 ? 32 : __builtin_clz(x);
#endif
}

int Utils::CountTrailingZeros64(uint64_t x) {
#if defined(ARCH_IS_32_BIT)
  const uint32_t x_lo = static_cast<uint32_t>(x);
  if (x_lo != 0) {
    return CountTrailingZeros32(x_lo);
  }
  return 32 + CountTrailingZeros32(static_cast<uint32_t>(x >> 32));
#elif defined(HOST_OS_WINDOWS)
  unsigned long position;  // NOLINT
  return (_BitScanForward64(&position, x) == 0) ? 64
                                                : static_cast<int>(position);
#else
  return x == 0 ? 64 : __builtin_ctzll(x);
#endif
}

int Utils::CountTrailingZeros32(uint32_t x) {
#if defined(HOST_OS_WINDOWS)
  unsigned long position;  // NOLINT
  return (_BitScanForward(&position, x) == 0) ? 32 : static_cast<int>(position);
#else
  return x == 0 ? 32 : __builtin_ctz(x);
#endif
}

uint64_t Utils::ReverseBits64(uint64_t x) {
  const uint64_t one = static_cast<uint64_t>(1);
  uint64_t result = 0;
  for (uint64_t rbit = one << 63; x != 0; x >>= 1) {
    if ((x & one) != 0) result |= rbit;
    rbit >>= 1;
  }
  return result;
}

uint32_t Utils::ReverseBits32(uint32_t x) {
  const uint32_t one = static_cast<uint32_t>(1);
  uint32_t result = 0;
  for (uint32_t rbit = one << 31; x != 0; x >>= 1) {
    if ((x & one) != 0) result |= rbit;
    rbit >>= 1;
  }
  return result;
}

// Implementation according to H.S.Warren's "Hacker's Delight"
// (Addison Wesley, 2002) Chapter 10 and T.Grablund, P.L.Montogomery's
// "Division by Invariant Integers Using Multiplication" (PLDI 1994).
void Utils::CalculateMagicAndShiftForDivRem(int64_t divisor,
                                            int64_t* magic,
                                            int64_t* shift) {
  ASSERT(divisor <= -2 || divisor >= 2);
  /* The magic number M and shift S can be calculated in the following way:
   * Let nc be the most positive value of numerator(n) such that nc = kd - 1,
   * where divisor(d) >= 2.
   * Let nc be the most negative value of numerator(n) such that nc = kd + 1,
   * where divisor(d) <= -2.
   * Thus nc can be calculated like:
   * nc =  exp + exp       % d - 1, where d >= 2 and exp = 2^63.
   * nc = -exp + (exp + 1) % d,     where d >= 2 and exp = 2^63.
   *
   * So the shift p is the smallest p satisfying
   * 2^p > nc * (d - 2^p % d), where d >= 2
   * 2^p > nc * (d + 2^p % d), where d <= -2.
   *
   * The magic number M is calculated by
   * M = (2^p + d - 2^p % d) / d, where d >= 2
   * M = (2^p - d - 2^p % d) / d, where d <= -2.
   */
  int64_t p = 63;
  const uint64_t exp = 1LL << 63;

  // Initialize the computations.
  uint64_t abs_d = (divisor >= 0) ? divisor : -static_cast<uint64_t>(divisor);
  uint64_t sign_bit = static_cast<uint64_t>(divisor) >> 63;
  uint64_t tmp = exp + sign_bit;
  uint64_t abs_nc = tmp - 1 - (tmp % abs_d);
  uint64_t quotient1 = exp / abs_nc;
  uint64_t remainder1 = exp % abs_nc;
  uint64_t quotient2 = exp / abs_d;
  uint64_t remainder2 = exp % abs_d;

  // To avoid handling both positive and negative divisor,
  // "Hacker's Delight" introduces a method to handle these
  // two cases together to avoid duplication.
  uint64_t delta;
  do {
    p++;
    quotient1 = 2 * quotient1;
    remainder1 = 2 * remainder1;
    if (remainder1 >= abs_nc) {
      quotient1++;
      remainder1 = remainder1 - abs_nc;
    }
    quotient2 = 2 * quotient2;
    remainder2 = 2 * remainder2;
    if (remainder2 >= abs_d) {
      quotient2++;
      remainder2 = remainder2 - abs_d;
    }
    delta = abs_d - remainder2;
  } while (quotient1 < delta || (quotient1 == delta && remainder1 == 0));

  *magic = (divisor > 0) ? (quotient2 + 1) : (-quotient2 - 1);
  *shift = p - 64;
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
      FALL_THROUGH;
    case 2:
      hash ^= cursor[1] << 8;
      FALL_THROUGH;
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

uint32_t Utils::WordHash(intptr_t key) {
  // TODO(iposva): Need to check hash spreading.
  // This example is from http://www.concentric.net/~Ttwang/tech/inthash.htm
  // via. http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm
  uword a = static_cast<uword>(key);
  a = (a + 0x7ed55d16) + (a << 12);
  a = (a ^ 0xc761c23c) ^ (a >> 19);
  a = (a + 0x165667b1) + (a << 5);
  a = (a + 0xd3a2646c) ^ (a << 9);
  a = (a + 0xfd7046c5) + (a << 3);
  a = (a ^ 0xb55a4f09) ^ (a >> 16);
  return static_cast<uint32_t>(a);
}

char* Utils::SCreate(const char* format, ...) {
  va_list args;
  va_start(args, format);
  char* buffer = VSCreate(format, args);
  va_end(args);
  return buffer;
}

char* Utils::VSCreate(const char* format, va_list args) {
  // Measure.
  va_list measure_args;
  va_copy(measure_args, args);
  intptr_t len = VSNPrint(NULL, 0, format, measure_args);
  va_end(measure_args);

  char* buffer = reinterpret_cast<char*>(malloc(len + 1));
  ASSERT(buffer != NULL);

  // Print.
  va_list print_args;
  va_copy(print_args, args);
  VSNPrint(buffer, len + 1, format, print_args);
  va_end(print_args);
  return buffer;
}

Utils::CStringUniquePtr Utils::CreateCStringUniquePtr(char* str) {
  return std::unique_ptr<char, decltype(std::free)*>{str, std::free};
}

}  // namespace dart
