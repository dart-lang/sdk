// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('updates an outdated binstub script', () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok');")])]);
    });

    schedulePub(args: ["global", "activate", "foo"]);

    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages/foo/bin',
                [d.file('script.dart.snapshot', 'junk')])]).create();

    schedulePub(args: ["cache", "repair"], output: '''
          Downloading foo 1.0.0...
          Reinstalled 1 package.
          Reactivating foo 1.0.0...
          Precompiling executables...
          Loading source assets...
          Precompiled foo:script.
          Reactivated 1 package.''');

    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stdout.expect("ok");
    pub.shouldExit();
  });
}
