// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('gets a package from a pub server', () {
    servePackages((builder) => builder.serve("foo", "1.2.3"));

    d.appDir({
      "foo": "1.2.3"
    }).create();

    pubGet();

    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
    d.packagesDir({
      "foo": "1.2.3"
    }).validate();
  });

  integration('URL encodes the package name', () {
    serveNoPackages();

    d.appDir({
      "bad name!": "1.2.3"
    }).create();

    pubGet(
        error: new RegExp(
            r"Could not find package bad name! at http://localhost:\d+\."),
        exitCode: exit_codes.UNAVAILABLE);
  });
}
