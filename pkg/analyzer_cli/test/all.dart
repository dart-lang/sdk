// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'boot_loader_test.dart' as boot_loader;
import 'build_mode_test.dart' as build_mode_test;
import 'driver_test.dart' as driver;
import 'error_test.dart' as error;
import 'options_test.dart' as options;
import 'package_prefix_test.dart' as package_prefix;
import 'perf_report_test.dart' as perf;
import 'plugin_manager_test.dart' as plugin_manager;
import 'reporter_test.dart' as reporter;
import 'super_mixin_test.dart' as super_mixin;
//import 'sdk_ext_test.dart' as sdk_ext;
//import 'strong_mode_test.dart' as strong_mode;

main() {
  boot_loader.main();
  build_mode_test.main();
  driver.main();
  // TODO(pq): fix tests to run safely on the bots
  // https://github.com/dart-lang/sdk/issues/25001
  //sdk_ext.main();
  //strong_mode.main();
  error.main();
  options.main();
  perf.main();
  plugin_manager.main();
  reporter.main();
  super_mixin.main();
  package_prefix.main();
}
