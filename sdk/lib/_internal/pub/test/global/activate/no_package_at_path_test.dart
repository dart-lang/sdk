// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if path does not point to a package', () {
    // No pubspec.
    d.dir("foo", []).create();

    schedulePub(args: ["global", "activate", "--source", "path", "foo"],
        error: 'Could not find a file named "pubspec.yaml" in "foo".',
        exitCode: 1);
  });
}
