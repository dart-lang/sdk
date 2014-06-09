// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  forBothPubGetAndUpgrade((command) {
    integration('fails gracefully if the package does not exist', () {
      servePackages([]);

      d.appDir({"foo": "1.2.3"}).create();

      pubCommand(command, error: new RegExp(r"""
Could not find package foo at http://localhost:\d+\.
Depended on by:
- myapp""", multiLine: true));
    });
  });
}
