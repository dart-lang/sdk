// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails gracefully if the package does not exist', () {
    servePackages([]);

    d.appDir([dependencyMap("foo", "1.2.3")]).create();

    schedulePub(args: ['install'],
        error: new RegExp('Could not find package "foo" at '
                            'http://localhost:'),
        exitCode: 1);
  });
}
