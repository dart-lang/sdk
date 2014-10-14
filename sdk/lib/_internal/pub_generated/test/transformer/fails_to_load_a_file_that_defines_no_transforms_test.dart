// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();

  withBarbackVersions("any", () {
    integration("fails to load a file that defines no transforms", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/transformer"]
        }),
            d.dir("lib", [d.file("transformer.dart", "library does_nothing;")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      var pub = startPubServe();
      pub.stderr.expect(startsWith('No transformers were defined in '));
      pub.stderr.expect(startsWith('required by myapp.'));
      pub.shouldExit(1);
      pub.stderr.expect(never(contains('This is an unexpected error')));
    });
  });
}
