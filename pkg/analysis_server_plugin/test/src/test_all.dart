// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'plugin_server_error_test.dart' as plugin_server_error_test;
import 'plugin_server_test.dart' as plugin_server_test;

void main() {
  defineReflectiveSuite(() {
    plugin_server_error_test.main();
    plugin_server_test.main();
  }, name: 'src');
}
