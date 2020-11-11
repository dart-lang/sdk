// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'info_builder_test.dart' as info_builder;
import 'instrumentation_renderer_test.dart' as instrumentation_renderer;
import 'migration_info_test.dart' as migration_info;
import 'migration_summary_test.dart' as migration_summary;
import 'navigation_tree_renderer_test.dart' as navigation_tree_renderer;
import 'offset_mapper_test.dart' as offset_mapper;
import 'region_renderer_test.dart' as region_renderer;
import 'unit_renderer_test.dart' as unit_renderer;

main() {
  defineReflectiveSuite(() {
    info_builder.main();
    instrumentation_renderer.main();
    migration_info.main();
    migration_summary.main();
    navigation_tree_renderer.main();
    offset_mapper.main();
    region_renderer.main();
    unit_renderer.main();
  }, name: 'front_end');
}
