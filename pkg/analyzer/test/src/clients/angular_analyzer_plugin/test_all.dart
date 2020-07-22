// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolve_template_node_test.dart' as resolve_template_node;

main() {
  defineReflectiveSuite(() {
    resolve_template_node.main();
  }, name: 'angular_analyzer_plugin');
}
