// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/abi_version.h"

namespace dart {

int AbiVersion::GetCurrent() {
  return {{ABI_VERSION}};
}

int AbiVersion::GetOldestSupported() {
  return {{OLDEST_SUPPORTED_ABI_VERSION}};
}

}  // namespace dart
