// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdint.h>

void CallFunction1Uint8(void (*callback)(uint8_t), uint32_t batch_size) {
  for (uint32_t i = 0; i < batch_size; i++) {
    callback(1);
  }
}
