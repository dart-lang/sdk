// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_visitors_test.dart' as element_visitors;
import 'hierarchy_test.dart' as hierarchy_test;
import 'search_engine_test.dart' as search_engine_test;

void main() {
  defineReflectiveSuite(() {
    element_visitors.main();
    hierarchy_test.main();
    search_engine_test.main();
  }, name: 'search');
}
