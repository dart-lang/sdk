// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration(
      'requires the dependency name to match the remote pubspec ' 'name',
      () {
    ensureGit();

    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();

    d.dir(appPath, [d.appPubspec({
        "weirdname": {
          "git": "../foo.git"
        }
      })]).create();

    pubGet(
        error: contains('"name" field doesn\'t match expected name ' '"weirdname".'),
        exitCode: exit_codes.DATA);
  });
}
