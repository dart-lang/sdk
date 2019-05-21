// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test.dart' as migration_visitor_test;
import 'provisional_api_test.dart' as provisional_api_test;

main() {
  defineReflectiveSuite(() {
    migration_visitor_test.main();
    provisional_api_test.main();
  });
}
