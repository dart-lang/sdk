// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if path does not exist', () {
    schedulePub(args: ["global", "activate", "--source", "path", "nope"],
        error: 'Could not find a file named "pubspec.yaml" in "nope".',
        exitCode: 1);
  });
}
