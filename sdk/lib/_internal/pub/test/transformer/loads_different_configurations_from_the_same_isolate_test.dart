// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("loads different configurations from the same isolate", () {
      // If different configurations are loaded from different isolates, a
      // transformer can end up being loaded twice. It's even possible for the
      // second load to use code that's transformed by the first, which is
      // really bad. This tests sets up such a scenario.
      //
      // The foo package has two self-transformers: foo/first and foo/second,
      // loaded in that order. This means that *no instances of foo/first*
      // should ever have their code transformed by foo/second.
      //
      // The myapp package also has a reference to foo/first. This reference has
      // a different configuration than foo's, which means that if it's loaded
      // in a separate isolate, it will be loaded after all of foo's
      // transformers have run. This means that foo/first.dart will have been
      // transformed by foo/first and foo/second, causing it to have different
      // code than the previous instance. This tests asserts that that doesn't
      // happen.

      d.dir("foo", [
        d.pubspec({
          "name": "foo",
          "version": "1.0.0",
          "transformers": [
            {"foo/first": {"addition": " in foo"}},
            "foo/second"
          ]
        }),
        d.dir("lib", [
          d.file("first.dart", dartTransformer('foo/first')),
          d.file("second.dart", dartTransformer('foo/second'))
        ])
      ]).create();

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": [
            {
              "foo/first": {
                "addition": " in myapp",
                "\$include": "web/first.dart"
              }
            },
            {"foo/second": {"\$include": "web/second.dart"}}
          ],
          "dependencies": {'foo': {'path': '../foo'}}
        }),
        d.dir("web", [
          // This is transformed by foo/first. It's used to see which
          // transformers ran on foo/first.
          d.file("first.dart", 'const TOKEN = "myapp/first";'),

          // This is transformed by foo/second. It's used to see which
          // transformers ran on foo/second.
          d.file("second.dart", 'const TOKEN = "myapp/second";')
        ])
      ]).create();

      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);

      pubServe();

      // The version of foo/first used on myapp should have myapp's
      // configuration and shouldn't be transformed by foo/second.
      requestShouldSucceed("first.dart",
          'const TOKEN = "(myapp/first, foo/first in myapp)";');

      // foo/second should be transformed by only foo/first.
      requestShouldSucceed("second.dart",
          'const TOKEN = "(myapp/second, (foo/second, foo/first in foo))";');

      endPubServe();
    });
  });
}
