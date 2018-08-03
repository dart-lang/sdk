// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/cpuinfo.h"
#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(GetCpuModelTest) {
  const char* cpumodel = CpuInfo::GetCpuModel();
  EXPECT_NE(strlen(cpumodel), 0UL);
  // caller is responsible for deleting the returned cpumodel string.
  free(const_cast<char*>(cpumodel));
}

}  // namespace dart
