// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/snapshot_utils.h"
#include "bin/file.h"
#include "bin/test_utils.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(DART_TARGET_OS_MACOS)
TEST_CASE(CanDetectMachOFiles) {
  const char* kMachO32BitLittleEndianFilename =
      bin::test::GetFileName("runtime/tests/vm/data/macho_32bit_little_endian");
  const char* kMachO64BitLittleEndianFilename =
      bin::test::GetFileName("runtime/tests/vm/data/macho_64bit_little_endian");
  const char* kMachO32BitBigEndianFilename =
      bin::test::GetFileName("runtime/tests/vm/data/macho_32bit_big_endian");
  const char* kMachO64BitBigEndianFilename =
      bin::test::GetFileName("runtime/tests/vm/data/macho_64bit_big_endian");

  EXPECT(
      bin::Snapshot::IsMachOFormattedBinary(kMachO32BitLittleEndianFilename));
  EXPECT(
      bin::Snapshot::IsMachOFormattedBinary(kMachO64BitLittleEndianFilename));
  EXPECT(bin::Snapshot::IsMachOFormattedBinary(kMachO32BitBigEndianFilename));
  EXPECT(bin::Snapshot::IsMachOFormattedBinary(kMachO64BitBigEndianFilename));

  const char* kFilename =
      bin::test::GetFileName("runtime/bin/snapshot_utils_test.cc");
  EXPECT(!bin::Snapshot::IsMachOFormattedBinary(kFilename));
}
#endif

}  // namespace dart
