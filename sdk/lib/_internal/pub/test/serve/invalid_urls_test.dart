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
    d.dir("foo", [
      d.libPubspec("foo", "0.0.1")
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      }),
      // Make files that map to the special directory names to ensure they
      // are *not* found.
      d.dir("asset", [
        d.file("packages"),
        d.file("assets")
      ]),
      d.dir("lib", [
        d.file("packages"),
        d.file("assets")
      ]),
      d.dir("web", [
        d.file("packages"),
        d.file("assets")
      ])
    ]).create();

    pubGet();
    startPubServe();
    requestShould404("packages");
    requestShould404("assets");
    requestShould404("packages/");
    requestShould404("assets/");
    requestShould404("packages/myapp");
    requestShould404("assets/myapp");
    requestShould404("packages/myapp/");
    requestShould404("assets/myapp/");
    requestShould404("packages/foo");
    requestShould404("assets/foo");
    requestShould404("packages/foo/");
    requestShould404("assets/foo/");
    requestShould404("packages/unknown");
    requestShould404("assets/unknown");
    requestShould404("packages/unknown/");
    requestShould404("assets/unknown/");
    endPubServe();
  });

}
