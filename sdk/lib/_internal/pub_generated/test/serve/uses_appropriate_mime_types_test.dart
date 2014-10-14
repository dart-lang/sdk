// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("uses appropriate mime types", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("index.html", "<body>"),
                    d.file("file.dart", "main() => print('hello');"),
                    d.file("file.js", "console.log('hello');"),
                    d.file("file.css", "body {color: blue}")])]).create();

    pubServe();
    requestShouldSucceed(
        "index.html",
        anything,
        headers: containsPair('content-type', 'text/html'));
    requestShouldSucceed(
        "file.dart",
        anything,
        headers: containsPair('content-type', 'application/dart'));
    requestShouldSucceed(
        "file.js",
        anything,
        headers: containsPair('content-type', 'application/javascript'));
    requestShouldSucceed(
        "file.css",
        anything,
        headers: containsPair('content-type', 'text/css'));
    endPubServe();
  });
}
