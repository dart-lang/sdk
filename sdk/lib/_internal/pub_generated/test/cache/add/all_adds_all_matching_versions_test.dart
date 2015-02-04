// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('"--all" adds all matching versions of the package', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.2");
      builder.serve("foo", "1.2.3-dev");
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "2.0.0");
    });

    schedulePub(
        args: ["cache", "add", "foo", "-v", ">=1.0.0 <2.0.0", "--all"],
        output: '''
          Downloading foo 1.2.2...
          Downloading foo 1.2.3-dev...
          Downloading foo 1.2.3...''');

    d.cacheDir({
      "foo": "1.2.2"
    }).validate();
    d.cacheDir({
      "foo": "1.2.3-dev"
    }).validate();
    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
  });
}
