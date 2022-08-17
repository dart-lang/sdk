// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/snapshot_utils.h"
#include "bin/dartutils.h"
#include "bin/file.h"
#include "bin/test_utils.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {

#if defined(DART_TARGET_OS_MACOS)

static const unsigned char kMachO32BitLittleEndianHeader[] = {
    0xce, 0xfa, 0xed, 0xfe, 0x07, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

static const unsigned char kMachO32BitBigEndianHeader[] = {
    0xfe, 0xed, 0xfa, 0xce, 0x01, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

static const unsigned char kMachO64BitLittleEndianHeader[] = {
    0xcf, 0xfa, 0xed, 0xfe, 0x07, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00,
    0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

static const unsigned char kMachO64BitBigEndianHeader[] = {
    0xfe, 0xed, 0xfa, 0xcf, 0x01, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

static const struct {
  const char* filename;
  const unsigned char* contents;
  size_t contents_size;
} kTestcases[] = {
    {"macho_32bit_little_endian", kMachO32BitLittleEndianHeader,
     ARRAY_SIZE(kMachO32BitLittleEndianHeader)},
    {"macho_32bit_big_endian", kMachO32BitBigEndianHeader,
     ARRAY_SIZE(kMachO32BitBigEndianHeader)},
    {"macho_64bit_little_endian", kMachO64BitLittleEndianHeader,
     ARRAY_SIZE(kMachO64BitLittleEndianHeader)},
    {"macho_64bit_big_endian", kMachO64BitBigEndianHeader,
     ARRAY_SIZE(kMachO64BitBigEndianHeader)},
};

TEST_CASE(CanDetectMachOFiles) {
  for (uintptr_t i = 0; i < ARRAY_SIZE(kTestcases); i++) {
    const auto& testcase = kTestcases[i];
    auto* const file =
        bin::DartUtils::OpenFile(testcase.filename, /*write=*/true);
    bin::DartUtils::WriteFile(testcase.contents, testcase.contents_size, file);
    bin::DartUtils::CloseFile(file);

    EXPECT(bin::Snapshot::IsMachOFormattedBinary(testcase.filename));

    EXPECT(bin::File::Delete(nullptr, testcase.filename));
  }

  const char* kFilename =
      bin::test::GetFileName("runtime/bin/snapshot_utils_test.cc");
  EXPECT(!bin::Snapshot::IsMachOFormattedBinary(kFilename));
}
#endif

}  // namespace dart
