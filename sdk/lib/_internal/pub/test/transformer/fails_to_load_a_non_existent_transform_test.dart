// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("fails to load a non-existent transform", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/transform"]
      })
    ]).create();

    var pub = startPub(args: ['serve', '--port=0', "--hostname=127.0.0.1"]);
    expect(pub.nextErrLine(), completion(equals(
        'Transformer library "package:myapp/transform.dart" not found.')));
    pub.shouldExit(1);
  });
}
