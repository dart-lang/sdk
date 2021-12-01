// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:io";

import "package:expect/expect.dart";

main() {
  // Match patterns like:
  //    "en"                    (MacOS)
  //    "en-US"                 (Android, iOS, Windows)
  //    "en_US", "en_US.UTF-8"  (Linux)
  //    "ESP-USA"               (theoretically possible)
  // Assumes that the platform has a reasonably configured locale.
  var localePattern = RegExp(r"[A-Za-z]{2,4}([_-][A-Za-z]{2})?");
  var localeName = Platform.localeName;
  Expect.isNotNull(
      localePattern.matchAsPrefix(localeName),
      "Platform.localeName: ${localeName} does not match "
      "${localePattern.pattern}");
}
