// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('fails gracefully if the url does not resolve', () {
    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {
            "hosted": {
              "name": "foo",
              "url": "http://pub.invalid"
            }
          }
         }
      })
    ]).scheduleCreate();

    schedulePub(args: ['update'],
        error: const RegExp('Could not resolve URL "http://pub.invalid".'),
        exitCode: 1);

    run();
  });
}
