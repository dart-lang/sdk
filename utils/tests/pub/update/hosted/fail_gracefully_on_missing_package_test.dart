// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('fails gracefully if the package does not exist', () {
    servePackages([]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['update'],
        error: new RegExp('Could not find package "foo" at '
                            'http://localhost:'),
        exitCode: 1);

    run();
  });
}
