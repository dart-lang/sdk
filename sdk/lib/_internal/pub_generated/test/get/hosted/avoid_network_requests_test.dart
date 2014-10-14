// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();

  integration('only requests versions that are needed during solving', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.1.0");
      builder.serve("foo", "1.2.0");
      builder.serve("bar", "1.0.0");
      builder.serve("bar", "1.1.0");
      builder.serve("bar", "1.2.0");
    });

    d.appDir({
      "foo": "any"
    }).create();

    // Get once so it gets cached.
    pubGet();

    // Clear the cache. We don't care about anything that was served during
    // the initial get.
    getRequestedPaths();

    // Add "bar" to the dependencies.
    d.appDir({
      "foo": "any",
      "bar": "any"
    }).create();

    // Run the solver again.
    pubGet();

    d.packagesDir({
      "foo": "1.2.0",
      "bar": "1.2.0"
    }).validate();

    // The get should not have done any network requests since the lock file is
    // up to date.
    getRequestedPaths().then((paths) {
      expect(
          paths,
          unorderedEquals([// Bar should be requested because it's new, but not foo.
        "api/packages/bar", // Should only request the most recent version.
        "api/packages/bar/versions/1.2.0", // Need to download it.
        "packages/bar/versions/1.2.0.tar.gz"]));
    });
  });
}
