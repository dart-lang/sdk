// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'info_builder_test.dart' as info_builder;
import 'offset_mapper_test.dart' as offset_mapper;
import 'unit_renderer_test.dart' as unit_renderer;

main() {
  defineReflectiveSuite(() {
    info_builder.main();
    offset_mapper.main();
    unit_renderer.main();
  }, name: 'nnbd_migration');
}
