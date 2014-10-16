// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  forBothPubGetAndUpgrade((command) {
    integration('upgrades a package using the cache', () {
      // Run the server so that we know what URL to use in the system cache.
      serveNoPackages();

      d.cacheDir({
        "foo": ["1.2.2", "1.2.3"],
        "bar": ["1.2.3"]
      }, includePubspecs: true).create();

      d.appDir({
        "foo": "any",
        "bar": "any"
      }).create();

      var warning = null;
      if (command == RunCommand.upgrade) {
        warning =
            "Warning: Upgrading when offline may not update you "
                "to the latest versions of your dependencies.";
      }

      pubCommand(command, args: ['--offline'], warning: warning);

      d.packagesDir({
        "foo": "1.2.3",
        "bar": "1.2.3"
      }).validate();
    });

    integration('fails gracefully if a dependency is not cached', () {
      // Run the server so that we know what URL to use in the system cache.
      serveNoPackages();

      d.appDir({
        "foo": "any"
      }).create();

      pubCommand(
          command,
          args: ['--offline'],
          error: "Could not find package foo in cache.");
    });

    integration('fails gracefully no cached versions match', () {
      // Run the server so that we know what URL to use in the system cache.
      serveNoPackages();

      d.cacheDir({
        "foo": ["1.2.2", "1.2.3"]
      }, includePubspecs: true).create();

      d.appDir({
        "foo": ">2.0.0"
      }).create();

      pubCommand(
          command,
          args: ['--offline'],
          error: "Package foo has no versions that match >2.0.0 derived from:\n"
              "- myapp 0.0.0 depends on version >2.0.0");
    });
  });
}
