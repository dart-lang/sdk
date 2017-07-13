// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/random.h"
#include "vm/dart.h"
#include "vm/flags.h"
#include "vm/os.h"

namespace dart {

DEFINE_FLAG(int, random_seed, 0, "Override the random seed for debugging.");

Random::Random() {
  uint64_t seed = FLAG_random_seed;
  if (seed == 0) {
    Dart_EntropySource callback = Dart::entropy_source_callback();
    if (callback != NULL) {
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
  _state = seed;
  NextState();
  NextState();
  NextState();
  NextState();
}

Random::Random(uint64_t seed) {
  Initialize(seed);
}

Random::~Random() {
  // Nothing to be done here.
}

// The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
// http://en.wikipedia.org/wiki/Multiply-with-carry
// The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.
void Random::NextState() {
  const uint64_t MASK_32 = 0xffffffff;
  const uint64_t A = 0xffffda61;

  uint64_t state_lo = _state & MASK_32;
  uint64_t state_hi = (_state >> 32) & MASK_32;
  _state = (A * state_lo) + state_hi;
}

uint32_t Random::NextUInt32() {
  const uint64_t MASK_32 = 0xffffffff;
  NextState();
  return static_cast<uint32_t>(_state & MASK_32);
}

}  // namespace dart
