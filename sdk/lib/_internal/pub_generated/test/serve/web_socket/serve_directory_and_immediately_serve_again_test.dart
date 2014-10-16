// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration(
      "binds a directory to a new port and immediately binds that " "directory again",
      () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("test", [d.file("index.html", "<test body>")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();

    pubServe(args: ["web"]);

    schedule(() {
      return Future.wait([webSocketRequest("serveDirectory", {
          "path": "test"
        }), webSocketRequest("serveDirectory", {
          "path": "test"
        })]).then((results) {
        expect(results[0], contains("result"));
        expect(results[1], contains("result"));
        expect(results[0]["result"], equals(results[1]["result"]));
      });
    });

    endPubServe();
  });
}
