// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/base64.h"

#include "platform/assert.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Base64Decode) {
  intptr_t decoded_len;
  uint8_t* decoded_bytes = DecodeBase64("SGVsbG8sIHdvcmxkIQo=", &decoded_len);
  const char expected_bytes[] = "Hello, world!\n";
  intptr_t expected_len = strlen(expected_bytes);
  EXPECT(!memcmp(expected_bytes, decoded_bytes, expected_len));
  EXPECT_EQ(expected_len, decoded_len);
  free(decoded_bytes);
}

TEST_CASE(Base64DecodeMalformed) {
  intptr_t decoded_len;
  EXPECT(DecodeBase64("SomethingMalformed", &decoded_len) == nullptr);
}

TEST_CASE(Base64DecodeEmpty) {
  intptr_t decoded_len;
  EXPECT(DecodeBase64("", &decoded_len) == nullptr);
}
}  // namespace dart
