// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'string_table_test.dart' as string_table;

main() {
  defineReflectiveSuite(() {
    string_table.main();
  }, name: 'binary');
}
