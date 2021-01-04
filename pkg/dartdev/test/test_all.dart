// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'analytics_test.dart' as analytics;
import 'commands/analyze_test.dart' as analyze;
import 'commands/compile_test.dart' as compile;
import 'commands/create_test.dart' as create;
import 'commands/fix_test.dart' as fix;
import 'commands/flag_test.dart' as flag;
import 'commands/format_test.dart' as format;
import 'commands/help_test.dart' as help;
import 'commands/migrate_test.dart' as migrate;
import 'commands/pub_test.dart' as pub;
import 'commands/run_test.dart' as run;
import 'commands/test_test.dart' as test;
import 'core_test.dart' as core;
import 'experiments_test.dart' as experiments;
import 'fix_driver_test.dart' as fix_driver;
import 'no_such_file_test.dart' as no_such_file;
import 'sdk_test.dart' as sdk;
import 'smoke/implicit_smoke_test.dart' as implicit_smoke;
import 'smoke/invalid_smoke_test.dart' as invalid_smoke;
import 'smoke/smoke_test.dart' as smoke;
import 'utils_test.dart' as utils;

void main() {
  group('dart', () {
    analytics.main();
    analyze.main();
    create.main();
    experiments.main();
    fix.main();
    fix_driver.main();
    flag.main();
    format.main();
    help.main();
    implicit_smoke.main();
    invalid_smoke.main();
    migrate.main();
    no_such_file.main();
    pub.main();
    run.main();
    compile.main();
    test.main();
    core.main();
    sdk.main();
    smoke.main();
    utils.main();
  });
}
