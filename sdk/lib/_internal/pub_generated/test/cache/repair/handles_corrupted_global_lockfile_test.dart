// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('handles a corrupted global lockfile', () {
    d.dir(
        cachePath,
        [d.dir('global_packages/foo', [d.file('pubspec.lock', 'junk')])]).create();

    schedulePub(
        args: ["cache", "repair"],
        error: contains('Failed to reactivate foo:'),
        output: contains('Failed to reactivate 1 package.'));
  });
}
