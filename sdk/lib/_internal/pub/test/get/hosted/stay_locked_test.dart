// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('keeps a pub server package locked to the version in the '
      'lockfile', () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));

    d.appDir({"foo": "any"}).create();

    // This should lock the foo dependency to version 1.0.0.
    pubGet();

    d.packagesDir({"foo": "1.0.0"}).validate();

    // Delete the packages path to simulate a new checkout of the application.
    schedule(() => deleteEntry(path.join(sandboxDir, packagesPath)));

    // Start serving a newer package as well.
    servePackages((builder) => builder.serve("foo", "1.0.1"));

    // This shouldn't upgrade the foo dependency due to the lockfile.
    pubGet();

    d.packagesDir({"foo": "1.0.0"}).validate();
  });
}
