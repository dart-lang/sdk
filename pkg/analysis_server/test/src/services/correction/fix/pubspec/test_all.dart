// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'add_dependency_test.dart' as add_dependency;
import 'missing_name_test.dart' as missing_name;
import 'sort_pub_dependencies_test.dart' as sort_pub_dependencies;

void main() {
  defineReflectiveSuite(() {
    add_dependency.main();
    missing_name.main();
    sort_pub_dependencies.main();
  });
}
