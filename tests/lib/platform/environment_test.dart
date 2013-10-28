// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:platform" as platform;

import "package:unittest/unittest.dart";

main() {
  if (platform.operatingSystem != null) {
    expect(platform.environment, new isInstanceOf<Map<String, String>>());
  } else {
    expect(platform.environment, isNull);
  }
}

