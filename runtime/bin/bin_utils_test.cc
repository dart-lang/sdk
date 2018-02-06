// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/utils.h"
#include "vm/unit_test.h"

namespace dart {
namespace bin {

TEST_CASE(UriToPath) {
#if defined(HOST_OS_WINDOWS)
  EXPECT_STREQ("c:\\abc\\file.dill",
      ShellUtils::UriToPath("file:///c:/abc/file.dill"));
  EXPECT_STREQ("\\abc\\def.dill",
      ShellUtils::UriToPath("file:///abc/def.dill"));
#else
  EXPECT_STREQ("/c:/abc/file.dill",
      ShellUtils::UriToPath("file:///c:/abc/file.dill"));
  EXPECT_STREQ("/abc/def.dill",
      ShellUtils::UriToPath("file:///abc/def.dill"));
#endif
  EXPECT_STREQ(ShellUtils::UriToPath("not an uri"), "not an uri");
}
}  // namespace bin
}  // namespace dart
