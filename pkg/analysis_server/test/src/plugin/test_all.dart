// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'notification_manager_test.dart' as notification_manager_test;
import 'plugin_locator_test.dart' as plugin_locator_test;
import 'result_collector_test.dart' as result_collector_test;
import 'result_converter_test.dart' as result_converter_test;
import 'result_merger_test.dart' as result_merger_test;

main() {
  defineReflectiveSuite(() {
    notification_manager_test.main();
    plugin_locator_test.main();
    result_collector_test.main();
    result_converter_test.main();
    result_merger_test.main();
  });
}
