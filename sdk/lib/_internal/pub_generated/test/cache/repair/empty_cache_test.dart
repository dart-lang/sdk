// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../test_pub.dart';

main() {
  initConfig();
  integration('does nothing if the cache is empty', () {
    // Repair them.
    schedulePub(
        args: ["cache", "repair"],
        output: "No packages in cache, so nothing to repair.");
  });
}
