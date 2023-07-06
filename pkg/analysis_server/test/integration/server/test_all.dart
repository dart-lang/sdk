// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'blaze_changes_test.dart' as blaze_changes_test;
import 'command_line_options_test.dart' as command_line_options_test;
import 'get_version_test.dart' as get_version_test;
import 'lsp_over_legacy_test.dart' as lsp_over_legacy;
import 'set_subscriptions_invalid_service_test.dart'
    as set_subscriptions_invalid_service_test;
import 'set_subscriptions_test.dart' as set_subscriptions_test;
import 'shutdown_test.dart' as shutdown_test;
import 'status_test.dart' as status_test;

void main() {
  defineReflectiveSuite(() {
    blaze_changes_test.main();
    command_line_options_test.main();
    get_version_test.main();
    lsp_over_legacy.main();
    set_subscriptions_test.main();
    set_subscriptions_invalid_service_test.main();
    shutdown_test.main();
    status_test.main();
  }, name: 'server');
}
