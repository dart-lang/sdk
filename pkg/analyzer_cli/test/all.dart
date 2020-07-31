// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analysis_options_test.dart' as analysis_options;
import 'build_mode_test.dart' as build_mode;
import 'driver_test.dart' as driver;
import 'embedder_test.dart' as embedder;
import 'errors_reported_once_test.dart' as errors_reported_once;
import 'errors_upgrade_fails_cli_test.dart' as errors_upgrade_fails_cli;
import 'options_test.dart' as options;
import 'package_prefix_test.dart' as package_prefix;
import 'perf_report_test.dart' as perf_report;
import 'reporter_test.dart' as reporter;
import 'strong_mode_test.dart' as strong_mode;

void main() {
  analysis_options.main();
  build_mode.main();
  driver.main();
  embedder.main();
  errors_reported_once.main();
  errors_upgrade_fails_cli.main();
  options.main();
  package_prefix.main();
  perf_report.main();
  reporter.main();
  strong_mode.main();
}
