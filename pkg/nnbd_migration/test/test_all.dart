// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'api_test.dart' as api_test;
import 'decorated_class_hierarchy_test.dart' as decorated_class_hierarchy_test;
import 'decorated_type_test.dart' as decorated_type_test;
import 'edge_builder_test.dart' as edge_builder_test;
import 'node_builder_test.dart' as node_builder_test;
import 'nullability_node_test.dart' as nullability_node_test;

main() {
  defineReflectiveSuite(() {
    api_test.main();
    decorated_class_hierarchy_test.main();
    decorated_type_test.main();
    edge_builder_test.main();
    node_builder_test.main();
    nullability_node_test.main();
  });
}
