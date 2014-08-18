// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.local;

import 'package:analysis_services/src/completion/local_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
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
    assertSuggestLocalVariable('f');
    assertNotSuggested('g');
    assertNotSuggested('x');
  }

  test_catch() {
    addTestSource('class A {a() {try{} catch (e) {^}}}');
    expect(computeFast(), isTrue);
    assertSuggestParameter('e');
  }

  test_catch2() {
    addTestSource('class A {a() {try{} catch (e, s) {^}}}');
    expect(computeFast(), isTrue);
    assertSuggestParameter('e');
    assertSuggestParameter('s');
  }

  test_compilationUnit_declarations() {
    addTestSource('class A {^} class B {} var T;');
    expect(computeFast(), isTrue);
    assertSuggestClass('A');
    assertSuggestClass('B');
    assertSuggestTopLevelVar('T');
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
    //TODO (danrubel) should not be suggested
    // but var ^ in this test
    // parses differently than B ^ in test above
    assertSuggestClass('A');
  }

  test_for() {
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('i');
  }

  test_forEach() {
    addTestSource('main(args) {for (foo in bar) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('foo');
  }

  test_function() {
    addTestSource('main(args) {x.then((b) {^});}');
    expect(computeFast(), isTrue);
    assertSuggestFunction('main');
    assertSuggestParameter('args');
    assertSuggestParameter('b');
  }

  test_local_name() {
    addTestSource('class A {a() {var f; A ^}}');
    expect(computeFast(), isTrue);
    //TODO (danrubel) should not be suggested
    // but A ^ in this test
    // parses differently than var ^ in test below
    assertSuggestClass('A');
    assertSuggestMethodName('a');
    assertSuggestLocalVariable('f');
  }

  test_local_name2() {
    addTestSource('class A {a() {var f; var ^}}');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
    assertNotSuggested('a');
    assertNotSuggested('f');
  }

  test_members() {
    addTestSource('class A {var f; a() {^} var g;}');
    expect(computeFast(), isTrue);
    assertSuggestMethodName('a');
    assertSuggestField('f');
    assertSuggestField('g');
  }

  test_methodParam_named() {
    addTestSource('class A {a(x, {y: boo}) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestMethodName('a');
    assertSuggestParameter('x');
    assertSuggestParameter('y');
  }

  test_methodParam_positional() {
    addTestSource('class A {a(x, [y=1]) {^}}');
    expect(computeFast(), isTrue);
    assertSuggestMethodName('a');
    assertSuggestParameter('x');
    assertSuggestParameter('y');
  }

  test_topLevelVar_name() {
    addTestSource('class A {} B ^');
    expect(computeFast(), isTrue);
    assertNotSuggested('A');
  }

  test_topLevelVar_name2() {
    addTestSource('class A {} var ^');
    expect(computeFast(), isTrue);
    // TODO (danrubel) should not be suggested
    // but var ^ in this test
    // parses differently than B ^ in test above
    assertSuggestClass('A');
  }

  test_variableDeclaration() {
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    expect(computeFast(), isTrue);
    assertSuggestLocalVariable('a');
    assertNotSuggested('b');
  }
}
