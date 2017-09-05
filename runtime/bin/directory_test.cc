// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/thread.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(DirectoryCurrentNoScope) {
  char* current_dir = dart::bin::Directory::CurrentNoScope();
  EXPECT_NOTNULL(current_dir);
  free(current_dir);
}

TEST_CASE(DirectoryCurrent) {
  const char* current = dart::bin::Directory::Current(NULL);
  EXPECT_NOTNULL(current);
}

TEST_CASE(DirectoryExists) {
  const char* current = dart::bin::Directory::Current(NULL);
  EXPECT_NOTNULL(current);

  dart::bin::Directory::ExistsResult r =
      dart::bin::Directory::Exists(NULL, current);
  EXPECT_EQ(dart::bin::Directory::EXISTS, r);
}

TEST_CASE(DirectorySystemTemp) {
  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);
}

TEST_CASE(DirectorySystemTempExists) {
  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);

  dart::bin::Directory::ExistsResult r =
      dart::bin::Directory::Exists(NULL, system_temp);
  EXPECT_EQ(dart::bin::Directory::EXISTS, r);
}

TEST_CASE(DirectoryCreateTemp) {
  const char* kTempPrefix = "test_prefix";
  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);

  const char* temp_dir = dart::bin::Directory::CreateTemp(NULL, kTempPrefix);
  EXPECT_NOTNULL(temp_dir);

  // Make sure temp_dir contains test_prefix.
  EXPECT_NOTNULL(strstr(temp_dir, kTempPrefix));

  // Cleanup.
  EXPECT(dart::bin::Directory::Delete(NULL, temp_dir, false));
}

TEST_CASE(DirectorySetCurrent) {
  const char* current = dart::bin::Directory::Current(NULL);
  EXPECT_NOTNULL(current);

  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);

  EXPECT(dart::bin::Directory::SetCurrent(NULL, system_temp));

  const char* new_current = dart::bin::Directory::Current(NULL);
  EXPECT_NOTNULL(new_current);

  EXPECT_NOTNULL(strstr(new_current, system_temp));

  EXPECT(dart::bin::Directory::SetCurrent(NULL, current));
}

TEST_CASE(DirectoryCreateDelete) {
  const char* kTempDirName = "create_delete_test_name";

  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);

  const intptr_t name_len =
      snprintf(NULL, 0, "%s/%s", system_temp, kTempDirName);
  ASSERT(name_len > 0);
  char* name = new char[name_len + 1];
  snprintf(name, name_len + 1, "%s/%s", system_temp, kTempDirName);

  // Make a directory.
  EXPECT(dart::bin::Directory::Create(NULL, name));

  // Make sure it exists.
  dart::bin::Directory::ExistsResult r =
      dart::bin::Directory::Exists(NULL, name);
  EXPECT_EQ(dart::bin::Directory::EXISTS, r);

  // Cleanup.
  EXPECT(dart::bin::Directory::Delete(NULL, name, false));
  delete[] name;
}

TEST_CASE(DirectoryRename) {
  const char* kTempDirName = "rename_test_name";

  const char* system_temp = dart::bin::Directory::SystemTemp(NULL);
  EXPECT_NOTNULL(system_temp);

  const intptr_t name_len =
      snprintf(NULL, 0, "%s/%s", system_temp, kTempDirName);
  ASSERT(name_len > 0);
  char* name = new char[name_len + 1];
  snprintf(name, name_len + 1, "%s/%s", system_temp, kTempDirName);

  // Make a directory.
  EXPECT(dart::bin::Directory::Create(NULL, name));

  // Make sure it exists.
  dart::bin::Directory::ExistsResult r =
      dart::bin::Directory::Exists(NULL, name);
  EXPECT_EQ(dart::bin::Directory::EXISTS, r);

  const intptr_t new_name_len =
      snprintf(NULL, 0, "%s/%snewname", system_temp, kTempDirName);
  ASSERT(new_name_len > 0);
  char* new_name = new char[new_name_len + 1];
  snprintf(new_name, new_name_len + 1, "%s/%snewname", system_temp,
           kTempDirName);

  EXPECT(dart::bin::Directory::Rename(NULL, name, new_name));

  r = dart::bin::Directory::Exists(NULL, new_name);
  EXPECT_EQ(dart::bin::Directory::EXISTS, r);

  r = dart::bin::Directory::Exists(NULL, name);
  EXPECT_EQ(dart::bin::Directory::DOES_NOT_EXIST, r);

  EXPECT(dart::bin::Directory::Delete(NULL, new_name, false));
  delete[] name;
  delete[] new_name;
}

}  // namespace dart
