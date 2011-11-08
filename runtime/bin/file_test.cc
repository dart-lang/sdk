// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/file.h"

#include "vm/assert.h"
#include "vm/globals.h"
#include "vm/unit_test.h"


// Helper method to be able to run the test from the runtime
// directory, or the top directory.
static const char* GetFileName(const char* name) {
  if (File::Exists(name)) {
    return name;
  } else {
    static const int kRuntimeLength = strlen("runtime/");
    return name + kRuntimeLength;
  }
}


UNIT_TEST_CASE(Read) {
  const char* kFilename = GetFileName("runtime/bin/file_test.cc");
  File* file = File::Open(kFilename, false);
  EXPECT(file != NULL);
  EXPECT_STREQ(kFilename, file->name());
  char buffer[16];
  buffer[0] = '\0';
  EXPECT(file->ReadFully(buffer, 13));  // ReadFully returns true.
  buffer[13] = '\0';
  EXPECT_STREQ("// Copyright ", buffer);
  EXPECT(!file->WriteByte(1));  // Cannot write to a read-only file.
  delete file;
}


UNIT_TEST_CASE(FileLength) {
  const char* kFilename =
      GetFileName("runtime/tests/vm/data/fixed_length_file");
  File* file = File::Open(kFilename, false);
  EXPECT(file != NULL);
  EXPECT_EQ(42, file->Length());
  delete file;
}


UNIT_TEST_CASE(FilePosition) {
  char buf[42];
  const char* kFilename =
      GetFileName("runtime/tests/vm/data/fixed_length_file");
  File* file = File::Open(kFilename, false);
  EXPECT(file != NULL);
  EXPECT(file->ReadFully(buf, 12));
  EXPECT_EQ(12, file->Position());
  EXPECT(file->ReadFully(buf, 6));
  EXPECT_EQ(18, file->Position());
  delete file;
}
