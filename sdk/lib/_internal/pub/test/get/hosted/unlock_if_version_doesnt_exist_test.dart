// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('upgrades a locked pub server package with a nonexistent version',
      () {
    servePackages([packageMap("foo", "1.0.0")]);

    d.appDir({"foo": "any"}).create();
    pubGet();
    d.packagesDir({"foo": "1.0.0"}).validate();

    schedule(() => deleteEntry(p.join(sandboxDir, cachePath)));

    servePackages([packageMap("foo", "1.0.1")], replace: true);
    pubGet();
    d.packagesDir({"foo": "1.0.1"}).validate();
  });
}
