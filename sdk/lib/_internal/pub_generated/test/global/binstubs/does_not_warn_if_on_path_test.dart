// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("does not warn if the binstub directory is on the path", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "script": null
        }
      },
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok \$args');")])]);
    });

    // Add the test's cache bin directory to the path.
    var binDir = p.dirname(Platform.executable);
    var separator = Platform.operatingSystem == "windows" ? ";" : ":";
    var path = "${Platform.environment["PATH"]}$separator$binDir";

    schedulePub(
        args: ["global", "activate", "foo"],
        output: isNot(contains("is not on your path")),
        environment: {
      "PATH": path
    });
  });
}
