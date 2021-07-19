// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'change_builder_core_test.dart' as change_builder_core;
import 'change_builder_dart_test.dart' as change_builder_dart;
import 'change_builder_yaml_test.dart' as change_builder_yaml;
import 'dart/test_all.dart' as dart_all;

void main() {
  defineReflectiveSuite(() {
    change_builder_core.main();
    change_builder_dart.main();
    change_builder_yaml.main();
    dart_all.main();
  });
}
