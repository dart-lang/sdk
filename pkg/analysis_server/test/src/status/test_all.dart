// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'performance_page_test.dart' as performance_page;

void main() {
  defineReflectiveSuite(() {
    performance_page.main();
  }, name: 'status');
}
