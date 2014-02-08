// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/cpuinfo.h"
#include "vm/globals.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(GetCpuModelTest) {
  CpuInfo::InitOnce();
  char* cpumodel = CpuInfo::GetCpuModel();
  EXPECT_NE(strlen(cpumodel), 0UL);
  delete[] cpumodel;
}

}  // namespace dart
