// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('updates a package using the cache', () {
    // Run the server so that we know what URL to use in the system cache.
    servePackages([]);

    d.cacheDir({
      "foo": ["1.2.2", "1.2.3"],
      "bar": ["1.2.3"]
    }, includePubspecs: true).create();

    d.appDir([
      dependencyMap("foo", "any"),
      dependencyMap("bar", "any")
    ]).create();

    schedulePub(args: ['update', '--offline'],
        output: new RegExp("Dependencies updated!\$"),
        error: "Warning: Updating when offline may not update you "
               "to the latest versions of your dependencies.");

    d.packagesDir({
      "foo": "1.2.3",
      "bar": "1.2.3"
    }).validate();
  });

  integration('fails gracefully if a dependency is not cached', () {
    // Run the server so that we know what URL to use in the system cache.
    servePackages([]);

    d.appDir([
      dependencyMap("foo", "any")
    ]).create();

    schedulePub(args: ['update', '--offline'],
        error: new RegExp('Could not find package "foo" in cache'),
        exitCode: 1);
  });

  integration('fails gracefully no cached versions match', () {
    // Run the server so that we know what URL to use in the system cache.
    servePackages([]);

    d.cacheDir({
      "foo": ["1.2.2", "1.2.3"]
    }, includePubspecs: true).create();

    d.appDir([
      dependencyMap("foo", ">2.0.0")
    ]).create();

    schedulePub(args: ['update', '--offline'],
        error: new RegExp("Package 'foo' has no versions that match >2.0.0"),
        exitCode: 1);
  });
}
