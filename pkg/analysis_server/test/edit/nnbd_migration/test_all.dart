// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'instrumentation_output_test.dart' as instrumentation_output;

main() {
  defineReflectiveSuite(() {
    instrumentation_output.main();
  }, name: 'nnbd_migration');
}
