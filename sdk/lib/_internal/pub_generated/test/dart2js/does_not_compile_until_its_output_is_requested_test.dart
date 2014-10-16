// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_stream.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  integration("does not compile until its output is requested", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "version": "0.0.1",
      }),
          d.dir("web", [d.file("syntax-error.dart", "syntax error")])]).create();

    var server = pubServe();
    server.stdout.expect("Build completed successfully");

    // Once we request the output, it should start compiling and fail.
    requestShould404("syntax-error.dart.js");
    server.stdout.expect(
        emitsLines(
            "[Info from Dart2JS]:\n" "Compiling myapp|web/syntax-error.dart..."));
    server.stdout.expect(consumeThrough("Build completed with 1 errors."));
    endPubServe();
  });
}
