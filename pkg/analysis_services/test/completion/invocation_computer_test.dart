// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;


import 'package:analysis_services/src/completion/invocation_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(InvocationComputerTest);
}

@ReflectiveTestCase()
class InvocationComputerTest extends AbstractCompletionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new InvocationComputer();
  }

  test_field() {
    addTestSource('class A {A b;} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestField('b');
    });
  }

  test_getter() {
    addTestSource('class A {A get b => new A();} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestGetter('b');
    });
  }

  test_method() {
    addTestSource('class A {b(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestMethod('b');
    });
  }

  test_setter() {
    addTestSource('class A {set b(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestSetter('b');
    });
  }
}
