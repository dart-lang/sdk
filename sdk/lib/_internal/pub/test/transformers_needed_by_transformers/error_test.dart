// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

void main() {
  initConfig();

  integration("fails if an unknown package is imported", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp"]
      }),
      d.dir('lib', [
        d.file("myapp.dart", transformer(["package:foo/foo.dart"]))
      ])
    ]).create();

    expectException(predicate((error) {
      expect(error, new isInstanceOf<ApplicationException>());
      expect(error.message, equals(
          'A transformer imported unknown package "foo" (in '
          '"package:foo/foo.dart").'));
      return true;
    }));
  });

  integration("fails on a syntax error", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp"]
      }),
      d.dir('lib', [
        d.file("myapp.dart", "library;")
      ])
    ]).create();

    expectException(new isInstanceOf<AnalyzerErrorGroup>());
  });
}
