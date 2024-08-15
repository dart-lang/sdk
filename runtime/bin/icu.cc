// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/icu.h"

#include "unicode/udata.h"

#include "platform/assert.h"

#if defined(DART_EMBED_ICU_DATA)
extern "C" const uint8_t kIcuData[];
#endif

namespace dart {
namespace bin {

#if defined(DART_EMBED_ICU_DATA)
const uint8_t* icu_data = kIcuData;
#endif

void SetupICU() {
#if defined(DART_EMBED_ICU_DATA)
  // Setup ICU.
  UErrorCode err_code = U_ZERO_ERROR;
  udata_setCommonData(icu_data, &err_code);
  if (err_code != U_ZERO_ERROR) {
    FATAL("Failed to initialize ICU: %d\n", err_code);
  }
#endif
}

}  // namespace bin
}  // namespace dart
