// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("responds with a 404 on incomplete special URLs", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1")]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir(
              "lib",
              [// Make a file that maps to the special "packages" directory to ensure
        // it is *not* found.
        d.file("packages")]), d.dir("web", [d.file("packages")])]).create();

    pubGet();
    pubServe();
    requestShould404("packages");
    requestShould404("packages/");
    requestShould404("packages/myapp");
    requestShould404("packages/myapp/");
    requestShould404("packages/foo");
    requestShould404("packages/foo/");
    requestShould404("packages/unknown");
    requestShould404("packages/unknown/");
    endPubServe();
  });

}
