// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <type_traits>

#include "platform/globals.h"

#include "vm/kernel.h"
#include "vm/object.h"
#include "vm/unit_test.h"

namespace dart {

const dart::TypedData& CreateLineStartsData() {
  const intptr_t raw_line_starts_data[] = {
      0, 8, 12, 17, 18, 20, 23, 30, 31, 33,
  };
  const intptr_t length = std::extent<decltype(raw_line_starts_data)>::value;
  ASSERT(length > 0);
  const TypedData& line_starts_data = TypedData::Handle(
      TypedData::New(kTypedDataUint16ArrayCid, length, Heap::kOld));
  for (intptr_t i = 0; i < length; ++i) {
    line_starts_data.SetUint16(i << 1,
                               static_cast<int16_t>(raw_line_starts_data[i]));
  }
  return line_starts_data;
}

ISOLATE_UNIT_TEST_CASE(KernelLineStartsReader_MaxPosition) {
  kernel::KernelLineStartsReader reader(CreateLineStartsData(), thread->zone());
  EXPECT_EQ(33u, reader.MaxPosition());
}

void ExpectLocationForPosition(const kernel::KernelLineStartsReader& reader,
                               intptr_t position,
                               intptr_t expected_line,
                               intptr_t expected_col) {
  intptr_t line;
  intptr_t col;
  EXPECT_EQ(true, reader.LocationForPosition(position, &line, &col));
  EXPECT_EQ(expected_line, line);
  EXPECT_EQ(expected_col, col);
}

ISOLATE_UNIT_TEST_CASE(KernelLineStartsReader_LocationForPosition) {
  kernel::KernelLineStartsReader reader(CreateLineStartsData(), thread->zone());
  ExpectLocationForPosition(reader, 0, 1, 1);
  ExpectLocationForPosition(reader, 4, 1, 5);
  ExpectLocationForPosition(reader, 8, 2, 1);
  ExpectLocationForPosition(reader, 14, 3, 3);
  ExpectLocationForPosition(reader, 17, 4, 1);
  ExpectLocationForPosition(reader, 19, 5, 2);
  ExpectLocationForPosition(reader, 22, 6, 3);
  ExpectLocationForPosition(reader, 29, 7, 7);
  ExpectLocationForPosition(reader, 30, 8, 1);
  ExpectLocationForPosition(reader, 32, 9, 2);
  ExpectLocationForPosition(reader, 33, 10, 1);

  intptr_t line;
  intptr_t col;
  EXPECT_EQ(false, reader.LocationForPosition(-1, &line, &col));
  EXPECT_EQ(false, reader.LocationForPosition(34, &line, &col));
}

void ExpectTokenRangeAtLine(const kernel::KernelLineStartsReader& reader,
                            intptr_t line,
                            intptr_t expected_first_token,
                            intptr_t expected_last_token) {
  TokenPosition first_token = TokenPosition::Synthetic(0);
  TokenPosition last_token = TokenPosition::Synthetic(0);
  EXPECT_EQ(true, reader.TokenRangeAtLine(line, &first_token, &last_token));
  EXPECT_EQ(expected_first_token, first_token.Serialize());
  EXPECT_EQ(expected_last_token, last_token.Serialize());
}

ISOLATE_UNIT_TEST_CASE(KernelLineStartsReader_TokenRangeAtLine) {
  kernel::KernelLineStartsReader reader(CreateLineStartsData(), thread->zone());
  ExpectTokenRangeAtLine(reader, 1, 0, 7);
  ExpectTokenRangeAtLine(reader, 2, 8, 11);
  ExpectTokenRangeAtLine(reader, 3, 12, 16);
  ExpectTokenRangeAtLine(reader, 4, 17, 17);
  ExpectTokenRangeAtLine(reader, 5, 18, 19);
  ExpectTokenRangeAtLine(reader, 6, 20, 22);
  ExpectTokenRangeAtLine(reader, 7, 23, 29);
  ExpectTokenRangeAtLine(reader, 8, 30, 30);
  ExpectTokenRangeAtLine(reader, 9, 31, 32);
  ExpectTokenRangeAtLine(reader, 10, 33, 33);

  TokenPosition first_token = TokenPosition::Synthetic(0);
  TokenPosition last_token = TokenPosition::Synthetic(0);
  EXPECT_EQ(false, reader.TokenRangeAtLine(0, &first_token, &last_token));
  EXPECT_EQ(false, reader.TokenRangeAtLine(11, &first_token, &last_token));
}

}  // namespace dart
