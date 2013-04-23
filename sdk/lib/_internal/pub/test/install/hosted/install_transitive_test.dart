// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('installs packages transitively from a pub server', () {
    servePackages([
      packageMap("foo", "1.2.3", [dependencyMap("bar", "2.0.4")]),
      packageMap("bar", "2.0.3"),
      packageMap("bar", "2.0.4"),
      packageMap("bar", "2.0.5")
    ]);

    d.appDir([dependencyMap("foo", "1.2.3")]).create();

    schedulePub(args: ['install'],
        output: new RegExp("Dependencies installed!\$"));

    d.cacheDir({"foo": "1.2.3", "bar": "2.0.4"}).validate();
    d.packagesDir({"foo": "1.2.3", "bar": "2.0.4"}).validate();
  });
}
