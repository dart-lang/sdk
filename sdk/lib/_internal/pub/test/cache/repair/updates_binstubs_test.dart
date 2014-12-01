// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

const _OUTDATED_BINSTUB = """
#!/usr/bin/env sh
# This file was created by pub v0.1.2-3.
# Package: foo
# Version: 1.0.0
# Executable: foo-script
# Script: script
dart "/path/to/.pub-cache/global_packages/foo/bin/script.dart.snapshot" "\$@"
""";

main() {
  initConfig();
  integration('updates an outdated binstub script', () {
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

    d.dir(cachePath, [
      d.dir('bin', [
        d.file(binStubName('foo-script'), _OUTDATED_BINSTUB)
      ])
    ]).create();

    // Repair them.
    schedulePub(args: ["cache", "repair"],
        output: '''
          Downloading foo 1.0.0...
          Reinstalled 1 package.
          Reactivating foo 1.0.0...
          Precompiling executables...
          Loading source assets...
          Precompiled foo:script.
          Installed executable foo-script.
          Reactivated 1 package.''');

    // The broken versions should have been replaced.
    d.dir(cachePath, [
      d.dir('bin', [
        // 255 is the VM's exit code upon seeing an out-of-date snapshot.
        d.matcherFile(binStubName('foo-script'), contains('255'))
      ])
    ]).validate();
  });
}
