// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

const _ORPHANED_BINSTUB = """
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
  integration('handles an orphaned binstub script', () {
    d.dir(cachePath, [
      d.dir('bin', [
        d.file(binStubName('script'), _ORPHANED_BINSTUB)
      ])
    ]).create();

    schedulePub(args: ["cache", "repair"], error: allOf([
      contains('Binstubs exist for non-activated packages:'),
      contains('From foo: foo-script')
    ]));
  });
}
