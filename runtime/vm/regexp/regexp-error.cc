// Copyright 2020 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/regexp/regexp-error.h"

#include "vm/regexp/base.h"

namespace dart {

const char* const kRegExpErrorStrings[] = {
#define TEMPLATE(NAME, STRING) STRING,
    REGEXP_ERROR_MESSAGES(TEMPLATE)
#undef TEMPLATE
};

const char* RegExpErrorString(RegExpError error) {
  DCHECK_LT(error, RegExpError::NumErrors);
  return kRegExpErrorStrings[static_cast<int>(error)];
}

}  // namespace dart
