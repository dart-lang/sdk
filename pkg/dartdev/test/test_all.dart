// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'analysis_server_test.dart' as analysis_server;
import 'analytics_test.dart' as analytics;
import 'commands/analyze_test.dart' as analyze;
import 'commands/compile_test.dart' as compile;
import 'commands/create_integration_test.dart' as create_integration;
import 'commands/create_test.dart' as create;
import 'commands/debug_adapter_test.dart' as debug_adapter;
import 'commands/devtools_test.dart' as devtools;
import 'commands/doc_test.dart' as doc;
import 'commands/fix_test.dart' as fix;
import 'commands/flag_test.dart' as flag;
import 'commands/format_test.dart' as format;
import 'commands/help_test.dart' as help;
import 'commands/info_test.dart' as info;
import 'commands/info_windows_test.dart' as info_windows;
import 'commands/language_server_test.dart' as language_server;
import 'commands/pub_test.dart' as pub;
import 'commands/run_test.dart' as run;
import 'commands/test_test.dart' as test;
import 'core_test.dart' as core;
import 'experiments_test.dart' as experiments;
import 'fix_driver_test.dart' as fix_driver;
import 'load_from_dill_test.dart' as load_from_dill;
import 'no_such_file_test.dart' as no_such_file;
import 'regress_46364_test.dart' as regress_46364;
import 'sdk_test.dart' as sdk;
import 'smoke/implicit_smoke_test.dart' as implicit_smoke;
import 'smoke/invalid_smoke_test.dart' as invalid_smoke;
import 'smoke/smoke_test.dart' as smoke;
import 'templates_test.dart' as templates;
import 'utils_test.dart' as utils;

void main() {
  group('dart', () {
    analysis_server.main();
    analytics.main();
    analyze.main();
    compile.main();
    core.main();
    create.main();
    create_integration.main();
    debug_adapter.main();
    devtools.main();
    doc.main();
    experiments.main();
    fix_driver.main();
    fix.main();
    flag.main();
    format.main();
    help.main();
    implicit_smoke.main();
    info.main();
    info_windows.main();
    invalid_smoke.main();
    language_server.main();
    load_from_dill.main();
    no_such_file.main();
    pub.main();
    regress_46364.main();
    run.main();
    sdk.main();
    smoke.main();
    templates.main();
    test.main();
    utils.main();
  });
}
