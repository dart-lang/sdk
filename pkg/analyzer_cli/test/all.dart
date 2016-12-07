// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'build_mode_test.dart' as build_mode_test;
import 'driver_test.dart' as driver;
import 'embedder_test.dart' as embedder;
import 'error_test.dart' as error;
import 'options_test.dart' as options;
import 'package_prefix_test.dart' as package_prefix;
import 'perf_report_test.dart' as perf;
import 'reporter_test.dart' as reporter;
import 'sdk_ext_test.dart' as sdk_ext;
import 'super_mixin_test.dart' as super_mixin;
//import 'strong_mode_test.dart' as strong_mode;

main() {
  build_mode_test.main();
  driver.main();
  embedder.main();
  sdk_ext.main();
  // TODO(pq): fix tests to run safely on the bots
  // https://github.com/dart-lang/sdk/issues/25001
  //strong_mode.main();
  error.main();
  options.main();
  perf.main();
  reporter.main();
  super_mixin.main();
  package_prefix.main();
}
