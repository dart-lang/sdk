// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'enable_test.dart' as enable_test;
import 'is_enabled_test.dart' as is_enabled_test;
import 'send_event_test.dart' as send_event_test;
import 'send_timing_test.dart' as send_timing_test;

main() {
  defineReflectiveSuite(() {
    enable_test.main();
    is_enabled_test.main();
    send_event_test.main();
    send_timing_test.main();
  }, name: 'analytics');
}
