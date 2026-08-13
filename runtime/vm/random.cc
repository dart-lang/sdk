// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/random.h"

#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(uint64_t,
            random_seed,
            0,
            "Override the random seed for debugging.");

Random::Random() {
  uint64_t seed = FLAG_random_seed;
  if (seed == 0) {
    Dart_EntropySource callback = Dart::entropy_source_callback();
    if (callback != nullptr) {
      if (!callback(reinterpret_cast<uint8_t*>(&seed), sizeof(seed))) {
        // Callback failed. Reset the seed to 0.
        seed = 0;
      }
    }
  }
  if (seed == 0) {
    // We did not get a seed so far. As a fallback we do use the current time.
    seed = OS::GetCurrentTimeMicros();
  }
  Initialize(seed);
}

void Random::Initialize(uint64_t seed) {
  ASSERT(seed != 0);
  // Crank the next state a couple of times.
  state_ = seed;
  NextState();
  NextState();
  NextState();
  NextState();
}

Random::Random(uint64_t seed) {
  Initialize(seed);
}

// The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
// http://en.wikipedia.org/wiki/Multiply-with-carry
// The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.
uint64_t Random::NextState() {
  const uint64_t MASK_32 = 0xffffffff;
  const uint64_t A = 0xffffda61;

  uint64_t state_lo = state_ & MASK_32;
  uint64_t state_hi = (state_ >> 32) & MASK_32;
  state_ = (A * state_lo) + state_hi;
  return state_;
}

uint32_t Random::NextUInt32() {
  const uint64_t MASK_32 = 0xffffffff;
  return static_cast<uint32_t>(NextState() & MASK_32);
}

double Random::NextDouble() {
  uint64_t mantissa = NextUInt64() & 0xFFFFFFFFFFFFF;
  // The exponent value 0 in biased form.
  const uint64_t exp = 1023;
  return bit_cast<double>(exp << 52 | mantissa) - 1.0;
}

}  // namespace dart
