// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analysis_options_test.dart' as analysis_options_test;
import 'build_mode_test.dart' as build_mode_test;
import 'driver_test.dart' as driver_test;
import 'embedder_test.dart' as embedder_test;
import 'error_test.dart' as error_test;
import 'errors_reported_once_test.dart' as errors_reported_once_test;
import 'errors_upgrade_fails_cli_test.dart' as errors_upgrade_fails_cli_test;
import 'options_test.dart' as options_test;
import 'package_prefix_test.dart' as package_prefix_test;
import 'perf_report_test.dart' as perf_report_test;
import 'reporter_test.dart' as reporter_test;
import 'sdk_ext_test.dart' as sdk_ext_test;
import 'super_mixin_test.dart' as super_mixin_test;
//import 'strong_mode_test.dart' as strong_mode_test;

main() {
  analysis_options_test.main();
  build_mode_test.main();
  driver_test.main();
  embedder_test.main();
  error_test.main();
  errors_reported_once_test.main();
  errors_upgrade_fails_cli_test.main();
  options_test.main();
  package_prefix_test.main();
  perf_report_test.main();
  reporter_test.main();
  sdk_ext_test.main();
  super_mixin_test.main();
  // TODO(pq): fix tests to run safely on the bots
  // https://github.com/dart-lang/sdk/issues/25001
  //strong_mode_test.main();
}
