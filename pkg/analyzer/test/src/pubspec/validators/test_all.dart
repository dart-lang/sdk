// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'pubspec_dependency_validator_test.dart'
    as pubspec_dependency_validator_test;
import 'pubspec_flutter_validator_test.dart' as pubspec_flutter_validator_test;
import 'pubspec_name_validator_test.dart' as pubspec_name_validator_test;

main() {
  defineReflectiveSuite(() {
    pubspec_dependency_validator_test.main();
    pubspec_flutter_validator_test.main();
    pubspec_name_validator_test.main();
  }, name: 'validators');
}
