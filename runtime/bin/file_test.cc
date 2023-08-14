// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"
#include "bin/dartutils.h"
#include "bin/directory.h"
#include "bin/test_utils.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Read) {
  const char* kFilename = bin::test::GetFileName("runtime/bin/file_test.cc");
  bin::File* file = bin::File::Open(nullptr, kFilename, bin::File::kRead);
  EXPECT(file != nullptr);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

TEST_CASE(OpenUri_RelativeFilename) {
  const char* kFilename = bin::test::GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = '6';
      *t++ = '3';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file != nullptr);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

TEST_CASE(OpenUri_AbsoluteFilename) {
  const char* kRelativeFilename =
      bin::test::GetFileName("runtime/bin/file_test.cc");
  const char* kFilename =
      bin::File::GetCanonicalPath(nullptr, kRelativeFilename);
  EXPECT_NOTNULL(kFilename);
  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = '6';
      *t++ = '3';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file != nullptr);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

static const char* Concat(const char* a, const char* b) {
  const intptr_t len = strlen(a) + strlen(b);
  char* c = bin::DartUtils::ScopedCString(len + 1);
  EXPECT_NOTNULL(c);
  snprintf(c, len + 1, "%s%s", a, b);
  return c;
}

TEST_CASE(OpenUri_ValidUri) {
  const char* kRelativeFilename =
      bin::test::GetFileName("runtime/bin/file_test.cc");
  const char* kAbsoluteFilename =
      bin::File::GetCanonicalPath(nullptr, kRelativeFilename);
  EXPECT_NOTNULL(kAbsoluteFilename);
  const char* kFilename = Concat("file:///", kAbsoluteFilename);

  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = '6';
      *t++ = '3';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file != nullptr);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

TEST_CASE(OpenUri_UriWithSpaces) {
  const char* kRelativeFilename =
      bin::test::GetFileName("runtime/bin/file_test.cc");
  const char* strSystemTemp = bin::Directory::SystemTemp(nullptr);
  EXPECT_NOTNULL(strSystemTemp);
  const char* kTempDir = Concat(strSystemTemp, "/foo bar");
  const char* strTempDir = bin::Directory::CreateTemp(nullptr, kTempDir);
  EXPECT_NOTNULL(strTempDir);
  const char* kTargetFilename = Concat(strTempDir, "/file test.cc");
  bool result = bin::File::Copy(nullptr, kRelativeFilename, kTargetFilename);
  EXPECT(result);

  const char* kAbsoluteFilename =
      bin::File::GetCanonicalPath(nullptr, kTargetFilename);
  EXPECT_NOTNULL(kAbsoluteFilename);
  const char* kFilename = Concat("file:///", kAbsoluteFilename);

  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all spaces
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == ' ') {
      *t++ = '%';
      *t++ = '2';
      *t++ = '0';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  printf("encoded: %s\n", encoded);
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file != nullptr);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
  bin::Directory::Delete(nullptr, strTempDir, /* recursive= */ true);
}

TEST_CASE(OpenUri_InvalidUriPercentEncoding) {
  const char* kFilename = bin::test::GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = 'f';
      *t++ = 'o';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file == nullptr);
}

TEST_CASE(OpenUri_TruncatedUriPercentEncoding) {
  const char* kFilename = bin::test::GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(bin::DartUtils::ScopedCString(
      strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p != '\0'; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = 'f';
      *t++ = 'o';
    } else {
      *t++ = *p;
    }
  }
  *(t - 1) = 0;  // truncate last uri encoding
  bin::File* file = bin::File::OpenUri(nullptr, encoded, bin::File::kRead);
  EXPECT(file == nullptr);
}

TEST_CASE(FileLength) {
  const char* kFilename =
      bin::test::GetFileName("runtime/tests/vm/data/fixed_length_file");
  bin::File* file = bin::File::Open(nullptr, kFilename, bin::File::kRead);
  EXPECT(file != nullptr);
  EXPECT_EQ(42, file->Length());
  file->Release();
}

TEST_CASE(FilePosition) {
  char buf[42];
  const char* kFilename =
      bin::test::GetFileName("runtime/tests/vm/data/fixed_length_file");
  bin::File* file = bin::File::Open(nullptr, kFilename, bin::File::kRead);
  EXPECT(file != nullptr);
  EXPECT(file->ReadFully(buf, 12));
  EXPECT_EQ(12, file->Position());
  EXPECT(file->ReadFully(buf, 6));
  EXPECT_EQ(18, file->Position());
  file->Release();
}

}  // namespace dart
