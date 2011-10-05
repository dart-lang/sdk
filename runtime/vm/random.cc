// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/random.h"

#include "vm/assert.h"
#include "vm/isolate.h"

namespace dart {

// LSFR step with a period of 31-bits.
// Based on http://en.wikipedia.org/wiki/Linear_feedback_shift_register
static int32_t LinearFeedbackShiftRegisterStep(int32_t seed) {
  return (seed >> 1) ^ ((-(seed & 1)) & (1 << 30 | 1 << 27));
}


int32_t Random::RandomInt32() {
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != NULL);
  int32_t result = isolate->random_seed();
  int32_t new_random_seed = LinearFeedbackShiftRegisterStep(result);
  isolate->set_random_seed(new_random_seed);
  return result;
}

}  // namespace dart
