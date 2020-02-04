// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analyzer_status_test.dart' as analyzer_status;
import 'diagnostic_test.dart' as diagnostic_test;
import 'initialization_test.dart' as initialization_test;
import 'server_test.dart' as server_test;

void main() {
  defineReflectiveSuite(() {
    analyzer_status.main();
    diagnostic_test.main();
    initialization_test.main();
    server_test.main();
  }, name: 'lsp integration');
}
