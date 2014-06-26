// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('handles failure to reinstall some packages', () {
    // Only serve two packages so repairing will have a failure.
    servePackages([
      packageMap("foo", "1.2.3"),
      packageMap("foo", "1.2.5")
    ]);

    // Set up a cache with some packages.
    d.dir(cachePath, [
      d.dir('hosted', [
        d.async(port.then((p) => d.dir('localhost%58$p', [
          d.dir("foo-1.2.3", [
            d.libPubspec("foo", "1.2.3"),
            d.file("broken.txt")
          ]),
          d.dir("foo-1.2.4", [
            d.libPubspec("foo", "1.2.4"),
            d.file("broken.txt")
          ]),
          d.dir("foo-1.2.5", [
            d.libPubspec("foo", "1.2.5"),
            d.file("broken.txt")
          ])
        ])))
      ])
    ]).create();

    // Repair them.
    var pub = startPub(args: ["cache", "repair"]);

    pub.stdout.expect("Downloading foo 1.2.3...");
    pub.stdout.expect("Downloading foo 1.2.4...");
    pub.stdout.expect("Downloading foo 1.2.5...");

    pub.stderr.expect(startsWith("Failed to repair foo 1.2.4. Error:"));
    pub.stderr.expect("HTTP error 404: Not Found");

    pub.stdout.expect("Reinstalled 2 packages.");
    pub.stdout.expect("Failed to reinstall 1 package.");

    pub.shouldExit(exit_codes.UNAVAILABLE);
  });
}
