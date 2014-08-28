// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('reinstalls previously cached hosted packages', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "1.2.4");
      builder.serve("foo", "1.2.5");
      builder.serve("bar", "1.2.3");
      builder.serve("bar", "1.2.4");
    });

    // Set up a cache with some broken packages.
    d.dir(cachePath, [
      d.dir('hosted', [
        d.async(port.then((p) => d.dir('localhost%58$p', [
          d.dir("foo-1.2.3", [
            d.libPubspec("foo", "1.2.3"),
            d.file("broken.txt")
          ]),
          d.dir("foo-1.2.5", [
            d.libPubspec("foo", "1.2.5"),
            d.file("broken.txt")
          ]),
          d.dir("bar-1.2.4", [
            d.libPubspec("bar", "1.2.4"),
            d.file("broken.txt")
          ])
        ])))
      ])
    ]).create();

    // Repair them.
    schedulePub(args: ["cache", "repair"],
        output: '''
          Downloading bar 1.2.4...
          Downloading foo 1.2.3...
          Downloading foo 1.2.5...
          Reinstalled 3 packages.''');

    // The broken versions should have been replaced.
    d.hostedCache([
      d.dir("bar-1.2.4", [d.nothing("broken.txt")]),
      d.dir("foo-1.2.3", [d.nothing("broken.txt")]),
      d.dir("foo-1.2.5", [d.nothing("broken.txt")])
    ]).validate();
  });
}
