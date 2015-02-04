// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();

  setUp(() {
    d.appDir().create();
  });

  pubBuildAndServeShouldFail(
      "on --all with no default source directories",
      args: ["--all"],
      error: 'There are no source directories present.\n'
          'The default directories are "benchmark", "bin", "example", '
          '"test" and "web".',
      exitCode: exit_codes.DATA);
}
