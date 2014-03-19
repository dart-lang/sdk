// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();

  setUp(() {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("index.html", "<body>")
      ])
    ]).create();
  });

  integration("responds with an error if 'path' is missing", () {
    pubServe();
    expectWebSocketCall({
      "command": "unserveDirectory"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": 'Missing "path" argument.'
    });
    endPubServe();
  });

  integration("responds with an error if 'path' is not a string", () {
    pubServe();
    expectWebSocketCall({
      "command": "unserveDirectory",
      "path": 123
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"path" must be a string. Got 123.'
    });
    endPubServe();
  });

  integration("responds with an error if 'path' is absolute", () {
    pubServe();
    expectWebSocketCall({
      "command": "unserveDirectory",
      "path": "/absolute.txt"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error": '"path" must be a relative path. Got "/absolute.txt".'
    });
    endPubServe();
  });

  integration("responds with an error if 'path' reaches out", () {
    pubServe();
    expectWebSocketCall({
      "command": "unserveDirectory",
      "path": "a/../../bad.txt"
    }, replyEquals: {
      "code": "BAD_ARGUMENT",
      "error":
          '"path" cannot reach out of its containing directory. '
          'Got "a/../../bad.txt".'
    });
    endPubServe();
  });
}
