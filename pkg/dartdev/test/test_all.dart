// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'analytics_test.dart' as analytics;
import 'commands/analyze_test.dart' as analyze;
import 'commands/compile_test.dart' as compile;
import 'commands/create_test.dart' as create;
import 'commands/flag_test.dart' as flag;
import 'commands/format_test.dart' as format;
import 'commands/help_test.dart' as help;
import 'commands/migrate_test.dart' as migrate;
import 'commands/pub_test.dart' as pub;
import 'commands/run_test.dart' as run;
import 'commands/test_test.dart' as test;
import 'core_test.dart' as core;
import 'sdk_test.dart' as sdk;
import 'utils_test.dart' as utils;

void main() {
  group('dart', () {
    analytics.main();
    analyze.main();
    create.main();
    flag.main();
    format.main();
    help.main();
    migrate.main();
    pub.main();
    run.main();
    compile.main();
    test.main();
    core.main();
    sdk.main();
    utils.main();
  });
}
