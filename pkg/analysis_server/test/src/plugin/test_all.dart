// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'notification_manager_test.dart' as notification_manager;
import 'plugin_isolate_test.dart' as plugin_isolate;
import 'plugin_locator_test.dart' as plugin_locator;
import 'plugin_manager_test.dart' as plugin_manager;
import 'plugin_watcher_test.dart' as plugin_watcher;
import 'request_converter_test.dart' as request_converter;
import 'result_collector_test.dart' as result_collector;
import 'result_converter_test.dart' as result_converter;
import 'result_merger_test.dart' as result_merger;

void main() {
  defineReflectiveSuite(() {
    notification_manager.main();
    plugin_isolate.main();
    plugin_locator.main();
    plugin_manager.main();
    plugin_watcher.main();
    request_converter.main();
    result_collector.main();
    result_converter.main();
    result_merger.main();
  }, name: 'plugin');
}
