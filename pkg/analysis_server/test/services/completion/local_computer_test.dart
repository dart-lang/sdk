// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.local;

import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LocalComputerTest);
}

@ReflectiveTestCase()
class LocalComputerTest extends AbstractSelectorSuggestionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new LocalComputer();
  }

  test_FunctionExpression_body_function() {
    // Block  BlockFunctionBody  FunctionExpression
    addTestSource('String foo(List args) {x.then((R b) {^});}');
    expect(computeFast(), isTrue);
    var f = assertSuggestFunction('foo', 'String', false);
    expect(f.element.isPrivate, isFalse);
    assertSuggestParameter('args', 'List');
    assertSuggestParameter('b', 'R');
  }

  test_InterpolationExpression() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \$^");}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('name', 'String');
  }

  test_InterpolationExpression_block() {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('name', 'String');
  }

  test_MethodDeclaration_body_getters() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X get f => 0; Z a() {^} get _g => 1;}');
    expect(computeFast(), isTrue);
    var a = assertSuggestMethod('a', 'A', 'Z');
    expect(a.element.isDeprecated, isFalse);
    expect(a.element.isPrivate, isFalse);
    var f = assertSuggestGetter('f', 'X');
    expect(f.element.isDeprecated, isTrue);
    expect(f.element.isPrivate, isFalse);
    var g = assertSuggestGetter('_g', null);
    expect(g.element.isDeprecated, isFalse);
    expect(g.element.isPrivate, isTrue);
  }

  test_MethodDeclaration_members() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X f; Z _a() {^} var _g;}');
    expect(computeFast(), isTrue);
    var a = assertSuggestMethod('_a', 'A', 'Z');
    expect(a.element.isDeprecated, isFalse);
    expect(a.element.isPrivate, isTrue);
    var f = assertSuggestGetter('f', 'X');
    expect(f.element.isDeprecated, isTrue);
    expect(f.element.isPrivate, isFalse);
    var g = assertSuggestGetter('_g', null);
    expect(g.element.isDeprecated, isFalse);
    expect(g.element.isPrivate, isTrue);
  }

  test_MethodDeclaration_parameters_named() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated Z a(X x, {y: boo}) {^}}');
    expect(computeFast(), isTrue);
    var a = assertSuggestMethod('a', 'A', 'Z');
    expect(a.element.isDeprecated, isTrue);
    expect(a.element.isPrivate, isFalse);
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', null);
  }

  test_MethodDeclaration_parameters_positional() {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {Z a(X x, [int y=1]) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestMethod('a', 'A', 'Z');
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', 'int');
  }
}
