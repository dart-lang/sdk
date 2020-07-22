// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(HOST_OS_MACOS)
#include "bin/platform.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(Platform_ExtractsOSVersionFromString) {
  char str[] =
      "some overheads\n<key>ProductVersion</key>\nsome bytes<string>Fake "
      "version</string>";
  char* result = bin::ExtractsOSVersionFromString(str);
  EXPECT(result != NULL);
  EXPECT_STREQ("Fake version", result);

  EXPECT(bin::ExtractsOSVersionFromString("<key>ProductVersion</key>") == NULL);

  // Incomplete file
  EXPECT(bin::ExtractsOSVersionFromString(
             "<key>ProductVersion</key><string>Fake version</string") != NULL);

  // A copy of actual SystemVersion.plist on mac.
  str =
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "
      "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
      "<plist version=\"1.0\">\n"
      "<dict>\n"
      "        <key>ProductBuildVersion</key>\n"
      "        <string>19E287</string>\n"
      "        <key>ProductCopyright</key>\n"
      "        <string>1983-2020 Apple Inc.</string>\n"
      "        <key>ProductName</key>\n"
      "        <string>Mac OS X</string>\n"
      "        <key>ProductUserVisibleVersion</key>\n"
      "        <string>10.15.4</string>\n"
      "        <key>ProductVersion</key>\n"
      "        <string>10.15.4</string>\n"
      "        <key>iOSSupportVersion</key>\n"
      "        <string>13.4</string>\n"
      "</dict>\n"
      "</plist>"

      result = bin::ExtractsOSVersionFromString(str);
  EXPECT(result != NULL);
  EXPECT_STREQ("10.15.4", result);
}

}  // namespace dart
#endif  // defined(HOST_OS_MACOS)
