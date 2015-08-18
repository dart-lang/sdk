// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.task.strong_mode_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:analyzer/task/dart.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../../utils.dart';
import '../context/abstract_context.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(InferrenceFinderTest);
}

@reflectiveTest
class InferrenceFinderTest extends AbstractContextTest {
  void test_creation() {
    InferrenceFinder finder = new InferrenceFinder();
    expect(finder, isNotNull);
    expect(finder.classes, isEmpty);
    expect(finder.staticVariables, isEmpty);
  }

  void test_visit() {
    Source source = addSource(
        '/test.dart',
        r'''
const c = 1;
final f = '';
var v = const A();
class A {
  static final fa = 0;
  const A();
}
class B extends A {
  static const cb = 1;
  static vb = 0;
  const ci = 2;
  final fi = '';
  var vi;
}
class C = Object with A;
typedef int F(int x);
''');
    computeResult(source, PARSED_UNIT);
    CompilationUnit unit = outputs[PARSED_UNIT];
    InferrenceFinder finder = new InferrenceFinder();
    unit.accept(finder);
    expect(finder.classes, hasLength(3));
    expect(finder.staticVariables, hasLength(6));
  }
}
