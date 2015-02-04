// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();

  integration('does not request versions if the lockfile is up to date', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.1.0");
      builder.serve("foo", "1.2.0");
    });

    d.appDir({
      "foo": "any"
    }).create();

    // Get once so it gets cached.
    pubGet();

    // Clear the cache. We don't care about anything that was served during
    // the initial get.
    getRequestedPaths();

    // Run the solver again now that it's cached.
    pubGet();

    d.cacheDir({
      "foo": "1.2.0"
    }).validate();
    d.packagesDir({
      "foo": "1.2.0"
    }).validate();

    // The get should not have done any network requests since the lock file is
    // up to date.
    getRequestedPaths().then((paths) {
      expect(paths, isEmpty);
    });
  });
}
