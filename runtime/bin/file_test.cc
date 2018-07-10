// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/unit_test.h"

namespace dart {
namespace bin {

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
static const char* GetFileName(const char* name) {
  if (File::Exists(NULL, name)) {
    return name;
  } else {
    static const int kRuntimeLength = strlen("runtime/");
    return name + kRuntimeLength;
  }
}

TEST_CASE(Read) {
  const char* kFilename = GetFileName("runtime/bin/file_test.cc");
  File* file = File::Open(NULL, kFilename, File::kRead);
  EXPECT(file != NULL);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

TEST_CASE(OpenUri) {
  const char* kFilename = GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(malloc(strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = '6';
      *t++ = '3';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  File* file = File::OpenUri(NULL, encoded, File::kRead);
  free(encoded);
  EXPECT(file != NULL);
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  file->Release();
}

TEST_CASE(OpenUri_InvalidUriPercentEncoding) {
  const char* kFilename = GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(malloc(strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = 'f';
      *t++ = 'o';
    } else {
      *t++ = *p;
    }
  }
  *t = 0;
  File* file = File::OpenUri(NULL, encoded, File::kRead);
  free(encoded);
  EXPECT(file == NULL);
}

TEST_CASE(OpenUri_TruncatedUriPercentEncoding) {
  const char* kFilename = GetFileName("runtime/bin/file_test.cc");
  char* encoded = reinterpret_cast<char*>(malloc(strlen(kFilename) * 3 + 1));
  char* t = encoded;
  // percent-encode all characters 'c'
  for (const char* p = kFilename; *p; p++) {
    if (*p == 'c') {
      *t++ = '%';
      *t++ = 'f';
      *t++ = 'o';
    } else {
      *t++ = *p;
    }
  }
  *(t - 1) = 0;  // truncate last uri encoding
  File* file = File::OpenUri(NULL, encoded, File::kRead);
  free(encoded);
  EXPECT(file == NULL);
}

TEST_CASE(FileLength) {
  const char* kFilename =
      GetFileName("runtime/tests/vm/data/fixed_length_file");
  File* file = File::Open(NULL, kFilename, File::kRead);
  EXPECT(file != NULL);
  EXPECT_EQ(42, file->Length());
  file->Release();
}

TEST_CASE(FilePosition) {
  char buf[42];
  const char* kFilename =
      GetFileName("runtime/tests/vm/data/fixed_length_file");
  File* file = File::Open(NULL, kFilename, File::kRead);
  EXPECT(file != NULL);
  EXPECT(file->ReadFully(buf, 12));
  EXPECT_EQ(12, file->Position());
  EXPECT(file->ReadFully(buf, 6));
  EXPECT_EQ(18, file->Position());
  file->Release();
}

}  // namespace bin
}  // namespace dart
