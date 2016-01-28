// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.dart.element.element_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:unittest/unittest.dart';

import '../../generated/test_support.dart';
import '../../reflective_tests.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ElementKindTest);
}

@reflectiveTest
class ElementKindTest extends EngineTestCase {
  void test_of_nonNull() {
    expect(ElementKind.of(ElementFactory.classElement2("A")),
        same(ElementKind.CLASS));
  }

  void test_of_null() {
    expect(ElementKind.of(null), same(ElementKind.ERROR));
  }
}
