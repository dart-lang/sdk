// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("fails if the directory overlaps one already being served", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "web",
                [
                    d.file("index.html", "<body>"),
                    d.dir("sub", [d.file("index.html", "<sub>"),])])]).create();

    pubServe();

    var webSub = path.join("web", "sub");
    expectWebSocketError("serveDirectory", {
      "path": webSub
    },
        2,
        'Path "$webSub" overlaps already served directory "web".',
        data: containsPair("directories", ["web"]));

    endPubServe();
  });
}
