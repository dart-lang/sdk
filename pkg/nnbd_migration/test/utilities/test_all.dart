// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'multi_future_tracker_test.dart' as multi_future_tracker_test;
import 'scoped_set_test.dart' as scoped_set_test;
import 'subprocess_launcher_test.dart' as subprocess_launcher_test;

main() {
  defineReflectiveSuite(() {
    multi_future_tracker_test.main();
    scoped_set_test.main();
    subprocess_launcher_test.main();
  });
}
