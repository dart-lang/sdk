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

  test_ForEachStatement_body_typed() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('foo', 'int');
  }

  test_ForEachStatement_body_untyped() {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('foo', null);
  }

  test_ForStatement_body() {
    // Block  ForStatement
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('i', 'int');
  }

  test_ForStatement_condition() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('index', 'int');
  }

  test_ForStatement_updaters() {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('index', 'int');
  }

  test_ForStatement_updaters_prefix_expression() {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; ++i^)}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('index', 'int');
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
