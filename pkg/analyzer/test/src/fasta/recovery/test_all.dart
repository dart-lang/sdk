// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'code_order_test.dart' as code_order;
import 'missing_code_test.dart' as missing_code;

main() {
  defineReflectiveSuite(() {
    code_order.main();
    missing_code.main();
  }, name: 'recovery');
}
