// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.test_all;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'cancelable_future_test.dart' as cancelable_future_test;
import 'context/test_all.dart' as context;
import 'dart/test_all.dart' as dart;
import 'file_system/test_all.dart' as file_system;
import 'generated/test_all.dart' as generated;
import 'instrumentation/test_all.dart' as instrumentation;
import 'parse_compilation_unit_test.dart' as parse_compilation_unit;
import 'source/test_all.dart' as source;
import 'src/test_all.dart' as src;

/// Utility for manually running all tests.
main() {
  defineReflectiveSuite(() {
    cancelable_future_test.main();
    context.main();
    dart.main();
    file_system.main();
    generated.main();
    instrumentation.main();
    parse_compilation_unit.main();
    source.main();
    src.main();
  }, name: 'analyzer');
}
