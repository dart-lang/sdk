// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;


import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import '../../reflective_tests.dart';
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
    addTestSource('class A {var b; X _c;} class X{} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestField('b', 'A', null);
      assertSuggestField('_c', 'A', 'X');
    });
  }

  test_field_imported() {
    addSource('/testB.dart', 'lib B; class X {M y; var _z;} class M{}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestField('y', 'X', 'M');
      assertNotSuggested('_z');
    });
  }

  test_field_superclass() {
    addTestSource(
        'class A {X b; var _c;} class X{} class B extends A {} main() {B b; b.^}');
    return computeFull().then((_) {
      assertSuggestField('b', 'A', 'X');
      assertSuggestField('_c', 'A', null);
    });
  }

  test_getter() {
    addTestSource(
        'class A {X get b => new A();get _c => new A();} class X{} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestGetter('b', 'X');
      assertSuggestGetter('_c', null);
    });
  }

  test_getter_imported() {
    addSource(
        '/testB.dart',
        'lib B; class S{} class X {S get y => new X(); X get _z => new X();}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestGetter('y', 'S');
      assertNotSuggested('_z');
    });
  }

  test_getter_interface() {
    addTestSource('''class A {S get b => new A();A get _c => new A();}
           class B implements A {S get b => new A();} class S{}
           main() {B b; b.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b', 'S');
      assertSuggestGetter('_c', 'A');
    });
  }

  test_library_prefix() {
    addSource('/testB.dart', 'lib B; class X { }');
    addTestSource('import "/testB.dart" as b; main() {b.^}');
    return computeFull().then((_) {
      assertSuggestClass('X');
    });
  }

  test_method() {
    addTestSource('class S{} class A {b(X x) {} S _c(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestMethod('b', 'A', null);
      assertSuggestMethod('_c', 'A', 'S');
    });
  }

  test_method_imported() {
    addSource('/testB.dart', 'lib B; class X {T y(X x) {} _z(X x) {}} class T{}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestMethod('y', 'X', 'T');
      assertNotSuggested('_z');
    });
  }

  test_method_imported_mixin() {
    addSource('/testB.dart', 'lib B; class X {T y(X x) {} _z(X x) {}} class T{}');
    addTestSource('''import "/testB.dart";
      class A extends Object with X {}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestMethod('y', 'X', 'T');
      assertNotSuggested('_z');
    });
  }

  test_setter() {
    addTestSource('class A {set b(X x) {} set _c(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestSetter('b');
      assertSuggestSetter('_c');
    });
  }

  test_setter_imported() {
    addSource('/testB.dart', 'lib B; class X {set y(X x) {} set _z(X x) {}}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestSetter('y');
      assertNotSuggested('_z');
    });
  }
}
