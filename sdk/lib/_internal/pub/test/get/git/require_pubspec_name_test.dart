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
  integration('requires the dependency to have a pubspec with a name '
      'field', () {
    ensureGit();

    d.git('foo.git', [
      d.libDir('foo'),
      d.pubspec({})
    ]).create();

    d.appDir({"foo": {"git": "../foo.git"}}).create();

    pubGet(error: contains('Missing the required "name" field.'),
        exitCode: exit_codes.DATA);
  });
}
