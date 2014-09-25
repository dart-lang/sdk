// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("the generated binstub runs a snapshotted executable", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "foo-script": "script"
        }
      }, contents: [
        d.dir("bin", [
          d.file("script.dart", "main(args) => print('ok \$args');")
        ])
      ]);
    });

    schedulePub(args: ["global", "activate", "foo"]);

    var process = new ScheduledProcess.start(
        p.join(sandboxDir, cachePath, "bin", binStubName("foo-script")),
        ["arg1", "arg2"],
        environment: getEnvironment());

    process.stdout.expect("ok [arg1, arg2]");
    process.shouldExit();
  });

  integration("the generated binstub runs a non-snapshotted executable", () {
    d.dir("foo", [
      d.pubspec({
        "name": "foo",
        "executables": {
          "foo-script": "script"
        }
      }),
      d.dir("bin", [
          d.file("script.dart", "main(args) => print('ok \$args');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "-spath", "../foo"]);

    var process = new ScheduledProcess.start(
        p.join(sandboxDir, cachePath, "bin", binStubName("foo-script")),
        ["arg1", "arg2"],
        environment: getEnvironment());

    process.stdout.expect("ok [arg1, arg2]");
    process.shouldExit();
  });
}

/// The buildbots do not have the Dart SDK (containing "dart" and "pub") on
/// their PATH, so we need to spawn the binstub process with a PATH that
/// explicitly includes it.
getEnvironment() {
  var binDir = p.dirname(Platform.executable);
  var separator = Platform.operatingSystem == "windows" ? ";" : ":";
  var path = "${Platform.environment["PATH"]}$separator$binDir";

  var environment = getPubTestEnvironment();
  environment["PATH"] = path;
  return environment;
}
