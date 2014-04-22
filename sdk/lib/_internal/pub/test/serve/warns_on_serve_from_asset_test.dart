// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_stream.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("warns if an asset from the entrypoint package's 'asset' "
      "directory is requested", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("asset", [
        d.file("file.txt", "body")
      ])
    ]).create();

    var pub = pubServe();
    requestShouldSucceed("assets/myapp/file.txt", "body");

    pub.stderr.expect(consumeThrough(emitsLines('''
Warning: Support for the "asset" directory is deprecated and will be removed soon.
Please move "asset/file.txt" to "lib/file.txt".''')));
    endPubServe();
  });

  integration("warns if an asset from a dependency's 'asset' directory is "
      "requested", () {
    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.dir("asset", [
        d.file("file.txt", "body")
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      })
    ]).create();

    var pub = pubServe(shouldGetFirst: true);
    requestShouldSucceed("assets/foo/file.txt", "body");

    pub.stderr.expect(consumeThrough(emitsLines('''
Warning: Support for the "asset" directory is deprecated and will be removed soon.
Please ask the maintainer of "foo" to move "asset/file.txt" to "lib/file.txt".''')));
    endPubServe();
  });
}
