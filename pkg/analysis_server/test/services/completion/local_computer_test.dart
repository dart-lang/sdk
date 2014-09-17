// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.local;

import 'package:analysis_server/src/services/completion/local_computer.dart';
import '../../reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LocalComputerTest);
}

@ReflectiveTestCase()
class LocalComputerTest extends AbstractCompletionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new LocalComputer();
  }

  test_block() {
    addTestSource('class A {a() {var f; {var x;} ^ var g;}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('f', null);
    assertNotSuggested('g');
    assertNotSuggested('x');
  }

  test_catch() {
    addTestSource('class A {a() {try{} on E catch (e) {^}}}');
    expect(computeFast(), isTrue);
    assertSuggestParameter('e', 'E');
  }

  test_catch2() {
    addTestSource('class A {a() {try{} catch (e, s) {^}}}');
    expect(computeFast(), isTrue);
    assertSuggestParameter('e', null);
    assertSuggestParameter('s', 'StackTrace');
  }

  test_compilationUnit_declarations() {
    addTestSource('@deprecated class A {^} class _B {} A T;');
    expect(computeFast(), isTrue);
    var a = assertSuggestClass('A');
    expect(a.element.isDeprecated, isTrue);
    expect(a.element.isPrivate, isFalse);
    var b = assertSuggestClass('_B');
    expect(b.element.isDeprecated, isFalse);
    expect(b.element.isPrivate, isTrue);
    assertSuggestTopLevelVar('T', 'A');
  }

  test_compilationUnit_directives() {
    addTestSource('import "boo.dart" as x; class A {^}');
    expect(computeFast(), isTrue);
    assertSuggestLibraryPrefix('x');
  }

  test_field_name() {
    addTestSource('class A {B ^}}');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
  }

  test_field_name2() {
    addTestSource('class A {var ^}}');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
  }

  test_for() {
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('i', 'int');
  }

  test_forEach() {
    addTestSource('main(args) {for (foo in bar) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('foo', null);
  }

  test_forEach2() {
    addTestSource('main(args) {for (int foo in bar) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('foo', 'int');
  }

  test_function() {
    addTestSource('String foo(List args) {x.then((R b) {^});}');
    expect(computeFast(), isTrue);
    var f = assertSuggestFunction('foo', 'String', false);
    expect(f.element.isPrivate, isFalse);
    assertSuggestParameter('args', 'List');
    assertSuggestParameter('b', 'R');
  }

  test_getters() {
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

  test_local_name() {
    addTestSource('class A {a() {var f; A ^}}');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
    assertNotSuggested('a');
    assertNotSuggested('f');
  }

  test_local_name2() {
    addTestSource('class _A {a() {var f; var ^}}');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
    assertNotSuggested('a');
    assertNotSuggested('f');
  }

  test_members() {
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

  test_methodParam_named() {
    addTestSource('class A {@deprecated Z a(X x, {y: boo}) {^}}');
    expect(computeFast(), isTrue);
    var a = assertSuggestMethod('a', 'A', 'Z');
    expect(a.element.isDeprecated, isTrue);
    expect(a.element.isPrivate, isFalse);
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', null);
  }

  test_methodParam_positional() {
    addTestSource('class A {Z a(X x, [int y=1]) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestMethod('a', 'A', 'Z');
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', 'int');
  }

  test_topLevelVar_name() {
    addTestSource('class A {} B ^');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
  }

  test_topLevelVar_name2() {
    addTestSource('class A {} var ^');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
  }

  test_variableDeclaration() {
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('a', 'int');
    assertNotSuggested('b');
  }
}
